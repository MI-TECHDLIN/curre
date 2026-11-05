import 'models.dart';
import 'sessions.dart';
import 'span.dart';

final RegExp _leadingTimeWords = RegExp(
  r"^(?:(?:till|until|by|to|from|at)|(?:hasta(?:\s+las)?)|(?:até(?:\s+às)?)|(?:jusqu['’]?(?:à|a)?)|bis)\s+",
  caseSensitive: false,
);

/// Explicit plans never run longer than this. They also stop at the next
/// local midnight, whichever comes first.
const Duration maximumPlanDuration = Duration(hours: 6);

final RegExp _durationPattern = RegExp(
  r'\b(?:an?\s+hour\s+and\s+a\s+half|one\s+hour\s+and\s+a\s+half|half\s+an?\s+hour|an?\s+hour|one\s+hour|\d+(?:\.\d+)?\s*(?:hours?|hrs?|hr|h|minutes?|mins?|min|m))\b',
  caseSensitive: false,
);

const String _clockToken =
    r'(?:noon|midnight|(?:0?[1-9]|1[0-2])(?:(?::|\.)[0-5]\d)?\s*(?:am|pm)?)';

final RegExp _rangePattern = RegExp(
  'from\\s+($_clockToken)\\s+(?:to|until|till)\\s+($_clockToken)',
  caseSensitive: false,
);
final RegExp _startPattern = RegExp(
  '(?:from|at)\\s+($_clockToken)',
  caseSensitive: false,
);
final RegExp _endPattern = RegExp(
  '(?:until|till|by|to)\\s+($_clockToken)',
  caseSensitive: false,
);

final Map<String, RegExp> _localizedEndPatterns = <String, RegExp>{
  'es': RegExp(
    r'(?:(?:hasta(?:\s+las)?))\s+(mediod[ií]a|medianoche|\d{1,2}(?:(?::|\.)[0-5]\d)?)',
    caseSensitive: false,
  ),
  'fr': RegExp(
    r"(?:jusqu['’]?(?:à|a)?)\s+(midi|minuit|\d{1,2}(?:\s*h(?:\s*[0-5]\d)?)?)",
    caseSensitive: false,
  ),
  'pt': RegExp(
    r'(?:até(?:\s+às?)?)\s+(meio-dia|meiodia|meia-noite|meianoite|\d{1,2}(?:\s*h(?:\s*[0-5]\d)?)?)',
    caseSensitive: false,
  ),
  'de': RegExp(
    r'(?:bis)\s+(mittag|mitternacht|\d{1,2}(?:(?::|\.)[0-5]\d)?\s*(?:uhr)?)',
    caseSensitive: false,
  ),
};

class ResolvedPlanTime {
  const ResolvedPlanTime({
    required this.startsAt,
    required this.endsAt,
    required this.expression,
    required this.wasCapped,
    required this.usedFallback,
  });

  final DateTime startsAt;
  final DateTime endsAt;
  final PlanTimeExpression expression;
  final bool wasCapped;
  final bool usedFallback;
}

/// English is deliberately one isolated parser. A later language can provide
/// the same [PlanTimeExpression] without changing plan resolution or storage.
PlanTimeExpression parseEnglishTimeExpression(
  String text, {
  Iterable<SourceSpan> excluded = const <SourceSpan>[],
}) {
  final excludedList = excluded.toList(growable: false);
  SourceSpan? start;
  SourceSpan? end;

  final range = _rangePattern.firstMatch(text);
  if (range != null) {
    start = _groupSpan(text, range, 1);
    end = _groupSpan(text, range, 2);
  } else {
    final startMatch = _startPattern.firstMatch(text);
    if (startMatch != null) start = _groupSpan(text, startMatch, 1);
    final endMatch = _endPattern.firstMatch(text);
    if (endMatch != null) end = _groupSpan(text, endMatch, 1);
  }

  SourceSpan? duration;
  int? minutes;
  var wasClamped = false;
  for (final match in _durationPattern.allMatches(text)) {
    final candidate = _matchSpan(text, match);
    if (excludedList.any((span) => _overlaps(candidate, span))) continue;
    final parsed = durationMinutesFromEnglish(candidate.text);
    if (parsed == null) continue;
    duration = candidate;
    minutes = parsed.clamp(1, maximumPlanDuration.inMinutes);
    wasClamped = parsed != minutes;
    break;
  }

  return PlanTimeExpression(
    durationPhrase: duration,
    durationMinutes: minutes,
    startPhrase: start,
    startClock: start == null ? null : normalizeEnglishClock(start.text),
    endPhrase: end,
    endClock: end == null ? null : normalizeEnglishClock(end.text),
    wasClamped: wasClamped,
  );
}

/// Parses time words for the selected app language. English owns the richer
/// duration/range grammar today; the other language entries preserve their
/// established end-time forms behind the same interface so another grammar
/// can be added without touching plan construction or storage.
PlanTimeExpression parsePlanTimeExpression(
  String text, {
  String languageCode = 'en',
  Iterable<SourceSpan> excluded = const <SourceSpan>[],
}) {
  var parsed = parseEnglishTimeExpression(text, excluded: excluded);
  final language = _baseLanguage(languageCode);
  if (parsed.isEmpty) {
    final value = text.trim();
    final clock = normalizeClockPhrase(value, languageCode: language);
    if (value.isNotEmpty && clock != null) {
      final utf16Start = text.indexOf(value);
      final end = _utf16Span(text, utf16Start, utf16Start + value.length);
      parsed = PlanTimeExpression(endPhrase: end, endClock: clock);
    }
  }
  final pattern = _localizedEndPatterns[language];
  if (pattern == null) return parsed;

  final excludedList = excluded.toList(growable: false);
  for (final match in pattern.allMatches(text)) {
    final end = _groupSpan(text, match, 1);
    if (excludedList.any((span) => _overlaps(end, span))) continue;
    return PlanTimeExpression(
      durationPhrase: parsed.durationPhrase,
      durationMinutes: parsed.durationMinutes,
      startPhrase: parsed.startPhrase,
      startClock: parsed.startClock,
      endPhrase: end,
      endClock: normalizeClockPhrase(end.text, languageCode: language),
      wasClamped: parsed.wasClamped,
    );
  }
  return parsed;
}

/// Finds a duration tied to one app in a simple clause. Ambiguous clauses
/// naming several apps stay plan-wide, so Curre never invents which app a
/// timer belongs to.
Map<String, PlanTimeExpression> parseEnglishPerAppTimes(
  String text,
  Map<String, String> appLabels,
) {
  if (appLabels.isEmpty) return const <String, PlanTimeExpression>{};
  final durations = <SourceSpan>[
    for (final match in _durationPattern.allMatches(text))
      _matchSpan(text, match),
  ];
  final clauses = _clauses(text, durations);
  final found = <String, PlanTimeExpression>{};

  for (final clause in clauses) {
    final lower = clause.text.toLowerCase();
    final packages = <String>[
      for (final entry in appLabels.entries)
        if (_containsWords(lower, entry.value.toLowerCase())) entry.key,
    ];
    if (packages.length != 1) continue;
    final local = parseEnglishTimeExpression(clause.text);
    if (local.isEmpty) continue;
    found[packages.single] = _shiftExpression(local, clause.start);
  }
  return found;
}

/// Merges Clocked's structured result with the on-phone parser. Clocked's
/// spans win; a missing field is repaired locally so offline and partial
/// responses understand the same English forms.
PlanTimeExpression mergePlanTimeExpressions(
  PlanTimeExpression? primary,
  PlanTimeExpression fallback,
) {
  final value = primary;
  if (value == null) return fallback;
  return PlanTimeExpression(
    durationPhrase: value.durationPhrase ?? fallback.durationPhrase,
    durationMinutes: value.durationMinutes ?? fallback.durationMinutes,
    startPhrase: value.startPhrase ?? fallback.startPhrase,
    startClock: value.startClock ?? fallback.startClock,
    endPhrase: value.endPhrase ?? fallback.endPhrase,
    endClock: value.endClock ?? fallback.endClock,
    wasClamped: value.wasClamped || fallback.wasClamped,
  );
}

ResolvedPlanTime resolvePlanTime({
  required PlanTimeExpression expression,
  required DateTime now,
  required SessionWindow session,
  String languageCode = 'en',
  DateTime? fallbackEnd,
  DateTime? maximumEnd,
}) {
  final current = now.toUtc();
  final hasExplicitTime = !expression.isEmpty;
  var start = current;
  if (expression.startPhrase case final phrase?) {
    start =
        _resolveStart(
          phrase.text,
          current,
          session.timeZone,
          languageCode: languageCode,
        ) ??
        current;
  }

  DateTime? end;
  if (expression.endPhrase case final phrase?) {
    end = _resolveEnd(
      phrase.text,
      start,
      current,
      session.timeZone,
      languageCode: languageCode,
    );
  }
  if (end == null) {
    final minutes = expression.durationMinutes;
    if (minutes != null) end = start.add(Duration(minutes: minutes));
  }
  final usedFallback = end == null;
  end ??= (fallbackEnd ?? session.endsAt).toUtc();

  var capped = expression.wasClamped;
  if (hasExplicitTime) {
    final sixHours = start.add(maximumPlanDuration);
    final midnight = _nextMidnight(start, session.timeZone);
    final cap = sixHours.isBefore(midnight) ? sixHours : midnight;
    if (end.isAfter(cap)) {
      end = cap;
      capped = true;
    }
  }
  if (maximumEnd case final outerEnd? when end.isAfter(outerEnd.toUtc())) {
    end = outerEnd.toUtc();
    capped = true;
  }
  if (!end.isAfter(start)) {
    start = current;
    end = (fallbackEnd ?? session.endsAt).toUtc();
  }

  return ResolvedPlanTime(
    startsAt: start,
    endsAt: end,
    expression: expression,
    wasCapped: capped,
    usedFallback: usedFallback,
  );
}

/// Compatibility entry point for older responses that only carry `ends`.
DateTime resolvePlanEnd({
  required SourceSpan? endPhrase,
  required DateTime now,
  required SessionWindow session,
  String languageCode = 'en',
}) => resolvePlanTime(
  expression: PlanTimeExpression(
    endPhrase: endPhrase,
    endClock: endPhrase == null
        ? null
        : normalizeClockPhrase(endPhrase.text, languageCode: languageCode),
  ),
  now: now,
  session: session,
  languageCode: languageCode,
).endsAt;

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
  final language = _baseLanguage(languageCode);
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

String _baseLanguage(String languageCode) =>
    languageCode.toLowerCase().split(RegExp('[-_]')).first;

int? durationMinutesFromEnglish(String phrase) {
  final normalized = phrase.toLowerCase().trim().replaceAll(
    RegExp(r'\s+'),
    ' ',
  );
  if (normalized == 'an hour and a half' ||
      normalized == 'a hour and a half' ||
      normalized == 'one hour and a half') {
    return 90;
  }
  if (normalized == 'half an hour' || normalized == 'half a hour') return 30;
  if (normalized == 'an hour' ||
      normalized == 'a hour' ||
      normalized == 'one hour') {
    return 60;
  }
  final match = RegExp(
    r'^(\d+(?:\.\d+)?)\s*(hours?|hrs?|hr|h|minutes?|mins?|min|m)$',
    caseSensitive: false,
  ).firstMatch(normalized);
  if (match == null) return null;
  final amount = double.tryParse(match.group(1)!);
  if (amount == null || !amount.isFinite || amount <= 0) return null;
  final unit = match.group(2)!.toLowerCase();
  final minutes = unit.startsWith('h') ? amount * 60 : amount;
  return minutes.round();
}

String? normalizeEnglishClock(String phrase) {
  return normalizeClockPhrase(phrase);
}

String? normalizeClockPhrase(String phrase, {String languageCode = 'en'}) {
  final token = _normaliseTimePhrase(phrase, languageCode);
  final times = _candidateTimes(token, languageCode);
  if (times == null || times.isEmpty) return null;
  final value = times.first;
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

DateTime? _resolveStart(
  String token,
  DateTime now,
  CurreTimeZone zone, {
  required String languageCode,
}) {
  final wall = zone.toWallTime(now);
  final candidates = <DateTime>[];
  for (var day = 0; day <= 1; day++) {
    candidates.addAll(
      _instantsForClock(
        token,
        wall.date.addDays(day),
        zone,
        languageCode: languageCode,
      ).where((candidate) => !candidate.isBefore(now)),
    );
  }
  if (candidates.isEmpty) return null;
  candidates.sort();
  return candidates.first;
}

DateTime? _resolveEnd(
  String token,
  DateTime start,
  DateTime now,
  CurreTimeZone zone, {
  required String languageCode,
}) {
  final startWall = zone.toWallTime(start);
  final midnight = _nextMidnight(start, zone);
  final after = start.isAfter(now) ? start : now;
  final candidates = <DateTime>[];
  for (var day = 0; day <= 1; day++) {
    candidates.addAll(
      _instantsForClock(
        token,
        startWall.date.addDays(day),
        zone,
        languageCode: languageCode,
      ).where(
        (candidate) => candidate.isAfter(after) && !candidate.isAfter(midnight),
      ),
    );
  }
  if (candidates.isEmpty) return null;
  candidates.sort();
  return candidates.first;
}

List<DateTime> _instantsForClock(
  String token,
  LocalDate date,
  CurreTimeZone zone, {
  required String languageCode,
}) {
  final compact = _normaliseTimePhrase(token, languageCode);
  final times = _candidateTimes(compact, languageCode);
  if (times == null) return const <DateTime>[];
  return <DateTime>[
    for (final time in times)
      ...zone.instantsFor(LocalWallTime(date: date, time: time)),
  ];
}

DateTime _nextMidnight(DateTime instant, CurreTimeZone zone) {
  final date = zone.toWallTime(instant).date.addDays(1);
  final values = zone.instantsFor(
    LocalWallTime(date: date, time: const LocalTime(0)),
  );
  if (values.isNotEmpty) return values.first.toUtc();
  return instant.toUtc().add(const Duration(days: 1));
}

SourceSpan _groupSpan(String source, RegExpMatch match, int group) {
  final whole = match.group(0)!;
  var within = 0;
  for (var index = 1; index <= group; index++) {
    final value = match.group(index)!;
    within = whole.indexOf(value, within);
    if (index < group) within += value.length;
  }
  final start = match.start + within;
  return _utf16Span(source, start, start + match.group(group)!.length);
}

SourceSpan _matchSpan(String source, RegExpMatch match) =>
    _utf16Span(source, match.start, match.end);

SourceSpan _utf16Span(String source, int start, int end) => SourceSpan(
  text: source.substring(start, end),
  start: source.substring(0, start).runes.length,
  end: source.substring(0, end).runes.length,
);

bool _overlaps(SourceSpan left, SourceSpan right) =>
    left.start < right.end && right.start < left.end;

PlanTimeExpression _shiftExpression(PlanTimeExpression value, int by) {
  SourceSpan? shift(SourceSpan? span) => span == null
      ? null
      : SourceSpan(text: span.text, start: span.start + by, end: span.end + by);
  return PlanTimeExpression(
    durationPhrase: shift(value.durationPhrase),
    durationMinutes: value.durationMinutes,
    startPhrase: shift(value.startPhrase),
    startClock: value.startClock,
    endPhrase: shift(value.endPhrase),
    endClock: value.endClock,
    wasClamped: value.wasClamped,
  );
}

class _Clause {
  const _Clause(this.text, this.start);

  final String text;
  final int start;
}

List<_Clause> _clauses(String source, List<SourceSpan> durations) {
  final delimiter = RegExp(r'[,;]|\b(?:and|then)\b', caseSensitive: false);
  final clauses = <_Clause>[];
  var utf16Start = 0;
  for (final match in delimiter.allMatches(source)) {
    final delimiterSpan = _utf16Span(source, match.start, match.end);
    if (durations.any((duration) => _overlaps(delimiterSpan, duration))) {
      continue;
    }
    final raw = source.substring(utf16Start, match.start);
    final text = raw.trim();
    if (text.isNotEmpty) {
      final leading = raw.indexOf(text);
      final offset = source.substring(0, utf16Start + leading).runes.length;
      clauses.add(_Clause(text, offset));
    }
    utf16Start = match.end;
  }
  final raw = source.substring(utf16Start);
  final tail = raw.trim();
  if (tail.isNotEmpty) {
    final leading = raw.indexOf(tail);
    clauses.add(
      _Clause(tail, source.substring(0, utf16Start + leading).runes.length),
    );
  }
  return clauses;
}

bool _containsWords(String text, String value) {
  if (value.isEmpty) return false;
  final escaped = RegExp.escape(value).replaceAll(r'\ ', r'\s+');
  return RegExp(
    '(?:^|\\b)$escaped(?:\\b|\$)',
    caseSensitive: false,
  ).hasMatch(text);
}
