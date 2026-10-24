import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/models.dart';
import '../core/sessions.dart';
import '../core/visibility.dart';
import 'platform_channel.dart';

abstract interface class HomePlatformGateway {
  Future<bool> isDefaultHome();
  Future<void> setHomeSurfaceActive(bool active);
}

class HomePlatformService implements HomePlatformGateway {
  const HomePlatformService();

  /// Lets onboarding reflect the role Android currently holds, rather than
  /// assuming that a successful role request made Curre the default Home.
  @override
  Future<bool> isDefaultHome() async =>
      await currePlatformChannel.invokeMethod<bool>('isDefaultHome') ?? false;

  @override
  Future<void> setHomeSurfaceActive(bool active) =>
      currePlatformChannel.invokeMethod<void>('setHomeSurfaceActive', active);
}

class HomeVisibilitySnapshot {
  const HomeVisibilitySnapshot({required this.apps, required this.state});

  final List<AppEntry> apps;
  final LauncherState state;
}

typedef HomeSnapshotLoader = Future<HomeVisibilitySnapshot> Function();
typedef HomeVisibilityListener = FutureOr<void> Function(
  Set<String> packages,
  DateTime evaluatedAt,
);

class HomeVisibilityRefresher {
  HomeVisibilityRefresher({
    required this.load,
    required this.onVisibility,
    DateTime Function()? now,
    this.timeZone = const SystemCurreTimeZone(),
  }) : _now = now ?? DateTime.now;

  final HomeSnapshotLoader load;
  final HomeVisibilityListener onVisibility;
  final DateTime Function() _now;
  final CurreTimeZone timeZone;

  Future<Set<String>> refresh() async {
    final snapshot = await load();
    final evaluatedAt = _now().toUtc();
    final packages = Set<String>.unmodifiable(
      visiblePackages(
        snapshot.apps,
        evaluatedAt,
        snapshot.state,
        timeZone: timeZone,
      ),
    );
    await onVisibility(packages, evaluatedAt);
    return packages;
  }
}

typedef PeriodicTimerFactory = Timer Function(
  Duration interval,
  void Function() callback,
);
typedef HomeRefreshErrorHandler = void Function(Object error, StackTrace stack);

class HomeRefreshController {
  HomeRefreshController({
    required this.refresh,
    this.homePlatform = const HomePlatformService(),
    this.timerFactory = _periodicTimer,
    this.period = const Duration(minutes: 1),
    this.onError,
  });

  final Future<void> Function() refresh;
  final HomePlatformGateway homePlatform;
  final PeriodicTimerFactory timerFactory;
  final HomeRefreshErrorHandler? onError;
  final Duration period;

  Timer? _timer;
  bool _foreground = false;
  bool _routeVisible = false;
  bool _starting = false;
  bool _refreshing = false;
  bool _refreshPending = false;
  bool _disposed = false;

  Future<void> setRouteVisible(bool visible) async {
    _routeVisible = visible;
    await _updateRunningState();
  }

  Future<void> resume() async {
    _foreground = true;
    await _updateRunningState();
  }

  Future<void> pause() async {
    _foreground = false;
    await _updateRunningState();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    await homePlatform.setHomeSurfaceActive(false);
  }

  Future<void> _updateRunningState() async {
    if (_disposed) return;
    final shouldRun = _foreground && _routeVisible;
    if (!shouldRun) {
      _timer?.cancel();
      _timer = null;
      await homePlatform.setHomeSurfaceActive(false);
      return;
    }
    if (_timer != null || _starting) return;

    _starting = true;
    try {
      await homePlatform.setHomeSurfaceActive(true);
      await _triggerRefresh();
      if (_disposed || !_foreground || !_routeVisible) return;
      _timer = timerFactory(period, () {
        unawaited(_triggerRefresh());
      });
    } finally {
      _starting = false;
    }
  }

  Future<void> _triggerRefresh() async {
    if (_refreshing) {
      _refreshPending = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _refreshPending = false;
        try {
          await refresh();
        } catch (error, stack) {
          onError?.call(error, stack);
        }
      } while (_refreshPending && _foreground && _routeVisible && !_disposed);
    } finally {
      _refreshing = false;
    }
  }
}

class HomeRefreshLifecycleHook with WidgetsBindingObserver {
  HomeRefreshLifecycleHook(this.controller, {WidgetsBinding? binding})
    : _binding = binding ?? WidgetsBinding.instance;

  final HomeRefreshController controller;
  final WidgetsBinding _binding;
  bool _attached = false;

  void attach() {
    if (_attached) return;
    _attached = true;
    _binding.addObserver(this);
    if (_binding.lifecycleState == AppLifecycleState.resumed) {
      unawaited(controller.resume());
    }
  }

  /// Call when the Home route becomes current (including `didPopNext`).
  /// This starts refreshes and asks Android to ignore Back on Home.
  Future<void> show() => controller.setRouteVisible(true);

  /// Call when another Flutter route covers Home (including `didPushNext`).
  /// This stops the ticker and restores normal Back handling.
  Future<void> hide() => controller.setRouteVisible(false);

  void detach() {
    if (!_attached) return;
    _attached = false;
    _binding.removeObserver(this);
    unawaited(controller.dispose());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(controller.resume());
    } else {
      unawaited(controller.pause());
    }
  }
}

Timer _periodicTimer(Duration interval, void Function() callback) =>
    Timer.periodic(interval, (_) => callback());
