import 'package:flutter/material.dart';

import '../curre_colors.dart';
import '../curre_tokens.dart';
import '../curre_type.dart';
import 'curre_glyph.dart';
import 'span_text.dart';

/// A Home door row (design report 3.4 / differentiator §6.4): the app's
/// icon, its name, and the destination the tap actually opens, so you see
/// where a tap lands. Tapping opens the destination; long-pressing opens
/// the app normally (FR17/FR18), so both are separate callbacks.
///
/// [destinationHighlights] marks the user's own words inside
/// [destination] (code points, as [SpanText]), e.g. the search text.
///
/// With [link] set, the row becomes a door card in that link's colour,
/// the same colour that marks the words in the plan that put it here, and
/// shows the link number in a badge. Colour is never the only signal: the
/// number is always there too. [tint] instead fills the card with any pair
/// (a granted app uses the `open` outcome tint). With neither, it is a
/// plain row. [trailing] sits at the end (a grant's time left).
class DoorRow extends StatelessWidget {
  const DoorRow({
    super.key,
    required this.appName,
    required this.destination,
    this.appIcon,
    this.destinationHighlights = const [],
    this.link,
    this.tint,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
  });

  final String appName;
  final String destination;

  /// The installed app's own icon (from the platform channel), shown only
  /// above the horizon. Falls back to the door glyph when absent.
  final Widget? appIcon;

  final List<SpanHighlight> destinationHighlights;

  /// 1-based span/door link number, or null for an unlinked row.
  final int? link;

  /// Card fill and ink, overriding [link]'s colour.
  final Pair? tint;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final card = tint ?? (link != null ? c.link(link!).card : null);
    final fg = card?.fg ?? c.ink;
    final isCard = card != null;

    final row = Row(
      children: [
        SizedBox(
          width: CurreSpace.doorIcon,
          height: CurreSpace.doorIcon,
          child: appIcon ?? Center(child: CurreGlyph(CurreGlyphKind.door, size: 26, color: fg.withValues(alpha: .7))),
        ),
        const SizedBox(width: CurreSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                appName,
                style: t.label.weight(660).copyWith(color: fg, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              SpanText(
                destination,
                highlights: destinationHighlights,
                style: t.caption.copyWith(color: fg.withValues(alpha: .78), fontSize: 14, height: 20 / 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (link != null) ...[
          const SizedBox(width: CurreSpace.s2),
          _LinkBadge(number: link!, colors: c, onCard: isCard),
        ],
        if (trailing != null) ...[const SizedBox(width: CurreSpace.s2), trailing!],
      ],
    );

    return Semantics(
      button: true,
      label: semanticLabel ?? '$appName, opens $destination',
      excludeSemantics: true,
      child: Material(
        color: card?.bg ?? Colors.transparent,
        shape: isCard ? const RoundedRectangleBorder(borderRadius: CurreShape.md) : null,
        clipBehavior: isCard ? Clip.antiAlias : Clip.none,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          splashFactory: NoSplash.splashFactory,
          highlightColor: fg.withValues(alpha: .08),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: CurreSpace.doorRowMinHeight),
            child: Padding(
              padding: isCard
                  ? const EdgeInsets.fromLTRB(CurreSpace.s3, CurreSpace.s3, CurreSpace.s4, CurreSpace.s3)
                  : const EdgeInsets.symmetric(vertical: CurreSpace.s2),
              child: row,
            ),
          ),
        ),
      ),
    );
  }
}

/// The link number on a door card: white on a light pastel card, the
/// link's highlighter colour on a dark one, so it always reads as the same
/// mark as the highlighted words.
class _LinkBadge extends StatelessWidget {
  const _LinkBadge({required this.number, required this.colors, required this.onCard});

  final int number;
  final CurreColors colors;
  final bool onCard;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<CurreType>()!;
    final light = Theme.of(context).brightness == Brightness.light;
    final bg = light && onCard ? colors.raised : colors.link(number).mark;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text('$number', style: t.figure.copyWith(fontSize: 13, height: 1, color: colors.markInk)),
    );
  }
}
