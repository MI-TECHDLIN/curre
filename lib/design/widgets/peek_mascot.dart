import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../curre_colors.dart';

/// Peek, Curre's mascot (design report §5): a sun that lives on the
/// horizon, half-hidden, the thing peeking over the line. Drawn in code on
/// the report's 120-unit grid: a body disc, five crown rays, two floating
/// ray-hands beside the body, two peeking feet, pill eyes with eye-lights,
/// blush cheeks and a ground shadow. This is the **base pose only**, the
/// one the captain approves before any variation (mascot brief rule 6).
///
/// Its limbs float clear of the body like the orange robot reference's,
/// it keeps a sticker-strength silhouette like the cat set's, and its face
/// is pure geometry like the mood trio's. The palette is locked across
/// both themes (ember body, ink features, blush cheeks, paper eye-lights).
///
/// Placement (report §5): check-in and onboarding only. Never on Home once
/// a plan is set, never anywhere in the unlock gate, never in the hidden
/// list or a notification. The widget does not enforce this.
///
/// [compact] switches to the small master (≤40 dp): three heavier rays and
/// bigger eyes, no hands, feet, cheeks or eye-lights.
///
/// [animate] runs a slow float plus a blink every few seconds: lively but
/// calm, never a bounce or a spin. Peek holds still when the system asks
/// for reduced motion. [lit], [rays] and [eyesOpen] (each 0–1)
/// are hooks for a moment that wakes Peek up: a grey, rayless, eyes-shut
/// sun at 0, the base pose at 1.
class PeekMascot extends StatefulWidget {
  const PeekMascot({
    super.key,
    this.size = 120,
    this.compact = false,
    this.animate = true,
    this.groundShadow = true,
    this.lit = 1,
    this.rays = 1,
    this.eyesOpen = 1,
    this.semanticLabel = 'Peek',
  });

  final double size;
  final bool compact;
  final bool animate;
  final bool groundShadow;
  final double lit;
  final double rays;
  final double eyesOpen;
  final String? semanticLabel;

  /// Height of the widget for [size]: the ground shadow needs room below
  /// the feet.
  static double heightFor(double size, {bool groundShadow = true}) => groundShadow ? size * 1.0 : size * .92;

  @override
  State<PeekMascot> createState() => _PeekMascotState();
}

class _PeekMascotState extends State<PeekMascot> with SingleTickerProviderStateMixin {
  // One loop carries both the float (two slow breaths) and one blink, so
  // the blink timing stays deterministic for tests and renders.
  static const _loop = Duration(milliseconds: 5200);

  late final AnimationController _controller = AnimationController(vsync: this, duration: _loop);

  bool get _moving => widget.animate && !MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PeekMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (_moving && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!_moving && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = PeekMascot.heightFor(widget.size, groundShadow: widget.groundShadow);
    return Semantics(
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel == null,
      image: true,
      child: SizedBox(
        width: widget.size,
        height: height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final v = _controller.value;
            final moving = _moving;
            final lift = moving ? (1 - math.cos(v * 4 * math.pi)) / 2 * widget.size * .025 : 0.0;
            // Blink: close over ~120 ms, hold ~80 ms, open over ~160 ms.
            var blink = 1.0;
            if (moving) {
              const start = .84, closed = .863, hold = .878, open = .909;
              if (v >= start && v < closed) {
                blink = 1 - (v - start) / (closed - start);
              } else if (v >= closed && v < hold) {
                blink = 0;
              } else if (v >= hold && v < open) {
                blink = (v - hold) / (open - hold);
              }
            }
            return CustomPaint(
              size: Size(widget.size, height),
              painter: _PeekPainter(
                compact: widget.compact,
                lift: lift,
                groundShadow: widget.groundShadow,
                groundColor: Theme.of(context).extension<CurreColors>()?.sunk,
                lit: widget.lit.clamp(0, 1),
                rays: widget.rays.clamp(0, 1),
                eyesOpen: (widget.eyesOpen * blink).clamp(0, 1),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PeekPainter extends CustomPainter {
  _PeekPainter({
    required this.compact,
    required this.lift,
    required this.groundShadow,
    required this.groundColor,
    required this.lit,
    required this.rays,
    required this.eyesOpen,
  });

  final bool compact;
  final double lift;
  final bool groundShadow;
  final Color? groundColor;
  final double lit;
  final double rays;
  final double eyesOpen;

  // Locked palette (report §5), fixed across both themes.
  static const _ember = Color(0xFFE85F2E);
  static const _dormant = Color(0xFFB9B2A8);
  static const _ink = Color(0xFF1E1A16);
  static const _blush = Color(0xFFF6A07A);
  static const _eyeLight = Color(0xFFFFFDF9);

  static const double _grid = 120;
  static const Offset _center = Offset(60, 58);
  static const double _bodyRadius = 38;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _grid;
    canvas.save();
    canvas.scale(scale);

    if (groundShadow) _paintGround(canvas);
    canvas.translate(0, -lift / scale);

    final body = Paint()..color = Color.lerp(_dormant, _ember, lit)!;
    final ink = Paint()..color = _ink;

    if (compact) {
      _paintRays(canvas, body, count: 3, width: 13, length: 15);
      canvas.drawCircle(_center, _bodyRadius, body);
      _paintEyes(canvas, ink, null, width: 15, height: 22, apart: 28);
      _paintMouth(canvas, span: 7, stroke: 4);
    } else {
      _paintRays(canvas, body, count: 5, width: 8.5, length: 12);
      _paintHands(canvas, body);
      _paintFeet(canvas, body);
      canvas.drawCircle(_center, _bodyRadius, body);
      _paintCheeks(canvas);
      _paintEyes(canvas, ink, Paint()..color = _eyeLight, width: 10.5, height: 16.5, apart: 27);
      _paintMouth(canvas, span: 12, stroke: 3.6);
    }

    canvas.restore();
  }

  /// The robot reference's floor mark: a soft pill under the feet. It stays
  /// put while Peek floats, so the float reads as lift.
  void _paintGround(Canvas canvas) {
    final paint = Paint()..color = (groundColor ?? const Color(0xFFE7E0D4)).withValues(alpha: .95);
    final rect = Rect.fromCenter(center: Offset(_center.dx, _center.dy + _bodyRadius + 17), width: 58, height: 8);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
  }

  /// The crown: [count] capsules fanned over the top of the body. While
  /// [rays] < 1 they pop out one by one from the middle (the moment a
  /// dormant sun lights up).
  void _paintRays(Canvas canvas, Paint fill, {required int count, required double width, required double length}) {
    final spread = count == 3 ? 56.0 : 64.0;
    final order = count == 3 ? const [1, 0, 2] : const [2, 1, 3, 0, 4];
    for (var i = 0; i < count; i++) {
      final t = (i / (count - 1)) * 2 - 1;
      final rank = order.indexOf(i);
      final p = ((rays * count) - rank).clamp(0.0, 1.0);
      if (p <= 0) continue;
      // A short overshoot as each ray arrives, then it settles.
      final grow = p < .7 ? Curves.easeOut.transform(p / .7) * 1.15 : 1.15 - .15 * ((p - .7) / .3);
      _capsuleFromCenter(
        canvas,
        fill,
        angleDeg: -90 + t * spread,
        inner: _bodyRadius + 6,
        width: width,
        length: length * grow,
      );
    }
  }

  /// Two ray-hands floating beside the lower body, clear of it, their feet
  /// end tilted 14° outward (report §5; the robot's floating arms).
  void _paintHands(Canvas canvas, Paint fill) {
    for (final side in const [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(_center.dx + side * 49, _center.dy + 15);
      canvas.rotate(-side * 14 * math.pi / 180);
      final rect = Rect.fromCenter(center: Offset.zero, width: 9.5, height: 21);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4.75)), fill);
      canvas.restore();
    }
  }

  void _capsuleFromCenter(
    Canvas canvas,
    Paint fill, {
    required double angleDeg,
    required double inner,
    required double width,
    required double length,
  }) {
    canvas.save();
    canvas.translate(_center.dx, _center.dy);
    canvas.rotate(angleDeg * math.pi / 180);
    final rect = Rect.fromLTWH(inner, -width / 2, length, width);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(width / 2)), fill);
    canvas.restore();
  }

  /// Two capsules peeking out from under the body: drawn first, so only
  /// the part below the body's edge shows.
  void _paintFeet(Canvas canvas, Paint fill) {
    for (final dx in const [-12.0, 12.0]) {
      final rect = Rect.fromCenter(center: Offset(_center.dx + dx, _center.dy + _bodyRadius), width: 17, height: 14);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(7)), fill);
    }
  }

  void _paintEyes(
    Canvas canvas,
    Paint ink,
    Paint? eyeLight, {
    required double width,
    required double height,
    required double apart,
  }) {
    final eyeY = _center.dy - 4;
    // Shut eyes are a short flat bar (closed lids), never a sad curve.
    final h = math.max(width * .42, height * eyesOpen);
    for (final dx in [-apart / 2, apart / 2]) {
      final center = Offset(_center.dx + dx, eyeY + (height - h) * .35);
      final rect = Rect.fromCenter(center: center, width: width, height: h);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(width / 2)), ink);
      if (eyeLight != null && eyesOpen > .6) {
        canvas.drawCircle(center + Offset(width * .16, -h * .2), 2.3, eyeLight);
      }
    }
  }

  void _paintMouth(Canvas canvas, {required double span, required double stroke}) {
    final paint = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final mid = Offset(_center.dx, _center.dy + 13);
    final depth = span * .42 * (.4 + .6 * eyesOpen);
    final path = Path()
      ..moveTo(mid.dx - span / 2, mid.dy - 1)
      ..quadraticBezierTo(mid.dx, mid.dy - 1 + depth * 1.6, mid.dx + span / 2, mid.dy - 1);
    canvas.drawPath(path, paint);
  }

  void _paintCheeks(Canvas canvas) {
    final paint = Paint()..color = Color.lerp(_dormant, _blush, lit)!;
    for (final dx in const [-21.0, 21.0]) {
      canvas.drawCircle(Offset(_center.dx + dx, _center.dy + 7), 4.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PeekPainter old) =>
      old.compact != compact ||
      old.lift != lift ||
      old.groundShadow != groundShadow ||
      old.groundColor != groundColor ||
      old.lit != lit ||
      old.rays != rays ||
      old.eyesOpen != eyesOpen;
}
