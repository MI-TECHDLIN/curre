import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../core/models.dart' show Settings;
import '../../core/progress.dart' show DayProgress;
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
            Text(
              time,
              style: t.label.weight(620).copyWith(fontSize: 14, color: ink),
            ),
            const Spacer(),
            for (final h in const [4.0, 6.0, 8.0, 10.0])
              Container(
                width: 3,
                height: h,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(1.5),
                ),
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
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(1.5),
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
          shape: CircleBorder(
            side: outlined ? BorderSide(color: c.hairline) : BorderSide.none,
          ),
        ),
        child: CurreGlyph(glyph, size: 24, color: foreground ?? c.ink),
      ),
    );
  }
}

/// The session greeting, after the Mombo and "Morning, Budi" references:
/// a big friendly line that names the user ("Good morning, Chidi"), the
/// date, and one round button. With no name it is the greeting alone, never
/// a dangling comma. A long name never overflows: the line steps down from
/// 30 to 26, then wraps onto a second line, then steps down to 22 and ends
/// in an ellipsis, measured at the phone's own text scale. The size is the
/// one at which every session's greeting fits with this name, so it does
/// not change between the morning and the afternoon.
class Greeting extends StatelessWidget {
  const Greeting({
    super.key,
    required this.greeting,
    this.name,
    required this.subtitle,
    this.trailing,
  });

  final String greeting;

  /// The user's display name (core `Settings.displayName`), if any.
  final String? name;
  final String subtitle;
  final Widget? trailing;

  /// "Good morning, Chidi", or "Good morning" when [name] is blank, using
  /// the same tidy-up rule the core settings apply.
  static String compose(String greeting, String? name) {
    final tidy = Settings.normalizeDisplayName(name);
    return tidy == null ? greeting : '$greeting, $tidy';
  }

  /// Font size, line height and line count, tried in order.
  static const _fits = <(double, double, int)>[
    (30, 36, 1),
    (26, 32, 1),
    (26, 32, 2),
    (22, 28, 2),
  ];

  /// The three session greetings; the longest sets the size.
  static const sessionGreetings = [
    'Good morning',
    'Good afternoon',
    'Good evening',
  ];

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final text = compose(greeting, name);
    final sized = {text, for (final g in sessionGreetings) compose(g, name)};
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final scaler = MediaQuery.textScalerOf(context);
              var fit = _fits.last;
              bool fitsAll((double, double, int) candidate) {
                for (final line in sized) {
                  final painter = TextPainter(
                    text: TextSpan(
                      text: line,
                      style: t.headline.copyWith(
                        fontSize: candidate.$1,
                        height: candidate.$2 / candidate.$1,
                      ),
                    ),
                    maxLines: candidate.$3,
                    textDirection: TextDirection.ltr,
                    textScaler: scaler,
                  )..layout(maxWidth: box.maxWidth);
                  final fits = !painter.didExceedMaxLines;
                  painter.dispose();
                  if (!fits) return false;
                }
                return true;
              }

              for (final candidate in _fits) {
                if (fitsAll(candidate)) {
                  fit = candidate;
                  break;
                }
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: t.headline.copyWith(
                      fontSize: fit.$1,
                      height: fit.$2 / fit.$1,
                    ),
                    maxLines: fit.$3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: t.body.copyWith(color: c.ink2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: CurreSpace.s3),
          trailing!,
        ],
      ],
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
        if (trailing != null) ...[
          const SizedBox(width: CurreSpace.s3),
          trailing!,
        ],
      ],
    );
  }
}

/// The check-in card, descended from Mombo's: one question in the
/// session's own living sky, Peek on Curre's horizon where Mombo has its
/// sun over the hills, and today's water in the ground below the line.
///
/// Each session has its own sky ([LiveSky]: first light, the clear
/// afternoon, the blue hour) and its own height for Peek (design report §5:
/// lower in the morning, higher at noon, lower in the evening). [progress]
/// fills the ground with water: today's plans so far (core
/// `DayProgress`), rising from [progressFrom] (what the user last saw) with
/// a slosh as the card appears. [progressLabel] says what the water
/// measures, in Curre's words. [animate] off gives the still frame that
/// reduced motion also gets.
class CheckinCard extends StatelessWidget {
  const CheckinCard({
    super.key,
    required this.session,
    required this.question,
    required this.hint,
    this.progress,
    this.progressFrom,
    this.progressLabel,
    this.height = 308,
    this.animate = true,
  });

  final Session session;
  final String question;
  final String hint;
  final double? progress;
  final double? progressFrom;
  final String? progressLabel;
  final double height;
  final bool animate;

  /// Ground below the horizon: deep enough for the water to visibly rise.
  static const ground = 84.0;

  /// What today's water says it measures, in Curre's words.
  static String waterLabel(DayProgress day) =>
      switch ((day.plans, day.doorsUsed)) {
        (0, _) => 'Today · nothing yet',
        (1, 0) => 'Today · 1 plan',
        (final plans, 0) => 'Today · $plans plans',
        (_, 1) => 'Today · 1 door used',
        (_, final doors) => 'Today · $doors doors used',
      };

  /// Where Peek stands for each session: across the card, and how far its
  /// body has risen over the line.
  static (double, double) peekPlace(Session session) => switch (session) {
    Session.morning => (.76, .64),
    Session.afternoon => (.74, 1.0),
    Session.evening => (.79, .5),
  };

  /// The box the question and hint take up on a card [w] wide, measured at
  /// the phone's text scale, so the sky's moving shapes can keep out of it.
  Rect _wordsBox(
    BuildContext context,
    double w,
    TextStyle questionStyle,
    TextStyle hintStyle,
  ) {
    final scaler = MediaQuery.textScalerOf(context);
    Size measure(String text, TextStyle style, double maxWidth) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout(maxWidth: maxWidth);
      final size = painter.size;
      painter.dispose();
      return size;
    }

    final q = measure(question, questionStyle, w * .64);
    final h = measure(hint, hintStyle, w * .66);
    return Rect.fromLTWH(
      20,
      24,
      math.max(q.width, h.width),
      q.height + 8 + h.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final t = Theme.of(context).extension<CurreType>()!;
    final sky = c.sky(session);
    final (sunAt, sunRise) = peekPlace(session);
    final questionStyle = t.title
        .copyWith(fontSize: 26, height: 32 / 26, color: sky.fg)
        .weight(720);
    final hintStyle = t.body.copyWith(
      fontSize: 15,
      height: 20 / 15,
      color: sky.fg.withValues(alpha: .86),
    );
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final words = _wordsBox(context, w, questionStyle, hintStyle);
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
                  sunAt: sunAt,
                  sunSize: (w * .36).clamp(104.0, 128.0),
                  sunRise: sunRise,
                  animatePeek: animate,
                  live: true,
                  animate: animate,
                  keepClear: words,
                  water: progress,
                  waterFrom: progressFrom,
                  waterLabel: progressLabel,
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
                      child: Text(question, style: questionStyle),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: w * .66),
                      child: Text(hint, style: hintStyle),
                    ),
                  ],
                ),
              ),
              if (progressLabel != null)
                Positioned(
                  left: 16,
                  right: w * .3,
                  bottom: (ground - 24) / 2 - 1,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ExcludeSemantics(
                      child: MetaPill(
                        text: progressLabel!,
                        glyph: CurreGlyphKind.water,
                      ),
                    ),
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
            padding: EdgeInsets.fromLTRB(
              glyph == null || !mirror ? 20 : 56,
              8,
              glyph == null ? 20 : 8,
              8,
            ),
            decoration: ShapeDecoration(
              color: bg,
              shape: const StadiumBorder(),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: t.label
                        .weight(660)
                        .copyWith(fontSize: 16, color: fg),
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
                    decoration: BoxDecoration(
                      color: glyphBackground ?? fg,
                      shape: BoxShape.circle,
                    ),
                    child: CurreGlyph(
                      glyph!,
                      size: 20,
                      color: glyphColor ?? bg,
                    ),
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
          if (glyph != null) ...[
            CurreGlyph(glyph!, size: 16, color: c.ink),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: t.figure.copyWith(
                fontSize: 12,
                height: 16 / 12,
                color: c.ink,
              ),
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
        child: Text(
          '$n',
          style: t.figure.copyWith(fontSize: 11, height: 1, color: c.markInk),
        ),
      ),
    ),
  );
}

/// Highlight for span/door link [n]: the link's highlighter behind the
/// user's own words, set in mark ink, with the number after it.
SpanHighlight linkHighlight(
  BuildContext context,
  String text,
  String phrase,
  int n,
  TextStyle base,
) {
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
SpanHighlight timeHighlight(
  BuildContext context,
  String text,
  String phrase,
  TextStyle base,
) {
  final c = Theme.of(context).extension<CurreColors>()!;
  final (s, e) = spanOf(text, phrase);
  return SpanHighlight(
    s,
    e,
    style: base.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: c.ember,
      decorationThickness: 2.5,
    ),
  );
}

/// A stand-in for an installed app's own icon (the real launcher shows the
/// phone's icon, and only above the horizon). Neutral on purpose: no brand
/// colours or marks are imitated.
class AppIconStandIn extends StatelessWidget {
  const AppIconStandIn({
    super.key,
    required this.icon,
    this.size = CurreSpace.doorIcon,
    this.ring,
  });

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
        foregroundPainter: _GrantRingPainter(
          left: ring!,
          color: c.ember,
          track: c.ink.withValues(alpha: .12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: FittedBox(child: tile),
        ),
      ),
    );
  }
}

class _GrantRingPainter extends CustomPainter {
  _GrantRingPainter({
    required this.left,
    required this.color,
    required this.track,
  });

  final double left;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1.5);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.width * .34),
    );
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
        ..addPath(
          metric.extractPath(0, start + len - metric.length),
          Offset.zero,
        );
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
  bool shouldRepaint(covariant _GrantRingPainter old) =>
      old.left != left || old.color != color || old.track != track;
}

/// Essentials pinned on the horizon, never moving, and the single way into
/// Hidden apps. Sits in the same place on every screen and in every state,
/// like Mombo's tab bar.
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
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(icon, size: 24, color: c.ink),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: 'Hidden apps, $outOfSight apps. Open the list.',
          excludeSemantics: true,
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hidden apps · $outOfSight',
                  style: t.listItem
                      .copyWith(fontSize: 16, height: 20 / 16)
                      .weight(520),
                ),
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
