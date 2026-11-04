import 'dart:convert';

import 'package:curre/core/core.dart';
import 'package:curre/doors/door_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fakes.dart';

PlanAppInfo _app(
  String id,
  String label, {
  List<String> shortcuts = const <String>[],
  bool queryDoor = false,
}) =>
    (id: id, label: label, shortcutLabels: shortcuts, hasQueryDoor: queryDoor);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('cleanApiLabel', () {
    test('collapses whitespace and cuts to 60 code points', () {
      expect(cleanApiLabel('  Bank\n of   Lagos '), 'Bank of Lagos');
      expect(cleanApiLabel('x' * 61), 'x' * 60);
      // Emoji count once each, as the server counts them.
      expect(cleanApiLabel('😀' * 70)!.runes.length, 60);
    });

    test('is null when nothing usable is left', () {
      expect(cleanApiLabel(''), isNull);
      expect(cleanApiLabel(' \n\t '), isNull);
    });
  });

  test('cleanShortcutLabels drops empty, long, repeated and reserved', () {
    expect(
      cleanShortcutLabels(<String>[
        '',
        'Search',
        '   ',
        'x' * 61,
        'Search',
        ' New\nchat ',
        'The app itself',
        'app',
      ]),
      <String>['Search', 'New chat'],
    );
    expect(
      cleanShortcutLabels(List<String>.generate(20, (i) => 'S$i')),
      hasLength(maxShortcutLabels),
    );
  });

  group('planCandidatesFrom', () {
    test('leaves out empty and repeated ids and blank labels', () {
      final candidates = planCandidatesFrom(<PlanAppInfo>[
        _app('a', 'Maps'),
        _app('a', 'Maps again'),
        _app('', 'No id'),
        _app('  ', 'Blank id'),
        _app('c', '  '),
        _app('d', 'Notes', shortcuts: <String>['', 'New note', 'New note']),
      ]);

      expect(candidates.map((c) => c.id), <String>['a', 'd']);
      expect(candidates.last.shortcutLabels, <String>['New note']);
    });

    test('numbers repeated labels and keeps them within 60', () {
      final long = 'L' * 70;
      final candidates = planCandidatesFrom(<PlanAppInfo>[
        _app('a', 'Notes'),
        _app('b', 'Notes'),
        _app('c', 'Notes 2'),
        _app('d', long),
        _app('e', long),
      ]);

      expect(candidates.map((c) => c.label), <String>[
        'Notes',
        'Notes 2',
        'Notes 2 2',
        'L' * 60,
        '${'L' * 58} 2',
      ]);
    });

    test('keeps at most 30 apps so the request is still valid', () {
      final candidates = planCandidatesFrom(
        List<PlanAppInfo>.generate(45, (i) => _app('id$i', 'App $i')),
      );

      expect(candidates, hasLength(maxPlanCandidates));
      expect(
        () => PlanRequest(
          session: SessionName.morning,
          intention: 'write',
          candidates: candidates,
        ),
        returnsNormally,
      );
    });
  });

  group('rejectedFieldNames', () {
    test('keeps field paths and codes, never the rejected values', () {
      final body = jsonEncode(<String, Object?>{
        'detail': <Object?>[
          <String, Object?>{
            'type': 'string_too_long',
            'loc': <Object?>['body', 'candidates', 3, 'label'],
            'msg': 'String should have at most 60 characters',
            'input': 'my secret plan',
          },
          <String, Object?>{
            'type': 'value_error',
            'loc': <Object?>['body', 'intention words here'],
            'input': 'call Ada on 0803',
          },
        ],
      });

      final names = rejectedFieldNames(body);

      expect(names, <String>[
        'candidates.3.label:string_too_long',
        '?:value_error',
      ]);
      expect(names.join(), isNot(contains('secret')));
      expect(names.join(), isNot(contains('Ada')));
    });

    test('is empty for anything that is not a validation answer', () {
      expect(rejectedFieldNames('not json'), isEmpty);
      expect(rejectedFieldNames('{"detail": "invalid key"}'), isEmpty);
      expect(rejectedFieldNames('[]'), isEmpty);
    });
  });

  group('the controller sends odd apps in a form the server accepts', () {
    final apps = <LaunchableApp>[
      for (var i = 0; i < 40; i++)
        LaunchableApp(packageName: 'com.example.app$i', label: 'App $i'),
      LaunchableApp(packageName: 'com.example.long', label: 'Long ' * 20),
      const LaunchableApp(packageName: 'com.example.blank', label: '  '),
      const LaunchableApp(packageName: 'com.example.twin', label: 'App 1'),
    ];
    final shortcuts = <AppShortcut>[
      for (final label in <String>['', 'Search', 'x' * 61, 'Search'])
        AppShortcut(
          packageName: 'com.example.app0',
          id: 'shortcut-${label.length}',
          shortLabel: label,
        ),
    ];

    test('plan request', () async {
      Map<String, Object?>? sent;
      final api = CurreApiClient(
        baseUrl: Uri.parse('https://curre.test'),
        appKey: 'test-key',
        planRetryDelay: Duration.zero,
        httpClient: MockClient((request) async {
          if (request.url.path != '/v1/plan') return http.Response('{}', 200);
          sent = jsonDecode(request.body) as Map<String, Object?>;
          return http.Response(
            jsonEncode(<String, Object?>{
              'apps': <Object?>[
                <String, Object?>{'id': 'com.example.app0', 'door': 'Search'},
              ],
              'usage': <String, Object?>{'credits': 4, 'model_ms': 80},
            }),
            200,
          );
        }),
      );
      final controller = fakeController(
        api: api,
        platform: FakeDoorPlatform(apps: apps, staticShortcuts: shortcuts),
        settings: Settings(
          candidates: apps.map((app) => app.packageName).toSet(),
        ),
      );

      final result = await controller.buildPlan('find a song on App 0');

      expect(result.requiresManualChecklist, isFalse);
      final candidates = (sent!['candidates']! as List)
          .cast<Map<String, Object?>>();
      expect(candidates, hasLength(maxPlanCandidates));
      final labels = candidates.map((c) => c['label']! as String).toList();
      expect(labels.toSet(), hasLength(labels.length));
      expect(labels.every((label) => label.runes.length <= 60), isTrue);
      expect(labels, isNot(contains('')));
      final app0 = candidates.firstWhere((c) => c['id'] == 'com.example.app0');
      expect(app0['shortcut_labels'], <String>['Search']);
    });

    test('unlock request', () async {
      Map<String, Object?>? sent;
      final api = CurreApiClient(
        baseUrl: Uri.parse('https://curre.test'),
        appKey: 'test-key',
        httpClient: MockClient((request) async {
          sent = jsonDecode(request.body) as Map<String, Object?>;
          return http.Response('{"outcome": "unavailable"}', 200);
        }),
      );
      final controller = fakeController(
        api: api,
        platform: FakeDoorPlatform(apps: apps, staticShortcuts: shortcuts),
      );

      await controller.judgeUnlock(
        app: LaunchableApp(
          packageName: 'com.example.app0',
          label: 'Long ' * 20,
        ),
        reason: 'look up the G chord',
      );

      expect(sent!['app_label'], ('Long ' * 12).trimRight());
      expect(sent!['shortcut_labels'], <String>['Search']);
    });
  });
}
