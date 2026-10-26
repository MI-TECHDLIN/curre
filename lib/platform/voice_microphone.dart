import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'voice_audio.dart';

enum MicAccess {
  granted,

  /// Not allowed yet; Android will still ask.
  denied,

  /// Android no longer asks; only the phone's settings can turn it on.
  blocked,
}

/// The phone's mic: its permission, and a stream of what it hears.
abstract interface class MicrophoneGateway {
  /// The permission as it stands, without asking.
  Future<MicAccess> access();

  /// Shows Android's own permission prompt.
  Future<MicAccess> requestAccess();

  /// Opens Curre's page in the phone's settings.
  Future<bool> openSettings();

  /// Starts the mic: [voiceSampleRate] mono 16-bit PCM, kept in memory and
  /// never written to a file.
  Future<Stream<Uint8List>> start();

  /// Stops the mic and lets it go.
  Future<void> stop();
}

class DeviceMicrophone implements MicrophoneGateway {
  AudioRecorder? _recorder;

  @override
  Future<MicAccess> access() async =>
      _access(await Permission.microphone.status);

  @override
  Future<MicAccess> requestAccess() async =>
      _access(await Permission.microphone.request());

  @override
  Future<bool> openSettings() => openAppSettings();

  @override
  Future<Stream<Uint8List>> start() async {
    await stop();
    final recorder = _recorder = AudioRecorder();
    return recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: voiceSampleRate,
        numChannels: 1,
        // Android's speech-tuned source; Whisper wants the plain voice.
        androidConfig: AndroidRecordConfig(
          audioSource: AndroidAudioSource.voiceRecognition,
        ),
      ),
    );
  }

  @override
  Future<void> stop() async {
    final recorder = _recorder;
    _recorder = null;
    if (recorder == null) return;
    try {
      await recorder.stop();
    } finally {
      await recorder.dispose();
    }
  }

  static MicAccess _access(PermissionStatus status) => switch (status) {
    PermissionStatus.granted || PermissionStatus.limited => MicAccess.granted,
    PermissionStatus.permanentlyDenied ||
    PermissionStatus.restricted => MicAccess.blocked,
    _ => MicAccess.denied,
  };
}
