import 'models.dart';

class LocalWallTime implements Comparable<LocalWallTime> {
  const LocalWallTime({required this.date, required this.time});

  final LocalDate date;
  final LocalTime time;

  DateTime get _nominalUtc =>
      DateTime.utc(date.year, date.month, date.day, time.hour, time.minute);

  @override
  int compareTo(LocalWallTime other) =>
      _nominalUtc.compareTo(other._nominalUtc);

  @override
  bool operator ==(Object other) =>
      other is LocalWallTime && date == other.date && time == other.time;

  @override
  int get hashCode => Object.hash(date, time);
}

/// Converts between UTC instants and the device's current wall clock.
///
/// Implementations are deliberately queried on every evaluation. No offset or
/// session boundary is cached, so clock and device-time-zone changes take
/// effect on the next Home render.
abstract interface class CurreTimeZone {
  LocalWallTime toWallTime(DateTime instant);

  /// Returns every instant matching a wall time, earliest first. A fall-back
  /// overlap may have two matches.
  List<DateTime> instantsFor(LocalWallTime wallTime);
}

class SystemCurreTimeZone implements CurreTimeZone {
  const SystemCurreTimeZone();

  @override
  LocalWallTime toWallTime(DateTime instant) {
    final local = instant.toLocal();
    return LocalWallTime(
      date: LocalDate(local.year, local.month, local.day),
      time: LocalTime(local.hour, local.minute),
    );
  }

  @override
  List<DateTime> instantsFor(LocalWallTime wallTime) {
    // Dart normalizes a wall time in a DST gap forward, matching Android's
    // practical behavior for an editable schedule boundary.
    final local = DateTime(
      wallTime.date.year,
      wallTime.date.month,
      wallTime.date.day,
      wallTime.time.hour,
      wallTime.time.minute,
    );
    return <DateTime>[local.toUtc()];
  }
}

class FixedOffsetTimeZone implements CurreTimeZone {
  const FixedOffsetTimeZone(this.offset);

  final Duration offset;

  @override
  LocalWallTime toWallTime(DateTime instant) {
    final wall = instant.toUtc().add(offset);
    return LocalWallTime(
      date: LocalDate(wall.year, wall.month, wall.day),
      time: LocalTime(wall.hour, wall.minute),
    );
  }

  @override
  List<DateTime> instantsFor(LocalWallTime wallTime) => <DateTime>[
    DateTime.utc(
      wallTime.date.year,
      wallTime.date.month,
      wallTime.date.day,
      wallTime.time.hour,
      wallTime.time.minute,
    ).subtract(offset),
  ];
}

/// A deterministic transition-based zone, useful for exercising DST rules.
class OffsetTransition {
  OffsetTransition({required DateTime at, required this.offsetAfter})
    : at = at.toUtc();

  final DateTime at;
  final Duration offsetAfter;
}

class TransitionTimeZone implements CurreTimeZone {
  TransitionTimeZone({
    required this.initialOffset,
    required List<OffsetTransition> transitions,
  }) : transitions = List.unmodifiable(
         List<OffsetTransition>.of(transitions)
           ..sort((a, b) => a.at.compareTo(b.at)),
       );

  final Duration initialOffset;
  final List<OffsetTransition> transitions;

  Duration offsetAt(DateTime instant) {
    final utc = instant.toUtc();
    var result = initialOffset;
    for (final transition in transitions) {
      if (transition.at.isAfter(utc)) break;
      result = transition.offsetAfter;
    }
    return result;
  }

  @override
  LocalWallTime toWallTime(DateTime instant) {
    final wall = instant.toUtc().add(offsetAt(instant));
    return LocalWallTime(
      date: LocalDate(wall.year, wall.month, wall.day),
      time: LocalTime(wall.hour, wall.minute),
    );
  }

  @override
  List<DateTime> instantsFor(LocalWallTime wallTime) {
    final nominal = wallTime._nominalUtc;
    final offsets = <Duration>{
      initialOffset,
      ...transitions.map((transition) => transition.offsetAfter),
    };
    final matches = <DateTime>[];
    for (final offset in offsets) {
      final candidate = nominal.subtract(offset);
      if (toWallTime(candidate) == wallTime) matches.add(candidate);
    }
    matches.sort();
    if (matches.isNotEmpty) return matches;

    // Normalize a nonexistent spring-forward time by the gap, just as the
    // system DateTime constructor does.
    var offsetBefore = initialOffset;
    for (final transition in transitions) {
      final localBefore = transition.at.add(offsetBefore);
      final localAfter = transition.at.add(transition.offsetAfter);
      if (transition.offsetAfter > offsetBefore &&
          !nominal.isBefore(localBefore) &&
          nominal.isBefore(localAfter)) {
        return <DateTime>[nominal.subtract(offsetBefore)];
      }
      offsetBefore = transition.offsetAfter;
    }
    return const <DateTime>[];
  }
}

class SessionWindow {
  const SessionWindow({
    required this.session,
    required this.localStartDate,
    required this.startsAt,
    required this.endsAt,
    required this.timeZone,
  });

  final SessionName session;
  final LocalDate localStartDate;
  final DateTime startsAt;
  final DateTime endsAt;
  final CurreTimeZone timeZone;

  DateTime get nextBoundary => endsAt;

  bool contains(DateTime instant) {
    final utc = instant.toUtc();
    return !utc.isBefore(startsAt) && utc.isBefore(endsAt);
  }
}

class _Boundary {
  const _Boundary(this.session, this.localDate, this.instant);

  final SessionName session;
  final LocalDate localDate;
  final DateTime instant;
}

class SessionSchedule {
  SessionSchedule(
    Map<SessionName, LocalTime> starts, {
    this.timeZone = const SystemCurreTimeZone(),
  }) : starts = Map.unmodifiable(starts) {
    if (starts.length != SessionName.values.length ||
        !starts.keys.toSet().containsAll(SessionName.values)) {
      throw ArgumentError('A start time is required for every session');
    }
  }

  factory SessionSchedule.fromSettings(
    Settings settings, {
    CurreTimeZone timeZone = const SystemCurreTimeZone(),
  }) => SessionSchedule(settings.sessionStarts, timeZone: timeZone);

  final Map<SessionName, LocalTime> starts;
  final CurreTimeZone timeZone;

  SessionWindow current(DateTime instant) {
    final now = instant.toUtc();
    final localDate = timeZone.toWallTime(now).date;
    final boundaries = <_Boundary>[];
    for (var dayOffset = -2; dayOffset <= 2; dayOffset++) {
      final date = localDate.addDays(dayOffset);
      for (final session in SessionName.values) {
        final matches = timeZone.instantsFor(
          LocalWallTime(date: date, time: starts[session]!),
        );
        if (matches.isEmpty) continue;
        boundaries.add(_Boundary(session, date, matches.first.toUtc()));
      }
    }
    boundaries.sort((a, b) => a.instant.compareTo(b.instant));

    _Boundary? start;
    _Boundary? end;
    for (final boundary in boundaries) {
      if (!boundary.instant.isAfter(now)) {
        start = boundary;
      } else if (start != null) {
        end = boundary;
        break;
      }
    }
    if (start == null || end == null) {
      throw StateError('Could not resolve session boundaries around $now');
    }
    return SessionWindow(
      session: start.session,
      localStartDate: start.localDate,
      startsAt: start.instant,
      endsAt: end.instant,
      timeZone: timeZone,
    );
  }

  DateTime nextBoundary(DateTime instant) => current(instant).endsAt;
}
