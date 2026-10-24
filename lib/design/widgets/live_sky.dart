import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../curre_colors.dart';

/// A session's sky drawn as a small living scene, behind Peek on the
/// check-in card: flat shapes in tones of the session's own sky (no
/// gradients, no blur), each moving slowly enough to stay calm.
///
/// * **Morning, first light.** Broad beams turn slowly round the sun, three
///   rings of warm light breathe around it, soft clouds drift and a pair of
///   birds hangs low over the horizon (the Mombo card's birds).
/// * **Afternoon, clear and bright.** The sun is high in one bright halo,
///   and white cumulus drift in two layers, the near ones faster.
/// * **Evening, the blue hour.** Bands of dusk glow lie on the horizon, a
///   thin moon is up and the first stars twinkle in a clear sky.
///
/// Nothing that moves ever crosses the words laid over the sky
/// ([keepClear]): clouds, birds and stars keep to the column beside the
/// words and the band between them and the horizon, passing behind the sun
/// there. Only the faint light round the sun reaches
/// behind the words, and the on-sky ink keeps its contrast over it.
///
/// Everything is drawn above the horizon at [lineY]. The light centres on
/// [sunCenter]; a [sunRadius] of 0 means no sun and no light round it.
/// [flood] (0–1) fades the scene in while the sky is still filling up. One
/// loop lasts [period] and every motion fits into it a whole number of
/// times, so it repeats without a seam. With [animate] off or reduce-motion
/// on it is one still frame, and its ticker runs only while it is on
/// screen.
class LiveSky extends StatefulWidget {
  const LiveSky({
    super.key,
    required this.session,
    required this.lineY,
    required this.sunCenter,
    required this.sunRadius,
    this.keepClear,
    this.flood = 1,
    this.animate = true,
  });

  final Session session;
  final double lineY;
  final Offset sunCenter;
  final double sunRadius;

  /// Where the words sit over the sky, if any.
  final Rect? keepClear;
  final double flood;
  final bool animate;

  static const period = Duration(seconds: 90);

  @override
  State<LiveSky> createState() => _LiveSkyState();
}

class _LiveSkyState extends State<LiveSky> with SingleTickerProviderStateMixin {
  // A still sky shows this moment of the loop: clouds spread out, the
  // birds' wings up.
  static const _still = .12;

  late final AnimationController _loop = AnimationController(vsync: this, duration: LiveSky.period, value: _still);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LiveSky oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final still = !widget.animate || MediaQuery.disableAnimationsOf(context);
    if (still && _loop.isAnimating) {
      _loop.stop();
      _loop.value = _still;
    } else if (!still && !_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: LiveSkyPainter(
          session: widget.session,
          sky: c.sky(widget.session),
          dark: dark,
          lineY: widget.lineY,
          sunCenter: widget.sunCenter,
          sunRadius: widget.sunRadius,
          keepClear: widget.keepClear,
          flood: widget.flood,
          loop: _loop,
        ),
      ),
    );
  }
}

/// Paints one frame of a [LiveSky]; [loop] runs 0–1 over [LiveSky.period].
class LiveSkyPainter extends CustomPainter {
  LiveSkyPainter({
    required this.session,
    required this.sky,
    required this.dark,
    required this.lineY,
    required this.sunCenter,
    required this.sunRadius,
    required this.flood,
    required this.loop,
    this.keepClear,
  }) : super(repaint: loop);

  final Session session;
  final Pair sky;
  final bool dark;
  final double lineY;
  final Offset sunCenter;
  final double sunRadius;
  final Rect? keepClear;
  final double flood;
  final Animation<double> loop;

  static const _tau = math.pi * 2;
  static const _warm = Color(0xFFFFF4D6);
  static const _white = Color(0xFFFFFFFF);

  double get _alpha => flood.clamp(0.0, 1.0);

  /// [sky]'s background moved [t] of the way to [to]: every shape is a
  /// tone of the session's own sky.
  Color _tone(Color to, double t) => Color.lerp(sky.bg, to, t)!.withValues(alpha: _alpha);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || flood <= 0) return;
    final lanes = _Lanes.of(size, lineY, keepClear);
    final v = loop.value;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, lineY));
    switch (session) {
      case Session.morning:
        _morning(canvas, size, lanes, v);
      case Session.afternoon:
        _afternoon(canvas, size, lanes, v);
      case Session.evening:
        _evening(canvas, size, lanes, v);
    }
    canvas.restore();
  }

  // Morning: first light.

  void _morning(Canvas canvas, Size size, _Lanes lanes, double v) {
    final glow = dark ? const Color(0xFFFF9B5E) : _warm;
    _beams(canvas, size, v, glow);
    _rings(canvas, v, glow, const [2.7, 2.05, 1.5], dark ? const [.08, .14, .22] : const [.18, .32, .48]);

    final cloud = dark ? Color.lerp(sky.bg, sky.fg, .2)! : Color.lerp(sky.bg, _white, .7)!;
    _swayingCloud(canvas, lanes, v, width: .3, color: cloud, bumps: 3);
    _crossingCloud(canvas, size, v, lane: lanes.low, laps: 1, offset: .62, color: cloud, bumps: 3);
    _birds(canvas, size, lanes, v);
  }

  /// Broad beams turning slowly round the sun.
  void _beams(Canvas canvas, Size size, double v, Color glow) {
    if (sunRadius <= 0) return;
    // Twenty sectors, every other one lit: the pattern repeats every 36°,
    // and the beams turn exactly that far in one loop.
    final beams = Path();
    final reach = size.longestSide * 1.2;
    for (var i = 0; i < 10; i++) {
      final a = (i * 36 + v * 36) * math.pi / 180;
      beams
        ..moveTo(sunCenter.dx, sunCenter.dy)
        ..lineTo(sunCenter.dx + reach * math.cos(a), sunCenter.dy + reach * math.sin(a))
        ..lineTo(sunCenter.dx + reach * math.cos(a + .2), sunCenter.dy + reach * math.sin(a + .2))
        ..close();
    }
    canvas.drawPath(beams, Paint()..color = _tone(glow, dark ? .06 : .13));
  }

  /// A pair of birds hanging low over the horizon on the left, drifting a
  /// little, beating their wings now and then and gliding in between.
  void _birds(Canvas canvas, Size size, _Lanes lanes, double v) {
    final lane = lanes.low;
    if (lane.height < 14) return;
    final paint = Paint()
      ..color = sky.fg.withValues(alpha: .6 * _alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final (fx, dy, phase, half) in const [(.17, -2.0, 0.0, 5.5), (.25, 5.0, 2.1, 4.5)]) {
      final x = size.width * fx + 10 * math.sin(_tau * v * 2 + phase);
      final y = lane.center.dy + dy + 2.5 * math.sin(_tau * v * 9 + phase);
      // Thirty wing beats a loop, each followed by a glide.
      final beat = (v * 30 + phase / _tau) % 1;
      final flap = beat < .3 ? math.sin(beat / .3 * _tau) : 0.0;
      final lift = half * .62 + half * .5 * flap;
      final path = Path()
        ..moveTo(x - half, y - lift)
        ..quadraticBezierTo(x - half * .45, y - lift * .15, x, y)
        ..quadraticBezierTo(x + half * .45, y - lift * .15, x + half, y - lift);
      canvas.drawPath(path, paint);
    }
  }

  // Afternoon: clear and bright.

  void _afternoon(Canvas canvas, Size size, _Lanes lanes, double v) {
    final light = dark ? const Color(0xFFBFEFFF) : _white;
    _rings(canvas, v, light, const [2.3, 1.6], dark ? const [.08, .14] : const [.18, .32]);

    final far = dark ? Color.lerp(sky.bg, sky.fg, .14)! : Color.lerp(sky.bg, _white, .45)!;
    final near = dark ? Color.lerp(sky.bg, sky.fg, .26)! : Color.lerp(sky.bg, _white, .9)!;
    _crossingCloud(canvas, size, v, lane: lanes.low, laps: 1, offset: .55, color: far, bumps: 2, scale: .62);
    _swayingCloud(canvas, lanes, v, width: .34, color: near, bumps: 4);
    _crossingCloud(canvas, size, v, lane: lanes.low, laps: 2, offset: .1, color: near, bumps: 3);
  }

  // Evening: the blue hour.

  void _evening(Canvas canvas, Size size, _Lanes lanes, double v) {
    final w = size.width;
    // Dusk glow: three flat bands on the horizon, violet to peach, their
    // tops rolling very slowly. They stop short of the words.
    final bands = dark
        ? const [(Color(0xFF8E6FB0), .18, .34), (Color(0xFFC77A9C), .24, .21), (Color(0xFFF2A47E), .3, .1)]
        : const [(Color(0xFF8E6FB0), .32, .36), (Color(0xFFC77A9C), .48, .22), (Color(0xFFF2A47E), .64, .1)];
    for (final (i, (tint, mix, height)) in bands.indexed) {
      final top = math.max(lineY - lineY * height, lanes.low.top + 3);
      final path = Path()..moveTo(0, lineY);
      for (var x = 0.0; x <= w; x += 6) {
        path.lineTo(x, top + 2.5 * math.sin(_tau * (x / w * (1.2 + i * .4) + v * (i.isEven ? 1 : -1)) + i));
      }
      path
        ..lineTo(w, lineY)
        ..close();
      canvas.drawPath(path, Paint()..color = _tone(tint, mix));
    }

    // The moon, high in the column beside the words, in a faint ring.
    final side = lanes.side;
    if (side.width >= 36) {
      final moon = Offset(side.left + side.width * .64, side.top + 14);
      const r = 10.0;
      canvas.drawCircle(moon, r * 2.1, Paint()..color = _tone(sky.fg, .07));
      final crescent = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: moon, radius: r)),
        Path()..addOval(Rect.fromCircle(center: moon + const Offset(-5, -3.5), radius: r * .92)),
      );
      canvas.drawPath(crescent, Paint()..color = sky.fg.withValues(alpha: _alpha));
    }

    // The first stars: a handful, each twinkling a whole number of times a
    // loop, in the column beside the words, the strip above and the band
    // below.
    final stars = <(Offset, double, int)>[
      for (final (fx, fy, s, n) in const [
        (.15, .62, 3.0, 7),
        (.85, .3, 2.4, 9),
        (.4, .78, 2.6, 11),
        (.72, .95, 2.0, 13),
      ])
        (Offset(side.left + side.width * fx, side.top + (side.bottom - side.top) * fy * .6), s, n),
      for (final (fx, s, n) in const [(.06, 2.0, 6), (.34, 1.8, 10), (.58, 2.2, 8)])
        (Offset(w * fx, lanes.high.center.dy), s, n),
      for (final (fx, s, n) in const [(.08, 2.2, 12), (.46, 1.8, 5)]) (Offset(w * fx, lanes.low.top + 4), s, n),
    ];
    for (final (c, s, n) in stars) {
      if (c.dy >= lineY - 4) continue;
      final twinkle = .55 + .45 * math.sin(_tau * (v * n + c.dx / w * 3));
      _star(canvas, c, s * (.8 + .3 * twinkle), sky.fg.withValues(alpha: twinkle * _alpha));
    }
  }

  void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  // Shared shapes.

  /// Concentric rings of light round the sun, outermost first, each
  /// breathing slowly a little out of step with the next.
  void _rings(Canvas canvas, double v, Color tint, List<double> radii, List<double> mixes) {
    if (sunRadius <= 0) return;
    for (var i = 0; i < radii.length; i++) {
      final breath = 1 + .03 * math.sin(_tau * (v * 9) - i * .9);
      canvas.drawCircle(sunCenter, sunRadius * radii[i] * breath, Paint()..color = _tone(tint, mixes[i]));
    }
  }

  /// A cloud drifting left to right along [lane], [laps] times a loop,
  /// sized to the lane's height and wrapping round.
  void _crossingCloud(
    Canvas canvas,
    Size size,
    double v, {
    required Rect lane,
    required int laps,
    required double offset,
    required Color color,
    required int bumps,
    double scale = 1,
  }) {
    final h = math.min(lane.height, 28.0) * scale;
    if (h < 9) return;
    final cw = h / .34;
    final x = ((v * laps + offset) % 1) * (size.width + cw) - cw;
    _cloud(canvas, Rect.fromLTWH(x, lane.center.dy - h / 2, cw, h), color, bumps);
  }

  /// A larger cloud swaying in place at the top of the column beside the
  /// words.
  void _swayingCloud(
    Canvas canvas,
    _Lanes lanes,
    double v, {
    required double width,
    required Color color,
    required int bumps,
  }) {
    final side = lanes.side;
    const sway = 8.0;
    // Clouds keep a cloud's size on a wide card: at most 128 dp across.
    final cw = math.min(math.min(side.width - 2 * sway - 16, lanes.size.width * width), 128.0);
    if (cw < 48) return;
    final h = cw * .34;
    final x = side.left + (side.width - cw) / 2 + sway * math.sin(_tau * v * 2);
    _cloud(canvas, Rect.fromLTWH(x, side.top + 2, cw, h), color, bumps);
  }

  /// A flat cloud in [box]: a rounded base with [bumps] round tops.
  void _cloud(Canvas canvas, Rect box, Color color, int bumps) {
    final h = box.height;
    final path = Path()
      ..addRRect(RRect.fromLTRBR(box.left, box.top + h * .45, box.right, box.bottom, Radius.circular(h * .28)));
    for (var i = 0; i < bumps; i++) {
      final t = bumps == 1 ? .5 : .22 + .56 * i / (bumps - 1);
      final r = h * (i.isEven ? .48 : .38) * (bumps > 3 && (i == 1 || i == 2) ? 1.15 : 1);
      path.addOval(Rect.fromCircle(center: Offset(box.left + box.width * t, box.top + h * .62), radius: r));
    }
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: _alpha));
  }

  @override
  bool shouldRepaint(covariant LiveSkyPainter old) =>
      old.session != session ||
      old.sky != sky ||
      old.dark != dark ||
      old.lineY != lineY ||
      old.sunCenter != sunCenter ||
      old.sunRadius != sunRadius ||
      old.keepClear != keepClear ||
      old.flood != flood ||
      old.loop != loop;
}

/// The three places a [LiveSky] may move things without crossing the
/// words: a strip above them, a column beside them, a band below them.
class _Lanes {
  _Lanes(this.size, this.high, this.side, this.low);

  factory _Lanes.of(Size size, double lineY, Rect? words) {
    final w = size.width;
    if (words == null || words.isEmpty) {
      return _Lanes(
        size,
        Rect.fromLTRB(0, lineY * .04, w, lineY * .2),
        Rect.fromLTRB(w * .58, lineY * .06, w, lineY),
        Rect.fromLTRB(0, lineY * .58, w, lineY - 4),
      );
    }
    final top = math.max(0.0, words.top - 4);
    return _Lanes(
      size,
      Rect.fromLTRB(0, math.min(4, top), w, top),
      Rect.fromLTRB(math.min(w, words.right + 12), words.top, w, lineY),
      Rect.fromLTRB(0, math.min(lineY - 4, words.bottom + 8), w, lineY - 4),
    );
  }

  final Size size;
  final Rect high;
  final Rect side;
  final Rect low;
}
