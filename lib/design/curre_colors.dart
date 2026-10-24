import 'package:flutter/material.dart';

/// The three check-in sessions (design report 3.2 / 3.10).
enum Session { morning, afternoon, evening }

/// The five unlock-gate outcomes (handoff: five outcomes, not four).
enum Outcome { open, later, specify, flagged, unavailable }

/// The five reason kinds Decide sorts a reason into.
enum ReasonKind { task, person, timeSensitive, browse, unclear }

/// A background/foreground colour pair, e.g. a sky and its on-sky ink,
/// or an outcome tint and its ink.
@immutable
class Pair {
  const Pair(this.bg, this.fg);

  final Color bg;
  final Color fg;

  Pair lerp(Pair other, double t) =>
      Pair(Color.lerp(bg, other.bg, t)!, Color.lerp(fg, other.fg, t)!);

  @override
  bool operator ==(Object other) =>
      other is Pair && other.bg == bg && other.fg == fg;

  @override
  int get hashCode => Object.hash(bg, fg);
}

/// Curre's colour roles: paper and ink, the three session skies and the
/// five outcome tints. See design report 3.2 for the source table and 3.10
/// for this shape.
@immutable
class CurreColors extends ThemeExtension<CurreColors> {
  const CurreColors({
    required this.paper,
    required this.raised,
    required this.sunk,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.hairline,
    required this.horizon,
    required this.ember,
    required this.emberText,
    required this.marker,
    required this.guardMark,
    required this.skies,
    required this.outcomes,
  });

  final Color paper;
  final Color raised;
  final Color sunk;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color hairline;
  final Color horizon;
  final Color ember;
  final Color emberText;
  final Color marker;
  final Color guardMark;

  /// Sky + on-sky ink for each session.
  final Map<Session, Pair> skies;

  /// Tint + ink for the four outcomes that have one of their own.
  /// `later` has no entry: it borrows the sky of the session it saves to
  /// (see [outcome]).
  final Map<Outcome, Pair> outcomes;

  static const light = CurreColors(
    paper: Color(0xFFF7F2EA),
    raised: Color(0xFFFFFDF9),
    sunk: Color(0xFFEEE7DC),
    ink: Color(0xFF1E1A16),
    ink2: Color(0xFF5A5048),
    ink3: Color(0xFF6E6257),
    hairline: Color(0xFFE2D9CC),
    horizon: Color(0xFF1E1A16),
    ember: Color(0xFFE85F2E),
    emberText: Color(0xFFA8441A),
    marker: Color(0xFFFBE1A0),
    guardMark: Color(0xFFF6E2A8),
    skies: {
      Session.morning: Pair(Color(0xFFFBDCC4), Color(0xFF4A1E0B)),
      Session.afternoon: Pair(Color(0xFFB5DDE6), Color(0xFF0F3943)),
      Session.evening: Pair(Color(0xFF2C3463), Color(0xFFF2EEE6)),
    },
    outcomes: {
      Outcome.open: Pair(Color(0xFFCFE8C9), Color(0xFF1D4A22)),
      Outcome.specify: Pair(Color(0xFFF1D3CB), Color(0xFF6B2A1E)),
      Outcome.flagged: Pair(Color(0xFFF6E2A8), Color(0xFF5A4100)),
      Outcome.unavailable: Pair(Color(0xFFDCD8D2), Color(0xFF3F3A35)),
    },
  );

  static const dark = CurreColors(
    paper: Color(0xFF13111A),
    raised: Color(0xFF1D1A25),
    sunk: Color(0xFF0C0B11),
    ink: Color(0xFFF2ECE3),
    ink2: Color(0xFFB9B0A6),
    ink3: Color(0xFF8F877E),
    hairline: Color(0xFF2E2A36),
    horizon: Color(0xFFF2ECE3),
    ember: Color(0xFFE85F2E),
    emberText: Color(0xFFF08A55),
    marker: Color(0xFF5B4515),
    guardMark: Color(0xFF3F3311),
    skies: {
      Session.morning: Pair(Color(0xFF4A2A22), Color(0xFFFBD3B4)),
      Session.afternoon: Pair(Color(0xFF173C47), Color(0xFFCDEBF2)),
      Session.evening: Pair(Color(0xFF1C2147), Color(0xFFE6E3F7)),
    },
    outcomes: {
      Outcome.open: Pair(Color(0xFF1F3A22), Color(0xFFBFE5B8)),
      Outcome.specify: Pair(Color(0xFF43231D), Color(0xFFF3C3B6)),
      Outcome.flagged: Pair(Color(0xFF3F3311), Color(0xFFF4DB8E)),
      Outcome.unavailable: Pair(Color(0xFF2B2926), Color(0xFFD8D3CC)),
    },
  );

  /// Sky + on-sky ink for [s].
  Pair sky(Session s) => skies[s]!;

  /// Tint + ink for [o]. `later` resolves to the sky of [laterTarget],
  /// the session it will be waiting at (design report 4.6).
  Pair outcome(Outcome o, {required Session laterTarget}) =>
      o == Outcome.later ? sky(laterTarget) : outcomes[o]!;

  @override
  CurreColors copyWith({
    Color? paper,
    Color? raised,
    Color? sunk,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? hairline,
    Color? horizon,
    Color? ember,
    Color? emberText,
    Color? marker,
    Color? guardMark,
    Map<Session, Pair>? skies,
    Map<Outcome, Pair>? outcomes,
  }) {
    return CurreColors(
      paper: paper ?? this.paper,
      raised: raised ?? this.raised,
      sunk: sunk ?? this.sunk,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      hairline: hairline ?? this.hairline,
      horizon: horizon ?? this.horizon,
      ember: ember ?? this.ember,
      emberText: emberText ?? this.emberText,
      marker: marker ?? this.marker,
      guardMark: guardMark ?? this.guardMark,
      skies: skies ?? this.skies,
      outcomes: outcomes ?? this.outcomes,
    );
  }

  @override
  CurreColors lerp(ThemeExtension<CurreColors>? other, double t) {
    if (other is! CurreColors) return this;
    Map<Session, Pair> lerpSkies() => {
      for (final s in Session.values) s: skies[s]!.lerp(other.skies[s]!, t),
    };
    Map<Outcome, Pair> lerpOutcomes() => {
      for (final o in outcomes.keys) o: outcomes[o]!.lerp(other.outcomes[o]!, t),
    };
    return CurreColors(
      paper: Color.lerp(paper, other.paper, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      sunk: Color.lerp(sunk, other.sunk, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      horizon: Color.lerp(horizon, other.horizon, t)!,
      ember: Color.lerp(ember, other.ember, t)!,
      emberText: Color.lerp(emberText, other.emberText, t)!,
      marker: Color.lerp(marker, other.marker, t)!,
      guardMark: Color.lerp(guardMark, other.guardMark, t)!,
      skies: lerpSkies(),
      outcomes: lerpOutcomes(),
    );
  }
}
