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
      // Native text can be a raw error; the screen always gets plain words.
      'unavailable' => const SpeechInputResult._(
        status: SpeechInputStatus.unavailable,
        message: _unavailableMessage,
      ),
      _ => const SpeechInputResult._(
        status: SpeechInputStatus.unavailable,
        message: _unavailableMessage,
      ),
    };
  }

  static const String _unavailableMessage =
      "Voice typing isn't available on this phone. You can type instead.";

  static const String _busyMessage =
      'Voice typing is already open. Finish there, then try again.';

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
      return SpeechInputResult._(
        status: SpeechInputStatus.unavailable,
        message: error.code == 'speech_in_progress'
            ? SpeechInputResult._busyMessage
            : SpeechInputResult._unavailableMessage,
      );
    }
  }

  static Future<Object?> _invokeChannel(String method, Object? arguments) =>
      currePlatformChannel.invokeMethod<Object?>(method, arguments);
}
