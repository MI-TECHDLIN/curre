import 'package:flutter/material.dart';

/// 4 dp spacing scale (design report 3.4).
abstract final class CurreSpace {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;

  /// Screen gutter (the report's s5).
  static const s5 = 20.0;
  static const gutter = s5;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s10 = 40.0;
  static const s12 = 48.0;
  static const s16 = 64.0;

  /// Width of the horizon line.
  static const horizon = 2.0;

  /// Minimum touch target side.
  static const touchTarget = 48.0;

  /// Door row icon size and height (design report 3.4).
  static const doorIcon = 44.0;
  static const doorRowMinHeight = 56.0;
}

/// Radii and the signature "dome" shape (design report 3.5). Pushed more
/// generous than the report's first draft (captain's redesign steer,
/// 2026-10-24: "more generous rounded cards" is one of the ways to put life
/// into the system without abandoning it) — `md` grew from 16 to 20 and a
/// new `lg` covers full-bleed hero cards (sky header, grant banner body,
/// mascot stage) that want to read as one soft block of colour.
abstract final class CurreShape {
  static const radiusXs = Radius.circular(6);
  static const radiusMd = Radius.circular(20);
  static const radiusLg = Radius.circular(28);

  static const xs = BorderRadius.all(radiusXs);
  static const md = BorderRadius.all(radiusMd);
  static const lg = BorderRadius.all(radiusLg);

  /// The signature shape: only for surfaces that rise (check-in prompt,
  /// gate outcome card, grant banner).
  static const dome = BorderRadius.vertical(top: Radius.circular(28), bottom: Radius.circular(12));

  /// Bottom sheets (Under the hood).
  static const sheet = BorderRadius.vertical(top: Radius.circular(28));

  static const pill = StadiumBorder();
}

/// Elevation (design report 3.6). Curre has no blur, glass or gradients;
/// separation comes from tone, a hairline border, or (sheets/dialogs only)
/// a soft lift shadow.
abstract final class CurreElevation {
  static const List<BoxShadow> e0 = [];

  static const List<BoxShadow> e2 = [
    BoxShadow(color: Color(0x1A1E1A16), offset: Offset(0, 6), blurRadius: 20),
    BoxShadow(color: Color(0x0F1E1A16), offset: Offset(0, 1), blurRadius: 2),
  ];
}

/// Durations and curves (design report 3.8). [countdown] is linear:
/// the 60 s override and the grant ring are never eased.
abstract final class CurreMotion {
  static const tap = Duration(milliseconds: 90);
  static const quick = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 240);
  static const rise = Duration(milliseconds: 420);
  static const set = Duration(milliseconds: 320);
  static const sky = Duration(milliseconds: 650);
  static const stagger = Duration(milliseconds: 60);
  static const tick = Duration(milliseconds: 160);

  /// The 60-second unlock-gate override, and the grant ring. Both linear.
  static const countdown = Duration(seconds: 60);

  static const riseCurve = Cubic(.16, 1, .3, 1);
  static const setCurve = Cubic(.7, 0, .84, 0);
  static const standard = Cubic(.3, 0, 0, 1);

  /// Returns [Duration.zero] when the platform has reduced motion on,
  /// otherwise [d]. Countdown durations should not be passed through this:
  /// the countdown always counts, even with reduced motion (it is
  /// information, design report 3.8).
  static Duration of(BuildContext context, Duration d) => MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}
