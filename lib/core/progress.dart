import 'models.dart';
import 'sessions.dart';

/// How far one plan has come, from what Curre can see without asking: the
/// plan's doors used and its time run.
///
/// Every door is one step and the plan's time running its course is one
/// more, so [value] is `(doorsUsed + timeRun) / (doorCount + 1)`. A plan
/// with two doors is a third done once one door is used, and a plan with no
/// door at all ("Pray till 6") fills as its time runs. Every app the plan
/// put on Home counts as a door, used or not. The value only rises: a use
/// is never taken back and time only runs forward.
class PlanProgress {
  const PlanProgress({
    required this.doorCount,
    required this.doorsUsed,
    required this.timeRun,
  }) : assert(doorCount >= 0),
       assert(doorsUsed >= 0 && doorsUsed <= doorCount),
       assert(timeRun >= 0 && timeRun <= 1);

  /// [plan]'s progress at [now]. Its time runs from [startsAt] to the plan's
  /// end; Curre does not store when a plan was made, so callers pass the
  /// start of the plan's session. Only [uses] of this plan's own apps made by
  /// [now] count, each app once.
  factory PlanProgress.of(
    Plan plan, {
    required DateTime startsAt,
    required DateTime now,
    required Iterable<DoorUse> uses,
  }) {
    final instant = now.toUtc();
    final packages = plan.packages;
    final used = <String>{
      for (final use in uses)
        if (use.planId == plan.id &&
            packages.contains(use.packageName) &&
            !use.at.isAfter(instant))
          use.packageName,
    };
    final start = startsAt.toUtc();
    final span = plan.endsAt.difference(start).inMicroseconds;
    final run = span <= 0
        ? 1.0
        : (instant.difference(start).inMicroseconds / span).clamp(0.0, 1.0);
    return PlanProgress(
      doorCount: packages.length,
      doorsUsed: used.length,
      timeRun: run,
    );
  }

  final int doorCount;
  final int doorsUsed;

  /// How much of the plan's time has passed, 0–1.
  final double timeRun;

  /// The plan's progress as one level, 0–1.
  double get value => (doorsUsed + timeRun) / (doorCount + 1);
}

/// Today's progress as one level, 0–1: the water on the check-in card.
///
/// Each of the three sessions holds a third of the day and fills with its
/// plan's [PlanProgress]. When a session had more than one plan (the prompt
/// returns once a plan ends inside its session), the furthest one counts.
/// A session without a plan simply stays empty. So the level only rises
/// through the day, and it is full once each session's plan has run its
/// course with every door used.
class DayProgress {
  DayProgress._({
    required Map<SessionName, PlanProgress> sessions,
    required this.plans,
    required this.doorsUsed,
  }) : sessions = Map.unmodifiable(sessions);

  /// Nothing planned yet today.
  static final DayProgress empty = DayProgress._(
    sessions: const <SessionName, PlanProgress>{},
    plans: 0,
    doorsUsed: 0,
  );

  /// Progress at [now] over today's [plans] (as `loadTodayPlans` returns
  /// them) and today's door [uses]. [schedule] places each plan in its
  /// session, whose start is where the plan's time begins.
  factory DayProgress.of({
    required Iterable<Plan> plans,
    required Iterable<DoorUse> uses,
    required SessionSchedule schedule,
    required DateTime now,
  }) {
    final allUses = uses.toList(growable: false);
    final sessions = <SessionName, PlanProgress>{};
    var count = 0;
    var doorsUsed = 0;
    for (final plan in plans) {
      // A plan ends inside its session (or exactly at its end), so the
      // instant just before its end always falls in that session.
      final window = schedule.current(
        plan.endsAt.subtract(const Duration(microseconds: 1)),
      );
      final progress = PlanProgress.of(
        plan,
        startsAt: window.startsAt,
        now: now,
        uses: allUses,
      );
      count++;
      doorsUsed += progress.doorsUsed;
      final best = sessions[plan.session];
      if (best == null || progress.value > best.value) {
        sessions[plan.session] = progress;
      }
    }
    return DayProgress._(
      sessions: sessions,
      plans: count,
      doorsUsed: doorsUsed,
    );
  }

  /// The furthest plan of each session that had one.
  final Map<SessionName, PlanProgress> sessions;

  /// How many plans today has had.
  final int plans;

  /// Doors used today, each app once per plan.
  final int doorsUsed;

  double get value =>
      sessions.values.fold(0.0, (sum, p) => sum + p.value) /
      SessionName.values.length;
}
