import 'package:flutter/material.dart';
import 'package:curre/design/design.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HorizonLine renders a hairline without animating when still', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: const Scaffold(body: HorizonLine()),
      ),
    );
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byType(HorizonLine), findsOneWidget);
  });

  testWidgets('HorizonLine runs a looping scan while scanning is true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: const Scaffold(body: HorizonLine(scanning: true)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);

    // Still looping well past one 1.2 s cycle.
    await tester.pump(const Duration(milliseconds: 1300));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('HorizonLine stops scanning when scanning flips to false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: const Scaffold(body: HorizonLine(scanning: true)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final state = tester.state<State<HorizonLine>>(find.byType(HorizonLine));
    // ignore: invalid_use_of_visible_for_testing_member
    final controller = (state as dynamic).controller as AnimationController;
    expect(controller.isAnimating, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: const Scaffold(body: HorizonLine(scanning: false)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.isAnimating, isFalse);
  });
}
