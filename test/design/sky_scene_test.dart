import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) => MaterialApp(
  theme: curreTheme(brightness),
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, height: 240, child: child)),
  ),
);

void main() {
  testWidgets('SkyScene draws every session with each kind of sun, in both themes', (tester) async {
    for (final brightness in Brightness.values) {
      for (final session in Session.values) {
        for (final sun in SkySun.values) {
          await tester.pumpWidget(
            _host(
              SkyScene(session: session, sun: sun, child: const Text('q')),
              brightness: brightness,
            ),
          );
          expect(tester.takeException(), isNull);
          expect(find.text('q'), findsOneWidget);
          expect(find.byType(PeekMascot), sun == SkySun.peek ? findsOneWidget : findsNothing);
        }
      }
    }
  });

  testWidgets('Peek on a SkyScene stays still unless asked to move', (tester) async {
    await tester.pumpWidget(_host(const SkyScene(session: Session.morning)));
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(_host(const SkyScene(session: Session.morning, animatePeek: true)));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('a dormant sky (flood 0) draws, and so does every step of the flood', (tester) async {
    for (final f in [0.0, .25, .5, 1.0]) {
      await tester.pumpWidget(_host(SkyScene(session: Session.evening, flood: f, lit: f, rays: f, eyesOpen: f)));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('a living sky with water draws for every session in both themes', (tester) async {
    for (final brightness in Brightness.values) {
      for (final session in Session.values) {
        await tester.pumpWidget(
          _host(
            SkyScene(
              session: session,
              groundHeight: 72,
              live: true,
              keepClear: const Rect.fromLTWH(20, 24, 180, 80),
              water: .4,
              waterFrom: .1,
              waterLabel: 'Today so far',
            ),
            brightness: brightness,
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(find.byType(LiveSky), findsOneWidget);
        expect(find.byType(RisingWater), findsOneWidget);
      }
    }
  });

  testWidgets('a plain sky has neither', (tester) async {
    await tester.pumpWidget(_host(const SkyScene(session: Session.morning)));
    expect(find.byType(LiveSky), findsNothing);
    expect(find.byType(RisingWater), findsNothing);
  });
}
