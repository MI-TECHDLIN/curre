import 'dart:async';

import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../doors/door_models.dart';
import '../doors/door_router.dart';
import '../platform/home_refresh.dart';
import 'access_help.dart';
import 'app_widgets.dart';
import 'checkin_screen.dart';
import 'completion_sheet.dart';
import 'curre_controller.dart';
import 'hidden_apps_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    this.startWithCheckin = false,
  });

  final CurreController controller;
  final bool startWithCheckin;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeRefreshController _refreshController;
  late final HomeRefreshLifecycleHook _lifecycle;

  CurreController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _refreshController = HomeRefreshController(
      refresh: controller.refresh,
      homePlatform: controller.homePlatform,
      onError: (_, _) {},
    );
    _lifecycle = HomeRefreshLifecycleHook(_refreshController)..attach();
    unawaited(_lifecycle.show());
    if (widget.startWithCheckin || controller.takeFirstCheckinRequest()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_push(CheckinScreen(controller: controller)));
      });
    }
  }

  @override
  void dispose() {
    _lifecycle.detach();
    super.dispose();
  }

  Future<void> _push(Widget page) async {
    await _lifecycle.hide();
    if (!mounted) return;
    await Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => page));
    if (!mounted) return;
    await controller.refresh();
    await _lifecycle.show();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => _HomeBody(
          controller: controller,
          openCheckin: () => _push(CheckinScreen(controller: controller)),
          openHidden: () => _push(HiddenAppsScreen(controller: controller)),
          openSettings: () => _push(SettingsScreen(controller: controller)),
          openProfile: () => _showProfile(context),
        ),
      ),
    );
  }

  Future<void> _showProfile(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProfileSheet(controller: controller),
  );
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.controller,
    required this.openCheckin,
    required this.openHidden,
    required this.openSettings,
    required this.openProfile,
  });

  final CurreController controller;
  final VoidCallback openCheckin;
  final VoidCallback openHidden;
  final VoidCallback openSettings;
  final VoidCallback openProfile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final window = controller.currentSession;
    final plan = controller.activePlan;
    final name = controller.settings.displayName;
    final greeting = 'Good ${window.session.label}';
    final today = controller.now;
    final proof = controller.proofSummary;
    final offlineTasks = controller.offlineTasksOnHome;
    final completion = controller.activePlanCompletion;
    // Earlier tasks away from the phone still waiting for their Done; the
    // active plan's own task is in [completion].
    final earlierOffline = offlineTasks
        .where((task) => task.planId != plan?.id)
        .toList(growable: false);
    final activeTasks = completion?.active ?? const <TaskProgress>[];
    final doneTasks = completion?.done ?? const <TaskProgress>[];
    final allDone = plan != null && controller.allTasksDone;
    final schedule = SessionSchedule.fromSettings(controller.settings);
    final dayProgress = DayProgress.of(
      plans: controller.plans,
      uses: controller.doorUses,
      schedule: schedule,
      now: today,
    );
    final planProgress = plan == null
        ? null
        : PlanProgress.of(
            plan,
            startsAt: schedule
                .current(plan.endsAt.subtract(const Duration(microseconds: 1)))
                .startsAt,
            now: today,
            uses: controller.doorUses,
          );
    final plannedPackages = plan?.packages ?? const <String>{};
    final doorCount =
        (plan?.apps.length ?? 0) +
        controller.activeGrants
            .where((grant) => !plannedPackages.contains(grant.packageName))
            .length;
    final fixedEssentialPackages = <String>{
      ?controller.phonePackage,
      ?controller.messagesPackage,
      ?controller.androidSettingsPackage,
    };
    final extraEssentials =
        controller.settings.essentials
            .where(
              (packageName) =>
                  !fixedEssentialPackages.contains(packageName) &&
                  packageName != 'com.mitech.curre' &&
                  controller.appFor(packageName) != null,
            )
            .map(controller.appFor)
            .whereType<LaunchableApp>()
            .toList(growable: false)
          ..sort(
            (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
          );
    return CurrePage(
      safeBottom: false,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                CurreSpace.gutter,
                CurreSpace.s4,
                CurreSpace.gutter,
                CurreSpace.s5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name == null ? greeting : '$greeting, $name',
                              style: type.headline,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: CurreSpace.s1),
                            Text(
                              _date(today),
                              style: type.caption.copyWith(color: colors.ink3),
                            ),
                            const SizedBox(height: CurreSpace.s2),
                            ProofDaysLabel(
                              days: proof.currentRun,
                              raysToday: proof.raysToday,
                              runEnded: proof.betweenRuns,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: CurreSpace.s3),
                      ProfileAvatarButton(
                        displayName: name,
                        avatarId: controller.settings.avatarId,
                        motion: AvatarMotion.reactOnce,
                        onPressed: openProfile,
                      ),
                    ],
                  ),
                  const SizedBox(height: CurreSpace.s6),
                  if (plan == null)
                    _CheckinPrompt(
                      session: window.session,
                      progress: dayProgress.value,
                      onTap: openCheckin,
                    )
                  else
                    Hero(
                      tag: 'active-plan-${plan.id}',
                      flightShuttleBuilder: (_, _, _, _, _) =>
                          PlanHeroSentence(intention: plan.intention),
                      child: Material(
                        color: Colors.transparent,
                        child: _PlanCard(
                          plan: plan,
                          progress: planProgress!.value,
                          doneCount: doneTasks.length,
                          onEdit: openCheckin,
                        ),
                      ),
                    ),
                  if (allDone) ...[
                    const SizedBox(height: CurreSpace.s4),
                    _AllDoneCard(
                      session: plan.session,
                      proof: proof,
                      onEndPlan: () => _confirmEndPlan(context, controller),
                    ),
                  ],
                  for (final grant in controller.activeGrants) ...[
                    const SizedBox(height: CurreSpace.s4),
                    _GrantBanner(
                      grant: grant,
                      appLabel:
                          controller.appFor(grant.packageName)?.label ?? 'App',
                      now: controller.now,
                    ),
                  ],
                  if (controller.offers(ContextPrompt.nudges) &&
                      (plan != null || controller.activeGrants.isNotEmpty)) ...[
                    const SizedBox(height: CurreSpace.s4),
                    _NudgeOffer(controller: controller),
                  ],
                  const SizedBox(height: CurreSpace.s6),
                  _SightHeader(doorCount: doorCount),
                  const SizedBox(height: CurreSpace.s3),
                  if (plan == null &&
                      controller.activeGrants.isEmpty &&
                      offlineTasks.isEmpty)
                    const _EmptySightNote(),
                  if (plan != null)
                    for (final (index, item) in activeTasks.indexed) ...[
                      if (index > 0) const SizedBox(height: CurreSpace.s2),
                      _TaskRow(controller: controller, plan: plan, item: item),
                    ],
                  for (final (index, task) in earlierOffline.indexed) ...[
                    if (index > 0 || activeTasks.isNotEmpty)
                      const SizedBox(height: CurreSpace.s2),
                    _OfflineTaskRow(controller: controller, task: task),
                  ],
                  for (final grant in controller.activeGrants.where(
                    (grant) =>
                        plan?.packages.contains(grant.packageName) != true,
                  )) ...[
                    const SizedBox(height: CurreSpace.s2),
                    _GrantDoor(controller: controller, grant: grant),
                  ],
                  if (plan != null && doneTasks.isNotEmpty) ...[
                    SizedBox(
                      height:
                          activeTasks.isEmpty &&
                              earlierOffline.isEmpty &&
                              controller.activeGrants.isEmpty
                          ? 0
                          : CurreSpace.s4,
                    ),
                    _DoneTodayGroup(
                      key: ValueKey<String>('done-today-${plan.id}'),
                      controller: controller,
                      plan: plan,
                      done: doneTasks,
                    ),
                  ],
                  if (extraEssentials.isNotEmpty) ...[
                    const SizedBox(height: CurreSpace.s5),
                    Text('Always on Home', style: type.label),
                    const SizedBox(height: CurreSpace.s2),
                    for (final app in extraEssentials) ...[
                      _EssentialDoor(controller: controller, app: app),
                      const SizedBox(height: CurreSpace.s2),
                    ],
                  ],
                  if (plan != null && plan.apps.isNotEmpty) ...[
                    const SizedBox(height: CurreSpace.s3),
                    Text(
                      'Press and hold an app to open it the usual way.',
                      style: type.caption.copyWith(color: colors.ink3),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          HomeDock(
            controller: controller,
            onHidden: openHidden,
            onCurreSettings: openSettings,
          ),
        ],
      ),
    );
  }

  static String _date(DateTime date) {
    const weekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}

/// Asks once, the first time time is running, whether Curre may send a
/// quiet nudge when it's up.
class _NudgeOffer extends StatefulWidget {
  const _NudgeOffer({required this.controller});

  final CurreController controller;

  @override
  State<_NudgeOffer> createState() => _NudgeOfferState();
}

class _NudgeOfferState extends State<_NudgeOffer> {
  var _working = false;

  Future<void> _answer({required bool allow}) async {
    setState(() => _working = true);
    final allowed = await widget.controller.answerNudgeOffer(allow: allow);
    if (!mounted) return;
    setState(() => _working = false);
    showCurreSnack(
      context,
      allowed
          ? 'Quiet nudges are on. You can choose which ones in Curre settings.'
          : 'No problem. You can turn quiet nudges on later in Curre settings.',
    );
  }

  @override
  Widget build(BuildContext context) => ContextOfferCard(
    key: const Key('nudge-offer'),
    prop: CurreProp.bell,
    title: 'Want a quiet nudge when time’s up?',
    body: 'Curre can let you know when your plan or an app’s time runs out. No sound, no buzz, never ads.',
    yesLabel: 'Yes, nudge me',
    yesGlyph: CurreGlyphKind.notify,
    onYes: _working ? null : () => unawaited(_answer(allow: true)),
    onNotNow: _working ? null : () => unawaited(_answer(allow: false)),
  );
}

class _CheckinPrompt extends StatelessWidget {
  const _CheckinPrompt({
    required this.session,
    required this.progress,
    required this.onTap,
  });

  final SessionName session;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final sky = colors.sky(session.designSession);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    return Semantics(
      key: const Key('home-checkin-card'),
      button: true,
      label: 'Plan this ${session.label}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: _HomeSceneSettle(
          builder: (context, animate) => SizedBox(
            height: largeText ? 600 : 344,
            child: SkyScene(
              session: session.designSession,
              sun: SkySun.peek,
              sunAt: .82,
              sunSize: largeText ? 126 : 104,
              sunRise: switch (session) {
                SessionName.morning => .68,
                SessionName.afternoon => .9,
                SessionName.evening => .56,
              },
              groundHeight: largeText ? 104 : 82,
              live: true,
              animatePeek: animate,
              animate: animate,
              keepClear: Rect.fromLTWH(0, 0, largeText ? 420 : 248, 246),
              water: progress,
              waterFrom: (progress - .16).clamp(0.0, 1.0),
              waterLabel:
                  'Today is ${(progress * 100).round()} percent complete',
              borderRadius: CurreShape.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CurreGlyph(session.glyph, size: 23, color: sky.fg),
                      const SizedBox(width: CurreSpace.s2),
                      Text(
                        _capitalise(session.label),
                        style: type.label.weight(680).copyWith(color: sky.fg),
                      ),
                    ],
                  ),
                  const SizedBox(height: CurreSpace.s4),
                  FractionallySizedBox(
                    widthFactor: .74,
                    child: Text(
                      'What’s this ${session.label} for?',
                      style: type.headline.weight(730).copyWith(color: sky.fg),
                    ),
                  ),
                  const SizedBox(height: CurreSpace.s2),
                  FractionallySizedBox(
                    widthFactor: .68,
                    child: Text(
                      'Say it in one sentence. Curre puts just the apps you need on Home.',
                      style: type.body.copyWith(
                        color: sky.fg.withValues(alpha: .86),
                      ),
                      maxLines: largeText ? 4 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: ShapeDecoration(
                      color: sky.fg,
                      shape: CurreShape.pill,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CurreSpace.s4,
                        vertical: CurreSpace.s2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Plan now',
                            style: type.label
                                .weight(680)
                                .copyWith(color: sky.bg),
                          ),
                          const SizedBox(width: CurreSpace.s2),
                          CurreGlyph(
                            CurreGlyphKind.go,
                            size: 18,
                            color: sky.bg,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.progress,
    required this.onEdit,
    this.doneCount = 0,
  });

  final Plan plan;
  final double progress;
  final VoidCallback onEdit;

  /// How many of the plan's tasks are done.
  final int doneCount;

  /// The pill under the plan: its tasks, then how many are done.
  static String taskCountCopy(int tasks, int done) {
    if (done == 0 || tasks == 0) {
      return '$tasks ${tasks == 1 ? 'task' : 'tasks'} ready';
    }
    return '$done of $tasks done';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final sky = colors.sky(plan.session.designSession);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    final highlights = <SpanHighlight>[];
    for (final (index, app) in plan.apps.indexed) {
      final span = app.query;
      if (span != null) {
        highlights.add(
          SpanHighlight(
            span.start,
            span.end,
            style: type.you.copyWith(
              backgroundColor: colors.link(index + 1).mark,
              color: colors.markInk,
            ),
          ),
        );
      }
    }
    final end = plan.endPhrase;
    if (end != null) {
      highlights.add(
        SpanHighlight(
          end.start,
          end.end,
          style: type.you.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: colors.ember,
            decorationThickness: 2,
          ),
        ),
      );
    }
    return _HomeSceneSettle(
      builder: (context, animate) => SizedBox(
        key: const Key('home-plan-card'),
        height: largeText ? 580 : 306,
        child: SkyScene(
          session: plan.session.designSession,
          sun: SkySun.peek,
          sunAt: .84,
          sunSize: largeText ? 120 : 98,
          sunRise: switch (plan.session) {
            SessionName.morning => .7,
            SessionName.afternoon => .92,
            SessionName.evening => .58,
          },
          groundHeight: largeText ? 102 : 76,
          live: true,
          animatePeek: animate,
          animate: animate,
          keepClear: Rect.fromLTWH(0, 0, largeText ? 440 : 258, 210),
          water: progress,
          waterFrom: (progress - .16).clamp(0.0, 1.0),
          waterLabel:
              'This plan is ${(progress * 100).round()} percent complete',
          borderRadius: CurreShape.lg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CurreGlyph(plan.session.glyph, size: 21, color: sky.fg),
                  const SizedBox(width: CurreSpace.s2),
                  Expanded(
                    child: Text(
                      'Your ${plan.session.label}',
                      style: type.label.weight(680).copyWith(color: sky.fg),
                    ),
                  ),
                  if (!largeText) ...[
                    Text(
                      'until ${formatClock(plan.endsAt)}',
                      style: type.meta.copyWith(color: sky.fg),
                    ),
                    const SizedBox(width: CurreSpace.s2),
                  ],
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Change this plan',
                    icon: CurreGlyph(
                      CurreGlyphKind.editSpecify,
                      size: 20,
                      color: sky.fg,
                    ),
                  ),
                ],
              ),
              if (largeText) ...[
                const SizedBox(height: CurreSpace.s1),
                Text(
                  'until ${formatClock(plan.endsAt)}',
                  style: type.meta.copyWith(color: sky.fg),
                ),
              ],
              const SizedBox(height: CurreSpace.s3),
              Padding(
                padding: EdgeInsets.only(right: largeText ? 0 : CurreSpace.s12),
                child: SpanText(
                  plan.intention,
                  style: type.you.copyWith(color: sky.fg),
                  highlights: highlights,
                  maxLines: largeText ? 5 : 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              DecoratedBox(
                decoration: ShapeDecoration(
                  color: sky.fg,
                  shape: CurreShape.pill,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CurreSpace.s3,
                    vertical: CurreSpace.s2,
                  ),
                  child: Text(
                    taskCountCopy(plan.apps.length, doneCount),
                    style: type.caption.weight(680).copyWith(color: sky.bg),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lets Home acknowledge a newly visible scene, then leaves every essential
/// still. LiveSky and RisingWater also honor reduce motion and TickerMode.
class _HomeSceneSettle extends StatefulWidget {
  const _HomeSceneSettle({required this.builder});

  final Widget Function(BuildContext context, bool animate) builder;

  @override
  State<_HomeSceneSettle> createState() => _HomeSceneSettleState();
}

class _HomeSceneSettleState extends State<_HomeSceneSettle> {
  Timer? _timer;
  var _animate = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(RisingWater.sloshLength, () {
      if (mounted) setState(() => _animate = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _animate);
}

class _SightHeader extends StatelessWidget {
  const _SightHeader({required this.doorCount});

  final int doorCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('On Home now', style: type.title),
        const SizedBox(height: 2),
        Text(
          doorCount == 0
              ? 'Your always-there apps are below.'
              : 'Tap one to go straight to it.',
          style: type.caption.copyWith(color: colors.ink3),
        ),
      ],
    );
    final count = DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.raised,
        shape: StadiumBorder(side: BorderSide(color: colors.hairline)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CurreSpace.s3,
          vertical: CurreSpace.s2,
        ),
        child: Text(
          doorCount == 0 ? 'Nothing planned yet' : '$doorCount ready',
          style: type.meta.copyWith(color: colors.ink2),
        ),
      ),
    );
    if (largeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          words,
          const SizedBox(height: CurreSpace.s3),
          count,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: words),
        const SizedBox(width: CurreSpace.s3),
        count,
      ],
    );
  }
}

class _EmptySightNote extends StatelessWidget {
  const _EmptySightNote();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Semantics(
      key: const Key('home-empty-state'),
      label: 'Nothing planned yet. Plan your day and its apps show up here.',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.raised,
          borderRadius: CurreShape.md,
          border: Border.all(color: colors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(CurreSpace.s4),
          child: Row(
            children: [
              CurreGlyph(CurreGlyphKind.door, size: 24, color: colors.ink2),
              const SizedBox(width: CurreSpace.s3),
              Expanded(
                child: Text(
                  'Plan your day and its apps show up here.',
                  style: type.body.copyWith(color: colors.ink2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _capitalise(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

class _GrantBanner extends StatelessWidget {
  const _GrantBanner({
    required this.grant,
    required this.appLabel,
    required this.now,
  });

  final Grant grant;
  final String appLabel;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final open = colors.outcome(Outcome.open, laterTarget: Session.evening);
    final remaining = grant.expiresAt.difference(now.toUtc());
    final total = grant.expiresAt.difference(grant.grantedAt);
    final progress = total.inMilliseconds <= 0
        ? 0.0
        : (remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    return DecoratedBox(
      decoration: BoxDecoration(color: open.bg, borderRadius: CurreShape.dome),
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Column(
          children: [
            Row(
              children: [
                CurreGlyph(
                  kindGlyphs[grant.kind ?? ReasonKind.task]!,
                  size: 24,
                  color: open.fg,
                ),
                const SizedBox(width: CurreSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$appLabel is back for now',
                        style: type.label.weight(680).copyWith(color: open.fg),
                      ),
                      Text(
                        grant.task ?? grant.reason,
                        style: type.youSmall.copyWith(color: open.fg),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  formatDuration(remaining),
                  style: type.figure.copyWith(color: open.fg),
                ),
              ],
            ),
            const SizedBox(height: CurreSpace.s3),
            ClipRRect(
              borderRadius: BorderRadius.circular(CurreSpace.s1),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: CurreSpace.s1,
                color: colors.ember,
                backgroundColor: open.fg.withValues(alpha: .16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EssentialDoor extends StatelessWidget {
  const _EssentialDoor({required this.controller, required this.app});

  final CurreController controller;
  final LaunchableApp app;

  @override
  Widget build(BuildContext context) => DoorRow(
    appName: app.label,
    destination: 'Always available',
    appIcon: InstalledAppIcon(
      controller: controller,
      packageName: app.packageName,
    ),
    trailing: const CurreGlyph(
      CurreGlyphKind.essential,
      size: 19,
      semanticLabel: 'Always on Home',
    ),
    onTap: () => controller.plainLaunch(app.packageName),
    onLongPress: () => controller.plainLaunch(app.packageName),
  );
}

/// One of the active plan's tasks: its app's door, or the task away from
/// the phone when the plan has no apps. [_PlanDoor] keeps the app's link
/// number from the plan's own order wherever the row sits.
class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.controller,
    required this.plan,
    required this.item,
  });

  final CurreController controller;
  final Plan plan;
  final TaskProgress item;

  @override
  Widget build(BuildContext context) {
    final package = item.task.packageName;
    if (package == null) {
      return _OfflineTaskRow(controller: controller, task: item.task);
    }
    final index = plan.apps.indexWhere((app) => app.packageName == package);
    return _PlanDoor(
      controller: controller,
      plan: plan,
      app: plan.apps[index],
      link: index + 1,
      state: item.state,
    );
  }
}

/// What a task row says once the task is done, the same words for a door
/// and for a task away from the phone.
String? doneTaskCopy(TaskDoneState state) => switch (state) {
  TaskDoneState.open => null,
  TaskDoneState.proved => 'Done, with proof',
  TaskDoneState.waiting => 'Done · your note is waiting to be checked',
  TaskDoneState.checkedOff => 'Done · tap to add a note',
};

class _PlanDoor extends StatelessWidget {
  const _PlanDoor({
    required this.controller,
    required this.plan,
    required this.app,
    required this.link,
    this.state = TaskDoneState.open,
  });

  final CurreController controller;
  final Plan plan;
  final PlannedApp app;
  final int link;
  final TaskDoneState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final entry = controller.appFor(app.packageName);
    final appName = entry?.label ?? app.packageName;
    final destination = controller.destinationFor(app, plan);
    final done = doneTaskCopy(state);
    return DoorRow(
      appName: appName,
      destination: done ?? '→ $destination',
      appIcon: InstalledAppIcon(
        controller: controller,
        packageName: app.packageName,
      ),
      // A done row is a plain, quieter row; it still opens its app.
      link: done == null ? link : null,
      trailing: state == TaskDoneState.proved
          ? CurreGlyph(CurreGlyphKind.check, size: 22, color: colors.emberText)
          : null,
      semanticLabel: done == null
          ? null
          : '$appName, $done, opens $destination',
      onTap: () async {
        final task = PlannedTask.forDoor(plan, app);
        // Asked once per task; a check-off row invites its note, so a tap
        // there asks again on the way back.
        final ask =
            controller.asksAfterDoor(task) || state == TaskDoneState.checkedOff;
        final result = await controller.openPlanDoor(plan, app);
        if (!context.mounted) return;
        _reportDoorResult(context, result, app.query?.text);
        // Opened now, so it is waiting when the user comes back from the
        // door.
        if (result.succeeded && ask) {
          await showCompletionSheet(
            context,
            controller: controller,
            task: task,
          );
        }
      },
      onLongPress: () => controller.plainLaunch(app.packageName),
    );
  }
}

/// Finished tasks, below the ones still to do and in the plan's order.
/// More than [PlanCompletion.doneRowsShown] fold into one line with their
/// count until it is tapped. Rows stay tappable, so their apps stay at hand.
class _DoneTodayGroup extends StatefulWidget {
  const _DoneTodayGroup({
    super.key,
    required this.controller,
    required this.plan,
    required this.done,
  });

  final CurreController controller;
  final Plan plan;
  final List<TaskProgress> done;

  @override
  State<_DoneTodayGroup> createState() => _DoneTodayGroupState();
}

class _DoneTodayGroupState extends State<_DoneTodayGroup> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final count = widget.done.length;
    final folds = count > PlanCompletion.doneRowsShown;
    final countLabel = '$count ${count == 1 ? 'task' : 'tasks'}';
    if (folds && !_open) {
      return Semantics(
        key: const Key('done-today-folded'),
        button: true,
        label: 'Done today, $countLabel. Show them',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => setState(() => _open = true),
          borderRadius: CurreShape.md,
          splashFactory: NoSplash.splashFactory,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                CurreGlyph(
                  CurreGlyphKind.check,
                  size: 20,
                  color: colors.emberText,
                ),
                const SizedBox(width: CurreSpace.s2),
                Expanded(
                  child: Text(
                    'Done today · $count',
                    style: type.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('Show', style: type.label.copyWith(color: colors.ink2)),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      key: const Key('done-today'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Done today', style: type.label)),
            if (folds)
              TextButton(
                onPressed: () => setState(() => _open = false),
                child: Text(
                  'Hide',
                  style: type.label.copyWith(color: colors.ink2),
                ),
              ),
          ],
        ),
        const SizedBox(height: CurreSpace.s1),
        for (final (index, item) in widget.done.indexed) ...[
          if (index > 0) const SizedBox(height: CurreSpace.s1),
          _TaskRow(
            controller: widget.controller,
            plan: widget.plan,
            item: item,
          ),
        ],
      ],
    );
  }
}

/// The calm close of a plan whose tasks are all done: today's small, still
/// sun (it rises once, on the completion sheet, never here) and a way to
/// end the plan early so its apps go back to Hidden apps.
class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard({
    required this.session,
    required this.proof,
    required this.onEndPlan,
  });

  final SessionName session;
  final ProofSummary proof;
  final VoidCallback onEndPlan;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return DecoratedBox(
      key: const Key('home-all-done'),
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: CurreShape.md,
        border: Border.all(color: colors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProoflightSun(
                  rays: proof.raysToday,
                  proofDays: proof.currentRun,
                  size: 56,
                  lineColor: colors.ink3,
                  semanticLabel: proof.raysToday > 0
                      ? 'Today’s sun is up'
                      : 'Today’s sun',
                ),
                const SizedBox(width: CurreSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All done for this ${session.label}',
                        style: type.title,
                      ),
                      const SizedBox(height: CurreSpace.s1),
                      Text(
                        'Every task in this plan is done. End it now and its apps go back to Hidden apps.',
                        style: type.body.copyWith(color: colors.ink2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: CurreSpace.s4),
            CurreSecondaryButton(label: 'End plan now', onPressed: onEndPlan),
          ],
        ),
      ),
    );
  }
}

/// Asks once, then ends the plan and offers a short Undo.
Future<void> _confirmEndPlan(
  BuildContext context,
  CurreController controller,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('End this plan now?'),
      content: const Text(
        'Its apps go back to Hidden apps. You can plan again whenever you like.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep it'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('End plan'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final Plan? ended;
  try {
    ended = await controller.endPlanNow();
  } on Object {
    if (context.mounted) {
      showCurreSnack(context, 'Curre couldn’t end the plan. Please try again.');
    }
    return;
  }
  if (ended == null || !context.mounted) return;
  final colors = Theme.of(context).extension<CurreColors>()!;
  final type = Theme.of(context).extension<CurreType>()!;
  showCurreSnack(
    context,
    'Plan ended. Its apps are back in Hidden apps.',
    actionLabel: 'Undo',
    duration: endPlanUndoWindow,
    onAction: () async {
      final back = await controller.undoEndPlan(ended!);
      if (back) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'That plan’s time is already up.',
              style: type.body.copyWith(color: colors.paper),
            ),
            backgroundColor: colors.ink,
            behavior: SnackBarBehavior.floating,
          ),
        );
    },
  );
}

/// How long "Plan ended" offers its Undo.
const Duration endPlanUndoWindow = Duration(seconds: 6);

/// A task done away from the phone. Start leaves Curre's trace before the
/// task, as a door does; Done asks the one question. The row stays after
/// its plan ends until the task is closed, so a long task can still be.
class _OfflineTaskRow extends StatelessWidget {
  const _OfflineTaskRow({required this.controller, required this.task});

  final CurreController controller;
  final PlannedTask task;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final trace = controller.latestTraceFor(task);
    final record = controller.proofFor(task);
    final String destination;
    final String? action;
    if (trace == null) {
      destination = 'Tap Start when you begin';
      action = 'Start';
    } else if (record == null) {
      destination = 'Started ${formatClock(trace.at)} · tap when you’re done';
      action = 'Done';
    } else if (record.countsForProoflight) {
      destination = 'Done, with proof';
      action = null;
    } else if (record.isPending) {
      destination = 'Done · your note is waiting to be checked';
      action = null;
    } else {
      destination = 'Done · tap to add a note';
      action = null;
    }
    final proved = record?.countsForProoflight ?? false;
    // A waiting note is checked on its own; supported proof is complete.
    final closed = proved || (record?.isPending ?? false);
    return DoorRow(
      appName: 'Away from your phone',
      destination: destination,
      appIcon: Center(
        child: CurreGlyph(
          CurreGlyphKind.kindTask,
          size: 26,
          color: colors.ink2,
        ),
      ),
      trailing: action != null
          ? DecoratedBox(
              decoration: ShapeDecoration(
                color: colors.ink,
                shape: CurreShape.pill,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CurreSpace.s3,
                  vertical: CurreSpace.s2,
                ),
                child: Text(
                  action,
                  style: type.label.copyWith(color: colors.paper),
                ),
              ),
            )
          : proved
          ? CurreGlyph(CurreGlyphKind.check, size: 22, color: colors.emberText)
          : null,
      semanticLabel: ['Away from your phone', destination, ?action].join(', '),
      onTap: trace == null
          ? () => controller.startOfflineTask(task)
          : closed
          ? null
          : () => showCompletionSheet(
              context,
              controller: controller,
              task: task,
            ),
    );
  }
}

class _GrantDoor extends StatelessWidget {
  const _GrantDoor({required this.controller, required this.grant});

  final CurreController controller;
  final Grant grant;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final entry = controller.appFor(grant.packageName);
    final tint = colors.outcome(Outcome.open, laterTarget: Session.evening);
    return DoorRow(
      appName: entry?.label ?? grant.packageName,
      destination: '→ ${controller.grantDestinationFor(grant)}',
      appIcon: InstalledAppIcon(
        controller: controller,
        packageName: grant.packageName,
      ),
      tint: tint,
      trailing: Text(
        formatDuration(grant.expiresAt.difference(controller.now.toUtc())),
        style: type.figure.copyWith(fontSize: 13, color: tint.fg),
      ),
      onTap: () async {
        final result = await controller.openGrantDoor(grant);
        if (!context.mounted) return;
        _reportDoorResult(context, result, grant.task);
      },
      onLongPress: () => controller.plainLaunch(grant.packageName),
    );
  }
}

void _reportDoorResult(
  BuildContext context,
  DoorLaunchResult result,
  String? target,
) {
  if (result.kind == DoorLaunchKind.failed) {
    showCurreSnack(
      context,
      'That didn’t open. Press and hold the app to open it the usual way.',
    );
  } else if (result.usedFallback && target != null) {
    showCurreSnack(context, 'Copied “$target”. Paste it into the search box.');
  }
}

class ProfileSheet extends StatefulWidget {
  const ProfileSheet({super.key, required this.controller});

  final CurreController controller;

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.controller.settings.displayName,
  );
  late String? _avatarId = widget.controller.settings.avatarId;
  var _editing = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final proof = widget.controller.proofSummary;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.raised,
          borderRadius: CurreShape.sheet,
          boxShadow: CurreElevation.e2,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(CurreSpace.s5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ProfileAvatarButton(
                      displayName: widget.controller.settings.displayName,
                      avatarId: _avatarId,
                      motion: AvatarMotion.reactOnce,
                    ),
                    const SizedBox(width: CurreSpace.s3),
                    Expanded(
                      child: Text(
                        widget.controller.settings.displayName ?? 'You',
                        style: type.title,
                      ),
                    ),
                    RoundGlyphButton(
                      glyph: CurreGlyphKind.close,
                      label: 'Close profile',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: CurreSpace.s5),
                Text('Your face', style: type.label),
                const SizedBox(height: CurreSpace.s1),
                Text(
                  'Pick the one that feels like you.',
                  style: type.caption.copyWith(color: colors.ink2),
                ),
                const SizedBox(height: CurreSpace.s3),
                AvatarPicker(
                  selectedAvatarId: _avatarId,
                  onSelected: (id) {
                    setState(() => _avatarId = id);
                    unawaited(
                      widget.controller.updateSettings(
                        widget.controller.settings.copyWith(avatarId: id),
                      ),
                    );
                  },
                ),
                if (_avatarId != null) ...[
                  const SizedBox(height: CurreSpace.s2),
                  CurreSecondaryButton(
                    label: 'Use my initial instead',
                    onPressed: () {
                      setState(() => _avatarId = null);
                      unawaited(
                        widget.controller.updateSettings(
                          widget.controller.settings.copyWith(
                            clearAvatarId: true,
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: CurreSpace.s5),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ProfileStat(
                          label: 'Proof days',
                          value: '${proof.totalProofDays}',
                        ),
                      ),
                      const SizedBox(width: CurreSpace.s3),
                      Expanded(
                        child: _ProfileStat(
                          label: 'Best run',
                          value: proof.bestRun == 1
                              ? '1 day'
                              : '${proof.bestRun} days',
                        ),
                      ),
                      const SizedBox(width: CurreSpace.s3),
                      Expanded(
                        child: _ProfileStat(
                          label: 'Cloud days',
                          value: '${proof.cloudDays}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: CurreSpace.s4),
                CurreSecondaryButton(
                  label: 'History',
                  glyph: CurreGlyphKind.history,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          HistoryScreen(controller: widget.controller),
                    ),
                  ),
                ),
                const SizedBox(height: CurreSpace.s2),
                if (_editing) ...[
                  TextField(
                    controller: _name,
                    autofocus: true,
                    maxLength: 60,
                    decoration: const InputDecoration(labelText: 'Your name'),
                  ),
                  CurrePrimaryButton(
                    label: 'Save name',
                    onPressed: () async {
                      await widget.controller.updateDisplayName(_name.text);
                      if (mounted) setState(() => _editing = false);
                    },
                  ),
                ] else
                  CurreSecondaryButton(
                    label: 'Edit name',
                    glyph: CurreGlyphKind.editSpecify,
                    onPressed: () => setState(() => _editing = true),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: CurreShape.md,
        border: Border.all(color: colors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shrinks rather than wraps, so three stats share one row.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: type.title, maxLines: 1),
            ),
            Text(label, style: type.caption.copyWith(color: colors.ink3)),
          ],
        ),
      ),
    );
  }
}
