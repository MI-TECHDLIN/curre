import 'package:curre/design/design.dart';
import 'package:curre/gallery/preview/avatar_review_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadReviewFonts() async {
  for (final entry in const <String, String>{
    'Geologica': 'assets/fonts/Geologica[CRSV,SHRP,slnt,wght].ttf',
    'Newsreader': 'assets/fonts/Newsreader-Italic[opsz,wght].ttf',
    'AtkinsonHyperlegibleMono':
        'assets/fonts/AtkinsonHyperlegibleMono[wght].ttf',
  }.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
}

Widget _panel(Key boundaryKey, Brightness brightness) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: curreTheme(brightness),
    home: Scaffold(
      body: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: RepaintBoundary(
          key: boundaryKey,
          child: ColoredBox(
            color: brightness == Brightness.light
                ? CurreColors.light.paper
                : CurreColors.dark.paper,
            child: const Padding(
              padding: EdgeInsets.all(28),
              child: AvatarReviewPanel(),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _motionCard(Key boundaryKey) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: curreTheme(Brightness.light),
    home: Scaffold(
      body: RepaintBoundary(
        key: boundaryKey,
        child: const ColoredBox(
          color: Color(0xFFF7F2EA),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gentle motion, then rest',
                  style: TextStyle(
                    fontFamily: 'Geologica',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1A16),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Blink and breathe in the picker. A happy lift plays once after proof today.',
                  style: TextStyle(
                    fontFamily: 'Geologica',
                    fontSize: 16,
                    color: Color(0xFF5A5048),
                  ),
                ),
                SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MotionSample(
                      label: 'calm idle',
                      avatar: Avatar(
                        avatarId: 'avatar-03',
                        size: 128,
                        motion: AvatarMotion.idle,
                      ),
                    ),
                    _MotionSample(
                      label: 'proof reaction',
                      avatar: Avatar(
                        avatarId: 'avatar-01',
                        size: 128,
                        proofToday: true,
                        motion: AvatarMotion.reactOnce,
                      ),
                    ),
                    _MotionSample(
                      label: 'sleepy evening',
                      avatar: Avatar(
                        avatarId: 'avatar-12',
                        size: 128,
                        expression: AvatarExpression.sleepy,
                        motion: AvatarMotion.idle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _MotionSample extends StatelessWidget {
  const _MotionSample({required this.label, required this.avatar});

  final String label;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        avatar,
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'AtkinsonHyperlegibleMono',
            fontSize: 14,
            color: Color(0xFF5A5048),
          ),
        ),
      ],
    );
  }
}

void main() {
  testWidgets('capture avatar review surfaces', (tester) async {
    await _loadReviewFonts();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final brightness in Brightness.values) {
      tester.view.physicalSize = const Size(820, 1400);
      final boundaryKey = ValueKey('set-${brightness.name}');
      await tester.pumpWidget(_panel(boundaryKey, brightness));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/avatar-set-${brightness.name}.png'),
      );
    }

    tester.view.physicalSize = const Size(760, 380);
    const boundaryKey = ValueKey('motion-card');
    await tester.pumpWidget(_motionCard(boundaryKey));
    await tester.pump();
    for (var frame = 0; frame < 10; frame++) {
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/avatar-motion-${frame.toString().padLeft(2, '0')}.png',
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  });
}
