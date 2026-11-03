import 'package:curre/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

Plan _plan({List<String> packages = const <String>['a', 'b', 'c', 'd']}) =>
    Plan(
      id: 'plan-1',
      session: SessionName.morning,
      date: const LocalDate(2026, 10, 26),
      intention: 'Reply to Ada, then practise',
      apps: <PlannedApp>[
        for (final package in packages) PlannedApp(packageName: package),
      ],
      endsAt: DateTime.utc(2026, 10, 26, 9),
      source: PlanSource.clocked,
    );

ProofRecord _record(PlannedTask task, ProofResponse response) =>
    ProoflightRules.recordFromResponse(
      task: task,
      note: 'I replied to Ada about Friday',
      submittedAt: DateTime.utc(2026, 10, 26, 7),
      response: response,
      trace: TaskTrace.forTask(
        task,
        kind: TaskTraceKind.door,
        at: DateTime.utc(2026, 10, 26, 6, 50),
      ),
    );

const _accepted = ProofResponse(
  outcome: ProofOutcome.accepted,
  kind: ProofKind.specificCompletion,
  specificCompletion: .94,
  result: SourceSpan(text: 'replied to Ada about Friday', start: 2, end: 29),
);

void main() {
  group('TaskDoneState', () {
    final plan = _plan();
    final task = PlannedTask.forDoor(plan, plan.apps.first);

    test('reads each kind of record', () {
      expect(TaskDoneState.of(null), TaskDoneState.open);
      expect(TaskDoneState.of(_record(task, _accepted)), TaskDoneState.proved);
      expect(
        TaskDoneState.of(_record(task, const ProofResponse.pending())),
        TaskDoneState.waiting,
      );
      expect(
        TaskDoneState.of(
          ProoflightRules.checkOff(
            task: task,
            at: DateTime.utc(2026, 10, 26, 7),
            trace: null,
          ),
        ),
        TaskDoneState.checkedOff,
      );
      expect(TaskDoneState.open.isDone, isFalse);
      expect(TaskDoneState.checkedOff.isDone, isTrue);
    });
  });

  group('PlanCompletion', () {
    test('splits active and done, each in the plan’s order', () {
      final plan = _plan();
      final tasks = PlanCompletion.tasksOf(plan);
      final records = <String, ProofRecord>{
        tasks[2].id: _record(tasks[2], _accepted),
        tasks[0].id: ProoflightRules.checkOff(
          task: tasks[0],
          at: DateTime.utc(2026, 10, 26, 7, 30),
          trace: null,
        ),
      };
      final completion = PlanCompletion.of(plan, (task) => records[task.id]);

      expect(completion.active.map((item) => item.task.packageName), [
        'b',
        'd',
      ]);
      expect(completion.done.map((item) => item.task.packageName), ['a', 'c']);
      expect(completion.stateOf(tasks[2]), TaskDoneState.proved);
      expect(completion.allDone, isFalse);
      expect(completion.foldsDone, isFalse);
    });

    test('is all done only when every task has a record', () {
      final plan = _plan(packages: const <String>['a', 'b', 'c']);
      final tasks = PlanCompletion.tasksOf(plan);
      final records = <String, ProofRecord>{
        for (final task in tasks) task.id: _record(task, _accepted),
      };
      final completion = PlanCompletion.of(plan, (task) => records[task.id]);
      expect(completion.allDone, isTrue);
      expect(completion.active, isEmpty);
      // Three done rows fold into one line.
      expect(completion.foldsDone, isTrue);
    });

    test('a plan without apps is the one task away from the phone', () {
      final plan = _plan(packages: const <String>[]);
      final none = PlanCompletion.of(plan, (_) => null);
      expect(none.tasks.single.task.isOffline, isTrue);
      expect(none.allDone, isFalse);

      final task = PlannedTask.offline(plan);
      final pending = _record(task, const ProofResponse.pending());
      final done = PlanCompletion.of(plan, (_) => pending);
      expect(done.allDone, isTrue);
      expect(done.done.single.state, TaskDoneState.waiting);
    });
  });

  group('Plan.endedEarlyAt', () {
    test('ends now, keeps the planned end, and survives storage', () {
      final plan = _plan();
      final at = DateTime.utc(2026, 10, 26, 7, 42);
      final ended = plan.endedEarlyAt(at);

      expect(ended.endsAt, at);
      expect(ended.plannedEndsAt, plan.endsAt);
      expect(ended.endedEarly, isTrue);
      expect(plan.endedEarly, isFalse);
      expect(plan.toJson().containsKey('plannedEndsAt'), isFalse);

      final stored = Plan.fromJson(ended.toJson());
      expect(stored.endsAt, at);
      expect(stored.plannedEndsAt, plan.endsAt);
      expect(stored.apps.length, plan.apps.length);

      // Ending it again keeps the first planned end.
      final again = ended.endedEarlyAt(at.add(const Duration(minutes: 1)));
      expect(again.plannedEndsAt, plan.endsAt);
    });

    test('undoing the early end restores the plan as it was', () {
      final plan = _plan();
      final restored = plan
          .endedEarlyAt(DateTime.utc(2026, 10, 26, 7, 42))
          .withEarlyEndUndone();
      expect(restored.endsAt, plan.endsAt);
      expect(restored.endedEarly, isFalse);
      expect(restored.toJson(), plan.toJson());
      expect(identical(plan.withEarlyEndUndone(), plan), isTrue);
    });
  });
}
