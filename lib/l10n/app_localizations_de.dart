// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Curre';

  @override
  String get systemLanguage => 'Sprache des Smartphones';

  @override
  String get language => 'Sprache';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languageSpanish => 'Spanisch';

  @override
  String get languageFrench => 'Französisch';

  @override
  String get languagePortuguese => 'Portugiesisch';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get back => 'Zurück';

  @override
  String get close => 'Schließen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get done => 'Fertig';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get save => 'Speichern';

  @override
  String get notNow => 'Jetzt nicht';

  @override
  String get checking => 'Wird geprüft…';

  @override
  String get on => 'Ein';

  @override
  String get off => 'Aus';

  @override
  String get sessionMorning => 'Morgen';

  @override
  String get sessionAfternoon => 'Nachmittag';

  @override
  String get sessionEvening => 'Abend';

  @override
  String goodSession(String session) {
    return 'Guten $session';
  }

  @override
  String goodSessionName(String session, String name) {
    return 'Guten $session, $name';
  }

  @override
  String planThisSession(String session) {
    return 'Diesen $session planen';
  }

  @override
  String planYourSession(String session) {
    return 'Deinen $session planen';
  }

  @override
  String whatsThisSessionFor(String session) {
    return 'Wofür ist dieser $session?';
  }

  @override
  String setMySession(String session) {
    return 'Meinen $session festlegen';
  }

  @override
  String get phone => 'Telefon';

  @override
  String get messages => 'Nachrichten';

  @override
  String get androidSettings => 'Einstellungen';

  @override
  String get curreSettings => 'Curre-Einstellungen';

  @override
  String get allApps => 'Alle Apps';

  @override
  String get allAppsDescription =>
      'Alle Apps, die du nicht ausgeblendet hast – bereit zum Öffnen.';

  @override
  String get hiddenApps => 'Ausgeblendete Apps';

  @override
  String hiddenAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgeblendete Apps',
      one: '1 ausgeblendete App',
      zero: 'Keine ausgeblendeten Apps',
    );
    return '$_temp0';
  }

  @override
  String appsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Apps',
      one: '1 App',
    );
    return '$_temp0';
  }

  @override
  String minutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Minuten',
      one: '1 Minute',
    );
    return '$_temp0';
  }

  @override
  String secondsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sekunden',
      one: '1 Sekunde',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get couldNotReadApps => 'Deine Apps konnten nicht gelesen werden';

  @override
  String get couldNotReadAppsBody =>
      'Curre konnte die installierten Apps auf diesem Smartphone nicht lesen. Versuche es erneut, damit deine Apps hier erscheinen.';

  @override
  String get readingApps => 'Apps werden gelesen…';

  @override
  String get profileAvatar => 'Profilbild';

  @override
  String get openProfile => 'Profil öffnen';

  @override
  String get gettingReady => 'Alles wird vorbereitet…';

  @override
  String get gettingReadyBody => 'Das kann ein paar Sekunden länger dauern.';

  @override
  String get checkinHint => 'Sag oder schreib, was du erledigen möchtest.';

  @override
  String get sayItInstead => 'Stattdessen sprechen';

  @override
  String get planning => 'Dein Plan wird erstellt…';

  @override
  String get planningSemantics => 'Apps für deinen Plan werden ausgewählt';

  @override
  String get chooseAppsYourself => 'Apps selbst auswählen';

  @override
  String get chooseAppsBody =>
      'Curre konnte diesen Plan online nicht erstellen. Wähle die benötigten Apps aus und mach weiter.';

  @override
  String get useThisPlan => 'Diesen Plan verwenden';

  @override
  String get planReady => 'Dein Plan ist fertig';

  @override
  String onHomeUntil(String time) {
    return 'Bis $time auf dem Startbildschirm';
  }

  @override
  String get whyNow => 'Warum jetzt?';

  @override
  String whyNeedAppNow(String app) {
    return 'Wofür brauchst du $app gerade?';
  }

  @override
  String get whyNowHelp =>
      'Sag, was du tun willst, für wen und wie lange. Curre öffnet die App genau an der richtigen Stelle.';

  @override
  String get yourReason => 'Dein Grund';

  @override
  String get reasonHint => 'Ada wegen der Probe antworten';

  @override
  String yourPlan(String plan) {
    return 'Dein Plan: $plan';
  }

  @override
  String get oneMoreTry => 'Noch ein Versuch: Sag genau, was du tun wirst.';

  @override
  String get bringItBack => 'Wieder einblenden';

  @override
  String get askAgain => 'Erneut fragen';

  @override
  String get readingReason => 'Dein Grund wird gelesen';

  @override
  String get readingReasonProgress => 'Dein Grund wird gelesen…';

  @override
  String guardQuote(String quote) {
    return 'Diese Wörter wirken wie eine Anweisung an Curre: „$quote“';
  }

  @override
  String openAfter(String duration) {
    return 'Nach $duration öffnen';
  }

  @override
  String get saveForLater => 'Für später speichern';

  @override
  String appOpensIn(String app) {
    return '$app öffnet in';
  }

  @override
  String appOpensInDuration(String app, String duration) {
    return '$app öffnet in $duration';
  }

  @override
  String get waitUnavailableBody =>
      'Curre konnte deinen Grund nicht prüfen. Die App öffnet deshalb nach einer kurzen Wartezeit.';

  @override
  String get waitAllowedBody =>
      'Du hast dich fürs Warten entschieden, und das ist in Ordnung.';

  @override
  String get waitCancelHelp =>
      'Verlasse diese Seite zum Abbrechen. Wenn du wartest, erscheint das in deinem Verlauf.';

  @override
  String outcomeOpenApp(String app) {
    return 'Öffnet $app';
  }

  @override
  String outcomeOpenAt(String destination) {
    return 'Öffnet bei $destination';
  }

  @override
  String get outcomeSpecify => 'Was genau wirst du tun?';

  @override
  String get outcomeFlagged =>
      'Das klingt nach einer Anweisung, nicht nach einem Grund';

  @override
  String get outcomeUnavailable => 'Dein Grund konnte nicht geprüft werden';

  @override
  String youHaveMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Minuten',
      one: '1 Minute',
    );
    return 'Du hast $_temp0.';
  }

  @override
  String chatWith(String person) {
    return 'Chat mit $person';
  }

  @override
  String openDestination(String destination) {
    return '$destination öffnen';
  }

  @override
  String get savedForNextPlan =>
      'Gespeichert. Es erscheint bei deinem nächsten Plan wieder.';

  @override
  String get couldNotSave =>
      'Curre konnte das nicht auf diesem Smartphone speichern. Versuche es erneut.';

  @override
  String get settingsSubtitle => 'Änderungen gelten nur für Curre.';

  @override
  String todayPercent(int percent) {
    return 'Heute sind $percent Prozent geschafft';
  }

  @override
  String get oneSentenceHome =>
      'Ein Satz. Nur Genanntes erscheint auf dem Startbildschirm.';

  @override
  String get yourPlanLabel => 'Dein Plan';

  @override
  String get planHint => 'Bis 7 Uhr den G-Dur-Akkord auf YouTube lernen';

  @override
  String get sayYourPlan => 'Plan sprechen';

  @override
  String get gettingAppsReady => 'Deine Apps werden vorbereitet…';

  @override
  String get choosingApps => 'Apps werden ausgewählt';

  @override
  String lookingThroughApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Apps werden geprüft',
      one: '1 App wird geprüft',
    );
    return '$_temp0';
  }

  @override
  String get useTheseApps => 'Diese Apps verwenden';

  @override
  String get heresYourPlan => 'Hier ist dein Plan';

  @override
  String get backToHome => 'Zurück zum Startbildschirm';

  @override
  String get changePlan => 'Plan ändern';

  @override
  String get fallbackConnect => 'Gerade keine Verbindung möglich';

  @override
  String get fallbackTimeout => 'Das hat zu lange gedauert';

  @override
  String get fallbackReadPlan => 'Curre konnte diesen Plan nicht lesen';

  @override
  String get fallbackPlan => 'Curre konnte gerade keinen Plan erstellen';

  @override
  String get fallbackNetworkBody =>
      'Prüfe deine Internetverbindung und versuche es erneut oder wähle die Apps unten selbst aus.';

  @override
  String get fallbackBody =>
      'Versuche es gleich erneut oder wähle die Apps unten selbst aus.';

  @override
  String openedHiddenApp(String app) {
    return 'Du hast $app geöffnet. Sie gehört zu deinen ausgeblendeten Apps.';
  }

  @override
  String appIsHidden(String app) {
    return '$app gehört zu deinen ausgeblendeten Apps.';
  }

  @override
  String openNoChatBody(String app, String minutes) {
    return 'Curre hat auf diesem Smartphone keinen passenden Chat gefunden und öffnet deshalb $app. $minutes';
  }

  @override
  String laterBody(String duration, String app) {
    return 'Das klingt nach Stöbern und kann warten. Speichere es für später oder warte $duration, um $app jetzt zu öffnen.';
  }

  @override
  String specifyBody(String duration, String app) {
    return 'Sag etwas genauer, was du tun willst, oder warte $duration, um $app zu öffnen.';
  }

  @override
  String flaggedBody(String app, String duration) {
    return 'Sag Curre stattdessen, was du in $app tun willst. Oder warte $duration, um die App zu öffnen.';
  }

  @override
  String unavailableBody(String app, String duration) {
    return 'Kein Problem: $app öffnet nach $duration Wartezeit. Du kannst es auch erneut versuchen.';
  }

  @override
  String untilAppOpens(String duration, String app) {
    return '$duration, bis $app öffnet';
  }

  @override
  String get querySearch => 'Suchen';

  @override
  String get queryDraft => 'Entwurf';

  @override
  String get queryNewEvent => 'Neuer Termin';

  @override
  String get queryOpenWith => 'App öffnen mit';

  @override
  String get kindTask => 'Eine Aufgabe';

  @override
  String get kindPerson => 'Jemand wartet';

  @override
  String get kindTimeSensitive => 'Kann nicht warten';

  @override
  String get kindBrowse => 'Nur stöbern';

  @override
  String get kindUnclear => 'Noch nicht klar';

  @override
  String confidencePercent(String label, int percent) {
    return '$label, Sicherheit $percent Prozent';
  }

  @override
  String get outcomeGlyphOpen => 'Öffnet';

  @override
  String get outcomeGlyphLater => 'Jetzt nicht';

  @override
  String get outcomeGlyphSpecify => 'Mehr Details nötig';

  @override
  String get outcomeGlyphFlagged => 'Kein Grund';

  @override
  String get outcomeGlyphUnavailable => 'Prüfung nicht möglich';

  @override
  String get alwaysOnHome => 'Immer auf dem Startbildschirm';

  @override
  String get pressHoldApp =>
      'Halte eine App gedrückt, um sie normal zu öffnen.';

  @override
  String get quietNudgeQuestion =>
      'Möchtest du einen stillen Hinweis, wenn die Zeit um ist?';

  @override
  String get quietNudgeBody =>
      'Curre kann dich informieren, wenn dein Plan oder die Zeit einer App endet. Ohne Ton, Vibration oder Werbung.';

  @override
  String get quietNudgeYes => 'Ja, bitte erinnern';

  @override
  String get sayOneSentence =>
      'Sag es in einem Satz. Curre zeigt nur die nötigen Apps auf dem Startbildschirm.';

  @override
  String get planNow => 'Jetzt planen';

  @override
  String tasksReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufgaben bereit',
      one: '1 Aufgabe bereit',
    );
    return '$_temp0';
  }

  @override
  String tasksDone(int done, int count) {
    return '$done von $count erledigt';
  }

  @override
  String yourSession(String session) {
    return 'Dein $session';
  }

  @override
  String untilTime(String time) {
    return 'bis $time';
  }

  @override
  String get changeThisPlan => 'Diesen Plan ändern';

  @override
  String get onHomeNow => 'Jetzt auf dem Startbildschirm';

  @override
  String get alwaysAppsBelow => 'Deine immer verfügbaren Apps stehen unten.';

  @override
  String get tapStraightThere =>
      'Tippe auf eine, um direkt dorthin zu gelangen.';

  @override
  String get nothingPlanned => 'Noch nichts geplant';

  @override
  String get nothingPlannedBody =>
      'Plane deinen Tag und die Apps erscheinen hier.';

  @override
  String get alwaysAvailable => 'Immer verfügbar';

  @override
  String get doneWithProof => 'Erledigt, mit Nachweis';

  @override
  String get doneWaiting => 'Erledigt · deine Notiz wird noch geprüft';

  @override
  String get doneAddNote => 'Erledigt · tippen, um eine Notiz hinzuzufügen';

  @override
  String get doneToday => 'Heute erledigt';

  @override
  String get show => 'Anzeigen';

  @override
  String get hide => 'Ausblenden';

  @override
  String get todaySunUp => 'Die heutige Sonne ist aufgegangen';

  @override
  String get todaySun => 'Die heutige Sonne';

  @override
  String allDoneSession(String session) {
    return 'Alles für diesen $session erledigt';
  }

  @override
  String get allDoneBody =>
      'Alle Aufgaben dieses Plans sind erledigt. Du kannst ihn jetzt beenden und jederzeit neu planen.';

  @override
  String get endPlanNow => 'Plan jetzt beenden';

  @override
  String get endPlanQuestion => 'Diesen Plan jetzt beenden?';

  @override
  String get endPlanBody =>
      'Seine Aufgaben verlassen den Startbildschirm. Du kannst jederzeit neu planen.';

  @override
  String get keepIt => 'Behalten';

  @override
  String get endPlan => 'Plan beenden';

  @override
  String get planEnded => 'Plan beendet.';

  @override
  String get undo => 'Rückgängig';

  @override
  String get tapStart => 'Tippe beim Beginn auf Start';

  @override
  String get start => 'Start';

  @override
  String startedAt(String time) {
    return 'Um $time begonnen · am Ende tippen';
  }

  @override
  String get awayFromPhone => 'Abseits vom Smartphone';

  @override
  String get you => 'Du';

  @override
  String get closeProfile => 'Profil schließen';

  @override
  String get yourFace => 'Dein Gesicht';

  @override
  String get pickYourFace => 'Wähle das, das sich nach dir anfühlt.';

  @override
  String get useInitial => 'Stattdessen meinen Anfangsbuchstaben verwenden';

  @override
  String get proofDays => 'Tage mit Nachweis';

  @override
  String get bestRun => 'Beste Folge';

  @override
  String get cloudDays => 'Ruhetage';

  @override
  String get history => 'Verlauf';

  @override
  String get yourName => 'Dein Name';

  @override
  String get saveName => 'Name speichern';

  @override
  String get editName => 'Name bearbeiten';

  @override
  String get app => 'App';

  @override
  String get quietNudgeOn =>
      'Stille Hinweise sind aktiviert. Du kannst sie in den Curre-Einstellungen auswählen.';

  @override
  String get quietNudgeOff =>
      'Kein Problem. Du kannst stille Hinweise später in den Curre-Einstellungen aktivieren.';

  @override
  String planPercent(int percent) {
    return 'Dieser Plan ist zu $percent Prozent abgeschlossen';
  }

  @override
  String appsReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bereit',
      one: '1 bereit',
    );
    return '$_temp0';
  }

  @override
  String appBackForNow(String app) {
    return '$app ist vorerst wieder da';
  }

  @override
  String doneDoorSemantics(String app, String state, String destination) {
    return '$app, $state, öffnet $destination';
  }

  @override
  String tasksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufgaben',
      one: '1 Aufgabe',
    );
    return '$_temp0';
  }

  @override
  String doneTodayShow(String count) {
    return 'Heute erledigt, $count. Anzeigen';
  }

  @override
  String doneTodayCount(int count) {
    return 'Heute erledigt · $count';
  }

  @override
  String get endPlanFailed =>
      'Curre konnte den Plan nicht beenden. Versuche es erneut.';

  @override
  String get planTimeUp => 'Die Zeit dieses Plans ist bereits abgelaufen.';

  @override
  String get doorOpenFailed =>
      'Das hat sich nicht geöffnet. Halte die App gedrückt, um sie normal zu öffnen.';

  @override
  String copiedSearch(String target) {
    return '„$target“ wurde kopiert. Füge es in das Suchfeld ein.';
  }

  @override
  String get addProof => 'Nachweis hinzufügen';

  @override
  String get snoozeTenMinutes => '10 Min. später';

  @override
  String get focusDone => 'Deine Fokuszeit ist vorbei';

  @override
  String focusDoneNotification(String days) {
    return 'Sieh dir an, wie diese $days liefen, und entscheide, was als Nächstes kommt.';
  }

  @override
  String sessionAlmostDone(String session) {
    return 'Dein $session ist fast vorbei';
  }

  @override
  String get planEndsTenMinutes =>
      'Dein Plan endet in 10 Minuten. Entscheide, was als Nächstes kommt.';

  @override
  String get addYourProof => 'Füge deinen Nachweis hinzu';

  @override
  String get proofNotificationBody =>
      'Eine kurze Notiz darüber, was du erledigt hast, gilt als Nachweis.';

  @override
  String grantOngoingBody(String task) {
    return '$task · Die App wird am Ende wieder ausgeblendet.';
  }

  @override
  String appHiddenAgain(String app) {
    return '$app ist wieder ausgeblendet';
  }

  @override
  String grantExpiredBody(int minutes, String reason) {
    return 'Deine $minutes Min. für $reason sind vorbei.';
  }

  @override
  String get whatDidYouGetDone => 'Was hast du erledigt?';

  @override
  String get onboardingSaveFailed =>
      'Curre konnte deine Antworten nicht auf diesem Smartphone speichern. Versuche es erneut.';

  @override
  String get welcomeCurre => 'Willkommen bei Curre';

  @override
  String get aboutYou => 'Über dich';

  @override
  String get yourApps => 'Deine Apps';

  @override
  String get yourHomeScreen => 'Dein Startbildschirm';

  @override
  String get yourFirstPlan => 'Dein erster Plan';

  @override
  String get onboardingWelcomeQuestion =>
      'Nimmst du das Smartphone für eine Sache und verlierst eine Stunde?';

  @override
  String get whatShouldCurreCallYou => 'Wie soll Curre dich nennen?';

  @override
  String get whatPullsYouIn => 'Was zieht dich hinein?';

  @override
  String get makeCurreHomeHeadline => 'Mach Curre zu deinem Startbildschirm.';

  @override
  String get withoutCurre => 'Ohne Curre';

  @override
  String get withoutCurreBody =>
      'Nur kurz schauen. Der Feed zieht dich hinein. Eine Stunde ist vorbei.';

  @override
  String get withCurre => 'Mit Curre';

  @override
  String get withCurreBody =>
      'Sag, was du brauchst. Curre öffnet die App an der richtigen Stelle.';

  @override
  String get historyContactsStay =>
      'Dein Verlauf und deine Kontakte bleiben auf diesem Smartphone.';

  @override
  String get howCurrePrivate => 'So schützt Curre deine Daten';

  @override
  String get namePrivacyNote =>
      'Nur für die Begrüßung auf dem Startbildschirm. Der Name bleibt auf diesem Smartphone.';

  @override
  String get addNameError => 'Gib einen Namen ein, auch ein Spitzname reicht.';

  @override
  String get pickFaceOrInitial =>
      'Wähle ein Gesicht oder behalte deinen Anfangsbuchstaben. Du kannst es jederzeit ändern.';

  @override
  String get whatsFocusFor => 'Wofür ist diese Fokuszeit?';

  @override
  String get focusOnboardingBody =>
      'Curre hilft am meisten für eine Zeit mit Enddatum. Danach wird dein Smartphone wieder normal. Überspringe das, wenn du noch unsicher bist.';

  @override
  String get pickPullAppsBody =>
      'Wähle Apps, bei denen aus einem kurzen Blick eine Stunde wird. Curre blendet nur diese aus und fragt beim Öffnen „Warum jetzt?“. Alle anderen öffnen wie gewohnt.';

  @override
  String showAllApps(int count) {
    return 'Alle $count Apps anzeigen';
  }

  @override
  String get changeHiddenAnyTime =>
      'Blende jederzeit unter Ausgeblendete Apps oder in den Curre-Einstellungen eine weitere App aus oder wieder ein.';

  @override
  String get androidChooseCurre =>
      'Android fragt, welche App als Startbildschirm verwendet werden soll. Wähle Curre.';

  @override
  String get homePointPlan =>
      'Dein Startbildschirm zeigt deinen Plan. Nicht ausgeblendete Apps stehen unter Alle Apps und öffnen wie gewohnt.';

  @override
  String get homePointHidden =>
      'Nur die gewählten Apps sind ausgeblendet. Beim Öffnen fragt Curre „Warum jetzt?“.';

  @override
  String get homePointDoor =>
      'Tippe auf dem Startbildschirm auf eine App, um direkt zu deiner Aufgabe zu kommen.';

  @override
  String get curreIsHomeNow => 'Curre ist jetzt dein Startbildschirm.';

  @override
  String get switchHomeAnyTime =>
      'Anders entschieden? Du kannst den Startbildschirm jederzeit in den Curre-Einstellungen wechseln.';

  @override
  String get curreNotHomeHelp =>
      'Curre ist noch nicht dein Startbildschirm. Versuche es erneut oder öffne die Startbildschirm-Einstellungen und wähle Curre.';

  @override
  String get chooseCurreList =>
      'Wähle Curre in der Liste und komm dann zurück.';

  @override
  String get chooseCurreDefaultApps =>
      'Tippe auf „Start-App“, wähle Curre und komm zurück.';

  @override
  String get chooseCurreSettings =>
      'Suche in Einstellungen nach „Start-App“ oder öffne Apps und Standard-Apps; wähle Curre und komm zurück.';

  @override
  String get chooseCurrePhoneSettings =>
      'Öffne die Smartphone-Einstellungen, suche nach „Start-App“, wähle Curre und komm zurück.';

  @override
  String get planExampleGuitar =>
      'Bis 7 Uhr den G-Dur-Akkord auf YouTube lernen';

  @override
  String get planExamplePlaylist =>
      'Die Sonntags-Playlist auf Spotify abspielen';

  @override
  String get planExampleMaps => 'Den Weg zum Studio in Maps finden';

  @override
  String get onboardingPlanHelp =>
      'Sag in einem Satz: die App, was du tun wirst und bis wann. Curre bringt nur das auf deinen Startbildschirm.';

  @override
  String get startFromExample => 'Oder beginne mit einem Beispiel:';

  @override
  String morningStartNote(String time) {
    return 'Curre fragt ab $time, wofür dein Morgen da ist. Ändere das in den Einstellungen.';
  }

  @override
  String get showMeHow => 'Zeig mir wie';

  @override
  String callMe(String name) {
    return 'Nenn mich $name';
  }

  @override
  String get pickAtLeastOne => 'Wähle mindestens eine';

  @override
  String get hideThisOne => 'Diese ausblenden';

  @override
  String hideThese(int count) {
    return 'Diese $count ausblenden';
  }

  @override
  String get noneOfThese => 'Keine davon';

  @override
  String get makeCurreMyHome => 'Curre als Startbildschirm verwenden';

  @override
  String get openHomeSettings => 'Startbildschirm-Einstellungen öffnen';

  @override
  String get planLater => 'Ich plane später';

  @override
  String useExample(String text) {
    return 'Beispiel verwenden: $text';
  }
}
