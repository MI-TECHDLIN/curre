import 'package:flutter/material.dart';
import 'package:curre/design/design.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RisingDisc rises linearly over its duration and calls onComplete', (tester) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: Scaffold(
          body: RisingDisc(
            duration: const Duration(seconds: 10),
            onComplete: () => completed = true,
          ),
        ),
      ),
    );

    final state = tester.state<State<RisingDisc>>(find.byType(RisingDisc));
    // ignore: invalid_use_of_visible_for_testing_member
    final controller = (state as dynamic).controller as AnimationController;

    expect(controller.value, 0);
    await tester.pump(const Duration(seconds: 5));
    expect(controller.value, closeTo(0.5, 0.01));
    expect(controller.status, AnimationStatus.forward);

    // A tick slightly past the duration, not exactly at it, is what flips
    // AnimationController's status to `completed` and fires onComplete.
    await tester.pump(const Duration(milliseconds: 5001));
    expect(controller.value, 1);
    expect(completed, isTrue);
  });

  testWidgets('RisingDisc does not animate when autoStart is false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: const Scaffold(
          body: RisingDisc(duration: Duration(seconds: 10), autoStart: false),
        ),
      ),
    );
    expect(tester.hasRunningAnimations, isFalse);
  });
}
