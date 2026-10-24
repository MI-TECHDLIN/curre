import 'api_models.dart';
import 'grants.dart';
import 'models.dart';

enum DoorResolutionKind { conversation, query, shortcut, plain }

class DoorResolution {
  const DoorResolution._({required this.kind, this.value});

  const DoorResolution.conversation(String person)
    : this._(kind: DoorResolutionKind.conversation, value: person);

  const DoorResolution.query(String target)
    : this._(kind: DoorResolutionKind.query, value: target);

  const DoorResolution.shortcut(String label)
    : this._(kind: DoorResolutionKind.shortcut, value: label);

  const DoorResolution.plain() : this._(kind: DoorResolutionKind.plain);

  final DoorResolutionKind kind;
  final String? value;
}

class UnlockAction {
  const UnlockAction({
    required this.outcome,
    required this.opensImmediately,
    required this.offersOverride,
    required this.startsOverrideImmediately,
    required this.destination,
    required this.grantDuration,
  });

  final UnlockOutcome outcome;
  final bool opensImmediately;
  final bool offersOverride;

  /// Unavailable starts the 60-second fallback immediately; other non-open
  /// outcomes wait for an explicit user choice.
  final bool startsOverrideImmediately;
  final DoorResolution? destination;
  final Duration? grantDuration;

  Duration? get overrideDuration => offersOverride ? overrideWait : null;
}

UnlockAction mapUnlockOutcome(
  UnlockResponse response, {
  bool hasConversationMatch = false,
  bool hasQueryDoor = false,
  int fallbackUnlockMinutes = 5,
}) {
  if (response.outcome == UnlockOutcome.open) {
    final destination = _resolveDoor(
      response,
      hasConversationMatch: hasConversationMatch,
      hasQueryDoor: hasQueryDoor,
    );
    return UnlockAction(
      outcome: response.outcome,
      opensImmediately: true,
      offersOverride: false,
      startsOverrideImmediately: false,
      destination: destination,
      grantDuration: Duration(
        minutes: grantMinutesFor(
          response,
          fallbackUnlockMinutes: fallbackUnlockMinutes,
        ),
      ),
    );
  }

  return UnlockAction(
    outcome: response.outcome,
    opensImmediately: false,
    offersOverride: true,
    startsOverrideImmediately: response.outcome == UnlockOutcome.unavailable,
    destination: null,
    grantDuration: null,
  );
}

DoorResolution _resolveDoor(
  UnlockResponse response, {
  required bool hasConversationMatch,
  required bool hasQueryDoor,
}) {
  if (response.kind == ReasonKind.person &&
      response.person != null &&
      hasConversationMatch) {
    return DoorResolution.conversation(response.person!.text);
  }
  if (response.target != null && hasQueryDoor) {
    return DoorResolution.query(response.target!.text);
  }
  final door = response.door;
  if (door != null && door.isNotEmpty) {
    return DoorResolution.shortcut(door);
  }
  return const DoorResolution.plain();
}
