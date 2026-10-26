import 'dart:typed_data';

import 'voice_model.dart';

/// Turns recorded speech into text on the phone.
abstract interface class SpeechRecognizerEngine {
  /// Starts loading [model] right away, so it is ready by the time the
  /// speaker stops. [language] is a Whisper code, or '' to detect it.
  TranscriptionJob prepare(VoiceModelPaths model, {String language = ''});
}

/// One recording's transcription. Use it once, or cancel it.
abstract interface class TranscriptionJob {
  /// What was said in [samples], at the voice sample rate. Throws when the
  /// model cannot be loaded or run.
  Future<String> transcribe(Float32List samples);

  /// Lets the model go without transcribing.
  void cancel();
}
