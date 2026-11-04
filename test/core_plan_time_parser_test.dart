import 'package:curre/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const utc = FixedOffsetTimeZone(Duration.zero);
  final schedule = SessionSchedule.fromSettings(Settings(), timeZone: utc);

  ResolvedPlanTime resolve(
    String text,
    DateTime now, {
    SessionWindow? window,
  }) => resolvePlanTime(
    expression: parseEnglishTimeExpression(text),
    now: now,
    session: window ?? schedule.current(now),
  );

  DateTime legacy(
    String? text,
    DateTime now, {
    SessionWindow? window,
    String language = 'en',
  }) => resolvePlanEnd(
    endPhrase: text == null
        ? null
        : SourceSpan(text: text, start: 0, end: text.runes.length),
    now: now,
    session: window ?? schedule.current(now),
    languageCode: language,
  );

  test('understands every duration form', () {
    final now = DateTime.utc(2026, 10, 24, 15);
    final expected = <String, DateTime>{
      'watch for 2hrs': DateTime.utc(2026, 10, 24, 17),
      'watch for 2 hours': DateTime.utc(2026, 10, 24, 17),
      'watch for an hour and a half': DateTime.utc(2026, 10, 24, 16, 30),
      'watch for 90 min': DateTime.utc(2026, 10, 24, 16, 30),
      'watch for 45 minutes': DateTime.utc(2026, 10, 24, 15, 45),
      'watch for half an hour': DateTime.utc(2026, 10, 24, 15, 30),
    };
    for (final entry in expected.entries) {
      expect(resolve(entry.key, now).endsAt, entry.value, reason: entry.key);
    }
  });

  test('understands clock ends and natural starts', () {
    final afternoon = DateTime.utc(2026, 10, 24, 15);
    expect(
      resolve('work until 7', afternoon).endsAt,
      DateTime.utc(2026, 10, 24, 19),
    );
    expect(
      resolve('work till 7:30pm', afternoon).endsAt,
      DateTime.utc(2026, 10, 24, 19, 30),
    );
    expect(
      resolve('work by 3pm', DateTime.utc(2026, 10, 24, 13)).endsAt,
      DateTime.utc(2026, 10, 24, 15),
    );

    final ranged = resolve('study from 4 to 6', afternoon);
    expect(ranged.startsAt, DateTime.utc(2026, 10, 24, 16));
    expect(ranged.endsAt, DateTime.utc(2026, 10, 24, 18));

    final anchored = resolve('at 5 for an hour', afternoon);
    expect(anchored.startsAt, DateTime.utc(2026, 10, 24, 17));
    expect(anchored.endsAt, DateTime.utc(2026, 10, 24, 18));
  });

  test('accepts the five app languages and their usual time forms', () {
    final morning = DateTime.utc(2026, 10, 24, 5);
    expect(legacy('until 7', morning), DateTime.utc(2026, 10, 24, 7));
    expect(
      legacy('hasta las 7', morning, language: 'es'),
      DateTime.utc(2026, 10, 24, 7),
    );
    expect(
      legacy('jusqu’à 7 h 30', morning, language: 'fr'),
      DateTime.utc(2026, 10, 24, 7, 30),
    );
    expect(
      legacy('até às 7', morning, language: 'pt'),
      DateTime.utc(2026, 10, 24, 7),
    );
    expect(
      legacy('bis 7 Uhr', morning, language: 'de'),
      DateTime.utc(2026, 10, 24, 7),
    );
  });

  test('explicit durations may pass the current session end', () {
    final now = DateTime.utc(2026, 10, 24, 16, 30);
    expect(schedule.current(now).endsAt, DateTime.utc(2026, 10, 24, 17));
    expect(
      resolve('watch a 2 hrs maths video', now).endsAt,
      DateTime.utc(2026, 10, 24, 18, 30),
    );
  });

  test('caps explicit plans at six hours or midnight and reports the cap', () {
    final long = resolve('work for 10 hours', DateTime.utc(2026, 10, 24, 14));
    expect(long.endsAt, DateTime.utc(2026, 10, 24, 20));
    expect(long.wasCapped, isTrue);

    final midnight = resolve(
      'work for 3 hours',
      DateTime.utc(2026, 10, 24, 22),
    );
    expect(midnight.endsAt, DateTime.utc(2026, 10, 25));
    expect(midnight.wasCapped, isTrue);

    final noon = resolve('work until noon', DateTime.utc(2026, 10, 24, 5));
    expect(noon.endsAt, DateTime.utc(2026, 10, 24, 11));
    expect(noon.wasCapped, isTrue);
  });

  test(
    'finds separate app allowances without treating either as plan-wide',
    () {
      const text =
          'watch a 2 hrs maths video on YouTube and 20 min on WhatsApp';
      final appTimes = parseEnglishPerAppTimes(text, const <String, String>{
        'yt': 'YouTube',
        'wa': 'WhatsApp',
      });
      expect(appTimes['yt']?.durationMinutes, 120);
      expect(appTimes['yt']?.durationPhrase?.text, '2 hrs');
      expect(appTimes['wa']?.durationMinutes, 20);
      expect(appTimes['wa']?.durationPhrase?.text, '20 min');

      final excluded = <SourceSpan>[
        appTimes['yt']!.durationPhrase!,
        appTimes['wa']!.durationPhrase!,
      ];
      expect(
        parseEnglishTimeExpression(text, excluded: excluded).isEmpty,
        isTrue,
      );
    },
  );

  test('junk and elapsed explicit ends use the session end', () {
    final now = DateTime.utc(2026, 10, 24, 9);
    final end = DateTime.utc(2026, 10, 24, 12);
    expect(legacy(null, now), end);
    expect(legacy('after breakfast', now), end);
    expect(legacy('25:00', now), end);
    expect(legacy('8am', now), end);
  });

  test('legacy clock forms still resolve', () {
    final morning = DateTime.utc(2026, 10, 24, 5);
    expect(legacy('8', morning), DateTime.utc(2026, 10, 24, 8));
    expect(legacy('8am', morning), DateTime.utc(2026, 10, 24, 8));
    expect(legacy('8:30', morning), DateTime.utc(2026, 10, 24, 8, 30));
    expect(legacy('till 7', morning), DateTime.utc(2026, 10, 24, 7));
  });

  test('fall-back overlap picks the next occurrence of a wall time', () {
    final zone = TransitionTimeZone(
      initialOffset: const Duration(hours: -4),
      transitions: <OffsetTransition>[
        OffsetTransition(
          at: DateTime.utc(2026, 11, 1, 6),
          offsetAfter: const Duration(hours: -5),
        ),
      ],
    );
    final custom = Settings(
      sessionStarts: const <SessionName, LocalTime>{
        SessionName.morning: LocalTime(0),
        SessionName.afternoon: LocalTime(1),
        SessionName.evening: LocalTime(17),
      },
    );
    final overlapSchedule = SessionSchedule.fromSettings(
      custom,
      timeZone: zone,
    );
    final now = DateTime.utc(2026, 11, 1, 5, 45);
    final window = overlapSchedule.current(now);

    expect(
      legacy('1:30', now, window: window),
      DateTime.utc(2026, 11, 1, 6, 30),
    );
  });

  test('spring-forward nonexistent time is normalized by the DST gap', () {
    final zone = TransitionTimeZone(
      initialOffset: const Duration(hours: -5),
      transitions: <OffsetTransition>[
        OffsetTransition(
          at: DateTime.utc(2026, 3, 8, 7),
          offsetAfter: const Duration(hours: -4),
        ),
      ],
    );
    final custom = Settings(
      sessionStarts: const <SessionName, LocalTime>{
        SessionName.morning: LocalTime(0),
        SessionName.afternoon: LocalTime(12),
        SessionName.evening: LocalTime(17),
      },
    );
    final now = DateTime.utc(2026, 3, 8, 6);
    final window = SessionSchedule.fromSettings(
      custom,
      timeZone: zone,
    ).current(now);

    expect(
      legacy('2:30', now, window: window),
      DateTime.utc(2026, 3, 8, 7, 30),
    );
  });
}
