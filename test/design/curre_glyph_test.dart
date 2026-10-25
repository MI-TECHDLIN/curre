import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CurreGlyph draws every kind without throwing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [
            for (final kind in CurreGlyphKind.values)
              CurreGlyph(kind, semanticLabel: kind.name),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      find.byType(CurreGlyph),
      findsNWidgets(CurreGlyphKind.values.length),
    );
  });

  test('covers the approved set plus launcher, profile and proof marks', () {
    expect(CurreGlyphKind.values.length, 38);
  });

  test('every kind is a Solar Bold glyph except the three composed ones', () {
    const composed = {
      CurreGlyphKind.kindUnclear,
      CurreGlyphKind.guardFlagged,
      CurreGlyphKind.info,
    };
    for (final kind in CurreGlyphKind.values) {
      final icon = curreGlyphIcon(kind);
      if (composed.contains(kind)) {
        expect(icon, isNull, reason: '$kind is composed');
      } else {
        expect(icon, isNotNull, reason: '$kind needs a glyph');
        expect(icon!.fontPackage, 'solar_icons');
      }
    }
  });

  testWidgets('a stock kind renders the Solar icon at the asked size', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: CurreGlyph(CurreGlyphKind.kindPerson, size: 20)),
      ),
    );
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, curreGlyphIcon(CurreGlyphKind.kindPerson));
    expect(icon.size, 20);
    expect(tester.getSize(find.byType(CurreGlyph)), const Size.square(20));
  });

  testWidgets('a composed kind paints its own knocked-out mark', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: CurreGlyph(CurreGlyphKind.guardFlagged, size: 24)),
      ),
    );
    expect(find.byType(Icon), findsNothing);
    expect(
      find.descendant(
        of: find.byType(CurreGlyph),
        matching: find.byType(CustomPaint),
      ),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('CurreGlyph exposes its semantic label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: CurreGlyph(CurreGlyphKind.kindTask, semanticLabel: 'Task'),
      ),
    );
    expect(find.bySemanticsLabel('Task'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('CurreGlyph without a label adds nothing to semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CurreGlyph(CurreGlyphKind.check)),
    );
    final semantics = tester.getSemantics(find.byType(CurreGlyph));
    expect(semantics.label, isEmpty);
  });
}
