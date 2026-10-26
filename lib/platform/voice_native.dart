import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'voice_audio.dart';
import 'voice_engine.dart';
import 'voice_model.dart';

VoiceModelStore defaultVoiceModelStore() => FileVoiceModelStore();

SpeechRecognizerEngine defaultSpeechRecognizerEngine() => const WhisperEngine();

/// Keeps the model in the app's private files, where only Curre can read
/// it and Android removes it with the app. The `voice/` folder is left out
/// of Android backups (`android/app/src/main/res/xml/`): it is far over the
/// backup quota, and a new phone downloads it again.
class FileVoiceModelStore implements VoiceModelStore {
  FileVoiceModelStore({
    this.spec = whisperTinyInt8,
    Future<Directory> Function()? root,
    http.Client Function()? client,
    this.stallTimeout = const Duration(seconds: 30),
  }) : _root = root ?? getApplicationSupportDirectory,
       _client = client ?? http.Client.new;

  @override
  final VoiceModelSpec spec;
  final Future<Directory> Function() _root;
  final http.Client Function() _client;

  /// A download that receives nothing for this long counts as offline.
  final Duration stallTimeout;

  Future<Directory> _folder() async =>
      Directory('${(await _root()).path}/voice/${spec.id}');

  File _file(Directory folder, VoiceModelFile file) =>
      File('${folder.path}/${file.name}');

  File _part(Directory folder, VoiceModelFile file) =>
      File('${folder.path}/${file.name}.part');

  VoiceModelPaths _paths(Directory folder) => VoiceModelPaths(
    encoder: _file(folder, spec.encoder).path,
    decoder: _file(folder, spec.decoder).path,
    tokens: _file(folder, spec.tokens).path,
  );

  /// A file keeps its final name only after passing its SHA-256 check, so
  /// the right size is enough here.
  Future<bool> _complete(Directory folder, VoiceModelFile file) async {
    final target = _file(folder, file);
    return await target.exists() && await target.length() == file.bytes;
  }

  @override
  Future<VoiceModelPaths?> installed() async {
    final folder = await _folder();
    for (final file in spec.files) {
      if (!await _complete(folder, file)) return null;
    }
    return _paths(folder);
  }

  @override
  Future<int> bytesOnPhone() async {
    final folder = await _folder();
    if (!await folder.exists()) return 0;
    var total = 0;
    await for (final entry in folder.list()) {
      if (entry is File) total += await entry.length();
    }
    return total;
  }

  @override
  Future<VoiceModelPaths> download({
    void Function(int received, int total)? onProgress,
    VoiceDownloadCancel? cancel,
  }) async {
    final folder = await _folder();
    final client = _client();
    try {
      await folder.create(recursive: true);
      var done = 0;
      for (final file in spec.files) {
        if (cancel?.isCancelled ?? false) throw const VoiceDownloadCancelled();
        if (!await _complete(folder, file)) {
          await _fetch(
            client,
            folder,
            file,
            report: (have) => onProgress?.call(done + have, spec.bytes),
            cancel: cancel,
          );
        }
        done += file.bytes;
        onProgress?.call(done, spec.bytes);
      }
      return _paths(folder);
    } on FileSystemException {
      throw const VoiceDownloadException(VoiceDownloadProblem.storage);
    } on SocketException {
      throw const VoiceDownloadException(VoiceDownloadProblem.offline);
    } on HttpException {
      throw const VoiceDownloadException(VoiceDownloadProblem.offline);
    } on http.ClientException {
      throw const VoiceDownloadException(VoiceDownloadProblem.offline);
    } on TimeoutException {
      throw const VoiceDownloadException(VoiceDownloadProblem.offline);
    } finally {
      client.close();
    }
  }

  Future<void> _fetch(
    http.Client client,
    Directory folder,
    VoiceModelFile file, {
    required void Function(int have) report,
    VoiceDownloadCancel? cancel,
  }) async {
    final part = _part(folder, file);
    var have = await part.exists() ? await part.length() : 0;
    if (have > file.bytes) {
      await part.delete();
      have = 0;
    }

    if (have < file.bytes) {
      final request = http.Request('GET', spec.urlOf(file));
      if (have > 0) request.headers['range'] = 'bytes=$have-';
      final response = await client.send(request);
      final FileMode mode;
      if (response.statusCode == HttpStatus.partialContent && have > 0) {
        mode = FileMode.append;
      } else if (response.statusCode == HttpStatus.ok) {
        // The server sent the whole file again; start the part over.
        mode = FileMode.write;
        have = 0;
      } else {
        unawaited(response.stream.drain<void>().catchError((_) {}));
        throw const VoiceDownloadException(VoiceDownloadProblem.server);
      }
      report(have);

      final sink = part.openWrite(mode: mode);
      final finished = Completer<void>();
      late final StreamSubscription<List<int>> subscription;
      subscription = response.stream
          .timeout(stallTimeout)
          .listen(
            (chunk) {
              sink.add(chunk);
              have += chunk.length;
              if (have > file.bytes && !finished.isCompleted) {
                finished.completeError(
                  const VoiceDownloadException(VoiceDownloadProblem.damaged),
                );
                unawaited(subscription.cancel());
                return;
              }
              report(have);
            },
            onError: (Object error, StackTrace stack) {
              if (!finished.isCompleted) finished.completeError(error, stack);
              unawaited(subscription.cancel());
            },
            onDone: () {
              if (!finished.isCompleted) finished.complete();
            },
            cancelOnError: true,
          );
      unawaited(
        cancel?.whenCancelled.then((_) {
          if (finished.isCompleted) return;
          finished.completeError(const VoiceDownloadCancelled());
          unawaited(subscription.cancel());
        }),
      );
      try {
        await finished.future;
      } on VoiceDownloadException {
        await sink.close();
        await part.delete();
        rethrow;
      } finally {
        await sink.close();
      }
      // The connection closed early; what arrived waits for a resume.
      if (have < file.bytes) {
        throw const VoiceDownloadException(VoiceDownloadProblem.offline);
      }
    }

    final digest = await crypto.sha256.bind(part.openRead()).first;
    if (digest.toString() != file.sha256) {
      await part.delete();
      throw const VoiceDownloadException(VoiceDownloadProblem.damaged);
    }
    await part.rename(_file(folder, file).path);
  }

  @override
  Future<void> remove() async {
    final folder = await _folder();
    if (await folder.exists()) await folder.delete(recursive: true);
  }
}

/// Runs Whisper through sherpa-onnx on a background isolate, so the screen
/// keeps drawing while the model loads and reads.
class WhisperEngine implements SpeechRecognizerEngine {
  const WhisperEngine({this.threads = 2});

  final int threads;

  @override
  TranscriptionJob prepare(VoiceModelPaths model, {String language = ''}) =>
      _WhisperJob(model, language: language, threads: threads);
}

class _WhisperJob implements TranscriptionJob {
  _WhisperJob(
    VoiceModelPaths model, {
    required String language,
    required int threads,
  }) {
    _replies.listen(_onReply);
    unawaited(
      Isolate.spawn(
        _whisperWorker,
        _WhisperStart(
          reply: _replies.sendPort,
          encoder: model.encoder,
          decoder: model.decoder,
          tokens: model.tokens,
          language: language,
          threads: threads,
        ),
        onError: _replies.sendPort,
        onExit: _replies.sendPort,
        debugName: 'whisper',
      ).then<void>((_) {}, onError: _fail),
    );
  }

  final _replies = ReceivePort();
  final _worker = Completer<SendPort>();
  final _text = Completer<String>();
  var _sent = false;

  void _onReply(Object? message) {
    switch (message) {
      case ['ready', final SendPort worker]:
        if (!_worker.isCompleted) _worker.complete(worker);
      case ['text', final String text]:
        if (!_text.isCompleted) _text.complete(text);
        _replies.close();
      case ['error', final String error]:
        _fail(StateError(error));
      case [final Object? error, final Object? _]:
        // An uncaught error inside the isolate.
        _fail(StateError('$error'));
      case null:
        // The isolate exited.
        _fail(StateError('Whisper stopped before it answered.'));
    }
  }

  void _fail(Object error) {
    if (!_worker.isCompleted) {
      _worker.completeError(error);
      // Nobody may be waiting yet; the transcript carries the error.
      unawaited(_worker.future.then<void>((_) {}, onError: (_) {}));
    }
    if (!_text.isCompleted) {
      _text.completeError(error);
      unawaited(_text.future.then<void>((_) {}, onError: (_) {}));
    }
    _replies.close();
  }

  @override
  Future<String> transcribe(Float32List samples) async {
    if (_sent) throw StateError('A transcription job reads one recording.');
    _sent = true;
    final worker = await _worker.future;
    worker.send(TransferableTypedData.fromList([samples]));
    return _text.future;
  }

  @override
  void cancel() {
    if (_sent) return;
    _sent = true;
    unawaited(
      _worker.future.then<void>((worker) => worker.send(null), onError: (_) {}),
    );
    if (!_text.isCompleted) {
      _text.completeError(StateError('cancelled'));
      unawaited(_text.future.then<void>((_) {}, onError: (_) {}));
    }
  }
}

class _WhisperStart {
  const _WhisperStart({
    required this.reply,
    required this.encoder,
    required this.decoder,
    required this.tokens,
    required this.language,
    required this.threads,
  });

  final SendPort reply;
  final String encoder;
  final String decoder;
  final String tokens;
  final String language;
  final int threads;
}

/// Loads Whisper, reads one recording (or a null to stop), answers, frees
/// the native model and ends.
void _whisperWorker(_WhisperStart start) {
  final sherpa.OfflineRecognizer recognizer;
  try {
    sherpa.initBindings();
    recognizer = sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          whisper: sherpa.OfflineWhisperModelConfig(
            encoder: start.encoder,
            decoder: start.decoder,
            language: start.language,
            task: 'transcribe',
          ),
          tokens: start.tokens,
          modelType: 'whisper',
          numThreads: start.threads,
          debug: false,
        ),
      ),
    );
  } on Object catch (error) {
    start.reply.send(['error', '$error']);
    return;
  }

  final inbox = ReceivePort();
  start.reply.send(['ready', inbox.sendPort]);
  inbox.listen((message) {
    try {
      if (message is TransferableTypedData) {
        final samples = message.materialize().asFloat32List();
        final stream = recognizer.createStream();
        try {
          stream.acceptWaveform(samples: samples, sampleRate: voiceSampleRate);
          recognizer.decode(stream);
          start.reply.send(['text', recognizer.getResult(stream).text]);
        } finally {
          stream.free();
        }
      }
    } on Object catch (error) {
      start.reply.send(['error', '$error']);
    } finally {
      recognizer.free();
      inbox.close();
    }
  });
}
