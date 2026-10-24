import 'package:flutter/material.dart';

import '../../design/design.dart';
import 'parts.dart';

/// Onboarding, step 1 of 6: Welcome (design report 4.1). Peek's first
/// appearance, standing behind the horizon in the morning sky: the base
/// pose, floating gently and blinking, its limbs clear of its body like
/// the orange robot's, its silhouette as bold as a sticker. The report's
/// copy, one primary action, and the demo escape for judges. For the
/// review only.
class OnboardingPreviewScreen extends StatelessWidget {
  const OnboardingPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    return Column(
      children: [
        const StatusBar(time: '05:02'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(CurreSpace.gutter, CurreSpace.s3, CurreSpace.gutter, CurreSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('1 / 6', style: t.meta),
                const SizedBox(height: CurreSpace.s3),
                LayoutBuilder(
                  builder: (context, box) => SizedBox(
                    height: 340,
                    child: SkyScene(
                      session: Session.morning,
                      horizon: .8,
                      sunAt: .5,
                      sunSize: (box.maxWidth * .52).clamp(150.0, 184.0),
                      sunRise: .9,
                      animatePeek: true,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text('curre', style: t.display),
                const SizedBox(height: CurreSpace.s2),
                Text(
                  'Only the apps you said you need, opened at the task.',
                  style: t.body.copyWith(fontSize: 18, height: 26 / 18, color: c.ink2),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(CurreSpace.gutter, 0, CurreSpace.gutter, CurreSpace.s2),
          child: Column(
            children: [
              PrimaryPill(label: 'Set up Curre', glyph: CurreGlyphKind.go),
              SizedBox(height: CurreSpace.s3),
              SecondaryPill(label: 'Try the gate first · demo'),
            ],
          ),
        ),
        const GestureBar(),
      ],
    );
  }
}
