import 'package:curre/design/design.dart';
import 'package:curre/gallery/preview/streak_moment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: curreTheme(brightness),
      home: MediaQuery(
        data: MediaQueryData(size: const Size(390, 844), disableAnimations: reduceMotion),
        child: Material(child: child),
      ),
    ),
  );
}

PeekMascot _peek(WidgetTester tester) => tester.widget<PeekMascot>(find.byType(PeekMascot));

void main() {
  testWidgets('it starts dormant: a grey, rayless, sleeping sun and yesterday\'s count', (tester) async {
    await _pump(tester, const StreakMomentScreen(progress: 0));
    final peek = _peek(tester);
    expect(peek.lit, 0);
    expect(peek.rays, 0);
    expect(peek.eyesOpen, 0);
    expect(find.bySemanticsLabel('4 days in a row'), findsOneWidget);
  });

  testWidgets('it ends lit: Peek awake, the count rolled to 5, both doors as proof', (tester) async {
    await _pump(tester, const StreakMomentScreen(progress: 1));
    final peek = _peek(tester);
    expect(peek.lit, 1);
    expect(peek.rays, 1);
    expect(peek.eyesOpen, 1);
    expect(find.bySemanticsLabel('5 days in a row'), findsOneWidget);
    expect(find.text('Morning kept'), findsOneWidget);
    expect(find.textContaining('G chord'), findsOneWidget);
    expect(find.textContaining('worship'), findsOneWidget);
  });

  testWidgets('it plays and loops without throwing, in dark too', (tester) async {
    await _pump(tester, const StreakMomentScreen(), brightness: Brightness.dark);
    expect(tester.hasRunningAnimations, isTrue);
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('with reduced motion it shows the kept state at once', (tester) async {
    await _pump(tester, const StreakMomentScreen(), reduceMotion: true);
    await tester.pump();
    expect(_peek(tester).lit, 1);
    expect(find.bySemanticsLabel('5 days in a row'), findsOneWidget);
  });
}
