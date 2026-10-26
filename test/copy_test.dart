import 'dart:io';

import 'package:curre/app/checkin_screen.dart';
import 'package:curre/app/hidden_apps_screen.dart';
import 'package:curre/app/history_screen.dart';
import 'package:curre/app/home_screen.dart';
import 'package:curre/app/settings_screen.dart';
import 'package:curre/app/unlock_gate_screen.dart';
import 'package:curre/core/core.dart';
import 'package:curre/design/design.dart';
import 'package:curre/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/copy_rules.dart';
import 'support/fakes.dart';

/// Source files that hold no words a user sees: stored and sent field
/// names (lib/core), and the debug-only Door Lab and design gallery, which
/// main.dart registers only under kDebugMode.
bool _userFacing(String path) =>
    !path.startsWith('lib/core/') &&
    !path.startsWith('lib/gallery/') &&
    path != 'lib/doors/door_lab_screen.dart' &&
    // The wording of the timer notification belongs to the notifications
    // work running alongside this one.
    path != 'lib/platform/grant_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('no string in the app uses a banned word', () {
    final problems = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.path.replaceAll(r'\', '/'))
        .where(_userFacing);
    for (final path in files) {
      for (final literal in stringLiterals(File(path).readAsStringSync())) {
        for (final word in bannedWordsIn(literal)) {
          problems.add('$path: “$word” in “$literal”');
        }
      }
    }
    expect(problems, isEmpty);
  });

  test('the literal reader finds nested and interpolated strings', () {
    const source = r'''
// It's a comment with a 'quote'.
import 'package:x/y.dart';
final a = 'Bring back ${app.label} now';
final b = "${n == 1 ? 'one app' : '$n apps'} left";
final c = Key('override-countdown');
/* 'hidden' */ final d = r'raw \d';
''';
    expect(stringLiterals(source), [
      'Bring back … now',
      '… left',
      'one app',
      '… apps',
      r'raw \d',
    ]);
  });

  test('the rules catch jargon, not ordinary words', () {
    expect(bannedWordsIn('23 apps out of sight'), ['out of sight']);
    expect(bannedWordsIn('Sent to Clocked · Fill + Extract'), [
      'Clocked',
      'Extract',
      'Fill',
    ]);
    expect(bannedWordsIn('Endpoint map, last latency and credits'), [
      'endpoint',
      'credits?',
      'latency',
    ]);
    expect(bannedWordsIn('Filled ones started with a plan'), isEmpty);
    expect(bannedWordsIn('Find an insight in the apps you planned'), isEmpty);
  });

  group('screens read in plain words', () {
    Future<void> show(
      WidgetTester tester,
      Widget screen, {
      Brightness brightness = Brightness.light,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: curreTheme(brightness),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: screen,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('every onboarding step', (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final home = FakeHomePlatform(isHome: false);
      final controller = fakeController(
        onboardingComplete: false,
        settings: Settings(),
        home: home,
        platform: FakeDoorPlatform(home: home),
      );
      await tester.pumpWidget(CurreApp(controller: controller));
      await tester.pump();

      Future<void> tap(String text) async {
        await tester.ensureVisible(find.text(text).last);
        await tester.tap(find.text(text).last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
      }

      Future<void> check(int step) async =>
          expectPlainCopy(tester, where: 'onboarding step $step');

      await check(1);
      await tap('Show me how');
      await check(2);
      await tap('Sounds fair');
      await tap('Instagram');
      await check(3);
      await tap('This one pulls me in');
      await tester.enterText(find.byType(TextField), 'Ada');
      await tester.pump();
      await check(4);
      await tap('Call me Ada');
      await check(5);
      await tap('Use my initial');
      await check(6);
      await tap('Mornings start at 04:00');
      await check(7);
      await tap('Make Curre my home screen');
      await check(7);
      await tap('Continue');
      await check(8);
      await tap('Allow');
      await check(8);
      await tap('Skip for now');
      await check(9);
      await tap('Allow');
      await check(9);
      await tap('Skip for now');
      await check(10);
      await tap('Not now');
      await check(11);
      final use = find.textContaining(RegExp(r'^Use these \d+ apps$'));
      await tap(tester.widget<Text>(use).data!);
      await check(12);
      semantics.dispose();
    });

    testWidgets('Home, Hidden apps, settings and the profile', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = fakeController();
      controller.grants = <Grant>[
        Grant(
          packageName: 'com.instagram.android',
          reason: 'reply Ada about rehearsal',
          task: 'Ada',
          grantedAt: controller.now.subtract(const Duration(minutes: 2)),
          expiresAt: controller.now.add(const Duration(minutes: 8)),
          source: GrantSource.clocked,
          kind: ReasonKind.person,
        ),
      ];
      await show(tester, HomeScreen(controller: controller));
      expectPlainCopy(tester, where: 'Home');
      await show(tester, HiddenAppsScreen(controller: controller));
      expect(
        visibleCopy(tester),
        containsAll(<String>['Hidden apps', 'Bring back Chrome']),
      );
      expectPlainCopy(tester, where: 'Hidden apps');
      await show(tester, SettingsScreen(controller: controller));
      for (var i = 0; i < 6; i++) {
        expectPlainCopy(tester, where: 'Curre settings');
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
        await tester.pump();
      }
      await show(tester, ProfileSheet(controller: controller));
      expectPlainCopy(tester, where: 'the profile');
      semantics.dispose();
    });

    testWidgets('planning, including when it goes wrong', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = fakeController();
      await show(tester, CheckinScreen(controller: controller));
      expectPlainCopy(tester, where: 'the plan screen');
      await tester.enterText(
        find.byKey(const Key('checkin-intention')),
        'Learn the G chord on YouTube till 7',
      );
      await tester.pump();
      await tester.tap(find.text('Set my morning'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Choose the apps yourself'), findsOneWidget);
      expectPlainCopy(tester, where: 'the plan fallback');
      semantics.dispose();
    });

    testWidgets('Why now? in every outcome', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = fakeController();
      final app = controller.apps.firstWhere((app) => app.label == 'Instagram');
      await show(
        tester,
        UnlockGateScreen(controller: controller, app: app),
      );
      expectPlainCopy(tester, where: 'Why now?');
      for (final response in <UnlockResponse>[
        const UnlockResponse(
          outcome: UnlockOutcome.open,
          kind: ReasonKind.person,
          confidence: .9,
          person: SourceSpan(text: 'Ada', start: 6, end: 9),
          minutes: 5,
        ),
        const UnlockResponse(
          outcome: UnlockOutcome.later,
          kind: ReasonKind.browse,
          confidence: .9,
        ),
        const UnlockResponse(
          outcome: UnlockOutcome.specify,
          kind: ReasonKind.unclear,
          confidence: .5,
        ),
        const UnlockResponse(
          outcome: UnlockOutcome.flagged,
          guard: GuardInfo(
            category: 'instruction override',
            quote: SourceSpan(text: 'ignore your rules', start: 0, end: 17),
          ),
        ),
        const UnlockResponse.unavailable(),
      ]) {
        await show(
          tester,
          UnlockGateScreen(
            key: ValueKey(response.outcome),
            controller: controller,
            app: app,
            initialReason: 'reply Ada about rehearsal',
            initialResponse: response,
          ),
        );
        expectPlainCopy(tester, where: 'Why now? (${response.outcome.name})');
        final wait = find.text('Open after a minute');
        if (wait.evaluate().isNotEmpty) {
          await tester.ensureVisible(wait);
          await tester.tap(wait);
          await tester.pump(const Duration(milliseconds: 300));
          expectPlainCopy(
            tester,
            where: 'the wait after ${response.outcome.name}',
          );
        }
      }
      semantics.dispose();
    });

    testWidgets('History with plans, reasons and returns', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = fakeController();
      controller.historyPlans = <Plan>[
        Plan(
          id: 'history-plan',
          session: SessionName.morning,
          date: const LocalDate(2026, 10, 26),
          intention: 'Learn the G chord on YouTube till 7',
          apps: const <PlannedApp>[
            PlannedApp(packageName: 'com.google.android.youtube'),
          ],
          endsAt: DateTime(2026, 10, 26, 7),
          source: PlanSource.clocked,
        ),
      ];
      controller.historyAttempts = <Attempt>[
        for (final outcome in UnlockOutcome.values)
          Attempt(
            at: DateTime(2026, 10, 26, 6, outcome.index),
            packageName: 'com.instagram.android',
            outcome: outcome,
            confidence: .9,
            overridden: outcome == UnlockOutcome.later,
            kind: ReasonKind.browse,
            reason: 'just checking',
          ),
      ];
      controller.historyGrants = <Grant>[
        Grant(
          packageName: 'com.instagram.android',
          reason: 'just checking',
          task: null,
          grantedAt: DateTime(2026, 10, 26, 6, 10),
          expiresAt: DateTime(2026, 10, 26, 6, 11),
          source: GrantSource.override,
        ),
      ];
      await show(tester, HistoryScreen(controller: controller));
      for (var i = 0; i < 8; i++) {
        expectPlainCopy(tester, where: 'History');
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
        await tester.pump();
      }
      semantics.dispose();
    });
  });
}

/// The string literals in Dart [source], with interpolations shown as "…"
/// and the strings inside them listed on their own. Comments, directives
/// and widget keys are skipped.
List<String> stringLiterals(String source) {
  final found = <String>[];
  var i = 0;

  bool startsAt(String text, int at) => source.startsWith(text, at);

  // Reads the literal opening at [start]; returns the index after it.
  int readString(int start) {
    final raw = start > 0 && source[start - 1] == 'r';
    final quoteChar = source[start];
    final quote = startsAt(quoteChar * 3, start) ? quoteChar * 3 : quoteChar;
    final text = StringBuffer();
    final nested = <String>[];
    var j = start + quote.length;
    while (j < source.length && !startsAt(quote, j)) {
      if (!raw && source[j] == r'\') {
        text.write(source.substring(j, j + 2));
        j += 2;
      } else if (!raw && startsAt(r'${', j)) {
        text.write('…');
        var depth = 1;
        j += 2;
        while (j < source.length && depth > 0) {
          final c = source[j];
          if (c == "'" || c == '"') {
            final before = found.length;
            j = readString(j);
            nested.addAll(found.sublist(before));
            found.removeRange(before, found.length);
            continue;
          }
          if (c == '{') depth++;
          if (c == '}') depth--;
          j++;
        }
      } else if (!raw &&
          source[j] == r'$' &&
          j + 1 < source.length &&
          RegExp('[A-Za-z_]').hasMatch(source[j + 1])) {
        text.write('…');
        j++;
        while (j < source.length && RegExp(r'\w').hasMatch(source[j])) {
          j++;
        }
      } else {
        text.write(source[j]);
        j++;
      }
    }
    final before = source.substring(0, start);
    final isKey = RegExp(r'Key\(\s*$').hasMatch(before);
    if (!isKey) found.add(text.toString());
    found.addAll(nested);
    return j + quote.length;
  }

  while (i < source.length) {
    if (startsAt('//', i)) {
      final end = source.indexOf('\n', i);
      i = end < 0 ? source.length : end;
    } else if (startsAt('/*', i)) {
      final end = source.indexOf('*/', i);
      i = end < 0 ? source.length : end + 2;
    } else if (RegExp(r'(import|export|part|library)\b').matchAsPrefix(
              source,
              i,
            ) !=
            null &&
        (i == 0 || source[i - 1] == '\n')) {
      final end = source.indexOf(';', i);
      i = end < 0 ? source.length : end + 1;
    } else if (source[i] == "'" || source[i] == '"') {
      i = readString(i);
    } else {
      i++;
    }
  }
  return found;
}
