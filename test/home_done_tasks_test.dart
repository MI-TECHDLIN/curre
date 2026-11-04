import 'package:curre/app/app_widgets.dart';
import 'package:curre/app/curre_controller.dart';
import 'package:curre/app/history_screen.dart';
import 'package:curre/app/home_screen.dart';
import 'package:curre/core/core.dart';
import 'package:curre/design/design.dart';
import 'package:curre/main.dart';
import 'package:curre/platform/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/copy_rules.dart';
import 'support/fakes.dart';

const _youtube = 'com.google.android.youtube';
const _spotify = 'com.spotify.music';
const _maps = 'com.google.android.apps.maps';
const _whatsapp = 'com.whatsapp';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> showHome(WidgetTester tester, CurreController controller) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(CurreApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  }

  /// Saves a plan through the controller, so its reminders are scheduled
  /// as they are on a phone.
  Future<Plan> plan(CurreController controller, List<String> packages) =>
      controller.buildManualPlan('Reply to Ada, then practise', packages);

  PlannedTask door(Plan plan, String package) => PlannedTask.forDoor(
    plan,
    plan.apps.firstWhere((app) => app.packageName == package),
  );

  void record(CurreController controller, ProofRecord record) {
    controller.proofRecords = <ProofRecord>[
      ...controller.proofRecords.where((item) => item.id != record.id),
      record,
    ];
  }

  ProofRecord proved(CurreController controller, PlannedTask task) =>
      ProoflightRules.recordFromResponse(
        task: task,
        note: 'I replied to Ada about Friday',
        submittedAt: controller.now,
        response: const ProofResponse(
          outcome: ProofOutcome.accepted,
          kind: ProofKind.specificCompletion,
          specificCompletion: .94,
          result: SourceSpan(
            text: 'replied to Ada about Friday',
            start: 2,
            end: 29,
          ),
        ),
        trace: TaskTrace.forTask(
          task,
          kind: TaskTraceKind.door,
          at: controller.now.subtract(const Duration(minutes: 10)),
        ),
      );

  ProofRecord waiting(CurreController controller, PlannedTask task) =>
      ProoflightRules.recordFromResponse(
        task: task,
        note: 'I practised the scales',
        submittedAt: controller.now,
        response: const ProofResponse.pending(),
        trace: TaskTrace.forTask(
          task,
          kind: TaskTraceKind.door,
          at: controller.now.subtract(const Duration(minutes: 10)),
        ),
      );

  ProofRecord checkedOff(CurreController controller, PlannedTask task) =>
      ProoflightRules.checkOff(task: task, at: controller.now);

  double top(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  group('Home task rows', () {
    testWidgets('done app rows say how, and sit under Done today', (
      tester,
    ) async {
      final controller = fakeController();
      final active = await plan(controller, [_youtube, _spotify, _maps]);
      record(controller, proved(controller, door(active, _youtube)));
      record(controller, waiting(controller, door(active, _spotify)));
      await showHome(tester, controller);

      expect(find.text('Done, with proof'), findsOneWidget);
      expect(
        find.text('Done · your note is waiting to be checked'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('done-today')), findsOneWidget);
      expect(find.byKey(const Key('home-all-done')), findsNothing);
      expect(find.text('2 of 3 done'), findsOneWidget);

      // The one still to do stays on top; done rows keep the plan's order.
      expect(
        top(tester, find.text('Maps')),
        lessThan(top(tester, find.text('Done today'))),
      );
      expect(
        top(tester, find.text('YouTube')),
        lessThan(top(tester, find.text('Spotify'))),
      );
      // Supported proof wears the check, like the task away from the phone.
      final youtubeRow = find.ancestor(
        of: find.text('Done, with proof'),
        matching: find.byType(DoorRow),
      );
      expect(
        find.descendant(
          of: youtubeRow,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is CurreGlyph && widget.kind == CurreGlyphKind.check,
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<DoorRow>(youtubeRow).semanticLabel,
        'YouTube, Done, with proof, opens Open app',
      );
      expectPlainCopy(tester, where: 'Home with done tasks');
    });

    testWidgets('a done row still opens its app, without asking again', (
      tester,
    ) async {
      final platform = FakeDoorPlatform();
      final controller = fakeController(platform: platform);
      final active = await plan(controller, [_youtube, _maps]);
      record(controller, waiting(controller, door(active, _youtube)));
      await showHome(tester, controller);

      await tester.tap(find.text('Done · your note is waiting to be checked'));
      await tester.pumpAndSettle();
      expect(platform.launches, 1);
      expect(controller.doorUses.single.packageName, _youtube);
      expect(find.byKey(const Key('completion-note')), findsNothing);

      // Long-press is still the usual launch.
      await tester.longPress(
        find.text('Done · your note is waiting to be checked'),
      );
      await tester.pump();
      expect(platform.launches, 2);
    });

    testWidgets('a checked-off row opens its app, then takes its note', (
      tester,
    ) async {
      final platform = FakeDoorPlatform();
      final controller = fakeController(platform: platform);
      final active = await plan(controller, [_youtube, _maps]);
      record(controller, checkedOff(controller, door(active, _youtube)));
      await showHome(tester, controller);

      expect(find.text('Done · tap to add a note'), findsOneWidget);
      await tester.tap(find.text('Done · tap to add a note'));
      await tester.pumpAndSettle();
      expect(platform.launches, 1);
      expect(find.byKey(const Key('completion-note')), findsOneWidget);
    });

    testWidgets('more than two done rows fold into one line', (tester) async {
      final controller = fakeController();
      final active = await plan(controller, [
        _youtube,
        _spotify,
        _maps,
        _whatsapp,
      ]);
      for (final package in [_youtube, _spotify, _maps]) {
        record(controller, proved(controller, door(active, package)));
      }
      await showHome(tester, controller);

      expect(find.byKey(const Key('done-today-folded')), findsOneWidget);
      expect(find.text('Done today · 3'), findsOneWidget);
      expect(find.text('Done, with proof'), findsNothing);
      // The task still to do is untouched.
      expect(find.text('WhatsApp'), findsOneWidget);

      await tester.tap(find.byKey(const Key('done-today-folded')));
      await tester.pump();
      expect(find.text('Done, with proof'), findsNWidgets(3));
      expect(
        top(tester, find.text('YouTube')),
        lessThan(top(tester, find.text('Spotify'))),
      );
      expect(
        top(tester, find.text('Spotify')),
        lessThan(top(tester, find.text('Maps'))),
      );

      await tester.tap(find.text('Hide'));
      await tester.pump();
      expect(find.text('Done today · 3'), findsOneWidget);
    });
  });

  group('All done', () {
    testWidgets('a still card with the small sun, never on its own', (
      tester,
    ) async {
      final controller = fakeController();
      final active = await plan(controller, [_youtube, _spotify]);
      record(controller, proved(controller, door(active, _youtube)));
      expect(controller.allTasksDone, isFalse);
      record(controller, checkedOff(controller, door(active, _spotify)));
      expect(controller.allTasksDone, isTrue);
      await showHome(tester, controller);

      expect(find.byKey(const Key('home-all-done')), findsOneWidget);
      expect(find.text('All done for this morning'), findsOneWidget);
      expect(find.text('End plan now'), findsOneWidget);
      final sun = tester.widget<ProoflightSun>(
        find.descendant(
          of: find.byKey(const Key('home-all-done')),
          matching: find.byType(ProoflightSun),
        ),
      );
      expect((sun.rays, sun.rise, sun.grow, sun.size), (1, null, 1.0, 56.0));
      // Nothing loops: Home settles with the card on it.
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      expectPlainCopy(tester, where: 'Home, all done');
    });

    test('a plan without apps is all done once its task is', () async {
      final controller = fakeController();
      final active = await plan(controller, const <String>[]);
      expect(controller.allTasksDone, isFalse);
      record(controller, checkedOff(controller, PlannedTask.offline(active)));
      expect(controller.allTasksDone, isTrue);
    });

    test(
      'an earlier task away from the phone still waiting holds it',
      () async {
        var now = DateTime(2026, 10, 26, 5, 10);
        final moving = CurreController(
          launcher: FakeDoorPlatform(),
          apps: CurreController.fallbackApps,
          onboardingComplete: true,
          now: () => now,
        );
        final earlier = await moving.buildManualPlan('Pray', const <String>[]);
        await moving.startOfflineTask(PlannedTask.offline(earlier));
        final ended = earlier.endedEarlyAt(now.add(const Duration(minutes: 5)));
        moving.plans = <Plan>[ended];
        now = DateTime(2026, 10, 26, 6, 40);
        final active = await moving.buildManualPlan('Reply to Ada', [
          _whatsapp,
        ]);
        record(moving, proved(moving, door(active, _whatsapp)));

        expect(moving.activePlanCompletion!.allDone, isTrue);
        expect(moving.allTasksDone, isFalse);
        record(moving, checkedOff(moving, PlannedTask.offline(earlier)));
        expect(moving.allTasksDone, isTrue);
      },
    );
  });

  group('End plan now', () {
    Future<(CurreController, _Reminders, Plan)> allDone(
      WidgetTester tester,
    ) async {
      final reminders = _Reminders();
      final controller = fakeController(
        reminders: LocalReminderService(
          reminders,
          now: () => DateTime(2026, 10, 26, 6, 40),
        ),
      );
      final active = await plan(controller, [_whatsapp, _spotify]);
      record(controller, proved(controller, door(active, _whatsapp)));
      record(controller, waiting(controller, door(active, _spotify)));
      await showHome(tester, controller);
      return (controller, reminders, active);
    }

    Future<void> endPlan(WidgetTester tester, {bool confirm = true}) async {
      await tester.tap(find.text('End plan now'));
      await tester.pumpAndSettle();
      expect(find.text('End this plan now?'), findsOneWidget);
      await tester.tap(find.text(confirm ? 'End plan' : 'Keep it'));
      await tester.pumpAndSettle();
    }

    testWidgets('keeping it changes nothing', (tester) async {
      final (controller, _, active) = await allDone(tester);
      await endPlan(tester, confirm: false);
      await tester.pumpAndSettle();
      expect(controller.activePlan?.id, active.id);
      expect(controller.visiblePackages, contains(_whatsapp));
    });

    testWidgets('ends it, drops its reminders and keeps it in History', (
      tester,
    ) async {
      final (controller, reminders, active) = await allDone(tester);
      expect(controller.visiblePackages, containsAll([_whatsapp, _spotify]));
      final (headsUp, proof) = LocalReminderService.planReminderIds(active.id);
      expect(reminders.scheduled.map((reminder) => reminder.id), [
        headsUp,
        proof,
      ]);
      reminders.cancelled.clear();
      reminders.scheduled.clear();

      await endPlan(tester);

      expect(controller.activePlan, isNull);
      // Its apps weren't hidden by choice, so they still open as usual
      // from All apps; nothing new joins Hidden apps.
      expect(
        controller.openApps.map((app) => app.packageName),
        containsAll([_whatsapp, _spotify]),
      );
      expect(
        controller.hiddenApps.map((app) => app.packageName),
        isNot(contains(_whatsapp)),
      );
      expect(reminders.cancelled, containsAll([headsUp, proof]));
      expect(reminders.scheduled, isEmpty);

      final ended = controller.plans.single;
      expect(ended.endsAt, controller.now.toUtc());
      expect(ended.plannedEndsAt, active.endsAt);
      expect(controller.historyPlans.single.endedEarly, isTrue);
      // The proof it earned stays.
      expect(controller.proofSummary.raysToday, 1);

      expect(find.text('Plan ended.'), findsOne);
      expect(find.byKey(const Key('home-all-done')), findsNothing);
      expect(find.text('Undo'), findsOneWidget);

      // Undo is offered for a few seconds only.
      await tester.pump(endPlanUndoWindow);
      await tester.pumpAndSettle();
      expect(find.text('Undo'), findsNothing);
      expect(controller.activePlan, isNull);
    });

    testWidgets('a settings change never brings its reminders back', (
      tester,
    ) async {
      final (controller, reminders, active) = await allDone(tester);
      await endPlan(tester);
      reminders.scheduled.clear();
      await controller.updateSettings(
        controller.settings.copyWith(planEndingNudges: true),
      );
      final (headsUp, proof) = LocalReminderService.planReminderIds(active.id);
      expect(
        reminders.scheduled.map((reminder) => reminder.id),
        isNot(anyOf(contains(headsUp), contains(proof))),
      );
    });

    testWidgets('Undo brings the plan, its apps and reminders back', (
      tester,
    ) async {
      final (controller, reminders, active) = await allDone(tester);
      await endPlan(tester);
      reminders.scheduled.clear();

      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pump();

      expect(controller.activePlan?.id, active.id);
      expect(controller.activePlan?.endsAt, active.endsAt);
      expect(controller.activePlan?.endedEarly, isFalse);
      expect(controller.historyPlans.single.endedEarly, isFalse);
      expect(controller.visiblePackages, containsAll([_whatsapp, _spotify]));
      final (headsUp, proof) = LocalReminderService.planReminderIds(active.id);
      expect(reminders.scheduled.map((reminder) => reminder.id), [
        headsUp,
        proof,
      ]);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-all-done')), findsOneWidget);
    });

    test('undo does nothing once the planned end has passed', () async {
      var now = DateTime(2026, 10, 26, 6, 40);
      final controller = CurreController(
        launcher: FakeDoorPlatform(),
        apps: CurreController.fallbackApps,
        onboardingComplete: true,
        now: () => now,
      );
      final active = await controller.buildManualPlan('Reply to Ada', [
        _whatsapp,
      ]);
      final original = await controller.endPlanNow();
      expect(original?.id, active.id);
      now = active.endsAt.toLocal().add(const Duration(minutes: 1));
      expect(await controller.undoEndPlan(original!), isFalse);
      expect(controller.plans.single.endedEarly, isTrue);
    });

    testWidgets('History says the plan ended early', (tester) async {
      final (controller, _, active) = await allDone(tester);
      await endPlan(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: curreTheme(Brightness.light),
          home: HistoryScreen(controller: controller),
        ),
      );
      await tester.pump();
      final line = tester.widget<Text>(
        find.byKey(const Key('history-plan-ended-early')),
      );
      expect(line.data, startsWith('Ended early at 06:40, planned until '));
      expect(line.data, endsWith(formatClock(active.endsAt)));
      expectPlainCopy(tester, where: 'History');
    });
  });
}

class _Reminders implements ReminderNotificationGateway {
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
