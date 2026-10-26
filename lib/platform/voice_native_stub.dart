import 'voice_engine.dart';
import 'voice_model.dart';

// Web review builds have no files or native code: voice typing is simply
// not there, and the sheet says so in plain words.

VoiceModelStore defaultVoiceModelStore() => const _NoVoiceModelStore();

SpeechRecognizerEngine defaultSpeechRecognizerEngine() => const _NoEngine();

class _NoVoiceModelStore implements VoiceModelStore {
  const _NoVoiceModelStore();

  @override
  VoiceModelSpec get spec => whisperTinyInt8;

  @override
  Future<VoiceModelPaths?> installed() async => null;

  @override
  Future<int> bytesOnPhone() async => 0;

  @override
  Future<VoiceModelPaths> download({
    void Function(int received, int total)? onProgress,
    VoiceDownloadCancel? cancel,
  }) async => throw const VoiceDownloadException(VoiceDownloadProblem.storage);

  @override
  Future<void> remove() async {}
}

class _NoEngine implements SpeechRecognizerEngine {
  const _NoEngine();

  @override
  TranscriptionJob prepare(VoiceModelPaths model, {String language = ''}) =>
      throw UnsupportedError('Voice typing needs a phone.');
}
