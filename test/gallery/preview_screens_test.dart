import 'package:curre/design/design.dart';
import 'package:curre/gallery/preview/checkin_preview_screen.dart';
import 'package:curre/gallery/preview/gate_preview_screen.dart';
import 'package:curre/gallery/preview/home_preview_screen.dart';
import 'package:curre/gallery/preview/onboarding_preview_screen.dart';
import 'package:curre/gallery/preview/plan_sample.dart';
import 'package:curre/gallery/preview/reveal_preview_screen.dart';
import 'package:curre/gallery/preview/streak_moment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two phones every preview must fit: a common 390 dp phone, and the
/// narrow 360 dp one the detail pass checks nothing overflows on.
const _phones = {'390x844': Size(390, 844), '360x740': Size(360, 740)};

final _screens = <String, Widget Function()>{
  'check-in': () => const CheckinPreviewScreen(),
  'reveal': () => const RevealPreviewScreen(),
  'reveal, long plan': () => const RevealPreviewScreen(plan: longPlan),
  'home': () => const HomePreviewScreen(),
  'home, long plan': () => const HomePreviewScreen(plan: longPlan),
  'gate': () => const GatePreviewScreen(),
  'gate, long app name': () => const GatePreviewScreen(app: 'Samsung Health Monitor'),
  'wait': () => const WaitPreviewScreen(),
  'onboarding': () => const OnboardingPreviewScreen(),
  'streak moment, start': () => const StreakMomentScreen(progress: 0),
  'streak moment, end': () => const StreakMomentScreen(progress: 1),
};

Future<void> _pumpScreen(WidgetTester tester, Widget screen, Size size, Brightness brightness) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: curreTheme(brightness),
      home: Material(color: curreTheme(brightness).scaffoldBackgroundColor, child: screen),
    ),
  );
  // Past every staggered entrance (each a short Future.delayed).
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  for (final MapEntry(key: name, value: build) in _screens.entries) {
    for (final MapEntry(key: phone, value: size) in _phones.entries) {
      for (final brightness in Brightness.values) {
        testWidgets('$name fits a $phone phone in ${brightness.name}, nothing overflows', (tester) async {
          await _pumpScreen(tester, build(), size, brightness);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('the check-in carries the real copy and the streak', (tester) async {
    await _pumpScreen(tester, const CheckinPreviewScreen(), const Size(390, 844), Brightness.light);
    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('What’s this morning for?'), findsOneWidget);
    expect(find.text('4 days in a row'), findsOneWidget);
    expect(find.text('23 out of sight'), findsOneWidget);
    expect(find.byType(PeekMascot), findsOneWidget);
  });

  testWidgets('Home with a plan has no mascot and keeps the essentials where the check-in has them', (tester) async {
    await _pumpScreen(tester, const CheckinPreviewScreen(), const Size(390, 844), Brightness.light);
    final dockOnCheckin = tester.getRect(find.text('23 out of sight'));
    await _pumpScreen(tester, const HomePreviewScreen(), const Size(390, 844), Brightness.light);
    expect(find.byType(PeekMascot), findsNothing);
    expect(tester.getRect(find.text('23 out of sight')), dockOnCheckin);
  });

  testWidgets('the gate never shows Peek, in either state', (tester) async {
    await _pumpScreen(tester, const GatePreviewScreen(), const Size(390, 844), Brightness.dark);
    expect(find.byType(PeekMascot), findsNothing);
    expect(find.text('Open Instagram\u00A0→\u00A0Messages'), findsOneWidget);
    await _pumpScreen(tester, const WaitPreviewScreen(), const Size(390, 844), Brightness.dark);
    expect(find.byType(PeekMascot), findsNothing);
    expect(find.byType(RisingDisc), findsOneWidget);
  });

  testWidgets('every door of the plan rises on the reveal with its link number', (tester) async {
    await _pumpScreen(tester, const RevealPreviewScreen(plan: longPlan), const Size(390, 844), Brightness.light);
    expect(find.byType(DoorRow), findsNWidgets(longPlan.doors.length));
  });
}
