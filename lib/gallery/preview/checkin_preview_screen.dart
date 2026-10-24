import 'package:flutter/material.dart';

import '../../design/design.dart';
import 'parts.dart';

/// The sample user the previews greet. Not "Ada": in the demo Ada is the
/// friend waiting for a reply.
const previewName = 'Chidi';

/// A deliberately long name, for the detail pass at 360 dp.
const longPreviewName = 'Oluwadamilare Adeyemi-Okonkwo';

/// The week the previews share: Saturday 24 October 2026, four mornings
/// kept before it (Tuesday to Friday), Monday quiet, Sunday to come.
const previewWeek = <WeekDay>[
  WeekDay('Mon', 19, DayState.quiet),
  WeekDay('Tue', 20, DayState.kept),
  WeekDay('Wed', 21, DayState.kept),
  WeekDay('Thu', 22, DayState.kept),
  WeekDay('Fri', 23, DayState.kept),
  WeekDay('Sat', 24, DayState.today),
  WeekDay('Sun', 25, DayState.future),
];

/// The morning check-in at the start of a session: Home at 05:12 with no
/// plan yet, so it holds only the prompt and the essentials (US1). It is
/// laid out zone for zone after the captain's primary reference, the Mombo
/// check-in (greeting, week strip, a labelled card with one question and a
/// sun character, one attached action, a bar at the foot), and every zone
/// does a Curre job:
///
/// * the week strip carries the streak (kept mornings are lit ember);
/// * "See all" becomes the streak count;
/// * the sun over the hills becomes Peek on Curre's horizon;
/// * "Check-in →" becomes "Plan my morning" with the mic (spoken check-in);
/// * the tab bar becomes the essentials, pinned on the horizon, with the
///   single way down to the 23 apps out of sight.
///
/// Mombo's "Quick Journal" cards are left out on purpose: a session starts
/// with only a prompt and the essentials. They return on Home as door
/// cards. For the review only, not the production screen.
class CheckinPreviewScreen extends StatelessWidget {
  const CheckinPreviewScreen({
    super.key,
    this.name = previewName,
    this.week = previewWeek,
    this.streak = 4,
    this.outOfSight = 23,
  });

  /// The user's display name; null shows the greeting alone.
  final String? name;
  final List<WeekDay> week;
  final int streak;
  final int outOfSight;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    return Column(
      children: [
        const StatusBar(time: '05:12'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(CurreSpace.gutter, CurreSpace.s3, CurreSpace.gutter, CurreSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Greeting(
                  greeting: 'Good morning',
                  name: name,
                  subtitle: 'Saturday, 24 October',
                  trailing: const RoundGlyphButton(
                    glyph: CurreGlyphKind.curreSettings,
                    semanticLabel: 'Curre settings',
                  ),
                ),
                const SizedBox(height: CurreSpace.s6),
                WeekStrip(days: week),
                const SizedBox(height: 28),
                SectionLabel(
                  title: 'Morning check-in',
                  trailing: StreakCount(days: streak),
                ),
                const SizedBox(height: CurreSpace.s3),
                const CheckinCard(
                  session: Session.morning,
                  question: 'What’s this morning for?',
                  hint: 'One sentence. Only what you name comes into sight.',
                ),
                const SizedBox(height: CurreSpace.s3),
                PrimaryPill(
                  label: 'Plan my morning',
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
