import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as time_zone_data;
import 'package:timezone/timezone.dart' as time_zone;

import '../core/models.dart';
import 'local_notifications.dart';

class GrantNotificationNotice {
  const GrantNotificationNotice({
    required this.id,
    required this.ongoingTitle,
    required this.ongoingBody,
    required this.expiryTitle,
    required this.expiryBody,
    required this.expiresAt,
    required this.remaining,
    required this.packageName,
  });

  final int id;
  final String ongoingTitle;
  final String ongoingBody;
  final String expiryTitle;
  final String expiryBody;
  final DateTime expiresAt;
  final Duration remaining;
  final String packageName;
}

abstract interface class GrantNotificationGateway {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> showOngoing(GrantNotificationNotice notice);
  Future<void> scheduleExpiry(GrantNotificationNotice notice);
  Future<void> cancel(int id);
}

class GrantNotificationService {
  GrantNotificationService(
    this._gateway, {
    DateTime Function()? now,
    CurreNotificationPolicy? policy,
  }) : _now = now ?? DateTime.now,
       _policyOverride = policy;

  final GrantNotificationGateway _gateway;
  final DateTime Function() _now;
  final CurreNotificationPolicy? _policyOverride;

  CurreNotificationPolicy get policy =>
      _policyOverride ?? CurreNotificationPolicy();

  Future<bool> requestPermission() async {
    await _gateway.initialize();
    return _gateway.requestPermission();
  }

  Future<void> startGrant({
    required Grant grant,
    required String appLabel,
    Settings? settings,
  }) async {
    await _gateway.initialize();
    final id = notificationIdForPackage(grant.packageName);
    await _gateway.cancel(id);

    final now = _now().toUtc();
    final activePolicy = settings == null
        ? policy
        : _policyOverride ?? CurreNotificationPolicy.fromSettings(settings);
    if (!grant.isActiveAt(now) ||
        !activePolicy.allows(CurreNotificationType.unlockTimeUp)) {
      return;
    }

    final minutes = grant.expiresAt.difference(grant.grantedAt).inMinutes;
    final notice = GrantNotificationNotice(
      id: id,
      ongoingTitle: '$appLabel is back for now',
      ongoingBody:
          '${_targetWords(grant)} · It hides again when the time is up.',
      expiryTitle: '$appLabel is hidden again',
      expiryBody: 'Your $minutes min for ${grant.reason.trim()} are up.',
      expiresAt: grant.expiresAt,
      remaining: grant.expiresAt.difference(now),
      packageName: grant.packageName,
    );
    await _gateway.showOngoing(notice);
    await _gateway.scheduleExpiry(notice);
  }

  Future<void> endGrant(String packageName) async {
    await _gateway.initialize();
    await _gateway.cancel(notificationIdForPackage(packageName));
  }

  static String _targetWords(Grant grant) {
    final task = grant.task?.trim();
    return task == null || task.isEmpty ? grant.reason.trim() : task;
  }
}

int notificationIdForPackage(String packageName) {
  var hash = 0x811c9dc5;
  for (final codeUnit in packageName.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}

class FlutterGrantNotificationGateway
    implements GrantNotificationGateway, ReminderNotificationGateway {
  FlutterGrantNotificationGateway({
    FlutterLocalNotificationsPlugin? plugin,
    void Function(CurreNotificationIntent intent)? onResponse,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _onResponse = onResponse ?? CurreNotificationInbox.instance.add;

  static const String channelId = 'curre_time_up';
  static const String channelName = 'App time';
  static const String channelDescription =
      'Shows time left for an app and when it is hidden again.';

  static const Map<CurreNotificationType, _ChannelSpec> _channels =
      <CurreNotificationType, _ChannelSpec>{
        CurreNotificationType.checkIn: _ChannelSpec(
          id: 'curre_checkins',
          name: 'Plan your day',
          description:
              'A gentle reminder to plan your morning, afternoon and evening.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        CurreNotificationType.planEnding: _ChannelSpec(
          id: 'curre_plans',
          name: 'Plan reminders',
          description: 'A quiet heads-up before your plan ends.',
          importance: Importance.low,
          priority: Priority.low,
        ),
        CurreNotificationType.unlockTimeUp: _ChannelSpec(
          id: channelId,
          name: channelName,
          description: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        CurreNotificationType.proof: _ChannelSpec(
          id: 'curre_proof',
          name: 'Proof reminders',
          description: 'After a plan, a reminder to note what you got done.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      };

  final FlutterLocalNotificationsPlugin _plugin;
  final void Function(CurreNotificationIntent intent) _onResponse;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    time_zone_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_curre'),
      ),
      onDidReceiveNotificationResponse: (response) {
        unawaited(_handleResponse(response));
      },
    );
    for (final channel in _channels.values) {
      await _androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          channel.id,
          channel.name,
          description: channel.description,
          importance: channel.importance,
          playSound: false,
          enableVibration: false,
          showBadge: false,
        ),
      );
    }
    _initialized = true;
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp == true && response != null) {
      await _handleResponse(response);
    }
  }

  @override
  Future<bool> requestPermission() async =>
      await _androidPlugin?.requestNotificationsPermission() ?? true;

  @override
  Future<void> showOngoing(GrantNotificationNotice notice) => _plugin.show(
    id: notice.id,
    title: notice.ongoingTitle,
    body: notice.ongoingBody,
    notificationDetails: _details(
      type: CurreNotificationType.unlockTimeUp,
      title: notice.ongoingTitle,
      body: notice.ongoingBody,
      actions: const <CurreNotificationAction>[
        CurreNotificationAction.bringIntoSight,
      ],
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      when: notice.expiresAt.millisecondsSinceEpoch,
      usesChronometer: true,
      chronometerCountDown: true,
      timeoutAfter: notice.remaining.inMilliseconds,
    ),
    payload: _payload(
      type: CurreNotificationType.unlockTimeUp,
      destination: CurreNotificationDestination.hiddenApps,
      title: notice.ongoingTitle,
      body: notice.ongoingBody,
      reference: notice.packageName,
    ),
  );

  @override
  Future<void> scheduleExpiry(GrantNotificationNotice notice) =>
      _plugin.zonedSchedule(
        id: notice.id,
        title: notice.expiryTitle,
        body: notice.expiryBody,
        scheduledDate: time_zone.TZDateTime.from(
          notice.expiresAt,
          time_zone.UTC,
        ),
        notificationDetails: _details(
          type: CurreNotificationType.unlockTimeUp,
          title: notice.expiryTitle,
          body: notice.expiryBody,
          actions: const <CurreNotificationAction>[
            CurreNotificationAction.bringIntoSight,
          ],
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: _payload(
          type: CurreNotificationType.unlockTimeUp,
          destination: CurreNotificationDestination.hiddenApps,
          title: notice.expiryTitle,
          body: notice.expiryBody,
          reference: notice.packageName,
        ),
      );

  @override
  Future<void> scheduleReminder(CurreReminder reminder) =>
      _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: time_zone.TZDateTime.from(
          reminder.scheduledAt.toUtc(),
          time_zone.UTC,
        ),
        notificationDetails: _details(
          type: reminder.type,
          title: reminder.title,
          body: reminder.body,
          actions: reminder.actions,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: reminder.payload,
      );

  @override
  Future<void> cancelReminder(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> _handleResponse(NotificationResponse response) async {
    final action = CurreNotificationActionWire.tryParse(response.actionId);
    if (action == CurreNotificationAction.snooze) {
      final snoozed = _snoozedReminder(response.payload);
      if (snoozed != null) await scheduleReminder(snoozed);
      return;
    }
    final intent = CurreNotificationIntent.fromPayload(
      response.payload,
      actionId: response.actionId,
      note: response.input,
    );
    if (intent != null) _onResponse(intent);
  }

  CurreReminder? _snoozedReminder(String? payload) {
    if (payload == null) return null;
    try {
      final json = jsonDecode(payload);
      if (json is! Map<String, Object?> || json['version'] != 1) return null;
      final type = CurreNotificationType.values.byName(json['type']! as String);
      final destination = CurreNotificationDestination.values.byName(
        json['destination']! as String,
      );
      final at = DateTime.now().add(const Duration(minutes: 10));
      return CurreReminder(
        id: 800000 + at.millisecondsSinceEpoch.remainder(100000),
        type: type,
        title: json['title']! as String,
        body: json['body']! as String,
        scheduledAt: at,
        destination: destination,
        actions: _defaultActions(type),
        reference: json['reference'] as String?,
      );
    } on Object {
      return null;
    }
  }

  static List<CurreNotificationAction> _defaultActions(
    CurreNotificationType type,
  ) => switch (type) {
    CurreNotificationType.checkIn ||
    CurreNotificationType.planEnding => const <CurreNotificationAction>[
      CurreNotificationAction.startCheckIn,
      CurreNotificationAction.snooze,
    ],
    CurreNotificationType.unlockTimeUp => const <CurreNotificationAction>[
      CurreNotificationAction.bringIntoSight,
    ],
    CurreNotificationType.proof => const <CurreNotificationAction>[
      CurreNotificationAction.addProof,
      CurreNotificationAction.snooze,
    ],
  };

  static NotificationDetails _details({
    required CurreNotificationType type,
    required String title,
    required String body,
    required List<CurreNotificationAction> actions,
    bool ongoing = false,
    bool autoCancel = true,
    bool onlyAlertOnce = false,
    int? when,
    bool usesChronometer = false,
    bool chronometerCountDown = false,
    int? timeoutAfter,
  }) {
    final channel = _channels[type]!;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        icon: 'ic_stat_curre',
        importance: channel.importance,
        priority: channel.priority,
        playSound: false,
        enableVibration: false,
        silent: true,
        ongoing: ongoing,
        autoCancel: autoCancel,
        onlyAlertOnce: onlyAlertOnce,
        showWhen: true,
        when: when,
        usesChronometer: usesChronometer,
        chronometerCountDown: chronometerCountDown,
        timeoutAfter: timeoutAfter,
        color: const Color(0xFFE85F2E),
        category: AndroidNotificationCategory.reminder,
        groupKey: 'curre_${type.name}',
        groupAlertBehavior: GroupAlertBehavior.children,
        styleInformation: BigPictureStyleInformation(
          const DrawableResourceAndroidBitmap('curre_notification_art'),
          contentTitle: title,
          summaryText: body,
          hideExpandedLargeIcon: true,
          showBigPictureWhenCollapsed: true,
        ),
        actions: actions.map(_androidAction).toList(growable: false),
      ),
    );
  }

  static AndroidNotificationAction _androidAction(
    CurreNotificationAction action,
  ) => AndroidNotificationAction(
    action.wireValue,
    action.label,
    showsUserInterface: true,
    contextual: action == CurreNotificationAction.bringIntoSight,
    allowGeneratedReplies: action == CurreNotificationAction.addProof,
    semanticAction: action == CurreNotificationAction.addProof
        ? SemanticAction.reply
        : SemanticAction.none,
    inputs: action == CurreNotificationAction.addProof
        ? const <AndroidNotificationActionInput>[
            AndroidNotificationActionInput(label: 'What did you get done?'),
          ]
        : const <AndroidNotificationActionInput>[],
  );

  static String _payload({
    required CurreNotificationType type,
    required CurreNotificationDestination destination,
    required String title,
    required String body,
    String? reference,
  }) => jsonEncode(<String, Object?>{
    'version': 1,
    'type': type.name,
    'destination': destination.name,
    'title': title,
    'body': body,
    'reference': ?reference,
  });
}

class _ChannelSpec {
  const _ChannelSpec({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
    required this.priority,
  });

  final String id;
  final String name;
  final String description;
  final Importance importance;
  final Priority priority;
}
