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

ProoflightSun _sun(WidgetTester tester) => tester.widget<ProoflightSun>(find.byType(ProoflightSun).first);

void main() {
  testWidgets('it starts dormant: today\'s sun below the line, no ray, yesterday\'s count', (tester) async {
    await _pump(tester, const StreakMomentScreen(progress: 0));
    final sun = _sun(tester);
    expect(sun.rise, 0);
    expect(sun.grow, 0);
    expect(find.bySemanticsLabel('4 proof days'), findsOneWidget);
  });

  testWidgets('it ends lit: the sun up with one ray, five proof days, the proof in the user\'s words', (tester) async {
    await _pump(tester, const StreakMomentScreen(progress: 1));
    final sun = _sun(tester);
    expect(sun.rise, 1);
    expect(sun.grow, 1);
    expect(sun.rays, 1);
    expect(find.bySemanticsLabel('5 proof days'), findsOneWidget);
    expect(find.text('Today’s sun is up'), findsOneWidget);
    expect(find.textContaining('G chord'), findsWidgets);
    expect(find.text('“${StreakMomentScreen.note}”'), findsOneWidget);
  });

  testWidgets('Peek never judges the evidence: the proof sun has no face', (tester) async {
    await _pump(tester, const StreakMomentScreen(progress: 1));
    expect(find.byType(PeekMascot), findsNothing);
  });

  testWidgets('it plays and loops without throwing, in dark too', (tester) async {
    await _pump(tester, const StreakMomentScreen(), brightness: Brightness.dark);
    expect(tester.hasRunningAnimations, isTrue);
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('with reduced motion it shows the risen sun at once', (tester) async {
    await _pump(tester, const StreakMomentScreen(), reduceMotion: true);
    await tester.pump();
    expect(_sun(tester).rise, 1);
    expect(find.bySemanticsLabel('5 proof days'), findsOneWidget);
  });
}
