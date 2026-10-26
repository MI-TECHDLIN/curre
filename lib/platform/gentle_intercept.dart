import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'platform_channel.dart';
import 'quiet_notifications.dart';

/// Copy shared with onboarding and Settings.
///
/// Usage access is deliberately described without enforcement language: the
/// feature adds a moment of friction but never kills or blocks another app.
const usageAccessExplanation =
    'Curre uses Android Usage access to notice when a hidden app comes to the '
    'front, then asks why. It checks about once a second only while your '
    'screen is on. Usage stays on this phone and is not saved or sent.';

const currePackageName = 'com.mitech.curre';

@immutable
class ForegroundAppEvent {
  const ForegroundAppEvent({required this.packageName, required this.at});

  factory ForegroundAppEvent.fromMap(Map<Object?, Object?> map) {
    final packageName = map['package'] as String?;
    final atMillis = map['atMillis'] as int?;
    if (packageName == null || packageName.isEmpty || atMillis == null) {
      throw const FormatException('Invalid foreground-app event');
    }
    return ForegroundAppEvent(
      packageName: packageName,
      at: DateTime.fromMillisecondsSinceEpoch(atMillis, isUtc: true),
    );
  }

  final String packageName;
  final DateTime at;
}

@immutable
class GentleInterceptConfiguration {
  const GentleInterceptConfiguration({
    required this.enabled,
    required this.monitoredPackages,
    required this.alwaysAllowedPackages,
    required this.allowedUntilUtc,
  });

  final bool enabled;
  final Set<String> monitoredPackages;
  final Set<String> alwaysAllowedPackages;
  final Map<String, DateTime> allowedUntilUtc;

  Map<String, Object> toMap() => <String, Object>{
    'enabled': enabled,
    'monitoredPackages': monitoredPackages.toList(growable: false),
    'alwaysAllowedPackages': alwaysAllowedPackages.toList(growable: false),
    'allowedUntilMillis': <String, int>{
      for (final entry in allowedUntilUtc.entries)
        entry.key: entry.value.toUtc().millisecondsSinceEpoch,
    },
  };
}

@immutable
class GentleInterceptSnapshot {
  const GentleInterceptSnapshot({
    required this.enabled,
    required this.hasUsageAccess,
    required this.launchablePackages,
    required this.essentialPackages,
    required this.planPackages,
    required this.grantPackages,
    this.loopGuardPackages = const <String>{
      currePackageName,
      'android',
      'com.android.systemui',
    },
  });

  final bool enabled;
  final bool hasUsageAccess;
  final Set<String> launchablePackages;
  final Set<String> essentialPackages;
  final Set<String> planPackages;
  final Set<String> grantPackages;
  final Set<String> loopGuardPackages;
}

enum GentleInterceptDecision {
  intercept,
  disabled,
  usageAccessMissing,
  unknownApp,
  essential,
  activePlan,
  activeGrant,
  loopGuard,
  cooldown,
}

/// Pure, phone-owned decision logic for a foreground-app event.
///
/// Android receives a compact copy of the same visibility state so it can
/// raise Curre while Flutter is backgrounded. This engine re-checks every
/// native event before the gate is shown and supplies deterministic tests.
class GentleInterceptDecisionEngine {
  GentleInterceptDecisionEngine({this.cooldown = const Duration(seconds: 4)});

  final Duration cooldown;
  final Map<String, DateTime> _lastInterceptAt = <String, DateTime>{};

  GentleInterceptDecision evaluate(
    ForegroundAppEvent event,
    GentleInterceptSnapshot snapshot,
  ) {
    if (!snapshot.enabled) return GentleInterceptDecision.disabled;
    if (!snapshot.hasUsageAccess) {
      return GentleInterceptDecision.usageAccessMissing;
    }
    final packageName = event.packageName;
    if (snapshot.loopGuardPackages.contains(packageName)) {
      return GentleInterceptDecision.loopGuard;
    }
    if (!snapshot.launchablePackages.contains(packageName)) {
      return GentleInterceptDecision.unknownApp;
    }
    if (snapshot.essentialPackages.contains(packageName)) {
      return GentleInterceptDecision.essential;
    }
    if (snapshot.planPackages.contains(packageName)) {
      return GentleInterceptDecision.activePlan;
    }
    if (snapshot.grantPackages.contains(packageName)) {
      return GentleInterceptDecision.activeGrant;
    }
    final previous = _lastInterceptAt[packageName];
    if (previous != null && event.at.difference(previous) < cooldown) {
      return GentleInterceptDecision.cooldown;
    }
    _lastInterceptAt[packageName] = event.at;
    return GentleInterceptDecision.intercept;
  }
}

abstract interface class ForegroundAppEventSource {
  Stream<ForegroundAppEvent> get foregroundEvents;
}

abstract interface class GentleInterceptGateway
    implements ForegroundAppEventSource {
  Future<bool> hasUsageAccess();
  Future<bool> requestUsageAccess();
  Future<void> configureGentleIntercept(
    GentleInterceptConfiguration configuration,
  );
  Future<void> pollPendingForegroundEvent();
  Future<bool> hasNotificationAccess();
  Future<bool> requestNotificationAccess();
  Future<void> configureQuietNotifications(
    QuietNotificationConfiguration configuration,
  );
  Future<List<MissedWhileHiddenNotification>> loadMissedNotifications();
  Future<void> clearMissedNotifications();
  Future<void> dispose();
}

class DisabledGentleInterceptGateway implements GentleInterceptGateway {
  const DisabledGentleInterceptGateway();

  @override
  Stream<ForegroundAppEvent> get foregroundEvents => const Stream.empty();

  @override
  Future<bool> hasUsageAccess() async => false;

  @override
  Future<bool> requestUsageAccess() async => false;

  @override
  Future<void> configureGentleIntercept(
    GentleInterceptConfiguration configuration,
  ) async {}

  @override
  Future<void> pollPendingForegroundEvent() async {}

  @override
  Future<bool> hasNotificationAccess() async => false;

  @override
  Future<bool> requestNotificationAccess() async => false;

  @override
  Future<void> configureQuietNotifications(
    QuietNotificationConfiguration configuration,
  ) async {}

  @override
  Future<List<MissedWhileHiddenNotification>> loadMissedNotifications() async =>
      const <MissedWhileHiddenNotification>[];

  @override
  Future<void> clearMissedNotifications() async {}

  @override
  Future<void> dispose() async {}
}

/// Android channel adapter. The native service keeps one pending event until
/// Flutter consumes it, covering both a warm activity and a cold start.
class AndroidGentleInterceptGateway implements GentleInterceptGateway {
  AndroidGentleInterceptGateway({MethodChannel? channel})
    : _channel = channel ?? currePlatformChannel {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  final MethodChannel _channel;
  final StreamController<ForegroundAppEvent> _events =
      StreamController<ForegroundAppEvent>.broadcast();
  bool _disposed = false;

  @override
  Stream<ForegroundAppEvent> get foregroundEvents => _events.stream;

  Future<Object?> _handleNativeCall(MethodCall call) async {
    if (call.method != 'hiddenAppOpened' || _disposed) return null;
    final arguments = call.arguments;
    if (arguments is Map<Object?, Object?>) {
      _addEvent(arguments);
    }
    return null;
  }

  void _addEvent(Map<Object?, Object?> map) {
    try {
      _events.add(ForegroundAppEvent.fromMap(map));
    } on FormatException {
      // A malformed handoff must not stop the launcher from rendering.
    }
  }

  @override
  Future<bool> hasUsageAccess() async =>
      await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;

  @override
  Future<bool> requestUsageAccess() async =>
      await _channel.invokeMethod<bool>('requestUsageAccess') ?? false;

  @override
  Future<void> configureGentleIntercept(
    GentleInterceptConfiguration configuration,
  ) => _channel.invokeMethod<void>(
    'configureGentleIntercept',
    configuration.toMap(),
  );

  @override
  Future<void> pollPendingForegroundEvent() async {
    final pending = await _channel.invokeMapMethod<Object?, Object?>(
      'takePendingIntercept',
    );
    if (pending != null && !_disposed) _addEvent(pending);
  }

  @override
  Future<bool> hasNotificationAccess() async =>
      await _channel.invokeMethod<bool>('hasNotificationAccess') ?? false;

  @override
  Future<bool> requestNotificationAccess() async =>
      await _channel.invokeMethod<bool>('requestNotificationAccess') ?? false;

  @override
  Future<void> configureQuietNotifications(
    QuietNotificationConfiguration configuration,
  ) => _channel.invokeMethod<void>(
    'configureQuietNotifications',
    configuration.toMap(),
  );

  @override
  Future<List<MissedWhileHiddenNotification>> loadMissedNotifications() async {
    final raw =
        await _channel.invokeListMethod<Object?>('listMissedNotifications') ??
        const <Object?>[];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map(MissedWhileHiddenNotification.fromMap)
        .toList(growable: false);
  }

  @override
  Future<void> clearMissedNotifications() =>
      _channel.invokeMethod<void>('clearMissedNotifications');

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _channel.setMethodCallHandler(null);
    await _events.close();
  }
}

typedef GentleInterceptSnapshotReader = GentleInterceptSnapshot Function();
typedef GentleInterceptHandler = FutureOr<void> Function(
  ForegroundAppEvent event,
);

class GentleInterceptCoordinator {
  GentleInterceptCoordinator({
    required this.source,
    required this.snapshot,
    required this.onIntercept,
    GentleInterceptDecisionEngine? engine,
  }) : engine = engine ?? GentleInterceptDecisionEngine();

  final ForegroundAppEventSource source;
  final GentleInterceptSnapshotReader snapshot;
  final GentleInterceptHandler onIntercept;
  final GentleInterceptDecisionEngine engine;

  StreamSubscription<ForegroundAppEvent>? _subscription;

  void start() {
    _subscription ??= source.foregroundEvents.listen((event) async {
      if (engine.evaluate(event, snapshot()) ==
          GentleInterceptDecision.intercept) {
        await onIntercept(event);
      }
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
