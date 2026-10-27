import 'dart:convert';

import 'package:curre/app/checkin_screen.dart';
import 'package:curre/app/unlock_gate_screen.dart';
import 'package:curre/core/core.dart';
import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 26, 6, 40);
  final items = <LaterItem>[
    _item(
      'instagram',
      'com.instagram.android',
      'Instagram',
      'see what Tolu posted',
      now.subtract(const Duration(hours: 4)),
    ),
    _item(
      'spotify',
      'com.spotify.music',
      'Spotify',
      'play the guitar cover',
      now.subtract(const Duration(hours: 3)),
    ),
    _item(
      'maps',
      'com.google.android.apps.maps',
      'Maps',
      'find a bread shop',
      now.subtract(const Duration(hours: 2)),
    ),
    _item(
      'gmail',
      'com.google.android.gm',
      'Gmail',
      'write the note',
      now.subtract(const Duration(hours: 1)),
    ),
  ];

  Future<void> showPlan(
    WidgetTester tester, {
    required Future<http.Response> Function(http.Request) respond,
  }) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = CurreApiClient(
      baseUrl: Uri.parse('https://curre.test'),
      appKey: 'test-key',
      planRetryDelay: Duration.zero,
      httpClient: MockClient(respond),
    );
    final controller = fakeController(api: api, laterItems: items, now: now);
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 1400),
            disableAnimations: true,
          ),
          child: CheckinScreen(controller: controller),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('checkin-intention')),
      'Practice music and write this morning',
    );
    await tester.pump();
    await tester.tap(find.text('Set my morning'));
    for (
      var tick = 0;
      tick < 20 && find.byKey(const Key('later-shelf')).evaluate().isEmpty;
      tick++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  http.Response planResponse() => http.Response(
    jsonEncode(<String, Object?>{
      'apps': <Object?>[
        <String, Object?>{'id': 'com.google.android.youtube'},
      ],
      'end_phrase': null,
      'usage': <String, Object?>{'credits': 4, 'model_ms': 80},
    }),
    200,
  );

  testWidgets('check-in applies the plan-specific order and hides skips', (
    tester,
  ) async {
    await showPlan(
      tester,
      respond: (request) async {
        if (request.method == 'GET') return http.Response('{}', 200);
        if (request.url.path == '/v1/plan') return planResponse();
        expect(request.url.path, '/v1/later');
        return http.Response(
          jsonEncode(<String, Object?>{
            'items': <Object?>[
              <String, Object?>{'id': 'spotify', 'score': .98, 'fits': true},
              <String, Object?>{'id': 'maps', 'score': .8, 'fits': false},
              <String, Object?>{'id': 'instagram', 'score': .7, 'fits': true},
              <String, Object?>{'id': 'gmail', 'score': .6, 'fits': true},
            ],
            'usage': <String, Object?>{'credits': 2, 'model_ms': 38},
          }),
          200,
        );
      },
    );

    expect(find.text('Best match for this plan first.'), findsOneWidget);
    expect(find.byKey(const ValueKey('later-maps')), findsNothing);
    final spotify = tester.getTopLeft(
      find.byKey(const ValueKey('later-spotify')),
    );
    final instagram = tester.getTopLeft(
      find.byKey(const ValueKey('later-instagram')),
    );
    final gmail = tester.getTopLeft(find.byKey(const ValueKey('later-gmail')));
    expect(spotify.dy, lessThan(instagram.dy));
    expect(instagram.dy, lessThan(gmail.dy));
    expect(find.text('1 more keeps for another time.'), findsOneWidget);
    expect(find.text('Not today'), findsOneWidget);
  });

  testWidgets('Not now can save the app, reason, and extracted words', (
    tester,
  ) async {
    final controller = fakeController(now: now);
    final app = controller.apps.firstWhere(
      (candidate) => candidate.packageName == 'com.instagram.android',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: UnlockGateScreen(
          controller: controller,
          app: app,
          initialReason: 'see what Tolu posted',
          initialResponse: const UnlockResponse(
            outcome: UnlockOutcome.later,
            kind: ReasonKind.browse,
            confidence: .9,
            target: SourceSpan(text: 'what Tolu posted', start: 4, end: 20),
            redactions: <Redaction>[
              Redaction(kind: PersonalDetailKind.person, start: 9, end: 13),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save for later'));
    await tester.pump();

    expect(controller.laterItems, hasLength(1));
    final saved = controller.laterItems.single;
    expect(saved.packageName, 'com.instagram.android');
    expect(saved.reason, 'see what Tolu posted');
    expect(saved.target?.text, 'what Tolu posted');
    expect(saved.redactions?.single.kind, PersonalDetailKind.person);
  });

  testWidgets('a ranking failure quietly falls back to newest first', (
    tester,
  ) async {
    await showPlan(
      tester,
      respond: (request) async {
        if (request.method == 'GET') return http.Response('{}', 200);
        if (request.url.path == '/v1/plan') return planResponse();
        return http.Response('unavailable', 503);
      },
    );

    expect(find.text('Newest first.'), findsOneWidget);
    final gmail = tester.getTopLeft(find.byKey(const ValueKey('later-gmail')));
    final maps = tester.getTopLeft(find.byKey(const ValueKey('later-maps')));
    final spotify = tester.getTopLeft(
      find.byKey(const ValueKey('later-spotify')),
    );
    expect(gmail.dy, lessThan(maps.dy));
    expect(maps.dy, lessThan(spotify.dy));
    expect(find.byKey(const ValueKey('later-instagram')), findsNothing);
    expect(find.textContaining('couldn’t'), findsNothing);
  });
}

LaterItem _item(
  String id,
  String packageName,
  String appLabel,
  String reason,
  DateTime savedAt,
) => LaterItem(
  id: id,
  packageName: packageName,
  appLabel: appLabel,
  reason: reason,
  target: SourceSpan(text: reason, start: 0, end: reason.runes.length),
  savedAt: savedAt,
);
