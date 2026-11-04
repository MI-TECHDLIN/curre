import 'dart:convert';

import 'package:curre/app/all_apps_screen.dart';
import 'package:curre/app/app_choice_screen.dart';
import 'package:curre/app/curre_controller.dart';
import 'package:curre/app/hidden_apps_screen.dart';
import 'package:curre/app/unlock_gate_screen.dart';
import 'package:curre/core/core.dart';
import 'package:curre/design/design.dart';
import 'package:curre/platform/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/copy_rules.dart';
import 'support/fakes.dart';

const _instagram = 'com.instagram.android';
const _netflix = 'com.netflix.mediaclient';
const _maps = 'com.google.android.apps.maps';
const _whatsapp = 'com.whatsapp';
const _monday = LocalDate(2026, 10, 26);

Settings _settings({
  Set<String> hidden = const {_instagram, _netflix},
  FocusPeriod? focus,
}) => Settings(
  displayName: 'Chidi',
  essentials: const {
    'com.google.android.dialer',
    'com.google.android.apps.messaging',
    'com.android.settings',
  },
  candidates: const {
    'com.google.android.youtube',
    'com.spotify.music',
    _maps,
    _whatsapp,
  },
  hiddenApps: hidden,
  focus: focus,
);

MissedWhileHiddenNotification _held(
  String packageName, {
  String key = 'k1',
  bool held = true,
  String? text = 'See you at 6',
}) => MissedWhileHiddenNotification(
  packageName: packageName,
  appLabel: packageName == _instagram ? 'Instagram' : 'Netflix',
  title: 'Ada',
  text: held ? text : null,
  at: DateTime.utc(2026, 10, 26, 5, 30),
  key: key,
  held: held,
);

Grant _grant(String packageName, DateTime from, {int minutes = 10}) => Grant(
  packageName: packageName,
  reason: 'reply to Ada about tonight',
  task: 'reply to Ada',
  grantedAt: from.toUtc(),
  expiresAt: from.toUtc().add(Duration(minutes: minutes)),
  source: GrantSource.clocked,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('only the chosen apps are hidden', () {
    test(
      'Home, the check and the quieting all use the same chosen set',
      () async {
        final intercept = FakeGentleIntercept(usage: true, notifications: true);
        final controller = fakeController(
          settings: _settings(),
          gentleIntercept: intercept,
        );
        await controller.initializeGentleIntercept();

        expect(controller.chosenHiddenPackages, {_instagram, _netflix});
        expect(
          controller.hiddenApps.map((app) => app.packageName),
          unorderedEquals([_instagram, _netflix]),
        );
        // Camera-like everyday apps (here Maps, WhatsApp, Gmail) open as usual.
        final open = controller.openApps.map((app) => app.packageName);
        expect(open, containsAll([_maps, _whatsapp, 'com.google.android.gm']));
        expect(open, isNot(contains(_instagram)));
        expect(controller.visiblePackages, containsAll([_maps, _whatsapp]));
        expect(intercept.intercept!.monitoredPackages, {_instagram, _netflix});
        expect(intercept.quieting!.monitoredPackages, {_instagram, _netflix});
        expect(controller.gentleInterceptSnapshot.hiddenPackages, {
          _instagram,
          _netflix,
        });
      },
    );

    test('plans choose only from apps the user did not hide', () {
      final controller = fakeController(
        settings: _settings().copyWith(
          candidates: const {_maps, _whatsapp, _instagram},
        ),
      );
      expect(
        controller.candidateApps.map((app) => app.packageName),
        unorderedEquals([_maps, _whatsapp]),
      );
    });

    test('a hidden app a plan uses is out for that plan only', () async {
      final now = DateTime(2026, 10, 26, 6, 40);
      final intercept = FakeGentleIntercept(usage: true, notifications: true);
      final controller = fakeController(
        settings: _settings(),
        gentleIntercept: intercept,
        now: now,
      );
      controller.plans = [
        Plan(
          id: 'p1',
          session: SessionName.morning,
          date: _monday,
          intention: 'reply to Ada on Instagram',
          apps: const [PlannedApp(packageName: _instagram)],
          endsAt: DateTime(2026, 10, 26, 7).toUtc(),
          source: PlanSource.clocked,
        ),
      ];
      await controller.refresh();
      expect(controller.visiblePackages, contains(_instagram));
      expect(
        intercept.quieting!.allowedUntilUtc[_instagram],
        DateTime(2026, 10, 26, 7).toUtc(),
      );
      expect(controller.hiddenApps.map((app) => app.packageName), [_netflix]);
    });

    test('hide this app, then stop hiding it', () async {
      final intercept = FakeGentleIntercept(usage: true, notifications: true);
      final controller = fakeController(
        settings: _settings(hidden: const {}),
        gentleIntercept: intercept,
      );
      await controller.initializeGentleIntercept();
      expect(intercept.quieting!.monitoredPackages, isEmpty);

      await controller.hideApp(_whatsapp);
      expect(controller.isHiddenApp(_whatsapp), isTrue);
      expect(controller.settings.candidates, isNot(contains(_whatsapp)));
      expect(intercept.quieting!.monitoredPackages, {_whatsapp});
      expect(intercept.intercept!.monitoredPackages, {_whatsapp});

      // Phone, Messages and Settings can never be hidden.
      expect(controller.canHide('com.google.android.dialer'), isFalse);
      await controller.hideApp('com.google.android.dialer');
      expect(controller.isHiddenApp('com.google.android.dialer'), isFalse);

      await controller.stopHidingApp(_whatsapp);
      expect(controller.isHiddenApp(_whatsapp), isFalse);
      // Its held notifications come back: the app is no longer watched.
      expect(intercept.quieting!.monitoredPackages, isEmpty);
    });
  });

  group('existing users keep only what they picked', () {
    test('legacy settings get their pull picks hidden, once', () async {
      final legacy = Settings(
        essentials: const {
          'com.google.android.dialer',
          'com.google.android.apps.messaging',
          'com.android.settings',
        },
        candidates: const {_maps, _whatsapp, 'com.google.android.youtube'},
      ).toJson()..remove(Settings.hiddenAppsKey);
      SharedPreferences.setMockInitialValues({
        'curre.settings.v1': jsonEncode(legacy),
        'curre.onboarding.v1': true,
      });
      final store = await CurreLocalStore.open();
      expect(store.settingsPredateHiddenApps, isTrue);

      final migrated = await CurreController.migrateHiddenApps(
        store: store,
        settings: store.loadSettings(),
        installed: CurreController.fallbackApps.map((app) => app.packageName),
      );

      // Instagram, Netflix and Chrome were left out of plans back then:
      // the pull picks. Gmail, Photos and the rest come back to Home.
      expect(migrated.hiddenApps, {_instagram, _netflix, 'com.android.chrome'});
      expect(store.settingsPredateHiddenApps, isFalse);
      expect(store.loadSettings().hiddenApps, migrated.hiddenApps);
    });

    test('a refresh migrates a start whose app list was not ready', () async {
      final legacy = _settings().toJson()..remove(Settings.hiddenAppsKey);
      SharedPreferences.setMockInitialValues({
        'curre.settings.v1': jsonEncode(legacy),
        'curre.onboarding.v1': true,
      });
      final store = await CurreLocalStore.open();
      final controller = fakeController(
        store: store,
        settings: store.loadSettings(),
      );
      expect(controller.chosenHiddenPackages, isEmpty);

      await controller.refresh();

      expect(controller.chosenHiddenPackages, {
        _instagram,
        _netflix,
        'com.android.chrome',
      });
      expect(store.settingsPredateHiddenApps, isFalse);
    });

    test('new settings never migrate', () async {
      SharedPreferences.setMockInitialValues({
        'curre.settings.v1': jsonEncode(_settings(hidden: const {}).toJson()),
      });
      final store = await CurreLocalStore.open();
      expect(store.settingsPredateHiddenApps, isFalse);
    });
  });

  group('held notifications come back', () {
    QuietNotificationPolicy policyOf(CurreController controller, bool access) =>
        QuietNotificationPolicy.fromConfiguration(
          (controller.gentleIntercept as FakeGentleIntercept).quieting!,
          hasNotificationAccess: access,
        );

    test('the rule holds only chosen, ordinary, unallowed apps', () {
      final now = DateTime.utc(2026, 10, 26, 6);
      final policy = QuietNotificationPolicy(
        enabled: true,
        monitoredPackages: const {_instagram, _netflix},
        alwaysAllowedPackages: const {'com.google.android.dialer'},
        allowedUntilUtc: {_netflix: now.add(const Duration(minutes: 5))},
      );
      expect(policy.holds(_instagram, now, curreIsHome: true), isTrue);
      expect(policy.holds(_netflix, now, curreIsHome: true), isFalse);
      expect(policy.holds(_whatsapp, now, curreIsHome: true), isFalse);
      // A grant's end is exclusive, like everywhere else.
      expect(
        policy.holds(
          _netflix,
          now.add(const Duration(minutes: 5)),
          curreIsHome: true,
        ),
        isTrue,
      );
    });

    test(
      'opening the app through “Why now?” gives its notifications back',
      () async {
        final now = DateTime(2026, 10, 26, 6, 40);
        final intercept = FakeGentleIntercept(usage: true, notifications: true);
        final controller = fakeController(
          settings: _settings(),
          gentleIntercept: intercept,
          now: now,
        );
        await controller.initializeGentleIntercept();
        final held = [_held(_instagram), _held(_netflix, key: 'k2')];
        expect(
          policyOf(controller, true).toRelease(held, now, curreIsHome: true),
          isEmpty,
        );

        controller.grants = [_grant(_instagram, now)];
        await controller.refresh();

        expect(
          policyOf(
            controller,
            true,
          ).toRelease(held, now, curreIsHome: true).map((item) => item.key),
          ['k1'],
        );
      },
    );

    test('a rest day gives everything back', () async {
      final intercept = FakeGentleIntercept(usage: true, notifications: true);
      final now = DateTime(2026, 10, 26, 6, 40);
      final controller = fakeController(
        settings: _settings(
          focus: FocusPeriod(
            purpose: FocusPurpose.exams,
            goal: '',
            startsOn: _monday,
            endsOn: _monday.addDays(14),
          ),
        ),
        gentleIntercept: intercept,
        now: now,
      );
      await controller.initializeGentleIntercept();
      expect(await controller.takeRestDay(), isTrue);

      final held = [_held(_instagram), _held(_netflix, key: 'k2')];
      expect(
        policyOf(controller, true).toRelease(held, now, curreIsHome: true),
        hasLength(2),
      );
      // Tomorrow morning, holding starts again by itself.
      expect(
        policyOf(controller, true).holds(
          _instagram,
          DateTime(2026, 10, 27, 4).toUtc(),
          curreIsHome: true,
        ),
        isTrue,
      );
    });

    test('Curre no longer being Home gives everything back', () async {
      final home = FakeHomePlatform();
      final intercept = FakeGentleIntercept(usage: true, notifications: true);
      final now = DateTime(2026, 10, 26, 6, 40);
      final controller = fakeController(
        settings: _settings(),
        home: home,
        gentleIntercept: intercept,
        now: now,
      );
      await controller.refresh();
      final held = [_held(_instagram)];
      // Android itself checks Home before holding or keeping anything.
      expect(
        policyOf(controller, true).toRelease(held, now, curreIsHome: false),
        hasLength(1),
      );

      home.isHome = false;
      await controller.refresh();
      expect(intercept.quieting!.enabled, isFalse);
      expect(
        policyOf(controller, true).toRelease(held, now, curreIsHome: true),
        hasLength(1),
      );
    });

    test('the focus ending gives everything back and holds no more', () async {
      final intercept = FakeGentleIntercept(usage: true, notifications: true);
      final focus = FocusPeriod(
        purpose: FocusPurpose.exams,
        goal: '',
        startsOn: _monday.addDays(-6),
        endsOn: _monday.addDays(1),
      );
      final controller = fakeController(
        settings: _settings(focus: focus),
        gentleIntercept: intercept,
      );
      await controller.initializeGentleIntercept();
      // Android knows when the focus ends (its last morning start) and
      // gives back by itself then, even if Curre isn't opened.
      final ends = DateTime(2026, 10, 27, 4).toUtc();
      expect(intercept.quieting!.holdUntilUtc, ends);
      final policy = policyOf(controller, true);
      final held = [_held(_instagram)];
      expect(
        policy.toRelease(
          held,
          ends.subtract(const Duration(minutes: 1)),
          curreIsHome: true,
        ),
        isEmpty,
      );
      expect(policy.toRelease(held, ends, curreIsHome: true), hasLength(1));

      await controller.endFocusNow();
      expect(controller.focusIsOver, isTrue);
      expect(intercept.quieting!.enabled, isFalse);
      expect(intercept.quieting!.holdUntilUtc, isNull);
    });

    test('the held list survives a restart and is released after it', () {
      final now = DateTime.utc(2026, 10, 26, 6);
      final saved = [
        _held(_instagram),
        _held(_netflix, key: 'k2', held: false),
      ].map((item) => item.toMap()).toList();
      // What Android saves is plain JSON; a restart reads the same list.
      final restored = (jsonDecode(jsonEncode(saved)) as List)
          .cast<Map<String, Object?>>()
          .map(MissedWhileHiddenNotification.fromMap)
          .toList();
      expect(restored.first.held, isTrue);
      expect(restored.first.text, 'See you at 6');
      expect(restored.first.key, 'k1');
      expect(restored.last.held, isFalse);
      expect(restored.last.text, isNull);

      const stillHidden = QuietNotificationPolicy(
        enabled: true,
        monitoredPackages: {_instagram},
        alwaysAllowedPackages: {},
        allowedUntilUtc: {},
      );
      expect(stillHidden.toRelease(restored, now, curreIsHome: true), isEmpty);
      const broughtBack = QuietNotificationPolicy(
        enabled: true,
        monitoredPackages: {},
        alwaysAllowedPackages: {},
        allowedUntilUtc: {},
      );
      final released = broughtBack.toRelease(restored, now, curreIsHome: true);
      expect(released.map((item) => item.key), ['k1']);
      expect(released.single.released().text, isNull);
      expect(released.single.released().held, isFalse);
    });

    test('records older builds saved still load, as already given back', () {
      final old = MissedWhileHiddenNotification.fromMap(const {
        'package': _instagram,
        'appLabel': 'Instagram',
        'title': 'Ada',
        'atMillis': 1761456600000,
      });
      expect(old.held, isFalse);
      expect(old.key, isNull);
      expect(old.text, isNull);
    });

    test('the configuration tells Android when holding ends', () {
      final until = DateTime.utc(2026, 11, 9, 4);
      final map = QuietNotificationConfiguration(
        enabled: true,
        monitoredPackages: const {_instagram},
        alwaysAllowedPackages: const {},
        allowedUntilUtc: const {},
        holdUntilUtc: until,
      ).toMap();
      expect(map['holdUntilMillis'], until.millisecondsSinceEpoch);
      expect(
        const QuietNotificationConfiguration(
          enabled: true,
          monitoredPackages: {},
          alwaysAllowedPackages: {},
          allowedUntilUtc: {},
        ).toMap().containsKey('holdUntilMillis'),
        isFalse,
      );
    });
  });

  group('screens', () {
    Future<void> pump(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(theme: curreTheme(Brightness.light), home: child),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('All apps opens an app as usual and can hide it', (
      tester,
    ) async {
      final platform = FakeDoorPlatform();
      final controller = fakeController(
        settings: _settings(),
        platform: platform,
      );
      await pump(tester, AllAppsScreen(controller: controller));

      expect(find.text('All apps'), findsOneWidget);
      expect(bannedWordsIn(visibleCopy(tester).join('\n')), isEmpty);
      await tester.enterText(find.byKey(const Key('all-apps-find')), 'a');
      await tester.pumpAndSettle();
      expect(find.text('Instagram'), findsNothing);
      await tester.enterText(find.byKey(const Key('all-apps-find')), 'whats');
      await tester.pumpAndSettle();
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(bannedWordsIn(visibleCopy(tester).join('\n')), isEmpty);

      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();
      expect(platform.launched, [_whatsapp]);

      await tester.tap(find.byKey(const ValueKey('hide-$_whatsapp')));
      await tester.pumpAndSettle();
      expect(controller.isHiddenApp(_whatsapp), isTrue);
      expect(find.text('WhatsApp'), findsNothing);
      expect(
        find.text('WhatsApp is hidden. Opening it asks “Why now?” first.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(controller.isHiddenApp(_whatsapp), isFalse);

      // Phone is always on Home: it has no hide button.
      await tester.enterText(find.byKey(const Key('all-apps-find')), 'pho');
      await tester.pumpAndSettle();
      expect(find.text('Phone'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('hide-com.google.android.dialer')),
        findsNothing,
      );
    });

    testWidgets('Hidden apps offers “Hide another app”', (tester) async {
      final controller = fakeController(settings: _settings());
      await pump(tester, HiddenAppsScreen(controller: controller));

      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('WhatsApp'), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const Key('hide-another-app')),
        200,
      );
      await tester.tap(find.byKey(const Key('hide-another-app')));
      await tester.pumpAndSettle();

      expect(find.byType(AppChoiceScreen), findsOneWidget);
      expect(find.text('2 hidden'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'whats');
      await tester.pumpAndSettle();
      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();
      expect(controller.isHiddenApp(_whatsapp), isTrue);
      expect(find.text('3 hidden'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'insta');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Instagram'));
      await tester.pumpAndSettle();
      expect(controller.isHiddenApp(_instagram), isFalse);
      expect(bannedWordsIn(visibleCopy(tester).join('\n')), isEmpty);
    });

    testWidgets('a missed notification opens through “Why now?” while hidden', (
      tester,
    ) async {
      final intercept = FakeGentleIntercept(
        notifications: true,
        missed: [_held(_instagram)],
      );
      final controller = fakeController(
        settings: _settings(),
        gentleIntercept: intercept,
      );
      await controller.refreshMissedNotifications();
      await pump(tester, MissedWhileHiddenScreen(controller: controller));

      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('See you at 6'), findsOneWidget);
      expect(find.textContaining('Held'), findsWidgets);
      expect(bannedWordsIn(visibleCopy(tester).join('\n')), isEmpty);

      await tester.tap(find.text('Ada'));
      await tester.pumpAndSettle();
      expect(find.byType(UnlockGateScreen), findsOneWidget);
      expect(intercept.openedMissed, isEmpty);
    });

    testWidgets('once its app is back, a missed notification opens straight', (
      tester,
    ) async {
      final platform = FakeDoorPlatform();
      final intercept = FakeGentleIntercept(
        notifications: true,
        missed: [_held(_instagram, held: false)],
      );
      final controller = fakeController(
        settings: _settings(hidden: const {_netflix}),
        platform: platform,
        gentleIntercept: intercept,
      );
      await controller.refreshMissedNotifications();
      await pump(tester, MissedWhileHiddenScreen(controller: controller));

      expect(find.textContaining('Given back'), findsOneWidget);
      await tester.tap(find.text('Ada'));
      await tester.pumpAndSettle();
      expect(find.byType(UnlockGateScreen), findsNothing);
      expect(intercept.openedMissed.single.packageName, _instagram);

      // If Android no longer has its tap action, the app itself opens.
      intercept.opensMissed = false;
      await tester.tap(find.text('Ada'));
      await tester.pumpAndSettle();
      expect(platform.launched, [_instagram]);
    });
  });
}
