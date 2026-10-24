import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) => MaterialApp(
  theme: curreTheme(brightness),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('PeekMascot renders the base pose in light and dark', (tester) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(_host(const PeekMascot(), brightness: brightness));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Peek'), findsOneWidget);
    }
  });

  testWidgets('PeekMascot renders the small master', (tester) async {
    await tester.pumpWidget(_host(const PeekMascot(size: 36, compact: true, groundShadow: false)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('PeekMascot is still when animate is false', (tester) async {
    await tester.pumpWidget(_host(const PeekMascot(animate: false)));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('PeekMascot floats and blinks when animate is true, through a whole loop', (tester) async {
    await tester.pumpWidget(_host(const PeekMascot()));
    expect(tester.hasRunningAnimations, isTrue);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the waking hooks draw from dormant to lit without throwing', (tester) async {
    for (final v in [0.0, .3, .7, 1.0]) {
      await tester.pumpWidget(_host(PeekMascot(animate: false, lit: v, rays: v, eyesOpen: v)));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('PeekMascot can be purely decorative', (tester) async {
    await tester.pumpWidget(_host(const PeekMascot(semanticLabel: null)));
    expect(find.bySemanticsLabel('Peek'), findsNothing);
  });

  test('heightFor leaves room for the ground shadow', () {
    expect(PeekMascot.heightFor(100), greaterThan(PeekMascot.heightFor(100, groundShadow: false)));
  });
}
