import 'dart:async';

import 'package:flutter/material.dart';

import '../design/design.dart';
import 'preview/avatar_review_panel.dart';
import 'preview/checkin_preview_screen.dart';
import 'preview/gate_preview_screen.dart';
import 'preview/home_preview_screen.dart';
import 'preview/onboarding_preview_screen.dart';
import 'preview/parts.dart' show CheckinCard;
import 'preview/phone_frame.dart';
import 'preview/plan_sample.dart';
import 'preview/reveal_preview_screen.dart';
import 'preview/streak_moment.dart';

/// A debug-only gallery of the design foundation, shown in light and dark
/// side by side whatever the device's own theme is. A temporary home for
/// the widgets while Home, check-in and the gate are built, not a real
/// screen.
///
/// It leads with real composed screens (the check-in modelled on the Mombo
/// reference first), then a detail pass at 360 dp with a long plan, then
/// the token and widget catalogue as an appendix.
class DesignGalleryScreen extends StatelessWidget {
  const DesignGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Curre design gallery')),
      body: ListView(
        padding: const EdgeInsets.all(CurreSpace.gutter),
        children: [
          const _SectionHeading('Human profile avatars'),
          const _Note(
            'Every face looks straight ahead. The same 12-person family is rendered in light and dark with the real picker, profile-button context and 32/40/96 dp checks.',
          ),
          const _DualTheme(stacked: true, builder: _buildAvatarReview),
          const _SectionGap(),
          const _SectionHeading('Screens'),
          const _Note(
            'Real Flutter screens built from the tokens and widgets in the appendix, for review. '
            'Not the production Home, check-in, gate or onboarding: those are a separate task.',
          ),
          const _SectionHeading('Check-in, at the start of a morning'),
          const _Note('Today’s water is still low: nothing has run yet.'),
          PhoneFramePair(builder: (context) => const CheckinPreviewScreen()),
          const _SectionGap(),
          const _SectionHeading('Check-in, the afternoon'),
          const _Note(
            'The morning’s two doors filled a third of the day; the water rises to it as the card opens.',
          ),
          PhoneFramePair(
            builder: (context) =>
                const CheckinPreviewScreen(session: Session.afternoon),
          ),
          const _SectionGap(),
          const _SectionHeading('Check-in, the evening'),
          PhoneFramePair(
            builder: (context) =>
                const CheckinPreviewScreen(session: Session.evening),
          ),
          const _SectionGap(),
          const _SectionHeading('Check-in, what Curre read'),
          PhoneFramePair(builder: (context) => const RevealPreviewScreen()),
          const _SectionGap(),
          const _SectionHeading('Home, with a plan'),
          PhoneFramePair(builder: (context) => const HomePreviewScreen()),
          const _SectionGap(),
          const _SectionHeading('Unlock gate, opens for a person'),
          PhoneFramePair(builder: (context) => const GatePreviewScreen()),
          const _SectionGap(),
          const _SectionHeading('Unlock gate, the 60-second wait'),
          PhoneFramePair(builder: (context) => const WaitPreviewScreen()),
          const _SectionGap(),
          const _SectionHeading('Onboarding, step 1 of 6'),
          PhoneFramePair(builder: (context) => const OnboardingPreviewScreen()),
          const _SectionGap(),
          const _SectionHeading('Prooflight moment, today’s sun rises'),
          const _Note(
            'Plays, holds, rests and replays. Duolingo’s rhythm, Curre’s own sun, with no face.',
          ),
          PhoneFramePair(builder: (context) => const StreakMomentScreen()),
          const _SectionGap(),
          const _SectionHeading('Detail pass: 360 dp, a long plan'),
          const _Note(
            'Four doors, long app names and long search words on a narrow phone.',
          ),
          PhoneFramePair(
            size: PhoneFrame.narrowSize,
            builder: (context) => const HomePreviewScreen(plan: longPlan),
          ),
          const SizedBox(height: CurreSpace.s4),
          PhoneFramePair(
            size: PhoneFrame.narrowSize,
            builder: (context) => const RevealPreviewScreen(plan: longPlan),
          ),
          const SizedBox(height: CurreSpace.s4),
          PhoneFramePair(
            size: PhoneFrame.narrowSize,
            builder: (context) => const CheckinPreviewScreen(),
          ),
          const _SectionGap(),
          const Divider(),
          const _SectionGap(),
          const _SectionHeading('Appendix: tokens'),
          const _SectionHeading('Colour'),
          const _ColorTokens(),
          const _SectionGap(),
          const _SectionHeading('Session skies, grounds and water'),
          const _Skies(),
          const _SectionGap(),
          const _SectionHeading('Outcome tints'),
          const _OutcomeTints(),
          const _SectionGap(),
          const _SectionHeading('Link tints'),
          const _LinkTints(),
          const _SectionGap(),
          const _SectionHeading('Type voices'),
          const _TypeVoices(),
          const _SectionGap(),
          const _SectionHeading('Spacing'),
          const _Spacing(),
          const _SectionGap(),
          const _SectionHeading('Radius'),
          const _Shapes(),
          const _SectionGap(),
          const _SectionHeading('Motion durations'),
          const _Motion(),
          const _SectionGap(),
          const _SectionHeading('Appendix: widgets'),
          const _SectionHeading('CurreGlyph (Solar Bold)'),
          const _Glyphs(),
          const _SectionGap(),
          const _SectionHeading('SpanText (rune-safe highlights)'),
          const _SpanTextDemo(),
          const _SectionGap(),
          const _SectionHeading('DoorRow'),
          const _DoorRows(),
          const _SectionGap(),
          const _SectionHeading('HorizonLine'),
          const _HorizonLines(),
          const _SectionGap(),
          const _SectionHeading('SkyScene'),
          const _SkyScenes(),
          const _SectionGap(),
          const _SectionHeading('OutcomeCard'),
          const _OutcomeCards(),
          const _SectionGap(),
          const _SectionHeading('KindChip'),
          const _KindChips(),
          const _SectionGap(),
          const _SectionHeading('RisingDisc'),
          const _RisingDiscDemo(),
          const _SectionGap(),
          const _SectionHeading('PeekMascot'),
          const _PeekMascotDemo(),
          const _SectionGap(),
          const _SectionHeading('CurrePropArt (Fluent Emoji, outlined)'),
          const _Note(
            'Onboarding’s scene props: Microsoft’s Fluent Emoji Flat artwork (MIT), drawn as vectors with the avatars’ ink outline.',
          ),
          const _PropsDemo(),
          const _SectionGap(),
          const _SectionHeading('AvatarFigure'),
          const _Note(
            'A catalogue face on a body, for scenes: relaxed, waving, holding a phone, and the initial fallback.',
          ),
          const _FiguresDemo(),
          const _SectionGap(),
          const _SectionHeading('Scene kit'),
          const _Note(
            'Grain, a blob, a sticker card and a phone: the flat layers onboarding’s stages are built from.',
          ),
          const _SceneKitDemo(),
          const _SectionGap(),
          const _SectionHeading('LiveSky'),
          const _LiveSkies(),
          const _SectionGap(),
          const _SectionHeading('RisingWater'),
          const _RisingWaterDemo(),
          const _SectionGap(),
          const _SectionHeading('Prooflight'),
          const _ProoflightDemo(),
          const _SectionGap(),
        ],
      ),
    );
  }
}

Widget _buildAvatarReview(BuildContext context) => const AvatarReviewPanel();

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CurreSpace.s3),
      child: Text(text),
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
  const _DualTheme({required this.builder, this.stacked = false});
  final WidgetBuilder builder;

  /// True stacks the light and dark panes full-width, one above the other,
  /// instead of side by side. Use for content too wide for a half-screen
  /// column (e.g. KindChip's confidence meter + label).
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ThemedPane(brightness: Brightness.light, builder: builder),
          const SizedBox(height: CurreSpace.s3),
          _ThemedPane(brightness: Brightness.dark, builder: builder),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ThemedPane(brightness: Brightness.light, builder: builder),
        ),
        const SizedBox(width: CurreSpace.s4),
        Expanded(
          child: _ThemedPane(brightness: Brightness.dark, builder: builder),
        ),
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
            for (final e in tokens.entries)
              // Highlighter marks always carry mark ink, in both themes.
              _Swatch(
                label: e.key,
                pair: Pair(
                  e.value,
                  e.key == 'marker' || e.key == 'guardMark' ? c.markInk : c.ink,
                ),
              ),
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
            for (final s in Session.values) ...[
              _Swatch(label: '${s.name} sky + on-sky', pair: c.sky(s)),
              _Swatch(
                label: '${s.name} ground',
                pair: Pair(c.ground(s), c.sky(s).fg),
              ),
              _Swatch(label: '${s.name} water + crest', pair: c.water(s)),
            ],
          ],
        );
      },
    );
  }
}

class _LinkTints extends StatelessWidget {
  const _LinkTints();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        final c = Theme.of(context).extension<CurreColors>()!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var n = 1; n <= c.links.length; n++) ...[
              _Swatch(
                label: 'link $n mark (words)',
                pair: Pair(c.link(n).mark, c.markInk),
              ),
              _Swatch(label: 'link $n door card', pair: c.link(n).card),
            ],
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
            for (final o in [
              Outcome.open,
              Outcome.specify,
              Outcome.flagged,
              Outcome.unavailable,
            ])
              _Swatch(
                label: o.name,
                pair: c.outcome(o, laterTarget: Session.evening),
              ),
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
            Text('Hidden apps · 23', style: t.listItem),
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
          's1': CurreSpace.s1,
          's2': CurreSpace.s2,
          's3': CurreSpace.s3,
          's4': CurreSpace.s4,
          's5 (gutter)': CurreSpace.s5,
          's6': CurreSpace.s6,
          's8': CurreSpace.s8,
          's10': CurreSpace.s10,
          's12': CurreSpace.s12,
          's16': CurreSpace.s16,
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
              Container(
                width: 48,
                height: 32,
                decoration: BoxDecoration(
                  color: c.raised,
                  borderRadius: radius,
                  border: Border.all(color: c.hairline),
                ),
              ),
              const SizedBox(width: CurreSpace.s2),
              Text(label, style: t.caption),
            ],
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            box('xs (6)', CurreShape.xs),
            box('md (20)', CurreShape.md),
            box('lg (28)', CurreShape.lg),
            box('dome (28/12)', CurreShape.dome),
            box('sheet (28 top)', CurreShape.sheet),
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
          'tap': CurreMotion.tap,
          'quick': CurreMotion.quick,
          'base': CurreMotion.base,
          'rise': CurreMotion.rise,
          'set': CurreMotion.set,
          'sky': CurreMotion.sky,
          'stagger': CurreMotion.stagger,
          'tick': CurreMotion.tick,
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
      stacked: true,
      builder: (context) {
        final c = Theme.of(context).extension<CurreColors>()!;
        final t = Theme.of(context).extension<CurreType>()!;
        return Wrap(
          spacing: CurreSpace.s2,
          runSpacing: CurreSpace.s3,
          children: [
            for (final k in CurreGlyphKind.values)
              SizedBox(
                width: 136,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CurreGlyph(
                      k,
                      size: 28,
                      color: c.ink,
                      semanticLabel: k.name,
                    ),
                    const SizedBox(height: CurreSpace.s1),
                    Text(
                      k.name,
                      style: t.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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
        const emoji = '😀 reply Ada about rehearsal';
        const nonLatin = '读書 then reply Ada';
        TextStyle mark(int n) =>
            t.you.copyWith(backgroundColor: c.link(n).mark, color: c.markInk);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('emoji first: "Ada" is code points 8–11', style: t.meta),
            SpanText(
              emoji,
              style: t.you,
              highlights: [
                SpanHighlight(8, 11, style: mark(1)),
                SpanHighlight(18, 27, style: mark(2)),
              ],
            ),
            const SizedBox(height: CurreSpace.s3),
            Text('non-Latin: "读書" is code points 0–2', style: t.meta),
            SpanText(
              nonLatin,
              style: t.you,
              highlights: [
                SpanHighlight(0, 2, style: mark(3)),
                SpanHighlight(14, 17, style: mark(1)),
              ],
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
        final c = Theme.of(context).extension<CurreColors>()!;
        TextStyle words(int n) =>
            t.youSmall.copyWith(fontSize: 16, color: c.link(n).card.fg);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DoorRow(
              appName: 'Spotify',
              destination: '→\u00A0Search “worship”',
            ),
            const SizedBox(height: CurreSpace.s2),
            DoorRow(
              appName: 'YouTube',
              destination: '→\u00A0Search “G chord”',
              link: 1,
              destinationHighlights: [SpanHighlight(9, 18, style: words(1))],
            ),
            const SizedBox(height: CurreSpace.s2),
            DoorRow(
              appName: 'Spotify',
              destination: '→\u00A0Search “worship”',
              link: 2,
              destinationHighlights: [SpanHighlight(9, 18, style: words(2))],
            ),
            const SizedBox(height: CurreSpace.s2),
            DoorRow(
              appName: 'Instagram',
              destination: '→\u00A0Messages · Ada',
              tint: c.outcome(Outcome.open, laterTarget: Session.evening),
              trailing: Text(
                '3:12',
                style: t.figure.copyWith(
                  color: c
                      .outcome(Outcome.open, laterTarget: Session.evening)
                      .fg,
                ),
              ),
            ),
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
            const SizedBox(height: CurreSpace.s2),
            const HorizonLine(),
            const SizedBox(height: CurreSpace.s4),
            Text('scanning (the only busy state)', style: t.meta),
            const SizedBox(height: CurreSpace.s2),
            const HorizonLine(
              scanning: true,
              semanticLabel: 'Reading your reason',
            ),
          ],
        );
      },
    );
  }
}

class _SkyScenes extends StatelessWidget {
  const _SkyScenes();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        final t = Theme.of(context).extension<CurreType>()!;
        final c = Theme.of(context).extension<CurreColors>()!;
        Widget scene(Session s, SkySun sun, String label) => Padding(
          padding: const EdgeInsets.only(bottom: CurreSpace.s2),
          child: SizedBox(
            height: 112,
            child: SkyScene(
              session: s,
              sun: sun,
              sunSize: sun == SkySun.disc ? 36 : 84,
              sunRise: sun == SkySun.disc ? .6 : .74,
              padding: const EdgeInsets.all(CurreSpace.s3),
              child: Text(label, style: t.caption.copyWith(color: c.sky(s).fg)),
            ),
          ),
        );
        return Column(
          children: [
            scene(Session.morning, SkySun.peek, 'morning · Peek (check-in)'),
            scene(Session.afternoon, SkySun.disc, 'afternoon · disc (Home)'),
            scene(Session.evening, SkySun.none, 'evening · no sun'),
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
              headline: 'Opens at YouTube\u00A0→\u00A0Search “capo tutorial”',
              body: '15 minutes, because you said 15 min',
            ),
            SizedBox(height: CurreSpace.s3),
            OutcomeCard(
              outcome: Outcome.later,
              laterTarget: Session.evening,
              headline: 'Not now',
              body: 'Sounds like browsing, so it can wait for a browsing time.',
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
              headline: 'No answer. Opening anyway, in a minute',
              body: 'The gate didn’t reply in 8 s. You may be offline.',
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
      stacked: true,
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
        final c = Theme.of(context).extension<CurreColors>()!;
        final sky = c.sky(Session.morning);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: CurreShape.md,
              child: ColoredBox(
                color: sky.bg,
                child: Padding(
                  padding: const EdgeInsets.only(top: CurreSpace.s4),
                  // Shortened to 6 s here so the gallery shows the rise;
                  // the real wait is 60 s (CurreMotion.countdown), linear.
                  child: LayoutBuilder(
                    builder: (context, box) => RisingDisc(
                      duration: const Duration(seconds: 6),
                      diameter: 48,
                      width: box.maxWidth,
                      lineColor: sky.fg,
                      groundColor: c.ground(Session.morning),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: CurreSpace.s2),
            Text('6 s here; the real wait is 60 s, linear', style: t.meta),
          ],
        );
      },
    );
  }
}

class _PeekMascotDemo extends StatelessWidget {
  const _PeekMascotDemo();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      stacked: true,
      builder: (context) {
        final t = Theme.of(context).extension<CurreType>()!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Wrap(
              spacing: CurreSpace.s6,
              runSpacing: CurreSpace.s4,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                PeekMascot(size: 120),
                PeekMascot(
                  size: 40,
                  compact: true,
                  animate: false,
                  groundShadow: false,
                ),
                PeekMascot(
                  size: 72,
                  animate: false,
                  lit: 0,
                  rays: 0,
                  eyesOpen: 0,
                ),
                PeekMascot(
                  size: 72,
                  animate: false,
                  lit: .6,
                  rays: .5,
                  eyesOpen: 0,
                ),
              ],
            ),
            const SizedBox(height: CurreSpace.s2),
            Text(
              'Base pose (floats and blinks) · small master · waking: dormant, half-lit. '
              'Check-in and onboarding only, never Home with a plan, never the gate.',
              style: t.meta,
            ),
          ],
        );
      },
    );
  }
}

class _LiveSkies extends StatelessWidget {
  const _LiveSkies();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      stacked: true,
      builder: (context) {
        final t = Theme.of(context).extension<CurreType>()!;
        return Column(
          children: [
            for (final s in Session.values) ...[
              SizedBox(
                height: 160,
                child: SkyScene(
                  session: s,
                  groundHeight: 40,
                  sunSize: 88,
                  sunAt: CheckinCard.peekPlace(s).$1,
                  sunRise: CheckinCard.peekPlace(s).$2,
                  live: true,
                  animatePeek: true,
                  keepClear: const Rect.fromLTWH(16, 16, 150, 20),
                  padding: const EdgeInsets.all(CurreSpace.s4),
                  child: Text(
                    switch (s) {
                      Session.morning => 'morning · first light',
                      Session.afternoon => 'afternoon · clear and bright',
                      Session.evening => 'evening · the blue hour',
                    },
                    style: t.caption.copyWith(
                      color: Theme.of(context)
                          .extension<CurreColors>()!
                          .sky(s)
                          .fg,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CurreSpace.s2),
            ],
          ],
        );
      },
    );
  }
}

/// Water that rises a step every few seconds, sloshing each time, then
/// drains back to start again.
class _RisingWaterDemo extends StatefulWidget {
  const _RisingWaterDemo();

  @override
  State<_RisingWaterDemo> createState() => _RisingWaterDemoState();
}

class _RisingWaterDemoState extends State<_RisingWaterDemo> {
  static const _steps = [0.0, 1 / 3, .56, 1.0];
  int _step = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (mounted) setState(() => _step = (_step + 1) % _steps.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        final c = Theme.of(context).extension<CurreColors>()!;
        final t = Theme.of(context).extension<CurreType>()!;
        final brightness = Theme.of(context).brightness;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final s in Session.values) ...[
              ClipRRect(
                borderRadius: CurreShape.md,
                child: ColoredBox(
                  color: c.ground(s),
                  child: SizedBox(
                    height: 64,
                    child: RisingWater(
                      level: _steps[_step],
                      style: SkyScene.waterStyle(c, brightness, s),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CurreSpace.s2),
            ],
            Text(
              'level ${(_steps[_step] * 100).round()}% · one input, rising with a slosh',
              style: t.meta,
            ),
          ],
        );
      },
    );
  }
}

class _ProoflightDemo extends StatelessWidget {
  const _ProoflightDemo();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      stacked: true,
      builder: (context) {
        final c = Theme.of(context).extension<CurreColors>()!;
        final t = Theme.of(context).extension<CurreType>()!;
        Widget sun(int rays, int days, String label) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProoflightSun(
              rays: rays,
              proofDays: days,
              size: 88,
              lineColor: c.ink,
            ),
            const SizedBox(height: CurreSpace.s1),
            Text(label, style: t.meta),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: CurreSpace.s4,
              runSpacing: CurreSpace.s3,
              children: [
                sun(0, 4, 'not yet today'),
                sun(1, 5, '1 proved task'),
                sun(3, 5, '3 proved tasks'),
                sun(3, 7, '7 days: sparks'),
                sun(4, 21, '21 days: a ring'),
                sun(5, 50, '50 days: two rings'),
              ],
            ),
            const SizedBox(height: CurreSpace.s4),
            const Wrap(
              spacing: CurreSpace.s6,
              runSpacing: CurreSpace.s3,
              children: [
                ProofDaysLabel(days: 4),
                ProofDaysLabel(days: 5, raysToday: 1),
                ProofDaysLabel(days: 12, raysToday: 2, cloudDay: true),
              ],
            ),
            const SizedBox(height: CurreSpace.s4),
            Row(
              children: [
                const CloudDayMark(label: '21'),
                const SizedBox(width: CurreSpace.s3),
                Expanded(
                  child: Text(
                    'A cloud day covers one empty day: it keeps the run and adds nothing.',
                    style: t.caption,
                  ),
                ),
              ],
            ),
            const SizedBox(height: CurreSpace.s4),
            // History's week: a note still waiting to be checked rings faintly,
            // and keeps today's label bold.
            const WeekStrip(
              days: [
                WeekDay('Sun', 18, DayState.quiet),
                WeekDay('Mon', 19, DayState.proof),
                WeekDay('Tue', 20, DayState.cloud),
                WeekDay('Wed', 21, DayState.proof),
                WeekDay('Thu', 22, DayState.proof),
                WeekDay('Fri', 23, DayState.proof),
                WeekDay('Sat', 24, DayState.pending, isToday: true),
              ],
            ),
            const SizedBox(height: CurreSpace.s4),
            const RunEndedNote(endedAt: 12, best: 12, total: 31),
          ],
        );
      },
    );
  }
}

class _PropsDemo extends StatelessWidget {
  const _PropsDemo();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) => Wrap(
        spacing: CurreSpace.s2,
        runSpacing: CurreSpace.s2,
        children: [
          for (final prop in CurreProp.values)
            Tooltip(
              message: prop.name,
              child: CurrePropArt(prop, size: 40, semanticLabel: prop.name),
            ),
        ],
      ),
    );
  }
}

class _FiguresDemo extends StatelessWidget {
  const _FiguresDemo();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      stacked: true,
      builder: (context) {
        final c = Theme.of(context).extension<CurreColors>()!;
        return Container(
          height: 170,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(color: c.sky(Session.afternoon).bg),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AvatarFigure(avatarId: 'avatar-01', height: 160),
              AvatarFigure(
                avatarId: 'avatar-03',
                height: 160,
                pose: FigurePose.wave,
              ),
              AvatarFigure(
                avatarId: 'avatar-09',
                height: 160,
                pose: FigurePose.phone,
              ),
              AvatarFigure(initial: 'Ada', height: 160),
            ],
          ),
        );
      },
    );
  }
}

class _SceneKitDemo extends StatelessWidget {
  const _SceneKitDemo();

  @override
  Widget build(BuildContext context) {
    return _DualTheme(
      builder: (context) {
        final c = Theme.of(context).extension<CurreColors>()!;
        final sky = c.sky(Session.morning);
        return SizedBox(
          height: 220,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: sky.bg)),
              Positioned.fill(
                child: SceneGrain(
                  dark: sky.fg.withValues(alpha: .06),
                  light: Colors.white.withValues(alpha: .16),
                ),
              ),
              Positioned(
                left: 10,
                top: 20,
                width: 160,
                height: 150,
                child: SceneBlob(color: Color.lerp(sky.bg, Colors.white, .3)!),
              ),
              const Positioned(
                left: 24,
                top: 40,
                child: SceneCard(
                  padding: EdgeInsets.all(12),
                  child: Text('A sticker card'),
                ),
              ),
              const Positioned(
                right: 16,
                top: 12,
                child: ScenePhone(
                  width: 92,
                  height: 180,
                  screen: Center(child: Text('Screen')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
