import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../design/design.dart';
import 'checkin_preview_screen.dart' show previewName;
import 'parts.dart';
import 'plan_sample.dart';

/// Home with a plan (design report 4.4), 05:31. Same greeting and the same
/// essentials dock as the session's check-in, so nothing that never moves
/// has moved. Mombo's big card is now the plan card: your sentence in the
/// session's sky, its destination words marked in link colours, and a
/// faceless sun on the card's horizon whose place between the start and
/// the end time shows how much of the plan has run (Home never animates:
/// it is simply drawn where the time is). Mombo's quick cards are the door
/// cards, each in the colour of the words that put it here. A granted app
/// joins them with its ember ring draining. No mascot. For the review
/// only.
class HomePreviewScreen extends StatelessWidget {
  const HomePreviewScreen({
    super.key,
    this.name = previewName,
    this.plan = demoPlan,
    this.showGrant = true,
    this.outOfSight = 23,
  });

  /// The user's display name; null shows the greeting alone.
  final String? name;
  final PlanSample plan;
  final bool showGrant;
  final int outOfSight;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final open = c.outcome(Outcome.open, laterTarget: Session.evening);
    return Column(
      children: [
        const StatusBar(time: '05:31'),
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
                PlanCard(plan: plan),
                const SizedBox(height: 28),
                SectionLabel(
                  title: 'On Home',
                  trailing: Text('Tap opens the task', style: t.caption.copyWith(color: c.ink3)),
                ),
                const SizedBox(height: CurreSpace.s3),
                for (final (i, door) in plan.doors.indexed) ...[
                  if (i > 0) const SizedBox(height: CurreSpace.s2),
                  _door(context, door, i + 1),
                ],
                if (showGrant) ...[
                  const SizedBox(height: CurreSpace.s2),
                  DoorRow(
                    appName: 'Instagram',
                    destination: '→\u00A0Open app',
                    appIcon: const AppIconStandIn(icon: SolarIconsBold.chatRoundLine, ring: .64),
                    tint: open,
                    trailing: _TimeLeft(text: '3:12', color: open.fg),
                    semanticLabel: 'Instagram, opens the app, 3 minutes 12 seconds left',
                  ),
                ],
                const SizedBox(height: CurreSpace.s3),
                Text(
                  'Long-press any door to open the app normally.',
                  style: t.caption.copyWith(color: c.ink3),
                  textAlign: TextAlign.center,
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

  Widget _door(BuildContext context, DoorSample door, int link) {
    final t = Theme.of(context).extension<CurreType>()!;
    final c = Theme.of(context).extension<CurreColors>()!;
    final destination = '→\u00A0${door.destination} “${door.words}”';
    final (s, e) = spanOf(destination, '“${door.words}”');
    return DoorRow(
      appName: door.app,
      destination: destination,
      destinationHighlights: [
        SpanHighlight(s, e, style: t.youSmall.copyWith(fontSize: 16, color: c.link(link).card.fg)),
      ],
      appIcon: AppIconStandIn(icon: door.icon),
      link: link,
      semanticLabel: '${door.app}, opens ${door.destination} for ${door.words}',
    );
  }
}

/// The plan card: Mombo's big warm card, answered.
class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan, this.session = Session.morning});

  final PlanSample plan;
  final Session session;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final sky = c.sky(session);
    // A long plan steps down one size so its doors stay in view.
    final style = (plan.sentence.length > 110 ? t.youSmall : t.you).copyWith(color: sky.fg);
    final timeStyle = t.figure.copyWith(fontSize: 12, height: 16 / 12, color: sky.fg.withValues(alpha: .86));
    return ClipRRect(
      borderRadius: CurreShape.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: sky.bg,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(CurreSpace.gutter, CurreSpace.s4, CurreSpace.s3, CurreSpace.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CurreGlyph(CurreGlyphKind.sessionMorning, size: 20, color: sky.fg),
                      const SizedBox(width: CurreSpace.s2),
                      Expanded(
                        child: Text('Your morning', style: t.label.weight(660).copyWith(color: sky.fg)),
                      ),
                      RoundGlyphButton(
                        glyph: CurreGlyphKind.editSpecify,
                        semanticLabel: 'Change this plan',
                        background: sky.fg.withValues(alpha: .1),
                        foreground: sky.fg,
                        outlined: false,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: CurreSpace.s2),
                    child: SpanText(
                      plan.sentence,
                      style: style,
                      highlights: [
                        for (final (i, door) in plan.doors.indexed)
                          linkHighlight(context, plan.sentence, door.words, i + 1, style),
                        timeHighlight(context, plan.sentence, plan.endPhrase, style),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: SkyScene(
              session: session,
              sun: SkySun.disc,
              horizon: .46,
              sunAt: .06 + plan.progress * .88,
              sunSize: 22,
              sunRise: .62,
              borderRadius: BorderRadius.zero,
              padding: const EdgeInsets.fromLTRB(CurreSpace.gutter, 0, CurreSpace.gutter, 6),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  children: [
                    Text(plan.startedAt, style: timeStyle),
                    const Spacer(),
                    Text('ends ${plan.endsAt}', style: timeStyle),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeLeft extends StatelessWidget {
  const _TimeLeft({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<CurreType>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CurreGlyph(CurreGlyphKind.overrideWait, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: t.figure.copyWith(color: color)),
      ],
    );
  }
}
