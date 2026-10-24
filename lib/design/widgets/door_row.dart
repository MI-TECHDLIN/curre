import 'package:flutter/material.dart';

import '../curre_colors.dart';
import '../curre_tokens.dart';
import '../curre_type.dart';
import 'curre_glyph.dart';
import 'span_text.dart';

/// A Home door row (design report 3.4 / differentiator §6.4): the app's
/// icon, its name, and the destination the tap actually opens — "you see
/// where a tap lands". Tapping opens the destination; long-pressing opens
/// the app normally (FR17/FR18), so both are exposed as callbacks here
/// rather than baked into one `onTap`.
///
/// [destinationHighlights] marks the Extract span(s) inside [destination]
/// that this row's tap came from (e.g. the search text), so the row can
/// echo them in the user's own voice (Newsreader italic) the way the
/// check-in confirmation does.
class DoorRow extends StatelessWidget {
  const DoorRow({
    super.key,
    required this.appName,
    required this.destination,
    this.appIcon,
    this.destinationHighlights = const [],
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
  });

  final String appName;
  final String destination;

  /// The installed app's own icon (from the platform channel), shown only
  /// above the horizon. Falls back to a generic door glyph when absent —
  /// the gallery and tests have no platform channel to ask.
  final Widget? appIcon;

  final List<SpanHighlight> destinationHighlights;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;

    return Semantics(
      button: true,
      label: semanticLabel ?? '$appName, opens $destination',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          splashFactory: NoSplash.splashFactory,
          highlightColor: c.hairline.withValues(alpha: 0.4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: CurreSpace.doorRowMinHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: CurreSpace.s2),
              child: Row(
                children: [
                  SizedBox(
                    width: CurreSpace.doorIcon,
                    height: CurreSpace.doorIcon,
                    child: appIcon ??
                        Center(
                          child: CurreGlyph(
                            CurreGlyphKind.door,
                            size: 28,
                            color: c.ink2,
                            semanticLabel: null,
                          ),
                        ),
                  ),
                  const SizedBox(width: CurreSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          appName,
                          style: t.label.copyWith(fontWeight: FontWeight.w600, color: c.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        SpanText(
                          destination,
                          highlights: destinationHighlights,
                          style: t.caption.copyWith(color: c.ink2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
