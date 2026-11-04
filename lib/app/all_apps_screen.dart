import 'package:flutter/material.dart';

import '../doors/door_models.dart';
import '../design/design.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';

/// All apps: every app the user didn't hide, by name, opening as usual with
/// no question. "Hide this app" (the eye button, or a long press) sends one
/// to Hidden apps, with an Undo.
class AllAppsScreen extends StatefulWidget {
  const AllAppsScreen({super.key, required this.controller});

  final CurreController controller;

  @override
  State<AllAppsScreen> createState() => _AllAppsScreenState();
}

class _AllAppsScreenState extends State<AllAppsScreen> {
  String _query = '';

  CurreController get controller => widget.controller;

  List<LaunchableApp> get _apps {
    final apps = controller.openApps;
    if (_query.isEmpty) return apps;
    final query = _query.toLowerCase();
    return apps
        .where((app) => app.label.toLowerCase().contains(query))
        .toList(growable: false);
  }

  Future<void> _hide(LaunchableApp app) async {
    try {
      await controller.hideApp(app.packageName);
    } on Object {
      if (mounted) {
        showCurreSnack(
          context,
          'Curre couldn’t save that on this phone. Please try again.',
        );
      }
      return;
    }
    if (!mounted) return;
    showCurreSnack(
      context,
      '${app.label} is hidden. Opening it asks “Why now?” first.',
      actionLabel: 'Undo',
      onAction: () async {
        try {
          await controller.stopHidingApp(app.packageName);
        } on Object {
          // Hidden apps still has "Stop hiding".
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final colors = Theme.of(context).extension<CurreColors>()!;
      final type = Theme.of(context).extension<CurreType>()!;
      final apps = _apps;
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
                title: 'All apps',
                subtitle: 'Every app you didn’t hide. They open as usual.',
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(CurreSpace.gutter),
                children: [
                  TextField(
                    key: const Key('all-apps-find'),
                    decoration: InputDecoration(
                      labelText: 'Find an app',
                      filled: true,
                      fillColor: colors.raised,
                    ),
                    onChanged: (value) => setState(() => _query = value.trim()),
                  ),
                  const SizedBox(height: CurreSpace.s2),
                  if (apps.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(CurreSpace.s6),
                      child: Text(
                        _query.isEmpty
                            ? 'Every app on this phone is hidden.'
                            : 'No app matches “$_query”.',
                        style: type.body.copyWith(color: colors.ink2),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final app in apps)
                    _AllAppsRow(
                      app: app,
                      canHide: controller.canHide(app.packageName),
                      onOpen: () => controller.plainLaunch(app.packageName),
                      onHide: () => _hide(app),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _AllAppsRow extends StatelessWidget {
  const _AllAppsRow({
    required this.app,
    required this.canHide,
    required this.onOpen,
    required this.onHide,
  });

  final LaunchableApp app;
  final bool canHide;
  final VoidCallback onOpen;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Open ${app.label}',
              onLongPressHint: canHide ? 'Hide this app' : null,
              excludeSemantics: true,
              child: InkWell(
                onTap: onOpen,
                onLongPress: canHide ? onHide : null,
                splashFactory: NoSplash.splashFactory,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(app.label, style: type.listItem),
                  ),
                ),
              ),
            ),
          ),
          if (canHide)
            IconButton(
              key: ValueKey<String>('hide-${app.packageName}'),
              tooltip: 'Hide ${app.label}',
              onPressed: onHide,
              icon: CurreGlyph(
                CurreGlyphKind.outOfSight,
                size: 20,
                color: colors.ink3,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(CurreSpace.s3),
              child: CurreGlyph(
                CurreGlyphKind.essential,
                size: 18,
                color: colors.ink3,
                semanticLabel: 'Always on Home',
              ),
            ),
        ],
      ),
    );
  }
}
