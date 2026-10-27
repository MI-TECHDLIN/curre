import 'dart:convert';

import 'package:curre/core/core.dart';
import 'package:curre/platform/local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('session reminders', () {
    test('use the three user session starts with rich actions', () async {
      final gateway = _FakeReminderGateway();
      final now = DateTime(2026, 10, 26, 8, 30);
      final service = LocalReminderService(gateway, now: () => now);
      final settings = Settings(
        sessionStarts: const <SessionName, LocalTime>{
          SessionName.morning: LocalTime(6, 45),
          SessionName.afternoon: LocalTime(13, 15),
          SessionName.evening: LocalTime(18, 30),
        },
      );

      await service.scheduleSessionReminders(settings);

      expect(gateway.initializeCalls, 1);
      expect(gateway.cancelled, <int>[1101, 1102, 1103]);
      expect(gateway.scheduled, hasLength(3));
      expect(
        gateway.scheduled.map((reminder) => reminder.scheduledAt),
        <DateTime>[
          DateTime(2026, 10, 27, 7),
          DateTime(2026, 10, 26, 13, 15),
          DateTime(2026, 10, 26, 18, 30),
        ],
      );
      for (final reminder in gateway.scheduled) {
        expect(reminder.type, CurreNotificationType.checkIn);
        expect(reminder.destination, CurreNotificationDestination.checkIn);
        expect(reminder.body, contains('on Home'));
        expect(reminder.actions, <CurreNotificationAction>[
          CurreNotificationAction.startCheckIn,
          CurreNotificationAction.snooze,
        ]);
      }
      expect(gateway.scheduled.first.title, 'Plan your morning');
      expect(gateway.scheduled.last.reference, 'evening');
    });

    test('moves reminders out of overnight quiet hours', () async {
      final gateway = _FakeReminderGateway();
      final service = LocalReminderService(
        gateway,
        now: () => DateTime(2026, 10, 26, 21),
      );

      await service.scheduleSessionReminders(Settings());

      expect(gateway.scheduled.first.scheduledAt, DateTime(2026, 10, 27, 7));
      expect(service.policy.isQuiet(DateTime(2026, 10, 26, 22, 30)), isTrue);
      expect(service.policy.isQuiet(DateTime(2026, 10, 27, 7)), isFalse);
    });

    test(
      'exposes a per-type policy hook while cancelling stale alarms',
      () async {
        final gateway = _FakeReminderGateway();
        final service = LocalReminderService(
          gateway,
          now: () => DateTime(2026, 10, 26, 8),
          policy: CurreNotificationPolicy(
            enabled: const <CurreNotificationType>{CurreNotificationType.proof},
          ),
        );

        await service.scheduleSessionReminders(Settings());

        expect(gateway.cancelled, <int>[1101, 1102, 1103]);
        expect(gateway.scheduled, isEmpty);
      },
    );

    test(
      'saved check-in choice cancels each alarm without replacing it',
      () async {
        final gateway = _FakeReminderGateway();
        final service = LocalReminderService(
          gateway,
          now: () => DateTime(2026, 10, 26, 8),
        );

        await service.scheduleSessionReminders(Settings(checkInNudges: false));

        expect(gateway.cancelled, <int>[1101, 1102, 1103]);
        expect(gateway.scheduled, isEmpty);
      },
    );
  });

  group('plan reminders', () {
    test('schedules a heads-up and proof prompt around plan end', () async {
      final gateway = _FakeReminderGateway();
      final now = DateTime.utc(2026, 10, 26, 12);
      final service = LocalReminderService(gateway, now: () => now);
      final plan = _plan(DateTime.utc(2026, 10, 26, 13));

      await service.schedulePlanReminders(plan);

      expect(gateway.cancelled, hasLength(2));
      expect(gateway.scheduled, hasLength(2));
      final headsUp = gateway.scheduled.first;
      final proof = gateway.scheduled.last;
      expect(headsUp.type, CurreNotificationType.planEnding);
      expect(headsUp.scheduledAt, DateTime(2026, 10, 26, 12, 50));
      expect(headsUp.title, 'Your afternoon is almost done');
      expect(headsUp.actions, contains(CurreNotificationAction.startCheckIn));
      expect(proof.type, CurreNotificationType.proof);
      expect(proof.scheduledAt, DateTime(2026, 10, 26, 13, 5));
      expect(proof.title, 'Add your proof');
      expect(proof.actions, <CurreNotificationAction>[
        CurreNotificationAction.addProof,
        CurreNotificationAction.snooze,
      ]);
      expect(proof.reference, plan.id);
    });

    test('does not schedule plan reminders after their useful time', () async {
      final gateway = _FakeReminderGateway();
      final end = DateTime.utc(2026, 10, 26, 13);
      final service = LocalReminderService(
        gateway,
        now: () => end.add(const Duration(minutes: 5)),
      );

      await service.schedulePlanReminders(_plan(end));

      expect(gateway.cancelled, hasLength(2));
      expect(gateway.scheduled, isEmpty);
    });

    test(
      'saved plan choices cancel both kinds and schedule only enabled ones',
      () async {
        final gateway = _FakeReminderGateway();
        final now = DateTime.utc(2026, 10, 26, 12);
        final service = LocalReminderService(gateway, now: () => now);

        await service.schedulePlanReminders(
          _plan(DateTime.utc(2026, 10, 26, 13)),
          settings: Settings(planEndingNudges: false, proofNudges: true),
        );

        expect(gateway.cancelled, hasLength(2));
        expect(gateway.scheduled, hasLength(1));
        expect(gateway.scheduled.single.type, CurreNotificationType.proof);
      },
    );
  });

  test('payload round-trips deep link, action, reference and proof note', () {
    final reminder = CurreReminder(
      id: 7,
      type: CurreNotificationType.proof,
      title: 'Add your proof',
      body: 'Mark what you finished.',
      scheduledAt: DateTime.utc(2026, 10, 26, 13),
      destination: CurreNotificationDestination.proof,
      actions: const <CurreNotificationAction>[
        CurreNotificationAction.addProof,
      ],
      reference: 'plan-7',
    );

    final payload = jsonDecode(reminder.payload) as Map<String, Object?>;
    expect(payload['version'], 1);
    expect(payload['destination'], 'proof');
    final intent = CurreNotificationIntent.fromPayload(
      reminder.payload,
      actionId: 'add_proof',
      note: '  Practised the whole chorus.  ',
    );

    expect(intent, isNotNull);
    expect(intent!.type, CurreNotificationType.proof);
    expect(intent.destination, CurreNotificationDestination.proof);
    expect(intent.action, CurreNotificationAction.addProof);
    expect(intent.reference, 'plan-7');
    expect(intent.note, 'Practised the whole chorus.');
    expect(CurreNotificationIntent.fromPayload('not-json'), isNull);
    expect(CurreNotificationAction.bringIntoSight.label, 'Bring back');
  });
}

Plan _plan(DateTime endsAt) => Plan(
  id: 'plan-afternoon-1',
  session: SessionName.afternoon,
  date: const LocalDate(2026, 10, 26),
  intention: 'Write the first page',
  apps: const <PlannedApp>[PlannedApp(packageName: 'com.google.android.keep')],
  endsAt: endsAt,
  source: PlanSource.manual,
);

class _FakeReminderGateway implements ReminderNotificationGateway {
  int initializeCalls = 0;
  final List<int> cancelled = <int>[];
  final List<CurreReminder> scheduled = <CurreReminder>[];

  @override
  Future<void> initialize() async => initializeCalls += 1;

  @override
  Future<void> cancelReminder(int id) async => cancelled.add(id);

  @override
  Future<void> scheduleReminder(CurreReminder reminder) async {
    scheduled.add(reminder);
  }
}
