import 'dart:async';

import 'package:flutter/foundation.dart';

const notificationAccessExplanation =
    'Hidden apps can still buzz you. With notification access, Curre keeps '
    'them quiet until you bring them back, and saves just the app, title and '
    'time in Missed notifications. Message text is never saved or shared.';

@immutable
class QuietNotificationConfiguration {
  const QuietNotificationConfiguration({
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
class MissedWhileHiddenNotification {
  const MissedWhileHiddenNotification({
    required this.packageName,
    required this.appLabel,
    required this.title,
    required this.at,
  });

  factory MissedWhileHiddenNotification.fromMap(Map<Object?, Object?> map) {
    final packageName = map['package'] as String?;
    final appLabel = map['appLabel'] as String?;
    final title = map['title'] as String?;
    final atMillis = map['atMillis'] as int?;
    if (packageName == null ||
        packageName.isEmpty ||
        appLabel == null ||
        appLabel.isEmpty ||
        title == null ||
        title.isEmpty ||
        atMillis == null) {
      throw const FormatException('Invalid missed notification');
    }
    return MissedWhileHiddenNotification(
      packageName: packageName,
      appLabel: appLabel,
      title: title,
      at: DateTime.fromMillisecondsSinceEpoch(atMillis, isUtc: true),
    );
  }

  final String packageName;
  final String appLabel;
  final String title;
  final DateTime at;
}

enum NotificationKind { ordinary, call, alarm, system }

@immutable
class PostedNotificationEvent {
  const PostedNotificationEvent({
    required this.packageName,
    required this.title,
    required this.at,
    this.kind = NotificationKind.ordinary,
    this.isClearable = true,
  });

  final String packageName;
  final String title;
  final DateTime at;
  final NotificationKind kind;
  final bool isClearable;
}

@immutable
class QuietNotificationSnapshot {
  const QuietNotificationSnapshot({
    required this.enabled,
    required this.hasNotificationAccess,
    required this.launchablePackages,
    required this.essentialPackages,
    required this.planPackages,
    required this.grantPackages,
    this.protectedPackages = const <String>{
      'com.mitech.curre',
      'android',
      'com.android.systemui',
      'com.android.permissioncontroller',
      'com.google.android.permissioncontroller',
    },
  });

  final bool enabled;
  final bool hasNotificationAccess;
  final Set<String> launchablePackages;
  final Set<String> essentialPackages;
  final Set<String> planPackages;
  final Set<String> grantPackages;
  final Set<String> protectedPackages;
}

enum QuietNotificationDecision {
  quiet,
  disabled,
  notificationAccessMissing,
  protectedApp,
  unknownApp,
  essential,
  activePlan,
  activeGrant,
  protectedKind,
  notClearable,
}

/// Mirrors the native listener's phone-owned filter in a deterministic form.
class QuietNotificationDecisionEngine {
  const QuietNotificationDecisionEngine();

  QuietNotificationDecision evaluate(
    PostedNotificationEvent event,
    QuietNotificationSnapshot snapshot,
  ) {
    if (!snapshot.enabled) return QuietNotificationDecision.disabled;
    if (!snapshot.hasNotificationAccess) {
      return QuietNotificationDecision.notificationAccessMissing;
    }
    if (snapshot.protectedPackages.contains(event.packageName)) {
      return QuietNotificationDecision.protectedApp;
    }
    if (event.kind != NotificationKind.ordinary) {
      return QuietNotificationDecision.protectedKind;
    }
    if (!event.isClearable) return QuietNotificationDecision.notClearable;
    if (!snapshot.launchablePackages.contains(event.packageName)) {
      return QuietNotificationDecision.unknownApp;
    }
    if (snapshot.essentialPackages.contains(event.packageName)) {
      return QuietNotificationDecision.essential;
    }
    if (snapshot.planPackages.contains(event.packageName)) {
      return QuietNotificationDecision.activePlan;
    }
    if (snapshot.grantPackages.contains(event.packageName)) {
      return QuietNotificationDecision.activeGrant;
    }
    return QuietNotificationDecision.quiet;
  }
}

abstract interface class PostedNotificationEventSource {
  Stream<PostedNotificationEvent> get notificationEvents;
}

typedef QuietNotificationSnapshotReader = QuietNotificationSnapshot Function();
typedef QuietNotificationHandler = FutureOr<void> Function(
  PostedNotificationEvent event,
);

/// Testable event-source seam. Android applies the same filter inside its
/// NotificationListenerService because Flutter may be suspended at post time.
class QuietNotificationCoordinator {
  QuietNotificationCoordinator({
    required this.source,
    required this.snapshot,
    required this.onQuiet,
    this.engine = const QuietNotificationDecisionEngine(),
  });

  final PostedNotificationEventSource source;
  final QuietNotificationSnapshotReader snapshot;
  final QuietNotificationHandler onQuiet;
  final QuietNotificationDecisionEngine engine;
  StreamSubscription<PostedNotificationEvent>? _subscription;

  void start() {
    _subscription ??= source.notificationEvents.listen((event) async {
      if (engine.evaluate(event, snapshot()) ==
          QuietNotificationDecision.quiet) {
        await onQuiet(event);
      }
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
