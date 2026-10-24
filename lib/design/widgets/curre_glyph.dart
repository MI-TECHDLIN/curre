import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

/// Curre's glyph set (design report 3.7), drawn with the Solar icon set in
/// its **Bold** style, the captain's pick after the pack comparison
/// (2026-10-24: "for the icon solar bold is fine"). The enum stays
/// semantic, so screens ask for a meaning ("kind: person", "out of
/// sight") and never for a Solar name; the mapping lives here alone.
///
/// Covers the report's full list of 31 glyphs plus [streak], [water] and
/// [cloudDay]: sessions, visibility, doors and reasons, gate states and
/// utilities. There is still no padlock (friction, not a lock).
///
/// A few Solar Bold glyphs lose an inner cut-out in the `solar_icons`
/// 0.2.0 font (the question mark, the info dot, the warning shield's
/// bang, the clock hands). [kindUnclear], [guardFlagged] and [info] are
/// therefore composed here in the same filled style: a solid Solar shape
/// with its mark knocked out. Every other kind is a stock Solar Bold
/// glyph, each one checked by eye at 56 dp.
enum CurreGlyphKind {
  // Sessions.
  sessionMorning,
  sessionAfternoon,
  sessionEvening,
  // Visibility.
  outOfSight,
  rise,
  set,
  // Doors and reasons.
  door,
  kindTask,
  kindPerson,
  kindTimeSensitive,
  kindBrowse,
  kindUnclear,
  later,
  // Gate states.
  guardFlagged,
  unavailable,
  overrideWait,
  pasteFallback,
  // Utility.
  speak,
  essential,
  history,
  curreSettings,
  underTheHood,
  homeRole,
  privacy,
  notify,
  editSpecify,
  info,
  check,
  close,
  back,
  go,
  // Outside the report's 31: the kept-day mark of the streak the captain
  // added (2026-10-24). Its counting rules come from a separate audit.
  streak,
  // Also outside the 31: today's water (the check-in card's progress) and
  // the streak's cloud day (proof audit §3, rule 7).
  water,
  cloudDay,
}

/// The Solar Bold glyph behind each stock kind; `null` for the three
/// composed kinds.
IconData? curreGlyphIcon(CurreGlyphKind kind) => switch (kind) {
  CurreGlyphKind.sessionMorning => SolarIconsBold.sunrise,
  CurreGlyphKind.sessionAfternoon => SolarIconsBold.sun,
  CurreGlyphKind.sessionEvening => SolarIconsBold.sunset,
  CurreGlyphKind.outOfSight => SolarIconsBold.eyeClosed,
  CurreGlyphKind.rise => SolarIconsBold.roundArrowUp,
  CurreGlyphKind.set => SolarIconsBold.roundArrowDown,
  CurreGlyphKind.door => SolarIconsBold.login_2,
  CurreGlyphKind.kindTask => SolarIconsBold.clipboardCheck,
  CurreGlyphKind.kindPerson => SolarIconsBold.userSpeak,
  CurreGlyphKind.kindTimeSensitive => SolarIconsBold.alarm,
  CurreGlyphKind.kindBrowse => SolarIconsBold.eye,
  CurreGlyphKind.later => SolarIconsBold.bookmark,
  CurreGlyphKind.unavailable => SolarIconsBold.cloudCross,
  CurreGlyphKind.overrideWait => SolarIconsBold.hourglass,
  CurreGlyphKind.pasteFallback => SolarIconsBold.clipboardText,
  CurreGlyphKind.speak => SolarIconsBold.microphone3,
  CurreGlyphKind.essential => SolarIconsBold.pin,
  CurreGlyphKind.history => SolarIconsBold.history,
  CurreGlyphKind.curreSettings => SolarIconsBold.tuning_2,
  CurreGlyphKind.underTheHood => SolarIconsBold.cpu,
  CurreGlyphKind.homeRole => SolarIconsBold.homeSmile,
  CurreGlyphKind.privacy => SolarIconsBold.shieldCheck,
  CurreGlyphKind.notify => SolarIconsBold.bell,
  CurreGlyphKind.editSpecify => SolarIconsBold.pen,
  CurreGlyphKind.check => SolarIconsBold.checkCircle,
  CurreGlyphKind.close => SolarIconsBold.closeCircle,
  CurreGlyphKind.back => SolarIconsBold.arrowLeft,
  CurreGlyphKind.go => SolarIconsBold.arrowRight,
  CurreGlyphKind.streak => SolarIconsBold.sun,
  CurreGlyphKind.water => SolarIconsBold.water,
  CurreGlyphKind.cloudDay => SolarIconsBold.cloud,
  CurreGlyphKind.kindUnclear || CurreGlyphKind.guardFlagged || CurreGlyphKind.info => null,
};

/// One glyph at [size] (the report's 24 dp grid by default) in [color].
///
/// Always set [semanticLabel] to the glyph's meaning (e.g. "Task") so it
/// reaches TalkBack, as the report requires. A null label marks the glyph
/// as purely decorative.
class CurreGlyph extends StatelessWidget {
  const CurreGlyph(this.kind, {super.key, this.size = 24, this.color, this.semanticLabel});

  final CurreGlyphKind kind;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color ?? const Color(0xFF1E1A16);
    final icon = curreGlyphIcon(kind);
    final Widget glyph = icon != null
        ? Icon(icon, size: size, color: resolved)
        : CustomPaint(
            size: Size.square(size),
            painter: _KnockoutGlyphPainter(kind: kind, color: resolved),
          );
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Center(child: glyph),
      ),
    );
  }
}

/// Draws a solid Solar Bold shape and knocks its mark out of it, so the
/// three composed kinds read exactly like their stock neighbours on any
/// background (the cut-out is real transparency, not a painted colour).
class _KnockoutGlyphPainter extends CustomPainter {
  _KnockoutGlyphPainter({required this.kind, required this.color});

  final CurreGlyphKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.saveLayer(Offset.zero & size, Paint());

    final String mark;
    final double markScale;
    final Offset markNudge;
    if (kind == CurreGlyphKind.guardFlagged) {
      // The plain Solar Bold shield (its warning variant is the one that
      // loses the bang in this font).
      const base = SolarIconsBold.shieldMinimalistic;
      final baseText = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(base.codePoint),
          style: TextStyle(
            fontFamily: base.fontFamily,
            package: base.fontPackage,
            fontSize: s,
            color: color,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      baseText.paint(canvas, Offset((s - baseText.width) / 2, (s - baseText.height) / 2));
      baseText.dispose();
      mark = '!';
      markScale = .50;
      markNudge = Offset(0, -s * .03);
    } else {
      // A solid disc at Solar's circle proportions (its check and close
      // circles span about 83% of the em box).
      canvas.drawCircle(Offset(s / 2, s / 2), s * .415, Paint()..color = color);
      final isInfo = kind == CurreGlyphKind.info;
      mark = isInfo ? 'i' : '?';
      markScale = isInfo ? .50 : .54;
      markNudge = Offset(s * .01, 0);
    }

    final markText = TextPainter(
      text: TextSpan(
        text: mark,
        style: TextStyle(
          fontFamily: 'Geologica',
          fontSize: s * markScale,
          height: 1,
          fontWeight: FontWeight.w800,
          fontVariations: const [FontVariation('wght', 800), FontVariation('SHRP', 0)],
          foreground: Paint()
            ..color = const Color(0xFF000000)
            ..blendMode = BlendMode.dstOut,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    markText.paint(canvas, Offset((s - markText.width) / 2, (s - markText.height) / 2) + markNudge);
    markText.dispose();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KnockoutGlyphPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
