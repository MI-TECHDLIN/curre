import 'dart:convert';

import 'package:curre/app/app_widgets.dart';
import 'package:curre/app/checkin_screen.dart';
import 'package:curre/app/completion_sheet.dart';
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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/voice_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> phone(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  test('sample app inventory is never used on Android', () {
    expect(
      CurreController.usesReviewInventoryFixtures(
        web: false,
        platform: TargetPlatform.android,
        debugMode: true,
      ),
      isFalse,
    );
    expect(
      CurreController.usesReviewInventoryFixtures(
        web: true,
        platform: TargetPlatform.android,
        debugMode: false,
      ),
      isTrue,
    );
    expect(
      CurreController.usesReviewInventoryFixtures(
        web: false,
        platform: TargetPlatform.linux,
        debugMode: true,
      ),
      isTrue,
    );
    expect(
      CurreController.usesReviewInventoryFixtures(
        web: false,
        platform: TargetPlatform.linux,
        debugMode: false,
      ),
      isFalse,
    );
  });

  testWidgets('an app inventory failure shows a retry, then real apps', (
    tester,
  ) async {
    await phone(tester);
    final installed = <LaunchableApp>[
      const LaunchableApp(
        packageName: 'com.android.settings',
        label: 'Settings',
      ),
    ];
    final platform = _FakeDoorPlatform(installed);
    final controller = CurreController(
      launcher: platform,
      apps: const <LaunchableApp>[],
      appInventoryState: AppInventoryState.failed,
      speech: fakeSpeech(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(CurreApp(controller: controller));
    await tester.pump();

    expect(find.text('Couldn’t read your apps'), findsOneWidget);
    expect(find.text('Spotify'), findsNothing);
    expect(controller.apps, isEmpty);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Couldn’t read your apps'), findsNothing);
    expect(controller.apps, installed);
    expect(controller.appInventoryState, AppInventoryState.ready);
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
    expect(find.text('No proof days yet'), findsOneWidget);
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
    expect(find.text('Cloud days'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('History'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);
  });

  testWidgets(
    'Home empty state settles, then keeps launcher entry points still',
    (tester) async {
      await phone(tester);
      final controller = _controller();
      await tester.pumpWidget(
        MaterialApp(
          theme: curreTheme(Brightness.light),
          home: HomeScreen(controller: controller),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('home-checkin-card')), findsOneWidget);
      expect(find.text('Plan now'), findsOneWidget);
      expect(find.byKey(const Key('home-empty-state')), findsOneWidget);
      expect(find.text('Nothing planned yet'), findsOneWidget);
      expect(find.byType(PeekMascot), findsOneWidget);
      var scene = tester.widget<SkyScene>(find.byType(SkyScene));
      expect(scene.live, isTrue);
      expect(scene.water, 0);
      expect(scene.animate, isTrue);
      expect(scene.sun, SkySun.peek);
      await tester.pump(RisingWater.sloshLength);
      scene = tester.widget<SkyScene>(find.byType(SkyScene));
      expect(scene.animate, isFalse);
      for (final label in <String>['Phone', 'Messages', 'Settings', 'Curre']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('12 hidden apps'), findsOneWidget);
    },
  );

  testWidgets('Home plan state gives the task one bold illustrated card', (
    tester,
  ) async {
    await phone(tester);
    final controller = _controller();
    controller.plans = <Plan>[
      Plan(
        id: 'home-plan',
        session: SessionName.morning,
        date: const LocalDate(2026, 10, 24),
        intention: 'Learn the G chord on YouTube',
        apps: const <PlannedApp>[
          PlannedApp(packageName: 'com.google.android.youtube'),
        ],
        endsAt: DateTime.utc(2026, 10, 24, 9),
        source: PlanSource.clocked,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.dark),
        home: HomeScreen(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('home-plan-card')), findsOneWidget);
    expect(find.byKey(const Key('home-checkin-card')), findsNothing);
    expect(find.text('1 task ready'), findsOneWidget);
    expect(find.text('1 ready'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.byType(PeekMascot), findsOneWidget);
    var scene = tester.widget<SkyScene>(find.byType(SkyScene));
    expect(scene.live, isTrue);
    expect(scene.water, closeTo(.15, .001));
    expect(scene.animate, isTrue);
    expect(scene.sun, SkySun.peek);
    await tester.pump(RisingWater.sloshLength);
    scene = tester.widget<SkyScene>(find.byType(SkyScene));
    expect(scene.animate, isFalse);
  });

  testWidgets('Home grant state keeps the unlock banner and door visible', (
    tester,
  ) async {
    await phone(tester);
    final controller = _controller();
    controller.grants = <Grant>[
      Grant(
        packageName: 'com.instagram.android',
        reason: 'reply to Ada',
        task: 'Ada',
        grantedAt: DateTime.utc(2026, 10, 24, 5, 25),
        expiresAt: DateTime.utc(2026, 10, 24, 5, 40),
        source: GrantSource.clocked,
        kind: ReasonKind.person,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: HomeScreen(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('Instagram is back for now'), findsOneWidget);
    expect(find.text('Ada'), findsWidgets);
    expect(find.text('1 ready'), findsOneWidget);
    expect(find.text('→ Open app'), findsOneWidget);
  });

  testWidgets('Home names a chat only after a local conversation matches', (
    tester,
  ) async {
    await phone(tester);
    final platform = _FakeDoorPlatform(
      CurreController.fallbackApps,
      conversations: const <AppShortcut>[
        AppShortcut(
          packageName: 'com.instagram.android',
          id: 'chat-ada',
          shortLabel: 'Recent conversation',
          isConversation: true,
          personNames: <String>['Ada'],
        ),
      ],
    );
    final controller = _controller(platform: platform);
    await controller.conversationShortcutsFor('com.instagram.android');
    controller.grants = <Grant>[
      Grant(
        packageName: 'com.instagram.android',
        reason: 'reply to Ada',
        task: 'Ada',
        grantedAt: DateTime.utc(2026, 10, 24, 5, 25),
        expiresAt: DateTime.utc(2026, 10, 24, 5, 40),
        source: GrantSource.clocked,
        kind: ReasonKind.person,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: HomeScreen(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('→ Chat with Ada'), findsOneWidget);
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

  testWidgets(
    'a planned check-in reveals the apps and returns the plan to Home',
    (tester) async {
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

      expect(find.text('Here’s your plan'), findsOneWidget);
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('→ Search “G chord”'), findsOneWidget);
      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();
      expect(find.text('Your morning'), findsOneWidget);
      expect(controller.lastPlanCall?.usage?.credits, 18);
    },
  );

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
        i < 10 && find.text('Here’s your plan').evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(warmupCalls, 1);
      expect(planCalls, 2);
      expect(find.text('Here’s your plan'), findsOneWidget);
      expect(find.text('Choose the apps yourself'), findsNothing);
    },
  );

  testWidgets('a planned Door records its start and asks once on return', (
    tester,
  ) async {
    await phone(tester);
    final platform = _FakeDoorPlatform(CurreController.fallbackApps);
    final controller = _controller(platform: platform);
    controller.plans = <Plan>[_doorPlan()];
    await tester.pumpWidget(CurreApp(controller: controller));
    await tester.pump();

    await tester.tap(find.byType(DoorRow).first);
    await tester.pumpAndSettle();

    expect(platform.launches, 1);
    expect(controller.taskTraces.single.kind, TaskTraceKind.door);
    expect(find.text(completionQuestion), findsOneWidget);
    expect(find.text('YouTube → Search “G chord”'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('completion-note')),
      'I wrote a clear summary of the central example',
    );
    await tester.pump();
    await tester.tap(find.text('Add proof'));
    await tester.pump();
    await tester.pump();

    // No backend on this phone: the note waits on its own day.
    expect(find.byKey(const Key('proof-pending')), findsOneWidget);
    final record = controller.proofRecords.single;
    expect(record.judgement, ProofJudgement.pending);
    expect(record.date, const LocalDate(2026, 10, 24));
    await tester.tap(find.widgetWithText(CurrePrimaryButton, 'Done'));
    await tester.pumpAndSettle();
    expect(find.text('No proof days yet'), findsOneWidget);

    // The same door again opens the task without asking twice.
    await tester.tap(find.byType(DoorRow).first);
    await tester.pumpAndSettle();
    expect(platform.launches, 2);
    expect(find.text(completionQuestion), findsNothing);
  });

  testWidgets('an accepted note plays the sunrise; Home only counts', (
    tester,
  ) async {
    await phone(tester);
    final sent = <Map<String, Object?>>[];
    final api = CurreApiClient(
      baseUrl: Uri.parse('https://curre.test'),
      appKey: 'test-key',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/v1/proof');
        sent.add(jsonDecode(request.body) as Map<String, Object?>);
        return http.Response(
          jsonEncode(<String, Object?>{
            'outcome': 'accepted',
            'kind': 'specific_completion',
            'specific_completion': .94,
            'result': <String, Object?>{
              'text': 'switched from G to C without looking',
              'start': 2,
              'end': 38,
            },
            'learning': null,
            'usage': <String, Object?>{'credits': 4, 'model_ms': 81.5},
          }),
          200,
        );
      }),
    );
    final controller = _controller(api: api);
    controller.plans = <Plan>[_doorPlan()];
    controller.proofRecords = <ProofRecord>[
      for (var day = 20; day <= 23; day++)
        _supportedOn(LocalDate(2026, 10, day)),
    ];
    await tester.pumpWidget(CurreApp(controller: controller));
    await tester.pump();
    expect(find.text('4 proof days'), findsOneWidget);

    await tester.tap(find.byType(DoorRow).first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('completion-note')),
      'I switched from G to C without looking',
    );
    await tester.pump();
    await tester.tap(find.text('Add proof'));
    await tester.pump();
    await tester.pump();

    expect(sent.single, <String, Object?>{
      'task': 'Learn the G chord on YouTube',
      'note': 'I switched from G to C without looking',
    });
    expect(find.byKey(const Key('proof-accepted')), findsOneWidget);
    expect(find.text('Today’s sun is up'), findsOneWidget);
    final reaction = tester.widget<Avatar>(
      find.descendant(
        of: find.byKey(const Key('proof-accepted')),
        matching: find.byType(Avatar),
      ),
    );
    expect(reaction.expression, AvatarExpression.happy);
    expect(controller.lastProofCall?.usage?.credits, 4);

    await tester.pump(ProoflightMoment.length);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    // Home settles: nothing about the streak moves there.
    await tester.pumpAndSettle();
    expect(find.text('5 proof days'), findsOneWidget);
    final sun = tester.widget<ProoflightSun>(find.byType(ProoflightSun));
    expect((sun.rays, sun.rise), (1, null));
  });

  testWidgets('a task away from the phone waits past its plan for Done', (
    tester,
  ) async {
    await phone(tester);
    var now = DateTime.utc(2026, 10, 24, 5, 30);
    final controller = _controller(now: () => now);
    controller.plans = <Plan>[
      Plan(
        id: 'offline-plan',
        session: SessionName.morning,
        date: const LocalDate(2026, 10, 24),
        intention: 'Pray for twenty minutes',
        apps: const <PlannedApp>[],
        endsAt: DateTime.utc(2026, 10, 24, 6),
        source: PlanSource.clocked,
      ),
    ];
    await tester.pumpWidget(CurreApp(controller: controller));
    await tester.pump();

    expect(find.text('Tap Start when you begin'), findsOneWidget);
    expect(
      find.text('Press and hold an app to open it the usual way.'),
      findsNothing,
    );
    await tester.ensureVisible(find.text('Start'));
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(controller.taskTraces.single.kind, TaskTraceKind.offlineStart);
    expect(find.textContaining('tap when you’re done'), findsOneWidget);

    // The plan ends while the task goes on; its row waits for Done.
    now = DateTime.utc(2026, 10, 24, 6, 25);
    await controller.refresh();
    await tester.pump();
    expect(controller.activePlan, isNull);
    expect(find.text('Away from your phone'), findsOneWidget);

    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text(completionQuestion), findsOneWidget);
    expect(find.text('Pray for twenty minutes'), findsOneWidget);
    await tester.tap(find.text('Just mark it done'));
    await tester.pump();
    await tester.tap(find.widgetWithText(CurrePrimaryButton, 'Done'));
    await tester.pumpAndSettle();

    final record = controller.proofRecords.single;
    expect(record.judgement, ProofJudgement.none);
    expect(record.date, const LocalDate(2026, 10, 24));
    expect(controller.proofSummary.totalProofDays, 0);
    // Closed, and its plan is over: nothing is left waiting on Home.
    expect(find.text('Away from your phone'), findsNothing);
  });

  testWidgets('History and the profile carry Prooflight’s figures and marks', (
    tester,
  ) async {
    await phone(tester);
    final controller = _controller();
    controller.historyPlans = <Plan>[_doorPlan()];
    controller.proofRecords = <ProofRecord>[
      for (var day = 20; day <= 23; day++)
        _supportedOn(LocalDate(2026, 10, day)),
      _pendingOn(const LocalDate(2026, 10, 24)),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: HistoryScreen(controller: controller),
      ),
    );

    expect(find.text('4 proof days'), findsOneWidget);
    expect(
      find.text('4 proof days in all · Best run 4 · 0 cloud days'),
      findsOneWidget,
    );
    final week = tester.widget<WeekStrip>(find.byType(WeekStrip));
    expect(week.days.map((day) => day.state), <DayState>[
      DayState.quiet,
      DayState.quiet,
      DayState.proof,
      DayState.proof,
      DayState.proof,
      DayState.proof,
      DayState.pending,
    ]);
    expect(week.days.last.isToday, isTrue);
    expect(
      find.text('3 more proof days to your next cloud day.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Waiting to be checked'), 300);
    expect(find.text('Waiting to be checked'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Fri, 23 October'), 300);
    expect(find.text('Supported proof'), findsWidgets);

    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: Scaffold(body: ProfileSheet(controller: controller)),
      ),
    );
    Finder stat(String label, String value) => find.ancestor(
      of: find.text(label),
      matching: find.ancestor(
        of: find.text(value),
        matching: find.byType(Column),
      ),
    );
    expect(stat('Proof days', '4'), findsWidgets);
    expect(stat('Best run', '4 days'), findsWidgets);
    expect(stat('Cloud days', '0'), findsWidgets);
  });

  testWidgets('a run that ended is told plainly, with nothing erased', (
    tester,
  ) async {
    await phone(tester);
    final controller = _controller();
    controller.proofRecords = <ProofRecord>[
      for (var day = 1; day <= 5; day++) _supportedOn(LocalDate(2026, 10, day)),
    ];
    await tester.pumpWidget(CurreApp(controller: controller));
    await tester.pump();
    expect(find.text('Next sunrise: one proof away'), findsOneWidget);
    expect(find.textContaining(RegExp('lost|failed|zero')), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: HistoryScreen(controller: controller),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('That run ended at 5 proof days.'),
      300,
    );
    expect(find.text('Today’s proof starts the next sunrise.'), findsOneWidget);
    expect(find.text('Best run 5 · 5 proof days in all'), findsOneWidget);
    expect(find.textContaining(RegExp('lost|failed|zero')), findsNothing);
  });

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

    expect(find.text('Hidden apps'), findsOneWidget);
    expect(
      find.text(
        'Apps you didn’t plan for wait here. Tap one to bring it back.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pump();
    expect(controller.hiddenAppsTipDismissed, isTrue);
    expect(find.text('Got it'), findsNothing);
    expect(find.bySemanticsLabel('Bring back Chrome'), findsOneWidget);
    await tester.tap(find.text('Chrome'));
    await tester.pumpAndSettle();
    expect(find.text('Why now?'), findsOneWidget);
    expect(find.text('What do you need Chrome for right now?'), findsOneWidget);
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
        'Not now',
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
        'That reads like an instruction, not a reason',
      ),
      (const UnlockResponse.unavailable(), 'Couldn’t check your reason'),
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

  testWidgets('person result promises only a conversation found on the phone', (
    tester,
  ) async {
    await phone(tester);
    const response = UnlockResponse(
      outcome: UnlockOutcome.open,
      kind: ReasonKind.person,
      confidence: .94,
      person: SourceSpan(text: 'Ada', start: 6, end: 9),
      minutes: 5,
    );

    Future<void> show(_FakeDoorPlatform platform) async {
      final controller = _controller(platform: platform);
      final app = controller.apps.firstWhere(
        (item) => item.label == 'Instagram',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: curreTheme(Brightness.light),
          home: UnlockGateScreen(
            key: UniqueKey(),
            controller: controller,
            app: app,
            initialReason: 'reply Ada',
            initialResponse: response,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    await show(_FakeDoorPlatform(CurreController.fallbackApps));
    expect(find.text('Opens Instagram'), findsOneWidget);
    expect(find.text('Open Instagram'), findsOneWidget);
    expect(find.textContaining('didn’t find a matching chat'), findsOneWidget);

    await show(
      _FakeDoorPlatform(
        CurreController.fallbackApps,
        conversations: const <AppShortcut>[
          AppShortcut(
            packageName: 'com.instagram.android',
            id: 'chat-ada',
            shortLabel: 'Recent conversation',
            isConversation: true,
            personNames: <String>['Ada'],
          ),
        ],
      ),
    );
    expect(find.text('Opens at Instagram → Chat with Ada'), findsOneWidget);
    expect(find.text('Open Instagram → Chat with Ada'), findsOneWidget);
    expect(find.textContaining('didn’t find a matching chat'), findsNothing);
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
    await tester.tap(find.text('Open after 30 seconds'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(seconds: 2));
    expect(platform.launches, 0);
  });

  test(
    'a finished wait updates its attempt instead of adding another',
    () async {
      final api = CurreApiClient(
        baseUrl: Uri.parse('https://curre.test'),
        appKey: 'test-key',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode(<String, Object?>{
              'outcome': 'later',
              'kind': 'browse',
              'confidence': 0.88,
            }),
            200,
          );
        }),
      );
      final platform = _FakeDoorPlatform(CurreController.fallbackApps);
      final controller = _controller(platform: platform, api: api);
      addTearDown(controller.dispose);
      final app = controller.apps.firstWhere(
        (item) => item.label == 'Instagram',
      );
      const reason = 'just checking today’s posts';

      final response = await controller.judgeUnlock(app: app, reason: reason);
      expect(controller.historyAttempts, hasLength(1));
      expect(controller.historyAttempts.single.overridden, isFalse);

      await controller.finishOverride(
        app: app,
        reason: reason,
        response: response,
      );

      expect(controller.historyAttempts, hasLength(1));
      expect(controller.historyAttempts.single.overridden, isTrue);
      expect(controller.historyAttempts.single.outcome, UnlockOutcome.later);
      expect(platform.launches, 1);
    },
  );

  test(
    'History redacts an unlock while its active grant keeps the live words',
    () async {
      const reason = 'reply Ada on 0803 555';
      final api = CurreApiClient(
        baseUrl: Uri.parse('https://curre.test'),
        appKey: 'test-key',
        httpClient: MockClient((_) async {
          return http.Response(
            jsonEncode(<String, Object?>{
              'outcome': 'open',
              'kind': 'person',
              'confidence': .94,
              'person': <String, Object?>{'text': 'Ada', 'start': 6, 'end': 9},
              'minutes': 5,
              'redactions': <Object?>[
                <String, Object?>{'kind': 'person', 'start': 6, 'end': 9},
                <String, Object?>{'kind': 'phone', 'start': 13, 'end': 21},
              ],
            }),
            200,
          );
        }),
      );
      final platform = _FakeDoorPlatform(CurreController.fallbackApps);
      final controller = _controller(platform: platform, api: api);
      addTearDown(controller.dispose);
      final app = controller.apps.firstWhere(
        (item) => item.label == 'Instagram',
      );

      final response = await controller.judgeUnlock(app: app, reason: reason);
      await controller.grantAndOpen(
        app: app,
        reason: reason,
        response: response,
      );

      expect(
        controller.historyAttempts.single.reason,
        'reply [name] on [phone]',
      );
      expect(
        controller.historyAttempts.single.highlights.single.text,
        '[name]',
      );
      expect(controller.historyGrants.single.reason, 'reply [name] on [phone]');
      expect(controller.historyGrants.single.task, '[name]');
      expect(controller.grants.single.reason, reason);
      expect(controller.grants.single.task, 'Ada');
    },
  );

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
      await tester.tap(find.text('Open after 30 seconds'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Open gate'), findsOneWidget);
      expect(platform.launches, 1);
      expect(controller.grants.single.source, GrantSource.override);
    },
  );

  testWidgets('Curre settings has plain sections and no developer details', (
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
    await tester.pump();
    expect(find.text('Curre settings'), findsOneWidget);
    expect(find.text('Judge demo mode'), findsNothing);
    for (final section in <String>[
      'Your day',
      'Your apps',
      'How strict should Curre be?',
      'Hidden apps',
      'Ask “Why now?” when a hidden app opens',
      'Keep hidden apps quiet',
      'Quiet nudges',
      'Your name',
      'Your home screen',
      'History and privacy',
    ]) {
      final heading = find.text(section);
      for (var i = 0; i < 80 && heading.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -240));
        await tester.pump();
      }
      expect(
        heading,
        findsOneWidget,
        reason: 'Missing Settings section $section',
      );
    }
    expect(find.text('Under the hood'), findsNothing);
    expect(find.textContaining('/v1/'), findsNothing);
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

    expect(find.text('0 of 21 planned'), findsOneWidget);
    expect(find.text('No proof days yet'), findsOneWidget);
    expect(
      find.text(
        'After a task, say what changed. A specific note adds a proof day.',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('A quiet start.'), 300);
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

    expect(find.text('1 of 21 planned'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Learn the G chord on YouTube till 7'),
      300,
    );
    expect(find.text('Morning plan'), findsOneWidget);
    expect(find.text('Learn the G chord on YouTube till 7'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('just checking what Tolu posted'),
      300,
    );
    expect(find.text('Not now'), findsOneWidget);
    expect(find.text('Just browsing'), findsOneWidget);
    expect(find.text('Waited 30 seconds'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Instagram came back'), 300);
    expect(find.text('Instagram came back'), findsOneWidget);
  });

  testWidgets('History visibly marks hidden personal details', (tester) async {
    await phone(tester);
    final controller = _controller();
    controller.historyAttempts = <Attempt>[
      Attempt(
        at: DateTime.utc(2026, 10, 24, 5, 20),
        packageName: 'com.instagram.android',
        outcome: UnlockOutcome.open,
        confidence: .94,
        overridden: false,
        kind: ReasonKind.person,
        reason: 'reply [name] on [phone]',
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: HistoryScreen(controller: controller),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    final marked = tester.widget<SpanText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is SpanText && widget.text == 'reply [name] on [phone]',
      ),
    );
    expect(
      marked.highlights.where(
        (item) => item.semanticsLabel == 'Personal detail hidden',
      ),
      hasLength(2),
    );
  });

  testWidgets('Clear history in settings empties the History screen', (
    tester,
  ) async {
    await phone(tester);
    final controller = _controller();
    _addHistory(controller);
    controller.proofRecords = <ProofRecord>[
      _supportedOn(const LocalDate(2026, 10, 23)),
      _pendingOn(const LocalDate(2026, 10, 24)),
    ];
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
    // Proof days stay; every word written after a task goes.
    final kept = controller.proofRecords.single;
    expect(kept.date, const LocalDate(2026, 10, 23));
    expect((kept.note, kept.taskText), ('', ''));
    expect(controller.proofSummary.totalProofDays, 1);

    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: HistoryScreen(controller: controller),
      ),
    );
    await tester.scrollUntilVisible(find.text('A quiet start.'), 300);
    expect(find.text('A quiet start.'), findsOneWidget);
  });

  test(
    'pending proof retries are bounded and keep their original days',
    () async {
      var calls = 0;
      final api = CurreApiClient(
        baseUrl: Uri.parse('https://curre.test'),
        appKey: 'test-key',
        httpClient: MockClient((request) async {
          calls++;
          expect(request.url.path, '/v1/proof');
          return http.Response(
            jsonEncode(<String, Object?>{
              'outcome': 'accepted',
              'specific_completion': .92,
              'result': <String, Object?>{
                'text': 'a concrete result',
                'start': 0,
                'end': 17,
              },
            }),
            200,
          );
        }),
      );
      final controller = _controller(api: api);
      controller.proofRecords = <ProofRecord>[
        for (var day = 21; day <= 23; day++)
          ProofRecord(
            id: 'proof-$day',
            taskId: 'task-$day',
            planId: 'plan-$day',
            date: LocalDate(2026, 10, day),
            taskText: 'task $day',
            note: 'a concrete result',
            submittedAt: DateTime.utc(2026, 10, day, 7),
            judgement: ProofJudgement.pending,
            level: ProofLevel.selfReported,
            traceId: 'trace-$day',
          ),
      ];

      await controller.retryPendingProofs();
      await controller.retryPendingProofs();

      expect(calls, CurreController.pendingProofRetryBatchSize);
      expect(
        controller.proofRecords
            .where((record) => record.judgement == ProofJudgement.accepted)
            .map((record) => record.date),
        <LocalDate>[
          const LocalDate(2026, 10, 21),
          const LocalDate(2026, 10, 22),
        ],
      );
      expect(
        controller.proofRecords
            .singleWhere(
              (record) => record.date == const LocalDate(2026, 10, 23),
            )
            .judgement,
        ProofJudgement.pending,
      );
    },
  );

  test('a retry never overwrites a newer note for the same task', () async {
    late CurreController controller;
    final api = CurreApiClient(
      baseUrl: Uri.parse('https://curre.test'),
      appKey: 'test-key',
      httpClient: MockClient((request) async {
        // The person writes again while the older note is out.
        final old = controller.proofRecords.single;
        controller.proofRecords = <ProofRecord>[
          ProofRecord(
            id: old.id,
            taskId: old.taskId,
            planId: old.planId,
            date: old.date,
            taskText: old.taskText,
            note: 'a newer, more specific note',
            submittedAt: old.submittedAt.add(const Duration(minutes: 5)),
            judgement: ProofJudgement.pending,
            level: ProofLevel.selfReported,
            traceId: old.traceId,
          ),
        ];
        return http.Response(jsonEncode({'outcome': 'vague'}), 200);
      }),
    );
    controller = _controller(api: api);
    controller.proofRecords = <ProofRecord>[
      _pendingOn(const LocalDate(2026, 10, 24)),
    ];

    await controller.retryPendingProofs();

    final record = controller.proofRecords.single;
    expect(record.note, 'a newer, more specific note');
    expect(record.isPending, isTrue);
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
        controller.proofRecords = <ProofRecord>[
          for (var day = 10; day <= 22; day++)
            if (day != 16) _supportedOn(LocalDate(2026, 10, day)),
          _pendingOn(const LocalDate(2026, 10, 24)),
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
        final task = PlannedTask.forDoor(
          controller.plans.single,
          controller.plans.single.apps.first,
        );
        await show(
          Scaffold(
            body: CompletionSheet(controller: controller, task: task),
          ),
        );
        final today = _supportedOn(const LocalDate(2026, 10, 24));
        await show(
          Scaffold(
            body: SingleChildScrollView(
              child: ProoflightMoment(
                submission: ProofSubmission(
                  record: today,
                  before: controller.proofSummary,
                  after: ProoflightRules.summarize(
                    records: <ProofRecord>[...controller.proofRecords, today],
                    today: const LocalDate(2026, 10, 24),
                  ),
                ),
                title: 'A Very Long Social Application Name → Search “capo tutorial for Sunday”',
                avatarId: 'avatar-03',
                displayName: 'Chidiebere Nwachukwu-Okafor',
                progress: 1,
                onContinue: () {},
              ),
            ),
          ),
        );
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

Plan _doorPlan({LocalDate date = const LocalDate(2026, 10, 24)}) => Plan(
  id: 'door-plan-$date',
  session: SessionName.morning,
  date: date,
  intention: 'Learn the G chord on YouTube',
  apps: const <PlannedApp>[
    PlannedApp(
      packageName: 'com.google.android.youtube',
      query: SourceSpan(text: 'G chord', start: 10, end: 17),
    ),
  ],
  endsAt: DateTime.utc(date.year, date.month, date.day, 8),
  source: PlanSource.clocked,
);

ProofRecord _proofOn(LocalDate date, ProofResponse response) {
  final plan = _doorPlan(date: date);
  final task = PlannedTask.forDoor(plan, plan.apps.single);
  final at = DateTime.utc(date.year, date.month, date.day, 5);
  return ProoflightRules.recordFromResponse(
    task: task,
    note: 'I switched from G to C without looking',
    submittedAt: at,
    response: response,
    trace: TaskTrace.forTask(
      task,
      kind: TaskTraceKind.door,
      at: at.subtract(const Duration(minutes: 20)),
    ),
  );
}

ProofRecord _supportedOn(LocalDate date) => _proofOn(
  date,
  const ProofResponse(
    outcome: ProofOutcome.accepted,
    kind: ProofKind.specificCompletion,
    specificCompletion: .94,
    result: SourceSpan(
      text: 'switched from G to C without looking',
      start: 2,
      end: 38,
    ),
  ),
);

ProofRecord _pendingOn(LocalDate date) =>
    _proofOn(date, const ProofResponse.pending());

CurreController _controller({
  bool onboardingComplete = true,
  _FakeDoorPlatform? platform,
  CurreApiClient? api,
  DateTime Function()? now,
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
    speech: fakeSpeech(),
    settings: Settings(
      displayName: 'Chidi',
      essentials: essentials,
      candidates: candidates,
    ),
    apps: CurreController.fallbackApps,
    onboardingComplete: onboardingComplete,
    now: now ?? () => DateTime.utc(2026, 10, 24, 5, 30),
  );
}

class _FakeHomePlatform implements HomePlatformGateway {
  @override
  Future<bool> isDefaultHome() async => true;

  @override
  Future<void> setHomeSurfaceActive(bool active) async {}
}

class _FakeDoorPlatform implements DoorPlatform {
  _FakeDoorPlatform(this.apps, {this.conversations = const <AppShortcut>[]});

  final List<LaunchableApp> apps;
  final List<AppShortcut> conversations;
  int launches = 0;

  @override
  Future<Uint8List?> getIcon(String packageName) async => null;

  @override
  Future<List<AppShortcut>> getConversationShortcuts(
    String packageName,
  ) async => conversations
      .where((shortcut) => shortcut.packageName == packageName)
      .toList(growable: false);

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
