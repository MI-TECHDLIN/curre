import 'dart:async';

import 'package:flutter/foundation.dart';

const notificationAccessExplanation =
    'Apps you hid can still buzz you. With notification access, Curre holds '
    'their notifications quietly and gives every one back when you open that '
    'app, take a rest day, your focus ends or Curre stops being your home '
    'screen. Nothing is lost. Calls and alarms always come through, and what '
    'Curre holds stays on this phone.';

@immutable
class QuietNotificationConfiguration {
  const QuietNotificationConfiguration({
    required this.enabled,
    required this.monitoredPackages,
    required this.alwaysAllowedPackages,
    required this.allowedUntilUtc,
    this.holdUntilUtc,
  });

  final bool enabled;

  /// The apps the user chose to hide: the only ones whose notifications
  /// are held.
  final Set<String> monitoredPackages;
  final Set<String> alwaysAllowedPackages;
  final Map<String, DateTime> allowedUntilUtc;

  /// When holding stops by itself (the running focus ends then), so Android
  /// gives everything back even if Curre isn't opened; null for no end.
  final DateTime? holdUntilUtc;

  Map<String, Object> toMap() => <String, Object>{
    'enabled': enabled,
    'monitoredPackages': monitoredPackages.toList(growable: false),
    'alwaysAllowedPackages': alwaysAllowedPackages.toList(growable: false),
    'allowedUntilMillis': <String, int>{
      for (final entry in allowedUntilUtc.entries)
        entry.key: entry.value.toUtc().millisecondsSinceEpoch,
    },
    if (holdUntilUtc case final until?)
      'holdUntilMillis': until.toUtc().millisecondsSinceEpoch,
  };
}

/// What Android's listener does with notifications from hidden apps, in a
/// form tests can run: the same rule decides what is held when it arrives
/// and what is given back when anything changes (an app opened or brought
/// back, a rest day, the focus ending, Curre no longer Home, or Curre's
/// start after a restart, which re-reads the saved held list).
@immutable
class QuietNotificationPolicy {
  const QuietNotificationPolicy({
    required this.enabled,
    required this.monitoredPackages,
    required this.alwaysAllowedPackages,
    required this.allowedUntilUtc,
    this.holdUntilUtc,
  });

  /// The policy Android saves from [configuration]; holding needs
  /// notification access as well as the switch.
  factory QuietNotificationPolicy.fromConfiguration(
    QuietNotificationConfiguration configuration, {
    required bool hasNotificationAccess,
  }) => QuietNotificationPolicy(
    enabled: configuration.enabled && hasNotificationAccess,
    monitoredPackages: configuration.monitoredPackages,
    alwaysAllowedPackages: configuration.alwaysAllowedPackages,
    allowedUntilUtc: configuration.allowedUntilUtc,
    holdUntilUtc: configuration.holdUntilUtc,
  );

  final bool enabled;
  final Set<String> monitoredPackages;
  final Set<String> alwaysAllowedPackages;
  final Map<String, DateTime> allowedUntilUtc;
  final DateTime? holdUntilUtc;

  /// Whether a notification from [packageName] is held at [now].
  bool holds(String packageName, DateTime now, {required bool curreIsHome}) {
    if (!enabled || !curreIsHome) return false;
    final instant = now.toUtc();
    if (holdUntilUtc case final until? when !instant.isBefore(until)) {
      return false;
    }
    if (!monitoredPackages.contains(packageName)) return false;
    if (alwaysAllowedPackages.contains(packageName)) return false;
    final allowedUntil = allowedUntilUtc[packageName];
    return allowedUntil == null || !allowedUntil.isAfter(instant);
  }

  /// The held notifications in [items] to give back at [now].
  List<MissedWhileHiddenNotification> toRelease(
    Iterable<MissedWhileHiddenNotification> items,
    DateTime now, {
    required bool curreIsHome,
  }) => [
    for (final item in items)
      if (item.held && !holds(item.packageName, now, curreIsHome: curreIsHome))
        item,
  ];
}

/// A notification from a hidden app that Curre held: still held (waiting
/// for its app to come back) or already given back.
@immutable
class MissedWhileHiddenNotification {
  const MissedWhileHiddenNotification({
    required this.packageName,
    required this.appLabel,
    required this.title,
    required this.at,
    this.key,
    this.text,
    this.held = false,
  });

  factory MissedWhileHiddenNotification.fromMap(Map<Object?, Object?> map) {
    final packageName = map['package'] as String?;
    final appLabel = map['appLabel'] as String?;
    final title = map['title'] as String?;
    final atMillis = map['atMillis'] as int?;
    final key = map['key'];
    final text = map['text'];
    final held = map['held'];
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
      key: key is String && key.isNotEmpty ? key : null,
      text: text is String && text.trim().isNotEmpty ? text.trim() : null,
      held: held is bool && held,
    );
  }

  final String packageName;
  final String appLabel;
  final String title;
  final DateTime at;

  /// Android's key for the original notification, while Curre knows it.
  final String? key;

  /// The notification's text, kept on this phone only while it is held.
  final String? text;

  /// Still held: it comes back when its app does.
  final bool held;

  Map<String, Object> toMap() => <String, Object>{
    'package': packageName,
    'appLabel': appLabel,
    'title': title,
    'atMillis': at.toUtc().millisecondsSinceEpoch,
    'key': ?key,
    'text': ?text,
    'held': held,
  };

  /// The same notification once it has been given back: its text goes.
  MissedWhileHiddenNotification released() => MissedWhileHiddenNotification(
    packageName: packageName,
    appLabel: appLabel,
    title: title,
    at: at,
    key: key,
  );
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
    required this.hiddenPackages,
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

  /// The apps the user chose to hide; only their notifications are held.
  final Set<String> hiddenPackages;
  final Set<String> planPackages;
  final Set<String> grantPackages;
  final Set<String> protectedPackages;
}

enum QuietNotificationDecision {
  /// Held until its app comes back; never deleted.
  quiet,
  disabled,
  notificationAccessMissing,
  protectedApp,
  unknownApp,
  essential,
  notHidden,
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
    if (!snapshot.hiddenPackages.contains(event.packageName)) {
      return QuietNotificationDecision.notHidden;
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
