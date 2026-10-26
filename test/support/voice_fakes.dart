import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:curre/platform/speech_input.dart';

/// 16-bit PCM of a 220 Hz tone: close, clear speech to the endpointer.
Uint8List speechAudio(Duration length, {double amplitude = .3}) {
  final count = length.inMicroseconds * voiceSampleRate ~/ 1000000;
  final data = ByteData(count * 2);
  for (var i = 0; i < count; i++) {
    final value = amplitude * math.sin(2 * math.pi * 220 * i / voiceSampleRate);
    data.setInt16(i * 2, (value * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

/// 16-bit PCM of a quiet room.
Uint8List quietAudio(Duration length) =>
    Uint8List(length.inMicroseconds * voiceSampleRate ~/ 1000000 * 2);

/// Feeds [audio] to [mic] in 100 ms chunks, the way the recorder does.
void say(FakeMicrophone mic, Uint8List audio) {
  const chunk = voiceSampleRate ~/ 10 * 2;
  for (var start = 0; start < audio.length; start += chunk) {
    mic.hear(
      Uint8List.sublistView(
        audio,
        start,
        math.min(audio.length, start + chunk),
      ),
    );
  }
}

class FakeMicrophone implements MicrophoneGateway {
  FakeMicrophone({
    this.current = MicAccess.granted,
    this.afterRequest = MicAccess.granted,
    this.failToStart = false,
  });

  MicAccess current;
  MicAccess afterRequest;
  bool failToStart;
  var requests = 0;
  var settingsOpened = 0;
  var starts = 0;
  var stops = 0;
  StreamController<Uint8List>? _audio;

  /// The mic is recording right now.
  bool get open => _audio != null;

  void hear(Uint8List bytes) => _audio?.add(bytes);

  @override
  Future<MicAccess> access() async => current;

  @override
  Future<MicAccess> requestAccess() async {
    requests++;
    return current = afterRequest;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Future<Stream<Uint8List>> start() async {
    starts++;
    if (failToStart) throw StateError('busy');
    final audio = _audio = StreamController<Uint8List>();
    return audio.stream;
  }

  @override
  Future<void> stop() async {
    stops++;
    final audio = _audio;
    _audio = null;
    // Not awaited: closing a cancelled stream answers outside a widget
    // test's clock, and the recorder's own stop never waits on it.
    unawaited(audio?.close());
  }
}

class FakeEngine implements SpeechRecognizerEngine {
  FakeEngine({this.text = 'Learn the G chord on YouTube till 7', this.error});

  String text;
  Object? error;
  final jobs = <FakeJob>[];

  @override
  TranscriptionJob prepare(VoiceModelPaths model, {String language = ''}) {
    final job = FakeJob(this, model, language);
    jobs.add(job);
    return job;
  }
}

class FakeJob implements TranscriptionJob {
  FakeJob(this.engine, this.model, this.language);

  final FakeEngine engine;
  final VoiceModelPaths model;
  final String language;
  Float32List? samples;
  var cancelled = false;

  @override
  Future<String> transcribe(Float32List samples) async {
    this.samples = samples;
    final error = engine.error;
    if (error != null) throw error;
    return engine.text;
  }

  @override
  void cancel() => cancelled = true;
}

const fakeModelPaths = VoiceModelPaths(
  encoder: '/voice/tiny-encoder.int8.onnx',
  decoder: '/voice/tiny-decoder.int8.onnx',
  tokens: '/voice/tiny-tokens.txt',
);

/// A model store whose download the test steps through by hand.
class FakeVoiceModelStore implements VoiceModelStore {
  FakeVoiceModelStore({this._installed = true, this.onPhone = 0});

  bool _installed;
  int onPhone;
  var downloads = 0;
  var removals = 0;
  void Function(int received, int total)? _progress;
  Completer<VoiceModelPaths>? _download;
  VoiceDownloadCancel? _cancel;

  @override
  VoiceModelSpec get spec => whisperTinyInt8;

  bool get isDownloading => _download != null;

  @override
  Future<VoiceModelPaths?> installed() async =>
      _installed ? fakeModelPaths : null;

  @override
  Future<int> bytesOnPhone() async => _installed ? spec.bytes : onPhone;

  @override
  Future<VoiceModelPaths> download({
    void Function(int received, int total)? onProgress,
    VoiceDownloadCancel? cancel,
  }) {
    downloads++;
    _progress = onProgress;
    _cancel = cancel;
    final download = _download = Completer<VoiceModelPaths>();
    unawaited(
      cancel?.whenCancelled.then((_) {
        if (download.isCompleted) return;
        _download = null;
        download.completeError(const VoiceDownloadCancelled());
      }),
    );
    return download.future;
  }

  void progress(int received) {
    onPhone = received;
    _progress?.call(received, spec.bytes);
  }

  void finishDownload() {
    _installed = true;
    _download?.complete(fakeModelPaths);
    _download = null;
  }

  void failDownload(VoiceDownloadProblem problem) {
    _download?.completeError(VoiceDownloadException(problem));
    _download = null;
  }

  bool get cancelled => _cancel?.isCancelled ?? false;

  @override
  Future<void> remove() async {
    removals++;
    _installed = false;
    onPhone = 0;
  }
}

SpeechInputService fakeSpeech({
  FakeVoiceModelStore? models,
  FakeMicrophone? microphone,
  FakeEngine? engine,
  String language = 'en',
}) => SpeechInputService(
  models: models ?? FakeVoiceModelStore(),
  microphone: microphone ?? FakeMicrophone(),
  engine: engine ?? FakeEngine(),
  language: () => language,
);
