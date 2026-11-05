import 'package:curre/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  const youtube = 'com.google.android.youtube';
  const whatsapp = 'com.whatsapp';
  final settings = Settings(
    candidates: const <String>{youtube, whatsapp},
    hiddenApps: const <String>{youtube, whatsapp},
  );

  test(
    'manual fallback gives each app its stated allowance past session end',
    () async {
      var now = DateTime.utc(2026, 10, 26, 16, 30);
      final controller = fakeController(settings: settings, clock: () => now);
      final plan = await controller.buildManualPlan(
        'watch a 2 hrs maths video on YouTube and 20 min on WhatsApp',
        const <String>[youtube, whatsapp],
      );

      expect(controller.currentSession.endsAt, DateTime.utc(2026, 10, 26, 17));
      expect(plan.startsAt, now);
      expect(plan.endsAt, DateTime.utc(2026, 10, 26, 18, 30));
      final apps = {for (final app in plan.apps) app.packageName: app};
      expect(apps[youtube]!.timing!.durationMinutes, 120);
      expect(apps[youtube]!.endsAt, DateTime.utc(2026, 10, 26, 18, 30));
      expect(apps[whatsapp]!.timing!.durationMinutes, 20);
      expect(apps[whatsapp]!.endsAt, DateTime.utc(2026, 10, 26, 16, 50));

      now = DateTime.utc(2026, 10, 26, 17, 10);
      expect(controller.currentSession.session, SessionName.evening);
      expect(controller.activePlan?.id, plan.id);
      expect(
        isVisible(
          youtube,
          now,
          LauncherState(settings: settings, plan: plan, grants: const []),
          timeZone: const FixedOffsetTimeZone(Duration.zero),
        ),
        isTrue,
      );
      expect(
        isVisible(
          whatsapp,
          now,
          LauncherState(settings: settings, plan: plan, grants: const []),
          timeZone: const FixedOffsetTimeZone(Duration.zero),
        ),
        isFalse,
      );
    },
  );

  test('confirmation adjustments reuse the same parser', () async {
    final now = DateTime.utc(2026, 10, 26, 16, 30);
    final controller = fakeController(settings: settings, now: now);
    final plan = await controller.buildManualPlan(
      'watch YouTube and check WhatsApp',
      const <String>[youtube, whatsapp],
    );

    final planAdjusted = await controller.adjustPlanTime(plan, 'until 8');
    expect(planAdjusted!.endsAt, DateTime.utc(2026, 10, 26, 20));

    final appAdjusted = await controller.adjustPlanTime(
      planAdjusted,
      '45 minutes',
      packageName: whatsapp,
    );
    expect(
      appAdjusted!.apps.firstWhere((app) => app.packageName == whatsapp).endsAt,
      DateTime.utc(2026, 10, 26, 17, 15),
    );
  });

  test('a natural future start belongs to the Curre day it starts', () async {
    var now = DateTime.utc(2026, 10, 26, 18);
    final controller = fakeController(settings: settings, clock: () => now);
    final plan = await controller.buildManualPlan(
      'study maths from 5 to 6',
      const <String>[youtube],
    );

    expect(plan.startsAt, DateTime.utc(2026, 10, 27, 5));
    expect(plan.endsAt, DateTime.utc(2026, 10, 27, 6));
    expect(plan.date, const LocalDate(2026, 10, 27));
    expect(plan.session, SessionName.morning);
    expect(controller.activePlan, isNull);

    now = DateTime.utc(2026, 10, 27, 5, 30);
    expect(controller.activePlan?.id, plan.id);
  });

  test('a hidden app with its own time gets the gentle expiry nudge', () async {
    final notices = FakeNotificationGateway();
    final controller = fakeController(
      settings: settings,
      notifications: notices,
      now: DateTime.utc(2026, 10, 26, 16, 30),
    );
    await controller.buildManualPlan(
      'watch YouTube for 2 hours and use WhatsApp for 20 min',
      const <String>[youtube, whatsapp],
    );

    expect(notices.expiryNotices, hasLength(1));
    expect(notices.expiryNotices.single.packageName, whatsapp);
    expect(
      notices.expiryNotices.single.expiryTitle,
      'WhatsApp is hidden again',
    );
  });
}
