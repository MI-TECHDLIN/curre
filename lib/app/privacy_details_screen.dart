import 'package:flutter/material.dart';

import '../design/design.dart';
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
          const Padding(
            padding: EdgeInsets.fromLTRB(
              CurreSpace.gutter,
              CurreSpace.s3,
              CurreSpace.gutter,
              0,
            ),
            child: CurreTopBar(
              title: 'Privacy details',
              subtitle: 'What leaves this phone, and for how long.',
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(CurreSpace.gutter),
              children: [
                Text('What is read online', style: type.title),
                const SizedBox(height: CurreSpace.s2),
                Text(
                  'Your plan, app names, the reason you give for opening a hidden app and a note you send after a task are read online so Curre can answer you.',
                  style: type.body,
                ),
                const SizedBox(height: CurreSpace.s5),
                Text('How long a copy may remain', style: type.title),
                const SizedBox(height: CurreSpace.s2),
                Text(
                  'Curre keeps no online copy. The AI service that reads your words may keep a successful answer, including quoted words, for about a day so a retry can return the same answer. It then deletes that copy.',
                  style: type.body,
                ),
                const SizedBox(height: CurreSpace.s5),
                Text('What stays here', style: type.title),
                const SizedBox(height: CurreSpace.s2),
                Text(
                  'Your contacts, chat names, app use and history stay on this phone. You can clear plans, reasons and notes from Curre settings.',
                  style: type.body,
                ),
                const SizedBox(height: CurreSpace.s5),
                Text('What History hides', style: type.title),
                const SizedBox(height: CurreSpace.s2),
                Text(
                  'Before History saves a checked reason or note, Curre looks for names, phone numbers, email and address or payment details. What it finds becomes a label such as [name] or [phone]. If that check isn’t available, your words stay as they are.',
                  style: type.body,
                ),
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
                      'Curre records only whether a request worked and how long it took. It does not put your words in online logs.',
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
