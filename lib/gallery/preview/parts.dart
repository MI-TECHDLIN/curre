import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../design/design.dart';

// Shared parts for the review-only screen previews. Every measure sits on
// the 4 dp grid, every tappable thing is at least 48 dp, and every row
// that holds text can shrink to a 360 dp phone without overflowing.

/// Code-point span of [phrase] inside [text] (the offsets Clocked's Extract
/// returns), found by search so preview copy can change without hand-
/// counted offsets.
(int, int) spanOf(String text, String phrase) {
  final i = text.indexOf(phrase);
  assert(i >= 0, '"$phrase" is not in "$text"');
  final start = text.substring(0, i).runes.length;
  return (start, start + phrase.runes.length);
}

/// A fake phone status bar: the time Curre's session logic runs on, and
/// three quiet marks.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.time, this.color});

  final String time;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final ink = color ?? c.ink;
    return SizedBox(
      height: 36,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Row(
          children: [
            Text(time, style: t.label.weight(620).copyWith(fontSize: 14, color: ink)),
            const Spacer(),
            for (final h in const [4.0, 6.0, 8.0, 10.0])
              Container(
                width: 3,
                height: h,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(1.5)),
              ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 11,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(color: ink.withValues(alpha: .5), width: 1),
                borderRadius: BorderRadius.circular(3.5),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: .72,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(1.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The gesture-navigation handle at the foot of an Android screen.
class GestureBar extends StatelessWidget {
  const GestureBar({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    return SizedBox(
      height: 20,
      child: Center(
        child: Container(
          width: 108,
          height: 4,
          decoration: BoxDecoration(
            color: (color ?? c.ink).withValues(alpha: .85),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// A 48 dp round button carrying one glyph.
class RoundGlyphButton extends StatelessWidget {
  const RoundGlyphButton({
    super.key,
    required this.glyph,
    required this.semanticLabel,
    this.background,
    this.foreground,
    this.outlined = true,
  });

  final CurreGlyphKind glyph;
  final String semanticLabel;
  final Color? background;
  final Color? foreground;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: background ?? c.raised,
          shape: CircleBorder(side: outlined ? BorderSide(color: c.hairline) : BorderSide.none),
        ),
        child: CurreGlyph(glyph, size: 24, color: foreground ?? c.ink),
      ),
    );
  }
}

/// The session greeting, after the Mombo and "Morning, Budi" references:
/// a big friendly line, the date, and one round button.
class Greeting extends StatelessWidget {
  const Greeting({super.key, required this.title, required this.subtitle, this.trailing});

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.headline, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: t.body.copyWith(color: c.ink2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: CurreSpace.s3), trailing!],
      ],
    );
  }
}

/// How a day reads in the [WeekStrip].
enum DayState {
  /// That day's plan was kept: a sun rose (ember).
  kept,

  /// A past day without a kept plan: plain. Never red, never crossed out.
  quiet,

  /// Today, still open: the session's sky, as the check-in card is.
  today,

  /// A day still to come.
  future,
}

@immutable
class WeekDay {
  const WeekDay(this.label, this.date, this.state);

  final String label;
  final int date;
  final DayState state;
}

/// The Mombo week strip, carrying Curre's streak: past days whose plan
/// was kept are lit ember (a sun rose), today wears the session's sky
/// like the check-in card below it, and a quiet day is simply unlit.
/// [todayLit] (0–1) turns today from open to kept, for the moment a plan
/// is kept. Display only in core: the days are not buttons.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.days, this.session = Session.morning, this.todayLit = 0});

  final List<WeekDay> days;
  final Session session;
  final double todayLit;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final sky = c.sky(session);
    return LayoutBuilder(
      builder: (context, box) {
        final col = box.maxWidth / days.length;
        final d = (col - 6).clamp(36.0, 44.0);
        return Row(
          children: [
            for (final day in days)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      day.label,
                      style: t.caption
                          .copyWith(color: day.state == DayState.today ? c.ink : c.ink3)
                          .weight(day.state == DayState.today ? 700 : 520),
                    ),
                    const SizedBox(height: 8),
                    _DayDot(
                      day: day,
                      diameter: d,
                      colors: c,
                      type: t,
                      sky: sky,
                      lit: day.state == DayState.today ? todayLit : 0,
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

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.day,
    required this.diameter,
    required this.colors,
    required this.type,
    required this.sky,
    required this.lit,
  });

  final WeekDay day;
  final double diameter;
  final CurreColors colors;
  final CurreType type;
  final Pair sky;
  final double lit;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    // A kept day wears an ember ring (a sun that rose), quiet enough that
    // the check-in card below stays the loudest thing on the screen.
    final kept = BorderSide(color: c.ember, width: 2.5);
    final (Color fill, Color fg, BorderSide side) = switch (day.state) {
      DayState.kept => (c.raised, c.ink, kept),
      DayState.quiet => (c.raised, c.ink2, BorderSide(color: c.hairline)),
      DayState.future => (Colors.transparent, c.ink3, BorderSide(color: c.hairline)),
      DayState.today => (
        Color.lerp(sky.bg, c.raised, lit)!,
        Color.lerp(sky.fg, c.ink, lit)!,
        BorderSide(color: Color.lerp(sky.fg, c.ember, lit)!, width: lit > 0 ? 2.5 : 2),
      ),
    };
    // A short pop as today lights up, then it settles.
    final pop = lit <= 0 || lit >= 1 ? 1.0 : 1 + .14 * (lit < .5 ? lit * 2 : (1 - lit) * 2);
    return Transform.scale(
      scale: pop,
      child: Container(
        width: diameter,
        height: diameter,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: fill,
          shape: CircleBorder(side: side),
        ),
        child: Text(
          '${day.date}',
          style: type.label.weight(day.state == DayState.today ? 720 : 600).copyWith(color: fg),
        ),
      ),
    );
  }
}

/// A section heading with something useful on its right (Mombo's "Today's
/// Check-in · See all" slot).
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<CurreType>()!;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: t.title.copyWith(fontSize: 18, height: 24 / 18),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: CurreSpace.s3), trailing!],
      ],
    );
  }
}

/// "4 days in a row", with the kept-day sun.
class StreakCount extends StatelessWidget {
  const StreakCount({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CurreGlyph(CurreGlyphKind.streak, size: 20, color: c.ember),
        const SizedBox(width: 4),
        Text('$days days in a row', style: t.label.copyWith(fontSize: 14, color: c.ink2)),
      ],
    );
  }
}

/// The check-in card, descended from Mombo's: one question in the
/// session's sky, Peek on Curre's horizon where Mombo has its sun over the
/// hills. Peek stays still here (this sits on Home at a session's start).
class CheckinCard extends StatelessWidget {
  const CheckinCard({super.key, required this.session, required this.question, required this.hint, this.height = 280});

  final Session session;
  final String question;
  final String hint;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final sky = c.sky(session);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        const ground = 52.0;
        // The card is at least [height] and grows with its words (large
        // system text), keeping the horizon a fixed distance from the
        // bottom so the words never reach the ground.
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: Stack(
            children: [
              Positioned.fill(
                child: SkyScene(
                  session: session,
                  groundHeight: ground,
                  sunAt: .77,
                  sunSize: (w * .36).clamp(104.0, 128.0),
                  sunRise: .74,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, ground + 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: w * .64),
                      child: Text(
                        question,
                        style: t.title.copyWith(fontSize: 26, height: 32 / 26, color: sky.fg).weight(720),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: w * .66),
                      child: Text(
                        hint,
                        style: t.body.copyWith(fontSize: 15, height: 20 / 15, color: sky.fg.withValues(alpha: .86)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The one primary action of a screen: a full-width 56 dp pill with its
/// label centred and a glyph in a circle at its end (Mombo's "Check-in →").
class PrimaryPill extends StatelessWidget {
  const PrimaryPill({
    super.key,
    required this.label,
    this.glyph,
    this.background,
    this.foreground,
    this.glyphBackground,
    this.glyphColor,
  });

  final String label;
  final CurreGlyphKind? glyph;
  final Color? background;
  final Color? foreground;
  final Color? glyphBackground;
  final Color? glyphColor;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final bg = background ?? c.ink;
    final fg = foreground ?? c.paper;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          // Centre the label on the whole pill when there is room to mirror
          // the end glyph; on a narrow pill, give the words that room.
          final mirror = glyph != null && box.maxWidth >= 300;
          return Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: EdgeInsets.fromLTRB(glyph == null || !mirror ? 20 : 56, 8, glyph == null ? 20 : 8, 8),
            decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: t.label.weight(660).copyWith(fontSize: 16, color: fg),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (glyph != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: glyphBackground ?? fg, shape: BoxShape.circle),
                    child: CurreGlyph(glyph!, size: 20, color: glyphColor ?? bg),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A quiet secondary pill (outlined), same height as [PrimaryPill].
class SecondaryPill extends StatelessWidget {
  const SecondaryPill({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final ink = color ?? c.ink;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          shape: StadiumBorder(side: BorderSide(color: ink, width: 1.5)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: t.label.weight(640).copyWith(fontSize: 16, color: ink),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// A small white tag (Mombo's "Personal" pill) carrying a machine value.
class MetaPill extends StatelessWidget {
  const MetaPill({super.key, required this.text, this.glyph});

  final String text;
  final CurreGlyphKind? glyph;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final light = Theme.of(context).brightness == Brightness.light;
    final bg = light ? c.raised : c.paper.withValues(alpha: .55);
    return Container(
      padding: EdgeInsets.fromLTRB(glyph == null ? 12 : 8, 4, 12, 4),
      decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[CurreGlyph(glyph!, size: 16, color: c.ink), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              text,
              style: t.figure.copyWith(fontSize: 12, height: 16 / 12, color: c.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// A mono countdown ("0:47") with the colon pulled in: mono digits keep
/// their fixed width so the seconds never jitter, but a full mono cell
/// around the colon reads as "0 : 47" at display size.
Widget countdownText(String text, TextStyle style) {
  final i = text.indexOf(':');
  final pull = -(style.fontSize ?? 72) * .2;
  return Text.rich(
    TextSpan(
      children: [
        if (i > 1) TextSpan(text: text.substring(0, i - 1)),
        TextSpan(
          text: text.substring(i - 1, i),
          style: TextStyle(letterSpacing: pull),
        ),
        TextSpan(
          text: ':',
          style: TextStyle(letterSpacing: pull),
        ),
        TextSpan(text: text.substring(i + 1)),
      ],
    ),
    style: style,
    semanticsLabel: text,
  );
}

/// The link number set inline after a highlighted span.
InlineSpan linkBadgeSpan(BuildContext context, int n) {
  final c = Theme.of(context).extension<CurreColors>()!;
  final t = Theme.of(context).extension<CurreType>()!;
  return WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Padding(
      padding: const EdgeInsets.only(left: 4, right: 2),
      child: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.link(n).mark,
          shape: BoxShape.circle,
          border: Border.all(color: c.markInk.withValues(alpha: .18)),
        ),
        child: Text('$n', style: t.figure.copyWith(fontSize: 11, height: 1, color: c.markInk)),
      ),
    ),
  );
}

/// Highlight for span/door link [n]: the link's highlighter behind the
/// user's own words, set in mark ink, with the number after it.
SpanHighlight linkHighlight(BuildContext context, String text, String phrase, int n, TextStyle base) {
  final c = Theme.of(context).extension<CurreColors>()!;
  final (s, e) = spanOf(text, phrase);
  return SpanHighlight(
    s,
    e,
    style: base.copyWith(backgroundColor: c.link(n).mark, color: c.markInk),
    after: linkBadgeSpan(context, n),
  );
}

/// Highlight for a time phrase: underlined in ember, the visible reason
/// for when the plan ends or how long a grant runs.
SpanHighlight timeHighlight(BuildContext context, String text, String phrase, TextStyle base) {
  final c = Theme.of(context).extension<CurreColors>()!;
  final (s, e) = spanOf(text, phrase);
  return SpanHighlight(
    s,
    e,
    style: base.copyWith(decoration: TextDecoration.underline, decorationColor: c.ember, decorationThickness: 2.5),
  );
}

/// A stand-in for an installed app's own icon (the real launcher shows the
/// phone's icon, and only above the horizon). Neutral on purpose: no brand
/// colours or marks are imitated.
class AppIconStandIn extends StatelessWidget {
  const AppIconStandIn({super.key, required this.icon, this.size = CurreSpace.doorIcon, this.ring});

  final IconData icon;
  final double size;

  /// 0–1 of a grant left: draws the draining ember ring around the icon.
  final double? ring;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final light = Theme.of(context).brightness == Brightness.light;
    final tile = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: light ? c.raised : const Color(0xFF2A2633),
        borderRadius: BorderRadius.circular(size * .32),
      ),
      child: Icon(icon, size: size * .5, color: c.ink),
    );
    if (ring == null) return tile;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        foregroundPainter: _GrantRingPainter(left: ring!, color: c.ember, track: c.ink.withValues(alpha: .12)),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: FittedBox(child: tile),
        ),
      ),
    );
  }
}

class _GrantRingPainter extends CustomPainter {
  _GrantRingPainter({required this.left, required this.color, required this.track});

  final double left;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1.5);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.width * .34));
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rrect, trackPaint);
    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;
    // Drains linearly (time is never eased), from the top centre.
    final start = metric.length * .125;
    final len = metric.length * left;
    final arc = Path();
    if (start + len <= metric.length) {
      arc.addPath(metric.extractPath(start, start + len), Offset.zero);
    } else {
      arc
        ..addPath(metric.extractPath(start, metric.length), Offset.zero)
        ..addPath(metric.extractPath(0, start + len - metric.length), Offset.zero);
    }
    canvas.drawPath(
      arc,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GrantRingPainter old) => old.left != left || old.color != color || old.track != track;
}

/// Essentials pinned on the horizon, never moving, and the single way down
/// to everything out of sight (design report 4.4). Sits in the same place
/// on every screen and in every state, like Mombo's tab bar.
class EssentialsDock extends StatelessWidget {
  const EssentialsDock({super.key, this.outOfSight = 23});

  final int outOfSight;

  static const essentials = <(IconData, String)>[
    (SolarIconsBold.phone, 'Phone'),
    (SolarIconsBold.chatRoundLine, 'Messages'),
    (SolarIconsBold.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 64,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned(left: 0, right: 0, child: HorizonLine()),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: ShapeDecoration(
                  color: c.raised,
                  shape: StadiumBorder(side: BorderSide(color: c.hairline)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (icon, label) in essentials)
                      Semantics(
                        button: true,
                        label: label,
                        excludeSemantics: true,
                        child: SizedBox(width: 56, height: 56, child: Icon(icon, size: 24, color: c.ink)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: '$outOfSight apps out of sight. Open the list.',
          excludeSemantics: true,
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$outOfSight out of sight', style: t.listItem.copyWith(fontSize: 16, height: 20 / 16).weight(520)),
                const SizedBox(width: 8),
                CurreGlyph(CurreGlyphKind.rise, size: 20, color: c.ink2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
