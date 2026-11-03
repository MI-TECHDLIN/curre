import 'dart:async';

import 'package:flutter/material.dart';

import '../design/design.dart';
import '../platform/speech_input.dart';
import 'app_widgets.dart';

/// The promise made before Android's own mic prompt.
const voicePermissionExplanation =
    'Curre listens only while you hold or tap the mic. '
    'Your voice never leaves your phone.';

const _micOffMessage = 'Voice typing needs the mic. You can type instead.';
const _couldNotStartMessage =
    "Voice typing couldn't start. You can type instead.";

/// The mic's note while the voice files are still on their way.
const voiceGettingReadyMessage =
    'Voice is getting ready. You can type for now.';

/// Shows the voice sheet and answers with what it heard. Closing the sheet
/// is a cancel, unless it was showing a problem, which then becomes the
/// short line under the text field.
Future<SpeechInputResult> showVoiceSheet(
  BuildContext context, {
  required SpeechInputService speech,
  String? prompt,
}) async {
  var dismissed = const SpeechInputResult.cancelled();
  final result = await showModalBottomSheet<SpeechInputResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // A held mic must never turn into a drag that closes the sheet.
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => VoiceSheet(
      speech: speech,
      prompt: prompt,
      onDismissResult: (value) => dismissed = value,
    ),
  );
  return result ?? dismissed;
}

enum VoiceSheetStep {
  checking,

  /// The voice files are still downloading, or waiting to: a short note,
  /// the water rising with the download, and "Download now".
  gettingReady,
  askMic,
  micBlocked,
  ready,
  listening,
  writing,
  failed,
}

/// Voice typing in one sheet: hold or tap the mic and speak. The voice
/// files download quietly in the background ([VoicePrefetcher]); if the
/// mic is tapped before they are ready, the sheet says so in one calm note
/// and offers to download now.
class VoiceSheet extends StatefulWidget {
  const VoiceSheet({
    super.key,
    required this.speech,
    this.prompt,
    this.onDismissResult,
  });

  final SpeechInputService speech;
  final String? prompt;

  /// Told what closing the sheet now would mean, whenever that changes.
  final ValueChanged<SpeechInputResult>? onDismissResult;

  @override
  State<VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<VoiceSheet> with WidgetsBindingObserver {
  /// A press shorter than this is a tap: listen until the speaker pauses.
  static const _tapLimit = Duration(milliseconds: 350);

  var _step = VoiceSheetStep.checking;
  String? _note;
  VoiceModelPaths? _model;
  VoiceCapture? _capture;
  VoiceCaptureProblem? _captureProblem;
  var _holding = false;
  var _preparing = false;
  Duration? _pressedAt;

  SpeechInputService get speech => widget.speech;
  VoicePrefetcher get prefetch => speech.prefetch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    prefetch.addListener(_prefetchChanged);
    // The mic tap that opened the sheet is the tap that starts listening.
    unawaited(_prepare(autoStart: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    prefetch.removeListener(_prefetchChanged);
    _dropCapture();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed
          when _step == VoiceSheetStep.askMic ||
              _step == VoiceSheetStep.micBlocked:
        // Back from the phone's settings, perhaps with the mic on.
        unawaited(_prepare(autoStart: false));
      case AppLifecycleState.hidden || AppLifecycleState.paused
          when _capture != null:
        // Curre never listens from the background.
        _dropCapture();
        _show(VoiceSheetStep.ready);
      default:
        break;
    }
  }

  void _prefetchChanged() {
    if (!mounted || _step != VoiceSheetStep.gettingReady) return;
    if (prefetch.phase == VoicePrefetchPhase.ready) {
      // Ready while the sheet was open: the mic, then a tap to talk.
      unawaited(
        _prepare(
          autoStart: false,
          readyNote: 'Ready. Voice typing now works offline.',
        ),
      );
    } else {
      setState(() {});
    }
  }

  void _show(VoiceSheetStep step, {String? note}) {
    if (!mounted) return;
    setState(() {
      _step = step;
      _note = note;
    });
    widget.onDismissResult?.call(switch (step) {
      VoiceSheetStep.askMic when note != null =>
        const SpeechInputResult.unavailable(_micOffMessage),
      VoiceSheetStep.micBlocked => const SpeechInputResult.unavailable(
        _micOffMessage,
      ),
      VoiceSheetStep.failed => const SpeechInputResult.unavailable(
        _couldNotStartMessage,
      ),
      _ => const SpeechInputResult.cancelled(),
    });
  }

  Future<void> _prepare({required bool autoStart, String? readyNote}) async {
    if (_preparing) return;
    _preparing = true;
    try {
      await _prepareOnce(autoStart: autoStart, readyNote: readyNote);
    } finally {
      _preparing = false;
    }
  }

  Future<void> _prepareOnce({
    required bool autoStart,
    String? readyNote,
  }) async {
    final VoiceModelPaths? model;
    try {
      model = await prefetch.installed();
    } on Object {
      // No voice typing in this build at all.
      if (mounted) {
        Navigator.of(context).pop(const SpeechInputResult.unavailable());
      }
      return;
    }
    if (model == null) {
      // Not there yet: never a blocking download screen, just the note.
      // Tapping the mic also turns the quiet download back on.
      unawaited(prefetch.wantVoice());
      _show(VoiceSheetStep.gettingReady);
      return;
    }
    final MicAccess access;
    try {
      access = await speech.microphone.access();
    } on Object {
      _captureProblem = VoiceCaptureProblem.microphone;
      _show(VoiceSheetStep.failed);
      return;
    }
    if (access != MicAccess.granted) {
      _show(
        access == MicAccess.blocked
            ? VoiceSheetStep.micBlocked
            : VoiceSheetStep.askMic,
      );
      return;
    }
    if (!mounted) return;
    _model = model;
    if (autoStart) {
      _listen(stopOnPause: true);
    } else {
      _show(VoiceSheetStep.ready, note: readyNote);
    }
  }

  Future<void> _allowMic() async {
    final MicAccess access;
    try {
      access = await speech.microphone.requestAccess();
    } on Object {
      _show(VoiceSheetStep.askMic, note: _micStillOff);
      return;
    }
    switch (access) {
      case MicAccess.granted:
        await _prepare(autoStart: false);
      case MicAccess.denied:
        _show(VoiceSheetStep.askMic, note: _micStillOff);
      case MicAccess.blocked:
        _show(VoiceSheetStep.micBlocked);
    }
  }

  static const _micStillOff =
      'The mic is still off. Allow it to speak, or type instead.';

  Future<void> _openSettings() async {
    try {
      await speech.microphone.openSettings();
    } on Object {
      // The sheet still says where the switch is.
    }
  }

  /// The explicit path: the person saw the size and asked for it now, so
  /// it may use mobile data.
  void _downloadNow() {
    unawaited(prefetch.downloadNow());
    setState(() {});
  }

  /// The voice files would not load: fetch them fresh.
  void _downloadAgain() {
    _model = null;
    unawaited(prefetch.replace());
    _show(VoiceSheetStep.gettingReady);
  }

  void _listen({required bool stopOnPause}) {
    final model = _model;
    if (model == null) return;
    _dropCapture();
    final capture = _capture = speech.capture(model, stopOnPause: stopOnPause);
    capture.addListener(_captureChanged);
    unawaited(capture.outcome.then((outcome) => _heard(capture, outcome)));
    _show(VoiceSheetStep.listening);
  }

  void _captureChanged() {
    final capture = _capture;
    if (!mounted || capture == null) return;
    if (capture.phase == VoiceCapturePhase.writing &&
        _step != VoiceSheetStep.writing) {
      _show(VoiceSheetStep.writing);
    } else {
      setState(() {});
    }
  }

  void _heard(VoiceCapture capture, VoiceCaptureOutcome outcome) {
    if (!mounted || !identical(capture, _capture)) return;
    _dropCapture();
    switch (outcome) {
      case VoiceHeard(:final text):
        Navigator.of(context).pop(SpeechInputResult.recognized(text));
      case VoiceNothingHeard():
        _show(
          VoiceSheetStep.ready,
          note: 'I didn’t catch that. Try again, a little closer to the mic.',
        );
      case VoiceCaptureCancelled():
        _show(VoiceSheetStep.ready);
      case VoiceCaptureFailed(:final problem):
        _captureProblem = problem;
        _show(VoiceSheetStep.failed);
    }
  }

  void _dropCapture() {
    final capture = _capture;
    _capture = null;
    _holding = false;
    if (capture == null) return;
    capture.removeListener(_captureChanged);
    capture.dispose();
  }

  void _micDown(Duration at) {
    switch (_step) {
      case VoiceSheetStep.ready:
        _listen(stopOnPause: false);
        // After _listen, which lets go of any earlier hold.
        _pressedAt = at;
        _holding = true;
      case VoiceSheetStep.listening when _capture?.stopOnPause ?? false:
        // A tap while listening is "that's all".
        unawaited(_capture!.finish());
      default:
        break;
    }
  }

  void _micUp(Duration at) {
    if (!_holding) return;
    _holding = false;
    final capture = _capture;
    if (capture == null) return;
    if (at - (_pressedAt ?? at) < _tapLimit) {
      capture.stopOnPause = true;
    } else {
      unawaited(capture.finish());
    }
    setState(() {});
  }

  /// Screen readers get one action: start, or stop and write it down.
  void _micToggle() {
    switch (_step) {
      case VoiceSheetStep.ready:
        _listen(stopOnPause: true);
      case VoiceSheetStep.listening:
        unawaited(_capture?.finish());
      default:
        break;
    }
  }

  void _typeInstead() =>
      Navigator.of(context).pop(const SpeechInputResult.cancelled());

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final view = VoiceSheetView(
      step: _step,
      prompt: widget.prompt,
      note: _note,
      level: _capture?.level ?? 0,
      holding: _holding,
      download: VoiceDownloadView.of(prefetch),
      captureProblem: _captureProblem,
      onClose: () => Navigator.of(context).pop(),
      onTypeInstead: _typeInstead,
      onAllowMic: _allowMic,
      onOpenSettings: _openSettings,
      onDownloadNow: _downloadNow,
      onDownloadAgain: _downloadAgain,
      onTryAgain: () => _show(VoiceSheetStep.ready),
      onMicDown: _micDown,
      onMicUp: _micUp,
      onMicToggle: _micToggle,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: CurreShape.sheet,
        boxShadow: CurreElevation.e2,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CurreSpace.s5),
          // The sheet grows and shrinks with its step instead of jumping;
          // with reduced motion it simply changes.
          child: MediaQuery.disableAnimationsOf(context)
              ? view
              : AnimatedSize(
                  duration: CurreMotion.base,
                  curve: CurreMotion.standard,
                  alignment: Alignment.topCenter,
                  child: view,
                ),
        ),
      ),
    );
  }
}

/// Where the quiet voice download stands, for a screen to draw.
@immutable
class VoiceDownloadView {
  const VoiceDownloadView({
    required this.phase,
    required this.total,
    this.received = 0,
    this.problem,
  });

  factory VoiceDownloadView.of(VoicePrefetcher prefetch) => VoiceDownloadView(
    phase: prefetch.phase,
    total: prefetch.total,
    received: prefetch.received,
    problem: prefetch.problem,
  );

  final VoicePrefetchPhase phase;
  final int received;
  final int total;
  final VoiceDownloadProblem? problem;

  double get fraction =>
      total == 0 ? 0 : (received / total).clamp(0.0, 1.0).toDouble();

  int get percent => (fraction * 100).floor();

  int get remaining => (total - received).clamp(0, total);

  bool get downloading => phase == VoicePrefetchPhase.downloading;

  /// "47 MB of 104 MB".
  String get amount =>
      '${formatMegabytes(received)} of ${formatMegabytes(total)}';
}

/// Renders one step of the voice sheet. It decides nothing: [VoiceSheet]
/// and the widget tests drive it.
class VoiceSheetView extends StatelessWidget {
  const VoiceSheetView({
    super.key,
    required this.step,
    required this.download,
    this.prompt,
    this.note,
    this.level = 0,
    this.holding = false,
    this.captureProblem,
    this.onClose,
    this.onTypeInstead,
    this.onAllowMic,
    this.onOpenSettings,
    this.onDownloadNow,
    this.onDownloadAgain,
    this.onTryAgain,
    this.onMicDown,
    this.onMicUp,
    this.onMicToggle,
  });

  final VoiceSheetStep step;
  final String? prompt;

  /// A short line for this step, such as the files having just arrived.
  final String? note;

  /// Live mic loudness, 0 to 1.
  final double level;

  /// The mic is held down right now.
  final bool holding;

  /// The quiet download, for the getting-ready note.
  final VoiceDownloadView download;
  final VoiceCaptureProblem? captureProblem;
  final VoidCallback? onClose;
  final VoidCallback? onTypeInstead;
  final VoidCallback? onAllowMic;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onDownloadNow;
  final VoidCallback? onDownloadAgain;
  final VoidCallback? onTryAgain;

  /// Pointer down and up on the mic, with the events' timestamps.
  final ValueChanged<Duration>? onMicDown;
  final ValueChanged<Duration>? onMicUp;
  final VoidCallback? onMicToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Column(
      key: ValueKey('voice-${step.name}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: CurreSpace.s2),
                child: Text(
                  prompt ?? 'Say it instead',
                  style: type.title.weight(680).copyWith(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: CurreSpace.s3),
            RoundGlyphButton(
              glyph: CurreGlyphKind.close,
              label: 'Close',
              onPressed: onClose,
            ),
          ],
        ),
        const SizedBox(height: CurreSpace.s4),
        ..._body(context, colors, type),
        const SizedBox(height: CurreSpace.s5),
        Row(
          children: [
            CurreGlyph(CurreGlyphKind.privacy, size: 16, color: colors.ink3),
            const SizedBox(width: CurreSpace.s2),
            Expanded(
              child: Text(
                'On this phone · nothing you say is saved or sent',
                style: type.meta,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _body(BuildContext context, CurreColors colors, CurreType type) {
    final size = formatMegabytes(download.total);
    Widget lead(String text) => Text(text, style: type.label.weight(640));
    Widget line(String text) =>
        Text(text, style: type.body.copyWith(color: colors.ink2));
    Widget? noteLine() => note == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: CurreSpace.s2),
            child: Text(
              note!,
              style: type.caption.copyWith(color: colors.emberText),
            ),
          );
    List<Widget> actions(Widget primary) => [
      const SizedBox(height: CurreSpace.s5),
      primary,
      const SizedBox(height: CurreSpace.s2),
      CurreSecondaryButton(label: 'Type instead', onPressed: onTypeInstead),
    ];

    switch (step) {
      case VoiceSheetStep.checking:
        return [
          const SizedBox(height: CurreSpace.s8),
          HorizonLine(
            scanning: !MediaQuery.disableAnimationsOf(context),
            semanticLabel: 'Getting voice typing ready',
          ),
          const SizedBox(height: CurreSpace.s8),
        ];
      case VoiceSheetStep.gettingReady:
        return [
          lead(voiceGettingReadyMessage),
          const SizedBox(height: CurreSpace.s4),
          VoiceDownloadGauge(download: download),
          const SizedBox(height: CurreSpace.s5),
          if (download.downloading)
            CurrePrimaryButton(label: 'Type instead', onPressed: onTypeInstead)
          else ...[
            CurrePrimaryButton(
              key: const Key('voice-download-now'),
              label: 'Download now · ${formatMegabytes(download.remaining)}',
              onPressed: onDownloadNow,
            ),
            const SizedBox(height: CurreSpace.s2),
            CurreSecondaryButton(
              label: 'Type instead',
              onPressed: onTypeInstead,
            ),
          ],
        ];
      case VoiceSheetStep.askMic:
        return [
          lead('Speak instead of typing'),
          const SizedBox(height: CurreSpace.s2),
          line(voicePermissionExplanation),
          ?noteLine(),
          ...actions(
            CurrePrimaryButton(
              key: const Key('voice-allow-mic'),
              label: 'Allow the mic',
              glyph: CurreGlyphKind.speak,
              onPressed: onAllowMic,
            ),
          ),
        ];
      case VoiceSheetStep.micBlocked:
        return [
          lead('The mic is off for Curre'),
          const SizedBox(height: CurreSpace.s2),
          line(
            'Turn on Microphone for Curre in your phone’s settings, then come '
            'back. $voicePermissionExplanation',
          ),
          ...actions(
            CurrePrimaryButton(
              key: const Key('voice-open-settings'),
              label: 'Open phone settings',
              glyph: CurreGlyphKind.androidSettings,
              onPressed: onOpenSettings,
            ),
          ),
        ];
      case VoiceSheetStep.ready || VoiceSheetStep.listening:
        final listening = step == VoiceSheetStep.listening;
        return [
          const SizedBox(height: CurreSpace.s2),
          Center(
            child: _MicButton(
              level: listening ? level : 0,
              listening: listening,
              onDown: onMicDown,
              onUp: onMicUp,
              onToggle: onMicToggle,
            ),
          ),
          const SizedBox(height: CurreSpace.s3),
          Text(
            !listening
                ? 'Tap or hold the mic, then speak.'
                : holding
                ? 'Listening… let go when you’re done.'
                : 'Listening… pause when you’re done, or tap the mic.',
            style: type.body.copyWith(color: colors.ink2),
            textAlign: TextAlign.center,
          ),
          if (note != null && !listening)
            Padding(
              padding: const EdgeInsets.only(top: CurreSpace.s2),
              child: Text(
                note!,
                style: type.caption.copyWith(color: colors.emberText),
                textAlign: TextAlign.center,
              ),
            ),
        ];
      case VoiceSheetStep.writing:
        return [
          const SizedBox(height: CurreSpace.s8),
          HorizonLine(
            scanning: !MediaQuery.disableAnimationsOf(context),
            semanticLabel: 'Writing down what you said',
          ),
          const SizedBox(height: CurreSpace.s3),
          Text(
            'Writing it down…',
            style: type.body.copyWith(color: colors.ink2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CurreSpace.s6),
        ];
      case VoiceSheetStep.failed:
        final model = captureProblem == VoiceCaptureProblem.model;
        return [
          lead(model ? 'Voice typing couldn’t start' : 'The mic didn’t start'),
          const SizedBox(height: CurreSpace.s2),
          line(
            model
                ? 'Downloading the voice files again ($size) usually fixes it.'
                : 'If another app is using the mic, close it and try again.',
          ),
          ...actions(
            CurrePrimaryButton(
              key: const Key('voice-failed-retry'),
              label: model ? 'Download again' : 'Try again',
              onPressed: model ? onDownloadAgain : onTryAgain,
            ),
          ),
        ];
    }
  }
}

/// One plain line for where the voice download stands.
String voiceDownloadStatus(VoiceDownloadView download) {
  final size = formatMegabytes(download.total);
  final soFar = download.received > 0 ? ' · ${download.amount} so far' : '';
  return switch (download.phase) {
    VoicePrefetchPhase.checking => 'Checking…',
    VoicePrefetchPhase.ready => 'Ready · works offline',
    VoicePrefetchPhase.downloading =>
      'Getting ready ${download.percent}% · ${download.amount}',
    VoicePrefetchPhase.waitingForWifi => 'Waiting for Wi-Fi$soFar',
    VoicePrefetchPhase.waitingForConnection => 'Waiting for a connection$soFar',
    VoicePrefetchPhase.waitingForBattery => 'Waiting for more battery$soFar',
    VoicePrefetchPhase.stopped => switch (download.problem) {
      VoiceDownloadProblem.storage => 'Stopped · your phone needs $size free',
      _ => 'Stopped · it tries again later$soFar',
    },
    VoicePrefetchPhase.off =>
      'Not on this phone · $size, when you next use the mic',
    VoicePrefetchPhase.unavailable => 'Not available on this phone',
  };
}

/// The voice download as water filling a small pane, the way the
/// check-in's water rises with the day: the level is the download's
/// percent, its surface moves in slow waves (still under reduce-motion)
/// and the same words sit beside it for anyone not looking at the water.
class VoiceDownloadGauge extends StatelessWidget {
  const VoiceDownloadGauge({super.key, required this.download});

  static const _size = 56.0;

  final VoiceDownloadView download;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final brightness = Theme.of(context).brightness;
    final ready = download.phase == VoicePrefetchPhase.ready;
    return Row(
      key: const Key('voice-download-gauge'),
      children: [
        ClipRRect(
          borderRadius: CurreShape.md,
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: colors.sky(Session.afternoon).bg,
              borderRadius: CurreShape.md,
            ),
            child: RisingWater(
              key: const Key('voice-download-water'),
              level: ready ? 1 : download.fraction,
              // Only a running download moves; a waiting one holds still.
              animate: download.downloading,
              style: SkyScene.waterStyle(colors, brightness, Session.afternoon),
              semanticLabel: 'Voice download',
            ),
          ),
        ),
        const SizedBox(width: CurreSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ready ? '100%' : '${download.percent}%',
                style: type.label.weight(640),
              ),
              Text(
                _detail(download),
                style: type.caption.copyWith(color: colors.ink2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _detail(VoiceDownloadView download) {
    final size = formatMegabytes(download.total);
    return switch (download.phase) {
      VoicePrefetchPhase.downloading =>
        '${download.amount}. It keeps going if you close this.',
      VoicePrefetchPhase.waitingForWifi =>
        'It downloads by itself on Wi-Fi, $size once.',
      VoicePrefetchPhase.waitingForConnection =>
        'No connection right now. It picks up where it stopped.',
      VoicePrefetchPhase.waitingForBattery =>
        'It waits for more battery, or a charger.',
      VoicePrefetchPhase.stopped => switch (download.problem) {
        VoiceDownloadProblem.storage =>
          'Your phone is short on space. Voice typing needs $size free.',
        VoiceDownloadProblem.damaged =>
          'A file arrived damaged, so it was thrown away. Try again.',
        _ =>
          'The voice files couldn’t be reached. Try again in a little while.',
      },
      VoicePrefetchPhase.ready => 'Ready. Voice typing now works offline.',
      _ => 'Voice typing runs on this phone and needs $size once.',
    };
  }
}

/// The big mic. Press and hold to talk; a short tap listens until a pause.
/// While listening, its ring swells with the voice it hears.
class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.level,
    required this.listening,
    this.onDown,
    this.onUp,
    this.onToggle,
  });

  static const _size = 88.0;

  final double level;
  final bool listening;
  final ValueChanged<Duration>? onDown;
  final ValueChanged<Duration>? onUp;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    return Semantics(
      key: const Key('voice-mic'),
      button: true,
      label: listening ? 'Stop and write it down' : 'Start listening',
      excludeSemantics: true,
      onTap: onToggle,
      child: Listener(
        onPointerDown: (event) => onDown?.call(event.timeStamp),
        onPointerUp: (event) => onUp?.call(event.timeStamp),
        onPointerCancel: (event) => onUp?.call(event.timeStamp),
        child: SizedBox.square(
          dimension: _size * 1.7,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Live level, not decoration: it moves even with reduced
              // motion, only without easing.
              AnimatedScale(
                key: const Key('voice-level'),
                scale: listening ? 1 + level * .7 : 1,
                duration: CurreMotion.of(context, CurreMotion.tap),
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.ember.withValues(alpha: listening ? .24 : 0),
                  ),
                ),
              ),
              Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.ember,
                  boxShadow: CurreElevation.e2,
                ),
                child: Center(
                  child: CurreGlyph(
                    CurreGlyphKind.speak,
                    size: 36,
                    color: colors.markInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings line for voice typing: where it runs, where its quiet download
/// stands, whether it may use mobile data, and a way to take the files off
/// the phone.
class VoiceSettingsCard extends StatefulWidget {
  const VoiceSettingsCard({super.key, required this.speech});

  final SpeechInputService speech;

  @override
  State<VoiceSettingsCard> createState() => _VoiceSettingsCardState();
}

class _VoiceSettingsCardState extends State<VoiceSettingsCard> {
  VoicePrefetcher get prefetch => widget.speech.prefetch;

  @override
  void initState() {
    super.initState();
    prefetch.addListener(_changed);
    // Settings opens after setup, when the quiet download runs anyway.
    unawaited(prefetch.start());
  }

  @override
  void dispose() {
    prefetch.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmRemove() async {
    final size = formatMegabytes(
      prefetch.received > 0 ? prefetch.received : prefetch.total,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove the voice files?'),
        content: Text(
          'This frees $size. Voice typing downloads again only when you '
          'next use the mic, or turn it back on here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep them'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    var removed = true;
    try {
      await prefetch.remove();
    } on Object {
      removed = false;
    }
    if (!mounted) return;
    showCurreSnack(
      context,
      removed ? 'Voice files removed.' : 'The voice files couldn’t be removed.',
    );
  }

  Future<void> _setOnMobileData(bool value) => prefetch.setOnMobileData(value);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final download = VoiceDownloadView.of(prefetch);
    final phase = download.phase;
    final showWater =
        phase != VoicePrefetchPhase.ready &&
        phase != VoicePrefetchPhase.off &&
        phase != VoicePrefetchPhase.checking &&
        phase != VoicePrefetchPhase.unavailable;
    return Material(
      key: const Key('voice-settings'),
      color: colors.raised,
      shape: RoundedRectangleBorder(
        borderRadius: CurreShape.md,
        side: BorderSide(color: colors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CurreGlyph(CurreGlyphKind.speak, color: colors.ink),
                const SizedBox(width: CurreSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Voice: on this phone', style: type.label),
                      Text(
                        voiceDownloadStatus(download),
                        key: const Key('voice-status'),
                        style: type.caption.copyWith(color: colors.ink2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showWater) ...[
              const SizedBox(height: CurreSpace.s3),
              VoiceDownloadGauge(download: download),
            ],
            const SizedBox(height: CurreSpace.s2),
            Text(
              'Voice typing needs no account and, once downloaded, no '
              'internet. Nothing you say is saved or sent.',
              style: type.caption.copyWith(color: colors.ink3),
            ),
            if (phase != VoicePrefetchPhase.unavailable)
              SwitchListTile.adaptive(
                key: const Key('voice-mobile-data'),
                contentPadding: EdgeInsets.zero,
                title: Text('Download voice on mobile data', style: type.body),
                subtitle: Text(
                  'Off: it waits for Wi-Fi. About '
                  '${formatMegabytes(download.total)}, once.',
                  style: type.caption.copyWith(color: colors.ink2),
                ),
                value: prefetch.onMobileData,
                onChanged: _setOnMobileData,
              ),
            if (phase == VoicePrefetchPhase.off) ...[
              const SizedBox(height: CurreSpace.s2),
              CurreSecondaryButton(
                key: const Key('voice-turn-on'),
                label: 'Download voice files',
                onPressed: () => unawaited(prefetch.wantVoice()),
              ),
            ],
            if (download.received > 0) ...[
              const SizedBox(height: CurreSpace.s2),
              CurreSecondaryButton(
                key: const Key('voice-remove'),
                label: 'Remove voice files',
                onPressed: _confirmRemove,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
