import 'dart:async';
import 'dart:convert';

import '../core/models.dart';

/// The notification families exposed to Android as separate channels.
///
/// Settings can toggle these values independently without changing the
/// scheduling implementation.
enum CurreNotificationType { checkIn, planEnding, unlockTimeUp, proof }

enum CurreNotificationDestination { home, checkIn, hiddenApps, proof }

enum CurreNotificationAction { startCheckIn, bringIntoSight, addProof, snooze }

extension CurreNotificationActionWire on CurreNotificationAction {
  String get wireValue => switch (this) {
    CurreNotificationAction.startCheckIn => 'start_check_in',
    CurreNotificationAction.bringIntoSight => 'bring_into_sight',
    CurreNotificationAction.addProof => 'add_proof',
    CurreNotificationAction.snooze => 'snooze_10',
  };

  String get label => switch (this) {
    CurreNotificationAction.startCheckIn => 'Plan now',
    CurreNotificationAction.bringIntoSight => 'Bring back',
    CurreNotificationAction.addProof => 'Add proof',
    CurreNotificationAction.snooze => 'Snooze 10 min',
  };

  static CurreNotificationAction? tryParse(String? value) {
    for (final action in CurreNotificationAction.values) {
      if (action.wireValue == value) return action;
    }
    return null;
  }
}

/// A quiet-hours aware switchboard for the future Settings UI.
///
/// Quiet hours may cross midnight. Reminders that land inside them move to
/// the end of the quiet window; they are never scheduled with an exact alarm.
class CurreNotificationPolicy {
  CurreNotificationPolicy({
    Set<CurreNotificationType>? enabled,
    this.quietStarts = const LocalTime(22),
    this.quietEnds = const LocalTime(7),
  }) : enabled = Set.unmodifiable(
         enabled ?? CurreNotificationType.values.toSet(),
       );

  final Set<CurreNotificationType> enabled;
  final LocalTime quietStarts;
  final LocalTime quietEnds;

  bool allows(CurreNotificationType type) => enabled.contains(type);

  bool isQuiet(DateTime local) {
    final minute = local.hour * 60 + local.minute;
    final start = quietStarts.minutesAfterMidnight;
    final end = quietEnds.minutesAfterMidnight;
    if (start == end) return false;
    return start < end
        ? minute >= start && minute < end
        : minute >= start || minute < end;
  }

  DateTime nextAllowed(DateTime local) {
    if (!isQuiet(local)) return local;
    final minute = local.hour * 60 + local.minute;
    final start = quietStarts.minutesAfterMidnight;
    final end = quietEnds.minutesAfterMidnight;
    final nextDay = start > end && minute >= start;
    return DateTime(
      local.year,
      local.month,
      local.day + (nextDay ? 1 : 0),
      quietEnds.hour,
      quietEnds.minute,
    );
  }
}

class CurreReminder {
  const CurreReminder({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.destination,
    required this.actions,
    this.reference,
  });

  final int id;
  final CurreNotificationType type;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final CurreNotificationDestination destination;
  final List<CurreNotificationAction> actions;
  final String? reference;

  String get payload => jsonEncode(<String, Object?>{
    'version': 1,
    'type': type.name,
    'destination': destination.name,
    'title': title,
    'body': body,
    'reference': ?reference,
  });
}

class CurreNotificationIntent {
  const CurreNotificationIntent({
    required this.type,
    required this.destination,
    this.action,
    this.reference,
    this.note,
  });

  final CurreNotificationType type;
  final CurreNotificationDestination destination;
  final CurreNotificationAction? action;
  final String? reference;
  final String? note;

  static CurreNotificationIntent? fromPayload(
    String? payload, {
    String? actionId,
    String? note,
  }) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final json = jsonDecode(payload);
      if (json is! Map<String, Object?> || json['version'] != 1) return null;
      final type = CurreNotificationType.values.byName(json['type']! as String);
      final destination = CurreNotificationDestination.values.byName(
        json['destination']! as String,
      );
      return CurreNotificationIntent(
        type: type,
        destination: destination,
        action: CurreNotificationActionWire.tryParse(actionId),
        reference: json['reference'] as String?,
        note: note?.trim().isEmpty ?? true ? null : note!.trim(),
      );
    } on Object {
      return null;
    }
  }
}

/// Process-wide hand-off between Android's notification callback and the
/// navigation tree. It deliberately carries only routes and an optional proof
/// note; product state remains phone-owned by the app controller.
class CurreNotificationInbox {
  CurreNotificationInbox._();

  static final CurreNotificationInbox instance = CurreNotificationInbox._();

  final StreamController<CurreNotificationIntent> _controller =
      StreamController<CurreNotificationIntent>.broadcast(sync: true);

  Stream<CurreNotificationIntent> get stream => _controller.stream;

  void add(CurreNotificationIntent intent) => _controller.add(intent);
}

abstract interface class ReminderNotificationGateway {
  Future<void> initialize();
  Future<void> scheduleReminder(CurreReminder reminder);
  Future<void> cancelReminder(int id);
}

/// Builds all rich local reminders as plain values before the Android plugin
/// sees them. That keeps content, actions, quiet hours and schedule math easy
/// to test and lets a future Settings screen supply a different [policy].
class LocalReminderService {
  LocalReminderService(
    this._gateway, {
    DateTime Function()? now,
    CurreNotificationPolicy? policy,
  }) : _now = now ?? DateTime.now,
       policy = policy ?? CurreNotificationPolicy();

  static const int _morningId = 1101;
  static const int _afternoonId = 1102;
  static const int _eveningId = 1103;
  static const Duration planHeadsUp = Duration(minutes: 10);
  static const Duration proofDelay = Duration(minutes: 5);

  final ReminderNotificationGateway _gateway;
  final DateTime Function() _now;
  final CurreNotificationPolicy policy;

  Future<void> scheduleSessionReminders(Settings settings) async {
    await _gateway.initialize();
    final now = _now();
    for (final session in SessionName.values) {
      final id = _sessionId(session);
      await _gateway.cancelReminder(id);
      if (!policy.allows(CurreNotificationType.checkIn)) continue;
      final start = settings.sessionStarts[session]!;
      var scheduled = DateTime(
        now.year,
        now.month,
        now.day,
        start.hour,
        start.minute,
      );
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      scheduled = policy.nextAllowed(scheduled);
      await _gateway.scheduleReminder(
        CurreReminder(
          id: id,
          type: CurreNotificationType.checkIn,
          title: 'Plan your ${session.name}',
          body: 'One sentence, and Curre puts just the apps you need on Home.',
          scheduledAt: scheduled,
          destination: CurreNotificationDestination.checkIn,
          actions: const <CurreNotificationAction>[
            CurreNotificationAction.startCheckIn,
            CurreNotificationAction.snooze,
          ],
          reference: session.name,
        ),
      );
    }
  }

  Future<void> schedulePlanReminders(Plan plan) async {
    await _gateway.initialize();
    final seed = _stableId(plan.id);
    final headsUpId = 200000 + seed;
    final proofId = 400000 + seed;
    await _gateway.cancelReminder(headsUpId);
    await _gateway.cancelReminder(proofId);

    final now = _now();
    final localEnd = plan.endsAt.toLocal();
    if (policy.allows(CurreNotificationType.planEnding)) {
      final proposed = localEnd.subtract(planHeadsUp);
      if (proposed.isAfter(now)) {
        await _gateway.scheduleReminder(
          CurreReminder(
            id: headsUpId,
            type: CurreNotificationType.planEnding,
            title: 'Your ${plan.session.name} is almost done',
            body: 'Your plan ends in 10 minutes. Choose what comes next.',
            scheduledAt: policy.nextAllowed(proposed),
            destination: CurreNotificationDestination.checkIn,
            actions: const <CurreNotificationAction>[
              CurreNotificationAction.startCheckIn,
              CurreNotificationAction.snooze,
            ],
            reference: plan.id,
          ),
        );
      }
    }

    if (policy.allows(CurreNotificationType.proof)) {
      final proposed = localEnd.add(proofDelay);
      if (proposed.isAfter(now)) {
        await _gateway.scheduleReminder(
          CurreReminder(
            id: proofId,
            type: CurreNotificationType.proof,
            title: 'Add your proof',
            body: 'A short note about what you got done counts as proof.',
            scheduledAt: policy.nextAllowed(proposed),
            destination: CurreNotificationDestination.proof,
            actions: const <CurreNotificationAction>[
              CurreNotificationAction.addProof,
              CurreNotificationAction.snooze,
            ],
            reference: plan.id,
          ),
        );
      }
    }
  }

  int _sessionId(SessionName session) => switch (session) {
    SessionName.morning => _morningId,
    SessionName.afternoon => _afternoonId,
    SessionName.evening => _eveningId,
  };
}

int _stableId(String value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash.remainder(190000);
}
