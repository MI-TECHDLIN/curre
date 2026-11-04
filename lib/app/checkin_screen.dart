import 'dart:async';

import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../l10n/l10n.dart';
import '../platform/speech_input.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';
import 'later_shelf_card.dart';

enum _CheckinState { compose, thinking, manual, confirmation }

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key, required this.controller});

  final CurreController controller;

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final _intention = TextEditingController();
  final _manual = <String>{};
  var _state = _CheckinState.compose;
  String? _message;
  Plan? _plan;

  /// What was saved with "Not now", arranged for the plan being made.
  LaterShelf? _shelf;
  Future<LaterShelf>? _pendingShelf;

  /// Why the plan couldn't be made for the user (null when it wasn't
  /// tried, or when it threw before saying).
  PlanFallbackReason? _fallback;

  CurreController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // A launcher process can stay alive across several sessions. Wake the
    // planner when check-in opens as well as when the process starts, so the
    // user's typing time overlaps a sleeping deployment's cold start.
    unawaited(controller.warmUpPlanning());
    // The sentence written on onboarding's last step is planned straight
    // away, through this same screen.
    final first = controller.takeFirstIntention();
    if (first != null) {
      _intention.text = first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_submit());
      });
    }
  }

  @override
  void dispose() {
    _intention.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final l10n = context.l10n;
    final session = controller.currentSession.session.localizedLabel(l10n);
    return CurrePage(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CurreSpace.gutter,
              CurreSpace.s3,
              CurreSpace.gutter,
              0,
            ),
            child: CurreTopBar(title: l10n.planYourSession(session)),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: CurreMotion.base,
              child: switch (_state) {
                _CheckinState.compose => _compose(context),
                _CheckinState.thinking => _thinking(context),
                _CheckinState.manual => _manualChecklist(context),
                _CheckinState.confirmation => _confirmation(context),
              },
            ),
          ),
          if (_state == _CheckinState.compose)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CurreSpace.gutter,
                CurreSpace.s2,
                CurreSpace.gutter,
                CurreSpace.s4,
              ),
              child: CurrePrimaryButton(
                label: l10n.setMySession(session),
                glyph: CurreGlyphKind.go,
                onPressed: _intention.text.trim().isEmpty ? null : _submit,
                background: colors.ember,
                foreground: colors.markInk,
              ),
            ),
        ],
      ),
    );
  }

  Widget _compose(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final l10n = context.l10n;
    final session = controller.currentSession.session;
    final designSession = session.designSession;
    final sky = colors.sky(designSession);
    final schedule = SessionSchedule.fromSettings(controller.settings);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final sceneHeight = 300.0 + ((textScale - 1).clamp(0.0, 1.0) * 600.0);
    final day = DayProgress.of(
      plans: controller.plans,
      uses: controller.doorUses,
      schedule: schedule,
      now: controller.now,
    );
    return SingleChildScrollView(
      key: const ValueKey('compose'),
      padding: const EdgeInsets.all(CurreSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: sceneHeight,
            child: SkyScene(
              session: designSession,
              groundHeight: 78,
              sunAt: .78,
              sunRise: switch (session) {
                SessionName.morning => .62,
                SessionName.afternoon => 1,
                SessionName.evening => .5,
              },
              animatePeek: true,
              animate: true,
              live: true,
              water: day.value,
              waterFrom: day.value,
              waterLabel: l10n.todayPercent((day.value * 100).round()),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.whatsThisSessionFor(session.localizedLabel(l10n)),
                        style: type.title
                            .weight(720)
                            .copyWith(color: sky.fg, fontSize: 26),
                      ),
                      const SizedBox(height: CurreSpace.s2),
                      Text(
                        l10n.oneSentenceHome,
                        style: type.body.copyWith(
                          color: sky.fg.withValues(alpha: .86),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: CurreSpace.s4),
          TextField(
            key: const Key('checkin-intention'),
            controller: _intention,
            minLines: 3,
            maxLines: 7,
            maxLength: 500,
            style: type.you,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.yourPlanLabel,
              hintText: l10n.planHint,
              filled: true,
              fillColor: colors.raised,
              suffixIcon: IconButton(
                tooltip: l10n.sayYourPlan,
                onPressed: _listen,
                icon: CurreGlyph(CurreGlyphKind.speak, color: colors.emberText),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: CurreSpace.s2),
              child: Text(
                _message!,
                style: type.caption.copyWith(color: colors.emberText),
              ),
            ),
        ],
      ),
    );
  }

  Widget _thinking(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final l10n = context.l10n;
    final candidates = controller.candidateApps;
    return SingleChildScrollView(
      key: const ValueKey('thinking'),
      padding: const EdgeInsets.all(CurreSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: CurreSpace.s8),
          Text(l10n.gettingAppsReady, style: type.headline),
          const SizedBox(height: CurreSpace.s3),
          Text(_intention.text, style: type.youLarge),
          const SizedBox(height: CurreSpace.s6),
          HorizonLine(scanning: true, semanticLabel: l10n.choosingApps),
          const SizedBox(height: CurreSpace.s3),
          GettingReadyNote(
            waking: controller.waking,
            child: Text(
              l10n.lookingThroughApps(candidates.length),
              style: type.caption.copyWith(color: colors.ink2),
            ),
          ),
          const SizedBox(height: CurreSpace.s5),
          Wrap(
            spacing: CurreSpace.s2,
            runSpacing: CurreSpace.s2,
            children: [
              for (final app in candidates)
                DecoratedBox(
                  decoration: ShapeDecoration(
                    color: colors.sunk,
                    shape: const StadiumBorder(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CurreSpace.s3,
                      vertical: CurreSpace.s2,
                    ),
                    child: Text(
                      app.label,
                      style: type.caption.copyWith(color: colors.ink2),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _manualChecklist(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final l10n = context.l10n;
    final candidates = controller.candidateApps.isEmpty
        ? controller.apps.take(30).toList(growable: false)
        : controller.candidateApps;
    return Column(
      key: const ValueKey('manual'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(CurreSpace.gutter),
            children: [
              OutcomeCard(
                outcome: Outcome.unavailable,
                headline: _fallbackHeadline(l10n, _fallback),
                body: _fallbackBody(l10n, _fallback),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: CurreSecondaryButton(
                      label: l10n.tryAgain,
                      glyph: CurreGlyphKind.rise,
                      onPressed: _submit,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CurreSpace.s5),
              Text(l10n.chooseAppsYourself, style: type.title),
              const SizedBox(height: CurreSpace.s2),
              Text(_intention.text, style: type.you),
              const SizedBox(height: CurreSpace.s3),
              for (final app in candidates)
                CheckboxListTile(
                  value: _manual.contains(app.packageName),
                  onChanged: (checked) => setState(() {
                    if (checked ?? false) {
                      _manual.add(app.packageName);
                    } else {
                      _manual.remove(app.packageName);
                    }
                  }),
                  title: Text(
                    app.label,
                    style: type.listItem.copyWith(color: colors.ink),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(CurreSpace.gutter),
          child: CurrePrimaryButton(
            label: l10n.useTheseApps,
            glyph: CurreGlyphKind.check,
            onPressed: _manual.isEmpty ? null : _saveManual,
          ),
        ),
      ],
    );
  }

  Widget _confirmation(BuildContext context) {
    final plan = _plan!;
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final l10n = context.l10n;
    final highlights = <SpanHighlight>[];
    for (final (index, app) in plan.apps.indexed) {
      if (app.query case final span?) {
        highlights.add(
          SpanHighlight(
            span.start,
            span.end,
            style: type.youLarge.copyWith(
              backgroundColor: colors.link(index + 1).mark,
              color: colors.markInk,
            ),
          ),
        );
      }
      for (final span in <SourceSpan?>[
        app.timing?.durationPhrase,
        app.timing?.startPhrase,
        app.timing?.endPhrase,
      ]) {
        if (span != null && _spanBelongsTo(plan.intention, span)) {
          highlights.add(
            SpanHighlight(
              span.start,
              span.end,
              style: type.youLarge.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: colors.ember,
                decorationThickness: 2.5,
              ),
            ),
          );
        }
      }
    }
    for (final span in <SourceSpan?>[
      plan.timing?.durationPhrase,
      plan.timing?.startPhrase,
      plan.timing?.endPhrase ?? plan.endPhrase,
    ]) {
      if (span != null && _spanBelongsTo(plan.intention, span)) {
        highlights.add(
          SpanHighlight(
            span.start,
            span.end,
            style: type.youLarge.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: colors.ember,
              decorationThickness: 2.5,
            ),
          ),
        );
      }
    }
    return Column(
      key: const ValueKey('confirmation'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(CurreSpace.gutter),
            children: [
              Text(l10n.heresYourPlan, style: type.headline),
              const SizedBox(height: CurreSpace.s3),
              Hero(
                tag: 'active-plan-${plan.id}',
                flightShuttleBuilder: (_, _, _, _, _) =>
                    PlanHeroSentence(intention: plan.intention),
                child: Material(
                  color: Colors.transparent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.raised,
                      borderRadius: CurreShape.md,
                      border: Border.all(color: colors.hairline),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(CurreSpace.s4),
                      child: SpanText(
                        plan.intention,
                        style: type.youLarge,
                        highlights: highlights,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CurreSpace.s3),
              Semantics(
                button: true,
                label: 'Plan time, ${_planTimeSummary(plan)}. Tap to adjust.',
                child: InkWell(
                  key: const Key('adjust-plan-time'),
                  onTap: () => _adjustTime(plan),
                  borderRadius: CurreShape.md,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: CurreSpace.s2,
                    ),
                    child: Row(
                      children: [
                        const CurreGlyph(CurreGlyphKind.editSpecify, size: 18),
                        const SizedBox(width: CurreSpace.s2),
                        Expanded(
                          child: Text(
                            _planTimeSummary(plan),
                            style: type.meta.copyWith(color: colors.emberText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (plan.timeWasCapped)
                Text(
                  'Kept to six hours or midnight, whichever comes first.',
                  style: type.caption.copyWith(color: colors.ink3),
                ),
              const SizedBox(height: CurreSpace.s1),
              Text(
                'Tap a time to adjust it before starting.',
                style: type.caption,
              ),
              const SizedBox(height: CurreSpace.s5),
              for (final (index, app) in plan.apps.indexed) ...[
                if (index > 0) const SizedBox(height: CurreSpace.s2),
                DoorRow(
                  appName:
                      controller.appFor(app.packageName)?.label ??
                      app.packageName,
                  destination:
                      '→ ${controller.destinationFor(app, plan, l10n)} · ${_appTimeSummary(app, plan)}',
                  appIcon: InstalledAppIcon(
                    controller: controller,
                    packageName: app.packageName,
                  ),
                  link: index + 1,
                  onTap: () => _adjustTime(plan, app: app),
                  semanticLabel:
                      '${controller.appFor(app.packageName)?.label ?? app.packageName}, '
                      '${_appTimeSummary(app, plan)}, tap to adjust',
                ),
              ],
              if (_shelf case final shelf? when !shelf.isEmpty) ...[
                const SizedBox(height: CurreSpace.s6),
                LaterShelfCard(
                  controller: controller,
                  shelf: shelf,
                  onOpen: _openLater,
                  onDismiss: _dismissLater,
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(CurreSpace.gutter),
          child: Column(
            children: [
              CurrePrimaryButton(
                label: l10n.backToHome,
                glyph: CurreGlyphKind.homeRole,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: CurreSpace.s2),
              CurreSecondaryButton(
                label: l10n.changePlan,
                glyph: CurreGlyphKind.editSpecify,
                onPressed: () => setState(() => _state = _CheckinState.compose),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _adjustTime(Plan plan, {PlannedApp? app}) async {
    final label = app == null
        ? 'this plan'
        : controller.appFor(app.packageName)?.label ?? app.packageName;
    final input = TextEditingController(
      text: _timePhrase(app?.timing ?? plan.timing),
    );
    final phrase = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Time for $label'),
        content: TextField(
          key: const Key('time-adjustment-field'),
          controller: input,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '2 hours, until 7, or from 4 to 6',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(input.text.trim()),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    input.dispose();
    if (phrase == null || phrase.isEmpty || !mounted) return;
    final updated = await controller.adjustPlanTime(
      plan,
      phrase,
      packageName: app?.packageName,
    );
    if (!mounted) return;
    if (updated == null) {
      showCurreSnack(
        context,
        'Try a duration like “90 min” or a clock time like “until 7”.',
      );
      return;
    }
    setState(() => _plan = updated);
  }

  Future<void> _listen() async {
    final l10n = context.l10n;
    final result = await controller.speech.listen(
      prompt: l10n.whatsThisSessionFor(
        controller.currentSession.session.localizedLabel(l10n),
      ),
    );
    if (!mounted) return;
    switch (result.status) {
      case SpeechInputStatus.recognized:
        setState(() {
          _intention.text = result.transcript!;
          _message = null;
        });
      case SpeechInputStatus.cancelled:
        break;
      case SpeechInputStatus.unavailable:
        setState(() => _message = result.message);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _state = _CheckinState.thinking;
      _message = null;
    });
    _arrangeShelf(_intention.text.trim());
    PlanBuildResult result;
    try {
      result = await controller.buildPlan(_intention.text.trim());
    } on Object {
      // Whatever went wrong, the user can still choose the apps.
      result = const PlanBuildResult.manual(null);
    }
    if (!mounted) return;
    if (result.requiresManualChecklist) {
      setState(() {
        _fallback = result.fallbackReason;
        if (_manual.isEmpty) {
          _manual.addAll(
            controller.candidateApps.take(2).map((app) => app.packageName),
          );
        }
        _state = _CheckinState.manual;
      });
    } else {
      setState(() {
        _plan = result.plan;
        _state = _CheckinState.confirmation;
      });
    }
  }

  Future<void> _saveManual() async {
    final plan = await controller.buildManualPlan(
      _intention.text.trim(),
      _manual,
    );
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _state = _CheckinState.confirmation;
    });
  }

  /// Ranks the saved items against this plan while the plan itself is
  /// read; the shelf appears under the plan once both are ready.
  void _arrangeShelf(String intention) {
    _shelf = null;
    final pending = controller
        .arrangeLaterShelf(intention)
        .catchError((Object _) => LaterShelf.empty);
    _pendingShelf = pending;
    pending.then((shelf) {
      if (mounted && identical(_pendingShelf, pending)) {
        setState(() => _shelf = shelf);
      }
    });
  }

  Future<void> _openLater(LaterItem item) async {
    final result = await controller.openLaterItem(item);
    if (!mounted) return;
    if (!result.succeeded) {
      showCurreSnack(
        context,
        '${item.appLabel} didn’t open. It’s still saved for later.',
      );
      return;
    }
    setState(() => _shelf = _shelf?.without(item.id));
  }

  Future<void> _dismissLater() async {
    setState(() => _shelf = null);
    await controller.dismissLaterShelf();
  }

  /// What went wrong, in words a person would use, then what to do.
  static String _fallbackHeadline(
    AppLocalizations l10n,
    PlanFallbackReason? reason,
  ) => switch (reason) {
    PlanFallbackReason.network => l10n.fallbackConnect,
    PlanFallbackReason.timeout => l10n.fallbackTimeout,
    PlanFallbackReason.invalidResponse => l10n.fallbackReadPlan,
    PlanFallbackReason.http || null => l10n.fallbackPlan,
  };

  static String _fallbackBody(
    AppLocalizations l10n,
    PlanFallbackReason? reason,
  ) => switch (reason) {
    PlanFallbackReason.network => l10n.fallbackNetworkBody,
    _ => l10n.fallbackBody,
  };
}

bool _spanBelongsTo(String source, SourceSpan span) {
  try {
    return sliceExtractSpan(source, span) == span.text;
  } on Object {
    return false;
  }
}

String _planTimeSummary(Plan plan) {
  final timing = plan.timing;
  if (timing == null || timing.isEmpty) {
    return 'Until ${formatClock(plan.endsAt)} · session end';
  }
  final parts = <String>[];
  if (plan.startsAt case final start? when timing.startPhrase != null) {
    parts.add('from ${formatClock(start)}');
  }
  final start =
      plan.startsAt ?? plan.endsAt.subtract(const Duration(minutes: 1));
  parts.add(_shortDuration(plan.endsAt.difference(start).inMinutes));
  parts.add('until ${formatClock(plan.endsAt)}');
  return parts.join(' · ');
}

String _appTimeSummary(PlannedApp app, Plan plan) {
  final end = app.availableUntil(plan);
  final timing = app.timing;
  if (timing == null || timing.isEmpty) return 'until ${formatClock(end)}';
  final start = plan.startsAt;
  final parts = <String>[];
  if (timing.durationMinutes != null) {
    final actual = start == null
        ? timing.durationMinutes!
        : end.difference(start).inMinutes;
    parts.add(_shortDuration(actual.clamp(1, maximumPlanDuration.inMinutes)));
  }
  parts.add('until ${formatClock(end)}');
  return parts.join(' · ');
}

String _shortDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours h' : '$hours h $rest min';
}

String _timePhrase(PlanTimeExpression? timing) {
  if (timing == null) return '';
  if (timing.startPhrase != null && timing.endPhrase != null) {
    return 'from ${timing.startPhrase!.text} to ${timing.endPhrase!.text}';
  }
  if (timing.startPhrase != null && timing.durationPhrase != null) {
    return 'at ${timing.startPhrase!.text} for ${timing.durationPhrase!.text}';
  }
  if (timing.durationPhrase case final duration?) return duration.text;
  if (timing.endPhrase case final end?) return 'until ${end.text}';
  return timing.durationMinutes == null
      ? ''
      : _shortDuration(timing.durationMinutes!);
}
