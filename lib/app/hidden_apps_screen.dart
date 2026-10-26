import 'dart:async';

import 'package:flutter/material.dart';

import '../design/design.dart';
import '../platform/platform.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';
import 'unlock_gate_screen.dart';

/// Hidden apps: every app that isn't part of the current plan, by name
/// only (no icons, so nothing calls out to be opened). Tapping one asks
/// "Why now?" before bringing it back.
class HiddenAppsScreen extends StatefulWidget {
  const HiddenAppsScreen({super.key, required this.controller});

  final CurreController controller;

  @override
  State<HiddenAppsScreen> createState() => _HiddenAppsScreenState();
}

class _HiddenAppsScreenState extends State<HiddenAppsScreen> {
  CurreController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    unawaited(controller.refreshMissedNotifications());
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => _HiddenAppsBody(controller: controller),
  );
}

class _HiddenAppsBody extends StatelessWidget {
  const _HiddenAppsBody({required this.controller});

  final CurreController controller;

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
                        MissedWhileHiddenScreen(notifications: missed),
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
            onTap: () => Navigator.of(context).push(
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
              subtitle: apps.length == 1 ? '1 app' : '${apps.length} apps',
            ),
          ),
          Expanded(
            child: apps.isEmpty && missed.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(CurreSpace.gutter),
                      child: Text(
                        'No hidden apps right now. Everything you planned is on Home.',
                        style: type.body.copyWith(color: colors.ink2),
                        textAlign: TextAlign.center,
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
                  'Apps you didn’t plan for wait here. Tap one to bring it back.',
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

/// Notifications Curre kept quiet while their apps were hidden: app, title
/// and time only.
class MissedWhileHiddenScreen extends StatelessWidget {
  const MissedWhileHiddenScreen({super.key, required this.notifications});

  final List<MissedWhileHiddenNotification> notifications;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
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
              subtitle: 'Kept quiet while their apps were hidden. Only the app, title and time are saved, on this phone.',
              maxTitleLines: 2,
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                CurreSpace.gutter,
                CurreSpace.s2,
                CurreSpace.gutter,
                CurreSpace.s6,
              ),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => Divider(color: colors.hairline),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Semantics(
                  label:
                      '${notification.appLabel}, ${notification.title}, ${_notificationTime(notification.at)}',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: CurreSpace.s3,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.title, style: type.body),
                        const SizedBox(height: CurreSpace.s1),
                        Text(
                          '${notification.appLabel} · ${_notificationTime(notification.at)}',
                          style: type.caption.copyWith(color: colors.ink3),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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
