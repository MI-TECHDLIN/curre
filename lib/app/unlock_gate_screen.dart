import 'dart:async';

import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../doors/door_models.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';

enum _GateState { ask, thinking, result, waiting }

class UnlockGateScreen extends StatefulWidget {
  const UnlockGateScreen({
    super.key,
    required this.controller,
    required this.app,
    this.initialReason,
    this.initialResponse,
    this.autoJudge = false,
    this.overrideDuration = overrideWait,
  });

  final CurreController controller;
  final LaunchableApp app;
  final String? initialReason;
  final UnlockResponse? initialResponse;
  final bool autoJudge;
  final Duration overrideDuration;

  @override
  State<UnlockGateScreen> createState() => _UnlockGateScreenState();
}

class _UnlockGateScreenState extends State<UnlockGateScreen> {
  late final TextEditingController _reason = TextEditingController(
    text: widget.initialReason,
  );
  var _state = _GateState.ask;
  UnlockResponse? _response;
  Timer? _timer;
  DateTime? _deadline;
  Duration _remaining = overrideWait;
  var _retryCount = 0;
  String? _firstReason;
  var _overrideFinishing = false;
  var _leaving = false;

  CurreController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    if (widget.initialResponse != null) {
      _response = widget.initialResponse;
      _state = _GateState.result;
      if (_response!.outcome == UnlockOutcome.unavailable) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _startOverride());
      }
    } else if (widget.autoJudge && _reason.text.trim().runes.length >= 8) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _judge());
    }
  }

  @override
  void dispose() {
    _leaving = true;
    _timer?.cancel();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _leaving = true;
          _timer?.cancel();
        }
      },
      child: CurrePage(
        background: colors.sunk,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CurreSpace.gutter,
                CurreSpace.s3,
                CurreSpace.gutter,
                0,
              ),
              child: CurreTopBar(
                title: 'Why open ${widget.app.label} now?',
                subtitle: 'No app icon here · this is a deliberate choice',
                maxTitleLines: 3,
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: CurreMotion.base,
                child: switch (_state) {
                  _GateState.ask => _ask(context),
                  _GateState.thinking => _thinking(context),
                  _GateState.result => _result(context),
                  _GateState.waiting => _waiting(context),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ask(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final length = _reason.text.runes.length;
    return Column(
      key: const ValueKey('ask'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(CurreSpace.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Say what you’ll do and who or what it’s for, and how long if you know. Curre will open right there.',
                  style: type.body.copyWith(color: colors.ink2),
                ),
                const SizedBox(height: CurreSpace.s4),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.raised,
                    borderRadius: CurreShape.dome,
                    border: Border.all(color: colors.hairline),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(CurreSpace.s4),
                    child: TextField(
                      key: const Key('unlock-reason'),
                      controller: _reason,
                      autofocus: widget.initialReason == null,
                      minLines: 4,
                      maxLines: 8,
                      maxLength: 300,
                      style: type.youLarge,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Your reason',
                        hintText: 'reply Ada about rehearsal',
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(height: CurreSpace.s2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.activePlan == null
                            ? 'Plan: none'
                            : 'Plan: ${controller.activePlan!.intention}',
                        style: type.meta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('$length/300', style: type.meta),
                  ],
                ),
                if (_retryCount > 0) ...[
                  const SizedBox(height: CurreSpace.s3),
                  if (_firstReason case final firstReason?) ...[
                    Text(
                      firstReason,
                      style: type.youSmall.copyWith(
                        color: colors.ink3,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: CurreSpace.s2),
                  ],
                  Text(
                    'Retry 1 of 1 · be specific about the task.',
                    style: type.caption.copyWith(color: colors.emberText),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(CurreSpace.gutter),
          child: CurrePrimaryButton(
            label: _retryCount == 0 ? 'Ask Curre' : 'Ask again',
            glyph: CurreGlyphKind.go,
            onPressed: length < 8 || length > 300 ? null : _judge,
          ),
        ),
      ],
    );
  }

  Widget _thinking(BuildContext context) {
    final type = Theme.of(context).extension<CurreType>()!;
    return SingleChildScrollView(
      key: const ValueKey('thinking'),
      padding: const EdgeInsets.all(CurreSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: CurreSpace.s6),
          Text(_reason.text, style: type.youLarge),
          const SizedBox(height: CurreSpace.s6),
          const HorizonLine(
            scanning: true,
            semanticLabel: 'Reading your reason',
          ),
          const SizedBox(height: CurreSpace.s4),
          Text('Reading your reason · gives up at 8 s', style: type.meta),
          const SizedBox(height: CurreSpace.s5),
          const _PipelineStep(
            glyph: CurreGlyphKind.privacy,
            label: 'Guard · checks for steering',
          ),
          const _PipelineStep(
            glyph: CurreGlyphKind.kindTask,
            label: 'Decide · kind and door',
          ),
          const _PipelineStep(
            glyph: CurreGlyphKind.editSpecify,
            label: 'Extract · who, what, how long',
          ),
          const _PipelineStep(
            glyph: CurreGlyphKind.door,
            label: 'Find the door · on this phone',
          ),
        ],
      ),
    );
  }

  Widget _result(BuildContext context) {
    final response = _response!;
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final outcome = response.outcome.designOutcome;
    return Column(
      key: ValueKey('result-${response.outcome.name}'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(CurreSpace.gutter),
            children: [
              if (response.kind != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: KindChip(
                    kind: response.kind!,
                    confidence: response.confidence,
                    threshold: controller.settings.threshold,
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: _NotJudgedChip(
                    label: response.outcome == UnlockOutcome.flagged
                        ? 'Not judged · Guard stopped'
                        : 'Not judged · no answer',
                  ),
                ),
              const SizedBox(height: CurreSpace.s3),
              OutcomeCard(
                outcome: outcome,
                headline: _headline(response),
                body: _body(response),
              ),
              const SizedBox(height: CurreSpace.s4),
              Text('Why', style: type.label),
              const SizedBox(height: CurreSpace.s2),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.raised,
                  borderRadius: CurreShape.md,
                  border: Border.all(color: colors.hairline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(CurreSpace.s4),
                  child: SpanText(
                    _reason.text,
                    style: type.you,
                    highlights: _reasonHighlights(context, response),
                  ),
                ),
              ),
              if (response.guard != null) ...[
                const SizedBox(height: CurreSpace.s3),
                Text(
                  'Guard · ${response.guard!.category}: “${response.guardQuoteText}”',
                  style: type.caption.copyWith(color: colors.emberText),
                ),
              ],
              if (controller.lastUnlockCall case final receipt?) ...[
                const SizedBox(height: CurreSpace.s3),
                Text(
                  '${receipt.endpoint} · ${receipt.elapsed.inMilliseconds} ms · '
                  '${receipt.usage?.credits ?? '—'} credits',
                  style: type.meta,
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CurreSpace.gutter,
            CurreSpace.s2,
            CurreSpace.gutter,
            CurreSpace.s4,
          ),
          child: _resultActions(context, response),
        ),
      ],
    );
  }

  Widget _resultActions(BuildContext context, UnlockResponse response) {
    return switch (response.outcome) {
      UnlockOutcome.open => CurrePrimaryButton(
        label: _openLabel(response),
        glyph: CurreGlyphKind.door,
        onPressed: _openGranted,
      ),
      UnlockOutcome.specify => Column(
        children: [
          if (_retryCount == 0) ...[
            CurrePrimaryButton(
              label: 'Ask again',
              glyph: CurreGlyphKind.editSpecify,
              onPressed: () => setState(() {
                _retryCount = 1;
                _firstReason = _reason.text.trim();
                _reason.clear();
                _state = _GateState.ask;
              }),
            ),
            const SizedBox(height: CurreSpace.s2),
          ],
          CurreSecondaryButton(
            label: 'Open after 60 s',
            glyph: CurreGlyphKind.overrideWait,
            onPressed: _startOverride,
          ),
        ],
      ),
      UnlockOutcome.later || UnlockOutcome.flagged => Column(
        children: [
          CurreSecondaryButton(
            label: 'Open after 60 s',
            glyph: CurreGlyphKind.overrideWait,
            onPressed: _startOverride,
          ),
          const SizedBox(height: CurreSpace.s2),
          CurreSecondaryButton(
            label: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      UnlockOutcome.unavailable => CurreSecondaryButton(
        label: 'Try again',
        onPressed: () {
          _timer?.cancel();
          setState(() => _state = _GateState.ask);
        },
      ),
    };
  }

  Widget _waiting(BuildContext context) {
    final response = _response!;
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Column(
      key: const ValueKey('waiting'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(CurreSpace.gutter),
            child: Column(
              children: [
                if (response.kind != null)
                  KindChip(
                    kind: response.kind!,
                    confidence: response.confidence,
                    threshold: controller.settings.threshold,
                  )
                else
                  _NotJudgedChip(
                    label: response.outcome == UnlockOutcome.unavailable
                        ? 'No answer · local override'
                        : 'Not judged',
                  ),
                const SizedBox(height: CurreSpace.s5),
                OutcomeCard(
                  outcome: response.outcome.designOutcome,
                  headline: response.outcome == UnlockOutcome.unavailable
                      ? 'No answer · opening anyway, in a minute'
                      : '${widget.app.label} opens after the wait',
                  body: response.outcome == UnlockOutcome.unavailable
                      ? 'The gate did not reply. You may be offline.'
                      : 'You chose to wait, and that’s allowed.',
                ),
                const SizedBox(height: CurreSpace.s6),
                Text('${widget.app.label} opens in', style: type.title),
                const SizedBox(height: CurreSpace.s2),
                Text(
                  formatDuration(_remaining),
                  key: const Key('override-countdown'),
                  style: type.figureXL,
                ),
                RisingDisc(
                  key: ValueKey(_deadline),
                  duration: widget.overrideDuration,
                  onComplete: _finishOverride,
                  semanticLabel:
                      '${formatDuration(_remaining)} until ${widget.app.label} opens',
                ),
                const SizedBox(height: CurreSpace.s3),
                Text(
                  'Leaving this screen cancels the wait. A finished wait is logged as an override.',
                  style: type.caption.copyWith(color: colors.ink3),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(CurreSpace.gutter),
          child: Column(
            children: [
              if (response.outcome == UnlockOutcome.unavailable) ...[
                CurrePrimaryButton(
                  label: 'Try again',
                  onPressed: _retryUnavailable,
                ),
                const SizedBox(height: CurreSpace.s2),
              ],
              CurreSecondaryButton(
                label: 'Cancel',
                onPressed: () {
                  _timer?.cancel();
                  setState(() => _state = _GateState.result);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<SpanHighlight> _reasonHighlights(
    BuildContext context,
    UnlockResponse response,
  ) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final duration = _durationSpan(_reason.text, response.minutes);
    return <SpanHighlight>[
      if (response.person case final span?)
        SpanHighlight(
          span.start,
          span.end,
          style: type.you.copyWith(
            backgroundColor: colors.link(1).mark,
            color: colors.markInk,
          ),
        ),
      if (response.target case final span?)
        SpanHighlight(
          span.start,
          span.end,
          style: type.you.copyWith(
            backgroundColor: colors.marker,
            color: colors.markInk,
          ),
        ),
      if (duration case final span?)
        SpanHighlight(
          span.$1,
          span.$2,
          style: type.you.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: colors.ember,
            decorationThickness: 2,
          ),
        ),
      if (response.guard?.quote case final span?)
        SpanHighlight(
          span.start,
          span.end,
          style: type.you.copyWith(
            backgroundColor: colors.guardMark,
            color: colors.markInk,
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: colors.markInk,
          ),
        ),
    ];
  }

  String _headline(UnlockResponse response) => switch (response.outcome) {
    UnlockOutcome.open => 'Opens at ${_destination(response)}',
    UnlockOutcome.later => 'Not now.',
    UnlockOutcome.specify => 'What exactly will you do?',
    UnlockOutcome.flagged => 'This reason tried to steer the gate',
    UnlockOutcome.unavailable => 'No answer · opening anyway, in a minute',
  };

  String _body(UnlockResponse response) => switch (response.outcome) {
    UnlockOutcome.open =>
      '${grantMinutesFor(response, fallbackUnlockMinutes: controller.settings.unlockMinutes)} minutes · ${kindLabels[response.kind] ?? 'task'}',
    UnlockOutcome.later => 'Sounds like browsing, so it can wait. There is no saved “later” list in core.',
    UnlockOutcome.specify => 'One more try, or wait 60 seconds.',
    UnlockOutcome.flagged =>
      'Guard: ${response.guard?.category ?? 'instruction override'}',
    UnlockOutcome.unavailable =>
      'The gate did not reply in 8 seconds. You may be offline.',
  };

  String _destination(UnlockResponse response) {
    if (response.kind == ReasonKind.person && response.person != null) {
      return '${widget.app.label} → Messages · ${response.person!.text}';
    }
    if (response.target != null) {
      return '${widget.app.label} → Search “${response.target!.text}”';
    }
    if (response.door != null) return '${widget.app.label} → ${response.door}';
    return widget.app.label;
  }

  String _openLabel(UnlockResponse response) =>
      'Open ${_destination(response)}';

  Future<void> _judge() async {
    FocusScope.of(context).unfocus();
    setState(() => _state = _GateState.thinking);
    final response = await controller.judgeUnlock(
      app: widget.app,
      reason: _reason.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _response = response;
      _state = _GateState.result;
    });
    if (response.outcome == UnlockOutcome.unavailable) _startOverride();
  }

  void _retryUnavailable() {
    _timer?.cancel();
    setState(() => _state = _GateState.ask);
  }

  void _startOverride() {
    _timer?.cancel();
    _deadline = DateTime.now().add(widget.overrideDuration);
    _remaining = widget.overrideDuration;
    if (mounted) setState(() => _state = _GateState.waiting);
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final left = _deadline!.difference(DateTime.now());
      if (left <= Duration.zero) {
        _timer?.cancel();
        _remaining = Duration.zero;
        if (mounted) setState(() {});
        _finishOverride();
      } else if (mounted) {
        setState(() => _remaining = left);
      }
    });
  }

  Future<void> _openGranted() async {
    final result = await controller.grantAndOpen(
      app: widget.app,
      reason: _reason.text.trim(),
      response: _response!,
    );
    if (!mounted) return;
    if (!result.succeeded) {
      showCurreSnack(
        context,
        'That door did not open. The grant is still active.',
      );
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _finishOverride() async {
    if (_overrideFinishing || _leaving || !mounted) return;
    _overrideFinishing = true;
    _timer?.cancel();
    await controller.finishOverride(
      app: widget.app,
      reason: _reason.text.trim(),
      response: _response!,
    );
    if (mounted) Navigator.of(context).pop();
  }
}

(int, int)? _durationSpan(String reason, int? minutes) {
  if (minutes == null) return null;
  final match = RegExp(
    r'\b\d{1,2}\s*(?:minutes?|mins?|min|hours?|hrs?|hr|h)\b',
    caseSensitive: false,
  ).firstMatch(reason);
  if (match == null) return null;
  final start = reason.substring(0, match.start).runes.length;
  final end = start + match.group(0)!.runes.length;
  return (start, end);
}

extension on UnlockOutcome {
  Outcome get designOutcome => switch (this) {
    UnlockOutcome.open => Outcome.open,
    UnlockOutcome.later => Outcome.later,
    UnlockOutcome.specify => Outcome.specify,
    UnlockOutcome.flagged => Outcome.flagged,
    UnlockOutcome.unavailable => Outcome.unavailable,
  };
}

class _PipelineStep extends StatelessWidget {
  const _PipelineStep({required this.glyph, required this.label});

  final CurreGlyphKind glyph;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: CurreSpace.s3),
      child: Row(
        children: [
          CurreGlyph(glyph, size: 20, color: colors.ink2),
          const SizedBox(width: CurreSpace.s3),
          Expanded(
            child: Text(label, style: type.body.copyWith(color: colors.ink2)),
          ),
        ],
      ),
    );
  }
}

class _NotJudgedChip extends StatelessWidget {
  const _NotJudgedChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.raised,
        shape: StadiumBorder(side: BorderSide(color: colors.hairline)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CurreSpace.s3,
          vertical: CurreSpace.s2,
        ),
        child: Text(label, style: type.meta.copyWith(color: colors.ink2)),
      ),
    );
  }
}
