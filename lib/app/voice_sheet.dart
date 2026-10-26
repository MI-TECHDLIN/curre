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
const _needsDownloadMessage =
    'Voice typing needs its one-time download. You can type instead.';
const _couldNotStartMessage =
    "Voice typing couldn't start. You can type instead.";

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
  askMic,
  micBlocked,
  askDownload,
  downloading,
  downloadFailed,
  ready,
  listening,
  writing,
  failed,
}

/// Voice typing in one sheet: the mic permission, the one-time download,
/// then hold or tap the mic and speak.
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
  VoiceDownloadCancel? _downloadCancel;
  VoiceDownloadProblem? _downloadProblem;
  VoiceCaptureProblem? _captureProblem;
  var _received = 0;
  var _onPhone = 0;
  var _holding = false;
  Duration? _pressedAt;

  SpeechInputService get speech => widget.speech;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The mic tap that opened the sheet is the tap that starts listening.
    unawaited(_prepare(autoStart: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _downloadCancel?.cancel();
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
      VoiceSheetStep.downloadFailed => const SpeechInputResult.unavailable(
        _needsDownloadMessage,
      ),
      VoiceSheetStep.failed => const SpeechInputResult.unavailable(
        _couldNotStartMessage,
      ),
      _ => const SpeechInputResult.cancelled(),
    });
  }

  Future<void> _prepare({required bool autoStart}) async {
    final MicAccess access;
    final VoiceModelPaths? model;
    try {
      access = await speech.microphone.access();
      if (access != MicAccess.granted) {
        _show(
          access == MicAccess.blocked
              ? VoiceSheetStep.micBlocked
              : VoiceSheetStep.askMic,
        );
        return;
      }
      model = await speech.models.installed();
      if (model == null) {
        _onPhone = await speech.models.bytesOnPhone();
        _show(VoiceSheetStep.askDownload);
        return;
      }
    } on Object {
      _captureProblem = VoiceCaptureProblem.microphone;
      _show(VoiceSheetStep.failed);
      return;
    }
    if (!mounted) return;
    _model = model;
    if (autoStart) {
      _listen(stopOnPause: true);
    } else {
      _show(VoiceSheetStep.ready);
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

  Future<void> _download() async {
    final cancel = _downloadCancel = VoiceDownloadCancel();
    _received = _onPhone;
    _show(VoiceSheetStep.downloading);
    try {
      final model = await speech.models.download(
        cancel: cancel,
        onProgress: (received, _) {
          if (mounted) setState(() => _received = received);
        },
      );
      _model = model;
      _show(
        VoiceSheetStep.ready,
        note: 'Ready. Voice typing now works offline.',
      );
    } on VoiceDownloadCancelled {
      if (!mounted) return;
      _onPhone = await _bytesOnPhone();
      _show(
        VoiceSheetStep.askDownload,
        note:
            'Paused at ${formatMegabytes(_onPhone)}. '
            'It picks up from there.',
      );
    } on VoiceDownloadException catch (error) {
      _downloadProblem = error.problem;
      _show(VoiceSheetStep.downloadFailed);
    } on Object {
      _downloadProblem = VoiceDownloadProblem.server;
      _show(VoiceSheetStep.downloadFailed);
    } finally {
      if (identical(_downloadCancel, cancel)) _downloadCancel = null;
    }
  }

  Future<int> _bytesOnPhone() async {
    try {
      return await speech.models.bytesOnPhone();
    } on Object {
      return 0;
    }
  }

  void _stopDownload() => _downloadCancel?.cancel();

  /// The voice files would not load: fetch them fresh.
  Future<void> _downloadAgain() async {
    try {
      await speech.models.remove();
    } on Object {
      // A fresh download overwrites what is left.
    }
    _model = null;
    _onPhone = 0;
    await _download();
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
      received: _received,
      onPhone: _onPhone,
      total: speech.models.spec.bytes,
      downloadProblem: _downloadProblem,
      captureProblem: _captureProblem,
      onClose: () => Navigator.of(context).pop(),
      onTypeInstead: _typeInstead,
      onAllowMic: _allowMic,
      onOpenSettings: _openSettings,
      onDownload: _download,
      onStopDownload: _stopDownload,
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

/// Renders one step of the voice sheet. It decides nothing: [VoiceSheet]
/// and the widget tests drive it.
class VoiceSheetView extends StatelessWidget {
  const VoiceSheetView({
    super.key,
    required this.step,
    required this.total,
    this.prompt,
    this.note,
    this.level = 0,
    this.holding = false,
    this.received = 0,
    this.onPhone = 0,
    this.downloadProblem,
    this.captureProblem,
    this.onClose,
    this.onTypeInstead,
    this.onAllowMic,
    this.onOpenSettings,
    this.onDownload,
    this.onStopDownload,
    this.onDownloadAgain,
    this.onTryAgain,
    this.onMicDown,
    this.onMicUp,
    this.onMicToggle,
  });

  final VoiceSheetStep step;
  final String? prompt;

  /// A short line for this step, such as a stopped download.
  final String? note;

  /// Live mic loudness, 0 to 1.
  final double level;

  /// The mic is held down right now.
  final bool holding;
  final int received;
  final int onPhone;
  final int total;
  final VoiceDownloadProblem? downloadProblem;
  final VoiceCaptureProblem? captureProblem;
  final VoidCallback? onClose;
  final VoidCallback? onTypeInstead;
  final VoidCallback? onAllowMic;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onDownload;
  final VoidCallback? onStopDownload;
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
    final size = formatMegabytes(total);
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
      case VoiceSheetStep.askDownload:
        final resuming = onPhone > 0 && onPhone < total;
        return [
          lead('One download, then it works offline'),
          const SizedBox(height: CurreSpace.s2),
          line(
            'Voice typing runs on this phone, so it needs $size once. '
            'Wi-Fi is best.',
          ),
          ?noteLine(),
          ...actions(
            CurrePrimaryButton(
              key: const Key('voice-download'),
              label: resuming ? 'Resume the download' : 'Download $size',
              onPressed: onDownload,
            ),
          ),
        ];
      case VoiceSheetStep.downloading:
        final fraction = total == 0 ? 0.0 : (received / total).clamp(0.0, 1.0);
        return [
          lead('Downloading voice typing'),
          const SizedBox(height: CurreSpace.s4),
          _ProgressLine(value: fraction),
          const SizedBox(height: CurreSpace.s2),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatMegabytes(received)} of $size',
                  style: type.meta,
                ),
              ),
              Text('${(fraction * 100).floor()}%', style: type.meta),
            ],
          ),
          const SizedBox(height: CurreSpace.s3),
          Text(
            'Closing this pauses it. It picks up where it stopped.',
            style: type.caption.copyWith(color: colors.ink3),
          ),
          const SizedBox(height: CurreSpace.s5),
          CurreSecondaryButton(label: 'Pause', onPressed: onStopDownload),
        ];
      case VoiceSheetStep.downloadFailed:
        return [
          lead('The download stopped'),
          const SizedBox(height: CurreSpace.s2),
          line(switch (downloadProblem) {
            VoiceDownloadProblem.storage =>
              'Your phone is short on space. Voice typing needs $size free.',
            VoiceDownloadProblem.damaged =>
              'A file arrived damaged, so it was thrown away. Try again.',
            VoiceDownloadProblem.server => 'The voice files couldn’t be reached. Try again in a little while.',
            _ =>
              'No connection right now. What arrived is kept, so it picks up '
                  'where it stopped. Try again, ideally on Wi-Fi.',
          }),
          ...actions(
            CurrePrimaryButton(
              key: const Key('voice-retry-download'),
              label: 'Try again',
              onPressed: onDownload,
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

/// Download progress along the horizon: ember fills a hairline.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    return Semantics(
      label: 'Download progress',
      value: '${(value * 100).floor()}%',
      child: ClipRRect(
        borderRadius: CurreShape.xs,
        child: SizedBox(
          height: 6,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: colors.hairline),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: ColoredBox(color: colors.ember),
              ),
            ],
          ),
        ),
      ),
    );
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

/// Settings line for voice typing: where it runs, how much room the voice
/// files take, and a way to take them off the phone.
class VoiceSettingsCard extends StatefulWidget {
  const VoiceSettingsCard({super.key, required this.speech});

  final SpeechInputService speech;

  @override
  State<VoiceSettingsCard> createState() => _VoiceSettingsCardState();
}

class _VoiceSettingsCardState extends State<VoiceSettingsCard> {
  int? _onPhone;
  var _installed = false;

  VoiceModelStore get models => widget.speech.models;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    var installed = false;
    var onPhone = 0;
    try {
      installed = await models.installed() != null;
      onPhone = await models.bytesOnPhone();
    } on Object {
      // Shown as not downloaded; the mic sheet explains any problem.
    }
    if (!mounted) return;
    setState(() {
      _installed = installed;
      _onPhone = onPhone;
    });
  }

  Future<void> _confirmRemove() async {
    final size = formatMegabytes(_onPhone ?? models.spec.bytes);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove the voice files?'),
        content: Text(
          'This frees $size. Voice typing will need its one-time download '
          'again the next time you use the mic.',
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
      await models.remove();
    } on Object {
      removed = false;
    }
    await _refresh();
    if (!mounted) return;
    showCurreSnack(
      context,
      removed ? 'Voice files removed.' : 'The voice files couldn’t be removed.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final onPhone = _onPhone;
    final size = formatMegabytes(models.spec.bytes);
    final status = switch (onPhone) {
      null => 'Checking…',
      _ when _installed =>
        '${formatMegabytes(onPhone)} on this phone · works offline',
      > 0 => 'Download paused · ${formatMegabytes(onPhone)} of $size',
      _ => 'Not downloaded yet · $size once, the first time you use the mic',
    };
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
                        status,
                        style: type.caption.copyWith(color: colors.ink2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: CurreSpace.s2),
            Text(
              'Voice typing needs no account and, once downloaded, no '
              'internet. Nothing you say is saved or sent.',
              style: type.caption.copyWith(color: colors.ink3),
            ),
            if ((onPhone ?? 0) > 0) ...[
              const SizedBox(height: CurreSpace.s4),
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
