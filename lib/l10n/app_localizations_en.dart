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
  String get languageSpanish => 'Spanish';

  @override
  String get languageFrench => 'French';

  @override
  String get languagePortuguese => 'Portuguese';

  @override
  String get languageGerman => 'German';

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
}
