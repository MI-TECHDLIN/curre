import 'dart:convert';

import 'package:curre/core/core.dart';
import 'package:curre/platform/local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  group('session reminders', () {
    test('use the three user session starts with rich actions', () async {
      final gateway = _FakeReminderGateway();
      final now = DateTime(2026, 10, 26, 8, 30);
      final service = LocalReminderService(gateway, now: () => now);
      final settings = Settings(
        everySessionNudges: true,
        sessionStarts: const <SessionName, LocalTime>{
          SessionName.morning: LocalTime(6, 45),
          SessionName.afternoon: LocalTime(13, 15),
          SessionName.evening: LocalTime(18, 30),
        },
      );

      await service.scheduleSessionReminders(settings);

      expect(gateway.initializeCalls, 1);
      expect(
        gateway.cancelled.toSet(),
        LocalReminderService.sessionReminderIds.toSet(),
      );
      // Three days ahead, so they keep coming while Home stays open.
      expect(gateway.scheduled, hasLength(9));
      expect(
        gateway.scheduled.take(3).map((reminder) => reminder.scheduledAt),
        <DateTime>[
          DateTime(2026, 10, 27, 7),
          DateTime(2026, 10, 28, 7),
          DateTime(2026, 10, 29, 7),
        ],
      );
      expect(
        gateway.scheduled
            .where((reminder) => reminder.reference == 'afternoon')
            .map((reminder) => reminder.scheduledAt),
        <DateTime>[
          DateTime(2026, 10, 26, 13, 15),
          DateTime(2026, 10, 27, 13, 15),
          DateTime(2026, 10, 28, 13, 15),
        ],
      );
      expect(
        gateway.scheduled.map((reminder) => reminder.id).toSet(),
        hasLength(9),
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
      // New setups get one "Plan your day" a day: the morning's.
      expect(
        gateway.scheduled.map((reminder) => reminder.reference).toSet(),
        <String>{'morning'},
      );
      expect(gateway.scheduled, hasLength(3));
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

        expect(
          gateway.cancelled.toSet(),
          LocalReminderService.sessionReminderIds.toSet(),
        );
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

        expect(
          gateway.cancelled.toSet(),
          LocalReminderService.sessionReminderIds.toSet(),
        );
        expect(gateway.scheduled, isEmpty);
      },
    );
  });

  group('rest days and the focus', () {
    test('a rest day sends no "Plan your day"', () async {
      final gateway = FakeReminderGateway();
      final service = LocalReminderService(
        gateway,
        now: () => DateTime(2026, 10, 26, 8),
      );
      await service.scheduleSessionReminders(
        Settings(everySessionNudges: true),
        restDays: const [LocalDate(2026, 10, 27)],
      );
      final days = gateway.scheduled
          .map((reminder) => LocalDate.fromLocalDateTime(reminder.scheduledAt))
          .toSet();
      expect(days, isNot(contains(const LocalDate(2026, 10, 27))));
      expect(days, contains(const LocalDate(2026, 10, 26)));
      expect(days, contains(const LocalDate(2026, 10, 28)));
    });

    test('a plan on a rest day gets no heads-up or proof reminder', () async {
      final gateway = FakeReminderGateway();
      final service = LocalReminderService(
        gateway,
        now: () => DateTime.utc(2026, 10, 26, 12),
      );
      await service.schedulePlanReminders(
        _plan(DateTime.utc(2026, 10, 26, 13)),
        restDays: const [LocalDate(2026, 10, 26)],
      );
      expect(gateway.cancelled, hasLength(2));
      expect(gateway.scheduled, isEmpty);
    });

    test('the focus end comes on the end date’s morning', () async {
      final gateway = FakeReminderGateway();
      final service = LocalReminderService(
        gateway,
        now: () => DateTime(2026, 10, 26, 8),
      );
      final settings = Settings(
        sessionStarts: const <SessionName, LocalTime>{
          SessionName.morning: LocalTime(8),
          SessionName.afternoon: LocalTime(12),
          SessionName.evening: LocalTime(17),
        },
        focus: FocusPeriod(
          purpose: FocusPurpose.exams,
          startsOn: const LocalDate(2026, 10, 26),
          endsOn: const LocalDate(2026, 11, 2),
        ),
      );
      await service.scheduleFocusEnd(settings);
      final reminder = gateway.scheduled.single;
      expect(reminder.id, LocalReminderService.focusEndId);
      expect(reminder.scheduledAt, DateTime(2026, 11, 2, 8));
      expect(reminder.body, 'See how your 7 days went, and choose what comes next.');
      expect(reminder.destination, CurreNotificationDestination.home);
      expect(reminder.actions, isEmpty);

      gateway.scheduled.clear();
      await service.scheduleFocusEnd(settings.copyWith(focusNudges: false));
      await service.scheduleFocusEnd(settings.copyWith(clearFocus: true));
      expect(gateway.scheduled, isEmpty);
      expect(
        gateway.cancelled.where((id) => id == LocalReminderService.focusEndId),
        hasLength(3),
      );
    });

    test('nothing is set before setup is done', () async {
      final gateway = FakeReminderGateway();
      final controller = fakeController(
        onboardingComplete: false,
        reminders: LocalReminderService(
          gateway,
          now: () => DateTime(2026, 10, 26, 6, 40),
        ),
      );
      await controller.requestNotifications();
      expect(gateway.pendingOf(CurreNotificationType.checkIn), isEmpty);
      expect(
        gateway.cancelled.toSet(),
        containsAll(LocalReminderService.sessionReminderIds),
      );
    });

    test('a new day sets the next reminders again', () async {
      final gateway = FakeReminderGateway();
      var now = DateTime(2026, 10, 26, 6, 40);
      final controller = fakeController(
        clock: () => now,
        reminders: LocalReminderService(gateway, now: () => now),
      );
      await controller.refresh();
      final first = gateway.scheduled.length;
      expect(first, greaterThan(0));
      await controller.refresh();
      expect(gateway.scheduled.length, first, reason: 'same day: unchanged');

      now = DateTime(2026, 10, 27, 9);
      await controller.refresh();
      expect(gateway.scheduled.length, greaterThan(first));
      expect(
        gateway
            .pendingOf(CurreNotificationType.checkIn)
            .first
            .scheduledAt,
        DateTime(2026, 10, 28, 7),
      );
    });
  });

  group('snooze', () {
    test('brings the same reminder back in ten minutes', () {
      final reminder = CurreReminder(
        id: 1101,
        type: CurreNotificationType.checkIn,
        title: 'Plan your morning',
        body: 'One sentence.',
        scheduledAt: DateTime(2026, 10, 26, 7),
        destination: CurreNotificationDestination.checkIn,
        actions: defaultActionsFor(CurreNotificationType.checkIn),
        reference: 'morning',
      );
      final at = DateTime(2026, 10, 26, 7, 2);
      final snoozed = snoozedReminder(reminder.payload, at)!;
      expect(snoozed.scheduledAt, DateTime(2026, 10, 26, 7, 12));
      expect(snoozed.title, 'Plan your morning');
      expect(snoozed.destination, CurreNotificationDestination.checkIn);
      expect(snoozed.reference, 'morning');
      expect(snoozed.actions, contains(CurreNotificationAction.snooze));
      expect(snoozed.id, inInclusiveRange(800000, 899999));
      expect(snoozedReminder('nope', at), isNull);
      expect(snoozedReminder(null, at), isNull);
    });

    test('every kind of notification has its actions', () {
      for (final type in CurreNotificationType.values) {
        expect(() => defaultActionsFor(type), returnsNormally);
      }
      expect(defaultActionsFor(CurreNotificationType.focus), isEmpty);
    });
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

    test('an ended plan drops both of its reminders', () async {
      final gateway = _FakeReminderGateway();
      final now = DateTime.utc(2026, 10, 26, 12);
      final service = LocalReminderService(gateway, now: () => now);
      final plan = _plan(DateTime.utc(2026, 10, 26, 13));

      await service.schedulePlanReminders(plan);
      gateway.cancelled.clear();
      await service.cancelPlanReminders(plan);

      final (headsUp, proof) = LocalReminderService.planReminderIds(plan.id);
      expect(gateway.cancelled, <int>[headsUp, proof]);
      expect(gateway.scheduled.map((reminder) => reminder.id), <int>[
        headsUp,
        proof,
      ]);
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
