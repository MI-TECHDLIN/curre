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
  String chatWith(String target) {
    return 'Mit $target chatten';
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
  String get awayFromPhone => 'Abseits vom Handy';

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

  @override
  String get findApp => 'App suchen';

  @override
  String noAppMatches(String query) {
    return 'Keine App passt zu „$query“.';
  }

  @override
  String get everyAppHidden =>
      'Alle Apps auf diesem Smartphone sind ausgeblendet.';

  @override
  String openApp(String app) {
    return '$app öffnen';
  }

  @override
  String get hideThisApp => 'Diese App ausblenden';

  @override
  String hideApp(String app) {
    return '$app ausblenden';
  }

  @override
  String appHiddenAsk(String app) {
    return '$app ist ausgeblendet. Beim Öffnen fragt Curre zuerst „Warum jetzt?“.';
  }

  @override
  String get planApps => 'Apps für deine Pläne';

  @override
  String get planAppsHelp =>
      'Beim Planen wählt Curre aus diesen Apps. Wähle 2 bis 30.';

  @override
  String get hiddenAppsHelp =>
      'Nur diese verlassen den Startbildschirm und fragen zuerst „Warum jetzt?“. Alle anderen öffnen wie gewohnt.';

  @override
  String get alwaysOnHomeHelp =>
      'Diese bleiben den ganzen Tag auf dem Startbildschirm, auch ohne Plan.';

  @override
  String pickedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String hiddenCount(int count) {
    return '$count ausgeblendet';
  }

  @override
  String onHomeCount(int count) {
    return '$count auf dem Startbildschirm';
  }

  @override
  String planAppsMinimum(int count) {
    return 'Pläne brauchen mindestens $count Apps zur Auswahl.';
  }

  @override
  String planAppsMaximum(int count) {
    return 'Du hast schon $count. Wähle eine ab, um eine weitere hinzuzufügen.';
  }

  @override
  String appAlwaysOnHome(String app) {
    return '$app ist immer auf dem Startbildschirm.';
  }

  @override
  String get privacyDetails => 'Datenschutzdetails';

  @override
  String get privacySubtitle => 'Was dieses Smartphone verlässt und wie lange.';

  @override
  String get privacyReadOnline => 'Was online gelesen wird';

  @override
  String get privacyReadOnlineBody =>
      'Dein Plan, App-Namen, der Grund zum Öffnen einer ausgeblendeten App und Notizen nach einer Aufgabe werden online gelesen, damit Curre dir antworten kann.';

  @override
  String get privacyCopyTime => 'Wie lange eine Kopie bestehen kann';

  @override
  String get privacyCopyTimeBody =>
      'Curre speichert keine Online-Kopie. Der KI-Dienst kann eine erfolgreiche Antwort einschließlich zitierter Wörter ungefähr einen Tag behalten, damit ein neuer Versuch dieselbe Antwort erhält. Danach wird sie gelöscht.';

  @override
  String get privacyStaysHere => 'Was hier bleibt';

  @override
  String get privacyStaysHereBody =>
      'Deine Kontakte, Chat-Namen, App-Nutzung und dein Verlauf bleiben auf diesem Smartphone. Pläne, Gründe und Notizen kannst du in den Curre-Einstellungen löschen.';

  @override
  String get privacyHistoryHides => 'Was der Verlauf verbirgt';

  @override
  String get privacyHistoryHidesBody =>
      'Bevor der Verlauf einen geprüften Grund oder eine Notiz speichert, sucht Curre nach Namen, Telefonnummern, E-Mails, Adressen und Zahlungsdaten. Gefundene Angaben werden zu Bezeichnungen wie [Name] oder [Telefon]. Ist die Prüfung nicht verfügbar, bleiben deine Wörter unverändert.';

  @override
  String get privacyLogs =>
      'Curre zeichnet nur auf, ob eine Anfrage funktioniert hat und wie lange sie dauerte. Deine Wörter stehen nicht in Online-Protokollen.';

  @override
  String get savedForLaterTitle => 'Für später gespeichert';

  @override
  String get laterNoneFits =>
      'Nichts Gespeichertes passt zu diesem Plan. Es wartet auf einen besseren Zeitpunkt.';

  @override
  String get laterBestFirst =>
      'Die beste Übereinstimmung mit diesem Plan zuerst.';

  @override
  String get laterNewestFirst => 'Neueste zuerst.';

  @override
  String get laterOneMore => '1 weiteres wartet auf einen anderen Zeitpunkt.';

  @override
  String laterMore(int count) {
    return '$count weitere warten auf einen anderen Zeitpunkt.';
  }

  @override
  String get notToday => 'Heute nicht';

  @override
  String get sectionYourFocus => 'Dein Fokus';

  @override
  String get sectionYourDay => 'Dein Tag';

  @override
  String get dayStartsHelp =>
      'Zu Beginn jedes Tagesabschnitts fragt Curre, wofür er da ist.';

  @override
  String startsAt(String time) {
    return 'Beginnt um $time';
  }

  @override
  String get sectionYourApps => 'Deine Apps';

  @override
  String get defaultEssentials => 'Telefon, Nachrichten und Einstellungen';

  @override
  String defaultEssentialsMore(int count) {
    return 'Telefon, Nachrichten, Einstellungen und $count weitere';
  }

  @override
  String get strictQuestion => 'Wie streng soll Curre sein?';

  @override
  String get sectionHiddenApps => 'Ausgeblendete Apps';

  @override
  String get askWhyHidden =>
      'Beim Öffnen einer ausgeblendeten App „Warum jetzt?“ fragen';

  @override
  String get needsAndroidOk => 'Braucht zuerst deine Zustimmung in Android';

  @override
  String get pausedOtherHome =>
      'Pausiert, während ein anderer Startbildschirm verwendet wird';

  @override
  String get restingToday => 'Heute ist Ruhetag. Morgen früh geht es weiter.';

  @override
  String get askWhyOn =>
      'Aktiv, auch über zuletzt verwendete Apps, Mitteilungen und Links';

  @override
  String get keepHiddenQuiet => 'Ausgeblendete Apps still halten';

  @override
  String get focusEndedNothingHeld =>
      'Dein Fokus ist beendet, daher wird nichts zurückgehalten';

  @override
  String get heldUntilBack =>
      'Aktiv. Zurückgehalten, bis die App wieder da ist.';

  @override
  String get turnOnUsageAccess => 'Nutzungszugriff aktivieren';

  @override
  String get turnOnNotificationAccess => 'Mitteilungszugriff aktivieren';

  @override
  String get sectionQuietNudges => 'Stille Hinweise';

  @override
  String get allowNotifications => 'Mitteilungen erlauben';

  @override
  String get notificationsAllowed =>
      'Erlaubt. Deine ausgewählten Hinweise können erscheinen.';

  @override
  String get notificationsNotAllowed =>
      'Noch nicht erlaubt. Tippe zum Erlauben.';

  @override
  String get notificationsAndroidControls =>
      'Android bestimmt, ob deine ausgewählten Hinweise erscheinen dürfen';

  @override
  String get sectionVoiceTyping => 'Spracheingabe';

  @override
  String get sectionYourName => 'Dein Name';

  @override
  String get nameInGreeting => 'Name in deiner Begrüßung';

  @override
  String get sectionHomeScreen => 'Dein Startbildschirm';

  @override
  String get sectionHistoryPrivacy => 'Verlauf und Datenschutz';

  @override
  String get historySettingsBody =>
      'Deine Pläne und zurückgeholten Apps der letzten 30 Tage. Nur auf diesem Smartphone.';

  @override
  String get privacySettingsBody =>
      'Was online gelesen wird, was hier bleibt und wann Online-Kopien gelöscht werden';

  @override
  String get clearHistory => 'Verlauf löschen';

  @override
  String get clearHistorySettingsBody =>
      'Frühere Pläne, Gründe, Notizen und verpasste Mitteilungen von diesem Smartphone löschen';

  @override
  String get sectionAbout => 'Info';

  @override
  String get licences => 'Lizenzen';

  @override
  String get licencesBody =>
      'Schriften, Symbole, Illustrationen und Spracheingabe, die Curre verwendet';

  @override
  String get appLegalese => 'Curre öffnet die Aufgabe, nicht die App.';

  @override
  String sessionStartsAt(String session) {
    return 'Dein $session beginnt um';
  }

  @override
  String get sessionOrderError =>
      'Der Morgen beginnt vor dem Nachmittag und der Nachmittag vor dem Abend. Wähle eine andere Zeit.';

  @override
  String sessionStartSaved(String session, String time) {
    return 'Dein $session beginnt jetzt um $time.';
  }

  @override
  String get nameSaved => 'Gespeichert. Curre begrüßt dich mit diesem Namen.';

  @override
  String get usageAccessDone =>
      'Fertig. Curre fragt beim Öffnen einer ausgeblendeten App „Warum jetzt?“.';

  @override
  String get accessStillOff =>
      'Noch immer deaktiviert. Du kannst es hier jederzeit aktivieren.';

  @override
  String get notificationAccessDone =>
      'Fertig. Ausgeblendete Apps bleiben still, bis du sie zurückholst.';

  @override
  String get notificationsPermissionDone =>
      'Mitteilungen sind erlaubt. Curre verwendet die oben ausgewählten stillen Hinweise.';

  @override
  String get notificationsPermissionOff =>
      'Mitteilungen sind nicht erlaubt. Du kannst sie für Curre in den Smartphone-Einstellungen erlauben.';

  @override
  String get chooseHomeApp =>
      'Tippe auf „Start-App“ und wähle die gewünschte App.';

  @override
  String get searchHomeApp =>
      'Die Einstellungen wurden geöffnet. Suche nach „Start-App“ oder öffne Apps und Standard-Apps und triff deine Wahl.';

  @override
  String get openSettingsHomeApp =>
      'Öffne die Smartphone-Einstellungen und suche nach „Start-App“. Wähle dort die gewünschte App.';

  @override
  String get curreNotHomeSettings =>
      'Curre ist noch nicht dein Startbildschirm. Öffne die Einstellungen, suche nach „Start-App“ und wähle Curre.';

  @override
  String get clearHistoryQuestion => 'Deinen Verlauf löschen?';

  @override
  String get clearHistoryBody =>
      'Frühere Pläne, Gründe fürs Zurückholen von Apps, Notizen nach Aufgaben und verpasste Mitteilungen werden gelöscht. Deine Nachweistage, der heutige Plan und laufende Zeiten bleiben erhalten.';

  @override
  String get historyCleared => 'Verlauf gelöscht.';

  @override
  String get historyClearFailed =>
      'Curre konnte deinen Verlauf nicht löschen. Versuche es erneut.';

  @override
  String get switchHome => 'Zu einem anderen Startbildschirm wechseln';

  @override
  String get curreNotHomeBody =>
      'Curre ist gerade nicht dein Startbildschirm. Deine Pläne und dein Verlauf bleiben hier, bis du sie wieder brauchst.';

  @override
  String get switchHomeBody =>
      'Möchtest du eine Weile einen anderen Startbildschirm? Kein Problem. In Android kannst du wählen, welche App sich beim Drücken von Home öffnet. Deine Pläne und dein Verlauf bleiben auf diesem Smartphone und du kannst jederzeit zurückkehren.';

  @override
  String get openHomeScreenSettings => 'Startbildschirm-Einstellungen öffnen';

  @override
  String get chooseHomeScreenApp => 'Startbildschirm-App auswählen';

  @override
  String get homeSettingsPath =>
      'Falls die Smartphone-Einstellungen geöffnet werden, gehe zu Apps, dann Standard-Apps und Start-App.';

  @override
  String get nudgesHelp =>
      'Wähle, welche stillen Hinweise Curre sendet. Wenn du einen ausschaltest, werden auch wartende Hinweise dieser Art abgebrochen.';

  @override
  String get planYourDay => 'Deinen Tag planen';

  @override
  String get eachSessionBegins => 'Zu Beginn jedes Tagesabschnitts';

  @override
  String get morningBegins => 'Einmal täglich zu Beginn deines Morgens';

  @override
  String get afternoonEveningToo => 'Auch nachmittags und abends';

  @override
  String get afternoonEveningBegins =>
      'Auch zu Beginn des Nachmittags und Abends';

  @override
  String get planEnding => 'Plan endet';

  @override
  String get tenMinutesBeforePlan => 'Zehn Minuten vor dem Ende deines Plans';

  @override
  String get appTimeUp => 'App-Zeit vorbei';

  @override
  String get hiddenAppTimeEnds =>
      'Wenn die Zeit einer ausgeblendeten App abläuft';

  @override
  String get addProofLater => 'Einige Minuten nach dem Ende deines Plans';

  @override
  String get focusEnds => 'Fokus endet';

  @override
  String get focusEndsMorning => 'Am Morgen, an dem dein Fokus endet';

  @override
  String get turnAllNudgesOff => 'Alle stillen Hinweise ausschalten';

  @override
  String get turnAllNudgesOn => 'Alle stillen Hinweise einschalten';

  @override
  String get gentle => 'Sanft';

  @override
  String get balanced => 'Ausgewogen';

  @override
  String get strict => 'Streng';

  @override
  String get strictnessBody =>
      'Wenn du eine ausgeblendete App zurückholst, prüft Curre deinen Grund. Je strenger die Einstellung, desto klarer muss dein Grund vor dem Öffnen sein.';

  @override
  String get hiddenChoiceNone => 'Keine. Alle Apps öffnen wie gewohnt.';

  @override
  String get hiddenChoiceOne => '1 App. Nur sie fragt „Warum jetzt?“.';

  @override
  String hiddenChoiceMany(int count) {
    return '$count Apps. Nur diese fragen „Warum jetzt?“.';
  }

  @override
  String get missedNotifications => 'Verpasste Mitteilungen';

  @override
  String missedFromHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitteilungen von ausgeblendeten Apps',
      one: '1 Mitteilung von ausgeblendeten Apps',
    );
    return '$_temp0';
  }

  @override
  String heldUntilAppBack(int count) {
    return '$count zurückgehalten, bis ihre App wieder da ist';
  }

  @override
  String bringBackApp(String app) {
    return '$app zurückholen';
  }

  @override
  String get restDayTheyOpen => 'Ruhetag: Sie öffnen ohne Nachfrage';

  @override
  String get nothingHidden =>
      'Nichts ist ausgeblendet. Alle Apps öffnen wie gewohnt unter Alle Apps.';

  @override
  String get hiddenAppsOut =>
      'Deine ausgeblendeten Apps sind für deinen Plan oder für eine Weile verfügbar.';

  @override
  String get hideAnotherApp => 'Weitere App ausblenden';

  @override
  String notificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitteilungen',
      one: '1 Mitteilung',
    );
    return '$_temp0';
  }

  @override
  String get hiddenAppsTip =>
      'Hier warten nur Apps, die du ausgeblendet hast. Tippe auf eine, um sie eine Weile zurückzuholen.';

  @override
  String get gotIt => 'Verstanden';

  @override
  String get appOpenFailed =>
      'Die App wurde nicht geöffnet. Vielleicht ist sie nicht mehr installiert.';

  @override
  String get missedNotificationsBody =>
      'Still zurückgehalten, solange ihre Apps ausgeblendet waren, und bei der Rückkehr der App wiedergegeben. Nichts verlässt dieses Smartphone.';

  @override
  String get nothingHeld => 'Gerade wird nichts zurückgehalten.';

  @override
  String get held => 'Zurückgehalten';

  @override
  String get givenBack => 'Wiedergegeben';

  @override
  String openNotificationApp(String app) {
    return '$app öffnen';
  }

  @override
  String get openCurreAppInfo => 'Curre-App-Info öffnen';

  @override
  String get openSettingsAppsCurre =>
      'Öffne die Smartphone-Einstellungen, dann Apps und Curre.';

  @override
  String get restrictedStillOff =>
      'Noch immer deaktiviert. Das ist in Ordnung, Curre funktioniert auch ohne diesen Zugriff. Falls Android die Einstellung als eingeschränkt bezeichnet, erlaube sie einmal:';

  @override
  String get restrictedHelp =>
      'Falls Android die Einstellung als eingeschränkt bezeichnet, erlaube sie einmal:';

  @override
  String get restrictedStepOne => 'Öffne die Curre-App-Info.';

  @override
  String get restrictedStepTwo => 'Tippe oben rechts auf die drei Punkte.';

  @override
  String get restrictedStepThree =>
      'Tippe auf „Eingeschränkte Einstellungen zulassen“.';

  @override
  String get restrictedStepFour => 'Bestätige mit PIN oder Fingerabdruck.';

  @override
  String get restrictedStepFive =>
      'Kehre hierher zurück und aktiviere den Zugriff.';

  @override
  String get noProblemSettings =>
      'Kein Problem. Diese Option bleibt jederzeit in den Curre-Einstellungen.';

  @override
  String get allSet => 'Alles bereit.';

  @override
  String get usageAccessAllSet =>
      'Curre fragt beim Öffnen einer ausgeblendeten App „Warum jetzt?“.';

  @override
  String get notificationAccessAllSet =>
      'Ausgeblendete Apps bleiben still, bis du sie zurückholst.';

  @override
  String get askWhyPrompt =>
      'Beim Öffnen einer ausgeblendeten App „Warum jetzt?“ fragen?';

  @override
  String get quietPrompt => 'Ausgeblendete Apps still halten?';

  @override
  String get askWhyPromptBody =>
      'Ausgeblendete Apps können über zuletzt verwendete Apps, Links oder Mitteilungen zurückkommen. Curre kann dann ebenfalls fragen. Es prüft nur, welche App geöffnet wurde, nie den Bildschirminhalt.';

  @override
  String get tryAgainAccess => 'Erneut versuchen';

  @override
  String get hiddenNamesFallback => 'die Apps, die du ausblendest';

  @override
  String hiddenNamesTwo(String first, String second) {
    return '$first und $second';
  }

  @override
  String hiddenNamesMore(String first, String second, int count) {
    return '$first, $second und $count weitere';
  }

  @override
  String quietPromptBody(String apps) {
    return 'Curre kann Mitteilungen von $apps still zurückhalten und beim Öffnen der App alle wiedergeben. Andere Apps benachrichtigen wie gewohnt, und Anrufe und Wecker kommen immer durch.';
  }

  @override
  String get focusPurposeExams => 'Prüfungen';

  @override
  String get focusPurposeDeadline => 'Eine Frist';

  @override
  String get focusPurposeHabit => 'Eine Gewohnheit ändern';

  @override
  String get focusPurposeOther => 'Etwas anderes';

  @override
  String get focusHintExams => 'Meine Matheprüfung bestehen';

  @override
  String get focusHintDeadline => 'Das Portfolio fertigstellen';

  @override
  String get focusHintHabit => 'Im Bett keine sozialen Apps öffnen';

  @override
  String get focusHintOther => 'Was ich ändern möchte';

  @override
  String get focusEndExams =>
      'Du hast Raum für die wichtige Arbeit geschaffen.';

  @override
  String get focusEndDeadline => 'Du hast diese Arbeit bis ins Ziel gebracht.';

  @override
  String get focusEndHabit =>
      'Du hast der neuen Gewohnheit Raum zum Wachsen gegeben.';

  @override
  String get focusEndOther =>
      'Du bist immer wieder zum Wichtigen zurückgekehrt.';

  @override
  String get focusLengthWeek => '1 Woche';

  @override
  String get focusLengthTwoWeeks => '2 Wochen';

  @override
  String get focusLengthThreeWeeks => '3 Wochen';

  @override
  String get focusLengthThirtyDays => '30 Tage';

  @override
  String get focusGoalLabel => 'Dein Ziel in wenigen Worten (optional)';

  @override
  String get untilWhen => 'Bis wann?';

  @override
  String get pickDate => 'Datum auswählen';

  @override
  String focusEndsSummary(String date, String days) {
    return 'Endet am $date, in $days. Du kannst es später ändern.';
  }

  @override
  String get focusEndsOn => 'Fokus endet am';

  @override
  String get focusSaveFailed =>
      'Curre konnte deinen Fokus nicht speichern. Versuche es erneut.';

  @override
  String get focusQuestion => 'Wofür ist dieser Fokus?';

  @override
  String get focusPickerBody =>
      'Curre hilft am meisten über einen Zeitraum mit Ende: Prüfungen, eine Frist oder eine Gewohnheit, die du ändern möchtest.';

  @override
  String get pickFocusPurpose => 'Wähle den Zweck';

  @override
  String get startMyFocus => 'Meinen Fokus starten';

  @override
  String get setFocusQuestion => 'Einen Fokus festlegen?';

  @override
  String get focusOfferBody =>
      'Curre hilft am meisten über einen Zeitraum mit Ende: Prüfungen, eine Frist oder eine Gewohnheit. Wähle einen Zweck und das Ende.';

  @override
  String get maybeLater => 'Vielleicht später';

  @override
  String get setFocus => 'Fokus festlegen';

  @override
  String get restDay => 'Ruhetag';

  @override
  String get yourFocus => 'Dein Fokus';

  @override
  String get restDayBody =>
      'Heute öffnen ausgeblendete Apps ohne Nachfrage, ihre Mitteilungen kommen durch und Hinweise bleiben still. Deine Nachweistage sind sicher. Morgen geht es weiter.';

  @override
  String focusLeft(String days, String date) {
    return 'Noch $days · endet am $date';
  }

  @override
  String get backToFocusNow => 'Jetzt zum Fokus zurück';

  @override
  String get takeTodayOff => 'Heute freinehmen';

  @override
  String nextRestDay(String date) {
    return 'Nächster Ruhetag: $date';
  }

  @override
  String get today => 'heute';

  @override
  String get tomorrow => 'morgen';

  @override
  String get takeTodayOffQuestion => 'Heute freinehmen?';

  @override
  String get takeTodayOffBody =>
      'Bis morgen früh öffnen ausgeblendete Apps ohne Nachfrage, ihre Mitteilungen kommen durch und Curre sendet keine Hinweise. Deine Nachweistage sind sicher. Du kannst einen Ruhetag pro Woche nehmen.';

  @override
  String get keepGoing => 'Weitermachen';

  @override
  String get enjoyRestDay => 'Genieß deinen Ruhetag. Morgen geht es weiter.';

  @override
  String focusSummaryDays(String days) {
    return '$days Fokus.';
  }

  @override
  String focusSummaryWithRest(String days, String rests) {
    return '$days Fokus, $rests.';
  }

  @override
  String restDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ruhetage',
      one: '1 Ruhetag',
    );
    return '$_temp0';
  }

  @override
  String get daysWithProof => 'Tage mit Nachweis';

  @override
  String get tasksProved => 'nachgewiesene Aufgaben';

  @override
  String get hiddenAppsLeftClosed => 'ausgeblendete Apps geschlossen gelassen';

  @override
  String get startAnotherFocus => 'Weiteren Fokus starten';

  @override
  String get oldHomeScreen => 'Zu meinem alten Startbildschirm zurück';

  @override
  String get focusHistoryStays =>
      'Dein Verlauf und deine Nachweistage bleiben in beiden Fällen auf diesem Smartphone.';

  @override
  String get chooseOldHome =>
      'Wähle deinen alten Startbildschirm in der Liste. Curre fragt nicht mehr nach und lässt alle Mitteilungen durch.';

  @override
  String get tapOldHome =>
      'Tippe auf „Start-App“ und wähle deinen alten Startbildschirm.';

  @override
  String get searchOldHome =>
      'Die Einstellungen wurden geöffnet. Suche nach „Start-App“ und wähle deinen alten Startbildschirm.';

  @override
  String get openSettingsOldHome =>
      'Öffne die Smartphone-Einstellungen, suche nach „Start-App“ und wähle dort deinen alten Startbildschirm.';

  @override
  String get noFocusSet => 'Kein Fokus festgelegt';

  @override
  String get focusSettingsEmpty =>
      'Wähle, wofür dieser Zeitraum da ist und wann er endet.';

  @override
  String focusEndedOn(String date) {
    return 'Am $date beendet. Sieh dir das Ergebnis auf dem Startbildschirm an.';
  }

  @override
  String focusEndsLeft(String date, String days) {
    return 'Endet am $date, noch $days';
  }

  @override
  String get changeEndDate => 'Enddatum ändern';

  @override
  String weeklyRestNext(String date) {
    return 'Ein Ruhetag pro Woche. Nächster: $date.';
  }

  @override
  String get endFocusNow => 'Fokus jetzt beenden';

  @override
  String focusNowEnds(String date) {
    return 'Dein Fokus endet jetzt am $date.';
  }

  @override
  String get endFocusQuestion => 'Deinen Fokus jetzt beenden?';

  @override
  String get endFocusBody =>
      'Der Startbildschirm zeigt das Ergebnis, danach entscheidest du, wie es weitergeht. Dein Verlauf und deine Nachweistage bleiben erhalten.';

  @override
  String get endFocus => 'Fokus beenden';

  @override
  String get historySubtitle => 'Die letzten 30 Tage · nur auf diesem Handy';

  @override
  String get whatHappened => 'Was passiert ist';

  @override
  String get historyEmptyTitle => 'Ein ruhiger Anfang.';

  @override
  String get historyEmptyBody =>
      'Deine Pläne und zurückgeholten Apps erscheinen hier. Alles bleibt auf diesem Handy.';

  @override
  String plannedSessionsCount(int count) {
    return '$count von 21 geplant';
  }

  @override
  String get historyOverviewHelp =>
      'Jedes Feld steht für einen Morgen, Nachmittag oder Abend der letzten 7 Tage. Ausgefüllte Felder begannen mit einem Plan.';

  @override
  String sessionPlanState(String session, String state) {
    return '$session: $state';
  }

  @override
  String get planned => 'geplant';

  @override
  String get noPlan => 'ohne Plan';

  @override
  String proofCloudInHand(String detail) {
    return 'Du hast einen Wolkentag. $detail';
  }

  @override
  String get oneMoreProofToCloud =>
      'Noch 1 Nachweistag bis zu deinem nächsten Wolkentag.';

  @override
  String moreProofToCloud(int count) {
    return 'Noch $count Nachweistage bis zu deinem nächsten Wolkentag.';
  }

  @override
  String proofDaysInAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'insgesamt $count Nachweistage',
      one: 'insgesamt 1 Nachweistag',
    );
    return '$_temp0';
  }

  @override
  String bestRunCount(int count) {
    return 'Beste Folge $count';
  }

  @override
  String cloudDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wolkentage',
      one: '1 Wolkentag',
    );
    return '$_temp0';
  }

  @override
  String get historyProofHint =>
      'Sag nach einer Aufgabe, was sich geändert hat. Eine konkrete Notiz fügt einen Nachweistag hinzu.';

  @override
  String historySessionPlan(String session) {
    String _temp0 = intl.Intl.selectLogic(session, {
      'morning': 'Morgenplan',
      'afternoon': 'Nachmittagsplan',
      'evening': 'Abendplan',
      'other': 'Plan',
    });
    return '$_temp0';
  }

  @override
  String endedEarlyAt(String ended, String planned) {
    return 'Um $ended vorzeitig beendet, geplant bis $planned';
  }

  @override
  String waitedDuration(String duration) {
    return '$duration gewartet';
  }

  @override
  String whyNowApp(String app) {
    return 'Warum jetzt? · $app';
  }

  @override
  String get olderReasonMissing =>
      'Der Grund wurde in diesem älteren Eintrag nicht gespeichert.';

  @override
  String appCameBack(String app) {
    return '$app kam zurück';
  }

  @override
  String minutesShort(int count) {
    return '$count Min.';
  }

  @override
  String openedAfterWaiting(String duration) {
    return 'Nach $duration Wartezeit geöffnet';
  }

  @override
  String get openedFromLater =>
      'Für später aufgehoben und aus einem Plan geöffnet';

  @override
  String get supportedProof => 'Gestützter Nachweis';

  @override
  String get waitingToBeChecked => 'Wird noch geprüft';

  @override
  String get markedDone => 'Als erledigt markiert';

  @override
  String get noNote => 'Keine Notiz';

  @override
  String get personalDetailHidden => 'Persönliche Angabe ausgeblendet';

  @override
  String get outcomeOpened => 'Geöffnet';

  @override
  String get outcomeNotNow => 'Nicht jetzt';

  @override
  String get outcomeNeededDetail => 'Mehr Details nötig';

  @override
  String get outcomeNotReason => 'Kein Grund';

  @override
  String get outcomeCouldNotCheck => 'Prüfung nicht möglich';

  @override
  String get nextSunriseOneProof => 'Nächster Sonnenaufgang: noch ein Nachweis';

  @override
  String get noProofDaysYet => 'Noch keine Nachweistage';

  @override
  String proofDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nachweistage',
      one: '1 Nachweistag',
    );
    return '$_temp0';
  }

  @override
  String get todaysSunIsUp => 'die heutige Sonne ist aufgegangen';

  @override
  String get oneCloudInHand => 'ein Wolkentag verfügbar';

  @override
  String get cloudDay => 'Wolkentag';

  @override
  String runEndedAt(String days) {
    return 'Diese Folge endete bei $days.';
  }

  @override
  String get todaysProofStartsNext =>
      'Der heutige Nachweis beginnt den nächsten Sonnenaufgang.';

  @override
  String get theNextSunrise => 'Der nächste Sonnenaufgang';

  @override
  String get dayProof => 'Nachweistag';

  @override
  String get dayPending => 'Notiz wird noch geprüft';

  @override
  String get dayNoProof => 'kein Nachweis';

  @override
  String get dayCloud => 'Wolkentag';

  @override
  String get dayToday => 'heute';

  @override
  String get dayFuture => 'kommt noch';

  @override
  String get dayStillOpen => 'noch offen';

  @override
  String get startingToday => 'Beginnt heute';

  @override
  String proofRunRange(String start, String end) {
    return '$start bis $end';
  }

  @override
  String sinceDate(String date) {
    return 'Seit $date';
  }

  @override
  String get milestoneSeven =>
      'Sieben Nachweistage: Deine Strahlen enden jetzt in Funken.';

  @override
  String get milestoneTwentyOne =>
      '21 Nachweistage: Ein Lichtring steht nun hinter deiner Sonne.';

  @override
  String get milestoneFifty =>
      '50 Nachweistage: Deine Sonne trägt einen zweiten Ring.';

  @override
  String get cloudDayKeepsRun =>
      'Wenn ein Tag ohne Nachweis vergeht, hält er deine Folge am Laufen.';

  @override
  String weekdaySunUp(String weekday) {
    return 'Die Sonne am $weekday ist aufgegangen';
  }

  @override
  String earnedCloudDay(String detail) {
    return 'Du hast einen Wolkentag verdient. $detail';
  }

  @override
  String get completionQuestion =>
      'Was hat sich verändert, was wurde fertig oder klar?';

  @override
  String get oneSentenceEnough => 'Ein Satz genügt';

  @override
  String get addOneDetail => 'Füge ein Detail hinzu';

  @override
  String get addWhatChanged => 'Ergänze, was sich geändert hat';

  @override
  String proofMismatchPrompt(String detail) {
    return '„$detail“ passt nicht zu deiner geplanten Aufgabe. Was hat sich verändert, was wurde fertig oder klar?';
  }

  @override
  String get proofFuturePrompt =>
      'Das klingt nach dem nächsten Schritt. Was hat sich verändert, was wurde fertig oder klar?';

  @override
  String get proofUnrelatedPrompt =>
      'Sag, wie es mit deinem Plan zusammenhängt. Was hat sich verändert, was wurde fertig oder klar?';

  @override
  String get proofDetailPrompt =>
      'Ein Name, eine Zahl oder ein Schritt genügt. Was hat sich verändert, was wurde fertig oder klar?';

  @override
  String get justMarkDone => 'Nur als erledigt markieren';

  @override
  String get readingYourNote => 'Deine Notiz wird gelesen';

  @override
  String get readingYourNoteProgress => 'Deine Notiz wird gelesen…';

  @override
  String get noteSaved => 'Deine Notiz ist gespeichert';

  @override
  String get noteSavedBody =>
      'Sie konnte gerade nicht geprüft werden. Das geschieht, sobald du wieder online bist.';

  @override
  String get runSafeWhileWaiting =>
      'Deine Folge bleibt während der Wartezeit sicher.';

  @override
  String get markedAsDone => 'Als erledigt markiert';

  @override
  String get markedDoneBody =>
      'Es steht in deinem Verlauf. Nachweistage entstehen aus einer Notiz darüber, was sich geändert hat.';

  @override
  String get noteCountsAsProof => 'Deine Notiz zählt als Nachweis.';

  @override
  String get oneMoreRay => 'Ein Strahl mehr';

  @override
  String get proofAdded => 'Nachweis hinzugefügt';

  @override
  String get profileSmiling => 'Dein Profil lächelt';

  @override
  String get sunOneRay =>
      'Die heutige Sonne, ein Strahl: eine Aufgabe mit Nachweis';

  @override
  String sunManyRays(int count) {
    return 'Die heutige Sonne, $count Strahlen: $count Aufgaben mit Nachweis';
  }

  @override
  String proofDayUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nachweistage',
      one: 'Nachweistag',
    );
    return '$_temp0';
  }

  @override
  String get newRunStarts => 'Hier beginnt eine neue Folge.';

  @override
  String get supported => 'Gestützt';

  @override
  String get backedByStart =>
      'Gestützt durch den Aufgabenstart und deine Notiz';

  @override
  String get backedByApp => 'Gestützt durch die geöffnete App und deine Notiz';

  @override
  String get voicePermissionExplanation =>
      'Curre hört nur zu, während du das Mikrofon hältst oder antippst. Deine Stimme verlässt dein Handy nie.';

  @override
  String get voiceMicNeeded =>
      'Die Spracheingabe braucht das Mikrofon. Du kannst auch tippen.';

  @override
  String get voiceCouldNotStart =>
      'Die Spracheingabe konnte nicht starten. Du kannst auch tippen.';

  @override
  String get voiceGettingReady =>
      'Die Spracheingabe wird vorbereitet. Du kannst solange tippen.';

  @override
  String get voiceReadyOffline =>
      'Bereit. Die Spracheingabe funktioniert jetzt offline.';

  @override
  String get voiceMicStillOff =>
      'Das Mikrofon ist noch aus. Erlaube es zum Sprechen oder tippe.';

  @override
  String get voiceNothingHeard =>
      'Ich habe nichts verstanden. Versuch es etwas näher am Mikrofon noch einmal.';

  @override
  String get voicePrivacyLine =>
      'Auf diesem Handy · nichts Gesagtes wird gespeichert oder gesendet';

  @override
  String get typeInstead => 'Stattdessen tippen';

  @override
  String get gettingVoiceReady => 'Spracheingabe wird vorbereitet';

  @override
  String downloadNowSize(String size) {
    return 'Jetzt herunterladen · $size';
  }

  @override
  String get speakInsteadTyping => 'Sprechen statt tippen';

  @override
  String get allowMic => 'Mikrofon erlauben';

  @override
  String get micOffForCurre => 'Das Mikrofon ist für Curre aus';

  @override
  String micSettingsBody(String privacy) {
    return 'Aktiviere das Mikrofon für Curre in den Handy-Einstellungen und komm zurück. $privacy';
  }

  @override
  String get openPhoneSettings => 'Handy-Einstellungen öffnen';

  @override
  String get tapOrHoldMic => 'Tippe oder halte das Mikrofon und sprich.';

  @override
  String get listeningHeld => 'Ich höre zu… loslassen, wenn du fertig bist.';

  @override
  String get listeningPause =>
      'Ich höre zu… mach eine Pause oder tippe das Mikrofon, wenn du fertig bist.';

  @override
  String get writingSaid => 'Gesagtes wird aufgeschrieben';

  @override
  String get writingProgress => 'Wird aufgeschrieben…';

  @override
  String get voiceStartFailed => 'Die Spracheingabe konnte nicht starten';

  @override
  String get micStartFailed => 'Das Mikrofon startete nicht';

  @override
  String voiceModelFix(String size) {
    return 'Ein erneuter Download der Sprachdateien ($size) behebt das meistens.';
  }

  @override
  String get voiceMicBusy =>
      'Wenn eine andere App das Mikrofon nutzt, schließe sie und versuche es erneut.';

  @override
  String get downloadAgain => 'Erneut herunterladen';

  @override
  String voiceAmount(String received, String total) {
    return '$received von $total';
  }

  @override
  String get voiceStatusReady => 'Bereit · funktioniert offline';

  @override
  String voiceStatusGetting(int percent, String amount) {
    return 'Vorbereitung $percent % · $amount';
  }

  @override
  String voiceWaitingWifi(String extra) {
    return 'Warten auf WLAN$extra';
  }

  @override
  String voiceWaitingConnection(String extra) {
    return 'Warten auf eine Verbindung$extra';
  }

  @override
  String voiceWaitingBattery(String extra) {
    return 'Warten auf mehr Akku$extra';
  }

  @override
  String voiceStatusExtra(String amount) {
    return ' · bisher $amount';
  }

  @override
  String voiceStoppedStorage(String size) {
    return 'Gestoppt · dein Handy braucht $size freien Speicher';
  }

  @override
  String voiceStoppedLater(String extra) {
    return 'Gestoppt · später neuer Versuch$extra';
  }

  @override
  String voiceNotOnPhone(String size) {
    return 'Nicht auf diesem Handy · $size bei der nächsten Mikrofonnutzung';
  }

  @override
  String get voiceUnavailable => 'Auf diesem Handy nicht verfügbar';

  @override
  String get voiceDownload => 'Sprachdateien-Download';

  @override
  String voiceKeepsGoing(String amount) {
    return '$amount. Läuft weiter, wenn du das hier schließt.';
  }

  @override
  String voiceDownloadsWifi(String size) {
    return 'Wird einmal automatisch über WLAN geladen: $size.';
  }

  @override
  String get voiceNoConnection =>
      'Gerade keine Verbindung. Später geht es an derselben Stelle weiter.';

  @override
  String get voiceWaitBattery => 'Wartet auf mehr Akku oder ein Ladegerät.';

  @override
  String voiceNoSpace(String size) {
    return 'Dein Handy hat zu wenig Platz. Die Spracheingabe braucht $size freien Speicher.';
  }

  @override
  String get voiceDamaged =>
      'Eine Datei war beschädigt und wurde gelöscht. Versuch es erneut.';

  @override
  String get voiceFilesUnreachable =>
      'Die Sprachdateien sind nicht erreichbar. Versuch es später noch einmal.';

  @override
  String voiceRunsHere(String size) {
    return 'Die Spracheingabe läuft auf diesem Handy und braucht einmalig $size.';
  }

  @override
  String get stopAndWrite => 'Stoppen und aufschreiben';

  @override
  String get startListening => 'Zuhören starten';

  @override
  String get removeVoiceQuestion => 'Sprachdateien entfernen?';

  @override
  String removeVoiceBody(String size) {
    return 'Das gibt $size frei. Die Spracheingabe lädt sie erst bei der nächsten Mikrofonnutzung oder nach dem Einschalten hier erneut.';
  }

  @override
  String get keepFiles => 'Behalten';

  @override
  String get remove => 'Entfernen';

  @override
  String get voiceFilesRemoved => 'Sprachdateien entfernt.';

  @override
  String get voiceFilesRemoveFailed =>
      'Die Sprachdateien konnten nicht entfernt werden.';

  @override
  String get voiceOnPhone => 'Sprache: auf diesem Handy';

  @override
  String get voiceSettingsBody =>
      'Die Spracheingabe braucht kein Konto und nach dem Download kein Internet. Nichts Gesagtes wird gespeichert oder gesendet.';

  @override
  String get downloadMobile => 'Sprachdateien über mobile Daten laden';

  @override
  String mobileOffHelp(String size) {
    return 'Aus: wartet auf WLAN. Einmalig etwa $size.';
  }

  @override
  String get downloadVoiceFiles => 'Sprachdateien herunterladen';

  @override
  String get removeVoiceFiles => 'Sprachdateien entfernen';

  @override
  String get sceneStory =>
      'Spät am Abend zieht ein Handy voller Beiträge einen Zettel mit „nur kurz die Buszeit prüfen“ in ein Wollknäuel, während die Sonne noch schläft.';

  @override
  String get sceneBusTime => 'Nur kurz die Buszeit prüfen';

  @override
  String get sceneMagnetEmpty =>
      'Ein Magnet wartet auf die Apps, die dich hineinziehen.';

  @override
  String sceneMagnetApps(String apps) {
    return 'Ein Magnet zieht $apps an.';
  }

  @override
  String get sceneInitial => 'Dein Anfangsbuchstabe winkt dir zu.';

  @override
  String get sceneFace => 'Das gewählte Gesicht winkt dir zu.';

  @override
  String get sceneHome =>
      'Ein Handy zeigt Curres ruhigen Startbildschirm: eine Begrüßung, einen Plan und zwei Apps, die direkt bei der Aufgabe öffnen.';

  @override
  String get goodMorning => 'Guten Morgen';

  @override
  String goodMorningName(String name) {
    return 'Guten Morgen, $name';
  }

  @override
  String sceneSearch(String query) {
    return '→ „$query“ suchen';
  }

  @override
  String miniAllApps(String count) {
    return 'Alle Apps · $count';
  }

  @override
  String get scenePlan =>
      'Die Sonne ist aufgegangen und du winkst Peek guten Morgen.';

  @override
  String onboardingStep(int step, int total) {
    return 'Schritt $step von $total';
  }

  @override
  String get nothingHiddenYet =>
      'Noch ist nichts ausgeblendet. Alle Apps öffnen sich wie gewohnt.';

  @override
  String hiddenSummaryOne(String name) {
    return 'Ausgeblendet: $name. Alle anderen Apps öffnen sich wie gewohnt.';
  }

  @override
  String hiddenSummaryMany(String names) {
    return 'Ausgeblendet: $names. Alle anderen Apps öffnen sich wie gewohnt.';
  }

  @override
  String hiddenSummaryMore(String names, int count) {
    return '$names und $count weitere';
  }

  @override
  String get taskExampleLearn => 'Etwas lernen, etwa einen Gitarrenakkord';

  @override
  String get taskExampleFindWay => 'Einen Weg finden';

  @override
  String get taskExampleReply => 'Jemandem antworten';

  @override
  String get taskExampleTextBack => 'Auf eine Nachricht antworten';

  @override
  String get taskExamplePlaylist => 'Eine Playlist abspielen';

  @override
  String get taskExampleLookUp => 'Etwas nachschlagen';

  @override
  String get taskExampleEmail => 'Eine E-Mail beantworten';

  @override
  String get taskExampleToday => 'Nachsehen, was heute ansteht';

  @override
  String get taskExampleWrite => 'Etwas notieren';

  @override
  String get taskExamplePhoto => 'Ein Foto finden';

  @override
  String get taskExampleFile => 'Eine Datei öffnen';

  @override
  String get taskExampleMessage => 'Auf eine Nachricht antworten';

  @override
  String get taskExampleEpisode => 'Eine Folge ansehen';

  @override
  String get taskExampleGroup => 'Eine Gruppe ansehen';

  @override
  String get taskExampleVideo => 'Ein Video posten';

  @override
  String get taskExamplePost => 'Etwas posten';

  @override
  String get taskExampleThread => 'Einen Thread lesen';

  @override
  String get taskExampleIdea => 'Eine Idee finden';

  @override
  String get taskExampleFriend => 'Einem Freund antworten';

  @override
  String get doorActionSearch => 'Suchen';

  @override
  String get doorActionDraft => 'Entwurf';

  @override
  String get doorActionNewEvent => 'Neuer Termin';

  @override
  String get openAppGeneric => 'App öffnen';

  @override
  String get openAppWith => 'App öffnen mit';

  @override
  String laterSavedSemantics(String app, String reason, String destination) {
    return '$app, für später aufgehoben: $reason. Öffnet $destination';
  }

  @override
  String get chooseProfileAvatar => 'Profilbild auswählen';

  @override
  String profileAvatarNumber(int number) {
    return 'Profilbild $number';
  }

  @override
  String profileAvatarSelected(int number) {
    return 'Profilbild $number, ausgewählt';
  }

  @override
  String get customProfileAvatar => 'Eigenes Profilbild';

  @override
  String avatarProofToday(String label) {
    return '$label, heute mit Nachweis';
  }

  @override
  String avatarSleepy(String label) {
    return '$label, schläfrig';
  }

  @override
  String profileInitial(String letter) {
    return 'Anfangsbuchstabe $letter';
  }

  @override
  String profileInitialProof(String letter) {
    return 'Anfangsbuchstabe $letter, heute mit Nachweis';
  }

  @override
  String get profileDefaultInitial => 'Profil-Anfangsbuchstabe';

  @override
  String get profileDefaultInitialProof =>
      'Profil-Anfangsbuchstabe, heute mit Nachweis';

  @override
  String get channelAppTime => 'App-Zeit';

  @override
  String get channelAppTimeBody =>
      'Zeigt die verbleibende App-Zeit und wann die App wieder ausgeblendet wird.';

  @override
  String get channelCheckins => 'Plane deinen Tag';

  @override
  String get channelCheckinsBody =>
      'Eine sanfte Erinnerung, Morgen, Nachmittag und Abend zu planen.';

  @override
  String get channelPlans => 'Plan-Erinnerungen';

  @override
  String get channelPlansBody => 'Ein ruhiger Hinweis, bevor dein Plan endet.';

  @override
  String get channelProof => 'Nachweis-Erinnerungen';

  @override
  String get channelProofBody =>
      'Erinnert dich nach einem Plan daran, Erledigtes zu notieren.';

  @override
  String get channelFocus => 'Fokuszeit';

  @override
  String get channelFocusBody =>
      'Schau am letzten Tag deiner Fokuszeit, wie es gelaufen ist.';

  @override
  String get nameExample => 'Ada';

  @override
  String appDidNotOpenThere(String app) {
    return '$app wurde dort nicht geöffnet. Deine Zeit läuft weiter; versuch es vom Startbildschirm aus.';
  }

  @override
  String get sceneGChord => 'G-Dur-Akkord';

  @override
  String get sceneWorship => 'Lobpreis';
}
