import 'package:flutter/material.dart';

import '../curre_colors.dart';
import '../curre_tokens.dart';
import '../curre_type.dart';
import 'curre_glyph.dart';

/// Word and glyph Curre shows for each [ReasonKind] (design report 3.7 / 4.6).
const Map<ReasonKind, String> kindLabels = {
  ReasonKind.task: 'Task',
  ReasonKind.person: 'Person waiting',
  ReasonKind.timeSensitive: 'Time-sensitive',
  ReasonKind.browse: 'Browsing',
  ReasonKind.unclear: 'Unclear',
};

const Map<ReasonKind, CurreGlyphKind> kindGlyphs = {
  ReasonKind.task: CurreGlyphKind.kindTask,
  ReasonKind.person: CurreGlyphKind.kindPerson,
  ReasonKind.timeSensitive: CurreGlyphKind.kindTimeSensitive,
  ReasonKind.browse: CurreGlyphKind.kindBrowse,
  ReasonKind.unclear: CurreGlyphKind.kindUnclear,
};

/// The reason-kind chip (design report 3.2 / 4.6): a raised pill, a glyph
/// and a word, **never coloured** by outcome — colour stays the single
/// signal that belongs to the outcome card, not the kind. When [confidence]
/// (0–1) is given, it is shown as a small ember meter with a tick at
/// [threshold] plus the mono number, as on the gate's "Ask" and "Thinking"
/// states.
class KindChip extends StatelessWidget {
  const KindChip({super.key, required this.kind, this.confidence, this.threshold = 0.70});

  final ReasonKind kind;

  /// 0–1, or null to hide the meter (e.g. while still thinking).
  final double? confidence;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final label = kindLabels[kind]!;

    return Semantics(
      label: confidence == null ? label : '$label, confidence ${(confidence! * 100).round()} percent',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: c.raised,
          shape: StadiumBorder(side: BorderSide(color: c.hairline)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(CurreSpace.s3, CurreSpace.s2, CurreSpace.s4, CurreSpace.s2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CurreGlyph(kindGlyphs[kind]!, size: 18, color: c.ink),
              const SizedBox(width: CurreSpace.s2),
              Flexible(
                child: Text(
                  label,
                  style: t.label.weight(640).copyWith(color: c.ink, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (confidence != null) ...[
                const SizedBox(width: CurreSpace.s3),
                _ConfidenceMeter(value: confidence!, threshold: threshold, colors: c),
                const SizedBox(width: CurreSpace.s2),
                Text('${(confidence! * 100).round()}%', style: t.figure.copyWith(fontSize: 13, color: c.ink2)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceMeter extends StatelessWidget {
  const _ConfidenceMeter({required this.value, required this.threshold, required this.colors});

  final double value;
  final double threshold;
  final CurreColors colors;

  static const double _width = 48;
  static const double _height = 6;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: CustomPaint(
        painter: _ConfidenceMeterPainter(
          value: value.clamp(0, 1),
          threshold: threshold.clamp(0, 1),
          track: colors.hairline,
          fill: colors.ember,
        ),
      ),
    );
  }
}

class _ConfidenceMeterPainter extends CustomPainter {
  _ConfidenceMeterPainter({required this.value, required this.threshold, required this.track, required this.fill});

  final double value;
  final double threshold;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    final trackRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(radius));
    canvas.drawRRect(trackRect, Paint()..color = track);

    if (value > 0) {
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * value, size.height),
        Radius.circular(radius),
      );
      canvas.save();
      canvas.clipRRect(trackRect);
      canvas.drawRRect(fillRect, Paint()..color = fill);
      canvas.restore();
    }

    final tickX = size.width * threshold;
    canvas.drawLine(
      Offset(tickX, -1.5),
      Offset(tickX, size.height + 1.5),
      Paint()
        ..color = fill
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _ConfidenceMeterPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.threshold != threshold ||
      oldDelegate.track != track ||
      oldDelegate.fill != fill;
}
