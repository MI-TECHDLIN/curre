import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reason kinds are named in everyday words', () {
    expect(kindLabels.values, ['A task', 'Someone’s waiting', 'Can’t wait', 'Just browsing', 'Not clear yet']);
  });

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

  testWidgets('KindChip is never tinted by an outcome: it is always a raised pill', (tester) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: curreTheme(brightness),
          themeAnimationDuration: Duration.zero,
          home: const Scaffold(body: KindChip(kind: ReasonKind.task, confidence: 0.94)),
        ),
      );
      final box = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(KindChip), matching: find.byType(DecoratedBox)).first,
      );
      final decoration = box.decoration as ShapeDecoration;
      final colors = brightness == Brightness.light ? CurreColors.light : CurreColors.dark;
      expect(decoration.color, colors.raised);
      expect(decoration.shape, isA<StadiumBorder>());
      expect(find.text('94%'), findsOneWidget);
    }
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

  testWidgets('KindChip reads its kind and confidence as one label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: const Scaffold(body: KindChip(kind: ReasonKind.person, confidence: 0.94)),
      ),
    );
    expect(find.bySemanticsLabel('Someone’s waiting, confidence 94 percent'), findsOneWidget);
    handle.dispose();
  });
}
