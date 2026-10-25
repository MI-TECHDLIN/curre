import 'package:flutter/material.dart';

import '../../design/design.dart';

/// Review composition for the human avatar system. It shows the actual picker,
/// production sizes and the top-right profile-button context together.
class AvatarReviewPanel extends StatefulWidget {
  const AvatarReviewPanel({super.key});

  @override
  State<AvatarReviewPanel> createState() => _AvatarReviewPanelState();
}

class _AvatarReviewPanelState extends State<AvatarReviewPanel> {
  String? _selected = 'avatar-12';

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('In the profile button', style: t.label),
        const SizedBox(height: CurreSpace.s2),
        Container(
          constraints: const BoxConstraints(maxWidth: 390),
          padding: const EdgeInsets.all(CurreSpace.s3),
          decoration: BoxDecoration(
            color: c.raised,
            borderRadius: CurreShape.md,
            border: Border.all(color: c.hairline),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good morning', style: t.title),
                    const SizedBox(height: CurreSpace.s1),
                    Text(
                      'Saturday, 24 October',
                      style: t.caption.copyWith(color: c.ink3),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'Open profile',
                child: ExcludeSemantics(
                  child: SizedBox.square(
                    dimension: CurreSpace.touchTarget,
                    child: Center(
                      child: Avatar(
                        avatarId: _selected,
                        initial: 'C',
                        size: 40,
                        proofToday: true,
                        motion: AvatarMotion.reactOnce,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: CurreSpace.s4),
        Text('Crisp at production sizes', style: t.label),
        const SizedBox(height: CurreSpace.s2),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: CurreSpace.s4,
          runSpacing: CurreSpace.s3,
          children: [
            _SizeSample(
              label: '32 dp',
              avatar: Avatar(avatarId: _selected, initial: 'C', size: 32),
            ),
            _SizeSample(
              label: '40 dp',
              avatar: Avatar(avatarId: _selected, initial: 'C', size: 40),
            ),
            _SizeSample(
              label: '96 dp',
              avatar: Avatar(avatarId: _selected, initial: 'C', size: 96),
            ),
            const _SizeSample(
              label: 'fallback',
              avatar: Avatar(initial: 'C', size: 40),
            ),
            _SizeSample(
              label: 'proof today',
              avatar: Avatar(
                avatarId: _selected,
                initial: 'C',
                size: 40,
                proofToday: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: CurreSpace.s4),
        Text('Calm motion states', style: t.label),
        const SizedBox(height: CurreSpace.s2),
        Wrap(
          spacing: CurreSpace.s4,
          runSpacing: CurreSpace.s3,
          children: [
            _SizeSample(
              label: 'idle · blink + breathe',
              avatar: Avatar(
                avatarId: 'avatar-03',
                initial: 'C',
                size: 64,
                motion: AvatarMotion.idle,
              ),
            ),
            _SizeSample(
              label: 'happy · plays once',
              avatar: Avatar(
                avatarId: 'avatar-01',
                initial: 'C',
                size: 64,
                proofToday: true,
                motion: AvatarMotion.reactOnce,
              ),
            ),
            _SizeSample(
              label: 'sleepy evening',
              avatar: Avatar(
                avatarId: 'avatar-12',
                initial: 'C',
                size: 64,
                motion: AvatarMotion.idle,
                expression: AvatarExpression.sleepy,
              ),
            ),
          ],
        ),
        const SizedBox(height: CurreSpace.s4),
        Text('Choose your face', style: t.label),
        const SizedBox(height: CurreSpace.s1),
        Text(
          'Twelve unnamed, front-facing choices: a light-tone majority with four Black profiles, varied hair textures and playful headwear.',
          style: t.caption.copyWith(color: c.ink2),
        ),
        const SizedBox(height: CurreSpace.s3),
        AvatarPicker(
          selectedAvatarId: _selected,
          motion: AvatarMotion.idle,
          onSelected: (id) => setState(() => _selected = id),
        ),
      ],
    );
  }
}

class _SizeSample extends StatelessWidget {
  const _SizeSample({required this.label, required this.avatar});

  final String label;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<CurreType>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(height: CurreSpace.s1),
        Text(label, style: t.meta),
      ],
    );
  }
}
