import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app_widgets.dart';
import 'app/checkin_screen.dart';
import 'app/completion_sheet.dart';
import 'app/curre_controller.dart';
import 'app/hidden_apps_screen.dart';
import 'app/history_screen.dart';
import 'app/home_screen.dart';
import 'app/onboarding_screen.dart';
import 'app/unlock_gate_screen.dart';
import 'app/voice_sheet.dart';
import 'design/design.dart';
import 'doors/door_lab_screen.dart';
import 'gallery/gallery_screen.dart';
import 'platform/platform.dart';

void main() {
  registerCurreLicenses();
  registerVoiceLicenses();
  runApp(const CurreApp());
}

class CurreApp extends StatefulWidget {
  const CurreApp({
    super.key,
    this.controller,
    this.themeMode = ThemeMode.system,
    this.onProofNotification,
  });

  /// Injection point for widget tests and review renders. Production creates
  /// the controller from SharedPreferences, Android channels and dart-defines.
  final CurreController? controller;
  final ThemeMode themeMode;

  /// Test hook for observing proof-reminder routing without replacing the
  /// production Prooflight completion sheet.
  final Future<void> Function(String? note)? onProofNotification;

  @override
  State<CurreApp> createState() => _CurreAppState();
}

class _CurreAppState extends State<CurreApp> {
  Future<CurreController>? _bootstrap;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<CurreNotificationIntent>
  _notificationSubscription;
  CurreController? _resolvedController;
  CurreNotificationIntent? _pendingNotification;

  @override
  void initState() {
    super.initState();
    _notificationSubscription = CurreNotificationInbox.instance.stream.listen(
      _handleNotification,
    );
    if (widget.controller == null) {
      _bootstrap = CurreController.bootstrap();
      unawaited(_rememberBootstrappedController());
    } else {
      _resolvedController = widget.controller;
    }
  }

  Future<void> _rememberBootstrappedController() async {
    try {
      final controller = await _bootstrap!;
      if (!mounted) return;
      _resolvedController = controller;
      final pending = _pendingNotification;
      _pendingNotification = null;
      if (pending != null) _handleNotification(pending);
    } on Object {
      // FutureBuilder owns the visible bootstrap error state.
    }
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    final future = _bootstrap;
    if (future != null) future.then((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Curre',
      debugShowCheckedModeBanner: false,
      themeMode: widget.themeMode,
      theme: curreTheme(Brightness.light),
      darkTheme: curreTheme(Brightness.dark),
      routes: <String, WidgetBuilder>{
        if (kDebugMode) '/door-lab': (_) => const DoorLabScreen(),
        if (kDebugMode) '/gallery': (_) => const DesignGalleryScreen(),
      },
      home: widget.controller == null
          ? FutureBuilder<CurreController>(
              future: _bootstrap,
              builder: (context, snapshot) {
                final controller = snapshot.data;
                if (controller != null) {
                  return _CurreRoot(controller: controller);
                }
                return const _BootScreen();
              },
            )
          : _CurreRoot(controller: widget.controller!),
    );
  }

  void _handleNotification(CurreNotificationIntent intent) {
    final controller = _resolvedController;
    if (controller == null) {
      _pendingNotification = intent;
      return;
    }
    if (!controller.onboardingComplete) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;
      switch (intent.destination) {
        case CurreNotificationDestination.home:
          navigator.popUntil((route) => route.isFirst);
        case CurreNotificationDestination.checkIn:
          unawaited(
            navigator.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => CheckinScreen(controller: controller),
              ),
            ),
          );
        case CurreNotificationDestination.hiddenApps:
          unawaited(
            navigator.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => HiddenAppsScreen(controller: controller),
              ),
            ),
          );
        case CurreNotificationDestination.proof:
          final handler = widget.onProofNotification;
          if (handler != null) {
            unawaited(handler(intent.note));
            return;
          }
          final task = controller.proofTaskForPlan(intent.reference);
          if (task != null) {
            unawaited(
              showCompletionSheet(
                navigator.context,
                controller: controller,
                task: task,
                initialNote: intent.note,
              ),
            );
          } else {
            unawaited(
              navigator.push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => HistoryScreen(controller: controller),
                ),
              ),
            );
          }
      }
    });
  }
}

class _CurreRoot extends StatefulWidget {
  const _CurreRoot({required this.controller});

  final CurreController controller;

  @override
  State<_CurreRoot> createState() => _CurreRootState();
}

class _CurreRootState extends State<_CurreRoot> with WidgetsBindingObserver {
  late final GentleInterceptCoordinator _interceptCoordinator;
  bool _interceptGateOpen = false;

  CurreController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.speech.presenter = _showVoiceSheet;
    _interceptCoordinator = GentleInterceptCoordinator(
      source: controller.gentleIntercept,
      snapshot: () => controller.gentleInterceptSnapshot,
      onIntercept: _showInterceptGate,
    )..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(controller.pollPendingGentleIntercept());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_refreshAndPoll());
  }

  Future<void> _refreshAndPoll() async {
    await controller.refreshUsageAccess();
    await controller.refreshNotificationAccess();
    await controller.pollPendingGentleIntercept();
  }

  Future<void> _showInterceptGate(ForegroundAppEvent event) async {
    if (!mounted || !controller.onboardingComplete || _interceptGateOpen) {
      return;
    }
    var app = controller.appFor(event.packageName);
    if (app == null) {
      await controller.refresh();
      app = controller.appFor(event.packageName);
    }
    if (!mounted || app == null) return;
    final targetApp = app;

    _interceptGateOpen = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => UnlockGateScreen(
            controller: controller,
            app: targetApp,
            openedFromOutside: true,
          ),
        ),
      );
    } finally {
      _interceptGateOpen = false;
    }
  }

  /// Every mic button reaches the voice sheet through here.
  Future<SpeechInputResult> _showVoiceSheet(String? prompt) =>
      showVoiceSheet(context, speech: controller.speech, prompt: prompt);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (controller.speech.presenter == _showVoiceSheet) {
      controller.speech.presenter = null;
    }
    unawaited(_interceptCoordinator.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.appInventoryState != AppInventoryState.ready) {
          return _AppInventoryRetry(controller: controller);
        }
        return controller.onboardingComplete
            ? HomeScreen(controller: controller)
            : OnboardingScreen(controller: controller);
      },
    );
  }
}

class _AppInventoryRetry extends StatelessWidget {
  const _AppInventoryRetry({required this.controller});

  final CurreController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final loading = controller.appInventoryState == AppInventoryState.loading;
    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CurreSpace.gutter),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CurreGlyph(
                    CurreGlyphKind.unavailable,
                    size: 42,
                    color: colors.ink2,
                  ),
                  const SizedBox(height: CurreSpace.s4),
                  Text(
                    'Couldn’t read your apps',
                    style: type.headline,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: CurreSpace.s2),
                  Text(
                    'Curre couldn’t read the apps installed on this phone. Try again, and your real apps will appear here.',
                    style: type.body.copyWith(color: colors.ink2),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: CurreSpace.s5),
                  CurrePrimaryButton(
                    label: loading ? 'Reading apps…' : 'Try again',
                    onPressed: loading ? null : controller.retryAppInventory,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    return Scaffold(
      backgroundColor: colors.paper,
      body: const Center(child: _SplashMark()),
    );
  }
}

/// Matches Android's native light/dark splash mark, so Flutter's first frame
/// replaces it without a white flash or a geometry jump.
class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final sky = colors.sky(Session.morning);
    return Semantics(
      image: true,
      label: 'Curre',
      child: ClipOval(
        child: SizedBox.square(
          key: const Key('curre-splash-mark'),
          dimension: 112,
          child: ColoredBox(
            color: sky.bg,
            child: Stack(
              children: [
                const Positioned(
                  left: 20,
                  top: 19,
                  child: PeekMascot(
                    size: 72,
                    compact: true,
                    animate: false,
                    groundShadow: false,
                    semanticLabel: null,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 72,
                  bottom: 0,
                  child: ColoredBox(color: sky.bg),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  top: 70,
                  child: HorizonLine(color: const Color(0xFF1E1A16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
