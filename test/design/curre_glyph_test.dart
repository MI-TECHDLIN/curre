import 'package:flutter/material.dart';
import 'package:curre/design/design.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CurreGlyph paints every kind without throwing, in both variants', (tester) async {
    for (final kind in CurreGlyphKind.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              CurreGlyph(kind, semanticLabel: kind.name),
              CurreGlyph(kind, filled: true, semanticLabel: kind.name),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
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

  testWidgets('CurreGlyph without a label is excluded from semantics', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CurreGlyph(CurreGlyphKind.check)),
    );
    final semantics = tester.getSemantics(find.byType(CurreGlyph));
    expect(semantics.label, isEmpty);
  });
}
