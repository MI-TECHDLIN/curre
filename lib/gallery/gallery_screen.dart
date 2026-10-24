import 'package:flutter/material.dart';

import '../design/design.dart';

/// A debug-only gallery of every design-foundation token and widget, shown
/// in light and dark side by side regardless of the device's own theme
/// setting. This is a temporary home for the widgets while Home, check-in
/// and the gate are built — not a real screen.
class DesignGalleryScreen extends StatelessWidget {
  const DesignGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Curre design gallery')),
      body: ListView(
        padding: const EdgeInsets.all(CurreSpace.gutter),
        children: const [
          _SectionHeading('Colour'),
          _ColorTokens(),
          _SectionGap(),
          _SectionHeading('Skies'),
          _Skies(),
          _SectionGap(),
          _SectionHeading('Outcome tints'),
          _OutcomeTints(),
          _SectionGap(),
          _SectionHeading('Type voices'),
          _TypeVoices(),
          _SectionGap(),
          _SectionHeading('Spacing'),
          _Spacing(),
          _SectionGap(),
          _SectionHeading('Radius'),
          _Shapes(),
          _SectionGap(),
          _SectionHeading('Motion durations'),
          _Motion(),
          _SectionGap(),
          _SectionHeading('CurreGlyph'),
          _Glyphs(),
          _SectionGap(),
          _SectionHeading('SpanText (rune-safe highlights)'),
          _SpanTextDemo(),
          _SectionGap(),
          _SectionHeading('DoorRow'),
          _DoorRows(),
          _SectionGap(),
          _SectionHeading('HorizonLine'),
          _HorizonLines(),
          _SectionGap(),
          _SectionHeading('OutcomeCard'),
          _OutcomeCards(),
          _SectionGap(),
          _SectionHeading('KindChip'),
          _KindChips(),
          _SectionGap(),
          _SectionHeading('RisingDisc'),
          _RisingDiscDemo(),
          _SectionGap(),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CurreSpace.s3),
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}

class _SectionGap extends StatelessWidget {
  const _SectionGap();
  @override
  Widget build(BuildContext context) => const SizedBox(height: CurreSpace.s10);
}

/// Renders [builder] twice — once under the light theme, once under dark —
/// side by side, so a reviewer sees both without touching the device
/// theme setting.
class _DualTheme extends StatelessWidget {
  const _DualTheme({required this.builder});
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _ThemedPane(brightness: Brightness.light, builder: builder)),
        const SizedBox(width: CurreSpace.s4),
        Expanded(child: _ThemedPane(brightness: Brightness.dark, builder: builder)),
      ],
    );
  }
}

class _ThemedPane extends StatelessWidget {
  const _ThemedPane({required this.brightness, required this.builder});
  final Brightness brightness;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final theme = curreTheme(brightness);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: CurreShape.md,
        border: Border.all(color: theme.extension<CurreColors>()!.hairline),
      ),
      child: Theme(
        data: theme,
        child: Padding(
          padding: const EdgeInsets.all(CurreSpace.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                brightness == Brightness.light ? 'Light' : 'Dark',
                style: theme.extension<CurreType>()!.meta,
              ),
              const SizedBox(height: CurreSpace.s2),
              Builder(builder: builder),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.label, required this.pair});
  final String label;
  final Pair pair;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<CurreType>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: CurreSpace.s2),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: pair.bg,
              borderRadius: CurreShape.xs,
              border: Border.all(color: pair.fg.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: Text('Aa', style: TextStyle(color: pair.fg, fontSize: 12)),
          ),
          const SizedBox(width: CurreSpace.s2),
          Expanded(child: Text(label, style: t.caption)),
        ],
      ),
    );
  }
}

class _ColorTokens extends StatelessWidget {
  const _ColorTokens();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        final c = Theme.of(context).extension<CurreColors>()!;
        final tokens = <String, Color>{
          'paper': c.paper,
          'raised': c.raised,
          'sunk': c.sunk,
          'ink': c.ink,
          'ink2': c.ink2,
          'ink3': c.ink3,
          'hairline': c.hairline,
          'ember': c.ember,
          'emberText': c.emberText,
          'marker': c.marker,
          'guardMark': c.guardMark,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final e in tokens.entries) _Swatch(label: e.key, pair: Pair(e.value, c.ink)),
          ],
        );
      },
    );
  }
}

class _Skies extends StatelessWidget {
  const _Skies();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        final c = Theme.of(context).extension<CurreColors>()!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final s in Session.values)
              _Swatch(label: s.name, pair: c.sky(s)),
          ],
        );
      },
    );
  }
}

class _OutcomeTints extends StatelessWidget {
  const _OutcomeTints();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        final c = Theme.of(context).extension<CurreColors>()!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final o in [Outcome.open, Outcome.specify, Outcome.flagged, Outcome.unavailable])
              _Swatch(label: o.name, pair: c.outcome(o, laterTarget: Session.evening)),
            _Swatch(
              label: 'later (borrows evening sky)',
              pair: c.outcome(Outcome.later, laterTarget: Session.evening),
            ),
          ],
        );
      },
    );
  }
}

class _TypeVoices extends StatelessWidget {
  const _TypeVoices();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        final t = Theme.of(context).extension<CurreType>()!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('curre', style: t.display),
            const SizedBox(height: CurreSpace.s2),
            Text('Why open Instagram now?', style: t.headline),
            const SizedBox(height: CurreSpace.s2),
            Text('Save for this evening', style: t.title),
            const SizedBox(height: CurreSpace.s2),
            Text("Say what you'll do and who or what it's for.", style: t.body),
            const SizedBox(height: CurreSpace.s2),
            Text('OPEN INSTAGRAM', style: t.label),
            const SizedBox(height: CurreSpace.s2),
            Text('Opens at Instagram → Messages', style: t.caption),
            const SizedBox(height: CurreSpace.s2),
            Text('23 apps out of sight', style: t.listItem),
            const SizedBox(height: CurreSpace.s2),
            Text('reply Ada about rehearsal', style: t.youLarge),
            const SizedBox(height: CurreSpace.s2),
            Text('just checking what Tolu posted', style: t.you),
            const SizedBox(height: CurreSpace.s2),
            Text('15 min to watch the capo tutorial', style: t.youSmall),
            const SizedBox(height: CurreSpace.s2),
            Text('0:47', style: t.figureXL),
            const SizedBox(height: CurreSpace.s2),
            Text('23', style: t.figure),
            const SizedBox(height: CurreSpace.s2),
            Text('target [20,33] → search', style: t.meta),
          ],
        );
      },
    );
  }
}

class _Spacing extends StatelessWidget {
  const _Spacing();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        final c = Theme.of(context).extension<CurreColors>()!;
        final t = Theme.of(context).extension<CurreType>()!;
        const steps = {
          's1': CurreSpace.s1, 's2': CurreSpace.s2, 's3': CurreSpace.s3, 's4': CurreSpace.s4,
          'gutter': CurreSpace.gutter, 's6': CurreSpace.s6, 's8': CurreSpace.s8,
          's10': CurreSpace.s10, 's12': CurreSpace.s12, 's16': CurreSpace.s16,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final e in steps.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: CurreSpace.s1),
                child: Row(
                  children: [
                    Container(width: e.value, height: 12, color: c.ember),
                    const SizedBox(width: CurreSpace.s2),
                    Text('${e.key} = ${e.value.toInt()} dp', style: t.caption),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Shapes extends StatelessWidget {
  const _Shapes();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        final c = Theme.of(context).extension<CurreColors>()!;
        final t = Theme.of(context).extension<CurreType>()!;
        Widget box(String label, BorderRadius radius) => Padding(
          padding: const EdgeInsets.only(bottom: CurreSpace.s2),
          child: Row(
            children: [
              Container(width: 48, height: 32, decoration: BoxDecoration(color: c.raised, borderRadius: radius, border: Border.all(color: c.hairline))),
              const SizedBox(width: CurreSpace.s2),
              Text(label, style: t.caption),
            ],
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            box('xs (6)', CurreShape.xs),
            box('md (16)', CurreShape.md),
            box('dome (24/10)', CurreShape.dome),
            box('sheet (24 top)', CurreShape.sheet),
          ],
        );
      },
    );
  }
}

class _Motion extends StatelessWidget {
  const _Motion();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        final t = Theme.of(context).extension<CurreType>()!;
        const rows = {
          'tap': CurreMotion.tap, 'quick': CurreMotion.quick, 'base': CurreMotion.base,
          'rise': CurreMotion.rise, 'set': CurreMotion.set, 'sky': CurreMotion.sky,
          'stagger': CurreMotion.stagger, 'tick': CurreMotion.tick,
          'countdown (linear)': CurreMotion.countdown,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final e in rows.entries)
              Text('${e.key}: ${e.value.inMilliseconds} ms', style: t.meta),
          ],
        );
      },
    );
  }
}

class _Glyphs extends StatelessWidget {
  const _Glyphs();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        final c = Theme.of(context).extension<CurreColors>()!;
        final t = Theme.of(context).extension<CurreType>()!;
        return Wrap(
          spacing: CurreSpace.s3,
          runSpacing: CurreSpace.s3,
          children: [
            for (final k in CurreGlyphKind.values)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CurreGlyph(k, size: 24, color: c.ink, semanticLabel: k.name),
                      const SizedBox(width: CurreSpace.s1),
                      CurreGlyph(k, size: 24, color: c.ink, filled: true, semanticLabel: k.name),
                    ],
                  ),
                  Text(k.name, style: t.meta),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _SpanTextDemo extends StatelessWidget {
  const _SpanTextDemo();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        final c = Theme.of(context).extension<CurreColors>()!;
        final t = Theme.of(context).extension<CurreType>()!;
        const text = '😀 reply Ada about rehearsal';
        // Code-point offsets: "😀" is 1 code point, " reply " is 7, "Ada" starts at 8.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SpanText(
              text,
              style: t.you,
              highlights: [
                SpanHighlight(8, 11, style: t.you.copyWith(backgroundColor: c.marker)),
                SpanHighlight(18, 28, style: t.you.copyWith(backgroundColor: c.marker)),
              ],
            ),
            const SizedBox(height: CurreSpace.s2),
            Text('non-Latin: "读書 reply" highlighted on 读書', style: t.meta),
            SpanText(
              '读書 reply',
              style: t.you,
              highlights: const [],
            ),
          ],
        );
      },
    );
  }
}

class _DoorRows extends StatelessWidget {
  const _DoorRows();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        final t = Theme.of(context).extension<CurreType>()!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DoorRow(
              appName: 'YouTube',
              destination: 'Search "G chord"',
              destinationHighlights: [SpanHighlight(8, 16, style: t.youSmall)],
            ),
            DoorRow(
              appName: 'Spotify',
              destination: 'Search "worship"',
              destinationHighlights: [SpanHighlight(8, 17, style: t.youSmall)],
            ),
            const DoorRow(appName: 'Instagram', destination: 'Messages → Ada'),
          ],
        );
      },
    );
  }
}

class _HorizonLines extends StatelessWidget {
  const _HorizonLines();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        final t = Theme.of(context).extension<CurreType>()!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('still', style: t.meta),
            const HorizonLine(),
            const SizedBox(height: CurreSpace.s4),
            Text('scanning', style: t.meta),
            const HorizonLine(scanning: true, semanticLabel: 'Reading your reason'),
          ],
        );
      },
    );
  }
}

class _OutcomeCards extends StatelessWidget {
  const _OutcomeCards();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        return const Column(
          children: [
            OutcomeCard(
              outcome: Outcome.open,
              headline: 'YouTube → Search "capo tutorial"',
              body: '15 min because you said 15 min',
            ),
            SizedBox(height: CurreSpace.s3),
            OutcomeCard(
              outcome: Outcome.later,
              laterTarget: Session.evening,
              headline: 'Not now. Save it for this evening?',
              body: "It'll be waiting at your 17:00 check-in.",
            ),
            SizedBox(height: CurreSpace.s3),
            OutcomeCard(
              outcome: Outcome.specify,
              headline: 'What exactly will you do?',
              body: 'One more try, or wait 60 s.',
            ),
            SizedBox(height: CurreSpace.s3),
            OutcomeCard(
              outcome: Outcome.flagged,
              headline: 'This reason tried to steer the gate',
              body: 'Guard: instruction override',
            ),
            SizedBox(height: CurreSpace.s3),
            OutcomeCard(
              outcome: Outcome.unavailable,
              headline: 'No answer · Opening anyway, in a minute',
              body: "The gate didn't reply in 8 s. You may be offline.",
            ),
          ],
        );
      },
    );
  }
}

class _KindChips extends StatelessWidget {
  const _KindChips();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        return const Wrap(
          spacing: CurreSpace.s2,
          runSpacing: CurreSpace.s2,
          children: [
            KindChip(kind: ReasonKind.task, confidence: 0.94),
            KindChip(kind: ReasonKind.person, confidence: 0.88),
            KindChip(kind: ReasonKind.timeSensitive, confidence: 0.72),
            KindChip(kind: ReasonKind.browse, confidence: 0.81),
            KindChip(kind: ReasonKind.unclear),
          ],
        );
      },
    );
  }
}

class _RisingDiscDemo extends StatelessWidget {
  const _RisingDiscDemo();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        final t = Theme.of(context).extension<CurreType>()!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shortened to 6s here purely so the gallery shows visible
            // motion; the real override is 60 s (CurreMotion.countdown).
            const RisingDisc(duration: Duration(seconds: 6)),
            const SizedBox(height: CurreSpace.s2),
            Text('duration shortened for this gallery; default is 60 s, linear', style: t.meta),
          ],
        );
      },
    );
  }
}
