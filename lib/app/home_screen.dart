import 'dart:async';

import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../doors/door_models.dart';
import '../doors/door_router.dart';
import '../platform/home_refresh.dart';
import 'app_widgets.dart';
import 'checkin_screen.dart';
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
                    _CheckinPrompt(session: window.session, onTap: openCheckin)
                  else
                    Hero(
                      tag: 'active-plan-${plan.id}',
                      flightShuttleBuilder: (_, _, _, _, _) =>
                          PlanHeroSentence(intention: plan.intention),
                      child: Material(
                        color: Colors.transparent,
                        child: _PlanCard(plan: plan, onEdit: openCheckin),
                      ),
                    ),
                  for (final grant in controller.activeGrants) ...[
                    const SizedBox(height: CurreSpace.s4),
                    _GrantBanner(
                      grant: grant,
                      appLabel:
                          controller.appFor(grant.packageName)?.label ?? 'App',
                      now: controller.now,
                    ),
                  ],
                  const SizedBox(height: CurreSpace.s6),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: CurreSpace.s1,
                    children: [
                      Text('On Home', style: type.title),
                      Text(
                        'Tap opens the task',
                        style: type.caption.copyWith(color: colors.ink3),
                      ),
                    ],
                  ),
                  const SizedBox(height: CurreSpace.s3),
                  if (plan == null && controller.activeGrants.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: CurreSpace.s8,
                      ),
                      child: Text(
                        'Nothing else in sight yet.',
                        style: type.body.copyWith(color: colors.ink2),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (plan != null)
                    for (final (index, app) in plan.apps.indexed) ...[
                      if (index > 0) const SizedBox(height: CurreSpace.s2),
                      _PlanDoor(
                        controller: controller,
                        plan: plan,
                        app: app,
                        link: index + 1,
                      ),
                    ],
                  for (final grant in controller.activeGrants.where(
                    (grant) =>
                        plan?.packages.contains(grant.packageName) != true,
                  )) ...[
                    const SizedBox(height: CurreSpace.s2),
                    _GrantDoor(controller: controller, grant: grant),
                  ],
                  if (extraEssentials.isNotEmpty) ...[
                    const SizedBox(height: CurreSpace.s5),
                    Text('Always in sight', style: type.label),
                    const SizedBox(height: CurreSpace.s2),
                    for (final app in extraEssentials) ...[
                      _EssentialDoor(controller: controller, app: app),
                      const SizedBox(height: CurreSpace.s2),
                    ],
                  ],
                  if (plan != null) ...[
                    const SizedBox(height: CurreSpace.s3),
                    Text(
                      'Long-press any door to open the app normally.',
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

class _CheckinPrompt extends StatelessWidget {
  const _CheckinPrompt({required this.session, required this.onTap});

  final SessionName session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final sky = colors.sky(session.designSession);
    return Semantics(
      button: true,
      label: 'Plan this ${session.label}',
      excludeSemantics: true,
      child: Material(
        color: sky.bg,
        borderRadius: CurreShape.dome,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          child: Padding(
            padding: const EdgeInsets.all(CurreSpace.s5),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CurreGlyph(session.glyph, size: 24, color: sky.fg),
                      const SizedBox(height: CurreSpace.s5),
                      Text(
                        'What’s this ${session.label} for?',
                        style: type.title.weight(720).copyWith(color: sky.fg),
                      ),
                      const SizedBox(height: CurreSpace.s2),
                      Text(
                        'Say it or type it in one sentence.',
                        style: type.body.copyWith(
                          color: sky.fg.withValues(alpha: .84),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: CurreSpace.s4),
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sky.fg,
                    shape: BoxShape.circle,
                  ),
                  child: CurreGlyph(
                    CurreGlyphKind.speak,
                    color: sky.bg,
                    semanticLabel: 'Speak or type',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onEdit});

  final Plan plan;
  final VoidCallback onEdit;

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
    return DecoratedBox(
      decoration: BoxDecoration(color: sky.bg, borderRadius: CurreShape.lg),
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s5),
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
                    'ends ${formatClock(plan.endsAt)}',
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
                'ends ${formatClock(plan.endsAt)}',
                style: type.meta.copyWith(color: sky.fg),
              ),
            ],
            const SizedBox(height: CurreSpace.s3),
            SpanText(
              plan.intention,
              style: type.you.copyWith(color: sky.fg),
              highlights: highlights,
            ),
          ],
        ),
      ),
    );
  }
}

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
                        '$appLabel is in sight',
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
      semanticLabel: 'Essential',
    ),
    onTap: () => controller.plainLaunch(app.packageName),
    onLongPress: () => controller.plainLaunch(app.packageName),
  );
}

class _PlanDoor extends StatelessWidget {
  const _PlanDoor({
    required this.controller,
    required this.plan,
    required this.app,
    required this.link,
  });

  final CurreController controller;
  final Plan plan;
  final PlannedApp app;
  final int link;

  @override
  Widget build(BuildContext context) {
    final entry = controller.appFor(app.packageName);
    final destination = controller.destinationFor(app, plan);
    return DoorRow(
      appName: entry?.label ?? app.packageName,
      destination: '→ $destination',
      appIcon: InstalledAppIcon(
        controller: controller,
        packageName: app.packageName,
      ),
      link: link,
      onTap: () async {
        final result = await controller.openPlanDoor(plan, app);
        if (!context.mounted) return;
        _reportDoorResult(context, result, app.query?.text);
      },
      onLongPress: () => controller.plainLaunch(app.packageName),
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
      destination: '→ ${grant.task ?? grant.reason}',
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
    showCurreSnack(context, 'That door did not open. Try a long-press.');
  } else if (result.usedFallback && target != null) {
    showCurreSnack(context, 'Copied: paste “$target” into search.');
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
                        widget.controller.settings.displayName ?? 'Curre user',
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
                Text('Choose your profile', style: type.label),
                const SizedBox(height: CurreSpace.s1),
                Text(
                  'The faces stay unnamed. Pick the one that feels like you.',
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
                Row(
                  children: [
                    Expanded(
                      child: _ProfileStat(label: 'Proof days', value: '0'),
                    ),
                    const SizedBox(width: CurreSpace.s3),
                    Expanded(
                      child: _ProfileStat(label: 'Best run', value: '0 days'),
                    ),
                  ],
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
                const SizedBox(height: CurreSpace.s2),
                Text(
                  'Prooflight arrives after the core flow. Until then, proof days stay honestly at 0.',
                  style: type.caption.copyWith(color: colors.ink3),
                  textAlign: TextAlign.center,
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
            Text(value, style: type.title),
            Text(label, style: type.caption.copyWith(color: colors.ink3)),
          ],
        ),
      ),
    );
  }
}
