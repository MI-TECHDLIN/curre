import 'dart:async';

import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';

/// How to allow a restricted setting once. Android 13 and later block
/// Usage access and Notification access for apps installed outside an app
/// store, and the switch then says Curre was denied. Only the user can
/// allow it, from Curre's App info page; Curre never tries to get around
/// it.
const restrictedSettingsSteps = <String>[
  'Open Curre’s App info.',
  'Tap the three dots in the top right corner.',
  'Tap “Allow restricted settings”.',
  'Confirm with your PIN or fingerprint.',
  'Come back here and switch access on.',
];

/// The restricted-setting note: shown before Curre opens Android's access
/// screen and again, kindly, if access is still off when the user is back.
class RestrictedSettingsHelp extends StatelessWidget {
  const RestrictedSettingsHelp({
    super.key,
    required this.controller,
    this.stillOff = false,
  });

  final CurreController controller;

  /// The user came back and Android still says no.
  final bool stillOff;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Semantics(
      liveRegion: stillOff,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(CurreSpace.s3),
        decoration: BoxDecoration(
          color: colors.sunk,
          borderRadius: CurreShape.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CurreGlyph(CurreGlyphKind.info, size: 20, color: colors.ink2),
                const SizedBox(width: CurreSpace.s2),
                Expanded(
                  child: Text(
                    stillOff
                        ? 'It’s still off. That’s okay, Curre works without it. If Android said the setting is restricted, allow it once:'
                        : 'If Android says the setting is restricted, allow it once:',
                    style: type.body.copyWith(color: colors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CurreSpace.s2),
            for (final (index, step) in restrictedSettingsSteps.indexed)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${index + 1}. $step',
                  style: type.caption.copyWith(color: colors.ink2),
                ),
              ),
            const SizedBox(height: CurreSpace.s3),
            CurreSecondaryButton(
              label: 'Open Curre’s App info',
              glyph: CurreGlyphKind.go,
              onPressed: () => unawaited(_openAppInfo(context)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAppInfo(BuildContext context) async {
    final opened = await controller.openAppInfo();
    if (!opened && context.mounted) {
      showCurreSnack(
        context,
        'Open your phone’s Settings, then Apps, then Curre.',
      );
    }
  }
}

/// A one-time question asked in context: a prop, a short why, a yes and an
/// honest "Not now". Never blocks what the user came to do.
class ContextOfferCard extends StatelessWidget {
  const ContextOfferCard({
    super.key,
    required this.prop,
    required this.title,
    required this.body,
    required this.yesLabel,
    required this.onYes,
    required this.onNotNow,
    this.yesGlyph = CurreGlyphKind.go,
    this.notNowLabel = 'Not now',
    this.footer = const <Widget>[],
  });

  final CurreProp prop;
  final String title;
  final String body;
  final String yesLabel;
  final CurreGlyphKind yesGlyph;
  final VoidCallback? onYes;

  /// Null leaves the card with only its yes.
  final String? notNowLabel;
  final VoidCallback? onNotNow;

  /// Shown under the words, above the buttons.
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Container(
      padding: const EdgeInsets.all(CurreSpace.s4),
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: CurreShape.md,
        border: Border.all(color: colors.hairline, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CurrePropArt(prop, size: 44),
              const SizedBox(width: CurreSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: type.label.weight(700).copyWith(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: CurreSpace.s1),
                    Text(body, style: type.body.copyWith(color: colors.ink2)),
                  ],
                ),
              ),
            ],
          ),
          for (final widget in footer) ...[
            const SizedBox(height: CurreSpace.s3),
            widget,
          ],
          const SizedBox(height: CurreSpace.s3),
          CurrePrimaryButton(
            label: yesLabel,
            glyph: yesGlyph,
            onPressed: onYes,
          ),
          if (notNowLabel case final label?) ...[
            const SizedBox(height: CurreSpace.s1),
            TextButton(
              onPressed: onNotNow,
              child: Text(
                label,
                style: type.label.copyWith(color: colors.ink2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Offers one Android access in context: what it does, the restricted
/// setting note, then Android's own screen. Answering either way settles
/// [prompt] for good; if access is still off when the user is back, the
/// steps stay on screen and Curre carries on without it.
class AccessOffer extends StatefulWidget {
  const AccessOffer({super.key, required this.controller, required this.prompt})
    : assert(prompt != ContextPrompt.nudges);

  final CurreController controller;
  final ContextPrompt prompt;

  @override
  State<AccessOffer> createState() => _AccessOfferState();
}

class _AccessOfferState extends State<AccessOffer>
    with AutomaticKeepAliveClientMixin {
  var _working = false;

  // Android's answer must outlive scrolling the list it sits in.
  @override
  bool get wantKeepAlive => true;

  /// Null until Android has answered.
  bool? _on;
  var _closed = false;

  bool get _askWhy => widget.prompt == ContextPrompt.askWhy;

  Future<void> _allow() async {
    setState(() => _working = true);
    unawaited(widget.controller.settlePrompt(widget.prompt));
    final on = await (_askWhy
        ? widget.controller.requestUsageAccess()
        : widget.controller.requestNotificationAccess());
    if (!mounted) return;
    setState(() {
      _working = false;
      _on = on;
    });
    // The card changes size; keep Android's answer in view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(Scrollable.ensureVisible(context));
    });
  }

  void _notNow() {
    unawaited(widget.controller.settlePrompt(widget.prompt));
    setState(() => _closed = true);
    showCurreSnack(context, 'No problem. It’s in Curre settings any time.');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_closed) return const SizedBox.shrink();
    if (_on == true) {
      return ContextOfferCard(
        prop: CurreProp.sparkles,
        title: 'All set.',
        body: _askWhy
            ? 'Curre will ask “Why now?” when a hidden app opens.'
            : 'Hidden apps will stay quiet until you bring them back.',
        yesLabel: 'Done',
        yesGlyph: CurreGlyphKind.check,
        onYes: () => setState(() => _closed = true),
        notNowLabel: null,
        onNotNow: null,
      );
    }
    return ContextOfferCard(
      prop: _askWhy ? CurreProp.shield : CurreProp.zzz,
      title: _askWhy
          ? 'Ask “Why now?” when a hidden app opens?'
          : 'Keep hidden apps quiet?',
      body: _askWhy
          ? 'Hidden apps can sneak back in through recent apps, links or notifications. Curre can ask “Why now?” then too. It only checks which app opened, never what’s on your screen.'
          : 'Hidden apps can still buzz you. Curre can keep them quiet until you bring them back, and list what you missed here. Message text is never saved.',
      yesLabel: _on == false
          ? 'Try again'
          : _askWhy
          ? 'Turn on Usage access'
          : 'Turn on notification access',
      yesGlyph: _askWhy ? CurreGlyphKind.outOfSight : CurreGlyphKind.notify,
      onYes: _working ? null : _allow,
      onNotNow: _working ? null : _notNow,
      footer: [
        RestrictedSettingsHelp(
          controller: widget.controller,
          stillOff: _on == false,
        ),
      ],
    );
  }
}
