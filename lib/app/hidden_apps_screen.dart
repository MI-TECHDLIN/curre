import 'dart:async';

import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../platform/platform.dart';
import 'access_help.dart';
import 'app_choice_screen.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';
import 'unlock_gate_screen.dart';

/// Hidden apps: only the apps the user chose to hide, by name only (no
/// icons, so nothing calls out to be opened). Tapping one asks "Why now?"
/// before bringing it back; "Hide another app" edits the list.
class HiddenAppsScreen extends StatefulWidget {
  const HiddenAppsScreen({super.key, required this.controller});

  final CurreController controller;

  @override
  State<HiddenAppsScreen> createState() => _HiddenAppsScreenState();
}

class _HiddenAppsScreenState extends State<HiddenAppsScreen> {
  CurreController get controller => widget.controller;

  /// The one Android access offered on this visit, if any: asking "Why
  /// now?" first, keeping hidden apps quiet on a later visit.
  late final ContextPrompt? _offer = controller.offers(ContextPrompt.askWhy)
      ? ContextPrompt.askWhy
      : !controller.pendingPrompts.contains(ContextPrompt.askWhy) &&
            controller.offers(ContextPrompt.quietHidden)
      ? ContextPrompt.quietHidden
      : null;

  @override
  void initState() {
    super.initState();
    unawaited(controller.refreshMissedNotifications());
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) =>
        _HiddenAppsBody(controller: controller, offer: _offer),
  );
}

class _HiddenAppsBody extends StatelessWidget {
  const _HiddenAppsBody({required this.controller, required this.offer});

  final CurreController controller;
  final ContextPrompt? offer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final apps = controller.hiddenApps;
    final missed = controller.missedWhileHidden;
    String? lastLetter;
    final rows = <Widget>[];
    if (missed.isNotEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: CurreSpace.s2),
          child: Semantics(
            button: true,
            label:
                '${missedNotificationsLabel(missed.length)} from hidden apps. Open the list.',
            excludeSemantics: true,
            child: Material(
              color: colors.raised,
              shape: RoundedRectangleBorder(
                borderRadius: CurreShape.md,
                side: BorderSide(color: colors.hairline),
              ),
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        MissedWhileHiddenScreen(controller: controller),
                  ),
                ),
                splashFactory: NoSplash.splashFactory,
                borderRadius: CurreShape.md,
                child: Padding(
                  padding: const EdgeInsets.all(CurreSpace.s4),
                  child: Row(
                    children: [
                      CurreGlyph(CurreGlyphKind.notify, color: colors.ink),
                      const SizedBox(width: CurreSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Missed notifications', style: type.label),
                            Text(
                              '${missedNotificationsLabel(missed.length)} from hidden apps',
                              style: type.caption.copyWith(color: colors.ink3),
                            ),
                            if (missed.where((item) => item.held).length
                                case final held when held > 0)
                              Text(
                                '$held held until their app comes back',
                                style: type.caption.copyWith(
                                  color: colors.ink3,
                                ),
                              ),
                          ],
                        ),
                      ),
                      CurreGlyph(
                        CurreGlyphKind.go,
                        size: 18,
                        color: colors.ink3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (offer case final prompt? when apps.isNotEmpty) {
      rows.add(
        Padding(
          key: ValueKey(prompt),
          padding: const EdgeInsets.only(top: CurreSpace.s2),
          child: AccessOffer(controller: controller, prompt: prompt),
        ),
      );
    }
    for (final app in apps) {
      final letter = app.label.isEmpty ? '#' : app.label[0].toUpperCase();
      if (letter != lastLetter) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(
              top: CurreSpace.s4,
              bottom: CurreSpace.s1,
            ),
            child: ExcludeSemantics(
              child: Text(
                letter,
                style: type.meta.copyWith(color: colors.emberText),
              ),
            ),
          ),
        );
        lastLetter = letter;
      }
      rows.add(
        Semantics(
          button: true,
          label: 'Bring back ${app.label}',
          excludeSemantics: true,
          child: InkWell(
            // A rest day opens hidden apps without asking why.
            onTap: controller.isRestDay
                ? () => controller.plainLaunch(app.packageName)
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          UnlockGateScreen(controller: controller, app: app),
                    ),
                  ),
            splashFactory: NoSplash.splashFactory,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.hairline)),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(app.label, style: type.listItem)),
                  CurreGlyph(CurreGlyphKind.rise, size: 18, color: colors.ink3),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return CurrePage(
      background: colors.sunk,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CurreSpace.gutter,
              CurreSpace.s3,
              CurreSpace.gutter,
              CurreSpace.s3,
            ),
            child: CurreTopBar(
              title: 'Hidden apps',
              subtitle: controller.isRestDay
                  ? 'Rest day: they open without asking'
                  : apps.length == 1
                  ? '1 app'
                  : '${apps.length} apps',
            ),
          ),
          Expanded(
            child: apps.isEmpty && missed.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(CurreSpace.gutter),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.chosenHiddenPackages.isEmpty
                                ? 'Nothing is hidden. Every app opens as usual from All apps.'
                                : 'Your hidden apps are out for your plan or for a while right now.',
                            style: type.body.copyWith(color: colors.ink2),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: CurreSpace.s4),
                          _HideAnotherApp(controller: controller),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(
                          CurreSpace.gutter,
                          0,
                          CurreSpace.s10,
                          CurreSpace.s6,
                        ),
                        children: [
                          if (!controller.hiddenAppsTipDismissed &&
                              apps.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: CurreSpace.s2,
                              ),
                              child: _HiddenAppsTip(
                                onDismiss: controller.dismissHiddenAppsTip,
                              ),
                            ),
                          ...rows,
                          const SizedBox(height: CurreSpace.s4),
                          _HideAnotherApp(controller: controller),
                        ],
                      ),
                      if (apps.isNotEmpty)
                        Positioned(
                          right: CurreSpace.s2,
                          top: CurreSpace.s2,
                          bottom: CurreSpace.s2,
                          child: Center(
                            child: ExcludeSemantics(
                              child: Text(
                                'A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM\nN\nO\nP\nQ\nR\nS\nT\nU\nV\nW\nX\nY\nZ',
                                style: type.meta.copyWith(
                                  fontSize: 9,
                                  height: 1.15,
                                  color: colors.ink3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// "Hide another app": the full list of apps, where a tap hides one or
/// stops hiding it.
class _HideAnotherApp extends StatelessWidget {
  const _HideAnotherApp({required this.controller});

  final CurreController controller;

  @override
  Widget build(BuildContext context) => CurreSecondaryButton(
    key: const Key('hide-another-app'),
    label: 'Hide another app',
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AppChoiceScreen(controller: controller, kind: AppChoiceKind.hidden),
      ),
    ),
  );
}

String missedNotificationsLabel(int count) =>
    count == 1 ? '1 notification' : '$count notifications';

/// The first-time explainer, until the user puts it away.
class _HiddenAppsTip extends StatelessWidget {
  const _HiddenAppsTip({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        CurreSpace.s4,
        CurreSpace.s3,
        CurreSpace.s2,
        CurreSpace.s1,
      ),
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: CurreShape.dome,
        border: Border.all(color: colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CurrePropArt(CurreProp.door, size: 40),
              const SizedBox(width: CurreSpace.s3),
              Expanded(
                child: Text(
                  'Only the apps you chose to hide wait here. Tap one to bring it back for a while.',
                  style: type.body.copyWith(color: colors.ink),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDismiss,
              child: Text(
                'Got it',
                style: type.label.copyWith(color: colors.emberText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Notifications Curre held while their apps were hidden: the ones still
/// held (with their text, kept on this phone until they go back) and the
/// ones already given back. Tapping one opens its app, through "Why now?"
/// while the app is still hidden, straight once it's back.
class MissedWhileHiddenScreen extends StatelessWidget {
  const MissedWhileHiddenScreen({super.key, required this.controller});

  final CurreController controller;

  Future<void> _open(
    BuildContext context,
    MissedWhileHiddenNotification notification,
  ) async {
    final hidden = controller.hiddenApps
        .where((app) => app.packageName == notification.packageName)
        .firstOrNull;
    if (hidden != null && !controller.isRestDay) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => UnlockGateScreen(controller: controller, app: hidden),
        ),
      );
      return;
    }
    final opened = await controller.openMissedNotification(notification);
    if (!opened && context.mounted) {
      showCurreSnack(context, 'That app didn’t open. It may not be installed.');
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final colors = Theme.of(context).extension<CurreColors>()!;
      final type = Theme.of(context).extension<CurreType>()!;
      final notifications = controller.missedWhileHidden;
      return CurrePage(
        background: colors.sunk,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                CurreSpace.gutter,
                CurreSpace.s3,
                CurreSpace.gutter,
                CurreSpace.s3,
              ),
              child: CurreTopBar(
                title: 'Missed notifications',
                subtitle: 'Held quietly while their apps were hidden, and given back when the app comes back. Nothing leaves this phone.',
                maxTitleLines: 2,
              ),
            ),
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(CurreSpace.gutter),
                        child: Text(
                          'Nothing held right now.',
                          style: type.body.copyWith(color: colors.ink2),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        CurreSpace.gutter,
                        CurreSpace.s2,
                        CurreSpace.gutter,
                        CurreSpace.s6,
                      ),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) =>
                          Divider(color: colors.hairline),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final state = notification.held ? 'Held' : 'Given back';
                        final meta =
                            '${notification.appLabel} · ${_notificationTime(notification.at)} · $state';
                        return Semantics(
                          button: true,
                          label: [
                            notification.title,
                            ?notification.text,
                            meta,
                            'Open ${notification.appLabel}',
                          ].join(', '),
                          excludeSemantics: true,
                          child: InkWell(
                            key: ValueKey<int>(index),
                            onTap: () => _open(context, notification),
                            splashFactory: NoSplash.splashFactory,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: CurreSpace.s3,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notification.title,
                                          style: type.body,
                                        ),
                                        if (notification.text case final text?)
                                          Text(
                                            text,
                                            style: type.body.copyWith(
                                              color: colors.ink2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: CurreSpace.s1),
                                        Text(
                                          meta,
                                          style: type.caption.copyWith(
                                            color: colors.ink3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: CurreSpace.s2),
                                  CurreGlyph(
                                    CurreGlyphKind.go,
                                    size: 18,
                                    color: colors.ink3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    },
  );

  static String _notificationTime(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return time;
    }
    return '${local.day}/${local.month} · $time';
  }
}
