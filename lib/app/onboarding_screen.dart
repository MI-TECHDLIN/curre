import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/models.dart';
import '../design/design.dart';
import '../doors/door_models.dart';
import '../doors/query_door_allowlist.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';
import 'demo_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.controller});

  final CurreController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _steps = 7;
  final _nameController = TextEditingController();
  var _step = 0;
  var _working = false;
  bool? _homeReady;
  bool? _notificationsReady;
  late final Set<String> _essentials;
  late final Set<String> _candidates;

  CurreController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _nameController.text = controller.settings.displayName ?? '';
    _essentials = controller.settings.essentials.isEmpty
        ? controller.suggestedEssentials
        : controller.settings.essentials.toSet();
    final eligible = _candidateChoices;
    _candidates = controller.settings.candidates.isEmpty
        ? eligible
              .take(math.min(10, eligible.length))
              .map((app) => app.packageName)
              .toSet()
        : controller.settings.candidates.toSet();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<LaunchableApp> get _candidateChoices =>
      controller.apps
          .where(
            (app) =>
                app.packageName != 'com.mitech.curre' &&
                !_essentials.contains(app.packageName),
          )
          .toList(growable: false)
        ..sort(
          (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
        );

  List<LaunchableApp> get _essentialChoices =>
      controller.apps
          .where((app) => app.packageName != 'com.mitech.curre')
          .toList(growable: false)
        ..sort(
          (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
        );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
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
            child: Row(
              children: [
                if (_step > 0)
                  RoundGlyphButton(
                    glyph: CurreGlyphKind.back,
                    label: 'Previous step',
                    onPressed: _working ? null : () => setState(() => _step--),
                  )
                else
                  const SizedBox(width: CurreSpace.touchTarget),
                const Spacer(),
                Text('${_step + 1} / $_steps', style: type.meta),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: CurreMotion.base,
              child: SingleChildScrollView(
                key: ValueKey(_step),
                padding: const EdgeInsets.all(CurreSpace.gutter),
                child: _body(context),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CurreSpace.gutter,
              CurreSpace.s2,
              CurreSpace.gutter,
              CurreSpace.s4,
            ),
            child: CurrePrimaryButton(
              label: _primaryLabel,
              glyph: _step == _steps - 1
                  ? CurreGlyphKind.go
                  : CurreGlyphKind.check,
              onPressed: _working || !_canContinue ? null : _continue,
              background: colors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) => switch (_step) {
    0 => _privacy(context),
    1 => _name(context),
    2 => _homeRole(context),
    3 => _notifications(context),
    4 => _essentialsPicker(context),
    5 => _candidatePicker(context),
    _ => _done(context),
  };

  String get _primaryLabel => switch (_step) {
    0 => 'That’s fair',
    1 => 'Use this name',
    2 => _homeReady == true ? 'Curre is my Home' : 'Set Curre as Home',
    3 =>
      _notificationsReady == true
          ? 'Notifications ready'
          : 'Allow notifications',
    4 => 'Keep these in sight',
    5 => 'Use these candidates',
    _ => 'Start my first check-in',
  };

  int get _minimumCandidates =>
      math.min(10, math.max(2, _candidateChoices.length));

  bool get _canContinue => switch (_step) {
    1 => Settings.normalizeDisplayName(_nameController.text) != null,
    5 => _candidates.length >= _minimumCandidates && _candidates.length <= 30,
    _ => true,
  };

  Widget _intro(
    BuildContext context, {
    required CurreGlyphKind glyph,
    required String eyebrow,
    required String headline,
    required String body,
  }) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.marker,
            borderRadius: CurreShape.md,
          ),
          child: CurreGlyph(glyph, size: 28, color: colors.markInk),
        ),
        const SizedBox(height: CurreSpace.s5),
        Text(
          eyebrow.toUpperCase(),
          style: type.meta.copyWith(color: colors.emberText),
        ),
        const SizedBox(height: CurreSpace.s2),
        Text(headline, style: type.headline),
        const SizedBox(height: CurreSpace.s3),
        Text(body, style: type.body.copyWith(color: colors.ink2)),
      ],
    );
  }

  Widget _privacy(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _intro(
          context,
          glyph: CurreGlyphKind.privacy,
          eyebrow: 'Welcome to Curre',
          headline: 'Only the apps you said you need, opened at the task.',
          body: 'Before setup, here is the whole privacy promise.',
        ),
        const SizedBox(height: CurreSpace.s6),
        _noteCard(
          context,
          title: 'Sent to Clocked (Rezolve.ai)',
          lines: const [
            'Your check-in sentence',
            'App and shortcut names',
            'An app name and your reason',
          ],
        ),
        const SizedBox(height: CurreSpace.s3),
        _noteCard(
          context,
          title: 'Stays on this phone',
          lines: const ['Contact and chat names', 'History and app use'],
        ),
        const SizedBox(height: CurreSpace.s3),
        Text(
          'The Curre server stores nothing and logs no text.',
          style: type.caption.copyWith(color: colors.ink3),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: CurreSpace.s5),
        CurreSecondaryButton(
          label: 'Try the gate first',
          glyph: CurreGlyphKind.door,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DemoScreen(controller: controller),
            ),
          ),
        ),
      ],
    );
  }

  Widget _noteCard(
    BuildContext context, {
    required String title,
    required List<String> lines,
  }) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: CurreShape.md,
        border: Border.all(color: colors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: type.label),
            const SizedBox(height: CurreSpace.s2),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: CurreSpace.s1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CurreGlyph(
                      CurreGlyphKind.check,
                      size: 17,
                      color: colors.emberText,
                    ),
                    const SizedBox(width: CurreSpace.s2),
                    Expanded(child: Text(line, style: type.body)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _name(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _intro(
          context,
          glyph: CurreGlyphKind.profile,
          eyebrow: 'Your Home',
          headline: 'What should Curre call you?',
          body: 'This name stays on your phone. You can change it in Curre settings.',
        ),
        const SizedBox(height: CurreSpace.s8),
        TextField(
          controller: _nameController,
          autofocus: true,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          style: type.youLarge,
          decoration: InputDecoration(
            labelText: 'Your name',
            hintText: 'Chidi',
            filled: true,
            fillColor: colors.raised,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _homeRole(BuildContext context) {
    final type = Theme.of(context).extension<CurreType>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _intro(
          context,
          glyph: CurreGlyphKind.homeRole,
          eyebrow: 'Task Doors',
          headline: 'Make Curre your Home.',
          body: 'Android lets the default Home use shortcut and chat doors. That is how Curre opens the task instead of the feed.',
        ),
        if (_homeReady != null) ...[
          const SizedBox(height: CurreSpace.s6),
          Text(
            _homeReady! ? 'Curre is your default Home.' : 'Android has not made Curre your Home yet. You can try again or continue in demo mode.',
            style: type.body,
          ),
        ],
        const SizedBox(height: CurreSpace.s5),
        CurreSecondaryButton(
          label: 'Not yet · try the gate',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DemoScreen(controller: controller),
            ),
          ),
        ),
      ],
    );
  }

  Widget _notifications(BuildContext context) {
    final type = Theme.of(context).extension<CurreType>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _intro(
          context,
          glyph: CurreGlyphKind.notify,
          eyebrow: 'Quiet reminders',
          headline: 'Know when an app goes out of sight again.',
          body: 'On Android 13 and later, Curre asks before showing a silent timer and one expiry note. No sound. No vibration.',
        ),
        if (_notificationsReady != null) ...[
          const SizedBox(height: CurreSpace.s6),
          Text(
            _notificationsReady! ? 'Notifications are ready.' : 'Permission was not granted. Curre still uses the stored timer as the source of truth.',
            style: type.body,
          ),
        ],
      ],
    );
  }

  Widget _essentialsPicker(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final pinned = controller.suggestedEssentials;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _intro(
          context,
          glyph: CurreGlyphKind.essential,
          eyebrow: 'Always in sight',
          headline: 'Pick your essentials.',
          body: 'Phone, Messages and Android Settings stay pinned. Curre has its own clearly labelled place beside them.',
        ),
        const SizedBox(height: CurreSpace.s5),
        Text('${_essentials.length} picked', style: type.meta),
        const SizedBox(height: CurreSpace.s2),
        for (final app in _essentialChoices)
          CheckboxListTile(
            value: _essentials.contains(app.packageName),
            onChanged: pinned.contains(app.packageName)
                ? null
                : (checked) {
                    setState(() {
                      if (checked ?? false) {
                        _essentials.add(app.packageName);
                      } else {
                        _essentials.remove(app.packageName);
                      }
                      _candidates.remove(app.packageName);
                    });
                  },
            title: Text(
              app.label,
              style: type.listItem.copyWith(color: colors.ink),
            ),
            subtitle: pinned.contains(app.packageName)
                ? Text('Pinned', style: type.meta)
                : null,
            secondary: CurreGlyph(
              pinned.contains(app.packageName)
                  ? CurreGlyphKind.essential
                  : CurreGlyphKind.check,
              color: pinned.contains(app.packageName)
                  ? colors.emberText
                  : colors.ink3,
            ),
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _candidatePicker(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final choices = _candidateChoices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _intro(
          context,
          glyph: CurreGlyphKind.outOfSight,
          eyebrow: 'Choose from',
          headline: 'Which apps may a plan bring into sight?',
          body: 'Pick 10–30. There are no icons here: labels are enough to make a deliberate choice.',
        ),
        const SizedBox(height: CurreSpace.s5),
        Text(
          '${_candidates.length} picked · $_minimumCandidates–30',
          style: type.meta.copyWith(
            color: _canContinue ? colors.ink3 : colors.emberText,
          ),
        ),
        const SizedBox(height: CurreSpace.s2),
        for (final app in choices)
          CheckboxListTile(
            value: _candidates.contains(app.packageName),
            onChanged: (checked) {
              setState(() {
                if (checked ?? false) {
                  if (_candidates.length < 30) _candidates.add(app.packageName);
                } else {
                  _candidates.remove(app.packageName);
                }
              });
            },
            title: Text(app.label, style: type.listItem),
            secondary: QueryDoorAllowlist.forPackage(app.packageName) == null
                ? null
                : CurreGlyph(
                    CurreGlyphKind.door,
                    color: colors.emberText,
                    semanticLabel: 'Verified link door',
                  ),
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _done(BuildContext context) {
    final name = Settings.normalizeDisplayName(_nameController.text) ?? 'you';
    return _intro(
      context,
      glyph: CurreGlyphKind.check,
      eyebrow: 'Ready',
      headline: 'Your Home is quiet, $name.',
      body: 'Start with one sentence about this session. Curre will bring only those Task Doors into sight.',
    );
  }

  Future<void> _continue() async {
    if (_step == 2 && _homeReady != true) {
      setState(() => _working = true);
      final ready = await controller.requestHomeRole();
      if (!mounted) return;
      setState(() {
        _working = false;
        _homeReady = ready;
      });
      if (!ready) return;
    } else if (_step == 3 && _notificationsReady != true) {
      setState(() => _working = true);
      final ready = await controller.requestNotifications();
      if (!mounted) return;
      setState(() {
        _working = false;
        _notificationsReady = ready;
      });
    }

    if (_step < _steps - 1) {
      setState(() => _step++);
      return;
    }

    setState(() => _working = true);
    await controller.finishOnboarding(
      displayName: _nameController.text,
      essentials: _essentials,
      candidates: _candidates,
    );
  }
}
