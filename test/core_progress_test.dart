import 'dart:convert';

import 'package:curre/core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _utc = FixedOffsetTimeZone(Duration.zero);
const _day = LocalDate(2026, 10, 24);

final _schedule = SessionSchedule.fromSettings(Settings(), timeZone: _utc);

/// A morning plan with two doors (YouTube, Spotify), session from 04:00,
/// plan till 07:00.
final _morning = Plan(
  id: 'morning',
  session: SessionName.morning,
  date: _day,
  intention: 'Pray, then learn the G chord and play worship till 7',
  apps: const <PlannedApp>[
    PlannedApp(packageName: 'youtube', door: 'search'),
    PlannedApp(packageName: 'spotify', door: 'search'),
  ],
  endsAt: DateTime.utc(2026, 10, 24, 7),
  source: PlanSource.clocked,
);

/// An afternoon with no door at all, running to the session's end.
final _afternoon = Plan(
  id: 'afternoon',
  session: SessionName.afternoon,
  date: _day,
  intention: 'Pray at the mosque',
  apps: const <PlannedApp>[],
  endsAt: DateTime.utc(2026, 10, 24, 17),
  source: PlanSource.manual,
);

DoorUse _use(Plan plan, String package, int hour, [int minute = 0]) =>
    DoorUse.forPlan(plan, package, DateTime.utc(2026, 10, 24, hour, minute));

PlanProgress _progress(Plan plan, DateTime now, List<DoorUse> uses) =>
    PlanProgress.of(
      plan,
      startsAt: _schedule
          .current(plan.endsAt.subtract(const Duration(microseconds: 1)))
          .startsAt,
      now: now,
      uses: uses,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlanProgress', () {
    test('each door is a step and the plan running its course is one more', () {
      final start = _progress(_morning, DateTime.utc(2026, 10, 24, 4), []);
      expect(start.doorCount, 2);
      expect(start.doorsUsed, 0);
      expect(start.value, 0);

      final halfway = _progress(_morning, DateTime.utc(2026, 10, 24, 5, 30), [
        _use(_morning, 'youtube', 5, 13),
      ]);
      expect(halfway.timeRun, closeTo(.5, 1e-9));
      expect(halfway.value, closeTo((1 + .5) / 3, 1e-9));

      final done = _progress(_morning, DateTime.utc(2026, 10, 24, 7), [
        _use(_morning, 'youtube', 5, 13),
        _use(_morning, 'spotify', 6, 2),
      ]);
      expect(done.value, 1);
    });

    test('a plan with no doors fills as its time runs', () {
      final p = _progress(_afternoon, DateTime.utc(2026, 10, 24, 14, 30), []);
      expect(p.doorCount, 0);
      expect(p.value, closeTo(.5, 1e-9));
    });

    test('counts each of the plan\'s own apps once, and only by now', () {
      final other = Plan(
        id: 'other',
        session: SessionName.morning,
        date: _day,
        intention: 'x',
        apps: const <PlannedApp>[PlannedApp(packageName: 'youtube')],
        endsAt: DateTime.utc(2026, 10, 24, 7),
        source: PlanSource.manual,
      );
      final p = _progress(_morning, DateTime.utc(2026, 10, 24, 6), [
        _use(_morning, 'youtube', 5),
        _use(_morning, 'youtube', 5, 30),
        _use(other, 'youtube', 5, 40),
        _use(_morning, 'spotify', 6, 30),
      ]);
      expect(p.doorsUsed, 1);
    });

    test('time is clamped to the plan\'s window', () {
      expect(_progress(_morning, DateTime.utc(2026, 10, 24, 3), []).timeRun, 0);
      expect(_progress(_morning, DateTime.utc(2026, 10, 24, 9), []).timeRun, 1);
    });

    test('a use must belong to one of the plan\'s apps', () {
      expect(
        () => DoorUse.forPlan(_morning, 'instagram', DateTime.utc(2026)),
        throwsArgumentError,
      );
    });
  });

  group('DayProgress', () {
    test('nothing planned is an empty day', () {
      final day = DayProgress.of(
        plans: const <Plan>[],
        uses: const <DoorUse>[],
        schedule: _schedule,
        now: DateTime.utc(2026, 10, 24, 5),
      );
      expect(day.value, 0);
      expect(day.plans, 0);
      expect(DayProgress.empty.value, 0);
    });

    test('each session holds a third of the day', () {
      final uses = [
        _use(_morning, 'youtube', 5, 13),
        _use(_morning, 'spotify', 6, 2),
      ];
      final afterMorning = DayProgress.of(
        plans: [_morning],
        uses: uses,
        schedule: _schedule,
        now: DateTime.utc(2026, 10, 24, 12, 4),
      );
      expect(afterMorning.value, closeTo(1 / 3, 1e-9));
      expect(afterMorning.doorsUsed, 2);

      final evening = DayProgress.of(
        plans: [_morning, _afternoon],
        uses: uses,
        schedule: _schedule,
        now: DateTime.utc(2026, 10, 24, 17, 20),
      );
      expect(evening.value, closeTo(2 / 3, 1e-9));
      expect(evening.plans, 2);
    });

    test(
      'the furthest plan of a session counts, so a new plan never drains',
      () {
        final rest = Plan(
          id: 'rest-of-morning',
          session: SessionName.morning,
          date: _day,
          intention: 'Read Romans 8 on YouVersion till 9',
          apps: const <PlannedApp>[PlannedApp(packageName: 'bible')],
          endsAt: DateTime.utc(2026, 10, 24, 9),
          source: PlanSource.clocked,
        );
        final uses = [
          _use(_morning, 'youtube', 5, 13),
          _use(_morning, 'spotify', 6, 2),
        ];
        final now = DateTime.utc(2026, 10, 24, 7, 10);
        final before = DayProgress.of(
          plans: [_morning],
          uses: uses,
          schedule: _schedule,
          now: now,
        );
        final after = DayProgress.of(
          plans: [_morning, rest],
          uses: uses,
          schedule: _schedule,
          now: now,
        );
        expect(after.value, before.value);
      },
    );

    test('the level only rises through the day', () {
      // Uses made after `now` do not count yet, so one list serves every
      // moment of the day.
      final uses = [
        _use(_morning, 'youtube', 5, 13),
        _use(_morning, 'spotify', 6, 2),
      ];
      var last = 0.0;
      for (var minutes = 4 * 60; minutes <= 20 * 60; minutes += 7) {
        final now = DateTime.utc(2026, 10, 24).add(Duration(minutes: minutes));
        final value = DayProgress.of(
          plans: [_morning, _afternoon],
          uses: uses,
          schedule: _schedule,
          now: now,
        ).value;
        expect(value, greaterThanOrEqualTo(last), reason: 'at $now');
        last = value;
      }
      expect(last, closeTo(2 / 3, 1e-9));
    });
  });

  group('door uses in the local store', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('round-trip through JSON', () {
      final use = _use(_morning, 'youtube', 5, 13);
      final restored = DoorUse.fromJson(
        jsonDecode(jsonEncode(use.toJson())) as Map<String, Object?>,
      );
      expect(restored.toJson(), use.toJson());
      expect(restored.at.isUtc, isTrue);
    });

    test('are kept for the current Curre day only', () async {
      final store = await CurreLocalStore.open();
      final now = DateTime.utc(2026, 10, 24, 6);
      await store.recordDoorUse(
        _use(_morning, 'spotify', 6),
        now: now,
        timeZone: _utc,
      );
      await store.recordDoorUse(
        _use(_morning, 'youtube', 5, 13),
        now: now,
        timeZone: _utc,
      );
      final today = await store.loadTodayDoorUses(now: now, timeZone: _utc);
      expect(today.map((use) => use.packageName), <String>[
        'youtube',
        'spotify',
      ]);

      // The next Curre day starts at 04:00 and leaves yesterday's uses out.
      expect(
        await store.loadTodayDoorUses(
          now: DateTime.utc(2026, 10, 25, 4),
          timeZone: _utc,
        ),
        isEmpty,
      );
      final preferences = await SharedPreferences.getInstance();
      expect(jsonDecode(preferences.getString('curre.doorUses.v1')!), isEmpty);
    });

    test('a use from another day is not recorded', () async {
      final store = await CurreLocalStore.open();
      await store.recordDoorUse(
        _use(_morning, 'youtube', 5),
        now: DateTime.utc(2026, 10, 25, 5),
        timeZone: _utc,
      );
      expect(
        await store.loadTodayDoorUses(
          now: DateTime.utc(2026, 10, 25, 5),
          timeZone: _utc,
        ),
        isEmpty,
      );
    });
  });
}
