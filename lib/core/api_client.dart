import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_models.dart';

enum PlanFallbackReason { timeout, network, http, invalidResponse }

class PlanCallResult {
  const PlanCallResult._({this.response, this.fallbackReason});

  const PlanCallResult.success(PlanResponse response)
    : this._(response: response);

  const PlanCallResult.manualChecklist(PlanFallbackReason reason)
    : this._(fallbackReason: reason);

  final PlanResponse? response;
  final PlanFallbackReason? fallbackReason;

  bool get requiresManualChecklist => response == null;
}

/// Typed client for Curre's four backend routes.
class CurreApiClient {
  CurreApiClient({
    required Uri baseUrl,
    required String appKey,
    required http.Client httpClient,
    Duration unlockTimeout = const Duration(seconds: 8),
    Duration planTimeout = const Duration(seconds: 12),
    Duration proofTimeout = const Duration(seconds: 8),
    Duration laterTimeout = const Duration(seconds: 6),
    Duration planFirstAttemptTimeout = const Duration(seconds: 9),
    Duration planRetryDelay = const Duration(milliseconds: 250),
    Duration warmUpTimeout = const Duration(seconds: 3),
    bool diagnosticsEnabled = const bool.fromEnvironment('CURRE_API_DEBUG'),
    Map<String, String> localTestingHeaders = const <String, String>{},
  }) : this._internal(
         baseUrl,
         appKey,
         httpClient,
         unlockTimeout: unlockTimeout,
         planTimeout: planTimeout,
         proofTimeout: proofTimeout,
         laterTimeout: laterTimeout,
         planFirstAttemptTimeout: planFirstAttemptTimeout,
         planRetryDelay: planRetryDelay,
         warmUpTimeout: warmUpTimeout,
         diagnosticsEnabled: diagnosticsEnabled,
         localTestingHeaders: localTestingHeaders,
       );

  CurreApiClient._internal(
    this._baseUrl,
    this._appKey,
    this._httpClient, {
    required this.unlockTimeout,
    required this.planTimeout,
    required this.proofTimeout,
    required this.laterTimeout,
    required this.planFirstAttemptTimeout,
    required this.planRetryDelay,
    required this.warmUpTimeout,
    required this.diagnosticsEnabled,
    required Map<String, String> localTestingHeaders,
  }) : _localTestingHeaders = Map.unmodifiable(localTestingHeaders);

  factory CurreApiClient.fromEnvironment({http.Client? httpClient}) {
    const baseUrl = String.fromEnvironment('CURRE_API_BASE_URL');
    const appKey = String.fromEnvironment('CURRE_APP_KEY');
    if (baseUrl.isEmpty) {
      throw StateError(
        'CURRE_API_BASE_URL must be supplied with --dart-define',
      );
    }
    if (appKey.isEmpty) {
      throw StateError('CURRE_APP_KEY must be supplied with --dart-define');
    }
    return CurreApiClient(
      baseUrl: Uri.parse(baseUrl),
      appKey: appKey,
      httpClient: httpClient ?? http.Client(),
      localTestingHeaders: _localTestingHeadersFromEnvironment(),
    );
  }

  final Uri _baseUrl;
  final String _appKey;
  final http.Client _httpClient;
  final Duration unlockTimeout;
  final Duration planTimeout;
  final Duration proofTimeout;
  final Duration laterTimeout;
  final Duration planFirstAttemptTimeout;
  final Duration planRetryDelay;
  final Duration warmUpTimeout;
  final bool diagnosticsEnabled;
  final Map<String, String> _localTestingHeaders;

  /// Starts the deployment before a check-in needs it. This is deliberately
  /// best-effort: Home and onboarding never wait for the network.
  Future<void> warmUp() async {
    final watch = Stopwatch()..start();
    try {
      final endpoint = _endpoint('healthz').replace(
        queryParameters: <String, String>{
          'warmup': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await _httpClient
          .get(endpoint, headers: _headers())
          .timeout(warmUpTimeout);
      _diagnostic(
        'warmup status=${response.statusCode} elapsed_ms=${watch.elapsedMilliseconds}',
      );
    } on Object catch (error) {
      _diagnostic(
        'warmup error=${error.runtimeType} elapsed_ms=${watch.elapsedMilliseconds}',
      );
    }
  }

  Future<PlanCallResult> plan(PlanRequest request) async {
    final watch = Stopwatch()..start();
    final idempotencyKey = _newIdempotencyKey();
    var fallback = PlanFallbackReason.network;

    for (var attempt = 1; attempt <= 2; attempt++) {
      if (attempt > 1 && planRetryDelay > Duration.zero) {
        final delay = _shorter(planRetryDelay, planTimeout - watch.elapsed);
        if (delay > Duration.zero) await Future<void>.delayed(delay);
      }
      final remaining = planTimeout - watch.elapsed;
      if (remaining <= Duration.zero) {
        fallback = PlanFallbackReason.timeout;
        break;
      }
      final attemptTimeout = attempt == 1
          ? _shorter(planFirstAttemptTimeout, remaining)
          : remaining;

      late http.Response response;
      try {
        response = await _post(
          'v1/plan',
          request.toJson(),
          idempotencyKey: idempotencyKey,
        ).timeout(attemptTimeout);
      } on TimeoutException catch (error) {
        fallback = PlanFallbackReason.timeout;
        _diagnostic(
          'plan attempt=$attempt error=${error.runtimeType} '
          'elapsed_ms=${watch.elapsedMilliseconds}',
        );
        continue;
      } on Object catch (error) {
        fallback = PlanFallbackReason.network;
        _diagnostic(
          'plan attempt=$attempt error=${error.runtimeType} '
          'elapsed_ms=${watch.elapsedMilliseconds}',
        );
        continue;
      }

      _diagnostic(
        'plan attempt=$attempt status=${response.statusCode} '
        'elapsed_ms=${watch.elapsedMilliseconds}',
      );
      if (!_isSuccess(response.statusCode)) {
        fallback = PlanFallbackReason.http;
        if (attempt == 1 && _isRetryable(response.statusCode)) continue;
        break;
      }
      if (_looksLikeHtml(response)) {
        fallback = PlanFallbackReason.invalidResponse;
        _diagnostic(
          'plan attempt=$attempt error=htmlResponse '
          'content_type=${_contentType(response)} '
          'elapsed_ms=${watch.elapsedMilliseconds}',
        );
        if (attempt == 1) continue;
        break;
      }
      try {
        final parsed = PlanResponse.fromJson(_decodeObject(response.body));
        _diagnostic(
          'plan success attempt=$attempt apps=${parsed.apps.length} '
          'elapsed_ms=${watch.elapsedMilliseconds}',
        );
        return PlanCallResult.success(parsed);
      } on Object catch (error) {
        _diagnostic(
          'plan attempt=$attempt error=${error.runtimeType} '
          'content_type=${_contentType(response)} '
          'elapsed_ms=${watch.elapsedMilliseconds}',
        );
        fallback = PlanFallbackReason.invalidResponse;
        if (attempt == 1) continue;
        break;
      }
    }

    _diagnostic(
      'plan fallback=${fallback.name} elapsed_ms=${watch.elapsedMilliseconds}',
    );
    return PlanCallResult.manualChecklist(fallback);
  }

  Future<UnlockResponse> unlock(UnlockRequest request) async {
    try {
      final response = await _post(
        'v1/unlock',
        request.toJson(),
      ).timeout(unlockTimeout);
      if (!_isSuccess(response.statusCode)) {
        return const UnlockResponse.unavailable();
      }
      return UnlockResponse.fromJson(_decodeObject(response.body));
    } on Object {
      // Every transport, timeout, status, and malformed-response failure must
      // leave the user with the local override wait.
      return const UnlockResponse.unavailable();
    }
  }

  /// Returns pending for every transport, timeout, status, or malformed
  /// response failure. The phone keeps the note and retries it against its
  /// original Curre day.
  Future<ProofResponse> proof(ProofRequest request) async {
    try {
      final response = await _post(
        'v1/proof',
        request.toJson(),
      ).timeout(proofTimeout);
      if (!_isSuccess(response.statusCode)) {
        return const ProofResponse.pending();
      }
      return ProofResponse.fromJson(_decodeObject(response.body));
    } on Object {
      return const ProofResponse.pending();
    }
  }

  /// Ranks saved "Not now" reasons against a new plan. Returns null for
  /// every transport, timeout, status, or malformed response failure; the
  /// shelf then shows the newest first.
  Future<LaterResponse?> later(LaterRequest request) async {
    try {
      final response = await _post(
        'v1/later',
        request.toJson(),
      ).timeout(laterTimeout);
      if (!_isSuccess(response.statusCode)) return null;
      return LaterResponse.fromJson(_decodeObject(response.body));
    } on Object {
      return null;
    }
  }

  Future<http.Response> _post(
    String path,
    Map<String, Object?> body, {
    String? idempotencyKey,
  }) => _httpClient.post(
    _endpoint(path),
    headers: _headers(json: true, idempotencyKey: idempotencyKey),
    body: jsonEncode(body),
  );

  Map<String, String> _headers({bool json = false, String? idempotencyKey}) {
    final headers = <String, String>{
      if (!kReleaseMode) ..._localTestingHeaders,
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      'X-App-Key': _appKey,
    };
    if (idempotencyKey case final key?) {
      headers['Idempotency-Key'] = key;
    }
    return headers;
  }

  Uri _endpoint(String path) {
    final root = _baseUrl.toString().replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$root/$path');
  }

  void _diagnostic(String message) {
    if (diagnosticsEnabled) debugPrint('[CurreApi] $message');
  }

  void close() => _httpClient.close();
}

bool _isSuccess(int status) => status >= 200 && status < 300;

bool _isRetryable(int status) =>
    status == 408 || status == 425 || status == 429 || status >= 500;

bool _looksLikeHtml(http.Response response) {
  if (_contentType(response) == 'text/html') return true;
  final prefix = response.body.trimLeft().toLowerCase();
  return prefix.startsWith('<!doctype html') || prefix.startsWith('<html');
}

String _contentType(http.Response response) =>
    response.headers['content-type']?.split(';').first.toLowerCase() ??
    'unknown';

Duration _shorter(Duration first, Duration second) =>
    first <= second ? first : second;

String _newIdempotencyKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

Map<String, String> _localTestingHeadersFromEnvironment() {
  if (kReleaseMode) return const <String, String>{};
  const name = String.fromEnvironment('CURRE_API_LOCAL_HEADER_NAME');
  const value = String.fromEnvironment('CURRE_API_LOCAL_HEADER_VALUE');
  if (name.isEmpty || value.isEmpty) return const <String, String>{};
  return <String, String>{name: value};
}

Map<String, Object?> _decodeObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is Map<String, Object?>) return decoded;
  if (decoded is Map) return decoded.cast<String, Object?>();
  throw const FormatException('Response body must be a JSON object');
}
