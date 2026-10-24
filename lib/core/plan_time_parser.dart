import 'models.dart';
import 'sessions.dart';
import 'span.dart';

final RegExp _clockPattern = RegExp(
  r'^(?:(?:till|until)\s+)?(noon|(?:0?[1-9]|1[0-2])(?:(?::|\.)[0-5]\d)?\s*(?:am|pm)?)$',
  caseSensitive: false,
);

/// Resolves the plan's extracted end phrase to the next matching wall time in
/// [session]. Missing, unrecognized, elapsed, or out-of-session times use the
/// session's exclusive end boundary.
DateTime resolvePlanEnd({
  required SourceSpan? endPhrase,
  required DateTime now,
  required SessionWindow session,
}) {
  final phrase = endPhrase?.text.trim();
  if (phrase == null || phrase.isEmpty) return session.endsAt.toUtc();

  final match = _clockPattern.firstMatch(phrase);
  if (match == null) return session.endsAt.toUtc();
  final token = match.group(1)!.toLowerCase().replaceAll(' ', '');
  final times = _candidateTimes(token);
  if (times == null) return session.endsAt.toUtc();

  final current = now.toUtc();
  final startWall = session.timeZone.toWallTime(session.startsAt);
  final lastWall = session.timeZone.toWallTime(
    session.endsAt.subtract(const Duration(microseconds: 1)),
  );
  final dayCount =
      DateTime.utc(lastWall.date.year, lastWall.date.month, lastWall.date.day)
          .difference(
            DateTime.utc(
              startWall.date.year,
              startWall.date.month,
              startWall.date.day,
            ),
          )
          .inDays;

  final matches = <DateTime>[];
  for (var day = 0; day <= dayCount + 1; day++) {
    final date = startWall.date.addDays(day);
    for (final time in times) {
      for (final candidate in session.timeZone.instantsFor(
        LocalWallTime(date: date, time: time),
      )) {
        final utc = candidate.toUtc();
        if (utc.isAfter(current) &&
            !utc.isBefore(session.startsAt) &&
            !utc.isAfter(session.endsAt)) {
          matches.add(utc);
        }
      }
    }
  }
  if (matches.isEmpty) return session.endsAt.toUtc();
  matches.sort();
  return matches.first;
}

List<LocalTime>? _candidateTimes(String token) {
  if (token == 'noon') return const <LocalTime>[LocalTime(12)];

  final match = RegExp(r'^(\d{1,2})(?:(?::|\.)(\d{2}))?(am|pm)?$')
      .firstMatch(token);
  if (match == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.tryParse(match.group(2) ?? '0');
  if (hour < 1 || hour > 12 || minute == null || minute > 59) return null;

  final meridiem = match.group(3);
  if (meridiem != null) {
    final hour24 = switch (meridiem) {
      'am' => hour == 12 ? 0 : hour,
      'pm' => hour == 12 ? 12 : hour + 12,
      _ => throw StateError('Unreachable meridiem'),
    };
    return <LocalTime>[LocalTime(hour24, minute)];
  }

  if (hour == 12) {
    return <LocalTime>[LocalTime(0, minute), LocalTime(12, minute)];
  }
  return <LocalTime>[LocalTime(hour, minute), LocalTime(hour + 12, minute)];
}
