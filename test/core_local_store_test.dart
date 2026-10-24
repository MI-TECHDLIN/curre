import 'dart:convert';

import 'package:curre/core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const utc = FixedOffsetTimeZone(Duration.zero);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'settings round-trip and corrupt settings recover to defaults',
    () async {
      final store = await CurreLocalStore.open();
      final settings = Settings(
        sessionStarts: const <SessionName, LocalTime>{
          SessionName.morning: LocalTime(5),
          SessionName.afternoon: LocalTime(13),
          SessionName.evening: LocalTime(19),
        },
        essentials: const <String>{'phone'},
        candidates: const <String>{'maps', 'youtube'},
        unlockMinutes: 6,
        threshold: 0.8,
      );
      await store.saveSettings(settings);

      expect(store.loadSettings().toJson(), settings.toJson());

      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('curre.settings.v1', '{bad json');
      final recovered = store.loadSettings();
      expect(recovered.sessionStarts[SessionName.morning], const LocalTime(4));
      expect(recovered.threshold, 0.7);
    },
  );

  test('today follows the 04:00 Curre day across midnight', () async {
    final store = await CurreLocalStore.open();
    final oldDay = _plan(const LocalDate(2026, 1, 1));
    final newDay = _plan(const LocalDate(2026, 1, 2));

    await store.saveTodayPlans(
      <Plan>[oldDay, newDay],
      now: DateTime.utc(2026, 1, 2, 1),
      timeZone: utc,
    );
    expect(
      await store.loadTodayPlans(
        now: DateTime.utc(2026, 1, 2, 1),
        timeZone: utc,
      ),
      hasLength(1),
    );
    expect(
      (await store.loadTodayPlans(
        now: DateTime.utc(2026, 1, 2, 1),
        timeZone: utc,
      )).single.date,
      const LocalDate(2026, 1, 1),
    );

    expect(
      await store.loadTodayPlans(
        now: DateTime.utc(2026, 1, 2, 5),
        timeZone: utc,
      ),
      isEmpty,
    );
  });

  test('active grant round-trip prunes at the exclusive expiry', () async {
    final store = await CurreLocalStore.open();
    final now = DateTime.utc(2026, 10, 24, 8);
    final active = _grant(
      'active',
      grantedAt: now.subtract(const Duration(minutes: 1)),
      expiresAt: now.add(const Duration(minutes: 1)),
    );
    final expired = _grant(
      'expired',
      grantedAt: now.subtract(const Duration(minutes: 5)),
      expiresAt: now,
    );

    await store.saveActiveGrants(<Grant>[active, expired], now: now);
    final loaded = await store.loadActiveGrants(now: now);

    expect(loaded.map((grant) => grant.packageName), <String>['active']);
    expect(loaded.single.grantedAt.isUtc, isTrue);
  });

  test('attempt log keeps exactly 30 days, round-trips, and clears', () async {
    final store = await CurreLocalStore.open();
    final now = DateTime.utc(2026, 1, 31, 12);
    final older = _attempt(DateTime.utc(2026, 1, 1, 11, 59), 'older');
    final edge = _attempt(DateTime.utc(2026, 1, 1, 12), 'edge');
    final recent = _attempt(DateTime.utc(2026, 1, 30), 'recent');

    await store.appendAttempt(older, now: older.at);
    await store.appendAttempt(edge, now: edge.at);
    await store.appendAttempt(recent, now: now);

    final loaded = await store.loadAttempts(now: now);
    expect(loaded.map((attempt) => attempt.packageName), <String>[
      'edge',
      'recent',
    ]);
    expect(loaded.first.outcome, UnlockOutcome.later);
    expect(loaded.first.kind, ReasonKind.browse);

    await store.clearHistory();
    expect(await store.loadAttempts(now: now), isEmpty);
  });

  test('opening the store prunes stale attempts immediately', () async {
    final now = DateTime.utc(2026, 1, 31, 12);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'curre.attempts.v1': jsonEncode(<Object?>[
        _attempt(DateTime.utc(2025, 12, 1), 'stale').toJson(),
        _attempt(DateTime.utc(2026, 1, 30), 'current').toJson(),
      ]),
    });

    await CurreLocalStore.open(now: now);

    final preferences = await SharedPreferences.getInstance();
    final saved = jsonDecode(
      preferences.getString('curre.attempts.v1')!,
    ) as List<Object?>;
    expect(saved, hasLength(1));
    expect((saved.single! as Map<String, dynamic>)['package'], 'current');
  });
}

Plan _plan(LocalDate date) => Plan(
  id: date.toString(),
  session: SessionName.evening,
  date: date,
  intention: 'read',
  apps: const <PlannedApp>[PlannedApp(packageName: 'reader')],
  endsAt: DateTime.utc(date.year, date.month, date.day + 1, 4),
  source: PlanSource.manual,
);

Grant _grant(
  String packageName, {
  required DateTime grantedAt,
  required DateTime expiresAt,
}) => Grant(
  packageName: packageName,
  reason: 'reason',
  task: null,
  grantedAt: grantedAt,
  expiresAt: expiresAt,
  source: GrantSource.clocked,
);

Attempt _attempt(DateTime at, String packageName) => Attempt(
  at: at,
  packageName: packageName,
  outcome: UnlockOutcome.later,
  confidence: 0.88,
  overridden: false,
  kind: ReasonKind.browse,
);
