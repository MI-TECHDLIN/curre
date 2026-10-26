import 'package:curre/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

const _youtube = 'com.google.android.youtube';

Plan _plan({
  String id = 'plan-1',
  LocalDate date = const LocalDate(2026, 10, 20),
  List<PlannedApp> apps = const <PlannedApp>[
    PlannedApp(
      packageName: _youtube,
      query: SourceSpan(text: 'G chord', start: 10, end: 17),
    ),
  ],
}) => Plan(
  id: id,
  session: SessionName.morning,
  date: date,
  intention: 'Learn the G chord on YouTube, then pray',
  apps: apps,
  endsAt: DateTime.utc(date.year, date.month, date.day, 9),
  source: PlanSource.clocked,
);

PlannedTask _task({String id = 'plan-1', LocalDate? date}) {
  final plan = _plan(id: id, date: date ?? const LocalDate(2026, 10, 20));
  return PlannedTask.forDoor(plan, plan.apps.single);
}

ProofResponse _accepted({
  double probability = .93,
  String caption = 'switched from G to C',
}) => ProofResponse(
  outcome: ProofOutcome.accepted,
  kind: ProofKind.specificCompletion,
  specificCompletion: probability,
  result: SourceSpan(text: caption, start: 2, end: 2 + caption.runes.length),
);

TaskTrace _trace(PlannedTask task, DateTime at) =>
    TaskTrace.forTask(task, kind: TaskTraceKind.door, at: at);

DateTime _morning(LocalDate date, [int hour = 7]) =>
    DateTime.utc(date.year, date.month, date.day, hour);

/// A supported task on [date]; [task] tells several apart on one day.
ProofRecord _supported(LocalDate date, {String task = 'a'}) {
  final planned = _task(id: 'plan-$date-$task', date: date);
  return ProoflightRules.recordFromResponse(
    task: planned,
    note: 'I switched from G to C',
    submittedAt: _morning(date, 8),
    response: _accepted(),
    trace: _trace(planned, _morning(date)),
  );
}

/// A note on [date] still waiting for its answer.
ProofRecord _pending(LocalDate date, {bool traced = true}) {
  final planned = _task(id: 'plan-$date-pending', date: date);
  return ProoflightRules.recordFromResponse(
    task: planned,
    note: 'I can switch from G to C now',
    submittedAt: _morning(date, 8),
    response: const ProofResponse.pending(),
    trace: traced ? _trace(planned, _morning(date)) : null,
  );
}

LocalDate _oct(int day) => LocalDate(2026, 10, day);

List<ProofRecord> _days(Iterable<int> days) => <ProofRecord>[
  for (final day in days) _supported(_oct(day)),
];

ProofSummary _summary(Iterable<ProofRecord> records, int today) =>
    ProoflightRules.summarize(records: records, today: _oct(today));

void main() {
  group('pre-committed tasks and their start traces', () {
    test('a door task exists only for an app the plan already had', () {
      final plan = _plan();
      final task = PlannedTask.forDoor(plan, plan.apps.single);

      expect(task.id, 'plan-1:door:$_youtube');
      expect(task.planId, 'plan-1');
      expect(task.date, const LocalDate(2026, 10, 20));
      expect(task.text, plan.intention);
      expect(task.packageName, _youtube);
      expect(task.isOffline, isFalse);
      // The plan's app, even as a fresh copy read back from storage.
      expect(
        PlannedTask.forDoor(plan, const PlannedApp(packageName: _youtube)).id,
        task.id,
      );
      expect(
        () => PlannedTask.forDoor(
          plan,
          const PlannedApp(packageName: 'com.added.afterwards'),
        ),
        throwsArgumentError,
      );
    });

    test('the task away from the phone is the plan itself', () {
      final task = PlannedTask.offline(_plan(apps: const <PlannedApp>[]));
      expect(task.id, 'plan-1:offline');
      expect(task.isOffline, isTrue);
      expect(task.packageName, isNull);
    });

    test('a trace supports only the task it started', () {
      final task = _task();
      final trace = _trace(task, _morning(task.date));
      expect(trace.supports(task), isTrue);
      expect(trace.packageName, _youtube);
      // The same app in a later plan, an edit of it included, is another
      // task: a door opened before the edit does not count for it.
      expect(trace.supports(_task(id: 'plan-2')), isFalse);
      expect(
        trace.supports(PlannedTask.offline(_plan(apps: const []))),
        isFalse,
      );
    });

    test('a trace and a record survive a JSON round trip', () {
      final task = _task();
      final trace = TaskTrace.forTask(
        task,
        kind: TaskTraceKind.offlineStart,
        at: DateTime.utc(2026, 10, 20, 6, 30),
      );
      final restoredTrace = TaskTrace.fromJson(trace.toJson());
      expect(restoredTrace.id, trace.id);
      expect(restoredTrace.kind, TaskTraceKind.offlineStart);
      expect(restoredTrace.at, trace.at);
      expect(restoredTrace.supports(task), isTrue);

      final record = ProoflightRules.recordFromResponse(
        task: task,
        note: 'I switched from G to C',
        submittedAt: DateTime.utc(2026, 10, 20, 7),
        response: _accepted(),
        trace: trace,
      );
      final restored = ProofRecord.fromJson(record.toJson());
      expect(restored.toJson(), record.toJson());
      expect(restored.level, ProofLevel.supported);
      expect(restored.caption?.text, 'switched from G to C');
    });
  });

  group('evidence levels', () {
    final task = _task();
    final startedAt = DateTime.utc(2026, 10, 20, 7);
    final noteAt = DateTime.utc(2026, 10, 20, 8);

    ProofRecord judge(ProofResponse response, {TaskTrace? trace}) =>
        ProoflightRules.recordFromResponse(
          task: task,
          note: 'I switched from G to C',
          submittedAt: noteAt,
          response: response,
          trace: trace,
        );

    test('a check-off is kept but self-reported, with its note local', () {
      final trace = _trace(task, startedAt);
      final record = ProoflightRules.checkOff(
        task: task,
        at: noteAt,
        trace: trace,
        note: 'did it',
      );
      expect(record.judgement, ProofJudgement.none);
      expect(record.level, ProofLevel.selfReported);
      expect(record.countsForProoflight, isFalse);
      expect(record.traceId, trace.id);
      expect(record.note, 'did it');
      expect(_summaryOf(<ProofRecord>[record]).totalProofDays, 0);
    });

    test('a specific note after the door opened is supported', () {
      final record = judge(_accepted(), trace: _trace(task, startedAt));
      expect(record.judgement, ProofJudgement.accepted);
      expect(record.level, ProofLevel.supported);
      expect(record.countsForProoflight, isTrue);
      expect(record.date, task.date);
      expect(record.caption?.text, 'switched from G to C');
    });

    test(
      'without Curre seeing the start, a specific note is self-reported',
      () {
        final record = judge(_accepted());
        expect(record.judgement, ProofJudgement.accepted);
        expect(record.level, ProofLevel.selfReported);
        expect(record.countsForProoflight, isFalse);
      },
    );

    test('a start traced after the note does not support it', () {
      final record = judge(
        _accepted(),
        trace: _trace(task, noteAt.add(const Duration(minutes: 1))),
      );
      expect(record.countsForProoflight, isFalse);
      expect(record.traceId, isNull);
    });

    test('the threshold is 0.75, inclusive, and a span must be copied', () {
      final trace = _trace(task, startedAt);
      expect(
        judge(_accepted(probability: .7499), trace: trace).countsForProoflight,
        isFalse,
      );
      expect(
        judge(_accepted(probability: .75), trace: trace).countsForProoflight,
        isTrue,
      );
      expect(
        judge(
          const ProofResponse(
            outcome: ProofOutcome.accepted,
            specificCompletion: .95,
          ),
          trace: trace,
        ).countsForProoflight,
        isFalse,
      );
      final learning = judge(
        const ProofResponse(
          outcome: ProofOutcome.accepted,
          specificCompletion: .95,
          learning: SourceSpan(text: 'G to C', start: 16, end: 22),
        ),
        trace: trace,
      );
      expect(learning.countsForProoflight, isTrue);
      expect(learning.caption?.text, 'G to C');
    });

    test('a vague or unanswered note never counts, but keeps its trace', () {
      final trace = _trace(task, startedAt);
      final vague = judge(
        const ProofResponse(
          outcome: ProofOutcome.vague,
          kind: ProofKind.vague,
          specificCompletion: .12,
        ),
        trace: trace,
      );
      expect(vague.judgement, ProofJudgement.vague);
      expect(vague.countsForProoflight, isFalse);

      final pending = judge(const ProofResponse.pending(), trace: trace);
      expect(pending.judgement, ProofJudgement.pending);
      expect(pending.isPending, isTrue);
      expect(pending.countsForProoflight, isFalse);
      expect(pending.traceId, trace.id);
    });

    test('a supported record cannot be made without its evidence', () {
      ProofRecord make({
        ProofJudgement judgement = ProofJudgement.accepted,
        String? traceId = 'trace',
        double? probability = .9,
      }) => ProofRecord(
        id: 'proof',
        taskId: 'task',
        planId: 'plan',
        date: const LocalDate(2026, 10, 20),
        taskText: 'task',
        note: 'note',
        submittedAt: noteAt,
        judgement: judgement,
        level: ProofLevel.supported,
        traceId: traceId,
        specificCompletion: probability,
      );

      expect(make().countsForProoflight, isTrue);
      expect(() => make(traceId: null), throwsArgumentError);
      expect(() => make(probability: .74), throwsArgumentError);
      expect(() => make(probability: null), throwsArgumentError);
      expect(
        () => make(judgement: ProofJudgement.pending),
        throwsArgumentError,
      );
      expect(() => make(probability: 1.2), throwsRangeError);
    });

    test('a later, weaker note never undoes supported proof', () {
      final supported = judge(_accepted(), trace: _trace(task, startedAt));
      final vague = ProoflightRules.recordFromResponse(
        task: task,
        note: 'done',
        submittedAt: noteAt.add(const Duration(minutes: 2)),
        response: const ProofResponse(outcome: ProofOutcome.vague),
      );
      final checkOff = ProoflightRules.checkOff(task: task, at: noteAt);

      expect(supported.id, vague.id);
      expect(ProoflightRules.preferRecord(supported, vague), same(supported));
      expect(
        ProoflightRules.preferRecord(supported, checkOff),
        same(supported),
      );
      expect(ProoflightRules.preferRecord(vague, supported), same(supported));
      expect(ProoflightRules.preferRecord(null, vague), same(vague));
      expect(
        () => ProoflightRules.preferRecord(
          supported,
          _supported(const LocalDate(2026, 10, 21)),
        ),
        throwsArgumentError,
      );
    });

    test('a waiting note is judged later with its time, trace and day', () {
      final pending = judge(
        const ProofResponse.pending(),
        trace: _trace(task, startedAt),
      );
      final judged = ProoflightRules.recordFromPending(
        pending: pending,
        response: _accepted(),
      );
      expect(judged.id, pending.id);
      expect(judged.date, pending.date);
      expect(judged.submittedAt, pending.submittedAt);
      expect(judged.traceId, pending.traceId);
      expect(judged.countsForProoflight, isTrue);
      expect(
        () => ProoflightRules.recordFromPending(
          pending: judged,
          response: _accepted(),
        ),
        throwsArgumentError,
      );
    });

    test('forgetting the words keeps every proof day and nothing else', () {
      final supported = _supported(const LocalDate(2026, 10, 20));
      final kept = ProoflightRules.forgetWords(<ProofRecord>[
        supported,
        _pending(const LocalDate(2026, 10, 21)),
        ProoflightRules.checkOff(
          task: _task(id: 'other'),
          at: noteAt,
        ),
      ]);

      expect(kept, hasLength(1));
      final record = kept.single;
      expect(record.note, isEmpty);
      expect(record.taskText, isEmpty);
      expect(record.caption, isNull);
      expect(record.date, supported.date);
      expect(record.countsForProoflight, isTrue);
    });
  });

  group('Prooflight streak rules', () {
    test('nothing yet is no proof days, not a run that ended', () {
      final summary = _summary(const <ProofRecord>[], 20);
      expect(summary.currentRun, 0);
      expect(summary.totalProofDays, 0);
      expect(summary.betweenRuns, isFalse);
      expect(summary.today, _oct(20));
    });

    test('the first supported task adds a day; more only add rays', () {
      final summary = _summary(<ProofRecord>[
        _supported(_oct(20), task: 'a'),
        _supported(_oct(20), task: 'b'),
        _supported(_oct(20), task: 'c'),
      ], 20);
      expect(summary.currentRun, 1);
      expect(summary.totalProofDays, 1);
      expect(summary.raysToday, 3);
      expect(summary.runStart, _oct(20));
    });

    test('the same task proved twice is still one ray', () {
      final first = _supported(_oct(20));
      final again = ProoflightRules.recordFromResponse(
        task: _task(id: 'plan-${_oct(20)}-a', date: _oct(20)),
        note: 'I switched from G to C twice',
        submittedAt: _morning(_oct(20), 9),
        response: _accepted(),
        trace: TaskTrace(
          id: first.traceId!,
          taskId: first.taskId,
          planId: first.planId,
          date: first.date,
          kind: TaskTraceKind.door,
          at: _morning(_oct(20)),
        ),
      );
      expect(_summary(<ProofRecord>[first, again], 20).raysToday, 1);
    });

    test('self-reported days never add to the run', () {
      final task = _task(id: 'checked', date: _oct(21));
      final summary = _summary(<ProofRecord>[
        _supported(_oct(20)),
        ProoflightRules.checkOff(
          task: task,
          at: _morning(_oct(21)),
          trace: _trace(task, _morning(_oct(21), 6)),
        ),
      ], 21);
      expect(summary.currentRun, 1);
      expect(summary.raysToday, 0);
    });

    test('today is never empty: an unproved today keeps the run', () {
      final summary = _summary(_days(<int>[18, 19]), 20);
      expect(summary.currentRun, 2);
      expect(summary.raysToday, 0);
      expect(summary.betweenRuns, isFalse);
    });

    test('one empty day is forgiven; a second in a row closes the run', () {
      final records = _days(<int>[10, 11, 12]);

      final forgiven = _summary(records, 14);
      expect(forgiven.currentRun, 3);
      expect(forgiven.cloudDays, 0);

      final ended = _summary(records, 15);
      expect(ended.currentRun, 0);
      expect(ended.betweenRuns, isTrue);
      expect(ended.lastEndedRun, 3);
      expect(ended.lastEndedOn, _oct(14));
      // Nothing is erased.
      expect(ended.bestRun, 3);
      expect(ended.totalProofDays, 3);
      expect(ended.proofDates, containsAll(<LocalDate>[_oct(10), _oct(12)]));
    });

    test('single empty days apart never close a run', () {
      final summary = _summary(_days(<int>[1, 3, 5, 7]), 7);
      expect(summary.currentRun, 4);
      expect(summary.lastEndedRun, isNull);
    });

    test(
      'seven proof days earn one automatic cloud day, held one at a time',
      () {
        final seven = _summary(_days(<int>[for (var d = 1; d <= 7; d++) d]), 7);
        expect(seven.cloudInHand, isTrue);
        expect(seven.cloudDays, 0);
        expect(seven.towardCloud, 0);

        final fourteen = _summary(
          _days(<int>[for (var d = 1; d <= 14; d++) d]),
          14,
        );
        expect(fourteen.currentRun, 14);
        expect(fourteen.cloudInHand, isTrue);
        expect(fourteen.towardCloud, 0);

        final six = _summary(_days(<int>[for (var d = 1; d <= 6; d++) d]), 6);
        expect(six.cloudInHand, isFalse);
        expect(six.towardCloud, 6);
      },
    );

    test('a cloud covers the first empty day and adds nothing to the run', () {
      final records = _days(<int>[for (var d = 1; d <= 7; d++) d]);

      final covered = _summary(records, 9);
      expect(covered.currentRun, 7);
      expect(covered.cloudInHand, isFalse);
      expect(covered.cloudDays, 1);
      expect(covered.cloudDates, <LocalDate>{_oct(8)});

      // The cloud took the first empty day; one more is still forgiven.
      final stillGoing = _summary(records, 10);
      expect(stillGoing.currentRun, 7);
      expect(stillGoing.betweenRuns, isFalse);

      final ended = _summary(records, 11);
      expect(ended.currentRun, 0);
      expect(ended.lastEndedRun, 7);
      expect(ended.lastEndedOn, _oct(10));
      expect(ended.cloudDays, 1);
      expect(ended.bestRun, 7);

      final resumed = _summary(<ProofRecord>[
        ...records,
        _supported(_oct(10)),
      ], 10);
      expect(resumed.currentRun, 8);
      expect(resumed.cloudDates, <LocalDate>{_oct(8)});
    });

    test('days count toward the next cloud only while none is held', () {
      final records = _days(<int>[
        for (var d = 1; d <= 9; d++) d,
        // The 10th is empty and takes the cloud.
        for (var d = 11; d <= 16; d++) d,
      ]);
      final six = _summary(records, 16);
      expect(six.currentRun, 15);
      expect(six.cloudInHand, isFalse);
      expect(six.towardCloud, 6);

      final seventh = _summary(<ProofRecord>[
        ...records,
        _supported(_oct(17)),
      ], 17);
      expect(seventh.cloudInHand, isTrue);
      expect(seventh.cloudDays, 1);
    });

    test('a proof after a run ended starts the next with nothing erased', () {
      final records = <ProofRecord>[
        ..._days(<int>[1, 2, 3, 4, 5]),
        _supported(_oct(10)),
      ];
      final summary = _summary(records, 10);
      expect(summary.currentRun, 1);
      expect(summary.runStart, _oct(10));
      expect(summary.bestRun, 5);
      expect(summary.totalProofDays, 6);
      expect(summary.lastEndedRun, 5);
      expect(summary.betweenRuns, isFalse);
    });

    test('a waiting note holds its day, so an outage never ends a run', () {
      final records = <ProofRecord>[
        ..._days(<int>[1, 2, 3]),
        _pending(_oct(4)),
      ];
      final held = _summary(records, 6);
      expect(held.currentRun, 3);
      expect(held.pendingDates, <LocalDate>{_oct(4)});
      expect(held.betweenRuns, isFalse);
      // Without the waiting note, days 4 and 5 would have closed the run.
      expect(_summary(_days(<int>[1, 2, 3]), 6).betweenRuns, isTrue);
    });

    test('a waiting note without a start trace holds nothing', () {
      final summary = _summary(<ProofRecord>[
        ..._days(<int>[1, 2, 3]),
        _pending(_oct(4), traced: false),
      ], 6);
      expect(summary.pendingDates, isEmpty);
      expect(summary.betweenRuns, isTrue);
    });

    test('once judged, a waiting note lands on its own day', () {
      final pending = _pending(_oct(4));
      final accepted = ProoflightRules.recordFromPending(
        pending: pending,
        response: _accepted(),
      );
      final credited = _summary(<ProofRecord>[
        ..._days(<int>[1, 2, 3]),
        accepted,
      ], 5);
      expect(accepted.date, _oct(4));
      expect(credited.proofDates, contains(_oct(4)));
      expect(credited.currentRun, 4);
      expect(credited.totalProofDays, 4);

      // Judged vague, the day is simply empty again.
      final vague = ProoflightRules.recordFromPending(
        pending: pending,
        response: const ProofResponse(outcome: ProofOutcome.vague),
      );
      final emptied = _summary(<ProofRecord>[
        ..._days(<int>[1, 2, 3]),
        vague,
      ], 7);
      expect(emptied.pendingDates, isEmpty);
      expect(emptied.lastEndedRun, 3);
      expect(emptied.lastEndedOn, _oct(5));
    });

    test('a proof dated after today still counts and ends nothing', () {
      // The phone moved west: yesterday's proof carries tomorrow's date
      // until the local day catches up.
      final summary = _summary(_days(<int>[18, 19, 21]), 20);
      expect(summary.currentRun, 3);
      expect(summary.totalProofDays, 3);
      expect(summary.raysToday, 0);
      expect(summary.betweenRuns, isFalse);
    });
  });

  group('what one completion changed', () {
    ProofSubmission submit(
      List<ProofRecord> before,
      ProofRecord record,
      int today,
    ) => ProofSubmission(
      record: record,
      before: _summary(before, today),
      after: _summary(<ProofRecord>[...before, record], today),
    );

    test('the first proof of today raises the sun; the next adds a ray', () {
      final first = submit(_days(<int>[18, 19]), _supported(_oct(20)), 20);
      expect(first.supported, isTrue);
      expect(first.isToday, isTrue);
      expect(first.earnedProofDay, isTrue);
      expect(first.addedRay, isFalse);
      expect(first.after.currentRun, 3);

      final second = submit(
        <ProofRecord>[
          ..._days(<int>[18, 19, 20]),
        ],
        _supported(_oct(20), task: 'b'),
        20,
      );
      expect(second.earnedProofDay, isFalse);
      expect(second.addedRay, isTrue);
      expect(second.after.currentRun, 3);
      expect(second.after.raysToday, 2);
    });

    test('the seventh proof day earns the cloud; a proof after an end starts again', () {
      final seventh = submit(
        _days(<int>[for (var d = 14; d <= 19; d++) d]),
        _supported(_oct(20)),
        20,
      );
      expect(seventh.earnedCloudDay, isTrue);
      expect(seventh.startedNewRun, isFalse);

      final restart = submit(_days(<int>[1, 2, 3]), _supported(_oct(20)), 20);
      expect(restart.before.betweenRuns, isTrue);
      expect(restart.startedNewRun, isTrue);
      expect(restart.after.bestRun, 3);
      expect(restart.after.totalProofDays, 4);
    });

    test('a vague note changes nothing', () {
      final vague = ProoflightRules.recordFromResponse(
        task: _task(id: 'vague', date: _oct(20)),
        note: 'done',
        submittedAt: _morning(_oct(20), 8),
        response: const ProofResponse(outcome: ProofOutcome.vague),
      );
      final submission = submit(_days(<int>[19]), vague, 20);
      expect(submission.supported, isFalse);
      expect(submission.earnedProofDay, isFalse);
      expect(submission.addedRay, isFalse);
      expect(submission.after.currentRun, 1);
    });
  });

  group('the Curre day', () {
    final settings = Settings();
    const utc = FixedOffsetTimeZone(Duration.zero);

    LocalDate day(DateTime at, {Settings? using, CurreTimeZone zone = utc}) =>
        ProoflightRules.curreDay(at, using ?? settings, timeZone: zone);

    test('starts at the morning session, not at midnight', () {
      expect(day(DateTime.utc(2026, 10, 20, 3, 59)), _oct(19));
      expect(day(DateTime.utc(2026, 10, 20, 4)), _oct(20));
      // The evening runs past midnight and still belongs to its day.
      expect(day(DateTime.utc(2026, 10, 21, 1, 30)), _oct(20));
    });

    test('follows an edited morning start', () {
      final edited = Settings(
        sessionStarts: const <SessionName, LocalTime>{
          SessionName.morning: LocalTime(5, 30),
          SessionName.afternoon: LocalTime(12),
          SessionName.evening: LocalTime(17),
        },
      );
      expect(day(DateTime.utc(2026, 10, 20, 5, 29), using: edited), _oct(19));
      expect(day(DateTime.utc(2026, 10, 20, 5, 30), using: edited), _oct(20));
    });

    test('keeps 04:00 across the spring-forward change', () {
      final zone = TransitionTimeZone(
        initialOffset: const Duration(hours: 1),
        transitions: <OffsetTransition>[
          OffsetTransition(
            at: DateTime.utc(2026, 3, 29, 1),
            offsetAfter: const Duration(hours: 2),
          ),
        ],
      );
      // 04:00 local is 02:00 UTC after the change.
      expect(
        day(DateTime.utc(2026, 3, 29, 1, 59), zone: zone),
        const LocalDate(2026, 3, 28),
      );
      expect(
        day(DateTime.utc(2026, 3, 29, 2), zone: zone),
        const LocalDate(2026, 3, 29),
      );
    });

    test('keeps 04:00 across the fall-back change', () {
      final zone = TransitionTimeZone(
        initialOffset: const Duration(hours: 2),
        transitions: <OffsetTransition>[
          OffsetTransition(
            at: DateTime.utc(2026, 10, 25, 1),
            offsetAfter: const Duration(hours: 1),
          ),
        ],
      );
      // 04:00 local is 03:00 UTC after the change; the repeated hour
      // before it is still the night of the 24th.
      expect(day(DateTime.utc(2026, 10, 25, 2, 59), zone: zone), _oct(24));
      expect(day(DateTime.utc(2026, 10, 25, 3), zone: zone), _oct(25));
    });

    test('a time-zone move changes today, never a recorded day', () {
      final instant = DateTime.utc(2026, 10, 20, 2, 30);
      final home = day(instant);
      final east = day(
        instant,
        zone: const FixedOffsetTimeZone(Duration(hours: 3)),
      );
      expect(home, _oct(19));
      expect(east, _oct(20));

      final record = _supported(home);
      expect(record.date, home);
      final abroad = ProoflightRules.summarize(
        records: <ProofRecord>[record],
        today: east,
      );
      expect(abroad.proofDates, <LocalDate>{_oct(19)});
      expect(abroad.currentRun, 1);
      expect(abroad.raysToday, 0);
    });
  });
}

ProofSummary _summaryOf(List<ProofRecord> records) => ProoflightRules.summarize(
  records: records,
  today: const LocalDate(2026, 10, 20),
);
