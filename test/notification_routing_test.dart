import 'package:curre/app/checkin_screen.dart';
import 'package:curre/app/hidden_apps_screen.dart';
import 'package:curre/app/settings_screen.dart';
import 'package:curre/core/core.dart';
import 'package:curre/main.dart';
import 'package:curre/platform/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// Where each notification tap lands (lib/main.dart). The proof reminder's
/// route is covered in completion_sheet_test.dart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> show(WidgetTester tester, {bool onboarded = true}) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      CurreApp(
        controller: fakeController(onboardingComplete: onboarded),
        themeMode: ThemeMode.light,
      ),
    );
    await tester.pump();
  }

  Future<void> tapNotification(
    WidgetTester tester,
    CurreNotificationType type,
    CurreNotificationDestination destination, {
    CurreNotificationAction? action,
  }) async {
    CurreNotificationInbox.instance.add(
      CurreNotificationIntent(
        type: type,
        destination: destination,
        action: action,
      ),
    );
    await settle(tester);
  }

  testWidgets('"Plan your day" and "Plan ending" open planning', (
    tester,
  ) async {
    await show(tester);
    await tapNotification(
      tester,
      CurreNotificationType.checkIn,
      CurreNotificationDestination.checkIn,
      action: CurreNotificationAction.startCheckIn,
    );
    expect(find.byType(CheckinScreen), findsOneWidget);
  });

  testWidgets('"App time up" opens Hidden apps', (tester) async {
    await show(tester);
    await tapNotification(
      tester,
      CurreNotificationType.unlockTimeUp,
      CurreNotificationDestination.hiddenApps,
      action: CurreNotificationAction.bringIntoSight,
    );
    expect(find.byType(HiddenAppsScreen), findsOneWidget);
  });

  testWidgets('"Your focus is done" comes back to Home', (tester) async {
    await show(tester);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaitedPush(
      navigator,
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(controller: fakeController()),
      ),
    );
    await settle(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tapNotification(
      tester,
      CurreNotificationType.focus,
      CurreNotificationDestination.home,
    );
    expect(find.byType(SettingsScreen), findsNothing);
  });

  testWidgets('taps are ignored until setup is done', (tester) async {
    await show(tester, onboarded: false);
    await tapNotification(
      tester,
      CurreNotificationType.checkIn,
      CurreNotificationDestination.checkIn,
    );
    expect(find.byType(CheckinScreen), findsNothing);
  });

  test('every kind of notification has its own Android channel', () {
    final ids = {
      for (final type in CurreNotificationType.values)
        FlutterGrantNotificationGateway.channelIdFor(type),
    };
    expect(ids, hasLength(CurreNotificationType.values.length));
    expect(
      FlutterGrantNotificationGateway.channelIdFor(CurreNotificationType.focus),
      'curre_focus',
    );
  });

  test('switching off every nudge includes the focus end', () async {
    final controller = fakeController(
      notifications: FakeNotificationGateway(allow: false),
    );
    expect(controller.settings.hasAnyNudges, isTrue);
    await controller.answerNudgeOffer(allow: true);
    expect(controller.settings.hasAnyNudges, isFalse);
    expect(controller.settings.focusNudges, isFalse);
  });

  test('the per-type switches map to notification kinds', () {
    final policy = CurreNotificationPolicy.fromSettings(
      Settings(
        checkInNudges: false,
        planEndingNudges: true,
        unlockTimeUpNudges: false,
        proofNudges: true,
        focusNudges: false,
      ),
    );
    expect(policy.enabled, {
      CurreNotificationType.planEnding,
      CurreNotificationType.proof,
    });
  });
}

/// Lets a route finish moving; Home's sky never stops, so it can't settle.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void unawaitedPush(NavigatorState navigator, Route<void> route) {
  navigator.push(route);
}
