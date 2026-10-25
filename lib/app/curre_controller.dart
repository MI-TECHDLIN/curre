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
    this.notifications,
    SpeechInputService? speech,
    this.api,
    Settings? settings,
    List<LaunchableApp> apps = const <LaunchableApp>[],
    List<Plan> plans = const <Plan>[],
    List<Grant> grants = const <Grant>[],
    List<DoorUse> doorUses = const <DoorUse>[],
    List<Plan> historyPlans = const <Plan>[],
    List<Grant> historyGrants = const <Grant>[],
    List<Attempt> historyAttempts = const <Attempt>[],
    this.onboardingComplete = false,
    DateTime Function()? now,
  }) : speech = speech ?? SpeechInputService(),
       settings = settings ?? Settings(),
       apps = List<LaunchableApp>.of(apps),
       plans = List<Plan>.of(plans),
       grants = List<Grant>.of(grants),
       doorUses = List<DoorUse>.of(doorUses),
       historyPlans = List<Plan>.of(historyPlans),
       historyGrants = List<Grant>.of(historyGrants),
       historyAttempts = List<Attempt>.of(historyAttempts),
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
    } on Object {
      // No dart-defines is a supported offline state, not an app-start crash.
    }

    var apps = <LaunchableApp>[];
    try {
      apps = await launcher.listApps();
    } on Object {
      // Method channels are absent on web; sample labels keep review builds
      // navigable without pretending that they are installed Android apps.
    }
    if (apps.isEmpty) apps = fallbackApps;

    final now = DateTime.now();
    final settings = store?.loadSettings() ?? Settings();
    final plans = await store?.loadTodayPlans(now: now) ?? <Plan>[];
    final grants = await store?.loadActiveGrants(now: now) ?? <Grant>[];
    final uses = await store?.loadTodayDoorUses(now: now) ?? <DoorUse>[];
    final historyPlans = await store?.loadPlanHistory(now: now) ?? <Plan>[];
    final historyGrants = await store?.loadGrantHistory(now: now) ?? <Grant>[];
    final historyAttempts = await store?.loadAttempts(now: now) ?? <Attempt>[];

    return CurreController(
      launcher: launcher,
      store: store,
      notifications: GrantNotificationService(
        FlutterGrantNotificationGateway(),
      ),
      api: api,
      settings: settings,
      apps: apps,
      plans: plans,
      grants: grants,
      doorUses: uses,
      historyPlans: historyPlans,
      historyGrants: historyGrants,
      historyAttempts: historyAttempts,
      onboardingComplete: store?.isOnboardingComplete ?? false,
    );
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

  final DoorPlatform launcher;
  final CurreLocalStore? store;
  final HomePlatformGateway homePlatform;
  final GrantNotificationService? notifications;
  final SpeechInputService speech;
  final CurreApiClient? api;
  final DateTime Function() _now;

  Settings settings;
  List<LaunchableApp> apps;
  List<Plan> plans;
  List<Grant> grants;
  List<DoorUse> doorUses;
  List<Plan> historyPlans;
  List<Grant> historyGrants;
  List<Attempt> historyAttempts;
  bool onboardingComplete;
  CallReceipt? lastPlanCall;
  CallReceipt? lastUnlockCall;
  bool _firstCheckinRequested = false;

  final Map<String, Future<Uint8List?>> _icons = {};
  final Map<String, List<AppShortcut>> _staticShortcuts = {};
  final Map<String, List<AppShortcut>> _conversationShortcuts = {};

  DateTime get now => _now();
  bool get backendConfigured => api != null;

  SessionWindow get currentSession =>
      SessionSchedule.fromSettings(settings).current(now);

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

  Future<void> finishOnboarding({
    required String displayName,
    required Set<String> essentials,
    required Set<String> candidates,
  }) async {
    settings = settings.copyWith(
      displayName: displayName,
      essentials: essentials,
      candidates: candidates,
    );
    _firstCheckinRequested = true;
    onboardingComplete = true;
    await store?.saveSettings(settings);
    await store?.setOnboardingComplete(true);
    notifyListeners();
  }

  Future<void> updateSettings(Settings value) async {
    settings = value;
    await store?.saveSettings(value);
    notifyListeners();
  }

  Future<void> updateDisplayName(String value) =>
      updateSettings(settings.copyWith(displayName: value));

  Future<void> clearHistory() async {
    await store?.clearHistory();
    historyPlans = <Plan>[];
    historyGrants = <Grant>[];
    historyAttempts = <Attempt>[];
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

  Future<bool> isDefaultHome() async {
    try {
      return await homePlatform.isDefaultHome();
    } on Object {
      return false;
    }
  }

  Future<bool> requestNotifications() async {
    try {
      return await notifications?.requestPermission() ?? true;
    } on Object {
      return false;
    }
  }

  Future<void> refresh() async {
    try {
      final found = await launcher.listApps();
      if (found.isNotEmpty) apps = found;
    } on Object {
      // Keep the last local snapshot.
    }
    final instant = now;
    if (store != null) {
      settings = store!.loadSettings();
      plans = await store!.loadTodayPlans(now: instant);
      grants = await store!.loadActiveGrants(now: instant);
      doorUses = await store!.loadTodayDoorUses(now: instant);
    } else {
      grants = activeGrants;
    }
    notifyListeners();
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
    notifyListeners();
  }

  String destinationFor(PlannedApp app, Plan plan) {
    if (app.query case final query?) return 'Search “${query.text}”';
    if (app.door case final door?) return door;
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
      notifyListeners();
    }
    return result;
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
    if (grant != null) await _saveGrant(grant, app.label);
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
    await _saveGrant(grant, app.label);
    await _logAttempt(
      app: app,
      reason: reason,
      response: response,
      overridden: true,
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

  Future<void> _saveGrant(Grant grant, String appLabel) async {
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
      grant,
    ];
    await store?.saveActiveGrants(grants, now: now);
    await store?.appendGrantHistory(grant, now: now);
    try {
      await notifications?.startGrant(grant: grant, appLabel: appLabel);
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
      ?_literalSpan(reason, response.guard?.quote.text),
    ];
    final attempt = Attempt(
      at: now,
      packageName: app.packageName,
      outcome: response.outcome,
      confidence: response.confidence,
      overridden: overridden,
      kind: response.kind,
      reason: reason,
      highlights: highlights,
    );
    historyAttempts = <Attempt>[...historyAttempts, attempt];
    await store?.appendAttempt(attempt, now: now);
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
    super.dispose();
  }
}

SourceSpan? _literalSpan(String source, String? literal) {
  if (literal == null || literal.isEmpty) return null;
  final utf16Start = source.indexOf(literal);
  if (utf16Start < 0) return null;
  final start = source.substring(0, utf16Start).runes.length;
  return SourceSpan(
    text: literal,
    start: start,
    end: start + literal.runes.length,
  );
}
