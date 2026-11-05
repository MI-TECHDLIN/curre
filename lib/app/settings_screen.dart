import 'dart:async';

import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../l10n/l10n.dart';
import '../platform/platform.dart';
import 'access_help.dart';
import 'app_choice_screen.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';
import 'focus_widgets.dart';
import 'history_screen.dart';
import 'privacy_details_screen.dart';
import 'voice_sheet.dart';

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

  /// Whether Usage access or notification access was asked for here and
  /// Android still says no: their cards then show the steps again.
  bool _usageTried = false;
  bool _notificationAccessTried = false;

  /// Android's answer for quiet nudges; null when Curre can't tell.
  bool? _notificationsAllowed;
  bool _checkingNotifications = true;

  CurreController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_checkHome());
    unawaited(_refreshUsageAccess());
    unawaited(_refreshNotificationAccess());
    unawaited(_refreshNotificationPermission());
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
      unawaited(_refreshNotificationPermission());
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CurreSpace.gutter,
              CurreSpace.s3,
              CurreSpace.gutter,
              0,
            ),
            child: CurreTopBar(
              title: context.l10n.curreSettings,
              subtitle: context.l10n.settingsSubtitle,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(CurreSpace.gutter),
              children: [
                _SectionTitle(context.l10n.sectionYourFocus),
                const SizedBox(height: CurreSpace.s2),
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) =>
                      FocusSettingsCard(controller: controller),
                ),
                const SizedBox(height: CurreSpace.s6),
                _SettingsTile(
                  glyph: CurreGlyphKind.curreSettings,
                  title: context.l10n.language,
                  subtitle: _languageName(context.l10n, settings.languageCode),
                  onTap: _pickLanguage,
                ),
                const SizedBox(height: CurreSpace.s6),
                _SectionTitle(context.l10n.sectionYourDay),
                const SizedBox(height: CurreSpace.s1),
                Text(
                  context.l10n.dayStartsHelp,
                  style: type.caption.copyWith(color: colors.ink3),
                ),
                const SizedBox(height: CurreSpace.s2),
                for (final session in SessionName.values)
                  _SettingsTile(
                    glyph: session.glyph,
                    title: _capitalise(session.localizedLabel(context.l10n)),
                    subtitle: context.l10n.startsAt(
                      settings.sessionStarts[session].toString(),
                    ),
                    onTap: () => _pickTime(session),
                  ),
                const SizedBox(height: CurreSpace.s6),
                _SectionTitle(context.l10n.sectionYourApps),
                const SizedBox(height: CurreSpace.s2),
                _SettingsTile(
                  glyph: CurreGlyphKind.essential,
                  title: context.l10n.alwaysOnHome,
                  subtitle: extraEssentials <= 3
                      ? context.l10n.defaultEssentials
                      : context.l10n.defaultEssentialsMore(extraEssentials - 3),
                  onTap: () => _editApps(AppChoiceKind.alwaysOnHome),
                ),
                _SettingsTile(
                  glyph: CurreGlyphKind.door,
                  title: context.l10n.planApps,
                  subtitle: context.l10n.appsCount(settings.candidates.length),
                  onTap: () => _editApps(AppChoiceKind.planApps),
                ),
                _SettingsTile(
                  key: const Key('settings-hidden-apps'),
                  glyph: CurreGlyphKind.outOfSight,
                  title: context.l10n.hiddenApps,
                  subtitle: hiddenChoiceSummary(
                    controller.chosenHiddenPackages.length,
                    context.l10n,
                  ),
                  onTap: () => _editApps(AppChoiceKind.hidden),
                ),
                const SizedBox(height: CurreSpace.s6),
                _SectionTitle(context.l10n.strictQuestion),
                const SizedBox(height: CurreSpace.s2),
                _StrictnessCard(
                  value: _threshold,
                  onChanged: (value) => setState(() => _threshold = value),
                  onChangeEnd: _saveThreshold,
                ),
                const SizedBox(height: CurreSpace.s6),
                _SectionTitle(context.l10n.sectionHiddenApps),
                const SizedBox(height: CurreSpace.s2),
                _AccessCard(
                  key: const Key('settings-ask-why'),
                  title: context.l10n.askWhyHidden,
                  status: _checkingUsageAccess
                      ? context.l10n.checking
                      : !controller.hasUsageAccess
                      ? context.l10n.needsAndroidOk
                      : settings.askWhyOnHiddenAppOpen &&
                            controller.pausedAwayFromHome
                      ? context.l10n.pausedOtherHome
                      : settings.askWhyOnHiddenAppOpen && controller.isRestDay
                      ? context.l10n.restingToday
                      : settings.askWhyOnHiddenAppOpen
                      ? context.l10n.askWhyOn
                      : context.l10n.off,
                  needsAccess:
                      !_checkingUsageAccess && !controller.hasUsageAccess,
                  value: settings.askWhyOnHiddenAppOpen,
                  onChanged: _setGentleInterceptEnabled,
                  explanation: usageAccessExplanation,
                  allowLabel: context.l10n.turnOnUsageAccess,
                  allowGlyph: CurreGlyphKind.outOfSight,
                  onAllow: _requestUsageAccess,
                  help: RestrictedSettingsHelp(
                    controller: controller,
                    stillOff: _usageTried,
                  ),
                ),
                const SizedBox(height: CurreSpace.s3),
                _AccessCard(
                  key: const Key('settings-quiet-notifications'),
                  title: context.l10n.keepHiddenQuiet,
                  status: _checkingNotificationAccess
                      ? context.l10n.checking
                      : !controller.hasNotificationAccess
                      ? context.l10n.needsAndroidOk
                      : settings.quietNotificationsFromHiddenApps &&
                            controller.pausedAwayFromHome
                      ? context.l10n.pausedOtherHome
                      : settings.quietNotificationsFromHiddenApps &&
                            controller.isRestDay
                      ? context.l10n.restingToday
                      : settings.quietNotificationsFromHiddenApps &&
                            controller.focusIsOver
                      ? context.l10n.focusEndedNothingHeld
                      : settings.quietNotificationsFromHiddenApps
                      ? context.l10n.heldUntilBack
                      : context.l10n.off,
                  needsAccess:
                      !_checkingNotificationAccess &&
                      !controller.hasNotificationAccess,
                  value: settings.quietNotificationsFromHiddenApps,
                  onChanged: _setQuietNotificationsEnabled,
                  explanation: notificationAccessExplanation,
                  allowLabel: context.l10n.turnOnNotificationAccess,
                  allowGlyph: CurreGlyphKind.notify,
                  onAllow: _requestNotificationAccess,
                  help: RestrictedSettingsHelp(
                    controller: controller,
                    stillOff: _notificationAccessTried,
                  ),
                ),
                const SizedBox(height: CurreSpace.s6),
                _SectionTitle(context.l10n.sectionQuietNudges),
                const SizedBox(height: CurreSpace.s2),
                _ReminderSettingsCard(
                  settings: settings,
                  onCheckInChanged: (value) =>
                      _saveNudges(settings.copyWith(checkInNudges: value)),
                  onEverySessionChanged: (value) =>
                      _saveNudges(settings.copyWith(everySessionNudges: value)),
                  onFocusChanged: (value) =>
                      _saveNudges(settings.copyWith(focusNudges: value)),
                  onPlanEndingChanged: (value) =>
                      _saveNudges(settings.copyWith(planEndingNudges: value)),
                  onUnlockTimeUpChanged: (value) =>
                      _saveNudges(settings.copyWith(unlockTimeUpNudges: value)),
                  onProofChanged: (value) =>
                      _saveNudges(settings.copyWith(proofNudges: value)),
                  onAllChanged: (value) => _saveNudges(
                    settings.copyWith(
                      checkInNudges: value,
                      planEndingNudges: value,
                      unlockTimeUpNudges: value,
                      proofNudges: value,
                      focusNudges: value,
                    ),
                  ),
                ),
                const SizedBox(height: CurreSpace.s2),
                _SettingsTile(
                  glyph: CurreGlyphKind.notify,
                  title: context.l10n.allowNotifications,
                  subtitle: _checkingNotifications
                      ? context.l10n.checking
                      : switch (_notificationsAllowed) {
                          true => context.l10n.notificationsAllowed,
                          false => context.l10n.notificationsNotAllowed,
                          null => context.l10n.notificationsAndroidControls,
                        },
                  onTap: _askForNotificationPermission,
                ),
                const SizedBox(height: CurreSpace.s6),
                _SectionTitle(context.l10n.sectionVoiceTyping),
                const SizedBox(height: CurreSpace.s2),
                VoiceSettingsCard(speech: controller.speech),
                const SizedBox(height: CurreSpace.s6),
                _SectionTitle(context.l10n.sectionYourName),
                const SizedBox(height: CurreSpace.s2),
                TextField(
                  controller: _name,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: context.l10n.nameInGreeting,
                    filled: true,
                    fillColor: colors.raised,
                  ),
                ),
                CurrePrimaryButton(
                  label: context.l10n.saveName,
                  onPressed: _saveName,
                ),
                const SizedBox(height: CurreSpace.s6),
                _SectionTitle(context.l10n.sectionHomeScreen),
                const SizedBox(height: CurreSpace.s2),
                _HomeScreenCard(
                  isHome: _isHome,
                  onSwitch: _switchHomeScreen,
                  onMakeHome: _makeCurreHome,
                ),
                const SizedBox(height: CurreSpace.s6),
                _SectionTitle(context.l10n.sectionHistoryPrivacy),
                const SizedBox(height: CurreSpace.s2),
                _SettingsTile(
                  glyph: CurreGlyphKind.history,
                  title: context.l10n.history,
                  subtitle: context.l10n.historySettingsBody,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => HistoryScreen(controller: controller),
                    ),
                  ),
                ),
                _SettingsTile(
                  glyph: CurreGlyphKind.privacy,
                  title: context.l10n.privacyDetails,
                  subtitle: context.l10n.privacySettingsBody,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyDetailsScreen(),
                    ),
                  ),
                ),
                _SettingsTile(
                  glyph: CurreGlyphKind.close,
                  title: context.l10n.clearHistory,
                  subtitle: context.l10n.clearHistorySettingsBody,
                  onTap: _confirmClearHistory,
                  destructive: true,
                ),
                const SizedBox(height: CurreSpace.s6),
                _SectionTitle(context.l10n.sectionAbout),
                const SizedBox(height: CurreSpace.s2),
                _SettingsTile(
                  glyph: CurreGlyphKind.info,
                  title: context.l10n.licences,
                  subtitle: context.l10n.licencesBody,
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Curre',
                    applicationVersion: '1.0.0',
                    applicationLegalese: context.l10n.appLegalese,
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
      helpText: context.l10n.sessionStartsAt(
        session.localizedLabel(context.l10n),
      ),
    );
    if (selected == null || !mounted) return;
    final starts = Map<SessionName, LocalTime>.of(
      controller.settings.sessionStarts,
    )..[session] = LocalTime(selected.hour, selected.minute);
    final Settings next;
    try {
      next = controller.settings.copyWith(sessionStarts: starts);
    } on ArgumentError {
      showCurreSnack(context, context.l10n.sessionOrderError);
      return;
    }
    await _save(
      next,
      saved: context.l10n.sessionStartSaved(
        session.localizedLabel(context.l10n),
        starts[session].toString(),
      ),
    );
  }

  Future<void> _pickLanguage() async {
    const system = 'system';
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        final current = controller.settings.languageCode ?? system;
        return SimpleDialog(
          title: Text(l10n.language),
          children: [
            for (final code in const [system, 'en', 'es', 'fr', 'pt', 'de'])
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(code),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _languageName(l10n, code == system ? null : code),
                      ),
                    ),
                    if (current == code)
                      const CurreGlyph(CurreGlyphKind.check, size: 20),
                  ],
                ),
              ),
          ],
        );
      },
    );
    if (selected == null || !mounted) return;
    await _save(
      selected == system
          ? controller.settings.copyWith(clearLanguageCode: true)
          : controller.settings.copyWith(languageCode: selected),
    );
  }

  static String _languageName(AppLocalizations l10n, String? code) =>
      switch (code) {
        null => l10n.systemLanguage,
        'en' => l10n.languageEnglish,
        'es' => l10n.languageSpanish,
        'fr' => l10n.languageFrench,
        'pt' => l10n.languagePortuguese,
        'de' => l10n.languageGerman,
        _ => code,
      };

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
      saved: context.l10n.nameSaved,
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
        showCurreSnack(context, context.l10n.couldNotSave);
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

  Future<void> _refreshNotificationPermission() async {
    final allowed = await controller.notificationsAllowed();
    if (!mounted) return;
    setState(() {
      _notificationsAllowed = allowed;
      _checkingNotifications = false;
    });
  }

  Future<void> _setGentleInterceptEnabled(bool enabled) =>
      _save(controller.settings.copyWith(askWhyOnHiddenAppOpen: enabled));

  Future<void> _setQuietNotificationsEnabled(bool enabled) => _save(
    controller.settings.copyWith(quietNotificationsFromHiddenApps: enabled),
  );

  void _saveNudges(Settings next) => unawaited(_save(next));

  Future<void> _requestUsageAccess() async {
    final granted = await controller.requestUsageAccess();
    if (!mounted) return;
    setState(() {
      _checkingUsageAccess = false;
      _usageTried = !granted;
    });
    showCurreSnack(
      context,
      granted ? context.l10n.usageAccessDone : context.l10n.accessStillOff,
    );
  }

  Future<void> _requestNotificationAccess() async {
    final granted = await controller.requestNotificationAccess();
    if (!mounted) return;
    setState(() {
      _checkingNotificationAccess = false;
      _notificationAccessTried = !granted;
    });
    showCurreSnack(
      context,
      granted
          ? context.l10n.notificationAccessDone
          : context.l10n.accessStillOff,
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

  Future<void> _askForNotificationPermission() async {
    final allowed = await controller.requestNotifications();
    if (!mounted) return;
    setState(() {
      _notificationsAllowed = allowed;
      _checkingNotifications = false;
    });
    showCurreSnack(
      context,
      allowed
          ? context.l10n.notificationsPermissionDone
          : context.l10n.notificationsPermissionOff,
    );
  }

  Future<void> _switchHomeScreen() async {
    final opened = await controller.openHomeSettings();
    if (!mounted) return;
    final help = switch (opened) {
      HomeSettingsOpened.homeApps => null,
      HomeSettingsOpened.defaultApps => context.l10n.chooseHomeApp,
      HomeSettingsOpened.settings => context.l10n.searchHomeApp,
      HomeSettingsOpened.none => context.l10n.openSettingsHomeApp,
    };
    if (help != null) showCurreSnack(context, help);
  }

  Future<void> _makeCurreHome() async {
    final isHome = await controller.requestHomeRole();
    if (!mounted) return;
    setState(() => _isHome = isHome);
    if (!isHome) {
      showCurreSnack(context, context.l10n.curreNotHomeSettings);
    }
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.clearHistoryQuestion),
        content: Text(context.l10n.clearHistoryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.keepIt),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.clearHistory),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await controller.clearHistory();
      if (mounted) showCurreSnack(context, context.l10n.historyCleared);
    } on Object {
      if (mounted) {
        showCurreSnack(context, context.l10n.historyClearFailed);
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
                      context.l10n.switchHome,
                      style: type.label.weight(700).copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: CurreSpace.s1),
                    Text(
                      notHome
                          ? context.l10n.curreNotHomeBody
                          : context.l10n.switchHomeBody,
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
              label: context.l10n.makeCurreMyHome,
              glyph: CurreGlyphKind.homeRole,
              onPressed: onMakeHome,
            ),
            const SizedBox(height: CurreSpace.s2),
            CurreSecondaryButton(
              label: context.l10n.openHomeScreenSettings,
              onPressed: onSwitch,
            ),
          ] else
            CurreSecondaryButton(
              label: context.l10n.chooseHomeScreenApp,
              glyph: CurreGlyphKind.go,
              onPressed: onSwitch,
            ),
          const SizedBox(height: CurreSpace.s3),
          Text(
            context.l10n.homeSettingsPath,
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
    required this.help,
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

  /// Shown while Android still says no: how to allow a restricted setting.
  final Widget help;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    // A Material, not a decorated box: the switch row paints its ink here.
    return Material(
      color: colors.raised,
      shape: RoundedRectangleBorder(
        borderRadius: CurreShape.md,
        side: BorderSide(color: colors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
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
              const SizedBox(height: CurreSpace.s3),
              help,
            ],
          ],
        ),
      ),
    );
  }
}

class _ReminderSettingsCard extends StatelessWidget {
  const _ReminderSettingsCard({
    required this.settings,
    required this.onCheckInChanged,
    required this.onEverySessionChanged,
    required this.onFocusChanged,
    required this.onPlanEndingChanged,
    required this.onUnlockTimeUpChanged,
    required this.onProofChanged,
    required this.onAllChanged,
  });

  final Settings settings;
  final ValueChanged<bool> onCheckInChanged;
  final ValueChanged<bool> onEverySessionChanged;
  final ValueChanged<bool> onFocusChanged;
  final ValueChanged<bool> onPlanEndingChanged;
  final ValueChanged<bool> onUnlockTimeUpChanged;
  final ValueChanged<bool> onProofChanged;
  final ValueChanged<bool> onAllChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Material(
      color: colors.raised,
      shape: RoundedRectangleBorder(
        borderRadius: CurreShape.md,
        side: BorderSide(color: colors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CurreSpace.s4,
          CurreSpace.s3,
          CurreSpace.s4,
          CurreSpace.s4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.nudgesHelp,
              style: type.caption.copyWith(color: colors.ink2),
            ),
            const SizedBox(height: CurreSpace.s2),
            _ReminderSwitch(
              key: const Key('nudge-check-in'),
              title: context.l10n.planYourDay,
              subtitle: settings.everySessionNudges
                  ? context.l10n.eachSessionBegins
                  : context.l10n.morningBegins,
              value: settings.checkInNudges,
              onChanged: onCheckInChanged,
            ),
            if (settings.checkInNudges)
              _ReminderSwitch(
                key: const Key('nudge-every-session'),
                title: context.l10n.afternoonEveningToo,
                subtitle: context.l10n.afternoonEveningBegins,
                value: settings.everySessionNudges,
                onChanged: onEverySessionChanged,
              ),
            _ReminderSwitch(
              key: const Key('nudge-plan-ending'),
              title: context.l10n.planEnding,
              subtitle: context.l10n.tenMinutesBeforePlan,
              value: settings.planEndingNudges,
              onChanged: onPlanEndingChanged,
            ),
            _ReminderSwitch(
              key: const Key('nudge-unlock-time-up'),
              title: context.l10n.appTimeUp,
              subtitle: context.l10n.hiddenAppTimeEnds,
              value: settings.unlockTimeUpNudges,
              onChanged: onUnlockTimeUpChanged,
            ),
            _ReminderSwitch(
              key: const Key('nudge-proof'),
              title: context.l10n.addProof,
              subtitle: context.l10n.addProofLater,
              value: settings.proofNudges,
              onChanged: onProofChanged,
            ),
            _ReminderSwitch(
              key: const Key('nudge-focus'),
              title: context.l10n.focusEnds,
              subtitle: context.l10n.focusEndsMorning,
              value: settings.focusNudges,
              onChanged: onFocusChanged,
            ),
            const SizedBox(height: CurreSpace.s2),
            CurreSecondaryButton(
              label: settings.hasAnyNudges
                  ? context.l10n.turnAllNudgesOff
                  : context.l10n.turnAllNudgesOn,
              onPressed: () => onAllChanged(!settings.hasAnyNudges),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderSwitch extends StatelessWidget {
  const _ReminderSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<CurreType>()!;
    final colors = Theme.of(context).extension<CurreColors>()!;
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: type.label),
      subtitle: Text(
        subtitle,
        style: type.caption.copyWith(color: colors.ink3),
      ),
      value: value,
      onChanged: onChanged,
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

  static String wordFor(AppLocalizations l10n, double value) => value < .65
      ? l10n.gentle
      : value < .8
      ? l10n.balanced
      : l10n.strict;

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
            Text(wordFor(context.l10n, value), style: type.title),
            Slider(
              value: value,
              min: .5,
              max: .9,
              divisions: 8,
              label: wordFor(context.l10n, value),
              semanticFormatterCallback: (value) =>
                  wordFor(context.l10n, value),
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
            Row(
              children: [
                Text(
                  context.l10n.gentle,
                  style: type.caption.copyWith(color: colors.ink3),
                ),
                const Spacer(),
                Text(
                  context.l10n.strict,
                  style: type.caption.copyWith(color: colors.ink3),
                ),
              ],
            ),
            const SizedBox(height: CurreSpace.s2),
            Text(
              context.l10n.strictnessBody,
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

/// What Curre settings says under "Hidden apps".
String hiddenChoiceSummary(int count, [AppLocalizations? l10n]) =>
    switch (count) {
      0 => l10n?.hiddenChoiceNone ?? 'None. Every app opens as usual.',
      1 => l10n?.hiddenChoiceOne ?? '1 app. Only it asks “Why now?”.',
      _ =>
        l10n?.hiddenChoiceMany(count) ??
            '$count apps. Only these ask “Why now?”.',
    };

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    super.key,
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
