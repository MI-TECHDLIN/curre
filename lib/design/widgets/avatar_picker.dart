import 'package:flutter/material.dart';

import '../curre_colors.dart';
import '../curre_tokens.dart';
import 'avatar.dart';
import 'curre_glyph.dart';

/// An accessible, controlled grid for choosing one of Curre's human avatars.
///
/// The caller owns [selectedAvatarId], which keeps persistence and sheet
/// lifecycle outside the design component. The grid grows with its content so
/// it can sit inside a profile sheet's scroll view without nested scrolling.
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.selectedAvatarId,
    required this.onSelected,
    this.options = AvatarCatalog.all,
    this.crossAxisCount,
    this.avatarSize = 72,
    this.motion = AvatarMotion.still,
  });

  final String? selectedAvatarId;
  final ValueChanged<String> onSelected;
  final List<AvatarOption> options;
  final int? crossAxisCount;
  final double avatarSize;
  final AvatarMotion motion;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inferredColumns = constraints.maxWidth < 300
            ? 2
            : constraints.maxWidth < 440
            ? 3
            : 4;
        final columns = crossAxisCount ?? inferredColumns;
        return Semantics(
          container: true,
          label: 'Choose a profile avatar',
          explicitChildNodes: true,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: CurreSpace.s2,
              mainAxisSpacing: CurreSpace.s2,
              mainAxisExtent: avatarSize + 24,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              return _AvatarChoice(
                option: option,
                selected: option.id == selectedAvatarId,
                avatarSize: avatarSize,
                motion: motion,
                onTap: () => onSelected(option.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.option,
    required this.selected,
    required this.avatarSize,
    required this.motion,
    required this.onTap,
  });

  final AvatarOption option;
  final bool selected;
  final double avatarSize;
  final AvatarMotion motion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: '${option.semanticLabel}${selected ? ', selected' : ''}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? c.ember.withValues(alpha: .10) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: CurreShape.md,
            side: BorderSide(
              color: selected ? c.ember : c.hairline,
              width: selected ? 2.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Avatar(
                      avatarId: option.id,
                      size: avatarSize,
                      motion: motion,
                    ),
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.ember,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: CurreGlyph(
                          CurreGlyphKind.check,
                          size: 13,
                          color: c.paper,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
