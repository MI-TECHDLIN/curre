import 'package:curre/platform/speech_input.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps the recognizer best transcript', () async {
    final fake = _FakeInvoker(<Object?, Object?>{
      'status': 'recognized',
      'transcript': '  Pray, then learn the G chord  ',
      'message': null,
    });
    final service = SpeechInputService(invoke: fake.call);

    final result = await service.listen(prompt: "What's this morning for?");

    expect(result.status, SpeechInputStatus.recognized);
    expect(result.transcript, 'Pray, then learn the G chord');
    expect(result.message, isNull);
    expect(fake.method, 'startSpeechInput');
    expect(fake.arguments, <String, String>{
      'prompt': "What's this morning for?",
    });
  });

  test('maps cancellation to a null transcript', () async {
    final service = SpeechInputService(
      invoke: _FakeInvoker(<Object?, Object?>{
        'status': 'cancelled',
        'transcript': null,
        'message': null,
      }).call,
    );

    final result = await service.listen();

    expect(result.status, SpeechInputStatus.cancelled);
    expect(result.transcript, isNull);
    expect(result.message, isNull);
  });

  test('keeps the native unavailable message for the screen', () async {
    final service = SpeechInputService(
      invoke: _FakeInvoker(<Object?, Object?>{
        'status': 'unavailable',
        'transcript': null,
        'message': 'Install a speech recognizer to dictate your check-in.',
      }).call,
    );

    final result = await service.listen();

    expect(result.status, SpeechInputStatus.unavailable);
    expect(result.transcript, isNull);
    expect(result.message, contains('speech recognizer'));
  });

  test('maps a platform failure to graceful unavailability', () async {
    final service = SpeechInputService(
      invoke: (method, arguments) => throw PlatformException(
        code: 'speech_unavailable',
        message: 'Speech input is unavailable.',
      ),
    );

    final result = await service.listen();

    expect(result.status, SpeechInputStatus.unavailable);
    expect(result.message, 'Speech input is unavailable.');
  });
}

class _FakeInvoker {
  _FakeInvoker(this.result);

  final Object? result;
  String? method;
  Object? arguments;

  Future<Object?> call(String method, Object? arguments) async {
    this.method = method;
    this.arguments = arguments;
    return result;
  }
}
