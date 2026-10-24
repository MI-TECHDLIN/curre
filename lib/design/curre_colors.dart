import 'package:flutter/material.dart';

// One ReasonKind for the whole app: the door policy owns it and core
// re-exports it too, so screens can import design, core and doors together.
export '../doors/door_models.dart' show ReasonKind;

/// The three check-in sessions (design report 3.2 / 3.10).
enum Session { morning, afternoon, evening }

/// The five unlock-gate outcomes (handoff: five outcomes, not four).
enum Outcome { open, later, specify, flagged, unavailable }

/// A background/foreground colour pair, e.g. a sky and its on-sky ink,
/// or an outcome tint and its ink.
@immutable
class Pair {
  const Pair(this.bg, this.fg);

  final Color bg;
  final Color fg;

  Pair lerp(Pair other, double t) => Pair(Color.lerp(bg, other.bg, t)!, Color.lerp(fg, other.fg, t)!);

  @override
  bool operator ==(Object other) => other is Pair && other.bg == bg && other.fg == fg;

  @override
  int get hashCode => Object.hash(bg, fg);
}

/// One link colour: it ties a span in the user's own words to the door
/// that span opens. Span 1 and door 1 share `links[0]`, and so on, so a
/// glance says which words put which app on Home (design report
/// principle 4, "each mark links to what it drives"). Always paired with a
/// number, never colour alone.
///
/// [mark] is the highlighter behind the words. It is a light pastel in both
/// themes, so marked words are always set in [CurreColors.markInk]. [card]
/// is the door card's fill and ink in the current theme.
@immutable
class LinkTint {
  const LinkTint({required this.mark, required this.card});

  final Color mark;
  final Pair card;

  LinkTint lerp(LinkTint other, double t) =>
      LinkTint(mark: Color.lerp(mark, other.mark, t)!, card: card.lerp(other.card, t));

  @override
  bool operator ==(Object other) => other is LinkTint && other.mark == mark && other.card == card;

  @override
  int get hashCode => Object.hash(mark, card);
}

/// Curre's colour roles: paper and ink, the three session skies (each with
/// a ground tone for below its horizon), the five outcome tints and the
/// link tints. See design report 3.2 for the source table and 3.10 for this
/// shape.
///
/// Level-up (captain's review, 2026-10-24): the skies are now strong,
/// confident card colours rather than pale washes. The morning sky is the
/// marigold of the Mombo check-in card the captain chose as the primary
/// reference, and the base stays warm paper, so one warm card on a calm
/// page carries the screen. Every text pair still clears WCAG AA (most
/// clear AAA). Ember on a sky is decorative only (Peek, the sun disc), and
/// the countdown disc keeps its ink edge.
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
    required this.markInk,
    required this.guardMark,
    required this.skies,
    required this.grounds,
    required this.outcomes,
    required this.links,
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

  /// Default highlighter for an extracted span that drives no door.
  /// Highlighter marks ([marker], [guardMark], every [LinkTint.mark]) are
  /// light in both themes, like real highlighter ink, and always carry
  /// [markInk], so one sentence never mixes two kinds of mark.
  final Color marker;

  /// Ink for any word set on a [LinkTint.mark] (light pastel in both
  /// themes, so this is a dark ink in both).
  final Color markInk;
  final Color guardMark;

  /// Sky + on-sky ink for each session: the check-in card, the plan card
  /// and the `later` outcome.
  final Map<Session, Pair> skies;

  /// The tone below a sky's horizon inside a sky scene (tone-on-tone, the
  /// mood-face recording's idea): where things go out of sight.
  final Map<Session, Color> grounds;

  /// Tint + ink for the four outcomes that have one of their own.
  /// `later` has no entry: it borrows the sky of the session it saves to
  /// (see [outcome]).
  final Map<Outcome, Pair> outcomes;

  /// Span-to-door link colours, used in order and cycled after the last.
  final List<LinkTint> links;

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
    markInk: Color(0xFF1E1A16),
    guardMark: Color(0xFFF6E2A8),
    skies: {
      Session.morning: Pair(Color(0xFFFCC35A), Color(0xFF3B2206)),
      Session.afternoon: Pair(Color(0xFF96D0E6), Color(0xFF0C3442)),
      Session.evening: Pair(Color(0xFF2E3876), Color(0xFFF4EFE6)),
    },
    grounds: {
      Session.morning: Color(0xFFF0A43A),
      Session.afternoon: Color(0xFF6DB5D1),
      Session.evening: Color(0xFF222A5E),
    },
    outcomes: {
      Outcome.open: Pair(Color(0xFFCFE8C9), Color(0xFF1D4A22)),
      Outcome.specify: Pair(Color(0xFFF1D3CB), Color(0xFF6B2A1E)),
      Outcome.flagged: Pair(Color(0xFFF6E2A8), Color(0xFF5A4100)),
      Outcome.unavailable: Pair(Color(0xFFDCD8D2), Color(0xFF3F3A35)),
    },
    links: [
      LinkTint(mark: Color(0xFFF7D3CC), card: Pair(Color(0xFFF7D3CC), Color(0xFF1E1A16))),
      LinkTint(mark: Color(0xFFCFE2F4), card: Pair(Color(0xFFCFE2F4), Color(0xFF1E1A16))),
      LinkTint(mark: Color(0xFFDDE9CF), card: Pair(Color(0xFFDDE9CF), Color(0xFF1E1A16))),
      LinkTint(mark: Color(0xFFF3E2C4), card: Pair(Color(0xFFF3E2C4), Color(0xFF1E1A16))),
    ],
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
    marker: Color(0xFFFBE1A0),
    markInk: Color(0xFF1E1A16),
    guardMark: Color(0xFFF6E2A8),
    skies: {
      Session.morning: Pair(Color(0xFF6E2A12), Color(0xFFFFE0C8)),
      Session.afternoon: Pair(Color(0xFF16506A), Color(0xFFD2F0FA)),
      Session.evening: Pair(Color(0xFF262F78), Color(0xFFECE8FA)),
    },
    grounds: {
      Session.morning: Color(0xFF4E1C0B),
      Session.afternoon: Color(0xFF0F3B4F),
      Session.evening: Color(0xFF1A2257),
    },
    outcomes: {
      Outcome.open: Pair(Color(0xFF1F3A22), Color(0xFFBFE5B8)),
      Outcome.specify: Pair(Color(0xFF43231D), Color(0xFFF3C3B6)),
      Outcome.flagged: Pair(Color(0xFF3F3311), Color(0xFFF4DB8E)),
      Outcome.unavailable: Pair(Color(0xFF2B2926), Color(0xFFD8D3CC)),
    },
    links: [
      LinkTint(mark: Color(0xFFF7D3CC), card: Pair(Color(0xFF4A2B2D), Color(0xFFF7D3CC))),
      LinkTint(mark: Color(0xFFCFE2F4), card: Pair(Color(0xFF1E3449), Color(0xFFCFE2F4))),
      LinkTint(mark: Color(0xFFDDE9CF), card: Pair(Color(0xFF2B3A27), Color(0xFFDDE9CF))),
      LinkTint(mark: Color(0xFFF3E2C4), card: Pair(Color(0xFF3E3322), Color(0xFFF3E2C4))),
    ],
  );

  /// Sky + on-sky ink for [s].
  Pair sky(Session s) => skies[s]!;

  /// The ground tone below [s]'s horizon.
  Color ground(Session s) => grounds[s]!;

  /// Link tint for span/door number [n] (1-based, as shown on screen),
  /// cycling once the palette runs out.
  LinkTint link(int n) => links[(n - 1) % links.length];

  /// Tint + ink for [o]. `later` resolves to the sky of [laterTarget],
  /// the session it will be waiting at (design report 4.6).
  Pair outcome(Outcome o, {required Session laterTarget}) => o == Outcome.later ? sky(laterTarget) : outcomes[o]!;

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
    Color? markInk,
    Color? guardMark,
    Map<Session, Pair>? skies,
    Map<Session, Color>? grounds,
    Map<Outcome, Pair>? outcomes,
    List<LinkTint>? links,
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
      markInk: markInk ?? this.markInk,
      guardMark: guardMark ?? this.guardMark,
      skies: skies ?? this.skies,
      grounds: grounds ?? this.grounds,
      outcomes: outcomes ?? this.outcomes,
      links: links ?? this.links,
    );
  }

  @override
  CurreColors lerp(ThemeExtension<CurreColors>? other, double t) {
    if (other is! CurreColors) return this;
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
      markInk: Color.lerp(markInk, other.markInk, t)!,
      guardMark: Color.lerp(guardMark, other.guardMark, t)!,
      skies: {for (final s in Session.values) s: skies[s]!.lerp(other.skies[s]!, t)},
      grounds: {for (final s in Session.values) s: Color.lerp(grounds[s], other.grounds[s], t)!},
      outcomes: {for (final o in outcomes.keys) o: outcomes[o]!.lerp(other.outcomes[o]!, t)},
      links: [
        for (var i = 0; i < links.length; i++) i < other.links.length ? links[i].lerp(other.links[i], t) : links[i],
      ],
    );
  }
}
