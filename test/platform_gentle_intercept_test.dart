import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:curre/core/core.dart';
import 'package:curre/platform/gentle_intercept.dart';
import 'package:curre/platform/quiet_notifications.dart';

void main() {
  const hidden = 'com.example.hidden';
  const essential = 'com.example.phone';
  const planned = 'com.example.maps';
  const granted = 'com.example.messages';
  final baseTime = DateTime.utc(2026, 10, 26, 8);

  GentleInterceptSnapshot snapshot({
    bool enabled = true,
    bool hasUsageAccess = true,
    Set<String> essentials = const <String>{essential},
    Set<String> plan = const <String>{planned},
    Set<String> grants = const <String>{granted},
    Set<String> loopGuards = const <String>{
      currePackageName,
      'android',
      'com.android.systemui',
      'com.example.launcher',
      'com.example.keyboard',
      'com.example.dialer',
    },
  }) => GentleInterceptSnapshot(
    enabled: enabled,
    hasUsageAccess: hasUsageAccess,
    launchablePackages: const <String>{hidden, essential, planned, granted},
    essentialPackages: essentials,
    planPackages: plan,
    grantPackages: grants,
    loopGuardPackages: loopGuards,
  );

  group('GentleInterceptDecisionEngine', () {
    test('intercepts a hidden launchable app', () {
      final engine = GentleInterceptDecisionEngine();

      expect(
        engine.evaluate(
          ForegroundAppEvent(packageName: hidden, at: baseTime),
          snapshot(),
        ),
        GentleInterceptDecision.intercept,
      );
    });

    test('leaves essentials, the active plan, and active grants alone', () {
      final engine = GentleInterceptDecisionEngine();
      final current = snapshot();

      expect(
        engine.evaluate(
          ForegroundAppEvent(packageName: essential, at: baseTime),
          current,
        ),
        GentleInterceptDecision.essential,
      );
      expect(
        engine.evaluate(
          ForegroundAppEvent(packageName: planned, at: baseTime),
          current,
        ),
        GentleInterceptDecision.activePlan,
      );
      expect(
        engine.evaluate(
          ForegroundAppEvent(packageName: granted, at: baseTime),
          current,
        ),
        GentleInterceptDecision.activeGrant,
      );
    });

    test('ignores Curre, system UI, launcher, keyboard, and dialer loops', () {
      final engine = GentleInterceptDecisionEngine();
      final current = snapshot();

      for (final packageName in <String>{
        currePackageName,
        'com.android.systemui',
        'com.example.launcher',
        'com.example.keyboard',
        'com.example.dialer',
      }) {
        expect(
          engine.evaluate(
            ForegroundAppEvent(packageName: packageName, at: baseTime),
            current,
          ),
          GentleInterceptDecision.loopGuard,
        );
      }
      expect(
        engine.evaluate(
          ForegroundAppEvent(packageName: 'com.example.unknown', at: baseTime),
          current,
        ),
        GentleInterceptDecision.unknownApp,
      );
    });

    test('honors access, the toggle, and the per-app cooldown', () {
      final engine = GentleInterceptDecisionEngine();
      final event = ForegroundAppEvent(packageName: hidden, at: baseTime);

      expect(
        engine.evaluate(event, snapshot(enabled: false)),
        GentleInterceptDecision.disabled,
      );
      expect(
        engine.evaluate(event, snapshot(hasUsageAccess: false)),
        GentleInterceptDecision.usageAccessMissing,
      );
      expect(
        engine.evaluate(event, snapshot()),
        GentleInterceptDecision.intercept,
      );
      expect(
        engine.evaluate(
          ForegroundAppEvent(
            packageName: hidden,
            at: baseTime.add(const Duration(seconds: 3)),
          ),
          snapshot(),
        ),
        GentleInterceptDecision.cooldown,
      );
      expect(
        engine.evaluate(
          ForegroundAppEvent(
            packageName: hidden,
            at: baseTime.add(const Duration(seconds: 5)),
          ),
          snapshot(),
        ),
        GentleInterceptDecision.intercept,
      );
    });
  });

  test('coordinator consumes a fake foreground event source', () async {
    final source = _FakeForegroundEventSource();
    final intercepted = <String>[];
    final coordinator = GentleInterceptCoordinator(
      source: source,
      snapshot: snapshot,
      onIntercept: (event) => intercepted.add(event.packageName),
    )..start();

    source.add(ForegroundAppEvent(packageName: essential, at: baseTime));
    source.add(
      ForegroundAppEvent(
        packageName: hidden,
        at: baseTime.add(const Duration(seconds: 1)),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(intercepted, <String>[hidden]);
    await coordinator.dispose();
    await source.close();
  });

  test('setting defaults on and round-trips for access granted later', () {
    expect(Settings().askWhyOnHiddenAppOpen, isTrue);

    final legacy = Settings().toJson()..remove('askWhyOnHiddenAppOpen');
    expect(Settings.fromJson(legacy).askWhyOnHiddenAppOpen, isTrue);

    final disabled = Settings(askWhyOnHiddenAppOpen: false);
    expect(Settings.fromJson(disabled.toJson()).askWhyOnHiddenAppOpen, isFalse);
    expect(Settings().quietNotificationsFromHiddenApps, isTrue);
    final oldSettings = Settings().toJson()
      ..remove('quietNotificationsFromHiddenApps');
    expect(
      Settings.fromJson(oldSettings).quietNotificationsFromHiddenApps,
      isTrue,
    );
  });

  group('QuietNotificationDecisionEngine', () {
    QuietNotificationSnapshot notificationSnapshot({
      bool enabled = true,
      bool access = true,
    }) => QuietNotificationSnapshot(
      enabled: enabled,
      hasNotificationAccess: access,
      launchablePackages: const <String>{hidden, essential, planned, granted},
      essentialPackages: const <String>{essential},
      planPackages: const <String>{planned},
      grantPackages: const <String>{granted},
    );

    PostedNotificationEvent notification(
      String packageName, {
      NotificationKind kind = NotificationKind.ordinary,
      bool clearable = true,
    }) => PostedNotificationEvent(
      packageName: packageName,
      title: 'A title, not a message body',
      at: baseTime,
      kind: kind,
      isClearable: clearable,
    );

    test('quiets only an ordinary notification from a hidden app', () {
      const engine = QuietNotificationDecisionEngine();

      expect(
        engine.evaluate(notification(hidden), notificationSnapshot()),
        QuietNotificationDecision.quiet,
      );
      expect(
        engine.evaluate(notification(essential), notificationSnapshot()),
        QuietNotificationDecision.essential,
      );
      expect(
        engine.evaluate(notification(planned), notificationSnapshot()),
        QuietNotificationDecision.activePlan,
      );
      expect(
        engine.evaluate(notification(granted), notificationSnapshot()),
        QuietNotificationDecision.activeGrant,
      );
    });

    test('never touches calls, alarms, system, or ongoing notifications', () {
      const engine = QuietNotificationDecisionEngine();
      for (final packageName in <String>{
        currePackageName,
        'android',
        'com.android.systemui',
      }) {
        expect(
          engine.evaluate(notification(packageName), notificationSnapshot()),
          QuietNotificationDecision.protectedApp,
        );
      }
      for (final kind in <NotificationKind>{
        NotificationKind.call,
        NotificationKind.alarm,
        NotificationKind.system,
      }) {
        expect(
          engine.evaluate(
            notification(hidden, kind: kind),
            notificationSnapshot(),
          ),
          QuietNotificationDecision.protectedKind,
        );
      }
      expect(
        engine.evaluate(
          notification(hidden, clearable: false),
          notificationSnapshot(),
        ),
        QuietNotificationDecision.notClearable,
      );
    });

    test('honors notification access, the toggle, and known apps', () {
      const engine = QuietNotificationDecisionEngine();

      expect(
        engine.evaluate(
          notification(hidden),
          notificationSnapshot(enabled: false),
        ),
        QuietNotificationDecision.disabled,
      );
      expect(
        engine.evaluate(
          notification(hidden),
          notificationSnapshot(access: false),
        ),
        QuietNotificationDecision.notificationAccessMissing,
      );
      expect(
        engine.evaluate(
          notification('com.example.unknown'),
          notificationSnapshot(),
        ),
        QuietNotificationDecision.unknownApp,
      );
    });

    test('fake notification source emits only filter matches', () async {
      final source = _FakeNotificationEventSource();
      final quieted = <String>[];
      final coordinator = QuietNotificationCoordinator(
        source: source,
        snapshot: notificationSnapshot,
        onQuiet: (event) => quieted.add(event.packageName),
      )..start();

      source.add(notification(essential));
      source.add(notification(hidden));
      source.add(notification(hidden, kind: NotificationKind.call));
      await Future<void>.delayed(Duration.zero);

      expect(quieted, <String>[hidden]);
      await coordinator.dispose();
      await source.close();
    });
  });
}

class _FakeForegroundEventSource implements ForegroundAppEventSource {
  final _events = StreamController<ForegroundAppEvent>();

  @override
  Stream<ForegroundAppEvent> get foregroundEvents => _events.stream;

  void add(ForegroundAppEvent event) => _events.add(event);

  Future<void> close() => _events.close();
}

class _FakeNotificationEventSource implements PostedNotificationEventSource {
  final _events = StreamController<PostedNotificationEvent>();

  @override
  Stream<PostedNotificationEvent> get notificationEvents => _events.stream;

  void add(PostedNotificationEvent event) => _events.add(event);

  Future<void> close() => _events.close();
}
