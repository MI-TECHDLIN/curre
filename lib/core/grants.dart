import 'api_models.dart';
import 'models.dart';

/// How long "Why now?" makes the user wait before opening an app anyway
/// (not now, needs more detail, an instruction, or no answer). Linear and
/// cancellable; `CurreMotion.countdown` draws it.
const Duration overrideWait = Duration(seconds: 30);

int grantMinutesFor(UnlockResponse response, {int fallbackUnlockMinutes = 5}) {
  final extracted = response.minutes;
  if (extracted != null) return extracted.clamp(1, 30);
  return switch (response.kind) {
    ReasonKind.task => 10,
    ReasonKind.person || ReasonKind.timeSensitive => 5,
    _ => fallbackUnlockMinutes.clamp(1, 30),
  };
}

Grant? grantFromUnlock({
  required UnlockResponse response,
  required String packageName,
  required String reason,
  required DateTime now,
  int fallbackUnlockMinutes = 5,
}) {
  if (response.outcome != UnlockOutcome.open) return null;
  return _createGrant(
    response: response,
    packageName: packageName,
    reason: reason,
    now: now,
    source: GrantSource.clocked,
    fallbackUnlockMinutes: fallbackUnlockMinutes,
  );
}

Grant grantFromFinishedOverride({
  required UnlockResponse response,
  required String packageName,
  required String reason,
  required DateTime finishedAt,
  int fallbackUnlockMinutes = 5,
}) => _createGrant(
  response: response,
  packageName: packageName,
  reason: reason,
  now: finishedAt,
  source: GrantSource.override,
  fallbackUnlockMinutes: fallbackUnlockMinutes,
);

Grant _createGrant({
  required UnlockResponse response,
  required String packageName,
  required String reason,
  required DateTime now,
  required GrantSource source,
  required int fallbackUnlockMinutes,
}) {
  final grantedAt = now.toUtc();
  final minutes = grantMinutesFor(
    response,
    fallbackUnlockMinutes: fallbackUnlockMinutes,
  );
  return Grant(
    packageName: packageName,
    reason: reason,
    task: response.kind == ReasonKind.person
        ? response.person?.text ?? response.target?.text
        : response.target?.text ?? response.person?.text,
    grantedAt: grantedAt,
    expiresAt: grantedAt.add(Duration(minutes: minutes)),
    source: source,
    kind: response.kind,
  );
}

List<Grant> activeGrants(Iterable<Grant> grants, DateTime now) =>
    grants.where((grant) => grant.isActiveAt(now)).toList(growable: false);
