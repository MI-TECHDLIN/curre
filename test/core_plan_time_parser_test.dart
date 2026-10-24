import 'package:curre/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const utc = FixedOffsetTimeZone(Duration.zero);
  final schedule = SessionSchedule.fromSettings(Settings(), timeZone: utc);

  DateTime parse(String? text, DateTime now, {SessionWindow? window}) =>
      resolvePlanEnd(
        endPhrase: text == null
            ? null
            : SourceSpan(text: text, start: 0, end: text.runes.length),
        now: now,
        session: window ?? schedule.current(now),
      );

  test('accepts every specified form', () {
    final morning = DateTime.utc(2026, 10, 24, 5);
    expect(parse('8', morning), DateTime.utc(2026, 10, 24, 8));
    expect(parse('8am', morning), DateTime.utc(2026, 10, 24, 8));
    expect(parse('8:30', morning), DateTime.utc(2026, 10, 24, 8, 30));
    expect(parse('noon', morning), DateTime.utc(2026, 10, 24, 12));
    expect(parse('till 7', morning), DateTime.utc(2026, 10, 24, 7));

    final evening = DateTime.utc(2026, 10, 24, 18);
    expect(parse('8.30pm', evening), DateTime.utc(2026, 10, 24, 20, 30));
  });

  test('bare hours choose the next match within the session', () {
    final afternoon = DateTime.utc(2026, 10, 24, 13);
    expect(parse('till 4', afternoon), DateTime.utc(2026, 10, 24, 16));

    final evening = DateTime.utc(2026, 10, 24, 18);
    expect(parse('1', evening), DateTime.utc(2026, 10, 25, 1));
  });

  test('junk, elapsed times, and times outside the session use its end', () {
    final now = DateTime.utc(2026, 10, 24, 9);
    final end = DateTime.utc(2026, 10, 24, 12);
    expect(parse(null, now), end);
    expect(parse('after breakfast', now), end);
    expect(parse('25:00', now), end);
    expect(parse('8am', now), end);
    expect(parse('8.30pm', now), end);
  });

  test('session edge is allowed but remains the exclusive boundary', () {
    final now = DateTime.utc(2026, 10, 24, 11);
    expect(parse('12', now), DateTime.utc(2026, 10, 24, 12));
    expect(schedule.current(parse('12', now)).session, SessionName.afternoon);
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
    // At 05:45 UTC the first 01:30 has passed; clocks fall back at 06:00,
    // so the second 01:30 at 06:30 UTC is the next match.
    final now = DateTime.utc(2026, 11, 1, 5, 45);
    final window = overlapSchedule.current(now);

    expect(
      parse('1:30', now, window: window),
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

    // 02:30 does not exist; it normalizes to 03:30 EDT (07:30 UTC).
    expect(parse('2:30', now, window: window), DateTime.utc(2026, 3, 8, 7, 30));
  });
}
