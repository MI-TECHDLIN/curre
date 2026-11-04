import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'paths.dart';

/// The film's stand-in for the deployed Curre server.
///
/// Every request the real app sends is written to `$FILM_OUT/requests/`.
/// `demo/tool/capture_live.py` replays those exact bodies against the
/// deployed server once and saves its answers in `demo/film/fixtures/`, so
/// what the film shows is a real response to the request the app really
/// made. A request with no saved answer gets a plainly synthetic one (and
/// fails the render when `FILM_STRICT` is set), so a changed request can
/// never silently borrow another request's answer.
class DemoServer {
  DemoServer();

  static const strict = bool.fromEnvironment('FILM_STRICT');
  static String get fixtures => '${FilmPaths.root}/film/fixtures';

  /// Requests that had no captured answer.
  final missing = <String>[];

  /// Route and fixture name of every request, in order.
  final calls = <String>[];

  late final http.Client client = MockClient(_handle);

  static String nameFor(String route, String body) {
    final digest = sha1.convert(utf8.encode('$route\n$body')).toString();
    return '${route.replaceAll('/', '_').replaceFirst('_', '')}-'
        '${digest.substring(0, 12)}';
  }

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path.replaceFirst(RegExp('^/+'), '');
    if (request.method == 'GET' && path == 'healthz') {
      return _json(<String, Object?>{'status': 'ok'});
    }
    final route = '/$path';
    final name = nameFor(route, request.body);
    calls.add(name);
    final requests = Directory('${FilmPaths.out}/requests')
      ..createSync(recursive: true);
    File('${requests.path}/$name.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'route': route,
        'request': jsonDecode(request.body),
      }),
    );
    final fixture = File('$fixtures/$name.json');
    if (fixture.existsSync()) {
      final saved = jsonDecode(fixture.readAsStringSync()) as Map;
      return http.Response(
        jsonEncode(saved['response']),
        saved['status'] as int,
        headers: const {'content-type': 'application/json'},
      );
    }
    missing.add(name);
    if (strict) {
      throw StateError(
        'No captured answer for $name. Run demo/tool/render.sh --capture.',
      );
    }
    return _synthetic(route, jsonDecode(request.body) as Map<String, Object?>);
  }

  /// Placeholder answers for a first pass, before the live capture.
  http.Response _synthetic(String route, Map<String, Object?> body) {
    const usage = <String, Object?>{'credits': 0, 'model_ms': 0.0};
    switch (route) {
      case '/v1/plan':
        final candidates = (body['candidates']! as List).cast<Map>();
        return _json(<String, Object?>{
          'apps': [
            for (final c in candidates.take(2)) {'id': c['id']},
          ],
          'end_phrase': null,
          'usage': usage,
        });
      case '/v1/unlock':
        return _json(<String, Object?>{
          'outcome': 'specify',
          'kind': 'unclear',
          'confidence': 0.5,
          'usage': usage,
        });
      case '/v1/proof':
        return _json(<String, Object?>{'outcome': 'pending'});
      default:
        return http.Response('{"detail":"synthetic"}', 503);
    }
  }

  static http.Response _json(Object body) => http.Response(
    jsonEncode(body),
    200,
    headers: const {'content-type': 'application/json'},
  );
}
