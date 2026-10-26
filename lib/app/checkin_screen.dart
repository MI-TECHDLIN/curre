import 'dart:async';

import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../platform/speech_input.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';

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

  CurreController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // A launcher process can stay alive across several sessions. Wake the
    // planner when check-in opens as well as when the process starts, so the
    // user's typing time overlaps a sleeping deployment's cold start.
    unawaited(controller.warmUpPlanning());
  }

  @override
  void dispose() {
    _intention.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
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
            child: CurreTopBar(
              title:
                  '${_titlePrefix(controller.currentSession.session)} check-in',
              subtitle: 'Sent to Clocked · Fill + Extract',
            ),
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
                label: 'Set my ${controller.currentSession.session.label}',
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
              waterLabel:
                  'Today is ${(day.value * 100).round()} percent complete',
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'What’s this ${session.label} for?',
                        style: type.title
                            .weight(720)
                            .copyWith(color: sky.fg, fontSize: 26),
                      ),
                      const SizedBox(height: CurreSpace.s2),
                      Text(
                        'One sentence. Only what you name comes into sight.',
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
              labelText: 'Your plan',
              hintText: 'Learn the G chord on YouTube till 7',
              filled: true,
              fillColor: colors.raised,
              suffixIcon: IconButton(
                tooltip: 'Speak your plan',
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
    final candidates = controller.candidateApps;
    return SingleChildScrollView(
      key: const ValueKey('thinking'),
      padding: const EdgeInsets.all(CurreSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: CurreSpace.s8),
          Text('Choosing the Task Doors', style: type.headline),
          const SizedBox(height: CurreSpace.s3),
          Text(_intention.text, style: type.youLarge),
          const SizedBox(height: CurreSpace.s6),
          const HorizonLine(scanning: true, semanticLabel: 'Choosing apps'),
          const SizedBox(height: CurreSpace.s3),
          Text(
            'Fill + Extract · ${candidates.length} candidates · gives up at 12 s',
            style: type.meta,
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
                headline: 'Choose the apps yourself',
                body:
                    'I couldn’t finish that automatically. Pick what you need '
                    'and your plan will still work.',
              ),
              const SizedBox(height: CurreSpace.s4),
              Text('Pick what this sentence needs', style: type.title),
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
            label: 'Use this local plan',
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
    }
    if (plan.endPhrase case final span?) {
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
    return Column(
      key: const ValueKey('confirmation'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(CurreSpace.gutter),
            children: [
              Text('Here’s what comes into sight', style: type.headline),
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
              Text(
                'Ends ${formatClock(plan.endsAt)} · ${plan.source == PlanSource.clocked ? 'Clocked plan' : 'Local plan'}',
                style: type.meta,
              ),
              const SizedBox(height: CurreSpace.s5),
              for (final (index, app) in plan.apps.indexed) ...[
                if (index > 0) const SizedBox(height: CurreSpace.s2),
                DoorRow(
                  appName:
                      controller.appFor(app.packageName)?.label ??
                      app.packageName,
                  destination: '→ ${controller.destinationFor(app, plan)}',
                  appIcon: InstalledAppIcon(
                    controller: controller,
                    packageName: app.packageName,
                  ),
                  link: index + 1,
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
                label: 'Back to Home',
                glyph: CurreGlyphKind.homeRole,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: CurreSpace.s2),
              CurreSecondaryButton(
                label: 'Edit the plan',
                glyph: CurreGlyphKind.editSpecify,
                onPressed: () => setState(() => _state = _CheckinState.compose),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _listen() async {
    final result = await controller.speech.listen(
      prompt: 'What is this ${controller.currentSession.session.label} for?',
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
    final result = await controller.buildPlan(_intention.text.trim());
    if (!mounted) return;
    if (result.requiresManualChecklist) {
      setState(() {
        _manual
          ..clear()
          ..addAll(
            controller.candidateApps.take(2).map((app) => app.packageName),
          );
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

  static String _titlePrefix(SessionName session) {
    final label = session.label;
    return '${label[0].toUpperCase()}${label.substring(1)}';
  }
}
