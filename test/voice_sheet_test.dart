import 'package:curre/app/checkin_screen.dart';
import 'package:curre/app/voice_sheet.dart';
import 'package:curre/design/design.dart';
import 'package:curre/main.dart';
import 'package:curre/platform/speech_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/copy_rules.dart';
import 'support/fakes.dart';
import 'support/voice_fakes.dart';

const _prompt = 'What’s this morning for?';
const _second = Duration(seconds: 1);

class _Sheet {
  SpeechInputResult? result;
}

void main() {
  late FakeMicrophone mic;
  late FakeVoiceModelStore models;
  late FakeEngine engine;
  late SpeechInputService speech;

  setUp(() {
    mic = FakeMicrophone();
    models = FakeVoiceModelStore();
    engine = FakeEngine();
    speech = fakeSpeech(microphone: mic, models: models, engine: engine);
  });

  void stillMotion(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<_Sheet> open(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) async {
    stillMotion(tester);
    final sheet = _Sheet();
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(brightness),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async => sheet.result = await showVoiceSheet(
                  context,
                  speech: speech,
                  prompt: _prompt,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    return sheet;
  }

  Future<TestGesture> pressMic(WidgetTester tester, Duration at) async {
    final gesture = await tester.createGesture();
    await gesture.down(
      tester.getCenter(find.byKey(const Key('voice-mic'))),
      timeStamp: at,
    );
    await tester.pump();
    return gesture;
  }

  double ringScale(WidgetTester tester) => tester
      .widget<AnimatedScale>(find.byKey(const Key('voice-level')))
      .scale;

  testWidgets('first use: allow the mic, download once, hold to talk', (
    tester,
  ) async {
    mic
      ..current = MicAccess.denied
      ..afterRequest = MicAccess.granted;
    models = FakeVoiceModelStore(installed: false);
    speech = fakeSpeech(microphone: mic, models: models, engine: engine);

    final sheet = await open(tester);

    expect(find.text(_prompt), findsOneWidget);
    expect(find.text(voicePermissionExplanation), findsOneWidget);
    expect(mic.starts, 0);
    expectPlainCopy(tester, where: 'the mic prompt');

    await tester.tap(find.text('Allow the mic'));
    await settle(tester);
    expect(mic.requests, 1);
    expect(find.text('Download 104 MB'), findsOneWidget);
    expect(find.textContaining('Wi-Fi is best'), findsOneWidget);
    expectPlainCopy(tester, where: 'the download offer');

    await tester.tap(find.text('Download 104 MB'));
    await tester.pump();
    models.progress(52000000);
    await tester.pump();
    expect(find.text('52 MB of 104 MB'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);

    models.finishDownload();
    await settle(tester);
    expect(find.text('Ready. Voice typing now works offline.'), findsOneWidget);
    expect(find.text('Tap or hold the mic, then speak.'), findsOneWidget);
    // Setting up is not the mic tap: nothing listens yet.
    expect(mic.starts, 0);

    final hold = await pressMic(tester, Duration.zero);
    expect(mic.open, isTrue);
    expect(find.text('Listening… let go when you’re done.'), findsOneWidget);

    say(mic, speechAudio(_second));
    await settle(tester);
    expect(ringScale(tester), greaterThan(1.3));
    say(mic, quietAudio(const Duration(seconds: 2)));
    await settle(tester);
    // Held: a pause does not end it.
    expect(mic.open, isTrue);
    expect(ringScale(tester), 1);

    await hold.up(timeStamp: const Duration(seconds: 3));
    await settle(tester);

    expect(mic.open, isFalse);
    expect(find.byType(VoiceSheet), findsNothing);
    expect(sheet.result?.status, SpeechInputStatus.recognized);
    expect(sheet.result?.transcript, 'Learn the G chord on YouTube till 7');
  });

  testWidgets('the check-in mic listens at once and fills the plan', (
    tester,
  ) async {
    stillMotion(tester);
    final controller = fakeController(speech: speech);
    await tester.pumpWidget(CurreApp(controller: controller));
    await tester.pump();
    expect(controller.speech.presenter, isNotNull);

    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => CheckinScreen(controller: controller),
          ),
        );
    await settle(tester);
    await tester.tap(find.byTooltip('Say your plan'));
    await settle(tester);

    expect(mic.open, isTrue);
    expect(
      find.text('Listening… pause when you’re done, or tap the mic.'),
      findsOneWidget,
    );

    say(mic, speechAudio(_second));
    say(mic, quietAudio(const Duration(milliseconds: 1500)));
    await settle(tester);

    expect(mic.open, isFalse);
    expect(find.byType(VoiceSheet), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('checkin-intention')))
          .controller!
          .text,
      'Learn the G chord on YouTube till 7',
    );
  });

  testWidgets('nothing heard asks again; a tap starts, a tap stops', (
    tester,
  ) async {
    final sheet = await open(tester);
    expect(mic.open, isTrue);

    say(mic, quietAudio(const Duration(seconds: 9)));
    await settle(tester);
    expect(mic.open, isFalse);
    expect(find.textContaining('I didn’t catch that'), findsOneWidget);
    expect(engine.jobs.single.samples, isNull);

    final tap = await pressMic(tester, Duration.zero);
    await tap.up(timeStamp: const Duration(milliseconds: 120));
    await tester.pump();
    expect(mic.open, isTrue);
    expect(
      find.text('Listening… pause when you’re done, or tap the mic.'),
      findsOneWidget,
    );

    say(mic, speechAudio(_second));
    await tester.pump();
    final stop = await pressMic(tester, const Duration(seconds: 2));
    await stop.up(timeStamp: const Duration(milliseconds: 2100));
    await settle(tester);

    expect(sheet.result?.transcript, 'Learn the G chord on YouTube till 7');
    expect(mic.open, isFalse);
  });

  testWidgets('a mic Android will not ask for again points to settings', (
    tester,
  ) async {
    mic
      ..current = MicAccess.denied
      ..afterRequest = MicAccess.blocked;
    await open(tester);

    await tester.tap(find.text('Allow the mic'));
    await settle(tester);
    expect(find.text('The mic is off for Curre'), findsOneWidget);
    expectPlainCopy(tester, where: 'the mic switched off');

    await tester.tap(find.text('Open phone settings'));
    await tester.pump();
    expect(mic.settingsOpened, 1);

    // Back from settings with the mic on.
    mic.current = MicAccess.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
    expect(find.text('Tap or hold the mic, then speak.'), findsOneWidget);
    expect(mic.open, isFalse);
  });

  testWidgets('closing with the mic off leaves a plain line for the field', (
    tester,
  ) async {
    mic
      ..current = MicAccess.denied
      ..afterRequest = MicAccess.denied;
    final sheet = await open(tester);

    await tester.tap(find.text('Allow the mic'));
    await settle(tester);
    expect(find.textContaining('The mic is still off'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Close'));
    await settle(tester);

    expect(sheet.result?.status, SpeechInputStatus.unavailable);
    expect(
      sheet.result?.message,
      'Voice typing needs the mic. You can type instead.',
    );
    expect(mic.starts, 0);
  });

  testWidgets('type instead is a plain cancel', (tester) async {
    mic.current = MicAccess.denied;
    final sheet = await open(tester);

    await tester.tap(find.text('Type instead'));
    await settle(tester);

    expect(sheet.result?.status, SpeechInputStatus.cancelled);
    expect(mic.requests, 0);
  });

  testWidgets('offline or paused, the download picks up where it stopped', (
    tester,
  ) async {
    models = FakeVoiceModelStore(installed: false);
    speech = fakeSpeech(microphone: mic, models: models, engine: engine);
    await open(tester);

    await tester.tap(find.text('Download 104 MB'));
    await tester.pump();
    models.progress(30000000);
    await tester.tap(find.text('Pause'));
    await settle(tester);
    expect(models.cancelled, isTrue);
    expect(find.text('Paused at 30 MB. It picks up from there.'), findsOne);
    expect(find.text('Resume the download'), findsOneWidget);

    await tester.tap(find.text('Resume the download'));
    await tester.pump();
    expect(find.text('30 MB of 104 MB'), findsOneWidget);
    models.failDownload(VoiceDownloadProblem.offline);
    await settle(tester);
    expect(find.textContaining('No connection right now'), findsOneWidget);
    expectPlainCopy(tester, where: 'a stopped download');

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(models.downloads, 3);
    expect(models.isDownloading, isTrue);
  });

  testWidgets('voice files that will not load can be fetched again', (
    tester,
  ) async {
    engine.error = StateError('bad model');
    await open(tester);

    say(mic, speechAudio(_second));
    say(mic, quietAudio(const Duration(milliseconds: 1500)));
    await settle(tester);
    expect(find.text('Voice typing couldn’t start'), findsOneWidget);

    await tester.tap(find.text('Download again'));
    await tester.pump();
    expect(models.removals, 1);
    expect(models.downloads, 1);
  });

  testWidgets('Curre never listens from the background', (tester) async {
    await open(tester);
    expect(mic.open, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await settle(tester);

    expect(mic.open, isFalse);
    expect(engine.jobs.single.cancelled, isTrue);
    expect(find.text('Tap or hold the mic, then speak.'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('every step fits a small phone in light and dark', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      for (final step in VoiceSheetStep.values) {
        stillMotion(tester);
        tester.view.physicalSize = const Size(320, 640);
        await tester.pumpWidget(
          MaterialApp(
            theme: curreTheme(brightness),
            home: Scaffold(
              body: SingleChildScrollView(
                child: VoiceSheetView(
                  step: step,
                  prompt: _prompt,
                  total: whisperTinyInt8.bytes,
                  received: 40000000,
                  onPhone: 40000000,
                  level: .6,
                  note: 'Paused at 40 MB. It picks up from there.',
                  downloadProblem: VoiceDownloadProblem.storage,
                  captureProblem: VoiceCaptureProblem.model,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$step $brightness');
        expectPlainCopy(tester, where: 'the voice sheet, $step');
      }
    }
  });

  group('the settings line', () {
    Future<void> show(WidgetTester tester) async {
      stillMotion(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: curreTheme(Brightness.light),
          home: Scaffold(body: VoiceSettingsCard(speech: speech)),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows the size on the phone and removes it', (tester) async {
      await show(tester);

      expect(find.text('Voice: on this phone'), findsOneWidget);
      expect(find.text('104 MB on this phone · works offline'), findsOne);
      expectPlainCopy(tester, where: 'the voice settings line');

      await tester.tap(find.text('Remove voice files'));
      await settle(tester);
      expect(find.text('Remove the voice files?'), findsOneWidget);
      await tester.tap(find.text('Remove'));
      await settle(tester);

      expect(models.removals, 1);
      expect(
        find.text(
          'Not downloaded yet · 104 MB once, the first time you use the mic',
        ),
        findsOneWidget,
      );
      expect(find.text('Remove voice files'), findsNothing);
      expect(find.text('Voice files removed.'), findsOneWidget);
    });

    testWidgets('a paused download can be cleared too', (tester) async {
      models = FakeVoiceModelStore(installed: false, onPhone: 52000000);
      speech = fakeSpeech(microphone: mic, models: models, engine: engine);
      await show(tester);

      expect(find.text('Download paused · 52 MB of 104 MB'), findsOneWidget);
      expect(find.text('Remove voice files'), findsOneWidget);
    });
  });
}
