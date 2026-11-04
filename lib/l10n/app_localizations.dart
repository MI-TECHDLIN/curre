import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Curre'**
  String get appName;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get systemLanguage;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @sessionMorning.
  ///
  /// In en, this message translates to:
  /// **'morning'**
  String get sessionMorning;

  /// No description provided for @sessionAfternoon.
  ///
  /// In en, this message translates to:
  /// **'afternoon'**
  String get sessionAfternoon;

  /// No description provided for @sessionEvening.
  ///
  /// In en, this message translates to:
  /// **'evening'**
  String get sessionEvening;

  /// No description provided for @goodSession.
  ///
  /// In en, this message translates to:
  /// **'Good {session}'**
  String goodSession(String session);

  /// No description provided for @goodSessionName.
  ///
  /// In en, this message translates to:
  /// **'Good {session}, {name}'**
  String goodSessionName(String session, String name);

  /// No description provided for @planThisSession.
  ///
  /// In en, this message translates to:
  /// **'Plan this {session}'**
  String planThisSession(String session);

  /// No description provided for @planYourSession.
  ///
  /// In en, this message translates to:
  /// **'Plan your {session}'**
  String planYourSession(String session);

  /// No description provided for @whatsThisSessionFor.
  ///
  /// In en, this message translates to:
  /// **'What’s this {session} for?'**
  String whatsThisSessionFor(String session);

  /// No description provided for @setMySession.
  ///
  /// In en, this message translates to:
  /// **'Set my {session}'**
  String setMySession(String session);

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @androidSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get androidSettings;

  /// No description provided for @curreSettings.
  ///
  /// In en, this message translates to:
  /// **'Curre settings'**
  String get curreSettings;

  /// No description provided for @allApps.
  ///
  /// In en, this message translates to:
  /// **'All apps'**
  String get allApps;

  /// No description provided for @allAppsDescription.
  ///
  /// In en, this message translates to:
  /// **'Every app you didn’t hide, ready to open.'**
  String get allAppsDescription;

  /// No description provided for @hiddenApps.
  ///
  /// In en, this message translates to:
  /// **'Hidden apps'**
  String get hiddenApps;

  /// No description provided for @hiddenAppsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No hidden apps} =1{1 hidden app} other{{count} hidden apps}}'**
  String hiddenAppsCount(int count);

  /// No description provided for @appsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 app} other{{count} apps}}'**
  String appsCount(int count);

  /// No description provided for @minutesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String minutesCount(int count);

  /// No description provided for @secondsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 second} other{{count} seconds}}'**
  String secondsCount(int count);

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// No description provided for @couldNotReadApps.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read your apps'**
  String get couldNotReadApps;

  /// No description provided for @couldNotReadAppsBody.
  ///
  /// In en, this message translates to:
  /// **'Curre couldn’t read the apps installed on this phone. Try again, and your real apps will appear here.'**
  String get couldNotReadAppsBody;

  /// No description provided for @readingApps.
  ///
  /// In en, this message translates to:
  /// **'Reading apps…'**
  String get readingApps;

  /// No description provided for @profileAvatar.
  ///
  /// In en, this message translates to:
  /// **'Profile avatar'**
  String get profileAvatar;

  /// No description provided for @openProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get openProfile;

  /// No description provided for @gettingReady.
  ///
  /// In en, this message translates to:
  /// **'Getting things ready…'**
  String get gettingReady;

  /// No description provided for @gettingReadyBody.
  ///
  /// In en, this message translates to:
  /// **'This can take a few more seconds.'**
  String get gettingReadyBody;

  /// No description provided for @checkinHint.
  ///
  /// In en, this message translates to:
  /// **'Say or type what you want to get done.'**
  String get checkinHint;

  /// No description provided for @sayItInstead.
  ///
  /// In en, this message translates to:
  /// **'Say it instead'**
  String get sayItInstead;

  /// No description provided for @planning.
  ///
  /// In en, this message translates to:
  /// **'Building your plan…'**
  String get planning;

  /// No description provided for @planningSemantics.
  ///
  /// In en, this message translates to:
  /// **'Choosing apps for your plan'**
  String get planningSemantics;

  /// No description provided for @chooseAppsYourself.
  ///
  /// In en, this message translates to:
  /// **'Choose the apps yourself'**
  String get chooseAppsYourself;

  /// No description provided for @chooseAppsBody.
  ///
  /// In en, this message translates to:
  /// **'Curre couldn’t build this plan online. Pick the apps you need and keep going.'**
  String get chooseAppsBody;

  /// No description provided for @useThisPlan.
  ///
  /// In en, this message translates to:
  /// **'Use this plan'**
  String get useThisPlan;

  /// No description provided for @planReady.
  ///
  /// In en, this message translates to:
  /// **'Your plan is ready'**
  String get planReady;

  /// No description provided for @onHomeUntil.
  ///
  /// In en, this message translates to:
  /// **'On your Home until {time}'**
  String onHomeUntil(String time);

  /// No description provided for @whyNow.
  ///
  /// In en, this message translates to:
  /// **'Why now?'**
  String get whyNow;

  /// No description provided for @whyNeedAppNow.
  ///
  /// In en, this message translates to:
  /// **'What do you need {app} for right now?'**
  String whyNeedAppNow(String app);

  /// No description provided for @whyNowHelp.
  ///
  /// In en, this message translates to:
  /// **'Say what you’ll do, who it’s for, and for how long. Curre opens the app right where you need it.'**
  String get whyNowHelp;

  /// No description provided for @yourReason.
  ///
  /// In en, this message translates to:
  /// **'Your reason'**
  String get yourReason;

  /// No description provided for @reasonHint.
  ///
  /// In en, this message translates to:
  /// **'reply Ada about rehearsal'**
  String get reasonHint;

  /// No description provided for @yourPlan.
  ///
  /// In en, this message translates to:
  /// **'Your plan: {plan}'**
  String yourPlan(String plan);

  /// No description provided for @oneMoreTry.
  ///
  /// In en, this message translates to:
  /// **'One more try: say exactly what you’ll do.'**
  String get oneMoreTry;

  /// No description provided for @bringItBack.
  ///
  /// In en, this message translates to:
  /// **'Bring it back'**
  String get bringItBack;

  /// No description provided for @askAgain.
  ///
  /// In en, this message translates to:
  /// **'Ask again'**
  String get askAgain;

  /// No description provided for @readingReason.
  ///
  /// In en, this message translates to:
  /// **'Reading your reason'**
  String get readingReason;

  /// No description provided for @readingReasonProgress.
  ///
  /// In en, this message translates to:
  /// **'Reading your reason…'**
  String get readingReasonProgress;

  /// No description provided for @guardQuote.
  ///
  /// In en, this message translates to:
  /// **'These words read like an instruction to Curre: “{quote}”'**
  String guardQuote(String quote);

  /// No description provided for @openAfter.
  ///
  /// In en, this message translates to:
  /// **'Open after {duration}'**
  String openAfter(String duration);

  /// No description provided for @saveForLater.
  ///
  /// In en, this message translates to:
  /// **'Save for later'**
  String get saveForLater;

  /// No description provided for @appOpensIn.
  ///
  /// In en, this message translates to:
  /// **'{app} opens in'**
  String appOpensIn(String app);

  /// No description provided for @appOpensInDuration.
  ///
  /// In en, this message translates to:
  /// **'{app} opens in {duration}'**
  String appOpensInDuration(String app, String duration);

  /// No description provided for @waitUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Curre couldn’t check your reason, so it opens after a short wait instead.'**
  String get waitUnavailableBody;

  /// No description provided for @waitAllowedBody.
  ///
  /// In en, this message translates to:
  /// **'You chose to wait, and that’s allowed.'**
  String get waitAllowedBody;

  /// No description provided for @waitCancelHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave this screen to cancel. If you wait it out, it shows in your history.'**
  String get waitCancelHelp;

  /// No description provided for @outcomeOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Opens {app}'**
  String outcomeOpenApp(String app);

  /// No description provided for @outcomeOpenAt.
  ///
  /// In en, this message translates to:
  /// **'Opens at {destination}'**
  String outcomeOpenAt(String destination);

  /// No description provided for @outcomeSpecify.
  ///
  /// In en, this message translates to:
  /// **'What exactly will you do?'**
  String get outcomeSpecify;

  /// No description provided for @outcomeFlagged.
  ///
  /// In en, this message translates to:
  /// **'That reads like an instruction, not a reason'**
  String get outcomeFlagged;

  /// No description provided for @outcomeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t check your reason'**
  String get outcomeUnavailable;

  /// No description provided for @youHaveMinutes.
  ///
  /// In en, this message translates to:
  /// **'You have {count, plural, =1{1 minute} other{{count} minutes}}.'**
  String youHaveMinutes(int count);

  /// No description provided for @chatWith.
  ///
  /// In en, this message translates to:
  /// **'Chat with {person}'**
  String chatWith(String person);

  /// No description provided for @openDestination.
  ///
  /// In en, this message translates to:
  /// **'Open {destination}'**
  String openDestination(String destination);

  /// No description provided for @savedForNextPlan.
  ///
  /// In en, this message translates to:
  /// **'Saved. It comes back when you next plan.'**
  String get savedForNextPlan;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Curre couldn’t save that on this phone. Please try again.'**
  String get couldNotSave;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Changes here only affect Curre.'**
  String get settingsSubtitle;

  /// No description provided for @todayPercent.
  ///
  /// In en, this message translates to:
  /// **'Today is {percent} percent complete'**
  String todayPercent(int percent);

  /// No description provided for @oneSentenceHome.
  ///
  /// In en, this message translates to:
  /// **'One sentence. Only what you name shows on Home.'**
  String get oneSentenceHome;

  /// No description provided for @yourPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get yourPlanLabel;

  /// No description provided for @planHint.
  ///
  /// In en, this message translates to:
  /// **'Learn the G chord on YouTube until 7'**
  String get planHint;

  /// No description provided for @sayYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Say your plan'**
  String get sayYourPlan;

  /// No description provided for @gettingAppsReady.
  ///
  /// In en, this message translates to:
  /// **'Getting your apps ready…'**
  String get gettingAppsReady;

  /// No description provided for @choosingApps.
  ///
  /// In en, this message translates to:
  /// **'Choosing apps'**
  String get choosingApps;

  /// No description provided for @lookingThroughApps.
  ///
  /// In en, this message translates to:
  /// **'Looking through {count, plural, =1{1 app} other{{count} apps}}'**
  String lookingThroughApps(int count);

  /// No description provided for @useTheseApps.
  ///
  /// In en, this message translates to:
  /// **'Use these apps'**
  String get useTheseApps;

  /// No description provided for @heresYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Here’s your plan'**
  String get heresYourPlan;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @changePlan.
  ///
  /// In en, this message translates to:
  /// **'Change the plan'**
  String get changePlan;

  /// No description provided for @fallbackConnect.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t connect just now'**
  String get fallbackConnect;

  /// No description provided for @fallbackTimeout.
  ///
  /// In en, this message translates to:
  /// **'That took too long'**
  String get fallbackTimeout;

  /// No description provided for @fallbackReadPlan.
  ///
  /// In en, this message translates to:
  /// **'Curre couldn’t read that plan'**
  String get fallbackReadPlan;

  /// No description provided for @fallbackPlan.
  ///
  /// In en, this message translates to:
  /// **'Curre couldn’t plan that just now'**
  String get fallbackPlan;

  /// No description provided for @fallbackNetworkBody.
  ///
  /// In en, this message translates to:
  /// **'Check your internet and try again, or choose the apps yourself below.'**
  String get fallbackNetworkBody;

  /// No description provided for @fallbackBody.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment, or choose the apps yourself below.'**
  String get fallbackBody;

  /// No description provided for @openedHiddenApp.
  ///
  /// In en, this message translates to:
  /// **'You opened {app}. It’s one of your hidden apps.'**
  String openedHiddenApp(String app);

  /// No description provided for @appIsHidden.
  ///
  /// In en, this message translates to:
  /// **'{app} is in your hidden apps.'**
  String appIsHidden(String app);

  /// No description provided for @openNoChatBody.
  ///
  /// In en, this message translates to:
  /// **'Curre didn’t find a matching chat on this phone, so it opens {app}. {minutes}'**
  String openNoChatBody(String app, String minutes);

  /// No description provided for @laterBody.
  ///
  /// In en, this message translates to:
  /// **'That sounds like browsing, so it can wait. Save it for later and it comes back when you next plan, or wait {duration} to open {app} now.'**
  String laterBody(String duration, String app);

  /// No description provided for @specifyBody.
  ///
  /// In en, this message translates to:
  /// **'Say a bit more about what you’ll do, or wait {duration} to open {app}.'**
  String specifyBody(String duration, String app);

  /// No description provided for @flaggedBody.
  ///
  /// In en, this message translates to:
  /// **'Tell Curre what you’ll do in {app} instead. Or wait {duration} to open it.'**
  String flaggedBody(String app, String duration);

  /// No description provided for @unavailableBody.
  ///
  /// In en, this message translates to:
  /// **'No problem: {app} opens after you wait {duration}. You can also try again now.'**
  String unavailableBody(String app, String duration);

  /// No description provided for @untilAppOpens.
  ///
  /// In en, this message translates to:
  /// **'{duration} until {app} opens'**
  String untilAppOpens(String duration, String app);

  /// No description provided for @querySearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get querySearch;

  /// No description provided for @queryDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get queryDraft;

  /// No description provided for @queryNewEvent.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get queryNewEvent;

  /// No description provided for @queryOpenWith.
  ///
  /// In en, this message translates to:
  /// **'Open app with'**
  String get queryOpenWith;

  /// No description provided for @kindTask.
  ///
  /// In en, this message translates to:
  /// **'A task'**
  String get kindTask;

  /// No description provided for @kindPerson.
  ///
  /// In en, this message translates to:
  /// **'Someone’s waiting'**
  String get kindPerson;

  /// No description provided for @kindTimeSensitive.
  ///
  /// In en, this message translates to:
  /// **'Can’t wait'**
  String get kindTimeSensitive;

  /// No description provided for @kindBrowse.
  ///
  /// In en, this message translates to:
  /// **'Just browsing'**
  String get kindBrowse;

  /// No description provided for @kindUnclear.
  ///
  /// In en, this message translates to:
  /// **'Not clear yet'**
  String get kindUnclear;

  /// No description provided for @confidencePercent.
  ///
  /// In en, this message translates to:
  /// **'{label}, confidence {percent} percent'**
  String confidencePercent(String label, int percent);

  /// No description provided for @outcomeGlyphOpen.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get outcomeGlyphOpen;

  /// No description provided for @outcomeGlyphLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get outcomeGlyphLater;

  /// No description provided for @outcomeGlyphSpecify.
  ///
  /// In en, this message translates to:
  /// **'Needs more detail'**
  String get outcomeGlyphSpecify;

  /// No description provided for @outcomeGlyphFlagged.
  ///
  /// In en, this message translates to:
  /// **'Not a reason'**
  String get outcomeGlyphFlagged;

  /// No description provided for @outcomeGlyphUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t check'**
  String get outcomeGlyphUnavailable;

  /// No description provided for @alwaysOnHome.
  ///
  /// In en, this message translates to:
  /// **'Always on Home'**
  String get alwaysOnHome;

  /// No description provided for @pressHoldApp.
  ///
  /// In en, this message translates to:
  /// **'Press and hold an app to open it the usual way.'**
  String get pressHoldApp;

  /// No description provided for @quietNudgeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Want a quiet nudge when time’s up?'**
  String get quietNudgeQuestion;

  /// No description provided for @quietNudgeBody.
  ///
  /// In en, this message translates to:
  /// **'Curre can let you know when your plan or an app’s time runs out. No sound, no buzz, never ads.'**
  String get quietNudgeBody;

  /// No description provided for @quietNudgeYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, nudge me'**
  String get quietNudgeYes;

  /// No description provided for @sayOneSentence.
  ///
  /// In en, this message translates to:
  /// **'Say it in one sentence. Curre puts just the apps you need on Home.'**
  String get sayOneSentence;

  /// No description provided for @planNow.
  ///
  /// In en, this message translates to:
  /// **'Plan now'**
  String get planNow;

  /// No description provided for @tasksReady.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task ready} other{{count} tasks ready}}'**
  String tasksReady(int count);

  /// No description provided for @tasksDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {count} done'**
  String tasksDone(int done, int count);

  /// No description provided for @yourSession.
  ///
  /// In en, this message translates to:
  /// **'Your {session}'**
  String yourSession(String session);

  /// No description provided for @untilTime.
  ///
  /// In en, this message translates to:
  /// **'until {time}'**
  String untilTime(String time);

  /// No description provided for @changeThisPlan.
  ///
  /// In en, this message translates to:
  /// **'Change this plan'**
  String get changeThisPlan;

  /// No description provided for @onHomeNow.
  ///
  /// In en, this message translates to:
  /// **'On Home now'**
  String get onHomeNow;

  /// No description provided for @alwaysAppsBelow.
  ///
  /// In en, this message translates to:
  /// **'Your always-there apps are below.'**
  String get alwaysAppsBelow;

  /// No description provided for @tapStraightThere.
  ///
  /// In en, this message translates to:
  /// **'Tap one to go straight to it.'**
  String get tapStraightThere;

  /// No description provided for @nothingPlanned.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned yet'**
  String get nothingPlanned;

  /// No description provided for @nothingPlannedBody.
  ///
  /// In en, this message translates to:
  /// **'Plan your day and its apps show up here.'**
  String get nothingPlannedBody;

  /// No description provided for @alwaysAvailable.
  ///
  /// In en, this message translates to:
  /// **'Always available'**
  String get alwaysAvailable;

  /// No description provided for @doneWithProof.
  ///
  /// In en, this message translates to:
  /// **'Done, with proof'**
  String get doneWithProof;

  /// No description provided for @doneWaiting.
  ///
  /// In en, this message translates to:
  /// **'Done · your note is waiting to be checked'**
  String get doneWaiting;

  /// No description provided for @doneAddNote.
  ///
  /// In en, this message translates to:
  /// **'Done · tap to add a note'**
  String get doneAddNote;

  /// No description provided for @doneToday.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get doneToday;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @todaySunUp.
  ///
  /// In en, this message translates to:
  /// **'Today’s sun is up'**
  String get todaySunUp;

  /// No description provided for @todaySun.
  ///
  /// In en, this message translates to:
  /// **'Today’s sun'**
  String get todaySun;

  /// No description provided for @allDoneSession.
  ///
  /// In en, this message translates to:
  /// **'All done for this {session}'**
  String allDoneSession(String session);

  /// No description provided for @allDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Every task in this plan is done. You can end it now and plan again whenever you like.'**
  String get allDoneBody;

  /// No description provided for @endPlanNow.
  ///
  /// In en, this message translates to:
  /// **'End plan now'**
  String get endPlanNow;

  /// No description provided for @endPlanQuestion.
  ///
  /// In en, this message translates to:
  /// **'End this plan now?'**
  String get endPlanQuestion;

  /// No description provided for @endPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Its tasks leave Home. You can plan again whenever you like.'**
  String get endPlanBody;

  /// No description provided for @keepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keepIt;

  /// No description provided for @endPlan.
  ///
  /// In en, this message translates to:
  /// **'End plan'**
  String get endPlan;

  /// No description provided for @planEnded.
  ///
  /// In en, this message translates to:
  /// **'Plan ended.'**
  String get planEnded;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @tapStart.
  ///
  /// In en, this message translates to:
  /// **'Tap Start when you begin'**
  String get tapStart;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @startedAt.
  ///
  /// In en, this message translates to:
  /// **'Started {time} · tap when you’re done'**
  String startedAt(String time);

  /// No description provided for @awayFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Away from your phone'**
  String get awayFromPhone;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @closeProfile.
  ///
  /// In en, this message translates to:
  /// **'Close profile'**
  String get closeProfile;

  /// No description provided for @yourFace.
  ///
  /// In en, this message translates to:
  /// **'Your face'**
  String get yourFace;

  /// No description provided for @pickYourFace.
  ///
  /// In en, this message translates to:
  /// **'Pick the one that feels like you.'**
  String get pickYourFace;

  /// No description provided for @useInitial.
  ///
  /// In en, this message translates to:
  /// **'Use my initial instead'**
  String get useInitial;

  /// No description provided for @proofDays.
  ///
  /// In en, this message translates to:
  /// **'Proof days'**
  String get proofDays;

  /// No description provided for @bestRun.
  ///
  /// In en, this message translates to:
  /// **'Best run'**
  String get bestRun;

  /// No description provided for @cloudDays.
  ///
  /// In en, this message translates to:
  /// **'Cloud days'**
  String get cloudDays;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @saveName.
  ///
  /// In en, this message translates to:
  /// **'Save name'**
  String get saveName;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editName;

  /// No description provided for @app.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get app;

  /// No description provided for @quietNudgeOn.
  ///
  /// In en, this message translates to:
  /// **'Quiet nudges are on. You can choose which ones in Curre settings.'**
  String get quietNudgeOn;

  /// No description provided for @quietNudgeOff.
  ///
  /// In en, this message translates to:
  /// **'No problem. You can turn quiet nudges on later in Curre settings.'**
  String get quietNudgeOff;

  /// No description provided for @planPercent.
  ///
  /// In en, this message translates to:
  /// **'This plan is {percent} percent complete'**
  String planPercent(int percent);

  /// No description provided for @appsReady.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ready} other{{count} ready}}'**
  String appsReady(int count);

  /// No description provided for @appBackForNow.
  ///
  /// In en, this message translates to:
  /// **'{app} is back for now'**
  String appBackForNow(String app);

  /// No description provided for @doneDoorSemantics.
  ///
  /// In en, this message translates to:
  /// **'{app}, {state}, opens {destination}'**
  String doneDoorSemantics(String app, String state, String destination);

  /// No description provided for @tasksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task} other{{count} tasks}}'**
  String tasksCount(int count);

  /// No description provided for @doneTodayShow.
  ///
  /// In en, this message translates to:
  /// **'Done today, {count}. Show them'**
  String doneTodayShow(String count);

  /// No description provided for @doneTodayCount.
  ///
  /// In en, this message translates to:
  /// **'Done today · {count}'**
  String doneTodayCount(int count);

  /// No description provided for @endPlanFailed.
  ///
  /// In en, this message translates to:
  /// **'Curre couldn’t end the plan. Please try again.'**
  String get endPlanFailed;

  /// No description provided for @planTimeUp.
  ///
  /// In en, this message translates to:
  /// **'That plan’s time is already up.'**
  String get planTimeUp;

  /// No description provided for @doorOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn’t open. Press and hold the app to open it the usual way.'**
  String get doorOpenFailed;

  /// No description provided for @copiedSearch.
  ///
  /// In en, this message translates to:
  /// **'Copied “{target}”. Paste it into the search box.'**
  String copiedSearch(String target);

  /// No description provided for @addProof.
  ///
  /// In en, this message translates to:
  /// **'Add proof'**
  String get addProof;

  /// No description provided for @snoozeTenMinutes.
  ///
  /// In en, this message translates to:
  /// **'Snooze 10 min'**
  String get snoozeTenMinutes;

  /// No description provided for @focusDone.
  ///
  /// In en, this message translates to:
  /// **'Your focus is done'**
  String get focusDone;

  /// No description provided for @focusDoneNotification.
  ///
  /// In en, this message translates to:
  /// **'See how your {days} went, and choose what comes next.'**
  String focusDoneNotification(String days);

  /// No description provided for @sessionAlmostDone.
  ///
  /// In en, this message translates to:
  /// **'Your {session} is almost done'**
  String sessionAlmostDone(String session);

  /// No description provided for @planEndsTenMinutes.
  ///
  /// In en, this message translates to:
  /// **'Your plan ends in 10 minutes. Choose what comes next.'**
  String get planEndsTenMinutes;

  /// No description provided for @addYourProof.
  ///
  /// In en, this message translates to:
  /// **'Add your proof'**
  String get addYourProof;

  /// No description provided for @proofNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'A short note about what you got done counts as proof.'**
  String get proofNotificationBody;

  /// No description provided for @grantOngoingBody.
  ///
  /// In en, this message translates to:
  /// **'{task} · It hides again when the time is up.'**
  String grantOngoingBody(String task);

  /// No description provided for @appHiddenAgain.
  ///
  /// In en, this message translates to:
  /// **'{app} is hidden again'**
  String appHiddenAgain(String app);

  /// No description provided for @grantExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Your {minutes} min for {reason} are up.'**
  String grantExpiredBody(int minutes, String reason);

  /// No description provided for @whatDidYouGetDone.
  ///
  /// In en, this message translates to:
  /// **'What did you get done?'**
  String get whatDidYouGetDone;

  /// No description provided for @onboardingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Curre couldn’t save your answers on this phone. Please try again.'**
  String get onboardingSaveFailed;

  /// No description provided for @welcomeCurre.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Curre'**
  String get welcomeCurre;

  /// No description provided for @aboutYou.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get aboutYou;

  /// No description provided for @yourApps.
  ///
  /// In en, this message translates to:
  /// **'Your apps'**
  String get yourApps;

  /// No description provided for @yourHomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Your home screen'**
  String get yourHomeScreen;

  /// No description provided for @yourFirstPlan.
  ///
  /// In en, this message translates to:
  /// **'Your first plan'**
  String get yourFirstPlan;

  /// No description provided for @onboardingWelcomeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ever pick up your phone for one thing and lose an hour?'**
  String get onboardingWelcomeQuestion;

  /// No description provided for @whatShouldCurreCallYou.
  ///
  /// In en, this message translates to:
  /// **'What should Curre call you?'**
  String get whatShouldCurreCallYou;

  /// No description provided for @whatPullsYouIn.
  ///
  /// In en, this message translates to:
  /// **'What pulls you in?'**
  String get whatPullsYouIn;

  /// No description provided for @makeCurreHomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Make Curre your home screen.'**
  String get makeCurreHomeHeadline;

  /// No description provided for @withoutCurre.
  ///
  /// In en, this message translates to:
  /// **'Without Curre'**
  String get withoutCurre;

  /// No description provided for @withoutCurreBody.
  ///
  /// In en, this message translates to:
  /// **'One quick look. The feed pulls you in. An hour is gone.'**
  String get withoutCurreBody;

  /// No description provided for @withCurre.
  ///
  /// In en, this message translates to:
  /// **'With Curre'**
  String get withCurre;

  /// No description provided for @withCurreBody.
  ///
  /// In en, this message translates to:
  /// **'Say what you need. Curre opens the app right where you need it.'**
  String get withCurreBody;

  /// No description provided for @historyContactsStay.
  ///
  /// In en, this message translates to:
  /// **'Your history and contacts stay on this phone.'**
  String get historyContactsStay;

  /// No description provided for @howCurrePrivate.
  ///
  /// In en, this message translates to:
  /// **'How Curre keeps things private'**
  String get howCurrePrivate;

  /// No description provided for @namePrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Just for your greeting on Home. It stays on this phone.'**
  String get namePrivacyNote;

  /// No description provided for @addNameError.
  ///
  /// In en, this message translates to:
  /// **'Add a name, even just a nickname.'**
  String get addNameError;

  /// No description provided for @pickFaceOrInitial.
  ///
  /// In en, this message translates to:
  /// **'Pick a face, or keep your initial. You can change it any time.'**
  String get pickFaceOrInitial;

  /// No description provided for @whatsFocusFor.
  ///
  /// In en, this message translates to:
  /// **'What’s this focus for?'**
  String get whatsFocusFor;

  /// No description provided for @focusOnboardingBody.
  ///
  /// In en, this message translates to:
  /// **'Curre helps most for a while, with an end date. When it ends, your phone goes back to normal. Skip this if you’re not sure yet.'**
  String get focusOnboardingBody;

  /// No description provided for @pickPullAppsBody.
  ///
  /// In en, this message translates to:
  /// **'Pick the ones where a quick look turns into an hour. Curre hides only these: they leave your Home, and opening one asks “Why now?” first. Every other app opens as usual.'**
  String get pickPullAppsBody;

  /// No description provided for @showAllApps.
  ///
  /// In en, this message translates to:
  /// **'Show all {count} apps'**
  String showAllApps(int count);

  /// No description provided for @changeHiddenAnyTime.
  ///
  /// In en, this message translates to:
  /// **'Hide another app or bring one back any time from Hidden apps or Curre settings.'**
  String get changeHiddenAnyTime;

  /// No description provided for @androidChooseCurre.
  ///
  /// In en, this message translates to:
  /// **'Android will ask which app to use as your home screen. Choose Curre.'**
  String get androidChooseCurre;

  /// No description provided for @homePointPlan.
  ///
  /// In en, this message translates to:
  /// **'Your Home shows your plan. Every app you didn’t hide is in All apps and opens as usual.'**
  String get homePointPlan;

  /// No description provided for @homePointHidden.
  ///
  /// In en, this message translates to:
  /// **'Only the apps you picked are hidden. Opening one asks “Why now?” first.'**
  String get homePointHidden;

  /// No description provided for @homePointDoor.
  ///
  /// In en, this message translates to:
  /// **'Tap an app on Home to go straight to your task.'**
  String get homePointDoor;

  /// No description provided for @curreIsHomeNow.
  ///
  /// In en, this message translates to:
  /// **'Curre is your home screen now.'**
  String get curreIsHomeNow;

  /// No description provided for @switchHomeAnyTime.
  ///
  /// In en, this message translates to:
  /// **'Changed your mind? You can switch home screens any time in Curre settings.'**
  String get switchHomeAnyTime;

  /// No description provided for @curreNotHomeHelp.
  ///
  /// In en, this message translates to:
  /// **'Curre isn’t your home screen yet. Try again, or open your phone’s home screen settings and choose Curre.'**
  String get curreNotHomeHelp;

  /// No description provided for @chooseCurreList.
  ///
  /// In en, this message translates to:
  /// **'Choose Curre in the list, then come back here.'**
  String get chooseCurreList;

  /// No description provided for @chooseCurreDefaultApps.
  ///
  /// In en, this message translates to:
  /// **'Tap “Home app”, choose Curre, then come back here.'**
  String get chooseCurreDefaultApps;

  /// No description provided for @chooseCurreSettings.
  ///
  /// In en, this message translates to:
  /// **'In Settings, search for “Home app” (or open Apps, then Default apps), choose Curre, then come back here.'**
  String get chooseCurreSettings;

  /// No description provided for @chooseCurrePhoneSettings.
  ///
  /// In en, this message translates to:
  /// **'Open your phone’s Settings app, search for “Home app”, choose Curre, then come back here.'**
  String get chooseCurrePhoneSettings;

  /// No description provided for @planExampleGuitar.
  ///
  /// In en, this message translates to:
  /// **'Learn the G chord on YouTube till 7'**
  String get planExampleGuitar;

  /// No description provided for @planExamplePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Play the Sunday worship playlist on Spotify'**
  String get planExamplePlaylist;

  /// No description provided for @planExampleMaps.
  ///
  /// In en, this message translates to:
  /// **'Find the way to the studio on Maps'**
  String get planExampleMaps;

  /// No description provided for @onboardingPlanHelp.
  ///
  /// In en, this message translates to:
  /// **'Say it in one sentence: the app, what you’ll do, and until when. Curre brings only that to your Home.'**
  String get onboardingPlanHelp;

  /// No description provided for @startFromExample.
  ///
  /// In en, this message translates to:
  /// **'Or start from one of these:'**
  String get startFromExample;

  /// No description provided for @morningStartNote.
  ///
  /// In en, this message translates to:
  /// **'Curre asks what your morning is for from {time}. Change that any time in Curre settings.'**
  String morningStartNote(String time);

  /// No description provided for @showMeHow.
  ///
  /// In en, this message translates to:
  /// **'Show me how'**
  String get showMeHow;

  /// No description provided for @callMe.
  ///
  /// In en, this message translates to:
  /// **'Call me {name}'**
  String callMe(String name);

  /// No description provided for @pickAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one'**
  String get pickAtLeastOne;

  /// No description provided for @hideThisOne.
  ///
  /// In en, this message translates to:
  /// **'Hide this one'**
  String get hideThisOne;

  /// No description provided for @hideThese.
  ///
  /// In en, this message translates to:
  /// **'Hide these {count}'**
  String hideThese(int count);

  /// No description provided for @noneOfThese.
  ///
  /// In en, this message translates to:
  /// **'None of these'**
  String get noneOfThese;

  /// No description provided for @makeCurreMyHome.
  ///
  /// In en, this message translates to:
  /// **'Make Curre my home screen'**
  String get makeCurreMyHome;

  /// No description provided for @openHomeSettings.
  ///
  /// In en, this message translates to:
  /// **'Open home settings'**
  String get openHomeSettings;

  /// No description provided for @planLater.
  ///
  /// In en, this message translates to:
  /// **'I’ll plan later'**
  String get planLater;

  /// No description provided for @useExample.
  ///
  /// In en, this message translates to:
  /// **'Use example: {text}'**
  String useExample(String text);

  /// No description provided for @findApp.
  ///
  /// In en, this message translates to:
  /// **'Find an app'**
  String get findApp;

  /// No description provided for @noAppMatches.
  ///
  /// In en, this message translates to:
  /// **'No app matches “{query}”.'**
  String noAppMatches(String query);

  /// No description provided for @everyAppHidden.
  ///
  /// In en, this message translates to:
  /// **'Every app on this phone is hidden.'**
  String get everyAppHidden;

  /// No description provided for @openApp.
  ///
  /// In en, this message translates to:
  /// **'Open {app}'**
  String openApp(String app);

  /// No description provided for @hideThisApp.
  ///
  /// In en, this message translates to:
  /// **'Hide this app'**
  String get hideThisApp;

  /// No description provided for @hideApp.
  ///
  /// In en, this message translates to:
  /// **'Hide {app}'**
  String hideApp(String app);

  /// No description provided for @appHiddenAsk.
  ///
  /// In en, this message translates to:
  /// **'{app} is hidden. Opening it asks “Why now?” first.'**
  String appHiddenAsk(String app);

  /// No description provided for @planApps.
  ///
  /// In en, this message translates to:
  /// **'Apps your plans can use'**
  String get planApps;

  /// No description provided for @planAppsHelp.
  ///
  /// In en, this message translates to:
  /// **'When you plan, Curre picks from these. Choose 2 to 30.'**
  String get planAppsHelp;

  /// No description provided for @hiddenAppsHelp.
  ///
  /// In en, this message translates to:
  /// **'Only these leave Home and ask “Why now?” first. Every other app opens as usual.'**
  String get hiddenAppsHelp;

  /// No description provided for @alwaysOnHomeHelp.
  ///
  /// In en, this message translates to:
  /// **'These stay on Home all day, no plan needed.'**
  String get alwaysOnHomeHelp;

  /// No description provided for @pickedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} picked'**
  String pickedCount(int count);

  /// No description provided for @hiddenCount.
  ///
  /// In en, this message translates to:
  /// **'{count} hidden'**
  String hiddenCount(int count);

  /// No description provided for @onHomeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} on Home'**
  String onHomeCount(int count);

  /// No description provided for @planAppsMinimum.
  ///
  /// In en, this message translates to:
  /// **'Plans need at least {count} apps to choose from.'**
  String planAppsMinimum(int count);

  /// No description provided for @planAppsMaximum.
  ///
  /// In en, this message translates to:
  /// **'That’s {count} already. Untick one to add another.'**
  String planAppsMaximum(int count);

  /// No description provided for @appAlwaysOnHome.
  ///
  /// In en, this message translates to:
  /// **'{app} is always on Home.'**
  String appAlwaysOnHome(String app);

  /// No description provided for @privacyDetails.
  ///
  /// In en, this message translates to:
  /// **'Privacy details'**
  String get privacyDetails;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'What leaves this phone, and for how long.'**
  String get privacySubtitle;

  /// No description provided for @privacyReadOnline.
  ///
  /// In en, this message translates to:
  /// **'What is read online'**
  String get privacyReadOnline;

  /// No description provided for @privacyReadOnlineBody.
  ///
  /// In en, this message translates to:
  /// **'Your plan, app names, the reason you give for opening a hidden app and a note you send after a task are read online so Curre can answer you.'**
  String get privacyReadOnlineBody;

  /// No description provided for @privacyCopyTime.
  ///
  /// In en, this message translates to:
  /// **'How long a copy may remain'**
  String get privacyCopyTime;

  /// No description provided for @privacyCopyTimeBody.
  ///
  /// In en, this message translates to:
  /// **'Curre keeps no online copy. The AI service that reads your words may keep a successful answer, including quoted words, for about a day so a retry can return the same answer. It then deletes that copy.'**
  String get privacyCopyTimeBody;

  /// No description provided for @privacyStaysHere.
  ///
  /// In en, this message translates to:
  /// **'What stays here'**
  String get privacyStaysHere;

  /// No description provided for @privacyStaysHereBody.
  ///
  /// In en, this message translates to:
  /// **'Your contacts, chat names, app use and history stay on this phone. You can clear plans, reasons and notes from Curre settings.'**
  String get privacyStaysHereBody;

  /// No description provided for @privacyHistoryHides.
  ///
  /// In en, this message translates to:
  /// **'What History hides'**
  String get privacyHistoryHides;

  /// No description provided for @privacyHistoryHidesBody.
  ///
  /// In en, this message translates to:
  /// **'Before History saves a checked reason or note, Curre looks for names, phone numbers, email and address or payment details. What it finds becomes a label such as [name] or [phone]. If that check isn’t available, your words stay as they are.'**
  String get privacyHistoryHidesBody;

  /// No description provided for @privacyLogs.
  ///
  /// In en, this message translates to:
  /// **'Curre records only whether a request worked and how long it took. It does not put your words in online logs.'**
  String get privacyLogs;

  /// No description provided for @savedForLaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved for later'**
  String get savedForLaterTitle;

  /// No description provided for @laterNoneFits.
  ///
  /// In en, this message translates to:
  /// **'Nothing you saved fits this plan, so it waits for a better time.'**
  String get laterNoneFits;

  /// No description provided for @laterBestFirst.
  ///
  /// In en, this message translates to:
  /// **'Best match for this plan first.'**
  String get laterBestFirst;

  /// No description provided for @laterNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first.'**
  String get laterNewestFirst;

  /// No description provided for @laterOneMore.
  ///
  /// In en, this message translates to:
  /// **'1 more keeps for another time.'**
  String get laterOneMore;

  /// No description provided for @laterMore.
  ///
  /// In en, this message translates to:
  /// **'{count} more keep for another time.'**
  String laterMore(int count);

  /// No description provided for @notToday.
  ///
  /// In en, this message translates to:
  /// **'Not today'**
  String get notToday;

  /// No description provided for @sectionYourFocus.
  ///
  /// In en, this message translates to:
  /// **'Your focus'**
  String get sectionYourFocus;

  /// No description provided for @sectionYourDay.
  ///
  /// In en, this message translates to:
  /// **'Your day'**
  String get sectionYourDay;

  /// No description provided for @dayStartsHelp.
  ///
  /// In en, this message translates to:
  /// **'When each part of your day starts, Curre asks what it’s for.'**
  String get dayStartsHelp;

  /// No description provided for @startsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at {time}'**
  String startsAt(String time);

  /// No description provided for @sectionYourApps.
  ///
  /// In en, this message translates to:
  /// **'Your apps'**
  String get sectionYourApps;

  /// No description provided for @defaultEssentials.
  ///
  /// In en, this message translates to:
  /// **'Phone, Messages and Settings'**
  String get defaultEssentials;

  /// No description provided for @defaultEssentialsMore.
  ///
  /// In en, this message translates to:
  /// **'Phone, Messages, Settings and {count} more'**
  String defaultEssentialsMore(int count);

  /// No description provided for @strictQuestion.
  ///
  /// In en, this message translates to:
  /// **'How strict should Curre be?'**
  String get strictQuestion;

  /// No description provided for @sectionHiddenApps.
  ///
  /// In en, this message translates to:
  /// **'Hidden apps'**
  String get sectionHiddenApps;

  /// No description provided for @askWhyHidden.
  ///
  /// In en, this message translates to:
  /// **'Ask “Why now?” when a hidden app opens'**
  String get askWhyHidden;

  /// No description provided for @needsAndroidOk.
  ///
  /// In en, this message translates to:
  /// **'Needs your OK in Android first'**
  String get needsAndroidOk;

  /// No description provided for @pausedOtherHome.
  ///
  /// In en, this message translates to:
  /// **'Paused while another home screen is in use'**
  String get pausedOtherHome;

  /// No description provided for @restingToday.
  ///
  /// In en, this message translates to:
  /// **'Resting today. Back tomorrow morning.'**
  String get restingToday;

  /// No description provided for @askWhyOn.
  ///
  /// In en, this message translates to:
  /// **'On, even from recent apps, notifications and links'**
  String get askWhyOn;

  /// No description provided for @keepHiddenQuiet.
  ///
  /// In en, this message translates to:
  /// **'Keep hidden apps quiet'**
  String get keepHiddenQuiet;

  /// No description provided for @focusEndedNothingHeld.
  ///
  /// In en, this message translates to:
  /// **'Your focus has ended, so nothing is held'**
  String get focusEndedNothingHeld;

  /// No description provided for @heldUntilBack.
  ///
  /// In en, this message translates to:
  /// **'On. Held until their app comes back.'**
  String get heldUntilBack;

  /// No description provided for @turnOnUsageAccess.
  ///
  /// In en, this message translates to:
  /// **'Turn on Usage access'**
  String get turnOnUsageAccess;

  /// No description provided for @turnOnNotificationAccess.
  ///
  /// In en, this message translates to:
  /// **'Turn on notification access'**
  String get turnOnNotificationAccess;

  /// No description provided for @sectionQuietNudges.
  ///
  /// In en, this message translates to:
  /// **'Quiet nudges'**
  String get sectionQuietNudges;

  /// No description provided for @allowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get allowNotifications;

  /// No description provided for @notificationsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed. The quiet nudges you choose can appear.'**
  String get notificationsAllowed;

  /// No description provided for @notificationsNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed yet. Tap to allow.'**
  String get notificationsNotAllowed;

  /// No description provided for @notificationsAndroidControls.
  ///
  /// In en, this message translates to:
  /// **'Android controls whether the quiet nudges you choose can appear'**
  String get notificationsAndroidControls;

  /// No description provided for @sectionVoiceTyping.
  ///
  /// In en, this message translates to:
  /// **'Voice typing'**
  String get sectionVoiceTyping;

  /// No description provided for @sectionYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get sectionYourName;

  /// No description provided for @nameInGreeting.
  ///
  /// In en, this message translates to:
  /// **'Name in your greeting'**
  String get nameInGreeting;

  /// No description provided for @sectionHomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Your home screen'**
  String get sectionHomeScreen;

  /// No description provided for @sectionHistoryPrivacy.
  ///
  /// In en, this message translates to:
  /// **'History and privacy'**
  String get sectionHistoryPrivacy;

  /// No description provided for @historySettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Your plans and the apps you brought back, from the last 30 days. Only on this phone.'**
  String get historySettingsBody;

  /// No description provided for @privacySettingsBody.
  ///
  /// In en, this message translates to:
  /// **'What is read online, what stays here and when online copies are deleted'**
  String get privacySettingsBody;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @clearHistorySettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Delete past plans, reasons, notes and missed notifications from this phone'**
  String get clearHistorySettingsBody;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @licences.
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get licences;

  /// No description provided for @licencesBody.
  ///
  /// In en, this message translates to:
  /// **'The fonts, icons, illustrations and voice typing Curre uses'**
  String get licencesBody;

  /// No description provided for @appLegalese.
  ///
  /// In en, this message translates to:
  /// **'Curre opens the task, not the app.'**
  String get appLegalese;

  /// No description provided for @sessionStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Your {session} starts at'**
  String sessionStartsAt(String session);

  /// No description provided for @sessionOrderError.
  ///
  /// In en, this message translates to:
  /// **'Mornings start before afternoons, and afternoons before evenings. Try a different time.'**
  String get sessionOrderError;

  /// No description provided for @sessionStartSaved.
  ///
  /// In en, this message translates to:
  /// **'Your {session} now starts at {time}.'**
  String sessionStartSaved(String session, String time);

  /// No description provided for @nameSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. Curre will greet you by this name.'**
  String get nameSaved;

  /// No description provided for @usageAccessDone.
  ///
  /// In en, this message translates to:
  /// **'Done. Curre will ask “Why now?” when a hidden app opens.'**
  String get usageAccessDone;

  /// No description provided for @accessStillOff.
  ///
  /// In en, this message translates to:
  /// **'It’s still off. You can turn it on here any time.'**
  String get accessStillOff;

  /// No description provided for @notificationAccessDone.
  ///
  /// In en, this message translates to:
  /// **'Done. Hidden apps will stay quiet until you bring them back.'**
  String get notificationAccessDone;

  /// No description provided for @notificationsPermissionDone.
  ///
  /// In en, this message translates to:
  /// **'Notifications are allowed. Curre will use the quiet nudge choices above.'**
  String get notificationsPermissionDone;

  /// No description provided for @notificationsPermissionOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are not allowed. You can allow them for Curre in your phone’s Settings.'**
  String get notificationsPermissionOff;

  /// No description provided for @chooseHomeApp.
  ///
  /// In en, this message translates to:
  /// **'Tap “Home app”, then choose the one you want.'**
  String get chooseHomeApp;

  /// No description provided for @searchHomeApp.
  ///
  /// In en, this message translates to:
  /// **'Your phone opened Settings. Search for “Home app” (or open Apps, then Default apps), then choose the one you want.'**
  String get searchHomeApp;

  /// No description provided for @openSettingsHomeApp.
  ///
  /// In en, this message translates to:
  /// **'Open your phone’s Settings app and search for “Home app”. Choose the one you want there.'**
  String get openSettingsHomeApp;

  /// No description provided for @curreNotHomeSettings.
  ///
  /// In en, this message translates to:
  /// **'Curre isn’t your home screen yet. Open your phone’s Settings, search for “Home app” and choose Curre.'**
  String get curreNotHomeSettings;

  /// No description provided for @clearHistoryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Clear your history?'**
  String get clearHistoryQuestion;

  /// No description provided for @clearHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes your past plans, the reasons you gave for bringing apps back, the notes you wrote after tasks and your missed notifications. Your proof days, today’s plan and any time already running stay as they are.'**
  String get clearHistoryBody;

  /// No description provided for @historyCleared.
  ///
  /// In en, this message translates to:
  /// **'History cleared.'**
  String get historyCleared;

  /// No description provided for @historyClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Curre couldn’t clear your history. Please try again.'**
  String get historyClearFailed;

  /// No description provided for @switchHome.
  ///
  /// In en, this message translates to:
  /// **'Switch to another home screen'**
  String get switchHome;

  /// No description provided for @curreNotHomeBody.
  ///
  /// In en, this message translates to:
  /// **'Curre isn’t your home screen right now. Your plans and history are still here, ready when you want them.'**
  String get curreNotHomeBody;

  /// No description provided for @switchHomeBody.
  ///
  /// In en, this message translates to:
  /// **'Want a different home screen for a while? That’s okay. Android lets you choose which app opens when you press Home. Your plans and history stay on this phone, and you can switch back any time.'**
  String get switchHomeBody;

  /// No description provided for @openHomeScreenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open home screen settings'**
  String get openHomeScreenSettings;

  /// No description provided for @chooseHomeScreenApp.
  ///
  /// In en, this message translates to:
  /// **'Choose a home screen app'**
  String get chooseHomeScreenApp;

  /// No description provided for @homeSettingsPath.
  ///
  /// In en, this message translates to:
  /// **'If your phone opens its Settings instead, look for Apps, then Default apps, then Home app.'**
  String get homeSettingsPath;

  /// No description provided for @nudgesHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose which silent notes Curre sends. Turning one off also cancels any of that kind already waiting.'**
  String get nudgesHelp;

  /// No description provided for @planYourDay.
  ///
  /// In en, this message translates to:
  /// **'Plan your day'**
  String get planYourDay;

  /// No description provided for @eachSessionBegins.
  ///
  /// In en, this message translates to:
  /// **'When each part of your day begins'**
  String get eachSessionBegins;

  /// No description provided for @morningBegins.
  ///
  /// In en, this message translates to:
  /// **'Once a day, when your morning begins'**
  String get morningBegins;

  /// No description provided for @afternoonEveningToo.
  ///
  /// In en, this message translates to:
  /// **'Afternoon and evening too'**
  String get afternoonEveningToo;

  /// No description provided for @afternoonEveningBegins.
  ///
  /// In en, this message translates to:
  /// **'Also when your afternoon and evening begin'**
  String get afternoonEveningBegins;

  /// No description provided for @planEnding.
  ///
  /// In en, this message translates to:
  /// **'Plan ending'**
  String get planEnding;

  /// No description provided for @tenMinutesBeforePlan.
  ///
  /// In en, this message translates to:
  /// **'Ten minutes before your plan ends'**
  String get tenMinutesBeforePlan;

  /// No description provided for @appTimeUp.
  ///
  /// In en, this message translates to:
  /// **'App time up'**
  String get appTimeUp;

  /// No description provided for @hiddenAppTimeEnds.
  ///
  /// In en, this message translates to:
  /// **'When time for a hidden app runs out'**
  String get hiddenAppTimeEnds;

  /// No description provided for @addProofLater.
  ///
  /// In en, this message translates to:
  /// **'A few minutes after your plan ends'**
  String get addProofLater;

  /// No description provided for @focusEnds.
  ///
  /// In en, this message translates to:
  /// **'Focus ends'**
  String get focusEnds;

  /// No description provided for @focusEndsMorning.
  ///
  /// In en, this message translates to:
  /// **'On the morning your focus period ends'**
  String get focusEndsMorning;

  /// No description provided for @turnAllNudgesOff.
  ///
  /// In en, this message translates to:
  /// **'Turn all quiet nudges off'**
  String get turnAllNudgesOff;

  /// No description provided for @turnAllNudgesOn.
  ///
  /// In en, this message translates to:
  /// **'Turn all quiet nudges on'**
  String get turnAllNudgesOn;

  /// No description provided for @gentle.
  ///
  /// In en, this message translates to:
  /// **'Gentle'**
  String get gentle;

  /// No description provided for @balanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get balanced;

  /// No description provided for @strict.
  ///
  /// In en, this message translates to:
  /// **'Strict'**
  String get strict;

  /// No description provided for @strictnessBody.
  ///
  /// In en, this message translates to:
  /// **'When you bring back a hidden app, Curre checks your reason. The stricter it is, the clearer your reason needs to be before the app opens.'**
  String get strictnessBody;

  /// No description provided for @hiddenChoiceNone.
  ///
  /// In en, this message translates to:
  /// **'None. Every app opens as usual.'**
  String get hiddenChoiceNone;

  /// No description provided for @hiddenChoiceOne.
  ///
  /// In en, this message translates to:
  /// **'1 app. Only it asks “Why now?”.'**
  String get hiddenChoiceOne;

  /// No description provided for @hiddenChoiceMany.
  ///
  /// In en, this message translates to:
  /// **'{count} apps. Only these ask “Why now?”.'**
  String hiddenChoiceMany(int count);

  /// No description provided for @missedNotifications.
  ///
  /// In en, this message translates to:
  /// **'Missed notifications'**
  String get missedNotifications;

  /// No description provided for @missedFromHidden.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 notification from hidden apps} other{{count} notifications from hidden apps}}'**
  String missedFromHidden(int count);

  /// No description provided for @heldUntilAppBack.
  ///
  /// In en, this message translates to:
  /// **'{count} held until their app comes back'**
  String heldUntilAppBack(int count);

  /// No description provided for @bringBackApp.
  ///
  /// In en, this message translates to:
  /// **'Bring back {app}'**
  String bringBackApp(String app);

  /// No description provided for @restDayTheyOpen.
  ///
  /// In en, this message translates to:
  /// **'Rest day: they open without asking'**
  String get restDayTheyOpen;

  /// No description provided for @nothingHidden.
  ///
  /// In en, this message translates to:
  /// **'Nothing is hidden. Every app opens as usual from All apps.'**
  String get nothingHidden;

  /// No description provided for @hiddenAppsOut.
  ///
  /// In en, this message translates to:
  /// **'Your hidden apps are out for your plan or for a while right now.'**
  String get hiddenAppsOut;

  /// No description provided for @hideAnotherApp.
  ///
  /// In en, this message translates to:
  /// **'Hide another app'**
  String get hideAnotherApp;

  /// No description provided for @notificationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 notification} other{{count} notifications}}'**
  String notificationsCount(int count);

  /// No description provided for @hiddenAppsTip.
  ///
  /// In en, this message translates to:
  /// **'Only the apps you chose to hide wait here. Tap one to bring it back for a while.'**
  String get hiddenAppsTip;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @appOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'That app didn’t open. It may not be installed.'**
  String get appOpenFailed;

  /// No description provided for @missedNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Held quietly while their apps were hidden, and given back when the app comes back. Nothing leaves this phone.'**
  String get missedNotificationsBody;

  /// No description provided for @nothingHeld.
  ///
  /// In en, this message translates to:
  /// **'Nothing held right now.'**
  String get nothingHeld;

  /// No description provided for @held.
  ///
  /// In en, this message translates to:
  /// **'Held'**
  String get held;

  /// No description provided for @givenBack.
  ///
  /// In en, this message translates to:
  /// **'Given back'**
  String get givenBack;

  /// No description provided for @openNotificationApp.
  ///
  /// In en, this message translates to:
  /// **'Open {app}'**
  String openNotificationApp(String app);

  /// No description provided for @openCurreAppInfo.
  ///
  /// In en, this message translates to:
  /// **'Open Curre’s App info'**
  String get openCurreAppInfo;

  /// No description provided for @openSettingsAppsCurre.
  ///
  /// In en, this message translates to:
  /// **'Open your phone’s Settings, then Apps, then Curre.'**
  String get openSettingsAppsCurre;

  /// No description provided for @restrictedStillOff.
  ///
  /// In en, this message translates to:
  /// **'It’s still off. That’s okay, Curre works without it. If Android said the setting is restricted, allow it once:'**
  String get restrictedStillOff;

  /// No description provided for @restrictedHelp.
  ///
  /// In en, this message translates to:
  /// **'If Android says the setting is restricted, allow it once:'**
  String get restrictedHelp;

  /// No description provided for @restrictedStepOne.
  ///
  /// In en, this message translates to:
  /// **'Open Curre’s App info.'**
  String get restrictedStepOne;

  /// No description provided for @restrictedStepTwo.
  ///
  /// In en, this message translates to:
  /// **'Tap the three dots in the top right corner.'**
  String get restrictedStepTwo;

  /// No description provided for @restrictedStepThree.
  ///
  /// In en, this message translates to:
  /// **'Tap “Allow restricted settings”.'**
  String get restrictedStepThree;

  /// No description provided for @restrictedStepFour.
  ///
  /// In en, this message translates to:
  /// **'Confirm with your PIN or fingerprint.'**
  String get restrictedStepFour;

  /// No description provided for @restrictedStepFive.
  ///
  /// In en, this message translates to:
  /// **'Come back here and switch access on.'**
  String get restrictedStepFive;

  /// No description provided for @noProblemSettings.
  ///
  /// In en, this message translates to:
  /// **'No problem. It’s in Curre settings any time.'**
  String get noProblemSettings;

  /// No description provided for @allSet.
  ///
  /// In en, this message translates to:
  /// **'All set.'**
  String get allSet;

  /// No description provided for @usageAccessAllSet.
  ///
  /// In en, this message translates to:
  /// **'Curre will ask “Why now?” when a hidden app opens.'**
  String get usageAccessAllSet;

  /// No description provided for @notificationAccessAllSet.
  ///
  /// In en, this message translates to:
  /// **'Hidden apps will stay quiet until you bring them back.'**
  String get notificationAccessAllSet;

  /// No description provided for @askWhyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Ask “Why now?” when a hidden app opens?'**
  String get askWhyPrompt;

  /// No description provided for @quietPrompt.
  ///
  /// In en, this message translates to:
  /// **'Keep hidden apps quiet?'**
  String get quietPrompt;

  /// No description provided for @askWhyPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Hidden apps can sneak back in through recent apps, links or notifications. Curre can ask “Why now?” then too. It only checks which app opened, never what’s on your screen.'**
  String get askWhyPromptBody;

  /// No description provided for @tryAgainAccess.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainAccess;

  /// No description provided for @hiddenNamesFallback.
  ///
  /// In en, this message translates to:
  /// **'the apps you hide'**
  String get hiddenNamesFallback;

  /// No description provided for @hiddenNamesTwo.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second}'**
  String hiddenNamesTwo(String first, String second);

  /// No description provided for @hiddenNamesMore.
  ///
  /// In en, this message translates to:
  /// **'{first}, {second} and {count} more'**
  String hiddenNamesMore(String first, String second, int count);

  /// No description provided for @quietPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Curre can hold notifications from {apps} quietly and give every one back when you open the app. Other apps notify as usual, and calls and alarms always come through.'**
  String quietPromptBody(String apps);

  /// No description provided for @focusPurposeExams.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get focusPurposeExams;

  /// No description provided for @focusPurposeDeadline.
  ///
  /// In en, this message translates to:
  /// **'A deadline'**
  String get focusPurposeDeadline;

  /// No description provided for @focusPurposeHabit.
  ///
  /// In en, this message translates to:
  /// **'Breaking a habit'**
  String get focusPurposeHabit;

  /// No description provided for @focusPurposeOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get focusPurposeOther;

  /// No description provided for @focusHintExams.
  ///
  /// In en, this message translates to:
  /// **'Pass my maths finals'**
  String get focusHintExams;

  /// No description provided for @focusHintDeadline.
  ///
  /// In en, this message translates to:
  /// **'Finish the portfolio'**
  String get focusHintDeadline;

  /// No description provided for @focusHintHabit.
  ///
  /// In en, this message translates to:
  /// **'Stop opening social apps in bed'**
  String get focusHintHabit;

  /// No description provided for @focusHintOther.
  ///
  /// In en, this message translates to:
  /// **'What I want to change'**
  String get focusHintOther;

  /// No description provided for @focusEndExams.
  ///
  /// In en, this message translates to:
  /// **'You made room for the work that mattered.'**
  String get focusEndExams;

  /// No description provided for @focusEndDeadline.
  ///
  /// In en, this message translates to:
  /// **'You carried this work to its finish line.'**
  String get focusEndDeadline;

  /// No description provided for @focusEndHabit.
  ///
  /// In en, this message translates to:
  /// **'You gave the new habit room to grow.'**
  String get focusEndHabit;

  /// No description provided for @focusEndOther.
  ///
  /// In en, this message translates to:
  /// **'You kept coming back to what mattered.'**
  String get focusEndOther;

  /// No description provided for @focusLengthWeek.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get focusLengthWeek;

  /// No description provided for @focusLengthTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'2 weeks'**
  String get focusLengthTwoWeeks;

  /// No description provided for @focusLengthThreeWeeks.
  ///
  /// In en, this message translates to:
  /// **'3 weeks'**
  String get focusLengthThreeWeeks;

  /// No description provided for @focusLengthThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get focusLengthThirtyDays;

  /// No description provided for @focusGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Your goal, in a few words (optional)'**
  String get focusGoalLabel;

  /// No description provided for @untilWhen.
  ///
  /// In en, this message translates to:
  /// **'Until when?'**
  String get untilWhen;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get pickDate;

  /// No description provided for @focusEndsSummary.
  ///
  /// In en, this message translates to:
  /// **'Ends {date}, in {days}. You can change it later.'**
  String focusEndsSummary(String date, String days);

  /// No description provided for @focusEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Focus ends on'**
  String get focusEndsOn;

  /// No description provided for @focusSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Curre couldn’t save your focus. Please try again.'**
  String get focusSaveFailed;

  /// No description provided for @focusQuestion.
  ///
  /// In en, this message translates to:
  /// **'What’s this focus for?'**
  String get focusQuestion;

  /// No description provided for @focusPickerBody.
  ///
  /// In en, this message translates to:
  /// **'Curre helps most for a stretch with an end: exams, a deadline, a habit you want to break.'**
  String get focusPickerBody;

  /// No description provided for @pickFocusPurpose.
  ///
  /// In en, this message translates to:
  /// **'Pick what it’s for'**
  String get pickFocusPurpose;

  /// No description provided for @startMyFocus.
  ///
  /// In en, this message translates to:
  /// **'Start my focus'**
  String get startMyFocus;

  /// No description provided for @setFocusQuestion.
  ///
  /// In en, this message translates to:
  /// **'Set a focus?'**
  String get setFocusQuestion;

  /// No description provided for @focusOfferBody.
  ///
  /// In en, this message translates to:
  /// **'Curre helps most for a stretch with an end: exams, a deadline, a habit to break. Pick one and when it ends.'**
  String get focusOfferBody;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater;

  /// No description provided for @setFocus.
  ///
  /// In en, this message translates to:
  /// **'Set a focus'**
  String get setFocus;

  /// No description provided for @restDay.
  ///
  /// In en, this message translates to:
  /// **'Rest day'**
  String get restDay;

  /// No description provided for @yourFocus.
  ///
  /// In en, this message translates to:
  /// **'Your focus'**
  String get yourFocus;

  /// No description provided for @restDayBody.
  ///
  /// In en, this message translates to:
  /// **'Hidden apps open without asking today, their notifications come through, and reminders stay quiet. Your proof days are safe. Back to focus tomorrow.'**
  String get restDayBody;

  /// No description provided for @focusLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} left · ends {date}'**
  String focusLeft(String days, String date);

  /// No description provided for @backToFocusNow.
  ///
  /// In en, this message translates to:
  /// **'Back to focus now'**
  String get backToFocusNow;

  /// No description provided for @takeTodayOff.
  ///
  /// In en, this message translates to:
  /// **'Take today off'**
  String get takeTodayOff;

  /// No description provided for @nextRestDay.
  ///
  /// In en, this message translates to:
  /// **'Next rest day: {date}'**
  String nextRestDay(String date);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get tomorrow;

  /// No description provided for @takeTodayOffQuestion.
  ///
  /// In en, this message translates to:
  /// **'Take today off?'**
  String get takeTodayOffQuestion;

  /// No description provided for @takeTodayOffBody.
  ///
  /// In en, this message translates to:
  /// **'Until tomorrow morning, hidden apps open without asking why, their notifications come through and Curre sends no reminders. Your proof days stay safe. You can take one rest day a week.'**
  String get takeTodayOffBody;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get keepGoing;

  /// No description provided for @enjoyRestDay.
  ///
  /// In en, this message translates to:
  /// **'Enjoy your rest day. Back to focus tomorrow.'**
  String get enjoyRestDay;

  /// No description provided for @focusSummaryDays.
  ///
  /// In en, this message translates to:
  /// **'{days} of focus.'**
  String focusSummaryDays(String days);

  /// No description provided for @focusSummaryWithRest.
  ///
  /// In en, this message translates to:
  /// **'{days} of focus, {rests}.'**
  String focusSummaryWithRest(String days, String rests);

  /// No description provided for @restDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 rest day} other{{count} rest days}}'**
  String restDaysCount(int count);

  /// No description provided for @daysWithProof.
  ///
  /// In en, this message translates to:
  /// **'days with proof'**
  String get daysWithProof;

  /// No description provided for @tasksProved.
  ///
  /// In en, this message translates to:
  /// **'tasks proved'**
  String get tasksProved;

  /// No description provided for @hiddenAppsLeftClosed.
  ///
  /// In en, this message translates to:
  /// **'hidden apps left closed'**
  String get hiddenAppsLeftClosed;

  /// No description provided for @startAnotherFocus.
  ///
  /// In en, this message translates to:
  /// **'Start another focus period'**
  String get startAnotherFocus;

  /// No description provided for @oldHomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Go back to my old home screen'**
  String get oldHomeScreen;

  /// No description provided for @focusHistoryStays.
  ///
  /// In en, this message translates to:
  /// **'Your history and proof days stay on this phone either way.'**
  String get focusHistoryStays;

  /// No description provided for @chooseOldHome.
  ///
  /// In en, this message translates to:
  /// **'Choose your old home screen in the list. Curre stops asking why and lets every notification through.'**
  String get chooseOldHome;

  /// No description provided for @tapOldHome.
  ///
  /// In en, this message translates to:
  /// **'Tap “Home app”, then choose your old home screen.'**
  String get tapOldHome;

  /// No description provided for @searchOldHome.
  ///
  /// In en, this message translates to:
  /// **'Your phone opened Settings. Search for “Home app”, then choose your old home screen.'**
  String get searchOldHome;

  /// No description provided for @openSettingsOldHome.
  ///
  /// In en, this message translates to:
  /// **'Open your phone’s Settings app and search for “Home app”. Choose your old home screen there.'**
  String get openSettingsOldHome;

  /// No description provided for @noFocusSet.
  ///
  /// In en, this message translates to:
  /// **'No focus set'**
  String get noFocusSet;

  /// No description provided for @focusSettingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Pick what this stretch is for and when it ends.'**
  String get focusSettingsEmpty;

  /// No description provided for @focusEndedOn.
  ///
  /// In en, this message translates to:
  /// **'Ended {date}. See how it went on Home.'**
  String focusEndedOn(String date);

  /// No description provided for @focusEndsLeft.
  ///
  /// In en, this message translates to:
  /// **'Ends {date}, {days} left'**
  String focusEndsLeft(String date, String days);

  /// No description provided for @changeEndDate.
  ///
  /// In en, this message translates to:
  /// **'Change end date'**
  String get changeEndDate;

  /// No description provided for @weeklyRestNext.
  ///
  /// In en, this message translates to:
  /// **'One rest day a week. Next one: {date}.'**
  String weeklyRestNext(String date);

  /// No description provided for @endFocusNow.
  ///
  /// In en, this message translates to:
  /// **'End focus now'**
  String get endFocusNow;

  /// No description provided for @focusNowEnds.
  ///
  /// In en, this message translates to:
  /// **'Your focus now ends {date}.'**
  String focusNowEnds(String date);

  /// No description provided for @endFocusQuestion.
  ///
  /// In en, this message translates to:
  /// **'End your focus now?'**
  String get endFocusQuestion;

  /// No description provided for @endFocusBody.
  ///
  /// In en, this message translates to:
  /// **'Home shows how it went, then you choose what’s next. Your history and proof days stay.'**
  String get endFocusBody;

  /// No description provided for @endFocus.
  ///
  /// In en, this message translates to:
  /// **'End focus'**
  String get endFocus;

  /// No description provided for @historySubtitle.
  ///
  /// In en, this message translates to:
  /// **'The last 30 days · only on this phone'**
  String get historySubtitle;

  /// No description provided for @whatHappened.
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get whatHappened;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'A quiet start.'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Your plans, and the apps you bring back, will show up here. It all stays on this phone.'**
  String get historyEmptyBody;

  /// No description provided for @plannedSessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of 21 planned'**
  String plannedSessionsCount(int count);

  /// No description provided for @historyOverviewHelp.
  ///
  /// In en, this message translates to:
  /// **'Each square is a morning, afternoon or evening in the last 7 days. Filled ones started with a plan.'**
  String get historyOverviewHelp;

  /// No description provided for @sessionPlanState.
  ///
  /// In en, this message translates to:
  /// **'{session}: {state}'**
  String sessionPlanState(String session, String state);

  /// No description provided for @planned.
  ///
  /// In en, this message translates to:
  /// **'planned'**
  String get planned;

  /// No description provided for @noPlan.
  ///
  /// In en, this message translates to:
  /// **'no plan'**
  String get noPlan;

  /// No description provided for @proofCloudInHand.
  ///
  /// In en, this message translates to:
  /// **'You have a cloud day. {detail}'**
  String proofCloudInHand(String detail);

  /// No description provided for @oneMoreProofToCloud.
  ///
  /// In en, this message translates to:
  /// **'1 more proof day to your next cloud day.'**
  String get oneMoreProofToCloud;

  /// No description provided for @moreProofToCloud.
  ///
  /// In en, this message translates to:
  /// **'{count} more proof days to your next cloud day.'**
  String moreProofToCloud(int count);

  /// No description provided for @proofDaysInAll.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 proof day in all} other{{count} proof days in all}}'**
  String proofDaysInAll(int count);

  /// No description provided for @bestRunCount.
  ///
  /// In en, this message translates to:
  /// **'Best run {count}'**
  String bestRunCount(int count);

  /// No description provided for @cloudDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 cloud day} other{{count} cloud days}}'**
  String cloudDaysCount(int count);

  /// No description provided for @historyProofHint.
  ///
  /// In en, this message translates to:
  /// **'After a task, say what changed. A specific note adds a proof day.'**
  String get historyProofHint;

  /// No description provided for @historySessionPlan.
  ///
  /// In en, this message translates to:
  /// **'{session, select, morning{Morning plan} afternoon{Afternoon plan} evening{Evening plan} other{Plan}}'**
  String historySessionPlan(String session);

  /// No description provided for @endedEarlyAt.
  ///
  /// In en, this message translates to:
  /// **'Ended early at {ended}, planned until {planned}'**
  String endedEarlyAt(String ended, String planned);

  /// No description provided for @waitedDuration.
  ///
  /// In en, this message translates to:
  /// **'Waited {duration}'**
  String waitedDuration(String duration);

  /// No description provided for @whyNowApp.
  ///
  /// In en, this message translates to:
  /// **'Why now? · {app}'**
  String whyNowApp(String app);

  /// No description provided for @olderReasonMissing.
  ///
  /// In en, this message translates to:
  /// **'Reason wasn’t stored in this older entry.'**
  String get olderReasonMissing;

  /// No description provided for @appCameBack.
  ///
  /// In en, this message translates to:
  /// **'{app} came back'**
  String appCameBack(String app);

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @openedAfterWaiting.
  ///
  /// In en, this message translates to:
  /// **'Opened after waiting {duration}'**
  String openedAfterWaiting(String duration);

  /// No description provided for @openedFromLater.
  ///
  /// In en, this message translates to:
  /// **'Saved for later, then opened from a plan'**
  String get openedFromLater;

  /// No description provided for @supportedProof.
  ///
  /// In en, this message translates to:
  /// **'Supported proof'**
  String get supportedProof;

  /// No description provided for @waitingToBeChecked.
  ///
  /// In en, this message translates to:
  /// **'Waiting to be checked'**
  String get waitingToBeChecked;

  /// No description provided for @markedDone.
  ///
  /// In en, this message translates to:
  /// **'Marked done'**
  String get markedDone;

  /// No description provided for @noNote.
  ///
  /// In en, this message translates to:
  /// **'No note'**
  String get noNote;

  /// No description provided for @personalDetailHidden.
  ///
  /// In en, this message translates to:
  /// **'Personal detail hidden'**
  String get personalDetailHidden;

  /// No description provided for @outcomeOpened.
  ///
  /// In en, this message translates to:
  /// **'Opened'**
  String get outcomeOpened;

  /// No description provided for @outcomeNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get outcomeNotNow;

  /// No description provided for @outcomeNeededDetail.
  ///
  /// In en, this message translates to:
  /// **'Needed more detail'**
  String get outcomeNeededDetail;

  /// No description provided for @outcomeNotReason.
  ///
  /// In en, this message translates to:
  /// **'Not a reason'**
  String get outcomeNotReason;

  /// No description provided for @outcomeCouldNotCheck.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t check'**
  String get outcomeCouldNotCheck;

  /// No description provided for @nextSunriseOneProof.
  ///
  /// In en, this message translates to:
  /// **'Next sunrise: one proof away'**
  String get nextSunriseOneProof;

  /// No description provided for @noProofDaysYet.
  ///
  /// In en, this message translates to:
  /// **'No proof days yet'**
  String get noProofDaysYet;

  /// No description provided for @proofDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 proof day} other{{count} proof days}}'**
  String proofDaysCount(int count);

  /// No description provided for @todaysSunIsUp.
  ///
  /// In en, this message translates to:
  /// **'today’s sun is up'**
  String get todaysSunIsUp;

  /// No description provided for @oneCloudInHand.
  ///
  /// In en, this message translates to:
  /// **'one cloud day in hand'**
  String get oneCloudInHand;

  /// No description provided for @cloudDay.
  ///
  /// In en, this message translates to:
  /// **'Cloud day'**
  String get cloudDay;

  /// No description provided for @runEndedAt.
  ///
  /// In en, this message translates to:
  /// **'That run ended at {days}.'**
  String runEndedAt(String days);

  /// No description provided for @todaysProofStartsNext.
  ///
  /// In en, this message translates to:
  /// **'Today’s proof starts the next sunrise.'**
  String get todaysProofStartsNext;

  /// No description provided for @theNextSunrise.
  ///
  /// In en, this message translates to:
  /// **'The next sunrise'**
  String get theNextSunrise;

  /// No description provided for @dayProof.
  ///
  /// In en, this message translates to:
  /// **'proof day'**
  String get dayProof;

  /// No description provided for @dayPending.
  ///
  /// In en, this message translates to:
  /// **'note waiting to be checked'**
  String get dayPending;

  /// No description provided for @dayNoProof.
  ///
  /// In en, this message translates to:
  /// **'no proof'**
  String get dayNoProof;

  /// No description provided for @dayCloud.
  ///
  /// In en, this message translates to:
  /// **'cloud day'**
  String get dayCloud;

  /// No description provided for @dayToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get dayToday;

  /// No description provided for @dayFuture.
  ///
  /// In en, this message translates to:
  /// **'still to come'**
  String get dayFuture;

  /// No description provided for @dayStillOpen.
  ///
  /// In en, this message translates to:
  /// **'still open'**
  String get dayStillOpen;

  /// No description provided for @startingToday.
  ///
  /// In en, this message translates to:
  /// **'Starting today'**
  String get startingToday;

  /// No description provided for @proofRunRange.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String proofRunRange(String start, String end);

  /// No description provided for @sinceDate.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String sinceDate(String date);

  /// No description provided for @milestoneSeven.
  ///
  /// In en, this message translates to:
  /// **'Seven proof days: your rays now end in sparks.'**
  String get milestoneSeven;

  /// No description provided for @milestoneTwentyOne.
  ///
  /// In en, this message translates to:
  /// **'21 proof days: a ring of light now stands behind your sun.'**
  String get milestoneTwentyOne;

  /// No description provided for @milestoneFifty.
  ///
  /// In en, this message translates to:
  /// **'50 proof days: your sun wears a second ring.'**
  String get milestoneFifty;

  /// No description provided for @cloudDayKeepsRun.
  ///
  /// In en, this message translates to:
  /// **'If a day passes without proof, it keeps your run going.'**
  String get cloudDayKeepsRun;

  /// No description provided for @weekdaySunUp.
  ///
  /// In en, this message translates to:
  /// **'{weekday}’s sun is up'**
  String weekdaySunUp(String weekday);

  /// No description provided for @earnedCloudDay.
  ///
  /// In en, this message translates to:
  /// **'You earned a cloud day. {detail}'**
  String earnedCloudDay(String detail);

  /// No description provided for @completionQuestion.
  ///
  /// In en, this message translates to:
  /// **'What changed, finished, or became clear?'**
  String get completionQuestion;

  /// No description provided for @oneSentenceEnough.
  ///
  /// In en, this message translates to:
  /// **'One sentence is enough'**
  String get oneSentenceEnough;

  /// No description provided for @addOneDetail.
  ///
  /// In en, this message translates to:
  /// **'Add one detail'**
  String get addOneDetail;

  /// No description provided for @addWhatChanged.
  ///
  /// In en, this message translates to:
  /// **'Add what changed'**
  String get addWhatChanged;

  /// No description provided for @proofMismatchPrompt.
  ///
  /// In en, this message translates to:
  /// **'“{detail}” doesn’t match the task you planned. What changed, finished, or became clear?'**
  String proofMismatchPrompt(String detail);

  /// No description provided for @proofFuturePrompt.
  ///
  /// In en, this message translates to:
  /// **'That sounds like what comes next. What changed, finished, or became clear?'**
  String get proofFuturePrompt;

  /// No description provided for @proofUnrelatedPrompt.
  ///
  /// In en, this message translates to:
  /// **'Say how it connects to your plan. What changed, finished, or became clear?'**
  String get proofUnrelatedPrompt;

  /// No description provided for @proofDetailPrompt.
  ///
  /// In en, this message translates to:
  /// **'A name, a number or a step is enough. What changed, finished, or became clear?'**
  String get proofDetailPrompt;

  /// No description provided for @justMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Just mark it done'**
  String get justMarkDone;

  /// No description provided for @readingYourNote.
  ///
  /// In en, this message translates to:
  /// **'Reading your note'**
  String get readingYourNote;

  /// No description provided for @readingYourNoteProgress.
  ///
  /// In en, this message translates to:
  /// **'Reading your note…'**
  String get readingYourNoteProgress;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Your note is saved'**
  String get noteSaved;

  /// No description provided for @noteSavedBody.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t check it right now. It will be checked once you’re back online.'**
  String get noteSavedBody;

  /// No description provided for @runSafeWhileWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your run stays safe while it waits.'**
  String get runSafeWhileWaiting;

  /// No description provided for @markedAsDone.
  ///
  /// In en, this message translates to:
  /// **'Marked as done'**
  String get markedAsDone;

  /// No description provided for @markedDoneBody.
  ///
  /// In en, this message translates to:
  /// **'It’s in your history. Proof days come from a note about what changed.'**
  String get markedDoneBody;

  /// No description provided for @noteCountsAsProof.
  ///
  /// In en, this message translates to:
  /// **'Your note counts as proof.'**
  String get noteCountsAsProof;

  /// No description provided for @oneMoreRay.
  ///
  /// In en, this message translates to:
  /// **'One more ray'**
  String get oneMoreRay;

  /// No description provided for @proofAdded.
  ///
  /// In en, this message translates to:
  /// **'Proof added'**
  String get proofAdded;

  /// No description provided for @profileSmiling.
  ///
  /// In en, this message translates to:
  /// **'Your profile, smiling'**
  String get profileSmiling;

  /// No description provided for @sunOneRay.
  ///
  /// In en, this message translates to:
  /// **'Today’s sun, one ray: one task with proof'**
  String get sunOneRay;

  /// No description provided for @sunManyRays.
  ///
  /// In en, this message translates to:
  /// **'Today’s sun, {count} rays: {count} tasks with proof'**
  String sunManyRays(int count);

  /// No description provided for @proofDayUnit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{proof day} other{proof days}}'**
  String proofDayUnit(int count);

  /// No description provided for @newRunStarts.
  ///
  /// In en, this message translates to:
  /// **'A new run starts here.'**
  String get newRunStarts;

  /// No description provided for @supported.
  ///
  /// In en, this message translates to:
  /// **'Supported'**
  String get supported;

  /// No description provided for @backedByStart.
  ///
  /// In en, this message translates to:
  /// **'Backed by starting the task and your note'**
  String get backedByStart;

  /// No description provided for @backedByApp.
  ///
  /// In en, this message translates to:
  /// **'Backed by the app you opened and your note'**
  String get backedByApp;

  /// No description provided for @voicePermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Curre listens only while you hold or tap the mic. Your voice never leaves your phone.'**
  String get voicePermissionExplanation;

  /// No description provided for @voiceMicNeeded.
  ///
  /// In en, this message translates to:
  /// **'Voice typing needs the mic. You can type instead.'**
  String get voiceMicNeeded;

  /// No description provided for @voiceCouldNotStart.
  ///
  /// In en, this message translates to:
  /// **'Voice typing couldn\'t start. You can type instead.'**
  String get voiceCouldNotStart;

  /// No description provided for @voiceGettingReady.
  ///
  /// In en, this message translates to:
  /// **'Voice is getting ready. You can type for now.'**
  String get voiceGettingReady;

  /// No description provided for @voiceReadyOffline.
  ///
  /// In en, this message translates to:
  /// **'Ready. Voice typing now works offline.'**
  String get voiceReadyOffline;

  /// No description provided for @voiceMicStillOff.
  ///
  /// In en, this message translates to:
  /// **'The mic is still off. Allow it to speak, or type instead.'**
  String get voiceMicStillOff;

  /// No description provided for @voiceNothingHeard.
  ///
  /// In en, this message translates to:
  /// **'I didn’t catch that. Try again, a little closer to the mic.'**
  String get voiceNothingHeard;

  /// No description provided for @voicePrivacyLine.
  ///
  /// In en, this message translates to:
  /// **'On this phone · nothing you say is saved or sent'**
  String get voicePrivacyLine;

  /// No description provided for @typeInstead.
  ///
  /// In en, this message translates to:
  /// **'Type instead'**
  String get typeInstead;

  /// No description provided for @gettingVoiceReady.
  ///
  /// In en, this message translates to:
  /// **'Getting voice typing ready'**
  String get gettingVoiceReady;

  /// No description provided for @downloadNowSize.
  ///
  /// In en, this message translates to:
  /// **'Download now · {size}'**
  String downloadNowSize(String size);

  /// No description provided for @speakInsteadTyping.
  ///
  /// In en, this message translates to:
  /// **'Speak instead of typing'**
  String get speakInsteadTyping;

  /// No description provided for @allowMic.
  ///
  /// In en, this message translates to:
  /// **'Allow the mic'**
  String get allowMic;

  /// No description provided for @micOffForCurre.
  ///
  /// In en, this message translates to:
  /// **'The mic is off for Curre'**
  String get micOffForCurre;

  /// No description provided for @micSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on Microphone for Curre in your phone’s settings, then come back. {privacy}'**
  String micSettingsBody(String privacy);

  /// No description provided for @openPhoneSettings.
  ///
  /// In en, this message translates to:
  /// **'Open phone settings'**
  String get openPhoneSettings;

  /// No description provided for @tapOrHoldMic.
  ///
  /// In en, this message translates to:
  /// **'Tap or hold the mic, then speak.'**
  String get tapOrHoldMic;

  /// No description provided for @listeningHeld.
  ///
  /// In en, this message translates to:
  /// **'Listening… let go when you’re done.'**
  String get listeningHeld;

  /// No description provided for @listeningPause.
  ///
  /// In en, this message translates to:
  /// **'Listening… pause when you’re done, or tap the mic.'**
  String get listeningPause;

  /// No description provided for @writingSaid.
  ///
  /// In en, this message translates to:
  /// **'Writing down what you said'**
  String get writingSaid;

  /// No description provided for @writingProgress.
  ///
  /// In en, this message translates to:
  /// **'Writing it down…'**
  String get writingProgress;

  /// No description provided for @voiceStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Voice typing couldn’t start'**
  String get voiceStartFailed;

  /// No description provided for @micStartFailed.
  ///
  /// In en, this message translates to:
  /// **'The mic didn’t start'**
  String get micStartFailed;

  /// No description provided for @voiceModelFix.
  ///
  /// In en, this message translates to:
  /// **'Downloading the voice files again ({size}) usually fixes it.'**
  String voiceModelFix(String size);

  /// No description provided for @voiceMicBusy.
  ///
  /// In en, this message translates to:
  /// **'If another app is using the mic, close it and try again.'**
  String get voiceMicBusy;

  /// No description provided for @downloadAgain.
  ///
  /// In en, this message translates to:
  /// **'Download again'**
  String get downloadAgain;

  /// No description provided for @voiceAmount.
  ///
  /// In en, this message translates to:
  /// **'{received} of {total}'**
  String voiceAmount(String received, String total);

  /// No description provided for @voiceStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready · works offline'**
  String get voiceStatusReady;

  /// No description provided for @voiceStatusGetting.
  ///
  /// In en, this message translates to:
  /// **'Getting ready {percent}% · {amount}'**
  String voiceStatusGetting(int percent, String amount);

  /// No description provided for @voiceWaitingWifi.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Wi-Fi{extra}'**
  String voiceWaitingWifi(String extra);

  /// No description provided for @voiceWaitingConnection.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a connection{extra}'**
  String voiceWaitingConnection(String extra);

  /// No description provided for @voiceWaitingBattery.
  ///
  /// In en, this message translates to:
  /// **'Waiting for more battery{extra}'**
  String voiceWaitingBattery(String extra);

  /// No description provided for @voiceStatusExtra.
  ///
  /// In en, this message translates to:
  /// **' · {amount} so far'**
  String voiceStatusExtra(String amount);

  /// No description provided for @voiceStoppedStorage.
  ///
  /// In en, this message translates to:
  /// **'Stopped · your phone needs {size} free'**
  String voiceStoppedStorage(String size);

  /// No description provided for @voiceStoppedLater.
  ///
  /// In en, this message translates to:
  /// **'Stopped · it tries again later{extra}'**
  String voiceStoppedLater(String extra);

  /// No description provided for @voiceNotOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Not on this phone · {size}, when you next use the mic'**
  String voiceNotOnPhone(String size);

  /// No description provided for @voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this phone'**
  String get voiceUnavailable;

  /// No description provided for @voiceDownload.
  ///
  /// In en, this message translates to:
  /// **'Voice download'**
  String get voiceDownload;

  /// No description provided for @voiceKeepsGoing.
  ///
  /// In en, this message translates to:
  /// **'{amount}. It keeps going if you close this.'**
  String voiceKeepsGoing(String amount);

  /// No description provided for @voiceDownloadsWifi.
  ///
  /// In en, this message translates to:
  /// **'It downloads by itself on Wi-Fi, {size} once.'**
  String voiceDownloadsWifi(String size);

  /// No description provided for @voiceNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection right now. It picks up where it stopped.'**
  String get voiceNoConnection;

  /// No description provided for @voiceWaitBattery.
  ///
  /// In en, this message translates to:
  /// **'It waits for more battery, or a charger.'**
  String get voiceWaitBattery;

  /// No description provided for @voiceNoSpace.
  ///
  /// In en, this message translates to:
  /// **'Your phone is short on space. Voice typing needs {size} free.'**
  String voiceNoSpace(String size);

  /// No description provided for @voiceDamaged.
  ///
  /// In en, this message translates to:
  /// **'A file arrived damaged, so it was thrown away. Try again.'**
  String get voiceDamaged;

  /// No description provided for @voiceFilesUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The voice files couldn’t be reached. Try again in a little while.'**
  String get voiceFilesUnreachable;

  /// No description provided for @voiceRunsHere.
  ///
  /// In en, this message translates to:
  /// **'Voice typing runs on this phone and needs {size} once.'**
  String voiceRunsHere(String size);

  /// No description provided for @stopAndWrite.
  ///
  /// In en, this message translates to:
  /// **'Stop and write it down'**
  String get stopAndWrite;

  /// No description provided for @startListening.
  ///
  /// In en, this message translates to:
  /// **'Start listening'**
  String get startListening;

  /// No description provided for @removeVoiceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove the voice files?'**
  String get removeVoiceQuestion;

  /// No description provided for @removeVoiceBody.
  ///
  /// In en, this message translates to:
  /// **'This frees {size}. Voice typing downloads again only when you next use the mic, or turn it back on here.'**
  String removeVoiceBody(String size);

  /// No description provided for @keepFiles.
  ///
  /// In en, this message translates to:
  /// **'Keep them'**
  String get keepFiles;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @voiceFilesRemoved.
  ///
  /// In en, this message translates to:
  /// **'Voice files removed.'**
  String get voiceFilesRemoved;

  /// No description provided for @voiceFilesRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'The voice files couldn’t be removed.'**
  String get voiceFilesRemoveFailed;

  /// No description provided for @voiceOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Voice: on this phone'**
  String get voiceOnPhone;

  /// No description provided for @voiceSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Voice typing needs no account and, once downloaded, no internet. Nothing you say is saved or sent.'**
  String get voiceSettingsBody;

  /// No description provided for @downloadMobile.
  ///
  /// In en, this message translates to:
  /// **'Download voice on mobile data'**
  String get downloadMobile;

  /// No description provided for @mobileOffHelp.
  ///
  /// In en, this message translates to:
  /// **'Off: it waits for Wi-Fi. About {size}, once.'**
  String mobileOffHelp(String size);

  /// No description provided for @downloadVoiceFiles.
  ///
  /// In en, this message translates to:
  /// **'Download voice files'**
  String get downloadVoiceFiles;

  /// No description provided for @removeVoiceFiles.
  ///
  /// In en, this message translates to:
  /// **'Remove voice files'**
  String get removeVoiceFiles;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
