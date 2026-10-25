import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import 'curre_controller.dart';

extension SessionPresentation on SessionName {
  Session get designSession => switch (this) {
    SessionName.morning => Session.morning,
    SessionName.afternoon => Session.afternoon,
    SessionName.evening => Session.evening,
  };

  String get label => switch (this) {
    SessionName.morning => 'morning',
    SessionName.afternoon => 'afternoon',
    SessionName.evening => 'evening',
  };

  CurreGlyphKind get glyph => switch (this) {
    SessionName.morning => CurreGlyphKind.sessionMorning,
    SessionName.afternoon => CurreGlyphKind.sessionAfternoon,
    SessionName.evening => CurreGlyphKind.sessionEvening,
  };
}

String formatClock(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String formatDuration(Duration value) {
  final clamped = value.isNegative ? Duration.zero : value;
  final minutes = clamped.inMinutes;
  final seconds = clamped.inSeconds.remainder(60);
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class CurrePage extends StatelessWidget {
  const CurrePage({
    super.key,
    required this.child,
    this.background,
    this.safeBottom = true,
  });

  final Widget child;
  final Color? background;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    return Scaffold(
      backgroundColor: background ?? colors.paper,
      body: SafeArea(bottom: safeBottom, child: child),
    );
  }
}

class CurrePrimaryButton extends StatelessWidget {
  const CurrePrimaryButton({
    super.key,
    required this.label,
    this.glyph,
    this.onPressed,
    this.background,
    this.foreground,
  });

  final String label;
  final CurreGlyphKind? glyph;
  final VoidCallback? onPressed;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final enabled = onPressed != null;
    final bg = background ?? colors.ink;
    final fg = foreground ?? colors.paper;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: enabled ? bg : colors.hairline,
        shape: CurreShape.pill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          splashFactory: NoSplash.splashFactory,
          highlightColor: fg.withValues(alpha: .1),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: type.label
                          .weight(660)
                          .copyWith(
                            color: enabled ? fg : colors.ink3,
                            fontSize: 16,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (glyph != null) ...[
                    const SizedBox(width: CurreSpace.s2),
                    CurreGlyph(
                      glyph!,
                      size: 20,
                      color: enabled ? fg : colors.ink3,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CurreSecondaryButton extends StatelessWidget {
  const CurreSecondaryButton({
    super.key,
    required this.label,
    this.glyph,
    this.onPressed,
  });

  final String label;
  final CurreGlyphKind? glyph;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: colors.ink, width: 1.5)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          splashFactory: NoSplash.splashFactory,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: type.label.copyWith(color: colors.ink),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (glyph != null) ...[
                    const SizedBox(width: CurreSpace.s2),
                    CurreGlyph(glyph!, size: 19, color: colors.ink),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoundGlyphButton extends StatelessWidget {
  const RoundGlyphButton({
    super.key,
    required this.glyph,
    required this.label,
    this.onPressed,
  });

  final CurreGlyphKind glyph;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: colors.raised,
        shape: CircleBorder(side: BorderSide(color: colors.hairline)),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          splashFactory: NoSplash.splashFactory,
          child: SizedBox.square(
            dimension: CurreSpace.touchTarget,
            child: Center(
              child: CurreGlyph(glyph, size: 22, color: colors.ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// The single swap point for the avatar art being produced in parallel.
class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({
    super.key,
    required this.displayName,
    this.onPressed,
  });

  final String? displayName;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final trimmed = displayName?.trim();
    final initial = trimmed == null || trimmed.isEmpty
        ? 'C'
        : String.fromCharCode(trimmed.runes.first).toUpperCase();
    return Semantics(
      button: onPressed != null,
      label: onPressed == null ? 'Profile avatar' : 'Open profile',
      excludeSemantics: true,
      child: Material(
        color: colors.raised,
        shape: CircleBorder(side: BorderSide(color: colors.ember, width: 2)),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          splashFactory: NoSplash.splashFactory,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: Text(
                initial,
                style: type.title
                    .weight(720)
                    .copyWith(color: colors.emberText, height: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The compact shared element used while a check-in sentence becomes Home's
/// richer plan card. It stays valid at every interpolated Hero size.
class PlanHeroSentence extends StatelessWidget {
  const PlanHeroSentence({super.key, required this.intention});

  final String intention;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Material(
      color: colors.raised,
      borderRadius: CurreShape.md,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            intention,
            style: type.you,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class CurreTopBar extends StatelessWidget {
  const CurreTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.maxTitleLines,
  });

  final String title;
  final String? subtitle;
  final int? maxTitleLines;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoundGlyphButton(
          glyph: CurreGlyphKind.back,
          label: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: CurreSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: type.title,
                maxLines: maxTitleLines,
                overflow: maxTitleLines == null
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: type.caption.copyWith(color: colors.ink3),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class InstalledAppIcon extends StatelessWidget {
  const InstalledAppIcon({
    super.key,
    required this.controller,
    required this.packageName,
    this.size = CurreSpace.doorIcon,
  });

  final CurreController controller;
  final String packageName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    return FutureBuilder<Uint8List?>(
      future: controller.iconFor(packageName),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(size * .28),
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          );
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.raised,
            borderRadius: BorderRadius.circular(size * .28),
            border: Border.all(color: colors.hairline),
          ),
          child: Center(
            child: CurreGlyph(
              CurreGlyphKind.door,
              size: size * .52,
              color: colors.ink2,
            ),
          ),
        );
      },
    );
  }
}

class HomeDock extends StatelessWidget {
  const HomeDock({
    super.key,
    required this.controller,
    required this.onHidden,
    required this.onCurreSettings,
  });

  final CurreController controller;
  final VoidCallback onHidden;
  final VoidCallback onCurreSettings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    final items = <({String label, CurreGlyphKind glyph, VoidCallback action})>[
      (
        label: 'Phone',
        glyph: CurreGlyphKind.phone,
        action: () => _launch(controller.phonePackage),
      ),
      (
        label: 'Messages',
        glyph: CurreGlyphKind.messages,
        action: () => _launch(controller.messagesPackage),
      ),
      (
        label: 'Settings',
        glyph: CurreGlyphKind.androidSettings,
        action: () => _launch(controller.androidSettingsPackage),
      ),
      (
        label: 'Curre',
        glyph: CurreGlyphKind.curreSettings,
        action: onCurreSettings,
      ),
    ];
    return Material(
      color: colors.paper,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CurreSpace.gutter,
          CurreSpace.s1,
          CurreSpace.gutter,
          CurreSpace.s2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: largeText ? 92 : 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned(left: 0, right: 0, child: HorizonLine()),
                  DecoratedBox(
                    decoration: ShapeDecoration(
                      color: colors.raised,
                      shape: StadiumBorder(
                        side: BorderSide(color: colors.hairline),
                      ),
                    ),
                    child: Row(
                      children: [
                        for (final item in items)
                          Expanded(
                            child: Semantics(
                              button: true,
                              label: item.label == 'Curre'
                                  ? 'Curre settings'
                                  : item.label,
                              excludeSemantics: true,
                              child: InkWell(
                                onTap: item.action,
                                splashFactory: NoSplash.splashFactory,
                                child: SizedBox(
                                  height: largeText ? 86 : 64,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CurreGlyph(
                                        item.glyph,
                                        size: 23,
                                        color: item.label == 'Curre'
                                            ? colors.emberText
                                            : colors.ink,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.label,
                                        style: type.caption.copyWith(
                                          fontSize: 10,
                                          color: item.label == 'Curre'
                                              ? colors.emberText
                                              : colors.ink2,
                                        ),
                                        maxLines: largeText ? 2 : 1,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label:
                  '${controller.hiddenApps.length} apps out of sight. Open list.',
              excludeSemantics: true,
              child: InkWell(
                onTap: onHidden,
                splashFactory: NoSplash.splashFactory,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: CurreSpace.s2,
                          ),
                          child: Text(
                            '${controller.hiddenApps.length} out of sight',
                            style: type.listItem
                                .weight(520)
                                .copyWith(fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: CurreSpace.s2),
                      CurreGlyph(
                        CurreGlyphKind.rise,
                        size: 19,
                        color: colors.ink2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launch(String? packageName) {
    if (packageName != null) controller.plainLaunch(packageName);
  }
}

void showCurreSnack(BuildContext context, String message) {
  final colors = Theme.of(context).extension<CurreColors>()!;
  final type = Theme.of(context).extension<CurreType>()!;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: type.body.copyWith(color: colors.paper)),
        backgroundColor: colors.ink,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
