import 'package:flutter/material.dart';
import 'package:curre/design/design.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('OutcomeCard shows the headline, body and outcome glyph for every outcome', (
    tester,
  ) async {
    for (final outcome in Outcome.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: curreTheme(Brightness.light),
          home: Scaffold(
            body: OutcomeCard(
              outcome: outcome,
              headline: 'Headline for ${outcome.name}',
              body: 'Body for ${outcome.name}',
            ),
          ),
        ),
      );

      expect(find.text('Headline for ${outcome.name}'), findsOneWidget);
      expect(find.text('Body for ${outcome.name}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets("`later`'s tint resolves to the target session's sky", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: const Scaffold(
          body: OutcomeCard(
            outcome: Outcome.later,
            laterTarget: Session.evening,
            headline: 'Not now',
          ),
        ),
      ),
    );

    final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    final decoration = decoratedBox.decoration as BoxDecoration;
    expect(decoration.color, CurreColors.light.sky(Session.evening).bg);
  });

  testWidgets('OutcomeCard renders extra content passed as child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: const Scaffold(
          body: OutcomeCard(
            outcome: Outcome.open,
            headline: 'Opens',
            child: Text('actions go here'),
          ),
        ),
      ),
    );
    expect(find.text('actions go here'), findsOneWidget);
  });
}
