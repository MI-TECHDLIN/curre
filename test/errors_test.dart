import 'dart:async';
import 'dart:convert';

import 'package:curre/app/checkin_screen.dart';
import 'package:curre/app/settings_screen.dart';
import 'package:curre/app/unlock_gate_screen.dart';
import 'package:curre/core/core.dart';
import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

/// A plan the planner might send back for the G chord sentence.
final _planBody = jsonEncode(<String, Object?>{
  'apps': <Object?>[
    <String, Object?>{
      'id': 'com.google.android.youtube',
      'query': <String, Object?>{'text': 'G chord', 'start': 10, 'end': 17},
    },
  ],
  'end_phrase': null,
  'usage': <String, Object?>{'credits': 4, 'model_ms': 90},
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> show(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
          ),
          child: screen,
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  CurreApiClient api(Future<http.Response> Function(http.Request) plan) =>
      CurreApiClient(
        baseUrl: Uri.parse('https://curre.test'),
        appKey: 'test-key',
        planTimeout: const Duration(milliseconds: 600),
        planFirstAttemptTimeout: const Duration(milliseconds: 300),
        planRetryDelay: Duration.zero,
        httpClient: MockClient((request) async {
          if (request.method == 'GET') return http.Response('{}', 200);
          return plan(request);
        }),
      );

  Future<void> planGChord(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('checkin-intention')),
      'Learn the G chord on YouTube till 7',
    );
    await tester.pump();
    await tester.tap(find.text('Set my morning'));
    await tester.pump();
    await waitFor(tester, find.text('Choose the apps yourself'));
  }

  group('when a plan can’t be made, Curre says why and what to do', () {
    for (final (name, respond, headline, body)
        in <
          (String, Future<http.Response> Function(http.Request), String, String)
        >[
          (
            'offline',
            (_) async => throw http.ClientException('Network is unreachable'),
            'Couldn’t connect just now',
            'Check your internet and try again, or choose the apps yourself below.',
          ),
          (
            'too slow',
            (_) => Future<http.Response>.delayed(
              const Duration(seconds: 2),
              () => http.Response(_planBody, 200),
            ),
            'That took too long',
            'Try again in a moment, or choose the apps yourself below.',
          ),
          (
            'refused',
            (_) async => http.Response('unavailable', 503),
            'Curre couldn’t plan that just now',
            'Try again in a moment, or choose the apps yourself below.',
          ),
          (
            'garbled',
            (_) async => http.Response('{"apps": "?"}', 200),
            'Curre couldn’t read that plan',
            'Try again in a moment, or choose the apps yourself below.',
          ),
        ]) {
      testWidgets(name, (tester) async {
        final controller = fakeController(api: api(respond));
        await show(tester, CheckinScreen(controller: controller));
        await planGChord(tester);
        await tester.pump(const Duration(seconds: 3));

        expect(find.text(headline), findsOneWidget);
        expect(find.text(body), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(find.text('Use these apps'), findsOneWidget);
      });
    }

    testWidgets('Try again plans once the problem clears', (tester) async {
      var online = false;
      final controller = fakeController(
        api: api((_) async {
          if (!online) throw http.ClientException('Network is unreachable');
          return http.Response(_planBody, 200);
        }),
      );
      await show(tester, CheckinScreen(controller: controller));
      await planGChord(tester);
      expect(find.text('Couldn’t connect just now'), findsOneWidget);

      online = true;
      await tester.ensureVisible(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await waitFor(tester, find.text('Here’s your plan'));
      expect(find.text('Here’s your plan'), findsOneWidget);
      expect(find.text('→ Search “G chord”'), findsOneWidget);
    });
  });

  testWidgets('Settings says so when a change can’t be saved', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = FailingStore(await SharedPreferences.getInstance());
    final controller = fakeController(store: store);
    await show(tester, SettingsScreen(controller: controller));

    final name = find.widgetWithText(TextField, 'Name in your greeting');
    await tester.scrollUntilVisible(
      name,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(name, 'Ada');
    await tester.ensureVisible(find.text('Save name'));
    await tester.tap(find.text('Save name'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Curre couldn’t save that on this phone. Please try again.'),
      findsOneWidget,
    );
    expect(controller.settings.displayName, 'Chidi');

    store.failSaves = false;
    // Bring the button back down from under the top bar.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 200));
    await tester.pump();
    await tester.tap(find.text('Save name'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.settings.displayName, 'Ada');
  });

  testWidgets('Why now? falls back to a short wait when it can’t check', (
    tester,
  ) async {
    final controller = fakeController(
      api: CurreApiClient(
        baseUrl: Uri.parse('https://curre.test'),
        appKey: 'test-key',
        httpClient: MockClient(
          (_) async => throw http.ClientException('Network is unreachable'),
        ),
      ),
    );
    final app = controller.apps.firstWhere((app) => app.label == 'Instagram');
    await show(
      tester,
      UnlockGateScreen(
        controller: controller,
        app: app,
        overrideDuration: const Duration(minutes: 1),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('unlock-reason')),
      'reply Ada about rehearsal',
    );
    await tester.pump();
    await tester.tap(find.text('Bring it back'));
    await tester.pump();
    await waitFor(tester, find.text('Instagram opens in 30 seconds'));

    // The user is never stuck: the wait starts on its own, with a retry.
    expect(find.text('Instagram opens in 30 seconds'), findsOneWidget);
    expect(
      find.text(
        'Curre couldn’t check your reason, so it opens after a short wait instead.',
      ),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  group('a slow first call says things are getting ready', () {
    CurreApiClient asleep(Future<http.Response> Function(http.Request) post) =>
        CurreApiClient(
          baseUrl: Uri.parse('https://curre.test'),
          appKey: 'test-key',
          planRetryDelay: Duration.zero,
          httpClient: MockClient((request) async {
            // The warm-up ping never gets an answer from a sleeping host.
            if (request.method == 'GET') {
              throw http.ClientException('Connection closed');
            }
            return post(request);
          }),
        );

    Future<void> setMorning(WidgetTester tester) async {
      await tester.enterText(
        find.byKey(const Key('checkin-intention')),
        'Learn the G chord on YouTube till 7',
      );
      await tester.pump();
      await tester.tap(find.text('Set my morning'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('and waits past the usual time for the plan', (tester) async {
      final controller = fakeController(
        api: asleep(
          // A sleeping free host took about 13 s to answer its first plan.
          (_) => Future<http.Response>.delayed(
            const Duration(seconds: 13),
            () => http.Response(_planBody, 200),
          ),
        ),
      );
      await show(tester, CheckinScreen(controller: controller));
      await setMorning(tester);

      expect(find.text('Getting things ready…'), findsOneWidget);
      expect(find.text('This can take a few more seconds.'), findsOneWidget);
      expect(find.textContaining('Looking through your'), findsNothing);

      // Past the usual 12 s plan budget, still waiting calmly.
      await tester.pump(const Duration(seconds: 12));
      expect(find.text('Getting things ready…'), findsOneWidget);
      expect(find.text('That took too long'), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      await waitFor(tester, find.text('Here’s your plan'));
      expect(find.text('Here’s your plan'), findsOneWidget);
      expect(controller.waking.value, isFalse);
    });

    testWidgets('and still falls back when the wait runs out', (tester) async {
      final controller = fakeController(
        api: asleep((_) => Completer<http.Response>().future),
      );
      await show(tester, CheckinScreen(controller: controller));
      await setMorning(tester);
      expect(find.text('Getting things ready…'), findsOneWidget);

      await tester.pump(const Duration(seconds: 29));
      expect(find.text('That took too long'), findsNothing);

      // The client's budget runs on a real stopwatch, so under the test's
      // fake clock the retry outlasts 30 s; the unit tests pin the total.
      for (
        var i = 0;
        i < 40 && find.text('That took too long').evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.text('That took too long'), findsOneWidget);
      expect(find.text('Use these apps'), findsOneWidget);
      expect(controller.waking.value, isFalse);
    });

    testWidgets('while Why now? reads a reason', (tester) async {
      final controller = fakeController(
        api: asleep(
          (_) => Future<http.Response>.delayed(
            const Duration(seconds: 13),
            () => http.Response('unavailable', 503),
          ),
        ),
      );
      final app = controller.apps.firstWhere((app) => app.label == 'Instagram');
      await show(
        tester,
        UnlockGateScreen(
          controller: controller,
          app: app,
          overrideDuration: const Duration(minutes: 1),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('unlock-reason')),
        'reply Ada about rehearsal',
      );
      await tester.pump();
      await tester.tap(find.text('Bring it back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Getting things ready…'), findsOneWidget);
      expect(find.text('Reading your reason…'), findsNothing);

      await tester.pump(const Duration(seconds: 14));
      await waitFor(tester, find.text('Instagram opens in 30 seconds'));
      expect(find.text('Instagram opens in 30 seconds'), findsOneWidget);
    });
  });
}
