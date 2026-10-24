import 'package:curre/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const zone = FixedOffsetTimeZone(Duration.zero);
  final settings = Settings(essentials: const <String>{'phone'});

  Plan plan({DateTime? endsAt}) => Plan(
    id: 'p1',
    session: SessionName.morning,
    date: const LocalDate(2026, 10, 24),
    intention: 'learn',
    apps: const <PlannedApp>[PlannedApp(packageName: 'youtube')],
    endsAt: endsAt ?? DateTime.utc(2026, 10, 24, 8),
    source: PlanSource.clocked,
  );

  test('essentials are visible without a plan and regardless of grants', () {
    final state = LauncherState(settings: settings, grants: const <Grant>[]);
    expect(
      isVisible('phone', DateTime.utc(2026, 10, 24, 5), state, timeZone: zone),
      isTrue,
    );
    expect(
      isVisible(
        'youtube',
        DateTime.utc(2026, 10, 24, 5),
        state,
        timeZone: zone,
      ),
      isFalse,
    );
  });

  test('plan end is exclusive', () {
    final state = LauncherState(
      settings: settings,
      plan: plan(),
      grants: const <Grant>[],
    );
    expect(
      isVisible(
        'youtube',
        DateTime.utc(2026, 10, 24, 7, 59),
        state,
        timeZone: zone,
      ),
      isTrue,
    );
    expect(
      isVisible(
        'youtube',
        DateTime.utc(2026, 10, 24, 8),
        state,
        timeZone: zone,
      ),
      isFalse,
    );
  });

  test('session rollover hides a stale plan even if its end is malformed', () {
    final state = LauncherState(
      settings: settings,
      plan: plan(endsAt: DateTime.utc(2026, 10, 24, 14)),
      grants: const <Grant>[],
    );
    expect(
      isVisible(
        'youtube',
        DateTime.utc(2026, 10, 24, 12),
        state,
        timeZone: zone,
      ),
      isFalse,
    );
  });

  test('grant expiry is exclusive and independent of the plan', () {
    final grant = Grant(
      packageName: 'maps',
      reason: 'find church',
      task: 'church',
      grantedAt: DateTime.utc(2026, 10, 24, 5),
      expiresAt: DateTime.utc(2026, 10, 24, 5, 5),
      source: GrantSource.clocked,
    );
    final state = LauncherState(settings: settings, grants: <Grant>[grant]);
    expect(
      isVisible(
        'maps',
        DateTime.utc(2026, 10, 24, 5, 4, 59),
        state,
        timeZone: zone,
      ),
      isTrue,
    );
    expect(
      isVisible(
        'maps',
        DateTime.utc(2026, 10, 24, 5, 5),
        state,
        timeZone: zone,
      ),
      isFalse,
    );
  });

  test('visiblePackages returns only apps Home should render', () {
    final grant = Grant(
      packageName: 'maps',
      reason: 'directions',
      task: null,
      grantedAt: DateTime.utc(2026, 10, 24, 5),
      expiresAt: DateTime.utc(2026, 10, 24, 5, 10),
      source: GrantSource.override,
    );
    final state = LauncherState(
      settings: settings,
      plan: plan(),
      grants: <Grant>[grant],
    );
    const apps = <AppEntry>[
      AppEntry(
        packageName: 'phone',
        label: 'Phone',
        isEssential: true,
        isCandidate: false,
      ),
      AppEntry(
        packageName: 'youtube',
        label: 'YouTube',
        isEssential: false,
        isCandidate: true,
      ),
      AppEntry(
        packageName: 'maps',
        label: 'Maps',
        isEssential: false,
        isCandidate: true,
      ),
      AppEntry(
        packageName: 'instagram',
        label: 'Instagram',
        isEssential: false,
        isCandidate: false,
      ),
    ];

    expect(
      visiblePackages(
        apps,
        DateTime.utc(2026, 10, 24, 5, 1),
        state,
        timeZone: zone,
      ),
      <String>{'phone', 'youtube', 'maps'},
    );
  });
}
