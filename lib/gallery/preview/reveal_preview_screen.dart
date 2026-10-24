import 'package:flutter/material.dart';

import '../../design/design.dart';
import 'parts.dart';
import 'plan_sample.dart';
import 'staggered_reveal.dart';

/// The check-in's reveal (design report 4.3, step 3): the morning sky has
/// filled the screen from the horizon, the sentence comes back with what
/// Clocked read in it (destination words marked in their link colours and
/// numbered, the end time underlined in ember), and each marked phrase's
/// door rises above the line wearing the same colour and number. Below
/// the line, everything else stays out of sight. Peek watches from the
/// horizon. For the review only.
class RevealPreviewScreen extends StatelessWidget {
  const RevealPreviewScreen({super.key, this.plan = demoPlan, this.outOfSight = 23});

  final PlanSample plan;
  final int outOfSight;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final sky = c.sky(Session.morning);
    // A long plan steps down one size so its doors stay in view.
    final sentenceStyle = (plan.sentence.length > 110 ? t.you : t.youLarge).copyWith(color: sky.fg);

    return ColoredBox(
      color: c.ground(Session.morning),
      child: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: sky.bg,
              child: Column(
                children: [
                  StatusBar(time: '05:13', color: sky.fg),
                  Expanded(
                    // The doors sit right on the line, as if they had just
                    // risen over it; a long plan scrolls instead.
                    child: LayoutBuilder(
                      builder: (context, box) => SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          CurreSpace.gutter,
                          CurreSpace.s2,
                          CurreSpace.gutter,
                          CurreSpace.s4,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: box.maxHeight - CurreSpace.s2 - CurreSpace.s4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      RoundGlyphButton(
                                        glyph: CurreGlyphKind.back,
                                        semanticLabel: 'Back to the question',
                                        background: sky.fg.withValues(alpha: .1),
                                        foreground: sky.fg,
                                        outlined: false,
                                      ),
                                      const SizedBox(width: CurreSpace.s3),
                                      const Flexible(
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: MetaPill(text: 'Fill + Extract · 1.4 s'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: CurreSpace.s5),
                                  Text(
                                    'Your morning',
                                    style: t.caption.copyWith(color: sky.fg.withValues(alpha: .8)).weight(600),
                                  ),
                                  const SizedBox(height: CurreSpace.s2),
                                  SpanText(
                                    plan.sentence,
                                    style: sentenceStyle,
                                    highlights: [
                                      for (final (i, door) in plan.doors.indexed)
                                        linkHighlight(context, plan.sentence, door.words, i + 1, sentenceStyle),
                                      timeHighlight(context, plan.sentence, plan.endPhrase, sentenceStyle),
                                    ],
                                  ),
                                  const SizedBox(height: CurreSpace.s3),
                                  MetaPill(text: 'ends ${plan.endsAt}', glyph: CurreGlyphKind.sessionMorning),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: CurreSpace.s5),
                                child: Column(
                                  children: [
                                    for (final (i, door) in plan.doors.indexed) ...[
                                      if (i > 0) const SizedBox(height: CurreSpace.s2),
                                      StaggeredReveal(index: i, child: _door(context, door, i + 1)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // The horizon, with Peek peeking over it; the ground below.
          const SizedBox(
            height: 64,
            child: SkyScene(
              session: Session.morning,
              horizon: .78,
              sunAt: .82,
              sunSize: 72,
              sunRise: .7,
              borderRadius: BorderRadius.zero,
              padding: EdgeInsets.zero,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(CurreSpace.gutter, CurreSpace.s2, CurreSpace.gutter, CurreSpace.s4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CurreGlyph(CurreGlyphKind.outOfSight, size: 20, color: sky.fg),
                    const SizedBox(width: CurreSpace.s2),
                    Flexible(
                      child: Text(
                        'The other $outOfSight stay out of sight',
                        style: t.body.copyWith(color: sky.fg).weight(560),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CurreSpace.s4),
                Row(
                  children: [
                    SizedBox(
                      width: 104,
                      child: SecondaryPill(label: 'Edit', color: sky.fg),
                    ),
                    const SizedBox(width: CurreSpace.s3),
                    const Expanded(
                      child: PrimaryPill(label: 'Set my morning', glyph: CurreGlyphKind.check),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureBar(color: sky.fg),
        ],
      ),
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
