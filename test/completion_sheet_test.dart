import 'dart:convert';
import 'dart:typed_data';

import 'package:curre/app/completion_sheet.dart';
import 'package:curre/app/curre_controller.dart';
import 'package:curre/core/core.dart';
import 'package:curre/design/design.dart';
import 'package:curre/doors/door_models.dart';
import 'package:curre/main.dart';
import 'package:curre/platform/home_refresh.dart';
import 'package:curre/platform/local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _today = LocalDate(2026, 10, 24);
const _youtube = 'com.google.android.youtube';
const _title = 'YouTube → Search “G chord”';
const _caption = 'switched from G to C without looking';
const _note = 'I switched from G to C without looking';

/// Words Curre never shows a person about their proof: how it is judged,
/// where it goes, what it costs, and loss language (proof audit §3–4).
final _forbidden = RegExp(
  r'Clocked|backend|server|\bAPI\b|network|credit|latency|hackathon|'
  r'verified|\bgate\b|lost|failed|back to zero|streak',
  caseSensitive: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('each state of the sheet', () {
    testWidgets('compose asks the one question, typed or spoken', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_view(CompletionSheetState.compose, onSubmit: null)),
      );

      expect(find.byKey(const Key('proof-compose')), findsOneWidget);
      expect(find.text(_title), findsOneWidget);
      expect(find.text(completionQuestion), findsOneWidget);
      expect(find.byTooltip('Say it instead'), findsOneWidget);
      expect(find.text('Just mark it done'), findsOneWidget);
      // Nothing to send yet.
      final add = tester.widget<Semantics>(
        find.ancestor(
          of: find.text('Add proof'),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.label == 'Add proof',
          ),
        ),
      );
      expect(add.properties.enabled, isFalse);
      _expectCalmCopy(tester);
    });

    testWidgets('a vague note gets one gentle follow-up, by kind', (
      tester,
    ) async {
      for (final (kind, prompt) in <(ProofKind?, String)>[
        (ProofKind.vague, 'A name, a number or a step is enough.'),
        (null, 'A name, a number or a step is enough.'),
        (ProofKind.future, 'That sounds like what comes next.'),
        (ProofKind.unrelated, 'Say how it connects to your plan.'),
      ]) {
        await tester.pumpWidget(
          _host(
            _view(
              CompletionSheetState.vagueFollowUp,
              note: 'done',
              submission: _submission(
                past: const <ProofRecord>[],
                record: _vague(),
                kind: kind,
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('proof-vague-follow-up')), findsOneWidget);
        expect(find.text('Add one detail'), findsOneWidget);
        expect(find.textContaining(prompt), findsOneWidget);
        expect(find.textContaining(completionQuestion), findsOneWidget);
        expect(find.text('done'), findsOneWidget);
        _expectCalmCopy(tester);
      }
    });

    testWidgets('a note that could not be checked is saved, calmly', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_view(CompletionSheetState.pending)));

      expect(find.byKey(const Key('proof-pending')), findsOneWidget);
      expect(find.text('Your note is saved'), findsOneWidget);
      expect(
        find.text(
          'Couldn’t check it right now. It will be checked once you’re back online.',
        ),
        findsOneWidget,
      );
      expect(find.text('Your run stays safe while it waits.'), findsOneWidget);
      _expectCalmCopy(tester);
    });

    testWidgets('a check-off is kept honestly, without a proof day', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_view(CompletionSheetState.selfReported)));

      expect(find.byKey(const Key('proof-self-reported')), findsOneWidget);
      expect(find.text('Marked as done'), findsOneWidget);
      expect(
        find.textContaining('Proof days come from a note'),
        findsOneWidget,
      );
      _expectCalmCopy(tester);
    });

    testWidgets('the thinking state reads the note on the horizon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_view(CompletionSheetState.thinking), reduceMotion: true),
      );

      expect(find.byKey(const Key('proof-thinking')), findsOneWidget);
      expect(find.text('Reading your note…'), findsOneWidget);
      expect(find.byType(HorizonLine), findsOneWidget);
    });
  });

  group('the Prooflight moment', () {
    testWidgets('the first proof raises today’s sun and rolls the count', (
      tester,
    ) async {
      final submission = _submission(
        past: _days(<int>[20, 21, 22, 23]),
        record: _supported(_today),
      );
      await tester.pumpWidget(
        _host(_moment(submission, progress: 0), size: const Size(360, 1000)),
      );
      Avatar avatar() => tester.widget<Avatar>(find.byType(Avatar));
      ProoflightSun sun() =>
          tester.widget<ProoflightSun>(find.byType(ProoflightSun));

      expect(find.byKey(const Key('proof-accepted')), findsOneWidget);
      expect(sun().rise, 0);
      expect(avatar().expression, AvatarExpression.happy);
      expect(avatar().motion, AvatarMotion.still);
      expect(tester.widget<RollingCount>(find.byType(RollingCount)).t, 0);

      await tester.pumpWidget(
        _host(_moment(submission, progress: 1), size: const Size(360, 1000)),
      );
      expect(sun().rise, 1);
      expect(sun().grow, 1);
      expect(sun().rays, 1);
      expect(sun().proofDays, 5);
      // The single happy reaction, once the sun is up.
      expect(avatar().motion, AvatarMotion.reactOnce);
      expect(avatar().proofToday, isTrue);
      final count = tester.widget<RollingCount>(find.byType(RollingCount));
      expect((count.from, count.to, count.t), (4, 5, 1.0));
      expect(find.text('Today’s sun is up'), findsOneWidget);
      expect(find.text('Your note counts as proof.'), findsOneWidget);
      expect(find.text('proof days'), findsOneWidget);
      expect(find.text('Tuesday to Saturday'), findsOneWidget);
      expect(find.text('“$_caption”'), findsOneWidget);
      expect(
        find.text('Backed by the app you opened and your note'),
        findsOneWidget,
      );
      final week = tester.widget<WeekStrip>(find.byType(WeekStrip));
      expect(week.todayLit, 1);
      expect(week.days.map((day) => day.state), <DayState>[
        DayState.quiet,
        DayState.quiet,
        DayState.proof,
        DayState.proof,
        DayState.proof,
        DayState.proof,
        DayState.today,
      ]);
      _expectCalmCopy(tester);
    });

    testWidgets('it plays through once and holds the end', (tester) async {
      final submission = _submission(
        past: _days(<int>[23]),
        record: _supported(_today),
      );
      await tester.pumpWidget(
        _host(_moment(submission), size: const Size(360, 1000)),
      );
      expect(tester.widget<ProoflightSun>(find.byType(ProoflightSun)).rise, 0);

      await tester.pump(const Duration(milliseconds: 1000));
      expect(tester.widget<ProoflightSun>(find.byType(ProoflightSun)).rise, 1);
      await tester.pump(ProoflightMoment.length);
      expect(find.text('2'), findsWidgets);
      expect(
        tester.widget<Avatar>(find.byType(Avatar)).motion,
        AvatarMotion.reactOnce,
      );
    });

    testWidgets('reduced motion shows the end state at once', (tester) async {
      final submission = _submission(
        past: _days(<int>[23]),
        record: _supported(_today),
      );
      await tester.pumpWidget(
        _host(
          _moment(submission),
          size: const Size(360, 1000),
          reduceMotion: true,
        ),
      );
      await tester.pump();

      final sun = tester.widget<ProoflightSun>(find.byType(ProoflightSun));
      expect((sun.rise, sun.grow), (1.0, 1.0));
      expect(tester.widget<RollingCount>(find.byType(RollingCount)).t, 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a second proof today grows one more ray, no new day', (
      tester,
    ) async {
      final submission = _submission(
        past: <ProofRecord>[
          ..._days(<int>[22, 23]),
          _supported(_today),
        ],
        record: _supported(_today, task: 'b', caption: 'replied to Ada'),
      );
      await tester.pumpWidget(
        _host(_moment(submission, progress: 1), size: const Size(360, 1000)),
      );

      expect(find.text('One more ray'), findsOneWidget);
      final sun = tester.widget<ProoflightSun>(find.byType(ProoflightSun));
      expect(sun.rays, 2);
      expect(sun.rise, 1);
      final count = tester.widget<RollingCount>(find.byType(RollingCount));
      expect((count.from, count.to), (3, 3));
      expect(find.text('“replied to Ada”'), findsOneWidget);
    });

    testWidgets('the seventh proof day earns a cloud day and sparks', (
      tester,
    ) async {
      final submission = _submission(
        past: _days(<int>[18, 19, 20, 21, 22, 23]),
        record: _supported(_today),
      );
      await tester.pumpWidget(
        _host(_moment(submission, progress: 1), size: const Size(360, 1100)),
      );

      expect(find.byType(CloudDayMark), findsOneWidget);
      expect(
        find.text(
          'You earned a cloud day. If a day passes without proof, it keeps your run going.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Seven proof days: your rays now end in sparks.'),
        findsOneWidget,
      );
      expect(find.text('Sunday to Saturday'), findsOneWidget);
      _expectCalmCopy(tester);
    });

    testWidgets(
      'after a run ended, a proof starts the next and keeps the record',
      (tester) async {
        final submission = _submission(
          // Twelve days, a cloud on the 20th, then two quiet days ended it.
          past: _days(<int>[for (var day = 8; day <= 19; day++) day]),
          record: _supported(_today),
        );
        expect(submission.before.lastEndedRun, 12);
        await tester.pumpWidget(
          _host(_moment(submission, progress: 1), size: const Size(360, 1100)),
        );

        expect(find.text('Today’s sun is up'), findsOneWidget);
        expect(find.text('proof day'), findsOneWidget);
        expect(find.text('Starting today'), findsOneWidget);
        expect(find.text('A new run starts here.'), findsOneWidget);
        expect(find.text('Best run 12 · 13 proof days in all'), findsOneWidget);
        final week = tester.widget<WeekStrip>(find.byType(WeekStrip));
        expect(week.days[2].state, DayState.cloud);
        _expectCalmCopy(tester);
      },
    );

    testWidgets('a task away from the phone names its Start', (tester) async {
      final plan = _plan('away', apps: const <PlannedApp>[]);
      final task = PlannedTask.offline(plan);
      final record = ProoflightRules.recordFromResponse(
        task: task,
        note: _note,
        submittedAt: DateTime.utc(2026, 10, 24, 7),
        response: _acceptedResponse(),
        trace: TaskTrace.forTask(
          task,
          kind: TaskTraceKind.offlineStart,
          at: DateTime.utc(2026, 10, 24, 6),
        ),
      );
      await tester.pumpWidget(
        _host(
          ProoflightMoment(
            submission: _submission(past: const [], record: record),
            title: 'Away from your phone',
            progress: 1,
            onContinue: () {},
          ),
          size: const Size(360, 1000),
        ),
      );

      expect(find.text('Away from your phone'), findsOneWidget);
      expect(
        find.text('Backed by starting the task and your note'),
        findsOneWidget,
      );
    });
  });

  group('the sheet with Curre behind it', () {
    testWidgets('a proof reminder opens its task with the reply filled in', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = _controller();
      final task = await _openDoor(controller);
      await tester.pumpWidget(
        CurreApp(controller: controller, themeMode: ThemeMode.light),
      );
      await tester.pump();

      CurreNotificationInbox.instance.add(
        CurreNotificationIntent(
          type: CurreNotificationType.proof,
          destination: CurreNotificationDestination.proof,
          action: CurreNotificationAction.addProof,
          reference: task.planId,
          note: _note,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(CompletionSheet), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('completion-note')),
      );
      expect(field.controller!.text, _note);
      expect(controller.proofTaskForPlan(task.planId)?.id, task.id);
    });

    testWidgets('vague, then one detail, then today’s sun', (tester) async {
      final replies = <Map<String, Object?>>[
        <String, Object?>{'outcome': 'vague', 'kind': 'vague'},
        _acceptedJson(),
      ];
      final sent = <String>[];
      final controller = _controller(
        api: _api((body) {
          sent.add(body['note']! as String);
          return replies.removeAt(0);
        }),
      );
      final task = await _openDoor(controller);
      await _openSheet(tester, controller, task);

      await tester.enterText(find.byKey(const Key('completion-note')), 'done');
      await tester.pump();
      await tester.tap(find.text('Add proof'));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('proof-vague-follow-up')), findsOneWidget);
      expect(controller.proofRecords.single.judgement, ProofJudgement.vague);
      // The first answer stays, so one detail can join it.
      expect(find.text('done'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('completion-note')),
        'done, $_note',
      );
      await tester.pump();
      await tester.tap(find.text('Add proof'));
      await tester.pump();
      await tester.pump();

      expect(sent, <String>['done', 'done, $_note']);
      expect(find.byKey(const Key('proof-accepted')), findsOneWidget);
      final record = controller.proofRecords.single;
      expect(record.countsForProoflight, isTrue);
      expect(record.date, _today);
      expect(controller.proofSummary.currentRun, 1);

      await tester.pump(ProoflightMoment.length);
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CompletionSheet), findsNothing);
    });

    testWidgets('a second vague note is kept as done, never asked again', (
      tester,
    ) async {
      final controller = _controller(
        api: _api((_) => <String, Object?>{'outcome': 'vague'}),
      );
      final task = await _openDoor(controller);
      await _openSheet(tester, controller, task);

      for (final note in <String>['done', 'done it']) {
        await tester.enterText(find.byKey(const Key('completion-note')), note);
        await tester.pump();
        await tester.tap(find.text('Add proof'));
        await tester.pump();
        await tester.pump();
      }

      expect(find.byKey(const Key('proof-self-reported')), findsOneWidget);
      expect(controller.proofRecords.single.countsForProoflight, isFalse);
      expect(controller.proofSummary.totalProofDays, 0);
      expect(controller.asksAfterDoor(task), isFalse);
    });

    testWidgets('no answer keeps the note waiting on its own day', (
      tester,
    ) async {
      final controller = _controller(
        api: CurreApiClient(
          baseUrl: Uri.parse('https://curre.test'),
          appKey: 'key',
          httpClient: MockClient((_) async => http.Response('waking', 503)),
        ),
      );
      final task = await _openDoor(controller);
      await _openSheet(tester, controller, task);

      await tester.enterText(find.byKey(const Key('completion-note')), _note);
      await tester.pump();
      await tester.tap(find.text('Add proof'));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('proof-pending')), findsOneWidget);
      final record = controller.proofRecords.single;
      expect(record.isPending, isTrue);
      expect(record.note, _note);
      expect(record.date, _today);
      expect(controller.proofSummary.pendingDates, <LocalDate>{_today});
    });

    testWidgets('just mark it done keeps a local check-off', (tester) async {
      var calls = 0;
      final controller = _controller(
        api: _api((_) {
          calls++;
          return _acceptedJson();
        }),
      );
      final task = await _openDoor(controller);
      await _openSheet(tester, controller, task);

      await tester.enterText(
        find.byKey(const Key('completion-note')),
        'private words',
      );
      await tester.pump();
      await tester.tap(find.text('Just mark it done'));
      await tester.pump();

      expect(calls, 0);
      expect(find.byKey(const Key('proof-self-reported')), findsOneWidget);
      final record = controller.proofRecords.single;
      expect(record.judgement, ProofJudgement.none);
      expect(record.note, 'private words');
      expect(record.countsForProoflight, isFalse);
    });
  });
}

void _expectCalmCopy(WidgetTester tester) {
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final words = text.data ?? text.textSpan?.toPlainText() ?? '';
    expect(words, isNot(matches(_forbidden)), reason: words);
  }
}

Widget _host(
  Widget child, {
  Size size = const Size(360, 800),
  bool reduceMotion = false,
}) => MaterialApp(
  theme: curreTheme(Brightness.light),
  home: MediaQuery(
    data: MediaQueryData(size: size, disableAnimations: reduceMotion),
    child: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    ),
  ),
);

Future<void> _openSheet(
  WidgetTester tester,
  CurreController controller,
  PlannedTask task,
) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_sheetHost(controller, task));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.text(completionQuestion), findsOneWidget);
}

Widget _sheetHost(CurreController controller, PlannedTask task) => MaterialApp(
  theme: curreTheme(Brightness.light),
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () =>
              showCompletionSheet(context, controller: controller, task: task),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

CompletionSheetView _view(
  CompletionSheetState state, {
  String note = '',
  ProofSubmission? submission,
  VoidCallback? onSubmit = _noop,
}) {
  final plan = _plan('today');
  return CompletionSheetView(
    state: state,
    task: PlannedTask.forDoor(plan, plan.apps.single),
    title: _title,
    link: 1,
    noteController: TextEditingController(text: note),
    submission: submission,
    onSubmit: onSubmit,
    onSpeak: _noop,
    onMarkDone: _noop,
    onClose: _noop,
  );
}

ProoflightMoment _moment(ProofSubmission submission, {double? progress}) =>
    ProoflightMoment(
      submission: submission,
      title: _title,
      link: 1,
      avatarId: 'avatar-03',
      displayName: 'Chidi',
      progress: progress,
      onContinue: _noop,
    );

void _noop() {}

Plan _plan(
  String id, {
  LocalDate date = _today,
  List<PlannedApp> apps = const <PlannedApp>[
    PlannedApp(
      packageName: _youtube,
      query: SourceSpan(text: 'G chord', start: 10, end: 17),
    ),
  ],
}) => Plan(
  id: 'plan-$id',
  session: SessionName.morning,
  date: date,
  intention: 'Learn the G chord on YouTube, then pray',
  apps: apps,
  endsAt: DateTime.utc(date.year, date.month, date.day, 9),
  source: PlanSource.clocked,
);

ProofResponse _acceptedResponse({String caption = _caption}) => ProofResponse(
  outcome: ProofOutcome.accepted,
  kind: ProofKind.specificCompletion,
  specificCompletion: .94,
  result: SourceSpan(text: caption, start: 2, end: 2 + caption.runes.length),
);

Map<String, Object?> _acceptedJson() => <String, Object?>{
  'outcome': 'accepted',
  'kind': 'specific_completion',
  'specific_completion': .94,
  'result': <String, Object?>{
    'text': _caption,
    'start': 8,
    'end': 8 + _caption.length,
  },
  'learning': null,
  'usage': <String, Object?>{'credits': 4, 'model_ms': 80},
};

ProofRecord _supported(
  LocalDate date, {
  String task = 'a',
  String caption = _caption,
}) {
  final plan = _plan('$task-${date.day}', date: date);
  final planned = PlannedTask.forDoor(plan, plan.apps.single);
  final at = DateTime.utc(date.year, date.month, date.day, 7);
  return ProoflightRules.recordFromResponse(
    task: planned,
    note: 'I $caption',
    submittedAt: at,
    response: _acceptedResponse(caption: caption),
    trace: TaskTrace.forTask(
      planned,
      kind: TaskTraceKind.door,
      at: at.subtract(const Duration(minutes: 20)),
    ),
  );
}

ProofRecord _vague() {
  final plan = _plan('today');
  final task = PlannedTask.forDoor(plan, plan.apps.single);
  return ProoflightRules.recordFromResponse(
    task: task,
    note: 'done',
    submittedAt: DateTime.utc(2026, 10, 24, 7),
    response: const ProofResponse(outcome: ProofOutcome.vague),
  );
}

List<ProofRecord> _days(Iterable<int> days) => <ProofRecord>[
  for (final day in days) _supported(LocalDate(2026, 10, day)),
];

ProofSubmission _submission({
  required List<ProofRecord> past,
  required ProofRecord record,
  ProofKind? kind,
}) => ProofSubmission(
  record: record,
  before: ProoflightRules.summarize(records: past, today: _today),
  after: ProoflightRules.summarize(
    records: <ProofRecord>[...past, record],
    today: _today,
  ),
  kind: kind,
);

CurreApiClient _api(
  Map<String, Object?> Function(Map<String, Object?>) reply,
) => CurreApiClient(
  baseUrl: Uri.parse('https://curre.test'),
  appKey: 'key',
  httpClient: MockClient((request) async {
    expect(request.url.path, '/v1/proof');
    final body = jsonDecode(request.body) as Map<String, Object?>;
    return http.Response(jsonEncode(reply(body)), 200);
  }),
);

CurreController _controller({CurreApiClient? api}) => CurreController(
  launcher: _FakeDoorPlatform(),
  homePlatform: _FakeHomePlatform(),
  api: api,
  settings: Settings(displayName: 'Chidi', avatarId: 'avatar-03'),
  apps: CurreController.fallbackApps,
  plans: <Plan>[_plan('today')],
  onboardingComplete: true,
  now: () => DateTime.utc(2026, 10, 24, 7, 30),
);

/// Opens today's YouTube door, so Curre has seen the task start, and
/// returns the task with the sheet already shown.
Future<PlannedTask> _openDoor(CurreController controller) async {
  final plan = controller.plans.single;
  final app = plan.apps.single;
  await controller.openPlanDoor(plan, app);
  return PlannedTask.forDoor(plan, app);
}

class _FakeHomePlatform implements HomePlatformGateway {
  @override
  Future<bool> isDefaultHome() async => true;

  @override
  Future<void> setHomeSurfaceActive(bool active) async {}
}

class _FakeDoorPlatform implements DoorPlatform {
  @override
  Future<Uint8List?> getIcon(String packageName) async => null;

  @override
  Future<List<AppShortcut>> getConversationShortcuts(String p) async =>
      <AppShortcut>[];

  @override
  Future<List<AppShortcut>> getStaticShortcuts(String p) async =>
      <AppShortcut>[];

  @override
  Future<bool> hasShortcutHostPermission() async => false;

  @override
  Future<bool> launch(String packageName) async => true;

  @override
  Future<bool> launchQueryDoor(String doorId, String query) async => true;

  @override
  Future<List<LaunchableApp>> listApps() async => CurreController.fallbackApps;

  @override
  Future<bool> requestHomeRole() async => true;

  @override
  Future<bool> startShortcut(String packageName, String shortcutId) async =>
      false;
}
