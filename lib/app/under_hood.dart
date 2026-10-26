import 'package:flutter/material.dart';

import '../design/design.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';

Future<void> showUnderTheHood(
  BuildContext context,
  CurreController controller,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => _UnderTheHoodSheet(controller: controller),
);

class _UnderTheHoodSheet extends StatelessWidget {
  const _UnderTheHoodSheet({required this.controller});

  final CurreController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return DraggableScrollableSheet(
      initialChildSize: .78,
      minChildSize: .45,
      maxChildSize: .94,
      expand: false,
      builder: (context, scrollController) => DecoratedBox(
        decoration: BoxDecoration(
          color: colors.raised,
          borderRadius: CurreShape.sheet,
          boxShadow: CurreElevation.e2,
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(CurreSpace.s5),
          children: [
            Row(
              children: [
                CurreGlyph(
                  CurreGlyphKind.underTheHood,
                  color: colors.emberText,
                ),
                const SizedBox(width: CurreSpace.s3),
                Expanded(child: Text('Under the hood', style: type.title)),
                RoundGlyphButton(
                  glyph: CurreGlyphKind.close,
                  label: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: CurreSpace.s4),
            Text(
              'Curre sends one Pipeline call per decision. The phone owns every visibility change and resolves the final door locally.',
              style: type.body.copyWith(color: colors.ink2),
            ),
            const SizedBox(height: CurreSpace.s5),
            const _Endpoint(
              method: 'POST',
              path: '/v1/plan',
              detail: 'Fill chooses apps and shortcut labels · Extract marks query and end-time spans.',
            ),
            const _Endpoint(
              method: 'POST',
              path: '/v1/unlock',
              detail: 'Guard → Decide kind and door → Extract who, what and minutes.',
            ),
            const _Endpoint(
              method: 'POST',
              path: '/v1/proof',
              detail: 'Guard → Decide specific completion at 0.75 → Extract result or learning.',
            ),
            const SizedBox(height: CurreSpace.s5),
            Text('Last calls', style: type.label),
            const SizedBox(height: CurreSpace.s2),
            _Receipt(label: 'Plan', receipt: controller.lastPlanCall),
            const SizedBox(height: CurreSpace.s2),
            _Receipt(label: 'Unlock', receipt: controller.lastUnlockCall),
            const SizedBox(height: CurreSpace.s2),
            _Receipt(label: 'Proof', receipt: controller.lastProofCall),
            const SizedBox(height: CurreSpace.s5),
            Text('Door resolution · on this phone', style: type.label),
            const SizedBox(height: CurreSpace.s2),
            Text(
              'Conversation shortcut → verified query link → chosen app shortcut → plain launch. Model output never chooses a URL.',
              style: type.body.copyWith(color: colors.ink2),
            ),
            const SizedBox(height: CurreSpace.s4),
            DecoratedBox(
              decoration: BoxDecoration(
                color: controller.backendConfigured
                    ? colors.marker
                    : colors.sunk,
                borderRadius: CurreShape.md,
              ),
              child: Padding(
                padding: const EdgeInsets.all(CurreSpace.s4),
                child: Text(
                  controller.backendConfigured
                      ? 'Backend configured from CURRE_API_BASE_URL and CURRE_APP_KEY.'
                      : 'Offline mode: add CURRE_API_BASE_URL and CURRE_APP_KEY with --dart-define. Check-ins use the local checklist, unlocks keep the 60-second override, and completion notes wait on their original day.',
                  style: type.caption.copyWith(
                    color: controller.backendConfigured
                        ? colors.markInk
                        : colors.ink2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({
    required this.method,
    required this.path,
    required this.detail,
  });

  final String method;
  final String path;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: CurreSpace.s3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.paper,
          borderRadius: CurreShape.md,
          border: Border.all(color: colors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(CurreSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$method  $path',
                style: type.figure.copyWith(color: colors.emberText),
              ),
              const SizedBox(height: CurreSpace.s2),
              Text(detail, style: type.body.copyWith(color: colors.ink2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt({required this.label, required this.receipt});

  final String label;
  final CallReceipt? receipt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final value = receipt;
    return Row(
      children: [
        SizedBox(width: 72, child: Text(label, style: type.caption)),
        Expanded(
          child: Text(
            value == null
                ? 'No call yet'
                : '${value.elapsed.inMilliseconds} ms · ${value.usage?.modelMilliseconds.round() ?? '—'} model ms · ${value.usage?.credits ?? '—'} credits',
            style: type.meta.copyWith(color: colors.ink2),
          ),
        ),
      ],
    );
  }
}
