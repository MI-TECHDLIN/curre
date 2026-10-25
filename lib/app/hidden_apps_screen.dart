import 'package:flutter/material.dart';

import '../design/design.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';
import 'unlock_gate_screen.dart';

class HiddenAppsScreen extends StatelessWidget {
  const HiddenAppsScreen({super.key, required this.controller});

  final CurreController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final apps = controller.hiddenApps;
    String? lastLetter;
    final rows = <Widget>[];
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
            child: apps.isEmpty
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
