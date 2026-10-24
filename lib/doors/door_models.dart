import 'dart:typed_data';

enum ReasonKind { task, person, timeSensitive, browse, unclear }

class LaunchableApp {
  const LaunchableApp({required this.packageName, required this.label});

  factory LaunchableApp.fromMap(Map<Object?, Object?> map) => LaunchableApp(
    packageName: map['package']! as String,
    label: map['label']! as String,
  );

  final String packageName;
  final String label;
}

class AppShortcut {
  const AppShortcut({
    required this.packageName,
    required this.id,
    required this.shortLabel,
    this.longLabel,
    this.isConversation = false,
    this.personNames = const <String>[],
  });

  factory AppShortcut.fromMap(Map<Object?, Object?> map) => AppShortcut(
    packageName: map['package']! as String,
    id: map['id']! as String,
    shortLabel: map['shortLabel']! as String,
    longLabel: map['longLabel'] as String?,
    isConversation: map['isConversation'] as bool? ?? false,
    personNames: (map['personNames'] as List<Object?>? ?? const <Object?>[])
        .whereType<String>()
        .toList(growable: false),
  );

  final String packageName;
  final String id;
  final String shortLabel;
  final String? longLabel;
  final bool isConversation;
  final List<String> personNames;

  Iterable<String> get matchLabels sync* {
    yield shortLabel;
    if (longLabel case final value?) yield value;
    yield* personNames;
  }
}

abstract interface class DoorPlatform {
  Future<List<LaunchableApp>> listApps();
  Future<Uint8List?> getIcon(String packageName);
  Future<bool> launch(String packageName);
  Future<bool> requestHomeRole();
  Future<bool> hasShortcutHostPermission();
  Future<List<AppShortcut>> getStaticShortcuts(String packageName);
  Future<List<AppShortcut>> getConversationShortcuts(String packageName);
  Future<bool> startShortcut(String packageName, String shortcutId);
  Future<bool> launchQueryDoor(String doorId, String query);
}
