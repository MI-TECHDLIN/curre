import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: curreTheme(brightness),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  test(
    'catalogue has six masculine and six feminine, with stable unique IDs',
    () {
      expect(AvatarCatalog.all, hasLength(12));
      expect(
        AvatarCatalog.all.where(
          (option) => option.presentation == AvatarPresentation.masculine,
        ),
        hasLength(6),
      );
      expect(
        AvatarCatalog.all.where(
          (option) => option.presentation == AvatarPresentation.feminine,
        ),
        hasLength(6),
      );
      expect(
        AvatarCatalog.all.map((option) => option.id).toSet(),
        hasLength(12),
      );
      for (var index = 0; index < AvatarCatalog.all.length; index++) {
        final number = index + 1;
        expect(
          AvatarCatalog.all[index].id,
          'avatar-${number.toString().padLeft(2, '0')}',
        );
        expect(AvatarCatalog.all[index].label, 'Avatar $number');
      }
      expect(AvatarCatalog.byId('avatar-07')?.label, 'Avatar 7');
      expect(AvatarCatalog.byId('retired-avatar'), isNull);
    },
  );

  test('catalogue covers the requested skin, hair and headwear range', () {
    final options = AvatarCatalog.all;
    expect(
      options.map((option) => option.skinTone),
      containsAll([AvatarSkinTone.deep, AvatarSkinTone.light]),
    );
    expect(
      options.map((option) => option.hair),
      containsAll([
        AvatarHair.short,
        AvatarHair.curls,
        AvatarHair.afro,
        AvatarHair.braids,
        AvatarHair.locs,
        AvatarHair.longWaves,
      ]),
    );
    expect(
      options.map((option) => option.headwear),
      containsAll([
        AvatarHeadwear.hijab,
        AvatarHeadwear.headWrap,
        AvatarHeadwear.racerHelmet,
        AvatarHeadwear.aviatorGoggles,
        AvatarHeadwear.screenHelmet,
        AvatarHeadwear.spaceHelmet,
      ]),
    );
    expect(
      options.where(
        (option) =>
            option.skinTone == AvatarSkinTone.light ||
            option.skinTone == AvatarSkinTone.warm,
      ),
      hasLength(8),
    );
  });

  for (final brightness in Brightness.values) {
    for (final size in const [32.0, 40.0, 96.0]) {
      testWidgets(
        'every avatar paints at ${size.toInt()} dp in ${brightness.name}',
        (tester) async {
          await tester.pumpWidget(
            _host(
              Wrap(
                children: [
                  for (final option in AvatarCatalog.all)
                    Avatar(avatarId: option.id, size: size),
                ],
              ),
              brightness: brightness,
            ),
          );
          await tester.pump();

          expect(find.byType(Avatar), findsNWidgets(12));
          for (final element in find.byType(Avatar).evaluate()) {
            final box = element.renderObject! as RenderBox;
            expect(box.size, Size.square(size));
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('unknown or unset avatar IDs fall back to the initial', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Avatar(initial: 'C', size: 40),
            Avatar(avatarId: 'retired-avatar', initial: 'Q', size: 40),
          ],
        ),
      ),
    );

    expect(find.text('C'), findsOneWidget);
    expect(find.text('Q'), findsOneWidget);
    expect(find.bySemanticsLabel('C initial'), findsOneWidget);
    expect(find.bySemanticsLabel('Q initial'), findsOneWidget);
  });

  testWidgets('custom parameters draw a human avatar without a catalogue ID', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Avatar(
          size: 96,
          skinTone: AvatarSkinTone.rich,
          hair: AvatarHair.curls,
          hairColor: AvatarHairColor.chestnut,
          headwear: AvatarHeadwear.headWrap,
          background: AvatarBackground.sky,
        ),
      ),
    );

    expect(find.bySemanticsLabel('Custom profile avatar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('proof ring is included in the accessible description', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const Avatar(avatarId: 'avatar-01', proofToday: true)),
    );
    expect(find.bySemanticsLabel(RegExp('proof today')), findsOneWidget);
  });

  testWidgets('idle motion keeps cycling and a Home reaction plays once', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Avatar(
          avatarId: 'avatar-07',
          size: 64,
          motion: AvatarMotion.idle,
        ),
      ),
    );
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(seconds: 10));
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(
      _host(
        const Avatar(
          avatarId: 'avatar-07',
          size: 64,
          motion: AvatarMotion.reactOnce,
        ),
      ),
    );
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('reduce motion and an off-screen TickerMode hold still', (
    tester,
  ) async {
    Widget motionHost({required bool reduceMotion, required bool onScreen}) =>
        MaterialApp(
          theme: curreTheme(Brightness.light),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: TickerMode(
              enabled: onScreen,
              child: const Avatar(
                avatarId: 'avatar-08',
                size: 64,
                motion: AvatarMotion.idle,
              ),
            ),
          ),
        );

    await tester.pumpWidget(motionHost(reduceMotion: true, onScreen: true));
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(motionHost(reduceMotion: false, onScreen: false));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('sleepy evening variant remains front-facing and labelled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Avatar(
          avatarId: 'avatar-12',
          expression: AvatarExpression.sleepy,
        ),
      ),
    );
    expect(find.bySemanticsLabel(RegExp('sleepy')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'the bold outline has at least 7:1 contrast on every curated background',
    () {
      final outline = AvatarPalette.outline.computeLuminance();
      for (final background in AvatarBackground.values) {
        final fill = background.color.computeLuminance();
        final lighter = fill > outline ? fill : outline;
        final darker = fill > outline ? outline : fill;
        final ratio = (lighter + .05) / (darker + .05);
        expect(
          ratio,
          greaterThanOrEqualTo(7),
          reason: '${background.name}: $ratio',
        );
      }
    },
  );
}
