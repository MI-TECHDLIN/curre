import 'package:curre/app/curre_controller.dart';
import 'package:curre/core/core.dart';
import 'package:curre/doors/door_models.dart';

import '../../test/support/fakes.dart';
import '../../test/support/voice_fakes.dart';
import 'demo_server.dart';

/// The phone the film is shot on: Tobi, a student two weeks before exams.
///
/// Apps are the ordinary set a student has. Each app shows as Curre's own
/// letter tile, since the film draws no third-party logos.
abstract final class FilmPhone {
  static const keep = 'com.google.android.keep';
  static const youtube = 'com.google.android.youtube';
  static const instagram = 'com.instagram.android';
  static const tiktok = 'com.zhiliaoapp.musically';
  static const whatsapp = 'com.whatsapp';
  static const spotify = 'com.spotify.music';

  static const hidden = {instagram, tiktok};
  static const essentials = {
    'com.google.android.dialer',
    'com.google.android.apps.messaging',
    'com.android.settings',
  };

  static const apps = <LaunchableApp>[
    LaunchableApp(packageName: 'com.google.android.dialer', label: 'Phone'),
    LaunchableApp(
      packageName: 'com.google.android.apps.messaging',
      label: 'Messages',
    ),
    LaunchableApp(packageName: 'com.android.settings', label: 'Settings'),
    LaunchableApp(packageName: 'com.google.android.calendar', label: 'Calendar'),
    LaunchableApp(packageName: 'com.google.android.deskclock', label: 'Clock'),
    LaunchableApp(packageName: 'com.google.android.apps.docs', label: 'Drive'),
    LaunchableApp(packageName: 'com.google.android.gm', label: 'Gmail'),
    LaunchableApp(packageName: instagram, label: 'Instagram'),
    LaunchableApp(packageName: keep, label: 'Keep Notes'),
    LaunchableApp(packageName: 'com.google.android.apps.maps', label: 'Maps'),
    LaunchableApp(packageName: 'com.netflix.mediaclient', label: 'Netflix'),
    LaunchableApp(packageName: spotify, label: 'Spotify'),
    LaunchableApp(packageName: tiktok, label: 'TikTok'),
    LaunchableApp(packageName: whatsapp, label: 'WhatsApp'),
    LaunchableApp(packageName: youtube, label: 'YouTube'),
  ];

  static const staticShortcuts = <AppShortcut>[
    AppShortcut(packageName: keep, id: 'new-list', shortLabel: 'New list'),
    AppShortcut(packageName: keep, id: 'new-note', shortLabel: 'New note'),
    AppShortcut(packageName: keep, id: 'search', shortLabel: 'Search'),
  ];

  static const conversations = <AppShortcut>[
    AppShortcut(
      packageName: whatsapp,
      id: 'chat-study-group',
      shortLabel: 'Study group',
      isConversation: true,
    ),
    AppShortcut(
      packageName: instagram,
      id: 'chat-ada',
      shortLabel: 'Ada',
      isConversation: true,
      personNames: ['Ada'],
    ),
  ];
}

/// Tobi's settings once onboarding is done: Instagram and TikTok hidden,
/// a two-week exam focus, everything else open as usual.
Settings filmSettings({FocusPeriod? focus, String? avatarId}) => Settings(
  displayName: 'Tobi',
  avatarId: avatarId,
  essentials: const {
    'com.google.android.dialer',
    'com.google.android.apps.messaging',
    'com.android.settings',
  },
  candidates: {
    for (final app in FilmPhone.apps)
      if (!FilmPhone.hidden.contains(app.packageName) &&
          !FilmPhone.essentials.contains(app.packageName))
        app.packageName,
  },
  hiddenApps: FilmPhone.hidden,
  focus:
      focus ??
      FocusPeriod(
        purpose: FocusPurpose.exams,
        goal: 'Pass my finals',
        startsOn: const LocalDate(2026, 11, 2),
        endsOn: const LocalDate(2026, 11, 16),
      ),
);

/// One take's state: a controller over fakes, a clock the film moves, and
/// the demo server.
class FilmWorld {
  FilmWorld({
    required this.start,
    bool onboarded = true,
    Settings? settings,
    List<LaterItem> laterItems = const <LaterItem>[],
    List<LocalDate> restDays = const <LocalDate>[],
    List<ProofRecord> proofRecords = const <ProofRecord>[],
    List<Plan> plans = const <Plan>[],
    List<Plan> historyPlans = const <Plan>[],
    List<Attempt> historyAttempts = const <Attempt>[],
    Set<ContextPrompt> pendingPrompts = const <ContextPrompt>{},
    bool isHome = true,
  }) : now = start {
    home = FakeHomePlatform(isHome: isHome);
    platform = FakeDoorPlatform(
      apps: FilmPhone.apps,
      staticShortcuts: FilmPhone.staticShortcuts,
      conversationShortcuts: FilmPhone.conversations,
      home: home,
    );
    access = FakeGentleIntercept(usage: true, notifications: true);
    controller = CurreController(
      launcher: platform,
      homePlatform: home,
      homeSettings: homeSettings,
      gentleIntercept: access,
      api: CurreApiClient(
        baseUrl: Uri.parse('https://curre.film'),
        appKey: 'film',
        httpClient: server.client,
      ),
      speech: fakeSpeech(),
      settings: settings ?? (onboarded ? filmSettings() : Settings()),
      apps: FilmPhone.apps,
      plans: plans,
      historyPlans: historyPlans,
      historyAttempts: historyAttempts,
      laterItems: laterItems,
      restDays: restDays,
      proofRecords: proofRecords,
      onboardingComplete: onboarded,
      hiddenAppsTipDismissed: onboarded,
      focusOfferDismissed: onboarded,
      pendingPrompts: pendingPrompts,
      now: () => now,
    );
  }

  /// Where the take's clock starts; [now] moves on with the film.
  final DateTime start;
  DateTime now;
  final server = DemoServer();
  final homeSettings = FakeHomeSettings();
  late final FakeHomePlatform home;
  late final FakeDoorPlatform platform;
  late final FakeGentleIntercept access;
  late final CurreController controller;
}
