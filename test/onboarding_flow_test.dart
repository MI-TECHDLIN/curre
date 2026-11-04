import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:curre/app/checkin_screen.dart';
import 'package:curre/app/curre_controller.dart';
import 'package:curre/app/home_screen.dart';
import 'package:curre/app/onboarding/onboarding_parts.dart';
import 'package:curre/app/onboarding_screen.dart';
import 'package:curre/app/privacy_details_screen.dart';
import 'package:curre/core/core.dart';
import 'package:curre/main.dart';
import 'package:curre/platform/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/copy_rules.dart';
import 'support/fakes.dart';

const _instagram = 'com.instagram.android';
const _netflix = 'com.netflix.mediaclient';
const _youtube = 'com.google.android.youtube';
const _dialer = 'com.google.android.dialer';
const _settings = 'com.android.settings';

/// A 1×1 PNG: enough for an app icon the phone gives.
final _icon = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// A phone whose icons arrive only when the test says so.
class _SlowIconPlatform extends FakeDoorPlatform {
  _SlowIconPlatform({super.home});

  final pending = <String, Completer<Uint8List?>>{};
  final asked = <String>[];

  @override
  Future<Uint8List?> getIcon(String packageName) {
    asked.add(packageName);
    return pending.putIfAbsent(packageName, Completer<Uint8List?>.new).future;
  }
}

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

  testWidgets('About you asks what the focus is for and until when', (
    tester,
  ) async {
    final controller = newUser();
    await pump(tester, controller);
    await walkTo(tester, 'What should Curre call you?');
    await tester.enterText(find.byType(TextField), 'Ada');
    await settle(tester);
    expect(find.text('What’s this focus for?'), findsOneWidget);
    for (final purpose in FocusPurpose.values) {
      expect(find.text(purpose.label), findsOneWidget);
    }
    await tapText(tester, 'Breaking a habit');
    // A habit starts at 21 days.
    expect(find.textContaining('in 21 days'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('focus-goal')),
      'Stop scrolling at night',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('focus-length-7')));
    await tester.tap(find.byKey(const ValueKey('focus-length-7')));
    await settle(tester);
    expect(find.textContaining('in 7 days'), findsOneWidget);
    for (final text in visibleCopy(tester)) {
      expect(bannedWordsIn(text), isEmpty, reason: text);
    }

    await tapText(tester, 'Call me Ada');
    await tapText(tester, 'None of these');
    await tapText(tester, 'Make Curre my home screen');
    await tapText(tester, 'Continue');
    await tapText(tester, 'I’ll plan later');

    final focus = controller.settings.focus!;
    expect(focus.purpose, FocusPurpose.habit);
    expect(focus.goal, 'Stop scrolling at night');
    expect(focus.lengthInDays, 7);
  });

  testWidgets('skipping the focus is fine; Home offers it later', (
    tester,
  ) async {
    final controller = newUser();
    await pump(tester, controller);
    await walkTo(tester, 'What’s this morning for?');
    await tapText(tester, 'I’ll plan later');
    expect(controller.settings.focus, isNull);
    expect(find.byKey(const Key('home-focus-offer')), findsOneWidget);
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
  Finder chipFor(String packageName) => find.byKey(ValueKey(packageName));

  Finder inside(Finder parent, Finder child) =>
      find.descendant(of: parent, matching: child);

  testWidgets('the app picker shows each app’s own icon, or its letter', (
    tester,
  ) async {
    final home = FakeHomePlatform(isHome: false);
    final controller = newUser(
      home: home,
      platform: FakeDoorPlatform(
        home: home,
        icons: {_instagram: _icon, _youtube: _icon, _dialer: _icon},
      ),
    );
    await pump(tester, controller);
    await walkTo(tester, 'What pulls you in?');
    await settle(tester);

    // Apps the phone has icons for show them, as Home does.
    for (final package in [_instagram, _youtube]) {
      expect(inside(chipFor(package), find.byType(Image)), findsOneWidget);
      expect(inside(chipFor(package), find.byType(AppMonogram)), findsNothing);
    }
    // Without one, the app's letter stands in.
    expect(inside(chipFor(_netflix), find.byType(Image)), findsNothing);
    expect(inside(chipFor(_netflix), find.byType(AppMonogram)), findsOneWidget);
    // The essentials show theirs too.
    expect(inside(chipFor(_dialer), find.byType(Image)), findsOneWidget);
    expect(
      inside(chipFor(_settings), find.byType(AppMonogram)),
      findsOneWidget,
    );

    // Choosing still works and still reads as the app's name.
    final semantics = tester.ensureSemantics();
    await tapText(tester, 'Instagram');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Instagram').first),
      isSemantics(label: 'Instagram', isSelected: true, isButton: true),
    );
    expect(find.text('Hide this one'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a neutral tile holds an icon’s place while it loads', (
    tester,
  ) async {
    final home = FakeHomePlatform(isHome: false);
    final platform = _SlowIconPlatform(home: home);
    final controller = newUser(home: home, platform: platform);
    await pump(tester, controller);
    await walkTo(tester, 'What pulls you in?');
    await settle(tester);

    // Nothing has arrived: the list is there, with plain tiles.
    expect(find.text('Instagram'), findsOneWidget);
    expect(inside(chipFor(_instagram), find.byType(Image)), findsNothing);
    expect(inside(chipFor(_instagram), find.byType(AppMonogram)), findsNothing);
    await tapText(tester, 'Instagram');
    expect(find.text('Hide this one'), findsOneWidget);

    platform.pending[_instagram]!.complete(_icon);
    platform.pending[_netflix]!.complete(null);
    await settle(tester);
    expect(inside(chipFor(_instagram), find.byType(Image)), findsOneWidget);
    expect(inside(chipFor(_netflix), find.byType(AppMonogram)), findsOneWidget);
    // Each icon is asked for once, however often the list redraws.
    expect(platform.asked.where((p) => p == _instagram), hasLength(1));
  });

  testWidgets('icons fit a small phone at twice the text size', (tester) async {
    final home = FakeHomePlatform(isHome: false);
    final controller = newUser(
      home: home,
      platform: FakeDoorPlatform(
        home: home,
        icons: {
          for (final app in CurreController.fallbackApps)
            app.packageName: _icon,
        },
      ),
    );
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(CurreApp(controller: controller));
    await settle(tester);
    await walkTo(tester, 'What pulls you in?');
    await settle(tester);
    expect(tester.takeException(), isNull);
    final showAll = find.textContaining('Show all');
    if (showAll.evaluate().isNotEmpty) {
      await tapText(tester, tester.widget<Text>(showAll.last).data!);
    }
    await tapText(tester, 'Instagram');
    await tapText(tester, 'Netflix');
    expect(find.text('Hide these 2'), findsOneWidget);
    await tester.ensureVisible(chipFor(_dialer));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });
  group('when Android starts Curre afresh mid-onboarding', () {
    // Making Curre the home screen can start a second Curre (Android's Home
    // task) or a new process: a new controller and widget tree over the
    // same saved data. These rebuild exactly that.
    late SharedPreferences preferences;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      preferences = await SharedPreferences.getInstance();
    });

    Future<CurreController> startAfresh(
      WidgetTester tester,
      FakeHomePlatform home,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final controller = newUser(
        home: home,
        platform: FakeDoorPlatform(home: home),
        store: CurreLocalStore(preferences),
      );
      await pump(tester, controller);
      await settle(tester);
      return controller;
    }

    /// Leaves Curre and comes back, through every state Android reports.
    void leaveAndComeBack(WidgetTester tester) {
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
    }

    Future<void> answerFirstSteps(WidgetTester tester) async {
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
      await tapText(tester, 'Netflix');
    }

    testWidgets('it picks up at the apps step with the answers kept', (
      tester,
    ) async {
      final home = FakeHomePlatform(isHome: false);
      await startAfresh(tester, home);
      await answerFirstSteps(tester);
      // Leaving Curre mid-step keeps what was picked on this step too.
      leaveAndComeBack(tester);

      await startAfresh(tester, home);
      expect(find.text('What pulls you in?'), findsOneWidget);
      expect(find.text('3 / 5'), findsOneWidget);
      expect(find.text('Hide these 2'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back'));
      await settle(tester);
      expect(find.text('Call me Ada'), findsOneWidget);
    });

    testWidgets('once Curre is Home, it goes on to the first plan', (
      tester,
    ) async {
      final home = FakeHomePlatform(isHome: false);
      await startAfresh(tester, home);
      await answerFirstSteps(tester);
      await tapText(tester, 'Hide these 2');
      expect(find.text('Make Curre your home screen.'), findsOneWidget);
      await tapText(tester, 'Make Curre my home screen');

      // Android makes Curre Home and starts it again.
      final controller = await startAfresh(tester, home);
      expect(find.text('What’s this morning for?'), findsOneWidget);
      expect(find.text('5 / 5'), findsOneWidget);
      await tapText(tester, 'I’ll plan later');
      await settle(tester);

      expect(controller.onboardingComplete, isTrue);
      expect(controller.settings.displayName, 'Ada');
      expect(controller.settings.avatarId, 'avatar-03');
      expect(controller.settings.candidates, isNot(contains(_instagram)));
      expect(controller.settings.candidates, isNot(contains(_netflix)));
      // Finishing forgets the half-way answers.
      expect(CurreLocalStore(preferences).loadOnboardingDraft(), isNull);
    });

    testWidgets('if Curre isn’t Home yet, it waits on the Home step', (
      tester,
    ) async {
      final home = FakeHomePlatform(isHome: false);
      final platform = FakeDoorPlatform(home: home)..grantHome = false;
      SharedPreferences.setMockInitialValues(<String, Object>{});
      preferences = await SharedPreferences.getInstance();
      await tester.pumpWidget(const SizedBox());
      await pump(
        tester,
        newUser(
          home: home,
          platform: platform,
          store: CurreLocalStore(preferences),
        ),
      );
      await answerFirstSteps(tester);
      await tapText(tester, 'Hide these 2');

      await startAfresh(tester, home);
      expect(find.text('Make Curre your home screen.'), findsOneWidget);
      expect(find.text('4 / 5'), findsOneWidget);
    });

    testWidgets('the first Curre catches up when the other one finished', (
      tester,
    ) async {
      final home = FakeHomePlatform(isHome: false);
      final store = CurreLocalStore(preferences);
      final first = newUser(home: home, store: store);
      await pump(tester, first);
      await walkTo(tester, 'What’s this morning for?');

      // The second Curre (Android's Home) finishes onboarding meanwhile.
      final second = newUser(home: home, store: store);
      await second.finishOnboarding(
        displayName: 'Ada',
        avatarId: null,
        essentials: second.suggestedEssentials,
        candidates: {_youtube, 'com.google.android.gm'},
        morningStart: const LocalTime(6),
        firstIntention: null,
      );

      leaveAndComeBack(tester);
      await settle(tester);
      expect(first.onboardingComplete, isTrue);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
