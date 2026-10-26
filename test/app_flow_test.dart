import 'dart:convert';
import 'dart:typed_data';

import 'package:curre/app/checkin_screen.dart';
import 'package:curre/app/curre_controller.dart';
import 'package:curre/app/hidden_apps_screen.dart';
import 'package:curre/app/home_screen.dart';
import 'package:curre/app/history_screen.dart';
import 'package:curre/app/settings_screen.dart';
import 'package:curre/app/unlock_gate_screen.dart';
import 'package:curre/core/core.dart';
import 'package:curre/design/design.dart';
import 'package:curre/doors/door_models.dart';
import 'package:curre/main.dart';
import 'package:curre/platform/home_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> phone(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets(
    'onboarding starts with the privacy promise and asks for a name',
    (tester) async {
      await phone(tester);
      final controller = _controller(onboardingComplete: false);
      await tester.pumpWidget(CurreApp(controller: controller));

      expect(find.text('Sent to Clocked (Rezolve.ai)'), findsOneWidget);
      expect(find.text('Try the gate first'), findsNothing);
      expect(find.text('Not yet · try the gate'), findsNothing);
      await tester.tap(find.text('That’s fair'));
      await tester.pumpAndSettle();
      expect(find.text('What should Curre call you?'), findsOneWidget);
    },
  );

  testWidgets('onboarding completes every essential step then opens check-in', (
    tester,
  ) async {
    await phone(tester);
    final controller = _controller(onboardingComplete: false);
    await tester.pumpWidget(CurreApp(controller: controller));

    await tester.tap(find.text('That’s fair'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.pump();
    await tester.tap(find.text('Use this name'));
    await tester.pumpAndSettle();
    expect(find.byType(AvatarPicker), findsOneWidget);
    await tester.tap(
      find.bySemanticsLabel(RegExp('Avatar 3, light skin, soft curls')),
    );
    await tester.pump();
    await tester.tap(find.text('Use this profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set Curre as Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allow notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep these in sight'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use these candidates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start my first check-in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.onboardingComplete, isTrue);
    expect(controller.settings.displayName, 'Ada');
    expect(controller.settings.avatarId, 'avatar-03');
    expect(find.byType(CheckinScreen), findsOneWidget);
    expect(find.text('Morning check-in'), findsOneWidget);
  });

  testWidgets('Home has the fixed dock and profile sheet', (tester) async {
    await phone(tester);
    final controller = _controller();
    await tester.pumpWidget(CurreApp(controller: controller));
    await tester.pump();

    expect(find.text('Good morning, Chidi'), findsOneWidget);
    final homeAvatar = tester.widget<Avatar>(find.byType(Avatar));
    expect(homeAvatar.avatarId, isNull);
    expect(homeAvatar.motion, AvatarMotion.reactOnce);
    for (final label in <String>['Phone', 'Messages', 'Settings', 'Curre']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('C'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(AvatarPicker), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('Avatar 1, light skin')));
    await tester.pump();
    expect(controller.settings.avatarId, 'avatar-01');
    expect(find.text('Proof days'), findsOneWidget);
    expect(find.text('Best run'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('History'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);
  });

  testWidgets('Home opens check-in and offline planning becomes a checklist', (
    tester,
  ) async {
    await phone(tester);
    final controller = _controller();
    await tester.pumpWidget(CurreApp(controller: controller));
    await tester.pump();
    await tester.tap(find.text('What’s this morning for?'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CheckinScreen), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('checkin-intention')),
      'Learn the G chord on YouTube till 7',
    );
    await tester.pump();
    await tester.tap(find.text('Set my morning'));
    for (
      var i = 0;
      i < 10 && find.text('Choose the apps yourself').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Choose the apps yourself'), findsOneWidget);
  });

  testWidgets('Clocked check-in reveals doors and returns the plan to Home', (
    tester,
  ) async {
    await phone(tester);
    var deploymentAwake = false;
    final api = CurreApiClient(
      baseUrl: Uri.parse('https://curre.test'),
      appKey: 'test-key',
      httpClient: MockClient((request) async {
        if (request.method == 'GET') {
          expect(request.url.path, '/healthz');
          deploymentAwake = true;
          return http.Response('{}', 200);
        }
        expect(request.url.path, '/v1/plan');
        expect(deploymentAwake, isTrue);
        return http.Response(
          jsonEncode(<String, Object?>{
            'apps': <Object?>[
              <String, Object?>{
                'id': 'com.google.android.youtube',
                'query': <String, Object?>{
                  'text': 'G chord',
                  'start': 10,
                  'end': 17,
                },
              },
            ],
            'end_phrase': <String, Object?>{
              'text': 'till 7',
              'start': 29,
              'end': 35,
            },
            'usage': <String, Object?>{'credits': 18, 'model_ms': 420},
          }),
          200,
        );
      }),
    );
    final controller = _controller(api: api);
    await tester.pumpWidget(CurreApp(controller: controller));
    await tester.pump();
    await tester.tap(find.text('What’s this morning for?'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(CheckinScreen), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('checkin-intention')),
      'Learn the G chord on YouTube till 7',
    );
    await tester.pump();
    await tester.tap(find.text('Set my morning'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Here’s what comes into sight'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.text('→ Search “G chord”'), findsOneWidget);
    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();
    expect(find.text('Your morning'), findsOneWidget);
    expect(controller.lastPlanCall?.usage?.credits, 18);
  });

  testWidgets(
    'check-in recovers when the first plan request is transiently unavailable',
    (tester) async {
      await phone(tester);
      var warmupCalls = 0;
      var planCalls = 0;
      final api = CurreApiClient(
        baseUrl: Uri.parse('https://curre.test'),
        appKey: 'test-key',
        planRetryDelay: Duration.zero,
        httpClient: MockClient((request) async {
          if (request.method == 'GET') {
            warmupCalls++;
            return http.Response('{}', 200);
          }
          planCalls++;
          if (planCalls == 1) return http.Response('waking', 503);
          return http.Response(
            jsonEncode(<String, Object?>{
              'apps': <Object?>[
                <String, Object?>{
                  'id': 'com.google.android.youtube',
                  'query': <String, Object?>{
                    'text': 'G chord',
                    'start': 10,
                    'end': 17,
                  },
                },
              ],
              'end_phrase': null,
              'usage': <String, Object?>{'credits': 4, 'model_ms': 86},
            }),
            200,
          );
        }),
      );
      final controller = _controller(api: api);
      await tester.pumpWidget(CurreApp(controller: controller));
      await tester.pump();
      await tester.tap(find.text('What’s this morning for?'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.enterText(
        find.byKey(const Key('checkin-intention')),
        'Learn the G chord on YouTube till 7',
      );
      await tester.pump();
      await tester.tap(find.text('Set my morning'));

      for (
        var i = 0;
        i < 10 && find.text('Here’s what comes into sight').evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(warmupCalls, 1);
      expect(planCalls, 2);
      expect(find.text('Here’s what comes into sight'), findsOneWidget);
      expect(find.text('Choose the apps yourself'), findsNothing);
    },
  );

  testWidgets('hidden apps are alphabetical text and navigate to the gate', (
    tester,
  ) async {
    await phone(tester);
    final controller = _controller();
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: HiddenAppsScreen(controller: controller),
      ),
    );

    expect(find.text('Out of sight'), findsOneWidget);
    expect(find.text('Chrome'), findsOneWidget);
    await tester.tap(find.text('Chrome'));
    await tester.pumpAndSettle();
    expect(find.text('Why open Chrome now?'), findsOneWidget);
    expect(find.byKey(const Key('unlock-reason')), findsOneWidget);
  });

  testWidgets('unlock gate renders all five outcome states', (tester) async {
    await phone(tester);
    final controller = _controller();
    final app = controller.apps.firstWhere((app) => app.label == 'YouTube');
    final cases = <(UnlockResponse, String)>[
      (
        const UnlockResponse(
          outcome: UnlockOutcome.open,
          kind: ReasonKind.task,
          confidence: .91,
          target: SourceSpan(text: 'capo tutorial', start: 6, end: 19),
          minutes: 15,
        ),
        'Opens at YouTube → Search “capo tutorial”',
      ),
      (
        const UnlockResponse(
          outcome: UnlockOutcome.later,
          kind: ReasonKind.browse,
          confidence: .92,
        ),
        'Not now.',
      ),
      (
        const UnlockResponse(
          outcome: UnlockOutcome.specify,
          kind: ReasonKind.unclear,
          confidence: .55,
        ),
        'What exactly will you do?',
      ),
      (
        const UnlockResponse(
          outcome: UnlockOutcome.flagged,
          guard: GuardInfo(
            category: 'instruction override',
            quote: SourceSpan(text: 'ignore your rules', start: 0, end: 17),
          ),
        ),
        'This reason tried to steer the gate',
      ),
      (
        const UnlockResponse.unavailable(),
        'No answer · opening anyway, in a minute',
      ),
    ];

    for (final item in cases) {
      await tester.pumpWidget(
        MaterialApp(
          theme: curreTheme(Brightness.light),
          home: UnlockGateScreen(
            key: ValueKey(item.$1.outcome),
            controller: controller,
            app: app,
            initialReason: item.$1.outcome == UnlockOutcome.open
                ? 'watch capo tutorial'
                : 'just checking for updates',
            initialResponse: item.$1,
            overrideDuration: const Duration(minutes: 5),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(item.$2), findsWidgets);
    }
  });

  testWidgets('leaving the gate cancels a running override', (tester) async {
    await phone(tester);
    final platform = _FakeDoorPlatform(CurreController.fallbackApps);
    final controller = _controller(platform: platform);
    final app = controller.apps.firstWhere((app) => app.label == 'Instagram');
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => UnlockGateScreen(
                  controller: controller,
                  app: app,
                  initialReason: 'just checking for updates',
                  initialResponse: const UnlockResponse(
                    outcome: UnlockOutcome.later,
                    kind: ReasonKind.browse,
                    confidence: .9,
                  ),
                  overrideDuration: const Duration(seconds: 1),
                ),
              ),
            ),
            child: const Text('Open gate'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open gate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open after 60 s'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(seconds: 2));
    expect(platform.launches, 0);
  });

  testWidgets('an open result grants, launches and returns from the gate', (
    tester,
  ) async {
    await phone(tester);
    final platform = _FakeDoorPlatform(CurreController.fallbackApps);
    final controller = _controller(platform: platform);
    final app = controller.apps.firstWhere((app) => app.label == 'YouTube');
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => UnlockGateScreen(
                  controller: controller,
                  app: app,
                  initialReason: '15 min to watch the capo tutorial',
                  initialResponse: const UnlockResponse(
                    outcome: UnlockOutcome.open,
                    kind: ReasonKind.task,
                    confidence: .94,
                    target: SourceSpan(
                      text: 'capo tutorial',
                      start: 20,
                      end: 33,
                    ),
                    minutes: 15,
                  ),
                ),
              ),
            ),
            child: const Text('Open gate'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open gate'));
    await tester.pumpAndSettle();
    expect(find.text('Open YouTube → Search “capo tutorial”'), findsOneWidget);
    await tester.tap(find.text('Open YouTube → Search “capo tutorial”'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Open gate'), findsOneWidget);
    expect(platform.launches, 1);
    expect(controller.grants.single.source, GrantSource.clocked);
    expect(
      controller.grants.single.expiresAt.difference(controller.now),
      const Duration(minutes: 15),
    );
  });

  testWidgets(
    'a finished override grants, launches and returns from the gate',
    (tester) async {
      await phone(tester);
      final platform = _FakeDoorPlatform(CurreController.fallbackApps);
      final controller = _controller(platform: platform);
      final app = controller.apps.firstWhere((app) => app.label == 'Instagram');
      await tester.pumpWidget(
        MaterialApp(
          theme: curreTheme(Brightness.light),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => UnlockGateScreen(
                    controller: controller,
                    app: app,
                    initialReason: 'just checking for updates',
                    initialResponse: const UnlockResponse(
                      outcome: UnlockOutcome.later,
                      kind: ReasonKind.browse,
                      confidence: .9,
                    ),
                    overrideDuration: const Duration(milliseconds: 300),
                  ),
                ),
              ),
              child: const Text('Open gate'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open gate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open after 60 s'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Open gate'), findsOneWidget);
      expect(platform.launches, 1);
      expect(controller.grants.single.source, GrantSource.override);
    },
  );

  testWidgets('Curre settings exposes telemetry, licences and history only', (
    tester,
  ) async {
    await phone(tester);
    final controller = _controller();
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: SettingsScreen(controller: controller),
      ),
    );
    expect(find.text('Curre settings'), findsOneWidget);
    expect(find.text('Judge demo mode'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Under the hood'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Under the hood'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Clear history'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Clear history'), findsOneWidget);
  });

  testWidgets('History has a friendly empty state and Prooflight slot', (
    tester,
  ) async {
    await phone(tester);
    final controller = _controller();
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: HistoryScreen(controller: controller),
      ),
    );

    expect(find.text('0 of 21 sessions started with a plan'), findsOneWidget);
    expect(find.text('Proof days · —'), findsOneWidget);
    expect(find.text('A quiet start.'), findsOneWidget);
  });

  testWidgets('History groups populated plans, grants and unlock attempts', (
    tester,
  ) async {
    await phone(tester);
    final controller = _controller();
    _addHistory(controller);
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.dark),
        home: HistoryScreen(controller: controller),
      ),
    );

    expect(find.text('1 of 21 sessions started with a plan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Learn the G chord on YouTube till 7'),
      300,
    );
    expect(find.text('Morning check-in'), findsOneWidget);
    expect(find.text('Learn the G chord on YouTube till 7'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('just checking what Tolu posted'),
      300,
    );
    expect(find.text('Later'), findsOneWidget);
    expect(find.text('Browsing'), findsOneWidget);
    expect(find.text('60 s override used'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Instagram came into sight'),
      300,
    );
    expect(find.text('Instagram came into sight'), findsOneWidget);
  });

  testWidgets('Clear history in settings empties the History screen', (
    tester,
  ) async {
    await phone(tester);
    final controller = _controller();
    _addHistory(controller);
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: SettingsScreen(controller: controller),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Clear history'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Clear history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Clear history'));
    await tester.pumpAndSettle();

    expect(controller.historyPlans, isEmpty);
    expect(controller.historyGrants, isEmpty);
    expect(controller.historyAttempts, isEmpty);

    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: HistoryScreen(controller: controller),
      ),
    );
    expect(find.text('A quiet start.'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'production screens fit 360 dp at 200% text in ${brightness.name}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 740));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = _controller();
        controller.settings = controller.settings.copyWith(
          displayName: 'Chidiebere Nwachukwu-Okafor',
          essentials: <String>{
            ...controller.settings.essentials,
            'com.google.android.gm',
          },
        );
        controller.plans = <Plan>[
          Plan(
            id: 'layout-plan',
            session: SessionName.morning,
            date: const LocalDate(2026, 10, 24),
            intention: 'Learn a careful G chord lesson on YouTube, then play worship on Spotify before breakfast.',
            apps: const <PlannedApp>[
              PlannedApp(packageName: 'com.google.android.youtube'),
              PlannedApp(packageName: 'com.spotify.music'),
            ],
            endsAt: DateTime.utc(2026, 10, 24, 9),
            source: PlanSource.clocked,
          ),
        ];
        controller.grants = <Grant>[
          Grant(
            packageName: 'com.instagram.android',
            reason: 'reply Ada about the Sunday rehearsal details',
            task: 'Ada and the Sunday rehearsal details',
            grantedAt: DateTime.utc(2026, 10, 24, 5, 28),
            expiresAt: DateTime.utc(2026, 10, 24, 5, 38),
            source: GrantSource.clocked,
            kind: ReasonKind.person,
          ),
        ];

        Future<void> show(Widget screen) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: curreTheme(brightness),
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(360, 740),
                  textScaler: TextScaler.linear(2),
                ),
                child: screen,
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        }

        await show(HomeScreen(controller: controller));
        await show(CheckinScreen(controller: controller));
        await show(HiddenAppsScreen(controller: controller));
        await show(HistoryScreen(controller: controller));
        await show(SettingsScreen(controller: controller));
        await show(ProfileSheet(controller: controller));
        await show(
          UnlockGateScreen(
            controller: controller,
            app: const LaunchableApp(
              packageName: 'com.example.long',
              label: 'A Very Long Social Application Name',
            ),
            initialReason: 'just checking what everyone posted today',
            initialResponse: const UnlockResponse(
              outcome: UnlockOutcome.later,
              kind: ReasonKind.browse,
              confidence: .91,
            ),
          ),
        );
      },
    );
  }
}

void _addHistory(CurreController controller) {
  controller.historyPlans = <Plan>[
    Plan(
      id: 'history-plan',
      session: SessionName.morning,
      date: const LocalDate(2026, 10, 24),
      intention: 'Learn the G chord on YouTube till 7',
      apps: const <PlannedApp>[
        PlannedApp(
          packageName: 'com.google.android.youtube',
          query: SourceSpan(text: 'G chord', start: 10, end: 17),
        ),
      ],
      endsAt: DateTime.utc(2026, 10, 24, 7),
      source: PlanSource.clocked,
    ),
  ];
  controller.historyAttempts = <Attempt>[
    Attempt(
      at: DateTime.utc(2026, 10, 24, 5, 20),
      packageName: 'com.instagram.android',
      outcome: UnlockOutcome.later,
      confidence: .92,
      overridden: true,
      kind: ReasonKind.browse,
      reason: 'just checking what Tolu posted',
      highlights: const <SourceSpan>[
        SourceSpan(text: 'what Tolu posted', start: 14, end: 30),
      ],
    ),
  ];
  controller.historyGrants = <Grant>[
    Grant(
      packageName: 'com.instagram.android',
      reason: 'reply Ada about rehearsal',
      task: 'Ada',
      grantedAt: DateTime.utc(2026, 10, 24, 5, 10),
      expiresAt: DateTime.utc(2026, 10, 24, 5, 15),
      source: GrantSource.clocked,
      kind: ReasonKind.person,
    ),
  ];
}

CurreController _controller({
  bool onboardingComplete = true,
  _FakeDoorPlatform? platform,
  CurreApiClient? api,
}) {
  final launcher = platform ?? _FakeDoorPlatform(CurreController.fallbackApps);
  final essentials = <String>{
    'com.google.android.dialer',
    'com.google.android.apps.messaging',
    'com.android.settings',
  };
  final candidates = CurreController.fallbackApps
      .where((app) => !essentials.contains(app.packageName))
      .take(10)
      .map((app) => app.packageName)
      .toSet();
  return CurreController(
    launcher: launcher,
    homePlatform: _FakeHomePlatform(),
    api: api,
    settings: Settings(
      displayName: 'Chidi',
      essentials: essentials,
      candidates: candidates,
    ),
    apps: CurreController.fallbackApps,
    onboardingComplete: onboardingComplete,
    now: () => DateTime.utc(2026, 10, 24, 5, 30),
  );
}

class _FakeHomePlatform implements HomePlatformGateway {
  @override
  Future<bool> isDefaultHome() async => true;

  @override
  Future<void> setHomeSurfaceActive(bool active) async {}
}

class _FakeDoorPlatform implements DoorPlatform {
  _FakeDoorPlatform(this.apps);

  final List<LaunchableApp> apps;
  int launches = 0;

  @override
  Future<Uint8List?> getIcon(String packageName) async => null;

  @override
  Future<List<AppShortcut>> getConversationShortcuts(
    String packageName,
  ) async => <AppShortcut>[];

  @override
  Future<List<AppShortcut>> getStaticShortcuts(String packageName) async =>
      <AppShortcut>[];

  @override
  Future<bool> hasShortcutHostPermission() async => false;

  @override
  Future<bool> launch(String packageName) async {
    launches += 1;
    return true;
  }

  @override
  Future<bool> launchQueryDoor(String doorId, String query) async {
    launches += 1;
    return true;
  }

  @override
  Future<List<LaunchableApp>> listApps() async => apps;

  @override
  Future<bool> requestHomeRole() async => true;

  @override
  Future<bool> startShortcut(String packageName, String shortcutId) async =>
      false;
}
