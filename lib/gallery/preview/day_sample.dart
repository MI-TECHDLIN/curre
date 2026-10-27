import '../../core/models.dart';
import '../../core/progress.dart';
import '../../core/sessions.dart';
import '../../design/design.dart' show Session;
import 'plan_sample.dart';

/// The demo Saturday the previews share, as real core plans and door uses,
/// so the water on each check-in card is today's progress as core computes
/// it (`DayProgress`), not a level picked for the picture.
///
/// Chidi plans the morning at 05:13 (the G chord on YouTube, worship on
/// Spotify, till 7) and goes through both doors; at 12:05 plans the
/// afternoon (find the rehearsal studio on Maps and watch a Romans 8 video
/// on YouTube, till 3) and goes through one. Preview clocks read wall time as
/// UTC.
abstract final class SampleDay {
  static const _zone = FixedOffsetTimeZone(Duration.zero);
  static final schedule = SessionSchedule.fromSettings(
    Settings(),
    timeZone: _zone,
  );
  static const date = LocalDate(2026, 10, 24);

  static DateTime _at(int hour, int minute) =>
      DateTime.utc(2026, 10, 24, hour, minute);

  static final morning = Plan(
    id: 'sat-morning',
    session: SessionName.morning,
    date: date,
    intention: demoPlan.sentence,
    apps: const [
      PlannedApp(packageName: 'com.google.android.youtube', door: 'search'),
      PlannedApp(packageName: 'com.spotify.music', door: 'search'),
    ],
    endsAt: _at(7, 0),
    source: PlanSource.clocked,
  );

  static final afternoon = Plan(
    id: 'sat-afternoon',
    session: SessionName.afternoon,
    date: date,
    intention: 'Find the rehearsal studio on Google Maps and watch Romans 8 on YouTube till 3',
    apps: const [
      PlannedApp(packageName: 'com.google.android.apps.maps', door: 'search'),
      PlannedApp(packageName: 'com.google.android.youtube', door: 'search'),
    ],
    endsAt: _at(15, 0),
    source: PlanSource.clocked,
  );

  /// When each plan was made (core does not keep this; the sample does, to
  /// leave a plan out of the day before it existed).
  static final _made = {morning: _at(5, 13), afternoon: _at(12, 5)};

  static final uses = [
    DoorUse.forPlan(morning, 'com.google.android.youtube', _at(5, 14)),
    DoorUse.forPlan(morning, 'com.spotify.music', _at(6, 31)),
    DoorUse.forPlan(afternoon, 'com.google.android.apps.maps', _at(12, 40)),
  ];

  /// When each session's check-in opens in the previews.
  static DateTime checkinAt(Session session) => switch (session) {
    Session.morning => _at(5, 12),
    Session.afternoon => _at(12, 4),
    Session.evening => _at(17, 20),
  };

  /// "05:12": the status bar's time at [session]'s check-in.
  static String clock(Session session) {
    final t = checkinAt(session);
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// Today's progress at [now].
  static DayProgress at(DateTime now) => DayProgress.of(
    plans: [
      for (final plan in [morning, afternoon])
        if (!_made[plan]!.isAfter(now)) plan,
    ],
    uses: uses,
    schedule: schedule,
    now: now,
  );

  /// Today's progress when [session]'s check-in opens.
  static DayProgress atCheckin(Session session) => at(checkinAt(session));

  /// What the user last saw on the card: the previous check-in's level, so
  /// the water rises from there as the card appears.
  static double? lastSeen(Session session) => switch (session) {
    Session.morning => null,
    Session.afternoon => atCheckin(Session.morning).value,
    Session.evening => atCheckin(Session.afternoon).value,
  };
}
