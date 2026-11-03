import 'package:curre/platform/speech_input.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';
import 'support/voice_fakes.dart';

void main() {
  late FakeVoiceModelStore models;
  late FakeVoiceConditions conditions;
  late MemoryVoicePrefetchChoices choices;
  late VoicePrefetcher prefetch;

  setUp(() {
    models = FakeVoiceModelStore(installed: false);
    conditions = FakeVoiceConditions();
    choices = MemoryVoicePrefetchChoices();
    prefetch = fakePrefetcher(
      models: models,
      conditions: conditions,
      choices: choices,
    );
  });

  tearDown(() => prefetch.stop());

  /// Lets queued microtasks (a cancelled download unwinding) finish.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('nothing downloads before start', () async {
    await prefetch.recheck();
    expect(prefetch.phase, VoicePrefetchPhase.checking);
    expect(models.downloads, 0);
    expect(conditions.reads, 0);
  });

  test('on Wi-Fi it downloads by itself and is then ready', () async {
    await prefetch.start();
    expect(prefetch.phase, VoicePrefetchPhase.downloading);
    expect(models.downloads, 1);

    models.progress(52000000);
    expect(prefetch.fraction, closeTo(.5, .01));

    models.finishDownload();
    await settle();
    expect(prefetch.phase, VoicePrefetchPhase.ready);
    expect(prefetch.model, fakeModelPaths);
    expect(prefetch.fraction, 1);
  });

  test('already on the phone: ready without a download', () async {
    models = FakeVoiceModelStore();
    prefetch = fakePrefetcher(models: models, conditions: conditions);
    await prefetch.start();
    expect(prefetch.phase, VoicePrefetchPhase.ready);
    expect(models.downloads, 0);
  });

  test('waits on mobile data, offline and on a low battery', () async {
    conditions.mobileData();
    await prefetch.start();
    expect(prefetch.phase, VoicePrefetchPhase.waitingForWifi);

    conditions.offline();
    await prefetch.recheck();
    expect(prefetch.phase, VoicePrefetchPhase.waitingForConnection);

    conditions
      ..wifi()
      ..batteryLow = true;
    await prefetch.recheck();
    expect(prefetch.phase, VoicePrefetchPhase.waitingForBattery);
    expect(models.downloads, 0);

    conditions.batteryLow = false;
    await prefetch.recheck();
    expect(prefetch.phase, VoicePrefetchPhase.downloading);
  });

  test('a phone that cannot say its connection counts as mobile data', () {
    expect(VoiceDownloadConditions.unknown.network, VoiceNetwork.unknown);
  });

  test('leaving Wi-Fi pauses it; Wi-Fi again resumes from there', () async {
    await prefetch.start();
    models.progress(20000000);
    await settle();
    expect(models.cancelled, isFalse);

    conditions.mobileData();
    models.progress(30000000);
    await settle();
    await settle();
    expect(models.cancelled, isTrue);
    expect(prefetch.phase, VoicePrefetchPhase.waitingForWifi);
    expect(prefetch.received, 30000000);

    conditions.wifi();
    await prefetch.recheck();
    expect(models.downloads, 2);
    expect(prefetch.phase, VoicePrefetchPhase.downloading);
  });

  test('a low battery mid-download pauses it too', () async {
    await prefetch.start();
    conditions.batteryLow = true;
    models.progress(10000000);
    await settle();
    await settle();
    expect(prefetch.phase, VoicePrefetchPhase.waitingForBattery);
  });

  test('"Download now" uses mobile data and keeps going on it', () async {
    conditions.mobileData();
    await prefetch.start();
    expect(models.downloads, 0);

    await prefetch.downloadNow();
    expect(models.downloads, 1);
    models.progress(40000000);
    await settle();
    await settle();
    expect(models.cancelled, isFalse);
    expect(prefetch.phase, VoicePrefetchPhase.downloading);
  });

  test('the mobile data switch is remembered and lets it go', () async {
    conditions.mobileData();
    await prefetch.start();
    expect(prefetch.onMobileData, isFalse);

    await prefetch.setOnMobileData(true);
    expect(choices.choices.onMobileData, isTrue);
    expect(models.downloads, 1);

    final again = fakePrefetcher(
      models: FakeVoiceModelStore(installed: false),
      conditions: conditions,
      choices: choices,
    );
    await again.start();
    expect(again.onMobileData, isTrue);
    expect(again.phase, VoicePrefetchPhase.downloading);
    again.stop();
  });

  test('removing stops it until the mic asks again', () async {
    models = FakeVoiceModelStore();
    prefetch = fakePrefetcher(
      models: models,
      conditions: conditions,
      choices: choices,
    );
    await prefetch.start();
    await prefetch.remove();
    expect(models.removals, 1);
    expect(prefetch.phase, VoicePrefetchPhase.off);
    expect(choices.choices.auto, isFalse);

    await prefetch.start();
    expect(prefetch.phase, VoicePrefetchPhase.off);
    expect(models.downloads, 0);

    await prefetch.wantVoice();
    expect(choices.choices.auto, isTrue);
    expect(models.downloads, 1);
  });

  test('removing during a download stops it', () async {
    await prefetch.start();
    models.progress(10000000);
    await prefetch.remove();
    await settle();
    expect(models.cancelled, isTrue);
    expect(prefetch.phase, VoicePrefetchPhase.off);
  });

  test('a dropped connection waits; a full phone stops', () async {
    await prefetch.start();
    models.failDownload(VoiceDownloadProblem.offline);
    await settle();
    expect(prefetch.phase, VoicePrefetchPhase.waitingForConnection);

    await prefetch.recheck();
    models.failDownload(VoiceDownloadProblem.storage);
    await settle();
    expect(prefetch.phase, VoicePrefetchPhase.stopped);
    expect(prefetch.problem, VoiceDownloadProblem.storage);
  });

  test('a build without voice typing says so', () async {
    prefetch = VoicePrefetcher(models: _NoModels(), conditions: conditions);
    await prefetch.start();
    expect(prefetch.phase, VoicePrefetchPhase.unavailable);
  });

  testWidgets('a waiting download looks again by itself', (tester) async {
    conditions.mobileData();
    final timed = VoicePrefetcher(
      models: models,
      conditions: conditions,
      choices: choices,
      recheckEvery: const Duration(minutes: 1),
    );
    await timed.start();
    expect(timed.phase, VoicePrefetchPhase.waitingForWifi);

    conditions.wifi();
    await tester.pump(const Duration(seconds: 59));
    expect(models.downloads, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(models.downloads, 1);
    timed.stop();
  });

  test('finishing setup starts it; closing the app stops it', () async {
    final speech = fakeSpeech(models: models, conditions: conditions);
    final controller = fakeController(
      onboardingComplete: false,
      speech: speech,
    );
    expect(models.downloads, 0);

    await controller.finishOnboarding(
      displayName: 'Ada',
      avatarId: null,
      essentials: const <String>{},
      candidates: const <String>{},
    );
    await settle();
    expect(models.downloads, 1);
    expect(speech.prefetch.phase, VoicePrefetchPhase.downloading);

    controller.dispose();
    await settle();
    expect(models.cancelled, isTrue);
  });
}

class _NoModels extends FakeVoiceModelStore {
  @override
  Future<VoiceModelPaths?> installed() async =>
      throw UnsupportedError('no voice');
}
