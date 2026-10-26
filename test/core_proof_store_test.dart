import 'dart:convert';

import 'package:curre/core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tracesKey = 'curre.taskTraces.v1';
const _recordsKey = 'curre.proofRecords.v1';

final _monday = DateTime.utc(2026, 10, 19, 7);

Plan _plan(String id, LocalDate date) => Plan(
  id: id,
  session: SessionName.morning,
  date: date,
  intention: 'read chapter four',
  apps: const <PlannedApp>[],
  endsAt: DateTime.utc(date.year, date.month, date.day, 9),
  source: PlanSource.manual,
);

PlannedTask _task(
  String id, [
  LocalDate date = const LocalDate(2026, 10, 19),
]) => PlannedTask.offline(_plan(id, date));

TaskTrace _start(PlannedTask task, DateTime at) =>
    TaskTrace.forTask(task, kind: TaskTraceKind.offlineStart, at: at);

const _accepted = ProofResponse(
  outcome: ProofOutcome.accepted,
  kind: ProofKind.specificCompletion,
  specificCompletion: .9,
  learning: SourceSpan(
    text: 'understood the central example',
    start: 2,
    end: 32,
  ),
);

ProofRecord _record(
  PlannedTask task,
  DateTime at,
  ProofResponse response, {
  TaskTrace? trace,
}) => ProoflightRules.recordFromResponse(
  task: task,
  note: 'I understood the central example',
  submittedAt: at,
  response: response,
  trace: trace,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('traces and records persist, one record per task', () async {
    final store = await CurreLocalStore.open(now: _monday);
    final task = _task('plan-1');
    final trace = _start(task, _monday);
    await store.appendTaskTrace(trace, now: _monday);

    final later = _monday.add(const Duration(minutes: 40));
    final pending = _record(
      task,
      later,
      const ProofResponse.pending(),
      trace: trace,
    );
    await store.upsertProofRecord(pending, now: later);
    final accepted = ProoflightRules.recordFromPending(
      pending: pending,
      response: _accepted,
    );
    await store.upsertProofRecord(accepted, now: later);
    // A weaker answer afterwards never replaces supported proof.
    await store.upsertProofRecord(
      _record(
        task,
        later.add(const Duration(minutes: 1)),
        const ProofResponse(outcome: ProofOutcome.vague),
        trace: trace,
      ),
      now: later,
    );

    final reopened = await CurreLocalStore.open(now: later);
    expect(reopened.loadTaskTraces(now: later).single.id, trace.id);
    final record = reopened.loadProofRecords(now: later).single;
    expect(record.level, ProofLevel.supported);
    expect(record.judgement, ProofJudgement.accepted);
    expect(record.date, const LocalDate(2026, 10, 19));
    expect(record.submittedAt, pending.submittedAt);
    expect(record.caption?.text, 'understood the central example');
  });

  test('past 30 days a record keeps its proof day but not its words', () async {
    final store = await CurreLocalStore.open(now: _monday);
    final task = _task('plan-1');
    final trace = _start(task, _monday);
    final waitingTask = _task('plan-2');
    final waitingTrace = _start(waitingTask, _monday);
    await store.appendTaskTrace(trace, now: _monday);
    await store.appendTaskTrace(waitingTrace, now: _monday);
    await store.upsertProofRecord(
      _record(task, _monday, _accepted, trace: trace),
      now: _monday,
    );
    await store.upsertProofRecord(
      _record(
        waitingTask,
        _monday,
        const ProofResponse.pending(),
        trace: waitingTrace,
      ),
      now: _monday,
    );

    final monthLater = _monday.add(const Duration(days: 31));
    final records = store.loadProofRecords(now: monthLater);
    final kept = records.singleWhere((record) => record.taskId == task.id);
    expect(kept.note, isEmpty);
    expect(kept.taskText, isEmpty);
    expect(kept.caption, isNull);
    expect(kept.countsForProoflight, isTrue);
    expect(kept.date, const LocalDate(2026, 10, 19));
    // A note still waiting keeps its words, so it can still be sent.
    final waiting = records.singleWhere(
      (record) => record.taskId == waitingTask.id,
    );
    expect(waiting.isPending, isTrue);
    expect(waiting.note, 'I understood the central example');

    // Traces only matter until the note is written; they follow history.
    expect(store.loadTaskTraces(now: monthLater), isEmpty);

    final summary = ProoflightRules.summarize(
      records: records,
      today: const LocalDate(2026, 11, 19),
    );
    expect(summary.totalProofDays, 1);
    expect(summary.bestRun, 1);

    // The compaction was written back.
    final preferences = await SharedPreferences.getInstance();
    final stored = jsonDecode(preferences.getString(_recordsKey)!) as List;
    expect(
      stored.cast<Map<String, Object?>>().map((json) => json['note']),
      containsAll(<Object?>['', 'I understood the central example']),
    );
  });

  test('an unreadable record is skipped, never the whole streak', () async {
    final store = await CurreLocalStore.open(now: _monday);
    final task = _task('plan-1');
    final trace = _start(task, _monday);
    await store.upsertProofRecord(
      _record(task, _monday, _accepted, trace: trace),
      now: _monday,
    );
    final preferences = await SharedPreferences.getInstance();
    final stored = jsonDecode(preferences.getString(_recordsKey)!) as List;
    await preferences.setString(
      _recordsKey,
      jsonEncode(<Object?>[
        ...stored,
        <String, Object?>{'id': 'broken', 'level': 'verified'},
        'not a record',
      ]),
    );

    final records = store.loadProofRecords(now: _monday);
    expect(records.single.taskId, task.id);

    // Unreadable as a whole, the list starts again rather than crashing.
    await preferences.setString(_tracesKey, '{bad json');
    expect(store.loadTaskTraces(now: _monday), isEmpty);
  });

  test('Clear history keeps proof days and forgets every word', () async {
    final store = await CurreLocalStore.open(now: _monday);
    final proved = _task('plan-1');
    final provedTrace = _start(proved, _monday);
    final waiting = _task('plan-2');
    final waitingTrace = _start(waiting, _monday);
    final checked = _task('plan-3');
    await store.appendTaskTrace(provedTrace, now: _monday);
    await store.appendTaskTrace(waitingTrace, now: _monday);
    await store.upsertProofRecord(
      _record(proved, _monday, _accepted, trace: provedTrace),
      now: _monday,
    );
    await store.upsertProofRecord(
      _record(
        waiting,
        _monday,
        const ProofResponse.pending(),
        trace: waitingTrace,
      ),
      now: _monday,
    );
    await store.upsertProofRecord(
      ProoflightRules.checkOff(task: checked, at: _monday, note: 'did it'),
      now: _monday,
    );

    await store.clearHistory();

    expect(store.loadTaskTraces(now: _monday), isEmpty);
    final record = store.loadProofRecords(now: _monday).single;
    expect(record.taskId, proved.id);
    expect(record.note, isEmpty);
    expect(record.taskText, isEmpty);
    expect(record.countsForProoflight, isTrue);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(_recordsKey), isNot(contains('chapter')));
    expect(preferences.getString(_recordsKey), isNot(contains('understood')));
  });
}
