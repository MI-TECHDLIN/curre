import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = Size(350, 224);
const _sun = Offset(266, 190);
const _words = Rect.fromLTWH(20, 24, 210, 112);

Widget _host(Widget child, {Brightness brightness = Brightness.light, bool reduceMotion = false}) => MaterialApp(
  theme: curreTheme(brightness),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Center(
      child: SizedBox.fromSize(size: _size, child: child),
    ),
  ),
);

LiveSky _sky(Session session, {Rect? keepClear = _words, double flood = 1, bool animate = true}) => LiveSky(
  session: session,
  lineY: _size.height,
  sunCenter: _sun,
  sunRadius: 40,
  keepClear: keepClear,
  flood: flood,
  animate: animate,
);

/// Bounds of every shape [painter] draws at loop position [v].
List<Rect> _shapes(LiveSkyPainter painter) {
  final canvas = TestRecordingCanvas();
  painter.paint(canvas, _size);
  final rects = <Rect>[];
  for (final call in canvas.invocations) {
    final args = call.invocation.positionalArguments;
    switch (call.invocation.memberName) {
      case #drawPath:
        rects.add((args[0] as Path).getBounds());
      case #drawCircle:
        rects.add(Rect.fromCircle(center: args[0] as Offset, radius: args[1] as double));
      case #drawRRect:
        rects.add((args[0] as RRect).outerRect);
    }
  }
  return rects;
}

void main() {
  testWidgets('every session draws in both themes, with and without words to avoid', (tester) async {
    for (final brightness in Brightness.values) {
      for (final session in Session.values) {
        for (final keepClear in [_words, null]) {
          await tester.pumpWidget(_host(_sky(session, keepClear: keepClear), brightness: brightness));
          await tester.pump(const Duration(seconds: 3));
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  test('nothing that moves crosses the words, anywhere in the loop', () {
    for (final session in Session.values) {
      for (var i = 0; i <= 120; i++) {
        final painter = LiveSkyPainter(
          session: session,
          sky: CurreColors.light.sky(session),
          dark: false,
          lineY: _size.height,
          sunCenter: _sun,
          sunRadius: 40,
          keepClear: _words,
          flood: 1,
          loop: AlwaysStoppedAnimation(i / 120),
        );
        for (final shape in _shapes(painter)) {
          // The light round the sun (its rings and beams) is centred on it
          // and may lie faintly behind the words; nothing else may.
          if (shape.contains(_sun)) continue;
          expect(shape.overlaps(_words), isFalse, reason: '$session at ${i / 120}: $shape');
        }
      }
    }
  });

  testWidgets('moves only when motion is welcome and the sky is on screen', (tester) async {
    // Each case settles first: switching the host's reduce-motion setting
    // starts a short transition of the app's own.
    Future<void> expectMoving(Widget host, bool moving) async {
      await tester.pumpWidget(host);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, moving);
    }

    await expectMoving(_host(_sky(Session.morning)), true);
    await expectMoving(_host(_sky(Session.morning), reduceMotion: true), false);
    await expectMoving(_host(_sky(Session.morning, animate: false)), false);
    await expectMoving(_host(TickerMode(enabled: false, child: _sky(Session.evening))), false);
  });

  testWidgets('fades in with a sky that is still filling up', (tester) async {
    for (final f in [0.0, .4, 1.0]) {
      await tester.pumpWidget(_host(_sky(Session.afternoon, flood: f)));
      expect(tester.takeException(), isNull);
    }
  });
}
