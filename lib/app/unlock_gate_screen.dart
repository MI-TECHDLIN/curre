import 'dart:async';

import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../doors/door_models.dart';
import '../doors/query_door_allowlist.dart';
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
    this.openedFromOutside = false,
    this.overrideDuration = overrideWait,
  });

  final CurreController controller;
  final LaunchableApp app;
  final String? initialReason;
  final UnlockResponse? initialResponse;
  final bool autoJudge;
  final bool openedFromOutside;
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
  DoorResolution? _resolvedDestination;
  var _overrideFinishing = false;
  var _leaving = false;
  var _saving = false;

  CurreController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    if (widget.initialResponse != null) {
      _response = widget.initialResponse;
      _state = _GateState.result;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_response!.outcome == UnlockOutcome.open) {
          unawaited(_resolveDestination(_response!));
        } else if (_response!.outcome == UnlockOutcome.unavailable) {
          _startOverride();
        }
      });
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
                title: 'Why now?',
                subtitle: widget.openedFromOutside
                    ? 'You opened ${widget.app.label}. It\'s one of your hidden apps.'
                    : '${widget.app.label} is in your hidden apps.',
                maxTitleLines: 2,
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
                Semantics(
                  header: true,
                  child: Text(
                    'What do you need ${widget.app.label} for right now?',
                    style: type.title,
                  ),
                ),
                const SizedBox(height: CurreSpace.s2),
                Text(
                  'Say what you’ll do, who it’s for, and for how long. Curre opens the app right where you need it.',
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
                            ? ''
                            : 'Your plan: ${controller.activePlan!.intention}',
                        style: type.caption.copyWith(color: colors.ink3),
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
                    'One more try: say exactly what you’ll do.',
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
            label: _retryCount == 0 ? 'Bring it back' : 'Ask again',
            glyph: CurreGlyphKind.go,
            onPressed: length < 8 || length > 300 ? null : _judge,
          ),
        ),
      ],
    );
  }

  Widget _thinking(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
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
          Text(
            'Reading your reason…',
            style: type.body.copyWith(color: colors.ink2),
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
              if (response.kind != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: KindChip(kind: response.kind!),
                ),
                const SizedBox(height: CurreSpace.s3),
              ],
              OutcomeCard(
                outcome: outcome,
                headline: _headline(response),
                body: _body(response),
              ),
              const SizedBox(height: CurreSpace.s4),
              Text('Your reason', style: type.label),
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
              if (response.guardQuoteText case final quote?) ...[
                const SizedBox(height: CurreSpace.s3),
                Text(
                  'These words read like an instruction to Curre: “$quote”',
                  style: type.caption.copyWith(color: colors.emberText),
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
            label: 'Open after $overrideWaitWords',
            glyph: CurreGlyphKind.overrideWait,
            onPressed: _startOverride,
          ),
        ],
      ),
      UnlockOutcome.later => Column(
        children: [
          CurrePrimaryButton(
            label: 'Save for later',
            glyph: CurreGlyphKind.later,
            onPressed: _saving ? null : _saveForLater,
          ),
          const SizedBox(height: CurreSpace.s2),
          CurreSecondaryButton(
            label: 'Open after $overrideWaitWords',
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
      UnlockOutcome.flagged => Column(
        children: [
          CurreSecondaryButton(
            label: 'Open after $overrideWaitWords',
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
                if (response.kind != null) ...[
                  KindChip(kind: response.kind!),
                  const SizedBox(height: CurreSpace.s5),
                ],
                OutcomeCard(
                  outcome: response.outcome.designOutcome,
                  headline: '${widget.app.label} opens in $overrideWaitWords',
                  body: response.outcome == UnlockOutcome.unavailable
                      ? 'Curre couldn’t check your reason, so it opens after a short wait instead.'
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
                  'Leave this screen to cancel. If you wait it out, it shows in your history.',
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
      if (literalSpanInSource(_reason.text, response.guard?.quote.text)
          case final span?)
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
    UnlockOutcome.open
        when _resolvedDestination == null ||
            _resolvedDestination!.kind == DoorResolutionKind.plain =>
      'Opens ${widget.app.label}',
    UnlockOutcome.open => 'Opens at ${_destination(response)}',
    UnlockOutcome.later => 'Not now',
    UnlockOutcome.specify => 'What exactly will you do?',
    UnlockOutcome.flagged => 'That reads like an instruction, not a reason',
    UnlockOutcome.unavailable => 'Couldn’t check your reason',
  };

  String _body(UnlockResponse response) {
    final app = widget.app.label;
    final minutes = grantMinutesFor(
      response,
      fallbackUnlockMinutes: controller.settings.unlockMinutes,
    );
    return switch (response.outcome) {
      UnlockOutcome.open
          when response.kind == ReasonKind.person &&
              _resolvedDestination?.kind != DoorResolutionKind.conversation =>
        'Curre didn’t find a matching chat on this phone, so it opens $app. You have $minutes minutes.',
      UnlockOutcome.open => 'You have $minutes minutes.',
      UnlockOutcome.later =>
        'That sounds like browsing, so it can wait. Save it for later and it comes back when you next plan, or wait $overrideWaitWords to open $app now.',
      UnlockOutcome.specify =>
        'Say a bit more about what you’ll do, or wait $overrideWaitWords to open $app.',
      UnlockOutcome.flagged =>
        'Tell Curre what you’ll do in $app instead. Or wait $overrideWaitWords to open it.',
      UnlockOutcome.unavailable =>
        'No problem: $app opens after you wait $overrideWaitWords. You can also try again now.',
    };
  }

  String _destination(UnlockResponse response) =>
      switch (_resolvedDestination) {
        DoorResolution(
          kind: DoorResolutionKind.conversation,
          value: final value?,
        ) =>
          '${widget.app.label} → Chat with $value',
        DoorResolution(kind: DoorResolutionKind.query, value: final value?) =>
          '${widget.app.label} → ${_queryAction()} “$value”',
        DoorResolution(
          kind: DoorResolutionKind.shortcut,
          value: final value?,
        ) =>
          '${widget.app.label} → $value',
        _ => widget.app.label,
      };

  String _openLabel(UnlockResponse response) =>
      'Open ${_destination(response)}';

  String _queryAction() =>
      QueryDoorAllowlist.forPackage(widget.app.packageName)?.actionLabel ??
      'Open app with';

  Future<void> _judge() async {
    FocusScope.of(context).unfocus();
    setState(() => _state = _GateState.thinking);
    UnlockResponse response;
    try {
      response = await controller.judgeUnlock(
        app: widget.app,
        reason: _reason.text.trim(),
      );
    } on Object {
      // Never strand the user: the override wait still opens the app.
      response = const UnlockResponse.unavailable();
    }
    final destination = response.outcome == UnlockOutcome.open
        ? await controller.unlockDestinationFor(widget.app, response)
        : null;
    if (!mounted) return;
    setState(() {
      _response = response;
      _resolvedDestination = destination;
      _state = _GateState.result;
    });
    if (response.outcome == UnlockOutcome.unavailable) _startOverride();
  }

  Future<void> _resolveDestination(UnlockResponse response) async {
    final destination = await controller.unlockDestinationFor(
      widget.app,
      response,
    );
    if (!mounted || !identical(_response, response)) return;
    setState(() => _resolvedDestination = destination);
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

  Future<void> _saveForLater() async {
    setState(() => _saving = true);
    try {
      await controller.saveForLater(
        app: widget.app,
        reason: _reason.text.trim(),
        response: _response!,
      );
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      showCurreSnack(
        context,
        'Curre couldn’t save that on this phone. Please try again.',
      );
      return;
    }
    if (!mounted) return;
    showCurreSnack(context, 'Saved. It comes back when you next plan.');
    Navigator.of(context).pop();
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
        '${widget.app.label} didn’t open there. Your time is still running, so try it from Home.',
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
