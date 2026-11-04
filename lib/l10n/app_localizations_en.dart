// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Curre';

  @override
  String get systemLanguage => 'Phone language';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageFrench => 'Français';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get continueLabel => 'Continue';

  @override
  String get tryAgain => 'Try again';

  @override
  String get done => 'Done';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get notNow => 'Not now';

  @override
  String get checking => 'Checking…';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get sessionMorning => 'morning';

  @override
  String get sessionAfternoon => 'afternoon';

  @override
  String get sessionEvening => 'evening';

  @override
  String goodSession(String session) {
    return 'Good $session';
  }

  @override
  String goodSessionName(String session, String name) {
    return 'Good $session, $name';
  }

  @override
  String planThisSession(String session) {
    return 'Plan this $session';
  }

  @override
  String planYourSession(String session) {
    return 'Plan your $session';
  }

  @override
  String whatsThisSessionFor(String session) {
    return 'What’s this $session for?';
  }

  @override
  String setMySession(String session) {
    return 'Set my $session';
  }

  @override
  String get phone => 'Phone';

  @override
  String get messages => 'Messages';

  @override
  String get androidSettings => 'Settings';

  @override
  String get curreSettings => 'Curre settings';

  @override
  String get allApps => 'All apps';

  @override
  String get allAppsDescription => 'Every app you didn’t hide, ready to open.';

  @override
  String get hiddenApps => 'Hidden apps';

  @override
  String hiddenAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hidden apps',
      one: '1 hidden app',
      zero: 'No hidden apps',
    );
    return '$_temp0';
  }

  @override
  String appsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return '$_temp0';
  }

  @override
  String minutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String secondsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get couldNotReadApps => 'Couldn’t read your apps';

  @override
  String get couldNotReadAppsBody =>
      'Curre couldn’t read the apps installed on this phone. Try again, and your real apps will appear here.';

  @override
  String get readingApps => 'Reading apps…';

  @override
  String get profileAvatar => 'Profile avatar';

  @override
  String get openProfile => 'Open profile';

  @override
  String get gettingReady => 'Getting things ready…';

  @override
  String get gettingReadyBody => 'This can take a few more seconds.';

  @override
  String get checkinHint => 'Say or type what you want to get done.';

  @override
  String get sayItInstead => 'Say it instead';

  @override
  String get planning => 'Building your plan…';

  @override
  String get planningSemantics => 'Choosing apps for your plan';

  @override
  String get chooseAppsYourself => 'Choose the apps yourself';

  @override
  String get chooseAppsBody =>
      'Curre couldn’t build this plan online. Pick the apps you need and keep going.';

  @override
  String get useThisPlan => 'Use this plan';

  @override
  String get planReady => 'Your plan is ready';

  @override
  String onHomeUntil(String time) {
    return 'On your Home until $time';
  }

  @override
  String get whyNow => 'Why now?';

  @override
  String whyNeedAppNow(String app) {
    return 'What do you need $app for right now?';
  }

  @override
  String get whyNowHelp =>
      'Say what you’ll do, who it’s for, and for how long. Curre opens the app right where you need it.';

  @override
  String get yourReason => 'Your reason';

  @override
  String get reasonHint => 'reply Ada about rehearsal';

  @override
  String yourPlan(String plan) {
    return 'Your plan: $plan';
  }

  @override
  String get oneMoreTry => 'One more try: say exactly what you’ll do.';

  @override
  String get bringItBack => 'Bring it back';

  @override
  String get askAgain => 'Ask again';

  @override
  String get readingReason => 'Reading your reason';

  @override
  String get readingReasonProgress => 'Reading your reason…';

  @override
  String guardQuote(String quote) {
    return 'These words read like an instruction to Curre: “$quote”';
  }

  @override
  String openAfter(String duration) {
    return 'Open after $duration';
  }

  @override
  String get saveForLater => 'Save for later';

  @override
  String appOpensIn(String app) {
    return '$app opens in';
  }

  @override
  String appOpensInDuration(String app, String duration) {
    return '$app opens in $duration';
  }

  @override
  String get waitUnavailableBody =>
      'Curre couldn’t check your reason, so it opens after a short wait instead.';

  @override
  String get waitAllowedBody => 'You chose to wait, and that’s allowed.';

  @override
  String get waitCancelHelp =>
      'Leave this screen to cancel. If you wait it out, it shows in your history.';

  @override
  String outcomeOpenApp(String app) {
    return 'Opens $app';
  }

  @override
  String outcomeOpenAt(String destination) {
    return 'Opens at $destination';
  }

  @override
  String get outcomeSpecify => 'What exactly will you do?';

  @override
  String get outcomeFlagged => 'That reads like an instruction, not a reason';

  @override
  String get outcomeUnavailable => 'Couldn’t check your reason';

  @override
  String youHaveMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return 'You have $_temp0.';
  }

  @override
  String chatWith(String person) {
    return 'Chat with $person';
  }

  @override
  String openDestination(String destination) {
    return 'Open $destination';
  }

  @override
  String get savedForNextPlan => 'Saved. It comes back when you next plan.';

  @override
  String get couldNotSave =>
      'Curre couldn’t save that on this phone. Please try again.';

  @override
  String get settingsSubtitle => 'Changes here only affect Curre.';

  @override
  String todayPercent(int percent) {
    return 'Today is $percent percent complete';
  }

  @override
  String get oneSentenceHome =>
      'One sentence. Only what you name shows on Home.';

  @override
  String get yourPlanLabel => 'Your plan';

  @override
  String get planHint => 'Learn the G chord on YouTube until 7';

  @override
  String get sayYourPlan => 'Say your plan';

  @override
  String get gettingAppsReady => 'Getting your apps ready…';

  @override
  String get choosingApps => 'Choosing apps';

  @override
  String lookingThroughApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return 'Looking through $_temp0';
  }

  @override
  String get useTheseApps => 'Use these apps';

  @override
  String get heresYourPlan => 'Here’s your plan';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get changePlan => 'Change the plan';

  @override
  String get fallbackConnect => 'Couldn’t connect just now';

  @override
  String get fallbackTimeout => 'That took too long';

  @override
  String get fallbackReadPlan => 'Curre couldn’t read that plan';

  @override
  String get fallbackPlan => 'Curre couldn’t plan that just now';

  @override
  String get fallbackNetworkBody =>
      'Check your internet and try again, or choose the apps yourself below.';

  @override
  String get fallbackBody =>
      'Try again in a moment, or choose the apps yourself below.';

  @override
  String openedHiddenApp(String app) {
    return 'You opened $app. It’s one of your hidden apps.';
  }

  @override
  String appIsHidden(String app) {
    return '$app is in your hidden apps.';
  }

  @override
  String openNoChatBody(String app, String minutes) {
    return 'Curre didn’t find a matching chat on this phone, so it opens $app. $minutes';
  }

  @override
  String laterBody(String duration, String app) {
    return 'That sounds like browsing, so it can wait. Save it for later and it comes back when you next plan, or wait $duration to open $app now.';
  }

  @override
  String specifyBody(String duration, String app) {
    return 'Say a bit more about what you’ll do, or wait $duration to open $app.';
  }

  @override
  String flaggedBody(String app, String duration) {
    return 'Tell Curre what you’ll do in $app instead. Or wait $duration to open it.';
  }

  @override
  String unavailableBody(String app, String duration) {
    return 'No problem: $app opens after you wait $duration. You can also try again now.';
  }

  @override
  String untilAppOpens(String duration, String app) {
    return '$duration until $app opens';
  }

  @override
  String get querySearch => 'Search';

  @override
  String get queryDraft => 'Draft';

  @override
  String get queryNewEvent => 'New event';

  @override
  String get queryOpenWith => 'Open app with';

  @override
  String get kindTask => 'A task';

  @override
  String get kindPerson => 'Someone’s waiting';

  @override
  String get kindTimeSensitive => 'Can’t wait';

  @override
  String get kindBrowse => 'Just browsing';

  @override
  String get kindUnclear => 'Not clear yet';

  @override
  String confidencePercent(String label, int percent) {
    return '$label, confidence $percent percent';
  }

  @override
  String get outcomeGlyphOpen => 'Opens';

  @override
  String get outcomeGlyphLater => 'Not now';

  @override
  String get outcomeGlyphSpecify => 'Needs more detail';

  @override
  String get outcomeGlyphFlagged => 'Not a reason';

  @override
  String get outcomeGlyphUnavailable => 'Couldn’t check';

  @override
  String get alwaysOnHome => 'Always on Home';

  @override
  String get pressHoldApp => 'Press and hold an app to open it the usual way.';

  @override
  String get quietNudgeQuestion => 'Want a quiet nudge when time’s up?';

  @override
  String get quietNudgeBody =>
      'Curre can let you know when your plan or an app’s time runs out. No sound, no buzz, never ads.';

  @override
  String get quietNudgeYes => 'Yes, nudge me';

  @override
  String get sayOneSentence =>
      'Say it in one sentence. Curre puts just the apps you need on Home.';

  @override
  String get planNow => 'Plan now';

  @override
  String tasksReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks ready',
      one: '1 task ready',
    );
    return '$_temp0';
  }

  @override
  String tasksDone(int done, int count) {
    return '$done of $count done';
  }

  @override
  String yourSession(String session) {
    return 'Your $session';
  }

  @override
  String untilTime(String time) {
    return 'until $time';
  }

  @override
  String get changeThisPlan => 'Change this plan';

  @override
  String get onHomeNow => 'On Home now';

  @override
  String get alwaysAppsBelow => 'Your always-there apps are below.';

  @override
  String get tapStraightThere => 'Tap one to go straight to it.';

  @override
  String get nothingPlanned => 'Nothing planned yet';

  @override
  String get nothingPlannedBody => 'Plan your day and its apps show up here.';

  @override
  String get alwaysAvailable => 'Always available';

  @override
  String get doneWithProof => 'Done, with proof';

  @override
  String get doneWaiting => 'Done · your note is waiting to be checked';

  @override
  String get doneAddNote => 'Done · tap to add a note';

  @override
  String get doneToday => 'Done today';

  @override
  String get show => 'Show';

  @override
  String get hide => 'Hide';

  @override
  String get todaySunUp => 'Today’s sun is up';

  @override
  String get todaySun => 'Today’s sun';

  @override
  String allDoneSession(String session) {
    return 'All done for this $session';
  }

  @override
  String get allDoneBody =>
      'Every task in this plan is done. You can end it now and plan again whenever you like.';

  @override
  String get endPlanNow => 'End plan now';

  @override
  String get endPlanQuestion => 'End this plan now?';

  @override
  String get endPlanBody =>
      'Its tasks leave Home. You can plan again whenever you like.';

  @override
  String get keepIt => 'Keep it';

  @override
  String get endPlan => 'End plan';

  @override
  String get planEnded => 'Plan ended.';

  @override
  String get undo => 'Undo';

  @override
  String get tapStart => 'Tap Start when you begin';

  @override
  String get start => 'Start';

  @override
  String startedAt(String time) {
    return 'Started $time · tap when you’re done';
  }

  @override
  String get awayFromPhone => 'Away from your phone';

  @override
  String get you => 'You';

  @override
  String get closeProfile => 'Close profile';

  @override
  String get yourFace => 'Your face';

  @override
  String get pickYourFace => 'Pick the one that feels like you.';

  @override
  String get useInitial => 'Use my initial instead';

  @override
  String get proofDays => 'Proof days';

  @override
  String get bestRun => 'Best run';

  @override
  String get cloudDays => 'Cloud days';

  @override
  String get history => 'History';

  @override
  String get yourName => 'Your name';

  @override
  String get saveName => 'Save name';

  @override
  String get editName => 'Edit name';

  @override
  String get app => 'App';

  @override
  String get quietNudgeOn =>
      'Quiet nudges are on. You can choose which ones in Curre settings.';

  @override
  String get quietNudgeOff =>
      'No problem. You can turn quiet nudges on later in Curre settings.';

  @override
  String planPercent(int percent) {
    return 'This plan is $percent percent complete';
  }

  @override
  String appsReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ready',
      one: '1 ready',
    );
    return '$_temp0';
  }

  @override
  String appBackForNow(String app) {
    return '$app is back for now';
  }

  @override
  String doneDoorSemantics(String app, String state, String destination) {
    return '$app, $state, opens $destination';
  }

  @override
  String tasksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String doneTodayShow(String count) {
    return 'Done today, $count. Show them';
  }

  @override
  String doneTodayCount(int count) {
    return 'Done today · $count';
  }

  @override
  String get endPlanFailed => 'Curre couldn’t end the plan. Please try again.';

  @override
  String get planTimeUp => 'That plan’s time is already up.';

  @override
  String get doorOpenFailed =>
      'That didn’t open. Press and hold the app to open it the usual way.';

  @override
  String copiedSearch(String target) {
    return 'Copied “$target”. Paste it into the search box.';
  }

  @override
  String get addProof => 'Add proof';

  @override
  String get snoozeTenMinutes => 'Snooze 10 min';

  @override
  String get focusDone => 'Your focus is done';

  @override
  String focusDoneNotification(String days) {
    return 'See how your $days went, and choose what comes next.';
  }

  @override
  String sessionAlmostDone(String session) {
    return 'Your $session is almost done';
  }

  @override
  String get planEndsTenMinutes =>
      'Your plan ends in 10 minutes. Choose what comes next.';

  @override
  String get addYourProof => 'Add your proof';

  @override
  String get proofNotificationBody =>
      'A short note about what you got done counts as proof.';

  @override
  String grantOngoingBody(String task) {
    return '$task · It hides again when the time is up.';
  }

  @override
  String appHiddenAgain(String app) {
    return '$app is hidden again';
  }

  @override
  String grantExpiredBody(int minutes, String reason) {
    return 'Your $minutes min for $reason are up.';
  }

  @override
  String get whatDidYouGetDone => 'What did you get done?';

  @override
  String get onboardingSaveFailed =>
      'Curre couldn’t save your answers on this phone. Please try again.';

  @override
  String get welcomeCurre => 'Welcome to Curre';

  @override
  String get aboutYou => 'About you';

  @override
  String get yourApps => 'Your apps';

  @override
  String get yourHomeScreen => 'Your home screen';

  @override
  String get yourFirstPlan => 'Your first plan';

  @override
  String get onboardingWelcomeQuestion =>
      'Ever pick up your phone for one thing and lose an hour?';

  @override
  String get whatShouldCurreCallYou => 'What should Curre call you?';

  @override
  String get whatPullsYouIn => 'What pulls you in?';

  @override
  String get makeCurreHomeHeadline => 'Make Curre your home screen.';

  @override
  String get withoutCurre => 'Without Curre';

  @override
  String get withoutCurreBody =>
      'One quick look. The feed pulls you in. An hour is gone.';

  @override
  String get withCurre => 'With Curre';

  @override
  String get withCurreBody =>
      'Say what you need. Curre opens the app right where you need it.';

  @override
  String get historyContactsStay =>
      'Your history and contacts stay on this phone.';

  @override
  String get howCurrePrivate => 'How Curre keeps things private';

  @override
  String get namePrivacyNote =>
      'Just for your greeting on Home. It stays on this phone.';

  @override
  String get addNameError => 'Add a name, even just a nickname.';

  @override
  String get pickFaceOrInitial =>
      'Pick a face, or keep your initial. You can change it any time.';

  @override
  String get whatsFocusFor => 'What’s this focus for?';

  @override
  String get focusOnboardingBody =>
      'Curre helps most for a while, with an end date. When it ends, your phone goes back to normal. Skip this if you’re not sure yet.';

  @override
  String get pickPullAppsBody =>
      'Pick the ones where a quick look turns into an hour. Curre hides only these: they leave your Home, and opening one asks “Why now?” first. Every other app opens as usual.';

  @override
  String showAllApps(int count) {
    return 'Show all $count apps';
  }

  @override
  String get changeHiddenAnyTime =>
      'Hide another app or bring one back any time from Hidden apps or Curre settings.';

  @override
  String get androidChooseCurre =>
      'Android will ask which app to use as your home screen. Choose Curre.';

  @override
  String get homePointPlan =>
      'Your Home shows your plan. Every app you didn’t hide is in All apps and opens as usual.';

  @override
  String get homePointHidden =>
      'Only the apps you picked are hidden. Opening one asks “Why now?” first.';

  @override
  String get homePointDoor => 'Tap an app on Home to go straight to your task.';

  @override
  String get curreIsHomeNow => 'Curre is your home screen now.';

  @override
  String get switchHomeAnyTime =>
      'Changed your mind? You can switch home screens any time in Curre settings.';

  @override
  String get curreNotHomeHelp =>
      'Curre isn’t your home screen yet. Try again, or open your phone’s home screen settings and choose Curre.';

  @override
  String get chooseCurreList =>
      'Choose Curre in the list, then come back here.';

  @override
  String get chooseCurreDefaultApps =>
      'Tap “Home app”, choose Curre, then come back here.';

  @override
  String get chooseCurreSettings =>
      'In Settings, search for “Home app” (or open Apps, then Default apps), choose Curre, then come back here.';

  @override
  String get chooseCurrePhoneSettings =>
      'Open your phone’s Settings app, search for “Home app”, choose Curre, then come back here.';

  @override
  String get planExampleGuitar => 'Learn the G chord on YouTube till 7';

  @override
  String get planExamplePlaylist =>
      'Play the Sunday worship playlist on Spotify';

  @override
  String get planExampleMaps => 'Find the way to the studio on Maps';

  @override
  String get onboardingPlanHelp =>
      'Say it in one sentence: the app, what you’ll do, and until when. Curre brings only that to your Home.';

  @override
  String get startFromExample => 'Or start from one of these:';

  @override
  String morningStartNote(String time) {
    return 'Curre asks what your morning is for from $time. Change that any time in Curre settings.';
  }

  @override
  String get showMeHow => 'Show me how';

  @override
  String callMe(String name) {
    return 'Call me $name';
  }

  @override
  String get pickAtLeastOne => 'Pick at least one';

  @override
  String get hideThisOne => 'Hide this one';

  @override
  String hideThese(int count) {
    return 'Hide these $count';
  }

  @override
  String get noneOfThese => 'None of these';

  @override
  String get makeCurreMyHome => 'Make Curre my home screen';

  @override
  String get openHomeSettings => 'Open home settings';

  @override
  String get planLater => 'I’ll plan later';

  @override
  String useExample(String text) {
    return 'Use example: $text';
  }

  @override
  String get findApp => 'Find an app';

  @override
  String noAppMatches(String query) {
    return 'No app matches “$query”.';
  }

  @override
  String get everyAppHidden => 'Every app on this phone is hidden.';

  @override
  String openApp(String app) {
    return 'Open $app';
  }

  @override
  String get hideThisApp => 'Hide this app';

  @override
  String hideApp(String app) {
    return 'Hide $app';
  }

  @override
  String appHiddenAsk(String app) {
    return '$app is hidden. Opening it asks “Why now?” first.';
  }

  @override
  String get planApps => 'Apps your plans can use';

  @override
  String get planAppsHelp =>
      'When you plan, Curre picks from these. Choose 2 to 30.';

  @override
  String get hiddenAppsHelp =>
      'Only these leave Home and ask “Why now?” first. Every other app opens as usual.';

  @override
  String get alwaysOnHomeHelp => 'These stay on Home all day, no plan needed.';

  @override
  String pickedCount(int count) {
    return '$count picked';
  }

  @override
  String hiddenCount(int count) {
    return '$count hidden';
  }

  @override
  String onHomeCount(int count) {
    return '$count on Home';
  }

  @override
  String planAppsMinimum(int count) {
    return 'Plans need at least $count apps to choose from.';
  }

  @override
  String planAppsMaximum(int count) {
    return 'That’s $count already. Untick one to add another.';
  }

  @override
  String appAlwaysOnHome(String app) {
    return '$app is always on Home.';
  }

  @override
  String get privacyDetails => 'Privacy details';

  @override
  String get privacySubtitle => 'What leaves this phone, and for how long.';

  @override
  String get privacyReadOnline => 'What is read online';

  @override
  String get privacyReadOnlineBody =>
      'Your plan, app names, the reason you give for opening a hidden app and a note you send after a task are read online so Curre can answer you.';

  @override
  String get privacyCopyTime => 'How long a copy may remain';

  @override
  String get privacyCopyTimeBody =>
      'Curre keeps no online copy. The AI service that reads your words may keep a successful answer, including quoted words, for about a day so a retry can return the same answer. It then deletes that copy.';

  @override
  String get privacyStaysHere => 'What stays here';

  @override
  String get privacyStaysHereBody =>
      'Your contacts, chat names, app use and history stay on this phone. You can clear plans, reasons and notes from Curre settings.';

  @override
  String get privacyHistoryHides => 'What History hides';

  @override
  String get privacyHistoryHidesBody =>
      'Before History saves a checked reason or note, Curre looks for names, phone numbers, email and address or payment details. What it finds becomes a label such as [name] or [phone]. If that check isn’t available, your words stay as they are.';

  @override
  String get privacyLogs =>
      'Curre records only whether a request worked and how long it took. It does not put your words in online logs.';

  @override
  String get savedForLaterTitle => 'Saved for later';

  @override
  String get laterNoneFits =>
      'Nothing you saved fits this plan, so it waits for a better time.';

  @override
  String get laterBestFirst => 'Best match for this plan first.';

  @override
  String get laterNewestFirst => 'Newest first.';

  @override
  String get laterOneMore => '1 more keeps for another time.';

  @override
  String laterMore(int count) {
    return '$count more keep for another time.';
  }

  @override
  String get notToday => 'Not today';

  @override
  String get sectionYourFocus => 'Your focus';

  @override
  String get sectionYourDay => 'Your day';

  @override
  String get dayStartsHelp =>
      'When each part of your day starts, Curre asks what it’s for.';

  @override
  String startsAt(String time) {
    return 'Starts at $time';
  }

  @override
  String get sectionYourApps => 'Your apps';

  @override
  String get defaultEssentials => 'Phone, Messages and Settings';

  @override
  String defaultEssentialsMore(int count) {
    return 'Phone, Messages, Settings and $count more';
  }

  @override
  String get strictQuestion => 'How strict should Curre be?';

  @override
  String get sectionHiddenApps => 'Hidden apps';

  @override
  String get askWhyHidden => 'Ask “Why now?” when a hidden app opens';

  @override
  String get needsAndroidOk => 'Needs your OK in Android first';

  @override
  String get pausedOtherHome => 'Paused while another home screen is in use';

  @override
  String get restingToday => 'Resting today. Back tomorrow morning.';

  @override
  String get askWhyOn => 'On, even from recent apps, notifications and links';

  @override
  String get keepHiddenQuiet => 'Keep hidden apps quiet';

  @override
  String get focusEndedNothingHeld =>
      'Your focus has ended, so nothing is held';

  @override
  String get heldUntilBack => 'On. Held until their app comes back.';

  @override
  String get turnOnUsageAccess => 'Turn on Usage access';

  @override
  String get turnOnNotificationAccess => 'Turn on notification access';

  @override
  String get sectionQuietNudges => 'Quiet nudges';

  @override
  String get allowNotifications => 'Allow notifications';

  @override
  String get notificationsAllowed =>
      'Allowed. The quiet nudges you choose can appear.';

  @override
  String get notificationsNotAllowed => 'Not allowed yet. Tap to allow.';

  @override
  String get notificationsAndroidControls =>
      'Android controls whether the quiet nudges you choose can appear';

  @override
  String get sectionVoiceTyping => 'Voice typing';

  @override
  String get sectionYourName => 'Your name';

  @override
  String get nameInGreeting => 'Name in your greeting';

  @override
  String get sectionHomeScreen => 'Your home screen';

  @override
  String get sectionHistoryPrivacy => 'History and privacy';

  @override
  String get historySettingsBody =>
      'Your plans and the apps you brought back, from the last 30 days. Only on this phone.';

  @override
  String get privacySettingsBody =>
      'What is read online, what stays here and when online copies are deleted';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get clearHistorySettingsBody =>
      'Delete past plans, reasons, notes and missed notifications from this phone';

  @override
  String get sectionAbout => 'About';

  @override
  String get licences => 'Licences';

  @override
  String get licencesBody =>
      'The fonts, icons, illustrations and voice typing Curre uses';

  @override
  String get appLegalese => 'Curre opens the task, not the app.';

  @override
  String sessionStartsAt(String session) {
    return 'Your $session starts at';
  }

  @override
  String get sessionOrderError =>
      'Mornings start before afternoons, and afternoons before evenings. Try a different time.';

  @override
  String sessionStartSaved(String session, String time) {
    return 'Your $session now starts at $time.';
  }

  @override
  String get nameSaved => 'Saved. Curre will greet you by this name.';

  @override
  String get usageAccessDone =>
      'Done. Curre will ask “Why now?” when a hidden app opens.';

  @override
  String get accessStillOff =>
      'It’s still off. You can turn it on here any time.';

  @override
  String get notificationAccessDone =>
      'Done. Hidden apps will stay quiet until you bring them back.';

  @override
  String get notificationsPermissionDone =>
      'Notifications are allowed. Curre will use the quiet nudge choices above.';

  @override
  String get notificationsPermissionOff =>
      'Notifications are not allowed. You can allow them for Curre in your phone’s Settings.';

  @override
  String get chooseHomeApp => 'Tap “Home app”, then choose the one you want.';

  @override
  String get searchHomeApp =>
      'Your phone opened Settings. Search for “Home app” (or open Apps, then Default apps), then choose the one you want.';

  @override
  String get openSettingsHomeApp =>
      'Open your phone’s Settings app and search for “Home app”. Choose the one you want there.';

  @override
  String get curreNotHomeSettings =>
      'Curre isn’t your home screen yet. Open your phone’s Settings, search for “Home app” and choose Curre.';

  @override
  String get clearHistoryQuestion => 'Clear your history?';

  @override
  String get clearHistoryBody =>
      'This deletes your past plans, the reasons you gave for bringing apps back, the notes you wrote after tasks and your missed notifications. Your proof days, today’s plan and any time already running stay as they are.';

  @override
  String get historyCleared => 'History cleared.';

  @override
  String get historyClearFailed =>
      'Curre couldn’t clear your history. Please try again.';

  @override
  String get switchHome => 'Switch to another home screen';

  @override
  String get curreNotHomeBody =>
      'Curre isn’t your home screen right now. Your plans and history are still here, ready when you want them.';

  @override
  String get switchHomeBody =>
      'Want a different home screen for a while? That’s okay. Android lets you choose which app opens when you press Home. Your plans and history stay on this phone, and you can switch back any time.';

  @override
  String get openHomeScreenSettings => 'Open home screen settings';

  @override
  String get chooseHomeScreenApp => 'Choose a home screen app';

  @override
  String get homeSettingsPath =>
      'If your phone opens its Settings instead, look for Apps, then Default apps, then Home app.';

  @override
  String get nudgesHelp =>
      'Choose which silent notes Curre sends. Turning one off also cancels any of that kind already waiting.';

  @override
  String get planYourDay => 'Plan your day';

  @override
  String get eachSessionBegins => 'When each part of your day begins';

  @override
  String get morningBegins => 'Once a day, when your morning begins';

  @override
  String get afternoonEveningToo => 'Afternoon and evening too';

  @override
  String get afternoonEveningBegins =>
      'Also when your afternoon and evening begin';

  @override
  String get planEnding => 'Plan ending';

  @override
  String get tenMinutesBeforePlan => 'Ten minutes before your plan ends';

  @override
  String get appTimeUp => 'App time up';

  @override
  String get hiddenAppTimeEnds => 'When time for a hidden app runs out';

  @override
  String get addProofLater => 'A few minutes after your plan ends';

  @override
  String get focusEnds => 'Focus ends';

  @override
  String get focusEndsMorning => 'On the morning your focus period ends';

  @override
  String get turnAllNudgesOff => 'Turn all quiet nudges off';

  @override
  String get turnAllNudgesOn => 'Turn all quiet nudges on';

  @override
  String get gentle => 'Gentle';

  @override
  String get balanced => 'Balanced';

  @override
  String get strict => 'Strict';

  @override
  String get strictnessBody =>
      'When you bring back a hidden app, Curre checks your reason. The stricter it is, the clearer your reason needs to be before the app opens.';

  @override
  String get hiddenChoiceNone => 'None. Every app opens as usual.';

  @override
  String get hiddenChoiceOne => '1 app. Only it asks “Why now?”.';

  @override
  String hiddenChoiceMany(int count) {
    return '$count apps. Only these ask “Why now?”.';
  }

  @override
  String get missedNotifications => 'Missed notifications';

  @override
  String missedFromHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications from hidden apps',
      one: '1 notification from hidden apps',
    );
    return '$_temp0';
  }

  @override
  String heldUntilAppBack(int count) {
    return '$count held until their app comes back';
  }

  @override
  String bringBackApp(String app) {
    return 'Bring back $app';
  }

  @override
  String get restDayTheyOpen => 'Rest day: they open without asking';

  @override
  String get nothingHidden =>
      'Nothing is hidden. Every app opens as usual from All apps.';

  @override
  String get hiddenAppsOut =>
      'Your hidden apps are out for your plan or for a while right now.';

  @override
  String get hideAnotherApp => 'Hide another app';

  @override
  String notificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications',
      one: '1 notification',
    );
    return '$_temp0';
  }

  @override
  String get hiddenAppsTip =>
      'Only the apps you chose to hide wait here. Tap one to bring it back for a while.';

  @override
  String get gotIt => 'Got it';

  @override
  String get appOpenFailed => 'That app didn’t open. It may not be installed.';

  @override
  String get missedNotificationsBody =>
      'Held quietly while their apps were hidden, and given back when the app comes back. Nothing leaves this phone.';

  @override
  String get nothingHeld => 'Nothing held right now.';

  @override
  String get held => 'Held';

  @override
  String get givenBack => 'Given back';

  @override
  String openNotificationApp(String app) {
    return 'Open $app';
  }

  @override
  String get openCurreAppInfo => 'Open Curre’s App info';

  @override
  String get openSettingsAppsCurre =>
      'Open your phone’s Settings, then Apps, then Curre.';

  @override
  String get restrictedStillOff =>
      'It’s still off. That’s okay, Curre works without it. If Android said the setting is restricted, allow it once:';

  @override
  String get restrictedHelp =>
      'If Android says the setting is restricted, allow it once:';

  @override
  String get restrictedStepOne => 'Open Curre’s App info.';

  @override
  String get restrictedStepTwo => 'Tap the three dots in the top right corner.';

  @override
  String get restrictedStepThree => 'Tap “Allow restricted settings”.';

  @override
  String get restrictedStepFour => 'Confirm with your PIN or fingerprint.';

  @override
  String get restrictedStepFive => 'Come back here and switch access on.';

  @override
  String get noProblemSettings =>
      'No problem. It’s in Curre settings any time.';

  @override
  String get allSet => 'All set.';

  @override
  String get usageAccessAllSet =>
      'Curre will ask “Why now?” when a hidden app opens.';

  @override
  String get notificationAccessAllSet =>
      'Hidden apps will stay quiet until you bring them back.';

  @override
  String get askWhyPrompt => 'Ask “Why now?” when a hidden app opens?';

  @override
  String get quietPrompt => 'Keep hidden apps quiet?';

  @override
  String get askWhyPromptBody =>
      'Hidden apps can sneak back in through recent apps, links or notifications. Curre can ask “Why now?” then too. It only checks which app opened, never what’s on your screen.';

  @override
  String get tryAgainAccess => 'Try again';

  @override
  String get hiddenNamesFallback => 'the apps you hide';

  @override
  String hiddenNamesTwo(String first, String second) {
    return '$first and $second';
  }

  @override
  String hiddenNamesMore(String first, String second, int count) {
    return '$first, $second and $count more';
  }

  @override
  String quietPromptBody(String apps) {
    return 'Curre can hold notifications from $apps quietly and give every one back when you open the app. Other apps notify as usual, and calls and alarms always come through.';
  }

  @override
  String get focusPurposeExams => 'Exams';

  @override
  String get focusPurposeDeadline => 'A deadline';

  @override
  String get focusPurposeHabit => 'Breaking a habit';

  @override
  String get focusPurposeOther => 'Something else';

  @override
  String get focusHintExams => 'Pass my maths finals';

  @override
  String get focusHintDeadline => 'Finish the portfolio';

  @override
  String get focusHintHabit => 'Stop opening social apps in bed';

  @override
  String get focusHintOther => 'What I want to change';

  @override
  String get focusEndExams => 'You made room for the work that mattered.';

  @override
  String get focusEndDeadline => 'You carried this work to its finish line.';

  @override
  String get focusEndHabit => 'You gave the new habit room to grow.';

  @override
  String get focusEndOther => 'You kept coming back to what mattered.';

  @override
  String get focusLengthWeek => '1 week';

  @override
  String get focusLengthTwoWeeks => '2 weeks';

  @override
  String get focusLengthThreeWeeks => '3 weeks';

  @override
  String get focusLengthThirtyDays => '30 days';

  @override
  String get focusGoalLabel => 'Your goal, in a few words (optional)';

  @override
  String get untilWhen => 'Until when?';

  @override
  String get pickDate => 'Pick a date';

  @override
  String focusEndsSummary(String date, String days) {
    return 'Ends $date, in $days. You can change it later.';
  }

  @override
  String get focusEndsOn => 'Focus ends on';

  @override
  String get focusSaveFailed =>
      'Curre couldn’t save your focus. Please try again.';

  @override
  String get focusQuestion => 'What’s this focus for?';

  @override
  String get focusPickerBody =>
      'Curre helps most for a stretch with an end: exams, a deadline, a habit you want to break.';

  @override
  String get pickFocusPurpose => 'Pick what it’s for';

  @override
  String get startMyFocus => 'Start my focus';

  @override
  String get setFocusQuestion => 'Set a focus?';

  @override
  String get focusOfferBody =>
      'Curre helps most for a stretch with an end: exams, a deadline, a habit to break. Pick one and when it ends.';

  @override
  String get maybeLater => 'Maybe later';

  @override
  String get setFocus => 'Set a focus';

  @override
  String get restDay => 'Rest day';

  @override
  String get yourFocus => 'Your focus';

  @override
  String get restDayBody =>
      'Hidden apps open without asking today, their notifications come through, and reminders stay quiet. Your proof days are safe. Back to focus tomorrow.';

  @override
  String focusLeft(String days, String date) {
    return '$days left · ends $date';
  }

  @override
  String get backToFocusNow => 'Back to focus now';

  @override
  String get takeTodayOff => 'Take today off';

  @override
  String nextRestDay(String date) {
    return 'Next rest day: $date';
  }

  @override
  String get today => 'today';

  @override
  String get tomorrow => 'tomorrow';

  @override
  String get takeTodayOffQuestion => 'Take today off?';

  @override
  String get takeTodayOffBody =>
      'Until tomorrow morning, hidden apps open without asking why, their notifications come through and Curre sends no reminders. Your proof days stay safe. You can take one rest day a week.';

  @override
  String get keepGoing => 'Keep going';

  @override
  String get enjoyRestDay => 'Enjoy your rest day. Back to focus tomorrow.';

  @override
  String focusSummaryDays(String days) {
    return '$days of focus.';
  }

  @override
  String focusSummaryWithRest(String days, String rests) {
    return '$days of focus, $rests.';
  }

  @override
  String restDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rest days',
      one: '1 rest day',
    );
    return '$_temp0';
  }

  @override
  String get daysWithProof => 'days with proof';

  @override
  String get tasksProved => 'tasks proved';

  @override
  String get hiddenAppsLeftClosed => 'hidden apps left closed';

  @override
  String get startAnotherFocus => 'Start another focus period';

  @override
  String get oldHomeScreen => 'Go back to my old home screen';

  @override
  String get focusHistoryStays =>
      'Your history and proof days stay on this phone either way.';

  @override
  String get chooseOldHome =>
      'Choose your old home screen in the list. Curre stops asking why and lets every notification through.';

  @override
  String get tapOldHome => 'Tap “Home app”, then choose your old home screen.';

  @override
  String get searchOldHome =>
      'Your phone opened Settings. Search for “Home app”, then choose your old home screen.';

  @override
  String get openSettingsOldHome =>
      'Open your phone’s Settings app and search for “Home app”. Choose your old home screen there.';

  @override
  String get noFocusSet => 'No focus set';

  @override
  String get focusSettingsEmpty =>
      'Pick what this stretch is for and when it ends.';

  @override
  String focusEndedOn(String date) {
    return 'Ended $date. See how it went on Home.';
  }

  @override
  String focusEndsLeft(String date, String days) {
    return 'Ends $date, $days left';
  }

  @override
  String get changeEndDate => 'Change end date';

  @override
  String weeklyRestNext(String date) {
    return 'One rest day a week. Next one: $date.';
  }

  @override
  String get endFocusNow => 'End focus now';

  @override
  String focusNowEnds(String date) {
    return 'Your focus now ends $date.';
  }

  @override
  String get endFocusQuestion => 'End your focus now?';

  @override
  String get endFocusBody =>
      'Home shows how it went, then you choose what’s next. Your history and proof days stay.';

  @override
  String get endFocus => 'End focus';

  @override
  String get historySubtitle => 'The last 30 days · only on this phone';

  @override
  String get whatHappened => 'What happened';

  @override
  String get historyEmptyTitle => 'A quiet start.';

  @override
  String get historyEmptyBody =>
      'Your plans, and the apps you bring back, will show up here. It all stays on this phone.';

  @override
  String plannedSessionsCount(int count) {
    return '$count of 21 planned';
  }

  @override
  String get historyOverviewHelp =>
      'Each square is a morning, afternoon or evening in the last 7 days. Filled ones started with a plan.';

  @override
  String sessionPlanState(String session, String state) {
    return '$session: $state';
  }

  @override
  String get planned => 'planned';

  @override
  String get noPlan => 'no plan';

  @override
  String proofCloudInHand(String detail) {
    return 'You have a cloud day. $detail';
  }

  @override
  String get oneMoreProofToCloud => '1 more proof day to your next cloud day.';

  @override
  String moreProofToCloud(int count) {
    return '$count more proof days to your next cloud day.';
  }

  @override
  String proofDaysInAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count proof days in all',
      one: '1 proof day in all',
    );
    return '$_temp0';
  }

  @override
  String bestRunCount(int count) {
    return 'Best run $count';
  }

  @override
  String cloudDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cloud days',
      one: '1 cloud day',
    );
    return '$_temp0';
  }

  @override
  String get historyProofHint =>
      'After a task, say what changed. A specific note adds a proof day.';

  @override
  String historySessionPlan(String session) {
    String _temp0 = intl.Intl.selectLogic(session, {
      'morning': 'Morning plan',
      'afternoon': 'Afternoon plan',
      'evening': 'Evening plan',
      'other': 'Plan',
    });
    return '$_temp0';
  }

  @override
  String endedEarlyAt(String ended, String planned) {
    return 'Ended early at $ended, planned until $planned';
  }

  @override
  String waitedDuration(String duration) {
    return 'Waited $duration';
  }

  @override
  String whyNowApp(String app) {
    return 'Why now? · $app';
  }

  @override
  String get olderReasonMissing => 'Reason wasn’t stored in this older entry.';

  @override
  String appCameBack(String app) {
    return '$app came back';
  }

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String openedAfterWaiting(String duration) {
    return 'Opened after waiting $duration';
  }

  @override
  String get openedFromLater => 'Saved for later, then opened from a plan';

  @override
  String get supportedProof => 'Supported proof';

  @override
  String get waitingToBeChecked => 'Waiting to be checked';

  @override
  String get markedDone => 'Marked done';

  @override
  String get noNote => 'No note';

  @override
  String get personalDetailHidden => 'Personal detail hidden';

  @override
  String get outcomeOpened => 'Opened';

  @override
  String get outcomeNotNow => 'Not now';

  @override
  String get outcomeNeededDetail => 'Needed more detail';

  @override
  String get outcomeNotReason => 'Not a reason';

  @override
  String get outcomeCouldNotCheck => 'Couldn’t check';

  @override
  String get nextSunriseOneProof => 'Next sunrise: one proof away';

  @override
  String get noProofDaysYet => 'No proof days yet';

  @override
  String proofDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count proof days',
      one: '1 proof day',
    );
    return '$_temp0';
  }

  @override
  String get todaysSunIsUp => 'today’s sun is up';

  @override
  String get oneCloudInHand => 'one cloud day in hand';

  @override
  String get cloudDay => 'Cloud day';

  @override
  String runEndedAt(String days) {
    return 'That run ended at $days.';
  }

  @override
  String get todaysProofStartsNext => 'Today’s proof starts the next sunrise.';

  @override
  String get theNextSunrise => 'The next sunrise';

  @override
  String get dayProof => 'proof day';

  @override
  String get dayPending => 'note waiting to be checked';

  @override
  String get dayNoProof => 'no proof';

  @override
  String get dayCloud => 'cloud day';

  @override
  String get dayToday => 'today';

  @override
  String get dayFuture => 'still to come';

  @override
  String get dayStillOpen => 'still open';

  @override
  String get startingToday => 'Starting today';

  @override
  String proofRunRange(String start, String end) {
    return '$start to $end';
  }

  @override
  String sinceDate(String date) {
    return 'Since $date';
  }

  @override
  String get milestoneSeven => 'Seven proof days: your rays now end in sparks.';

  @override
  String get milestoneTwentyOne =>
      '21 proof days: a ring of light now stands behind your sun.';

  @override
  String get milestoneFifty => '50 proof days: your sun wears a second ring.';

  @override
  String get cloudDayKeepsRun =>
      'If a day passes without proof, it keeps your run going.';

  @override
  String weekdaySunUp(String weekday) {
    return '$weekday’s sun is up';
  }

  @override
  String earnedCloudDay(String detail) {
    return 'You earned a cloud day. $detail';
  }

  @override
  String get completionQuestion => 'What changed, finished, or became clear?';

  @override
  String get oneSentenceEnough => 'One sentence is enough';

  @override
  String get addOneDetail => 'Add one detail';

  @override
  String get addWhatChanged => 'Add what changed';

  @override
  String proofMismatchPrompt(String detail) {
    return '“$detail” doesn’t match the task you planned. What changed, finished, or became clear?';
  }

  @override
  String get proofFuturePrompt =>
      'That sounds like what comes next. What changed, finished, or became clear?';

  @override
  String get proofUnrelatedPrompt =>
      'Say how it connects to your plan. What changed, finished, or became clear?';

  @override
  String get proofDetailPrompt =>
      'A name, a number or a step is enough. What changed, finished, or became clear?';

  @override
  String get justMarkDone => 'Just mark it done';

  @override
  String get readingYourNote => 'Reading your note';

  @override
  String get readingYourNoteProgress => 'Reading your note…';

  @override
  String get noteSaved => 'Your note is saved';

  @override
  String get noteSavedBody =>
      'Couldn’t check it right now. It will be checked once you’re back online.';

  @override
  String get runSafeWhileWaiting => 'Your run stays safe while it waits.';

  @override
  String get markedAsDone => 'Marked as done';

  @override
  String get markedDoneBody =>
      'It’s in your history. Proof days come from a note about what changed.';

  @override
  String get noteCountsAsProof => 'Your note counts as proof.';

  @override
  String get oneMoreRay => 'One more ray';

  @override
  String get proofAdded => 'Proof added';

  @override
  String get profileSmiling => 'Your profile, smiling';

  @override
  String get sunOneRay => 'Today’s sun, one ray: one task with proof';

  @override
  String sunManyRays(int count) {
    return 'Today’s sun, $count rays: $count tasks with proof';
  }

  @override
  String proofDayUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'proof days',
      one: 'proof day',
    );
    return '$_temp0';
  }

  @override
  String get newRunStarts => 'A new run starts here.';

  @override
  String get supported => 'Supported';

  @override
  String get backedByStart => 'Backed by starting the task and your note';

  @override
  String get backedByApp => 'Backed by the app you opened and your note';
}
