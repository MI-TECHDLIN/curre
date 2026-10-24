import 'package:curre/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final settings = Settings();
  const utc = FixedOffsetTimeZone(Duration.zero);

  test('default sessions use half-open boundaries and cross midnight', () {
    final schedule = SessionSchedule.fromSettings(settings, timeZone: utc);

    final beforeMorning = schedule.current(DateTime.utc(2026, 10, 24, 3, 59));
    expect(beforeMorning.session, SessionName.evening);
    expect(beforeMorning.localStartDate, const LocalDate(2026, 10, 23));
    expect(beforeMorning.endsAt, DateTime.utc(2026, 10, 24, 4));

    expect(
      schedule.current(DateTime.utc(2026, 10, 24, 4)).session,
      SessionName.morning,
    );
    expect(
      schedule.current(DateTime.utc(2026, 10, 24, 12)).session,
      SessionName.afternoon,
    );
    final evening = schedule.current(DateTime.utc(2026, 10, 24, 17));
    expect(evening.session, SessionName.evening);
    expect(evening.nextBoundary, DateTime.utc(2026, 10, 25, 4));
    expect(evening.contains(evening.startsAt), isTrue);
    expect(evening.contains(evening.endsAt), isFalse);
  });

  test('editable starts drive the next boundary', () {
    final custom = Settings(
      sessionStarts: const <SessionName, LocalTime>{
        SessionName.morning: LocalTime(6, 30),
        SessionName.afternoon: LocalTime(11, 45),
        SessionName.evening: LocalTime(19),
      },
    );
    final schedule = SessionSchedule.fromSettings(custom, timeZone: utc);
    final current = schedule.current(DateTime.utc(2026, 10, 24, 12));
    expect(current.session, SessionName.afternoon);
    expect(
      schedule.nextBoundary(DateTime.utc(2026, 10, 24, 12)),
      DateTime.utc(2026, 10, 24, 19),
    );
  });

  test('same schedule re-evaluates a device time-zone change', () {
    final zone = _MutableOffsetTimeZone(Duration.zero);
    final schedule = SessionSchedule.fromSettings(settings, timeZone: zone);
    final instant = DateTime.utc(2026, 10, 24, 10);

    expect(schedule.current(instant).session, SessionName.morning);
    zone.offset = const Duration(hours: 7);
    expect(schedule.current(instant).session, SessionName.evening);
  });

  test('DST gap normalizes an editable boundary forward', () {
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
        SessionName.morning: LocalTime(1, 30),
        SessionName.afternoon: LocalTime(2, 30),
        SessionName.evening: LocalTime(17),
      },
    );
    final session = SessionSchedule.fromSettings(
      custom,
      timeZone: zone,
    ).current(DateTime.utc(2026, 3, 8, 6, 45));

    expect(session.session, SessionName.morning);
    expect(session.endsAt, DateTime.utc(2026, 3, 8, 7, 30));
    expect(zone.toWallTime(session.endsAt).time, const LocalTime(3, 30));
  });
}

class _MutableOffsetTimeZone implements CurreTimeZone {
  _MutableOffsetTimeZone(this.offset);

  Duration offset;

  FixedOffsetTimeZone get _delegate => FixedOffsetTimeZone(offset);

  @override
  List<DateTime> instantsFor(LocalWallTime wallTime) =>
      _delegate.instantsFor(wallTime);

  @override
  LocalWallTime toWallTime(DateTime instant) => _delegate.toWallTime(instant);
}
