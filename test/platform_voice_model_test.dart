import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:curre/platform/voice_model.dart';
import 'package:curre/platform/voice_native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _contents = <String, List<int>>{
  'enc.onnx': utf8.encode('encoder bytes, about a dozen megabytes on a phone'),
  'dec.onnx': utf8.encode('decoder bytes, the big one'),
  'tokens.txt': utf8.encode('IQ== 0\nIg== 1\n'),
};

VoiceModelFile _file(String name) => VoiceModelFile(
  name: name,
  bytes: _contents[name]!.length,
  sha256: sha256.convert(_contents[name]!).toString(),
);

final _spec = VoiceModelSpec(
  id: 'test-model',
  source: 'https://models.example/rev',
  encoder: _file('enc.onnx'),
  decoder: _file('dec.onnx'),
  tokens: _file('tokens.txt'),
);

void main() {
  late Directory root;
  late List<http.BaseRequest> requests;

  setUp(() {
    root = Directory.systemTemp.createTempSync('curre-voice-');
    requests = [];
  });

  tearDown(() => root.deleteSync(recursive: true));

  FileVoiceModelStore store(
    Future<http.StreamedResponse> Function(http.BaseRequest request) answer,
  ) => FileVoiceModelStore(
    spec: _spec,
    root: () async => root,
    client: () => MockClient.streaming((request, _) {
      requests.add(request);
      return answer(request);
    }),
  );

  /// Serves each file whole, or from a Range when one is asked for.
  Future<http.StreamedResponse> serve(http.BaseRequest request) async {
    final bytes = _contents[request.url.pathSegments.last]!;
    final range = request.headers['range'];
    if (range == null) {
      return http.StreamedResponse(Stream.value(bytes), 200);
    }
    final from = int.parse(range.substring('bytes='.length, range.length - 1));
    return http.StreamedResponse(Stream.value(bytes.sublist(from)), 206);
  }

  File onPhone(String name) => File('${root.path}/voice/test-model/$name');

  test('downloads every file, checks it, and reports progress', () async {
    final voice = store(serve);
    final progress = <int>[];

    expect(await voice.installed(), isNull);
    final paths = await voice.download(
      onProgress: (received, total) {
        expect(total, _spec.bytes);
        progress.add(received);
      },
    );

    expect(paths.encoder, onPhone('enc.onnx').path);
    expect(paths.decoder, onPhone('dec.onnx').path);
    expect(paths.tokens, onPhone('tokens.txt').path);
    expect(onPhone('dec.onnx').readAsBytesSync(), _contents['dec.onnx']);
    expect(progress.last, _spec.bytes);
    expect(progress, orderedEquals([...progress]..sort()));
    expect((await voice.installed())?.decoder, paths.decoder);
    expect(await voice.bytesOnPhone(), _spec.bytes);
    expect(
      Directory('${root.path}/voice/test-model').listSync().map((e) => e.path),
      isNot(contains(endsWith('.part'))),
    );
    expect(requests.map((r) => r.url.toString()), [
      'https://models.example/rev/enc.onnx',
      'https://models.example/rev/dec.onnx',
      'https://models.example/rev/tokens.txt',
    ]);
  });

  test('a stopped download picks up where it stopped', () async {
    final voice = store(serve);
    final half = _contents['enc.onnx']!.length ~/ 2;
    onPhone('enc.onnx.part')
      ..createSync(recursive: true)
      ..writeAsBytesSync(_contents['enc.onnx']!.sublist(0, half));

    expect(await voice.bytesOnPhone(), half);
    await voice.download();

    expect(requests.first.headers['range'], 'bytes=$half-');
    expect(onPhone('enc.onnx').readAsBytesSync(), _contents['enc.onnx']);
  });

  test('when the server ignores the range, the part starts over', () async {
    final voice = store(
      (request) async => http.StreamedResponse(
        Stream.value(_contents[request.url.pathSegments.last]!),
        200,
      ),
    );
    onPhone('enc.onnx.part')
      ..createSync(recursive: true)
      ..writeAsStringSync('stale');

    await voice.download();

    expect(onPhone('enc.onnx').readAsBytesSync(), _contents['enc.onnx']);
  });

  test('files already on the phone are not fetched again', () async {
    await store(serve).download();
    requests.clear();

    await store(serve).download();

    expect(requests, isEmpty);
  });

  test('a damaged file is thrown away, never kept', () async {
    final voice = store((request) async {
      final bytes = List<int>.of(_contents[request.url.pathSegments.last]!);
      bytes[0] ^= 1;
      return http.StreamedResponse(Stream.value(bytes), 200);
    });

    await expectLater(
      voice.download(),
      throwsA(
        isA<VoiceDownloadException>().having(
          (e) => e.problem,
          'problem',
          VoiceDownloadProblem.damaged,
        ),
      ),
    );
    expect(onPhone('enc.onnx').existsSync(), isFalse);
    expect(onPhone('enc.onnx.part').existsSync(), isFalse);
    expect(await voice.installed(), isNull);
  });

  test('no connection keeps what arrived for the next try', () async {
    final voice = store((request) async {
      final bytes = _contents[request.url.pathSegments.last]!;
      return http.StreamedResponse(
        Stream.fromIterable([
          bytes.sublist(0, 10),
        ]).followedBy(http.ClientException('Connection reset')),
        200,
      );
    });

    await expectLater(
      voice.download(),
      throwsA(
        isA<VoiceDownloadException>().having(
          (e) => e.problem,
          'problem',
          VoiceDownloadProblem.offline,
        ),
      ),
    );
    expect(onPhone('enc.onnx.part').lengthSync(), 10);
  });

  test('a server error says so', () async {
    final voice = store(
      (_) async => http.StreamedResponse(const Stream.empty(), 503),
    );

    await expectLater(
      voice.download(),
      throwsA(
        isA<VoiceDownloadException>().having(
          (e) => e.problem,
          'problem',
          VoiceDownloadProblem.server,
        ),
      ),
    );
  });

  test('pausing stops at once and keeps the part', () async {
    final cancel = VoiceDownloadCancel();
    final body = StreamController<List<int>>();
    final voice = store(
      (_) async => http.StreamedResponse(body.stream, 200),
    );

    final download = voice.download(cancel: cancel);
    await pumpEventQueue();
    body.add(_contents['enc.onnx']!.sublist(0, 7));
    await pumpEventQueue();
    cancel.cancel();

    await expectLater(download, throwsA(isA<VoiceDownloadCancelled>()));
    expect(onPhone('enc.onnx.part').lengthSync(), 7);
    await body.close();
  });

  test('remove takes every file off the phone', () async {
    final voice = store(serve);
    await voice.download();

    await voice.remove();

    expect(await voice.installed(), isNull);
    expect(await voice.bytesOnPhone(), 0);
    await voice.remove();
  });

  test('the shipped model is Whisper tiny int8, pinned to one revision', () {
    expect(whisperTinyInt8.files.map((f) => f.name), [
      'tiny-encoder.int8.onnx',
      'tiny-decoder.int8.onnx',
      'tiny-tokens.txt',
    ]);
    expect(whisperTinyInt8.bytes, 103609903);
    expect(formatMegabytes(whisperTinyInt8.bytes), '104 MB');
    for (final file in whisperTinyInt8.files) {
      expect(file.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(
        whisperTinyInt8.urlOf(file).toString(),
        startsWith(
          'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny/resolve/'
          '65176e2deb88badc814a94058666cadccc29b61c/',
        ),
      );
    }
  });

  test('sizes read as Android counts them', () {
    expect(formatMegabytes(0), '0 MB');
    expect(formatMegabytes(400000), '1 MB');
    expect(formatMegabytes(52400000), '52 MB');
  });

  testWidgets('the licences page credits the voice model and its runtime', (
    tester,
  ) async {
    LicenseRegistry.reset();
    registerVoiceLicenses();

    final entries = await tester.runAsync(
      () => LicenseRegistry.licenses.toList(),
    );
    final text = {
      for (final entry in entries!)
        for (final package in entry.packages)
          package: entry.paragraphs.map((p) => p.text).join('\n'),
    };

    expect(text['Whisper (OpenAI)'], contains('Copyright (c) 2022 OpenAI'));
    expect(
      text['ONNX Runtime (Microsoft)'],
      contains('Copyright (c) Microsoft Corporation'),
    );
    expect(text['Voice model (Whisper tiny)'], contains('Apache-2.0'));
  });
}

extension on Stream<List<int>> {
  Stream<List<int>> followedBy(Object error) async* {
    yield* this;
    throw error;
  }
}
