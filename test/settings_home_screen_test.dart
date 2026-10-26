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
