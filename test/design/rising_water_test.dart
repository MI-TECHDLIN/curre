import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _style = WaterStyle(
  body: Color(0xFF3AA19C),
  back: Color(0xFF6DBDB4),
  crest: Color(0xFFC6F0E8),
  glint: Color(0xFFFFE7B3),
  glintKind: WaterGlint.sun,
  glintAt: .76,
);

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: curreTheme(Brightness.light),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Center(child: SizedBox(width: 320, height: 72, child: child)),
  ),
);

void main() {
  testWidgets('draws every level and every kind of light without throwing', (tester) async {
    for (final kind in WaterGlint.values) {
      for (final level in [0.0, .33, .5, 1.0]) {
        await tester.pumpWidget(
          _host(
            RisingWater(
              level: level,
              style: WaterStyle(
                body: _style.body,
                back: _style.back,
                crest: _style.crest,
                glint: _style.glint,
                glintKind: kind,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('rises from where it was, sloshes, and keeps moving calmly', (tester) async {
    await tester.pumpWidget(_host(const RisingWater(level: .2, style: _style)));
    await tester.pumpWidget(_host(const RisingWater(level: .6, style: _style)));
    expect(tester.hasRunningAnimations, isTrue);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    }
    // A level that falls (a new day) settles without a slosh.
    await tester.pumpWidget(_host(const RisingWater(level: 0, style: _style)));
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a first build can rise from the level last seen', (tester) async {
    await tester.pumpWidget(_host(const RisingWater(level: .56, from: .33, style: _style)));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('holds still with reduced motion, with animate off, and off screen', (tester) async {
    // Each case settles first: switching the host's reduce-motion setting
    // starts a short transition of the app's own.
    Future<void> expectStill(Widget host) async {
      await tester.pumpWidget(host);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
    }

    await expectStill(_host(const RisingWater(level: .5, from: 0, style: _style), reduceMotion: true));
    await expectStill(_host(const RisingWater(level: .5, style: _style, animate: false)));
    await expectStill(_host(const TickerMode(enabled: false, child: RisingWater(level: .5, style: _style))));
    await tester.pumpWidget(_host(const RisingWater(level: .5, style: _style)));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isTrue, reason: 'on screen, the surface keeps moving');
  });

  testWidgets('says what it measures, with its level', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const RisingWater(level: 1 / 3, style: _style, semanticLabel: 'Today so far, 2 doors used')),
    );
    final node = tester.getSemantics(find.byType(RisingWater));
    expect(node.label, 'Today so far, 2 doors used');
    expect(node.value, '33%');
    handle.dispose();
  });
}
