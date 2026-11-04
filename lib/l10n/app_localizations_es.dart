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
  String chatWith(String person) {
    return 'Chat con $person';
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
  String get awayFromPhone => 'Fuera del teléfono';

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
}
