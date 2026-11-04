import 'dart:convert';

import 'package:curre/app/curre_controller.dart';
import 'package:curre/app/hidden_apps_screen.dart';
import 'package:curre/app/settings_screen.dart';
import 'package:curre/core/core.dart';
import 'package:curre/design/design.dart';
import 'package:curre/main.dart';
import 'package:curre/platform/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/copy_rules.dart';
import 'support/fakes.dart';

const _monday = LocalDate(2026, 10, 26);

FocusPeriod _focus({
  LocalDate startsOn = _monday,
  int days = 14,
  FocusPurpose purpose = FocusPurpose.exams,
  String goal = 'Pass my maths finals',
}) => FocusPeriod(
  purpose: purpose,
  goal: goal,
  startsOn: startsOn,
  endsOn: startsOn.addDays(days),
);

Settings _settings({FocusPeriod? focus}) => Settings(
  displayName: 'Chidi',
  essentials: const {
    'com.google.android.dialer',
    'com.google.android.apps.messaging',
    'com.android.settings',
  },
  candidates: const {
    'com.google.android.youtube',
    'com.spotify.music',
    'com.google.android.apps.maps',
  },
  hiddenApps: const {'com.instagram.android', 'com.netflix.mediaclient'},
  focus: focus,
);

ProofRecord _proof(LocalDate day, String task) => ProofRecord(
  id: 'proof-$task',
  taskId: task,
  planId: 'plan-$task',
  date: day,
  taskText: '',
  note: '',
  submittedAt: DateTime.utc(day.year, day.month, day.day, 12),
  level: ProofLevel.supported,
  judgement: ProofJudgement.accepted,
  traceId: 'trace-$task',
  specificCompletion: .9,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FocusPeriod', () {
    test('counts days left and ends on its end date', () {
      final focus = _focus();
      expect(focus.lengthInDays, 14);
      expect(focus.daysLeft(_monday), 14);
      expect(focus.daysLeft(_monday.addDays(13)), 1);
      expect(focus.isOverOn(_monday.addDays(13)), isFalse);
      expect(focus.isOverOn(_monday.addDays(14)), isTrue);
      expect(focus.daysLeft(_monday.addDays(20)), 0);
      expect(focus.title, 'Pass my maths finals');
      expect(_focus(goal: '  ').title, 'Exams');
    });

    test('a habit runs 21 days unless another length is picked', () {
      final habit = const FocusChoice(purpose: FocusPurpose.habit)
          .periodFrom(_monday);
      expect(habit.endsOn, _monday.addDays(21));
      final week = const FocusChoice(
        purpose: FocusPurpose.habit,
        days: 7,
      ).periodFrom(_monday);
      expect(week.endsOn, _monday.addDays(7));
      final dated = FocusChoice(
        purpose: FocusPurpose.deadline,
        endsOn: _monday.addDays(40),
      ).periodFrom(_monday);
      expect(dated.endsOn, _monday.addDays(40));
      expect(FocusPurpose.deadline.defaultDays, 14);
    });

    test('is saved with the settings, and older settings still load', () {
      final settings = _settings(focus: _focus());
      final restored = Settings.fromJson(
        jsonDecode(jsonEncode(settings.toJson())) as Map<String, Object?>,
      );
      expect(restored.focus, _focus());

      final older = settings.toJson()
        ..remove('focus')
        ..remove('focusNudges')
        ..remove('everySessionNudges');
      final loaded = Settings.fromJson(older);
      expect(loaded.focus, isNull);
      expect(loaded.focusNudges, isTrue);
      // People who set up before keep the three reminders a day they had.
      expect(loaded.everySessionNudges, isTrue);

      final broken = settings.toJson()..['focus'] = {'purpose': 'nap'};
      expect(Settings.fromJson(broken).focus, isNull);
    });

    test('new setups get gentler reminders: one a day, proof opt-in', () {
      final fresh = Settings();
      expect(fresh.checkInNudges, isTrue);
      expect(fresh.everySessionNudges, isFalse);
      expect(fresh.proofNudges, isFalse);
      expect(fresh.focusNudges, isTrue);
    });
  });

  test('onboarding keeps a half-picked focus across a restart', () {
    const draft = OnboardingDraft(
      step: 'you',
      focusPurpose: 'deadline',
      focusGoal: 'Ship the report',
      focusEndsOn: '2026-11-20',
    );
    final restored = OnboardingDraft.fromJson(
      jsonDecode(jsonEncode(draft.toJson())) as Map<String, Object?>,
    );
    expect(restored.focusPurpose, 'deadline');
    expect(restored.focusGoal, 'Ship the report');
    expect(restored.focusEndsOn, '2026-11-20');
    expect(restored.focusDays, isNull);
    // Drafts saved before focus periods still load.
    expect(OnboardingDraft.fromJson({'step': 'pull'}).focusPurpose, isNull);
  });

  group('rest days', () {
    test('one in any seven days', () {
      expect(RestDayRules.canRest(_monday, const []), isTrue);
      final taken = [_monday];
      expect(RestDayRules.canRest(_monday, taken), isFalse);
      expect(RestDayRules.canRest(_monday.addDays(6), taken), isFalse);
      expect(
        RestDayRules.nextAllowed(_monday.addDays(3), taken),
        _monday.addDays(7),
      );
      expect(RestDayRules.canRest(_monday.addDays(7), taken), isTrue);
    });

    test('never end a Prooflight run', () {
      final records = [_proof(_monday, 'a'), _proof(_monday.addDays(1), 'b')];
      final today = _monday.addDays(4);
      // Two empty days in a row end a run...
      final without = ProoflightRules.summarize(records: records, today: today);
      expect(without.currentRun, 0);
      expect(without.lastEndedRun, 2);
      // ...but a rest day is skipped, so one empty day is forgiven.
      final rested = ProoflightRules.summarize(
        records: records,
        today: today,
        restDays: [_monday.addDays(2)],
      );
      expect(rested.currentRun, 2);
      expect(rested.betweenRuns, isFalse);
      expect(rested.cloudDays, 0);
    });

    test('proof on a rest day still counts', () {
      final summary = ProoflightRules.summarize(
        records: [_proof(_monday, 'a'), _proof(_monday.addDays(1), 'b')],
        today: _monday.addDays(1),
        restDays: [_monday.addDays(1)],
      );
      expect(summary.currentRun, 2);
    });
  });

  test('a focus summary counts proof, rest and apps left closed', () {
    final focus = _focus(days: 7);
    final summary = FocusSummary.of(
      focus: focus,
      today: _monday.addDays(9),
      proofRecords: [
        _proof(_monday, 'a'),
        _proof(_monday, 'b'),
        _proof(_monday.addDays(3), 'c'),
        _proof(_monday.addDays(8), 'after'),
      ],
      attempts: [
        Attempt(
          at: DateTime.utc(2026, 10, 27, 10),
          packageName: 'com.instagram.android',
          outcome: UnlockOutcome.later,
          confidence: .8,
          overridden: false,
        ),
        Attempt(
          at: DateTime.utc(2026, 10, 27, 11),
          packageName: 'com.instagram.android',
          outcome: UnlockOutcome.flagged,
          confidence: .8,
          overridden: true,
        ),
        Attempt(
          at: DateTime.utc(2026, 10, 28, 11),
          packageName: 'com.whatsapp',
          outcome: UnlockOutcome.open,
          confidence: .9,
          overridden: false,
        ),
      ],
      restDays: [_monday.addDays(5)],
      curreDay: LocalDate.fromLocalDateTime,
    );
    expect(summary.days, 7);
    expect(summary.restDays, 1);
    expect(summary.proofDays, 2);
    expect(summary.proofs, 3);
    expect(summary.opensAvoided, 1);
  });

  group('the controller', () {
    test('a rest day relaxes the check, quieting and reminders', () async {
      final gateway = FakeReminderGateway();
      final intercept = FakeGentleIntercept(usage: true, notifications: true);
      final controller = fakeController(
        settings: _settings(focus: _focus()),
        gentleIntercept: intercept,
        reminders: LocalReminderService(
          gateway,
          now: () => DateTime(2026, 10, 26, 6, 40),
        ),
      );
      await controller.initializeGentleIntercept();
      expect(controller.gentleInterceptSnapshot.enabled, isTrue);
      expect(controller.canRestToday, isTrue);

      expect(await controller.takeRestDay(), isTrue);

      expect(controller.isRestDay, isTrue);
      expect(controller.gentleInterceptSnapshot.enabled, isFalse);
      expect(controller.quietNotificationSnapshot.enabled, isFalse);
      // Android keeps checking, but every app is allowed until tomorrow's
      // morning start, so the check comes back by itself.
      final tomorrow = DateTime(2026, 10, 27, 4).toUtc();
      expect(intercept.intercept!.enabled, isTrue);
      expect(
        intercept.intercept!.allowedUntilUtc['com.instagram.android'],
        tomorrow,
      );
      expect(
        intercept.quieting!.allowedUntilUtc['com.instagram.android'],
        tomorrow,
      );
      // No "Plan your day" on the rest day itself; tomorrow's is still set.
      final dates = gateway
          .pendingOf(CurreNotificationType.checkIn)
          .map((reminder) => LocalDate.fromLocalDateTime(reminder.scheduledAt));
      expect(dates, isNot(contains(_monday)));
      expect(dates, contains(_monday.addDays(1)));
      // One a week.
      expect(controller.canRestToday, isFalse);
      expect(await controller.takeRestDay(), isFalse);
      expect(controller.nextRestDay, _monday.addDays(7));

      await controller.endRestDay();
      expect(controller.isRestDay, isFalse);
      expect(controller.gentleInterceptSnapshot.enabled, isTrue);
      expect(
        intercept.intercept!.allowedUntilUtc['com.instagram.android'],
        isNull,
      );
    });

    test('a plan made on a rest day sends no reminders', () async {
      final gateway = FakeReminderGateway();
      final controller = fakeController(
        settings: _settings(focus: _focus()).copyWith(proofNudges: true),
        restDays: const [_monday],
        reminders: LocalReminderService(
          gateway,
          now: () => DateTime(2026, 10, 26, 6, 40),
        ),
      );
      await controller.buildManualPlan('Revise algebra', [
        'com.google.android.youtube',
      ]);
      expect(gateway.pendingOf(CurreNotificationType.planEnding), isEmpty);
      expect(gateway.pendingOf(CurreNotificationType.proof), isEmpty);
    });

    test('rest days are kept on the phone, and only during a focus', () async {
      SharedPreferences.setMockInitialValues({});
      final store = CurreLocalStore(await SharedPreferences.getInstance());
      final idle = fakeController(store: store);
      expect(idle.canRestToday, isFalse);

      final controller = fakeController(
        store: store,
        settings: _settings(focus: _focus()),
      );
      await controller.takeRestDay();
      expect(store.loadRestDays(), [_monday]);
      await store.clearHistory();
      expect(store.loadRestDays(), [_monday]);
    });

    test('the focus end notification follows the focus', () async {
      final gateway = FakeReminderGateway();
      final controller = fakeController(
        settings: _settings(),
        reminders: LocalReminderService(
          gateway,
          now: () => DateTime(2026, 10, 26, 6, 40),
        ),
      );
      await controller.startFocus(
        const FocusChoice(purpose: FocusPurpose.exams, days: 7),
      );
      final end = gateway.pending[LocalReminderService.focusEndId]!;
      expect(end.type, CurreNotificationType.focus);
      expect(end.destination, CurreNotificationDestination.home);
      expect(end.title, 'Your focus is done');
      // The morning start (04:00) is in quiet hours, so it waits for 07:00.
      expect(end.scheduledAt, DateTime(2026, 11, 2, 7));

      await controller.changeFocusEnd(_monday.addDays(10));
      expect(
        gateway.pending[LocalReminderService.focusEndId]!.scheduledAt,
        DateTime(2026, 11, 5, 7),
      );

      await controller.updateSettings(
        controller.settings.copyWith(focusNudges: false),
      );
      expect(gateway.pending[LocalReminderService.focusEndId], isNull);

      await controller.updateSettings(
        controller.settings.copyWith(focusNudges: true),
      );
      await controller.endFocusNow();
      expect(controller.focusIsOver, isTrue);
      expect(gateway.pending[LocalReminderService.focusEndId], isNull);
    });

    test(
      'going back to the old home screen stops the check and quieting',
      () async {
        final homeSettings = FakeHomeSettings();
        final intercept = FakeGentleIntercept(usage: true, notifications: true);
        final gateway = FakeReminderGateway();
        final controller = fakeController(
          settings: _settings(focus: _focus(startsOn: _monday.addDays(-14))),
          homeSettings: homeSettings,
          gentleIntercept: intercept,
          reminders: LocalReminderService(
            gateway,
            now: () => DateTime(2026, 10, 26, 6, 40),
          ),
        );
        expect(controller.focusIsOver, isTrue);

        final opened = await controller.leaveForOldHomeScreen();

        expect(opened, HomeSettingsOpened.homeApps);
        expect(homeSettings.calls, 1);
        expect(controller.focus, isNull);
        expect(controller.settings.askWhyOnHiddenAppOpen, isFalse);
        expect(controller.settings.quietNotificationsFromHiddenApps, isFalse);
        expect(controller.settings.checkInNudges, isFalse);
        expect(intercept.intercept!.enabled, isFalse);
        expect(intercept.quieting!.enabled, isFalse);
        expect(gateway.pendingOf(CurreNotificationType.checkIn), isEmpty);
      },
    );

    test('another home screen pauses the check and quieting', () async {
      final home = FakeHomePlatform(isHome: false);
      final intercept = FakeGentleIntercept(usage: true, notifications: true);
      final controller = fakeController(home: home, gentleIntercept: intercept);
      await controller.refresh();
      expect(controller.pausedAwayFromHome, isTrue);
      expect(intercept.intercept!.enabled, isFalse);
      expect(intercept.quieting!.enabled, isFalse);
      expect(controller.gentleInterceptSnapshot.enabled, isFalse);
      // The switches themselves stay as the user set them.
      expect(controller.settings.askWhyOnHiddenAppOpen, isTrue);

      home.isHome = true;
      await controller.refresh();
      expect(controller.pausedAwayFromHome, isFalse);
      expect(intercept.intercept!.enabled, isTrue);
      expect(intercept.quieting!.enabled, isTrue);
    });

    test('onboarding saves the focus picked', () async {
      final controller = fakeController(onboardingComplete: false);
      await controller.finishOnboarding(
        displayName: 'Ada',
        avatarId: null,
        essentials: const {},
        candidates: const {'com.google.android.youtube', 'com.spotify.music'},
        focus: const FocusChoice(
          purpose: FocusPurpose.habit,
          goal: 'Stop scrolling at night',
        ),
      );
      expect(controller.focus!.purpose, FocusPurpose.habit);
      expect(controller.focus!.startsOn, _monday);
      expect(controller.focus!.endsOn, _monday.addDays(21));
    });
  });

  group('on screen', () {
    Future<void> show(WidgetTester tester, CurreController controller) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        CurreApp(controller: controller, themeMode: ThemeMode.light),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
    }

    void expectPlainWords(WidgetTester tester) {
      for (final text in visibleCopy(tester)) {
        expect(bannedWordsIn(text), isEmpty, reason: text);
      }
    }

    testWidgets('people without a focus get a gentle offer they can put away', (
      tester,
    ) async {
      final controller = fakeController(settings: _settings());
      await show(tester, controller);
      expect(find.byKey(const Key('home-focus-offer')), findsOneWidget);
      expectPlainWords(tester);

      await tester.tap(find.text('Set a focus'));
      await tester.pumpAndSettle();
      expect(find.text('What’s this focus for?'), findsOneWidget);
      await tester.tap(find.text('A deadline'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('focus-goal')),
        'Ship the report',
      );
      await tester.tap(find.byKey(const ValueKey('focus-length-7')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ends Mon 2 Nov, in 7 days'), findsOneWidget);
      expectPlainWords(tester);
      await tester.tap(find.text('Start my focus'));
      await tester.pumpAndSettle();

      expect(controller.focus!.title, 'Ship the report');
      expect(find.byKey(const Key('home-focus')), findsOneWidget);
      expect(find.text('7 days left · ends Mon 2 Nov'), findsOneWidget);
    });

    testWidgets('Maybe later puts the offer away', (tester) async {
      final controller = fakeController(settings: _settings());
      await show(tester, controller);
      await tester.tap(find.text('Maybe later'));
      await tester.pump();
      expect(find.byKey(const Key('home-focus-offer')), findsNothing);
      expect(controller.focusOfferDismissed, isTrue);
    });

    testWidgets('Home shows the focus and takes a rest day', (tester) async {
      final controller = fakeController(
        settings: _settings(focus: _focus(startsOn: _monday.addDays(-2))),
      );
      await show(tester, controller);
      expect(find.text('Pass my maths finals'), findsOneWidget);
      expect(find.text('12 days left · ends Sat 7 Nov'), findsOneWidget);

      await tester.tap(find.byKey(const Key('home-take-rest-day')));
      await tester.pumpAndSettle();
      expect(find.text('Take today off?'), findsOneWidget);
      expectPlainWords(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Take today off').last);
      await tester.pumpAndSettle();

      expect(controller.isRestDay, isTrue);
      expect(find.text('Rest day'), findsOneWidget);
      expect(find.text('Back to focus now'), findsOneWidget);
      expectPlainWords(tester);
    });

    testWidgets('a rest day opens hidden apps without asking', (tester) async {
      final platform = FakeDoorPlatform();
      final controller = fakeController(
        platform: platform,
        settings: _settings(focus: _focus()),
        restDays: const [_monday],
      );
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: curreTheme(Brightness.light),
          home: HiddenAppsScreen(controller: controller),
        ),
      );
      await tester.pump();
      expect(find.text('Rest day: they open without asking'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Bring back Instagram'));
      await tester.pumpAndSettle();
      expect(find.text('Why now?'), findsNothing);
      expect(platform.launched, contains('com.instagram.android'));
    });

    testWidgets('the end shows how it went and the way back', (tester) async {
      final homeSettings = FakeHomeSettings();
      final controller = fakeController(
        homeSettings: homeSettings,
        settings: _settings(focus: _focus(startsOn: _monday.addDays(-14))),
        proofRecords: [_proof(_monday.addDays(-10), 'a')],
        restDays: [_monday.addDays(-7)],
      );
      await show(tester, controller);
      expect(find.byKey(const Key('home-focus-end')), findsOneWidget);
      expect(find.text('Your focus is done'), findsOneWidget);
      expect(find.text('14 days of focus, 1 rest day.'), findsOneWidget);
      expect(find.bySemanticsLabel('1 days with proof'), findsOneWidget);
      expect(find.text(FocusPurpose.exams.endLine), findsOneWidget);
      expectPlainWords(tester);

      await tester.ensureVisible(find.text('Go back to my old home screen'));
      await tester.tap(find.text('Go back to my old home screen'));
      await tester.pumpAndSettle();

      expect(homeSettings.calls, 1);
      expect(controller.focus, isNull);
      expect(controller.settings.askWhyOnHiddenAppOpen, isFalse);
      expect(controller.settings.quietNotificationsFromHiddenApps, isFalse);
      expect(controller.proofRecords, hasLength(1));
    });

    testWidgets('Start another focus period begins a new one', (tester) async {
      final controller = fakeController(
        settings: _settings(focus: _focus(startsOn: _monday.addDays(-14))),
      );
      await show(tester, controller);
      await tester.tap(find.text('Start another focus period'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Breaking a habit'));
      await tester.pumpAndSettle();
      expect(find.textContaining('in 21 days'), findsOneWidget);
      await tester.tap(find.text('Start my focus'));
      await tester.pumpAndSettle();
      expect(controller.focus!.purpose, FocusPurpose.habit);
      expect(controller.focus!.startsOn, _monday);
      expect(find.byKey(const Key('home-focus-end')), findsNothing);
    });

    testWidgets('Settings ends the focus early after one confirm', (
      tester,
    ) async {
      final controller = fakeController(settings: _settings(focus: _focus()));
      tester.view.physicalSize = const Size(390, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: curreTheme(Brightness.light),
          home: SettingsScreen(controller: controller),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('settings-focus')), findsOneWidget);
      expect(find.text('Ends Mon 9 Nov, 14 days left'), findsOneWidget);
      expectPlainWords(tester);

      await tester.tap(find.byKey(const Key('settings-focus-end-now')));
      await tester.pumpAndSettle();
      expect(find.text('End your focus now?'), findsOneWidget);
      await tester.tap(find.text('Keep going'));
      await tester.pumpAndSettle();
      expect(controller.focusIsOver, isFalse);

      await tester.tap(find.byKey(const Key('settings-focus-end-now')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End focus'));
      await tester.pumpAndSettle();
      expect(controller.focusIsOver, isTrue);
      expect(controller.focus!.endsOn, _monday);

      await tester.scrollUntilVisible(
        find.byKey(const Key('nudge-focus')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Focus ends'), findsOneWidget);
    });
  });
}
