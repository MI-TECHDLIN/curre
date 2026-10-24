import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AnimationController _controllerOf(WidgetTester tester) {
  final state = tester.state<State<RisingDisc>>(find.byType(RisingDisc));
  // ignore: invalid_use_of_visible_for_testing_member
  return (state as dynamic).controller as AnimationController;
}

Widget _host(Widget child) => MaterialApp(
  theme: curreTheme(Brightness.light),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('RisingDisc rises linearly over its duration and calls onComplete', (tester) async {
    var completed = false;
    await tester.pumpWidget(
      _host(RisingDisc(duration: const Duration(seconds: 10), onComplete: () => completed = true)),
    );
    final controller = _controllerOf(tester);

    expect(controller.value, 0);
    await tester.pump(const Duration(seconds: 5));
    expect(controller.value, closeTo(.5, .01));
    await tester.pump(const Duration(milliseconds: 2500));
    expect(controller.value, closeTo(.75, .01));
    expect(controller.status, AnimationStatus.forward);

    // A tick just past the duration flips the status and fires onComplete.
    await tester.pump(const Duration(milliseconds: 2501));
    expect(controller.value, 1);
    expect(completed, isTrue);
  });

  testWidgets('the disc is hidden below the line at the start and clear above it at the end', (tester) async {
    await tester.pumpWidget(_host(const RisingDisc(duration: Duration(seconds: 10), diameter: 40)));
    final stackRect = tester.getRect(find.byType(RisingDisc));
    Rect disc() => tester.getRect(
      find.descendant(
        of: find.byType(RisingDisc),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      ),
    );
    final lineY = stackRect.top + 40 + 6;
    expect(disc().top, closeTo(lineY, .5));
    await tester.pump(const Duration(seconds: 11));
    expect(disc().bottom, closeTo(lineY, .5));
  });

  testWidgets('initialProgress starts a wait part-way through', (tester) async {
    await tester.pumpWidget(_host(const RisingDisc(initialProgress: 13 / 60)));
    expect(_controllerOf(tester).value, closeTo(13 / 60, 1e-9));
  });

  testWidgets('RisingDisc does not animate when autoStart is false', (tester) async {
    await tester.pumpWidget(_host(const RisingDisc(duration: Duration(seconds: 10), autoStart: false)));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
