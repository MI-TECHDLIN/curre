import 'dart:math' as math;
import 'dart:typed_data';

/// Curre records 16 kHz mono 16-bit PCM, the rate Whisper itself reads.
const voiceSampleRate = 16000;

/// What [loudnessDb] reports for digital silence.
const silenceDb = -90.0;

/// Turns the mic's little-endian 16-bit PCM bytes into samples in [-1, 1].
///
/// A chunk can end halfway through a sample, so the odd byte is carried into
/// the next chunk instead of being dropped.
class Pcm16Decoder {
  int? _carry;

  Float32List add(Uint8List bytes) {
    final carry = _carry;
    final total = bytes.length + (carry == null ? 0 : 1);
    final count = total ~/ 2;
    final samples = Float32List(count);
    var byte = 0;
    for (var i = 0; i < count; i++) {
      final int low;
      if (i == 0 && carry != null) {
        low = carry;
      } else {
        low = bytes[byte++];
      }
      final high = bytes[byte++];
      samples[i] = ((high << 8 | low).toSigned(16)) / 32768;
    }
    _carry = byte < bytes.length ? bytes[byte] : null;
    return samples;
  }
}

/// Root-mean-square loudness in dBFS: about -60 in a quiet room, -30 to -15
/// for speech close to the phone.
double loudnessDb(Float32List samples) {
  if (samples.isEmpty) return silenceDb;
  var sum = 0.0;
  for (final sample in samples) {
    sum += sample * sample;
  }
  final rms = math.sqrt(sum / samples.length);
  if (rms == 0) return silenceDb;
  return math.max(silenceDb, 20 * math.log(rms) / math.ln10);
}

/// The mic ring's size: 0 at -60 dBFS, 1 at -15 dBFS.
double meterLevel(double db) => ((db + 60) / 45).clamp(0.0, 1.0);

enum VoiceEndpoint { keepListening, finishedSpeaking, nothingHeard, tooLong }

/// Decides when a tapped recording is over: a pause after speech, nothing
/// said for a while, or Whisper's 30-second window filled.
///
/// "Speech" is loudness some way above the room's own noise floor. The
/// floor starts no louder than a quiet room, so words spoken the moment the
/// mic opens still count. It falls at once to any quieter moment and climbs
/// quickly through quiet, so a fan or a street settles in, but barely moves
/// while someone talks, so a long sentence never becomes the new floor.
class SpeechEndpointer {
  SpeechEndpointer({
    this.pauseToFinish = const Duration(milliseconds: 1400),
    this.waitForSpeech = const Duration(seconds: 8),
    this.maxLength = const Duration(seconds: 30),
    this.minSpeech = const Duration(milliseconds: 250),
    this.marginDb = 10,
    this.quietestSpeechDb = -50,
    this.startingFloorDb = -45,
  });

  final Duration pauseToFinish;
  final Duration waitForSpeech;
  final Duration maxLength;
  final Duration minSpeech;
  final double marginDb;
  final double quietestSpeechDb;
  final double startingFloorDb;

  /// How far the floor climbs toward louder sound per second, through
  /// quiet and through speech.
  static const _quietRisePerSecond = .5;
  static const _speechRisePerSecond = .02;

  Duration _elapsed = Duration.zero;
  Duration _speech = Duration.zero;
  Duration _quiet = Duration.zero;
  double? _floorDb;

  /// Enough speech was heard to be worth writing down.
  bool get heardSpeech => _speech >= minSpeech;

  Duration get elapsed => _elapsed;

  VoiceEndpoint add(double db, Duration length) {
    _elapsed += length;
    var floor = _floorDb ?? math.min(db, startingFloorDb);
    final speaking = db >= math.max(floor + marginDb, quietestSpeechDb);
    if (db < floor) {
      floor = db;
    } else {
      final perSecond = speaking ? _speechRisePerSecond : _quietRisePerSecond;
      floor += (db - floor) * math.min(1.0, perSecond * _seconds(length));
    }
    _floorDb = floor;
    if (speaking) {
      _speech += length;
      _quiet = Duration.zero;
    } else {
      _quiet += length;
    }

    if (_elapsed >= maxLength) return VoiceEndpoint.tooLong;
    if (heardSpeech) {
      if (_quiet >= pauseToFinish) return VoiceEndpoint.finishedSpeaking;
    } else if (_elapsed >= waitForSpeech) {
      return VoiceEndpoint.nothingHeard;
    }
    return VoiceEndpoint.keepListening;
  }

  static double _seconds(Duration value) => value.inMicroseconds / 1e6;
}

/// How long [sampleCount] samples last at [voiceSampleRate].
Duration voiceDuration(int sampleCount) =>
    Duration(microseconds: sampleCount * 1000000 ~/ voiceSampleRate);

final _nonSpeech = RegExp(r'\[[^\]]*\]|\([^)]*\)|[♪♫]');
final _spaces = RegExp(r'\s+');

/// Whisper marks sounds it heard rather than words, such as "[BLANK_AUDIO]"
/// or "(music)". Spoken sentences never contain brackets, so they go.
String cleanTranscript(String raw) =>
    raw.replaceAll(_nonSpeech, ' ').replaceAll(_spaces, ' ').trim();

/// Whisper's language for the phone's [languageCode], or '' to let Whisper
/// detect it. Steering by the phone's language keeps short sentences from
/// being mistaken for another language.
String whisperLanguageFor(String languageCode) {
  final code = languageCode.toLowerCase();
  final language = _languageAliases[code] ?? code;
  return _whisperLanguages.contains(language) ? language : '';
}

/// Older or regional codes Android reports for languages Whisper names
/// differently.
const _languageAliases = <String, String>{
  'nb': 'no',
  'iw': 'he',
  'in': 'id',
  'ji': 'yi',
  'jv': 'jw',
  'fil': 'tl',
};

/// The 99 languages of Whisper's multilingual models.
const _whisperLanguages = <String>{
  'en', 'zh', 'de', 'es', 'ru', 'ko', 'fr', 'ja', 'pt', 'tr', 'pl', 'ca', //
  'nl', 'ar', 'sv', 'it', 'id', 'hi', 'fi', 'vi', 'he', 'uk', 'el', 'ms',
  'cs', 'ro', 'da', 'hu', 'ta', 'no', 'th', 'ur', 'hr', 'bg', 'lt', 'la',
  'mi', 'ml', 'cy', 'sk', 'te', 'fa', 'lv', 'bn', 'sr', 'az', 'sl', 'kn',
  'et', 'mk', 'br', 'eu', 'is', 'hy', 'ne', 'mn', 'bs', 'kk', 'sq', 'sw',
  'gl', 'mr', 'pa', 'si', 'km', 'sn', 'yo', 'so', 'af', 'oc', 'ka', 'be',
  'tg', 'sd', 'gu', 'am', 'yi', 'lo', 'uz', 'fo', 'ht', 'ps', 'tk', 'nn',
  'mt', 'sa', 'lb', 'my', 'bo', 'tl', 'mg', 'as', 'tt', 'haw', 'ln', 'ha',
  'ba', 'jw', 'su',
};
