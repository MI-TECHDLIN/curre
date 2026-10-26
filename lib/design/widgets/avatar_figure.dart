import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'avatar.dart';

/// How an [AvatarFigure] holds its arms.
enum FigurePose {
  /// Arms down by the sides.
  relaxed,

  /// One hand up in a wave. With motion on, it waves twice and rests.
  wave,

  /// Both hands at the chest, holding a phone.
  phone,
}

/// A person from the avatar catalogue standing in a scene: their avatar's
/// head and hair on a simple body, drawn in the avatars' own style (flat
/// fills, one ink outline weight, front-facing). Onboarding uses it to put
/// the user's chosen face into its illustrations.
///
/// The figure is a bust: its body runs to the bottom edge, so a scene sets
/// it behind a ground, a card or a frame. Width is [height] × [aspect].
/// With no [avatarId] the head is the user's [initial] in a circle, like
/// the profile fallback.
///
/// Motion follows [Avatar]: [motion] drives the face, and the wave plays
/// only when motion is on and the platform has not asked for less.
class AvatarFigure extends StatefulWidget {
  const AvatarFigure({
    super.key,
    this.avatarId,
    this.initial,
    this.height = 200,
    this.pose = FigurePose.relaxed,
    this.shirt,
    this.motion = AvatarMotion.still,
    this.expression = AvatarExpression.neutral,
    this.semanticLabel,
  });

  final String? avatarId;
  final String? initial;
  final double height;
  final FigurePose pose;

  /// The top's colour; by default one picked from the avatar so the same
  /// person always wears the same colour.
  final Color? shirt;
  final AvatarMotion motion;
  final AvatarExpression expression;
  final String? semanticLabel;

  static const double aspect = .8;

  /// Tops that sit well on every avatar background, in stable order.
  static const shirts = <Color>[
    Color(0xFF4B79B8),
    Color(0xFF2E806F),
    Color(0xFFD95045),
    Color(0xFFE5A936),
    Color(0xFF7A5AA6),
    Color(0xFF2E3876),
  ];

  static Color shirtFor(String? avatarId) {
    var hash = 7;
    for (final unit in (avatarId ?? '').codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return shirts[hash % shirts.length];
  }

  @override
  State<AvatarFigure> createState() => _AvatarFigureState();
}

class _AvatarFigureState extends State<AvatarFigure>
    with SingleTickerProviderStateMixin {
  // Two waves, then rest: a greeting, not a loop.
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  bool get _waving =>
      widget.pose == FigurePose.wave &&
      widget.motion != AvatarMotion.still &&
      !MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(restart: false);
  }

  @override
  void didUpdateWidget(AvatarFigure oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(
      restart:
          oldWidget.avatarId != widget.avatarId ||
          oldWidget.pose != widget.pose,
    );
  }

  void _sync({required bool restart}) {
    if (!_waving) {
      _wave
        ..stop()
        ..value = 0;
      return;
    }
    if (restart || _wave.value == 0) _wave.forward(from: 0);
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height;
    final unit = height / 200;
    final option = AvatarCatalog.byId(widget.avatarId);
    final skin = (option?.skinTone ?? AvatarSkinTone.tan).color;
    final shirt = widget.shirt ?? AvatarFigure.shirtFor(widget.avatarId);
    final figure = SizedBox(
      width: height * AvatarFigure.aspect,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 30 * unit,
            top: 0,
            width: 100 * unit,
            height: 100 * unit,
            child: Avatar(
              avatarId: widget.avatarId,
              initial: widget.initial,
              size: 100 * unit,
              framed: false,
              motion: widget.motion,
              expression: widget.expression,
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _wave,
              builder: (context, _) => CustomPaint(
                painter: _FigureBodyPainter(
                  skin: skin,
                  shirt: shirt,
                  pose: widget.pose,
                  // A soft back-and-forth that eases out to rest.
                  wave:
                      math.sin(_wave.value * math.pi * 4) *
                      (1 - Curves.easeIn.transform(_wave.value)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      label: widget.semanticLabel,
      image: widget.semanticLabel != null,
      excludeSemantics: true,
      child: figure,
    );
  }
}

class _FigureBodyPainter extends CustomPainter {
  _FigureBodyPainter({
    required this.skin,
    required this.shirt,
    required this.pose,
    required this.wave,
  });

  final Color skin;
  final Color shirt;
  final FigurePose pose;

  /// −1 to 1: how far the waving forearm is swung.
  final double wave;

  static const _ink = AvatarPalette.outline;
  static const double _outline = 4.2;
  static const double _arm = 15;
  static const double _hand = 8.5;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.height / 200;
    canvas.save();
    canvas.scale(unit);

    // Arms that hang at the sides go behind the body.
    if (pose == FigurePose.relaxed) {
      _arm2(canvas, const [Offset(42, 118), Offset(30, 158), Offset(31, 210)]);
      _arm2(canvas, const [Offset(118, 118), Offset(130, 158), Offset(129, 210)]);
    } else if (pose == FigurePose.wave) {
      _arm2(canvas, const [Offset(42, 118), Offset(30, 158), Offset(31, 210)]);
    }

    final torso = Path()
      ..moveTo(34, 214)
      ..lineTo(34, 130)
      ..cubicTo(34, 108, 46, 96, 64, 93)
      ..quadraticBezierTo(80, 101, 96, 93)
      ..cubicTo(114, 96, 126, 108, 126, 130)
      ..lineTo(126, 214)
      ..close();
    canvas.drawPath(torso, Paint()..color = shirt);
    canvas.drawPath(torso, _stroke(_outline));
    // A collar seam, the one detail that makes it read as a top.
    final seam = Path()
      ..moveTo(68, 96.5)
      ..quadraticBezierTo(80, 103, 92, 96.5);
    canvas.drawPath(seam, _stroke(2.4, _ink.withValues(alpha: .55)));

    switch (pose) {
      case FigurePose.relaxed:
        break;
      case FigurePose.wave:
        // Upper arm out and up; the forearm swings round the elbow.
        const shoulder = Offset(118, 116);
        const elbow = Offset(142, 98);
        final angle = -math.pi / 2 + .18 + wave * .26;
        final hand = elbow + Offset(math.cos(angle), math.sin(angle)) * 38;
        _arm2(canvas, [shoulder, elbow, hand]);
        _handAt(canvas, hand);
      case FigurePose.phone:
        _phone(canvas);
        _arm2(canvas, const [Offset(42, 118), Offset(36, 160), Offset(64, 158)]);
        _arm2(canvas, const [Offset(118, 118), Offset(124, 160), Offset(96, 158)]);
        _handAt(canvas, const Offset(66, 156));
        _handAt(canvas, const Offset(94, 156));
    }
    canvas.restore();
  }

  void _phone(Canvas canvas) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(80, 142), width: 34, height: 52),
      const Radius.circular(7),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF2B2733));
    canvas.drawRRect(body, _stroke(3.2));
    canvas.drawCircle(
      const Offset(72, 124),
      2.6,
      Paint()..color = const Color(0xFF6C6478),
    );
  }

  void _arm2(Canvas canvas, List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = _arm + _outline * 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = shirt
        ..style = PaintingStyle.stroke
        ..strokeWidth = _arm
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _handAt(Canvas canvas, Offset at) {
    canvas.drawCircle(at, _hand, Paint()..color = skin);
    canvas.drawCircle(at, _hand, _stroke(3.4));
  }

  Paint _stroke(double width, [Color color = _ink]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  bool shouldRepaint(covariant _FigureBodyPainter old) =>
      old.skin != skin ||
      old.shirt != shirt ||
      old.pose != pose ||
      old.wave != wave;
}
