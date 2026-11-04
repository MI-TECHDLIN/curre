// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Curre';

  @override
  String get systemLanguage => 'Langue du téléphone';

  @override
  String get language => 'Langue';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageSpanish => 'Espagnol';

  @override
  String get languageFrench => 'Français';

  @override
  String get languagePortuguese => 'Portugais';

  @override
  String get languageGerman => 'Allemand';

  @override
  String get back => 'Retour';

  @override
  String get close => 'Fermer';

  @override
  String get cancel => 'Annuler';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get done => 'Terminé';

  @override
  String get edit => 'Modifier';

  @override
  String get save => 'Enregistrer';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get checking => 'Vérification…';

  @override
  String get on => 'Activé';

  @override
  String get off => 'Désactivé';

  @override
  String get sessionMorning => 'matinée';

  @override
  String get sessionAfternoon => 'après-midi';

  @override
  String get sessionEvening => 'soirée';

  @override
  String goodSession(String session) {
    return 'Bonne $session';
  }

  @override
  String goodSessionName(String session, String name) {
    return 'Bonne $session, $name';
  }

  @override
  String planThisSession(String session) {
    return 'Planifier cette $session';
  }

  @override
  String planYourSession(String session) {
    return 'Planifier votre $session';
  }

  @override
  String whatsThisSessionFor(String session) {
    return 'À quoi servira cette $session ?';
  }

  @override
  String setMySession(String session) {
    return 'Préparer ma $session';
  }

  @override
  String get phone => 'Téléphone';

  @override
  String get messages => 'Messages';

  @override
  String get androidSettings => 'Réglages';

  @override
  String get curreSettings => 'Réglages de Curre';

  @override
  String get allApps => 'Toutes les apps';

  @override
  String get allAppsDescription =>
      'Toutes les apps que vous n’avez pas masquées, prêtes à s’ouvrir.';

  @override
  String get hiddenApps => 'Apps masquées';

  @override
  String hiddenAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps masquées',
      one: '1 app masquée',
      zero: 'Aucune app masquée',
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
      other: '$count secondes',
      one: '1 seconde',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get couldNotReadApps => 'Impossible de lire vos apps';

  @override
  String get couldNotReadAppsBody =>
      'Curre n’a pas pu lire les apps installées sur ce téléphone. Réessayez pour afficher vos vraies apps.';

  @override
  String get readingApps => 'Lecture des apps…';

  @override
  String get profileAvatar => 'Avatar du profil';

  @override
  String get openProfile => 'Ouvrir le profil';

  @override
  String get gettingReady => 'Préparation en cours…';

  @override
  String get gettingReadyBody => 'Cela peut prendre quelques secondes de plus.';

  @override
  String get checkinHint => 'Dites ou écrivez ce que vous voulez accomplir.';

  @override
  String get sayItInstead => 'Le dire à voix haute';

  @override
  String get planning => 'Création de votre plan…';

  @override
  String get planningSemantics => 'Choix des apps pour votre plan';

  @override
  String get chooseAppsYourself => 'Choisissez vous-même les apps';

  @override
  String get chooseAppsBody =>
      'Curre n’a pas pu créer ce plan en ligne. Choisissez les apps nécessaires et continuez.';

  @override
  String get useThisPlan => 'Utiliser ce plan';

  @override
  String get planReady => 'Votre plan est prêt';

  @override
  String onHomeUntil(String time) {
    return 'Sur l’accueil jusqu’à $time';
  }

  @override
  String get whyNow => 'Pourquoi maintenant ?';

  @override
  String whyNeedAppNow(String app) {
    return 'Pourquoi avez-vous besoin de $app maintenant ?';
  }

  @override
  String get whyNowHelp =>
      'Dites ce que vous allez faire, pour qui et pendant combien de temps. Curre ouvre l’app exactement au bon endroit.';

  @override
  String get yourReason => 'Votre raison';

  @override
  String get reasonHint => 'répondre à Ada au sujet de la répétition';

  @override
  String yourPlan(String plan) {
    return 'Votre plan : $plan';
  }

  @override
  String get oneMoreTry =>
      'Un dernier essai : dites exactement ce que vous allez faire.';

  @override
  String get bringItBack => 'La faire revenir';

  @override
  String get askAgain => 'Redemander';

  @override
  String get readingReason => 'Lecture de votre raison';

  @override
  String get readingReasonProgress => 'Lecture de votre raison…';

  @override
  String guardQuote(String quote) {
    return 'Ces mots ressemblent à une instruction adressée à Curre : « $quote »';
  }

  @override
  String openAfter(String duration) {
    return 'Ouvrir après $duration';
  }

  @override
  String get saveForLater => 'Garder pour plus tard';

  @override
  String appOpensIn(String app) {
    return '$app s’ouvre dans';
  }

  @override
  String appOpensInDuration(String app, String duration) {
    return '$app s’ouvre dans $duration';
  }

  @override
  String get waitUnavailableBody =>
      'Curre n’a pas pu vérifier votre raison ; l’app s’ouvrira donc après une courte attente.';

  @override
  String get waitAllowedBody => 'Vous avez choisi d’attendre, et c’est permis.';

  @override
  String get waitCancelHelp =>
      'Quittez cet écran pour annuler. Si vous attendez, cela apparaîtra dans votre historique.';

  @override
  String outcomeOpenApp(String app) {
    return 'Ouvre $app';
  }

  @override
  String outcomeOpenAt(String destination) {
    return 'Ouvre à $destination';
  }

  @override
  String get outcomeSpecify => 'Qu’allez-vous faire exactement ?';

  @override
  String get outcomeFlagged =>
      'Cela ressemble à une instruction, pas à une raison';

  @override
  String get outcomeUnavailable => 'Impossible de vérifier votre raison';

  @override
  String youHaveMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return 'Vous avez $_temp0.';
  }

  @override
  String chatWith(String person) {
    return 'Discussion avec $person';
  }

  @override
  String openDestination(String destination) {
    return 'Ouvrir $destination';
  }

  @override
  String get savedForNextPlan =>
      'Enregistré. Cela reviendra lors de votre prochain plan.';

  @override
  String get couldNotSave =>
      'Curre n’a pas pu enregistrer cela sur ce téléphone. Réessayez.';

  @override
  String get settingsSubtitle => 'Les changements concernent uniquement Curre.';

  @override
  String todayPercent(int percent) {
    return 'La journée est accomplie à $percent pour cent';
  }

  @override
  String get oneSentenceHome =>
      'Une phrase. Seuls les éléments nommés apparaissent sur l’accueil.';

  @override
  String get yourPlanLabel => 'Votre plan';

  @override
  String get planHint => 'Apprendre l’accord de sol sur YouTube jusqu’à 7 h';

  @override
  String get sayYourPlan => 'Dire votre plan';

  @override
  String get gettingAppsReady => 'Préparation de vos apps…';

  @override
  String get choosingApps => 'Choix des apps';

  @override
  String lookingThroughApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return 'Parcours de $_temp0';
  }

  @override
  String get useTheseApps => 'Utiliser ces apps';

  @override
  String get heresYourPlan => 'Voici votre plan';

  @override
  String get backToHome => 'Retour à l’accueil';

  @override
  String get changePlan => 'Modifier le plan';

  @override
  String get fallbackConnect => 'Connexion impossible pour le moment';

  @override
  String get fallbackTimeout => 'Cela a pris trop de temps';

  @override
  String get fallbackReadPlan => 'Curre n’a pas pu lire ce plan';

  @override
  String get fallbackPlan => 'Curre n’a pas pu créer ce plan';

  @override
  String get fallbackNetworkBody =>
      'Vérifiez votre connexion et réessayez, ou choisissez les apps ci-dessous.';

  @override
  String get fallbackBody =>
      'Réessayez dans un instant, ou choisissez les apps ci-dessous.';

  @override
  String openedHiddenApp(String app) {
    return 'Vous avez ouvert $app. Elle fait partie de vos apps masquées.';
  }

  @override
  String appIsHidden(String app) {
    return '$app fait partie de vos apps masquées.';
  }

  @override
  String openNoChatBody(String app, String minutes) {
    return 'Curre n’a pas trouvé de discussion correspondante sur ce téléphone et ouvre donc $app. $minutes';
  }

  @override
  String laterBody(String duration, String app) {
    return 'Cela ressemble à de la navigation et peut attendre. Gardez-le pour plus tard ou attendez $duration pour ouvrir $app maintenant.';
  }

  @override
  String specifyBody(String duration, String app) {
    return 'Précisez un peu ce que vous allez faire, ou attendez $duration pour ouvrir $app.';
  }

  @override
  String flaggedBody(String app, String duration) {
    return 'Dites plutôt à Curre ce que vous ferez dans $app. Ou attendez $duration pour l’ouvrir.';
  }

  @override
  String unavailableBody(String app, String duration) {
    return 'Aucun souci : $app s’ouvre après $duration d’attente. Vous pouvez aussi réessayer.';
  }

  @override
  String untilAppOpens(String duration, String app) {
    return '$duration avant l’ouverture de $app';
  }

  @override
  String get querySearch => 'Rechercher';

  @override
  String get queryDraft => 'Brouillon';

  @override
  String get queryNewEvent => 'Nouvel événement';

  @override
  String get queryOpenWith => 'Ouvrir l’app avec';

  @override
  String get kindTask => 'Une tâche';

  @override
  String get kindPerson => 'Quelqu’un attend';

  @override
  String get kindTimeSensitive => 'Ne peut pas attendre';

  @override
  String get kindBrowse => 'Simple navigation';

  @override
  String get kindUnclear => 'Pas encore clair';

  @override
  String confidencePercent(String label, int percent) {
    return '$label, confiance de $percent pour cent';
  }

  @override
  String get outcomeGlyphOpen => 'S’ouvre';

  @override
  String get outcomeGlyphLater => 'Pas maintenant';

  @override
  String get outcomeGlyphSpecify => 'Plus de détails nécessaires';

  @override
  String get outcomeGlyphFlagged => 'Ce n’est pas une raison';

  @override
  String get outcomeGlyphUnavailable => 'Vérification impossible';

  @override
  String get alwaysOnHome => 'Toujours sur l’accueil';

  @override
  String get pressHoldApp =>
      'Appuyez longuement sur une app pour l’ouvrir normalement.';

  @override
  String get quietNudgeQuestion =>
      'Un rappel discret quand le temps est écoulé ?';

  @override
  String get quietNudgeBody =>
      'Curre peut vous prévenir à la fin d’un plan ou du temps d’une app. Aucun son, aucune vibration, aucune publicité.';

  @override
  String get quietNudgeYes => 'Oui, me prévenir';

  @override
  String get sayOneSentence =>
      'Dites-le en une phrase. Curre place seulement les apps nécessaires sur l’accueil.';

  @override
  String get planNow => 'Planifier maintenant';

  @override
  String tasksReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tâches prêtes',
      one: '1 tâche prête',
    );
    return '$_temp0';
  }

  @override
  String tasksDone(int done, int count) {
    return '$done sur $count terminées';
  }

  @override
  String yourSession(String session) {
    return 'Votre $session';
  }

  @override
  String untilTime(String time) {
    return 'jusqu’à $time';
  }

  @override
  String get changeThisPlan => 'Modifier ce plan';

  @override
  String get onHomeNow => 'Sur l’accueil maintenant';

  @override
  String get alwaysAppsBelow => 'Vos apps permanentes sont ci-dessous.';

  @override
  String get tapStraightThere => 'Touchez-en une pour y aller directement.';

  @override
  String get nothingPlanned => 'Rien de prévu pour le moment';

  @override
  String get nothingPlannedBody =>
      'Planifiez votre journée et ses apps apparaîtront ici.';

  @override
  String get alwaysAvailable => 'Toujours disponible';

  @override
  String get doneWithProof => 'Terminée, avec preuve';

  @override
  String get doneWaiting => 'Terminée · votre note attend sa vérification';

  @override
  String get doneAddNote => 'Terminée · touchez pour ajouter une note';

  @override
  String get doneToday => 'Terminé aujourd’hui';

  @override
  String get show => 'Afficher';

  @override
  String get hide => 'Masquer';

  @override
  String get todaySunUp => 'Le soleil du jour est levé';

  @override
  String get todaySun => 'Le soleil du jour';

  @override
  String allDoneSession(String session) {
    return 'Tout est fait pour cette $session';
  }

  @override
  String get allDoneBody =>
      'Toutes les tâches de ce plan sont terminées. Vous pouvez l’arrêter et refaire un plan quand vous voulez.';

  @override
  String get endPlanNow => 'Terminer le plan maintenant';

  @override
  String get endPlanQuestion => 'Terminer ce plan maintenant ?';

  @override
  String get endPlanBody =>
      'Ses tâches quittent l’accueil. Vous pourrez refaire un plan quand vous voulez.';

  @override
  String get keepIt => 'Le garder';

  @override
  String get endPlan => 'Terminer le plan';

  @override
  String get planEnded => 'Plan terminé.';

  @override
  String get undo => 'Annuler';

  @override
  String get tapStart => 'Touchez Commencer au début';

  @override
  String get start => 'Commencer';

  @override
  String startedAt(String time) {
    return 'Commencée à $time · touchez à la fin';
  }

  @override
  String get awayFromPhone => 'Hors du téléphone';

  @override
  String get you => 'Vous';

  @override
  String get closeProfile => 'Fermer le profil';

  @override
  String get yourFace => 'Votre visage';

  @override
  String get pickYourFace => 'Choisissez celui qui vous ressemble.';

  @override
  String get useInitial => 'Utiliser mon initiale';

  @override
  String get proofDays => 'Jours avec preuve';

  @override
  String get bestRun => 'Meilleure série';

  @override
  String get cloudDays => 'Jours de repos';

  @override
  String get history => 'Historique';

  @override
  String get yourName => 'Votre nom';

  @override
  String get saveName => 'Enregistrer le nom';

  @override
  String get editName => 'Modifier le nom';

  @override
  String get app => 'App';

  @override
  String get quietNudgeOn =>
      'Les rappels discrets sont activés. Vous pouvez les choisir dans les réglages de Curre.';

  @override
  String get quietNudgeOff =>
      'Aucun souci. Vous pourrez activer les rappels plus tard dans les réglages de Curre.';

  @override
  String planPercent(int percent) {
    return 'Ce plan est accompli à $percent pour cent';
  }

  @override
  String appsReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prêtes',
      one: '1 prête',
    );
    return '$_temp0';
  }

  @override
  String appBackForNow(String app) {
    return '$app est de retour pour le moment';
  }

  @override
  String doneDoorSemantics(String app, String state, String destination) {
    return '$app, $state, ouvre $destination';
  }

  @override
  String tasksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tâches',
      one: '1 tâche',
    );
    return '$_temp0';
  }

  @override
  String doneTodayShow(String count) {
    return 'Terminé aujourd’hui, $count. Afficher';
  }

  @override
  String doneTodayCount(int count) {
    return 'Terminé aujourd’hui · $count';
  }

  @override
  String get endPlanFailed => 'Curre n’a pas pu terminer le plan. Réessayez.';

  @override
  String get planTimeUp => 'Le temps de ce plan est déjà écoulé.';

  @override
  String get doorOpenFailed =>
      'L’app ne s’est pas ouverte. Appuyez longuement dessus pour l’ouvrir normalement.';

  @override
  String copiedSearch(String target) {
    return '« $target » a été copié. Collez-le dans la zone de recherche.';
  }

  @override
  String get addProof => 'Ajouter une preuve';

  @override
  String get snoozeTenMinutes => 'Reporter de 10 min';

  @override
  String get focusDone => 'Votre période de concentration est terminée';

  @override
  String focusDoneNotification(String days) {
    return 'Voyez comment se sont passés ces $days et choisissez la suite.';
  }

  @override
  String sessionAlmostDone(String session) {
    return 'Votre $session est presque terminée';
  }

  @override
  String get planEndsTenMinutes =>
      'Votre plan se termine dans 10 minutes. Choisissez la suite.';

  @override
  String get addYourProof => 'Ajoutez votre preuve';

  @override
  String get proofNotificationBody =>
      'Une courte note sur ce que vous avez accompli compte comme preuve.';

  @override
  String grantOngoingBody(String task) {
    return '$task · L’app sera de nouveau masquée à la fin.';
  }

  @override
  String appHiddenAgain(String app) {
    return '$app est de nouveau masquée';
  }

  @override
  String grantExpiredBody(int minutes, String reason) {
    return 'Vos $minutes min pour $reason sont écoulées.';
  }

  @override
  String get whatDidYouGetDone => 'Qu’avez-vous accompli ?';

  @override
  String get onboardingSaveFailed =>
      'Curre n’a pas pu enregistrer vos réponses sur ce téléphone. Réessayez.';

  @override
  String get welcomeCurre => 'Bienvenue dans Curre';

  @override
  String get aboutYou => 'À propos de vous';

  @override
  String get yourApps => 'Vos apps';

  @override
  String get yourHomeScreen => 'Votre écran d’accueil';

  @override
  String get yourFirstPlan => 'Votre premier plan';

  @override
  String get onboardingWelcomeQuestion =>
      'Vous prenez votre téléphone pour une chose et perdez une heure ?';

  @override
  String get whatShouldCurreCallYou => 'Comment Curre doit-il vous appeler ?';

  @override
  String get whatPullsYouIn => 'Qu’est-ce qui vous absorbe ?';

  @override
  String get makeCurreHomeHeadline => 'Faites de Curre votre écran d’accueil.';

  @override
  String get withoutCurre => 'Sans Curre';

  @override
  String get withoutCurreBody =>
      'Un regard rapide. Le fil vous absorbe. Une heure a passé.';

  @override
  String get withCurre => 'Avec Curre';

  @override
  String get withCurreBody =>
      'Dites ce qu’il vous faut. Curre ouvre l’app au bon endroit.';

  @override
  String get historyContactsStay =>
      'Votre historique et vos contacts restent sur ce téléphone.';

  @override
  String get howCurrePrivate => 'Comment Curre protège votre vie privée';

  @override
  String get namePrivacyNote =>
      'Seulement pour vous saluer sur l’accueil. Ce nom reste sur ce téléphone.';

  @override
  String get addNameError => 'Ajoutez un nom, même un surnom.';

  @override
  String get pickFaceOrInitial =>
      'Choisissez un visage ou gardez votre initiale. Vous pourrez changer à tout moment.';

  @override
  String get whatsFocusFor => 'À quoi sert cette période de concentration ?';

  @override
  String get focusOnboardingBody =>
      'Curre aide surtout pendant une période avec une date de fin. Ensuite, votre téléphone revient à la normale. Vous pouvez passer si vous hésitez.';

  @override
  String get pickPullAppsBody =>
      'Choisissez les apps où un regard rapide devient une heure. Curre masque seulement celles-ci et demande « Pourquoi maintenant ? » à l’ouverture. Les autres s’ouvrent normalement.';

  @override
  String showAllApps(int count) {
    return 'Afficher les $count apps';
  }

  @override
  String get changeHiddenAnyTime =>
      'Masquez une autre app ou faites-en revenir une depuis Apps masquées ou les réglages de Curre.';

  @override
  String get androidChooseCurre =>
      'Android demandera quelle app utiliser comme accueil. Choisissez Curre.';

  @override
  String get homePointPlan =>
      'L’accueil montre votre plan. Les apps non masquées sont dans Toutes les apps et s’ouvrent normalement.';

  @override
  String get homePointHidden =>
      'Seules les apps choisies sont masquées. À l’ouverture, Curre demande « Pourquoi maintenant ? ».';

  @override
  String get homePointDoor =>
      'Touchez une app sur l’accueil pour aller directement à votre tâche.';

  @override
  String get curreIsHomeNow => 'Curre est maintenant votre écran d’accueil.';

  @override
  String get switchHomeAnyTime =>
      'Vous changez d’avis ? Vous pouvez changer d’accueil dans les réglages de Curre.';

  @override
  String get curreNotHomeHelp =>
      'Curre n’est pas encore votre écran d’accueil. Réessayez ou ouvrez les réglages de l’accueil et choisissez Curre.';

  @override
  String get chooseCurreList =>
      'Choisissez Curre dans la liste, puis revenez ici.';

  @override
  String get chooseCurreDefaultApps =>
      'Touchez « App d’accueil », choisissez Curre, puis revenez.';

  @override
  String get chooseCurreSettings =>
      'Dans Réglages, cherchez « App d’accueil » ou ouvrez Apps puis Apps par défaut ; choisissez Curre et revenez.';

  @override
  String get chooseCurrePhoneSettings =>
      'Ouvrez les réglages du téléphone, cherchez « App d’accueil », choisissez Curre et revenez.';

  @override
  String get planExampleGuitar =>
      'Apprendre l’accord de sol sur YouTube jusqu’à 7 h';

  @override
  String get planExamplePlaylist => 'Lire la playlist du dimanche sur Spotify';

  @override
  String get planExampleMaps => 'Trouver le chemin du studio sur Maps';

  @override
  String get onboardingPlanHelp =>
      'Dites-le en une phrase : l’app, ce que vous ferez et jusqu’à quand. Curre n’apporte que cela sur l’accueil.';

  @override
  String get startFromExample => 'Ou partez d’un exemple :';

  @override
  String morningStartNote(String time) {
    return 'Curre demande le but de votre matinée à partir de $time. Modifiez cela dans les réglages.';
  }

  @override
  String get showMeHow => 'Montrez-moi';

  @override
  String callMe(String name) {
    return 'Appelez-moi $name';
  }

  @override
  String get pickAtLeastOne => 'Choisissez-en au moins une';

  @override
  String get hideThisOne => 'Masquer celle-ci';

  @override
  String hideThese(int count) {
    return 'Masquer ces $count';
  }

  @override
  String get noneOfThese => 'Aucune';

  @override
  String get makeCurreMyHome => 'Faire de Curre mon écran d’accueil';

  @override
  String get openHomeSettings => 'Ouvrir les réglages de l’accueil';

  @override
  String get planLater => 'Je planifierai plus tard';

  @override
  String useExample(String text) {
    return 'Utiliser l’exemple : $text';
  }
}
