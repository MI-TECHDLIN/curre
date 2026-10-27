import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/core.dart';
import '../doors/door_models.dart';
import '../doors/door_router.dart';
import '../doors/launcher_channel.dart';
import '../doors/query_door_allowlist.dart';
import '../platform/platform.dart';

class CallReceipt {
  const CallReceipt({
    required this.endpoint,
    required this.elapsed,
    this.usage,
  });

  final String endpoint;
  final Duration elapsed;
  final ApiUsage? usage;
}

class PlanBuildResult {
  const PlanBuildResult.success(this.plan)
    : requiresManualChecklist = false,
      fallbackReason = null;

  const PlanBuildResult.manual(this.fallbackReason)
    : plan = null,
      requiresManualChecklist = true;

  final Plan? plan;
  final bool requiresManualChecklist;
  final PlanFallbackReason? fallbackReason;
}

enum AppInventoryState { ready, loading, failed }

/// Screen-facing state over Curre's phone-owned core.
///
/// The controller deliberately keeps network decisions separate from local
/// visibility. Home can always render from [settings], [plans] and [grants],
/// even when the backend is not configured or the platform channel is absent
/// in a web review build.
class CurreController extends ChangeNotifier {
  CurreController({
    required this.launcher,
    this.store,
    this.homePlatform = const HomePlatformService(),
    this.gentleIntercept = const DisabledGentleInterceptGateway(),
    this.homeSettings = const HomeSettingsService(),
    this.notifications,
    this.reminders,
    SpeechInputService? speech,
    this.api,
    Settings? settings,
    List<LaunchableApp> apps = const <LaunchableApp>[],
    List<Plan> plans = const <Plan>[],
    List<Grant> grants = const <Grant>[],
    List<DoorUse> doorUses = const <DoorUse>[],
    List<TaskTrace> taskTraces = const <TaskTrace>[],
    List<ProofRecord> proofRecords = const <ProofRecord>[],
    List<Plan> historyPlans = const <Plan>[],
    List<Grant> historyGrants = const <Grant>[],
    List<Attempt> historyAttempts = const <Attempt>[],
    this.appInventoryState = AppInventoryState.ready,
    List<LaterItem> laterItems = const <LaterItem>[],
    this.onboardingComplete = false,
    this.hiddenAppsTipDismissed = false,
    DateTime Function()? now,
  }) : speech = speech ?? SpeechInputService(),
       settings = settings ?? Settings(),
       apps = List<LaunchableApp>.of(apps),
       plans = List<Plan>.of(plans),
       grants = List<Grant>.of(grants),
       doorUses = List<DoorUse>.of(doorUses),
       taskTraces = List<TaskTrace>.of(taskTraces),
       proofRecords = List<ProofRecord>.of(proofRecords),
       historyPlans = List<Plan>.of(historyPlans),
       historyGrants = List<Grant>.of(historyGrants),
       historyAttempts = List<Attempt>.of(historyAttempts),
       laterItems = List<LaterItem>.of(laterItems),
       _now = now ?? DateTime.now;

  static Future<CurreController> bootstrap() async {
    const launcher = LauncherChannel();
    CurreLocalStore? store;
    try {
      store = await CurreLocalStore.open();
    } on Object {
      // SharedPreferences is intentionally optional in web review builds.
    }

    CurreApiClient? api;
    try {
      api = CurreApiClient.fromEnvironment();
      unawaited(api.warmUp());
    } on Object {
      // No dart-defines is a supported offline state, not an app-start crash.
    }

    var apps = <LaunchableApp>[];
    var appInventoryState = AppInventoryState.ready;
    try {
      apps = await launcher.listApps();
    } on Object {
      appInventoryState = AppInventoryState.failed;
    }
    if (apps.isEmpty && usesReviewInventoryFixtures()) {
      // The Android app never substitutes fixture labels for installed apps.
      // Web and desktop review builds have no launcher channel, so their
      // explicit fixture inventory remains useful for gallery review.
      apps = fallbackApps;
      appInventoryState = AppInventoryState.ready;
    } else if (apps.isEmpty) {
      appInventoryState = AppInventoryState.failed;
    }

    final now = DateTime.now();
    final settings = store?.loadSettings() ?? Settings();
    final plans = await store?.loadTodayPlans(now: now) ?? <Plan>[];
    final grants = await store?.loadActiveGrants(now: now) ?? <Grant>[];
    final uses = await store?.loadTodayDoorUses(now: now) ?? <DoorUse>[];
    final traces = store?.loadTaskTraces(now: now) ?? <TaskTrace>[];
    final proofs = store?.loadProofRecords(now: now) ?? <ProofRecord>[];
    final historyPlans = await store?.loadPlanHistory(now: now) ?? <Plan>[];
    final historyGrants = await store?.loadGrantHistory(now: now) ?? <Grant>[];
    final historyAttempts = await store?.loadAttempts(now: now) ?? <Attempt>[];
    final laterItems = store?.loadLaterItems(now: now) ?? <LaterItem>[];

    final GentleInterceptGateway gentleIntercept =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? AndroidGentleInterceptGateway()
        : const DisabledGentleInterceptGateway();
    final notificationGateway = FlutterGrantNotificationGateway();
    final controller = CurreController(
      launcher: launcher,
      store: store,
      gentleIntercept: gentleIntercept,
      notifications: GrantNotificationService(notificationGateway),
      reminders: LocalReminderService(notificationGateway),
      api: api,
      settings: settings,
      apps: apps,
      plans: plans,
      grants: grants,
      doorUses: uses,
      taskTraces: traces,
      proofRecords: proofs,
      historyPlans: historyPlans,
      historyGrants: historyGrants,
      historyAttempts: historyAttempts,
      appInventoryState: appInventoryState,
      laterItems: laterItems,
      onboardingComplete: store?.isOnboardingComplete ?? false,
      hiddenAppsTipDismissed: store?.isHiddenAppsTipDismissed ?? false,
    );
    await controller.initializeGentleIntercept();
    await controller._prepareReminders();
    return controller;
  }

  static const fallbackApps = <LaunchableApp>[
    LaunchableApp(packageName: 'com.google.android.dialer', label: 'Phone'),
    LaunchableApp(
      packageName: 'com.google.android.apps.messaging',
      label: 'Messages',
    ),
    LaunchableApp(packageName: 'com.android.settings', label: 'Settings'),
    LaunchableApp(packageName: 'com.google.android.youtube', label: 'YouTube'),
    LaunchableApp(packageName: 'com.spotify.music', label: 'Spotify'),
    LaunchableApp(packageName: 'com.google.android.apps.maps', label: 'Maps'),
    LaunchableApp(packageName: 'com.instagram.android', label: 'Instagram'),
    LaunchableApp(packageName: 'com.whatsapp', label: 'WhatsApp'),
    LaunchableApp(packageName: 'com.google.android.gm', label: 'Gmail'),
    LaunchableApp(packageName: 'com.android.chrome', label: 'Chrome'),
    LaunchableApp(
      packageName: 'com.google.android.calendar',
      label: 'Calendar',
    ),
    LaunchableApp(packageName: 'com.google.android.keep', label: 'Keep Notes'),
    LaunchableApp(packageName: 'com.google.android.photos', label: 'Photos'),
    LaunchableApp(packageName: 'com.google.android.drive', label: 'Drive'),
    LaunchableApp(packageName: 'com.netflix.mediaclient', label: 'Netflix'),
  ];

  @visibleForTesting
  static bool usesReviewInventoryFixtures({
    bool? web,
    TargetPlatform? platform,
    bool? debugMode,
  }) {
    if (web ?? kIsWeb) return true;
    return (debugMode ?? kDebugMode) &&
        (platform ?? defaultTargetPlatform) != TargetPlatform.android;
  }

  final DoorPlatform launcher;
  final CurreLocalStore? store;
  final HomePlatformGateway homePlatform;
  final GentleInterceptGateway gentleIntercept;
  final HomeSettingsGateway homeSettings;
  final GrantNotificationService? notifications;
  final LocalReminderService? reminders;
  final SpeechInputService speech;
  final CurreApiClient? api;
  final DateTime Function() _now;

  Settings settings;
  List<LaunchableApp> apps;
  List<Plan> plans;
  List<Grant> grants;
  List<DoorUse> doorUses;
  List<TaskTrace> taskTraces;
  List<ProofRecord> proofRecords;
  List<Plan> historyPlans;
  List<Grant> historyGrants;
  List<Attempt> historyAttempts;
  AppInventoryState appInventoryState;

  /// "Not now" reasons saved for a later plan, oldest first.
  List<LaterItem> laterItems;
  bool onboardingComplete;

  /// Whether the Hidden apps explainer has been put away for good.
  bool hiddenAppsTipDismissed;
  CallReceipt? lastPlanCall;
  CallReceipt? lastUnlockCall;
  CallReceipt? lastProofCall;
  CallReceipt? lastLaterCall;
  bool _firstCheckinRequested = false;
  bool _hasUsageAccess = false;
  bool _hasNotificationAccess = false;
  String? _firstIntention;
  bool _retryingProofs = false;
  DateTime? _lastPendingProofRetryAt;
  int _pendingProofRetryCursor = 0;

  static const Duration pendingProofRetryInterval = Duration(minutes: 5);
  static const int pendingProofRetryBatchSize = 2;

  final Map<String, Future<Uint8List?>> _icons = {};
  final Map<String, List<AppShortcut>> _staticShortcuts = {};
  final Map<String, List<AppShortcut>> _conversationShortcuts = {};

  DateTime get now => _now();
  bool get backendConfigured => api != null;
  bool get hasUsageAccess => _hasUsageAccess;
  bool get hasNotificationAccess => _hasNotificationAccess;
  List<MissedWhileHiddenNotification> missedWhileHidden =
      <MissedWhileHiddenNotification>[];

  SessionWindow get currentSession =>
      SessionSchedule.fromSettings(settings).current(now);

  ProofSummary get proofSummary => ProoflightRules.summarize(
    records: proofRecords,
    today: currentSession.localStartDate,
  );

  Plan? get activePlan {
    final instant = now.toUtc();
    final window = currentSession;
    final matching = plans.where(
      (plan) =>
          plan.session == window.session &&
          plan.date == window.localStartDate &&
          instant.isBefore(plan.endsAt),
    );
    // Plans are appended when they are created. The last active plan is the
    // user's latest edit even when an older plan happened to end later.
    return matching.lastOrNull;
  }

  List<Grant> get activeGrants =>
      grants.where((grant) => grant.isActiveAt(now)).toList(growable: false);

  GentleInterceptSnapshot get gentleInterceptSnapshot {
    final plan = activePlan;
    return GentleInterceptSnapshot(
      enabled: onboardingComplete && settings.askWhyOnHiddenAppOpen,
      hasUsageAccess: _hasUsageAccess,
      launchablePackages: apps.map((app) => app.packageName).toSet(),
      essentialPackages: <String>{
        ...settings.essentials,
        ...suggestedEssentials,
      },
      planPackages: plan == null
          ? const <String>{}
          : plan.apps.map((app) => app.packageName).toSet(),
      grantPackages: activeGrants.map((grant) => grant.packageName).toSet(),
    );
  }

  QuietNotificationSnapshot get quietNotificationSnapshot {
    final plan = activePlan;
    return QuietNotificationSnapshot(
      enabled: onboardingComplete && settings.quietNotificationsFromHiddenApps,
      hasNotificationAccess: _hasNotificationAccess,
      launchablePackages: apps.map((app) => app.packageName).toSet(),
      essentialPackages: <String>{
        ...settings.essentials,
        ...suggestedEssentials,
      },
      planPackages: plan == null
          ? const <String>{}
          : plan.apps.map((app) => app.packageName).toSet(),
      grantPackages: activeGrants.map((grant) => grant.packageName).toSet(),
    );
  }

  LaunchableApp? appFor(String packageName) {
    for (final app in apps) {
      if (app.packageName == packageName) return app;
    }
    return null;
  }

  List<LaunchableApp> get candidateApps =>
      settings.candidates
          .map(appFor)
          .whereType<LaunchableApp>()
          .toList(growable: false)
        ..sort(
          (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
        );

  Set<String> get visiblePackages {
    final state = LauncherState(
      settings: settings,
      plan: activePlan,
      grants: activeGrants,
    );
    return <String>{
      for (final app in apps)
        if (isVisible(app.packageName, now, state)) app.packageName,
    };
  }

  List<LaunchableApp> get hiddenApps {
    final visible = visiblePackages;
    return apps
        .where(
          (app) =>
              !visible.contains(app.packageName) &&
              app.packageName != 'com.mitech.curre',
        )
        .toList(growable: false)
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  }

  String? _findSystemPackage(RegExp packagePattern, RegExp labelPattern) {
    for (final app in apps) {
      if (packagePattern.hasMatch(app.packageName) ||
          labelPattern.hasMatch(app.label)) {
        return app.packageName;
      }
    }
    return null;
  }

  String? get phonePackage => _findSystemPackage(
    RegExp(r'(dialer|contacts)', caseSensitive: false),
    RegExp(r'^(phone|dialer)$', caseSensitive: false),
  );

  String? get messagesPackage => _findSystemPackage(
    RegExp(r'(messaging|mms)', caseSensitive: false),
    RegExp(r'^(messages|messaging)$', caseSensitive: false),
  );

  String? get androidSettingsPackage => _findSystemPackage(
    RegExp(r'\.settings$', caseSensitive: false),
    RegExp(r'^settings$', caseSensitive: false),
  );

  Set<String> get suggestedEssentials => <String>{
    ?phonePackage,
    ?messagesPackage,
    ?androidSettingsPackage,
  };

  bool takeFirstCheckinRequest() {
    final requested = _firstCheckinRequested;
    _firstCheckinRequested = false;
    return requested;
  }

  /// The plan sentence the user wrote at the end of onboarding, handed to
  /// the first check-in exactly once.
  String? takeFirstIntention() {
    final intention = _firstIntention;
    _firstIntention = null;
    return intention;
  }

  /// Saves everything onboarding asked for in one step. With a
  /// [firstIntention], Home opens the check-in and plans it straight away;
  /// without one ("I'll plan later") Home simply opens.
  Future<void> finishOnboarding({
    required String displayName,
    required String? avatarId,
    required Set<String> essentials,
    required Set<String> candidates,
    LocalTime? morningStart,
    bool? nudgesEnabled,
    String? firstIntention,
  }) async {
    final next = settings.copyWith(
      displayName: displayName,
      avatarId: avatarId,
      clearAvatarId: avatarId == null,
      essentials: essentials,
      candidates: candidates,
      sessionStarts: morningStart == null
          ? null
          : <SessionName, LocalTime>{
              ...settings.sessionStarts,
              SessionName.morning: morningStart,
            },
      checkInNudges: nudgesEnabled,
      planEndingNudges: nudgesEnabled,
      unlockTimeUpNudges: nudgesEnabled,
      proofNudges: nudgesEnabled,
    );
    // Save first: if the phone can't store the answers, onboarding stays
    // open with everything still filled in, ready to try again.
    await store?.saveSettings(next);
    await store?.setOnboardingComplete(true);
    settings = next;
    final intention = firstIntention?.trim();
    _firstIntention = intention == null || intention.isEmpty ? null : intention;
    _firstCheckinRequested = _firstIntention != null;
    onboardingComplete = true;
    await _syncGentleInterceptPolicy();
    try {
      await _syncReminderSettings();
    } on Object {
      // Reminders are optional; onboarding is already saved.
    }
    notifyListeners();
  }

  /// Saves [value] and then shows it; a failed save leaves the settings as
  /// they were and throws, so the screen can say so.
  Future<void> updateSettings(Settings value) async {
    await store?.saveSettings(value);
    final unlockNudgeChanged =
        settings.unlockTimeUpNudges != value.unlockTimeUpNudges;
    settings = value;
    await _syncGentleInterceptPolicy();
    try {
      await _syncReminderSettings(syncGrantNotifications: unlockNudgeChanged);
    } on Object {
      // Settings stay local and authoritative if notifications are unavailable.
    }
    notifyListeners();
  }

  Future<void> initializeGentleIntercept() async {
    await refreshUsageAccess(notify: false);
    await refreshNotificationAccess(notify: false);
    await refreshMissedNotifications(notify: false);
  }

  Future<bool> refreshUsageAccess({bool notify = true}) async {
    var granted = false;
    try {
      granted = await gentleIntercept.hasUsageAccess();
    } on Object {
      // Non-Android review builds have no usage-access channel.
    }
    final changed = granted != _hasUsageAccess;
    _hasUsageAccess = granted;
    await _syncGentleInterceptPolicy();
    if (notify && changed) notifyListeners();
    return granted;
  }

  Future<bool> requestUsageAccess() async {
    var granted = false;
    try {
      granted = await gentleIntercept.requestUsageAccess();
      if (!granted) granted = await gentleIntercept.hasUsageAccess();
    } on Object {
      // The settings action is unavailable outside Android.
    }
    final changed = granted != _hasUsageAccess;
    _hasUsageAccess = granted;
    await _syncGentleInterceptPolicy();
    if (changed) notifyListeners();
    return granted;
  }

  Future<bool> refreshNotificationAccess({bool notify = true}) async {
    var granted = false;
    try {
      granted = await gentleIntercept.hasNotificationAccess();
    } on Object {
      // Non-Android review builds have no notification-listener channel.
    }
    final changed = granted != _hasNotificationAccess;
    _hasNotificationAccess = granted;
    await _syncGentleInterceptPolicy();
    if (notify && changed) notifyListeners();
    return granted;
  }

  Future<bool> requestNotificationAccess() async {
    var granted = false;
    try {
      granted = await gentleIntercept.requestNotificationAccess();
      if (!granted) {
        granted = await gentleIntercept.hasNotificationAccess();
      }
    } on Object {
      // The listener settings action is unavailable outside Android.
    }
    final changed = granted != _hasNotificationAccess;
    _hasNotificationAccess = granted;
    await _syncGentleInterceptPolicy();
    if (changed) notifyListeners();
    return granted;
  }

  Future<void> refreshMissedNotifications({bool notify = true}) async {
    try {
      missedWhileHidden = await gentleIntercept.loadMissedNotifications();
    } on Object {
      missedWhileHidden = <MissedWhileHiddenNotification>[];
    }
    if (notify) notifyListeners();
  }

  Future<void> pollPendingGentleIntercept() async {
    try {
      await gentleIntercept.pollPendingForegroundEvent();
    } on Object {
      // A pending handoff is best effort; Home remains usable without it.
    }
  }

  Future<void> _syncGentleInterceptPolicy() async {
    final allowedUntil = <String, DateTime>{};
    void extend(String packageName, DateTime until) {
      final existing = allowedUntil[packageName];
      if (existing == null || existing.isBefore(until)) {
        allowedUntil[packageName] = until.toUtc();
      }
    }

    final plan = activePlan;
    if (plan != null) {
      for (final app in plan.apps) {
        extend(app.packageName, plan.endsAt);
      }
    }
    for (final grant in activeGrants) {
      extend(grant.packageName, grant.expiresAt);
    }
    final monitoredPackages = apps
        .map((app) => app.packageName)
        .where((packageName) => packageName != currePackageName)
        .toSet();
    final alwaysAllowedPackages = <String>{
      currePackageName,
      ...settings.essentials,
      ...suggestedEssentials,
    };

    try {
      await gentleIntercept.configureGentleIntercept(
        GentleInterceptConfiguration(
          enabled: onboardingComplete && settings.askWhyOnHiddenAppOpen,
          monitoredPackages: monitoredPackages,
          alwaysAllowedPackages: alwaysAllowedPackages,
          allowedUntilUtc: allowedUntil,
        ),
      );
    } on Object {
      // Android owns the foreground helper; local visibility still works if
      // it cannot be configured.
    }
    try {
      await gentleIntercept.configureQuietNotifications(
        QuietNotificationConfiguration(
          enabled:
              onboardingComplete && settings.quietNotificationsFromHiddenApps,
          monitoredPackages: monitoredPackages,
          alwaysAllowedPackages: alwaysAllowedPackages,
          allowedUntilUtc: allowedUntil,
        ),
      );
    } on Object {
      // Notification access is optional and local visibility is unaffected.
    }
  }

  Future<void> dismissHiddenAppsTip() async {
    hiddenAppsTipDismissed = true;
    notifyListeners();
    try {
      await store?.dismissHiddenAppsTip();
    } on Object {
      // Showing the tip once more next time is harmless.
    }
  }

  Future<void> updateDisplayName(String value) =>
      updateSettings(settings.copyWith(displayName: value));

  Future<void> clearHistory() async {
    await store?.clearHistory();
    try {
      await gentleIntercept.clearMissedNotifications();
    } on Object {
      // The local Flutter history still clears on review builds.
    }
    historyPlans = <Plan>[];
    historyGrants = <Grant>[];
    historyAttempts = <Attempt>[];
    laterItems = <LaterItem>[];
    missedWhileHidden = <MissedWhileHiddenNotification>[];
    taskTraces = <TaskTrace>[];
    proofRecords = ProoflightRules.forgetWords(proofRecords);
    notifyListeners();
  }

  Future<bool> requestHomeRole() async {
    try {
      await launcher.requestHomeRole();
      return await homePlatform.isDefaultHome();
    } on Object {
      return false;
    }
  }

  /// Takes the user to Android's home screen choice (see
  /// [HomeSettingsService]); never throws.
  Future<HomeSettingsOpened> openHomeSettings() async {
    try {
      return await homeSettings.openHomeSettings();
    } on Object {
      return HomeSettingsOpened.none;
    }
  }

  Future<bool> isDefaultHome() async {
    try {
      return await homePlatform.isDefaultHome();
    } on Object {
      return false;
    }
  }

  Future<bool> requestNotifications() async {
    try {
      final allowed = await notifications?.requestPermission() ?? true;
      if (allowed) await _syncReminderSettings();
      return allowed;
    } on Object {
      return false;
    }
  }

  Future<void> retryAppInventory() async {
    appInventoryState = AppInventoryState.loading;
    notifyListeners();
    try {
      final found = await launcher.listApps();
      if (found.isEmpty) {
        appInventoryState = AppInventoryState.failed;
      } else {
        apps = found;
        appInventoryState = AppInventoryState.ready;
        _icons.clear();
        _staticShortcuts.clear();
        _conversationShortcuts.clear();
      }
    } on Object {
      appInventoryState = AppInventoryState.failed;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      final found = await launcher.listApps();
      if (found.isNotEmpty) {
        apps = found;
        appInventoryState = AppInventoryState.ready;
      } else if (apps.isEmpty) {
        appInventoryState = AppInventoryState.failed;
      }
    } on Object {
      if (apps.isEmpty) appInventoryState = AppInventoryState.failed;
    }
    final instant = now;
    if (store != null) {
      settings = store!.loadSettings();
      plans = await store!.loadTodayPlans(now: instant);
      grants = await store!.loadActiveGrants(now: instant);
      doorUses = await store!.loadTodayDoorUses(now: instant);
      taskTraces = store!.loadTaskTraces(now: instant);
      proofRecords = store!.loadProofRecords(now: instant);
      laterItems = store!.loadLaterItems(now: instant);
    } else {
      grants = activeGrants;
    }
    await _syncGentleInterceptPolicy();
    notifyListeners();
    unawaited(retryPendingProofs());
  }

  Future<Uint8List?> iconFor(String packageName) =>
      _icons.putIfAbsent(packageName, () async {
        try {
          return await launcher.getIcon(packageName);
        } on Object {
          return null;
        }
      });

  Future<List<AppShortcut>> staticShortcutsFor(String packageName) async {
    final cached = _staticShortcuts[packageName];
    if (cached != null) return cached;
    try {
      final result = await launcher.getStaticShortcuts(packageName);
      return _staticShortcuts[packageName] = result;
    } on Object {
      return _staticShortcuts[packageName] = <AppShortcut>[];
    }
  }

  Future<List<AppShortcut>> conversationShortcutsFor(String packageName) async {
    final cached = _conversationShortcuts[packageName];
    if (cached != null) return cached;
    try {
      final result = await launcher.getConversationShortcuts(packageName);
      return _conversationShortcuts[packageName] = result;
    } on Object {
      return _conversationShortcuts[packageName] = <AppShortcut>[];
    }
  }

  Future<void> warmUpPlanning() async {
    await api?.warmUp();
  }

  Future<PlanBuildResult> buildPlan(String intention) async {
    final candidates = candidateApps;
    if (api == null || candidates.length < 2) {
      return const PlanBuildResult.manual(PlanFallbackReason.network);
    }

    final shortcutLists = await Future.wait(
      candidates.map((app) => staticShortcutsFor(app.packageName)),
    );
    final labelsSeen = <String, int>{};
    final requestCandidates = <PlanCandidate>[];
    for (var i = 0; i < candidates.length; i++) {
      final app = candidates[i];
      final seen = labelsSeen.update(
        app.label,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      final label = seen == 1 ? app.label : '${app.label} $seen';
      requestCandidates.add(
        PlanCandidate(
          id: app.packageName,
          label: label,
          shortcutLabels: shortcutLists[i]
              .map((shortcut) => shortcut.shortLabel)
              .toSet()
              .toList(growable: false),
          hasQueryDoor: QueryDoorAllowlist.forPackage(app.packageName) != null,
        ),
      );
    }

    final stopwatch = Stopwatch()..start();
    final result = await api!.plan(
      PlanRequest(
        session: currentSession.session,
        intention: intention,
        candidates: requestCandidates,
      ),
    );
    stopwatch.stop();
    lastPlanCall = CallReceipt(
      endpoint: '/v1/plan',
      elapsed: stopwatch.elapsed,
      usage: result.response?.usage,
    );
    notifyListeners();

    final response = result.response;
    if (response == null || response.apps.isEmpty) {
      return PlanBuildResult.manual(result.fallbackReason);
    }
    final plan = _makePlan(
      intention: intention,
      apps: response.apps
          .where((selection) => appFor(selection.id) != null)
          .map(
            (selection) => PlannedApp(
              packageName: selection.id,
              door: selection.door,
              query: selection.query,
            ),
          )
          .toList(growable: false),
      endPhrase: response.endPhrase,
      source: PlanSource.clocked,
    );
    if (plan.apps.isEmpty) {
      return const PlanBuildResult.manual(PlanFallbackReason.invalidResponse);
    }
    await _savePlan(plan);
    return PlanBuildResult.success(plan);
  }

  Future<Plan> buildManualPlan(
    String intention,
    Iterable<String> packages,
  ) async {
    final plan = _makePlan(
      intention: intention,
      apps: packages
          .where((packageName) => appFor(packageName) != null)
          .map((packageName) => PlannedApp(packageName: packageName))
          .toList(growable: false),
      source: PlanSource.manual,
    );
    await _savePlan(plan);
    return plan;
  }

  Plan _makePlan({
    required String intention,
    required List<PlannedApp> apps,
    required PlanSource source,
    SourceSpan? endPhrase,
  }) {
    final window = currentSession;
    final instant = now;
    return Plan(
      id: 'plan-${instant.toUtc().microsecondsSinceEpoch}',
      session: window.session,
      date: window.localStartDate,
      intention: intention,
      apps: apps,
      endsAt: resolvePlanEnd(
        endPhrase: endPhrase,
        now: instant,
        session: window,
      ),
      endPhrase: endPhrase,
      source: source,
    );
  }

  Future<void> _savePlan(Plan plan) async {
    plans = <Plan>[...plans, plan];
    historyPlans = <Plan>[
      ...historyPlans.where((item) => item.id != plan.id),
      plan,
    ];
    await store?.saveTodayPlans(plans, now: now);
    await store?.appendPlanHistory(plan, now: now);
    await _syncGentleInterceptPolicy();
    try {
      await reminders?.schedulePlanReminders(plan, settings: settings);
    } on Object {
      // The plan is authoritative; reminder delivery is best effort.
    }
    notifyListeners();
  }

  Future<void> _prepareReminders() async {
    try {
      await _syncReminderSettings();
    } on Object {
      // Notifications are optional on platforms without Android channels.
    }
  }

  Future<void> _syncReminderSettings({
    bool syncGrantNotifications = true,
  }) async {
    await reminders?.scheduleSessionReminders(settings);
    for (final plan in plans) {
      await reminders?.schedulePlanReminders(plan, settings: settings);
    }
    if (!syncGrantNotifications) return;
    for (final grant in activeGrants) {
      if (!settings.unlockTimeUpNudges) {
        await notifications?.endGrant(grant.packageName);
        continue;
      }
      await notifications?.startGrant(
        grant: grant,
        appLabel: appFor(grant.packageName)?.label ?? grant.packageName,
        settings: settings,
      );
    }
  }

  String destinationFor(PlannedApp app, Plan plan) {
    if (app.query case final query?) {
      final action =
          QueryDoorAllowlist.forPackage(app.packageName)?.actionLabel ??
          'Open app with';
      return '$action “${query.text}”';
    }
    if (app.door case final door?) return door;
    return 'Open app';
  }

  Future<DoorResolution> unlockDestinationFor(
    LaunchableApp app,
    UnlockResponse response,
  ) async {
    if (response.kind == ReasonKind.person && response.person != null) {
      final conversations = await conversationShortcutsFor(app.packageName);
      final match = matchConversationShortcut(
        response.person!.text,
        conversations,
      );
      return match == null
          ? const DoorResolution.plain()
          : DoorResolution.conversation(response.person!.text);
    }
    if (response.target != null &&
        QueryDoorAllowlist.forPackage(app.packageName) != null) {
      return DoorResolution.query(response.target!.text);
    }
    final shortcuts = await staticShortcutsFor(app.packageName);
    final shortcutId = _shortcutIdForLabel(shortcuts, response.door);
    if (shortcutId != null) {
      return DoorResolution.shortcut(response.door!);
    }
    return const DoorResolution.plain();
  }

  String grantDestinationFor(Grant grant) {
    final target = grant.task?.trim();
    if (target == null || target.isEmpty) return 'Open app';
    if (grant.kind == ReasonKind.person) {
      final conversations =
          _conversationShortcuts[grant.packageName] ?? const <AppShortcut>[];
      return matchConversationShortcut(target, conversations) == null
          ? 'Open app'
          : 'Chat with $target';
    }
    final queryDoor = QueryDoorAllowlist.forPackage(grant.packageName);
    if ((grant.kind == ReasonKind.task ||
            grant.kind == ReasonKind.timeSensitive) &&
        queryDoor != null) {
      return '${queryDoor.actionLabel} “$target”';
    }
    return 'Open app';
  }

  Future<DoorLaunchResult> openPlanDoor(Plan plan, PlannedApp app) async {
    final staticShortcuts = await staticShortcutsFor(app.packageName);
    final target = app.query?.text;
    final queryDoor = QueryDoorAllowlist.forPackage(app.packageName);
    final shortcutId = _shortcutIdForLabel(staticShortcuts, app.door);
    final router = DoorRouter(launcher, copyTarget: _copyTarget);
    final result = await router.open(
      DoorRequest(
        packageName: app.packageName,
        kind: ReasonKind.task,
        target: target,
        queryDoorId: queryDoor?.id,
        chosenShortcutId: shortcutId,
        staticShortcuts: staticShortcuts,
      ),
    );
    if (result.succeeded) {
      final use = DoorUse.forPlan(plan, app.packageName, now);
      doorUses = <DoorUse>[...doorUses, use];
      await store?.recordDoorUse(use, now: now);
      await _recordTaskTrace(
        TaskTrace.forTask(
          PlannedTask.forDoor(plan, app),
          kind: TaskTraceKind.door,
          at: now,
        ),
      );
      notifyListeners();
    }
    return result;
  }

  /// The task's record, if it has one: supported, waiting, or done without
  /// proof.
  ProofRecord? proofFor(PlannedTask task) => proofRecords
      .where((record) => record.id == ProoflightRules.recordId(task))
      .lastOrNull;

  TaskTrace? latestTraceFor(PlannedTask task) =>
      taskTraces.where((trace) => trace.supports(task)).lastOrNull;

  /// Whether returning from a door should ask what changed: only while the
  /// task has no record. A supported, waiting or done task is not asked
  /// again, so a door used often never nags.
  bool asksAfterDoor(PlannedTask task) => proofFor(task) == null;

  /// The unfinished task a plan-ending proof reminder should open.
  /// A task Curre saw start wins; otherwise the first unfinished door is a
  /// calm fallback. Finished plans do not reopen an already completed task.
  PlannedTask? proofTaskForPlan(String? planId) {
    if (planId == null || planId.isEmpty) return null;
    final plan = <Plan>[
      ...plans,
      ...historyPlans,
    ].where((item) => item.id == planId).firstOrNull;
    if (plan == null) return null;
    final tasks = plan.apps.isEmpty
        ? <PlannedTask>[PlannedTask.offline(plan)]
        : <PlannedTask>[
            for (final app in plan.apps) PlannedTask.forDoor(plan, app),
          ];
    final unfinished = tasks.where((task) => proofFor(task) == null).toList();
    PlannedTask? latestStarted;
    DateTime? latestAt;
    for (final task in unfinished) {
      final at = latestTraceFor(task)?.at;
      if (at != null && (latestAt == null || at.isAfter(latestAt))) {
        latestStarted = task;
        latestAt = at;
      }
    }
    return latestStarted ?? unfinished.firstOrNull;
  }

  /// The tasks done away from the phone that Home offers: the active plan's
  /// when it has no doors, and any started today whose plan has since
  /// ended but which still waits for its Done.
  List<PlannedTask> get offlineTasksOnHome {
    final active = activePlan;
    final today = currentSession.localStartDate;
    return <PlannedTask>[
      if (active != null && active.apps.isEmpty) PlannedTask.offline(active),
      for (final plan in plans)
        if (plan.id != active?.id &&
            plan.date == today &&
            plan.apps.isEmpty &&
            latestTraceFor(PlannedTask.offline(plan)) != null &&
            proofFor(PlannedTask.offline(plan)) == null)
          PlannedTask.offline(plan),
    ];
  }

  /// How the completion sheet names a task: the door it went through
  /// ("YouTube → Search “G chord”"), or the time away from the phone.
  String taskTitle(PlannedTask task) =>
      titleFor(planId: task.planId, packageName: task.packageName);

  /// [taskTitle] for a task known only by its plan and door, as a proof
  /// record keeps it.
  String titleFor({required String planId, String? packageName}) {
    final package = packageName;
    if (package == null) return 'Away from your phone';
    final plan = <Plan>[
      ...plans,
      ...historyPlans,
    ].where((plan) => plan.id == planId).firstOrNull;
    final app = plan?.apps
        .where((app) => app.packageName == package)
        .firstOrNull;
    final label = appFor(package)?.label ?? package;
    if (plan == null || app == null) return label;
    return '$label → ${destinationFor(app, plan)}';
  }

  Future<TaskTrace> startOfflineTask(PlannedTask task) async {
    final trace = TaskTrace.forTask(
      task,
      kind: TaskTraceKind.offlineStart,
      at: now,
    );
    await _recordTaskTrace(trace);
    notifyListeners();
    return trace;
  }

  Future<void> _recordTaskTrace(TaskTrace trace) async {
    taskTraces = <TaskTrace>[...taskTraces, trace];
    await store?.appendTaskTrace(trace, now: now);
  }

  /// Sends a completion note to be judged and saves its record against the
  /// task's own Curre day. Without the backend the note waits as pending.
  Future<ProofSubmission> submitProof({
    required PlannedTask task,
    required String note,
  }) async {
    final before = proofSummary;
    final response = await _judgeProof(task.text, note);
    final record = ProoflightRules.recordFromResponse(
      task: task,
      note: note,
      submittedAt: now,
      response: response,
      trace: latestTraceFor(task),
    );
    await _upsertProof(record, redactions: response.redactions);
    final after = proofSummary;
    notifyListeners();
    return ProofSubmission(
      record: record,
      before: before,
      after: after,
      kind: response.kind,
      mismatch: response.mismatch,
    );
  }

  /// A check-off: kept and honest, but self-reported, so it never adds a
  /// proof day. A note typed first stays on the phone and is not sent.
  Future<ProofSubmission> markDone({
    required PlannedTask task,
    String note = '',
  }) async {
    final before = proofSummary;
    final record = ProoflightRules.checkOff(
      task: task,
      at: now,
      trace: latestTraceFor(task),
      note: note,
    );
    await _upsertProof(record);
    final after = proofSummary;
    notifyListeners();
    return ProofSubmission(record: record, before: before, after: after);
  }

  Future<ProofResponse> _judgeProof(String task, String note) async {
    final client = api;
    if (client == null) return const ProofResponse.pending();
    final stopwatch = Stopwatch()..start();
    final response = await client.proof(
      ProofRequest(task: _clip(task, 500), note: _clip(note, 300)),
    );
    stopwatch.stop();
    lastProofCall = CallReceipt(
      endpoint: '/v1/proof',
      elapsed: stopwatch.elapsed,
      usage: response.usage,
    );
    return response;
  }

  static String _clip(String value, int maxRunes) =>
      String.fromCharCodes(value.runes.take(maxRunes));

  Future<void> _upsertProof(
    ProofRecord record, {
    List<Redaction>? redactions,
  }) async {
    final stored = redactedProofRecord(record, redactions);
    final previous = proofRecords
        .where((item) => item.id == stored.id)
        .firstOrNull;
    final preferred = ProoflightRules.preferRecord(previous, stored);
    proofRecords = <ProofRecord>[
      ...proofRecords.where((item) => item.id != stored.id),
      preferred,
    ]..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
    await store?.upsertProofRecord(preferred, now: now);
  }

  /// Sends notes that are still waiting again, without moving their day:
  /// an accepted one is credited to its plan's own Curre day. Small
  /// rotating batches stay below the proof route's per-IP limit even
  /// though Home refreshes every minute.
  Future<void> retryPendingProofs() async {
    if (_retryingProofs || api == null) return;
    final pending = proofRecords
        .where(
          (record) =>
              record.isPending &&
              record.note.isNotEmpty &&
              record.taskText.isNotEmpty,
        )
        .toList(growable: false);
    if (pending.isEmpty) {
      _pendingProofRetryCursor = 0;
      return;
    }
    final attemptedAt = now.toUtc();
    final lastAttempt = _lastPendingProofRetryAt;
    if (lastAttempt != null) {
      final elapsed = attemptedAt.difference(lastAttempt);
      if (!elapsed.isNegative && elapsed < pendingProofRetryInterval) return;
    }
    _lastPendingProofRetryAt = attemptedAt;
    final start = _pendingProofRetryCursor % pending.length;
    final count = pending.length < pendingProofRetryBatchSize
        ? pending.length
        : pendingProofRetryBatchSize;
    final batch = <ProofRecord>[
      for (var offset = 0; offset < count; offset++)
        pending[(start + offset) % pending.length],
    ];
    _pendingProofRetryCursor = (start + count) % pending.length;
    _retryingProofs = true;
    var changed = false;
    try {
      for (final old in batch) {
        final response = await _judgeProof(old.taskText, old.note);
        if (response.outcome == ProofOutcome.pending) continue;
        // The user may have written a newer note for the task meanwhile.
        final current = proofRecords
            .where((record) => record.id == old.id)
            .firstOrNull;
        if (current == null ||
            !current.isPending ||
            current.submittedAt != old.submittedAt) {
          continue;
        }
        await _upsertProof(
          ProoflightRules.recordFromPending(pending: old, response: response),
          redactions: response.redactions,
        );
        changed = true;
      }
    } finally {
      _retryingProofs = false;
    }
    if (changed) notifyListeners();
  }

  /// Keeps a "Not now" reason for the next plan, with the words Extract
  /// picked out of it, so it can open there when it comes back.
  Future<LaterItem> saveForLater({
    required LaunchableApp app,
    required String reason,
    required UnlockResponse response,
  }) async {
    final instant = now;
    final item = LaterItem(
      id: 'later-${instant.toUtc().microsecondsSinceEpoch}',
      packageName: app.packageName,
      appLabel: app.label,
      reason: reason,
      target: response.target,
      redactions: response.redactions,
      savedAt: instant,
    );
    laterItems =
        await store?.saveLaterItem(item, now: instant) ??
        LaterShelfRules.add(laterItems, item, instant);
    notifyListeners();
    return item;
  }

  /// Whether "Not today" put the Later shelf away for this Curre day.
  bool get laterShelfDismissedToday =>
      store?.laterShelfDismissedOn == currentSession.localStartDate ||
      _laterDismissedOn == currentSession.localStartDate;
  LocalDate? _laterDismissedOn;

  Future<void> dismissLaterShelf() async {
    _laterDismissedOn = currentSession.localStartDate;
    notifyListeners();
    try {
      await store?.dismissLaterShelf(_laterDismissedOn!);
    } on Object {
      // Seeing the shelf once more today is harmless.
    }
  }

  /// What the Later shelf offers for [intention]: saved items that fit the
  /// plan, best first, as ranked from the plan's words. Offline, or when
  /// ranking fails, the newest come first instead, quietly.
  Future<LaterShelf> arrangeLaterShelf(String intention) async {
    final items = LaterShelfRules.current(laterItems, now);
    if (items.isEmpty || laterShelfDismissedToday) return LaterShelf.empty;
    final client = api;
    if (client == null) return LaterShelfRules.arrange(items);
    final ranked = items.reversed
        .take(LaterShelfRules.maxItems)
        .toList(growable: false);
    final stopwatch = Stopwatch()..start();
    final response = await client.later(
      LaterRequest(
        plan: _clip(intention, 500),
        items: <LaterRequestItem>[
          for (final item in ranked)
            LaterRequestItem(
              id: item.id,
              appLabel: _clip(item.appLabel, 60),
              text: _clip(item.reason, 300),
            ),
        ],
      ),
    );
    stopwatch.stop();
    lastLaterCall = CallReceipt(
      endpoint: '/v1/later',
      elapsed: stopwatch.elapsed,
      usage: response?.usage,
    );
    return LaterShelfRules.arrange(items, ranks: response?.items);
  }

  /// Opens a saved item at its words. Its app gets the usual time, and the
  /// item leaves the shelf once the app opens.
  Future<DoorLaunchResult> openLaterItem(LaterItem item) async {
    final instant = now.toUtc();
    final grant = Grant(
      packageName: item.packageName,
      reason: item.reason,
      task: item.target?.text,
      grantedAt: instant,
      expiresAt: instant.add(
        Duration(minutes: settings.unlockMinutes.clamp(1, 30)),
      ),
      source: GrantSource.later,
      kind: ReasonKind.browse,
    );
    await _saveGrant(
      grant,
      appFor(item.packageName)?.label ?? item.appLabel,
      redactions: item.redactions,
      taskSpan: item.target,
    );
    final staticShortcuts = await staticShortcutsFor(item.packageName);
    final router = DoorRouter(launcher, copyTarget: _copyTarget);
    final result = await router.open(
      DoorRequest(
        packageName: item.packageName,
        kind: ReasonKind.browse,
        target: item.target?.text,
        queryDoorId: QueryDoorAllowlist.forPackage(item.packageName)?.id,
        staticShortcuts: staticShortcuts,
      ),
    );
    if (result.succeeded) {
      laterItems =
          await store?.removeLaterItem(item.id, now: now) ??
          laterItems.where((saved) => saved.id != item.id).toList();
      notifyListeners();
    }
    return result;
  }

  /// Where a saved item's door lands, in the words the user wrote.
  String laterDestination(LaterItem item) {
    final target = item.target?.text;
    if (target == null || target.trim().isEmpty) return item.reason;
    if (QueryDoorAllowlist.forPackage(item.packageName) != null) {
      return 'Search “$target”';
    }
    return target;
  }

  Future<bool> plainLaunch(String packageName) async {
    try {
      return await launcher.launch(packageName);
    } on Object {
      return false;
    }
  }

  Future<DoorLaunchResult> openGrantDoor(Grant grant) async {
    final staticShortcuts = await staticShortcutsFor(grant.packageName);
    final conversationShortcuts = await conversationShortcutsFor(
      grant.packageName,
    );
    final kind = grant.kind ?? ReasonKind.unclear;
    final target = grant.task;
    final router = DoorRouter(launcher, copyTarget: _copyTarget);
    return router.open(
      DoorRequest(
        packageName: grant.packageName,
        kind: kind,
        person: kind == ReasonKind.person ? target : null,
        target: kind == ReasonKind.task || kind == ReasonKind.timeSensitive
            ? target
            : null,
        queryDoorId: QueryDoorAllowlist.forPackage(grant.packageName)?.id,
        conversationShortcuts: conversationShortcuts,
        staticShortcuts: staticShortcuts,
      ),
    );
  }

  Future<UnlockResponse> judgeUnlock({
    required LaunchableApp app,
    required String reason,
  }) async {
    final shortcuts = await staticShortcutsFor(app.packageName);
    final stopwatch = Stopwatch()..start();
    final response = api == null
        ? const UnlockResponse.unavailable()
        : await api!.unlock(
            UnlockRequest(
              appLabel: app.label,
              planIntention: activePlan?.intention,
              reason: reason,
              threshold: settings.threshold,
              shortcutLabels: shortcuts
                  .map((shortcut) => shortcut.shortLabel)
                  .toSet()
                  .toList(growable: false),
            ),
          );
    stopwatch.stop();
    lastUnlockCall = CallReceipt(
      endpoint: '/v1/unlock',
      elapsed: stopwatch.elapsed,
      usage: response.usage,
    );
    await _logAttempt(
      app: app,
      reason: reason,
      response: response,
      overridden: false,
    );
    notifyListeners();
    return response;
  }

  Future<DoorLaunchResult> grantAndOpen({
    required LaunchableApp app,
    required String reason,
    required UnlockResponse response,
  }) async {
    final grant = grantFromUnlock(
      response: response,
      packageName: app.packageName,
      reason: reason,
      now: now,
      fallbackUnlockMinutes: settings.unlockMinutes,
    );
    if (grant != null) {
      await _saveGrant(
        grant,
        app.label,
        redactions: response.redactions,
        taskSpan: response.target ?? response.person,
      );
    }
    return _openUnlockDoor(app, response);
  }

  Future<DoorLaunchResult> finishOverride({
    required LaunchableApp app,
    required String reason,
    required UnlockResponse response,
  }) async {
    final grant = grantFromFinishedOverride(
      response: response,
      packageName: app.packageName,
      reason: reason,
      finishedAt: now,
      fallbackUnlockMinutes: settings.unlockMinutes,
    );
    await _saveGrant(
      grant,
      app.label,
      redactions: response.redactions,
      taskSpan: response.target ?? response.person,
    );
    await _markLatestAttemptOverridden(
      app: app,
      reason: reason,
      response: response,
    );
    final launched = await plainLaunch(app.packageName);
    return DoorLaunchResult(
      launched ? DoorLaunchKind.plainLaunch : DoorLaunchKind.failed,
    );
  }

  Future<DoorLaunchResult> _openUnlockDoor(
    LaunchableApp app,
    UnlockResponse response,
  ) async {
    final staticShortcuts = await staticShortcutsFor(app.packageName);
    final conversationShortcuts = await conversationShortcutsFor(
      app.packageName,
    );
    final router = DoorRouter(launcher, copyTarget: _copyTarget);
    return router.open(
      DoorRequest(
        packageName: app.packageName,
        kind: response.kind ?? ReasonKind.unclear,
        person: response.person?.text,
        target: response.target?.text,
        queryDoorId: QueryDoorAllowlist.forPackage(app.packageName)?.id,
        chosenShortcutId: _shortcutIdForLabel(staticShortcuts, response.door),
        conversationShortcuts: conversationShortcuts,
        staticShortcuts: staticShortcuts,
      ),
    );
  }

  Future<void> _saveGrant(
    Grant grant,
    String appLabel, {
    List<Redaction>? redactions,
    SourceSpan? taskSpan,
  }) async {
    final historyGrant = redactedGrant(grant, redactions, taskSpan: taskSpan);
    grants = <Grant>[
      ...grants.where((item) => item.packageName != grant.packageName),
      grant,
    ];
    historyGrants = <Grant>[
      ...historyGrants.where(
        (item) =>
            item.packageName != grant.packageName ||
            item.grantedAt != grant.grantedAt,
      ),
      historyGrant,
    ];
    await store?.saveActiveGrants(grants, now: now);
    await store?.appendGrantHistory(historyGrant, now: now);
    // Update Android before opening the granted app, otherwise the usage
    // event from that launch could race the new grant and reopen the gate.
    await _syncGentleInterceptPolicy();
    try {
      await notifications?.startGrant(
        grant: grant,
        appLabel: appLabel,
        settings: settings,
      );
    } on Object {
      // Stored expiry is authoritative; a notification is only a nudge.
    }
    notifyListeners();
  }

  Future<void> _logAttempt({
    required LaunchableApp app,
    required String reason,
    required UnlockResponse response,
    required bool overridden,
  }) async {
    final highlights = <SourceSpan>[
      ?response.person,
      ?response.target,
      ?literalSpanInSource(reason, response.guard?.quote.text),
    ];
    final attempt = redactedAttempt(
      Attempt(
        at: now,
        packageName: app.packageName,
        outcome: response.outcome,
        confidence: response.confidence,
        overridden: overridden,
        kind: response.kind,
        reason: reason,
        highlights: highlights,
      ),
      response.redactions,
    );
    historyAttempts = <Attempt>[...historyAttempts, attempt];
    await store?.appendAttempt(attempt, now: now);
  }

  Future<void> _markLatestAttemptOverridden({
    required LaunchableApp app,
    required String reason,
    required UnlockResponse response,
  }) async {
    final historyReason = redactedHistoryText(reason, response.redactions);
    final index = historyAttempts.lastIndexWhere(
      (attempt) =>
          attempt.packageName == app.packageName &&
          attempt.reason == historyReason &&
          attempt.outcome == response.outcome &&
          !attempt.overridden,
    );
    if (index < 0) {
      await _logAttempt(
        app: app,
        reason: reason,
        response: response,
        overridden: true,
      );
      return;
    }

    final previous = historyAttempts[index];
    historyAttempts[index] = Attempt(
      at: previous.at,
      packageName: previous.packageName,
      outcome: previous.outcome,
      confidence: previous.confidence,
      overridden: true,
      kind: previous.kind,
      reason: previous.reason,
      highlights: previous.highlights,
    );
    await store?.saveAttempts(historyAttempts, now: now);
    notifyListeners();
  }

  String? _shortcutIdForLabel(List<AppShortcut> shortcuts, String? label) {
    if (label == null) return null;
    final wanted = label.trim().toLowerCase();
    for (final shortcut in shortcuts) {
      if (shortcut.matchLabels.any(
        (value) => value.trim().toLowerCase() == wanted,
      )) {
        return shortcut.id;
      }
    }
    return null;
  }

  Future<void> _copyTarget(String value) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
    } on Object {
      // Clipboard support is a convenience for a failed door. It must never
      // prevent the final plain-app fallback from opening.
    }
  }

  @override
  void dispose() {
    api?.close();
    unawaited(gentleIntercept.dispose());
    super.dispose();
  }
}
