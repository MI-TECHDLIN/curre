import 'dart:async';
import 'dart:convert';

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

/// Typed client for Curre's two backend routes.
class CurreApiClient {
  CurreApiClient({
    required Uri baseUrl,
    required String appKey,
    required http.Client httpClient,
    Duration unlockTimeout = const Duration(seconds: 8),
    Duration planTimeout = const Duration(seconds: 12),
  }) : this._internal(
         baseUrl,
         appKey,
         httpClient,
         unlockTimeout: unlockTimeout,
         planTimeout: planTimeout,
       );

  CurreApiClient._internal(
    this._baseUrl,
    this._appKey,
    this._httpClient, {
    required this.unlockTimeout,
    required this.planTimeout,
  });

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
    );
  }

  final Uri _baseUrl;
  final String _appKey;
  final http.Client _httpClient;
  final Duration unlockTimeout;
  final Duration planTimeout;

  Future<PlanCallResult> plan(PlanRequest request) async {
    late http.Response response;
    try {
      response = await _post('v1/plan', request.toJson()).timeout(planTimeout);
    } on TimeoutException {
      return const PlanCallResult.manualChecklist(PlanFallbackReason.timeout);
    } on Object {
      return const PlanCallResult.manualChecklist(PlanFallbackReason.network);
    }
    if (!_isSuccess(response.statusCode)) {
      return const PlanCallResult.manualChecklist(PlanFallbackReason.http);
    }
    try {
      return PlanCallResult.success(
        PlanResponse.fromJson(_decodeObject(response.body)),
      );
    } on Object {
      return const PlanCallResult.manualChecklist(
        PlanFallbackReason.invalidResponse,
      );
    }
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
      // leave the user with the 60-second local override.
      return const UnlockResponse.unavailable();
    }
  }

  Future<http.Response> _post(String path, Map<String, Object?> body) =>
      _httpClient.post(
        _endpoint(path),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-App-Key': _appKey,
        },
        body: jsonEncode(body),
      );

  Uri _endpoint(String path) {
    final root = _baseUrl.toString().replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$root/$path');
  }

  void close() => _httpClient.close();
}

bool _isSuccess(int status) => status >= 200 && status < 300;

Map<String, Object?> _decodeObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is Map<String, Object?>) return decoded;
  if (decoded is Map) return decoded.cast<String, Object?>();
  throw const FormatException('Response body must be a JSON object');
}
