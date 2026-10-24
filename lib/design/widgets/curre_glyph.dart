import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Curre's code-drawn glyph set (design report 3.7): a 24 dp grid, 2 dp
/// padding, round-capped 1.75 dp strokes, built only from circles, arcs and
/// straight lines at 45° steps. No stock icon set is used anywhere.
///
/// This is the subset the widgets in `lib/design` need right now
/// ([KindChip]'s five reason kinds, [OutcomeCard]'s five outcomes, plus a
/// few shared utility marks). The full 31-glyph set from the report
/// (session.*, out-of-sight/rise/set, paste fallback, speak, essential,
/// history, curre settings, under the hood, home role, privacy, notify,
/// info, back, go) is follow-up work for the screens that need them.
enum CurreGlyphKind {
  door,
  kindTask,
  kindPerson,
  kindTimeSensitive,
  kindBrowse,
  kindUnclear,
  later,
  editSpecify,
  guardFlagged,
  unavailable,
  overrideWait,
  check,
  close,
  sessionMorning,
  sessionAfternoon,
  sessionEvening,
}

/// One glyph, drawn in code at [size] (defaults to the 24 dp grid) in
/// [color]. [filled] switches on the active/selected variant where the
/// glyph has one (design report 3.7: "filled variants for active states").
///
/// Always set [semanticLabel] to the glyph's meaning (e.g. "Task") so it
/// reaches TalkBack — the report requires every glyph to carry one. A null
/// label marks the glyph as purely decorative.
class CurreGlyph extends StatelessWidget {
  const CurreGlyph(
    this.kind, {
    super.key,
    this.size = 24,
    this.color,
    this.filled = false,
    this.semanticLabel,
  });

  final CurreGlyphKind kind;
  final double size;
  final Color? color;
  final bool filled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? IconTheme.of(context).color ?? const Color(0xFF1E1A16);
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel == null,
      child: CustomPaint(
        size: Size.square(size),
        painter: _CurreGlyphPainter(kind: kind, color: resolvedColor, filled: filled),
      ),
    );
  }
}

class _CurreGlyphPainter extends CustomPainter {
  _CurreGlyphPainter({required this.kind, required this.color, required this.filled});

  final CurreGlyphKind kind;
  final Color color;
  final bool filled;

  /// Grid is 24 logical units with 2-unit padding, per the report; stroke
  /// scales with the painted size so smaller glyphs stay legible.
  static const double _grid = 24;
  static const double _strokeAt24 = 1.75;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _grid;
    canvas.save();
    canvas.scale(scale);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeAt24
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const p = 2.0; // 2 dp padding
    const c = _grid / 2; // 12, the grid centre

    switch (kind) {
      case CurreGlyphKind.door:
        final rect = Rect.fromLTRB(p + 2, p, _grid - p - 2, _grid - p);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1.5)), stroke);
        canvas.drawCircle(Offset(rect.right - 3.5, c), 1.1, filled ? fill : stroke);
        break;

      case CurreGlyphKind.kindTask:
        final rect = Rect.fromLTRB(p + 1, p + 1, _grid - p - 1, _grid - p - 1);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), stroke);
        if (filled) canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), fill);
        final checkPaint = Paint()
          ..color = filled ? _onColor(color) : color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeAt24
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final path = Path()
          ..moveTo(c - 4, c)
          ..lineTo(c - 1, c + 3)
          ..lineTo(c + 5, c - 4);
        canvas.drawPath(path, checkPaint);
        break;

      case CurreGlyphKind.kindPerson:
        canvas.drawCircle(Offset(c, c - 4), 3.4, filled ? fill : stroke);
        final shoulders = Path()
          ..moveTo(c - 6, _grid - p)
          ..arcToPoint(Offset(c + 6, _grid - p), radius: const Radius.circular(7), clockwise: false);
        canvas.drawPath(shoulders, filled ? (fill..style = PaintingStyle.fill) : stroke);
        break;

      case CurreGlyphKind.kindTimeSensitive:
        canvas.drawCircle(Offset(c, c), _grid / 2 - p - .5, stroke);
        canvas.drawLine(Offset(c, c), Offset(c, c - 4.5), stroke);
        canvas.drawLine(Offset(c, c), Offset(c + 3.5, c + 3.5), stroke);
        if (filled) canvas.drawCircle(Offset(c, c), 1.3, fill);
        break;

      case CurreGlyphKind.kindBrowse:
        final lens = Path()
          ..moveTo(p, c)
          ..quadraticBezierTo(c, p + 1, _grid - p, c)
          ..quadraticBezierTo(c, _grid - p - 1, p, c)
          ..close();
        canvas.drawPath(lens, stroke);
        canvas.drawCircle(Offset(c, c), filled ? 3.2 : 2.6, filled ? fill : stroke);
        break;

      case CurreGlyphKind.kindUnclear:
        final hook = Path()
          ..moveTo(c - 3.5, c - 4)
          ..arcToPoint(Offset(c + 3, c - 2.2), radius: const Radius.circular(3.6), clockwise: true)
          ..lineTo(c, c + 2.5);
        canvas.drawPath(hook, stroke);
        canvas.drawCircle(Offset(c, c + 6.2), filled ? 1.4 : 1.1, filled ? fill : stroke);
        break;

      case CurreGlyphKind.later:
        final path = Path()
          ..moveTo(p + 3, p)
          ..lineTo(_grid - p - 3, p)
          ..lineTo(_grid - p - 3, _grid - p)
          ..lineTo(c, c + 3)
          ..lineTo(p + 3, _grid - p)
          ..close();
        canvas.drawPath(path, filled ? fill : stroke);
        break;

      case CurreGlyphKind.editSpecify:
        canvas.drawLine(Offset(p + 2, _grid - p - 2), Offset(_grid - p - 3, p + 3), stroke);
        final tip = Path()
          ..moveTo(_grid - p - 3, p + 3)
          ..lineTo(_grid - p, p)
          ..lineTo(_grid - p - 1, p + 4)
          ..close();
        canvas.drawPath(tip, fill);
        canvas.drawLine(Offset(p + 2, _grid - p - 2), Offset(p + 2, _grid - p), stroke);
        break;

      case CurreGlyphKind.guardFlagged:
        final diamond = Path()
          ..moveTo(c, p)
          ..lineTo(_grid - p, c)
          ..lineTo(c, _grid - p)
          ..lineTo(p, c)
          ..close();
        canvas.drawPath(diamond, filled ? fill : stroke);
        final markColor = filled ? _onColor(color) : color;
        final markPaint = Paint()
          ..color = markColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeAt24
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(c, c - 4), Offset(c, c + 1), markPaint);
        canvas.drawCircle(Offset(c, c + 4.2), 0.9, Paint()..color = markColor);
        break;

      case CurreGlyphKind.unavailable:
        canvas.drawLine(Offset(p, c), Offset(c - 2.5, c), stroke);
        canvas.drawLine(Offset(c + 2.5, c), Offset(_grid - p, c), stroke);
        canvas.drawLine(Offset(c - 3.2, c - 3), Offset(c - 1, c + 1), stroke);
        canvas.drawLine(Offset(c + 1, c - 1), Offset(c + 3.2, c + 3), stroke);
        break;

      case CurreGlyphKind.overrideWait:
        canvas.drawLine(Offset(p + 2, p), Offset(_grid - p - 2, p), stroke);
        canvas.drawLine(Offset(p + 2, _grid - p), Offset(_grid - p - 2, _grid - p), stroke);
        final glass = Path()
          ..moveTo(p + 2, p)
          ..lineTo(_grid - p - 2, _grid - p)
          ..moveTo(_grid - p - 2, p)
          ..lineTo(p + 2, _grid - p);
        canvas.drawPath(glass, stroke);
        if (filled) canvas.drawCircle(Offset(c, c), 1.6, fill);
        break;

      case CurreGlyphKind.check:
        final path = Path()
          ..moveTo(p + 2, c)
          ..lineTo(c - 2, _grid - p - 2)
          ..lineTo(_grid - p - 2, p + 3);
        canvas.drawPath(path, stroke);
        break;

      case CurreGlyphKind.close:
        canvas.drawLine(Offset(p + 2, p + 2), Offset(_grid - p - 2, _grid - p - 2), stroke);
        canvas.drawLine(Offset(_grid - p - 2, p + 2), Offset(p + 2, _grid - p - 2), stroke);
        break;

      case CurreGlyphKind.sessionMorning:
      case CurreGlyphKind.sessionAfternoon:
      case CurreGlyphKind.sessionEvening:
        _paintSession(canvas, stroke, fill);
        break;
    }

    canvas.restore();
  }

  void _paintSession(Canvas canvas, Paint stroke, Paint fill) {
    const c = _grid / 2;
    const lineY = 16.0;
    canvas.drawLine(const Offset(2, lineY), const Offset(_grid - 2, lineY), stroke);

    final double sunCy;
    final double radius;
    final int rayCount;
    switch (kind) {
      case CurreGlyphKind.sessionMorning:
        sunCy = lineY - 1;
        radius = 3.6;
        rayCount = 3;
        break;
      case CurreGlyphKind.sessionAfternoon:
        sunCy = lineY - 6.5;
        radius = 4.2;
        rayCount = 5;
        break;
      case CurreGlyphKind.sessionEvening:
      default:
        sunCy = lineY - 3.2;
        radius = 3.6;
        rayCount = 1;
        break;
    }

    final sunCenter = Offset(c, sunCy);
    final clip = Path()..addRect(Rect.fromLTRB(0, 0, _grid, lineY));
    canvas.save();
    canvas.clipPath(clip);
    canvas.drawCircle(sunCenter, radius, filled ? fill : stroke);
    canvas.restore();

    if (rayCount > 0) {
      final span = math.pi / 3;
      for (var i = 0; i < rayCount; i++) {
        final angle = -math.pi / 2 - span / 2 + (rayCount == 1 ? span / 2 : span * i / (rayCount - 1));
        final inner = sunCenter + Offset(math.cos(angle), math.sin(angle)) * (radius + 1.5);
        final outer = sunCenter + Offset(math.cos(angle), math.sin(angle)) * (radius + 3.2);
        if (outer.dy < lineY) canvas.drawLine(inner, outer, stroke);
      }
    }
  }

  static Color _onColor(Color c) => ThemeData.estimateBrightnessForColor(c) == Brightness.dark
      ? const Color(0xFFFFFDF9)
      : const Color(0xFF1E1A16);

  @override
  bool shouldRepaint(covariant _CurreGlyphPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color || oldDelegate.filled != filled;
}
