import 'package:flutter/material.dart';

import 'curre_colors.dart';

/// Curre's three type voices (design report 3.3 / 3.10):
/// Curre speaks in Geologica, you speak in Newsreader Italic, the machine
/// speaks in Atkinson Hyperlegible Mono.
@immutable
class CurreType extends ThemeExtension<CurreType> {
  const CurreType({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.label,
    required this.caption,
    required this.listItem,
    required this.youLarge,
    required this.you,
    required this.youSmall,
    required this.figureXL,
    required this.figure,
    required this.meta,
  });

  // Curre's voice.
  final TextStyle display;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle body;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle listItem;

  // The user's voice.
  final TextStyle youLarge;
  final TextStyle you;
  final TextStyle youSmall;

  // The machine's voice.
  final TextStyle figureXL;
  final TextStyle figure;
  final TextStyle meta;

  /// Builds the scale for [c], a colour set, so the default ink in every
  /// style matches the current theme brightness.
  factory CurreType.of(CurreColors c) {
    // Variable fonts: set both FontWeight (fallback) and the `wght`
    // FontVariation axis. Flutter does not reliably map FontWeight onto a
    // variable font's axis on Android (design report 3.10 note 2).
    TextStyle geo(double size, double lh, double w, {double ls = 0, Color? color}) => TextStyle(
      fontFamily: 'Geologica',
      fontSize: size,
      height: lh / size,
      letterSpacing: ls,
      color: color ?? c.ink,
      fontWeight: _nearestWeight(w),
      fontVariations: [FontVariation('wght', w), const FontVariation('SHRP', 0)],
    );
    TextStyle you(double size, double lh) => TextStyle(
      fontFamily: 'Newsreader',
      fontStyle: FontStyle.italic,
      fontSize: size,
      height: lh / size,
      color: c.ink,
      fontWeight: FontWeight.w400,
      fontVariations: [const FontVariation('wght', 430), FontVariation('opsz', size)],
    );
    TextStyle mono(double size, double lh, double w, {double ls = 0, Color? color}) => TextStyle(
      fontFamily: 'AtkinsonHyperlegibleMono',
      fontSize: size,
      height: lh / size,
      letterSpacing: ls,
      color: color ?? c.ink,
      fontWeight: _nearestWeight(w),
      fontVariations: [FontVariation('wght', w)],
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return CurreType(
      // Level-up (captain's reviews, 2026-10-24): the references' big,
      // friendly headlines (Mombo's greeting, the mood trio's heavy
      // question) and the learning plan's big numerals. Still the three
      // voices from report 3.3; only size and weight move, and body copy
      // keeps the report's reading comfort.
      display: geo(48, 52, 720, ls: -1.4),
      headline: geo(30, 36, 700, ls: -.6),
      title: geo(22, 28, 680, ls: -.3),
      body: geo(16, 24, 420),
      label: geo(15, 20, 620),
      caption: geo(13, 18, 520, ls: .1),
      listItem: geo(18, 24, 400, color: c.ink2),
      youLarge: you(26, 34),
      you: you(20, 28),
      youSmall: you(16, 22),
      figureXL: mono(72, 76, 600, ls: -1),
      figure: mono(16, 20, 600),
      meta: mono(12, 16, 500, ls: .2, color: c.ink3),
    );
  }

  static FontWeight _nearestWeight(double w) {
    final clamped = w.clamp(100, 900);
    final step = (clamped / 100).round() * 100;
    return FontWeight.values[(step ~/ 100) - 1];
  }

  @override
  CurreType copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? body,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? listItem,
    TextStyle? youLarge,
    TextStyle? you,
    TextStyle? youSmall,
    TextStyle? figureXL,
    TextStyle? figure,
    TextStyle? meta,
  }) {
    return CurreType(
      display: display ?? this.display,
      headline: headline ?? this.headline,
      title: title ?? this.title,
      body: body ?? this.body,
      label: label ?? this.label,
      caption: caption ?? this.caption,
      listItem: listItem ?? this.listItem,
      youLarge: youLarge ?? this.youLarge,
      you: you ?? this.you,
      youSmall: youSmall ?? this.youSmall,
      figureXL: figureXL ?? this.figureXL,
      figure: figure ?? this.figure,
      meta: meta ?? this.meta,
    );
  }

  @override
  CurreType lerp(ThemeExtension<CurreType>? other, double t) {
    if (other is! CurreType) return this;
    return CurreType(
      display: TextStyle.lerp(display, other.display, t)!,
      headline: TextStyle.lerp(headline, other.headline, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      listItem: TextStyle.lerp(listItem, other.listItem, t)!,
      youLarge: TextStyle.lerp(youLarge, other.youLarge, t)!,
      you: TextStyle.lerp(you, other.you, t)!,
      youSmall: TextStyle.lerp(youSmall, other.youSmall, t)!,
      figureXL: TextStyle.lerp(figureXL, other.figureXL, t)!,
      figure: TextStyle.lerp(figure, other.figure, t)!,
      meta: TextStyle.lerp(meta, other.meta, t)!,
    );
  }
}

/// Weight changes for Curre's variable fonts. `copyWith(fontWeight: …)`
/// alone does not move a variable font's `wght` axis once a style carries
/// a `wght` [FontVariation] (the axis wins), so use [weight] instead: it
/// sets the axis and the [FontWeight] fallback together and keeps every
/// other axis (Geologica's SHRP, Newsreader's opsz) as it was.
extension CurreTextWeight on TextStyle {
  TextStyle weight(double w) {
    final others = [
      for (final v in fontVariations ?? const <FontVariation>[])
        if (v.axis != 'wght') v,
    ];
    return copyWith(fontWeight: CurreType._nearestWeight(w), fontVariations: [FontVariation('wght', w), ...others]);
  }
}
