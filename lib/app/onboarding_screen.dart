import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../doors/door_models.dart';
import '../platform/platform.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';
import 'onboarding/app_hints.dart';
import 'onboarding/onboarding_parts.dart';
import 'onboarding/onboarding_scenes.dart';
import 'privacy_details_screen.dart';

/// First-run setup in five short steps (onboarding study, 2026-10-25,
/// cut from twelve on 2026-11-03): the problem and Curre's promise, who
/// you are, the apps that pull you in, Curre as the home screen, and the
/// first plan itself.
///
/// Everything else waits until it helps: the morning starts at 06:00
/// (changed in Curre settings), and quiet nudges, Usage access and
/// notification access are each offered once in context
/// ([ContextPrompt]); the microphone is asked on the first mic tap.
///
/// Every step is a colour stage with an illustrated scene above a paper
/// sheet of controls, and the stages run from night into morning. Answers
/// live here until the last step saves them all at once
/// ([CurreController.finishOnboarding]); Back never loses one.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.controller});

  final CurreController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Step { welcome, you, pull, home, plan }

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  /// When mornings start until the user changes it in Curre settings.
  static const _defaultMorning = LocalTime(6);
  static const _shortList = 8;

  final _name = TextEditingController();
  final _plan = TextEditingController();
  final _nameFocus = FocusNode();
  final _pull = <String>{};
  late final Set<String> _essentials;
  late final LocalTime _morning;

  var _step = _Step.welcome;
  String? _avatarId;
  var _showAllPull = false;
  var _sinking = false;
  var _nameTried = false;
  bool? _homeReady;
  HomeSettingsOpened? _homeSettings;
  var _working = false;
  String? _error;

  CurreController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final settings = controller.settings;
    _name.text = settings.displayName ?? '';
    _avatarId = settings.avatarId;
    final afternoon = settings.sessionStarts[SessionName.afternoon]!;
    _morning = _defaultMorning.compareTo(afternoon) < 0
        ? _defaultMorning
        : settings.sessionStarts[SessionName.morning]!;
    _essentials = settings.essentials.isEmpty
        ? controller.suggestedEssentials
        : settings.essentials.toSet();
    final draft = controller.onboardingDraft;
    if (draft != null) _restore(draft);
  }

  /// Picks up where an earlier start of Curre left off. Android can start
  /// Curre afresh once it becomes the home screen; if it is Home now, the
  /// Home step is done.
  void _restore(OnboardingDraft draft) {
    _name.text = draft.displayName;
    _avatarId = AvatarCatalog.byId(draft.avatarId)?.id;
    final eligible = {for (final app in _eligibleApps) app.packageName};
    _pull.addAll(draft.hidden.where(eligible.contains));
    _showAllPull = draft.showAllApps;
    _plan.text = draft.plan;
    _step = _Step.values.asNameMap()[draft.step] ?? _Step.welcome;
    if (_step == _Step.home) unawaited(_resumeAtHome());
  }

  Future<void> _resumeAtHome() async {
    final ready = await controller.isDefaultHome();
    if (!mounted || _step != _Step.home) return;
    if (!ready) {
      unawaited(_recheckHome());
      return;
    }
    setState(() => _homeReady = true);
    _next();
  }

  void _saveDraft() => unawaited(
    controller.saveOnboardingDraft(
      OnboardingDraft(
        step: _step.name,
        displayName: _name.text,
        avatarId: _avatarId,
        hidden: {..._pull},
        showAllApps: _showAllPull,
        plan: _plan.text,
      ),
    ),
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _name.dispose();
    _plan.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Leaving Curre (Android's Home picker included) may be the last this
    // copy of Curre sees: keep the answers so far.
    if (state == AppLifecycleState.paused) _saveDraft();
    if (state != AppLifecycleState.resumed) return;
    // Another copy of Curre may have finished onboarding meanwhile.
    unawaited(controller.catchUpOnboarding());
    // Android's home screen choice happens outside Curre. Check the real
    // answer whenever the user comes back to this step.
    if (_step == _Step.home) unawaited(_recheckHome());
  }

  Future<void> _recheckHome() async {
    final ready = await controller.isDefaultHome();
    if (!mounted || _step != _Step.home) return;
    if (ready || _homeReady != null) setState(() => _homeReady = ready);
  }

  // -------------------------------------------------------------------------
  // Answers and app lists.

  String? get _displayName => Settings.normalizeDisplayName(_name.text);

  /// Apps the user could pick: everything but Curre and the apps that are
  /// always on Home.
  List<LaunchableApp> get _eligibleApps => controller.apps
      .where(
        (app) =>
            app.packageName != currePackageName &&
            !_essentials.contains(app.packageName),
      )
      .toList(growable: false);

  List<LaunchableApp> get _pullChoices {
    final eligible = _eligibleApps;
    final common = <LaunchableApp>[
      for (final package in commonPullPackages)
        ...eligible.where((app) => app.packageName == package),
    ];
    final rest =
        eligible
            .where((app) => !commonPullPackages.contains(app.packageName))
            .toList()
          ..sort(_byLabel);
    return [...common, ...rest];
  }

  static int _byLabel(LaunchableApp a, LaunchableApp b) =>
      a.label.toLowerCase().compareTo(b.label.toLowerCase());

  /// The apps plans can use: what the user didn't hide, everyday ones
  /// first. Curre settings changes them any time.
  Set<String> get _planApps => defaultPlanApps(
    eligible: [
      for (final app in _eligibleApps.toList()..sort(_byLabel)) app.packageName,
    ],
    hidden: _pull,
  );

  SessionName get _planSession {
    final starts = Map<SessionName, LocalTime>.of(
      controller.settings.sessionStarts,
    )..[SessionName.morning] = _morning;
    try {
      return SessionSchedule.fromSettings(
        controller.settings.copyWith(sessionStarts: starts),
      ).current(controller.now).session;
    } on Object {
      return controller.currentSession.session;
    }
  }

  // -------------------------------------------------------------------------
  // Navigation.

  void _go(_Step step) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _step = step;
      _error = null;
      _sinking = false;
    });
    _saveDraft();
    if (step == _Step.home) unawaited(_recheckHome());
  }

  void _next() {
    if (_step.index < _Step.values.length - 1) {
      _go(_Step.values[_step.index + 1]);
    }
  }

  void _back() {
    if (_working || _step.index == 0) return;
    _go(_Step.values[_step.index - 1]);
  }

  Future<void> _leavePull() async {
    if (_pull.isNotEmpty && !MediaQuery.disableAnimationsOf(context)) {
      // Let the chosen apps sink below the horizon first: off Home.
      setState(() => _sinking = true);
      await Future<void>.delayed(const Duration(milliseconds: 560));
      if (!mounted) return;
    }
    _next();
  }

  void _submitYou() {
    if (_displayName == null) {
      setState(() => _nameTried = true);
      _nameFocus.requestFocus();
      return;
    }
    _next();
  }

  Future<void> _askForHome() async {
    setState(() {
      _working = true;
      _homeSettings = null;
    });
    final ready = await controller.requestHomeRole();
    if (!mounted) return;
    setState(() {
      _working = false;
      _homeReady = ready;
    });
  }

  Future<void> _openHomeSettings() async {
    final opened = await controller.openHomeSettings();
    if (!mounted) return;
    setState(() => _homeSettings = opened);
  }

  void _openPrivacyDetails() {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PrivacyDetailsScreen()),
      ),
    );
  }

  Future<void> _finish({required bool withPlan}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await controller.finishOnboarding(
        displayName: _name.text,
        avatarId: _avatarId,
        essentials: _essentials,
        candidates: _planApps,
        morningStart: _morning,
        firstIntention: withPlan ? _plan.text : null,
      );
    } on Object {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error =
            'Curre couldn’t save your answers on this phone. Please try again.';
      });
    }
  }

  Future<void> _speakPlan() async {
    final session = _planSession.label;
    final result = await controller.speech.listen(
      prompt: 'What’s this $session for?',
    );
    if (!mounted) return;
    switch (result.status) {
      case SpeechInputStatus.recognized:
        setState(() => _plan.text = result.transcript!);
      case SpeechInputStatus.cancelled:
        break;
      case SpeechInputStatus.unavailable:
        showCurreSnack(context, result.message!);
    }
  }

  // -------------------------------------------------------------------------
  // Layout.

  StagePalette _palette(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final light = brightness == Brightness.light;
    switch (_step) {
      case _Step.welcome:
        return StagePalette.of(StageTone.night, brightness);
      case _Step.you:
        final option = AvatarCatalog.byId(_avatarId);
        if (option == null) return StagePalette.of(StageTone.peach, brightness);
        final bg = option.background.color;
        return light
            ? StagePalette.fromSky(bg)
            : StagePalette.fromSky(
                Color.lerp(bg, const Color(0xFF13111A), .74)!,
                ink: Color.lerp(bg, Colors.white, .4),
              );
      case _Step.pull:
        return StagePalette.of(StageTone.coral, brightness);
      case _Step.home:
        return StagePalette.of(StageTone.sky, brightness);
      case _Step.plan:
        final sky = Theme.of(context)
            .extension<CurreColors>()!
            .sky(_planSession.designSession);
        return StagePalette.fromSky(sky.bg, ink: sky.fg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final palette = _palette(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return PopScope(
      canPop: _step == _Step.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value:
            (palette.isDark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark)
                .copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: colors.paper,
          body: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: reduce
                      ? Duration.zero
                      : const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, ?current],
                  ),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, .025),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _page(context, palette),
                  ),
                ),
              ),
              _footer(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _page(BuildContext context, StagePalette palette) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Stage(
            palette: palette,
            step: _step.index + 1,
            total: _Step.values.length,
            eyebrow: _eyebrow,
            headline: _headline,
            onBack: _step == _Step.welcome || _working ? null : _back,
            scene: _scene(palette),
            backdrop: _step == _Step.plan
                ? (size) => PlanBackdrop(
                    session: _planSession,
                    stage: size,
                    capHeight: _Stage.cap,
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CurreSpace.gutter,
              0,
              CurreSpace.gutter,
              CurreSpace.s6,
            ),
            child: DefaultTextStyle.merge(
              style: type.body.copyWith(color: colors.ink2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _sheet(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _eyebrow => switch (_step) {
    _Step.welcome => 'Welcome to Curre',
    _Step.you => 'About you',
    _Step.pull => 'Your apps',
    _Step.home => 'Your home screen',
    _Step.plan => 'Your first plan',
  };

  String get _headline => switch (_step) {
    _Step.welcome => 'Ever pick up your phone for one thing and lose an hour?',
    _Step.you => 'What should Curre call you?',
    _Step.pull => 'What pulls you in?',
    _Step.home => 'Make Curre your home screen.',
    _Step.plan => 'What’s this ${_planSession.label} for?',
  };

  Widget _scene(StagePalette palette) => switch (_step) {
    _Step.welcome => StoryScene(palette: palette),
    _Step.you => FaceScene(
      palette: palette,
      avatarId: _avatarId,
      initial: _displayName,
    ),
    _Step.pull => PullScene(
      palette: palette,
      controller: controller,
      apps: _pullChoices
          .where((app) => _pull.contains(app.packageName))
          .toList(growable: false),
      sinking: _sinking,
    ),
    _Step.home => HomeScene(
      palette: palette,
      controller: controller,
      name: _displayName,
      avatarId: _avatarId,
    ),
    _Step.plan => PlanScene(avatarId: _avatarId, name: _displayName),
  };

  List<Widget> _sheet(BuildContext context) => switch (_step) {
    _Step.welcome => _welcomeSheet(context),
    _Step.you => _youSheet(context),
    _Step.pull => _pullSheet(context),
    _Step.home => _homeSheet(context),
    _Step.plan => _planSheet(context),
  };

  // -------------------------------------------------------------------------
  // Sheets: the words and controls under each scene.

  List<Widget> _welcomeSheet(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return [
      const _StoryCard(
        prop: CurreProp.yarn,
        label: 'Without Curre',
        body: 'One quick look. The feed pulls you in. An hour is gone.',
      ),
      const SizedBox(height: CurreSpace.s3),
      const _StoryCard(
        prop: CurreProp.door,
        label: 'With Curre',
        body: 'Say what you need. Curre opens the app right where you need it.',
        highlight: true,
      ),
      const SizedBox(height: CurreSpace.s4),
      Row(
        children: [
          const CurrePropArt(CurreProp.shield, size: 32),
          const SizedBox(width: CurreSpace.s3),
          Expanded(
            child: Text(
              'Your history and contacts stay on this phone.',
              style: type.body.copyWith(color: colors.ink2),
            ),
          ),
        ],
      ),
      _QuietButton(
        label: 'How Curre keeps things private',
        onPressed: _openPrivacyDetails,
      ),
    ];
  }

  List<Widget> _youSheet(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final missing = _nameTried && _displayName == null;
    return [
      const Text('Just for your greeting on Home. It stays on this phone.'),
      const SizedBox(height: CurreSpace.s4),
      TextField(
        controller: _name,
        focusNode: _nameFocus,
        maxLength: 60,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        style: type.youLarge.copyWith(height: 1.15),
        decoration: InputDecoration(
          labelText: 'Your name',
          hintText: 'Ada',
          filled: true,
          fillColor: colors.raised,
          counterText: '',
          errorText: missing ? 'Add a name, even just a nickname.' : null,
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      ),
      const SizedBox(height: CurreSpace.s5),
      Text(
        'Pick a face, or keep your initial. You can change it any time.',
        style: type.body.copyWith(color: colors.ink2),
      ),
      const SizedBox(height: CurreSpace.s3),
      AvatarPicker(
        selectedAvatarId: _avatarId,
        onSelected: (id) => setState(() {
          HapticFeedback.selectionClick();
          _avatarId = id;
        }),
      ),
      if (_avatarId != null) ...[
        const SizedBox(height: CurreSpace.s2),
        _QuietButton(
          label: 'Use my initial instead',
          onPressed: () => setState(() => _avatarId = null),
        ),
      ],
    ];
  }

  List<Widget> _pullSheet(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final choices = _pullChoices;
    final shown = _showAllPull ? choices : choices.take(_shortList).toList();
    return [
      const Text(
        'Pick the ones where a quick look turns into an hour. They go to Hidden apps: off your Home, a tap away when you really need one.',
      ),
      const SizedBox(height: CurreSpace.s4),
      _AppChips(
        controller: controller,
        apps: shown,
        selected: _pull,
        onToggle: (app) => setState(() {
          HapticFeedback.selectionClick();
          if (!_pull.remove(app.packageName)) _pull.add(app.packageName);
        }),
      ),
      if (!_showAllPull && choices.length > _shortList) ...[
        const SizedBox(height: CurreSpace.s3),
        _QuietButton(
          label: 'Show all ${choices.length} apps',
          onPressed: () => setState(() => _showAllPull = true),
        ),
      ],
      const SizedBox(height: CurreSpace.s4),
      _AlwaysOnHome(controller: controller, essentials: _essentials),
      const SizedBox(height: CurreSpace.s2),
      Text(
        'Plans can open the rest. Change any of this in Curre settings.',
        style: type.caption.copyWith(color: colors.ink3),
      ),
    ];
  }

  List<Widget> _homeSheet(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return [
      const Text(
        'Android will ask which app to use as your home screen. Choose Curre.',
      ),
      const SizedBox(height: CurreSpace.s4),
      const _NumberedPoint(
        number: 1,
        text: 'Your Home shows only what you plan.',
      ),
      const _NumberedPoint(
        number: 2,
        text: 'Every other app stays hidden, a tap away when you need it.',
      ),
      const _NumberedPoint(
        number: 3,
        text: 'Tap an app on Home to go straight to your task.',
      ),
      if (_homeReady != null) ...[
        const SizedBox(height: CurreSpace.s3),
        Semantics(
          liveRegion: true,
          child: _StatusNote(
            glyph: _homeReady! ? CurreGlyphKind.check : CurreGlyphKind.homeRole,
            color: _homeReady! ? colors.emberText : colors.ink2,
            text: _homeReady!
                ? 'Curre is your home screen now.'
                : _homeHelp(_homeSettings),
          ),
        ),
      ],
      if (_homeReady == false) ...[
        const SizedBox(height: CurreSpace.s2),
        Text(
          'Changed your mind? You can switch home screens any time in Curre settings.',
          style: type.caption.copyWith(color: colors.ink3),
        ),
      ],
    ];
  }

  static String _homeHelp(HomeSettingsOpened? opened) => switch (opened) {
    null => 'Curre isn’t your home screen yet. Try again, or open your phone’s home screen settings and choose Curre.',
    HomeSettingsOpened.homeApps =>
      'Choose Curre in the list, then come back here.',
    HomeSettingsOpened.defaultApps =>
      'Tap “Home app”, choose Curre, then come back here.',
    HomeSettingsOpened.settings => 'In Settings, search for “Home app” (or open Apps, then Default apps), choose Curre, then come back here.',
    HomeSettingsOpened.none => 'Open your phone’s Settings app, search for “Home app”, choose Curre, then come back here.',
  };

  List<Widget> _planSheet(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    const examples = <String>[
      'Learn the G chord on YouTube till 7',
      'Play the Sunday worship playlist on Spotify',
      'Find the way to the studio on Maps',
    ];
    return [
      const Text(
        'Say it in one sentence: the app, what you’ll do, and until when. Curre brings only that to your Home.',
      ),
      const SizedBox(height: CurreSpace.s4),
      TextField(
        key: const Key('onboarding-plan'),
        controller: _plan,
        minLines: 2,
        maxLines: 5,
        maxLength: 500,
        style: type.you,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: 'Your plan',
          hintText: examples.first,
          filled: true,
          fillColor: colors.raised,
          suffixIcon: IconButton(
            tooltip: 'Say your plan',
            onPressed: _speakPlan,
            icon: CurreGlyph(CurreGlyphKind.speak, color: colors.emberText),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: CurreSpace.s2),
      Text('Or start from one of these:', style: type.caption),
      const SizedBox(height: CurreSpace.s2),
      Wrap(
        spacing: CurreSpace.s2,
        runSpacing: CurreSpace.s2,
        children: [
          for (final example in examples)
            _ExampleChip(
              text: example,
              onTap: () => setState(() {
                _plan.text = example;
                _plan.selection = TextSelection.collapsed(
                  offset: example.length,
                );
              }),
            ),
        ],
      ),
      const SizedBox(height: CurreSpace.s4),
      Text(
        'Curre asks what your morning is for from $_morning. Change that any time in Curre settings.',
        style: type.caption.copyWith(color: colors.ink3),
      ),
    ];
  }

  // -------------------------------------------------------------------------
  // Footer.

  Widget _footer(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final (primary, secondary) = _actions();
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final primaryButton = CurrePrimaryButton(
      label: primary.label,
      glyph: primary.glyph,
      onPressed: _working ? null : primary.onPressed,
      background: _step == _Step.plan ? colors.ember : colors.ink,
      foreground: _step == _Step.plan ? colors.markInk : colors.paper,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border(top: BorderSide(color: colors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CurreSpace.gutter,
            CurreSpace.s3,
            CurreSpace.gutter,
            CurreSpace.s3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: type.caption.copyWith(color: colors.emberText),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: CurreSpace.s2),
              ],
              if (secondary == null)
                primaryButton
              else if (largeText)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    primaryButton,
                    const SizedBox(height: CurreSpace.s2),
                    _QuietButton(
                      label: secondary.label,
                      onPressed: _working ? null : secondary.onPressed,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: _QuietButton(
                        label: secondary.label,
                        onPressed: _working ? null : secondary.onPressed,
                      ),
                    ),
                    const SizedBox(width: CurreSpace.s2),
                    Expanded(flex: 3, child: primaryButton),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  (_Action, _Action?) _actions() {
    switch (_step) {
      case _Step.welcome:
        return (_Action('Show me how', _next, CurreGlyphKind.go), null);
      case _Step.you:
        final name = _displayName;
        return (
          _Action(
            name == null || name.runes.length > 16
                ? 'Continue'
                : 'Call me $name',
            _submitYou,
            CurreGlyphKind.go,
          ),
          null,
        );
      case _Step.pull:
        final count = _pull.length;
        return (
          _Action(
            switch (count) {
              0 => 'Pick at least one',
              1 => 'Hide this one',
              _ => 'Hide these $count',
            },
            count == 0 ? null : _leavePull,
            count == 0 ? null : CurreGlyphKind.go,
          ),
          _Action('None of these', () {
            setState(_pull.clear);
            _next();
          }),
        );
      case _Step.home:
        if (_homeReady == true) {
          return (_Action('Continue', _next, CurreGlyphKind.go), null);
        }
        return (
          _Action(
            'Make Curre my home screen',
            _askForHome,
            CurreGlyphKind.homeRole,
          ),
          _homeReady == false
              ? _Action('Open home settings', _openHomeSettings)
              : null,
        );
      case _Step.plan:
        final session = _planSession.label;
        return (
          _Action(
            'Set my $session',
            _plan.text.trim().isEmpty ? null : () => _finish(withPlan: true),
            CurreGlyphKind.go,
          ),
          _Action('I’ll plan later', () => _finish(withPlan: false)),
        );
    }
  }
}

class _Action {
  const _Action(this.label, this.onPressed, [this.glyph]);

  final String label;
  final VoidCallback? onPressed;
  final CurreGlyphKind? glyph;
}

// ---------------------------------------------------------------------------
// The stage: colour block, grain, progress, words and scene.

class _Stage extends StatelessWidget {
  const _Stage({
    required this.palette,
    required this.step,
    required this.total,
    required this.eyebrow,
    required this.headline,
    required this.onBack,
    required this.scene,
    this.backdrop,
  });

  final StagePalette palette;
  final int step;
  final int total;
  final String eyebrow;
  final String headline;
  final VoidCallback? onBack;
  final Widget scene;

  /// Drawn behind everything on the stage, given the stage's size.
  final Widget Function(Size stage)? backdrop;

  /// Height of the paper sheet's rounded top laid over the stage.
  static const cap = 28.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final top = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: palette.sky,
      child: Stack(
        children: [
          if (backdrop != null)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, box) => backdrop!(box.biggest),
              ),
            ),
          Positioned.fill(
            child: SceneGrain(
              dark: palette.grainDark,
              light: palette.grainLight,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: top + CurreSpace.s2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: CurreSpace.s4),
                child: Row(
                  children: [
                    if (onBack != null)
                      RoundGlyphButton(
                        glyph: CurreGlyphKind.back,
                        label: 'Back',
                        onPressed: onBack,
                      )
                    else
                      const SizedBox.square(dimension: CurreSpace.touchTarget),
                    const SizedBox(width: CurreSpace.s3),
                    Expanded(
                      child: SunriseProgress(
                        step: step,
                        total: total,
                        ink: palette.ink,
                      ),
                    ),
                    const SizedBox(width: CurreSpace.s3),
                    ExcludeSemantics(
                      child: Text(
                        '$step / $total',
                        style: type.meta.copyWith(color: palette.ink),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CurreSpace.s4),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CurreSpace.gutter,
                ),
                child: Semantics(
                  header: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        style: type.meta.copyWith(
                          color: palette.ink.withValues(alpha: .82),
                          letterSpacing: 1.4,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: CurreSpace.s2),
                      Text(
                        headline,
                        style: type.display
                            .weight(760)
                            .copyWith(
                              fontSize: 34,
                              height: 38 / 34,
                              letterSpacing: -1,
                              color: palette.ink,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: CurreSpace.s3),
              scene,
              const SizedBox(height: cap),
            ],
          ),
          // The paper sheet's rounded top, laid over the bottom of the
          // scene so the stage reads as a layer behind it.
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            height: cap + 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.paper,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(cap),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet parts.

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.prop,
    required this.label,
    required this.body,
    this.highlight = false,
  });

  final CurreProp prop;
  final String label;
  final String body;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Container(
      padding: const EdgeInsets.all(CurreSpace.s4),
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: CurreShape.md,
        border: Border.all(
          color: highlight ? colors.ember : colors.hairline,
          width: highlight ? 2.5 : 1.5,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: colors.ember.withValues(alpha: .28),
                  offset: const Offset(3, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurrePropArt(prop, size: 48),
          const SizedBox(width: CurreSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: type.label
                      .weight(700)
                      .copyWith(
                        color: highlight ? colors.emberText : colors.ink,
                      ),
                ),
                const SizedBox(height: 2),
                Text(body, style: type.body.copyWith(color: colors.ink2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberedPoint extends StatelessWidget {
  const _NumberedPoint({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: CurreSpace.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.marker,
              shape: BoxShape.circle,
              border: Border.all(color: colors.markInk, width: 1.5),
            ),
            child: Text(
              '$number',
              style: type.figure.copyWith(fontSize: 14, color: colors.markInk),
            ),
          ),
          const SizedBox(width: CurreSpace.s3),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text, style: type.body.copyWith(color: colors.ink)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusNote extends StatelessWidget {
  const _StatusNote({
    required this.glyph,
    required this.color,
    required this.text,
  });

  final CurreGlyphKind glyph;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Container(
      padding: const EdgeInsets.all(CurreSpace.s3),
      decoration: BoxDecoration(
        color: colors.sunk,
        borderRadius: CurreShape.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurreGlyph(glyph, size: 22, color: color),
          const SizedBox(width: CurreSpace.s3),
          Expanded(
            child: Text(text, style: type.body.copyWith(color: colors.ink)),
          ),
        ],
      ),
    );
  }
}

/// The apps to choose from as chips that size to their names, so a long
/// app name never breaks mid-word. Each shows the app's own icon, as Home
/// does, so it is easy to spot.
class _AppChips extends StatelessWidget {
  const _AppChips({
    required this.controller,
    required this.apps,
    required this.selected,
    required this.onToggle,
  });

  final CurreController controller;
  final List<LaunchableApp> apps;
  final Set<String> selected;
  final ValueChanged<LaunchableApp> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: CurreSpace.s2,
      runSpacing: CurreSpace.s2,
      children: [
        for (final app in apps)
          _AppChip(
            key: ValueKey(app.packageName),
            controller: controller,
            app: app,
            selected: selected.contains(app.packageName),
            onTap: () => onToggle(app),
          ),
      ],
    );
  }
}

class _AppChip extends StatelessWidget {
  const _AppChip({
    super.key,
    required this.controller,
    required this.app,
    required this.selected,
    required this.onTap,
  });

  final CurreController controller;
  final LaunchableApp app;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Semantics(
      button: true,
      selected: selected,
      label: app.label,
      excludeSemantics: true,
      onTap: onTap,
      child: AnimatedContainer(
        duration: CurreMotion.of(context, CurreMotion.quick),
        decoration: ShapeDecoration(
          color: selected ? colors.ember.withValues(alpha: .12) : colors.raised,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? colors.ember : colors.hairline,
              width: selected ? 2.5 : 1.5,
            ),
          ),
          shadows: selected
              ? [
                  BoxShadow(
                    color: colors.ember.withValues(alpha: .28),
                    offset: const Offset(2, 3),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashFactory: NoSplash.splashFactory,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 7, 12, 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AppIcon(controller: controller, app: app, size: 32),
                    const SizedBox(width: CurreSpace.s2),
                    Flexible(
                      child: Text(
                        app.label,
                        style: type.label.weight(640).copyWith(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: CurreSpace.s2),
                    selected
                        ? CurreGlyph(
                            CurreGlyphKind.check,
                            size: 22,
                            color: colors.ember,
                          )
                        : Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.ink3, width: 2),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An app's real icon, as on Home, or its [AppMonogram] when the phone has
/// none.
class _AppIcon extends StatelessWidget {
  const _AppIcon({
    required this.controller,
    required this.app,
    required this.size,
  });

  final CurreController controller;
  final LaunchableApp app;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: InstalledAppIcon(
      controller: controller,
      packageName: app.packageName,
      size: size,
      fallback: AppMonogram(
        label: app.label,
        packageName: app.packageName,
        size: size,
      ),
    ),
  );
}

/// The essentials, picked for the user: they stay on Home whatever the
/// plan, shown with their icons so they read the way Home will.
class _AlwaysOnHome extends StatelessWidget {
  const _AlwaysOnHome({required this.controller, required this.essentials});

  final CurreController controller;
  final Set<String> essentials;

  static const _plainNames = ['Phone', 'Messages', 'Settings'];

  /// The essentials this phone has, in Home's order (Phone, Messages,
  /// Settings), then any others by name.
  List<LaunchableApp> get _apps {
    final order = controller.suggestedEssentials.toList();
    int rank(LaunchableApp app) {
      final index = order.indexOf(app.packageName);
      return index < 0 ? order.length : index;
    }

    return [for (final package in essentials) ?controller.appFor(package)]
      ..sort((a, b) {
        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0
            ? byRank
            : a.label.toLowerCase().compareTo(b.label.toLowerCase());
      });
  }

  static String _spoken(List<String> names) => names.length < 2
      ? names.join()
      : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final apps = _apps;
    final names = apps.isEmpty
        ? _plainNames
        : [for (final app in apps) app.label];
    return Semantics(
      container: true,
      label: 'Always on Home: ${_spoken(names)}',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: CurreSpace.s4,
          vertical: CurreSpace.s3,
        ),
        decoration: BoxDecoration(
          color: colors.sunk,
          borderRadius: CurreShape.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CurreGlyph(
                  CurreGlyphKind.check,
                  size: 20,
                  color: colors.emberText,
                ),
                const SizedBox(width: CurreSpace.s3),
                Expanded(
                  child: Text('Always on Home', style: type.label.weight(680)),
                ),
              ],
            ),
            const SizedBox(height: CurreSpace.s2),
            if (apps.isEmpty)
              Text(
                names.join(' · '),
                style: type.body.copyWith(color: colors.ink2),
              )
            else
              Wrap(
                spacing: CurreSpace.s4,
                runSpacing: CurreSpace.s2,
                children: [
                  for (final app in apps)
                    Row(
                      key: ValueKey(app.packageName),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AppIcon(controller: controller, app: app, size: 24),
                        const SizedBox(width: CurreSpace.s2),
                        Flexible(
                          child: Text(
                            app.label,
                            style: type.body.copyWith(color: colors.ink2),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Semantics(
      button: true,
      label: 'Use example: $text',
      excludeSemantics: true,
      child: Material(
        color: colors.raised,
        shape: StadiumBorder(
          side: BorderSide(color: colors.hairline, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          splashFactory: NoSplash.splashFactory,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: CurreSpace.touchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CurreSpace.s4,
                vertical: CurreSpace.s2,
              ),
              child: Align(
                widthFactor: 1,
                child: Text(text, style: type.youSmall),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A low-key text action for the honest alternatives ("None of these",
/// "Use my initial", "Not now").
class _QuietButton extends StatelessWidget {
  const _QuietButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        splashFactory: NoSplash.splashFactory,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: CurreSpace.s2),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: type.label
                    .weight(640)
                    .copyWith(
                      color: onPressed == null ? colors.ink3 : colors.ink,
                      decoration: TextDecoration.underline,
                      decorationColor: colors.ink3,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
