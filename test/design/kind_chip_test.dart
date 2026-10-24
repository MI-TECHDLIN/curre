import 'package:flutter/material.dart';
import 'package:curre/design/design.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('KindChip shows the label for every reason kind', (tester) async {
    for (final kind in ReasonKind.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: curreTheme(Brightness.light),
          home: Scaffold(body: KindChip(kind: kind)),
        ),
      );
      expect(find.text(kindLabels[kind]!), findsOneWidget);
    }
  });

  testWidgets('KindChip is never tinted by outcome colour: it always uses the raised surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: const Scaffold(body: KindChip(kind: ReasonKind.task, confidence: 0.94)),
      ),
    );

    final decoration =
        (tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration) as BoxDecoration;
    expect(decoration.color, CurreColors.light.raised);
    expect(find.textContaining('94%'), findsOneWidget);
  });

  testWidgets('KindChip without confidence hides the meter', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: const Scaffold(body: KindChip(kind: ReasonKind.unclear)),
      ),
    );
    expect(find.textContaining('%'), findsNothing);
  });
}
