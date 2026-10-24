import 'door_models.dart';
import 'query_door_allowlist.dart';

enum DoorLaunchKind {
  conversation,
  queryLink,
  shortcut,
  plainLaunch,
  fallbackSearch,
  fallbackLaunch,
  failed,
}

class DoorRequest {
  const DoorRequest({
    required this.packageName,
    required this.kind,
    this.person,
    this.target,
    this.queryDoorId,
    this.chosenShortcutId,
    this.conversationShortcuts = const <AppShortcut>[],
    this.staticShortcuts = const <AppShortcut>[],
  });

  final String packageName;
  final ReasonKind kind;
  final String? person;
  final String? target;
  final String? queryDoorId;
  final String? chosenShortcutId;
  final List<AppShortcut> conversationShortcuts;
  final List<AppShortcut> staticShortcuts;
}

class DoorLaunchResult {
  const DoorLaunchResult(this.kind, {this.detail});

  final DoorLaunchKind kind;
  final String? detail;
  bool get succeeded => kind != DoorLaunchKind.failed;
  bool get usedFallback =>
      kind == DoorLaunchKind.fallbackSearch ||
      kind == DoorLaunchKind.fallbackLaunch;
}

typedef CopyTarget = Future<void> Function(String value);

class DoorRouter {
  const DoorRouter(this.platform, {required this.copyTarget});

  final DoorPlatform platform;
  final CopyTarget copyTarget;

  Future<DoorLaunchResult> fallback(DoorRequest request) => _fallback(request);

  Future<DoorLaunchResult> open(DoorRequest request) async {
    if (request.kind == ReasonKind.person && _hasText(request.person)) {
      final match = _matchConversation(
        request.person!,
        request.conversationShortcuts,
      );
      if (match != null) {
        if (await _attempt(
          () => platform.startShortcut(request.packageName, match.id),
        )) {
          return DoorLaunchResult(
            DoorLaunchKind.conversation,
            detail: match.shortLabel,
          );
        }
        return _fallback(request);
      }
    }

    if (_hasText(request.target) &&
        request.queryDoorId != null &&
        QueryDoorAllowlist.permits(
          request.queryDoorId!,
          packageName: request.packageName,
        )) {
      if (await _attempt(
        () => platform.launchQueryDoor(request.queryDoorId!, request.target!),
      )) {
        return DoorLaunchResult(
          DoorLaunchKind.queryLink,
          detail: QueryDoorAllowlist.encodedTarget(
            request.queryDoorId!,
            request.target!,
          ),
        );
      }
      return _fallback(request);
    }

    if (_hasText(request.chosenShortcutId)) {
      if (await _attempt(
        () => platform.startShortcut(
          request.packageName,
          request.chosenShortcutId!,
        ),
      )) {
        return const DoorLaunchResult(DoorLaunchKind.shortcut);
      }
      return _fallback(request);
    }

    final launched = await _attempt(() => platform.launch(request.packageName));
    return DoorLaunchResult(
      launched ? DoorLaunchKind.plainLaunch : DoorLaunchKind.failed,
    );
  }

  Future<DoorLaunchResult> _fallback(DoorRequest request) async {
    if (_hasText(request.target)) await copyTarget(request.target!);

    AppShortcut? search;
    for (final shortcut in request.staticShortcuts) {
      if (shortcut.matchLabels.any(
        (label) => label.toLowerCase().contains('search'),
      )) {
        search = shortcut;
        break;
      }
    }
    if (search != null &&
        await _attempt(
          () => platform.startShortcut(request.packageName, search!.id),
        )) {
      return DoorLaunchResult(
        DoorLaunchKind.fallbackSearch,
        detail: search.shortLabel,
      );
    }
    if (await _attempt(() => platform.launch(request.packageName))) {
      return const DoorLaunchResult(DoorLaunchKind.fallbackLaunch);
    }
    return const DoorLaunchResult(DoorLaunchKind.failed);
  }

  AppShortcut? _matchConversation(String person, List<AppShortcut> shortcuts) {
    final wanted = _normalise(person);
    AppShortcut? partial;
    for (final shortcut in shortcuts) {
      for (final label in shortcut.matchLabels) {
        final candidate = _normalise(label);
        if (candidate == wanted) return shortcut;
        if (candidate.contains(wanted) || wanted.contains(candidate)) {
          partial ??= shortcut;
        }
      }
    }
    return partial;
  }

  String _normalise(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  Future<bool> _attempt(Future<bool> Function() action) async {
    try {
      return await action();
    } on Object {
      return false;
    }
  }
}
