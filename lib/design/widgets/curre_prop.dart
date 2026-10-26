import 'package:flutter/material.dart';
import 'package:path_parsing/path_parsing.dart';

part '../art/fluent_props.dart';

/// The flat props Curre's illustrated scenes are built from: everyday
/// objects that tell a scene's story at a glance (a tangled ball of yarn
/// for a lost thread, a magnet for the apps that pull you in, a door for
/// landing on the task).
///
/// They come from Microsoft's Fluent Emoji in its Flat style (MIT, see
/// `tool/build_fluent_props.py`) and are drawn as vectors, never images.
/// [CurrePropArt] gives them the same ink outline as Curre's people, so a
/// prop and an avatar read as one illustration.
enum CurreProp {
  alarmClock,
  bell,
  cloud,
  crescentMoon,
  door,
  envelope,
  guitar,
  heart,
  hotDrink,
  hourglass,
  house,
  magnet,
  map,
  memo,
  musicalNotes,
  openBook,
  pin,
  popcorn,
  seedling,
  shield,
  sparkles,
  speechBalloon,
  star,
  yarn,
  zzz,
}

/// One flat shape of a prop: SVG path data on the 32-unit grid and its
/// fill (0xAARRGGBB).
@immutable
class PropShape {
  const PropShape(this.path, this.color, {this.evenOdd = false});

  final String path;
  final int color;
  final bool evenOdd;
}

/// One [CurreProp] at [size], in its own colours in both themes (like the
/// avatars and Peek, props are illustration, not UI).
///
/// [outline] is the visible width of the outline around the prop's whole
/// silhouette; 0 draws the prop flat. Props are decorative unless given a
/// [semanticLabel].
class CurrePropArt extends StatelessWidget {
  const CurrePropArt(
    this.prop, {
    super.key,
    this.size = 48,
    this.outline = 2,
    this.outlineColor = const Color(0xFF1E1A16),
    this.semanticLabel,
  });

  final CurreProp prop;
  final double size;
  final double outline;
  final Color outlineColor;
  final String? semanticLabel;

  /// The shapes [prop] is drawn from, for tests and the gallery.
  static List<PropShape> shapesOf(CurreProp prop) => _fluentPropShapes[prop]!;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _PropPainter(
            prop: prop,
            outline: outline,
            outlineColor: outlineColor,
          ),
        ),
      ),
    );
  }
}

class _PropPainter extends CustomPainter {
  _PropPainter({
    required this.prop,
    required this.outline,
    required this.outlineColor,
  });

  final CurreProp prop;
  final double outline;
  final Color outlineColor;

  static const double _grid = 32;
  static final Map<CurreProp, List<(Path, Color)>> _parsed = {};

  static List<(Path, Color)> _shapes(CurreProp prop) =>
      _parsed.putIfAbsent(prop, () {
        return [
          for (final shape in _fluentPropShapes[prop]!)
            (_parse(shape), Color(shape.color)),
        ];
      });

  static Path _parse(PropShape shape) {
    final proxy = _PathProxy(
      Path()..fillType = shape.evenOdd ? PathFillType.evenOdd : PathFillType.nonZero,
    );
    writeSvgPathDataToPath(shape.path, proxy);
    return proxy.path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Keep the outline inside the box: shrink the art by the outline.
    final inset = outline <= 0 ? 0.0 : outline;
    final artScale = (size.shortestSide - inset * 2) / _grid;
    canvas.save();
    canvas.translate(
      (size.width - _grid * artScale) / 2,
      (size.height - _grid * artScale) / 2,
    );
    canvas.scale(artScale);
    final shapes = _shapes(prop);
    if (outline > 0) {
      // Every shape is stroked first and every fill drawn after, so the
      // fills cover the strokes' inner halves and only the silhouette's
      // edge stays inked: one clean outline round the whole prop.
      final stroke = Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = outline * 2 / artScale
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      for (final (path, _) in shapes) {
        canvas.drawPath(path, stroke);
      }
    }
    for (final (path, color) in shapes) {
      canvas.drawPath(path, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PropPainter old) =>
      old.prop != prop ||
      old.outline != outline ||
      old.outlineColor != outlineColor;
}

class _PathProxy extends PathProxy {
  _PathProxy(this.path);

  final Path path;

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}
