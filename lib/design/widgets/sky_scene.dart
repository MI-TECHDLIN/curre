import 'package:flutter/material.dart';

import '../curre_colors.dart';
import '../curre_tokens.dart';
import 'peek_mascot.dart';

/// What sits on a [SkyScene]'s horizon.
enum SkySun {
  /// Peek, the mascot (check-in and onboarding only).
  peek,

  /// A plain ember disc with no face: the session's sun, allowed anywhere
  /// a mascot is not (Home's plan card).
  disc,

  /// Nothing: just sky, line and ground.
  none,
}

/// The horizon in its illustrated form: a session sky, the 2 dp line in
/// on-sky ink, the ground tone below it, and a sun that is cut by the line
/// the way a real sunrise is. This is where Curre's check-in card meets
/// its primary reference, the Mombo check-in card (a sun character over a
/// landscape): here the landscape is Curre's own horizon, and the ground
/// is where things go out of sight.
///
/// [horizon] is the line's height as a fraction of the scene (from the
/// top), or set [groundHeight] to pin it a fixed distance from the bottom. [sunAt] is the sun's centre as a fraction of the width. [sunRise]
/// is how far the sun's body has cleared the line: 0 hides it, 1 sets it
/// down on the line.
///
/// [flood] (0–1) is for moments that light up a dormant sky: below 1 the
/// sky is fog grey above a rising band of session colour that grows from
/// the line upward (the Duolingo streak's colour flood, slowed and grown
/// from the horizon). [lit], [rays] and [eyesOpen] pass through to Peek.
class SkyScene extends StatelessWidget {
  const SkyScene({
    super.key,
    required this.session,
    this.sun = SkySun.peek,
    this.horizon = .74,
    this.groundHeight,
    this.sunAt = .76,
    this.sunSize = 120,
    this.sunRise = .74,
    this.animatePeek = false,
    this.flood = 1,
    this.lit = 1,
    this.rays = 1,
    this.eyesOpen = 1,
    this.borderRadius = CurreShape.lg,
    this.padding = const EdgeInsets.all(20),
    this.child,
  });

  final Session session;
  final SkySun sun;
  final double horizon;

  /// The ground's height in logical pixels. When set it wins over
  /// [horizon], so a scene that grows with its text keeps its line at a
  /// fixed distance from the bottom.
  final double? groundHeight;
  final double sunAt;
  final double sunSize;
  final double sunRise;
  final bool animatePeek;
  final double flood;
  final double lit;
  final double rays;
  final double eyesOpen;
  final BorderRadius borderRadius;
  final EdgeInsets padding;

  /// Content laid over the sky (a question, a plan), inside [padding].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final sky = c.sky(session);
    final dormant = c.outcomes[Outcome.unavailable]!;
    final f = flood.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: borderRadius,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          final lineY = groundHeight != null ? (h - groundHeight!).roundToDouble() : (h * horizon).roundToDouble();
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SkyPainter(
                    lineY: lineY,
                    sky: sky.bg,
                    ground: c.ground(session),
                    dormantSky: dormant.bg,
                    dormantGround: Color.lerp(dormant.bg, dormant.fg, .18)!,
                    flood: f,
                  ),
                ),
              ),
              if (sun != SkySun.none)
                Positioned.fill(
                  child: ClipRect(
                    clipper: _AboveLine(lineY),
                    child: Stack(children: [_sun(c, w, lineY)]),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                top: lineY - CurreSpace.horizon / 2,
                height: CurreSpace.horizon,
                child: ColoredBox(color: Color.lerp(dormant.fg, sky.fg, f)!),
              ),
              if (child != null)
                Positioned.fill(
                  child: Padding(padding: padding, child: child),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _sun(CurreColors c, double w, double lineY) {
    final scale = sunSize / 120;
    if (sun == SkySun.peek) {
      // Peek's body spans 20–96 on its 120-unit grid.
      final bodyTop = 20 * scale;
      final bodyH = 76 * scale;
      final top = lineY - (bodyTop + sunRise * bodyH);
      return Positioned(
        left: w * sunAt - sunSize / 2,
        top: top,
        child: PeekMascot(
          size: sunSize,
          animate: animatePeek,
          groundShadow: false,
          lit: lit,
          rays: rays,
          eyesOpen: eyesOpen,
          semanticLabel: null,
        ),
      );
    }
    final top = lineY - sunRise * sunSize;
    return Positioned(
      left: w * sunAt - sunSize / 2,
      top: top,
      child: Container(
        width: sunSize,
        height: sunSize,
        decoration: BoxDecoration(
          color: Color.lerp(c.outcomes[Outcome.unavailable]!.fg, c.ember, lit),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _AboveLine extends CustomClipper<Rect> {
  _AboveLine(this.lineY);
  final double lineY;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width, lineY);

  @override
  bool shouldReclip(covariant _AboveLine oldClipper) => oldClipper.lineY != lineY;
}

class _SkyPainter extends CustomPainter {
  _SkyPainter({
    required this.lineY,
    required this.sky,
    required this.ground,
    required this.dormantSky,
    required this.dormantGround,
    required this.flood,
  });

  final double lineY;
  final Color sky;
  final Color ground;
  final Color dormantSky;
  final Color dormantGround;
  final double flood;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, lineY), Paint()..color = dormantSky);
    // The session colour rises from the line to fill the sky.
    final floodTop = lineY * (1 - flood);
    canvas.drawRect(Rect.fromLTRB(0, floodTop, size.width, lineY), Paint()..color = sky);
    canvas.drawRect(
      Rect.fromLTRB(0, lineY, size.width, size.height),
      Paint()..color = Color.lerp(dormantGround, ground, flood)!,
    );
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) =>
      old.lineY != lineY ||
      old.sky != sky ||
      old.ground != ground ||
      old.flood != flood ||
      old.dormantSky != dormantSky ||
      old.dormantGround != dormantGround;
}
