import 'package:curre/app/curre_controller.dart';
import 'package:curre/app/hidden_apps_screen.dart';
import 'package:curre/app/home_screen.dart';
import 'package:curre/app/onboarding/app_hints.dart';
import 'package:curre/app/settings_screen.dart';
import 'package:curre/core/core.dart';
import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

const _stillOff =
    'It’s still off. That’s okay, Curre works without it. If Android said the setting is restricted, allow it once:';
const _beforeAsking =
    'If Android says the setting is restricted, allow it once:';
const _nudgeOffer = 'Want a quiet nudge when time’s up?';
const _askWhyOffer = 'Ask “Why now?” when a hidden app opens?';
const _quietOffer = 'Keep hidden apps quiet?';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> show(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        // A new key each time, so every visit starts fresh.
        home: KeyedSubtree(key: UniqueKey(), child: screen),
      ),
    );
    await tester.pump();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pump();
    await tester.tap(find.text(text).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  CurreController afterSetup({
    FakeGentleIntercept? access,
    FakeNotificationGateway? notifications,
    CurreLocalStore? store,
    bool timeRunning = true,
  }) {
    final controller = fakeController(
      gentleIntercept: access,
      notifications: notifications,
      store: store,
      pendingPrompts: ContextPrompt.values.toSet(),
    );
    if (timeRunning) {
      controller.grants = <Grant>[
        Grant(
          packageName: 'com.instagram.android',
          reason: 'reply Ada about rehearsal',
          task: 'Ada',
          grantedAt: controller.now.subtract(const Duration(minutes: 2)),
          expiresAt: controller.now.add(const Duration(minutes: 8)),
          source: GrantSource.clocked,
          kind: ReasonKind.person,
        ),
      ];
    }
    return controller;
  }

  group('quiet nudges, asked on Home', () {
    testWidgets('wait until time is running', (tester) async {
      final controller = afterSetup(timeRunning: false);
      await show(tester, HomeScreen(controller: controller));
      expect(find.text(_nudgeOffer), findsNothing);
      expect(controller.pendingPrompts, contains(ContextPrompt.nudges));
    });

    testWidgets('can be declined, once, and say where to change it', (
      tester,
    ) async {
      final notifications = FakeNotificationGateway();
      final controller = afterSetup(notifications: notifications);
      await show(tester, HomeScreen(controller: controller));
      expect(find.text(_nudgeOffer), findsOneWidget);

      await tapText(tester, 'Not now');
      expect(notifications.requests, 0);
      expect(controller.settings.hasAnyNudges, isFalse);
      expect(find.text(_nudgeOffer), findsNothing);
      expect(
        find.text(
          'No problem. You can turn quiet nudges on later in Curre settings.',
        ),
        findsOneWidget,
      );
      expect(controller.pendingPrompts, isNot(contains(ContextPrompt.nudges)));

      await show(tester, HomeScreen(controller: controller));
      expect(find.text(_nudgeOffer), findsNothing);
    });

    testWidgets('ask Android once on yes', (tester) async {
      final notifications = FakeNotificationGateway();
      final controller = afterSetup(notifications: notifications);
      await show(tester, HomeScreen(controller: controller));

      await tapText(tester, 'Yes, nudge me');
      expect(notifications.requests, 1);
      expect(controller.settings.hasAnyNudges, isTrue);
      expect(find.text(_nudgeOffer), findsNothing);
      expect(
        find.text(
          'Quiet nudges are on. You can choose which ones in Curre settings.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('turn off when Android says no', (tester) async {
      final notifications = FakeNotificationGateway(allow: false);
      final controller = afterSetup(notifications: notifications);
      await show(tester, HomeScreen(controller: controller));

      await tapText(tester, 'Yes, nudge me');
      expect(notifications.requests, 1);
      expect(controller.settings.hasAnyNudges, isFalse);
      expect(find.text(_nudgeOffer), findsNothing);
    });
  });

  group('Android access, asked in Hidden apps', () {
    testWidgets(
      'explains restricted settings first, then again kindly if still off',
      (tester) async {
        final access = FakeGentleIntercept(grants: false);
        final controller = afterSetup(access: access);
        await show(tester, HiddenAppsScreen(controller: controller));

        expect(find.text(_askWhyOffer), findsOneWidget);
        // Only one access is offered per visit.
        expect(find.text(_quietOffer), findsNothing);
        expect(find.text(_beforeAsking), findsOneWidget);
        expect(
          find.text('3. Tap “Allow restricted settings”.'),
          findsOneWidget,
        );

        await tapText(tester, 'Open Curre’s App info');
        expect(access.appInfoOpens, 1);
        expect(access.usageRequests, 0);

        await tapText(tester, 'Turn on Usage access');
        expect(access.usageRequests, 1);
        expect(find.text(_stillOff), findsOneWidget);
        expect(
          find.text('3. Tap “Allow restricted settings”.'),
          findsOneWidget,
        );
        expect(find.text('Try again'), findsOneWidget);
        // Curre carries on without it: the hidden apps are all still here.
        await tester.scrollUntilVisible(
          find.bySemanticsLabel('Bring back Netflix'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.bySemanticsLabel('Bring back Netflix'), findsOneWidget);
        expect(
          controller.pendingPrompts,
          isNot(contains(ContextPrompt.askWhy)),
        );

        // Asked once: the next visit offers keeping hidden apps quiet.
        await show(tester, HiddenAppsScreen(controller: controller));
        expect(find.text(_askWhyOffer), findsNothing);
        expect(find.text(_quietOffer), findsOneWidget);
        await tapText(tester, 'Not now');
        expect(access.notificationRequests, 0);
        expect(find.text(_quietOffer), findsNothing);
        expect(
          find.text('No problem. It’s in Curre settings any time.'),
          findsOneWidget,
        );
        expect(
          controller.pendingPrompts,
          isNot(contains(ContextPrompt.quietHidden)),
        );

        await show(tester, HiddenAppsScreen(controller: controller));
        expect(find.text(_askWhyOffer), findsNothing);
        expect(find.text(_quietOffer), findsNothing);
      },
    );

    testWidgets('says all set when Android allows it', (tester) async {
      final access = FakeGentleIntercept();
      final controller = afterSetup(access: access);
      await show(tester, HiddenAppsScreen(controller: controller));

      await tapText(tester, 'Turn on Usage access');
      expect(controller.hasUsageAccess, isTrue);
      expect(
        find.text('Curre will ask “Why now?” when a hidden app opens.'),
        findsOneWidget,
      );
      await tapText(tester, 'Done');
      expect(find.text('All set.'), findsNothing);
    });

    testWidgets('isn’t offered when Android already allows it', (tester) async {
      final access = FakeGentleIntercept(usage: true, notifications: true);
      final controller = afterSetup(access: access);
      await controller.initializeGentleIntercept();
      await show(tester, HiddenAppsScreen(controller: controller));
      expect(find.text(_askWhyOffer), findsNothing);
      expect(find.text(_quietOffer), findsNothing);
    });
  });

  testWidgets('people who set up before are never asked again', (tester) async {
    final controller = fakeController();
    controller.grants = afterSetup().grants;
    await show(tester, HomeScreen(controller: controller));
    expect(find.text(_nudgeOffer), findsNothing);
    await show(tester, HiddenAppsScreen(controller: controller));
    expect(find.text(_askWhyOffer), findsNothing);
    expect(find.text(_quietOffer), findsNothing);
  });

  test('answers are kept on the phone', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = CurreLocalStore(await SharedPreferences.getInstance());
    expect(store.pendingPrompts, isEmpty);
    final controller = afterSetup(store: store);

    await controller.finishOnboarding(
      displayName: 'Ada',
      avatarId: null,
      essentials: const <String>{},
      candidates: const <String>{'com.whatsapp', 'com.spotify.music'},
    );
    expect(store.pendingPrompts, ContextPrompt.values.toSet());
    await controller.settlePrompt(ContextPrompt.askWhy);
    final reopened = CurreLocalStore(await SharedPreferences.getInstance());
    expect(reopened.pendingPrompts, <ContextPrompt>{
      ContextPrompt.nudges,
      ContextPrompt.quietHidden,
    });
  });

  group('plan apps after setup', () {
    const eligible = <String>[
      'com.android.calculator',
      'com.instagram.android',
      'com.netflix.mediaclient',
      'com.whatsapp',
      'com.google.android.youtube',
    ];

    test('are what the user didn’t hide, defaults first', () {
      final picked = defaultPlanApps(
        eligible: eligible,
        hidden: const {'com.instagram.android', 'com.netflix.mediaclient'},
        max: 2,
      );
      expect(picked, <String>{'com.google.android.youtube', 'com.whatsapp'});
    });

    test('bring back defaults when hiding leaves fewer than two', () {
      final picked = defaultPlanApps(
        eligible: eligible,
        hidden: eligible.toSet().difference({'com.android.calculator'}),
      );
      expect(picked, hasLength(2));
      expect(picked, contains('com.android.calculator'));
      expect(picked, contains('com.google.android.youtube'));
    });
  });

  group('settings still has every moved question', () {
    Future<void> scrollTo(WidgetTester tester, String text) async {
      await tester.scrollUntilVisible(
        find.text(text),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
    }

    testWidgets('notifications show where Android stands', (tester) async {
      final notifications = FakeNotificationGateway()..allowed = false;
      final controller = fakeController(notifications: notifications);
      await show(tester, SettingsScreen(controller: controller));
      await tester.pump();
      await scrollTo(tester, 'Not allowed yet. Tap to allow.');
      await tapText(tester, 'Allow notifications');
      expect(notifications.requests, 1);
      expect(
        find.text('Allowed. The quiet nudges you choose can appear.'),
        findsOneWidget,
      );
    });

    testWidgets('morning start shows its time', (tester) async {
      final controller = fakeController(
        settings: Settings(
          sessionStarts: const <SessionName, LocalTime>{
            SessionName.morning: LocalTime(6),
            SessionName.afternoon: LocalTime(12),
            SessionName.evening: LocalTime(17),
          },
        ),
      );
      await show(tester, SettingsScreen(controller: controller));
      expect(find.text('Starts at 06:00'), findsOneWidget);
    });

    testWidgets('access cards explain restricted settings, then again', (
      tester,
    ) async {
      final access = FakeGentleIntercept(grants: false);
      final controller = fakeController(gentleIntercept: access);
      await show(tester, SettingsScreen(controller: controller));
      await tester.pump();
      await scrollTo(tester, 'Turn on Usage access');
      expect(find.text(_beforeAsking), findsWidgets);
      await tapText(tester, 'Turn on Usage access');
      expect(access.usageRequests, 1);
      expect(find.text(_stillOff), findsOneWidget);
      await tapText(tester, 'Open Curre’s App info');
      expect(access.appInfoOpens, 1);
      await scrollTo(tester, 'Turn on notification access');
      expect(find.text('Keep hidden apps quiet'), findsOneWidget);
    });
  });
}
