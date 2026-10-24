import 'package:flutter/material.dart';

/// A highlighted span of [SpanText], given as Unicode **code-point**
/// offsets into the text, end exclusive — the same offsets Clocked's
/// Extract and Guard return (differentiator report §6.3: `Span = {text,
/// start, end}` within the source text, code points). [style] is merged
/// over the base style for the run between [start] and [end].
@immutable
class SpanHighlight {
  const SpanHighlight(this.start, this.end, {required this.style, this.semanticsLabel});

  /// Code-point offset of the first highlighted character.
  final int start;

  /// Code-point offset just past the last highlighted character
  /// (exclusive).
  final int end;

  final TextStyle style;

  /// Optional label read in place of the highlighted text, e.g.
  /// "Ada → matched a chat on this phone" (design report 4.6).
  final String? semanticsLabel;
}

/// Renders [text] with [highlights] applied, slicing by Unicode **runes**
/// rather than UTF-16 `substring`/`[]`, so offsets that split a surrogate
/// pair (an emoji, or any character outside the Basic Multilingual Plane)
/// land on the right boundary. Clocked's offsets are code points
/// (design report 3.10, note 1), never UTF-16 code units.
class SpanText extends StatelessWidget {
  const SpanText(
    this.text, {
    super.key,
    this.highlights = const [],
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final List<SpanHighlight> highlights;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  /// Splits [text] into runs of (text, highlight-or-null) by code-point
  /// offset. Exposed for testing without needing a widget tree.
  static List<(String, SpanHighlight?)> buildRuns(String text, List<SpanHighlight> highlights) {
    final runes = text.runes.toList(growable: false);
    final n = runes.length;
    if (n == 0 || highlights.isEmpty) return [(text, null)];

    final sorted = [...highlights]..sort((a, b) => a.start.compareTo(b.start));
    final runs = <(String, SpanHighlight?)>[];
    var cursor = 0;

    for (final h in sorted) {
      final start = h.start.clamp(0, n);
      final end = h.end.clamp(start, n);
      if (start > cursor) {
        runs.add((String.fromCharCodes(runes.sublist(cursor, start)), null));
      }
      if (end > start) {
        runs.add((String.fromCharCodes(runes.sublist(start, end)), h));
      }
      cursor = end > cursor ? end : cursor;
    }
    if (cursor < n) {
      runs.add((String.fromCharCodes(runes.sublist(cursor, n)), null));
    }
    return runs;
  }

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final runs = buildRuns(text, highlights);

    return Text.rich(
      TextSpan(
        children: [
          for (final (runText, highlight) in runs)
            TextSpan(
              text: runText,
              style: highlight?.style,
              semanticsLabel: highlight?.semanticsLabel,
            ),
        ],
      ),
      style: base,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}
