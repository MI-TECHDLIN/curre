import 'dart:async';
import 'dart:math' as math;

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

/// First-run setup, told as one short story from the problem to the first
/// plan (onboarding study, 2026-10-25): the pull of a feed, what stays
/// private, the apps that pull you in, who you are, when your morning
/// starts, Curre as the home screen, catching apps that sneak back in,
/// keeping hidden apps quiet, quiet nudges, the apps plans can use, and
/// finally the first plan itself.
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

enum _Step {
  story,
  privacy,
  pull,
  name,
  face,
  morning,
  home,
  sneak,
  quiet,
  nudges,
  apps,
  plan,
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  static const _morningChoices = <LocalTime>[
    LocalTime(4),
    LocalTime(5),
    LocalTime(6),
    LocalTime(7),
  ];
  static const _maxApps = 30;
  static const _shortList = 8;

  final _name = TextEditingController();
  final _plan = TextEditingController();
  final _nameFocus = FocusNode();
  final _pull = <String>{};
  final _apps = <String>{};
  final _appsRemoved = <String>{};
  late final Set<String> _essentials;
  late LocalTime _morning;
  late bool _nudgesEnabled;

  var _step = _Step.story;
  String? _avatarId;
  var _showAllPull = false;
  var _showAllApps = false;
  var _appsSeeded = false;
  var _sinking = false;
  var _nameTried = false;
  String? _morningError;
  bool? _homeReady;
  HomeSettingsOpened? _homeSettings;

  /// The intercept's Android permissions, by the step that asks for each:
  /// absent until Curre knows, then whether it is on.
  final _accessOn = <_Step, bool>{};
  var _working = false;
  String? _error;
  String _query = '';

  CurreController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final settings = controller.settings;
    _name.text = settings.displayName ?? '';
    _avatarId = settings.avatarId;
    _morning = settings.sessionStarts[SessionName.morning]!;
    _nudgesEnabled = settings.hasAnyNudges;
    _essentials = settings.essentials.isEmpty
        ? controller.suggestedEssentials
        : settings.essentials.toSet();
    if (settings.candidates.isNotEmpty) {
      _apps.addAll(settings.candidates);
      _appsSeeded = true;
    }
  }

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
    // Android's home screen choice happens outside Curre. Check the real
    // answer whenever the user comes back to this step.
    if (state != AppLifecycleState.resumed) return;
    if (_step == _Step.home) unawaited(_recheckHome());
    if (_isAccessStep(_step)) unawaited(_recheckAccess(_step));
  }

  Future<void> _recheckHome() async {
    final ready = await controller.isDefaultHome();
    if (!mounted || _step != _Step.home) return;
    if (ready || _homeReady != null) setState(() => _homeReady = ready);
  }

  static bool _isAccessStep(_Step step) =>
      step == _Step.sneak || step == _Step.quiet;

  Future<bool> _hasAccess(_Step step) => step == _Step.sneak
      ? controller.refreshUsageAccess()
      : controller.refreshNotificationAccess();

  Future<void> _recheckAccess(_Step step) async {
    final on = await _hasAccess(step);
    if (!mounted || _step != step) return;
    if (on || _accessOn.containsKey(step)) {
      setState(() => _accessOn[step] = on);
    }
  }

  // -------------------------------------------------------------------------
  // Answers and app lists.

  String? get _displayName => Settings.normalizeDisplayName(_name.text);

  /// Apps the user could pick in the app steps: everything but Curre and
  /// the apps that are always on Home.
  List<LaunchableApp> get _eligibleApps => controller.apps
      .where(
        (app) =>
            app.packageName != 'com.mitech.curre' &&
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

  List<LaunchableApp> get _appChoices {
    final eligible = _eligibleApps.toList()..sort(_byLabel);
    final picked = eligible.where((app) => _apps.contains(app.packageName));
    final others = eligible.where((app) => !_apps.contains(app.packageName));
    return [...picked, ...others];
  }

  static int _byLabel(LaunchableApp a, LaunchableApp b) =>
      a.label.toLowerCase().compareTo(b.label.toLowerCase());

  int get _minimumApps => math.min(2, _eligibleApps.length);

  void _seedApps() {
    final eligible = {for (final app in _eligibleApps) app.packageName};
    if (!_appsSeeded) {
      _appsSeeded = true;
      for (final package in commonTaskPackages) {
        if (eligible.contains(package)) _apps.add(package);
      }
    }
    // What pulls you in is often also what a plan needs (YouTube for a
    // lesson): bring those along unless the user took them out here.
    for (final package in _pull) {
      if (!_appsRemoved.contains(package) && _apps.length < _maxApps) {
        _apps.add(package);
      }
    }
    _apps.removeWhere((package) => !eligible.contains(package));
    final sorted = _eligibleApps.toList()..sort(_byLabel);
    for (final app in sorted) {
      if (_apps.length >= _minimumApps) break;
      _apps.add(app.packageName);
    }
  }

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
      if (step == _Step.apps) _seedApps();
    });
    if (step == _Step.home) unawaited(_recheckHome());
    if (_isAccessStep(step)) unawaited(_recheckAccess(step));
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

  void _submitName() {
    if (_displayName == null) {
      setState(() => _nameTried = true);
      _nameFocus.requestFocus();
      return;
    }
    _next();
  }

  Future<void> _pickOtherMorning() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _morning.hour, minute: _morning.minute),
      helpText: 'Your morning starts at',
    );
    if (picked == null || !mounted) return;
    _setMorning(LocalTime(picked.hour, picked.minute));
  }

  void _setMorning(LocalTime value) {
    final afternoon = controller.settings.sessionStarts[SessionName.afternoon]!;
    setState(() {
      if (value.compareTo(afternoon) >= 0) {
        _morningError =
            'Pick a time before $afternoon. That’s when your afternoon starts.';
      } else {
        _morning = value;
        _morningError = null;
      }
    });
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

  /// Opens Android's screen for this step's permission; the answer comes
  /// back when the user returns to Curre (false too when the screen
  /// couldn't open).
  Future<void> _askForAccess() async {
    final step = _step;
    setState(() => _working = true);
    final on = await (step == _Step.sneak
        ? controller.requestUsageAccess()
        : controller.requestNotificationAccess());
    if (!mounted) return;
    setState(() {
      _working = false;
      _accessOn[step] = on;
    });
  }

  Future<void> _allowNudges() async {
    setState(() => _working = true);
    final allowed = await controller.requestNotifications();
    if (!mounted) return;
    setState(() {
      _working = false;
      _nudgesEnabled = allowed;
    });
    if (!allowed) {
      showCurreSnack(
        context,
        'No problem. You can turn quiet nudges on later in Curre settings.',
      );
    }
    _next();
  }

  void _declineNudges() {
    setState(() => _nudgesEnabled = false);
    _next();
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
        candidates: _apps,
        morningStart: _morning,
        nudgesEnabled: _nudgesEnabled,
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
      case _Step.story:
        return StagePalette.of(StageTone.night, brightness);
      case _Step.privacy:
        return StagePalette.of(StageTone.lilac, brightness);
      case _Step.pull:
        return StagePalette.of(StageTone.coral, brightness);
      case _Step.name:
        return StagePalette.of(StageTone.peach, brightness);
      case _Step.face:
        final option = AvatarCatalog.byId(_avatarId);
        if (option == null) return StagePalette.of(StageTone.peach, brightness);
        final bg = option.background.color;
        return light
            ? StagePalette.fromSky(bg)
            : StagePalette.fromSky(
                Color.lerp(bg, const Color(0xFF13111A), .74)!,
                ink: Color.lerp(bg, Colors.white, .4),
              );
      case _Step.morning:
        return StagePalette.of(StageTone.dawn, brightness);
      case _Step.home:
        return StagePalette.of(StageTone.sky, brightness);
      case _Step.sneak:
        return StagePalette.of(StageTone.teal, brightness);
      case _Step.quiet:
        return StagePalette.of(StageTone.slate, brightness);
      case _Step.nudges:
        return StagePalette.of(StageTone.sage, brightness);
      case _Step.apps:
        return StagePalette.of(StageTone.mint, brightness);
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
      canPop: _step == _Step.story,
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
            onBack: _step == _Step.story || _working ? null : _back,
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
    _Step.story => 'Welcome to Curre',
    _Step.privacy => 'Your privacy',
    _Step.pull => 'Your apps',
    _Step.name => 'About you',
    _Step.face => 'About you',
    _Step.morning => 'Your day',
    _Step.home => 'Your home screen',
    _Step.sneak => 'Hidden apps',
    _Step.quiet => 'Hidden apps',
    _Step.nudges => 'Quiet nudges',
    _Step.apps => 'Your apps',
    _Step.plan => 'Your first plan',
  };

  String get _headline => switch (_step) {
    _Step.story => 'Ever pick up your phone for one thing and lose an hour?',
    _Step.privacy => 'Your life stays on your phone.',
    _Step.pull => 'Which apps pull you in?',
    _Step.name => 'What should Curre call you?',
    _Step.face => 'Pick a face that feels like you.',
    _Step.morning => 'When does your morning start?',
    _Step.home => 'Make Curre your home screen.',
    _Step.sneak => 'What if a hidden app sneaks back in?',
    _Step.quiet => 'Keep hidden apps quiet?',
    _Step.nudges => 'Want a quiet nudge when time’s up?',
    _Step.apps => 'Which apps will your plans need?',
    _Step.plan => 'What’s this ${_planSession.label} for?',
  };

  Widget _scene(StagePalette palette) => switch (_step) {
    _Step.story => StoryScene(palette: palette),
    _Step.privacy => PrivacyScene(palette: palette),
    _Step.pull => PullScene(
      palette: palette,
      controller: controller,
      apps: _pullChoices
          .where((app) => _pull.contains(app.packageName))
          .toList(growable: false),
      sinking: _sinking,
    ),
    _Step.name => NameScene(palette: palette, name: _displayName),
    _Step.face => FaceScene(
      palette: palette,
      avatarId: _avatarId,
      initial: _displayName,
    ),
    _Step.morning => MorningScene(palette: palette, start: _morning),
    _Step.home => HomeScene(
      palette: palette,
      controller: controller,
      name: _displayName,
      avatarId: _avatarId,
    ),
    _Step.sneak => SneakScene(
      palette: palette,
      controller: controller,
      app: _sceneHiddenApps.first,
    ),
    _Step.quiet => QuietScene(
      palette: palette,
      controller: controller,
      apps: _sceneHiddenApps,
    ),
    _Step.nudges => NudgeScene(palette: palette),
    _Step.apps => AppsScene(palette: palette, controller: controller),
    _Step.plan => PlanScene(avatarId: _avatarId, name: _displayName),
  };

  List<Widget> _sheet(BuildContext context) => switch (_step) {
    _Step.story => _storySheet(context),
    _Step.privacy => _privacySheet(context),
    _Step.pull => _pullSheet(context),
    _Step.name => _nameSheet(context),
    _Step.face => _faceSheet(context),
    _Step.morning => _morningSheet(context),
    _Step.home => _homeSheet(context),
    _Step.sneak => _sneakSheet(context),
    _Step.quiet => _quietSheet(context),
    _Step.nudges => _nudgesSheet(context),
    _Step.apps => _appsSheet(context),
    _Step.plan => _planSheet(context),
  };

  // -------------------------------------------------------------------------
  // Sheets: the words and controls under each scene.

  List<Widget> _storySheet(BuildContext context) => [
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
  ];

  List<Widget> _privacySheet(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return [
      const Text('Here is exactly what Curre reads, and what it never sees.'),
      const SizedBox(height: CurreSpace.s4),
      const _PromiseCard(
        prop: CurreProp.shield,
        title: 'Stays on this phone',
        lines: [
          'Your contacts and chats',
          'Your history of plans and reasons',
          'Which apps you use, and when',
        ],
      ),
      const SizedBox(height: CurreSpace.s3),
      const _PromiseCard(
        prop: CurreProp.cloud,
        title: 'Read online for a short time',
        lines: [
          'The plan you type or say',
          'The names of your apps',
          'Your reason when you open a hidden app',
        ],
      ),
      const SizedBox(height: CurreSpace.s3),
      Text(
        'Curre keeps no online copy. The AI service that reads your words may keep a copy for about a day so retries work, then deletes it. Your history stays on this phone.',
        style: type.caption.copyWith(color: colors.ink3),
        textAlign: TextAlign.center,
      ),
    ];
  }

  List<Widget> _pullSheet(BuildContext context) {
    final choices = _pullChoices;
    final shown = _showAllPull ? choices : choices.take(_shortList).toList();
    return [
      const Text(
        'Pick the ones where a quick look turns into an hour. Curre keeps them, and anything you don’t need right now, off your Home.',
      ),
      const SizedBox(height: CurreSpace.s4),
      _AppChips(
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
    ];
  }

  List<Widget> _nameSheet(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final missing = _nameTried && _displayName == null;
    return [
      const Text('Just for your greeting. It stays on this phone.'),
      const SizedBox(height: CurreSpace.s4),
      TextField(
        controller: _name,
        focusNode: _nameFocus,
        autofocus: true,
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
        onSubmitted: (_) => _submitName(),
      ),
    ];
  }

  List<Widget> _faceSheet(BuildContext context) => [
    const Text(
      'It sits next to your greeting on Home. You can change it any time.',
    ),
    const SizedBox(height: CurreSpace.s4),
    AvatarPicker(
      selectedAvatarId: _avatarId,
      onSelected: (id) => setState(() {
        HapticFeedback.selectionClick();
        _avatarId = id;
      }),
    ),
  ];

  List<Widget> _morningSheet(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final custom = !_morningChoices.contains(_morning);
    final afternoon = controller.settings.sessionStarts[SessionName.afternoon]!;
    final evening = controller.settings.sessionStarts[SessionName.evening]!;
    return [
      const Text('That’s when Curre asks what your morning is for.'),
      const SizedBox(height: CurreSpace.s4),
      LayoutBuilder(
        builder: (context, box) {
          final columns =
              box.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.5
              ? 1
              : 2;
          final width =
              (box.maxWidth - CurreSpace.s3 * (columns - 1)) / columns;
          return Wrap(
            spacing: CurreSpace.s3,
            runSpacing: CurreSpace.s3,
            children: [
              for (final time in [..._morningChoices, if (custom) _morning])
                SizedBox(
                  width: width,
                  child: ChoiceCard(
                    dense: true,
                    title: time.toString(),
                    subtitle: _morningHint(time),
                    selected: time == _morning,
                    semanticLabel:
                        'Morning starts at $time, ${_morningHint(time)}',
                    onTap: () => _setMorning(time),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: CurreSpace.s2),
      _QuietButton(label: 'Pick another time', onPressed: _pickOtherMorning),
      if (_morningError != null) ...[
        const SizedBox(height: CurreSpace.s2),
        Semantics(
          liveRegion: true,
          child: Text(
            _morningError!,
            style: type.caption.copyWith(color: colors.emberText),
          ),
        ),
      ],
      const SizedBox(height: CurreSpace.s3),
      Text(
        'Afternoons start at $afternoon and evenings at $evening. You can change all three in Curre settings.',
        style: type.caption.copyWith(color: colors.ink3),
      ),
    ];
  }

  static String _morningHint(LocalTime time) => switch (time.hour) {
    < 5 => 'Before the sun',
    5 => 'First light',
    6 => 'Early riser',
    _ => 'A gentle start',
  };

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

  /// The apps the user said pull them in, else familiar examples: the
  /// hidden apps the sneak-back and quiet scenes show.
  List<LaunchableApp> get _sceneHiddenApps {
    final pulled = [
      for (final app in _pullChoices)
        if (_pull.contains(app.packageName)) app,
    ];
    if (pulled.isNotEmpty) return pulled;
    return const [
      LaunchableApp(packageName: 'com.instagram.android', label: 'Instagram'),
      LaunchableApp(packageName: 'com.netflix.mediaclient', label: 'Netflix'),
    ];
  }

  List<Widget> _sneakSheet(BuildContext context) => [
    const Text(
      'Some apps sneak back in through notifications, links or your recent apps. Let Curre ask “Why now?” when that happens.',
    ),
    const SizedBox(height: CurreSpace.s4),
    const _PromiseCard(
      prop: CurreProp.shield,
      title: 'What Curre checks',
      lines: [
        'Only which app just opened',
        'Never what’s on your screen or in your messages',
        'You can switch it off any time in your phone’s Settings',
      ],
    ),
    ..._accessNotes(
      context,
      android: 'Android calls this “Usage access”. When the list opens, find Curre, switch it on, then come back here.',
      done: 'All set. Curre will ask “Why now?” when a hidden app sneaks back in.',
    ),
  ];

  List<Widget> _quietSheet(BuildContext context) => [
    const Text(
      'Hidden apps can still buzz you. Let Curre keep them quiet until you bring them back.',
    ),
    const SizedBox(height: CurreSpace.s4),
    const _PromiseCard(
      prop: CurreProp.zzz,
      title: 'What stays quiet',
      lines: [
        'Only notifications from hidden apps',
        'The apps on your Home still reach you',
        'You can switch it off any time in your phone’s Settings',
      ],
    ),
    ..._accessNotes(
      context,
      android: 'Android calls this “Notification access” and shows a strong warning. Curre uses it only to keep hidden apps quiet. Find Curre, switch it on, then come back here.',
      done: 'All set. Hidden apps will stay quiet until you bring them back.',
    ),
  ];

  /// How to switch an intercept permission on in Android, and where it
  /// stands once the user is back.
  List<Widget> _accessNotes(
    BuildContext context, {
    required String android,
    required String done,
  }) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final on = _accessOn[_step];
    return [
      const SizedBox(height: CurreSpace.s3),
      Text(android, style: type.caption.copyWith(color: colors.ink3)),
      if (on != null) ...[
        const SizedBox(height: CurreSpace.s3),
        Semantics(
          liveRegion: true,
          child: _StatusNote(
            glyph: on == true ? CurreGlyphKind.check : CurreGlyphKind.info,
            color: on == true ? colors.emberText : colors.ink2,
            text: on == true ? done : 'It isn’t on yet. Try again, or skip for now and turn it on later in Curre settings.',
          ),
        ),
      ],
    ];
  }

  List<Widget> _nudgesSheet(BuildContext context) => const [
    Text(
      'When you open a hidden app for a few minutes, Curre can let you know when the time is up. No sound, no buzz.',
    ),
    SizedBox(height: CurreSpace.s4),
    _PromiseCard(
      prop: CurreProp.bell,
      title: 'One silent note',
      lines: [
        'Only when time you asked for runs out',
        'Never ads, never “come back” reminders',
        'Turn it off any time',
      ],
    ),
  ];

  List<Widget> _appsSheet(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final all = _appChoices;
    final filtered = _query.isEmpty
        ? all
        : all
              .where(
                (app) => app.label.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList(growable: false);
    final shown = _showAllApps
        ? filtered
        : filtered.take(math.max(_shortList, _apps.length)).toList();
    final enough = _apps.length >= _minimumApps;
    return [
      Text(
        'When you plan your day, Curre picks the apps from this list. Choose 2 to $_maxApps.',
      ),
      const SizedBox(height: CurreSpace.s3),
      _AlwaysOnHome(controller: controller),
      const SizedBox(height: CurreSpace.s4),
      Semantics(
        liveRegion: true,
        child: Text(
          enough
              ? '${_apps.length} picked'
              : 'Pick at least $_minimumApps apps',
          style: type.meta.copyWith(
            color: enough ? colors.ink3 : colors.emberText,
          ),
        ),
      ),
      const SizedBox(height: CurreSpace.s2),
      if (_showAllApps && all.length > 12) ...[
        TextField(
          decoration: InputDecoration(
            labelText: 'Find an app',
            filled: true,
            fillColor: colors.raised,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: CurreGlyph(CurreGlyphKind.kindBrowse, color: colors.ink3),
            ),
          ),
          onChanged: (value) => setState(() => _query = value.trim()),
        ),
        const SizedBox(height: CurreSpace.s3),
      ],
      for (final app in shown) ...[
        ChoiceCard(
          dense: true,
          leading: AppMonogram(label: app.label, packageName: app.packageName),
          title: app.label,
          subtitle: appTaskExamples[app.packageName],
          selected: _apps.contains(app.packageName),
          onTap: () => _toggleApp(app),
        ),
        const SizedBox(height: CurreSpace.s2),
      ],
      if (!_showAllApps && filtered.length > shown.length)
        _QuietButton(
          label: 'Show all ${all.length} apps',
          onPressed: () => setState(() => _showAllApps = true),
        ),
    ];
  }

  void _toggleApp(LaunchableApp app) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_apps.remove(app.packageName)) {
        _appsRemoved.add(app.packageName);
      } else if (_apps.length < _maxApps) {
        _apps.add(app.packageName);
        _appsRemoved.remove(app.packageName);
      } else {
        showCurreSnack(
          context,
          'That’s $_maxApps already. Untick one to add another.',
        );
      }
    });
  }

  List<Widget> _planSheet(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    const examples = <String>[
      'Learn the G chord on YouTube till 7',
      'Reply to Ada on WhatsApp',
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
      case _Step.story:
        return (_Action('Show me how', _next, CurreGlyphKind.go), null);
      case _Step.privacy:
        return (_Action('Sounds fair', _next, CurreGlyphKind.go), null);
      case _Step.pull:
        final count = _pull.length;
        return (
          _Action(
            switch (count) {
              0 => 'Pick at least one',
              1 => 'This one pulls me in',
              _ => 'These pull me in',
            },
            count == 0 ? null : _leavePull,
            count == 0 ? null : CurreGlyphKind.go,
          ),
          _Action('None of these', () {
            setState(_pull.clear);
            _next();
          }),
        );
      case _Step.name:
        final name = _displayName;
        return (
          _Action(
            name == null || name.runes.length > 16
                ? 'Continue'
                : 'Call me $name',
            _submitName,
            CurreGlyphKind.go,
          ),
          null,
        );
      case _Step.face:
        return (
          _Action(
            _avatarId == null ? 'Pick a face first' : 'This is me',
            _avatarId == null ? null : _next,
            _avatarId == null ? null : CurreGlyphKind.go,
          ),
          _Action('Use my initial', () {
            setState(() => _avatarId = null);
            _next();
          }),
        );
      case _Step.morning:
        return (
          _Action('Mornings start at $_morning', _next, CurreGlyphKind.go),
          null,
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
      case _Step.sneak || _Step.quiet:
        if (_accessOn[_step] == true) {
          return (_Action('Continue', _next, CurreGlyphKind.go), null);
        }
        return (
          _Action('Allow', _askForAccess, CurreGlyphKind.go),
          _Action('Skip for now', _next),
        );
      case _Step.nudges:
        return (
          _Action('Yes, nudge me', _allowNudges, CurreGlyphKind.notify),
          _Action('Not now', _declineNudges),
        );
      case _Step.apps:
        final count = _apps.length;
        return (
          _Action(
            count < _minimumApps
                ? 'Pick at least $_minimumApps'
                : 'Use these $count apps',
            count < _minimumApps ? null : _next,
            count < _minimumApps ? null : CurreGlyphKind.go,
          ),
          null,
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
                        '$step of $total',
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

class _PromiseCard extends StatelessWidget {
  const _PromiseCard({
    required this.prop,
    required this.title,
    required this.lines,
  });

  final CurreProp prop;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Container(
      padding: const EdgeInsets.all(CurreSpace.s4),
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: CurreShape.md,
        border: Border.all(color: colors.hairline, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurrePropArt(prop, size: 44),
          const SizedBox(width: CurreSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: type.label.weight(700)),
                const SizedBox(height: CurreSpace.s1),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 9, right: 8),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colors.ember,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            line,
                            style: type.body.copyWith(color: colors.ink2),
                          ),
                        ),
                      ],
                    ),
                  ),
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
/// app name never breaks mid-word.
class _AppChips extends StatelessWidget {
  const _AppChips({
    required this.apps,
    required this.selected,
    required this.onToggle,
  });

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
    required this.app,
    required this.selected,
    required this.onTap,
  });

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
                    AppMonogram(
                      label: app.label,
                      packageName: app.packageName,
                      size: 32,
                    ),
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

class _AlwaysOnHome extends StatelessWidget {
  const _AlwaysOnHome({required this.controller});

  final CurreController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Semantics(
      container: true,
      label: 'Always on Home: Phone, Messages and Settings',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CurreSpace.s4,
          vertical: CurreSpace.s3,
        ),
        decoration: BoxDecoration(
          color: colors.sunk,
          borderRadius: CurreShape.md,
        ),
        child: Row(
          children: [
            CurreGlyph(
              CurreGlyphKind.essential,
              size: 20,
              color: colors.emberText,
            ),
            const SizedBox(width: CurreSpace.s3),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Always on Home  ',
                      style: type.label.weight(680),
                    ),
                    TextSpan(
                      text: 'Phone · Messages · Settings',
                      style: type.body.copyWith(color: colors.ink2),
                    ),
                  ],
                ),
              ),
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
