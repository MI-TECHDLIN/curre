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
    threshold: 0.85,
    shortcutLabels: const <String>['Search'],
  );

  LaterRequest laterRequest() => LaterRequest(
    plan: 'practice guitar before dinner',
    items: <LaterRequestItem>[
      LaterRequestItem(
        id: 'saved-guitar',
        appLabel: 'YouTube',
        text: 'find the fingerpicking lesson',
      ),
      LaterRequestItem(
        id: 'saved-shoes',
        appLabel: 'Browser',
        text: 'look at walking shoes',
      ),
    ],
  );

  CurreApiClient client(
    http.Client transport, {
    Duration timeout = const Duration(milliseconds: 100),
    Duration firstAttemptTimeout = const Duration(milliseconds: 75),
    Duration retryDelay = Duration.zero,
    Duration warmUpTimeout = const Duration(milliseconds: 100),
    Duration coldStartBudget = Duration.zero,
    Duration coldStartFirstAttemptTimeout = Duration.zero,
    Duration slowCallNotice = const Duration(seconds: 4),
    Map<String, String> localTestingHeaders = const <String, String>{},
  }) => CurreApiClient(
    baseUrl: Uri.parse('https://api.example.test/root/'),
    appKey: 'app-secret',
    httpClient: transport,
    planTimeout: timeout,
    planFirstAttemptTimeout: firstAttemptTimeout,
    planRetryDelay: retryDelay,
    warmUpTimeout: warmUpTimeout,
    coldStartBudget: coldStartBudget,
    coldStartFirstAttemptTimeout: coldStartFirstAttemptTimeout,
    slowCallNotice: slowCallNotice,
    localTestingHeaders: localTestingHeaders,
    unlockTimeout: timeout,
    proofTimeout: timeout,
    laterTimeout: timeout,
  );

  test('unlock sends the saved strictness threshold', () async {
    final transport = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['threshold'], 0.85);
      return _jsonResponse(<String, Object?>{'outcome': 'unavailable'});
    });

    await client(transport).unlock(unlockRequest());
  });

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
          'threshold': 0.85,
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

  test('proof sends task and note and parses accepted spans', () async {
    final transport = MockClient((request) async {
      expect(request.url.toString(), 'https://api.example.test/root/v1/proof');
      expect(jsonDecode(request.body), <String, Object?>{
        'task': 'learn the G chord',
        'note': 'I changed from G to C cleanly',
      });
      return _jsonResponse(<String, Object?>{
        'outcome': 'accepted',
        'specific_completion': .93,
        'result': <String, Object?>{
          'text': 'changed from G to C',
          'start': 2,
          'end': 21,
        },
        'learning': null,
        'usage': <String, Object?>{'credits': 11, 'model_ms': 42},
      });
    });

    final response = await client(transport).proof(
      ProofRequest(
        task: 'learn the G chord',
        note: 'I changed from G to C cleanly',
      ),
    );

    expect(response.outcome, ProofOutcome.accepted);
    expect(response.specificCompletion, .93);
    expect(response.result?.text, 'changed from G to C');
    expect(response.usage?.credits, 11);
  });

  test(
    'proof maps timeout, HTTP, transport, and malformed responses to pending',
    () async {
      final cases = <http.Client>[
        MockClient((_) => Completer<http.Response>().future),
        MockClient((_) async => http.Response('rate limited', 429)),
        MockClient((_) async => throw http.ClientException('offline')),
        MockClient((_) async => http.Response('not json', 200)),
      ];

      for (final transport in cases) {
        final response =
            await client(
              transport,
              timeout: const Duration(milliseconds: 5),
            ).proof(
              ProofRequest(
                task: 'learn the G chord',
                note: 'I changed cleanly',
              ),
            );
        expect(response.outcome, ProofOutcome.pending);
      }
    },
  );

  test('later sends exact fields and parses the ordered response', () async {
    final transport = MockClient((request) async {
      expect(request.url.toString(), 'https://api.example.test/root/v1/later');
      expect(jsonDecode(request.body), <String, Object?>{
        'plan': 'practice guitar before dinner',
        'items': <Object?>[
          <String, Object?>{
            'id': 'saved-guitar',
            'app_label': 'YouTube',
            'text': 'find the fingerpicking lesson',
          },
          <String, Object?>{
            'id': 'saved-shoes',
            'app_label': 'Browser',
            'text': 'look at walking shoes',
          },
        ],
      });
      return _jsonResponse(<String, Object?>{
        'items': <Object?>[
          <String, Object?>{'id': 'saved-guitar', 'score': 0.94, 'fits': true},
          <String, Object?>{'id': 'saved-shoes', 'score': 0.16, 'fits': false},
        ],
        'usage': <String, Object?>{'credits': 2, 'model_ms': 38.3},
      });
    });

    final response = await client(transport).later(laterRequest());

    expect(response!.items.map((item) => item.id), <String>[
      'saved-guitar',
      'saved-shoes',
    ]);
    expect(response.items.first.score, 0.94);
    expect(response.items.first.fits, isTrue);
    expect(response.items.last.fits, isFalse);
    expect(response.usage.credits, 2);
  });

  test(
    'later maps timeout, HTTP, transport, and malformed responses to fallback',
    () async {
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
        ).later(laterRequest());
        expect(response, isNull);
      }
    },
  );

  test('production timeout defaults cover every route', () {
    final api = CurreApiClient(
      baseUrl: Uri.parse('https://api.example.test'),
      appKey: 'key',
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );
    expect(api.unlockTimeout, const Duration(seconds: 8));
    expect(api.planTimeout, const Duration(seconds: 12));
    expect(api.planFirstAttemptTimeout, const Duration(seconds: 9));
    expect(api.warmUpTimeout, const Duration(seconds: 3));
    expect(api.proofTimeout, const Duration(seconds: 8));
    expect(api.laterTimeout, const Duration(seconds: 6));
    // A sleeping free host took about 13 s to answer its first plan.
    expect(api.coldStartBudget, const Duration(seconds: 30));
    expect(api.coldStartFirstAttemptTimeout, const Duration(seconds: 24));
  });

  group('first call of a session while the host may be asleep', () {
    final planBody = <String, Object?>{
      'apps': <Object?>[
        <String, Object?>{'id': 'yt', 'door': null, 'query': null},
      ],
      'end_phrase': null,
      'usage': <String, Object?>{'credits': 3, 'model_ms': 24},
    };

    CurreApiClient coldClient(http.Client transport) => client(
      transport,
      timeout: const Duration(milliseconds: 60),
      firstAttemptTimeout: const Duration(milliseconds: 40),
      coldStartBudget: const Duration(milliseconds: 600),
      coldStartFirstAttemptTimeout: const Duration(milliseconds: 450),
      slowCallNotice: const Duration(milliseconds: 30),
    );

    test('a slow first plan gets the longer budget and says so', () async {
      final keys = <String>[];
      final transport = MockClient((request) async {
        keys.add(request.headers['idempotency-key']!);
        // Longer than the usual 60 ms plan budget, inside the cold one.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return _jsonResponse(planBody);
      });
      final api = coldClient(transport);
      final seen = <bool>[];
      api.waking.addListener(() => seen.add(api.waking.value));

      final result = await api.plan(planRequest());

      expect(result.requiresManualChecklist, isFalse);
      expect(keys, hasLength(1));
      expect(seen, <bool>[true, false]);
      expect(api.hasAnswered, isTrue);
    });

    test('a cold first plan keeps one quiet retry with the same key', () async {
      final keys = <String>[];
      final transport = MockClient((request) async {
        keys.add(request.headers['idempotency-key']!);
        if (keys.length == 1) {
          // Hangs past the cold first attempt; the retry gets the rest.
          return Completer<http.Response>().future;
        }
        return _jsonResponse(planBody);
      });

      final result = await coldClient(transport).plan(planRequest());

      expect(result.requiresManualChecklist, isFalse);
      expect(keys, hasLength(2));
      expect(keys.toSet(), hasLength(1));
    });

    test('a first plan past the longer budget falls back as before', () async {
      final watch = Stopwatch()..start();
      final api = coldClient(
        MockClient((_) => Completer<http.Response>().future),
      );

      final result = await api.plan(planRequest());

      expect(result.fallbackReason, PlanFallbackReason.timeout);
      expect(
        watch.elapsed,
        greaterThanOrEqualTo(const Duration(milliseconds: 550)),
      );
      expect(watch.elapsed, lessThan(const Duration(milliseconds: 900)));
      expect(api.waking.value, isFalse);

      // Only the first call waits that long: the next keeps its usual time.
      watch.reset();
      final again = await api.plan(planRequest());
      expect(again.fallbackReason, PlanFallbackReason.timeout);
      expect(watch.elapsed, lessThan(const Duration(milliseconds: 400)));
    });

    test('calls started during the first wait share its budget', () async {
      final api = coldClient(
        MockClient((request) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          if (request.url.path.endsWith('proof')) {
            return http.Response('busy', 503);
          }
          return _jsonResponse(planBody);
        }),
      );

      // A background note retry goes first; the plan right behind it still
      // gets the longer wait.
      final proof = api.proof(
        ProofRequest(task: 'learn the G chord', note: 'I did it'),
      );
      final plan = await api.plan(planRequest());
      await proof;

      expect(plan.requiresManualChecklist, isFalse);
    });

    test('once the warm-up answers, calls keep their usual budget', () async {
      final transport = MockClient((request) async {
        if (request.method == 'GET') return _jsonResponse(<String, Object?>{});
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return _jsonResponse(<String, Object?>{'outcome': 'open'});
      });
      final api = coldClient(transport);
      await api.warmUp();
      expect(api.hasAnswered, isTrue);

      final response = await api.unlock(unlockRequest());

      expect(response.outcome, UnlockOutcome.unavailable);
    });

    test('a warm-up error page does not count as awake', () async {
      final api = coldClient(
        MockClient(
          (_) async => http.Response(
            '<html>waking</html>',
            200,
            headers: <String, String>{'content-type': 'text/html'},
          ),
        ),
      );
      await api.warmUp();
      expect(api.hasAnswered, isFalse);
    });

    test('unlock, proof and Later also get the longer first budget', () async {
      Future<http.Response> slow(Map<String, Object?> body) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return _jsonResponse(body);
      }

      final unlock = await coldClient(
        MockClient((_) => slow(<String, Object?>{'outcome': 'open'})),
      ).unlock(unlockRequest());
      expect(unlock.outcome, UnlockOutcome.open);

      final proof = await coldClient(
        MockClient(
          (_) => slow(<String, Object?>{
            'outcome': 'accepted',
            'specific_completion': .9,
            'result': null,
            'learning': null,
            'usage': <String, Object?>{'credits': 1, 'model_ms': 1},
          }),
        ),
      ).proof(ProofRequest(task: 'learn the G chord', note: 'I did it'));
      expect(proof.outcome, ProofOutcome.accepted);

      final later = await coldClient(
        MockClient(
          (_) => slow(<String, Object?>{
            'items': <Object?>[
              <String, Object?>{
                'id': 'saved-guitar',
                'score': .9,
                'fits': true,
              },
            ],
            'usage': <String, Object?>{'credits': 1, 'model_ms': 1},
          }),
        ),
      ).later(laterRequest());
      expect(later, isNotNull);
    });

    test('a warm call says it is getting ready only once it is slow', () async {
      final transport = MockClient((request) async {
        if (request.method == 'GET') return _jsonResponse(<String, Object?>{});
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return _jsonResponse(<String, Object?>{'outcome': 'open'});
      });
      final api = client(
        transport,
        timeout: const Duration(milliseconds: 300),
        slowCallNotice: const Duration(milliseconds: 20),
      );
      await api.warmUp();
      final seen = <bool>[];
      api.waking.addListener(() => seen.add(api.waking.value));

      final pending = api.unlock(unlockRequest());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(api.waking.value, isFalse);
      await pending;

      expect(seen, <bool>[true, false]);
    });
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
