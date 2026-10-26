import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Building blocks for Curre's illustrated scenes (onboarding's stages):
/// a printed-paper grain, organic colour blocks, sticker cards with a hard
/// offset shadow, a phone, and a slow float. Everything is flat colour; the
/// depth comes from layering and solid shadows, never blur or gradients.

/// Ink used for outlines in scenes, fixed across themes like the avatars'.
const sceneInk = Color(0xFF1E1A16);

/// A fine, fixed grain over a colour block, like ink on uncoated paper.
/// It is deterministic (the same dots for the same size and [seed]) and
/// static, so it rasterises once.
class SceneGrain extends StatelessWidget {
  const SceneGrain({
    super.key,
    required this.dark,
    required this.light,
    this.density = .0042,
    this.seed = 11,
  });

  /// Colour of the darker specks.
  final Color dark;

  /// Colour of the lighter specks.
  final Color light;

  /// Specks per square logical pixel, for each tone.
  final double density;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _GrainPainter(
            dark: dark,
            light: light,
            density: density,
            seed: seed,
          ),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({
    required this.dark,
    required this.light,
    required this.density,
    required this.seed,
  });

  final Color dark;
  final Color light;
  final double density;
  final int seed;

  static final Map<(int, int, int, double), (Float32List, Float32List)>
  _cache = {};

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.isFinite) return;
    final key = (size.width.round(), size.height.round(), seed, density);
    final (darkDots, lightDots) = _cache.putIfAbsent(key, () {
      final random = math.Random(seed);
      final count = (size.width * size.height * density).round();
      Float32List dots() {
        final list = Float32List(count * 2);
        for (var i = 0; i < count; i++) {
          list[i * 2] = random.nextDouble() * size.width;
          list[i * 2 + 1] = random.nextDouble() * size.height;
        }
        return list;
      }

      return (dots(), dots());
    });
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.3;
    canvas.drawRawPoints(ui.PointMode.points, darkDots, paint..color = dark);
    canvas.drawRawPoints(ui.PointMode.points, lightDots, paint..color = light);
  }

  @override
  bool shouldRepaint(covariant _GrainPainter old) =>
      old.dark != dark ||
      old.light != light ||
      old.density != density ||
      old.seed != seed;
}

/// A card that sits on a scene like a sticker: flat fill, an ink outline
/// and a solid shadow offset down and right.
class SceneCard extends StatelessWidget {
  const SceneCard({
    super.key,
    required this.child,
    this.color = const Color(0xFFFFFDF9),
    this.radius = 14,
    this.outline = 2,
    this.shadow = const Offset(4, 5),
    this.shadowColor = const Color(0x2E1E1A16),
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double outline;
  final Offset shadow;
  final Color shadowColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: outline > 0
            ? Border.all(color: sceneInk, width: outline)
            : null,
        boxShadow: shadow == Offset.zero
            ? null
            : [BoxShadow(color: shadowColor, offset: shadow)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(math.max(0, radius - outline)),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A phone in a scene: an ink body, a camera dot and a [screen].
class ScenePhone extends StatelessWidget {
  const ScenePhone({
    super.key,
    required this.width,
    required this.height,
    required this.screen,
    this.screenColor = const Color(0xFFFFFDF9),
    this.shadow = const Offset(6, 7),
    this.shadowColor = const Color(0x331E1A16),
  });

  final double width;
  final double height;
  final Widget screen;
  final Color screenColor;
  final Offset shadow;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    final bezel = width * .045;
    final radius = width * .16;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: sceneInk,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow == Offset.zero
            ? null
            : [BoxShadow(color: shadowColor, offset: shadow)],
      ),
      padding: EdgeInsets.all(bezel),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - bezel),
        child: ColoredBox(
          color: screenColor,
          child: Stack(
            children: [
              Positioned.fill(child: screen),
              Positioned(
                top: bezel * 1.4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: width * .18,
                    height: bezel * 1.5,
                    decoration: BoxDecoration(
                      color: sceneInk,
                      borderRadius: BorderRadius.circular(bezel),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A soft organic block of colour behind a scene's subject (the blob
/// behind the reference's characters). [wobble] bends the edge; 0 is an
/// ellipse.
class SceneBlob extends StatelessWidget {
  const SceneBlob({
    super.key,
    required this.color,
    this.wobble = .08,
    this.seed = 3,
  });

  final Color color;
  final double wobble;
  final int seed;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.infinite,
    painter: _BlobPainter(color: color, wobble: wobble, seed: seed),
  );
}

class _BlobPainter extends CustomPainter {
  _BlobPainter({required this.color, required this.wobble, required this.seed});

  final Color color;
  final double wobble;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    const points = 7;
    final radii = [
      for (var i = 0; i < points; i++) 1 - wobble + random.nextDouble() * wobble * 2,
    ];
    final center = size.center(Offset.zero);
    Offset at(int i) {
      final angle = i / points * math.pi * 2 - math.pi / 2;
      final r = radii[i % points];
      return center +
          Offset(
            math.cos(angle) * size.width / 2 * r,
            math.sin(angle) * size.height / 2 * r,
          );
    }

    // A closed Catmull-Rom curve through the points, as cubic Béziers.
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 0; i < points; i++) {
      final p0 = at((i - 1 + points) % points);
      final p1 = at(i);
      final p2 = at((i + 1) % points);
      final p3 = at((i + 2) % points);
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) =>
      old.color != color || old.wobble != wobble || old.seed != seed;
}

/// A slow, small float for one element of a scene, so a still picture
/// breathes a little. It holds still under reduced motion.
class SceneFloat extends StatefulWidget {
  const SceneFloat({
    super.key,
    required this.child,
    this.amplitude = 3,
    this.period = const Duration(milliseconds: 4200),
    this.phase = 0,
    this.turn = 0,
  });

  final Widget child;

  /// How far it rises and sinks, in logical pixels.
  final double amplitude;
  final Duration period;

  /// Where in the loop it starts (0–1), so neighbours don't move as one.
  final double phase;

  /// A matching sway in radians (0 for none).
  final double turn;

  @override
  State<SceneFloat> createState() => _SceneFloatState();
}

class _SceneFloatState extends State<SceneFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
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
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _loop,
      child: widget.child,
      builder: (context, child) {
        final wave = math.sin((_loop.value + widget.phase) * math.pi * 2);
        return Transform.translate(
          offset: Offset(0, wave * widget.amplitude),
          child: widget.turn == 0
              ? child
              : Transform.rotate(angle: wave * widget.turn, child: child),
        );
      },
    );
  }
}
