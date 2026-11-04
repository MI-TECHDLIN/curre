import 'models.dart';
import 'proof.dart';

/// What a focus period is for. Curre helps most for a stretch with an end:
/// exams, a deadline, or a habit to break.
enum FocusPurpose { exams, deadline, habit, other }

extension FocusPurposeWords on FocusPurpose {
  String get label => switch (this) {
    FocusPurpose.exams => 'Exams',
    FocusPurpose.deadline => 'A deadline',
    FocusPurpose.habit => 'Breaking a habit',
    FocusPurpose.other => 'Something else',
  };

  /// What the goal box suggests for this purpose.
  String get goalHint => switch (this) {
    FocusPurpose.exams => 'Pass my finals',
    FocusPurpose.deadline => 'Finish the project report',
    FocusPurpose.habit => 'Stop scrolling at night',
    FocusPurpose.other => 'Read more, scroll less',
  };

  /// How long a new focus runs unless the user picks otherwise. A habit
  /// takes about three weeks to loosen its grip.
  int get defaultDays => this == FocusPurpose.habit ? 21 : 14;

  /// The kind line on the summary when a focus ends.
  String get endLine => switch (this) {
    FocusPurpose.exams =>
      'You gave your studies the room they needed. Good luck out there.',
    FocusPurpose.deadline =>
      'You kept the noise down while the work got done. Well played.',
    FocusPurpose.habit =>
      'Every day you didn’t reach for it, the pull got weaker. Keep it up.',
    FocusPurpose.other => 'You set out to do something and you stayed with it.',
  };

  static FocusPurpose? tryParse(Object? value) {
    for (final purpose in FocusPurpose.values) {
      if (purpose.name == value) return purpose;
    }
    return null;
  }
}

/// The ready-made lengths offered when a focus is set.
enum FocusLength { oneWeek, twoWeeks, threeWeeks, thirtyDays }

extension FocusLengthWords on FocusLength {
  int get days => switch (this) {
    FocusLength.oneWeek => 7,
    FocusLength.twoWeeks => 14,
    FocusLength.threeWeeks => 21,
    FocusLength.thirtyDays => 30,
  };

  String get label => switch (this) {
    FocusLength.oneWeek => '1 week',
    FocusLength.twoWeeks => '2 weeks',
    FocusLength.threeWeeks => '3 weeks',
    FocusLength.thirtyDays => '30 days',
  };

  static FocusLength? forDays(int days) {
    for (final length in FocusLength.values) {
      if (length.days == days) return length;
    }
    return null;
  }
}

/// A stretch of days with a goal and an end: Curre's job for a while, not
/// forever.
///
/// Days are Curre days (they begin at the morning start). The focus runs
/// from [startsOn] up to [endsOn]; on [endsOn] it is over, Curre says so in
/// a notification and Home shows how it went.
class FocusPeriod {
  FocusPeriod({
    required this.purpose,
    String goal = '',
    required this.startsOn,
    required this.endsOn,
  }) : goal = normalizeGoal(goal) {
    // A focus ended on the day it began is still a (very short) focus.
    if (endsOn.compareTo(startsOn) < 0) {
      throw ArgumentError.value(
        endsOn,
        'endsOn',
        'Must not be before startsOn',
      );
    }
  }

  /// A focus that starts on [today] and runs for [days] days.
  factory FocusPeriod.starting({
    required FocusPurpose purpose,
    String goal = '',
    required LocalDate today,
    int? days,
  }) => FocusPeriod(
    purpose: purpose,
    goal: goal,
    startsOn: today,
    endsOn: today.addDays(days ?? purpose.defaultDays),
  );

  factory FocusPeriod.fromJson(Map<String, Object?> json) {
    final purpose = FocusPurposeWords.tryParse(json['purpose']);
    if (purpose == null) throw const FormatException('Unknown focus purpose');
    final goal = json['goal'];
    return FocusPeriod(
      purpose: purpose,
      goal: goal is String ? goal : '',
      startsOn: LocalDate.fromJson(json['startsOn']),
      endsOn: LocalDate.fromJson(json['endsOn']),
    );
  }

  static const int maxGoalLength = 80;

  /// The longest a focus can run from its start.
  static const int maxDays = 365;

  final FocusPurpose purpose;

  /// The user's own words for it, or empty.
  final String goal;
  final LocalDate startsOn;
  final LocalDate endsOn;

  /// What Home calls this focus: the user's goal, else its purpose.
  String get title => goal.isEmpty ? purpose.label : goal;

  /// How many days it runs, start to end.
  int get lengthInDays => daysBetween(startsOn, endsOn);

  /// Days left on [today]; 0 once it is over.
  int daysLeft(LocalDate today) {
    final left = daysBetween(today, endsOn);
    return left < 0 ? 0 : left;
  }

  bool isOverOn(LocalDate today) => today.compareTo(endsOn) >= 0;

  /// The same focus ending on [day] instead.
  FocusPeriod endingOn(LocalDate day) => FocusPeriod(
    purpose: purpose,
    goal: goal,
    startsOn: startsOn,
    endsOn: day,
  );

  /// The days a new end date can be: after [today], at most [maxDays] from
  /// the start.
  LocalDate latestEnd() => startsOn.addDays(maxDays);

  static String normalizeGoal(String value) {
    final tidy = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    final runes = tidy.runes.toList(growable: false);
    return runes.length <= maxGoalLength
        ? tidy
        : String.fromCharCodes(runes.take(maxGoalLength)).trimRight();
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'purpose': purpose.name,
    if (goal.isNotEmpty) 'goal': goal,
    'startsOn': startsOn.toJson(),
    'endsOn': endsOn.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is FocusPeriod &&
      other.purpose == purpose &&
      other.goal == goal &&
      other.startsOn == startsOn &&
      other.endsOn == endsOn;

  @override
  int get hashCode => Object.hash(purpose, goal, startsOn, endsOn);
}

/// Whole days from [from] to [to]; negative when [to] is earlier.
int daysBetween(LocalDate from, LocalDate to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Rest days: one day off a week, when hidden apps open without asking and
/// reminders stay quiet. A rest day is neither a proof day nor an empty
/// one, so it never ends a Prooflight run.
abstract final class RestDayRules {
  /// One rest day in any seven days.
  static const int daysBetweenRests = 7;

  /// Whether [today] can be a rest day, given the rest days already taken.
  static bool canRest(LocalDate today, Iterable<LocalDate> restDays) =>
      !restDays.contains(today) && nextAllowed(today, restDays) == today;

  /// The first day from [today] that can be a rest day.
  static LocalDate nextAllowed(LocalDate today, Iterable<LocalDate> restDays) {
    LocalDate? latest;
    for (final day in restDays) {
      if (day.compareTo(today) > 0) continue;
      if (latest == null || day.compareTo(latest) > 0) latest = day;
    }
    if (latest == null) return today;
    final next = latest.addDays(daysBetweenRests);
    return next.compareTo(today) > 0 ? next : today;
  }
}

/// How a focus went, rebuilt from what the phone already keeps.
class FocusSummary {
  const FocusSummary({
    required this.days,
    required this.restDays,
    required this.proofDays,
    required this.proofs,
    required this.opensAvoided,
  });

  /// Rebuilds the summary of [focus] up to [today] (or its end, if sooner).
  ///
  /// - [days]: the days of the focus so far, rest days included.
  /// - [proofDays]: days in it with at least one task backed by proof.
  /// - [proofs]: tasks backed by proof in it.
  /// - [opensAvoided]: hidden apps that asked "Why now?" and stayed closed
  ///   (not opened, and the wait not sat out). History keeps 30 days, so a
  ///   longer focus counts its last 30.
  factory FocusSummary.of({
    required FocusPeriod focus,
    required LocalDate today,
    required Iterable<ProofRecord> proofRecords,
    required Iterable<Attempt> attempts,
    required Iterable<LocalDate> restDays,
    required LocalDate Function(DateTime instant) curreDay,
  }) {
    final end = today.compareTo(focus.endsOn) < 0 ? today : focus.endsOn;
    bool inFocus(LocalDate day) =>
        day.compareTo(focus.startsOn) >= 0 && day.compareTo(end) < 0;
    final provedTasks = <String>{};
    final provedDays = <LocalDate>{};
    for (final record in proofRecords) {
      if (!record.countsForProoflight || !inFocus(record.date)) continue;
      provedTasks.add(record.taskId);
      provedDays.add(record.date);
    }
    var avoided = 0;
    for (final attempt in attempts) {
      if (attempt.overridden || attempt.outcome == UnlockOutcome.open) {
        continue;
      }
      if (inFocus(curreDay(attempt.at))) avoided++;
    }
    final elapsed = daysBetween(focus.startsOn, end);
    return FocusSummary(
      days: elapsed < 0 ? 0 : elapsed,
      restDays: restDays.where(inFocus).toSet().length,
      proofDays: provedDays.length,
      proofs: provedTasks.length,
      opensAvoided: avoided,
    );
  }

  final int days;
  final int restDays;
  final int proofDays;
  final int proofs;
  final int opensAvoided;
}

/// A focus as picked on screen, before it has a start: a purpose, the
/// user's words, and either a ready-made length or an end date.
class FocusChoice {
  const FocusChoice({
    required this.purpose,
    this.goal = '',
    this.days,
    this.endsOn,
  });

  final FocusPurpose purpose;
  final String goal;
  final int? days;
  final LocalDate? endsOn;

  /// The focus this choice makes when it starts on [today]. An end date
  /// that isn't after [today] falls back to the purpose's usual length.
  FocusPeriod periodFrom(LocalDate today) {
    final end = endsOn;
    if (end != null && end.compareTo(today) > 0) {
      return FocusPeriod(
        purpose: purpose,
        goal: goal,
        startsOn: today,
        endsOn: end,
      );
    }
    return FocusPeriod.starting(
      purpose: purpose,
      goal: goal,
      today: today,
      days: days,
    );
  }
}
