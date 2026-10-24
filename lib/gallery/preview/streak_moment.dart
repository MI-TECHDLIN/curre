import 'package:flutter/material.dart';

import '../../design/design.dart';
import 'checkin_preview_screen.dart';
import 'parts.dart';
import 'plan_sample.dart';

/// The Prooflight moment (proof audit §4): the first task of the Curre day
/// with real proof raises today's sun and adds a proof day. Here Chidi is
/// back from YouTube and said what changed; the note was specific, so it
/// counts. The rules that decide that live elsewhere: this shows the
/// moment only.
///
/// It borrows Duolingo's mechanics of delight, beat by beat, and re-grows
/// each one from Curre's own world:
///
/// | Duolingo (the two recordings)           | Curre                                                   |
/// | --------------------------------------- | ------------------------------------------------------- |
/// | grey, dormant flame and grey "29"       | today's sun, grey, still below the horizon              |
/// | the flame squashes, fills orange        | the sun rises over the line and takes its ember, 650 ms |
/// | 0.1 s full-screen orange flood          | the morning sky floods up from the horizon in 650 ms    |
/// | the owl pops in with particles          | the sun's first ray grows in: one ray per proved task   |
/// | "29" ticks to "30"                      | "4" rolls to "5" proof days                             |
/// | XP chips stagger in                     | the proof arrives: the door, then the user's own words  |
/// | the week's check marks                  | today's day in the week strip rings ember               |
///
/// No flame, no owl, no Duolingo green, and no face on the sun: Peek never
/// judges the evidence. Reduced motion shows the end state. [progress]
/// (0–1) freezes the moment at one point for renders and tests; otherwise
/// it plays and, with [loop], replays after a rest.
class StreakMomentScreen extends StatefulWidget {
  const StreakMomentScreen({super.key, this.progress, this.loop = true, this.from = 4, this.plan = demoPlan});

  final double? progress;
  final bool loop;
  final int from;
  final PlanSample plan;

  /// The moment's own length; [loop] adds [rest] after it.
  static const length = Duration(milliseconds: 3600);
  static const rest = Duration(milliseconds: 1600);

  /// The proof caption Extract copied from the completion note.
  static const note = 'switched from G to C without looking';

  @override
  State<StreakMomentScreen> createState() => _StreakMomentScreenState();
}

class _StreakMomentScreenState extends State<StreakMomentScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.loop ? StreakMomentScreen.length + StreakMomentScreen.rest : StreakMomentScreen.length,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || widget.progress != null) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (widget.loop) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 0–1 progress of a beat running from [startMs] to [endMs].
  static double _beat(double ms, double startMs, double endMs, [Curve curve = Curves.linear]) {
    if (ms <= startMs) return 0;
    if (ms >= endMs) return 1;
    return curve.transform((ms - startMs) / (endMs - startMs));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final total = _controller.duration!.inMilliseconds.toDouble();
        final double ms = widget.progress != null
            ? widget.progress!.clamp(0.0, 1.0) * StreakMomentScreen.length.inMilliseconds
            : (_controller.value * total).clamp(0.0, StreakMomentScreen.length.inMilliseconds.toDouble());
        return _frame(context, ms);
      },
    );
  }

  Widget _frame(BuildContext context, double ms) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;

    // Enter: today's sun rises over the line (the audit's 650 ms).
    final rise = _beat(ms, 300, 950, CurreMotion.riseCurve);
    // The sky floods up from the line (the sky token, 650 ms).
    final flood = _beat(ms, 520, 1170, CurreMotion.standard);
    // The first ray grows in (the rise token, 420 ms).
    final ray = _beat(ms, 950, 1370);
    // Hold, then settle: the count rolls, today lights, the proof arrives.
    final words = _beat(ms, 700, 1100);
    final tick = _beat(ms, 1300, 1460, Curves.easeOutCubic);
    final today = _beat(ms, 1380, 1740);
    final cta = _beat(ms, 2100, 2400);
    final door = widget.plan.doors.first;

    return Column(
      children: [
        const StatusBar(time: '07:12'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(CurreSpace.gutter, CurreSpace.s3, CurreSpace.gutter, CurreSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Opacity(
                  opacity: words,
                  child: Text('Today’s sun is up', style: t.headline),
                ),
                const SizedBox(height: CurreSpace.s1),
                Opacity(
                  opacity: words,
                  child: Text('Your note on the ${door.words} counts as proof.', style: t.body.copyWith(color: c.ink2)),
                ),
                const SizedBox(height: CurreSpace.s5),
                SizedBox(
                  height: 232,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final lineY = (232 * .78).roundToDouble();
                      const sunSize = 196.0;
                      final sunHeight = ProoflightSun.heightFor(sunSize);
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: SkyScene(
                              session: Session.morning,
                              sun: SkySun.none,
                              horizon: .78,
                              live: true,
                              flood: flood,
                            ),
                          ),
                          // The sun sits on the scene's own line.
                          Positioned(
                            left: (box.maxWidth - sunSize) / 2,
                            top: lineY - sunHeight + 1.5,
                            child: ProoflightSun(
                              rays: 1,
                              proofDays: widget.from + 1,
                              size: sunSize,
                              rise: rise,
                              grow: ray,
                              semanticLabel: 'Today’s sun, one ray: one task with proof',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: CurreSpace.s5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _RollingCount(
                      from: widget.from,
                      to: widget.from + 1,
                      t: tick,
                      style: t.display
                          .copyWith(fontSize: 60, height: 1, color: Color.lerp(c.ink3, c.ink, rise))
                          .weight(760),
                    ),
                    const SizedBox(width: CurreSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('proof days', style: t.title.copyWith(fontSize: 20, height: 26 / 20)),
                          Text('Tuesday to Saturday', style: t.caption.copyWith(color: c.ink3)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CurreSpace.s4),
                WeekStrip(days: previewWeek, todayLit: today),
                const SizedBox(height: CurreSpace.s5),
                _arrive(
                  _beat(ms, 1640, 2000, CurreMotion.riseCurve),
                  _ProofCard(door: door, link: 1, note: StreakMomentScreen.note),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(CurreSpace.gutter, 0, CurreSpace.gutter, CurreSpace.s2),
          child: Opacity(
            opacity: cta,
            child: const PrimaryPill(label: 'Continue'),
          ),
        ),
        const GestureBar(),
      ],
    );
  }

  Widget _arrive(double p, Widget child) => Opacity(
    opacity: p.clamp(0, 1),
    child: Transform.translate(offset: Offset(0, (1 - p) * 14), child: child),
  );
}

/// A count that rolls from [from] to [to] (the `tick` token: a short
/// decelerating roll).
class _RollingCount extends StatelessWidget {
  const _RollingCount({required this.from, required this.to, required this.t, required this.style});

  final int from;
  final int to;
  final double t;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final h = (style.fontSize ?? 60) * 1.1;
    final shown = t >= .5 ? to : from;
    return Semantics(
      label: ProofDaysLabel.text(shown),
      excludeSemantics: true,
      child: ClipRect(
        child: SizedBox(
          height: h,
          child: Stack(
            children: [
              Transform.translate(
                offset: Offset(0, -t * h),
                child: Text('$from', style: style),
              ),
              Transform.translate(
                offset: Offset(0, (1 - t) * h),
                child: Text('$to', style: style),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The proof: the door the task went through, in its link colour, and the
/// user's own words about what changed, as Extract copied them.
class _ProofCard extends StatelessWidget {
  const _ProofCard({required this.door, required this.link, required this.note});

  final DoorSample door;
  final int link;
  final String note;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final card = c.link(link).card;
    final text = '${door.app} → ${door.destination} “${door.words}”';
    final (s, e) = spanOf(text, '“${door.words}”');
    return Container(
      padding: const EdgeInsets.fromLTRB(CurreSpace.s3, CurreSpace.s3, CurreSpace.s4, CurreSpace.s3),
      decoration: BoxDecoration(color: card.bg, borderRadius: CurreShape.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurreGlyph(CurreGlyphKind.check, size: 24, color: card.fg, semanticLabel: 'Proved'),
          const SizedBox(width: CurreSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SpanText(
                  text,
                  style: t.label.copyWith(color: card.fg),
                  highlights: [SpanHighlight(s, e, style: t.youSmall.copyWith(color: card.fg))],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: CurreSpace.s1),
                Text(
                  '“$note”',
                  style: t.you.copyWith(fontSize: 18, height: 24 / 18, color: card.fg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
