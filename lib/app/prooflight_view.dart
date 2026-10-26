import '../core/core.dart';
import '../design/design.dart';

// Words and marks Prooflight's screens share: the completion moment, the
// profile sheet and History all read the same core summary.

const _weekdays = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _months = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String weekdayName(LocalDate date) =>
    _weekdays[DateTime.utc(date.year, date.month, date.day).weekday - 1];

String dayMonth(LocalDate date) => '${date.day} ${_months[date.month - 1]}';

/// "1 proof day", "12 proof days".
String proofDaysText(int days) =>
    days == 1 ? '1 proof day' : '$days proof days';

/// The last seven Curre days, ending today, as their marks: proof days
/// ring ember, a covered day wears its cloud, a waiting note rings faintly,
/// and today keeps the session's sky until its sun is up (the strip's
/// `todayLit`).
List<WeekDay> proofWeek(ProofSummary summary) => <WeekDay>[
  for (var offset = 6; offset >= 0; offset--)
    _weekDay(summary, summary.today.addDays(-offset)),
];

WeekDay _weekDay(ProofSummary summary, LocalDate date) {
  final today = date == summary.today;
  final state = summary.pendingDates.contains(date)
      ? DayState.pending
      : today
      ? DayState.today
      : summary.proofDates.contains(date)
      ? DayState.proof
      : summary.cloudDates.contains(date)
      ? DayState.cloud
      : DayState.quiet;
  return WeekDay(
    weekdayName(date).substring(0, 3),
    date.day,
    state,
    isToday: today,
  );
}

/// The days the current run covers, for the line under its count:
/// "Starting today", "Tuesday to Saturday", "Since 3 October".
String runRange(ProofSummary summary) {
  final start = summary.runStart;
  if (start == null) return '';
  final end = summary.today;
  if (start.compareTo(end) >= 0) return 'Starting today';
  final days = DateTime.utc(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
  if (days < 7) return '${weekdayName(start)} to ${weekdayName(end)}';
  return 'Since ${dayMonth(start)}';
}

/// The ray pattern a run reaches at a milestone (proof audit §4: a new
/// pattern, never louder confetti), or null between milestones.
String? milestoneLine(int proofDays) => switch (proofDays) {
  7 => 'Seven proof days: your rays now end in sparks.',
  21 => '21 proof days: a ring of light now stands behind your sun.',
  50 => '50 proof days: your sun wears a second ring.',
  _ => null,
};

const cloudDayLine = 'If a day passes without proof, it keeps your run going.';
