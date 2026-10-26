import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One file of the voice model, pinned by its exact size and SHA-256.
class VoiceModelFile {
  const VoiceModelFile({
    required this.name,
    required this.bytes,
    required this.sha256,
  });

  final String name;
  final int bytes;
  final String sha256;
}

/// A Whisper model as sherpa-onnx loads it: encoder, decoder and tokens,
/// fetched from one pinned revision so the bytes can never change under us.
class VoiceModelSpec {
  const VoiceModelSpec({
    required this.id,
    required this.source,
    required this.encoder,
    required this.decoder,
    required this.tokens,
  });

  /// The model's folder name on the phone.
  final String id;

  /// Base URL the files are fetched from.
  final String source;
  final VoiceModelFile encoder;
  final VoiceModelFile decoder;
  final VoiceModelFile tokens;

  List<VoiceModelFile> get files => [encoder, decoder, tokens];

  int get bytes => files.fold(0, (sum, file) => sum + file.bytes);

  Uri urlOf(VoiceModelFile file) => Uri.parse('$source/${file.name}');
}

/// Whisper tiny, multilingual, int8: OpenAI's smallest model (MIT) exported
/// for sherpa-onnx. 104 MB once, then voice typing works offline in
/// Whisper's 99 languages. tiny.en is the same size, so it would only lose
/// languages; base int8 is 160 MB and about twice as slow on a phone for
/// little gain on one short sentence.
const whisperTinyInt8 = VoiceModelSpec(
  id: 'whisper-tiny-int8',
  source:
      'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny/resolve/'
      '65176e2deb88badc814a94058666cadccc29b61c',
  encoder: VoiceModelFile(
    name: 'tiny-encoder.int8.onnx',
    bytes: 12937772,
    sha256: 'd24fb083ae3b1041fc24e97971d60e280c9342201fbb67b0ab428a8b4a51a434',
  ),
  decoder: VoiceModelFile(
    name: 'tiny-decoder.int8.onnx',
    bytes: 89855401,
    sha256: 'd2fece8dd42771f1df975c6c0445770d0c292bf7547c2cae04a6c0cc57540925',
  ),
  tokens: VoiceModelFile(
    name: 'tiny-tokens.txt',
    bytes: 816730,
    sha256: 'b34b360dbb493e781e479794586d661700670d65564001f23024971d1f2fa126',
  ),
);

/// Where an installed model's files are on the phone.
class VoiceModelPaths {
  const VoiceModelPaths({
    required this.encoder,
    required this.decoder,
    required this.tokens,
  });

  final String encoder;
  final String decoder;
  final String tokens;
}

enum VoiceDownloadProblem {
  /// No connection, or it dropped. What arrived is kept for the next try.
  offline,

  /// The server answered with an error.
  server,

  /// A file arrived but did not match its pinned SHA-256; it was deleted.
  damaged,

  /// The phone could not write the files, usually for lack of space.
  storage,
}

class VoiceDownloadException implements Exception {
  const VoiceDownloadException(this.problem);

  final VoiceDownloadProblem problem;

  @override
  String toString() => 'VoiceDownloadException(${problem.name})';
}

/// Thrown by [VoiceModelStore.download] when [VoiceDownloadCancel.cancel]
/// stops it. What arrived is kept, so the next download resumes.
class VoiceDownloadCancelled implements Exception {
  const VoiceDownloadCancelled();
}

/// Stops a running download from outside it.
class VoiceDownloadCancel {
  final _cancelled = Completer<void>();

  bool get isCancelled => _cancelled.isCompleted;

  Future<void> get whenCancelled => _cancelled.future;

  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }
}

/// The voice model's files on the phone.
abstract interface class VoiceModelStore {
  VoiceModelSpec get spec;

  /// The installed files, or null until every file is on the phone and has
  /// passed its SHA-256 check.
  Future<VoiceModelPaths?> installed();

  /// Bytes on the phone, a stopped download's part included.
  Future<int> bytesOnPhone();

  /// Fetches whatever is missing, resuming a stopped download, and checks
  /// every file before it is kept.
  ///
  /// Throws [VoiceDownloadException] or [VoiceDownloadCancelled].
  Future<VoiceModelPaths> download({
    void Function(int received, int total)? onProgress,
    VoiceDownloadCancel? cancel,
  });

  Future<void> remove();
}

/// "104 MB": decimal megabytes, as Android's own storage screens count.
String formatMegabytes(int bytes) {
  final megabytes = bytes / 1000000;
  if (bytes > 0 && megabytes < 1) return '1 MB';
  return '${megabytes.round()} MB';
}

/// Licences for the voice model and the runtime that reads it. sherpa-onnx's
/// own Apache-2.0 licence ships with its Flutter package, so Flutter lists
/// it already.
const voiceLicenseAssets = <String, String>{
  'Whisper (OpenAI)': 'assets/licenses/MIT-Whisper.txt',
  'ONNX Runtime (Microsoft)': 'assets/licenses/MIT-ONNXRuntime.txt',
};

/// Credit for the downloaded model, shown beside its licence.
const voiceModelCredit =
    'Voice typing: Whisper tiny by OpenAI (MIT), exported to ONNX for '
    'sherpa-onnx by the k2-fsa project (Apache-2.0). Curre downloads it '
    'once from Hugging Face and runs it with sherpa-onnx and ONNX Runtime '
    'on the phone.';

void registerVoiceLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in voiceLicenseAssets.entries) {
      final text = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
    yield const LicenseEntryWithLineBreaks([
      'Voice model (Whisper tiny)',
    ], voiceModelCredit);
  });
}
