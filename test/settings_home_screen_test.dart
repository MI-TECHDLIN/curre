import 'package:curre/app/curre_controller.dart';
import 'package:curre/app/settings_screen.dart';
import 'package:curre/design/design.dart';
import 'package:curre/platform/platform.dart';
import 'package:curre/platform/platform_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> showSettings(
    WidgetTester tester,
    CurreController controller,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: SettingsScreen(controller: controller),
      ),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Your home screen'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Your home screen'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Switch to another home screen'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('Hidden apps in settings', () {
    Future<void> showAccess(WidgetTester tester, String title) async {
      await tester.scrollUntilVisible(
        find.text(title),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
    }

    testWidgets('asks Android for each permission in plain words', (
      tester,
    ) async {
      final access = FakeGentleIntercept();
      final controller = fakeController(gentleIntercept: access);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: curreTheme(Brightness.light),
          home: SettingsScreen(controller: controller),
        ),
      );
      await tester.pump();

      await showAccess(tester, 'Ask “Why now?” when a hidden app opens');
      expect(find.text('Needs your OK in Android first'), findsNWidgets(2));
      await tapText(tester, 'Turn on Usage access');
      expect(access.usageRequests, 1);
      expect(controller.hasUsageAccess, isTrue);
      expect(
        find.text('Done. Curre will ask “Why now?” when a hidden app opens.'),
        findsOneWidget,
      );
      expect(
        find.text('On, even from recent apps, notifications and links'),
        findsOneWidget,
      );

      access.grants = false;
      await showAccess(tester, 'Keep hidden apps quiet');
      await tapText(tester, 'Turn on notification access');
      expect(access.notificationRequests, 1);
      expect(
        find.text('It’s still off. You can turn it on here any time.'),
        findsOneWidget,
      );
      expect(find.text('Needs your OK in Android first'), findsOneWidget);

      // The switch itself is saved like any other setting.
      expect(controller.settings.quietNotificationsFromHiddenApps, isTrue);
      await tester.pump(const Duration(seconds: 10)); // The note goes away.
      await tester.ensureVisible(find.text('Keep hidden apps quiet'));
      await tester.pump();
      await tapText(tester, 'Keep hidden apps quiet');
      expect(controller.settings.quietNotificationsFromHiddenApps, isFalse);
    });
  });

  group('Quiet nudges in settings', () {
    testWidgets('saves each kind and keeps Android permission separate', (
      tester,
    ) async {
      final notifications = FakeNotificationGateway();
      final reminderGateway = _RecordingReminderGateway();
      final controller = fakeController(
        notifications: notifications,
        reminders: LocalReminderService(reminderGateway),
      );
      await showSettings(tester, controller);
      await tester.scrollUntilVisible(
        find.text('Quiet nudges'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(controller.settings.checkInNudges, isTrue);
      await tester.tap(find.byKey(const Key('nudge-check-in')));
      await tester.pumpAndSettle();
      expect(controller.settings.checkInNudges, isFalse);
      expect(controller.settings.planEndingNudges, isTrue);
      expect(reminderGateway.cancelled, containsAll(<int>[1101, 1102, 1103]));
      expect(reminderGateway.scheduled, isEmpty);
      expect(notifications.requests, 0);

      await tapText(tester, 'Turn all quiet nudges off');
      expect(controller.settings.hasAnyNudges, isFalse);
      expect(find.text('Turn all quiet nudges on'), findsOneWidget);
      expect(notifications.requests, 0);

      await tapText(tester, 'Allow notifications');
      expect(notifications.requests, 1);
      expect(
        find.text(
          'Notifications are allowed. Curre will use the quiet nudge choices above.',
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('opens the short privacy details from settings', (tester) async {
    final controller = fakeController();
    await showSettings(tester, controller);
    await tester.scrollUntilVisible(
      find.text('Privacy details'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tapText(tester, 'Privacy details');

    expect(find.text('How long a copy may remain'), findsOneWidget);
    expect(
      find.textContaining(
        'Curre keeps no online copy. The AI service that reads your words may keep a successful answer',
      ),
      findsOneWidget,
    );
    expect(find.text('What stays here'), findsOneWidget);
  });

  group('Switch to another home screen', () {
    testWidgets('explains kindly and opens Android’s home screen choice', (
      tester,
    ) async {
      final homeSettings = FakeHomeSettings();
      final controller = fakeController(homeSettings: homeSettings);
      await showSettings(tester, controller);

      expect(
        find.text(
          'Want a different home screen for a while? That’s okay. Android lets you choose which app opens when you press Home. Your plans and history stay on this phone, and you can switch back any time.',
        ),
        findsOneWidget,
      );
      await tapText(tester, 'Choose a home screen app');
      expect(homeSettings.calls, 1);
      // Android's own picker opened, so there is nothing more to say.
      expect(find.byType(SnackBar), findsNothing);
    });

    for (final (opened, help) in <(HomeSettingsOpened, String)>[
      (
        HomeSettingsOpened.defaultApps,
        'Tap “Home app”, then choose the one you want.',
      ),
      (
        HomeSettingsOpened.settings,
        'Your phone opened Settings. Search for “Home app” (or open Apps, then Default apps), then choose the one you want.',
      ),
      (
        HomeSettingsOpened.none,
        'Open your phone’s Settings app and search for “Home app”. Choose the one you want there.',
      ),
    ]) {
      testWidgets('says what to do next when ${opened.name} opens', (
        tester,
      ) async {
        final homeSettings = FakeHomeSettings(opened);
        final controller = fakeController(homeSettings: homeSettings);
        await showSettings(tester, controller);
        await tapText(tester, 'Choose a home screen app');
        expect(homeSettings.calls, 1);
        expect(find.text(help), findsOneWidget);
      });
    }

    testWidgets('offers the way back when Curre isn’t the home screen', (
      tester,
    ) async {
      final home = FakeHomePlatform(isHome: false);
      final platform = FakeDoorPlatform(home: home, grantHome: false);
      final controller = fakeController(home: home, platform: platform);
      await showSettings(tester, controller);

      expect(
        find.text(
          'Curre isn’t your home screen right now. Your plans and history are still here, ready when you want them.',
        ),
        findsOneWidget,
      );
      await tapText(tester, 'Make Curre my home screen');
      expect(platform.homeRequests, 1);
      expect(
        find.text(
          'Curre isn’t your home screen yet. Open your phone’s Settings, search for “Home app” and choose Curre.',
        ),
        findsOneWidget,
      );

      // The choice is made in Android; coming back shows the real answer.
      home.isHome = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(find.text('Choose a home screen app'), findsOneWidget);
      expect(find.text('Make Curre my home screen'), findsNothing);
    });
  });

  group('Android adapters', () {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(
      () => messenger.setMockMethodCallHandler(currePlatformChannel, null),
    );

    test('home screen settings report which screen opened', () async {
      for (final (answer, opened) in <(String?, HomeSettingsOpened)>[
        ('home', HomeSettingsOpened.homeApps),
        ('defaultApps', HomeSettingsOpened.defaultApps),
        ('settings', HomeSettingsOpened.settings),
        ('none', HomeSettingsOpened.none),
        (null, HomeSettingsOpened.none),
      ]) {
        messenger.setMockMethodCallHandler(currePlatformChannel, (call) async {
          expect(call.method, 'openHomeSettings');
          return answer;
        });
        expect(await const HomeSettingsService().openHomeSettings(), opened);
      }
    });

    test('home screen settings never throw', () async {
      messenger.setMockMethodCallHandler(
        currePlatformChannel,
        (call) async => throw PlatformException(code: 'boom'),
      );
      expect(
        await const HomeSettingsService().openHomeSettings(),
        HomeSettingsOpened.none,
      );
    });
  });
}

class _RecordingReminderGateway implements ReminderNotificationGateway {
  final List<int> cancelled = <int>[];
  final List<CurreReminder> scheduled = <CurreReminder>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> cancelReminder(int id) async => cancelled.add(id);

  @override
  Future<void> scheduleReminder(CurreReminder reminder) async {
    scheduled.add(reminder);
  }
}
