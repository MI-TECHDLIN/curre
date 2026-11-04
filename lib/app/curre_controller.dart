import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/core.dart';
import '../doors/door_models.dart';
import '../doors/door_router.dart';
import '../doors/launcher_channel.dart';
import '../doors/query_door_allowlist.dart';
import '../l10n/l10n.dart';
import '../platform/platform.dart';
import 'onboarding/app_hints.dart';

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
    List<LocalDate> restDays = const <LocalDate>[],
    this.onboardingComplete = false,
    this.hiddenAppsTipDismissed = false,
    this.focusOfferDismissed = false,
    Set<ContextPrompt> pendingPrompts = const <ContextPrompt>{},
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
       restDays = List<LocalDate>.of(restDays),
       pendingPrompts = Set<ContextPrompt>.of(pendingPrompts),
       _now = now ?? DateTime.now {
    this.speech.languageProvider = () => effectiveLanguageCode(
      preference: this.settings.languageCode,
      phoneLocale: PlatformDispatcher.instance.locale,
    );
  }

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
    var settings = store?.loadSettings() ?? Settings();
    if (store != null &&
        store.isOnboardingComplete &&
        store.settingsPredateHiddenApps &&
        appInventoryState == AppInventoryState.ready) {
      settings = await migrateHiddenApps(
        store: store,
        settings: settings,
        installed: apps.map((app) => app.packageName),
      );
    }
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
    final notificationGateway = FlutterGrantNotificationGateway(
      languageCode: effectiveLanguageCode(
        preference: settings.languageCode,
        phoneLocale: PlatformDispatcher.instance.locale,
      ),
    );
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
      restDays: store?.loadRestDays() ?? const <LocalDate>[],
      onboardingComplete: store?.isOnboardingComplete ?? false,
      hiddenAppsTipDismissed: store?.isHiddenAppsTipDismissed ?? false,
      focusOfferDismissed: store?.isFocusOfferDismissed ?? false,
      pendingPrompts: store?.pendingPrompts ?? const <ContextPrompt>{},
    );
    await controller.initializeGentleIntercept();
    await controller._prepareReminders();
    // Later starts: fetch the voice files quietly if they are still missing.
    if (controller.onboardingComplete) {
      unawaited(controller.speech.prefetch.start());
    }
    return controller;
  }

  /// Fills the explicit hidden list once for someone who set Curre up when
  /// every app outside a plan was hidden: their "What pulls you in?" picks
  /// stay hidden ([legacyHiddenApps]) and every other app comes back. Saved
  /// at once so it happens only one time; if saving fails, the next start
  /// tries again.
  @visibleForTesting
  static Future<Settings> migrateHiddenApps({
    required CurreLocalStore store,
    required Settings settings,
    required Iterable<String> installed,
  }) async {
    final next = settings.copyWith(
      hiddenApps: legacyHiddenApps(
        settings: settings,
        installed: installed,
        pullPackages: commonPullPackages,
      ),
    );
    try {
      await store.saveSettings(next);
    } on Object {
      // Still use it for this start.
    }
    return next;
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

  String get languageCode => effectiveLanguageCode(
    preference: settings.languageCode,
    phoneLocale: PlatformDispatcher.instance.locale,
  );

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

  /// Rest days taken, oldest first (see [RestDayRules]).
  List<LocalDate> restDays;

  /// Whether "Set a focus" was put away on Home.
  bool focusOfferDismissed;

  /// The Curre day reminders were last set for; they are set again once a
  /// new day starts.
  LocalDate? _remindersSetFor;

  /// Android's last answer to "is Curre the home screen?"; null until it
  /// has answered.
  bool? _curreIsHome;

  /// Another home screen is in use: the hidden-app check and notification
  /// quieting pause until Curre is Home again, so leaving Curre really
  /// leaves it. Plans, history and settings stay.
  bool get pausedAwayFromHome => _curreIsHome == false;

  /// Whether "Why now?" applies at this moment: switched on, Curre is Home
  /// and today isn't a rest day.
  bool get _askingWhy =>
      onboardingComplete &&
      settings.askWhyOnHiddenAppOpen &&
      !pausedAwayFromHome &&
      !isRestDay;

  /// Whether hidden apps' notifications are held at this moment. Once a
  /// focus has ended Curre gives them all back and holds no more, until
  /// another focus starts.
  bool get _quieting =>
      onboardingComplete &&
      settings.quietNotificationsFromHiddenApps &&
      !pausedAwayFromHome &&
      !isRestDay &&
      !focusIsOver;

  /// When the running focus ends (its last day's morning start), so Android
  /// stops holding notifications then by itself; null without a running
  /// focus.
  DateTime? get focusEndsAt {
    final current = focus;
    if (current == null || focusIsOver) return null;
    final morning = settings.sessionStarts[SessionName.morning]!;
    final end = current.endsOn;
    return DateTime(
      end.year,
      end.month,
      end.day,
      morning.hour,
      morning.minute,
    ).toUtc();
  }

  /// What setup left to ask in context, until each is answered once.
  final Set<ContextPrompt> pendingPrompts;
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
    restDays: restDays,
  );

  /// Today's Curre day, which starts at the morning start.
  LocalDate get today => currentSession.localStartDate;

  /// What this stretch with Curre is for, if a focus is set.
  FocusPeriod? get focus => settings.focus;

  /// A focus is set and its end date has come: Home shows how it went.
  bool get focusIsOver => focus?.isOverOn(today) ?? false;

  /// A focus is set and still running.
  bool get focusIsRunning => focus != null && !focusIsOver;

  /// Today is a rest day: hidden apps open without asking why and no
  /// reminders come, until tomorrow's morning start.
  bool get isRestDay => restDays.contains(today);

  /// Whether today can become a rest day: during a focus, one a week.
  bool get canRestToday =>
      focusIsRunning && RestDayRules.canRest(today, restDays);

  /// The next day a rest day can be taken.
  LocalDate get nextRestDay => RestDayRules.nextAllowed(today, restDays);

  /// When today's rest ends: the next morning start.
  DateTime get restEndsAt {
    final schedule = SessionSchedule.fromSettings(settings);
    var window = currentSession;
    for (var i = 0; i < SessionName.values.length; i++) {
      if (window.localStartDate != today) break;
      window = schedule.current(window.endsAt);
    }
    return window.startsAt;
  }

  /// How the focus has gone so far (or went, once it is over).
  FocusSummary? get focusSummary {
    final current = focus;
    if (current == null) return null;
    final schedule = SessionSchedule.fromSettings(settings);
    return FocusSummary.of(
      focus: current,
      today: today,
      proofRecords: proofRecords,
      attempts: historyAttempts,
      restDays: restDays,
      curreDay: (instant) => schedule.current(instant).localStartDate,
    );
  }

  Plan? get activePlan {
    final instant = now.toUtc();
    final window = currentSession;
    final matching = plans.where(
      (plan) =>
          plan.date == window.localStartDate &&
          (plan.startsAt != null || plan.session == window.session) &&
          !instant.isBefore(
            plan.startsAt ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          ) &&
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
      enabled: _askingWhy,
      hasUsageAccess: _hasUsageAccess,
      launchablePackages: apps.map((app) => app.packageName).toSet(),
      essentialPackages: <String>{
        ...settings.essentials,
        ...suggestedEssentials,
      },
      hiddenPackages: chosenHiddenPackages,
      planPackages: plan == null
          ? const <String>{}
          : plan.apps
                .where((app) => app.isAvailableAt(now, plan))
                .map((app) => app.packageName)
                .toSet(),
      grantPackages: activeGrants.map((grant) => grant.packageName).toSet(),
    );
  }

  QuietNotificationSnapshot get quietNotificationSnapshot {
    final plan = activePlan;
    return QuietNotificationSnapshot(
      enabled: _quieting,
      hasNotificationAccess: _hasNotificationAccess,
      launchablePackages: apps.map((app) => app.packageName).toSet(),
      essentialPackages: <String>{
        ...settings.essentials,
        ...suggestedEssentials,
      },
      hiddenPackages: chosenHiddenPackages,
      planPackages: plan == null
          ? const <String>{}
          : plan.apps
                .where((app) => app.isAvailableAt(now, plan))
                .map((app) => app.packageName)
                .toSet(),
      grantPackages: activeGrants.map((grant) => grant.packageName).toSet(),
    );
  }

  /// The installed apps the user chose to hide (never Curre or an app
  /// always on Home), whether or not a plan or grant has them out now.
  Set<String> get chosenHiddenPackages {
    final alwaysOn = <String>{...settings.essentials, ...suggestedEssentials};
    return <String>{
      for (final app in apps)
        if (settings.hiddenApps.contains(app.packageName) &&
            app.packageName != currePackageName &&
            !alwaysOn.contains(app.packageName))
          app.packageName,
    };
  }

  /// Whether the user chose to hide [packageName].
  bool isHiddenApp(String packageName) =>
      chosenHiddenPackages.contains(packageName);

  LaunchableApp? appFor(String packageName) {
    for (final app in apps) {
      if (app.packageName == packageName) return app;
    }
    return null;
  }

  /// The apps plans can use: never one the user hid.
  List<LaunchableApp> get candidateApps =>
      settings.candidates
          .where((package) => !settings.hiddenApps.contains(package))
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

  /// The apps the user hid that are hidden right now (a plan or a grant
  /// can bring one out for a while), by name.
  List<LaunchableApp> get hiddenApps {
    final visible = visiblePackages;
    final chosen = chosenHiddenPackages;
    return apps
        .where(
          (app) =>
              chosen.contains(app.packageName) &&
              !visible.contains(app.packageName),
        )
        .toList(growable: false)
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  }

  /// Every app that opens as usual: all but Curre and the apps the user
  /// hid, by name. Home's "All apps" lists them.
  List<LaunchableApp> get openApps {
    final chosen = chosenHiddenPackages;
    return apps
        .where(
          (app) =>
              app.packageName != currePackageName &&
              !chosen.contains(app.packageName),
        )
        .toList(growable: false)
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  }

  /// Whether the user may hide [packageName]: not Curre, and not an app
  /// always on Home (Phone, Messages, Settings and any they added).
  bool canHide(String packageName) =>
      packageName != currePackageName &&
      !settings.essentials.contains(packageName) &&
      !suggestedEssentials.contains(packageName);

  /// "Hide this app": it leaves Home and plans, asks "Why now?" and has its
  /// notifications held from now on. Throws if it can't be saved.
  Future<void> hideApp(String packageName) async {
    if (!canHide(packageName) || settings.hiddenApps.contains(packageName)) {
      return;
    }
    await updateSettings(
      settings.copyWith(
        hiddenApps: <String>{...settings.hiddenApps, packageName},
        candidates: <String>{...settings.candidates}..remove(packageName),
      ),
    );
  }

  /// Stops hiding [packageName] for good: it opens as usual again and any
  /// notifications held for it come back. Throws if it can't be saved.
  Future<void> stopHidingApp(String packageName) async {
    if (!settings.hiddenApps.contains(packageName)) return;
    await updateSettings(
      settings.copyWith(
        hiddenApps: <String>{...settings.hiddenApps}..remove(packageName),
      ),
    );
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

  /// Saves everything onboarding asked for in one step, and leaves every
  /// [ContextPrompt] to be offered in context later. With a
  /// [firstIntention], Home opens the check-in and plans it straight away;
  /// without one ("I'll plan later") Home simply opens.
  Future<void> finishOnboarding({
    required String displayName,
    required String? avatarId,
    required Set<String> essentials,
    required Set<String> candidates,
    Set<String> hidden = const <String>{},
    LocalTime? morningStart,
    String? firstIntention,
    FocusChoice? focus,
  }) async {
    var next = settings.copyWith(
      displayName: displayName,
      avatarId: avatarId,
      clearAvatarId: avatarId == null,
      essentials: essentials,
      candidates: candidates.difference(hidden),
      hiddenApps: hidden.difference(essentials),
      sessionStarts: morningStart == null
          ? null
          : <SessionName, LocalTime>{
              ...settings.sessionStarts,
              SessionName.morning: morningStart,
            },
    );
    if (focus != null) {
      final day = SessionSchedule.fromSettings(next)
          .current(now)
          .localStartDate;
      next = next.copyWith(focus: focus.periodFrom(day));
    }
    const prompts = <ContextPrompt>{...ContextPrompt.values};
    // Save first: if the phone can't store the answers, onboarding stays
    // open with everything still filled in, ready to try again.
    await store?.saveSettings(next);
    await store?.savePendingPrompts(prompts);
    await store?.setOnboardingComplete(true);
    try {
      await store?.clearOnboardingDraft();
    } on Object {
      // A leftover draft is ignored once onboarding is complete.
    }
    settings = next;
    pendingPrompts
      ..clear()
      ..addAll(prompts);
    final intention = firstIntention?.trim();
    _firstIntention = intention == null || intention.isEmpty ? null : intention;
    _firstCheckinRequested = _firstIntention != null;
    onboardingComplete = true;
    // Voice typing's files start downloading quietly now (Wi-Fi only by
    // default), so the mic is usually ready by its first tap.
    unawaited(speech.prefetch.start());
    await _syncGentleInterceptPolicy();
    try {
      await _syncReminderSettings();
    } on Object {
      // Reminders are optional; onboarding is already saved.
    }
    notifyListeners();
  }

  /// Onboarding's answers so far, saved by an earlier start of Curre.
  OnboardingDraft? get onboardingDraft => store?.loadOnboardingDraft();

  /// Keeps onboarding's answers so far. Best effort: onboarding carries on
  /// if the phone can't save them.
  Future<void> saveOnboardingDraft(OnboardingDraft draft) async {
    try {
      await store?.saveOnboardingDraft(draft);
    } on Object {
      // Only a restart mid-onboarding would miss them.
    }
  }

  /// Notices when another copy of Curre (Android's Home, started when Curre
  /// became the home screen) finished onboarding, and shows Home here too.
  Future<void> catchUpOnboarding() async {
    final saved = store;
    if (onboardingComplete || saved == null) return;
    try {
      await saved.reloadFromDisk();
    } on Object {
      return;
    }
    if (onboardingComplete || !saved.isOnboardingComplete) return;
    onboardingComplete = true;
    pendingPrompts
      ..clear()
      ..addAll(saved.pendingPrompts);
    await refresh();
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
    await isDefaultHome();
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

  /// Opens what a held notification pointed at, once its app opens as
  /// usual (a hidden app asks "Why now?" first, on the screen's side).
  Future<bool> openMissedNotification(
    MissedWhileHiddenNotification item,
  ) async {
    var opened = false;
    try {
      opened = await gentleIntercept.openMissedNotification(item);
    } on Object {
      opened = false;
    }
    if (!opened) opened = await plainLaunch(item.packageName);
    unawaited(refreshMissedNotifications());
    return opened;
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
        extend(app.packageName, app.availableUntil(plan));
      }
    }
    for (final grant in activeGrants) {
      extend(grant.packageName, grant.expiresAt);
    }
    // Only the apps the user chose to hide are watched and held; every other
    // app opens and notifies as usual.
    final monitoredPackages = chosenHiddenPackages;
    // A rest day lets every hidden app open without asking, and its
    // notifications through, until the next morning start; Android picks
    // both up again by itself after that.
    if (isRestDay) {
      final until = restEndsAt;
      for (final packageName in monitoredPackages) {
        extend(packageName, until);
      }
    }
    final alwaysAllowedPackages = <String>{
      currePackageName,
      ...settings.essentials,
      ...suggestedEssentials,
    };

    try {
      await gentleIntercept.configureGentleIntercept(
        GentleInterceptConfiguration(
          enabled:
              onboardingComplete &&
              settings.askWhyOnHiddenAppOpen &&
              !pausedAwayFromHome,
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
              onboardingComplete &&
              settings.quietNotificationsFromHiddenApps &&
              !pausedAwayFromHome &&
              !focusIsOver,
          monitoredPackages: monitoredPackages,
          alwaysAllowedPackages: alwaysAllowedPackages,
          allowedUntilUtc: allowedUntil,
          holdUntilUtc: focusEndsAt,
        ),
      );
    } on Object {
      // Notification access is optional and local visibility is unaffected.
    }
  }

  /// Whether to offer [prompt] now: not answered yet, and Android doesn't
  /// already allow what it asks for.
  bool offers(ContextPrompt prompt) =>
      pendingPrompts.contains(prompt) &&
      switch (prompt) {
        ContextPrompt.nudges => true,
        ContextPrompt.askWhy => !_hasUsageAccess,
        ContextPrompt.quietHidden => !_hasNotificationAccess,
      };

  /// Marks [prompt] as answered, so it is never offered in context again
  /// (Curre settings still has it).
  Future<void> settlePrompt(ContextPrompt prompt) async {
    if (!pendingPrompts.remove(prompt)) return;
    notifyListeners();
    try {
      await store?.savePendingPrompts(pendingPrompts);
    } on Object {
      // Offering it once more next time is harmless.
    }
  }

  /// Answers the quiet nudge offer. Asks Android when [allow]; if the
  /// answer is no either way, every quiet nudge is saved as off so
  /// settings tell the truth. Returns whether nudges can appear.
  Future<bool> answerNudgeOffer({required bool allow}) async {
    final allowed = allow && await requestNotifications();
    if (!allowed && settings.hasAnyNudges) {
      try {
        await updateSettings(
          settings.copyWith(
            checkInNudges: false,
            planEndingNudges: false,
            unlockTimeUpNudges: false,
            proofNudges: false,
            focusNudges: false,
          ),
        );
      } on Object {
        // Settings still offers the switches.
      }
    }
    await settlePrompt(ContextPrompt.nudges);
    return allowed;
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

  /// Starts a focus today from [choice], in place of any earlier one.
  Future<void> startFocus(FocusChoice choice) =>
      updateSettings(settings.copyWith(focus: choice.periodFrom(today)));

  /// Moves the running focus's end to [day]: later to extend it, or today
  /// to end it now (Home then shows how it went).
  Future<void> changeFocusEnd(LocalDate day) async {
    final current = focus;
    if (current == null) return;
    final earliest = today.compareTo(current.startsOn) < 0
        ? current.startsOn
        : today;
    final end = day.compareTo(earliest) < 0 ? earliest : day;
    await updateSettings(settings.copyWith(focus: current.endingOn(end)));
  }

  /// Ends the focus today; Home shows how it went.
  Future<void> endFocusNow() => changeFocusEnd(today);

  /// Puts away "Set a focus" on Home; Curre settings still has it.
  Future<void> dismissFocusOffer() async {
    focusOfferDismissed = true;
    notifyListeners();
    try {
      await store?.dismissFocusOffer();
    } on Object {
      // Offering it once more next time is harmless.
    }
  }

  /// Makes today a rest day, if it can be one ([canRestToday]): hidden apps
  /// open without asking and reminders stay quiet until the next morning
  /// start. Prooflight skips the day, so no run ends because of it.
  Future<bool> takeRestDay() async {
    if (!canRestToday) return false;
    await _saveRestDays(<LocalDate>[...restDays, today]);
    return true;
  }

  /// Takes today's rest day back: Curre is strict again from now.
  Future<void> endRestDay() async {
    if (!isRestDay) return;
    await _saveRestDays(restDays.where((day) => day != today).toList());
  }

  Future<void> _saveRestDays(List<LocalDate> days) async {
    await store?.saveRestDays(days);
    restDays = days..sort();
    await _syncGentleInterceptPolicy();
    try {
      await _syncReminderSettings(syncGrantNotifications: false);
    } on Object {
      // The rest day is saved; reminders are best effort.
    }
    notifyListeners();
  }

  /// "Go back to my old home screen" when a focus ends: Curre stops asking
  /// why and stops quieting hidden apps (and their "Plan your day"
  /// reminders), the focus is put away, and Android's home screen choice
  /// opens. History and proof days stay on this phone.
  Future<HomeSettingsOpened> leaveForOldHomeScreen() async {
    await updateSettings(
      settings.copyWith(
        clearFocus: true,
        askWhyOnHiddenAppOpen: false,
        quietNotificationsFromHiddenApps: false,
        checkInNudges: false,
      ),
    );
    return openHomeSettings();
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
      final isHome = await homePlatform.isDefaultHome();
      if (_curreIsHome != isHome) {
        _curreIsHome = isHome;
        await _syncGentleInterceptPolicy();
      }
      return isHome;
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

  /// Whether Android lets Curre's notifications appear; null when Curre
  /// can't tell.
  Future<bool?> notificationsAllowed() async {
    try {
      return await notifications?.areNotificationsAllowed();
    } on Object {
      return null;
    }
  }

  /// Opens Curre's App info page, for "Allow restricted settings"; never
  /// throws.
  Future<bool> openAppInfo() async {
    try {
      return await gentleIntercept.openAppInfo();
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
      // Bootstrap fills the hidden list once; this covers a start whose
      // app list hadn't loaded yet.
      if (onboardingComplete &&
          store!.settingsPredateHiddenApps &&
          appInventoryState == AppInventoryState.ready) {
        settings = await migrateHiddenApps(
          store: store!,
          settings: settings,
          installed: apps.map((app) => app.packageName),
        );
      }
      plans = await store!.loadTodayPlans(now: instant);
      grants = await store!.loadActiveGrants(now: instant);
      doorUses = await store!.loadTodayDoorUses(now: instant);
      taskTraces = store!.loadTaskTraces(now: instant);
      proofRecords = store!.loadProofRecords(now: instant);
      laterItems = store!.loadLaterItems(now: instant);
      restDays = store!.loadRestDays();
    } else {
      grants = activeGrants;
    }
    await isDefaultHome();
    await _syncGentleInterceptPolicy();
    // Each reminder fires once; a new Curre day sets the next ones.
    if (_remindersSetFor != today) await _prepareReminders();
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

  /// True while a plan, reason or note call is slow, or is the first call
  /// before anything has answered this session. Screens that wait on one
  /// show [GettingReadyNote] in place.
  ValueListenable<bool> get waking => api?.waking ?? _neverWaking;
  static final ValueNotifier<bool> _neverWaking = ValueNotifier<bool>(false);

  Future<PlanBuildResult> buildPlan(String intention) async {
    final candidates = candidateApps;
    if (api == null || candidates.length < 2) {
      return const PlanBuildResult.manual(PlanFallbackReason.network);
    }

    final shortcutLists = await Future.wait(
      candidates.map((app) => staticShortcutsFor(app.packageName)),
    );
    final requestCandidates = planCandidatesFrom([
      for (var i = 0; i < candidates.length; i++)
        (
          id: candidates[i].packageName,
          label: candidates[i].label,
          shortcutLabels: shortcutLists[i].map(
            (shortcut) => shortcut.shortLabel,
          ),
          hasQueryDoor:
              QueryDoorAllowlist.forPackage(candidates[i].packageName) != null,
        ),
    ]);
    if (requestCandidates.length < 2) {
      return const PlanBuildResult.manual(PlanFallbackReason.network);
    }

    final stopwatch = Stopwatch()..start();
    final result = await api!.plan(
      PlanRequest(
        session: currentSession.session,
        intention: intention,
        candidates: requestCandidates,
        language: languageCode,
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
              timing: selection.timing,
            ),
          )
          .toList(growable: false),
      endPhrase: response.endPhrase,
      timing: response.timing,
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
    PlanTimeExpression? timing,
  }) {
    final window = currentSession;
    final instant = now;
    final labels = <String, String>{
      for (final app in apps)
        if (appFor(app.packageName) case final installed?)
          app.packageName: installed.label,
    };
    final fallbackPerApp = parseEnglishPerAppTimes(intention, labels);
    final appTimes = <String, PlanTimeExpression>{};
    for (final app in apps) {
      final merged = mergePlanTimeExpressions(
        app.timing,
        fallbackPerApp[app.packageName] ?? const PlanTimeExpression(),
      );
      if (!merged.isEmpty) appTimes[app.packageName] = merged;
    }
    final perAppSpans = <SourceSpan>[
      for (final value in appTimes.values) ...<SourceSpan>[
        ?value.durationPhrase,
        ?value.startPhrase,
        ?value.endPhrase,
      ],
    ];
    var serverTime = timing;
    if (serverTime == null && endPhrase != null) {
      serverTime = PlanTimeExpression(
        endPhrase: endPhrase,
        endClock: normalizeEnglishClock(endPhrase.text),
      );
    }
    if (serverTime != null) {
      serverTime = timeExpressionWithoutSpans(serverTime, perAppSpans);
    }
    final fallbackTime = parseEnglishTimeExpression(
      intention,
      excluded: perAppSpans,
    );
    final planTime = mergePlanTimeExpressions(serverTime, fallbackTime);
    final resolved = resolvePlanTime(
      expression: planTime,
      now: instant,
      session: window,
    );

    var planEnd = resolved.endsAt;
    var wasCapped = resolved.wasCapped;
    final appEnds = <String, DateTime>{};
    for (final entry in appTimes.entries) {
      final own = resolvePlanTime(
        expression: entry.value,
        now: resolved.startsAt,
        session: window,
        fallbackEnd: planEnd,
      );
      appEnds[entry.key] = own.endsAt;
      wasCapped = wasCapped || own.wasCapped;
    }
    if (planTime.isEmpty && appEnds.isNotEmpty) {
      planEnd = appEnds.values.reduce(
        (left, right) => left.isAfter(right) ? left : right,
      );
    }
    final resolvedApps = apps
        .map((app) {
          final ownEnd = appEnds[app.packageName];
          return PlannedApp(
            packageName: app.packageName,
            door: app.door,
            query: app.query,
            timing: appTimes[app.packageName],
            endsAt: ownEnd == null
                ? null
                : (ownEnd.isAfter(planEnd) ? planEnd : ownEnd),
          );
        })
        .toList(growable: false);
    return Plan(
      id: 'plan-${instant.toUtc().microsecondsSinceEpoch}',
      session: window.session,
      date: window.localStartDate,
      intention: intention,
      apps: resolvedApps,
      startsAt: resolved.startsAt,
      endsAt: planEnd,
      endPhrase: planTime.endPhrase,
      timing: planTime,
      timeWasCapped: wasCapped,
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
      await reminders?.schedulePlanReminders(
        plan,
        settings: settings,
        restDays: restDays,
      );
    } on Object {
      // The plan is authoritative; reminder delivery is best effort.
    }
    await _schedulePlanAppNotifications(plan);
    notifyListeners();
  }

  Future<void> _schedulePlanAppNotifications(Plan plan) async {
    if (!settings.unlockTimeUpNudges) return;
    final grantedAt = plan.startsAt ?? now.toUtc();
    for (final app in plan.apps) {
      final ownEnd = app.endsAt;
      if (ownEnd == null ||
          !ownEnd.isBefore(plan.endsAt) ||
          !ownEnd.isAfter(now.toUtc()) ||
          !chosenHiddenPackages.contains(app.packageName)) {
        continue;
      }
      try {
        await notifications?.startGrant(
          grant: Grant(
            packageName: app.packageName,
            reason: plan.intention,
            task: app.query?.text,
            grantedAt: grantedAt,
            expiresAt: ownEnd,
            source: GrantSource.clocked,
          ),
          appLabel: appFor(app.packageName)?.label ?? app.packageName,
          settings: settings,
        );
      } on Object {
        // The allowance remains exact even if its nudge cannot be scheduled.
      }
    }
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
    final service = reminders;
    if (service != null) {
      if (!onboardingComplete) {
        // Nothing to plan yet: no "Plan your day" before setup is done.
        await service.cancelSessionReminders();
      } else {
        await service.scheduleSessionReminders(settings, restDays: restDays);
      }
      await service.scheduleFocusEnd(settings);
      for (final plan in plans) {
        if (plan.endedEarly) {
          await service.cancelPlanReminders(plan);
        } else {
          await service.schedulePlanReminders(
            plan,
            settings: settings,
            restDays: restDays,
          );
        }
      }
      _remindersSetFor = today;
    }
    if (!syncGrantNotifications) return;
    final plan = activePlan;
    if (plan != null) await _schedulePlanAppNotifications(plan);
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

  String destinationFor(PlannedApp app, Plan plan, [AppLocalizations? l10n]) {
    if (app.query case final query?) {
      final template = QueryDoorAllowlist.forPackage(app.packageName);
      final action = template == null
          ? l10n?.openAppWith ?? 'Open app with'
          : _queryAction(template, l10n);
      return '$action “${query.text}”';
    }
    if (app.door case final door?) return door;
    return l10n?.openAppGeneric ?? 'Open app';
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

  String grantDestinationFor(Grant grant, [AppLocalizations? l10n]) {
    final target = grant.task?.trim();
    if (target == null || target.isEmpty) {
      return l10n?.openAppGeneric ?? 'Open app';
    }
    if (grant.kind == ReasonKind.person) {
      final conversations =
          _conversationShortcuts[grant.packageName] ?? const <AppShortcut>[];
      return matchConversationShortcut(target, conversations) == null
          ? l10n?.openAppGeneric ?? 'Open app'
          : l10n?.chatWith(target) ?? 'Chat with $target';
    }
    final queryDoor = QueryDoorAllowlist.forPackage(grant.packageName);
    if ((grant.kind == ReasonKind.task ||
            grant.kind == ReasonKind.timeSensitive) &&
        queryDoor != null) {
      return '${_queryAction(queryDoor, l10n)} “$target”';
    }
    return l10n?.openAppGeneric ?? 'Open app';
  }

  Future<DoorLaunchResult> openPlanDoor(Plan plan, PlannedApp app) async {
    if (!app.isAvailableAt(now, plan)) {
      return const DoorLaunchResult(DoorLaunchKind.failed, detail: 'time_up');
    }
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

  /// The active plan's tasks, split into still to do and done.
  PlanCompletion? get activePlanCompletion {
    final plan = activePlan;
    return plan == null ? null : PlanCompletion.of(plan, proofFor);
  }

  /// Whether every task Home shows is done: all of the active plan's, and
  /// no earlier task away from the phone still waits for its Done.
  bool get allTasksDone {
    final completion = activePlanCompletion;
    if (completion == null || !completion.allDone) return false;
    return offlineTasksOnHome.every((task) => proofFor(task) != null);
  }

  /// Ends the active plan now, once its tasks are done: its apps go back to
  /// Hidden apps, its reminders are dropped, and History keeps the early
  /// end. Returns the plan as it was, for [undoEndPlan], or null when no
  /// plan is running.
  Future<Plan?> endPlanNow() async {
    final plan = activePlan;
    if (plan == null) return null;
    await _replacePlan(plan.endedEarlyAt(now));
    try {
      await reminders?.cancelPlanReminders(plan);
    } on Object {
      // The plan has ended either way; reminder delivery is best effort.
    }
    return plan;
  }

  /// Brings back a plan [endPlanNow] ended, as long as its planned end has
  /// not passed meanwhile. Returns whether it is running again.
  Future<bool> undoEndPlan(Plan original) async {
    final current = plans.where((plan) => plan.id == original.id).lastOrNull;
    if (current == null || !current.endedEarly) return false;
    final restored = current.withEarlyEndUndone();
    if (!now.toUtc().isBefore(restored.endsAt)) return false;
    await _replacePlan(restored);
    try {
      await reminders?.schedulePlanReminders(restored, settings: settings);
    } on Object {
      // The plan is authoritative; reminder delivery is best effort.
    }
    return true;
  }

  Future<void> _replacePlan(Plan plan) async {
    plans = <Plan>[for (final item in plans) item.id == plan.id ? plan : item];
    historyPlans = historyPlans.any((item) => item.id == plan.id)
        ? <Plan>[
            for (final item in historyPlans) item.id == plan.id ? plan : item,
          ]
        : <Plan>[...historyPlans, plan];
    await store?.saveTodayPlans(plans, now: now);
    await store?.appendPlanHistory(plan, now: now);
    await _syncGentleInterceptPolicy();
    notifyListeners();
  }

  /// Applies a time phrase from confirmation. The same parser handles the
  /// original sentence and this small correction, so adjusting never opens a
  /// second interpretation path.
  Future<Plan?> adjustPlanTime(
    Plan plan,
    String phrase, {
    String? packageName,
  }) async {
    final expression = parseEnglishTimeExpression(phrase.trim());
    if (expression.isEmpty) return null;
    final window = SessionSchedule.fromSettings(settings)
        .current(plan.startsAt ?? now);

    Plan updated;
    if (packageName == null) {
      final resolved = resolvePlanTime(
        expression: expression,
        now: now,
        session: window,
      );
      final apps = <PlannedApp>[];
      for (final app in plan.apps) {
        final ownTiming = app.timing;
        DateTime? ownEnd;
        if (ownTiming != null && !ownTiming.isEmpty) {
          ownEnd = resolvePlanTime(
            expression: ownTiming,
            now: resolved.startsAt,
            session: window,
            fallbackEnd: resolved.endsAt,
            maximumEnd: resolved.endsAt,
          ).endsAt;
        }
        apps.add(
          PlannedApp(
            packageName: app.packageName,
            door: app.door,
            query: app.query,
            timing: ownTiming,
            endsAt: ownEnd,
          ),
        );
      }
      updated = plan.withTiming(
        startsAt: resolved.startsAt,
        endsAt: resolved.endsAt,
        timing: expression,
        timeWasCapped: resolved.wasCapped,
        apps: apps,
      );
    } else {
      final app = plan.apps
          .where((item) => item.packageName == packageName)
          .firstOrNull;
      if (app == null) return null;
      final resolved = resolvePlanTime(
        expression: expression,
        now: plan.startsAt ?? now,
        session: window,
        fallbackEnd: plan.endsAt,
        maximumEnd: plan.endsAt,
      );
      final apps = <PlannedApp>[
        for (final item in plan.apps)
          item.packageName == packageName
              ? PlannedApp(
                  packageName: item.packageName,
                  door: item.door,
                  query: item.query,
                  timing: expression,
                  endsAt: resolved.endsAt,
                )
              : item,
      ];
      updated = plan.withTiming(
        startsAt: plan.startsAt ?? now,
        endsAt: plan.endsAt,
        timing: plan.timing ?? const PlanTimeExpression(),
        timeWasCapped: plan.timeWasCapped,
        apps: apps,
      );
    }
    await _replacePlan(updated);
    await _schedulePlanAppNotifications(updated);
    return updated;
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
  String taskTitle(PlannedTask task, [AppLocalizations? l10n]) =>
      titleFor(planId: task.planId, packageName: task.packageName, l10n: l10n);

  /// [taskTitle] for a task known only by its plan and door, as a proof
  /// record keeps it.
  String titleFor({
    required String planId,
    String? packageName,
    AppLocalizations? l10n,
  }) {
    final package = packageName;
    if (package == null) return l10n?.awayFromPhone ?? 'Away from your phone';
    final plan = <Plan>[
      ...plans,
      ...historyPlans,
    ].where((plan) => plan.id == planId).firstOrNull;
    final app = plan?.apps
        .where((app) => app.packageName == package)
        .firstOrNull;
    final label = appFor(package)?.label ?? package;
    if (plan == null || app == null) return label;
    return '$label → ${destinationFor(app, plan, l10n)}';
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
      ProofRequest(
        task: _clip(task, 500),
        note: _clip(note, 300),
        language: languageCode,
      ),
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
        language: languageCode,
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
  String laterDestination(LaterItem item, [AppLocalizations? l10n]) {
    final target = item.target?.text;
    if (target == null || target.trim().isEmpty) return item.reason;
    if (QueryDoorAllowlist.forPackage(item.packageName) != null) {
      return '${l10n?.doorActionSearch ?? 'Search'} “$target”';
    }
    return target;
  }

  String _queryAction(QueryDoorTemplate template, AppLocalizations? l10n) =>
      switch (template.id) {
        'gmail_compose' => l10n?.doorActionDraft ?? template.actionLabel,
        'calendar_event' => l10n?.doorActionNewEvent ?? template.actionLabel,
        _ => l10n?.doorActionSearch ?? template.actionLabel,
      };

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
              appLabel: cleanApiLabel(app.label) ?? 'this app',
              planIntention: activePlan?.intention,
              reason: reason,
              threshold: settings.threshold,
              language: languageCode,
              shortcutLabels: cleanShortcutLabels(
                shortcuts.map((shortcut) => shortcut.shortLabel),
              ),
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
    speech.prefetch.stop();
    unawaited(gentleIntercept.dispose());
    super.dispose();
  }
}
