import 'package:intl/intl.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../l10n/l10n.dart';

// Words and marks Prooflight's screens share: the completion moment, the
// profile sheet and History all read the same core summary.

String weekdayName(LocalDate date, [String? locale]) => DateFormat(
  'EEEE',
  locale,
).format(DateTime(date.year, date.month, date.day));

String dayMonth(LocalDate date, [String? locale]) => DateFormat(
  'd MMMM',
  locale,
).format(DateTime(date.year, date.month, date.day));

/// "1 proof day", "12 proof days".
String proofDaysText(int days, [AppLocalizations? l10n]) =>
    l10n?.proofDaysCount(days) ??
    (days == 1 ? '1 proof day' : '$days proof days');

/// The last seven Curre days, ending today, as their marks: proof days
/// ring ember, a covered day wears its cloud, a waiting note rings faintly,
/// and today keeps the session's sky until its sun is up (the strip's
/// `todayLit`).
List<WeekDay> proofWeek(ProofSummary summary, [String? locale]) => <WeekDay>[
  for (var offset = 6; offset >= 0; offset--)
    _weekDay(summary, summary.today.addDays(-offset), locale),
];

WeekDay _weekDay(ProofSummary summary, LocalDate date, String? locale) {
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
    DateFormat('EEE', locale).format(DateTime(date.year, date.month, date.day)),
    date.day,
    state,
    isToday: today,
  );
}

/// The days the current run covers, for the line under its count:
/// "Starting today", "Tuesday to Saturday", "Since 3 October".
String runRange(
  ProofSummary summary, {
  AppLocalizations? l10n,
  String? locale,
}) {
  final start = summary.runStart;
  if (start == null) return '';
  final end = summary.today;
  if (start.compareTo(end) >= 0) return l10n?.startingToday ?? 'Starting today';
  final days = DateTime.utc(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
  if (days < 7) {
    final first = weekdayName(start, locale);
    final last = weekdayName(end, locale);
    return l10n?.proofRunRange(first, last) ?? '$first to $last';
  }
  final date = dayMonth(start, locale);
  return l10n?.sinceDate(date) ?? 'Since $date';
}

/// The ray pattern a run reaches at a milestone (proof audit §4: a new
/// pattern, never louder confetti), or null between milestones.
String? milestoneLine(
  int proofDays, [
  AppLocalizations? l10n,
]) => switch (proofDays) {
  7 => l10n?.milestoneSeven ?? 'Seven proof days: your rays now end in sparks.',
  21 =>
    l10n?.milestoneTwentyOne ??
        '21 proof days: a ring of light now stands behind your sun.',
  50 => l10n?.milestoneFifty ?? '50 proof days: your sun wears a second ring.',
  _ => null,
};

const cloudDayLine = 'If a day passes without proof, it keeps your run going.';

String cloudDayLineFor(AppLocalizations l10n) => l10n.cloudDayKeepsRun;
