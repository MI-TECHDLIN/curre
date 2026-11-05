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
  String chatWith(String target) {
    return 'Discuter avec $target';
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
  String get awayFromPhone => 'Loin du téléphone';

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

  @override
  String get findApp => 'Rechercher une app';

  @override
  String noAppMatches(String query) {
    return 'Aucune app ne correspond à « $query ».';
  }

  @override
  String get everyAppHidden => 'Toutes les apps de ce téléphone sont masquées.';

  @override
  String openApp(String app) {
    return 'Ouvrir $app';
  }

  @override
  String get hideThisApp => 'Masquer cette app';

  @override
  String hideApp(String app) {
    return 'Masquer $app';
  }

  @override
  String appHiddenAsk(String app) {
    return '$app est masquée. À l’ouverture, Curre demande d’abord « Pourquoi maintenant ? ».';
  }

  @override
  String get planApps => 'Apps utilisables par vos plans';

  @override
  String get planAppsHelp =>
      'Quand vous planifiez, Curre choisit parmi celles-ci. Sélectionnez-en 2 à 30.';

  @override
  String get hiddenAppsHelp =>
      'Seules celles-ci quittent l’accueil et demandent « Pourquoi maintenant ? ». Les autres s’ouvrent normalement.';

  @override
  String get alwaysOnHomeHelp =>
      'Elles restent sur l’accueil toute la journée, sans plan.';

  @override
  String pickedCount(int count) {
    return '$count sélectionnées';
  }

  @override
  String hiddenCount(int count) {
    return '$count masquées';
  }

  @override
  String onHomeCount(int count) {
    return '$count sur l’accueil';
  }

  @override
  String planAppsMinimum(int count) {
    return 'Les plans ont besoin d’au moins $count apps.';
  }

  @override
  String planAppsMaximum(int count) {
    return 'Il y en a déjà $count. Désélectionnez-en une pour en ajouter une autre.';
  }

  @override
  String appAlwaysOnHome(String app) {
    return '$app reste toujours sur l’accueil.';
  }

  @override
  String get privacyDetails => 'Détails de confidentialité';

  @override
  String get privacySubtitle =>
      'Ce qui quitte ce téléphone et pour combien de temps.';

  @override
  String get privacyReadOnline => 'Ce qui est lu en ligne';

  @override
  String get privacyReadOnlineBody =>
      'Votre plan, les noms des apps, la raison d’ouvrir une app masquée et les notes envoyées après une tâche sont lus en ligne pour que Curre puisse vous répondre.';

  @override
  String get privacyCopyTime => 'Durée possible d’une copie';

  @override
  String get privacyCopyTimeBody =>
      'Curre ne garde aucune copie en ligne. Le service d’IA peut conserver une réponse réussie, y compris des mots cités, pendant environ un jour afin qu’un nouvel essai reçoive la même réponse. Elle est ensuite supprimée.';

  @override
  String get privacyStaysHere => 'Ce qui reste ici';

  @override
  String get privacyStaysHereBody =>
      'Vos contacts, noms de conversations, utilisation des apps et historique restent sur ce téléphone. Vous pouvez effacer les plans, raisons et notes dans les réglages de Curre.';

  @override
  String get privacyHistoryHides => 'Ce que masque l’Historique';

  @override
  String get privacyHistoryHidesBody =>
      'Avant d’enregistrer une raison ou une note vérifiée, Curre cherche les noms, numéros de téléphone, e-mails, adresses et informations de paiement. Ils deviennent des libellés comme [nom] ou [téléphone]. Si cette vérification est indisponible, vos mots restent inchangés.';

  @override
  String get privacyLogs =>
      'Curre note seulement si une demande a fonctionné et sa durée. Vos mots ne figurent pas dans les journaux en ligne.';

  @override
  String get savedForLaterTitle => 'Gardé pour plus tard';

  @override
  String get laterNoneFits =>
      'Rien de ce que vous avez gardé ne correspond à ce plan. Cela attendra un meilleur moment.';

  @override
  String get laterBestFirst =>
      'La meilleure correspondance avec ce plan d’abord.';

  @override
  String get laterNewestFirst => 'Les plus récents d’abord.';

  @override
  String get laterOneMore => '1 autre attendra un meilleur moment.';

  @override
  String laterMore(int count) {
    return '$count autres attendront un meilleur moment.';
  }

  @override
  String get notToday => 'Pas aujourd’hui';

  @override
  String get sectionYourFocus => 'Votre objectif';

  @override
  String get sectionYourDay => 'Votre journée';

  @override
  String get dayStartsHelp =>
      'Au début de chaque partie de la journée, Curre demande à quoi elle sert.';

  @override
  String startsAt(String time) {
    return 'Commence à $time';
  }

  @override
  String get sectionYourApps => 'Vos apps';

  @override
  String get defaultEssentials => 'Téléphone, Messages et Réglages';

  @override
  String defaultEssentialsMore(int count) {
    return 'Téléphone, Messages, Réglages et $count autres';
  }

  @override
  String get strictQuestion => 'À quel point Curre doit-il être strict ?';

  @override
  String get sectionHiddenApps => 'Apps masquées';

  @override
  String get askWhyHidden =>
      'Demander « Pourquoi maintenant ? » à l’ouverture d’une app masquée';

  @override
  String get needsAndroidOk =>
      'Votre accord dans Android est d’abord nécessaire';

  @override
  String get pausedOtherHome =>
      'En pause pendant l’utilisation d’un autre écran d’accueil';

  @override
  String get restingToday => 'Repos aujourd’hui. Retour demain matin.';

  @override
  String get askWhyOn =>
      'Activé, même depuis les apps récentes, notifications et liens';

  @override
  String get keepHiddenQuiet => 'Garder les apps masquées silencieuses';

  @override
  String get focusEndedNothingHeld =>
      'Votre période est terminée, donc rien n’est retenu';

  @override
  String get heldUntilBack => 'Activé. Retenues jusqu’au retour de l’app.';

  @override
  String get turnOnUsageAccess => 'Activer l’accès à l’utilisation';

  @override
  String get turnOnNotificationAccess => 'Activer l’accès aux notifications';

  @override
  String get sectionQuietNudges => 'Rappels discrets';

  @override
  String get allowNotifications => 'Autoriser les notifications';

  @override
  String get notificationsAllowed =>
      'Autorisées. Les rappels choisis peuvent apparaître.';

  @override
  String get notificationsNotAllowed =>
      'Pas encore autorisées. Touchez pour les autoriser.';

  @override
  String get notificationsAndroidControls =>
      'Android décide si les rappels choisis peuvent apparaître';

  @override
  String get sectionVoiceTyping => 'Saisie vocale';

  @override
  String get sectionYourName => 'Votre nom';

  @override
  String get nameInGreeting => 'Nom dans votre salutation';

  @override
  String get sectionHomeScreen => 'Votre écran d’accueil';

  @override
  String get sectionHistoryPrivacy => 'Historique et confidentialité';

  @override
  String get historySettingsBody =>
      'Vos plans et les apps ramenées au cours des 30 derniers jours. Seulement sur ce téléphone.';

  @override
  String get privacySettingsBody =>
      'Ce qui est lu en ligne, ce qui reste ici et quand les copies sont supprimées';

  @override
  String get clearHistory => 'Effacer l’historique';

  @override
  String get clearHistorySettingsBody =>
      'Supprimer de ce téléphone les anciens plans, raisons, notes et notifications manquées';

  @override
  String get sectionAbout => 'À propos';

  @override
  String get licences => 'Licences';

  @override
  String get licencesBody =>
      'Les polices, icônes, illustrations et la saisie vocale utilisées par Curre';

  @override
  String get appLegalese => 'Curre ouvre la tâche, pas l’app.';

  @override
  String sessionStartsAt(String session) {
    return 'Votre $session commence à';
  }

  @override
  String get sessionOrderError =>
      'Le matin commence avant l’après-midi, et l’après-midi avant le soir. Essayez une autre heure.';

  @override
  String sessionStartSaved(String session, String time) {
    return 'Votre $session commence maintenant à $time.';
  }

  @override
  String get nameSaved => 'Enregistré. Curre vous saluera avec ce nom.';

  @override
  String get usageAccessDone =>
      'C’est fait. Curre demandera « Pourquoi maintenant ? » à l’ouverture d’une app masquée.';

  @override
  String get accessStillOff =>
      'C’est toujours désactivé. Vous pouvez l’activer ici quand vous voulez.';

  @override
  String get notificationAccessDone =>
      'C’est fait. Les apps masquées resteront silencieuses jusqu’à leur retour.';

  @override
  String get notificationsPermissionDone =>
      'Les notifications sont autorisées. Curre utilisera les rappels choisis ci-dessus.';

  @override
  String get notificationsPermissionOff =>
      'Les notifications ne sont pas autorisées. Vous pouvez les autoriser pour Curre dans les réglages du téléphone.';

  @override
  String get chooseHomeApp =>
      'Touchez « App d’accueil », puis choisissez celle que vous voulez.';

  @override
  String get searchHomeApp =>
      'Les réglages se sont ouverts. Cherchez « App d’accueil » ou ouvrez Apps puis Apps par défaut, et faites votre choix.';

  @override
  String get openSettingsHomeApp =>
      'Ouvrez les réglages du téléphone et cherchez « App d’accueil ». Faites votre choix.';

  @override
  String get curreNotHomeSettings =>
      'Curre n’est pas encore votre écran d’accueil. Ouvrez les réglages, cherchez « App d’accueil » et choisissez Curre.';

  @override
  String get clearHistoryQuestion => 'Effacer votre historique ?';

  @override
  String get clearHistoryBody =>
      'Vos anciens plans, les raisons données pour ramener des apps, les notes après les tâches et les notifications manquées seront supprimés. Vos jours de preuve, le plan du jour et les temps en cours restent inchangés.';

  @override
  String get historyCleared => 'Historique effacé.';

  @override
  String get historyClearFailed =>
      'Curre n’a pas pu effacer votre historique. Réessayez.';

  @override
  String get switchHome => 'Passer à un autre écran d’accueil';

  @override
  String get curreNotHomeBody =>
      'Curre n’est pas votre écran d’accueil pour le moment. Vos plans et votre historique restent ici quand vous en aurez besoin.';

  @override
  String get switchHomeBody =>
      'Vous voulez un autre écran d’accueil pour un moment ? Aucun problème. Android permet de choisir l’app qui s’ouvre avec le bouton Accueil. Vos plans et votre historique restent sur ce téléphone et vous pouvez revenir quand vous voulez.';

  @override
  String get openHomeScreenSettings => 'Ouvrir les réglages de l’accueil';

  @override
  String get chooseHomeScreenApp => 'Choisir une app d’accueil';

  @override
  String get homeSettingsPath =>
      'Si le téléphone ouvre ses réglages, cherchez Apps, puis Apps par défaut, puis App d’accueil.';

  @override
  String get nudgesHelp =>
      'Choisissez les rappels silencieux envoyés par Curre. En désactiver un annule aussi ceux de ce type qui attendent.';

  @override
  String get planYourDay => 'Planifier votre journée';

  @override
  String get eachSessionBegins => 'Au début de chaque partie de votre journée';

  @override
  String get morningBegins => 'Une fois par jour, au début de votre matinée';

  @override
  String get afternoonEveningToo => 'Aussi l’après-midi et le soir';

  @override
  String get afternoonEveningBegins =>
      'Aussi au début de l’après-midi et du soir';

  @override
  String get planEnding => 'Fin du plan';

  @override
  String get tenMinutesBeforePlan => 'Dix minutes avant la fin de votre plan';

  @override
  String get appTimeUp => 'Temps de l’app écoulé';

  @override
  String get hiddenAppTimeEnds => 'Quand le temps d’une app masquée est écoulé';

  @override
  String get addProofLater => 'Quelques minutes après la fin de votre plan';

  @override
  String get focusEnds => 'Fin de la période';

  @override
  String get focusEndsMorning => 'Le matin où votre période se termine';

  @override
  String get turnAllNudgesOff => 'Désactiver tous les rappels';

  @override
  String get turnAllNudgesOn => 'Activer tous les rappels';

  @override
  String get gentle => 'Souple';

  @override
  String get balanced => 'Équilibré';

  @override
  String get strict => 'Strict';

  @override
  String get strictnessBody =>
      'Quand vous ramenez une app masquée, Curre vérifie votre raison. Plus le réglage est strict, plus la raison doit être claire avant l’ouverture.';

  @override
  String get hiddenChoiceNone =>
      'Aucune. Toutes les apps s’ouvrent normalement.';

  @override
  String get hiddenChoiceOne =>
      '1 app. Elle seule demande « Pourquoi maintenant ? ».';

  @override
  String hiddenChoiceMany(int count) {
    return '$count apps. Seules celles-ci demandent « Pourquoi maintenant ? ».';
  }

  @override
  String get missedNotifications => 'Notifications manquées';

  @override
  String missedFromHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications d’apps masquées',
      one: '1 notification d’apps masquées',
    );
    return '$_temp0';
  }

  @override
  String heldUntilAppBack(int count) {
    return '$count retenues jusqu’au retour de leur app';
  }

  @override
  String bringBackApp(String app) {
    return 'Ramener $app';
  }

  @override
  String get restDayTheyOpen => 'Jour de repos : elles s’ouvrent sans demander';

  @override
  String get nothingHidden =>
      'Rien n’est masqué. Toutes les apps s’ouvrent normalement depuis Toutes les apps.';

  @override
  String get hiddenAppsOut =>
      'Vos apps masquées sont disponibles pour votre plan ou pendant un moment.';

  @override
  String get hideAnotherApp => 'Masquer une autre app';

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
      'Seules les apps que vous avez choisi de masquer attendent ici. Touchez-en une pour la ramener un moment.';

  @override
  String get gotIt => 'Compris';

  @override
  String get appOpenFailed =>
      'Cette app ne s’est pas ouverte. Elle n’est peut-être plus installée.';

  @override
  String get missedNotificationsBody =>
      'Retenues discrètement pendant que leurs apps étaient masquées, puis rendues au retour de l’app. Rien ne quitte ce téléphone.';

  @override
  String get nothingHeld => 'Rien n’est retenu pour le moment.';

  @override
  String get held => 'Retenue';

  @override
  String get givenBack => 'Rendue';

  @override
  String openNotificationApp(String app) {
    return 'Ouvrir $app';
  }

  @override
  String get openCurreAppInfo => 'Ouvrir les informations de Curre';

  @override
  String get openSettingsAppsCurre =>
      'Ouvrez les réglages du téléphone, puis Apps, puis Curre.';

  @override
  String get restrictedStillOff =>
      'C’est toujours désactivé. Ce n’est pas grave, Curre fonctionne sans cet accès. Si Android indique que le réglage est restreint, autorisez-le une fois :';

  @override
  String get restrictedHelp =>
      'Si Android indique que le réglage est restreint, autorisez-le une fois :';

  @override
  String get restrictedStepOne => 'Ouvrez les informations de Curre.';

  @override
  String get restrictedStepTwo => 'Touchez les trois points en haut à droite.';

  @override
  String get restrictedStepThree =>
      'Touchez « Autoriser les paramètres restreints ».';

  @override
  String get restrictedStepFour =>
      'Confirmez avec votre code PIN ou empreinte.';

  @override
  String get restrictedStepFive => 'Revenez ici et activez l’accès.';

  @override
  String get noProblemSettings =>
      'Aucun problème. Ce choix reste disponible dans les réglages de Curre.';

  @override
  String get allSet => 'Tout est prêt.';

  @override
  String get usageAccessAllSet =>
      'Curre demandera « Pourquoi maintenant ? » à l’ouverture d’une app masquée.';

  @override
  String get notificationAccessAllSet =>
      'Les apps masquées resteront silencieuses jusqu’à leur retour.';

  @override
  String get askWhyPrompt =>
      'Demander « Pourquoi maintenant ? » à l’ouverture d’une app masquée ?';

  @override
  String get quietPrompt => 'Garder les apps masquées silencieuses ?';

  @override
  String get askWhyPromptBody =>
      'Les apps masquées peuvent revenir par les apps récentes, les liens ou les notifications. Curre peut alors demander aussi. Il vérifie seulement quelle app s’est ouverte, jamais ce qui est affiché.';

  @override
  String get tryAgainAccess => 'Réessayer';

  @override
  String get hiddenNamesFallback => 'les apps que vous masquez';

  @override
  String hiddenNamesTwo(String first, String second) {
    return '$first et $second';
  }

  @override
  String hiddenNamesMore(String first, String second, int count) {
    return '$first, $second et $count autres';
  }

  @override
  String quietPromptBody(String apps) {
    return 'Curre peut retenir discrètement les notifications de $apps et toutes les rendre à l’ouverture de l’app. Les autres apps notifient normalement, et les appels et alarmes passent toujours.';
  }

  @override
  String get focusPurposeExams => 'Examens';

  @override
  String get focusPurposeDeadline => 'Une échéance';

  @override
  String get focusPurposeHabit => 'Changer une habitude';

  @override
  String get focusPurposeOther => 'Autre chose';

  @override
  String get focusHintExams => 'Réussir mes examens de maths';

  @override
  String get focusHintDeadline => 'Terminer le portfolio';

  @override
  String get focusHintHabit => 'Ne plus ouvrir les réseaux au lit';

  @override
  String get focusHintOther => 'Ce que je veux changer';

  @override
  String get focusEndExams =>
      'Vous avez fait de la place pour le travail important.';

  @override
  String get focusEndDeadline => 'Vous avez mené ce travail jusqu’à l’arrivée.';

  @override
  String get focusEndHabit => 'Vous avez laissé la nouvelle habitude grandir.';

  @override
  String get focusEndOther => 'Vous êtes revenu à ce qui comptait.';

  @override
  String get focusLengthWeek => '1 semaine';

  @override
  String get focusLengthTwoWeeks => '2 semaines';

  @override
  String get focusLengthThreeWeeks => '3 semaines';

  @override
  String get focusLengthThirtyDays => '30 jours';

  @override
  String get focusGoalLabel => 'Votre objectif, en quelques mots (facultatif)';

  @override
  String get untilWhen => 'Jusqu’à quand ?';

  @override
  String get pickDate => 'Choisir une date';

  @override
  String focusEndsSummary(String date, String days) {
    return 'Fin le $date, dans $days. Vous pourrez le modifier.';
  }

  @override
  String get focusEndsOn => 'La période se termine le';

  @override
  String get focusSaveFailed =>
      'Curre n’a pas pu enregistrer votre période. Réessayez.';

  @override
  String get focusQuestion => 'À quoi sert cette période ?';

  @override
  String get focusPickerBody =>
      'Curre aide surtout pendant une période avec une fin : examens, échéance ou habitude à changer.';

  @override
  String get pickFocusPurpose => 'Choisissez son but';

  @override
  String get startMyFocus => 'Commencer ma période';

  @override
  String get setFocusQuestion => 'Définir une période ?';

  @override
  String get focusOfferBody =>
      'Curre aide surtout pendant une période avec une fin : examens, échéance ou habitude à changer. Choisissez son but et sa fin.';

  @override
  String get maybeLater => 'Peut-être plus tard';

  @override
  String get setFocus => 'Définir une période';

  @override
  String get restDay => 'Jour de repos';

  @override
  String get yourFocus => 'Votre période';

  @override
  String get restDayBody =>
      'Aujourd’hui, les apps masquées s’ouvrent sans demander, leurs notifications passent et les rappels restent silencieux. Vos jours de preuve sont protégés. Reprise demain.';

  @override
  String focusLeft(String days, String date) {
    return '$days restants · fin le $date';
  }

  @override
  String get backToFocusNow => 'Reprendre maintenant';

  @override
  String get takeTodayOff => 'Prendre la journée';

  @override
  String nextRestDay(String date) {
    return 'Prochain repos : $date';
  }

  @override
  String get today => 'aujourd’hui';

  @override
  String get tomorrow => 'demain';

  @override
  String get takeTodayOffQuestion => 'Prendre la journée ?';

  @override
  String get takeTodayOffBody =>
      'Jusqu’à demain matin, les apps masquées s’ouvrent sans demander, leurs notifications passent et Curre n’envoie aucun rappel. Vos jours de preuve sont protégés. Vous pouvez prendre un jour par semaine.';

  @override
  String get keepGoing => 'Continuer';

  @override
  String get enjoyRestDay => 'Profitez de votre repos. Reprise demain.';

  @override
  String focusSummaryDays(String days) {
    return '$days de concentration.';
  }

  @override
  String focusSummaryWithRest(String days, String rests) {
    return '$days de concentration, $rests.';
  }

  @override
  String restDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours de repos',
      one: '1 jour de repos',
    );
    return '$_temp0';
  }

  @override
  String get daysWithProof => 'jours avec preuve';

  @override
  String get tasksProved => 'tâches prouvées';

  @override
  String get hiddenAppsLeftClosed => 'apps masquées restées fermées';

  @override
  String get startAnotherFocus => 'Commencer une autre période';

  @override
  String get oldHomeScreen => 'Revenir à mon ancien écran d’accueil';

  @override
  String get focusHistoryStays =>
      'Votre historique et vos jours de preuve restent sur ce téléphone dans les deux cas.';

  @override
  String get chooseOldHome =>
      'Choisissez votre ancien écran d’accueil dans la liste. Curre cesse de demander et laisse passer toutes les notifications.';

  @override
  String get tapOldHome =>
      'Touchez « App d’accueil », puis choisissez votre ancien écran.';

  @override
  String get searchOldHome =>
      'Les réglages se sont ouverts. Cherchez « App d’accueil », puis choisissez votre ancien écran.';

  @override
  String get openSettingsOldHome =>
      'Ouvrez les réglages du téléphone, cherchez « App d’accueil » et choisissez votre ancien écran.';

  @override
  String get noFocusSet => 'Aucune période définie';

  @override
  String get focusSettingsEmpty =>
      'Choisissez le but de cette période et sa date de fin.';

  @override
  String focusEndedOn(String date) {
    return 'Terminée le $date. Voyez le bilan sur l’accueil.';
  }

  @override
  String focusEndsLeft(String date, String days) {
    return 'Fin le $date, $days restants';
  }

  @override
  String get changeEndDate => 'Changer la date de fin';

  @override
  String weeklyRestNext(String date) {
    return 'Un jour de repos par semaine. Prochain : $date.';
  }

  @override
  String get endFocusNow => 'Terminer maintenant';

  @override
  String focusNowEnds(String date) {
    return 'Votre période se termine maintenant le $date.';
  }

  @override
  String get endFocusQuestion => 'Terminer votre période maintenant ?';

  @override
  String get endFocusBody =>
      'L’accueil affiche le bilan, puis vous choisissez la suite. Votre historique et vos jours de preuve restent.';

  @override
  String get endFocus => 'Terminer la période';

  @override
  String get historySubtitle =>
      'Les 30 derniers jours · seulement sur ce téléphone';

  @override
  String get whatHappened => 'Ce qui s’est passé';

  @override
  String get historyEmptyTitle => 'Un début tranquille.';

  @override
  String get historyEmptyBody =>
      'Vos plans et les applis que vous faites revenir apparaîtront ici. Tout reste sur ce téléphone.';

  @override
  String plannedSessionsCount(int count) {
    return '$count sur 21 planifiées';
  }

  @override
  String get historyOverviewHelp =>
      'Chaque case représente un matin, un après-midi ou un soir des 7 derniers jours. Les cases remplies ont commencé avec un plan.';

  @override
  String sessionPlanState(String session, String state) {
    return '$session : $state';
  }

  @override
  String get planned => 'planifié';

  @override
  String get noPlan => 'sans plan';

  @override
  String proofCloudInHand(String detail) {
    return 'Vous avez un jour nuage. $detail';
  }

  @override
  String get oneMoreProofToCloud =>
      'Encore 1 jour avec preuve avant votre prochain jour nuage.';

  @override
  String moreProofToCloud(int count) {
    return 'Encore $count jours avec preuve avant votre prochain jour nuage.';
  }

  @override
  String proofDaysInAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours avec preuve au total',
      one: '1 jour avec preuve au total',
    );
    return '$_temp0';
  }

  @override
  String bestRunCount(int count) {
    return 'Meilleure série $count';
  }

  @override
  String cloudDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours nuage',
      one: '1 jour nuage',
    );
    return '$_temp0';
  }

  @override
  String get historyProofHint =>
      'Après une tâche, dites ce qui a changé. Une note précise ajoute un jour avec preuve.';

  @override
  String historySessionPlan(String session) {
    String _temp0 = intl.Intl.selectLogic(session, {
      'morning': 'Plan du matin',
      'afternoon': 'Plan de l’après-midi',
      'evening': 'Plan du soir',
      'other': 'Plan',
    });
    return '$_temp0';
  }

  @override
  String endedEarlyAt(String ended, String planned) {
    return 'Terminé plus tôt à $ended, prévu jusqu’à $planned';
  }

  @override
  String waitedDuration(String duration) {
    return 'Attente de $duration';
  }

  @override
  String whyNowApp(String app) {
    return 'Pourquoi maintenant ? · $app';
  }

  @override
  String get olderReasonMissing =>
      'La raison n’a pas été enregistrée dans cette ancienne entrée.';

  @override
  String appCameBack(String app) {
    return '$app est revenue';
  }

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String openedAfterWaiting(String duration) {
    return 'Ouverte après $duration d’attente';
  }

  @override
  String get openedFromLater =>
      'Gardée pour plus tard, puis ouverte depuis un plan';

  @override
  String get supportedProof => 'Preuve appuyée';

  @override
  String get waitingToBeChecked => 'En attente de vérification';

  @override
  String get markedDone => 'Marquée terminée';

  @override
  String get noNote => 'Aucune note';

  @override
  String get personalDetailHidden => 'Donnée personnelle masquée';

  @override
  String get outcomeOpened => 'Ouverte';

  @override
  String get outcomeNotNow => 'Pas maintenant';

  @override
  String get outcomeNeededDetail => 'Manquait de précision';

  @override
  String get outcomeNotReason => 'Pas une raison';

  @override
  String get outcomeCouldNotCheck => 'Vérification impossible';

  @override
  String get nextSunriseOneProof => 'Prochain lever : une preuve suffit';

  @override
  String get noProofDaysYet => 'Aucun jour avec preuve pour le moment';

  @override
  String proofDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours avec preuve',
      one: '1 jour avec preuve',
    );
    return '$_temp0';
  }

  @override
  String get todaysSunIsUp => 'le soleil d’aujourd’hui est levé';

  @override
  String get oneCloudInHand => 'un jour nuage disponible';

  @override
  String get cloudDay => 'Jour nuage';

  @override
  String runEndedAt(String days) {
    return 'Cette série s’est terminée à $days.';
  }

  @override
  String get todaysProofStartsNext =>
      'La preuve d’aujourd’hui lance le prochain lever.';

  @override
  String get theNextSunrise => 'Le prochain lever';

  @override
  String get dayProof => 'jour avec preuve';

  @override
  String get dayPending => 'note en attente de vérification';

  @override
  String get dayNoProof => 'sans preuve';

  @override
  String get dayCloud => 'jour nuage';

  @override
  String get dayToday => 'aujourd’hui';

  @override
  String get dayFuture => 'à venir';

  @override
  String get dayStillOpen => 'encore ouvert';

  @override
  String get startingToday => 'Commence aujourd’hui';

  @override
  String proofRunRange(String start, String end) {
    return 'Du $start au $end';
  }

  @override
  String sinceDate(String date) {
    return 'Depuis le $date';
  }

  @override
  String get milestoneSeven =>
      'Sept jours avec preuve : vos rayons finissent désormais en étincelles.';

  @override
  String get milestoneTwentyOne =>
      '21 jours avec preuve : un anneau de lumière se tient derrière votre soleil.';

  @override
  String get milestoneFifty =>
      '50 jours avec preuve : votre soleil porte un second anneau.';

  @override
  String get cloudDayKeepsRun =>
      'Si une journée passe sans preuve, il maintient votre série.';

  @override
  String weekdaySunUp(String weekday) {
    return 'Le soleil de $weekday est levé';
  }

  @override
  String earnedCloudDay(String detail) {
    return 'Vous avez gagné un jour nuage. $detail';
  }

  @override
  String get completionQuestion =>
      'Qu’est-ce qui a changé, s’est terminé ou est devenu clair ?';

  @override
  String get oneSentenceEnough => 'Une phrase suffit';

  @override
  String get addOneDetail => 'Ajoutez un détail';

  @override
  String get addWhatChanged => 'Ajoutez ce qui a changé';

  @override
  String proofMismatchPrompt(String detail) {
    return '« $detail » ne correspond pas à la tâche prévue. Qu’est-ce qui a changé, s’est terminé ou est devenu clair ?';
  }

  @override
  String get proofFuturePrompt =>
      'Cela ressemble à la suite. Qu’est-ce qui a changé, s’est terminé ou est devenu clair ?';

  @override
  String get proofUnrelatedPrompt =>
      'Dites en quoi cela rejoint votre plan. Qu’est-ce qui a changé, s’est terminé ou est devenu clair ?';

  @override
  String get proofDetailPrompt =>
      'Un nom, un nombre ou une étape suffit. Qu’est-ce qui a changé, s’est terminé ou est devenu clair ?';

  @override
  String get justMarkDone => 'Marquer simplement comme terminée';

  @override
  String get readingYourNote => 'Lecture de votre note';

  @override
  String get readingYourNoteProgress => 'Lecture de votre note…';

  @override
  String get noteSaved => 'Votre note est enregistrée';

  @override
  String get noteSavedBody =>
      'Impossible de la vérifier maintenant. Elle le sera quand vous serez de nouveau en ligne.';

  @override
  String get runSafeWhileWaiting =>
      'Votre série reste à l’abri pendant l’attente.';

  @override
  String get markedAsDone => 'Marquée terminée';

  @override
  String get markedDoneBody =>
      'Elle est dans votre historique. Les jours avec preuve viennent d’une note sur ce qui a changé.';

  @override
  String get noteCountsAsProof => 'Votre note compte comme preuve.';

  @override
  String get oneMoreRay => 'Un rayon de plus';

  @override
  String get proofAdded => 'Preuve ajoutée';

  @override
  String get profileSmiling => 'Votre profil, souriant';

  @override
  String get sunOneRay =>
      'Le soleil d’aujourd’hui, un rayon : une tâche avec preuve';

  @override
  String sunManyRays(int count) {
    return 'Le soleil d’aujourd’hui, $count rayons : $count tâches avec preuve';
  }

  @override
  String proofDayUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jours avec preuve',
      one: 'jour avec preuve',
    );
    return '$_temp0';
  }

  @override
  String get newRunStarts => 'Une nouvelle série commence ici.';

  @override
  String get supported => 'Appuyée';

  @override
  String get backedByStart =>
      'Appuyée par le démarrage de la tâche et votre note';

  @override
  String get backedByApp => 'Appuyée par l’appli ouverte et votre note';

  @override
  String get voicePermissionExplanation =>
      'Curre écoute seulement lorsque vous maintenez ou touchez le micro. Votre voix ne quitte jamais votre téléphone.';

  @override
  String get voiceMicNeeded =>
      'La saisie vocale a besoin du micro. Vous pouvez aussi écrire.';

  @override
  String get voiceCouldNotStart =>
      'La saisie vocale n’a pas pu démarrer. Vous pouvez aussi écrire.';

  @override
  String get voiceGettingReady =>
      'La saisie vocale se prépare. Vous pouvez écrire en attendant.';

  @override
  String get voiceReadyOffline =>
      'Prête. La saisie vocale fonctionne maintenant hors ligne.';

  @override
  String get voiceMicStillOff =>
      'Le micro est toujours désactivé. Autorisez-le pour parler, ou écrivez.';

  @override
  String get voiceNothingHeard =>
      'Je n’ai rien entendu. Réessayez un peu plus près du micro.';

  @override
  String get voicePrivacyLine =>
      'Sur ce téléphone · rien de ce que vous dites n’est enregistré ni envoyé';

  @override
  String get typeInstead => 'Écrire plutôt';

  @override
  String get gettingVoiceReady => 'Préparation de la saisie vocale';

  @override
  String downloadNowSize(String size) {
    return 'Télécharger maintenant · $size';
  }

  @override
  String get speakInsteadTyping => 'Parlez plutôt que d’écrire';

  @override
  String get allowMic => 'Autoriser le micro';

  @override
  String get micOffForCurre => 'Le micro est désactivé pour Curre';

  @override
  String micSettingsBody(String privacy) {
    return 'Activez le micro pour Curre dans les réglages du téléphone, puis revenez. $privacy';
  }

  @override
  String get openPhoneSettings => 'Ouvrir les réglages du téléphone';

  @override
  String get tapOrHoldMic => 'Touchez ou maintenez le micro, puis parlez.';

  @override
  String get listeningHeld => 'Écoute… relâchez quand vous avez fini.';

  @override
  String get listeningPause =>
      'Écoute… faites une pause quand vous avez fini, ou touchez le micro.';

  @override
  String get writingSaid => 'Transcription de ce que vous avez dit';

  @override
  String get writingProgress => 'Transcription…';

  @override
  String get voiceStartFailed => 'La saisie vocale n’a pas pu démarrer';

  @override
  String get micStartFailed => 'Le micro n’a pas démarré';

  @override
  String voiceModelFix(String size) {
    return 'Retélécharger les fichiers vocaux ($size) règle généralement le problème.';
  }

  @override
  String get voiceMicBusy =>
      'Si une autre appli utilise le micro, fermez-la et réessayez.';

  @override
  String get downloadAgain => 'Retélécharger';

  @override
  String voiceAmount(String received, String total) {
    return '$received sur $total';
  }

  @override
  String get voiceStatusReady => 'Prête · fonctionne hors ligne';

  @override
  String voiceStatusGetting(int percent, String amount) {
    return 'Préparation $percent % · $amount';
  }

  @override
  String voiceWaitingWifi(String extra) {
    return 'En attente du Wi-Fi$extra';
  }

  @override
  String voiceWaitingConnection(String extra) {
    return 'En attente d’une connexion$extra';
  }

  @override
  String voiceWaitingBattery(String extra) {
    return 'En attente de plus de batterie$extra';
  }

  @override
  String voiceStatusExtra(String amount) {
    return ' · $amount pour le moment';
  }

  @override
  String voiceStoppedStorage(String size) {
    return 'Arrêtée · le téléphone a besoin de $size libres';
  }

  @override
  String voiceStoppedLater(String extra) {
    return 'Arrêtée · nouvel essai plus tard$extra';
  }

  @override
  String voiceNotOnPhone(String size) {
    return 'Absente du téléphone · $size à la prochaine utilisation du micro';
  }

  @override
  String get voiceUnavailable => 'Indisponible sur ce téléphone';

  @override
  String get voiceDownload => 'Téléchargement vocal';

  @override
  String voiceKeepsGoing(String amount) {
    return '$amount. Il continue si vous fermez ceci.';
  }

  @override
  String voiceDownloadsWifi(String size) {
    return 'Le téléchargement se fait tout seul en Wi-Fi, $size une fois.';
  }

  @override
  String get voiceNoConnection =>
      'Pas de connexion pour le moment. Il reprendra là où il s’est arrêté.';

  @override
  String get voiceWaitBattery => 'Il attend plus de batterie ou un chargeur.';

  @override
  String voiceNoSpace(String size) {
    return 'Le téléphone manque d’espace. La saisie vocale a besoin de $size libres.';
  }

  @override
  String get voiceDamaged =>
      'Un fichier est arrivé endommagé et a été supprimé. Réessayez.';

  @override
  String get voiceFilesUnreachable =>
      'Les fichiers vocaux sont inaccessibles. Réessayez un peu plus tard.';

  @override
  String voiceRunsHere(String size) {
    return 'La saisie vocale fonctionne sur ce téléphone et demande $size une fois.';
  }

  @override
  String get stopAndWrite => 'Arrêter et transcrire';

  @override
  String get startListening => 'Commencer l’écoute';

  @override
  String get removeVoiceQuestion => 'Supprimer les fichiers vocaux ?';

  @override
  String removeVoiceBody(String size) {
    return 'Cela libère $size. La saisie vocale ne les retéléchargera qu’à la prochaine utilisation du micro ou si vous la réactivez ici.';
  }

  @override
  String get keepFiles => 'Les garder';

  @override
  String get remove => 'Supprimer';

  @override
  String get voiceFilesRemoved => 'Fichiers vocaux supprimés.';

  @override
  String get voiceFilesRemoveFailed =>
      'Les fichiers vocaux n’ont pas pu être supprimés.';

  @override
  String get voiceOnPhone => 'Voix : sur ce téléphone';

  @override
  String get voiceSettingsBody =>
      'La saisie vocale ne demande aucun compte et, après téléchargement, aucune connexion. Rien de ce que vous dites n’est enregistré ni envoyé.';

  @override
  String get downloadMobile => 'Télécharger la voix avec les données mobiles';

  @override
  String mobileOffHelp(String size) {
    return 'Désactivé : attend le Wi-Fi. Environ $size, une fois.';
  }

  @override
  String get downloadVoiceFiles => 'Télécharger les fichiers vocaux';

  @override
  String get removeVoiceFiles => 'Supprimer les fichiers vocaux';

  @override
  String get sceneStory =>
      'Tard le soir, un téléphone rempli de publications entraîne une note disant « juste regarder l’heure du bus » dans un écheveau de laine, tandis que le soleil dort encore.';

  @override
  String get sceneBusTime => 'Juste regarder l’heure du bus';

  @override
  String get sceneMagnetEmpty =>
      'Un aimant attend les applis qui vous attirent.';

  @override
  String sceneMagnetApps(String apps) {
    return 'Un aimant attire $apps.';
  }

  @override
  String get sceneInitial => 'Votre initiale vous salue.';

  @override
  String get sceneFace => 'Le visage choisi vous salue.';

  @override
  String get sceneHome =>
      'Un téléphone affiche l’écran d’accueil calme de Curre : un bonjour, un plan et deux applis qui s’ouvrent directement sur la tâche.';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String goodMorningName(String name) {
    return 'Bonjour, $name';
  }

  @override
  String sceneSearch(String query) {
    return '→ Rechercher « $query »';
  }

  @override
  String miniAllApps(String count) {
    return 'Toutes les applis · $count';
  }

  @override
  String get scenePlan => 'Le soleil est levé et vous saluez Peek.';

  @override
  String onboardingStep(int step, int total) {
    return 'Étape $step sur $total';
  }

  @override
  String get nothingHiddenYet =>
      'Rien n’est encore masqué. Toutes les applis s’ouvrent normalement.';

  @override
  String hiddenSummaryOne(String name) {
    return 'Masquée : $name. Les autres applis s’ouvrent normalement.';
  }

  @override
  String hiddenSummaryMany(String names) {
    return 'Masquées : $names. Les autres applis s’ouvrent normalement.';
  }

  @override
  String hiddenSummaryMore(String names, int count) {
    return '$names et $count autres';
  }

  @override
  String get taskExampleLearn =>
      'Apprendre quelque chose, comme un accord de guitare';

  @override
  String get taskExampleFindWay => 'Trouver un itinéraire';

  @override
  String get taskExampleReply => 'Répondre à quelqu’un';

  @override
  String get taskExampleTextBack => 'Répondre à un message';

  @override
  String get taskExamplePlaylist => 'Écouter une playlist';

  @override
  String get taskExampleLookUp => 'Chercher une information';

  @override
  String get taskExampleEmail => 'Répondre à un e-mail';

  @override
  String get taskExampleToday => 'Voir ce qui est prévu aujourd’hui';

  @override
  String get taskExampleWrite => 'Noter quelque chose';

  @override
  String get taskExamplePhoto => 'Trouver une photo';

  @override
  String get taskExampleFile => 'Ouvrir un fichier';

  @override
  String get taskExampleMessage => 'Répondre à un message';

  @override
  String get taskExampleEpisode => 'Regarder un épisode';

  @override
  String get taskExampleGroup => 'Consulter un groupe';

  @override
  String get taskExampleVideo => 'Publier une vidéo';

  @override
  String get taskExamplePost => 'Publier quelque chose';

  @override
  String get taskExampleThread => 'Lire une discussion';

  @override
  String get taskExampleIdea => 'Trouver une idée';

  @override
  String get taskExampleFriend => 'Répondre à un ami';

  @override
  String get doorActionSearch => 'Rechercher';

  @override
  String get doorActionDraft => 'Brouillon';

  @override
  String get doorActionNewEvent => 'Nouvel événement';

  @override
  String get openAppGeneric => 'Ouvrir l’appli';

  @override
  String get openAppWith => 'Ouvrir l’appli avec';

  @override
  String laterSavedSemantics(String app, String reason, String destination) {
    return '$app, gardée pour plus tard : $reason. Ouvre $destination';
  }

  @override
  String get chooseProfileAvatar => 'Choisissez un avatar de profil';

  @override
  String profileAvatarNumber(int number) {
    return 'Avatar de profil $number';
  }

  @override
  String profileAvatarSelected(int number) {
    return 'Avatar de profil $number, sélectionné';
  }

  @override
  String get customProfileAvatar => 'Avatar de profil personnalisé';

  @override
  String avatarProofToday(String label) {
    return '$label, preuve aujourd’hui';
  }

  @override
  String avatarSleepy(String label) {
    return '$label, endormi';
  }

  @override
  String profileInitial(String letter) {
    return 'Initiale $letter';
  }

  @override
  String profileInitialProof(String letter) {
    return 'Initiale $letter, preuve aujourd’hui';
  }

  @override
  String get profileDefaultInitial => 'Initiale du profil';

  @override
  String get profileDefaultInitialProof =>
      'Initiale du profil, preuve aujourd’hui';

  @override
  String get channelAppTime => 'Temps de l’appli';

  @override
  String get channelAppTimeBody =>
      'Affiche le temps restant pour une appli et quand elle sera de nouveau masquée.';

  @override
  String get channelCheckins => 'Planifiez votre journée';

  @override
  String get channelCheckinsBody =>
      'Un rappel discret pour planifier matin, après-midi et soir.';

  @override
  String get channelPlans => 'Rappels de plans';

  @override
  String get channelPlansBody => 'Un petit rappel avant la fin de votre plan.';

  @override
  String get channelProof => 'Rappels de preuve';

  @override
  String get channelProofBody =>
      'Après un plan, un rappel pour noter ce que vous avez accompli.';

  @override
  String get channelFocus => 'Période de concentration';

  @override
  String get channelFocusBody =>
      'Le jour où votre période se termine, regardez comment elle s’est passée.';

  @override
  String get nameExample => 'Ada';

  @override
  String appDidNotOpenThere(String app) {
    return '$app ne s’est pas ouverte ici. Le temps continue : réessayez depuis l’accueil.';
  }

  @override
  String get sceneGChord => 'accord de sol';

  @override
  String get sceneWorship => 'louange';

  @override
  String planTimeAdjustSemantics(String summary) {
    return 'Durée du plan : $summary. Touchez pour ajuster.';
  }

  @override
  String get timeCappedNotice =>
      'Limité à six heures ou à minuit, selon la première échéance.';

  @override
  String get timeAdjustHelp =>
      'Touchez une heure pour l’ajuster avant de commencer.';

  @override
  String appTimeAdjustSemantics(String app, String summary) {
    return '$app, $summary, touchez pour ajuster';
  }

  @override
  String timeForLabel(String label) {
    return 'Temps pour $label';
  }

  @override
  String get timeExampleHint => '90 min ou jusqu’à 7 h';

  @override
  String get applyLabel => 'Appliquer';

  @override
  String get timeParseHelp =>
      'Essayez une durée comme « 90 min » ou une heure comme « jusqu’à 7 h ».';

  @override
  String get thisPlan => 'ce plan';

  @override
  String get sessionEnd => 'fin de la session';

  @override
  String fromTime(String time) {
    return 'à partir de $time';
  }

  @override
  String durationMinutesShort(int count) {
    return '$count min';
  }

  @override
  String durationHoursShort(int count) {
    return '$count h';
  }

  @override
  String durationHoursMinutesShort(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String youHaveTime(String duration) {
    return 'Vous avez $duration.';
  }
}
