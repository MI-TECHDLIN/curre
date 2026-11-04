import 'models.dart';
import 'sessions.dart';
import 'span.dart';

final RegExp _leadingTimeWords = RegExp(
  r"^(?:(?:till|until)|(?:hasta(?:\s+las)?)|(?:até(?:\s+às)?)|(?:jusqu['’]?(?:à|a)?)|bis)\s+",
  caseSensitive: false,
);

/// Resolves the plan's extracted end phrase to the next matching wall time in
/// [session]. Missing, unrecognized, elapsed, or out-of-session times use the
/// session's exclusive end boundary.
DateTime resolvePlanEnd({
  required SourceSpan? endPhrase,
  required DateTime now,
  required SessionWindow session,
  String languageCode = 'en',
}) {
  final phrase = endPhrase?.text.trim();
  if (phrase == null || phrase.isEmpty) return session.endsAt.toUtc();

  final token = _normaliseTimePhrase(phrase, languageCode);
  final times = _candidateTimes(token, languageCode);
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

String _normaliseTimePhrase(String phrase, String languageCode) {
  var token = phrase.toLowerCase().trim().replaceFirst(_leadingTimeWords, '');
  token = token
      .replaceAll(RegExp(r'\bp\s*\.\s*m\s*\.?'), 'pm')
      .replaceAll(RegExp(r'\ba\s*\.\s*m\s*\.?'), 'am')
      .replaceAll(RegExp(r'\s+uhr\b'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  // French and Portuguese commonly write 7h30; a trailing h means :00.
  token = token.replaceFirstMapped(
    RegExp(r'^(\d{1,2})\s*h\s*(\d{2})$'),
    (match) => '${match.group(1)}:${match.group(2)}',
  );
  token = token.replaceFirstMapped(
    RegExp(r'^(\d{1,2})\s*h$'),
    (match) => match.group(1)!,
  );
  return token.replaceAll(' ', '');
}

List<LocalTime>? _candidateTimes(String token, String languageCode) {
  final language = languageCode.toLowerCase().split(RegExp('[-_]')).first;
  final noon = switch (language) {
    'es' => const {'mediodía', 'mediodia'},
    'fr' => const {'midi'},
    'pt' => const {'meio-dia', 'meiodia'},
    'de' => const {'mittag'},
    _ => const {'noon'},
  };
  final midnight = switch (language) {
    'es' => const {'medianoche'},
    'fr' => const {'minuit'},
    'pt' => const {'meia-noite', 'meianoite'},
    'de' => const {'mitternacht'},
    _ => const {'midnight'},
  };
  if (noon.contains(token)) return const <LocalTime>[LocalTime(12)];
  if (midnight.contains(token)) return const <LocalTime>[LocalTime(0)];

  final match = RegExp(r'^(\d{1,2})(?:(?::|\.)(\d{2}))?(am|pm)?$')
      .firstMatch(token);
  if (match == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.tryParse(match.group(2) ?? '0');
  if (hour < 0 || hour > 23 || minute == null || minute > 59) return null;

  final meridiem = match.group(3);
  if (meridiem != null) {
    if (hour < 1 || hour > 12) return null;
    final hour24 = switch (meridiem) {
      'am' => hour == 12 ? 0 : hour,
      'pm' => hour == 12 ? 12 : hour + 12,
      _ => throw StateError('Unreachable meridiem'),
    };
    return <LocalTime>[LocalTime(hour24, minute)];
  }

  if (hour == 0 || hour > 12) return <LocalTime>[LocalTime(hour, minute)];

  if (hour == 12) {
    return <LocalTime>[LocalTime(0, minute), LocalTime(12, minute)];
  }
  return <LocalTime>[LocalTime(hour, minute), LocalTime(hour + 12, minute)];
}
