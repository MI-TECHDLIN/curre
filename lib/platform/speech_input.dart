import 'dart:async';

import 'package:flutter/foundation.dart';

import 'voice_audio.dart';
import 'voice_engine.dart';
import 'voice_microphone.dart';
import 'voice_model.dart';
import 'voice_native_stub.dart'
    if (dart.library.io) 'voice_native.dart'
    as native;

export 'voice_audio.dart' show voiceSampleRate;
export 'voice_engine.dart';
export 'voice_microphone.dart';
export 'voice_model.dart';

enum SpeechInputStatus { recognized, cancelled, unavailable }

class SpeechInputResult {
  const SpeechInputResult.recognized(String this.transcript)
    : status = SpeechInputStatus.recognized,
      message = null;

  const SpeechInputResult.cancelled()
    : status = SpeechInputStatus.cancelled,
      transcript = null,
      message = null;

  const SpeechInputResult.unavailable([this.message = unavailableMessage])
    : status = SpeechInputStatus.unavailable,
      transcript = null;

  static const unavailableMessage =
      "Voice typing isn't available on this phone. You can type instead.";

  static const busyMessage =
      'Voice typing is already open. Finish there, then try again.';

  final SpeechInputStatus status;
  final String? transcript;
  final String? message;
}

/// Shows the voice sheet for one answer. `main.dart` binds it to the app's
/// navigator, so screens only ever call [SpeechInputService.listen].
typedef SpeechInputPresenter = Future<SpeechInputResult> Function(
  String? prompt,
);

/// Voice typing, entirely on the phone: the mic is open only while the
/// voice sheet is listening, the audio stays in memory, and Whisper turns
/// it into text without a network.
class SpeechInputService {
  SpeechInputService({
    VoiceModelStore? models,
    MicrophoneGateway? microphone,
    SpeechRecognizerEngine? engine,
    String Function()? language,
  }) : models = models ?? native.defaultVoiceModelStore(),
       microphone = microphone ?? DeviceMicrophone(),
       engine = engine ?? native.defaultSpeechRecognizerEngine(),
       _language = language ?? _phoneLanguage;

  final VoiceModelStore models;
  final MicrophoneGateway microphone;
  final SpeechRecognizerEngine engine;
  final String Function() _language;

  SpeechInputPresenter? presenter;
  var _open = false;

  /// One spoken answer to [prompt], from the voice sheet.
  Future<SpeechInputResult> listen({String? prompt}) async {
    final present = presenter;
    if (present == null) return const SpeechInputResult.unavailable();
    if (_open) {
      return const SpeechInputResult.unavailable(SpeechInputResult.busyMessage);
    }
    _open = true;
    try {
      return await present(prompt?.trim());
    } on Object {
      // The screen gets plain words, never a raw error.
      return const SpeechInputResult.unavailable();
    } finally {
      _open = false;
    }
  }

  /// Opens the mic and starts loading [model] alongside it. While
  /// [VoiceCapture.stopOnPause] is false (the mic is held), only
  /// [VoiceCapture.finish] or Whisper's 30-second limit end it.
  VoiceCapture capture(VoiceModelPaths model, {bool stopOnPause = true}) =>
      VoiceCapture._(
        microphone: microphone,
        prepare: () =>
            engine.prepare(model, language: whisperLanguageFor(_language())),
        stopOnPause: stopOnPause,
      ).._begin();

  static String _phoneLanguage() =>
      PlatformDispatcher.instance.locale.languageCode;
}

enum VoiceCapturePhase { listening, writing, done }

sealed class VoiceCaptureOutcome {
  const VoiceCaptureOutcome();
}

final class VoiceHeard extends VoiceCaptureOutcome {
  const VoiceHeard(this.text);

  final String text;
}

/// Nothing but quiet, or Whisper found no words in it.
final class VoiceNothingHeard extends VoiceCaptureOutcome {
  const VoiceNothingHeard();
}

final class VoiceCaptureCancelled extends VoiceCaptureOutcome {
  const VoiceCaptureCancelled();
}

enum VoiceCaptureProblem {
  /// The mic would not start, often because another app holds it.
  microphone,

  /// The model would not load or run.
  model,
}

final class VoiceCaptureFailed extends VoiceCaptureOutcome {
  const VoiceCaptureFailed(this.problem);

  final VoiceCaptureProblem problem;
}

/// One recording, from the mic opening to the written words.
class VoiceCapture extends ChangeNotifier {
  VoiceCapture._({
    required this._microphone,
    required this._prepare,
    required this._stopOnPause,
  });

  final MicrophoneGateway _microphone;
  final TranscriptionJob Function() _prepare;
  final _endpointer = SpeechEndpointer();
  final _decoder = Pcm16Decoder();
  final _chunks = <Float32List>[];
  final _outcome = Completer<VoiceCaptureOutcome>();
  TranscriptionJob? _job;
  StreamSubscription<Uint8List>? _subscription;
  var _micOpen = false;
  var _disposed = false;
  var _phase = VoiceCapturePhase.listening;
  var _level = 0.0;
  bool _stopOnPause;

  VoiceCapturePhase get phase => _phase;

  /// Live loudness for the mic ring, 0 to 1.
  double get level => _level;

  Future<VoiceCaptureOutcome> get outcome => _outcome.future;

  /// Whether a pause after speech ends the recording. False while the mic
  /// is held down; true after a tap.
  bool get stopOnPause => _stopOnPause;
  set stopOnPause(bool value) {
    if (_stopOnPause == value) return;
    _stopOnPause = value;
    _notify();
  }

  Future<void> _begin() async {
    try {
      _job = _prepare();
    } on Object {
      _job = null;
    }
    final Stream<Uint8List> audio;
    try {
      audio = await _microphone.start();
    } on Object {
      await _releaseMic();
      _job?.cancel();
      _end(const VoiceCaptureFailed(VoiceCaptureProblem.microphone));
      return;
    }
    // Cancelled while the mic was starting.
    if (_phase != VoiceCapturePhase.listening) {
      await _releaseMic();
      return;
    }
    _micOpen = true;
    _subscription = audio.listen(
      _hear,
      onError: (Object _) => unawaited(finish()),
      onDone: () => unawaited(finish()),
    );
  }

  void _hear(Uint8List bytes) {
    if (_phase != VoiceCapturePhase.listening) return;
    final samples = _decoder.add(bytes);
    if (samples.isEmpty) return;
    _chunks.add(samples);
    final db = loudnessDb(samples);
    _level = meterLevel(db);
    final endpoint = _endpointer.add(db, voiceDuration(samples.length));
    _notify();
    final stop = switch (endpoint) {
      VoiceEndpoint.tooLong => true,
      VoiceEndpoint.finishedSpeaking ||
      VoiceEndpoint.nothingHeard => _stopOnPause,
      VoiceEndpoint.keepListening => false,
    };
    if (stop) unawaited(finish());
  }

  /// Closes the mic and writes down what was said.
  Future<void> finish() async {
    if (_phase != VoiceCapturePhase.listening) return;
    _phase = VoiceCapturePhase.writing;
    _level = 0;
    _notify();
    await _closeMic();
    final job = _job;
    // Quiet goes nowhere near Whisper, which invents words for silence.
    if (!_endpointer.heardSpeech) {
      job?.cancel();
      _end(const VoiceNothingHeard());
      return;
    }
    if (job == null) {
      _end(const VoiceCaptureFailed(VoiceCaptureProblem.model));
      return;
    }
    try {
      final text = cleanTranscript(await job.transcribe(_recording()));
      _end(text.isEmpty ? const VoiceNothingHeard() : VoiceHeard(text));
    } on Object {
      _end(const VoiceCaptureFailed(VoiceCaptureProblem.model));
    }
  }

  /// Closes the mic and drops the recording.
  Future<void> cancel() async {
    if (_phase == VoiceCapturePhase.done) return;
    final listening = _phase == VoiceCapturePhase.listening;
    _end(const VoiceCaptureCancelled());
    if (listening) _job?.cancel();
    await _closeMic();
  }

  Float32List _recording() {
    final total = _chunks.fold(0, (sum, chunk) => sum + chunk.length);
    final samples = Float32List(total);
    var offset = 0;
    for (final chunk in _chunks) {
      samples.setAll(offset, chunk);
      offset += chunk.length;
    }
    _chunks.clear();
    return samples;
  }

  Future<void> _closeMic() async {
    // Cancelling stops the samples at once. Nothing waits on the stream's
    // own cleanup: stopping the recorder below ends it anyway.
    _subscription?.cancel().ignore();
    _subscription = null;
    if (!_micOpen) return;
    _micOpen = false;
    await _releaseMic();
  }

  Future<void> _releaseMic() async {
    try {
      await _microphone.stop();
    } on Object {
      // The mic is already gone; nothing is left to release.
    }
  }

  void _end(VoiceCaptureOutcome outcome) {
    if (_outcome.isCompleted) return;
    _phase = VoiceCapturePhase.done;
    _level = 0;
    _chunks.clear();
    _outcome.complete(outcome);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(cancel());
    super.dispose();
  }
}
