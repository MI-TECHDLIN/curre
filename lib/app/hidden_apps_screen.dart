import 'dart:async';

import 'package:flutter/material.dart';

import '../design/design.dart';
import '../platform/platform.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';
import 'unlock_gate_screen.dart';

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
    unawaited(_loadMissed());
  }

  Future<void> _loadMissed() async {
    await controller.refreshMissedNotifications();
    if (mounted) setState(() {});
  }

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
                          Text('Missed while hidden', style: type.label),
                          Text(
                            '${missed.length} notification${missed.length == 1 ? '' : 's'} · titles only',
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
    for (final app in apps) {
      final letter = app.label.isEmpty ? '#' : app.label[0].toUpperCase();
      if (letter != lastLetter) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(
              top: CurreSpace.s4,
              bottom: CurreSpace.s1,
            ),
            child: Text(
              letter,
              style: type.meta.copyWith(color: colors.emberText),
            ),
          ),
        );
        lastLetter = letter;
      }
      rows.add(
        Semantics(
          button: true,
          label: 'Ask to open ${app.label}',
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
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.hairline)),
              ),
              child: Text(app.label, style: type.listItem),
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
              title: 'Out of sight',
              subtitle: '${apps.length} apps · tap a name and say why',
            ),
          ),
          Expanded(
            child: apps.isEmpty && missed.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(CurreSpace.gutter),
                      child: Text(
                        'Everything you chose is already in sight.',
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
                        children: rows,
                      ),
                      if (apps.isNotEmpty)
                        Positioned(
                          right: CurreSpace.s2,
                          top: CurreSpace.s2,
                          bottom: CurreSpace.s2,
                          child: Center(
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
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

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
              title: 'Missed while hidden',
              subtitle: 'App, title and time only · kept on this phone',
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
