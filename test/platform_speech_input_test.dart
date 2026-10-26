import 'dart:async';

import 'package:curre/platform/speech_input.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/voice_fakes.dart';

void main() {
  group('listen', () {
    test(
      'without the voice sheet bound, says voice typing is unavailable',
      () async {
        final result = await fakeSpeech().listen(prompt: 'What is this for?');

        expect(result.status, SpeechInputStatus.unavailable);
        expect(result.transcript, isNull);
        expect(result.message, SpeechInputResult.unavailableMessage);
      },
    );

    test('answers with what the voice sheet heard', () async {
      final speech = fakeSpeech();
      String? asked;
      speech.presenter = (prompt) async {
        asked = prompt;
        return const SpeechInputResult.recognized(
          'Pray, then learn the G chord',
        );
      };

      final result = await speech.listen(prompt: "  What's this morning for? ");

      expect(asked, "What's this morning for?");
      expect(result.status, SpeechInputStatus.recognized);
      expect(result.transcript, 'Pray, then learn the G chord');
      expect(result.message, isNull);
    });

    test('a sheet that breaks still leaves plain words', () async {
      final speech = fakeSpeech()
        ..presenter = (_) async => throw StateError('no navigator');

      final result = await speech.listen();

      expect(result.status, SpeechInputStatus.unavailable);
      expect(result.message, SpeechInputResult.unavailableMessage);
    });

    test('a cancelled sheet is a cancel, not a problem', () async {
      final speech = fakeSpeech()
        ..presenter = (_) async => const SpeechInputResult.cancelled();

      final result = await speech.listen();

      expect(result.status, SpeechInputStatus.cancelled);
      expect(result.transcript, isNull);
      expect(result.message, isNull);
    });

    test('a second mic tap while the sheet is open is turned away', () async {
      final speech = fakeSpeech();
      final first = Completer<SpeechInputResult>();
      speech.presenter = (_) => first.future;

      final open = speech.listen();
      final second = await speech.listen();
      first.complete(const SpeechInputResult.cancelled());
      await open;
      final third = await speech.listen();

      expect(second.status, SpeechInputStatus.unavailable);
      expect(second.message, SpeechInputResult.busyMessage);
      // Once it closes, the mic opens the sheet again.
      expect(third.status, SpeechInputStatus.cancelled);
    });
  });

  group('capture', () {
    late FakeMicrophone mic;
    late FakeEngine engine;
    late SpeechInputService speech;

    setUp(() {
      mic = FakeMicrophone();
      engine = FakeEngine(
        text: ' Learn the G chord on YouTube till 7 [BLANK_AUDIO]',
      );
      speech = fakeSpeech(microphone: mic, engine: engine, language: 'en');
    });

    test('a tap listens until a pause, then Whisper writes it down', () async {
      final capture = speech.capture(fakeModelPaths);
      await pumpEventQueue();
      expect(mic.open, isTrue);
      expect(capture.phase, VoiceCapturePhase.listening);

      say(mic, quietAudio(const Duration(milliseconds: 300)));
      say(mic, speechAudio(const Duration(seconds: 1)));
      await pumpEventQueue();
      expect(capture.level, greaterThan(.5));
      expect(capture.phase, VoiceCapturePhase.listening);

      say(mic, quietAudio(const Duration(milliseconds: 1500)));
      final outcome = await capture.outcome;

      expect(outcome, isA<VoiceHeard>());
      expect(
        (outcome as VoiceHeard).text,
        'Learn the G chord on YouTube till 7',
      );
      expect(mic.open, isFalse);
      expect(mic.stops, 1);
      final job = engine.jobs.single;
      expect(job.language, 'en');
      expect(job.model, same(fakeModelPaths));
      // Everything up to the pause, and nothing after it.
      expect(job.samples!.length, greaterThan(voiceSampleRate * 2));
      expect(job.samples!.length, lessThanOrEqualTo(voiceSampleRate * 2.8));
    });

    test(
      'while the mic is held, a pause does not end it; letting go does',
      () async {
        final capture = speech.capture(fakeModelPaths, stopOnPause: false);
        await pumpEventQueue();

        say(mic, speechAudio(const Duration(seconds: 1)));
        say(mic, quietAudio(const Duration(seconds: 3)));
        await pumpEventQueue();
        expect(capture.phase, VoiceCapturePhase.listening);
        expect(mic.open, isTrue);

        await capture.finish();

        expect(await capture.outcome, isA<VoiceHeard>());
        expect(mic.open, isFalse);
        expect(engine.jobs.single.samples!.length, voiceSampleRate * 4);
      },
    );

    test('a tap after a hold hands the end back to the pause', () async {
      final capture = speech.capture(fakeModelPaths, stopOnPause: false);
      await pumpEventQueue();
      say(mic, speechAudio(const Duration(seconds: 1)));
      say(mic, quietAudio(const Duration(seconds: 2)));
      await pumpEventQueue();
      expect(capture.phase, VoiceCapturePhase.listening);

      capture.stopOnPause = true;
      say(mic, quietAudio(const Duration(milliseconds: 100)));

      expect(await capture.outcome, isA<VoiceHeard>());
    });

    test(
      'quiet never reaches Whisper, which would invent words for it',
      () async {
        final capture = speech.capture(fakeModelPaths);
        await pumpEventQueue();

        say(mic, quietAudio(const Duration(seconds: 9)));

        expect(await capture.outcome, isA<VoiceNothingHeard>());
        expect(engine.jobs.single.samples, isNull);
        expect(engine.jobs.single.cancelled, isTrue);
        expect(mic.open, isFalse);
      },
    );

    test('words Whisper marks as sounds count as nothing heard', () async {
      engine.text = ' [BLANK_AUDIO] (music) ';
      final capture = speech.capture(fakeModelPaths);
      await pumpEventQueue();

      say(mic, speechAudio(const Duration(seconds: 1)));
      say(mic, quietAudio(const Duration(milliseconds: 1500)));

      expect(await capture.outcome, isA<VoiceNothingHeard>());
    });

    test('stops at 30 seconds even while held', () async {
      final capture = speech.capture(fakeModelPaths, stopOnPause: false);
      await pumpEventQueue();

      for (var second = 0; second < 31; second++) {
        say(mic, speechAudio(const Duration(seconds: 1)));
      }

      expect(await capture.outcome, isA<VoiceHeard>());
      expect(engine.jobs.single.samples!.length, voiceSampleRate * 30);
    });

    test('cancel closes the mic and drops the recording', () async {
      final capture = speech.capture(fakeModelPaths);
      await pumpEventQueue();
      say(mic, speechAudio(const Duration(seconds: 1)));

      await capture.cancel();

      expect(await capture.outcome, isA<VoiceCaptureCancelled>());
      expect(mic.open, isFalse);
      expect(engine.jobs.single.cancelled, isTrue);
      expect(engine.jobs.single.samples, isNull);
    });

    test('cancelling while the mic starts still lets the mic go', () async {
      final capture = speech.capture(fakeModelPaths);
      await capture.cancel();
      await pumpEventQueue();

      expect(await capture.outcome, isA<VoiceCaptureCancelled>());
      expect(mic.starts, 1);
      expect(mic.open, isFalse);
    });

    test('a mic that will not start is a mic problem', () async {
      mic.failToStart = true;
      final capture = speech.capture(fakeModelPaths);

      final outcome = await capture.outcome;

      expect(outcome, isA<VoiceCaptureFailed>());
      expect(
        (outcome as VoiceCaptureFailed).problem,
        VoiceCaptureProblem.microphone,
      );
      expect(engine.jobs.single.cancelled, isTrue);
    });

    test('a model that will not load is a model problem', () async {
      engine.error = StateError('bad model');
      final capture = speech.capture(fakeModelPaths);
      await pumpEventQueue();

      say(mic, speechAudio(const Duration(seconds: 1)));
      say(mic, quietAudio(const Duration(milliseconds: 1500)));
      final outcome = await capture.outcome;

      expect(outcome, isA<VoiceCaptureFailed>());
      expect(
        (outcome as VoiceCaptureFailed).problem,
        VoiceCaptureProblem.model,
      );
      expect(mic.open, isFalse);
    });

    test(
      "steers Whisper by the phone's language when Whisper knows it",
      () async {
        final norwegian = fakeSpeech(
          microphone: mic,
          engine: engine,
          language: 'nb',
        );
        await norwegian.capture(fakeModelPaths).cancel();
        final unknown = fakeSpeech(
          microphone: mic,
          engine: engine,
          language: 'xx',
        );
        await unknown.capture(fakeModelPaths).cancel();

        expect(engine.jobs.map((job) => job.language), ['no', '']);
      },
    );
  });
}
