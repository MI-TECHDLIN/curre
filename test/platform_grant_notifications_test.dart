import 'package:curre/core/core.dart';
import 'package:curre/platform/grant_notifications.dart';
import 'package:curre/platform/local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 24, 12);
  final grant = Grant(
    packageName: 'com.instagram.android',
    reason: 'reply Ada about rehearsal',
    task: 'Ada',
    grantedAt: now,
    expiresAt: now.add(const Duration(minutes: 5)),
    source: GrantSource.clocked,
    kind: ReasonKind.person,
  );

  test('shows and schedules a grant from the stored expiry', () async {
    final gateway = _FakeGrantNotificationGateway();
    final service = GrantNotificationService(gateway, now: () => now);

    await service.startGrant(grant: grant, appLabel: 'Instagram');

    expect(gateway.calls, <String>['initialize', 'cancel', 'show', 'schedule']);
    final shown = gateway.shown.single;
    final scheduled = gateway.scheduled.single;
    expect(shown.id, notificationIdForPackage(grant.packageName));
    expect(shown.ongoingTitle, 'Instagram → Ada');
    expect(shown.ongoingBody, contains('timer'));
    expect(shown.expiresAt, grant.expiresAt);
    expect(shown.remaining, const Duration(minutes: 5));
    expect(shown.packageName, grant.packageName);
    expect(scheduled.id, shown.id);
    expect(scheduled.expiryTitle, 'Instagram is hidden again');
    expect(scheduled.expiryBody, contains('reply Ada about rehearsal'));
  });

  test(
    'cancels the shown and pending notification when a grant ends',
    () async {
      final gateway = _FakeGrantNotificationGateway();
      final service = GrantNotificationService(gateway, now: () => now);

      await service.endGrant(grant.packageName);

      expect(gateway.cancelled, <int>[
        notificationIdForPackage(grant.packageName),
      ]);
    },
  );

  test('does not revive a grant at or after its exclusive expiry', () async {
    final gateway = _FakeGrantNotificationGateway();
    final service = GrantNotificationService(
      gateway,
      now: () => grant.expiresAt,
    );

    await service.startGrant(grant: grant, appLabel: 'Instagram');

    expect(gateway.cancelled, hasLength(1));
    expect(gateway.shown, isEmpty);
    expect(gateway.scheduled, isEmpty);
  });

  test('the per-type policy hook can turn time-up notices off', () async {
    final gateway = _FakeGrantNotificationGateway();
    final service = GrantNotificationService(
      gateway,
      now: () => now,
      policy: CurreNotificationPolicy(
        enabled: const <CurreNotificationType>{
          CurreNotificationType.checkIn,
          CurreNotificationType.planEnding,
          CurreNotificationType.proof,
        },
      ),
    );

    await service.startGrant(grant: grant, appLabel: 'Instagram');

    expect(gateway.cancelled, hasLength(1));
    expect(gateway.shown, isEmpty);
    expect(gateway.scheduled, isEmpty);
  });

  test(
    'requests notification permission only when the caller chooses',
    () async {
      final gateway = _FakeGrantNotificationGateway()..permissionResult = false;
      final service = GrantNotificationService(gateway, now: () => now);

      expect(await service.requestPermission(), isFalse);
      expect(gateway.calls, <String>['initialize', 'permission']);
    },
  );
}

class _FakeGrantNotificationGateway implements GrantNotificationGateway {
  final List<String> calls = <String>[];
  final List<GrantNotificationNotice> shown = <GrantNotificationNotice>[];
  final List<GrantNotificationNotice> scheduled = <GrantNotificationNotice>[];
  final List<int> cancelled = <int>[];
  bool permissionResult = true;

  @override
  Future<void> initialize() async => calls.add('initialize');

  @override
  Future<bool> requestPermission() async {
    calls.add('permission');
    return permissionResult;
  }

  @override
  Future<void> showOngoing(GrantNotificationNotice notice) async {
    calls.add('show');
    shown.add(notice);
  }

  @override
  Future<void> scheduleExpiry(GrantNotificationNotice notice) async {
    calls.add('schedule');
    scheduled.add(notice);
  }

  @override
  Future<void> cancel(int id) async {
    calls.add('cancel');
    cancelled.add(id);
  }
}
