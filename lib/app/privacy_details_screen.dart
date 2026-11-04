import 'package:flutter/material.dart';

import '../design/design.dart';
import '../l10n/l10n.dart';
import 'app_widgets.dart';

class PrivacyDetailsScreen extends StatelessWidget {
  const PrivacyDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return CurrePage(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CurreSpace.gutter,
              CurreSpace.s3,
              CurreSpace.gutter,
              0,
            ),
            child: CurreTopBar(
              title: context.l10n.privacyDetails,
              subtitle: context.l10n.privacySubtitle,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(CurreSpace.gutter),
              children: [
                Text(context.l10n.privacyReadOnline, style: type.title),
                const SizedBox(height: CurreSpace.s2),
                Text(context.l10n.privacyReadOnlineBody, style: type.body),
                const SizedBox(height: CurreSpace.s5),
                Text(context.l10n.privacyCopyTime, style: type.title),
                const SizedBox(height: CurreSpace.s2),
                Text(context.l10n.privacyCopyTimeBody, style: type.body),
                const SizedBox(height: CurreSpace.s5),
                Text(context.l10n.privacyStaysHere, style: type.title),
                const SizedBox(height: CurreSpace.s2),
                Text(context.l10n.privacyStaysHereBody, style: type.body),
                const SizedBox(height: CurreSpace.s5),
                Text(context.l10n.privacyHistoryHides, style: type.title),
                const SizedBox(height: CurreSpace.s2),
                Text(context.l10n.privacyHistoryHidesBody, style: type.body),
                const SizedBox(height: CurreSpace.s5),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.raised,
                    borderRadius: CurreShape.md,
                    border: Border.all(color: colors.hairline),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(CurreSpace.s4),
                    child: Text(
                      context.l10n.privacyLogs,
                      style: type.caption.copyWith(color: colors.ink2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
