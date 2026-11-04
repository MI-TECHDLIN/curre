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
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get languagePortuguese;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
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
