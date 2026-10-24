import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as time_zone_data;
import 'package:timezone/timezone.dart' as time_zone;

import '../core/models.dart';

class GrantNotificationNotice {
  const GrantNotificationNotice({
    required this.id,
    required this.ongoingTitle,
    required this.ongoingBody,
    required this.expiryTitle,
    required this.expiryBody,
    required this.expiresAt,
    required this.remaining,
  });

  final int id;
  final String ongoingTitle;
  final String ongoingBody;
  final String expiryTitle;
  final String expiryBody;
  final DateTime expiresAt;
  final Duration remaining;
}

abstract interface class GrantNotificationGateway {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> showOngoing(GrantNotificationNotice notice);
  Future<void> scheduleExpiry(GrantNotificationNotice notice);
  Future<void> cancel(int id);
}

class GrantNotificationService {
  GrantNotificationService(this._gateway, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final GrantNotificationGateway _gateway;
  final DateTime Function() _now;

  Future<bool> requestPermission() async {
    await _gateway.initialize();
    return _gateway.requestPermission();
  }

  Future<void> startGrant({
    required Grant grant,
    required String appLabel,
  }) async {
    await _gateway.initialize();
    final id = notificationIdForPackage(grant.packageName);
    await _gateway.cancel(id);

    final now = _now().toUtc();
    if (!grant.isActiveAt(now)) return;

    final target = _targetWords(grant);
    final minutes = grant.expiresAt.difference(grant.grantedAt).inMinutes;
    final notice = GrantNotificationNotice(
      id: id,
      ongoingTitle: '$appLabel → $target',
      ongoingBody: 'In sight until this timer ends',
      expiryTitle: '$appLabel is out of sight again',
      expiryBody: 'Your $minutes min for ${grant.reason.trim()} ended.',
      expiresAt: grant.expiresAt,
      remaining: grant.expiresAt.difference(now),
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

class FlutterGrantNotificationGateway implements GrantNotificationGateway {
  FlutterGrantNotificationGateway({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'curre_grants';
  static const String channelName = 'App time reminders';
  static const String channelDescription =
      'Shows time left for an app and when it goes out of sight again.';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDescription,
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
    showBadge: false,
  );

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    time_zone_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_curre'),
      ),
    );
    await _androidPlugin?.createNotificationChannel(_channel);
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async =>
      await _androidPlugin?.requestNotificationsPermission() ?? true;

  @override
  Future<void> showOngoing(GrantNotificationNotice notice) => _plugin.show(
    id: notice.id,
    title: notice.ongoingTitle,
    body: notice.ongoingBody,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
        silent: true,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showWhen: true,
        when: notice.expiresAt.millisecondsSinceEpoch,
        usesChronometer: true,
        chronometerCountDown: true,
        timeoutAfter: notice.remaining.inMilliseconds,
      ),
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
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.low,
            priority: Priority.low,
            playSound: false,
            enableVibration: false,
            silent: true,
            ongoing: false,
            autoCancel: true,
            showWhen: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
}
