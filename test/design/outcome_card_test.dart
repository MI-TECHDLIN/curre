import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('OutcomeCard shows the headline, body and outcome glyph for every outcome', (tester) async {
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
      expect(find.byType(CurreGlyph), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('`later` borrows the target session\'s sky, colour and glyph alike', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: const Scaffold(
          body: OutcomeCard(outcome: Outcome.later, laterTarget: Session.evening, headline: 'Not now'),
        ),
      ),
    );
    final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    expect((box.decoration as BoxDecoration).color, CurreColors.light.sky(Session.evening).bg);
    expect(tester.widget<CurreGlyph>(find.byType(CurreGlyph)).kind, CurreGlyphKind.sessionEvening);
    expect(outcomeGlyph(Outcome.later, laterTarget: Session.afternoon), CurreGlyphKind.sessionAfternoon);
  });

  testWidgets('OutcomeCard renders extra content passed as child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: const Scaffold(
          body: OutcomeCard(outcome: Outcome.open, headline: 'Opens', child: Text('actions go here')),
        ),
      ),
    );
    expect(find.text('actions go here'), findsOneWidget);
  });
}
