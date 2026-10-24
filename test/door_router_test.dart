import 'dart:typed_data';

import 'package:curre/doors/door_models.dart';
import 'package:curre/doors/door_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const packageName = 'com.google.android.youtube';
  const conversation = AppShortcut(
    packageName: packageName,
    id: 'chat-ada',
    shortLabel: 'Ada',
    isConversation: true,
  );
  const search = AppShortcut(
    packageName: packageName,
    id: 'search',
    shortLabel: 'Search',
  );

  late _FakeDoorPlatform platform;
  late List<String> copied;
  late DoorRouter router;

  setUp(() {
    platform = _FakeDoorPlatform();
    copied = <String>[];
    router = DoorRouter(
      platform,
      copyTarget: (value) async => copied.add(value),
    );
  });

  test(
    'person resolves to a local conversation before every other door',
    () async {
      final result = await router.open(
        const DoorRequest(
          packageName: packageName,
          kind: ReasonKind.person,
          person: 'ada',
          target: 'rehearsal',
          queryDoorId: 'youtube',
          chosenShortcutId: 'subscriptions',
          conversationShortcuts: <AppShortcut>[conversation],
          staticShortcuts: <AppShortcut>[search],
        ),
      );

      expect(result.kind, DoorLaunchKind.conversation);
      expect(platform.calls, <String>['shortcut:$packageName:chat-ada']);
    },
  );

  test(
    'target plus verified query door resolves to an encoded link door',
    () async {
      final result = await router.open(
        const DoorRequest(
          packageName: packageName,
          kind: ReasonKind.task,
          target: 'G chord & practice',
          queryDoorId: 'youtube',
          chosenShortcutId: 'subscriptions',
        ),
      );

      expect(result.kind, DoorLaunchKind.queryLink);
      expect(platform.calls, <String>['query:youtube:G chord & practice']);
      expect(result.detail, contains('search_query='));
      expect(result.detail, isNot(contains('G chord')));
    },
  );

  test(
    'chosen shortcut is used when no higher-priority door applies',
    () async {
      final result = await router.open(
        const DoorRequest(
          packageName: packageName,
          kind: ReasonKind.task,
          chosenShortcutId: 'subscriptions',
        ),
      );

      expect(result.kind, DoorLaunchKind.shortcut);
      expect(platform.calls, <String>['shortcut:$packageName:subscriptions']);
    },
  );

  test('plain app launch is the final normal choice', () async {
    final result = await router.open(
      const DoorRequest(packageName: packageName, kind: ReasonKind.task),
    );

    expect(result.kind, DoorLaunchKind.plainLaunch);
    expect(platform.calls, <String>['launch:$packageName']);
  });

  test('failed door copies target and opens Search shortcut', () async {
    platform.queryResult = false;

    final result = await router.open(
      const DoorRequest(
        packageName: packageName,
        kind: ReasonKind.task,
        target: 'G chord',
        queryDoorId: 'youtube',
        staticShortcuts: <AppShortcut>[search],
      ),
    );

    expect(result.kind, DoorLaunchKind.fallbackSearch);
    expect(copied, <String>['G chord']);
    expect(platform.calls, <String>[
      'query:youtube:G chord',
      'shortcut:$packageName:search',
    ]);
  });

  test('failed door falls back to app when Search is unavailable', () async {
    platform.shortcutResult = false;

    final result = await router.open(
      const DoorRequest(
        packageName: packageName,
        kind: ReasonKind.task,
        target: 'G chord',
        chosenShortcutId: 'broken',
        staticShortcuts: <AppShortcut>[search],
      ),
    );

    expect(result.kind, DoorLaunchKind.fallbackLaunch);
    expect(copied, <String>['G chord']);
    expect(platform.calls, <String>[
      'shortcut:$packageName:broken',
      'shortcut:$packageName:search',
      'launch:$packageName',
    ]);
  });
}

class _FakeDoorPlatform implements DoorPlatform {
  final List<String> calls = <String>[];
  bool queryResult = true;
  bool shortcutResult = true;
  bool launchResult = true;

  @override
  Future<bool> launch(String packageName) async {
    calls.add('launch:$packageName');
    return launchResult;
  }

  @override
  Future<bool> launchQueryDoor(String doorId, String query) async {
    calls.add('query:$doorId:$query');
    return queryResult;
  }

  @override
  Future<bool> startShortcut(String packageName, String shortcutId) async {
    calls.add('shortcut:$packageName:$shortcutId');
    return shortcutResult;
  }

  @override
  Future<List<AppShortcut>> getConversationShortcuts(
    String packageName,
  ) async => const <AppShortcut>[];

  @override
  Future<Uint8List?> getIcon(String packageName) async => null;

  @override
  Future<List<AppShortcut>> getStaticShortcuts(String packageName) async =>
      const <AppShortcut>[];

  @override
  Future<bool> hasShortcutHostPermission() async => true;

  @override
  Future<List<LaunchableApp>> listApps() async => const <LaunchableApp>[];

  @override
  Future<bool> requestHomeRole() async => true;
}
