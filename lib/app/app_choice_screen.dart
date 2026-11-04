import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../doors/door_models.dart';
import '../l10n/l10n.dart';
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

  /// The apps the user hides: only these leave Home, ask "Why now?" and
  /// have their notifications held.
  hidden,
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
  bool get _hidden => widget.kind == AppChoiceKind.hidden;

  Set<String> get _fixed => controller.suggestedEssentials;

  Set<String> get _chosen => switch (widget.kind) {
    AppChoiceKind.planApps => controller.settings.candidates,
    AppChoiceKind.hidden => controller.chosenHiddenPackages,
    AppChoiceKind.alwaysOnHome => {
      ...controller.settings.essentials,
      ..._fixed,
    },
  };

  List<LaunchableApp> get _choices {
    final essentials = {...controller.settings.essentials, ..._fixed};
    final hidden = controller.settings.hiddenApps;
    final apps =
        controller.apps
            .where(
              (app) =>
                  app.packageName != 'com.mitech.curre' &&
                  switch (widget.kind) {
                    // Plans never use an app the user hid.
                    AppChoiceKind.planApps =>
                      !essentials.contains(app.packageName) &&
                          !hidden.contains(app.packageName),
                    AppChoiceKind.hidden => !essentials.contains(
                      app.packageName,
                    ),
                    AppChoiceKind.alwaysOnHome => true,
                  },
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
    if (_hidden) {
      try {
        if (controller.isHiddenApp(package)) {
          await controller.stopHidingApp(package);
        } else {
          await controller.hideApp(package);
        }
        if (mounted) setState(() {});
      } on Object {
        if (mounted) {
          showCurreSnack(context, context.l10n.couldNotSave);
        }
      }
      return;
    }
    final Settings next;
    if (_planApps) {
      final candidates = settings.candidates.toSet();
      if (candidates.contains(package)) {
        if (candidates.length <= AppChoiceScreen.minPlanApps) {
          showCurreSnack(
            context,
            context.l10n.planAppsMinimum(AppChoiceScreen.minPlanApps),
          );
          return;
        }
        candidates.remove(package);
      } else {
        if (candidates.length >= AppChoiceScreen.maxPlanApps) {
          showCurreSnack(
            context,
            context.l10n.planAppsMaximum(AppChoiceScreen.maxPlanApps),
          );
          return;
        }
        candidates.add(package);
      }
      next = settings.copyWith(candidates: candidates);
    } else {
      if (_fixed.contains(package)) {
        showCurreSnack(context, context.l10n.appAlwaysOnHome(app.label));
        return;
      }
      final essentials = {...settings.essentials, ..._fixed};
      final candidates = settings.candidates.toSet();
      final hidden = settings.hiddenApps.toSet();
      if (!essentials.remove(package)) {
        essentials.add(package);
        // An app that is always on Home doesn't need a plan to bring it,
        // and is never hidden.
        candidates.remove(package);
        hidden.remove(package);
      }
      next = settings.copyWith(
        essentials: essentials,
        candidates: candidates,
        hiddenApps: hidden,
      );
    }
    try {
      await controller.updateSettings(next);
      if (mounted) setState(() {});
    } on Object {
      if (mounted) {
        showCurreSnack(context, context.l10n.couldNotSave);
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
              title: switch (widget.kind) {
                AppChoiceKind.planApps => context.l10n.planApps,
                AppChoiceKind.hidden => context.l10n.hiddenApps,
                AppChoiceKind.alwaysOnHome => context.l10n.alwaysOnHome,
              },
              subtitle: switch (widget.kind) {
                AppChoiceKind.planApps => context.l10n.planAppsHelp,
                AppChoiceKind.hidden => context.l10n.hiddenAppsHelp,
                AppChoiceKind.alwaysOnHome => context.l10n.alwaysOnHomeHelp,
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(CurreSpace.gutter),
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(switch (widget.kind) {
                    AppChoiceKind.planApps => context.l10n.pickedCount(
                      chosen.length,
                    ),
                    AppChoiceKind.hidden => context.l10n.hiddenCount(
                      chosen.length,
                    ),
                    AppChoiceKind.alwaysOnHome => context.l10n.onHomeCount(
                      chosen.length,
                    ),
                  }, style: type.meta),
                ),
                const SizedBox(height: CurreSpace.s3),
                TextField(
                  decoration: InputDecoration(
                    labelText: context.l10n.findApp,
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
                      context.l10n.noAppMatches(_query),
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
                        ? context.l10n.alwaysOnHome
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
