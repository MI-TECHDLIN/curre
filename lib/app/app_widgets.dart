import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../l10n/l10n.dart';
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

String formatClock(DateTime value, {String? locale}) {
  final local = value.toLocal();
  try {
    return DateFormat.Hm(locale).format(local);
  } on Object {
    // Lightweight widget tests do not always install intl's date symbols.
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
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

/// The shared profile-button rendering used on Home and in the profile sheet.
class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({
    super.key,
    required this.displayName,
    this.avatarId,
    this.motion = AvatarMotion.still,
    this.onPressed,
  });

  final String? displayName;
  final String? avatarId;
  final AvatarMotion motion;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final trimmed = displayName?.trim();
    final initial = trimmed == null || trimmed.isEmpty ? 'C' : trimmed;
    return Semantics(
      button: onPressed != null,
      label: onPressed == null
          ? context.l10n.profileAvatar
          : context.l10n.openProfile,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          splashFactory: NoSplash.splashFactory,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: Avatar(
                avatarId: avatarId,
                initial: initial,
                size: 40,
                motion: motion,
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
          label: context.l10n.back,
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

/// An app's real icon from the phone, loaded once and cached by
/// [CurreController.iconFor], so a list never waits on it.
///
/// While the icon loads a neutral tile holds its place. If the phone has no
/// icon for the app, [fallback] shows instead; without one, Home's plain
/// door tile stays.
class InstalledAppIcon extends StatelessWidget {
  const InstalledAppIcon({
    super.key,
    required this.controller,
    required this.packageName,
    this.size = CurreSpace.doorIcon,
    this.fallback,
  });

  final CurreController controller;
  final String packageName;
  final double size;
  final Widget? fallback;

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
              errorBuilder: (context, error, stackTrace) =>
                  fallback ?? _tile(colors, door: true),
            ),
          );
        }
        final loaded = snapshot.connectionState == ConnectionState.done;
        if (loaded && fallback != null) return fallback!;
        return _tile(colors, door: fallback == null);
      },
    );
  }

  Widget _tile(CurreColors colors, {required bool door}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: colors.raised,
      borderRadius: BorderRadius.circular(size * .28),
      border: Border.all(color: colors.hairline),
    ),
    child: door
        ? Center(
            child: CurreGlyph(
              CurreGlyphKind.door,
              size: size * .52,
              color: colors.ink2,
            ),
          )
        : null,
  );
}

class HomeDock extends StatelessWidget {
  const HomeDock({
    super.key,
    required this.controller,
    required this.onHidden,
    required this.onCurreSettings,
    this.onAllApps,
  });

  final CurreController controller;
  final VoidCallback onHidden;
  final VoidCallback onCurreSettings;

  /// Opens "All apps": every app the user didn't hide.
  final VoidCallback? onAllApps;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final l10n = context.l10n;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    final items = <({String label, CurreGlyphKind glyph, VoidCallback action})>[
      (
        label: l10n.phone,
        glyph: CurreGlyphKind.phone,
        action: () => _launch(controller.phonePackage),
      ),
      (
        label: l10n.messages,
        glyph: CurreGlyphKind.messages,
        action: () => _launch(controller.messagesPackage),
      ),
      (
        label: l10n.androidSettings,
        glyph: CurreGlyphKind.androidSettings,
        action: () => _launch(controller.androidSettingsPackage),
      ),
      (
        label: l10n.appName,
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
                              label: item.label == l10n.appName
                                  ? l10n.curreSettings
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
                                        color: item.label == l10n.appName
                                            ? colors.emberText
                                            : colors.ink,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.label,
                                        style: type.caption.copyWith(
                                          fontSize: 10,
                                          color: item.label == l10n.appName
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
            Row(
              children: [
                if (onAllApps case final openAll?) ...[
                  Expanded(
                    child: _DockLink(
                      key: const Key('home-all-apps'),
                      label: l10n.allApps,
                      semanticLabel:
                          '${l10n.allApps}. ${l10n.allAppsDescription}',
                      glyph: CurreGlyphKind.door,
                      onTap: openAll,
                    ),
                  ),
                  ExcludeSemantics(
                    child: Text(
                      '·',
                      style: type.listItem.copyWith(color: colors.ink3),
                    ),
                  ),
                ],
                Expanded(
                  child: _DockLink(
                    key: const Key('home-hidden-apps'),
                    label: l10n.hiddenAppsCount(controller.hiddenApps.length),
                    semanticLabel:
                        '${l10n.hiddenAppsCount(controller.hiddenApps.length)}. ${l10n.hiddenApps}',
                    glyph: CurreGlyphKind.rise,
                    onTap: onHidden,
                  ),
                ),
              ],
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

/// One quiet text link under the dock.
class _DockLink extends StatelessWidget {
  const _DockLink({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.glyph,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final CurreGlyphKind glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: CurreSpace.s2),
                  child: Text(
                    label,
                    style: type.listItem.weight(520).copyWith(fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: CurreSpace.s2),
              CurreGlyph(glyph, size: 19, color: colors.ink2),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "Why now?" wait in words: "30 seconds".
String overrideWaitWordsFor(AppLocalizations l10n) =>
    l10n.secondsCount(overrideWait.inSeconds);

/// English compatibility for non-widget reports; screens use
/// [overrideWaitWordsFor] with their active locale.
String get overrideWaitWords =>
    lookupAppLocalizations(const Locale('en'))
        .secondsCount(overrideWait.inSeconds);

/// "1 hidden app", "12 hidden apps".
String hiddenAppsLabel(int count) =>
    lookupAppLocalizations(const Locale('en')).hiddenAppsCount(count);

/// A short note at the foot of the screen. With [actionLabel] it offers one
/// action (an Undo) and still goes away by itself after [duration].
void showCurreSnack(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final colors = Theme.of(context).extension<CurreColors>()!;
  final type = Theme.of(context).extension<CurreType>()!;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: type.body.copyWith(color: colors.paper)),
        backgroundColor: colors.ink,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        persist: false,
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: colors.paper,
                onPressed: onAction,
              ),
      ),
    );
}

/// Shows [child] (the screen's usual waiting line) until [waking] turns on,
/// then a calm "getting ready" note in the same place.
class GettingReadyNote extends StatelessWidget {
  const GettingReadyNote({
    super.key,
    required this.waking,
    required this.child,
    this.textAlign,
  });

  final ValueListenable<bool> waking;
  final Widget child;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: waking,
      child: child,
      builder: (context, isWaking, child) {
        if (!isWaking) return child!;
        final colors = Theme.of(context).extension<CurreColors>()!;
        final type = Theme.of(context).extension<CurreType>()!;
        final align = textAlign ?? TextAlign.start;
        return Semantics(
          key: const Key('getting-ready'),
          liveRegion: true,
          child: Column(
            crossAxisAlignment: switch (align) {
              TextAlign.center => CrossAxisAlignment.center,
              _ => CrossAxisAlignment.start,
            },
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.gettingReady,
                style: type.body,
                textAlign: align,
              ),
              const SizedBox(height: CurreSpace.s1),
              Text(
                context.l10n.gettingReadyBody,
                style: type.caption.copyWith(color: colors.ink2),
                textAlign: align,
              ),
            ],
          ),
        );
      },
    );
  }
}
