import 'package:curre/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UnlockResponse open({
    ReasonKind kind = ReasonKind.task,
    int? minutes,
    SourceSpan? target,
    SourceSpan? person,
    String? door,
  }) => UnlockResponse(
    outcome: UnlockOutcome.open,
    kind: kind,
    confidence: 0.9,
    minutes: minutes,
    target: target,
    person: person,
    door: door,
  );

  group('grants', () {
    test('clamps extracted minutes to 1-30', () {
      expect(grantMinutesFor(open(minutes: -4)), 1);
      expect(grantMinutesFor(open(minutes: 1)), 1);
      expect(grantMinutesFor(open(minutes: 30)), 30);
      expect(grantMinutesFor(open(minutes: 99)), 30);
    });

    test('uses kind defaults when Extract has no minutes', () {
      expect(grantMinutesFor(open()), 10);
      expect(grantMinutesFor(open(kind: ReasonKind.person)), 5);
      expect(grantMinutesFor(open(kind: ReasonKind.timeSensitive)), 5);
      expect(
        grantMinutesFor(
          const UnlockResponse(
            outcome: UnlockOutcome.later,
            kind: ReasonKind.browse,
          ),
          fallbackUnlockMinutes: 7,
        ),
        7,
      );
    });

    test('creates clocked and finished-override grants in UTC', () {
      final response = open(
        kind: ReasonKind.person,
        person: const SourceSpan(text: 'Ada', start: 6, end: 9),
      );
      final now = DateTime.parse('2026-10-24T10:00:00+02:00');
      final clocked = grantFromUnlock(
        response: response,
        packageName: 'instagram',
        reason: 'reply Ada',
        now: now,
      )!;
      final override = grantFromFinishedOverride(
        response: const UnlockResponse(
          outcome: UnlockOutcome.specify,
          kind: ReasonKind.unclear,
        ),
        packageName: 'instagram',
        reason: 'need it',
        finishedAt: now,
      );

      expect(clocked.source, GrantSource.clocked);
      expect(clocked.task, 'Ada');
      expect(clocked.grantedAt, DateTime.utc(2026, 10, 24, 8));
      expect(clocked.expiresAt, DateTime.utc(2026, 10, 24, 8, 5));
      expect(override.source, GrantSource.override);
      expect(override.expiresAt, DateTime.utc(2026, 10, 24, 8, 5));
      expect(
        grantFromUnlock(
          response: const UnlockResponse(outcome: UnlockOutcome.later),
          packageName: 'instagram',
          reason: 'browse',
          now: now,
        ),
        isNull,
      );
    });

    test('activeGrants drops grants exactly at expiry', () {
      final grant = Grant(
        packageName: 'maps',
        reason: 'directions',
        task: null,
        grantedAt: DateTime.utc(2026, 10, 24, 8),
        expiresAt: DateTime.utc(2026, 10, 24, 8, 5),
        source: GrantSource.clocked,
      );
      expect(
        activeGrants(<Grant>[grant], DateTime.utc(2026, 10, 24, 8, 4)),
        <Grant>[grant],
      );
      expect(activeGrants(<Grant>[grant], grant.expiresAt), isEmpty);
    });
  });

  group('outcome mapping', () {
    test(
      'resolves open doors in conversation, query, shortcut, plain order',
      () {
        final response = open(
          kind: ReasonKind.person,
          person: const SourceSpan(text: 'Ada', start: 6, end: 9),
          target: const SourceSpan(text: 'rehearsal', start: 16, end: 25),
          door: 'Messages',
        );

        expect(
          mapUnlockOutcome(
            response,
            hasConversationMatch: true,
            hasQueryDoor: true,
          ).destination!.kind,
          DoorResolutionKind.conversation,
        );
        expect(
          mapUnlockOutcome(response, hasQueryDoor: true).destination!.kind,
          DoorResolutionKind.query,
        );
        expect(
          mapUnlockOutcome(response).destination!.kind,
          DoorResolutionKind.shortcut,
        );
        expect(
          mapUnlockOutcome(open()).destination!.kind,
          DoorResolutionKind.plain,
        );
      },
    );

    test('all four non-open states offer the 30-second override', () {
      for (final outcome in <UnlockOutcome>[
        UnlockOutcome.later,
        UnlockOutcome.specify,
        UnlockOutcome.flagged,
        UnlockOutcome.unavailable,
      ]) {
        final action = mapUnlockOutcome(UnlockResponse(outcome: outcome));
        expect(action.opensImmediately, isFalse, reason: outcome.name);
        expect(action.offersOverride, isTrue, reason: outcome.name);
        expect(action.overrideDuration, const Duration(seconds: 30));
        expect(
          action.startsOverrideImmediately,
          outcome == UnlockOutcome.unavailable,
          reason: outcome.name,
        );
      }
    });
  });
}
