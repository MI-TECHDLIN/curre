import 'package:flutter/material.dart';

import 'curre_colors.dart';
import 'curre_tokens.dart';
import 'curre_type.dart';

/// Builds Curre's [ThemeData] for [brightness], following the design
/// report's recommendation (3.10): follow the system theme mode rather than
/// a fixed light or dark theme.
ThemeData curreTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? CurreColors.light : CurreColors.dark;
  final t = CurreType.of(c);
  final specifyTint = c.outcomes[Outcome.specify]!;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.paper,
    fontFamily: 'Geologica',
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.ink,
      onPrimary: c.paper,
      secondary: c.ember,
      onSecondary: const Color(0xFF1E1A16),
      error: specifyTint.fg,
      onError: c.paper,
      surface: c.paper,
      onSurface: c.ink,
      surfaceContainerHighest: c.sunk,
      outline: c.hairline,
      outlineVariant: c.hairline,
    ),
    textTheme: TextTheme(
      displayLarge: t.display,
      headlineMedium: t.headline,
      titleMedium: t.title,
      bodyMedium: t.body,
      labelLarge: t.label,
      bodySmall: t.caption,
    ),
    splashFactory: NoSplash.splashFactory,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.ink,
        foregroundColor: c.paper,
        shape: CurreShape.pill,
        minimumSize: const Size(CurreSpace.touchTarget, CurreSpace.touchTarget),
        textStyle: t.label,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        side: BorderSide(color: c.ink, width: 1.5),
        shape: CurreShape.pill,
        minimumSize: const Size(CurreSpace.touchTarget, CurreSpace.touchTarget),
        textStyle: t.label,
      ),
    ),
    extensions: [c, t],
  );
}
