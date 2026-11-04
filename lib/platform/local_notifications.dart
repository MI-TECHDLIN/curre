import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import '../core/models.dart';
import '../l10n/l10n.dart';

/// The notification families exposed to Android as separate channels.
///
/// Settings can toggle these values independently without changing the
/// scheduling implementation.
enum CurreNotificationType { checkIn, planEnding, unlockTimeUp, proof, focus }

enum CurreNotificationDestination { home, checkIn, hiddenApps, proof }

enum CurreNotificationAction { startCheckIn, bringIntoSight, addProof, snooze }

extension CurreNotificationActionWire on CurreNotificationAction {
  String get wireValue => switch (this) {
    CurreNotificationAction.startCheckIn => 'start_check_in',
    CurreNotificationAction.bringIntoSight => 'bring_into_sight',
    CurreNotificationAction.addProof => 'add_proof',
    CurreNotificationAction.snooze => 'snooze_10',
  };

  String labelFor(AppLocalizations l10n) => switch (this) {
    CurreNotificationAction.startCheckIn => l10n.planNow,
    CurreNotificationAction.bringIntoSight => l10n.bringItBack,
    CurreNotificationAction.addProof => l10n.addProof,
    CurreNotificationAction.snooze => l10n.snoozeTenMinutes,
  };

  /// Kept for callers that build a notification without a locale.
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

  factory CurreNotificationPolicy.fromSettings(Settings settings) =>
      CurreNotificationPolicy(
        enabled: <CurreNotificationType>{
          if (settings.checkInNudges) CurreNotificationType.checkIn,
          if (settings.planEndingNudges) CurreNotificationType.planEnding,
          if (settings.unlockTimeUpNudges) CurreNotificationType.unlockTimeUp,
          if (settings.proofNudges) CurreNotificationType.proof,
          if (settings.focusNudges) CurreNotificationType.focus,
        },
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
    this.languageCode = 'en',
  });

  final int id;
  final CurreNotificationType type;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final CurreNotificationDestination destination;
  final List<CurreNotificationAction> actions;
  final String? reference;
  final String languageCode;

  String get payload => jsonEncode(<String, Object?>{
    'version': 1,
    'type': type.name,
    'destination': destination.name,
    'title': title,
    'body': body,
    'reference': ?reference,
    'language': languageCode,
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

/// The actions a reminder of [type] offers, also when it comes back after
/// "Snooze 10 min".
List<CurreNotificationAction> defaultActionsFor(CurreNotificationType type) =>
    switch (type) {
      CurreNotificationType.checkIn ||
      CurreNotificationType.planEnding => const <CurreNotificationAction>[
        CurreNotificationAction.startCheckIn,
        CurreNotificationAction.snooze,
      ],
      CurreNotificationType.unlockTimeUp => const <CurreNotificationAction>[
        CurreNotificationAction.bringIntoSight,
      ],
      CurreNotificationType.proof => const <CurreNotificationAction>[
        CurreNotificationAction.addProof,
        CurreNotificationAction.snooze,
      ],
      CurreNotificationType.focus => const <CurreNotificationAction>[],
    };

/// The same reminder again, ten minutes after [now], for "Snooze 10 min";
/// null when [payload] isn't one of Curre's.
CurreReminder? snoozedReminder(String? payload, DateTime now) {
  if (payload == null) return null;
  try {
    final json = jsonDecode(payload);
    if (json is! Map<String, Object?> || json['version'] != 1) return null;
    final type = CurreNotificationType.values.byName(json['type']! as String);
    final destination = CurreNotificationDestination.values.byName(
      json['destination']! as String,
    );
    final at = now.add(LocalReminderService.snoozeFor);
    return CurreReminder(
      id: LocalReminderService.snoozeIdFor(at),
      type: type,
      title: json['title']! as String,
      body: json['body']! as String,
      scheduledAt: at,
      destination: destination,
      actions: defaultActionsFor(type),
      reference: json['reference'] as String?,
      languageCode: json['language'] as String? ?? 'en',
    );
  } on Object {
    return null;
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
       _policyOverride = policy;

  static const int _firstSessionId = 1101;

  /// The focus-end notification's id.
  static const int focusEndId = 1201;
  static const Duration planHeadsUp = Duration(minutes: 10);
  static const Duration proofDelay = Duration(minutes: 5);
  static const Duration snoozeFor = Duration(minutes: 10);

  /// How many days of "Plan your day" reminders are set ahead. Each one
  /// fires once, and Curre (which stays running as the home screen) sets
  /// them again each new day, so a few days ahead keeps them coming even if
  /// Home isn't opened for a day or two.
  static const int sessionDaysAhead = 3;

  /// Every id a "Plan your day" reminder can use: one per session per day
  /// ahead, 1101 to 1109.
  static List<int> get sessionReminderIds => <int>[
    for (var day = 0; day < sessionDaysAhead; day++)
      for (final session in SessionName.values) _sessionId(session, day),
  ];

  /// A snoozed reminder's id, clear of every other range.
  static int snoozeIdFor(DateTime at) =>
      800000 + at.millisecondsSinceEpoch.remainder(100000);

  final ReminderNotificationGateway _gateway;
  final DateTime Function() _now;
  final CurreNotificationPolicy? _policyOverride;

  CurreNotificationPolicy get policy =>
      _policyOverride ?? CurreNotificationPolicy();

  CurreNotificationPolicy _policyFor(Settings settings) =>
      _policyOverride ?? CurreNotificationPolicy.fromSettings(settings);

  /// Sets "Plan your day" for the next morning start (and the afternoon and
  /// evening starts too with [Settings.everySessionNudges]) and the
  /// [sessionDaysAhead] days after, skipping [restDays]: a rest day sends
  /// no reminders.
  Future<void> scheduleSessionReminders(
    Settings settings, {
    Iterable<LocalDate> restDays = const <LocalDate>[],
  }) async {
    await _gateway.initialize();
    final now = _now();
    final activePolicy = _policyFor(settings);
    final l10n = _localizationsFor(settings);
    final resting = restDays.toSet();
    for (final session in SessionName.values) {
      final start = settings.sessionStarts[session]!;
      var first = DateTime(
        now.year,
        now.month,
        now.day,
        start.hour,
        start.minute,
      );
      if (!first.isAfter(now)) {
        first = DateTime(
          first.year,
          first.month,
          first.day + 1,
          start.hour,
          start.minute,
        );
      }
      for (var day = 0; day < sessionDaysAhead; day++) {
        final id = _sessionId(session, day);
        await _gateway.cancelReminder(id);
        if (!activePolicy.allows(CurreNotificationType.checkIn)) continue;
        // One a day unless the user asked for every part of the day.
        if (session != SessionName.morning && !settings.everySessionNudges) {
          continue;
        }
        // Built from the date, not by adding hours, so a clock change
        // keeps the session's own time.
        final occurrence = DateTime(
          first.year,
          first.month,
          first.day + day,
          start.hour,
          start.minute,
        );
        if (resting.contains(LocalDate.fromLocalDateTime(occurrence))) {
          continue;
        }
        await _gateway.scheduleReminder(
          CurreReminder(
            id: id,
            type: CurreNotificationType.checkIn,
            title: l10n.planYourSession(session.localizedLabel(l10n)),
            body: l10n.oneSentenceHome,
            scheduledAt: activePolicy.nextAllowed(occurrence),
            destination: CurreNotificationDestination.checkIn,
            actions: defaultActionsFor(CurreNotificationType.checkIn),
            reference: session.name,
            languageCode: l10n.localeName,
          ),
        );
      }
    }
  }

  /// Drops every "Plan your day" reminder, for a phone that hasn't finished
  /// setting Curre up yet.
  Future<void> cancelSessionReminders() async {
    await _gateway.initialize();
    for (final id in sessionReminderIds) {
      await _gateway.cancelReminder(id);
    }
  }

  /// Sets the one notification for the day [settings]' focus ends, at that
  /// day's morning start (after quiet hours), or drops it when there is no
  /// focus, it is already over, or its switch is off.
  Future<void> scheduleFocusEnd(Settings settings) async {
    await _gateway.initialize();
    await _gateway.cancelReminder(focusEndId);
    final focus = settings.focus;
    final activePolicy = _policyFor(settings);
    if (focus == null || !activePolicy.allows(CurreNotificationType.focus)) {
      return;
    }
    final morning = settings.sessionStarts[SessionName.morning]!;
    final end = focus.endsOn;
    final at = DateTime(
      end.year,
      end.month,
      end.day,
      morning.hour,
      morning.minute,
    );
    if (!at.isAfter(_now())) return;
    final days = focus.lengthInDays;
    final l10n = _localizationsFor(settings);
    await _gateway.scheduleReminder(
      CurreReminder(
        id: focusEndId,
        type: CurreNotificationType.focus,
        title: l10n.focusDone,
        body: l10n.focusDoneNotification(l10n.daysCount(days)),
        scheduledAt: activePolicy.nextAllowed(at),
        destination: CurreNotificationDestination.home,
        actions: defaultActionsFor(CurreNotificationType.focus),
        reference: end.toJson(),
        languageCode: l10n.localeName,
      ),
    );
  }

  /// The ids of a plan's two reminders: its heads-up before the end, and
  /// the proof reminder after it.
  static (int headsUp, int proof) planReminderIds(String planId) {
    final seed = _stableId(planId);
    return (200000 + seed, 400000 + seed);
  }

  /// Drops a plan's heads-up and proof reminders, for a plan ended early
  /// with every task done: there is nothing left to remind about.
  Future<void> cancelPlanReminders(Plan plan) async {
    await _gateway.initialize();
    final (headsUpId, proofId) = planReminderIds(plan.id);
    await _gateway.cancelReminder(headsUpId);
    await _gateway.cancelReminder(proofId);
  }

  /// Sets a plan's heads-up and proof reminders; a plan made on one of
  /// [restDays] gets none.
  Future<void> schedulePlanReminders(
    Plan plan, {
    Settings? settings,
    Iterable<LocalDate> restDays = const <LocalDate>[],
  }) async {
    await _gateway.initialize();
    final activePolicy = settings == null ? policy : _policyFor(settings);
    final (headsUpId, proofId) = planReminderIds(plan.id);
    await _gateway.cancelReminder(headsUpId);
    await _gateway.cancelReminder(proofId);
    if (restDays.contains(plan.date)) return;

    final now = _now();
    final localEnd = plan.endsAt.toLocal();
    final l10n = settings == null
        ? curreLocalizationsFor(PlatformDispatcher.instance.locale.languageCode)
        : _localizationsFor(settings);
    if (activePolicy.allows(CurreNotificationType.planEnding)) {
      final proposed = localEnd.subtract(planHeadsUp);
      if (proposed.isAfter(now)) {
        await _gateway.scheduleReminder(
          CurreReminder(
            id: headsUpId,
            type: CurreNotificationType.planEnding,
            title: l10n.sessionAlmostDone(plan.session.localizedLabel(l10n)),
            body: l10n.planEndsTenMinutes,
            scheduledAt: activePolicy.nextAllowed(proposed),
            destination: CurreNotificationDestination.checkIn,
            actions: const <CurreNotificationAction>[
              CurreNotificationAction.startCheckIn,
              CurreNotificationAction.snooze,
            ],
            reference: plan.id,
            languageCode: l10n.localeName,
          ),
        );
      }
    }

    if (activePolicy.allows(CurreNotificationType.proof)) {
      final proposed = localEnd.add(proofDelay);
      if (proposed.isAfter(now)) {
        await _gateway.scheduleReminder(
          CurreReminder(
            id: proofId,
            type: CurreNotificationType.proof,
            title: l10n.addYourProof,
            body: l10n.proofNotificationBody,
            scheduledAt: activePolicy.nextAllowed(proposed),
            destination: CurreNotificationDestination.proof,
            actions: const <CurreNotificationAction>[
              CurreNotificationAction.addProof,
              CurreNotificationAction.snooze,
            ],
            reference: plan.id,
            languageCode: l10n.localeName,
          ),
        );
      }
    }
  }

  static int _sessionId(SessionName session, int day) =>
      _firstSessionId + day * SessionName.values.length + session.index;
}

AppLocalizations _localizationsFor(Settings settings) => curreLocalizationsFor(
  effectiveLanguageCode(
    preference: settings.languageCode,
    phoneLocale: PlatformDispatcher.instance.locale,
  ),
);

int _stableId(String value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash.remainder(190000);
}
