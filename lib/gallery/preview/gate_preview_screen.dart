import 'package:flutter/material.dart';

import '../../design/design.dart';
import 'parts.dart';

/// The unlock gate, judged "open" for a person (design report 4.6; demo
/// beat 1:15). It keeps the check-in's language (one big question, one
/// card, one action) on the sunk surface below the line, and stays serious:
/// no Peek, no sky, no celebration. The reason card shows what Clocked
/// read ("Ada" is the link to the door, "rehearsal" what the grant is
/// for), the kind chip shows the verdict with its confidence, the outcome
/// card says where the tap lands, and the one action names that place.
/// For the review only.
class GatePreviewScreen extends StatelessWidget {
  const GatePreviewScreen({
    super.key,
    this.app = 'Instagram',
    this.reason = 'reply Ada about rehearsal',
  });

  final String app;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final style = t.youLarge;
    final (rs, re) = spanOf(reason, 'rehearsal');

    return ColoredBox(
      color: c.sunk,
      child: Column(
        children: [
          const StatusBar(time: '05:40'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                CurreSpace.gutter,
                CurreSpace.s2,
                CurreSpace.gutter,
                CurreSpace.s4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _GateTopBar(),
                  const SizedBox(height: CurreSpace.s5),
                  Text('Why open $app now?', style: t.headline),
                  const SizedBox(height: CurreSpace.s4),
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      CurreSpace.s4,
                      CurreSpace.s3,
                      CurreSpace.s4,
                      CurreSpace.s4,
                    ),
                    decoration: BoxDecoration(
                      color: c.raised,
                      borderRadius: CurreShape.md,
                      border: Border.all(color: c.hairline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your reason', style: t.meta),
                        const SizedBox(height: CurreSpace.s1),
                        SpanText(
                          reason,
                          style: style,
                          highlights: [
                            linkHighlight(context, reason, 'Ada', 1, style),
                            SpanHighlight(
                              rs,
                              re,
                              style: style.copyWith(
                                backgroundColor: c.marker,
                                color: c.markInk,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: CurreSpace.s2),
                        Text(
                          'Ada\u00A0→ matched a chat on this phone',
                          style: t.caption.copyWith(color: c.ink3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: CurreSpace.s4),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: KindChip(kind: ReasonKind.person, confidence: .94),
                  ),
                  const SizedBox(height: CurreSpace.s3),
                  OutcomeCard(
                    outcome: Outcome.open,
                    headline: 'Opens at $app\u00A0→\u00A0Messages',
                    body: 'Your chat with Ada · 5 minutes',
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CurreSpace.gutter,
              0,
              CurreSpace.gutter,
              CurreSpace.s2,
            ),
            child: Column(
              children: [
                PrimaryPill(
                  label: 'Open $app\u00A0→\u00A0Messages',
                  glyph: CurreGlyphKind.door,
                ),
                const SizedBox(height: CurreSpace.s2),
                Text(
                  '5 minutes · long-press opens $app normally',
                  style: t.caption.copyWith(color: c.ink3),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const GestureBar(),
        ],
      ),
    );
  }
}

class _GateTopBar extends StatelessWidget {
  const _GateTopBar();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    return Row(
      children: [
        const RoundGlyphButton(
          glyph: CurreGlyphKind.back,
          semanticLabel: 'Back to the list',
        ),
        const SizedBox(width: CurreSpace.s3),
        CurreGlyph(CurreGlyphKind.outOfSight, size: 20, color: c.ink2),
        const SizedBox(width: CurreSpace.s2),
        Text('Hidden apps', style: t.label.copyWith(color: c.ink2)),
      ],
    );
  }
}

/// The 30-second wait (design report 4.6, now "Open after 30 seconds"), after a
/// browsing reason was told "not now". The learning plan's big numeral,
/// mono so it never jitters, and the sun rising linearly over the session's
/// horizon: time is the only thing that moves, and it is never eased. Still
/// no mascot. For the review only.
class WaitPreviewScreen extends StatelessWidget {
  const WaitPreviewScreen({super.key, this.app = 'Instagram'});

  final String app;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final sky = c.sky(Session.morning);
    const reason = 'just checking what Tolu posted';

    return ColoredBox(
      color: c.sunk,
      child: Column(
        children: [
          const StatusBar(time: '05:44'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                CurreSpace.gutter,
                CurreSpace.s2,
                CurreSpace.gutter,
                CurreSpace.s4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _GateTopBar(),
                  const SizedBox(height: CurreSpace.s5),
                  Text('$app opens in', style: t.title),
                  countdownText('0:17', t.figureXL),
                  const SizedBox(height: CurreSpace.s3),
                  ClipRRect(
                    borderRadius: CurreShape.lg,
                    child: ColoredBox(
                      color: sky.bg,
                      child: Padding(
                        padding: const EdgeInsets.only(top: CurreSpace.s6),
                        child: LayoutBuilder(
                          builder: (context, box) => RisingDisc(
                            diameter: 72,
                            width: box.maxWidth,
                            lineColor: sky.fg,
                            groundColor: c.ground(Session.morning),
                            initialProgress: 13 / 30,
                            semanticLabel: '$app opens in 17 seconds',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: CurreSpace.s4),
                  Container(
                    padding: const EdgeInsets.all(CurreSpace.s4),
                    decoration: BoxDecoration(
                      color: c.raised,
                      borderRadius: CurreShape.md,
                      border: Border.all(color: c.hairline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your reason', style: t.meta),
                        const SizedBox(height: CurreSpace.s1),
                        Text(reason, style: t.you),
                        const SizedBox(height: CurreSpace.s3),
                        const KindChip(
                          kind: ReasonKind.browse,
                          confidence: .81,
                        ),
                        const SizedBox(height: CurreSpace.s3),
                        Text(
                          'Sounds like browsing, so it can wait for a browsing time. You chose to wait, and that’s allowed.',
                          style: t.body.copyWith(
                            color: c.ink2,
                            fontSize: 15,
                            height: 22 / 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CurreSpace.gutter,
              0,
              CurreSpace.gutter,
              CurreSpace.s2,
            ),
            child: Column(
              children: [
                Text(
                  'Leaving this screen cancels the wait. It will be logged as an override.',
                  style: t.caption.copyWith(color: c.ink3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: CurreSpace.s3),
                const SecondaryPill(label: 'Cancel'),
              ],
            ),
          ),
          const GestureBar(),
        ],
      ),
    );
  }
}
