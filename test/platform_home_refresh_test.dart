import 'dart:async';

import 'package:curre/core/core.dart';
import 'package:curre/platform/home_refresh.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'refreshes on resume and every minute only while Home is visible',
    () async {
      final platform = _FakeHomePlatform();
      final timers = <_FakeTimer>[];
      final intervals = <Duration>[];
      var refreshes = 0;
      final controller = HomeRefreshController(
        refresh: () async => refreshes += 1,
        homePlatform: platform,
        timerFactory: (interval, callback) {
          intervals.add(interval);
          final timer = _FakeTimer(callback);
          timers.add(timer);
          return timer;
        },
      );

      await controller.setRouteVisible(true);
      expect(refreshes, 0);

      await controller.resume();
      expect(refreshes, 1);
      expect(intervals, <Duration>[const Duration(minutes: 1)]);
      expect(platform.activeChanges.last, isTrue);

      timers.single.fire();
      await Future<void>.delayed(Duration.zero);
      expect(refreshes, 2);

      await controller.pause();
      expect(timers.single.isActive, isFalse);
      expect(platform.activeChanges.last, isFalse);
      timers.single.fire();
      await Future<void>.delayed(Duration.zero);
      expect(refreshes, 2);

      await controller.resume();
      expect(refreshes, 3);
      expect(timers, hasLength(2));

      await controller.setRouteVisible(false);
      expect(timers.last.isActive, isFalse);
      expect(platform.activeChanges.last, isFalse);
    },
  );

  test('coalesces overlapping resume callbacks into one ticker', () async {
    final platform = _FakeHomePlatform();
    final refreshStarted = Completer<void>();
    final releaseRefresh = Completer<void>();
    final timers = <_FakeTimer>[];
    final controller = HomeRefreshController(
      refresh: () async {
        refreshStarted.complete();
        await releaseRefresh.future;
      },
      homePlatform: platform,
      timerFactory: (interval, callback) {
        final timer = _FakeTimer(callback);
        timers.add(timer);
        return timer;
      },
    );
    await controller.setRouteVisible(true);

    final firstResume = controller.resume();
    await refreshStarted.future;
    final secondResume = controller.resume();
    releaseRefresh.complete();
    await Future.wait(<Future<void>>[firstResume, secondResume]);

    expect(timers, hasLength(1));
  });

  test(
    'refresh re-evaluates stored grants through the core visibility rule',
    () async {
      final expiry = DateTime.utc(2026, 10, 24, 5, 1);
      var now = expiry.subtract(const Duration(seconds: 1));
      final state = LauncherState(
        settings: Settings(essentials: const <String>{'phone'}),
        grants: <Grant>[
          Grant(
            packageName: 'instagram',
            reason: 'reply Ada',
            task: 'Ada',
            grantedAt: expiry.subtract(const Duration(minutes: 5)),
            expiresAt: expiry,
            source: GrantSource.clocked,
          ),
        ],
      );
      final emissions = <Set<String>>[];
      final refresher = HomeVisibilityRefresher(
        load: () async => HomeVisibilitySnapshot(
          apps: const <AppEntry>[
            AppEntry(
              packageName: 'phone',
              label: 'Phone',
              isEssential: true,
              isCandidate: false,
            ),
            AppEntry(
              packageName: 'instagram',
              label: 'Instagram',
              isEssential: false,
              isCandidate: true,
            ),
          ],
          state: state,
        ),
        onVisibility: (packages, evaluatedAt) => emissions.add(packages),
        now: () => now,
        timeZone: const FixedOffsetTimeZone(Duration.zero),
      );

      await refresher.refresh();
      now = expiry;
      await refresher.refresh();

      expect(emissions, <Set<String>>[
        <String>{'phone', 'instagram'},
        <String>{'phone'},
      ]);
    },
  );
}

class _FakeHomePlatform implements HomePlatformGateway {
  final List<bool> activeChanges = <bool>[];

  @override
  Future<bool> isDefaultHome() async => true;

  @override
  Future<void> setHomeSurfaceActive(bool active) async {
    activeChanges.add(active);
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this._callback);

  final void Function() _callback;
  bool _active = true;
  int _tick = 0;

  void fire() {
    if (!_active) return;
    _tick += 1;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => _tick;
}
