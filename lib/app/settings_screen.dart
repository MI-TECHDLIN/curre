import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';
import 'demo_screen.dart';
import 'history_screen.dart';
import 'under_hood.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});

  final CurreController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.controller.settings.displayName,
  );
  late double _threshold = widget.controller.settings.threshold;

  CurreController get controller => widget.controller;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
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
              subtitle: 'Not Android Settings',
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(CurreSpace.gutter),
              children: [
                _SectionTitle('Session times'),
                const SizedBox(height: CurreSpace.s2),
                for (final session in SessionName.values)
                  _SettingsTile(
                    glyph: session.glyph,
                    title: _capitalise(session.label),
                    subtitle: controller.settings.sessionStarts[session]
                        .toString(),
                    onTap: () => _pickTime(session),
                  ),
                const SizedBox(height: CurreSpace.s6),
                _SectionTitle('Decision threshold'),
                const SizedBox(height: CurreSpace.s2),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.raised,
                    borderRadius: CurreShape.md,
                    border: Border.all(color: colors.hairline),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(CurreSpace.s4),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Strictness', style: type.label),
                            ),
                            Text(
                              _threshold.toStringAsFixed(2),
                              style: type.figure,
                            ),
                          ],
                        ),
                        Slider(
                          value: _threshold,
                          min: .5,
                          max: .95,
                          divisions: 9,
                          label: _threshold.toStringAsFixed(2),
                          onChanged: (value) =>
                              setState(() => _threshold = value),
                          onChangeEnd: (value) => controller.updateSettings(
                            controller.settings.copyWith(threshold: value),
                          ),
                        ),
                        Text(
                          'A concrete reason must meet this confidence to open immediately.',
                          style: type.caption.copyWith(color: colors.ink3),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: CurreSpace.s6),
                _SectionTitle('Your name'),
                const SizedBox(height: CurreSpace.s2),
                TextField(
                  controller: _name,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Display name'),
                ),
                CurrePrimaryButton(
                  label: 'Save name',
                  onPressed: () async {
                    await controller.updateDisplayName(_name.text);
                    if (context.mounted) {
                      showCurreSnack(context, 'Name saved on this phone.');
                    }
                  },
                ),
                const SizedBox(height: CurreSpace.s6),
                _SectionTitle('See how it works'),
                const SizedBox(height: CurreSpace.s2),
                _SettingsTile(
                  glyph: CurreGlyphKind.history,
                  title: 'History',
                  subtitle: 'Check-ins and deliberate unlocks · on this phone',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => HistoryScreen(controller: controller),
                    ),
                  ),
                ),
                _SettingsTile(
                  glyph: CurreGlyphKind.door,
                  title: 'Judge demo mode',
                  subtitle: 'Real gate calls without changing your Home',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DemoScreen(controller: controller),
                    ),
                  ),
                ),
                _SettingsTile(
                  glyph: CurreGlyphKind.underTheHood,
                  title: 'Under the hood',
                  subtitle: 'Endpoint map, last latency and credits',
                  onTap: () => showUnderTheHood(context, controller),
                ),
                _SettingsTile(
                  glyph: CurreGlyphKind.info,
                  title: 'Licences',
                  subtitle: 'Fonts and the Solar icon set',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Curre',
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'Curre opens the task, not the app.',
                  ),
                ),
                const SizedBox(height: CurreSpace.s6),
                _SectionTitle('Privacy'),
                const SizedBox(height: CurreSpace.s2),
                _SettingsTile(
                  glyph: CurreGlyphKind.history,
                  title: 'Clear history',
                  subtitle: 'Remove 30 days of check-ins and unlock choices',
                  onTap: _confirmClearHistory,
                  destructive: true,
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
      helpText: '${_capitalise(session.label)} starts',
    );
    if (selected == null || !mounted) return;
    final starts = Map<SessionName, LocalTime>.of(
      controller.settings.sessionStarts,
    )..[session] = LocalTime(selected.hour, selected.minute);
    try {
      await controller.updateSettings(
        controller.settings.copyWith(sessionStarts: starts),
      );
      if (mounted) setState(() {});
    } on ArgumentError {
      if (mounted) {
        showCurreSnack(
          context,
          'Session starts must stay ordered: morning, afternoon, evening.',
        );
      }
    }
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear local history?'),
        content: const Text(
          'This removes saved check-ins, grants and unlock attempts. Today’s live plan and active app timers stay in place.',
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
    if (confirmed != true) return;
    await controller.clearHistory();
    if (mounted) showCurreSnack(context, 'History cleared.');
  }

  static String _capitalise(String value) =>
      '${value[0].toUpperCase()}${value.substring(1)}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<CurreType>()!;
    return Text(label, style: type.title.copyWith(fontSize: 18));
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Row(
            children: [
              CurreGlyph(glyph, color: foreground),
              const SizedBox(width: CurreSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: type.label.copyWith(color: foreground)),
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
    );
  }
}
