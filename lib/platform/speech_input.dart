import 'package:flutter/services.dart';

import 'platform_channel.dart';

enum SpeechInputStatus { recognized, cancelled, unavailable }

class SpeechInputResult {
  const SpeechInputResult._({
    required this.status,
    this.transcript,
    this.message,
  });

  factory SpeechInputResult.fromChannel(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return const SpeechInputResult._(
        status: SpeechInputStatus.unavailable,
        message: _unavailableMessage,
      );
    }

    final transcript = (raw['transcript'] as String?)?.trim();
    return switch (raw['status']) {
      'recognized' when transcript != null && transcript.isNotEmpty =>
        SpeechInputResult._(
          status: SpeechInputStatus.recognized,
          transcript: transcript,
        ),
      'cancelled' => const SpeechInputResult._(
        status: SpeechInputStatus.cancelled,
      ),
      'unavailable' => SpeechInputResult._(
        status: SpeechInputStatus.unavailable,
        message: (raw['message'] as String?)?.trim().isNotEmpty == true
            ? (raw['message'] as String).trim()
            : _unavailableMessage,
      ),
      _ => const SpeechInputResult._(
        status: SpeechInputStatus.unavailable,
        message: _unavailableMessage,
      ),
    };
  }

  static const String _unavailableMessage =
      "Speech input isn't available on this phone.";

  final SpeechInputStatus status;
  final String? transcript;
  final String? message;
}

typedef PlatformMethodInvoker = Future<Object?> Function(
  String method,
  Object? arguments,
);

class SpeechInputService {
  SpeechInputService({PlatformMethodInvoker? invoke})
    : _invoke = invoke ?? _invokeChannel;

  final PlatformMethodInvoker _invoke;

  Future<SpeechInputResult> listen({String? prompt}) async {
    try {
      final raw = await _invoke('startSpeechInput', <String, String>{
        if (prompt != null && prompt.trim().isNotEmpty) 'prompt': prompt.trim(),
      });
      return SpeechInputResult.fromChannel(raw);
    } on PlatformException catch (error) {
      return SpeechInputResult.fromChannel(<Object?, Object?>{
        'status': 'unavailable',
        'message': error.message,
      });
    }
  }

  static Future<Object?> _invokeChannel(String method, Object? arguments) =>
      currePlatformChannel.invokeMethod<Object?>(method, arguments);
}
