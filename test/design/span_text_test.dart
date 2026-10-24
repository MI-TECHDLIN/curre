import 'package:flutter/material.dart';
import 'package:curre/design/design.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpanText.buildRuns (rune-safe slicing)', () {
    test('slices plain ASCII text by code-point offsets', () {
      const text = 'reply Ada about rehearsal';
      final style = const TextStyle(backgroundColor: Colors.yellow);
      final runs = SpanText.buildRuns(text, [SpanHighlight(6, 9, style: style)]);

      expect(runs.map((r) => r.$1).toList(), ['reply ', 'Ada', ' about rehearsal']);
      expect(runs[1].$2?.style, style);
    });

    test('an emoji is one code point but two UTF-16 code units', () {
      // "😀" (U+1F600) is outside the Basic Multilingual Plane, so it is a
      // surrogate pair in UTF-16 (`.length`) but a single rune.
      const text = '😀 reply';
      expect(text.length, 8); // UTF-16 code units: 2 (surrogate pair) + ' reply' (6).
      expect(text.runes.length, 7); // code points: 😀, ' ', r, e, p, l, y.
    });

    test('highlighting the emoji by its single code-point offset keeps it intact', () {
      const text = '😀 reply Ada';
      final style = const TextStyle(color: Colors.red);
      // The emoji is codepoint [0, 1); highlighting it must not split the
      // surrogate pair the way a UTF-16 substring(0, 1) would.
      final runs = SpanText.buildRuns(text, [SpanHighlight(0, 1, style: style)]);

      expect(runs.first.$1, '😀');
      expect(runs.first.$2?.style, style);
      expect(runs.last.$1, ' reply Ada');
    });

    test('handles a non-Latin (CJK) string with correct code-point offsets', () {
      const text = '读書 reply Ada about rehearsal';
      final style = const TextStyle(fontStyle: FontStyle.italic);
      // "读書" is 2 code points; "Ada" starts right after "读書 reply ".
      final adaStart = '读書 reply '.runes.length;
      final runs = SpanText.buildRuns(text, [SpanHighlight(adaStart, adaStart + 3, style: style)]);

      final highlighted = runs.where((r) => r.$2 != null).map((r) => r.$1).toList();
      expect(highlighted, ['Ada']);
    });

    test('clamps out-of-range offsets instead of throwing', () {
      const text = 'short';
      final style = const TextStyle();
      final runs = SpanText.buildRuns(text, [SpanHighlight(2, 999, style: style)]);

      expect(runs.last.$1, 'ort');
    });

    test('returns the whole text as one run when there are no highlights', () {
      const text = 'no highlights here';
      final runs = SpanText.buildRuns(text, const []);
      expect(runs, [(text, null)]);
    });
  });

  testWidgets('SpanText renders highlighted and plain runs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpanText(
            '😀 reply Ada about rehearsal',
            highlights: [SpanHighlight(8, 11, style: const TextStyle(backgroundColor: Colors.yellow))],
          ),
        ),
      ),
    );

    expect(find.textContaining('reply'), findsOneWidget);
    final richText = tester.widget<RichText>(find.byType(RichText).first);
    final root = richText.text as TextSpan;
    expect(root.toPlainText(), '😀 reply Ada about rehearsal');
  });

  testWidgets('SpanText places a highlight\'s trailing span right after it, past an emoji', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpanText(
            '😀 reply Ada about rehearsal',
            highlights: [
              SpanHighlight(
                8,
                11,
                style: const TextStyle(backgroundColor: Colors.yellow),
                after: const TextSpan(text: '[1]'),
              ),
            ],
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText).first);
    expect((richText.text as TextSpan).toPlainText(), '😀 reply Ada[1] about rehearsal');
  });
}
