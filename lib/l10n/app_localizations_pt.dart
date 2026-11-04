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
  String chatWith(String person) {
    return 'Conversa com $person';
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
  String get awayFromPhone => 'Fora do telefone';

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
}
