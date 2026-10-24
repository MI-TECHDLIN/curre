import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../curre_colors.dart';
import '../curre_tokens.dart';
import '../curre_type.dart';

// Prooflight, the proof-backed streak's look (proof audit §3–4). These
// widgets draw what they are given and decide nothing: the streak's rules
// (what counts as proof, when a cloud day is earned, when a run ends) live
// elsewhere and are not built here.

/// Today's half-sun on the horizon, with one long ray for each task proved
/// today. The first proof raises it over the line with a crown of short
/// rays and grows the middle one long; each later proof grows the next one,
/// left and right in turn, and past five proofs the fan widens. Milestones
/// add a ray pattern, never louder confetti: from 7 proof days every long
/// ray ends in a spark, from 21 a ring of light stands behind the sun, from
/// 50 a second one.
///
/// It has no face: Peek never judges the evidence (audit §4). On Home it is
/// small and still; at the moment of completion a screen drives [rise] and
/// [grow] to play the 650 ms sunrise and the new ray.
///
/// [rays] is how many tasks have proof today (the drawing stops adding rays
/// at [maxRays]; the label carries the count). Below 48 dp the sun is a
/// sign rather than a count: once risen it wears its five short rays only. [proofDays] is the run so
/// far, for the milestone pattern. [rise] (0–1) is how far the sun has come
/// up, by default up when there is a proof and still below the line when
/// not. [grow] (0–1) is how far the newest proof's ray has grown long. [lineColor] draws
/// the horizon under it, or null for none (on a scene that has its own).
class ProoflightSun extends StatelessWidget {
  const ProoflightSun({
    super.key,
    required this.rays,
    this.proofDays = 0,
    this.size = 96,
    this.rise,
    this.grow = 1,
    this.lineColor,
    this.semanticLabel,
  });

  final int rays;
  final int proofDays;
  final double size;
  final double? rise;
  final double grow;
  final Color? lineColor;
  final String? semanticLabel;

  static const maxRays = 12;

  /// Height of the widget for [size]: the half-sun, its rays and the line.
  static double heightFor(double size) => (size * .56).roundToDouble();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      excludeSemantics: true,
      child: CustomPaint(
        size: Size(size, heightFor(size)),
        painter: _ProoflightPainter(
          rays: rays.clamp(0, maxRays),
          proofDays: proofDays,
          rise: (rise ?? (rays > 0 ? 1.0 : 0.0)).clamp(0.0, 1.0),
          grow: grow.clamp(0.0, 1.0),
          ember: c.ember,
          dormant: Color.lerp(c.outcomes[Outcome.unavailable]!.bg, c.outcomes[Outcome.unavailable]!.fg, .42)!,
          lineColor: lineColor,
        ),
      ),
    );
  }
}

class _ProoflightPainter extends CustomPainter {
  _ProoflightPainter({
    required this.rays,
    required this.proofDays,
    required this.rise,
    required this.grow,
    required this.ember,
    required this.dormant,
    required this.lineColor,
  });

  final int rays;
  final int proofDays;
  final double rise;
  final double grow;
  final Color ember;
  final Color dormant;
  final Color? lineColor;

  /// Ray angles in degrees from the right (90 is straight up) for a sun
  /// with [n] proofs: five rays at least, spread across 140°, and one for
  /// each proof past five, spread across 150°.
  static List<double> slots(int n) {
    final count = math.max(5, n);
    final spread = count == 5 ? 140.0 : 150.0;
    return [for (var i = 0; i < count; i++) 90 + spread / 2 - spread * i / (count - 1)];
  }

  /// The order proofs take the slots in: the centre first, then left and
  /// right of it in turn, so a new proof never moves a ray already there.
  static List<int> order(int count) {
    final mid = (count - 1) ~/ 2;
    final result = [mid];
    for (var k = 1; result.length < count; k++) {
      if (mid - k >= 0) result.add(mid - k);
      if (result.length < count && mid + k < count) result.add(mid + k);
    }
    return result;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final lineY = size.height - 1.5;
    final small = w < 48;
    // A small sun is a little bigger for its box. Before it rises a sun
    // still shows the top of its disc, so it reads as a sun below the line.
    final r = w * (small ? .3 : .25);
    final center = Offset(w / 2, lineY + r * (small ? .58 : .64) * (1 - rise));

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, w, lineY));

    final lit = Color.lerp(dormant, ember, Curves.easeIn.transform(rise))!;
    if (proofDays >= 50) {
      canvas.drawCircle(center, r * 1.98, Paint()..color = ember.withValues(alpha: .14 * rise));
    }
    if (proofDays >= 21) canvas.drawCircle(center, r * 1.62, Paint()..color = ember.withValues(alpha: .28 * rise));

    // Short rays say the sun is up; each proof grows one of them long. A
    // small sun is a sign only, so its rays stay short.
    final angles = slots(small ? 0 : rays);
    final longOnes = small ? const <int>{} : order(angles.length).take(rays).toSet();
    final newest = small || rays == 0 ? -1 : order(angles.length)[rays - 1];
    final width = r * (small ? .22 : .13);
    final gap = r * (small ? .22 : .14);
    final shortLength = r * (small ? .34 : .24);
    final longLength = r * .66;
    final paint = Paint()
      ..color = lit
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width;
    // Rays come out as the sun clears the line.
    final shown = small ? (rays > 0 ? 1.0 : 0.0) : Curves.easeOut.transform(((rise - .35) / .65).clamp(0.0, 1.0));
    if (shown > 0) {
      for (var i = 0; i < angles.length; i++) {
        final a = angles[i] * math.pi / 180;
        final dir = Offset(math.cos(a), -math.sin(a));
        var length = shortLength * shown;
        if (longOnes.contains(i)) {
          // The newest long ray overshoots a little as it lands.
          final g = i != newest
              ? 1.0
              : grow < .7
              ? Curves.easeOut.transform(grow / .7) * 1.12
              : 1.12 - .12 * (grow - .7) / .3;
          length = shortLength * shown + (longLength - shortLength) * g;
          if (proofDays >= 7 && g > .9) {
            final tip = center + dir * (r + gap + length + width * 1.3);
            canvas.drawCircle(tip, width * .42, Paint()..color = lit);
          }
        }
        final start = center + dir * (r + gap);
        canvas.drawLine(start, start + dir * length, paint);
      }
    }
    canvas.drawCircle(center, r, Paint()..color = lit);
    canvas.restore();

    if (lineColor != null) {
      canvas.drawLine(
        Offset(0, lineY),
        Offset(w, lineY),
        Paint()
          ..color = lineColor!
          ..strokeWidth = small ? 1.5 : CurreSpace.horizon,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProoflightPainter old) =>
      old.rays != rays ||
      old.proofDays != proofDays ||
      old.rise != rise ||
      old.grow != grow ||
      old.ember != ember ||
      old.dormant != dormant ||
      old.lineColor != lineColor;
}

/// The streak as Home shows it (audit §4): a small still sun and "7 proof
/// days", nothing more. The sun is up with today's rays once today has
/// proof, and still below the line before that, never red and never
/// crossed out. One day reads "1 proof day"; none yet, "No proof days yet".
/// [cloudDay] adds the soft cloud of a cloud day in hand.
class ProofDaysLabel extends StatelessWidget {
  const ProofDaysLabel({super.key, required this.days, this.raysToday = 0, this.cloudDay = false, this.color});

  final int days;
  final int raysToday;
  final bool cloudDay;
  final Color? color;

  static String text(int days) => switch (days) {
    0 => 'No proof days yet',
    1 => '1 proof day',
    _ => '$days proof days',
  };

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final ink = color ?? c.ink2;
    final label = [
      text(days),
      if (raysToday > 0) 'today’s sun is up',
      if (cloudDay) 'one cloud day in hand',
    ].join(', ');
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProoflightSun(rays: raysToday, proofDays: days, size: 34, lineColor: ink.withValues(alpha: .7)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text(days),
              style: t.label.copyWith(fontSize: 14, color: ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (cloudDay) ...[const SizedBox(width: 6), const CloudDayMark(size: 24, semanticLabel: null)],
        ],
      ),
    );
  }
}

/// A cloud day (audit §3, rule 7): a soft cloud over the one empty day it
/// covers. It keeps the run going and adds nothing to the count; it is
/// earned, free and visible as weather, never sold as a repair. [label] is
/// the day it covers (a date in the week strip).
class CloudDayMark extends StatelessWidget {
  const CloudDayMark({super.key, this.size = 44, this.label, this.semanticLabel = 'Cloud day'});

  final double size;
  final String? label;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final light = Theme.of(context).brightness == Brightness.light;
    final fill = light ? const Color(0xFFE6EEF6) : const Color(0xFF2C3446);
    final edge = light ? const Color(0xFFC9D6E3) : const Color(0xFF3F4A60);
    return Semantics(
      label: semanticLabel == null ? null : [semanticLabel!, ?label].join(', '),
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CloudPainter(fill: fill, edge: edge),
          child: label == null
              ? null
              : Padding(
                  padding: EdgeInsets.only(top: size * .16),
                  child: Center(
                    child: Text(label!, style: t.label.weight(600).copyWith(color: c.ink2)),
                  ),
                ),
        ),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  _CloudPainter({required this.fill, required this.edge});

  final Color fill;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..addRRect(RRect.fromLTRBR(w * .02, h * .42, w * .98, h * .9, Radius.circular(h * .24)))
      ..addOval(Rect.fromCircle(center: Offset(w * .34, h * .46), radius: h * .22))
      ..addOval(Rect.fromCircle(center: Offset(w * .6, h * .38), radius: h * .28));
    final outline = Path.combine(PathOperation.union, Path()..addPath(path, Offset.zero), Path());
    canvas.drawPath(outline, Paint()..color = fill);
    canvas.drawPath(
      outline,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _CloudPainter old) => old.fill != fill || old.edge != edge;
}

/// What Curre says when a run ends (audit §3, rule 8). Nothing is erased:
/// the best run and every proof day stay, and the next sunrise is one proof
/// away. Never "lost", "failed" or "back to zero".
class RunEndedNote extends StatelessWidget {
  const RunEndedNote({super.key, required this.endedAt, this.best, this.total});

  /// How many proof days the run that ended had.
  final int endedAt;
  final int? best;
  final int? total;

  static String headline(int days) => 'That run ended at ${days == 1 ? '1 proof day' : '$days proof days'}.';

  static const next = 'Today’s proof starts the next sunrise.';

  /// The standing record, in the machine's voice: "Best run 12 · 31 proof
  /// days in all".
  static String? record({int? best, int? total}) {
    final parts = [
      if (best != null) 'Best run $best',
      if (total != null) total == 1 ? '1 proof day in all' : '$total proof days in all',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final meta = record(best: best, total: total);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(CurreSpace.s5, CurreSpace.s4, CurreSpace.s5, CurreSpace.s5),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: CurreShape.md,
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The next sunrise: the sun waiting just below the line. Only the
          // foot of the sun's box shows; the room kept for rays stays out.
          ClipRect(
            child: Align(
              alignment: Alignment.bottomLeft,
              heightFactor: .5,
              child: ProoflightSun(rays: 0, size: 72, rise: .3, lineColor: c.ink, semanticLabel: 'The next sunrise'),
            ),
          ),
          const SizedBox(height: CurreSpace.s3),
          Text(headline(endedAt), style: t.title.copyWith(fontSize: 18, height: 24 / 18)),
          const SizedBox(height: CurreSpace.s1),
          Text(next, style: t.body.copyWith(color: c.ink2)),
          if (meta != null) ...[const SizedBox(height: CurreSpace.s3), Text(meta, style: t.meta)],
        ],
      ),
    );
  }
}
