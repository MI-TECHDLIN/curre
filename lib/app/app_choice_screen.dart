import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../doors/door_models.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';
import 'onboarding/app_hints.dart';
import 'onboarding/onboarding_parts.dart';

/// Which list of apps [AppChoiceScreen] edits.
enum AppChoiceKind {
  /// Apps that stay on Home all the time (Phone, Messages and Settings
  /// always do).
  alwaysOnHome,

  /// Apps a plan may put on Home (2 to 30).
  planApps,
}

/// Edits one of Curre's app lists from Curre settings. Each tap saves at
/// once; apps are listed by name with a plain letter tile, never their
/// real icons.
class AppChoiceScreen extends StatefulWidget {
  const AppChoiceScreen({
    super.key,
    required this.controller,
    required this.kind,
  });

  final CurreController controller;
  final AppChoiceKind kind;

  static const maxPlanApps = 30;
  static const minPlanApps = 2;

  @override
  State<AppChoiceScreen> createState() => _AppChoiceScreenState();
}

class _AppChoiceScreenState extends State<AppChoiceScreen> {
  String _query = '';

  CurreController get controller => widget.controller;
  bool get _planApps => widget.kind == AppChoiceKind.planApps;

  Set<String> get _fixed => controller.suggestedEssentials;

  Set<String> get _chosen => _planApps
      ? controller.settings.candidates
      : {...controller.settings.essentials, ..._fixed};

  List<LaunchableApp> get _choices {
    final essentials = {...controller.settings.essentials, ..._fixed};
    final apps =
        controller.apps
            .where(
              (app) =>
                  app.packageName != 'com.mitech.curre' &&
                  (!_planApps || !essentials.contains(app.packageName)),
            )
            .toList()
          ..sort(
            (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
          );
    if (_query.isEmpty) return apps;
    final query = _query.toLowerCase();
    return apps
        .where((app) => app.label.toLowerCase().contains(query))
        .toList(growable: false);
  }

  Future<void> _toggle(LaunchableApp app) async {
    final settings = controller.settings;
    final package = app.packageName;
    final Settings next;
    if (_planApps) {
      final candidates = settings.candidates.toSet();
      if (candidates.contains(package)) {
        if (candidates.length <= AppChoiceScreen.minPlanApps) {
          showCurreSnack(
            context,
            'Plans need at least ${AppChoiceScreen.minPlanApps} apps to choose from.',
          );
          return;
        }
        candidates.remove(package);
      } else {
        if (candidates.length >= AppChoiceScreen.maxPlanApps) {
          showCurreSnack(
            context,
            'That’s ${AppChoiceScreen.maxPlanApps} already. Untick one to add another.',
          );
          return;
        }
        candidates.add(package);
      }
      next = settings.copyWith(candidates: candidates);
    } else {
      if (_fixed.contains(package)) {
        showCurreSnack(context, '${app.label} is always on Home.');
        return;
      }
      final essentials = {...settings.essentials, ..._fixed};
      final candidates = settings.candidates.toSet();
      if (!essentials.remove(package)) {
        essentials.add(package);
        // An app that is always on Home doesn't need a plan to bring it.
        candidates.remove(package);
      }
      next = settings.copyWith(essentials: essentials, candidates: candidates);
    }
    try {
      await controller.updateSettings(next);
      if (mounted) setState(() {});
    } on Object {
      if (mounted) {
        showCurreSnack(
          context,
          'Curre couldn’t save that on this phone. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final chosen = _chosen;
    final apps = _choices;
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
              title: _planApps ? 'Apps your plans can use' : 'Always on Home',
              subtitle: _planApps
                  ? 'When you plan, Curre picks from these. Choose 2 to 30.'
                  : 'These stay on Home all day, no plan needed.',
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(CurreSpace.gutter),
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _planApps
                        ? '${chosen.length} picked'
                        : '${chosen.length} on Home',
                    style: type.meta,
                  ),
                ),
                const SizedBox(height: CurreSpace.s3),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Find an app',
                    filled: true,
                    fillColor: colors.raised,
                  ),
                  onChanged: (value) => setState(() => _query = value.trim()),
                ),
                const SizedBox(height: CurreSpace.s3),
                if (apps.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(CurreSpace.s6),
                    child: Text(
                      'No app matches “$_query”.',
                      style: type.body.copyWith(color: colors.ink2),
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final app in apps) ...[
                  ChoiceCard(
                    dense: true,
                    leading: AppMonogram(
                      label: app.label,
                      packageName: app.packageName,
                    ),
                    title: app.label,
                    subtitle: !_planApps && _fixed.contains(app.packageName)
                        ? 'Always on Home'
                        : _planApps
                        ? appTaskExamples[app.packageName]
                        : null,
                    selected: chosen.contains(app.packageName),
                    onTap: () => _toggle(app),
                  ),
                  const SizedBox(height: CurreSpace.s2),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
