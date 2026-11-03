import 'package:curre/app/checkin_screen.dart';
import 'package:curre/app/curre_controller.dart';
import 'package:curre/app/home_screen.dart';
import 'package:curre/app/onboarding_screen.dart';
import 'package:curre/app/privacy_details_screen.dart';
import 'package:curre/core/core.dart';
import 'package:curre/main.dart';
import 'package:curre/platform/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

const _instagram = 'com.instagram.android';
const _netflix = 'com.netflix.mediaclient';
const _youtube = 'com.google.android.youtube';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester, CurreController controller) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(CurreApp(controller: controller));
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await settle(tester);
  }

  Future<void> resume(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
  }

  CurreController newUser({
    FakeHomePlatform? home,
    FakeDoorPlatform? platform,
    FakeHomeSettings? homeSettings,
    FakeGentleIntercept? gentleIntercept,
    FakeNotificationGateway? notifications,
    Settings? settings,
    CurreLocalStore? store,
  }) {
    final homePlatform = home ?? FakeHomePlatform(isHome: false);
    return fakeController(
      onboardingComplete: false,
      settings: settings ?? Settings(),
      home: homePlatform,
      platform: platform ?? FakeDoorPlatform(home: homePlatform),
      homeSettings: homeSettings,
      gentleIntercept: gentleIntercept,
      notifications: notifications,
      store: store,
    );
  }

  /// Walks from the first step to the one with [headline], answering
  /// with the defaults (and Ada for a name).
  Future<void> walkTo(WidgetTester tester, String headline) async {
    final steps = <String, Future<void> Function()>{
      'Ever pick up your phone for one thing and lose an hour?': () =>
          tapText(tester, 'Show me how'),
      'What should Curre call you?': () async {
        await tester.enterText(find.byType(TextField), 'Ada');
        await settle(tester);
        await tapText(tester, 'Call me Ada');
      },
      'What pulls you in?': () => tapText(tester, 'None of these'),
      'Make Curre your home screen.': () async {
        await tapText(tester, 'Make Curre my home screen');
        await tapText(tester, 'Continue');
      },
    };
    for (final entry in steps.entries) {
      if (entry.key == headline) return;
      expect(find.text(entry.key), findsOneWidget);
      await entry.value();
    }
  }

  testWidgets('a new user walks all five steps and lands in their first plan', (
    tester,
  ) async {
    final home = FakeHomePlatform(isHome: false);
    final platform = FakeDoorPlatform(home: home);
    final access = FakeGentleIntercept();
    final notifications = FakeNotificationGateway();
    final controller = newUser(
      home: home,
      platform: platform,
      gentleIntercept: access,
      notifications: notifications,
    );
    await pump(tester, controller);
    final semantics = tester.ensureSemantics();

    // 1 · Welcome: the problem, the promise and one line on privacy.
    expect(
      find.text('Ever pick up your phone for one thing and lose an hour?'),
      findsOneWidget,
    );
    expect(find.text('1 / 5'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 1 of 5'), findsOneWidget);
    expect(find.bySemanticsLabel('Back'), findsNothing);
    expect(
      find.text('Your history and contacts stay on this phone.'),
      findsOneWidget,
    );
    await tapText(tester, 'How Curre keeps things private');
    expect(find.byType(PrivacyDetailsScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(PrivacyDetailsScreen))).pop();
    await settle(tester);
    await tapText(tester, 'Show me how');

    // 2 · You: name and face on one screen.
    expect(find.text('What should Curre call you?'), findsOneWidget);
    expect(find.text('2 / 5'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Ada');
    await settle(tester);
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Avatar 3, light skin, soft curls')),
    );
    await tester.tap(
      find.bySemanticsLabel(RegExp('Avatar 3, light skin, soft curls')),
    );
    await settle(tester);
    await tapText(tester, 'Call me Ada');

    // 3 · What pulls you in: those go to Hidden apps.
    expect(find.text('What pulls you in?'), findsOneWidget);
    expect(find.text('3 / 5'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Always on Home: Phone, Messages and Settings'),
      findsOneWidget,
    );
    await tapText(tester, 'Pick at least one');
    expect(find.text('What pulls you in?'), findsOneWidget);
    await tapText(tester, 'Instagram');
    await tapText(tester, 'Netflix');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Instagram').first),
      isSemantics(label: 'Instagram', isSelected: true, isButton: true),
    );
    await tapText(tester, 'Hide these 2');

    // 4 · Home: Android's answer is what counts.
    expect(find.text('Make Curre your home screen.'), findsOneWidget);
    expect(find.text('4 / 5'), findsOneWidget);
    await tapText(tester, 'Make Curre my home screen');
    expect(platform.homeRequests, 1);
    expect(find.text('Curre is your home screen now.'), findsOneWidget);
    await tapText(tester, 'Continue');

    // 5 · The first plan goes straight into the real check-in.
    expect(find.text('What’s this morning for?'), findsOneWidget);
    expect(find.text('5 / 5'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 5 of 5'), findsOneWidget);
    expect(
      find.text(
        'Curre asks what your morning is for from 06:00. Change that any time in Curre settings.',
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('onboarding-plan')),
      'Learn the G chord on YouTube till 7',
    );
    await settle(tester);
    await tapText(tester, 'Set my morning');
    await settle(tester);
    await settle(tester);

    expect(controller.onboardingComplete, isTrue);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(CheckinScreen), findsOneWidget);
    expect(find.text('Learn the G chord on YouTube till 7'), findsWidgets);
    final settings = controller.settings;
    expect(settings.displayName, 'Ada');
    expect(settings.avatarId, 'avatar-03');
    expect(settings.sessionStarts[SessionName.morning], const LocalTime(6));
    expect(settings.essentials, controller.suggestedEssentials);
    expect(settings.candidates, isNot(contains(_instagram)));
    expect(settings.candidates, isNot(contains(_netflix)));
    expect(settings.candidates, contains(_youtube));
    expect(settings.candidates.length, inInclusiveRange(2, 30));
    // Nothing was asked of Android beyond the home screen: each of these
    // waits for its moment.
    expect(access.usageRequests, 0);
    expect(access.notificationRequests, 0);
    expect(notifications.requests, 0);
    expect(controller.pendingPrompts, ContextPrompt.values.toSet());
    semantics.dispose();
  });

  testWidgets('Back keeps every answer', (tester) async {
    final controller = newUser();
    await pump(tester, controller);
    await tapText(tester, 'Show me how');
    await tester.enterText(find.byType(TextField), 'Ada');
    await settle(tester);
    await tester.ensureVisible(
      find.bySemanticsLabel(RegExp('Avatar 3, light skin, soft curls')),
    );
    await tester.tap(
      find.bySemanticsLabel(RegExp('Avatar 3, light skin, soft curls')),
    );
    await settle(tester);
    await tapText(tester, 'Call me Ada');
    await tapText(tester, 'Instagram');
    await tapText(tester, 'Hide this one');
    expect(find.text('Make Curre your home screen.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    expect(find.text('What pulls you in?'), findsOneWidget);
    expect(find.text('Hide this one'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    expect(find.text('What should Curre call you?'), findsOneWidget);
    expect(find.text('Ada'), findsWidgets);
    expect(find.text('Use my initial instead'), findsOneWidget);
    await tapText(tester, 'Use my initial instead');
    await tapText(tester, 'Call me Ada');
    await tapText(tester, 'Hide this one');
    await tapText(tester, 'Make Curre my home screen');
    await tapText(tester, 'Continue');
    await tapText(tester, 'I’ll plan later');
    expect(controller.settings.avatarId, isNull);
    expect(controller.settings.candidates, isNot(contains(_instagram)));
  });

  testWidgets('a blank name asks for one instead of moving on', (tester) async {
    final controller = newUser();
    await pump(tester, controller);
    await walkTo(tester, 'What should Curre call you?');
    await tester.enterText(find.byType(TextField), '   ');
    await settle(tester);
    await tapText(tester, 'Continue');
    expect(find.text('What should Curre call you?'), findsOneWidget);
    expect(find.text('Add a name, even just a nickname.'), findsOneWidget);
  });

  testWidgets('mornings start at 06:00 unless the afternoon starts sooner', (
    tester,
  ) async {
    final controller = newUser(
      settings: Settings(
        sessionStarts: const <SessionName, LocalTime>{
          SessionName.morning: LocalTime(5),
          SessionName.afternoon: LocalTime(6),
          SessionName.evening: LocalTime(17),
        },
      ),
    );
    await pump(tester, controller);
    await walkTo(tester, 'Make Curre your home screen.');
    await tapText(tester, 'Make Curre my home screen');
    await tapText(tester, 'Continue');
    await tapText(tester, 'I’ll plan later');
    expect(
      controller.settings.sessionStarts[SessionName.morning],
      const LocalTime(5),
    );
  });

  testWidgets('Home stays put until Android says Curre is the home screen', (
    tester,
  ) async {
    final home = FakeHomePlatform(isHome: false);
    final homeSettings = FakeHomeSettings(HomeSettingsOpened.defaultApps);
    final controller = newUser(
      home: home,
      platform: FakeDoorPlatform(home: home, grantHome: false),
      homeSettings: homeSettings,
    );
    await pump(tester, controller);
    await walkTo(tester, 'Make Curre your home screen.');

    await tapText(tester, 'Make Curre my home screen');
    expect(find.text('Make Curre your home screen.'), findsOneWidget);
    expect(
      find.text(
        'Curre isn’t your home screen yet. Try again, or open your phone’s home screen settings and choose Curre.',
      ),
      findsOneWidget,
    );

    await tapText(tester, 'Open home settings');
    expect(homeSettings.calls, 1);
    expect(
      find.text('Tap “Home app”, choose Curre, then come back here.'),
      findsOneWidget,
    );

    home.isHome = true;
    await resume(tester);
    expect(find.text('Curre is your home screen now.'), findsOneWidget);
    await tapText(tester, 'Continue');
    expect(find.text('What’s this morning for?'), findsOneWidget);
  });

  testWidgets('“I’ll plan later” finishes without opening a plan', (
    tester,
  ) async {
    final controller = newUser();
    await pump(tester, controller);
    await walkTo(tester, 'What’s this morning for?');
    await tapText(tester, 'I’ll plan later');
    await settle(tester);

    expect(controller.onboardingComplete, isTrue);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(CheckinScreen), findsNothing);
    // With nothing running yet, quiet nudges wait for a later moment.
    expect(find.text('Want a quiet nudge when time’s up?'), findsNothing);
    expect(controller.settings.candidates.length, greaterThanOrEqualTo(2));
  });

  testWidgets('if the phone can’t save, every answer stays for a retry', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = FailingStore(await SharedPreferences.getInstance());
    final controller = newUser(store: store);
    await pump(tester, controller);
    await walkTo(tester, 'What’s this morning for?');
    await tester.enterText(
      find.byKey(const Key('onboarding-plan')),
      'Reply to Ada on WhatsApp',
    );
    await settle(tester);
    await tapText(tester, 'Set my morning');

    expect(controller.onboardingComplete, isFalse);
    expect(
      find.text(
        'Curre couldn’t save your answers on this phone. Please try again.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('onboarding-plan')))
          .controller!
          .text,
      'Reply to Ada on WhatsApp',
    );

    store.failSaves = false;
    await tapText(tester, 'Set my morning');
    await settle(tester);
    expect(controller.onboardingComplete, isTrue);
    expect(controller.settings.displayName, 'Ada');
    expect(store.pendingPrompts, ContextPrompt.values.toSet());
  });

  testWidgets('every step fits a small phone at twice the text size', (
    tester,
  ) async {
    final controller = newUser();
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(CurreApp(controller: controller));
    await settle(tester);
    expect(tester.takeException(), isNull);

    await tapText(tester, 'Show me how');
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'Chidiebere');
    await settle(tester);
    for (final action in <String>[
      'Call me Chidiebere',
      'None of these',
      'Make Curre my home screen',
      'Continue',
    ]) {
      await tapText(tester, action);
      expect(tester.takeException(), isNull);
    }
    expect(find.text('What’s this morning for?'), findsOneWidget);
  });
}
