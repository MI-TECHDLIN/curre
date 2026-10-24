import 'package:curre/design/design.dart';
import 'package:curre/gallery/preview/checkin_preview_screen.dart';
import 'package:curre/gallery/preview/parts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child, {double width = 360, double textScale = 1}) async {
  tester.view.physicalSize = Size(width, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: curreTheme(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 400), textScaler: TextScaler.linear(textScale)),
        child: Material(
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    ),
  );
}

Greeting _greeting(String? name) => Greeting(
  greeting: 'Good morning',
  name: name,
  subtitle: 'Saturday, 24 October',
  trailing: const RoundGlyphButton(glyph: CurreGlyphKind.curreSettings, semanticLabel: 'Curre settings'),
);

void main() {
  test('the greeting names the user, and stands alone without a name', () {
    expect(Greeting.compose('Good morning', 'Chidi'), 'Good morning, Chidi');
    expect(Greeting.compose('Good morning', null), 'Good morning');
    expect(Greeting.compose('Good morning', '   '), 'Good morning');
    expect(Greeting.compose('Good morning', '  Chidi   Okafor '), 'Good morning, Chidi Okafor');
  });

  testWidgets('no name shows the greeting with no dangling comma', (tester) async {
    await _pump(tester, _greeting(null));
    expect(find.text('Good morning'), findsOneWidget);
    // The date line has its own comma; the greeting must not end in one.
    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').trimRight().endsWith(',')), findsNothing);
  });

  testWidgets('a name follows the greeting', (tester) async {
    await _pump(tester, _greeting(previewName), width: 390);
    expect(find.text('Good morning, $previewName'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('a long name steps down or wraps, never overflowing at 360 dp (text ×$scale)', (tester) async {
      await _pump(tester, _greeting(longPreviewName), textScale: scale);
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text('Good morning, $longPreviewName'));
      expect(text.maxLines, anyOf(1, 2));
      expect(text.style!.fontSize, lessThanOrEqualTo(30));
    });
  }

  testWidgets('the greeting keeps its full 30 sp size whenever it fits on one line', (tester) async {
    // Wide enough for the test font, which sets every glyph a full em wide.
    await _pump(tester, _greeting(null), width: 1200);
    expect(tester.widget<Text>(find.text('Good morning')).style!.fontSize, 30);
  });
}
