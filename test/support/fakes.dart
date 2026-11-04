import 'dart:io';
import 'dart:typed_data';

import 'package:curre/app/curre_controller.dart';
import 'package:curre/core/core.dart';
import 'package:curre/doors/door_models.dart';
import 'package:curre/platform/platform.dart';

import 'voice_fakes.dart';

/// Test doubles for the Android side of Curre, shared by the onboarding,
/// settings, copy and error tests.
class FakeDoorPlatform implements DoorPlatform {
  FakeDoorPlatform({
    List<LaunchableApp>? apps,
    this.staticShortcuts = const <AppShortcut>[],
    this.conversationShortcuts = const <AppShortcut>[],
    this.grantHome = true,
    this.launchWorks = true,
    this.home,
    this.icons = const <String, Uint8List>{},
  }) : apps = apps ?? CurreController.fallbackApps;

  final List<LaunchableApp> apps;

  /// The icon the phone gives for each package; any other has none.
  final Map<String, Uint8List> icons;
  final List<AppShortcut> staticShortcuts;
  final List<AppShortcut> conversationShortcuts;

  /// Whether Android's home screen request ends with Curre as Home.
  bool grantHome;
  bool launchWorks;

  /// Kept in step with a home role request, when given.
  FakeHomePlatform? home;
  var launches = 0;
  final launched = <String>[];
  var homeRequests = 0;

  @override
  Future<Uint8List?> getIcon(String packageName) async => icons[packageName];

  @override
  Future<List<AppShortcut>> getConversationShortcuts(
    String packageName,
  ) async => conversationShortcuts
      .where((shortcut) => shortcut.packageName == packageName)
      .toList(growable: false);

  @override
  Future<List<AppShortcut>> getStaticShortcuts(String packageName) async =>
      staticShortcuts
          .where((shortcut) => shortcut.packageName == packageName)
          .toList(growable: false);

  @override
  Future<bool> hasShortcutHostPermission() async => false;

  @override
  Future<bool> launch(String packageName) async {
    launches++;
    launched.add(packageName);
    return launchWorks;
  }

  @override
  Future<bool> launchQueryDoor(String doorId, String query) async {
    launches++;
    return launchWorks;
  }

  @override
  Future<List<LaunchableApp>> listApps() async => apps;

  @override
  Future<bool> requestHomeRole() async {
    homeRequests++;
    if (grantHome) home?.isHome = true;
    return grantHome;
  }

  @override
  Future<bool> startShortcut(String packageName, String shortcutId) async =>
      false;
}

class FakeHomePlatform implements HomePlatformGateway {
  FakeHomePlatform({this.isHome = true});

  bool isHome;

  @override
  Future<bool> isDefaultHome() async => isHome;

  @override
  Future<void> setHomeSurfaceActive(bool active) async {}
}

class FakeHomeSettings implements HomeSettingsGateway {
  FakeHomeSettings([this.opens = HomeSettingsOpened.homeApps]);

  HomeSettingsOpened opens;
  var calls = 0;

  @override
  Future<HomeSettingsOpened> openHomeSettings() async {
    calls++;
    return opens;
  }
}

/// Android's two hidden-app permissions. Asking opens Android's screen
/// and answers once the user is back: [grants] is whether they switch the
/// permission on there.
class FakeGentleIntercept extends DisabledGentleInterceptGateway {
  FakeGentleIntercept({
    this.usage = false,
    this.notifications = false,
    this.grants = true,
    this.missed = const <MissedWhileHiddenNotification>[],
  });

  bool usage;
  bool notifications;
  bool grants;

  /// What Android kept quiet while those apps were hidden.
  List<MissedWhileHiddenNotification> missed;
  var usageRequests = 0;
  var notificationRequests = 0;
  var appInfoOpens = 0;

  /// What Curre last told Android's hidden-app check and quieting.
  GentleInterceptConfiguration? intercept;
  QuietNotificationConfiguration? quieting;

  @override
  Future<void> configureGentleIntercept(
    GentleInterceptConfiguration configuration,
  ) async => intercept = configuration;

  @override
  Future<void> configureQuietNotifications(
    QuietNotificationConfiguration configuration,
  ) async => quieting = configuration;

  @override
  Future<bool> openAppInfo() async {
    appInfoOpens++;
    return true;
  }

  @override
  Future<List<MissedWhileHiddenNotification>> loadMissedNotifications() async =>
      missed;

  @override
  Future<bool> hasUsageAccess() async => usage;

  @override
  Future<bool> requestUsageAccess() async {
    usageRequests++;
    if (grants) usage = true;
    return usage;
  }

  @override
  Future<bool> hasNotificationAccess() async => notifications;

  @override
  Future<bool> requestNotificationAccess() async {
    notificationRequests++;
    if (grants) notifications = true;
    return notifications;
  }
}

/// A store whose saves fail, like a phone that is out of space.
class FailingStore extends CurreLocalStore {
  FailingStore(super.preferences);

  var failSaves = true;

  @override
  Future<void> saveSettings(Settings settings) async {
    if (failSaves) throw const FileSystemException('No space left');
    return super.saveSettings(settings);
  }
}

class FakeNotificationGateway implements GrantNotificationGateway {
  FakeNotificationGateway({this.allow = true});

  bool allow;
  var requests = 0;

  /// What Android says before any request; null when it can't tell.
  bool? allowed;

  @override
  Future<bool?> areNotificationsAllowed() async => allowed;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    requests++;
    allowed = allow;
    return allow;
  }

  @override
  Future<void> scheduleExpiry(GrantNotificationNotice notice) async {}

  @override
  Future<void> showOngoing(GrantNotificationNotice notice) async {}
}

/// Android's scheduled notifications, kept as plain values.
class FakeReminderGateway implements ReminderNotificationGateway {
  var initializeCalls = 0;
  final cancelled = <int>[];
  final scheduled = <CurreReminder>[];

  /// What would be waiting now: scheduled and not cancelled since.
  final pending = <int, CurreReminder>{};

  @override
  Future<void> initialize() async => initializeCalls += 1;

  @override
  Future<void> cancelReminder(int id) async {
    cancelled.add(id);
    pending.remove(id);
  }

  @override
  Future<void> scheduleReminder(CurreReminder reminder) async {
    scheduled.add(reminder);
    pending[reminder.id] = reminder;
  }

  List<CurreReminder> pendingOf(CurreNotificationType type) =>
      pending.values.where((reminder) => reminder.type == type).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
}

/// A controller over the fakes, at a fixed morning moment.
CurreController fakeController({
  bool onboardingComplete = true,
  Settings? settings,
  FakeDoorPlatform? platform,
  FakeHomePlatform? home,
  FakeHomeSettings? homeSettings,
  FakeGentleIntercept? gentleIntercept,
  FakeNotificationGateway? notifications,
  LocalReminderService? reminders,
  CurreApiClient? api,
  CurreLocalStore? store,
  SpeechInputService? speech,
  DateTime? now,
  AppInventoryState appInventoryState = AppInventoryState.ready,
  List<LaterItem> laterItems = const <LaterItem>[],
  List<LocalDate> restDays = const <LocalDate>[],
  List<Attempt> historyAttempts = const <Attempt>[],
  List<ProofRecord> proofRecords = const <ProofRecord>[],
  Set<ContextPrompt> pendingPrompts = const <ContextPrompt>{},
  DateTime Function()? clock,
}) {
  final homePlatform = home ?? FakeHomePlatform();
  final launcher = platform ?? FakeDoorPlatform();
  launcher.home ??= homePlatform;
  return CurreController(
    launcher: launcher,
    homePlatform: homePlatform,
    homeSettings: homeSettings ?? FakeHomeSettings(),
    gentleIntercept: gentleIntercept ?? FakeGentleIntercept(),
    notifications: notifications == null
        ? null
        : GrantNotificationService(notifications),
    reminders: reminders,
    api: api,
    store: store,
    speech: speech ?? fakeSpeech(),
    settings:
        settings ??
        Settings(
          displayName: 'Chidi',
          // Someone who set up before the gentler default kept it on.
          proofNudges: true,
          essentials: const {
            'com.google.android.dialer',
            'com.google.android.apps.messaging',
            'com.android.settings',
          },
          candidates: const {
            'com.google.android.youtube',
            'com.spotify.music',
            'com.google.android.apps.maps',
            'com.instagram.android',
            'com.whatsapp',
          },
        ),
    apps: launcher.apps,
    appInventoryState: appInventoryState,
    laterItems: laterItems,
    restDays: restDays,
    historyAttempts: historyAttempts,
    proofRecords: proofRecords,
    onboardingComplete: onboardingComplete,
    pendingPrompts: pendingPrompts,
    now: clock ?? () => now ?? DateTime(2026, 10, 26, 6, 40),
  );
}
