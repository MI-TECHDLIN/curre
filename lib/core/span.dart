/// A half-open span measured in Unicode code points, not Dart UTF-16 units.
class SourceSpan {
  const SourceSpan({
    required this.text,
    required this.start,
    required this.end,
  });

  factory SourceSpan.fromJson(Map<String, Object?> json) {
    final text = json['text'];
    final start = json['start'];
    final end = json['end'];
    if (text is! String || start is! int || end is! int) {
      throw const FormatException(
        'Span requires string text and integer offsets',
      );
    }
    if (start < 0 || end < start) {
      throw FormatException('Invalid half-open span [$start, $end)');
    }
    return SourceSpan(text: text, start: start, end: end);
  }

  final String text;
  final int start;
  final int end;

  Map<String, Object?> toJson() => <String, Object?>{
    'text': text,
    'start': start,
    'end': end,
  };
}

/// Slices a string using Clocked's Unicode code-point offsets.
String sliceByCodePoints(String source, int start, int end) {
  final points = source.runes.toList(growable: false);
  if (start < 0 || end < start || end > points.length) {
    throw RangeError(
      'Invalid code-point span [$start, $end) for ${points.length} points',
    );
  }
  return String.fromCharCodes(points.sublist(start, end));
}

/// Slices an Extract span and verifies that its copied text still matches.
String sliceExtractSpan(String source, SourceSpan span) {
  final value = sliceByCodePoints(source, span.start, span.end);
  if (value != span.text) {
    throw FormatException(
      'Span text does not match source at [${span.start}, ${span.end})',
    );
  }
  return value;
}
