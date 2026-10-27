import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';

/// The Later shelf under a new plan: what the user saved with "Not now"
/// that fits this plan, best match first, each a door into its app at the
/// saved words. Calm and still, like the rest of the plan's confirmation.
class LaterShelfCard extends StatelessWidget {
  const LaterShelfCard({
    super.key,
    required this.controller,
    required this.shelf,
    required this.onOpen,
    required this.onDismiss,
  });

  final CurreController controller;
  final LaterShelf shelf;
  final ValueChanged<LaterItem> onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final doors = shelf.doors;
    return DecoratedBox(
      key: const Key('later-shelf'),
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: CurreShape.md,
        border: Border.all(color: colors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CurreGlyph(
                  CurreGlyphKind.later,
                  size: 22,
                  color: colors.emberText,
                ),
                const SizedBox(width: CurreSpace.s2),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text('Saved for later', style: type.title),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CurreSpace.s1),
            Text(
              doors.isEmpty
                  ? 'Nothing you saved fits this plan, so it waits for a better time.'
                  : shelf.ranked
                  ? 'Best match for this plan first.'
                  : 'Newest first.',
              style: type.caption.copyWith(color: colors.ink2),
            ),
            for (final item in doors) ...[
              const SizedBox(height: CurreSpace.s2),
              DoorRow(
                key: ValueKey('later-${item.id}'),
                appName:
                    controller.appFor(item.packageName)?.label ?? item.appLabel,
                destination: '→ ${controller.laterDestination(item)}',
                appIcon: InstalledAppIcon(
                  controller: controller,
                  packageName: item.packageName,
                ),
                semanticLabel:
                    '${item.appLabel}, saved for later: ${item.reason}. Opens ${controller.laterDestination(item)}',
                onTap: () => onOpen(item),
              ),
            ],
            if (doors.isNotEmpty && shelf.waiting > 0) ...[
              const SizedBox(height: CurreSpace.s2),
              Text(
                shelf.waiting == 1
                    ? '1 more keeps for another time.'
                    : '${shelf.waiting} more keep for another time.',
                style: type.meta,
              ),
            ],
            if (doors.isNotEmpty) ...[
              const SizedBox(height: CurreSpace.s3),
              CurreSecondaryButton(label: 'Not today', onPressed: onDismiss),
            ],
          ],
        ),
      ),
    );
  }
}
