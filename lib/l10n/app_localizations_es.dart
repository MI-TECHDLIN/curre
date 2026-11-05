// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Curre';

  @override
  String get systemLanguage => 'Idioma del teléfono';

  @override
  String get language => 'Idioma';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageFrench => 'Francés';

  @override
  String get languagePortuguese => 'Portugués';

  @override
  String get languageGerman => 'Alemán';

  @override
  String get back => 'Atrás';

  @override
  String get close => 'Cerrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get done => 'Listo';

  @override
  String get edit => 'Editar';

  @override
  String get save => 'Guardar';

  @override
  String get notNow => 'Ahora no';

  @override
  String get checking => 'Comprobando…';

  @override
  String get on => 'Activado';

  @override
  String get off => 'Desactivado';

  @override
  String get sessionMorning => 'mañana';

  @override
  String get sessionAfternoon => 'tarde';

  @override
  String get sessionEvening => 'noche';

  @override
  String goodSession(String session) {
    return 'Buena $session';
  }

  @override
  String goodSessionName(String session, String name) {
    return 'Buena $session, $name';
  }

  @override
  String planThisSession(String session) {
    return 'Planifica esta $session';
  }

  @override
  String planYourSession(String session) {
    return 'Planifica tu $session';
  }

  @override
  String whatsThisSessionFor(String session) {
    return '¿Para qué es esta $session?';
  }

  @override
  String setMySession(String session) {
    return 'Preparar mi $session';
  }

  @override
  String get phone => 'Teléfono';

  @override
  String get messages => 'Mensajes';

  @override
  String get androidSettings => 'Ajustes';

  @override
  String get curreSettings => 'Ajustes de Curre';

  @override
  String get allApps => 'Todas las apps';

  @override
  String get allAppsDescription =>
      'Todas las apps que no ocultaste, listas para abrir.';

  @override
  String get hiddenApps => 'Apps ocultas';

  @override
  String hiddenAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps ocultas',
      one: '1 app oculta',
      zero: 'Ninguna app oculta',
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
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get couldNotReadApps => 'No se pudieron leer tus apps';

  @override
  String get couldNotReadAppsBody =>
      'Curre no pudo leer las apps instaladas en este teléfono. Inténtalo de nuevo para que aparezcan tus apps reales.';

  @override
  String get readingApps => 'Leyendo apps…';

  @override
  String get profileAvatar => 'Avatar del perfil';

  @override
  String get openProfile => 'Abrir perfil';

  @override
  String get gettingReady => 'Preparándolo todo…';

  @override
  String get gettingReadyBody => 'Puede tardar unos segundos más.';

  @override
  String get checkinHint => 'Di o escribe lo que quieres terminar.';

  @override
  String get sayItInstead => 'Decirlo en voz alta';

  @override
  String get planning => 'Creando tu plan…';

  @override
  String get planningSemantics => 'Eligiendo apps para tu plan';

  @override
  String get chooseAppsYourself => 'Elige las apps tú';

  @override
  String get chooseAppsBody =>
      'Curre no pudo crear este plan en línea. Elige las apps que necesitas y continúa.';

  @override
  String get useThisPlan => 'Usar este plan';

  @override
  String get planReady => 'Tu plan está listo';

  @override
  String onHomeUntil(String time) {
    return 'En Inicio hasta las $time';
  }

  @override
  String get whyNow => '¿Por qué ahora?';

  @override
  String whyNeedAppNow(String app) {
    return '¿Para qué necesitas $app ahora?';
  }

  @override
  String get whyNowHelp =>
      'Di qué vas a hacer, para quién y durante cuánto tiempo. Curre abre la app justo donde la necesitas.';

  @override
  String get yourReason => 'Tu motivo';

  @override
  String get reasonHint => 'responder a Ada sobre el ensayo';

  @override
  String yourPlan(String plan) {
    return 'Tu plan: $plan';
  }

  @override
  String get oneMoreTry => 'Un intento más: di exactamente qué vas a hacer.';

  @override
  String get bringItBack => 'Volver a mostrarla';

  @override
  String get askAgain => 'Preguntar de nuevo';

  @override
  String get readingReason => 'Leyendo tu motivo';

  @override
  String get readingReasonProgress => 'Leyendo tu motivo…';

  @override
  String guardQuote(String quote) {
    return 'Estas palabras parecen una instrucción para Curre: «$quote»';
  }

  @override
  String openAfter(String duration) {
    return 'Abrir después de $duration';
  }

  @override
  String get saveForLater => 'Guardar para después';

  @override
  String appOpensIn(String app) {
    return '$app se abre en';
  }

  @override
  String appOpensInDuration(String app, String duration) {
    return '$app se abre en $duration';
  }

  @override
  String get waitUnavailableBody =>
      'Curre no pudo comprobar tu motivo, así que la app se abre tras una breve espera.';

  @override
  String get waitAllowedBody => 'Has decidido esperar, y está bien.';

  @override
  String get waitCancelHelp =>
      'Sal de esta pantalla para cancelar. Si esperas, quedará anotado en tu historial.';

  @override
  String outcomeOpenApp(String app) {
    return 'Abre $app';
  }

  @override
  String outcomeOpenAt(String destination) {
    return 'Abre en $destination';
  }

  @override
  String get outcomeSpecify => '¿Qué vas a hacer exactamente?';

  @override
  String get outcomeFlagged => 'Eso parece una instrucción, no un motivo';

  @override
  String get outcomeUnavailable => 'No se pudo comprobar tu motivo';

  @override
  String youHaveMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
    );
    return 'Tienes $_temp0.';
  }

  @override
  String chatWith(String target) {
    return 'Hablar con $target';
  }

  @override
  String openDestination(String destination) {
    return 'Abrir $destination';
  }

  @override
  String get savedForNextPlan =>
      'Guardado. Volverá cuando hagas tu próximo plan.';

  @override
  String get couldNotSave =>
      'Curre no pudo guardar eso en este teléfono. Inténtalo de nuevo.';

  @override
  String get settingsSubtitle => 'Los cambios solo afectan a Curre.';

  @override
  String todayPercent(int percent) {
    return 'Hoy llevas un $percent por ciento';
  }

  @override
  String get oneSentenceHome =>
      'Una frase. Solo lo que nombres aparecerá en Inicio.';

  @override
  String get yourPlanLabel => 'Tu plan';

  @override
  String get planHint => 'Aprender el acorde de sol en YouTube hasta las 7';

  @override
  String get sayYourPlan => 'Decir tu plan';

  @override
  String get gettingAppsReady => 'Preparando tus apps…';

  @override
  String get choosingApps => 'Eligiendo apps';

  @override
  String lookingThroughApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return 'Revisando $_temp0';
  }

  @override
  String get useTheseApps => 'Usar estas apps';

  @override
  String get heresYourPlan => 'Este es tu plan';

  @override
  String get backToHome => 'Volver a Inicio';

  @override
  String get changePlan => 'Cambiar el plan';

  @override
  String get fallbackConnect => 'No se pudo conectar ahora';

  @override
  String get fallbackTimeout => 'Ha tardado demasiado';

  @override
  String get fallbackReadPlan => 'Curre no pudo leer ese plan';

  @override
  String get fallbackPlan => 'Curre no pudo crear el plan ahora';

  @override
  String get fallbackNetworkBody =>
      'Comprueba internet e inténtalo de nuevo, o elige las apps aquí abajo.';

  @override
  String get fallbackBody =>
      'Inténtalo de nuevo en un momento, o elige las apps aquí abajo.';

  @override
  String openedHiddenApp(String app) {
    return 'Has abierto $app. Es una de tus apps ocultas.';
  }

  @override
  String appIsHidden(String app) {
    return '$app está entre tus apps ocultas.';
  }

  @override
  String openNoChatBody(String app, String minutes) {
    return 'Curre no encontró un chat que coincida en este teléfono, así que abre $app. $minutes';
  }

  @override
  String laterBody(String duration, String app) {
    return 'Parece que quieres navegar, así que puede esperar. Guárdalo para después o espera $duration para abrir $app ahora.';
  }

  @override
  String specifyBody(String duration, String app) {
    return 'Cuenta un poco más qué vas a hacer, o espera $duration para abrir $app.';
  }

  @override
  String flaggedBody(String app, String duration) {
    return 'Dile a Curre qué vas a hacer en $app. O espera $duration para abrirla.';
  }

  @override
  String unavailableBody(String app, String duration) {
    return 'No pasa nada: $app se abre después de esperar $duration. También puedes intentarlo de nuevo.';
  }

  @override
  String untilAppOpens(String duration, String app) {
    return '$duration hasta que se abra $app';
  }

  @override
  String get querySearch => 'Buscar';

  @override
  String get queryDraft => 'Borrador';

  @override
  String get queryNewEvent => 'Nuevo evento';

  @override
  String get queryOpenWith => 'Abrir app con';

  @override
  String get kindTask => 'Una tarea';

  @override
  String get kindPerson => 'Alguien espera';

  @override
  String get kindTimeSensitive => 'No puede esperar';

  @override
  String get kindBrowse => 'Solo navegar';

  @override
  String get kindUnclear => 'Aún no está claro';

  @override
  String confidencePercent(String label, int percent) {
    return '$label, confianza del $percent por ciento';
  }

  @override
  String get outcomeGlyphOpen => 'Se abre';

  @override
  String get outcomeGlyphLater => 'Ahora no';

  @override
  String get outcomeGlyphSpecify => 'Faltan detalles';

  @override
  String get outcomeGlyphFlagged => 'No es un motivo';

  @override
  String get outcomeGlyphUnavailable => 'No se pudo comprobar';

  @override
  String get alwaysOnHome => 'Siempre en Inicio';

  @override
  String get pressHoldApp =>
      'Mantén pulsada una app para abrirla de la forma habitual.';

  @override
  String get quietNudgeQuestion =>
      '¿Quieres un aviso discreto cuando se acabe el tiempo?';

  @override
  String get quietNudgeBody =>
      'Curre puede avisarte cuando termine tu plan o el tiempo de una app. Sin sonido, vibración ni anuncios.';

  @override
  String get quietNudgeYes => 'Sí, avísame';

  @override
  String get sayOneSentence =>
      'Dilo en una frase. Curre pone en Inicio solo las apps que necesitas.';

  @override
  String get planNow => 'Planificar ahora';

  @override
  String tasksReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tareas listas',
      one: '1 tarea lista',
    );
    return '$_temp0';
  }

  @override
  String tasksDone(int done, int count) {
    return '$done de $count terminadas';
  }

  @override
  String yourSession(String session) {
    return 'Tu $session';
  }

  @override
  String untilTime(String time) {
    return 'hasta las $time';
  }

  @override
  String get changeThisPlan => 'Cambiar este plan';

  @override
  String get onHomeNow => 'Ahora en Inicio';

  @override
  String get alwaysAppsBelow => 'Tus apps de siempre están abajo.';

  @override
  String get tapStraightThere => 'Toca una para ir directamente.';

  @override
  String get nothingPlanned => 'Aún no hay nada planeado';

  @override
  String get nothingPlannedBody =>
      'Planifica tu día y sus apps aparecerán aquí.';

  @override
  String get alwaysAvailable => 'Siempre disponible';

  @override
  String get doneWithProof => 'Terminada, con prueba';

  @override
  String get doneWaiting => 'Terminada · tu nota está pendiente';

  @override
  String get doneAddNote => 'Terminada · toca para añadir una nota';

  @override
  String get doneToday => 'Terminado hoy';

  @override
  String get show => 'Mostrar';

  @override
  String get hide => 'Ocultar';

  @override
  String get todaySunUp => 'El sol de hoy ha salido';

  @override
  String get todaySun => 'El sol de hoy';

  @override
  String allDoneSession(String session) {
    return 'Todo listo esta $session';
  }

  @override
  String get allDoneBody =>
      'Todas las tareas de este plan están terminadas. Puedes cerrarlo y volver a planificar cuando quieras.';

  @override
  String get endPlanNow => 'Terminar el plan ahora';

  @override
  String get endPlanQuestion => '¿Terminar este plan ahora?';

  @override
  String get endPlanBody =>
      'Sus tareas saldrán de Inicio. Puedes volver a planificar cuando quieras.';

  @override
  String get keepIt => 'Conservarlo';

  @override
  String get endPlan => 'Terminar plan';

  @override
  String get planEnded => 'Plan terminado.';

  @override
  String get undo => 'Deshacer';

  @override
  String get tapStart => 'Toca Empezar cuando comiences';

  @override
  String get start => 'Empezar';

  @override
  String startedAt(String time) {
    return 'Empezada a las $time · toca al terminar';
  }

  @override
  String get awayFromPhone => 'Lejos del teléfono';

  @override
  String get you => 'Tú';

  @override
  String get closeProfile => 'Cerrar perfil';

  @override
  String get yourFace => 'Tu cara';

  @override
  String get pickYourFace => 'Elige la que sientas más tuya.';

  @override
  String get useInitial => 'Usar mi inicial';

  @override
  String get proofDays => 'Días con prueba';

  @override
  String get bestRun => 'Mejor racha';

  @override
  String get cloudDays => 'Días de descanso';

  @override
  String get history => 'Historial';

  @override
  String get yourName => 'Tu nombre';

  @override
  String get saveName => 'Guardar nombre';

  @override
  String get editName => 'Editar nombre';

  @override
  String get app => 'App';

  @override
  String get quietNudgeOn =>
      'Los avisos discretos están activados. Puedes elegirlos en los ajustes de Curre.';

  @override
  String get quietNudgeOff =>
      'No pasa nada. Puedes activar los avisos más tarde en los ajustes de Curre.';

  @override
  String planPercent(int percent) {
    return 'Este plan está completado al $percent por ciento';
  }

  @override
  String appsReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listas',
      one: '1 lista',
    );
    return '$_temp0';
  }

  @override
  String appBackForNow(String app) {
    return '$app ha vuelto por ahora';
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
      other: '$count tareas',
      one: '1 tarea',
    );
    return '$_temp0';
  }

  @override
  String doneTodayShow(String count) {
    return 'Terminado hoy, $count. Mostrar';
  }

  @override
  String doneTodayCount(int count) {
    return 'Terminado hoy · $count';
  }

  @override
  String get endPlanFailed =>
      'Curre no pudo terminar el plan. Inténtalo de nuevo.';

  @override
  String get planTimeUp => 'El tiempo de ese plan ya terminó.';

  @override
  String get doorOpenFailed =>
      'No se abrió. Mantén pulsada la app para abrirla de la forma habitual.';

  @override
  String copiedSearch(String target) {
    return 'Se copió «$target». Pégalo en el cuadro de búsqueda.';
  }

  @override
  String get addProof => 'Añadir prueba';

  @override
  String get snoozeTenMinutes => 'Posponer 10 min';

  @override
  String get focusDone => 'Tu periodo de enfoque terminó';

  @override
  String focusDoneNotification(String days) {
    return 'Mira cómo fueron estos $days y elige qué viene después.';
  }

  @override
  String sessionAlmostDone(String session) {
    return 'Tu $session casi ha terminado';
  }

  @override
  String get planEndsTenMinutes =>
      'Tu plan termina en 10 minutos. Elige qué viene después.';

  @override
  String get addYourProof => 'Añade tu prueba';

  @override
  String get proofNotificationBody =>
      'Una nota breve sobre lo que terminaste cuenta como prueba.';

  @override
  String grantOngoingBody(String task) {
    return '$task · Se ocultará de nuevo cuando termine el tiempo.';
  }

  @override
  String appHiddenAgain(String app) {
    return '$app vuelve a estar oculta';
  }

  @override
  String grantExpiredBody(int minutes, String reason) {
    return 'Se acabaron tus $minutes min para $reason.';
  }

  @override
  String get whatDidYouGetDone => '¿Qué terminaste?';

  @override
  String get onboardingSaveFailed =>
      'Curre no pudo guardar tus respuestas en este teléfono. Inténtalo de nuevo.';

  @override
  String get welcomeCurre => 'Te damos la bienvenida a Curre';

  @override
  String get aboutYou => 'Sobre ti';

  @override
  String get yourApps => 'Tus apps';

  @override
  String get yourHomeScreen => 'Tu pantalla de inicio';

  @override
  String get yourFirstPlan => 'Tu primer plan';

  @override
  String get onboardingWelcomeQuestion =>
      '¿Coges el teléfono para una cosa y pierdes una hora?';

  @override
  String get whatShouldCurreCallYou => '¿Cómo quieres que te llame Curre?';

  @override
  String get whatPullsYouIn => '¿Qué te atrapa?';

  @override
  String get makeCurreHomeHeadline => 'Pon Curre como pantalla de inicio.';

  @override
  String get withoutCurre => 'Sin Curre';

  @override
  String get withoutCurreBody =>
      'Una mirada rápida. El contenido te atrapa. Ha pasado una hora.';

  @override
  String get withCurre => 'Con Curre';

  @override
  String get withCurreBody =>
      'Di qué necesitas. Curre abre la app justo donde la necesitas.';

  @override
  String get historyContactsStay =>
      'Tu historial y tus contactos se quedan en este teléfono.';

  @override
  String get howCurrePrivate => 'Cómo protege Curre tu privacidad';

  @override
  String get namePrivacyNote =>
      'Solo para saludarte en Inicio. Se queda en este teléfono.';

  @override
  String get addNameError => 'Añade un nombre, aunque sea un apodo.';

  @override
  String get pickFaceOrInitial =>
      'Elige una cara o conserva tu inicial. Puedes cambiarla cuando quieras.';

  @override
  String get whatsFocusFor => '¿Para qué es este periodo de enfoque?';

  @override
  String get focusOnboardingBody =>
      'Curre ayuda más durante una etapa con fecha de fin. Al terminar, el teléfono vuelve a la normalidad. Puedes omitirlo si aún no lo tienes claro.';

  @override
  String get pickPullAppsBody =>
      'Elige las apps donde una mirada rápida se convierte en una hora. Curre oculta solo estas y pregunta «¿Por qué ahora?» al abrirlas. Las demás se abren como siempre.';

  @override
  String showAllApps(int count) {
    return 'Mostrar las $count apps';
  }

  @override
  String get changeHiddenAnyTime =>
      'Puedes ocultar otra app o recuperar una desde Apps ocultas o los ajustes de Curre.';

  @override
  String get androidChooseCurre =>
      'Android preguntará qué app usar como pantalla de inicio. Elige Curre.';

  @override
  String get homePointPlan =>
      'Inicio muestra tu plan. Las apps que no ocultaste están en Todas las apps y se abren como siempre.';

  @override
  String get homePointHidden =>
      'Solo se ocultan las apps que elegiste. Al abrir una, Curre pregunta «¿Por qué ahora?».';

  @override
  String get homePointDoor =>
      'Toca una app en Inicio para ir directamente a tu tarea.';

  @override
  String get curreIsHomeNow => 'Curre ya es tu pantalla de inicio.';

  @override
  String get switchHomeAnyTime =>
      '¿Has cambiado de idea? Puedes cambiar la pantalla de inicio en los ajustes de Curre.';

  @override
  String get curreNotHomeHelp =>
      'Curre aún no es tu pantalla de inicio. Inténtalo de nuevo o abre los ajustes de inicio y elige Curre.';

  @override
  String get chooseCurreList => 'Elige Curre en la lista y vuelve aquí.';

  @override
  String get chooseCurreDefaultApps =>
      'Toca «App de inicio», elige Curre y vuelve aquí.';

  @override
  String get chooseCurreSettings =>
      'En Ajustes, busca «App de inicio» o abre Apps y Apps predeterminadas; elige Curre y vuelve.';

  @override
  String get chooseCurrePhoneSettings =>
      'Abre los Ajustes del teléfono, busca «App de inicio», elige Curre y vuelve.';

  @override
  String get planExampleGuitar =>
      'Aprender el acorde de sol en YouTube hasta las 7';

  @override
  String get planExamplePlaylist =>
      'Reproducir la lista del domingo en Spotify';

  @override
  String get planExampleMaps => 'Buscar cómo llegar al estudio en Maps';

  @override
  String get onboardingPlanHelp =>
      'Dilo en una frase: la app, qué harás y hasta cuándo. Curre lleva solo eso a Inicio.';

  @override
  String get startFromExample => 'O empieza con uno de estos ejemplos:';

  @override
  String morningStartNote(String time) {
    return 'Curre pregunta para qué es tu mañana desde las $time. Puedes cambiarlo en los ajustes.';
  }

  @override
  String get showMeHow => 'Enséñame';

  @override
  String callMe(String name) {
    return 'Llámame $name';
  }

  @override
  String get pickAtLeastOne => 'Elige al menos una';

  @override
  String get hideThisOne => 'Ocultar esta';

  @override
  String hideThese(int count) {
    return 'Ocultar estas $count';
  }

  @override
  String get noneOfThese => 'Ninguna';

  @override
  String get makeCurreMyHome => 'Poner Curre como pantalla de inicio';

  @override
  String get openHomeSettings => 'Abrir ajustes de inicio';

  @override
  String get planLater => 'Planificaré después';

  @override
  String useExample(String text) {
    return 'Usar ejemplo: $text';
  }

  @override
  String get findApp => 'Buscar una app';

  @override
  String noAppMatches(String query) {
    return 'Ninguna app coincide con «$query».';
  }

  @override
  String get everyAppHidden => 'Todas las apps de este teléfono están ocultas.';

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
    return '$app está oculta. Al abrirla, Curre pregunta primero «¿Por qué ahora?».';
  }

  @override
  String get planApps => 'Apps que pueden usar tus planes';

  @override
  String get planAppsHelp =>
      'Cuando planificas, Curre elige entre estas. Escoge de 2 a 30.';

  @override
  String get hiddenAppsHelp =>
      'Solo estas salen de Inicio y preguntan primero «¿Por qué ahora?». Las demás se abren como siempre.';

  @override
  String get alwaysOnHomeHelp =>
      'Estas permanecen en Inicio todo el día, sin necesitar un plan.';

  @override
  String pickedCount(int count) {
    return '$count elegidas';
  }

  @override
  String hiddenCount(int count) {
    return '$count ocultas';
  }

  @override
  String onHomeCount(int count) {
    return '$count en Inicio';
  }

  @override
  String planAppsMinimum(int count) {
    return 'Los planes necesitan al menos $count apps entre las que elegir.';
  }

  @override
  String planAppsMaximum(int count) {
    return 'Ya hay $count. Desmarca una para añadir otra.';
  }

  @override
  String appAlwaysOnHome(String app) {
    return '$app siempre está en Inicio.';
  }

  @override
  String get privacyDetails => 'Detalles de privacidad';

  @override
  String get privacySubtitle =>
      'Qué sale de este teléfono y durante cuánto tiempo.';

  @override
  String get privacyReadOnline => 'Qué se lee en línea';

  @override
  String get privacyReadOnlineBody =>
      'Tu plan, los nombres de las apps, el motivo para abrir una app oculta y las notas que envías tras una tarea se leen en línea para que Curre pueda responderte.';

  @override
  String get privacyCopyTime => 'Cuánto tiempo puede quedar una copia';

  @override
  String get privacyCopyTimeBody =>
      'Curre no guarda copias en línea. El servicio de IA puede conservar una respuesta correcta, incluidas palabras citadas, durante alrededor de un día para responder igual a un reintento. Después la elimina.';

  @override
  String get privacyStaysHere => 'Qué se queda aquí';

  @override
  String get privacyStaysHereBody =>
      'Tus contactos, nombres de chats, uso de apps e historial se quedan en este teléfono. Puedes borrar planes, motivos y notas desde los ajustes de Curre.';

  @override
  String get privacyHistoryHides => 'Qué oculta el Historial';

  @override
  String get privacyHistoryHidesBody =>
      'Antes de guardar un motivo o una nota comprobados, Curre busca nombres, teléfonos, correos, direcciones y datos de pago. Lo que encuentra se sustituye por una etiqueta como [nombre] o [teléfono]. Si esa comprobación no está disponible, tus palabras se conservan.';

  @override
  String get privacyLogs =>
      'Curre solo registra si una solicitud funcionó y cuánto tardó. No incluye tus palabras en los registros en línea.';

  @override
  String get savedForLaterTitle => 'Guardado para después';

  @override
  String get laterNoneFits =>
      'Nada de lo guardado encaja en este plan, así que espera a un momento mejor.';

  @override
  String get laterBestFirst => 'Primero, lo que mejor encaja con este plan.';

  @override
  String get laterNewestFirst => 'Primero, lo más reciente.';

  @override
  String get laterOneMore => 'Queda 1 más para otro momento.';

  @override
  String laterMore(int count) {
    return 'Quedan $count más para otro momento.';
  }

  @override
  String get notToday => 'Hoy no';

  @override
  String get sectionYourFocus => 'Tu enfoque';

  @override
  String get sectionYourDay => 'Tu día';

  @override
  String get dayStartsHelp =>
      'Al empezar cada parte del día, Curre te pregunta para qué es.';

  @override
  String startsAt(String time) {
    return 'Empieza a las $time';
  }

  @override
  String get sectionYourApps => 'Tus apps';

  @override
  String get defaultEssentials => 'Teléfono, Mensajes y Ajustes';

  @override
  String defaultEssentialsMore(int count) {
    return 'Teléfono, Mensajes, Ajustes y $count más';
  }

  @override
  String get strictQuestion => '¿Hasta qué punto debe ser estricto Curre?';

  @override
  String get sectionHiddenApps => 'Apps ocultas';

  @override
  String get askWhyHidden =>
      'Preguntar «¿Por qué ahora?» al abrir una app oculta';

  @override
  String get needsAndroidOk => 'Primero necesita tu permiso en Android';

  @override
  String get pausedOtherHome =>
      'En pausa mientras usas otra pantalla de inicio';

  @override
  String get restingToday => 'Hoy descansas. Volverá mañana por la mañana.';

  @override
  String get askWhyOn =>
      'Activado, también desde apps recientes, notificaciones y enlaces';

  @override
  String get keepHiddenQuiet => 'Mantener en silencio las apps ocultas';

  @override
  String get focusEndedNothingHeld =>
      'Tu periodo de enfoque terminó, así que no se retiene nada';

  @override
  String get heldUntilBack => 'Activado. Se guardan hasta que vuelva la app.';

  @override
  String get turnOnUsageAccess => 'Activar Acceso al uso';

  @override
  String get turnOnNotificationAccess => 'Activar acceso a notificaciones';

  @override
  String get sectionQuietNudges => 'Avisos discretos';

  @override
  String get allowNotifications => 'Permitir notificaciones';

  @override
  String get notificationsAllowed =>
      'Permitidas. Pueden aparecer los avisos que elijas.';

  @override
  String get notificationsNotAllowed =>
      'Aún no están permitidas. Toca para permitirlas.';

  @override
  String get notificationsAndroidControls =>
      'Android decide si pueden aparecer los avisos que elijas';

  @override
  String get sectionVoiceTyping => 'Dictado por voz';

  @override
  String get sectionYourName => 'Tu nombre';

  @override
  String get nameInGreeting => 'Nombre en tu saludo';

  @override
  String get sectionHomeScreen => 'Tu pantalla de inicio';

  @override
  String get sectionHistoryPrivacy => 'Historial y privacidad';

  @override
  String get historySettingsBody =>
      'Tus planes y las apps que recuperaste durante los últimos 30 días. Solo en este teléfono.';

  @override
  String get privacySettingsBody =>
      'Qué se lee en línea, qué se queda aquí y cuándo se eliminan las copias';

  @override
  String get clearHistory => 'Borrar historial';

  @override
  String get clearHistorySettingsBody =>
      'Borrar de este teléfono planes, motivos, notas y notificaciones pasadas';

  @override
  String get sectionAbout => 'Acerca de';

  @override
  String get licences => 'Licencias';

  @override
  String get licencesBody =>
      'Fuentes, iconos, ilustraciones y dictado que usa Curre';

  @override
  String get appLegalese => 'Curre abre la tarea, no la app.';

  @override
  String sessionStartsAt(String session) {
    return 'Tu $session empieza a las';
  }

  @override
  String get sessionOrderError =>
      'La mañana empieza antes que la tarde y la tarde antes que la noche. Prueba otra hora.';

  @override
  String sessionStartSaved(String session, String time) {
    return 'Tu $session ahora empieza a las $time.';
  }

  @override
  String get nameSaved => 'Guardado. Curre te saludará con este nombre.';

  @override
  String get usageAccessDone =>
      'Listo. Curre preguntará «¿Por qué ahora?» al abrir una app oculta.';

  @override
  String get accessStillOff =>
      'Sigue desactivado. Puedes activarlo aquí cuando quieras.';

  @override
  String get notificationAccessDone =>
      'Listo. Las apps ocultas estarán en silencio hasta que vuelvan.';

  @override
  String get notificationsPermissionDone =>
      'Las notificaciones están permitidas. Curre usará los avisos elegidos arriba.';

  @override
  String get notificationsPermissionOff =>
      'Las notificaciones no están permitidas. Puedes activarlas para Curre en los Ajustes del teléfono.';

  @override
  String get chooseHomeApp => 'Toca «App de inicio» y elige la que quieras.';

  @override
  String get searchHomeApp =>
      'Se abrieron los Ajustes. Busca «App de inicio» o abre Apps y Apps predeterminadas, y elige la que quieras.';

  @override
  String get openSettingsHomeApp =>
      'Abre los Ajustes del teléfono y busca «App de inicio». Elige allí la que quieras.';

  @override
  String get curreNotHomeSettings =>
      'Curre aún no es tu pantalla de inicio. Abre los Ajustes, busca «App de inicio» y elige Curre.';

  @override
  String get clearHistoryQuestion => '¿Borrar tu historial?';

  @override
  String get clearHistoryBody =>
      'Se borrarán tus planes pasados, motivos para recuperar apps, notas tras las tareas y notificaciones perdidas. Tus días con prueba, el plan de hoy y los tiempos activos seguirán igual.';

  @override
  String get historyCleared => 'Historial borrado.';

  @override
  String get historyClearFailed =>
      'Curre no pudo borrar tu historial. Inténtalo de nuevo.';

  @override
  String get switchHome => 'Cambiar a otra pantalla de inicio';

  @override
  String get curreNotHomeBody =>
      'Curre no es tu pantalla de inicio ahora. Tus planes e historial siguen aquí para cuando los quieras.';

  @override
  String get switchHomeBody =>
      '¿Quieres usar otra pantalla de inicio un tiempo? No pasa nada. Android te deja elegir qué app se abre al pulsar Inicio. Tus planes e historial se quedan en este teléfono y puedes volver cuando quieras.';

  @override
  String get openHomeScreenSettings => 'Abrir ajustes de la pantalla de inicio';

  @override
  String get chooseHomeScreenApp => 'Elegir una app de inicio';

  @override
  String get homeSettingsPath =>
      'Si el teléfono abre Ajustes, busca Apps, Apps predeterminadas y luego App de inicio.';

  @override
  String get nudgesHelp =>
      'Elige qué avisos silenciosos envía Curre. Al desactivar uno también se cancelan los que estén esperando.';

  @override
  String get planYourDay => 'Planifica tu día';

  @override
  String get eachSessionBegins => 'Al empezar cada parte de tu día';

  @override
  String get morningBegins => 'Una vez al día, al empezar la mañana';

  @override
  String get afternoonEveningToo => 'También por la tarde y la noche';

  @override
  String get afternoonEveningBegins => 'También al empezar la tarde y la noche';

  @override
  String get planEnding => 'Fin del plan';

  @override
  String get tenMinutesBeforePlan =>
      'Diez minutos antes de que termine el plan';

  @override
  String get appTimeUp => 'Fin del tiempo de la app';

  @override
  String get hiddenAppTimeEnds => 'Cuando se acaba el tiempo de una app oculta';

  @override
  String get addProofLater => 'Unos minutos después de terminar el plan';

  @override
  String get focusEnds => 'Fin del enfoque';

  @override
  String get focusEndsMorning =>
      'La mañana en que termina tu periodo de enfoque';

  @override
  String get turnAllNudgesOff => 'Desactivar todos los avisos';

  @override
  String get turnAllNudgesOn => 'Activar todos los avisos';

  @override
  String get gentle => 'Suave';

  @override
  String get balanced => 'Equilibrado';

  @override
  String get strict => 'Estricto';

  @override
  String get strictnessBody =>
      'Al recuperar una app oculta, Curre comprueba tu motivo. Cuanto más estricto sea, más claro deberá ser el motivo para abrir la app.';

  @override
  String get hiddenChoiceNone =>
      'Ninguna. Todas las apps se abren como siempre.';

  @override
  String get hiddenChoiceOne => '1 app. Solo ella pregunta «¿Por qué ahora?».';

  @override
  String hiddenChoiceMany(int count) {
    return '$count apps. Solo estas preguntan «¿Por qué ahora?».';
  }

  @override
  String get missedNotifications => 'Notificaciones perdidas';

  @override
  String missedFromHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificaciones de apps ocultas',
      one: '1 notificación de apps ocultas',
    );
    return '$_temp0';
  }

  @override
  String heldUntilAppBack(int count) {
    return '$count retenidas hasta que vuelva su app';
  }

  @override
  String bringBackApp(String app) {
    return 'Recuperar $app';
  }

  @override
  String get restDayTheyOpen => 'Día de descanso: se abren sin preguntar';

  @override
  String get nothingHidden =>
      'No hay nada oculto. Todas las apps se abren como siempre desde Todas las apps.';

  @override
  String get hiddenAppsOut =>
      'Tus apps ocultas están disponibles por tu plan o durante un rato.';

  @override
  String get hideAnotherApp => 'Ocultar otra app';

  @override
  String notificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificaciones',
      one: '1 notificación',
    );
    return '$_temp0';
  }

  @override
  String get hiddenAppsTip =>
      'Aquí solo esperan las apps que elegiste ocultar. Toca una para recuperarla un rato.';

  @override
  String get gotIt => 'Entendido';

  @override
  String get appOpenFailed =>
      'La app no se abrió. Puede que ya no esté instalada.';

  @override
  String get missedNotificationsBody =>
      'Se guardaron en silencio mientras sus apps estaban ocultas y volvieron al regresar la app. Nada sale de este teléfono.';

  @override
  String get nothingHeld => 'No hay nada retenido ahora.';

  @override
  String get held => 'Retenida';

  @override
  String get givenBack => 'Devuelta';

  @override
  String openNotificationApp(String app) {
    return 'Abrir $app';
  }

  @override
  String get openCurreAppInfo => 'Abrir información de Curre';

  @override
  String get openSettingsAppsCurre =>
      'Abre los Ajustes del teléfono, luego Apps y Curre.';

  @override
  String get restrictedStillOff =>
      'Sigue desactivado. No pasa nada: Curre funciona sin él. Si Android dijo que el ajuste está restringido, permítelo una vez:';

  @override
  String get restrictedHelp =>
      'Si Android dice que el ajuste está restringido, permítelo una vez:';

  @override
  String get restrictedStepOne => 'Abre la información de Curre.';

  @override
  String get restrictedStepTwo =>
      'Toca los tres puntos de la esquina superior derecha.';

  @override
  String get restrictedStepThree => 'Toca «Permitir ajustes restringidos».';

  @override
  String get restrictedStepFour => 'Confirma con tu PIN o huella.';

  @override
  String get restrictedStepFive => 'Vuelve aquí y activa el acceso.';

  @override
  String get noProblemSettings =>
      'No pasa nada. Está siempre en los ajustes de Curre.';

  @override
  String get allSet => 'Todo listo.';

  @override
  String get usageAccessAllSet =>
      'Curre preguntará «¿Por qué ahora?» al abrir una app oculta.';

  @override
  String get notificationAccessAllSet =>
      'Las apps ocultas estarán en silencio hasta que vuelvan.';

  @override
  String get askWhyPrompt =>
      '¿Preguntar «¿Por qué ahora?» al abrir una app oculta?';

  @override
  String get quietPrompt => '¿Mantener en silencio las apps ocultas?';

  @override
  String get askWhyPromptBody =>
      'Las apps ocultas pueden volver desde apps recientes, enlaces o notificaciones. Curre también puede preguntar entonces. Solo comprueba qué app se abrió, nunca lo que hay en pantalla.';

  @override
  String get tryAgainAccess => 'Intentar de nuevo';

  @override
  String get hiddenNamesFallback => 'las apps que ocultes';

  @override
  String hiddenNamesTwo(String first, String second) {
    return '$first y $second';
  }

  @override
  String hiddenNamesMore(String first, String second, int count) {
    return '$first, $second y $count más';
  }

  @override
  String quietPromptBody(String apps) {
    return 'Curre puede guardar en silencio las notificaciones de $apps y devolverlas al abrir la app. Las demás apps notifican como siempre y las llamadas y alarmas siempre pasan.';
  }

  @override
  String get focusPurposeExams => 'Exámenes';

  @override
  String get focusPurposeDeadline => 'Una fecha límite';

  @override
  String get focusPurposeHabit => 'Romper un hábito';

  @override
  String get focusPurposeOther => 'Otra cosa';

  @override
  String get focusHintExams => 'Aprobar mis finales de matemáticas';

  @override
  String get focusHintDeadline => 'Terminar el portafolio';

  @override
  String get focusHintHabit => 'Dejar de abrir redes en la cama';

  @override
  String get focusHintOther => 'Lo que quiero cambiar';

  @override
  String get focusEndExams => 'Dejaste espacio para el trabajo importante.';

  @override
  String get focusEndDeadline => 'Llevaste este trabajo hasta la meta.';

  @override
  String get focusEndHabit => 'Le diste espacio al nuevo hábito para crecer.';

  @override
  String get focusEndOther => 'Volviste una y otra vez a lo importante.';

  @override
  String get focusLengthWeek => '1 semana';

  @override
  String get focusLengthTwoWeeks => '2 semanas';

  @override
  String get focusLengthThreeWeeks => '3 semanas';

  @override
  String get focusLengthThirtyDays => '30 días';

  @override
  String get focusGoalLabel => 'Tu objetivo, en pocas palabras (opcional)';

  @override
  String get untilWhen => '¿Hasta cuándo?';

  @override
  String get pickDate => 'Elegir una fecha';

  @override
  String focusEndsSummary(String date, String days) {
    return 'Termina el $date, dentro de $days. Puedes cambiarlo después.';
  }

  @override
  String get focusEndsOn => 'El enfoque termina el';

  @override
  String get focusSaveFailed =>
      'Curre no pudo guardar tu enfoque. Inténtalo de nuevo.';

  @override
  String get focusQuestion => '¿Para qué es este periodo de enfoque?';

  @override
  String get focusPickerBody =>
      'Curre ayuda más durante una etapa con final: exámenes, una fecha límite o un hábito que quieres romper.';

  @override
  String get pickFocusPurpose => 'Elige para qué es';

  @override
  String get startMyFocus => 'Empezar mi enfoque';

  @override
  String get setFocusQuestion => '¿Definir un enfoque?';

  @override
  String get focusOfferBody =>
      'Curre ayuda más durante una etapa con final: exámenes, una fecha límite o un hábito que romper. Elige uno y cuándo termina.';

  @override
  String get maybeLater => 'Quizá después';

  @override
  String get setFocus => 'Definir un enfoque';

  @override
  String get restDay => 'Día de descanso';

  @override
  String get yourFocus => 'Tu enfoque';

  @override
  String get restDayBody =>
      'Hoy las apps ocultas se abren sin preguntar, llegan sus notificaciones y los avisos descansan. Tus días con prueba están a salvo. Mañana vuelves al enfoque.';

  @override
  String focusLeft(String days, String date) {
    return 'Quedan $days · termina el $date';
  }

  @override
  String get backToFocusNow => 'Volver al enfoque ahora';

  @override
  String get takeTodayOff => 'Descansar hoy';

  @override
  String nextRestDay(String date) {
    return 'Próximo descanso: $date';
  }

  @override
  String get today => 'hoy';

  @override
  String get tomorrow => 'mañana';

  @override
  String get takeTodayOffQuestion => '¿Descansar hoy?';

  @override
  String get takeTodayOffBody =>
      'Hasta mañana por la mañana, las apps ocultas se abren sin preguntar, llegan sus notificaciones y Curre no envía avisos. Tus días con prueba están a salvo. Puedes descansar un día por semana.';

  @override
  String get keepGoing => 'Seguir';

  @override
  String get enjoyRestDay =>
      'Disfruta del descanso. Mañana vuelves al enfoque.';

  @override
  String focusSummaryDays(String days) {
    return '$days de enfoque.';
  }

  @override
  String focusSummaryWithRest(String days, String rests) {
    return '$days de enfoque, $rests.';
  }

  @override
  String restDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días de descanso',
      one: '1 día de descanso',
    );
    return '$_temp0';
  }

  @override
  String get daysWithProof => 'días con prueba';

  @override
  String get tasksProved => 'tareas demostradas';

  @override
  String get hiddenAppsLeftClosed => 'apps ocultas que no abriste';

  @override
  String get startAnotherFocus => 'Empezar otro periodo de enfoque';

  @override
  String get oldHomeScreen => 'Volver a mi pantalla de inicio anterior';

  @override
  String get focusHistoryStays =>
      'Tu historial y tus días con prueba se quedan en este teléfono en ambos casos.';

  @override
  String get chooseOldHome =>
      'Elige tu pantalla de inicio anterior en la lista. Curre deja de preguntar y permite todas las notificaciones.';

  @override
  String get tapOldHome => 'Toca «App de inicio» y elige tu pantalla anterior.';

  @override
  String get searchOldHome =>
      'Se abrieron los Ajustes. Busca «App de inicio» y elige tu pantalla anterior.';

  @override
  String get openSettingsOldHome =>
      'Abre los Ajustes del teléfono, busca «App de inicio» y elige allí tu pantalla anterior.';

  @override
  String get noFocusSet => 'No hay enfoque definido';

  @override
  String get focusSettingsEmpty =>
      'Elige para qué es esta etapa y cuándo termina.';

  @override
  String focusEndedOn(String date) {
    return 'Terminó el $date. Mira en Inicio cómo fue.';
  }

  @override
  String focusEndsLeft(String date, String days) {
    return 'Termina el $date, quedan $days';
  }

  @override
  String get changeEndDate => 'Cambiar fecha de fin';

  @override
  String weeklyRestNext(String date) {
    return 'Un día de descanso por semana. Próximo: $date.';
  }

  @override
  String get endFocusNow => 'Terminar enfoque ahora';

  @override
  String focusNowEnds(String date) {
    return 'Tu enfoque ahora termina el $date.';
  }

  @override
  String get endFocusQuestion => '¿Terminar tu enfoque ahora?';

  @override
  String get endFocusBody =>
      'Inicio muestra cómo fue y después eliges qué sigue. Tu historial y tus días con prueba se conservan.';

  @override
  String get endFocus => 'Terminar enfoque';

  @override
  String get historySubtitle => 'Los últimos 30 días · solo en este teléfono';

  @override
  String get whatHappened => 'Qué pasó';

  @override
  String get historyEmptyTitle => 'Un comienzo tranquilo.';

  @override
  String get historyEmptyBody =>
      'Aquí aparecerán tus planes y las apps que recuperes. Todo se queda en este teléfono.';

  @override
  String plannedSessionsCount(int count) {
    return '$count de 21 con plan';
  }

  @override
  String get historyOverviewHelp =>
      'Cada cuadro es una mañana, una tarde o una noche de los últimos 7 días. Los rellenos empezaron con un plan.';

  @override
  String sessionPlanState(String session, String state) {
    return '$session: $state';
  }

  @override
  String get planned => 'con plan';

  @override
  String get noPlan => 'sin plan';

  @override
  String proofCloudInHand(String detail) {
    return 'Tienes un día nube. $detail';
  }

  @override
  String get oneMoreProofToCloud =>
      'Falta 1 día con prueba para tu próximo día nube.';

  @override
  String moreProofToCloud(int count) {
    return 'Faltan $count días con prueba para tu próximo día nube.';
  }

  @override
  String proofDaysInAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días con prueba en total',
      one: '1 día con prueba en total',
    );
    return '$_temp0';
  }

  @override
  String bestRunCount(int count) {
    return 'Mejor racha $count';
  }

  @override
  String cloudDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días nube',
      one: '1 día nube',
    );
    return '$_temp0';
  }

  @override
  String get historyProofHint =>
      'Después de una tarea, cuenta qué cambió. Una nota concreta añade un día con prueba.';

  @override
  String historySessionPlan(String session) {
    String _temp0 = intl.Intl.selectLogic(session, {
      'morning': 'Plan de la mañana',
      'afternoon': 'Plan de la tarde',
      'evening': 'Plan de la noche',
      'other': 'Plan',
    });
    return '$_temp0';
  }

  @override
  String endedEarlyAt(String ended, String planned) {
    return 'Terminó antes a las $ended; estaba previsto hasta las $planned';
  }

  @override
  String waitedDuration(String duration) {
    return 'Esperó $duration';
  }

  @override
  String whyNowApp(String app) {
    return '¿Por qué ahora? · $app';
  }

  @override
  String get olderReasonMissing =>
      'El motivo no se guardó en esta entrada antigua.';

  @override
  String appCameBack(String app) {
    return '$app volvió';
  }

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String openedAfterWaiting(String duration) {
    return 'Se abrió tras esperar $duration';
  }

  @override
  String get openedFromLater =>
      'Se guardó para después y se abrió desde un plan';

  @override
  String get supportedProof => 'Prueba respaldada';

  @override
  String get waitingToBeChecked => 'Pendiente de revisar';

  @override
  String get markedDone => 'Marcada como hecha';

  @override
  String get noNote => 'Sin nota';

  @override
  String get personalDetailHidden => 'Dato personal oculto';

  @override
  String get outcomeOpened => 'Se abrió';

  @override
  String get outcomeNotNow => 'Ahora no';

  @override
  String get outcomeNeededDetail => 'Faltaban detalles';

  @override
  String get outcomeNotReason => 'No era un motivo';

  @override
  String get outcomeCouldNotCheck => 'No se pudo revisar';

  @override
  String get nextSunriseOneProof => 'Próximo amanecer: falta una prueba';

  @override
  String get noProofDaysYet => 'Aún no hay días con prueba';

  @override
  String proofDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días con prueba',
      one: '1 día con prueba',
    );
    return '$_temp0';
  }

  @override
  String get todaysSunIsUp => 'el sol de hoy ya salió';

  @override
  String get oneCloudInHand => 'un día nube disponible';

  @override
  String get cloudDay => 'Día nube';

  @override
  String runEndedAt(String days) {
    return 'Esa racha terminó con $days.';
  }

  @override
  String get todaysProofStartsNext =>
      'La prueba de hoy inicia el próximo amanecer.';

  @override
  String get theNextSunrise => 'El próximo amanecer';

  @override
  String get dayProof => 'día con prueba';

  @override
  String get dayPending => 'nota pendiente de revisar';

  @override
  String get dayNoProof => 'sin prueba';

  @override
  String get dayCloud => 'día nube';

  @override
  String get dayToday => 'hoy';

  @override
  String get dayFuture => 'aún por llegar';

  @override
  String get dayStillOpen => 'aún abierto';

  @override
  String get startingToday => 'Empieza hoy';

  @override
  String proofRunRange(String start, String end) {
    return 'De $start a $end';
  }

  @override
  String sinceDate(String date) {
    return 'Desde el $date';
  }

  @override
  String get milestoneSeven =>
      'Siete días con prueba: tus rayos terminan ahora en chispas.';

  @override
  String get milestoneTwentyOne =>
      '21 días con prueba: un aro de luz aparece detrás de tu sol.';

  @override
  String get milestoneFifty =>
      '50 días con prueba: tu sol lleva un segundo aro.';

  @override
  String get cloudDayKeepsRun =>
      'Si pasa un día sin prueba, mantiene tu racha.';

  @override
  String weekdaySunUp(String weekday) {
    return 'El sol del $weekday ya salió';
  }

  @override
  String earnedCloudDay(String detail) {
    return 'Has ganado un día nube. $detail';
  }

  @override
  String get completionQuestion => '¿Qué cambió, terminaste o entendiste?';

  @override
  String get oneSentenceEnough => 'Con una frase basta';

  @override
  String get addOneDetail => 'Añade un detalle';

  @override
  String get addWhatChanged => 'Añade qué cambió';

  @override
  String proofMismatchPrompt(String detail) {
    return '“$detail” no coincide con la tarea que planeaste. ¿Qué cambió, terminaste o entendiste?';
  }

  @override
  String get proofFuturePrompt =>
      'Eso suena a lo que viene después. ¿Qué cambió, terminaste o entendiste?';

  @override
  String get proofUnrelatedPrompt =>
      'Cuenta cómo se relaciona con tu plan. ¿Qué cambió, terminaste o entendiste?';

  @override
  String get proofDetailPrompt =>
      'Basta un nombre, un número o un paso. ¿Qué cambió, terminaste o entendiste?';

  @override
  String get justMarkDone => 'Solo marcar como hecha';

  @override
  String get readingYourNote => 'Leyendo tu nota';

  @override
  String get readingYourNoteProgress => 'Leyendo tu nota…';

  @override
  String get noteSaved => 'Tu nota está guardada';

  @override
  String get noteSavedBody =>
      'No se pudo revisar ahora. Se revisará cuando vuelvas a tener conexión.';

  @override
  String get runSafeWhileWaiting => 'Tu racha se mantiene mientras espera.';

  @override
  String get markedAsDone => 'Marcada como hecha';

  @override
  String get markedDoneBody =>
      'Está en tu historial. Los días con prueba nacen de una nota sobre lo que cambió.';

  @override
  String get noteCountsAsProof => 'Tu nota cuenta como prueba.';

  @override
  String get oneMoreRay => 'Un rayo más';

  @override
  String get proofAdded => 'Prueba añadida';

  @override
  String get profileSmiling => 'Tu perfil, sonriendo';

  @override
  String get sunOneRay => 'El sol de hoy, un rayo: una tarea con prueba';

  @override
  String sunManyRays(int count) {
    return 'El sol de hoy, $count rayos: $count tareas con prueba';
  }

  @override
  String proofDayUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'días con prueba',
      one: 'día con prueba',
    );
    return '$_temp0';
  }

  @override
  String get newRunStarts => 'Aquí empieza una nueva racha.';

  @override
  String get supported => 'Respaldada';

  @override
  String get backedByStart => 'Respaldada por el inicio de la tarea y tu nota';

  @override
  String get backedByApp => 'Respaldada por la app que abriste y tu nota';

  @override
  String get voicePermissionExplanation =>
      'Curre solo escucha cuando mantienes pulsado o tocas el micrófono. Tu voz nunca sale del teléfono.';

  @override
  String get voiceMicNeeded =>
      'El dictado necesita el micrófono. También puedes escribir.';

  @override
  String get voiceCouldNotStart =>
      'No se pudo iniciar el dictado. También puedes escribir.';

  @override
  String get voiceGettingReady =>
      'El dictado se está preparando. Mientras tanto, puedes escribir.';

  @override
  String get voiceReadyOffline => 'Listo. El dictado ya funciona sin conexión.';

  @override
  String get voiceMicStillOff =>
      'El micrófono sigue desactivado. Actívalo para hablar o escribe.';

  @override
  String get voiceNothingHeard =>
      'No he oído nada. Inténtalo de nuevo, un poco más cerca del micrófono.';

  @override
  String get voicePrivacyLine =>
      'En este teléfono · nada de lo que dices se guarda ni se envía';

  @override
  String get typeInstead => 'Escribir';

  @override
  String get gettingVoiceReady => 'Preparando el dictado';

  @override
  String downloadNowSize(String size) {
    return 'Descargar ahora · $size';
  }

  @override
  String get speakInsteadTyping => 'Habla en lugar de escribir';

  @override
  String get allowMic => 'Permitir el micrófono';

  @override
  String get micOffForCurre => 'El micrófono está desactivado para Curre';

  @override
  String micSettingsBody(String privacy) {
    return 'Activa el micrófono para Curre en los ajustes del teléfono y vuelve. $privacy';
  }

  @override
  String get openPhoneSettings => 'Abrir ajustes del teléfono';

  @override
  String get tapOrHoldMic => 'Toca o mantén pulsado el micrófono y habla.';

  @override
  String get listeningHeld => 'Escuchando… suelta cuando termines.';

  @override
  String get listeningPause =>
      'Escuchando… haz una pausa cuando termines o toca el micrófono.';

  @override
  String get writingSaid => 'Escribiendo lo que has dicho';

  @override
  String get writingProgress => 'Escribiéndolo…';

  @override
  String get voiceStartFailed => 'No se pudo iniciar el dictado';

  @override
  String get micStartFailed => 'No se pudo iniciar el micrófono';

  @override
  String voiceModelFix(String size) {
    return 'Volver a descargar los archivos de voz ($size) suele solucionarlo.';
  }

  @override
  String get voiceMicBusy =>
      'Si otra app usa el micrófono, ciérrala e inténtalo de nuevo.';

  @override
  String get downloadAgain => 'Descargar de nuevo';

  @override
  String voiceAmount(String received, String total) {
    return '$received de $total';
  }

  @override
  String get voiceStatusReady => 'Listo · funciona sin conexión';

  @override
  String voiceStatusGetting(int percent, String amount) {
    return 'Preparando $percent% · $amount';
  }

  @override
  String voiceWaitingWifi(String extra) {
    return 'Esperando una red Wi-Fi$extra';
  }

  @override
  String voiceWaitingConnection(String extra) {
    return 'Esperando conexión$extra';
  }

  @override
  String voiceWaitingBattery(String extra) {
    return 'Esperando más batería$extra';
  }

  @override
  String voiceStatusExtra(String amount) {
    return ' · $amount hasta ahora';
  }

  @override
  String voiceStoppedStorage(String size) {
    return 'Detenido · el teléfono necesita $size libres';
  }

  @override
  String voiceStoppedLater(String extra) {
    return 'Detenido · volverá a intentarlo más tarde$extra';
  }

  @override
  String voiceNotOnPhone(String size) {
    return 'No está en este teléfono · $size al volver a usar el micrófono';
  }

  @override
  String get voiceUnavailable => 'No disponible en este teléfono';

  @override
  String get voiceDownload => 'Descarga del dictado';

  @override
  String voiceKeepsGoing(String amount) {
    return '$amount. Sigue aunque cierres esto.';
  }

  @override
  String voiceDownloadsWifi(String size) {
    return 'Se descarga solo por Wi-Fi, $size una vez.';
  }

  @override
  String get voiceNoConnection =>
      'Ahora no hay conexión. Continuará donde se quedó.';

  @override
  String get voiceWaitBattery => 'Espera a que haya más batería o un cargador.';

  @override
  String voiceNoSpace(String size) {
    return 'Falta espacio. El dictado necesita $size libres.';
  }

  @override
  String get voiceDamaged =>
      'Un archivo llegó dañado y se eliminó. Inténtalo de nuevo.';

  @override
  String get voiceFilesUnreachable =>
      'No se pudo acceder a los archivos de voz. Inténtalo dentro de un rato.';

  @override
  String voiceRunsHere(String size) {
    return 'El dictado funciona en este teléfono y necesita $size una sola vez.';
  }

  @override
  String get stopAndWrite => 'Parar y escribirlo';

  @override
  String get startListening => 'Empezar a escuchar';

  @override
  String get removeVoiceQuestion => '¿Eliminar los archivos de voz?';

  @override
  String removeVoiceBody(String size) {
    return 'Liberarás $size. El dictado solo volverá a descargarlos cuando uses el micrófono o lo actives aquí.';
  }

  @override
  String get keepFiles => 'Conservar';

  @override
  String get remove => 'Eliminar';

  @override
  String get voiceFilesRemoved => 'Archivos de voz eliminados.';

  @override
  String get voiceFilesRemoveFailed =>
      'No se pudieron eliminar los archivos de voz.';

  @override
  String get voiceOnPhone => 'Voz: en este teléfono';

  @override
  String get voiceSettingsBody =>
      'El dictado no necesita cuenta y, tras descargarse, tampoco internet. Nada de lo que dices se guarda ni se envía.';

  @override
  String get downloadMobile => 'Descargar voz con datos móviles';

  @override
  String mobileOffHelp(String size) {
    return 'Desactivado: espera al Wi-Fi. Unos $size, una vez.';
  }

  @override
  String get downloadVoiceFiles => 'Descargar archivos de voz';

  @override
  String get removeVoiceFiles => 'Eliminar archivos de voz';

  @override
  String get sceneStory =>
      'De noche, un teléfono lleno de publicaciones arrastra una nota que dice «solo mirar la hora del bus» a una maraña de lana, mientras el sol aún duerme.';

  @override
  String get sceneBusTime => 'Solo mirar la hora del bus';

  @override
  String get sceneMagnetEmpty => 'Un imán espera a las apps que te atrapan.';

  @override
  String sceneMagnetApps(String apps) {
    return 'Un imán atrae a $apps.';
  }

  @override
  String get sceneInitial => 'Tu inicial te saluda.';

  @override
  String get sceneFace => 'La cara que elegiste te saluda.';

  @override
  String get sceneHome =>
      'Un teléfono muestra la tranquila pantalla de inicio de Curre: un saludo, un plan y dos apps que se abren justo en la tarea.';

  @override
  String get goodMorning => 'Buenos días';

  @override
  String goodMorningName(String name) {
    return 'Buenos días, $name';
  }

  @override
  String sceneSearch(String query) {
    return '→ Buscar «$query»';
  }

  @override
  String miniAllApps(String count) {
    return 'Todas las apps · $count';
  }

  @override
  String get scenePlan => 'Ha salido el sol y saludas a Peek.';

  @override
  String onboardingStep(int step, int total) {
    return 'Paso $step de $total';
  }

  @override
  String get nothingHiddenYet =>
      'Aún no hay nada oculto. Todas las apps se abren como siempre.';

  @override
  String hiddenSummaryOne(String name) {
    return 'Oculta: $name. Las demás apps se abren como siempre.';
  }

  @override
  String hiddenSummaryMany(String names) {
    return 'Ocultas: $names. Las demás apps se abren como siempre.';
  }

  @override
  String hiddenSummaryMore(String names, int count) {
    return '$names y $count más';
  }

  @override
  String get taskExampleLearn => 'Aprender algo, como un acorde de guitarra';

  @override
  String get taskExampleFindWay => 'Buscar cómo llegar a un sitio';

  @override
  String get taskExampleReply => 'Responder a alguien';

  @override
  String get taskExampleTextBack => 'Contestar un mensaje';

  @override
  String get taskExamplePlaylist => 'Reproducir una lista';

  @override
  String get taskExampleLookUp => 'Buscar una cosa';

  @override
  String get taskExampleEmail => 'Responder un correo';

  @override
  String get taskExampleToday => 'Mirar lo que hay hoy';

  @override
  String get taskExampleWrite => 'Anotar algo';

  @override
  String get taskExamplePhoto => 'Buscar una foto';

  @override
  String get taskExampleFile => 'Abrir un archivo';

  @override
  String get taskExampleMessage => 'Responder a un mensaje';

  @override
  String get taskExampleEpisode => 'Ver un episodio';

  @override
  String get taskExampleGroup => 'Mirar un grupo';

  @override
  String get taskExampleVideo => 'Publicar un vídeo';

  @override
  String get taskExamplePost => 'Publicar algo';

  @override
  String get taskExampleThread => 'Leer un hilo';

  @override
  String get taskExampleIdea => 'Buscar una idea';

  @override
  String get taskExampleFriend => 'Responder a un amigo';

  @override
  String get doorActionSearch => 'Buscar';

  @override
  String get doorActionDraft => 'Borrador';

  @override
  String get doorActionNewEvent => 'Nuevo evento';

  @override
  String get openAppGeneric => 'Abrir app';

  @override
  String get openAppWith => 'Abrir app con';

  @override
  String laterSavedSemantics(String app, String reason, String destination) {
    return '$app, guardada para después: $reason. Abre $destination';
  }

  @override
  String get chooseProfileAvatar => 'Elige un avatar de perfil';

  @override
  String profileAvatarNumber(int number) {
    return 'Avatar de perfil $number';
  }

  @override
  String profileAvatarSelected(int number) {
    return 'Avatar de perfil $number, seleccionado';
  }

  @override
  String get customProfileAvatar => 'Avatar de perfil personalizado';

  @override
  String avatarProofToday(String label) {
    return '$label, con prueba hoy';
  }

  @override
  String avatarSleepy(String label) {
    return '$label, con sueño';
  }

  @override
  String profileInitial(String letter) {
    return 'Inicial $letter';
  }

  @override
  String profileInitialProof(String letter) {
    return 'Inicial $letter, con prueba hoy';
  }

  @override
  String get profileDefaultInitial => 'Inicial del perfil';

  @override
  String get profileDefaultInitialProof => 'Inicial del perfil, con prueba hoy';

  @override
  String get channelAppTime => 'Tiempo de la app';

  @override
  String get channelAppTimeBody =>
      'Muestra cuánto tiempo queda para una app y cuándo vuelve a ocultarse.';

  @override
  String get channelCheckins => 'Planifica tu día';

  @override
  String get channelCheckinsBody =>
      'Un recordatorio suave para planificar la mañana, la tarde y la noche.';

  @override
  String get channelPlans => 'Recordatorios de planes';

  @override
  String get channelPlansBody =>
      'Un aviso discreto antes de que termine tu plan.';

  @override
  String get channelProof => 'Recordatorios de prueba';

  @override
  String get channelProofBody =>
      'Después de un plan, recuerda anotar lo que hiciste.';

  @override
  String get channelFocus => 'Periodo de enfoque';

  @override
  String get channelFocusBody =>
      'El día que termina tu enfoque, mira cómo te fue.';

  @override
  String get nameExample => 'Ada';

  @override
  String appDidNotOpenThere(String app) {
    return '$app no se abrió ahí. El tiempo sigue corriendo; inténtalo desde Inicio.';
  }

  @override
  String get sceneGChord => 'acorde de sol';

  @override
  String get sceneWorship => 'música de alabanza';

  @override
  String planTimeAdjustSemantics(String summary) {
    return 'Hora del plan: $summary. Toca para ajustarla.';
  }

  @override
  String get timeCappedNotice =>
      'Se limitó a seis horas o hasta medianoche, lo que ocurra primero.';

  @override
  String get timeAdjustHelp => 'Toca una hora para ajustarla antes de empezar.';

  @override
  String appTimeAdjustSemantics(String app, String summary) {
    return '$app, $summary, toca para ajustar';
  }

  @override
  String timeForLabel(String label) {
    return 'Tiempo para $label';
  }

  @override
  String get timeExampleHint => '90 min o hasta las 7';

  @override
  String get applyLabel => 'Aplicar';

  @override
  String get timeParseHelp =>
      'Prueba una duración como «90 min» o una hora como «hasta las 7».';

  @override
  String get thisPlan => 'este plan';

  @override
  String get sessionEnd => 'fin de la sesión';

  @override
  String fromTime(String time) {
    return 'desde las $time';
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
    return 'Tienes $duration.';
  }
}
