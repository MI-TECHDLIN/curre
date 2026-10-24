import 'package:flutter/material.dart';

import '../../design/design.dart';
import 'checkin_preview_screen.dart';
import 'parts.dart';
import 'plan_sample.dart';

/// The one streak moment the captain asked for (2026-10-24): the screen
/// that greets you when a morning's plan was kept. Curre now keeps a
/// streak for plans with real proof they were done; the counting rules
/// come from a separate audit and are not invented here, so this shows
/// the feeling only.
///
/// It borrows Duolingo's mechanics of delight, beat by beat, and re-grows
/// each one from Curre's own world:
///
/// | Duolingo (the two recordings)           | Curre                                                  |
/// | --------------------------------------- | ------------------------------------------------------ |
/// | grey, dormant flame and grey "29"       | a grey sun asleep on the horizon, eyes shut, no rays   |
/// | the flame squashes, fills orange        | the sun rises and takes its ember as it clears the line |
/// | 0.1 s full-screen orange flood          | the morning sky floods up from the horizon in 650 ms   |
/// | the owl pops in with particles          | Peek's own rays pop out one by one, then its eyes open |
/// | "29" ticks to "30"                      | "4" rolls to "5" days in a row                         |
/// | XP chips stagger in                     | the doors you actually went through stagger in         |
/// | the week's check marks                  | today's day in the week strip lights ember             |
///
/// No flame, no owl, no Duolingo green, nothing about a lost streak: a
/// missed day is simply never celebrated. Reduced motion shows the end
/// state. [progress] (0–1) freezes the moment at one point for renders
/// and tests; otherwise it plays and, with [loop], replays after a rest.
class StreakMomentScreen extends StatefulWidget {
  const StreakMomentScreen({super.key, this.progress, this.loop = true, this.from = 4, this.plan = demoPlan});

  final double? progress;
  final bool loop;
  final int from;
  final PlanSample plan;

  /// The moment's own length; [loop] adds [rest] after it.
  static const length = Duration(milliseconds: 3600);
  static const rest = Duration(milliseconds: 1600);

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

    // Enter: the sleeping sun rises and lights up.
    final rise = _beat(ms, 300, 720, CurreMotion.riseCurve);
    final lit = _beat(ms, 300, 820);
    // The sky floods up from the line (the sky token, 650 ms).
    final flood = _beat(ms, 520, 1170, CurreMotion.standard);
    // Peek wakes: rays pop out, then the eyes open.
    final rays = _beat(ms, 820, 1180);
    final eyes = _beat(ms, 1060, 1260, Curves.easeOut);
    // Hold, then settle: the count rolls, today lights, proof arrives.
    final words = _beat(ms, 700, 1100);
    final tick = _beat(ms, 1300, 1460, Curves.easeOutCubic);
    final today = _beat(ms, 1380, 1740);
    final cta = _beat(ms, 2100, 2400);

    final week = [for (final d in previewWeek) d];

    return Column(
      children: [
        const StatusBar(time: '07:00'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(CurreSpace.gutter, CurreSpace.s3, CurreSpace.gutter, CurreSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Opacity(
                  opacity: words,
                  child: Text('Morning kept', style: t.headline),
                ),
                const SizedBox(height: CurreSpace.s1),
                Opacity(
                  opacity: words,
                  child: Text(
                    'Your plan ended at ${widget.plan.endsAt}, and you went through both doors.',
                    style: t.body.copyWith(color: c.ink2),
                  ),
                ),
                const SizedBox(height: CurreSpace.s5),
                SizedBox(
                  height: 232,
                  child: SkyScene(
                    session: Session.morning,
                    horizon: .78,
                    sunAt: .5,
                    sunSize: 132,
                    sunRise: .16 + rise * .62,
                    flood: flood,
                    lit: lit,
                    rays: rays,
                    eyesOpen: eyes,
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
                          .copyWith(fontSize: 60, height: 1, color: Color.lerp(c.ink3, c.ink, lit))
                          .weight(760),
                    ),
                    const SizedBox(width: CurreSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('days in a row', style: t.title.copyWith(fontSize: 20, height: 26 / 20)),
                          Text('Tuesday to Saturday', style: t.caption.copyWith(color: c.ink3)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CurreSpace.s4),
                WeekStrip(days: week, todayLit: today),
                const SizedBox(height: CurreSpace.s5),
                for (final (i, door) in widget.plan.doors.indexed) ...[
                  if (i > 0) const SizedBox(height: CurreSpace.s2),
                  _arrive(
                    _beat(ms, 1640 + i * 120.0, 2000 + i * 120.0, CurreMotion.riseCurve),
                    _ProofChip(door: door, link: i + 1),
                  ),
                ],
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
    return Semantics(
      label: '${t >= .5 ? to : from} days in a row',
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

/// One door the plan actually used: the proof, in its link colour.
class _ProofChip extends StatelessWidget {
  const _ProofChip({required this.door, required this.link});

  final DoorSample door;
  final int link;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final card = c.link(link).card;
    final text = '${door.app}\u00A0→\u00A0${door.destination} “${door.words}”';
    final (s, e) = spanOf(text, '“${door.words}”');
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.fromLTRB(CurreSpace.s3, CurreSpace.s2, CurreSpace.s4, CurreSpace.s2),
      decoration: BoxDecoration(color: card.bg, borderRadius: CurreShape.md),
      child: Row(
        children: [
          CurreGlyph(CurreGlyphKind.check, size: 24, color: card.fg, semanticLabel: 'Used'),
          const SizedBox(width: CurreSpace.s3),
          Expanded(
            child: SpanText(
              text,
              style: t.label.copyWith(color: card.fg),
              highlights: [SpanHighlight(s, e, style: t.youSmall.copyWith(color: card.fg))],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
