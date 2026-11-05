// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Curre';

  @override
  String get systemLanguage => 'Idioma do telefone';

  @override
  String get language => 'Idioma';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get languageSpanish => 'Espanhol';

  @override
  String get languageFrench => 'Francês';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageGerman => 'Alemão';

  @override
  String get back => 'Voltar';

  @override
  String get close => 'Fechar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get tryAgain => 'Tentar novamente';

  @override
  String get done => 'Concluído';

  @override
  String get edit => 'Editar';

  @override
  String get save => 'Guardar';

  @override
  String get notNow => 'Agora não';

  @override
  String get checking => 'A verificar…';

  @override
  String get on => 'Ativado';

  @override
  String get off => 'Desativado';

  @override
  String get sessionMorning => 'manhã';

  @override
  String get sessionAfternoon => 'tarde';

  @override
  String get sessionEvening => 'noite';

  @override
  String goodSession(String session) {
    return 'Boa $session';
  }

  @override
  String goodSessionName(String session, String name) {
    return 'Boa $session, $name';
  }

  @override
  String planThisSession(String session) {
    return 'Planear esta $session';
  }

  @override
  String planYourSession(String session) {
    return 'Planear a sua $session';
  }

  @override
  String whatsThisSessionFor(String session) {
    return 'Para que serve esta $session?';
  }

  @override
  String setMySession(String session) {
    return 'Preparar a minha $session';
  }

  @override
  String get phone => 'Telefone';

  @override
  String get messages => 'Mensagens';

  @override
  String get androidSettings => 'Definições';

  @override
  String get curreSettings => 'Definições do Curre';

  @override
  String get allApps => 'Todas as apps';

  @override
  String get allAppsDescription =>
      'Todas as apps que não ocultou, prontas para abrir.';

  @override
  String get hiddenApps => 'Apps ocultas';

  @override
  String hiddenAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps ocultas',
      one: '1 app oculta',
      zero: 'Nenhuma app oculta',
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
      other: '$count minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String secondsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count segundos',
      one: '1 segundo',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get couldNotReadApps => 'Não foi possível ler as suas apps';

  @override
  String get couldNotReadAppsBody =>
      'O Curre não conseguiu ler as apps instaladas neste telefone. Tente novamente para ver as suas apps reais.';

  @override
  String get readingApps => 'A ler apps…';

  @override
  String get profileAvatar => 'Avatar do perfil';

  @override
  String get openProfile => 'Abrir perfil';

  @override
  String get gettingReady => 'A preparar tudo…';

  @override
  String get gettingReadyBody => 'Pode demorar mais alguns segundos.';

  @override
  String get checkinHint => 'Diga ou escreva o que quer concluir.';

  @override
  String get sayItInstead => 'Dizer em voz alta';

  @override
  String get planning => 'A criar o seu plano…';

  @override
  String get planningSemantics => 'A escolher apps para o seu plano';

  @override
  String get chooseAppsYourself => 'Escolha as apps';

  @override
  String get chooseAppsBody =>
      'O Curre não conseguiu criar este plano online. Escolha as apps de que precisa e continue.';

  @override
  String get useThisPlan => 'Usar este plano';

  @override
  String get planReady => 'O seu plano está pronto';

  @override
  String onHomeUntil(String time) {
    return 'No ecrã inicial até às $time';
  }

  @override
  String get whyNow => 'Porquê agora?';

  @override
  String whyNeedAppNow(String app) {
    return 'Para que precisa do $app agora?';
  }

  @override
  String get whyNowHelp =>
      'Diga o que vai fazer, para quem e durante quanto tempo. O Curre abre a app exatamente onde precisa.';

  @override
  String get yourReason => 'O seu motivo';

  @override
  String get reasonHint => 'responder à Ada sobre o ensaio';

  @override
  String yourPlan(String plan) {
    return 'O seu plano: $plan';
  }

  @override
  String get oneMoreTry =>
      'Mais uma tentativa: diga exatamente o que vai fazer.';

  @override
  String get bringItBack => 'Trazer de volta';

  @override
  String get askAgain => 'Perguntar de novo';

  @override
  String get readingReason => 'A ler o seu motivo';

  @override
  String get readingReasonProgress => 'A ler o seu motivo…';

  @override
  String guardQuote(String quote) {
    return 'Estas palavras parecem uma instrução para o Curre: “$quote”';
  }

  @override
  String openAfter(String duration) {
    return 'Abrir após $duration';
  }

  @override
  String get saveForLater => 'Guardar para mais tarde';

  @override
  String appOpensIn(String app) {
    return '$app abre em';
  }

  @override
  String appOpensInDuration(String app, String duration) {
    return '$app abre em $duration';
  }

  @override
  String get waitUnavailableBody =>
      'O Curre não conseguiu verificar o seu motivo, por isso a app abre após uma breve espera.';

  @override
  String get waitAllowedBody => 'Escolheu esperar, e isso é permitido.';

  @override
  String get waitCancelHelp =>
      'Saia deste ecrã para cancelar. Se esperar, isso aparecerá no seu histórico.';

  @override
  String outcomeOpenApp(String app) {
    return 'Abre $app';
  }

  @override
  String outcomeOpenAt(String destination) {
    return 'Abre em $destination';
  }

  @override
  String get outcomeSpecify => 'O que vai fazer exatamente?';

  @override
  String get outcomeFlagged => 'Isso parece uma instrução, não um motivo';

  @override
  String get outcomeUnavailable => 'Não foi possível verificar o seu motivo';

  @override
  String youHaveMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
    );
    return 'Tem $_temp0.';
  }

  @override
  String chatWith(String target) {
    return 'Conversar com $target';
  }

  @override
  String openDestination(String destination) {
    return 'Abrir $destination';
  }

  @override
  String get savedForNextPlan =>
      'Guardado. Volta quando fizer o próximo plano.';

  @override
  String get couldNotSave =>
      'O Curre não conseguiu guardar isso neste telefone. Tente novamente.';

  @override
  String get settingsSubtitle => 'As alterações afetam apenas o Curre.';

  @override
  String todayPercent(int percent) {
    return 'Hoje está $percent por cento concluído';
  }

  @override
  String get oneSentenceHome =>
      'Uma frase. Só o que indicar aparece no ecrã inicial.';

  @override
  String get yourPlanLabel => 'O seu plano';

  @override
  String get planHint => 'Aprender o acorde sol no YouTube até às 7';

  @override
  String get sayYourPlan => 'Dizer o seu plano';

  @override
  String get gettingAppsReady => 'A preparar as suas apps…';

  @override
  String get choosingApps => 'A escolher apps';

  @override
  String lookingThroughApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return 'A ver $_temp0';
  }

  @override
  String get useTheseApps => 'Usar estas apps';

  @override
  String get heresYourPlan => 'Aqui está o seu plano';

  @override
  String get backToHome => 'Voltar ao ecrã inicial';

  @override
  String get changePlan => 'Alterar o plano';

  @override
  String get fallbackConnect => 'Não foi possível ligar agora';

  @override
  String get fallbackTimeout => 'Demorou demasiado';

  @override
  String get fallbackReadPlan => 'O Curre não conseguiu ler esse plano';

  @override
  String get fallbackPlan => 'O Curre não conseguiu planear agora';

  @override
  String get fallbackNetworkBody =>
      'Verifique a internet e tente novamente, ou escolha as apps abaixo.';

  @override
  String get fallbackBody =>
      'Tente novamente dentro de instantes, ou escolha as apps abaixo.';

  @override
  String openedHiddenApp(String app) {
    return 'Abriu $app. É uma das suas apps ocultas.';
  }

  @override
  String appIsHidden(String app) {
    return '$app está nas suas apps ocultas.';
  }

  @override
  String openNoChatBody(String app, String minutes) {
    return 'O Curre não encontrou uma conversa correspondente neste telefone, por isso abre $app. $minutes';
  }

  @override
  String laterBody(String duration, String app) {
    return 'Parece navegação, por isso pode esperar. Guarde para mais tarde ou espere $duration para abrir $app agora.';
  }

  @override
  String specifyBody(String duration, String app) {
    return 'Diga um pouco mais sobre o que vai fazer, ou espere $duration para abrir $app.';
  }

  @override
  String flaggedBody(String app, String duration) {
    return 'Diga ao Curre o que vai fazer em $app. Ou espere $duration para a abrir.';
  }

  @override
  String unavailableBody(String app, String duration) {
    return 'Sem problema: $app abre após esperar $duration. Também pode tentar novamente.';
  }

  @override
  String untilAppOpens(String duration, String app) {
    return '$duration até $app abrir';
  }

  @override
  String get querySearch => 'Pesquisar';

  @override
  String get queryDraft => 'Rascunho';

  @override
  String get queryNewEvent => 'Novo evento';

  @override
  String get queryOpenWith => 'Abrir app com';

  @override
  String get kindTask => 'Uma tarefa';

  @override
  String get kindPerson => 'Alguém espera';

  @override
  String get kindTimeSensitive => 'Não pode esperar';

  @override
  String get kindBrowse => 'Apenas navegar';

  @override
  String get kindUnclear => 'Ainda não está claro';

  @override
  String confidencePercent(String label, int percent) {
    return '$label, confiança de $percent por cento';
  }

  @override
  String get outcomeGlyphOpen => 'Abre';

  @override
  String get outcomeGlyphLater => 'Agora não';

  @override
  String get outcomeGlyphSpecify => 'Precisa de mais detalhes';

  @override
  String get outcomeGlyphFlagged => 'Não é um motivo';

  @override
  String get outcomeGlyphUnavailable => 'Não foi possível verificar';

  @override
  String get alwaysOnHome => 'Sempre no ecrã inicial';

  @override
  String get pressHoldApp =>
      'Mantenha uma app premida para a abrir normalmente.';

  @override
  String get quietNudgeQuestion =>
      'Quer um aviso discreto quando o tempo terminar?';

  @override
  String get quietNudgeBody =>
      'O Curre pode avisar quando o plano ou o tempo de uma app terminar. Sem som, vibração ou anúncios.';

  @override
  String get quietNudgeYes => 'Sim, avisar-me';

  @override
  String get sayOneSentence =>
      'Diga numa frase. O Curre coloca no ecrã inicial apenas as apps necessárias.';

  @override
  String get planNow => 'Planear agora';

  @override
  String tasksReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarefas prontas',
      one: '1 tarefa pronta',
    );
    return '$_temp0';
  }

  @override
  String tasksDone(int done, int count) {
    return '$done de $count concluídas';
  }

  @override
  String yourSession(String session) {
    return 'A sua $session';
  }

  @override
  String untilTime(String time) {
    return 'até às $time';
  }

  @override
  String get changeThisPlan => 'Alterar este plano';

  @override
  String get onHomeNow => 'No ecrã inicial agora';

  @override
  String get alwaysAppsBelow => 'As suas apps permanentes estão abaixo.';

  @override
  String get tapStraightThere => 'Toque numa para ir diretamente.';

  @override
  String get nothingPlanned => 'Ainda não há nada planeado';

  @override
  String get nothingPlannedBody => 'Planeie o dia e as apps aparecerão aqui.';

  @override
  String get alwaysAvailable => 'Sempre disponível';

  @override
  String get doneWithProof => 'Concluída, com prova';

  @override
  String get doneWaiting => 'Concluída · a sua nota aguarda verificação';

  @override
  String get doneAddNote => 'Concluída · toque para adicionar uma nota';

  @override
  String get doneToday => 'Concluído hoje';

  @override
  String get show => 'Mostrar';

  @override
  String get hide => 'Ocultar';

  @override
  String get todaySunUp => 'O sol de hoje já nasceu';

  @override
  String get todaySun => 'O sol de hoje';

  @override
  String allDoneSession(String session) {
    return 'Tudo concluído nesta $session';
  }

  @override
  String get allDoneBody =>
      'Todas as tarefas deste plano estão concluídas. Pode terminá-lo e voltar a planear quando quiser.';

  @override
  String get endPlanNow => 'Terminar plano agora';

  @override
  String get endPlanQuestion => 'Terminar este plano agora?';

  @override
  String get endPlanBody =>
      'As tarefas saem do ecrã inicial. Pode voltar a planear quando quiser.';

  @override
  String get keepIt => 'Manter';

  @override
  String get endPlan => 'Terminar plano';

  @override
  String get planEnded => 'Plano terminado.';

  @override
  String get undo => 'Anular';

  @override
  String get tapStart => 'Toque em Começar quando iniciar';

  @override
  String get start => 'Começar';

  @override
  String startedAt(String time) {
    return 'Iniciada às $time · toque quando terminar';
  }

  @override
  String get awayFromPhone => 'Longe do telemóvel';

  @override
  String get you => 'Você';

  @override
  String get closeProfile => 'Fechar perfil';

  @override
  String get yourFace => 'O seu rosto';

  @override
  String get pickYourFace => 'Escolha o que mais combina consigo.';

  @override
  String get useInitial => 'Usar a minha inicial';

  @override
  String get proofDays => 'Dias com prova';

  @override
  String get bestRun => 'Melhor sequência';

  @override
  String get cloudDays => 'Dias de descanso';

  @override
  String get history => 'Histórico';

  @override
  String get yourName => 'O seu nome';

  @override
  String get saveName => 'Guardar nome';

  @override
  String get editName => 'Editar nome';

  @override
  String get app => 'App';

  @override
  String get quietNudgeOn =>
      'Os avisos discretos estão ativos. Pode escolhê-los nas definições do Curre.';

  @override
  String get quietNudgeOff =>
      'Sem problema. Pode ativar os avisos mais tarde nas definições do Curre.';

  @override
  String planPercent(int percent) {
    return 'Este plano está $percent por cento concluído';
  }

  @override
  String appsReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prontas',
      one: '1 pronta',
    );
    return '$_temp0';
  }

  @override
  String appBackForNow(String app) {
    return '$app voltou por agora';
  }

  @override
  String doneDoorSemantics(String app, String state, String destination) {
    return '$app, $state, abre $destination';
  }

  @override
  String tasksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarefas',
      one: '1 tarefa',
    );
    return '$_temp0';
  }

  @override
  String doneTodayShow(String count) {
    return 'Concluído hoje, $count. Mostrar';
  }

  @override
  String doneTodayCount(int count) {
    return 'Concluído hoje · $count';
  }

  @override
  String get endPlanFailed =>
      'O Curre não conseguiu terminar o plano. Tente novamente.';

  @override
  String get planTimeUp => 'O tempo desse plano já terminou.';

  @override
  String get doorOpenFailed =>
      'Não abriu. Mantenha a app premida para a abrir normalmente.';

  @override
  String copiedSearch(String target) {
    return '“$target” foi copiado. Cole-o na caixa de pesquisa.';
  }

  @override
  String get addProof => 'Adicionar prova';

  @override
  String get snoozeTenMinutes => 'Adiar 10 min';

  @override
  String get focusDone => 'O seu período de foco terminou';

  @override
  String focusDoneNotification(String days) {
    return 'Veja como correram estes $days e escolha o que vem a seguir.';
  }

  @override
  String sessionAlmostDone(String session) {
    return 'A sua $session está quase a terminar';
  }

  @override
  String get planEndsTenMinutes =>
      'O seu plano termina em 10 minutos. Escolha o que vem a seguir.';

  @override
  String get addYourProof => 'Adicione a sua prova';

  @override
  String get proofNotificationBody =>
      'Uma nota curta sobre o que concluiu conta como prova.';

  @override
  String grantOngoingBody(String task) {
    return '$task · A app volta a ficar oculta quando o tempo terminar.';
  }

  @override
  String appHiddenAgain(String app) {
    return '$app voltou a ficar oculta';
  }

  @override
  String grantExpiredBody(int minutes, String reason) {
    return 'Os seus $minutes min para $reason terminaram.';
  }

  @override
  String get whatDidYouGetDone => 'O que concluiu?';

  @override
  String get onboardingSaveFailed =>
      'O Curre não conseguiu guardar as suas respostas neste telefone. Tente novamente.';

  @override
  String get welcomeCurre => 'Bem-vindo ao Curre';

  @override
  String get aboutYou => 'Sobre si';

  @override
  String get yourApps => 'As suas apps';

  @override
  String get yourHomeScreen => 'O seu ecrã inicial';

  @override
  String get yourFirstPlan => 'O seu primeiro plano';

  @override
  String get onboardingWelcomeQuestion =>
      'Pega no telefone para uma coisa e perde uma hora?';

  @override
  String get whatShouldCurreCallYou => 'Como quer que o Curre lhe chame?';

  @override
  String get whatPullsYouIn => 'O que o prende?';

  @override
  String get makeCurreHomeHeadline => 'Use o Curre como ecrã inicial.';

  @override
  String get withoutCurre => 'Sem o Curre';

  @override
  String get withoutCurreBody =>
      'Uma vista rápida. O conteúdo prende-o. Passou uma hora.';

  @override
  String get withCurre => 'Com o Curre';

  @override
  String get withCurreBody =>
      'Diga do que precisa. O Curre abre a app no lugar certo.';

  @override
  String get historyContactsStay =>
      'O seu histórico e contactos ficam neste telefone.';

  @override
  String get howCurrePrivate => 'Como o Curre protege a sua privacidade';

  @override
  String get namePrivacyNote =>
      'Apenas para a saudação no ecrã inicial. Fica neste telefone.';

  @override
  String get addNameError => 'Adicione um nome, mesmo que seja uma alcunha.';

  @override
  String get pickFaceOrInitial =>
      'Escolha um rosto ou mantenha a inicial. Pode mudar quando quiser.';

  @override
  String get whatsFocusFor => 'Para que serve este período de foco?';

  @override
  String get focusOnboardingBody =>
      'O Curre ajuda mais durante um período com data de fim. Depois, o telefone volta ao normal. Pode ignorar se ainda não tiver a certeza.';

  @override
  String get pickPullAppsBody =>
      'Escolha as apps em que uma vista rápida vira uma hora. O Curre oculta apenas estas e pergunta “Porquê agora?” ao abri-las. As restantes abrem normalmente.';

  @override
  String showAllApps(int count) {
    return 'Mostrar as $count apps';
  }

  @override
  String get changeHiddenAnyTime =>
      'Oculte outra app ou recupere uma em Apps ocultas ou nas definições do Curre.';

  @override
  String get androidChooseCurre =>
      'O Android perguntará que app usar como ecrã inicial. Escolha o Curre.';

  @override
  String get homePointPlan =>
      'O ecrã inicial mostra o seu plano. As apps não ocultas estão em Todas as apps e abrem normalmente.';

  @override
  String get homePointHidden =>
      'Só as apps escolhidas ficam ocultas. Ao abrir uma, o Curre pergunta “Porquê agora?”.';

  @override
  String get homePointDoor =>
      'Toque numa app no ecrã inicial para ir diretamente à tarefa.';

  @override
  String get curreIsHomeNow => 'O Curre é agora o seu ecrã inicial.';

  @override
  String get switchHomeAnyTime =>
      'Mudou de ideias? Pode trocar de ecrã inicial nas definições do Curre.';

  @override
  String get curreNotHomeHelp =>
      'O Curre ainda não é o seu ecrã inicial. Tente novamente ou abra as definições do ecrã inicial e escolha o Curre.';

  @override
  String get chooseCurreList => 'Escolha o Curre na lista e volte aqui.';

  @override
  String get chooseCurreDefaultApps =>
      'Toque em “App de início”, escolha o Curre e volte aqui.';

  @override
  String get chooseCurreSettings =>
      'Nas Definições, procure “App de início” ou abra Apps e Apps predefinidas; escolha o Curre e volte.';

  @override
  String get chooseCurrePhoneSettings =>
      'Abra as Definições do telefone, procure “App de início”, escolha o Curre e volte.';

  @override
  String get planExampleGuitar => 'Aprender o acorde sol no YouTube até às 7';

  @override
  String get planExamplePlaylist => 'Ouvir a lista de domingo no Spotify';

  @override
  String get planExampleMaps => 'Encontrar o caminho para o estúdio no Maps';

  @override
  String get onboardingPlanHelp =>
      'Diga numa frase: a app, o que fará e até quando. O Curre leva apenas isso para o ecrã inicial.';

  @override
  String get startFromExample => 'Ou comece com um destes exemplos:';

  @override
  String morningStartNote(String time) {
    return 'O Curre pergunta para que serve a sua manhã a partir das $time. Altere nas definições.';
  }

  @override
  String get showMeHow => 'Mostrar como';

  @override
  String callMe(String name) {
    return 'Chame-me $name';
  }

  @override
  String get pickAtLeastOne => 'Escolha pelo menos uma';

  @override
  String get hideThisOne => 'Ocultar esta';

  @override
  String hideThese(int count) {
    return 'Ocultar estas $count';
  }

  @override
  String get noneOfThese => 'Nenhuma';

  @override
  String get makeCurreMyHome => 'Usar o Curre como ecrã inicial';

  @override
  String get openHomeSettings => 'Abrir definições do ecrã inicial';

  @override
  String get planLater => 'Planeio mais tarde';

  @override
  String useExample(String text) {
    return 'Usar exemplo: $text';
  }

  @override
  String get findApp => 'Procurar uma app';

  @override
  String noAppMatches(String query) {
    return 'Nenhuma app corresponde a “$query”.';
  }

  @override
  String get everyAppHidden => 'Todas as apps deste telefone estão ocultas.';

  @override
  String openApp(String app) {
    return 'Abrir $app';
  }

  @override
  String get hideThisApp => 'Ocultar esta app';

  @override
  String hideApp(String app) {
    return 'Ocultar $app';
  }

  @override
  String appHiddenAsk(String app) {
    return '$app está oculta. Ao abrir, o Curre pergunta primeiro “Porquê agora?”.';
  }

  @override
  String get planApps => 'Apps que os seus planos podem usar';

  @override
  String get planAppsHelp =>
      'Ao planear, o Curre escolhe entre estas. Selecione de 2 a 30.';

  @override
  String get hiddenAppsHelp =>
      'Só estas saem do ecrã inicial e perguntam primeiro “Porquê agora?”. As restantes abrem normalmente.';

  @override
  String get alwaysOnHomeHelp =>
      'Estas ficam no ecrã inicial todo o dia, sem precisar de plano.';

  @override
  String pickedCount(int count) {
    return '$count escolhidas';
  }

  @override
  String hiddenCount(int count) {
    return '$count ocultas';
  }

  @override
  String onHomeCount(int count) {
    return '$count no ecrã inicial';
  }

  @override
  String planAppsMinimum(int count) {
    return 'Os planos precisam de pelo menos $count apps.';
  }

  @override
  String planAppsMaximum(int count) {
    return 'Já escolheu $count. Desmarque uma para adicionar outra.';
  }

  @override
  String appAlwaysOnHome(String app) {
    return '$app está sempre no ecrã inicial.';
  }

  @override
  String get privacyDetails => 'Detalhes de privacidade';

  @override
  String get privacySubtitle =>
      'O que sai deste telefone e durante quanto tempo.';

  @override
  String get privacyReadOnline => 'O que é lido online';

  @override
  String get privacyReadOnlineBody =>
      'O seu plano, os nomes das apps, o motivo para abrir uma app oculta e as notas enviadas depois de uma tarefa são lidos online para o Curre responder.';

  @override
  String get privacyCopyTime => 'Durante quanto tempo pode existir uma cópia';

  @override
  String get privacyCopyTimeBody =>
      'O Curre não guarda cópias online. O serviço de IA pode manter uma resposta bem-sucedida, incluindo palavras citadas, durante cerca de um dia para devolver a mesma resposta numa nova tentativa. Depois elimina-a.';

  @override
  String get privacyStaysHere => 'O que fica aqui';

  @override
  String get privacyStaysHereBody =>
      'Os seus contactos, nomes de conversas, utilização de apps e histórico ficam neste telefone. Pode limpar planos, motivos e notas nas definições do Curre.';

  @override
  String get privacyHistoryHides => 'O que o Histórico oculta';

  @override
  String get privacyHistoryHidesBody =>
      'Antes de guardar um motivo ou nota verificados, o Curre procura nomes, telefones, e-mails, moradas e dados de pagamento. O que encontra torna-se uma etiqueta como [nome] ou [telefone]. Se a verificação não estiver disponível, as suas palavras ficam como estão.';

  @override
  String get privacyLogs =>
      'O Curre regista apenas se um pedido funcionou e quanto demorou. As suas palavras não entram nos registos online.';

  @override
  String get savedForLaterTitle => 'Guardado para mais tarde';

  @override
  String get laterNoneFits =>
      'Nada do que guardou combina com este plano, por isso fica para uma altura melhor.';

  @override
  String get laterBestFirst => 'Primeiro, a melhor combinação com este plano.';

  @override
  String get laterNewestFirst => 'Mais recentes primeiro.';

  @override
  String get laterOneMore => 'Mais 1 fica para outra altura.';

  @override
  String laterMore(int count) {
    return 'Mais $count ficam para outra altura.';
  }

  @override
  String get notToday => 'Hoje não';

  @override
  String get sectionYourFocus => 'O seu foco';

  @override
  String get sectionYourDay => 'O seu dia';

  @override
  String get dayStartsHelp =>
      'No início de cada parte do dia, o Curre pergunta para que serve.';

  @override
  String startsAt(String time) {
    return 'Começa às $time';
  }

  @override
  String get sectionYourApps => 'As suas apps';

  @override
  String get defaultEssentials => 'Telefone, Mensagens e Definições';

  @override
  String defaultEssentialsMore(int count) {
    return 'Telefone, Mensagens, Definições e mais $count';
  }

  @override
  String get strictQuestion => 'Quão rigoroso deve ser o Curre?';

  @override
  String get sectionHiddenApps => 'Apps ocultas';

  @override
  String get askWhyHidden =>
      'Perguntar “Porquê agora?” ao abrir uma app oculta';

  @override
  String get needsAndroidOk => 'Primeiro precisa da sua autorização no Android';

  @override
  String get pausedOtherHome => 'Em pausa enquanto usa outro ecrã inicial';

  @override
  String get restingToday => 'Hoje é dia de descanso. Volta amanhã de manhã.';

  @override
  String get askWhyOn =>
      'Ativo, também em apps recentes, notificações e ligações';

  @override
  String get keepHiddenQuiet => 'Manter as apps ocultas em silêncio';

  @override
  String get focusEndedNothingHeld =>
      'O seu período terminou, por isso nada é retido';

  @override
  String get heldUntilBack => 'Ativo. Retidas até a app voltar.';

  @override
  String get turnOnUsageAccess => 'Ativar Acesso à utilização';

  @override
  String get turnOnNotificationAccess => 'Ativar acesso às notificações';

  @override
  String get sectionQuietNudges => 'Avisos discretos';

  @override
  String get allowNotifications => 'Permitir notificações';

  @override
  String get notificationsAllowed =>
      'Permitidas. Os avisos escolhidos podem aparecer.';

  @override
  String get notificationsNotAllowed =>
      'Ainda não permitidas. Toque para permitir.';

  @override
  String get notificationsAndroidControls =>
      'O Android decide se os avisos escolhidos podem aparecer';

  @override
  String get sectionVoiceTyping => 'Escrita por voz';

  @override
  String get sectionYourName => 'O seu nome';

  @override
  String get nameInGreeting => 'Nome na saudação';

  @override
  String get sectionHomeScreen => 'O seu ecrã inicial';

  @override
  String get sectionHistoryPrivacy => 'Histórico e privacidade';

  @override
  String get historySettingsBody =>
      'Os seus planos e as apps recuperadas nos últimos 30 dias. Apenas neste telefone.';

  @override
  String get privacySettingsBody =>
      'O que é lido online, o que fica aqui e quando as cópias são eliminadas';

  @override
  String get clearHistory => 'Limpar histórico';

  @override
  String get clearHistorySettingsBody =>
      'Eliminar deste telefone planos, motivos, notas e notificações perdidas';

  @override
  String get sectionAbout => 'Acerca';

  @override
  String get licences => 'Licenças';

  @override
  String get licencesBody =>
      'Os tipos de letra, ícones, ilustrações e escrita por voz usados pelo Curre';

  @override
  String get appLegalese => 'O Curre abre a tarefa, não a app.';

  @override
  String sessionStartsAt(String session) {
    return 'A sua $session começa às';
  }

  @override
  String get sessionOrderError =>
      'A manhã começa antes da tarde e a tarde antes da noite. Tente outra hora.';

  @override
  String sessionStartSaved(String session, String time) {
    return 'A sua $session começa agora às $time.';
  }

  @override
  String get nameSaved => 'Guardado. O Curre vai saudá-lo com este nome.';

  @override
  String get usageAccessDone =>
      'Concluído. O Curre perguntará “Porquê agora?” ao abrir uma app oculta.';

  @override
  String get accessStillOff =>
      'Continua desativado. Pode ativá-lo aqui quando quiser.';

  @override
  String get notificationAccessDone =>
      'Concluído. As apps ocultas ficam em silêncio até voltarem.';

  @override
  String get notificationsPermissionDone =>
      'As notificações estão permitidas. O Curre usará os avisos escolhidos acima.';

  @override
  String get notificationsPermissionOff =>
      'As notificações não estão permitidas. Pode permiti-las para o Curre nas Definições do telefone.';

  @override
  String get chooseHomeApp =>
      'Toque em “App de início” e escolha a que quiser.';

  @override
  String get searchHomeApp =>
      'As Definições abriram. Procure “App de início” ou abra Apps e Apps predefinidas e escolha.';

  @override
  String get openSettingsHomeApp =>
      'Abra as Definições do telefone e procure “App de início”. Escolha a que quiser.';

  @override
  String get curreNotHomeSettings =>
      'O Curre ainda não é o seu ecrã inicial. Abra as Definições, procure “App de início” e escolha o Curre.';

  @override
  String get clearHistoryQuestion => 'Limpar o seu histórico?';

  @override
  String get clearHistoryBody =>
      'Isto elimina planos anteriores, motivos para recuperar apps, notas após tarefas e notificações perdidas. Os dias com prova, o plano de hoje e os tempos ativos ficam como estão.';

  @override
  String get historyCleared => 'Histórico limpo.';

  @override
  String get historyClearFailed =>
      'O Curre não conseguiu limpar o histórico. Tente novamente.';

  @override
  String get switchHome => 'Mudar para outro ecrã inicial';

  @override
  String get curreNotHomeBody =>
      'O Curre não é o seu ecrã inicial agora. Os seus planos e histórico continuam aqui quando precisar.';

  @override
  String get switchHomeBody =>
      'Quer outro ecrã inicial por algum tempo? Sem problema. O Android permite escolher a app que abre ao premir Início. Os seus planos e histórico ficam neste telefone e pode voltar quando quiser.';

  @override
  String get openHomeScreenSettings => 'Abrir definições do ecrã inicial';

  @override
  String get chooseHomeScreenApp => 'Escolher uma app de ecrã inicial';

  @override
  String get homeSettingsPath =>
      'Se o telefone abrir as Definições, procure Apps, depois Apps predefinidas e App de início.';

  @override
  String get nudgesHelp =>
      'Escolha os avisos silenciosos enviados pelo Curre. Desativar um também cancela os desse tipo que estejam à espera.';

  @override
  String get planYourDay => 'Planear o seu dia';

  @override
  String get eachSessionBegins => 'No início de cada parte do dia';

  @override
  String get morningBegins => 'Uma vez por dia, no início da manhã';

  @override
  String get afternoonEveningToo => 'Também à tarde e à noite';

  @override
  String get afternoonEveningBegins => 'Também no início da tarde e da noite';

  @override
  String get planEnding => 'Fim do plano';

  @override
  String get tenMinutesBeforePlan => 'Dez minutos antes do fim do plano';

  @override
  String get appTimeUp => 'Tempo da app terminado';

  @override
  String get hiddenAppTimeEnds => 'Quando termina o tempo de uma app oculta';

  @override
  String get addProofLater => 'Alguns minutos depois do fim do plano';

  @override
  String get focusEnds => 'Fim do foco';

  @override
  String get focusEndsMorning => 'Na manhã em que termina o seu período';

  @override
  String get turnAllNudgesOff => 'Desativar todos os avisos';

  @override
  String get turnAllNudgesOn => 'Ativar todos os avisos';

  @override
  String get gentle => 'Suave';

  @override
  String get balanced => 'Equilibrado';

  @override
  String get strict => 'Rigoroso';

  @override
  String get strictnessBody =>
      'Ao recuperar uma app oculta, o Curre verifica o motivo. Quanto mais rigoroso, mais claro deve ser o motivo antes de abrir a app.';

  @override
  String get hiddenChoiceNone => 'Nenhuma. Todas as apps abrem normalmente.';

  @override
  String get hiddenChoiceOne => '1 app. Só ela pergunta “Porquê agora?”.';

  @override
  String hiddenChoiceMany(int count) {
    return '$count apps. Só estas perguntam “Porquê agora?”.';
  }

  @override
  String get missedNotifications => 'Notificações perdidas';

  @override
  String missedFromHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificações de apps ocultas',
      one: '1 notificação de apps ocultas',
    );
    return '$_temp0';
  }

  @override
  String heldUntilAppBack(int count) {
    return '$count retidas até a app voltar';
  }

  @override
  String bringBackApp(String app) {
    return 'Recuperar $app';
  }

  @override
  String get restDayTheyOpen => 'Dia de descanso: abrem sem perguntar';

  @override
  String get nothingHidden =>
      'Nada está oculto. Todas as apps abrem normalmente em Todas as apps.';

  @override
  String get hiddenAppsOut =>
      'As suas apps ocultas estão disponíveis para o plano ou durante algum tempo.';

  @override
  String get hideAnotherApp => 'Ocultar outra app';

  @override
  String notificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificações',
      one: '1 notificação',
    );
    return '$_temp0';
  }

  @override
  String get hiddenAppsTip =>
      'Aqui esperam apenas as apps que escolheu ocultar. Toque numa para a recuperar por algum tempo.';

  @override
  String get gotIt => 'Entendi';

  @override
  String get appOpenFailed => 'A app não abriu. Pode já não estar instalada.';

  @override
  String get missedNotificationsBody =>
      'Retidas discretamente enquanto as apps estavam ocultas e devolvidas quando a app volta. Nada sai deste telefone.';

  @override
  String get nothingHeld => 'Nada retido agora.';

  @override
  String get held => 'Retida';

  @override
  String get givenBack => 'Devolvida';

  @override
  String openNotificationApp(String app) {
    return 'Abrir $app';
  }

  @override
  String get openCurreAppInfo => 'Abrir informações do Curre';

  @override
  String get openSettingsAppsCurre =>
      'Abra as Definições do telefone, depois Apps e Curre.';

  @override
  String get restrictedStillOff =>
      'Continua desativado. Sem problema, o Curre funciona sem este acesso. Se o Android disser que a definição está restringida, permita-a uma vez:';

  @override
  String get restrictedHelp =>
      'Se o Android disser que a definição está restringida, permita-a uma vez:';

  @override
  String get restrictedStepOne => 'Abra as informações do Curre.';

  @override
  String get restrictedStepTwo =>
      'Toque nos três pontos no canto superior direito.';

  @override
  String get restrictedStepThree =>
      'Toque em “Permitir definições restringidas”.';

  @override
  String get restrictedStepFour => 'Confirme com o PIN ou impressão digital.';

  @override
  String get restrictedStepFive => 'Volte aqui e ative o acesso.';

  @override
  String get noProblemSettings =>
      'Sem problema. Está sempre nas definições do Curre.';

  @override
  String get allSet => 'Tudo pronto.';

  @override
  String get usageAccessAllSet =>
      'O Curre perguntará “Porquê agora?” ao abrir uma app oculta.';

  @override
  String get notificationAccessAllSet =>
      'As apps ocultas ficam em silêncio até voltarem.';

  @override
  String get askWhyPrompt =>
      'Perguntar “Porquê agora?” ao abrir uma app oculta?';

  @override
  String get quietPrompt => 'Manter as apps ocultas em silêncio?';

  @override
  String get askWhyPromptBody =>
      'As apps ocultas podem voltar através das apps recentes, ligações ou notificações. O Curre também pode perguntar nessa altura. Verifica apenas que app abriu, nunca o que está no ecrã.';

  @override
  String get tryAgainAccess => 'Tentar novamente';

  @override
  String get hiddenNamesFallback => 'as apps que ocultar';

  @override
  String hiddenNamesTwo(String first, String second) {
    return '$first e $second';
  }

  @override
  String hiddenNamesMore(String first, String second, int count) {
    return '$first, $second e mais $count';
  }

  @override
  String quietPromptBody(String apps) {
    return 'O Curre pode reter discretamente as notificações de $apps e devolver todas quando abrir a app. As restantes notificam normalmente e as chamadas e alarmes passam sempre.';
  }

  @override
  String get focusPurposeExams => 'Exames';

  @override
  String get focusPurposeDeadline => 'Um prazo';

  @override
  String get focusPurposeHabit => 'Quebrar um hábito';

  @override
  String get focusPurposeOther => 'Outra coisa';

  @override
  String get focusHintExams => 'Passar nos exames de matemática';

  @override
  String get focusHintDeadline => 'Terminar o portefólio';

  @override
  String get focusHintHabit => 'Deixar de abrir redes na cama';

  @override
  String get focusHintOther => 'O que quero mudar';

  @override
  String get focusEndExams => 'Criou espaço para o trabalho importante.';

  @override
  String get focusEndDeadline => 'Levou este trabalho até à meta.';

  @override
  String get focusEndHabit => 'Deu espaço ao novo hábito para crescer.';

  @override
  String get focusEndOther => 'Voltou sempre ao que importava.';

  @override
  String get focusLengthWeek => '1 semana';

  @override
  String get focusLengthTwoWeeks => '2 semanas';

  @override
  String get focusLengthThreeWeeks => '3 semanas';

  @override
  String get focusLengthThirtyDays => '30 dias';

  @override
  String get focusGoalLabel => 'O seu objetivo, em poucas palavras (opcional)';

  @override
  String get untilWhen => 'Até quando?';

  @override
  String get pickDate => 'Escolher uma data';

  @override
  String focusEndsSummary(String date, String days) {
    return 'Termina a $date, dentro de $days. Pode alterar depois.';
  }

  @override
  String get focusEndsOn => 'O foco termina em';

  @override
  String get focusSaveFailed =>
      'O Curre não conseguiu guardar o seu foco. Tente novamente.';

  @override
  String get focusQuestion => 'Para que serve este período de foco?';

  @override
  String get focusPickerBody =>
      'O Curre ajuda mais num período com fim: exames, um prazo ou um hábito que quer quebrar.';

  @override
  String get pickFocusPurpose => 'Escolha para que serve';

  @override
  String get startMyFocus => 'Começar o meu foco';

  @override
  String get setFocusQuestion => 'Definir um foco?';

  @override
  String get focusOfferBody =>
      'O Curre ajuda mais num período com fim: exames, um prazo ou um hábito a quebrar. Escolha um e quando termina.';

  @override
  String get maybeLater => 'Talvez mais tarde';

  @override
  String get setFocus => 'Definir um foco';

  @override
  String get restDay => 'Dia de descanso';

  @override
  String get yourFocus => 'O seu foco';

  @override
  String get restDayBody =>
      'Hoje, as apps ocultas abrem sem perguntar, as notificações passam e os avisos ficam silenciosos. Os seus dias com prova estão seguros. Volta ao foco amanhã.';

  @override
  String focusLeft(String days, String date) {
    return 'Faltam $days · termina a $date';
  }

  @override
  String get backToFocusNow => 'Voltar ao foco agora';

  @override
  String get takeTodayOff => 'Descansar hoje';

  @override
  String nextRestDay(String date) {
    return 'Próximo descanso: $date';
  }

  @override
  String get today => 'hoje';

  @override
  String get tomorrow => 'amanhã';

  @override
  String get takeTodayOffQuestion => 'Descansar hoje?';

  @override
  String get takeTodayOffBody =>
      'Até amanhã de manhã, as apps ocultas abrem sem perguntar, as notificações passam e o Curre não envia avisos. Os seus dias com prova ficam seguros. Pode descansar um dia por semana.';

  @override
  String get keepGoing => 'Continuar';

  @override
  String get enjoyRestDay => 'Aproveite o descanso. Volta ao foco amanhã.';

  @override
  String focusSummaryDays(String days) {
    return '$days de foco.';
  }

  @override
  String focusSummaryWithRest(String days, String rests) {
    return '$days de foco, $rests.';
  }

  @override
  String restDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias de descanso',
      one: '1 dia de descanso',
    );
    return '$_temp0';
  }

  @override
  String get daysWithProof => 'dias com prova';

  @override
  String get tasksProved => 'tarefas provadas';

  @override
  String get hiddenAppsLeftClosed => 'apps ocultas que ficaram fechadas';

  @override
  String get startAnotherFocus => 'Começar outro período de foco';

  @override
  String get oldHomeScreen => 'Voltar ao meu ecrã inicial antigo';

  @override
  String get focusHistoryStays =>
      'O seu histórico e dias com prova ficam neste telefone de qualquer forma.';

  @override
  String get chooseOldHome =>
      'Escolha o ecrã inicial antigo na lista. O Curre deixa de perguntar e permite todas as notificações.';

  @override
  String get tapOldHome => 'Toque em “App de início” e escolha o ecrã antigo.';

  @override
  String get searchOldHome =>
      'As Definições abriram. Procure “App de início” e escolha o ecrã antigo.';

  @override
  String get openSettingsOldHome =>
      'Abra as Definições, procure “App de início” e escolha o ecrã antigo.';

  @override
  String get noFocusSet => 'Nenhum foco definido';

  @override
  String get focusSettingsEmpty =>
      'Escolha para que serve este período e quando termina.';

  @override
  String focusEndedOn(String date) {
    return 'Terminou a $date. Veja como correu no ecrã inicial.';
  }

  @override
  String focusEndsLeft(String date, String days) {
    return 'Termina a $date, faltam $days';
  }

  @override
  String get changeEndDate => 'Alterar data de fim';

  @override
  String weeklyRestNext(String date) {
    return 'Um dia de descanso por semana. Próximo: $date.';
  }

  @override
  String get endFocusNow => 'Terminar foco agora';

  @override
  String focusNowEnds(String date) {
    return 'O seu foco termina agora a $date.';
  }

  @override
  String get endFocusQuestion => 'Terminar o foco agora?';

  @override
  String get endFocusBody =>
      'O ecrã inicial mostra como correu e depois escolhe o que vem a seguir. O histórico e os dias com prova ficam guardados.';

  @override
  String get endFocus => 'Terminar foco';

  @override
  String get historySubtitle => 'Os últimos 30 dias · apenas neste telefone';

  @override
  String get whatHappened => 'O que aconteceu';

  @override
  String get historyEmptyTitle => 'Um início tranquilo.';

  @override
  String get historyEmptyBody =>
      'Os seus planos e as apps que recuperar aparecem aqui. Tudo fica neste telefone.';

  @override
  String plannedSessionsCount(int count) {
    return '$count de 21 planeados';
  }

  @override
  String get historyOverviewHelp =>
      'Cada quadrado é uma manhã, tarde ou noite dos últimos 7 dias. Os preenchidos começaram com um plano.';

  @override
  String sessionPlanState(String session, String state) {
    return '$session: $state';
  }

  @override
  String get planned => 'planeado';

  @override
  String get noPlan => 'sem plano';

  @override
  String proofCloudInHand(String detail) {
    return 'Tem um dia nuvem. $detail';
  }

  @override
  String get oneMoreProofToCloud =>
      'Falta 1 dia com prova para o próximo dia nuvem.';

  @override
  String moreProofToCloud(int count) {
    return 'Faltam $count dias com prova para o próximo dia nuvem.';
  }

  @override
  String proofDaysInAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias com prova no total',
      one: '1 dia com prova no total',
    );
    return '$_temp0';
  }

  @override
  String bestRunCount(int count) {
    return 'Melhor sequência $count';
  }

  @override
  String cloudDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias nuvem',
      one: '1 dia nuvem',
    );
    return '$_temp0';
  }

  @override
  String get historyProofHint =>
      'Depois de uma tarefa, diga o que mudou. Uma nota concreta acrescenta um dia com prova.';

  @override
  String historySessionPlan(String session) {
    String _temp0 = intl.Intl.selectLogic(session, {
      'morning': 'Plano da manhã',
      'afternoon': 'Plano da tarde',
      'evening': 'Plano da noite',
      'other': 'Plano',
    });
    return '$_temp0';
  }

  @override
  String endedEarlyAt(String ended, String planned) {
    return 'Terminou mais cedo às $ended; estava previsto até às $planned';
  }

  @override
  String waitedDuration(String duration) {
    return 'Esperou $duration';
  }

  @override
  String whyNowApp(String app) {
    return 'Porquê agora? · $app';
  }

  @override
  String get olderReasonMissing =>
      'O motivo não foi guardado nesta entrada antiga.';

  @override
  String appCameBack(String app) {
    return '$app voltou';
  }

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String openedAfterWaiting(String duration) {
    return 'Abriu depois de esperar $duration';
  }

  @override
  String get openedFromLater =>
      'Guardada para depois e aberta a partir de um plano';

  @override
  String get supportedProof => 'Prova apoiada';

  @override
  String get waitingToBeChecked => 'À espera de verificação';

  @override
  String get markedDone => 'Marcada como feita';

  @override
  String get noNote => 'Sem nota';

  @override
  String get personalDetailHidden => 'Dado pessoal ocultado';

  @override
  String get outcomeOpened => 'Abriu';

  @override
  String get outcomeNotNow => 'Agora não';

  @override
  String get outcomeNeededDetail => 'Faltaram pormenores';

  @override
  String get outcomeNotReason => 'Não era um motivo';

  @override
  String get outcomeCouldNotCheck => 'Não foi possível verificar';

  @override
  String get nextSunriseOneProof => 'Próximo nascer do sol: falta uma prova';

  @override
  String get noProofDaysYet => 'Ainda não há dias com prova';

  @override
  String proofDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias com prova',
      one: '1 dia com prova',
    );
    return '$_temp0';
  }

  @override
  String get todaysSunIsUp => 'o sol de hoje já nasceu';

  @override
  String get oneCloudInHand => 'um dia nuvem disponível';

  @override
  String get cloudDay => 'Dia nuvem';

  @override
  String runEndedAt(String days) {
    return 'Essa sequência terminou com $days.';
  }

  @override
  String get todaysProofStartsNext =>
      'A prova de hoje começa o próximo nascer do sol.';

  @override
  String get theNextSunrise => 'O próximo nascer do sol';

  @override
  String get dayProof => 'dia com prova';

  @override
  String get dayPending => 'nota à espera de verificação';

  @override
  String get dayNoProof => 'sem prova';

  @override
  String get dayCloud => 'dia nuvem';

  @override
  String get dayToday => 'hoje';

  @override
  String get dayFuture => 'ainda por vir';

  @override
  String get dayStillOpen => 'ainda aberto';

  @override
  String get startingToday => 'Começa hoje';

  @override
  String proofRunRange(String start, String end) {
    return 'De $start a $end';
  }

  @override
  String sinceDate(String date) {
    return 'Desde $date';
  }

  @override
  String get milestoneSeven =>
      'Sete dias com prova: os seus raios terminam agora em faíscas.';

  @override
  String get milestoneTwentyOne =>
      '21 dias com prova: um anel de luz aparece atrás do seu sol.';

  @override
  String get milestoneFifty =>
      '50 dias com prova: o seu sol usa um segundo anel.';

  @override
  String get cloudDayKeepsRun =>
      'Se passar um dia sem prova, mantém a sua sequência.';

  @override
  String weekdaySunUp(String weekday) {
    return 'O sol de $weekday já nasceu';
  }

  @override
  String earnedCloudDay(String detail) {
    return 'Ganhou um dia nuvem. $detail';
  }

  @override
  String get completionQuestion => 'O que mudou, terminou ou ficou claro?';

  @override
  String get oneSentenceEnough => 'Uma frase chega';

  @override
  String get addOneDetail => 'Acrescente um pormenor';

  @override
  String get addWhatChanged => 'Acrescente o que mudou';

  @override
  String proofMismatchPrompt(String detail) {
    return '“$detail” não corresponde à tarefa planeada. O que mudou, terminou ou ficou claro?';
  }

  @override
  String get proofFuturePrompt =>
      'Isso parece ser o que vem a seguir. O que mudou, terminou ou ficou claro?';

  @override
  String get proofUnrelatedPrompt =>
      'Diga como se liga ao seu plano. O que mudou, terminou ou ficou claro?';

  @override
  String get proofDetailPrompt =>
      'Um nome, um número ou um passo chega. O que mudou, terminou ou ficou claro?';

  @override
  String get justMarkDone => 'Apenas marcar como feita';

  @override
  String get readingYourNote => 'A ler a sua nota';

  @override
  String get readingYourNoteProgress => 'A ler a sua nota…';

  @override
  String get noteSaved => 'A sua nota está guardada';

  @override
  String get noteSavedBody =>
      'Não foi possível verificá-la agora. Será verificada quando voltar a estar online.';

  @override
  String get runSafeWhileWaiting =>
      'A sua sequência fica segura enquanto espera.';

  @override
  String get markedAsDone => 'Marcada como feita';

  @override
  String get markedDoneBody =>
      'Está no seu histórico. Os dias com prova vêm de uma nota sobre o que mudou.';

  @override
  String get noteCountsAsProof => 'A sua nota conta como prova.';

  @override
  String get oneMoreRay => 'Mais um raio';

  @override
  String get proofAdded => 'Prova acrescentada';

  @override
  String get profileSmiling => 'O seu perfil, a sorrir';

  @override
  String get sunOneRay => 'O sol de hoje, um raio: uma tarefa com prova';

  @override
  String sunManyRays(int count) {
    return 'O sol de hoje, $count raios: $count tarefas com prova';
  }

  @override
  String proofDayUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dias com prova',
      one: 'dia com prova',
    );
    return '$_temp0';
  }

  @override
  String get newRunStarts => 'Uma nova sequência começa aqui.';

  @override
  String get supported => 'Apoiada';

  @override
  String get backedByStart => 'Apoiada pelo início da tarefa e pela sua nota';

  @override
  String get backedByApp => 'Apoiada pela app que abriu e pela sua nota';

  @override
  String get voicePermissionExplanation =>
      'A Curre só ouve enquanto mantém o microfone premido ou lhe toca. A sua voz nunca sai do telemóvel.';

  @override
  String get voiceMicNeeded =>
      'A escrita por voz precisa do microfone. Também pode escrever.';

  @override
  String get voiceCouldNotStart =>
      'Não foi possível iniciar a escrita por voz. Também pode escrever.';

  @override
  String get voiceGettingReady =>
      'A escrita por voz está a preparar-se. Por agora, pode escrever.';

  @override
  String get voiceReadyOffline =>
      'Pronta. A escrita por voz já funciona sem internet.';

  @override
  String get voiceMicStillOff =>
      'O microfone continua desligado. Autorize-o para falar ou escreva.';

  @override
  String get voiceNothingHeard =>
      'Não ouvi nada. Tente de novo, um pouco mais perto do microfone.';

  @override
  String get voicePrivacyLine =>
      'Neste telemóvel · nada do que diz é guardado ou enviado';

  @override
  String get typeInstead => 'Escrever';

  @override
  String get gettingVoiceReady => 'A preparar a escrita por voz';

  @override
  String downloadNowSize(String size) {
    return 'Transferir agora · $size';
  }

  @override
  String get speakInsteadTyping => 'Fale em vez de escrever';

  @override
  String get allowMic => 'Permitir o microfone';

  @override
  String get micOffForCurre => 'O microfone está desligado para a Curre';

  @override
  String micSettingsBody(String privacy) {
    return 'Ative o microfone para a Curre nas definições do telemóvel e volte. $privacy';
  }

  @override
  String get openPhoneSettings => 'Abrir definições do telemóvel';

  @override
  String get tapOrHoldMic => 'Toque ou mantenha o microfone premido e fale.';

  @override
  String get listeningHeld => 'A ouvir… solte quando terminar.';

  @override
  String get listeningPause =>
      'A ouvir… faça uma pausa quando terminar ou toque no microfone.';

  @override
  String get writingSaid => 'A escrever o que disse';

  @override
  String get writingProgress => 'A escrever…';

  @override
  String get voiceStartFailed => 'Não foi possível iniciar a escrita por voz';

  @override
  String get micStartFailed => 'O microfone não arrancou';

  @override
  String voiceModelFix(String size) {
    return 'Voltar a transferir os ficheiros de voz ($size) costuma resolver.';
  }

  @override
  String get voiceMicBusy =>
      'Se outra app estiver a usar o microfone, feche-a e tente novamente.';

  @override
  String get downloadAgain => 'Transferir de novo';

  @override
  String voiceAmount(String received, String total) {
    return '$received de $total';
  }

  @override
  String get voiceStatusReady => 'Pronta · funciona sem internet';

  @override
  String voiceStatusGetting(int percent, String amount) {
    return 'A preparar $percent% · $amount';
  }

  @override
  String voiceWaitingWifi(String extra) {
    return 'À espera de Wi-Fi$extra';
  }

  @override
  String voiceWaitingConnection(String extra) {
    return 'À espera de ligação$extra';
  }

  @override
  String voiceWaitingBattery(String extra) {
    return 'À espera de mais bateria$extra';
  }

  @override
  String voiceStatusExtra(String amount) {
    return ' · $amount até agora';
  }

  @override
  String voiceStoppedStorage(String size) {
    return 'Parada · o telemóvel precisa de $size livres';
  }

  @override
  String voiceStoppedLater(String extra) {
    return 'Parada · volta a tentar mais tarde$extra';
  }

  @override
  String voiceNotOnPhone(String size) {
    return 'Não está neste telemóvel · $size quando voltar a usar o microfone';
  }

  @override
  String get voiceUnavailable => 'Não disponível neste telemóvel';

  @override
  String get voiceDownload => 'Transferência de voz';

  @override
  String voiceKeepsGoing(String amount) {
    return '$amount. Continua se fechar isto.';
  }

  @override
  String voiceDownloadsWifi(String size) {
    return 'É transferida sozinha por Wi-Fi, $size uma vez.';
  }

  @override
  String get voiceNoConnection =>
      'Sem ligação neste momento. Continua de onde parou.';

  @override
  String get voiceWaitBattery =>
      'Espera por mais bateria ou por um carregador.';

  @override
  String voiceNoSpace(String size) {
    return 'Falta espaço no telemóvel. A escrita por voz precisa de $size livres.';
  }

  @override
  String get voiceDamaged =>
      'Um ficheiro chegou danificado e foi apagado. Tente novamente.';

  @override
  String get voiceFilesUnreachable =>
      'Não foi possível chegar aos ficheiros de voz. Tente daqui a pouco.';

  @override
  String voiceRunsHere(String size) {
    return 'A escrita por voz funciona neste telemóvel e precisa de $size uma vez.';
  }

  @override
  String get stopAndWrite => 'Parar e escrever';

  @override
  String get startListening => 'Começar a ouvir';

  @override
  String get removeVoiceQuestion => 'Remover os ficheiros de voz?';

  @override
  String removeVoiceBody(String size) {
    return 'Liberta $size. A escrita por voz só os volta a transferir quando usar o microfone ou a ativar aqui.';
  }

  @override
  String get keepFiles => 'Manter';

  @override
  String get remove => 'Remover';

  @override
  String get voiceFilesRemoved => 'Ficheiros de voz removidos.';

  @override
  String get voiceFilesRemoveFailed =>
      'Não foi possível remover os ficheiros de voz.';

  @override
  String get voiceOnPhone => 'Voz: neste telemóvel';

  @override
  String get voiceSettingsBody =>
      'A escrita por voz não precisa de conta e, depois de transferida, não precisa de internet. Nada do que diz é guardado ou enviado.';

  @override
  String get downloadMobile => 'Transferir voz com dados móveis';

  @override
  String mobileOffHelp(String size) {
    return 'Desligado: espera por Wi-Fi. Cerca de $size, uma vez.';
  }

  @override
  String get downloadVoiceFiles => 'Transferir ficheiros de voz';

  @override
  String get removeVoiceFiles => 'Remover ficheiros de voz';

  @override
  String get sceneStory =>
      'Já de noite, um telemóvel cheio de publicações puxa uma nota que diz «ver só a hora do autocarro» para um emaranhado de lã, enquanto o sol ainda dorme.';

  @override
  String get sceneBusTime => 'Ver só a hora do autocarro';

  @override
  String get sceneMagnetEmpty => 'Um íman espera pelas apps que o prendem.';

  @override
  String sceneMagnetApps(String apps) {
    return 'Um íman puxa $apps.';
  }

  @override
  String get sceneInitial => 'A sua inicial acena-lhe.';

  @override
  String get sceneFace => 'O rosto que escolheu acena-lhe.';

  @override
  String get sceneHome =>
      'Um telemóvel mostra o ecrã inicial calmo da Curre: uma saudação, um plano e duas apps que abrem mesmo na tarefa.';

  @override
  String get goodMorning => 'Bom dia';

  @override
  String goodMorningName(String name) {
    return 'Bom dia, $name';
  }

  @override
  String sceneSearch(String query) {
    return '→ Pesquisar «$query»';
  }

  @override
  String miniAllApps(String count) {
    return 'Todas as apps · $count';
  }

  @override
  String get scenePlan => 'O sol já nasceu e acena bom dia ao Peek.';

  @override
  String onboardingStep(int step, int total) {
    return 'Passo $step de $total';
  }

  @override
  String get nothingHiddenYet =>
      'Ainda não há nada oculto. Todas as apps abrem normalmente.';

  @override
  String hiddenSummaryOne(String name) {
    return 'Oculta: $name. Todas as outras apps abrem normalmente.';
  }

  @override
  String hiddenSummaryMany(String names) {
    return 'Ocultas: $names. Todas as outras apps abrem normalmente.';
  }

  @override
  String hiddenSummaryMore(String names, int count) {
    return '$names e mais $count';
  }

  @override
  String get taskExampleLearn => 'Aprender algo, como um acorde de guitarra';

  @override
  String get taskExampleFindWay => 'Encontrar o caminho para algum sítio';

  @override
  String get taskExampleReply => 'Responder a alguém';

  @override
  String get taskExampleTextBack => 'Responder a uma mensagem';

  @override
  String get taskExamplePlaylist => 'Ouvir uma lista';

  @override
  String get taskExampleLookUp => 'Pesquisar uma coisa';

  @override
  String get taskExampleEmail => 'Responder a um e-mail';

  @override
  String get taskExampleToday => 'Ver o que há hoje';

  @override
  String get taskExampleWrite => 'Anotar algo';

  @override
  String get taskExamplePhoto => 'Encontrar uma fotografia';

  @override
  String get taskExampleFile => 'Abrir um ficheiro';

  @override
  String get taskExampleMessage => 'Responder a uma mensagem';

  @override
  String get taskExampleEpisode => 'Ver um episódio';

  @override
  String get taskExampleGroup => 'Ver um grupo';

  @override
  String get taskExampleVideo => 'Publicar um vídeo';

  @override
  String get taskExamplePost => 'Publicar algo';

  @override
  String get taskExampleThread => 'Ler uma conversa';

  @override
  String get taskExampleIdea => 'Encontrar uma ideia';

  @override
  String get taskExampleFriend => 'Responder a um amigo';

  @override
  String get doorActionSearch => 'Pesquisar';

  @override
  String get doorActionDraft => 'Rascunho';

  @override
  String get doorActionNewEvent => 'Novo evento';

  @override
  String get openAppGeneric => 'Abrir app';

  @override
  String get openAppWith => 'Abrir app com';

  @override
  String laterSavedSemantics(String app, String reason, String destination) {
    return '$app, guardada para depois: $reason. Abre $destination';
  }

  @override
  String get chooseProfileAvatar => 'Escolha um avatar de perfil';

  @override
  String profileAvatarNumber(int number) {
    return 'Avatar de perfil $number';
  }

  @override
  String profileAvatarSelected(int number) {
    return 'Avatar de perfil $number, selecionado';
  }

  @override
  String get customProfileAvatar => 'Avatar de perfil personalizado';

  @override
  String avatarProofToday(String label) {
    return '$label, prova hoje';
  }

  @override
  String avatarSleepy(String label) {
    return '$label, com sono';
  }

  @override
  String profileInitial(String letter) {
    return 'Inicial $letter';
  }

  @override
  String profileInitialProof(String letter) {
    return 'Inicial $letter, prova hoje';
  }

  @override
  String get profileDefaultInitial => 'Inicial do perfil';

  @override
  String get profileDefaultInitialProof => 'Inicial do perfil, prova hoje';

  @override
  String get channelAppTime => 'Tempo da app';

  @override
  String get channelAppTimeBody =>
      'Mostra o tempo restante de uma app e quando volta a ficar oculta.';

  @override
  String get channelCheckins => 'Planeie o seu dia';

  @override
  String get channelCheckinsBody =>
      'Um lembrete suave para planear a manhã, a tarde e a noite.';

  @override
  String get channelPlans => 'Lembretes de planos';

  @override
  String get channelPlansBody =>
      'Um aviso discreto antes de o seu plano terminar.';

  @override
  String get channelProof => 'Lembretes de prova';

  @override
  String get channelProofBody =>
      'Depois de um plano, lembra-o de anotar o que fez.';

  @override
  String get channelFocus => 'Período de foco';

  @override
  String get channelFocusBody =>
      'No dia em que o foco termina, veja como correu.';

  @override
  String get nameExample => 'Ada';

  @override
  String appDidNotOpenThere(String app) {
    return 'A $app não abriu ali. O tempo continua a contar; tente a partir do ecrã inicial.';
  }

  @override
  String get sceneGChord => 'acorde sol';

  @override
  String get sceneWorship => 'louvor';
}
