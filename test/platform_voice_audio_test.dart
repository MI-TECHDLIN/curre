import 'dart:typed_data';

import 'package:curre/platform/voice_audio.dart';
import 'package:flutter_test/flutter_test.dart';

const _tenth = Duration(milliseconds: 100);

void main() {
  test('16-bit PCM decodes to samples, even split mid-sample', () {
    final bytes = ByteData(6)
      ..setInt16(0, 16384, Endian.little)
      ..setInt16(2, -32768, Endian.little)
      ..setInt16(4, 32767, Endian.little);
    final all = bytes.buffer.asUint8List();
    final decoder = Pcm16Decoder();

    final first = decoder.add(Uint8List.sublistView(all, 0, 3));
    final second = decoder.add(Uint8List.sublistView(all, 3));

    expect(first, [.5]);
    expect(second, [-1, closeTo(1, .0001)]);
  });

  test('loudness is RMS in dBFS, and the meter spans a room to a voice', () {
    final full = Float32List.fromList([1, -1, 1, -1]);
    final tenth = Float32List.fromList([.1, -.1, .1, -.1]);

    expect(loudnessDb(full), closeTo(0, .001));
    expect(loudnessDb(tenth), closeTo(-20, .001));
    expect(loudnessDb(Float32List(8)), silenceDb);
    expect(loudnessDb(Float32List(0)), silenceDb);
    expect(meterLevel(-80), 0);
    expect(meterLevel(-37.5), .5);
    expect(meterLevel(0), 1);
  });

  group('the endpointer', () {
    VoiceEndpoint feed(SpeechEndpointer endpointer, double db, int tenths) {
      var last = VoiceEndpoint.keepListening;
      for (var i = 0; i < tenths; i++) {
        last = endpointer.add(db, _tenth);
        if (last != VoiceEndpoint.keepListening) return last;
      }
      return last;
    }

    test('ends 1.4 s after the speaker stops', () {
      final endpointer = SpeechEndpointer();

      expect(feed(endpointer, -60, 5), VoiceEndpoint.keepListening);
      expect(feed(endpointer, -20, 15), VoiceEndpoint.keepListening);
      expect(endpointer.heardSpeech, isTrue);
      expect(feed(endpointer, -60, 13), VoiceEndpoint.keepListening);
      expect(endpointer.add(-60, _tenth), VoiceEndpoint.finishedSpeaking);
    });

    test('short pauses between words do not end it', () {
      final endpointer = SpeechEndpointer();

      for (var word = 0; word < 10; word++) {
        expect(feed(endpointer, -22, 4), VoiceEndpoint.keepListening);
        expect(feed(endpointer, -58, 6), VoiceEndpoint.keepListening);
      }
    });

    test('words spoken the moment the mic opens still count', () {
      final endpointer = SpeechEndpointer();

      expect(feed(endpointer, -18, 5), VoiceEndpoint.keepListening);

      expect(endpointer.heardSpeech, isTrue);
    });

    test('a click is not speech, and silence gives up after 8 s', () {
      final endpointer = SpeechEndpointer();

      endpointer.add(-60, _tenth);
      endpointer.add(-10, _tenth);
      expect(endpointer.heardSpeech, isFalse);
      expect(feed(endpointer, -60, 77), VoiceEndpoint.keepListening);
      expect(endpointer.add(-60, _tenth), VoiceEndpoint.nothingHeard);
    });

    test('a steady noisy room settles into the floor', () {
      final endpointer = SpeechEndpointer();

      // A fan or street noise, then a voice above it, then the noise again.
      feed(endpointer, -36, 40);
      expect(feed(endpointer, -14, 10), VoiceEndpoint.keepListening);
      expect(endpointer.heardSpeech, isTrue);
      expect(feed(endpointer, -36, 20), VoiceEndpoint.finishedSpeaking);
    });

    test('stops at 30 seconds, speech or not', () {
      final endpointer = SpeechEndpointer();

      expect(feed(endpointer, -20, 299), VoiceEndpoint.keepListening);
      expect(endpointer.add(-20, _tenth), VoiceEndpoint.tooLong);
      expect(endpointer.elapsed, const Duration(seconds: 30));
    });
  });

  test('transcripts lose the sounds Whisper notes instead of words', () {
    expect(
      cleanTranscript(' Reply Ada about rehearsal. [BLANK_AUDIO] '),
      'Reply Ada about rehearsal.',
    );
    expect(cleanTranscript('(upbeat music) ♪'), '');
    expect(cleanTranscript('  Learn  the\nG chord '), 'Learn the G chord');
  });

  test("the phone's language steers Whisper only when Whisper knows it", () {
    expect(whisperLanguageFor('en'), 'en');
    expect(whisperLanguageFor('EN'), 'en');
    expect(whisperLanguageFor('yo'), 'yo');
    expect(whisperLanguageFor('ha'), 'ha');
    expect(whisperLanguageFor('nb'), 'no');
    expect(whisperLanguageFor('iw'), 'he');
    expect(whisperLanguageFor('fil'), 'tl');
    expect(whisperLanguageFor('ig'), '');
    expect(whisperLanguageFor(''), '');
  });

  test('a recording lasts as long as its samples', () {
    expect(voiceDuration(voiceSampleRate), const Duration(seconds: 1));
    expect(voiceDuration(1600), _tenth);
  });
}
