import 'models.dart';
import 'proof.dart';

/// Where one planned task stands, read from the one record it keeps.
enum TaskDoneState {
  /// No record yet: the task is still to do.
  open,

  /// Done, and its note was supported: it raised the day's sun.
  proved,

  /// Done, and its note is waiting to be checked.
  waiting,

  /// Done without proof: checked off, or a note that didn't count.
  checkedOff;

  static TaskDoneState of(ProofRecord? record) {
    if (record == null) return TaskDoneState.open;
    if (record.countsForProoflight) return TaskDoneState.proved;
    if (record.isPending) return TaskDoneState.waiting;
    return TaskDoneState.checkedOff;
  }

  bool get isDone => this != TaskDoneState.open;
}

/// One planned task and where it stands.
class TaskProgress {
  const TaskProgress({required this.task, required this.state});

  final PlannedTask task;
  final TaskDoneState state;

  bool get isDone => state.isDone;
}

/// A plan's tasks split into what is still to do and what is done, each in
/// the plan's own order, so a row never jumps within its group. Pure: it is
/// rebuilt from the plan and its records whenever Home draws.
class PlanCompletion {
  PlanCompletion._(this.plan, this.tasks);

  /// [recordFor] is the task's one record, if it has one.
  factory PlanCompletion.of(
    Plan plan,
    ProofRecord? Function(PlannedTask task) recordFor,
  ) {
    final tasks = tasksOf(plan);
    return PlanCompletion._(plan, <TaskProgress>[
      for (final task in tasks)
        TaskProgress(task: task, state: TaskDoneState.of(recordFor(task))),
    ]);
  }

  /// A plan with apps has one task per app; a plan without any is the one
  /// task done away from the phone.
  static List<PlannedTask> tasksOf(Plan plan) => plan.apps.isEmpty
      ? <PlannedTask>[PlannedTask.offline(plan)]
      : <PlannedTask>[
          for (final app in plan.apps) PlannedTask.forDoor(plan, app),
        ];

  /// How many done rows Home shows one by one before folding them into a
  /// single line with their count.
  static const int doneRowsShown = 2;

  final Plan plan;
  final List<TaskProgress> tasks;

  List<TaskProgress> get active =>
      tasks.where((task) => !task.isDone).toList(growable: false);

  List<TaskProgress> get done =>
      tasks.where((task) => task.isDone).toList(growable: false);

  /// Every task in the plan is done, in any way.
  bool get allDone => tasks.every((task) => task.isDone);

  /// Whether the done group starts folded into one line.
  bool get foldsDone => done.length > doneRowsShown;

  TaskDoneState stateOf(PlannedTask task) => tasks
      .firstWhere(
        (item) => item.task.id == task.id,
        orElse: () => TaskProgress(task: task, state: TaskDoneState.open),
      )
      .state;
}
