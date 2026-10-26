import 'package:flutter/material.dart';

import '../curre_colors.dart';
import '../curre_tokens.dart';
import '../curre_type.dart';
import 'curre_glyph.dart';

/// The glyph each outcome carries. `later` shows the sky of the session
/// it can wait for (its card borrows that sky too), so the icon and the
/// colour say the same thing: "this evening".
CurreGlyphKind outcomeGlyph(Outcome o, {Session laterTarget = Session.evening}) => switch (o) {
  Outcome.open => CurreGlyphKind.door,
  Outcome.later => switch (laterTarget) {
    Session.morning => CurreGlyphKind.sessionMorning,
    Session.afternoon => CurreGlyphKind.sessionAfternoon,
    Session.evening => CurreGlyphKind.sessionEvening,
  },
  Outcome.specify => CurreGlyphKind.editSpecify,
  Outcome.flagged => CurreGlyphKind.guardFlagged,
  Outcome.unavailable => CurreGlyphKind.unavailable,
};

/// Spoken label for the outcome glyph (TalkBack).
String outcomeGlyphLabel(Outcome o) => switch (o) {
  Outcome.open => 'Opens',
  Outcome.later => 'Not now',
  Outcome.specify => 'Needs more detail',
  Outcome.flagged => 'Not a reason',
  Outcome.unavailable => 'Couldn’t check',
};

/// The unlock gate's outcome card (design report 4.6): a dome card in the
/// outcome's tint, carrying its glyph and headline, then an optional body
/// line and then any extra content (the Why quote and the actions) passed
/// as [child].
///
/// `later` has no tint of its own — it borrows the sky of the session it
/// saves to, so pass [laterTarget] when [outcome] is `Outcome.later`.
class OutcomeCard extends StatelessWidget {
  const OutcomeCard({
    super.key,
    required this.outcome,
    required this.headline,
    this.body,
    this.laterTarget = Session.evening,
    this.child,
  });

  final Outcome outcome;
  final String headline;
  final String? body;
  final Session laterTarget;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final pair = c.outcome(outcome, laterTarget: laterTarget);

    return DecoratedBox(
      decoration: BoxDecoration(color: pair.bg, borderRadius: CurreShape.dome),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(CurreSpace.s4, CurreSpace.s4, CurreSpace.s4, CurreSpace.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: pair.fg.withValues(alpha: .12), shape: BoxShape.circle),
                  child: CurreGlyph(
                    outcomeGlyph(outcome, laterTarget: laterTarget),
                    size: 20,
                    color: pair.fg,
                    semanticLabel: outcomeGlyphLabel(outcome),
                  ),
                ),
                const SizedBox(width: CurreSpace.s3),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      headline,
                      style: t.title.copyWith(color: pair.fg, fontSize: 20, height: 26 / 20),
                    ),
                  ),
                ),
              ],
            ),
            if (body != null) ...[
              const SizedBox(height: CurreSpace.s2),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(body!, style: t.body.copyWith(color: pair.fg.withValues(alpha: .86))),
              ),
            ],
            if (child != null) ...[const SizedBox(height: CurreSpace.s3), child!],
          ],
        ),
      ),
    );
  }
}
