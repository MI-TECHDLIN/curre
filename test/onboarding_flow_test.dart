import 'package:curre/app/checkin_screen.dart';
import 'package:curre/app/curre_controller.dart';
import 'package:curre/app/home_screen.dart';
import 'package:curre/app/onboarding_screen.dart';
import 'package:curre/core/core.dart';
import 'package:curre/main.dart';
import 'package:curre/platform/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

const _instagram = 'com.instagram.android';
const _netflix = 'com.netflix.mediaclient';

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
      'Your life stays on your phone.': () => tapText(tester, 'Sounds fair'),
      'Which apps pull you in?': () => tapText(tester, 'None of these'),
      'What should Curre call you?': () async {
        await tester.enterText(find.byType(TextField), 'Ada');
        await settle(tester);
        await tapText(tester, 'Call me Ada');
      },
      'Pick a face that feels like you.': () =>
          tapText(tester, 'Use my initial'),
      'When does your morning start?': () =>
          tapText(tester, 'Mornings start at 04:00'),
      'Make Curre your home screen.': () async {
        await tapText(tester, 'Make Curre my home screen');
        await tapText(tester, 'Continue');
      },
      'What if a hidden app sneaks back in?': () =>
          tapText(tester, 'Skip for now'),
      'Keep hidden apps quiet?': () => tapText(tester, 'Skip for now'),
      'Want a quiet nudge when time’s up?': () => tapText(tester, 'Not now'),
    };
    for (final entry in steps.entries) {
      if (entry.key == headline) return;
      expect(find.text(entry.key), findsOneWidget);
      await entry.value();
    }
  }

  testWidgets(
    'a new user walks all twelve steps and lands in their first plan',
    (tester) async {
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

      // 1 · The problem, with no way back yet.
      expect(
        find.text('Ever pick up your phone for one thing and lose an hour?'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Step 1 of 12'), findsOneWidget);
      expect(find.bySemanticsLabel('Back'), findsNothing);
      await tapText(tester, 'Show me how');

      // 2 · Privacy.
      expect(find.text('Your life stays on your phone.'), findsOneWidget);
      expect(find.bySemanticsLabel('Step 2 of 12'), findsOneWidget);
      await tapText(tester, 'Sounds fair');

      // 3 · The apps that pull you in.
      expect(find.text('Which apps pull you in?'), findsOneWidget);
      await tapText(tester, 'Pick at least one');
      expect(find.text('Which apps pull you in?'), findsOneWidget);
      await tapText(tester, 'Instagram');
      await tapText(tester, 'Netflix');
      expect(
        tester.getSemantics(find.bySemanticsLabel('Instagram').first),
        isSemantics(label: 'Instagram', isSelected: true, isButton: true),
      );
      await tapText(tester, 'These pull me in');

      // 4 · Name.
      expect(find.text('What should Curre call you?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Ada');
      await settle(tester);
      await tapText(tester, 'Call me Ada');

      // 5 · Face.
      expect(find.text('Pick a face that feels like you.'), findsOneWidget);
      await tester.tap(
        find.bySemanticsLabel(RegExp('Avatar 3, light skin, soft curls')),
      );
      await settle(tester);
      await tapText(tester, 'This is me');

      // 6 · Morning.
      expect(find.text('When does your morning start?'), findsOneWidget);
      await tapText(tester, '06:00');
      await tapText(tester, 'Mornings start at 06:00');

      // 7 · Home: Android's answer is what counts.
      expect(find.text('Make Curre your home screen.'), findsOneWidget);
      await tapText(tester, 'Make Curre my home screen');
      expect(platform.homeRequests, 1);
      expect(find.text('Curre is your home screen now.'), findsOneWidget);
      await tapText(tester, 'Continue');

      // 8 · Apps that sneak back in.
      expect(find.text('What if a hidden app sneaks back in?'), findsOneWidget);
      await tapText(tester, 'Allow');
      // Android's screen answers once the user is back in Curre.
      expect(access.usageRequests, 1);
      expect(
        find.text(
          'All set. Curre will ask “Why now?” when a hidden app sneaks back in.',
        ),
        findsOneWidget,
      );
      await tapText(tester, 'Continue');

      // 9 · Hidden apps kept quiet.
      expect(find.text('Keep hidden apps quiet?'), findsOneWidget);
      await tapText(tester, 'Allow');
      expect(access.notificationRequests, 1);
      expect(
        find.text(
          'All set. Hidden apps will stay quiet until you bring them back.',
        ),
        findsOneWidget,
      );
      await tapText(tester, 'Continue');

      // 10 · Quiet nudges.
      expect(find.text('Want a quiet nudge when time’s up?'), findsOneWidget);
      expect(notifications.requests, 0);
      await tapText(tester, 'Yes, nudge me');
      expect(notifications.requests, 1);

      // 11 · The apps plans can use: what pulls you in comes along.
      expect(find.text('Which apps will your plans need?'), findsOneWidget);
      expect(
        find.textContaining('Always on Home', findRichText: true),
        findsOneWidget,
      );
      final use = find.textContaining(RegExp(r'^Use these \d+ apps$'));
      expect(use, findsOneWidget);
      await tapText(tester, tester.widget<Text>(use).data!);

      // 12 · The first plan goes straight into the real check-in.
      expect(find.text('What’s this morning for?'), findsOneWidget);
      expect(find.bySemanticsLabel('Step 12 of 12'), findsOneWidget);
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
      expect(settings.candidates, containsAll(<String>[_instagram, _netflix]));
      expect(settings.candidates.length, inInclusiveRange(2, 30));
      semantics.dispose();
    },
  );

  testWidgets('Back keeps every answer', (tester) async {
    final controller = newUser();
    await pump(tester, controller);
    await tapText(tester, 'Show me how');
    await tapText(tester, 'Sounds fair');
    await tapText(tester, 'Instagram');
    await tapText(tester, 'This one pulls me in');
    await tester.enterText(find.byType(TextField), 'Ada');
    await settle(tester);
    await tapText(tester, 'Call me Ada');
    expect(find.text('Pick a face that feels like you.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    expect(find.text('What should Curre call you?'), findsOneWidget);
    expect(find.text('Ada'), findsWidgets);
    expect(find.text('Call me Ada'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    expect(find.text('Which apps pull you in?'), findsOneWidget);
    expect(find.text('This one pulls me in'), findsOneWidget);
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

  testWidgets('a morning has to start before the afternoon', (tester) async {
    final controller = newUser(
      settings: Settings(
        sessionStarts: const <SessionName, LocalTime>{
          SessionName.morning: LocalTime(5),
          SessionName.afternoon: LocalTime(6, 30),
          SessionName.evening: LocalTime(17),
        },
      ),
    );
    await pump(tester, controller);
    await walkTo(tester, 'When does your morning start?');
    await tapText(tester, '07:00');
    expect(
      find.text('Pick a time before 06:30. That’s when your afternoon starts.'),
      findsOneWidget,
    );
    expect(find.text('Mornings start at 05:00'), findsOneWidget);
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
    expect(find.text('What if a hidden app sneaks back in?'), findsOneWidget);
  });

  testWidgets(
    'the hidden-app steps say so when access stays off, and notice it later',
    (tester) async {
      final access = FakeGentleIntercept(grants: false);
      final controller = newUser(gentleIntercept: access);
      await pump(tester, controller);
      await walkTo(tester, 'What if a hidden app sneaks back in?');

      const notYet =
          'It isn’t on yet. Try again, or skip for now and turn it on later in Curre settings.';
      await tapText(tester, 'Allow');
      expect(access.usageRequests, 1);
      expect(find.text(notYet), findsOneWidget);
      expect(find.text('Continue'), findsNothing);

      // Switched on in Android's own settings, then back to Curre.
      access.usage = true;
      await resume(tester);
      expect(
        find.text(
          'All set. Curre will ask “Why now?” when a hidden app sneaks back in.',
        ),
        findsOneWidget,
      );
      expect(controller.hasUsageAccess, isTrue);
      await tapText(tester, 'Continue');

      expect(find.text('Keep hidden apps quiet?'), findsOneWidget);
      await tapText(tester, 'Allow');
      expect(access.notificationRequests, 1);
      expect(find.text(notYet), findsOneWidget);
      await tapText(tester, 'Skip for now');
      expect(find.text('Want a quiet nudge when time’s up?'), findsOneWidget);
      expect(controller.hasNotificationAccess, isFalse);
    },
  );

  testWidgets('saying no to nudges still moves on', (tester) async {
    final notifications = FakeNotificationGateway(allow: false);
    final controller = newUser(notifications: notifications);
    await pump(tester, controller);
    await walkTo(tester, 'Want a quiet nudge when time’s up?');

    await tapText(tester, 'Yes, nudge me');
    expect(notifications.requests, 1);
    expect(
      find.text(
        'No problem. You can turn quiet nudges on later in Curre settings.',
      ),
      findsOneWidget,
    );
    expect(find.text('Which apps will your plans need?'), findsOneWidget);
  });

  testWidgets('not now saves every quiet nudge as off', (tester) async {
    final controller = newUser();
    await pump(tester, controller);
    await walkTo(tester, 'Want a quiet nudge when time’s up?');

    await tapText(tester, 'Not now');

    expect(find.text('Which apps will your plans need?'), findsOneWidget);
    final use = find.textContaining(RegExp(r'^Use these \d+ apps$'));
    await tapText(tester, tester.widget<Text>(use).data!);
    await tapText(tester, 'I’ll plan later');

    expect(controller.settings.hasAnyNudges, isFalse);
  });

  testWidgets('plans need at least two apps', (tester) async {
    final controller = newUser();
    await pump(tester, controller);
    await walkTo(tester, 'Which apps will your plans need?');

    // Untick every suggestion until fewer than two remain.
    for (
      var picked = find.textContaining(RegExp(r'^Use these \d+ apps$'));
      picked.evaluate().isNotEmpty;
      picked = find.textContaining(RegExp(r'^Use these \d+ apps$'))
    ) {
      final selected = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.selected == true &&
            widget.properties.button == true,
      );
      await tester.ensureVisible(selected.first);
      await tester.tap(selected.first);
      await settle(tester);
    }
    expect(find.text('Pick at least 2'), findsOneWidget);
    expect(find.text('Pick at least 2 apps'), findsOneWidget);
  });

  testWidgets('“I’ll plan later” finishes without opening a plan', (
    tester,
  ) async {
    final controller = newUser();
    await pump(tester, controller);
    await walkTo(tester, 'Which apps will your plans need?');
    final use = find.textContaining(RegExp(r'^Use these \d+ apps$'));
    await tapText(tester, tester.widget<Text>(use).data!);
    await tapText(tester, 'I’ll plan later');
    await settle(tester);

    expect(controller.onboardingComplete, isTrue);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(CheckinScreen), findsNothing);
  });

  testWidgets('if the phone can’t save, every answer stays for a retry', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = FailingStore(await SharedPreferences.getInstance());
    final controller = newUser(store: store);
    await pump(tester, controller);
    await walkTo(tester, 'Which apps will your plans need?');
    final use = find.textContaining(RegExp(r'^Use these \d+ apps$'));
    await tapText(tester, tester.widget<Text>(use).data!);
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

    for (final action in <String>[
      'Show me how',
      'Sounds fair',
      'None of these',
    ]) {
      await tapText(tester, action);
      expect(tester.takeException(), isNull);
    }
    await tester.enterText(find.byType(TextField), 'Chidiebere');
    await settle(tester);
    for (final action in <String>[
      'Call me Chidiebere',
      'Use my initial',
      'Mornings start at 04:00',
      'Make Curre my home screen',
      'Continue',
      'Skip for now',
      'Skip for now',
      'Not now',
    ]) {
      await tapText(tester, action);
      expect(tester.takeException(), isNull);
    }
    expect(find.text('Which apps will your plans need?'), findsOneWidget);
  });
}
