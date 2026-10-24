import 'package:flutter/material.dart';

import '../../design/design.dart';
import 'day_sample.dart';
import 'parts.dart';

/// The sample user the previews greet. Not "Ada": in the demo Ada is the
/// friend waiting for a reply.
const previewName = 'Chidi';

/// A deliberately long name, for the detail pass at 360 dp.
const longPreviewName = 'Oluwadamilare Adeyemi-Okonkwo';

/// The week the previews share: Saturday 24 October 2026, four proof days
/// before it (Tuesday to Friday), Monday quiet, Sunday to come.
const previewWeek = <WeekDay>[
  WeekDay('Mon', 19, DayState.quiet),
  WeekDay('Tue', 20, DayState.proof),
  WeekDay('Wed', 21, DayState.proof),
  WeekDay('Thu', 22, DayState.proof),
  WeekDay('Fri', 23, DayState.proof),
  WeekDay('Sat', 24, DayState.today),
  WeekDay('Sun', 25, DayState.future),
];

/// A check-in at the start of a session: Home with no plan for the session
/// yet, so it holds only the prompt and the essentials (US1). It is laid
/// out zone for zone after the captain's primary reference, the Mombo
/// check-in (greeting, week strip, a labelled card with one question and a
/// sun character, one attached action, a bar at the foot), and every zone
/// does a Curre job:
///
/// * the greeting names the user ("Good morning, Chidi");
/// * the week strip carries the Prooflight streak (proof days ring ember);
/// * "See all" becomes the proof-day count, with today's sun;
/// * the sun over the hills becomes Peek on the session's own living sky,
///   and the ground below holds today's water, risen as far as today's
///   plans have run (core `DayProgress`);
/// * "Check-in →" becomes "Plan my morning" with the mic (spoken check-in);
/// * the tab bar becomes the essentials, pinned on the horizon, with the
///   single way down to the 23 apps out of sight.
///
/// The sample day ([SampleDay]) runs through all three sessions: nothing
/// yet at 05:12; at 12:04 the morning's two doors have filled a third of
/// the day and today's sun is up; at 17:20 the afternoon has added one
/// more door and a second ray. Mombo's "Quick Journal" cards are left out
/// on purpose: they return on Home as door cards. For the review only, not
/// the production screen.
class CheckinPreviewScreen extends StatelessWidget {
  const CheckinPreviewScreen({
    super.key,
    this.session = Session.morning,
    this.name = previewName,
    this.week = previewWeek,
    this.outOfSight = 23,
    this.animate = true,
  });

  final Session session;

  /// The user's display name; null shows the greeting alone.
  final String? name;
  final List<WeekDay> week;
  final int outOfSight;
  final bool animate;

  static String _part(Session s) => switch (s) {
    Session.morning => 'morning',
    Session.afternoon => 'afternoon',
    Session.evening => 'evening',
  };

  /// Proof days and today's rays at each check-in of the sample day: the
  /// G chord proved at 07:12 raised today's sun, and the reply to Ada added
  /// a second ray in the afternoon.
  static (int, int) proofAt(Session s) => switch (s) {
    Session.morning => (4, 0),
    Session.afternoon => (5, 1),
    Session.evening => (5, 2),
  };

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final part = _part(session);
    final day = SampleDay.atCheckin(session);
    final (proofDays, raysToday) = proofAt(session);
    return Column(
      children: [
        StatusBar(time: SampleDay.clock(session)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(CurreSpace.gutter, CurreSpace.s3, CurreSpace.gutter, CurreSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Greeting(
                  greeting: 'Good $part',
                  name: name,
                  subtitle: 'Saturday, 24 October',
                  trailing: const RoundGlyphButton(
                    glyph: CurreGlyphKind.curreSettings,
                    semanticLabel: 'Curre settings',
                  ),
                ),
                const SizedBox(height: CurreSpace.s6),
                // Once today has proof, today's day wears its ember ring.
                WeekStrip(days: week, session: session, todayLit: raysToday > 0 ? 1 : 0),
                const SizedBox(height: 28),
                SectionLabel(
                  title: '${part[0].toUpperCase()}${part.substring(1)} check-in',
                  trailing: ProofDaysLabel(days: proofDays, raysToday: raysToday),
                ),
                const SizedBox(height: CurreSpace.s3),
                CheckinCard(
                  session: session,
                  question: 'What’s this $part for?',
                  hint: 'One sentence. Only what you name comes into sight.',
                  progress: day.value,
                  progressFrom: SampleDay.lastSeen(session),
                  progressLabel: CheckinCard.waterLabel(day),
                  animate: animate,
                ),
                const SizedBox(height: CurreSpace.s3),
                PrimaryPill(
                  label: 'Plan my $part',
                  glyph: CurreGlyphKind.speak,
                  background: c.ember,
                  foreground: c.markInk,
                  glyphBackground: c.markInk,
                  glyphColor: const Color(0xFFFFFDF9),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CurreSpace.gutter),
          child: EssentialsDock(outOfSight: outOfSight),
        ),
        const GestureBar(),
      ],
    );
  }
}
