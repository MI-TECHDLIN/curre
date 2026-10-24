import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Where a light source sits over the water, for its reflection.
enum WaterGlint {
  /// A low sun: a column of warm dashes on the water under it.
  sun,

  /// A high sun: small sparkles scattered along the surface.
  sparkle,

  /// The moon: a short column of pale dashes under it.
  moon,
}

/// How a body of [RisingWater] looks: the water itself, a lighter second
/// wave behind it for depth, the light line along its surface, and the
/// colour and kind of its reflections.
@immutable
class WaterStyle {
  const WaterStyle({
    required this.body,
    required this.back,
    required this.crest,
    required this.glint,
    this.glintKind = WaterGlint.sparkle,
    this.glintAt = .5,
  });

  final Color body;
  final Color back;
  final Color crest;
  final Color glint;
  final WaterGlint glintKind;

  /// The light source's place across the width, 0–1, for [WaterGlint.sun]
  /// and [WaterGlint.moon].
  final double glintAt;

  @override
  bool operator ==(Object other) =>
      other is WaterStyle &&
      other.body == body &&
      other.back == back &&
      other.crest == crest &&
      other.glint == glint &&
      other.glintKind == glintKind &&
      other.glintAt == glintAt;

  @override
  int get hashCode => Object.hash(body, back, crest, glint, glintKind, glintAt);
}

/// Water that fills its box from the bottom up to [level] (0–1): how Curre
/// shows progress rising. Its surface moves in two slow waves; when the
/// level rises the water climbs on a soft spring, sloshes side to side and
/// lets a few bubbles go, then settles.
///
/// [level] is the only input, so anything that measures progress can fill
/// the same water: today's plans now (`DayProgress` in core), proof later.
/// The first build rises from [from] when it is given (the level the user
/// last saw), and every later rise starts from the old level. A level that
/// falls (a new day) settles there without a slosh. Level 0 still shows a
/// shallow layer, so the water reads as water before anything has filled it.
///
/// The ticker runs only while the water is on screen: it stops when its
/// route is covered or the app is in the background (TickerMode), and with
/// [animate] off or the system's reduce-motion setting the water is a still
/// frame at [level]. Painting is a few short paths per frame, inside its
/// own repaint boundary.
class RisingWater extends StatefulWidget {
  const RisingWater({
    super.key,
    required this.level,
    required this.style,
    this.from,
    this.animate = true,
    this.semanticLabel,
  });

  final double level;
  final WaterStyle style;
  final double? from;
  final bool animate;

  /// What the water measures, read out with its level ("Today so far,
  /// 2 doors used"). Null makes the water decorative.
  final String? semanticLabel;

  /// One loop of the surface: both waves travel a whole number of lengths
  /// in it, so the loop has no seam.
  static const wavePeriod = Duration(milliseconds: 7200);

  /// How long a slosh takes to die away after a rise.
  static const sloshLength = Duration(milliseconds: 1800);

  @override
  State<RisingWater> createState() => _RisingWaterState();
}

class _RisingWaterState extends State<RisingWater> with TickerProviderStateMixin {
  late final AnimationController _waves = AnimationController(vsync: this, duration: RisingWater.wavePeriod);
  late final AnimationController _level = AnimationController.unbounded(vsync: this, value: _start);
  late final AnimationController _slosh = AnimationController(vsync: this, duration: RisingWater.sloshLength, value: 1);

  /// How far the last rise climbed (0–1), which sets the slosh's size.
  double _rise = 0;
  bool _still = true;
  bool _started = false;

  double get _target => widget.level.clamp(0.0, 1.0);
  double get _start => (widget.from ?? widget.level).clamp(0.0, 1.0);

  // The level's spring: a soft climb with a small overshoot, settled in
  // about a second.
  static final _spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 90, ratio: .62);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = !widget.animate || MediaQuery.disableAnimationsOf(context);
    if (still != _still || !_started) {
      _still = still;
      _apply(from: _started ? _level.value : _start, first: !_started);
      _started = true;
    }
  }

  @override
  void didUpdateWidget(RisingWater old) {
    super.didUpdateWidget(old);
    final still = !widget.animate || MediaQuery.disableAnimationsOf(context);
    if (still != _still || old.level != widget.level) {
      _still = still;
      _apply(from: _level.value, first: false);
    }
  }

  void _apply({required double from, required bool first}) {
    if (_still) {
      _waves.stop();
      _waves.value = .3;
      _slosh.value = 1;
      _level.value = _target;
      return;
    }
    if (!_waves.isAnimating) _waves.repeat();
    final to = _target;
    if (to > from + .001) {
      _rise = to - from;
      _level.value = from;
      _level.animateWith(SpringSimulation(_spring, from, to, 0));
      _slosh.forward(from: 0);
    } else if (to < from - .001) {
      _level.animateTo(to, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
    } else if (first) {
      _level.value = to;
    }
  }

  @override
  void dispose() {
    _waves.dispose();
    _level.dispose();
    _slosh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_target * 100).round();
    return Semantics(
      label: widget.semanticLabel,
      value: widget.semanticLabel == null ? null : '$percent%',
      excludeSemantics: true,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _WaterPainter(waves: _waves, level: _level, slosh: _slosh, rise: _rise, style: widget.style),
        ),
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  _WaterPainter({
    required this.waves,
    required this.level,
    required this.slosh,
    required this.rise,
    required this.style,
  }) : super(repaint: Listenable.merge([waves, level, slosh]));

  final Animation<double> waves;
  final Animation<double> level;
  final Animation<double> slosh;
  final double rise;
  final WaterStyle style;

  static const _tau = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final v = waves.value;
    // Seconds since the last rise began; 1 when there is no slosh.
    final st = slosh.value * RisingWater.sloshLength.inMilliseconds / 1000;
    final sloshing = slosh.value < 1;
    final decay = sloshing ? math.exp(-st / .55) : 0.0;

    final amp = 2.2 * (1 + 1.5 * decay);
    final top = amp * 2 + 3;
    final floor = math.max(h * .16, amp * 2 + 2);
    final lvl = level.value.clamp(-.04, 1.04);
    final mean = h - (floor + (h - top - floor) * lvl);

    // The slosh: the surface tilts one way, then the other, dying away.
    // A bigger rise sloshes harder, within a few dp.
    final tilt = sloshing ? math.min(9.0, 4 + rise * 14) * decay * math.sin(_tau * st / .8) : 0.0;

    double front(double x) {
      final u = x / w;
      return mean +
          amp * math.sin(_tau * (u * 1.8 + v)) +
          amp * .45 * math.sin(_tau * (u * 3.6 - 2 * v) + 1.1) +
          tilt * (u - .5) * 2;
    }

    double back(double x) {
      final u = x / w;
      return mean - amp * .9 - 1.5 + amp * .8 * math.sin(_tau * (u * 1.4 - v) + 2.2) + tilt * .6 * (u - .5) * 2;
    }

    Path body(double Function(double) surface) {
      final path = Path()..moveTo(0, h);
      for (var x = 0.0; x <= w; x += 4) {
        path.lineTo(x, surface(x));
      }
      path
        ..lineTo(w, surface(w))
        ..lineTo(w, h)
        ..close();
      return path;
    }

    canvas.drawPath(body(back), Paint()..color = style.back);
    final water = body(front);
    canvas.drawPath(water, Paint()..color = style.body);

    final crest = Path()..moveTo(0, front(0));
    for (var x = 4.0; x <= w; x += 4) {
      crest.lineTo(x, front(x));
    }
    crest.lineTo(w, front(w));
    canvas.drawPath(
      crest,
      Paint()
        ..color = style.crest
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.save();
    canvas.clipPath(water);
    _paintGlints(canvas, size, front, v);
    if (sloshing) _paintBubbles(canvas, size, front, st);
    canvas.restore();
  }

  void _paintGlints(Canvas canvas, Size size, double Function(double) front, double v) {
    final w = size.width;
    final paint = Paint()
      ..color = style.glint
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    switch (style.glintKind) {
      case WaterGlint.sun || WaterGlint.moon:
        // Broken light under the sun or the moon: short dashes of uneven
        // length, each a little off the centre line and shimmering at its
        // own pace, so the column reads as glitter on moving water.
        final moon = style.glintKind == WaterGlint.moon;
        final cx = w * style.glintAt;
        const sun = [(1.0, -2.0, 1), (.62, 5.0, 3), (.8, -6.0, 2), (.4, 2.0, 4), (.52, 9.0, 3)];
        const moonlight = [(.7, 1.0, 2), (.45, -4.0, 3), (.58, 3.0, 1), (.3, -1.0, 4)];
        final dashes = moon ? moonlight : sun;
        final widest = moon ? 14.0 : 26.0;
        paint.strokeWidth = moon ? 1.5 : 1.8;
        for (final (i, (len, dx, n)) in dashes.indexed) {
          final shimmer = .5 + .5 * math.sin(_tau * v * n + i * 1.9);
          final l = widest * len * (.6 + .4 * shimmer);
          final x = cx + dx + 2 * math.sin(_tau * v + i * 2.3);
          final y = front(x) + 4 + i * 4.5;
          paint.color = style.glint.withValues(alpha: (.95 - i * .12) * (.5 + .5 * shimmer));
          canvas.drawLine(Offset(x - l / 2, y), Offset(x + l / 2, y), paint);
        }
      case WaterGlint.sparkle:
        // Small four-point sparkles riding the surface, each lit in turn.
        const spots = [.12, .31, .52, .68, .86];
        for (var i = 0; i < spots.length; i++) {
          final x = w * spots[i];
          final on = math.max(0.0, math.sin(_tau * (v * 2 + i * .37)));
          if (on <= .05) continue;
          final r = 1.5 + 3 * on;
          final c = Offset(x, front(x) + 4);
          paint.color = style.glint.withValues(alpha: on);
          final star = Path()
            ..moveTo(c.dx, c.dy - r)
            ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
            ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
            ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
            ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
            ..close();
          canvas.drawPath(star, Paint()..color = paint.color);
        }
    }
  }

  void _paintBubbles(Canvas canvas, Size size, double Function(double) front, double st) {
    // Five bubbles let go from the bottom as the water climbs.
    const seeds = [(.18, .0, 2.2), (.34, .18, 1.6), (.57, .08, 2.6), (.71, .28, 1.8), (.86, .14, 2.0)];
    final h = size.height;
    for (final (x, delay, r) in seeds) {
      final t = st - delay;
      if (t <= 0) continue;
      final cx = size.width * x + 2.5 * math.sin(t * 9 + x * 20);
      final cy = h - 4 - t * 38;
      final surface = front(cx);
      if (cy - r < surface + 2) continue;
      final fade = (1 - t / 1.3).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = style.crest.withValues(alpha: .85 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaterPainter old) =>
      old.style != style || old.rise != rise || old.waves != waves || old.level != level || old.slosh != slosh;
}
