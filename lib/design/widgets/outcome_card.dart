import 'package:flutter/material.dart';

import '../curre_colors.dart';
import '../curre_tokens.dart';
import '../curre_type.dart';
import 'curre_glyph.dart';

CurreGlyphKind _glyphFor(Outcome o) => switch (o) {
  Outcome.open => CurreGlyphKind.door,
  Outcome.later => CurreGlyphKind.later,
  Outcome.specify => CurreGlyphKind.editSpecify,
  Outcome.flagged => CurreGlyphKind.guardFlagged,
  Outcome.unavailable => CurreGlyphKind.unavailable,
};

/// Spoken label for the outcome glyph (TalkBack).
String outcomeGlyphLabel(Outcome o) => switch (o) {
  Outcome.open => 'Opens',
  Outcome.later => 'Saved for later',
  Outcome.specify => 'Needs more detail',
  Outcome.flagged => 'Flagged',
  Outcome.unavailable => 'Unavailable',
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
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CurreGlyph(
                  _glyphFor(outcome),
                  size: 22,
                  color: pair.fg,
                  semanticLabel: outcomeGlyphLabel(outcome),
                ),
                const SizedBox(width: CurreSpace.s2),
                Expanded(
                  child: Text(headline, style: t.title.copyWith(color: pair.fg)),
                ),
              ],
            ),
            if (body != null) ...[
              const SizedBox(height: CurreSpace.s2),
              Text(body!, style: t.body.copyWith(color: pair.fg)),
            ],
            if (child != null) ...[
              const SizedBox(height: CurreSpace.s3),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}
