import 'package:flutter/services.dart';

import 'door_models.dart';

class LauncherChannel implements DoorPlatform {
  const LauncherChannel();

  static const MethodChannel _channel = MethodChannel('curre/launcher');

  @override
  Future<List<LaunchableApp>> listApps() async {
    final raw =
        await _channel.invokeListMethod<Object?>('listApps') ??
        const <Object?>[];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map(LaunchableApp.fromMap)
        .toList(growable: false);
  }

  @override
  Future<Uint8List?> getIcon(String packageName) =>
      _channel.invokeMethod<Uint8List>('getIcon', packageName);

  @override
  Future<bool> launch(String packageName) async =>
      await _channel.invokeMethod<bool>('launch', packageName) ?? false;

  @override
  Future<bool> requestHomeRole() async =>
      await _channel.invokeMethod<bool>('requestHomeRole') ?? false;

  @override
  Future<bool> hasShortcutHostPermission() async =>
      await _channel.invokeMethod<bool>('hasShortcutHostPermission') ?? false;

  @override
  Future<List<AppShortcut>> getStaticShortcuts(String packageName) =>
      _getShortcuts('getStaticShortcuts', packageName);

  @override
  Future<List<AppShortcut>> getConversationShortcuts(String packageName) =>
      _getShortcuts('getConversationShortcuts', packageName);

  Future<List<AppShortcut>> _getShortcuts(
    String method,
    String packageName,
  ) async {
    final raw =
        await _channel.invokeListMethod<Object?>(method, packageName) ??
        const <Object?>[];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map(AppShortcut.fromMap)
        .toList(growable: false);
  }

  @override
  Future<bool> startShortcut(String packageName, String shortcutId) async =>
      await _channel.invokeMethod<bool>('startShortcut', <String, String>{
        'package': packageName,
        'id': shortcutId,
      }) ??
      false;

  @override
  Future<bool> launchQueryDoor(String doorId, String query) async =>
      await _channel.invokeMethod<bool>('launchQueryLink', <String, String>{
        'door': doorId,
        'query': query,
      }) ??
      false;
}
