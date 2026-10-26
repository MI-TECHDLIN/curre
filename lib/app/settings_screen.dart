import 'dart:async';

import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../platform/platform.dart';
import 'app_choice_screen.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';
import 'history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});

  final CurreController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _name = TextEditingController(
    text: widget.controller.settings.displayName,
  );
  late double _threshold = widget.controller.settings.threshold;
  bool? _isHome;
  bool _checkingUsageAccess = true;
  bool _checkingNotificationAccess = true;

  CurreController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_checkHome());
    unawaited(_refreshUsageAccess());
    unawaited(_refreshNotificationAccess());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _name.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The home screen and access choices are made in Android's settings;
    // show the real answers when the user comes back.
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkHome());
      unawaited(_refreshUsageAccess());
      unawaited(_refreshNotificationAccess());
    }
  }

  Future<void> _checkHome() async {
    final isHome = await controller.isDefaultHome();
    if (mounted) setState(() => _isHome = isHome);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final settings = controller.settings;
    final extraEssentials = settings.essentials.length;
    return CurrePage(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              CurreSpace.gutter,
              CurreSpace.s3,
              CurreSpace.gutter,
              0,
            ),
            child: CurreTopBar(
              title: 'Curre settings',
              subtitle: 'Changes here only affect Curre.',
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(CurreSpace.gutter),
              children: [
                const _SectionTitle('Your day'),
                const SizedBox(height: CurreSpace.s1),
                Text(
                  'When each part of your day starts, Curre asks what it’s for.',
                  style: type.caption.copyWith(color: colors.ink3),
                ),
                const SizedBox(height: CurreSpace.s2),
                for (final session in SessionName.values)
                  _SettingsTile(
                    glyph: session.glyph,
                    title: _capitalise(session.label),
                    subtitle: 'Starts at ${settings.sessionStarts[session]}',
                    onTap: () => _pickTime(session),
                  ),
                const SizedBox(height: CurreSpace.s6),
                const _SectionTitle('Your apps'),
                const SizedBox(height: CurreSpace.s2),
                _SettingsTile(
                  glyph: CurreGlyphKind.essential,
                  title: 'Always on Home',
                  subtitle: extraEssentials <= 3
                      ? 'Phone, Messages and Settings'
                      : 'Phone, Messages, Settings and ${extraEssentials - 3} more',
                  onTap: () => _editApps(AppChoiceKind.alwaysOnHome),
                ),
                _SettingsTile(
                  glyph: CurreGlyphKind.door,
                  title: 'Apps your plans can use',
                  subtitle: '${settings.candidates.length} apps',
                  onTap: () => _editApps(AppChoiceKind.planApps),
                ),
                const SizedBox(height: CurreSpace.s6),
                const _SectionTitle('How strict should Curre be?'),
                const SizedBox(height: CurreSpace.s2),
                _StrictnessCard(
                  value: _threshold,
                  onChanged: (value) => setState(() => _threshold = value),
                  onChangeEnd: _saveThreshold,
                ),
                const SizedBox(height: CurreSpace.s6),
                const _SectionTitle('Hidden apps'),
                const SizedBox(height: CurreSpace.s2),
                _AccessCard(
                  key: const Key('settings-ask-why'),
                  title: 'Ask “Why now?” when a hidden app opens',
                  status: _checkingUsageAccess
                      ? 'Checking…'
                      : !controller.hasUsageAccess
                      ? 'Needs your OK in Android first'
                      : settings.askWhyOnHiddenAppOpen
                      ? 'On, even from recent apps, notifications and links'
                      : 'Off',
                  needsAccess:
                      !_checkingUsageAccess && !controller.hasUsageAccess,
                  value: settings.askWhyOnHiddenAppOpen,
                  onChanged: _setGentleInterceptEnabled,
                  explanation: usageAccessExplanation,
                  allowLabel: 'Turn on Usage access',
                  allowGlyph: CurreGlyphKind.outOfSight,
                  onAllow: _requestUsageAccess,
                ),
                const SizedBox(height: CurreSpace.s3),
                _AccessCard(
                  key: const Key('settings-quiet-notifications'),
                  title: 'Keep hidden apps quiet',
                  status: _checkingNotificationAccess
                      ? 'Checking…'
                      : !controller.hasNotificationAccess
                      ? 'Needs your OK in Android first'
                      : settings.quietNotificationsFromHiddenApps
                      ? 'On. You’ll find them in Missed notifications.'
                      : 'Off',
                  needsAccess:
                      !_checkingNotificationAccess &&
                      !controller.hasNotificationAccess,
                  value: settings.quietNotificationsFromHiddenApps,
                  onChanged: _setQuietNotificationsEnabled,
                  explanation: notificationAccessExplanation,
                  allowLabel: 'Turn on notification access',
                  allowGlyph: CurreGlyphKind.notify,
                  onAllow: _requestNotificationAccess,
                ),
                const SizedBox(height: CurreSpace.s6),
                const _SectionTitle('Quiet nudges'),
                const SizedBox(height: CurreSpace.s2),
                _SettingsTile(
                  glyph: CurreGlyphKind.notify,
                  title: 'Turn on quiet nudges',
                  subtitle:
                      'A silent note when time you asked for is up. No sound, no buzz.',
                  onTap: _askForNudges,
                ),
                const SizedBox(height: CurreSpace.s6),
                const _SectionTitle('Your name'),
                const SizedBox(height: CurreSpace.s2),
                TextField(
                  controller: _name,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Name in your greeting',
                    filled: true,
                    fillColor: colors.raised,
                  ),
                ),
                CurrePrimaryButton(label: 'Save name', onPressed: _saveName),
                const SizedBox(height: CurreSpace.s6),
                const _SectionTitle('Your home screen'),
                const SizedBox(height: CurreSpace.s2),
                _HomeScreenCard(
                  isHome: _isHome,
                  onSwitch: _switchHomeScreen,
                  onMakeHome: _makeCurreHome,
                ),
                const SizedBox(height: CurreSpace.s6),
                const _SectionTitle('History and privacy'),
                const SizedBox(height: CurreSpace.s2),
                _SettingsTile(
                  glyph: CurreGlyphKind.history,
                  title: 'History',
                  subtitle:
                      'Your plans and the apps you brought back, from the last 30 days. Only on this phone.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => HistoryScreen(controller: controller),
                    ),
                  ),
                ),
                _SettingsTile(
                  glyph: CurreGlyphKind.close,
                  title: 'Clear history',
                  subtitle:
                      'Delete past plans, reasons, notes and missed notifications from this phone',
                  onTap: _confirmClearHistory,
                  destructive: true,
                ),
                const SizedBox(height: CurreSpace.s6),
                const _SectionTitle('About'),
                const SizedBox(height: CurreSpace.s2),
                _SettingsTile(
                  glyph: CurreGlyphKind.info,
                  title: 'Licences',
                  subtitle: 'The fonts, icons and illustrations Curre uses',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Curre',
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'Curre opens the task, not the app.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(SessionName session) async {
    final current = controller.settings.sessionStarts[session]!;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Your ${session.label} starts at',
    );
    if (selected == null || !mounted) return;
    final starts = Map<SessionName, LocalTime>.of(
      controller.settings.sessionStarts,
    )..[session] = LocalTime(selected.hour, selected.minute);
    final Settings next;
    try {
      next = controller.settings.copyWith(sessionStarts: starts);
    } on ArgumentError {
      showCurreSnack(
        context,
        'Mornings start before afternoons, and afternoons before evenings. Try a different time.',
      );
      return;
    }
    await _save(
      next,
      saved: 'Your ${session.label} now starts at ${starts[session]}.',
    );
  }

  Future<void> _saveThreshold(double value) => _save(
    controller.settings.copyWith(threshold: value),
    onError: () => setState(() => _threshold = controller.settings.threshold),
  );

  Future<void> _saveName() async {
    FocusScope.of(context).unfocus();
    await _save(
      controller.settings.copyWith(
        displayName: _name.text,
        clearDisplayName: Settings.normalizeDisplayName(_name.text) == null,
      ),
      saved: 'Saved. Curre will greet you by this name.',
    );
  }

  /// Saves [next]; on failure says so plainly and leaves things as they
  /// were.
  Future<void> _save(
    Settings next, {
    String? saved,
    VoidCallback? onError,
  }) async {
    try {
      await controller.updateSettings(next);
      if (!mounted) return;
      setState(() {});
      if (saved != null) showCurreSnack(context, saved);
    } on Object {
      onError?.call();
      if (mounted) {
        showCurreSnack(
          context,
          'Curre couldn’t save that on this phone. Please try again.',
        );
      }
    }
  }

  Future<void> _refreshUsageAccess() async {
    await controller.refreshUsageAccess();
    if (mounted) setState(() => _checkingUsageAccess = false);
  }

  Future<void> _refreshNotificationAccess() async {
    await controller.refreshNotificationAccess();
    if (mounted) setState(() => _checkingNotificationAccess = false);
  }

  Future<void> _setGentleInterceptEnabled(bool enabled) => _save(
    controller.settings.copyWith(askWhyOnHiddenAppOpen: enabled),
  );

  Future<void> _setQuietNotificationsEnabled(bool enabled) => _save(
    controller.settings.copyWith(quietNotificationsFromHiddenApps: enabled),
  );

  Future<void> _requestUsageAccess() async {
    final granted = await controller.requestUsageAccess();
    if (!mounted) return;
    setState(() => _checkingUsageAccess = false);
    showCurreSnack(
      context,
      granted
          ? 'Done. Curre will ask “Why now?” when a hidden app opens.'
          : 'It’s still off. You can turn it on here any time.',
    );
  }

  Future<void> _requestNotificationAccess() async {
    final granted = await controller.requestNotificationAccess();
    if (!mounted) return;
    setState(() => _checkingNotificationAccess = false);
    showCurreSnack(
      context,
      granted
          ? 'Done. Hidden apps will stay quiet until you bring them back.'
          : 'It’s still off. You can turn it on here any time.',
    );
  }

  Future<void> _editApps(AppChoiceKind kind) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AppChoiceScreen(controller: controller, kind: kind),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _askForNudges() async {
    final allowed = await controller.requestNotifications();
    if (!mounted) return;
    showCurreSnack(
      context,
      allowed
          ? 'Quiet nudges are on.'
          : 'Nudges are off. To turn them on, allow notifications for Curre in your phone’s Settings.',
    );
  }

  Future<void> _switchHomeScreen() async {
    final opened = await controller.openHomeSettings();
    if (!mounted) return;
    final help = switch (opened) {
      HomeSettingsOpened.homeApps => null,
      HomeSettingsOpened.defaultApps =>
        'Tap “Home app”, then choose the one you want.',
      HomeSettingsOpened.settings =>
        'Your phone opened Settings. Search for “Home app” (or open Apps, then Default apps), then choose the one you want.',
      HomeSettingsOpened.none =>
        'Open your phone’s Settings app and search for “Home app”. Choose the one you want there.',
    };
    if (help != null) showCurreSnack(context, help);
  }

  Future<void> _makeCurreHome() async {
    final isHome = await controller.requestHomeRole();
    if (!mounted) return;
    setState(() => _isHome = isHome);
    if (!isHome) {
      showCurreSnack(
        context,
        'Curre isn’t your home screen yet. Open your phone’s Settings, search for “Home app” and choose Curre.',
      );
    }
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear your history?'),
        content: const Text(
          'This deletes your past plans, the reasons you gave for bringing apps back, the notes you wrote after tasks and your missed notifications. Your proof days, today’s plan and any time already running stay as they are.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear history'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await controller.clearHistory();
      if (mounted) showCurreSnack(context, 'History cleared.');
    } on Object {
      if (mounted) {
        showCurreSnack(
          context,
          'Curre couldn’t clear your history. Please try again.',
        );
      }
    }
  }

  static String _capitalise(String value) =>
      '${value[0].toUpperCase()}${value.substring(1)}';
}

/// "Switch to another home screen": a kind way out to another home screen
/// app, and the way back when Curre isn't the home screen.
class _HomeScreenCard extends StatelessWidget {
  const _HomeScreenCard({
    required this.isHome,
    required this.onSwitch,
    required this.onMakeHome,
  });

  /// Null while Curre is still asking Android.
  final bool? isHome;
  final VoidCallback onSwitch;
  final VoidCallback onMakeHome;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final notHome = isHome == false;
    return Container(
      padding: const EdgeInsets.all(CurreSpace.s4),
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: CurreShape.md,
        border: Border.all(color: colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CurrePropArt(CurreProp.house, size: 48),
              const SizedBox(width: CurreSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Switch to another home screen',
                      style: type.label.weight(700).copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: CurreSpace.s1),
                    Text(
                      notHome
                          ? 'Curre isn’t your home screen right now. Your plans and history are still here, ready when you want them.'
                          : 'Want a different home screen for a while? That’s okay. Android lets you choose which app opens when you press Home. Your plans and history stay on this phone, and you can switch back any time.',
                      style: type.body.copyWith(color: colors.ink2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: CurreSpace.s4),
          if (notHome) ...[
            CurrePrimaryButton(
              label: 'Make Curre my home screen',
              glyph: CurreGlyphKind.homeRole,
              onPressed: onMakeHome,
            ),
            const SizedBox(height: CurreSpace.s2),
            CurreSecondaryButton(
              label: 'Open home screen settings',
              onPressed: onSwitch,
            ),
          ] else
            CurreSecondaryButton(
              label: 'Choose a home screen app',
              glyph: CurreGlyphKind.go,
              onPressed: onSwitch,
            ),
          const SizedBox(height: CurreSpace.s3),
          Text(
            'If your phone opens its Settings instead, look for Apps, then Default apps, then Home app.',
            style: type.caption.copyWith(color: colors.ink3),
          ),
        ],
      ),
    );
  }
}

/// A Hidden apps switch that needs an Android permission: the switch, what
/// it does in plain words and, while Android still says no, a way to allow
/// it.
class _AccessCard extends StatelessWidget {
  const _AccessCard({
    super.key,
    required this.title,
    required this.status,
    required this.needsAccess,
    required this.value,
    required this.onChanged,
    required this.explanation,
    required this.allowLabel,
    required this.allowGlyph,
    required this.onAllow,
  });

  final String title;
  final String status;
  final bool needsAccess;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String explanation;
  final String allowLabel;
  final CurreGlyphKind allowGlyph;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Container(
      padding: const EdgeInsets.all(CurreSpace.s4),
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: CurreShape.md,
        border: Border.all(color: colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(title, style: type.label),
            subtitle: Text(
              status,
              style: type.caption.copyWith(
                color: needsAccess ? colors.emberText : colors.ink2,
              ),
            ),
            value: value,
            onChanged: onChanged,
          ),
          const SizedBox(height: CurreSpace.s2),
          Text(explanation, style: type.caption.copyWith(color: colors.ink3)),
          if (needsAccess) ...[
            const SizedBox(height: CurreSpace.s4),
            CurrePrimaryButton(
              label: allowLabel,
              glyph: allowGlyph,
              onPressed: onAllow,
            ),
          ],
        ],
      ),
    );
  }
}

class _StrictnessCard extends StatelessWidget {
  const _StrictnessCard({
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  static String wordFor(double value) => value < .65
      ? 'Gentle'
      : value < .8
      ? 'Balanced'
      : 'Strict';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return DecoratedBox(
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
            Text(wordFor(value), style: type.title),
            Slider(
              value: value,
              min: .5,
              max: .95,
              divisions: 9,
              label: wordFor(value),
              semanticFormatterCallback: wordFor,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
            Row(
              children: [
                Text('Gentle', style: type.caption.copyWith(color: colors.ink3)),
                const Spacer(),
                Text('Strict', style: type.caption.copyWith(color: colors.ink3)),
              ],
            ),
            const SizedBox(height: CurreSpace.s2),
            Text(
              'When you bring back a hidden app, Curre checks your reason. The stricter it is, the clearer your reason needs to be before the app opens.',
              style: type.caption.copyWith(color: colors.ink2),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<CurreType>()!;
    return Semantics(
      header: true,
      child: Text(label, style: type.title.copyWith(fontSize: 18)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.glyph,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final CurreGlyphKind glyph;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final foreground = destructive ? colors.emberText : colors.ink;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: CurreSpace.s2),
              child: Row(
                children: [
                  CurreGlyph(glyph, color: foreground),
                  const SizedBox(width: CurreSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: type.label.copyWith(color: foreground),
                        ),
                        Text(
                          subtitle,
                          style: type.caption.copyWith(color: colors.ink3),
                        ),
                      ],
                    ),
                  ),
                  CurreGlyph(CurreGlyphKind.go, size: 18, color: colors.ink3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
