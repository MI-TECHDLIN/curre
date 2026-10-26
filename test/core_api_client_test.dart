import 'dart:async';
import 'dart:convert';

import 'package:curre/core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  PlanRequest planRequest() => PlanRequest(
    session: SessionName.morning,
    intention: 'learn 😀 guitar till 8',
    candidates: <PlanCandidate>[
      PlanCandidate(
        id: 'yt',
        label: 'YouTube',
        shortcutLabels: const <String>['Search'],
        hasQueryDoor: true,
      ),
      PlanCandidate(id: 'maps', label: 'Maps'),
    ],
  );

  UnlockRequest unlockRequest() => UnlockRequest(
    appLabel: 'YouTube',
    planIntention: 'learn guitar',
    reason: '15 min to watch 😀 guitar',
    shortcutLabels: const <String>['Search'],
  );

  CurreApiClient client(
    http.Client transport, {
    Duration timeout = const Duration(milliseconds: 100),
    Duration firstAttemptTimeout = const Duration(milliseconds: 75),
    Duration retryDelay = Duration.zero,
    Duration warmUpTimeout = const Duration(milliseconds: 100),
    Map<String, String> localTestingHeaders = const <String, String>{},
  }) => CurreApiClient(
    baseUrl: Uri.parse('https://api.example.test/root/'),
    appKey: 'app-secret',
    httpClient: transport,
    planTimeout: timeout,
    planFirstAttemptTimeout: firstAttemptTimeout,
    planRetryDelay: retryDelay,
    warmUpTimeout: warmUpTimeout,
    localTestingHeaders: localTestingHeaders,
    unlockTimeout: timeout,
  );

  test('plan sends the exact backend shape and parses spans', () async {
    final transport = MockClient((request) async {
      expect(request.url.toString(), 'https://api.example.test/root/v1/plan');
      expect(request.headers['x-app-key'], 'app-secret');
      expect(request.headers['ngrok-skip-browser-warning'], isNull);
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['session'], 'morning');
      expect(body['intention'], 'learn 😀 guitar till 8');
      expect(body['candidates'], <Object?>[
        <String, Object?>{
          'id': 'yt',
          'label': 'YouTube',
          'shortcut_labels': <String>['Search'],
          'query_door': true,
        },
        <String, Object?>{
          'id': 'maps',
          'label': 'Maps',
          'shortcut_labels': <String>[],
          'query_door': false,
        },
      ]);
      return _jsonResponse(<String, Object?>{
        'apps': <Object?>[
          <String, Object?>{
            'id': 'yt',
            'door': 'Search',
            'query': <String, Object?>{
              'text': '😀 guitar',
              'start': 6,
              'end': 14,
            },
          },
        ],
        'end_phrase': <String, Object?>{
          'text': 'till 8',
          'start': 15,
          'end': 21,
        },
        'usage': <String, Object?>{'credits': 3, 'model_ms': 27.5},
      });
    });

    final result = await client(transport).plan(planRequest());

    expect(result.requiresManualChecklist, isFalse);
    expect(result.response!.apps.single.id, 'yt');
    expect(result.response!.apps.single.query!.text, '😀 guitar');
    expect(
      result.response!.endTextFromIntention('learn 😀 guitar till 8'),
      'till 8',
    );
    expect(result.response!.usage.modelMilliseconds, 27.5);
  });

  test(
    'plan maps timeout, HTTP errors, and malformed JSON to checklist',
    () async {
      final timeout = Completer<http.Response>();
      final timedOut = await client(
        MockClient((_) => timeout.future),
        timeout: const Duration(milliseconds: 5),
      ).plan(planRequest());
      expect(timedOut.fallbackReason, PlanFallbackReason.timeout);

      final failed = await client(
        MockClient((_) async => http.Response('busy', 503)),
      ).plan(planRequest());
      expect(failed.fallbackReason, PlanFallbackReason.http);

      final malformed = await client(
        MockClient((_) async => http.Response('{"apps":[]}', 200)),
      ).plan(planRequest());
      expect(malformed.fallbackReason, PlanFallbackReason.invalidResponse);
    },
  );

  test(
    'plan retries a transient first failure with one idempotency key',
    () async {
      var calls = 0;
      final idempotencyKeys = <String>[];
      final transport = MockClient((request) async {
        calls++;
        idempotencyKeys.add(request.headers['idempotency-key']!);
        if (calls == 1) return http.Response('waking', 503);
        return _jsonResponse(<String, Object?>{
          'apps': <Object?>[
            <String, Object?>{'id': 'yt', 'door': null, 'query': null},
          ],
          'end_phrase': null,
          'usage': <String, Object?>{'credits': 3, 'model_ms': 24},
        });
      });

      final result = await client(transport).plan(planRequest());

      expect(result.requiresManualChecklist, isFalse);
      expect(calls, 2);
      final uniqueKeys = idempotencyKeys.toSet();
      expect(uniqueKeys, hasLength(1));
      expect(
        uniqueKeys.single,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    },
  );

  test('plan retries a tunnel HTML interstitial before parsing JSON', () async {
    var calls = 0;
    final transport = MockClient((request) async {
      expect(request.headers['ngrok-skip-browser-warning'], 'true');
      calls++;
      if (calls == 1) {
        return http.Response(
          '<!doctype html><html><body>tunnel warning</body></html>',
          200,
          headers: <String, String>{'content-type': 'text/html; charset=utf-8'},
        );
      }
      return _jsonResponse(<String, Object?>{
        'apps': <Object?>[
          <String, Object?>{'id': 'yt', 'door': null, 'query': null},
        ],
        'end_phrase': null,
        'usage': <String, Object?>{'credits': 3, 'model_ms': 24},
      });
    });

    final result = await client(
      transport,
      localTestingHeaders: const <String, String>{
        'ngrok-skip-browser-warning': 'true',
      },
    ).plan(planRequest());

    expect(result.requiresManualChecklist, isFalse);
    expect(calls, 2);
  });

  test('plan treats repeated non-JSON responses as a hard failure', () async {
    var calls = 0;
    final transport = MockClient((_) async {
      calls++;
      return http.Response(
        'tunnel unavailable',
        200,
        headers: <String, String>{'content-type': 'text/plain'},
      );
    });

    final result = await client(transport).plan(planRequest());

    expect(result.fallbackReason, PlanFallbackReason.invalidResponse);
    expect(calls, 2);
  });

  test('plan retries when a slow cold first response times out', () async {
    var calls = 0;
    final firstResponse = Completer<http.Response>();
    final transport = MockClient((_) async {
      calls++;
      if (calls == 1) return firstResponse.future;
      return _jsonResponse(<String, Object?>{
        'apps': <Object?>[
          <String, Object?>{'id': 'yt', 'door': null, 'query': null},
        ],
        'end_phrase': null,
        'usage': <String, Object?>{'credits': 3, 'model_ms': 24},
      });
    });

    final result = await client(
      transport,
      timeout: const Duration(milliseconds: 80),
      firstAttemptTimeout: const Duration(milliseconds: 5),
    ).plan(planRequest());

    expect(result.requiresManualChecklist, isFalse);
    expect(calls, 2);
  });

  test('warmup is best-effort and does not send request text', () async {
    var calls = 0;
    final transport = MockClient((request) async {
      calls++;
      expect(request.method, 'GET');
      expect(request.url.path, '/root/healthz');
      expect(request.url.queryParameters['warmup'], isNotEmpty);
      expect(request.headers['x-app-key'], 'app-secret');
      expect(request.headers['ngrok-skip-browser-warning'], 'true');
      expect(request.body, isEmpty);
      throw http.ClientException('host is waking');
    });

    await client(
      transport,
      localTestingHeaders: const <String, String>{
        'ngrok-skip-browser-warning': 'true',
      },
    ).warmUp();

    expect(calls, 1);
  });

  test(
    'unlock sends exact fields and parses the five-outcome contract',
    () async {
      final transport = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.example.test/root/v1/unlock',
        );
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, <String, Object?>{
          'app_label': 'YouTube',
          'plan_intention': 'learn guitar',
          'reason': '15 min to watch 😀 guitar',
          'shortcut_labels': <String>['Search'],
        });
        return _jsonResponse(<String, Object?>{
          'outcome': 'open',
          'kind': 'time_sensitive',
          'confidence': 0.91,
          'door': 'Search',
          'target': <String, Object?>{
            'text': '😀 guitar',
            'start': 16,
            'end': 24,
          },
          'minutes': 15,
          'usage': <String, Object?>{'credits': 4, 'model_ms': 32},
        });
      });

      final response = await client(transport).unlock(unlockRequest());

      expect(response.outcome, UnlockOutcome.open);
      expect(response.kind, ReasonKind.timeSensitive);
      expect(
        response.targetTextFromReason(unlockRequest().reason),
        '😀 guitar',
      );
      expect(response.minutes, 15);
    },
  );

  test('unlock maps timeout, HTTP, transport, and malformed responses to unavailable', () async {
    final cases = <http.Client>[
      MockClient((_) => Completer<http.Response>().future),
      MockClient((_) async => http.Response('rate limited', 429)),
      MockClient((_) async => throw http.ClientException('offline')),
      MockClient((_) async => http.Response('not json', 200)),
    ];

    for (final transport in cases) {
      final response = await client(
        transport,
        timeout: const Duration(milliseconds: 5),
      ).unlock(unlockRequest());
      expect(response.outcome, UnlockOutcome.unavailable);
    }
  });

  test('production timeout defaults are 8 seconds and 12 seconds', () {
    final api = CurreApiClient(
      baseUrl: Uri.parse('https://api.example.test'),
      appKey: 'key',
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );
    expect(api.unlockTimeout, const Duration(seconds: 8));
    expect(api.planTimeout, const Duration(seconds: 12));
    expect(api.planFirstAttemptTimeout, const Duration(seconds: 9));
    expect(api.warmUpTimeout, const Duration(seconds: 3));
  });
}

http.Response _jsonResponse(Map<String, Object?> body, {int status = 200}) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const <String, String>{
        'content-type': 'application/json; charset=utf-8',
      },
    );
