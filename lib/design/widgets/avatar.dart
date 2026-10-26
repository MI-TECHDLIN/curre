import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../curre_colors.dart';
import '../curre_type.dart';

/// Skin colours shared by the avatar catalogue and custom avatars.
enum AvatarSkinTone { deep, rich, brown, tan, warm, light }

/// Hair silhouettes. Every one is drawn symmetrically and faces forward.
enum AvatarHair { short, curls, afro, braids, locs, longWaves, bob }

enum AvatarHairColor { ink, darkBrown, chestnut }

/// Optional coverings and playful helmets inspired by Curre's reference.
enum AvatarHeadwear {
  none,
  headWrap,
  hijab,
  racerHelmet,
  aviatorGoggles,
  screenHelmet,
  spaceHelmet,
}

/// Curated light fills that retain a strong outline at every avatar size.
enum AvatarBackground { cream, marigold, sky, sage, rose, lilac }

enum AvatarPresentation { masculine, feminine }

/// Motion is explicit so Home can play once and rest, while a profile sheet
/// can opt into the full calm idle loop.
enum AvatarMotion { still, idle, reactOnce }

enum AvatarExpression { neutral, happy, sleepy }

/// Small feature variations keep the catalogue recognisably human without
/// changing its shared, straight-ahead construction.
enum AvatarFaceStyle {
  classic,
  brightEyes,
  freckles,
  dimples,
  boldBrows,
  openSmile,
}

extension AvatarSkinToneColor on AvatarSkinTone {
  Color get color => switch (this) {
    AvatarSkinTone.deep => const Color(0xFF4A2B23),
    AvatarSkinTone.rich => const Color(0xFF704331),
    AvatarSkinTone.brown => const Color(0xFF9A6246),
    AvatarSkinTone.tan => const Color(0xFFC9845D),
    AvatarSkinTone.warm => const Color(0xFFE3A077),
    AvatarSkinTone.light => const Color(0xFFF2C2A2),
  };
}

extension AvatarHairColorValue on AvatarHairColor {
  Color get color => switch (this) {
    AvatarHairColor.ink => AvatarPalette.outline,
    AvatarHairColor.darkBrown => const Color(0xFF3F281F),
    AvatarHairColor.chestnut => const Color(0xFF713D2C),
  };
}

extension AvatarBackgroundColor on AvatarBackground {
  Color get color => switch (this) {
    AvatarBackground.cream => const Color(0xFFF5E7D5),
    AvatarBackground.marigold => const Color(0xFFFCC35A),
    AvatarBackground.sky => const Color(0xFF96D0E6),
    AvatarBackground.sage => const Color(0xFFBFD8B2),
    AvatarBackground.rose => const Color(0xFFF2C4BF),
    AvatarBackground.lilac => const Color(0xFFD8CBE8),
  };
}

/// Fixed colours used by every avatar, independent of app brightness.
abstract final class AvatarPalette {
  static const outline = Color(0xFF1E1A16);
  static const cheek = Color(0xFFD86E63);
  static const eyeLight = Color(0xFFFFFDF9);
  static const helmetGreen = Color(0xFF2E806F);
  static const helmetBlue = Color(0xFF4B79B8);
  static const helmetRed = Color(0xFFD95045);
  static const wrapGold = Color(0xFFE5A936);
  static const hijabBlue = Color(0xFF476889);
  static const visor = Color(0xFFC9EAF2);
  static const helmetCream = Color(0xFFF7F2EA);
  static const screenMint = Color(0xFF79BDA8);
}

@immutable
class AvatarOption {
  const AvatarOption({
    required this.id,
    required this.label,
    required this.description,
    required this.presentation,
    required this.skinTone,
    required this.hair,
    required this.background,
    this.hairColor = AvatarHairColor.ink,
    this.headwear = AvatarHeadwear.none,
    this.faceStyle = AvatarFaceStyle.classic,
  });

  final String id;
  final String label;
  final String description;
  final AvatarPresentation presentation;
  final AvatarSkinTone skinTone;
  final AvatarHair hair;
  final AvatarHairColor hairColor;
  final AvatarHeadwear headwear;
  final AvatarFaceStyle faceStyle;
  final AvatarBackground background;

  String get semanticLabel => '$label, $description';
}

/// The built-in human avatar family. IDs are persistence-safe and should not
/// be renamed after release.
abstract final class AvatarCatalog {
  static const all = <AvatarOption>[
    AvatarOption(
      id: 'avatar-01',
      label: 'Avatar 1',
      description: 'light skin, a short fade, and bold brows',
      presentation: AvatarPresentation.masculine,
      skinTone: AvatarSkinTone.light,
      hair: AvatarHair.short,
      faceStyle: AvatarFaceStyle.boldBrows,
      background: AvatarBackground.marigold,
    ),
    AvatarOption(
      id: 'avatar-02',
      label: 'Avatar 2',
      description: 'warm light skin, shoulder locs, and dimples',
      presentation: AvatarPresentation.masculine,
      skinTone: AvatarSkinTone.warm,
      hair: AvatarHair.locs,
      hairColor: AvatarHairColor.darkBrown,
      faceStyle: AvatarFaceStyle.dimples,
      background: AvatarBackground.sky,
    ),
    AvatarOption(
      id: 'avatar-03',
      label: 'Avatar 3',
      description: 'light skin, soft curls, and freckles',
      presentation: AvatarPresentation.masculine,
      skinTone: AvatarSkinTone.light,
      hair: AvatarHair.curls,
      hairColor: AvatarHairColor.chestnut,
      faceStyle: AvatarFaceStyle.freckles,
      background: AvatarBackground.sage,
    ),
    AvatarOption(
      id: 'avatar-04',
      label: 'Avatar 4',
      description: 'tan skin in a mint screen helmet',
      presentation: AvatarPresentation.masculine,
      skinTone: AvatarSkinTone.tan,
      hair: AvatarHair.afro,
      headwear: AvatarHeadwear.screenHelmet,
      faceStyle: AvatarFaceStyle.brightEyes,
      background: AvatarBackground.rose,
    ),
    AvatarOption(
      id: 'avatar-05',
      label: 'Avatar 5',
      description: 'warm light skin and aviator goggles',
      presentation: AvatarPresentation.masculine,
      skinTone: AvatarSkinTone.warm,
      hair: AvatarHair.short,
      hairColor: AvatarHairColor.chestnut,
      headwear: AvatarHeadwear.aviatorGoggles,
      faceStyle: AvatarFaceStyle.openSmile,
      background: AvatarBackground.cream,
    ),
    AvatarOption(
      id: 'avatar-06',
      label: 'Avatar 6',
      description: 'light skin and a green racer helmet',
      presentation: AvatarPresentation.masculine,
      skinTone: AvatarSkinTone.light,
      hair: AvatarHair.short,
      headwear: AvatarHeadwear.racerHelmet,
      background: AvatarBackground.lilac,
    ),
    AvatarOption(
      id: 'avatar-07',
      label: 'Avatar 7',
      description: 'rich brown skin, long braids, and dimples',
      presentation: AvatarPresentation.feminine,
      skinTone: AvatarSkinTone.rich,
      hair: AvatarHair.braids,
      faceStyle: AvatarFaceStyle.dimples,
      background: AvatarBackground.rose,
    ),
    AvatarOption(
      id: 'avatar-08',
      label: 'Avatar 8',
      description: 'light skin, bright eyes, and a blue hijab',
      presentation: AvatarPresentation.feminine,
      skinTone: AvatarSkinTone.light,
      hair: AvatarHair.longWaves,
      headwear: AvatarHeadwear.hijab,
      faceStyle: AvatarFaceStyle.brightEyes,
      background: AvatarBackground.marigold,
    ),
    AvatarOption(
      id: 'avatar-09',
      label: 'Avatar 9',
      description: 'deep skin, a full afro, and bold brows',
      presentation: AvatarPresentation.feminine,
      skinTone: AvatarSkinTone.deep,
      hair: AvatarHair.afro,
      faceStyle: AvatarFaceStyle.boldBrows,
      background: AvatarBackground.sage,
    ),
    AvatarOption(
      id: 'avatar-10',
      label: 'Avatar 10',
      description: 'tan skin, freckles, and a golden head wrap',
      presentation: AvatarPresentation.feminine,
      skinTone: AvatarSkinTone.tan,
      hair: AvatarHair.braids,
      headwear: AvatarHeadwear.headWrap,
      faceStyle: AvatarFaceStyle.freckles,
      background: AvatarBackground.sky,
    ),
    AvatarOption(
      id: 'avatar-11',
      label: 'Avatar 11',
      description: 'warm light skin, long waves, and a wide smile',
      presentation: AvatarPresentation.feminine,
      skinTone: AvatarSkinTone.warm,
      hair: AvatarHair.longWaves,
      hairColor: AvatarHairColor.darkBrown,
      faceStyle: AvatarFaceStyle.openSmile,
      background: AvatarBackground.lilac,
    ),
    AvatarOption(
      id: 'avatar-12',
      label: 'Avatar 12',
      description: 'light skin and a front-facing astronaut helmet',
      presentation: AvatarPresentation.feminine,
      skinTone: AvatarSkinTone.light,
      hair: AvatarHair.bob,
      hairColor: AvatarHairColor.chestnut,
      headwear: AvatarHeadwear.spaceHelmet,
      background: AvatarBackground.cream,
    ),
  ];

  static AvatarOption? byId(String? id) {
    if (id == null) return null;
    for (final option in all) {
      if (option.id == id) return option;
    }
    return null;
  }
}

/// A front-facing Curre profile avatar.
///
/// Give [avatarId] to use a catalogue face. Supplying any art parameter draws
/// a custom face (and can override a catalogue parameter). With neither, the
/// widget falls back to [initial] in a circle so an unset or retired ID never
/// leaves a blank profile button.
class Avatar extends StatefulWidget {
  const Avatar({
    super.key,
    this.avatarId,
    this.initial,
    this.size = 40,
    this.proofToday = false,
    this.skinTone,
    this.hair,
    this.hairColor,
    this.headwear,
    this.background,
    this.faceStyle,
    this.motion = AvatarMotion.still,
    this.expression = AvatarExpression.neutral,
    this.semanticLabel,
    this.framed = true,
  }) : assert(size > 0);

  final String? avatarId;
  final String? initial;
  final double size;
  final bool proofToday;
  final AvatarSkinTone? skinTone;
  final AvatarHair? hair;
  final AvatarHairColor? hairColor;
  final AvatarHeadwear? headwear;
  final AvatarBackground? background;
  final AvatarFaceStyle? faceStyle;
  final AvatarMotion motion;
  final AvatarExpression expression;
  final String? semanticLabel;

  /// Draws the round background and keeps the person inside it, as on the
  /// profile button. Off, only the person is drawn (head, hair and neck),
  /// so a scene can stand them on a body ([AvatarFigure]).
  final bool framed;

  @override
  State<Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late math.Random _random;
  var _blinkCenters = const <double>[];
  var _reduceMotion = false;
  var _tickerEnabled = true;

  bool get _hasCustomArt =>
      widget.skinTone != null ||
      widget.hair != null ||
      widget.hairColor != null ||
      widget.headwear != null ||
      widget.background != null ||
      widget.faceStyle != null;

  @override
  void initState() {
    super.initState();
    _random = math.Random(_motionSeed);
    _controller = AnimationController(vsync: this)
      ..addStatusListener(_handleStatus);
  }

  int get _motionSeed {
    var seed = 17;
    for (final codeUnit in widget.avatarId?.codeUnits ?? const <int>[]) {
      seed = (seed * 31 + codeUnit) & 0x7fffffff;
    }
    for (final index in <int>[
      widget.skinTone?.index ?? -1,
      widget.hair?.index ?? -1,
      widget.headwear?.index ?? -1,
      widget.faceStyle?.index ?? -1,
    ]) {
      seed = (seed * 31 + index + 1) & 0x7fffffff;
    }
    return seed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    final tickerEnabled = TickerMode.valuesOf(context).enabled;
    final changed = reduce != _reduceMotion || tickerEnabled != _tickerEnabled;
    _reduceMotion = reduce;
    _tickerEnabled = tickerEnabled;
    if (changed || !_controller.isAnimating) _syncMotion();
  }

  @override
  void didUpdateWidget(Avatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final identityChanged =
        widget.avatarId != oldWidget.avatarId ||
        widget.skinTone != oldWidget.skinTone ||
        widget.hair != oldWidget.hair ||
        widget.headwear != oldWidget.headwear ||
        widget.faceStyle != oldWidget.faceStyle;
    if (identityChanged) _random = math.Random(_motionSeed);
    final restartReaction =
        widget.motion == AvatarMotion.reactOnce &&
        (oldWidget.motion != widget.motion ||
            oldWidget.proofToday != widget.proofToday ||
            identityChanged);
    if (widget.motion != oldWidget.motion ||
        restartReaction ||
        identityChanged) {
      _syncMotion(restart: true);
    }
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        widget.motion == AvatarMotion.idle &&
        !_reduceMotion &&
        _tickerEnabled &&
        mounted) {
      _planIdleCycle();
      _controller.forward(from: 0);
    }
  }

  void _syncMotion({bool restart = false}) {
    if (_reduceMotion ||
        !_tickerEnabled ||
        widget.motion == AvatarMotion.still) {
      _controller.stop(canceled: false);
      if (_reduceMotion || widget.motion == AvatarMotion.still) {
        _controller.value = 0;
      }
      return;
    }
    if (widget.motion == AvatarMotion.reactOnce) {
      _controller.duration = const Duration(milliseconds: 900);
      if (restart || _controller.value == 0) {
        _controller.forward(from: 0);
      } else if (!_controller.isCompleted) {
        _controller.forward();
      }
      return;
    }
    if (restart || _controller.value == 0 || _controller.isCompleted) {
      _planIdleCycle();
      _controller.forward(from: 0);
    } else {
      _controller.forward();
    }
  }

  void _planIdleCycle() {
    _controller.duration = Duration(milliseconds: 6500 + _random.nextInt(3000));
    final first = .16 + _random.nextDouble() * .28;
    _blinkCenters = _random.nextBool()
        ? <double>[first]
        : <double>[first, .62 + _random.nextDouble() * .2];
  }

  double _pulse(double t, double center, double halfWidth) =>
      (1 - ((t - center).abs() / halfWidth)).clamp(0, 1).toDouble();

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preset = AvatarCatalog.byId(widget.avatarId);
    if (preset == null && !_hasCustomArt) {
      return _InitialAvatar(
        initial: widget.initial,
        size: widget.size,
        proofToday: widget.proofToday,
        semanticLabel: widget.semanticLabel,
      );
    }

    final resolved = preset ?? AvatarCatalog.all.first;
    final label =
        widget.semanticLabel ??
        '${preset?.semanticLabel ?? 'Custom profile avatar'}${widget.proofToday ? ', proof today' : ''}${widget.expression == AvatarExpression.sleepy ? ', sleepy' : ''}';
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: widget.size,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                var eyeOpen = 1.0;
                var headBob = 0.0;
                var breath = 1.0;
                var happy = widget.expression == AvatarExpression.happy
                    ? 1.0
                    : 0.0;
                if (!_reduceMotion && widget.motion == AvatarMotion.idle) {
                  final blink = _blinkCenters.fold<double>(
                    0,
                    (value, center) => math.max(value, _pulse(t, center, .022)),
                  );
                  eyeOpen = 1 - Curves.easeIn.transform(blink);
                  final loop = (1 - math.cos(t * math.pi * 2)) / 2;
                  headBob = -0.65 * loop;
                  breath = 1 + .006 * loop;
                } else if (!_reduceMotion &&
                    widget.motion == AvatarMotion.reactOnce) {
                  final reaction = math.sin(math.pi * t);
                  headBob = -1.2 * reaction;
                  breath = 1 + .012 * reaction;
                  happy = math.max(happy, reaction);
                }
                return CustomPaint(
                  painter: _AvatarPainter(
                    skin: (widget.skinTone ?? resolved.skinTone).color,
                    hair: widget.hair ?? resolved.hair,
                    hairColor: (widget.hairColor ?? resolved.hairColor).color,
                    headwear: widget.headwear ?? resolved.headwear,
                    faceStyle: widget.faceStyle ?? resolved.faceStyle,
                    background:
                        (widget.background ?? resolved.background).color,
                    proofToday: widget.proofToday,
                    framed: widget.framed,
                    ember:
                        Theme.of(context).extension<CurreColors>()?.ember ??
                        const Color(0xFFE85F2E),
                    eyeOpen: eyeOpen,
                    headBob: headBob,
                    breath: breath,
                    happy: happy,
                    sleepy: widget.expression == AvatarExpression.sleepy,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({
    required this.initial,
    required this.size,
    required this.proofToday,
    required this.semanticLabel,
  });

  final String? initial;
  final double size;
  final bool proofToday;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>() ?? CurreColors.light;
    final t = Theme.of(context).extension<CurreType>();
    final letter = _firstRune(initial);
    final label =
        semanticLabel ??
        '${letter == '?' ? 'Profile' : letter} initial${proofToday ? ', proof today' : ''}';
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.raised,
            shape: BoxShape.circle,
            border: Border.all(
              color: proofToday ? c.ember : c.ink,
              width: proofToday
                  ? math.max(2, size * .055)
                  : math.max(1.5, size * .04),
            ),
            boxShadow: proofToday
                ? [
                    BoxShadow(
                      color: c.ember.withValues(alpha: .22),
                      spreadRadius: math.max(1, size * .035),
                    ),
                  ]
                : null,
          ),
          child: Text(
            letter,
            style: (t?.label ?? const TextStyle()).copyWith(
              color: c.ink,
              fontSize: size * .42,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  static String _firstRune(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '?';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter({
    required this.skin,
    required this.hair,
    required this.hairColor,
    required this.headwear,
    required this.faceStyle,
    required this.background,
    required this.proofToday,
    required this.framed,
    required this.ember,
    required this.eyeOpen,
    required this.headBob,
    required this.breath,
    required this.happy,
    required this.sleepy,
  });

  final Color skin;
  final AvatarHair hair;
  final Color hairColor;
  final AvatarHeadwear headwear;
  final AvatarFaceStyle faceStyle;
  final Color background;
  final bool proofToday;
  final bool framed;
  final Color ember;
  final double eyeOpen;
  final double headBob;
  final double breath;
  final double happy;
  final bool sleepy;

  static const _outline = AvatarPalette.outline;

  Paint _fill(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  Paint _stroke([Color color = _outline, double width = 4.2]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  void _shape(Canvas canvas, Path path, Color color, {double width = 4.2}) {
    canvas.drawPath(path, _fill(color));
    canvas.drawPath(path, _stroke(_outline, width));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 100;
    canvas.save();
    canvas.scale(scale, scale);
    final circle = Path()..addOval(const Rect.fromLTWH(1.5, 1.5, 97, 97));
    if (framed) {
      canvas.clipPath(circle);
      canvas.drawPath(circle, _fill(background));
    }

    if (framed && proofToday) {
      canvas.drawCircle(
        const Offset(50, 50),
        46.4,
        _stroke(ember.withValues(alpha: .24), 6.5),
      );
      canvas.drawCircle(const Offset(50, 50), 46.4, _stroke(ember, 2.7));
    }

    // Only the person moves. The background and proof ring stay anchored so
    // the profile button never appears to wobble.
    canvas.save();
    canvas.translate(50, 50 + headBob);
    canvas.scale(breath * 1.04, breath * 1.04);
    canvas.translate(-50, -50);
    _drawBack(canvas);
    if (headwear != AvatarHeadwear.spaceHelmet &&
        headwear != AvatarHeadwear.screenHelmet) {
      _drawNeck(canvas);
    }
    if (!_coversEars) _drawEars(canvas);
    _drawFace(canvas);
    _drawFront(canvas);
    _drawFeatures(canvas);
    canvas.restore();

    canvas.restore();
  }

  bool get _coversEars =>
      headwear == AvatarHeadwear.hijab ||
      headwear == AvatarHeadwear.spaceHelmet ||
      headwear == AvatarHeadwear.screenHelmet;

  Path get _facePath => Path()
    ..moveTo(25, 47)
    ..cubicTo(25, 27, 35, 18, 50, 18)
    ..cubicTo(65, 18, 75, 27, 75, 47)
    ..lineTo(75, 62)
    ..cubicTo(74, 81, 63, 92, 50, 92)
    ..cubicTo(37, 92, 26, 81, 25, 62)
    ..close();

  void _drawBack(Canvas canvas) {
    if (headwear == AvatarHeadwear.hijab) {
      final hood = Path()
        ..moveTo(16, 94)
        ..cubicTo(16, 51, 17, 18, 50, 12)
        ..cubicTo(83, 18, 84, 51, 84, 94)
        ..close();
      _shape(canvas, hood, AvatarPalette.hijabBlue, width: 4.2);
      return;
    }
    if (headwear == AvatarHeadwear.racerHelmet) {
      final helmet = Path()
        ..moveTo(15, 72)
        ..lineTo(15, 48)
        ..cubicTo(15, 20, 30, 8, 50, 8)
        ..cubicTo(70, 8, 85, 20, 85, 48)
        ..lineTo(85, 72)
        ..lineTo(72, 72)
        ..lineTo(70, 40)
        ..cubicTo(61, 28, 39, 28, 30, 40)
        ..lineTo(28, 72)
        ..close();
      _shape(canvas, helmet, AvatarPalette.helmetGreen, width: 4.2);
      return;
    }
    if (headwear == AvatarHeadwear.screenHelmet) {
      final antenna = Path()
        ..moveTo(50, 14)
        ..lineTo(38, 3)
        ..moveTo(50, 14)
        ..lineTo(62, 3);
      canvas.drawPath(antenna, _stroke(_outline, 4.4));
      final shell = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(8, 11, 84, 84),
            const Radius.circular(17),
          ),
        );
      _shape(canvas, shell, AvatarPalette.screenMint, width: 4.8);
      final screen = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(17, 17, 66, 76),
            const Radius.circular(18),
          ),
        );
      _shape(canvas, screen, AvatarPalette.helmetCream, width: 3.4);
      return;
    }
    if (headwear == AvatarHeadwear.spaceHelmet) {
      final shell = Path()
        ..moveTo(10, 72)
        ..lineTo(12, 44)
        ..cubicTo(14, 19, 29, 7, 50, 7)
        ..cubicTo(71, 7, 86, 19, 88, 44)
        ..lineTo(90, 72)
        ..quadraticBezierTo(87, 90, 75, 97)
        ..lineTo(25, 97)
        ..quadraticBezierTo(13, 90, 10, 72)
        ..close();
      _shape(canvas, shell, AvatarPalette.helmetCream, width: 4.8);
      final visor = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(16, 15, 68, 78),
            const Radius.circular(29),
          ),
        );
      _shape(canvas, visor, AvatarPalette.visor, width: 3.4);
      final crownStripe = Path()
        ..moveTo(45, 8)
        ..lineTo(55, 8)
        ..lineTo(59, 18)
        ..quadraticBezierTo(50, 15, 41, 18)
        ..close();
      _shape(canvas, crownStripe, AvatarPalette.helmetBlue, width: 2.6);
      return;
    }
    if (headwear == AvatarHeadwear.headWrap) {
      final wrapBack = Path()
        ..moveTo(22, 46)
        ..cubicTo(20, 20, 33, 11, 50, 11)
        ..cubicTo(67, 11, 80, 20, 78, 46)
        ..close();
      _shape(canvas, wrapBack, AvatarPalette.wrapGold, width: 4.2);
      return;
    }

    switch (hair) {
      case AvatarHair.afro:
        final afro = Path()
          ..moveTo(15, 54)
          ..cubicTo(7, 36, 15, 17, 29, 13)
          ..cubicTo(35, 3, 46, 6, 50, 10)
          ..cubicTo(57, 3, 68, 7, 71, 14)
          ..cubicTo(87, 19, 92, 39, 84, 56)
          ..cubicTo(73, 67, 27, 67, 15, 54)
          ..close();
        _shape(canvas, afro, hairColor, width: 4.2);
        break;
      case AvatarHair.longWaves:
        final back = Path()
          ..moveTo(18, 94)
          ..lineTo(18, 45)
          ..cubicTo(18, 20, 31, 10, 50, 10)
          ..cubicTo(69, 10, 82, 20, 82, 45)
          ..lineTo(82, 94)
          ..cubicTo(70, 88, 65, 84, 62, 78)
          ..lineTo(38, 78)
          ..cubicTo(35, 84, 30, 88, 18, 94)
          ..close();
        _shape(canvas, back, hairColor, width: 4.2);
        break;
      case AvatarHair.bob:
        final back = Path()
          ..moveTo(18, 82)
          ..lineTo(20, 39)
          ..cubicTo(21, 18, 34, 10, 50, 10)
          ..cubicTo(66, 10, 79, 18, 80, 39)
          ..lineTo(82, 82)
          ..cubicTo(71, 88, 29, 88, 18, 82)
          ..close();
        _shape(canvas, back, hairColor, width: 4.2);
        break;
      case AvatarHair.braids:
      case AvatarHair.locs:
        final cap = Path()
          ..moveTo(22, 47)
          ..cubicTo(19, 24, 31, 11, 50, 11)
          ..cubicTo(69, 11, 81, 24, 78, 47)
          ..lineTo(69, 47)
          ..cubicTo(62, 32, 38, 32, 31, 47)
          ..close();
        _shape(canvas, cap, hairColor, width: 4);
        final braidStroke = _stroke(
          hairColor,
          hair == AvatarHair.braids ? 5.5 : 7,
        )..strokeCap = StrokeCap.round;
        for (final x in const [22.0, 28.0, 72.0, 78.0]) {
          final side = x < 50 ? -1.0 : 1.0;
          final path = Path()
            ..moveTo(x, 38)
            ..cubicTo(x + side * 4, 54, x - side * 3, 70, x + side, 91);
          canvas.drawPath(path, braidStroke);
          if (hair == AvatarHair.braids) {
            for (final y in const [52.0, 66.0, 80.0]) {
              canvas.drawCircle(
                Offset(x + side * 1.2, y),
                2.1,
                _fill(hairColor),
              );
            }
          }
        }
        break;
      case AvatarHair.short:
      case AvatarHair.curls:
        break;
    }
  }

  void _drawNeck(Canvas canvas) {
    final neck = Path()
      ..moveTo(39, 80)
      ..lineTo(38, 100)
      ..lineTo(62, 100)
      ..lineTo(61, 80)
      ..close();
    _shape(canvas, neck, skin, width: 3.2);
  }

  void _drawEars(Canvas canvas) {
    for (final x in const [24.5, 75.5]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 59), width: 13, height: 18),
        _fill(skin),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 59), width: 13, height: 18),
        _stroke(_outline, 3.2),
      );
    }
  }

  void _drawFace(Canvas canvas) => _shape(canvas, _facePath, skin, width: 4.5);

  void _drawFront(Canvas canvas) {
    if (headwear == AvatarHeadwear.hijab) {
      final opening = Path()
        ..moveTo(24, 51)
        ..cubicTo(24, 25, 35, 18, 50, 18)
        ..cubicTo(65, 18, 76, 25, 76, 51);
      canvas.drawPath(opening, _stroke(_outline, 4.2));
      final fold = Path()
        ..moveTo(24, 82)
        ..quadraticBezierTo(50, 92, 76, 82);
      canvas.drawPath(fold, _stroke(_outline, 3));
      return;
    }
    if (headwear == AvatarHeadwear.headWrap) {
      final band = Path()
        ..moveTo(22, 38)
        ..quadraticBezierTo(50, 29, 78, 38)
        ..lineTo(76, 50)
        ..quadraticBezierTo(50, 42, 24, 50)
        ..close();
      _shape(canvas, band, const Color(0xFFEBC45A), width: 3.4);
      final knot = Path()
        ..moveTo(40, 17)
        ..quadraticBezierTo(44, 5, 50, 14)
        ..quadraticBezierTo(57, 4, 61, 18)
        ..quadraticBezierTo(51, 27, 40, 17)
        ..close();
      _shape(canvas, knot, AvatarPalette.wrapGold, width: 3.5);
      return;
    }
    if (headwear == AvatarHeadwear.racerHelmet) {
      final stripe = Path()
        ..moveTo(43, 9)
        ..lineTo(56, 9)
        ..lineTo(63, 30)
        ..lineTo(51, 27)
        ..lineTo(38, 30)
        ..close();
      _shape(canvas, stripe, AvatarPalette.helmetRed, width: 2.6);
      canvas.drawCircle(const Offset(76, 40), 6, _fill(AvatarPalette.visor));
      canvas.drawCircle(const Offset(76, 40), 6, _stroke(_outline, 2.8));
      return;
    }
    if (headwear == AvatarHeadwear.aviatorGoggles) {
      final cap = Path()
        ..moveTo(20, 43)
        ..cubicTo(19, 20, 32, 10, 50, 10)
        ..cubicTo(68, 10, 81, 20, 80, 43)
        ..quadraticBezierTo(50, 33, 20, 43)
        ..close();
      _shape(canvas, cap, const Color(0xFF6F4736), width: 4);
      canvas.drawLine(
        const Offset(31, 31),
        const Offset(69, 31),
        _stroke(_outline, 4),
      );
      for (final x in const [39.0, 61.0]) {
        canvas.drawCircle(Offset(x, 31), 9, _fill(AvatarPalette.visor));
        canvas.drawCircle(Offset(x, 31), 9, _stroke(_outline, 3.4));
      }
      return;
    }
    if (headwear == AvatarHeadwear.screenHelmet) {
      final rim = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(17, 17, 66, 76),
            const Radius.circular(18),
          ),
        );
      canvas.drawPath(rim, _stroke(_outline, 4.2));
      for (final y in const [38.0, 49.0, 60.0]) {
        canvas.drawLine(Offset(87, y), Offset(90, y), _stroke(_outline, 2.6));
      }
      canvas.drawCircle(
        const Offset(88.5, 75),
        2.8,
        _fill(AvatarPalette.helmetRed),
      );
      return;
    }
    if (headwear == AvatarHeadwear.spaceHelmet) {
      final visorRim = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(16, 15, 68, 78),
            const Radius.circular(29),
          ),
        );
      canvas.drawPath(visorRim, _stroke(AvatarPalette.helmetBlue, 7.2));
      canvas.drawPath(visorRim, _stroke(_outline, 2.8));

      // A visible fringe makes the face read as a person at 32 dp instead of
      // a symbol floating inside a ring.
      final fringe = Path()
        ..moveTo(27, 43)
        ..quadraticBezierTo(36, 25, 50, 22)
        ..quadraticBezierTo(64, 25, 73, 43)
        ..quadraticBezierTo(61, 35, 50, 29)
        ..quadraticBezierTo(39, 35, 27, 43);
      canvas.drawPath(fringe, _stroke(hairColor, 8));

      final collar = Path()
        ..moveTo(22, 84)
        ..quadraticBezierTo(50, 98, 78, 84);
      canvas.drawPath(collar, _stroke(AvatarPalette.helmetBlue, 7));
      canvas.drawPath(collar, _stroke(_outline, 2.8));
      canvas.drawCircle(
        const Offset(81, 68),
        5.5,
        _fill(AvatarPalette.helmetRed),
      );
      canvas.drawCircle(const Offset(81, 68), 5.5, _stroke(_outline, 2.6));
      return;
    }

    switch (hair) {
      case AvatarHair.short:
        final top = Path()
          ..moveTo(27, 45)
          ..cubicTo(26, 24, 35, 15, 50, 15)
          ..cubicTo(65, 15, 74, 24, 73, 45)
          ..cubicTo(63, 36, 37, 36, 27, 45)
          ..close();
        _shape(canvas, top, hairColor, width: 3.8);
        break;
      case AvatarHair.curls:
        final centers = <Offset>[
          const Offset(29, 37),
          const Offset(34, 26),
          const Offset(43, 21),
          const Offset(53, 21),
          const Offset(63, 25),
          const Offset(71, 35),
        ];
        final curls = Path();
        for (final center in centers) {
          curls.addOval(Rect.fromCircle(center: center, radius: 10));
        }
        canvas.drawPath(curls, _fill(hairColor));
        canvas.drawPath(curls, _stroke(_outline, 3.2));
        break;
      case AvatarHair.afro:
        final hairline = Path()
          ..moveTo(27, 44)
          ..quadraticBezierTo(35, 34, 43, 41)
          ..quadraticBezierTo(50, 32, 57, 41)
          ..quadraticBezierTo(65, 34, 73, 44);
        canvas.drawPath(hairline, _stroke(hairColor, 8));
        break;
      case AvatarHair.braids:
      case AvatarHair.locs:
        final center = Path()
          ..moveTo(27, 45)
          ..quadraticBezierTo(36, 33, 50, 40)
          ..quadraticBezierTo(64, 33, 73, 45);
        canvas.drawPath(center, _stroke(hairColor, 8));
        break;
      case AvatarHair.longWaves:
        final part = Path()
          ..moveTo(27, 45)
          ..quadraticBezierTo(35, 24, 50, 20)
          ..quadraticBezierTo(65, 24, 73, 45)
          ..quadraticBezierTo(60, 37, 50, 28)
          ..quadraticBezierTo(40, 37, 27, 45);
        canvas.drawPath(part, _stroke(hairColor, 8));
        break;
      case AvatarHair.bob:
        final fringe = Path()
          ..moveTo(27, 44)
          ..quadraticBezierTo(37, 24, 50, 22)
          ..quadraticBezierTo(63, 24, 73, 44)
          ..quadraticBezierTo(60, 36, 50, 29)
          ..quadraticBezierTo(40, 36, 27, 44);
        canvas.drawPath(fringe, _stroke(hairColor, 8));
        break;
    }
  }

  void _drawFeatures(Canvas canvas) {
    // Centred, symmetrical eyes are the non-negotiable identity of the set.
    final eyeWidth = faceStyle == AvatarFaceStyle.brightEyes ? 6.8 : 5.5;
    final eyeHeight = faceStyle == AvatarFaceStyle.brightEyes ? 8.5 : 7.4;
    if (sleepy) {
      for (final x in const [40.5, 59.5]) {
        final eye = Path()
          ..moveTo(x - 3.4, 56)
          ..quadraticBezierTo(x, 59, x + 3.4, 56);
        canvas.drawPath(eye, _stroke(_outline, 2.8));
      }
    } else if (eyeOpen < .18) {
      for (final x in const [40.5, 59.5]) {
        canvas.drawLine(
          Offset(x - 3, 56),
          Offset(x + 3, 56),
          _stroke(_outline, 2.8),
        );
      }
    } else {
      for (final x in const [40.5, 59.5]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, 56),
            width: eyeWidth,
            height: math.max(1.5, eyeHeight * eyeOpen),
          ),
          _fill(_outline),
        );
        if (eyeOpen > .55) {
          canvas.drawCircle(
            Offset(x - .8, 54.6),
            faceStyle == AvatarFaceStyle.brightEyes ? 1.05 : .85,
            _fill(AvatarPalette.eyeLight),
          );
        }
      }
    }

    if (!sleepy && faceStyle == AvatarFaceStyle.boldBrows) {
      for (final x in const [40.5, 59.5]) {
        final brow = Path()
          ..moveTo(x - 4.1, 48.5)
          ..quadraticBezierTo(x, 46.5, x + 4.1, 48.5);
        canvas.drawPath(brow, _stroke(_outline, 3.2));
      }
    }

    final nose = Path()
      ..moveTo(50, 58)
      ..quadraticBezierTo(48.7, 64, 51.8, 64);
    canvas.drawPath(nose, _stroke(_outline.withValues(alpha: .72), 2));

    if (faceStyle == AvatarFaceStyle.freckles) {
      for (final x in const [34.0, 37.5, 41.0, 59.0, 62.5, 66.0]) {
        final y = x < 50
            ? 64 + (x - 37.5).abs() * .12
            : 64 + (x - 62.5).abs() * .12;
        canvas.drawCircle(
          Offset(x, y),
          1.05,
          _fill(_outline.withValues(alpha: .65)),
        );
      }
    }

    if (sleepy) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(50, 71), width: 4.5, height: 5.5),
        _stroke(_outline, 2.5),
      );
    } else if (faceStyle == AvatarFaceStyle.openSmile) {
      final mouth = Rect.fromCenter(
        center: Offset(50, 71 + happy),
        width: 12.5 + happy * 2,
        height: 7.5 + happy * 1.5,
      );
      canvas.drawOval(mouth, _fill(_outline));
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(50, 72.4 + happy),
          width: 7.5,
          height: 3.6,
        ),
        0,
        math.pi,
        false,
        _stroke(AvatarPalette.eyeLight, 1.8),
      );
    } else {
      final smile = Path()
        ..moveTo(43.5 - happy * 1.8, 70 - happy * .7)
        ..quadraticBezierTo(
          50,
          76 + happy * 2.5,
          56.5 + happy * 1.8,
          70 - happy * .7,
        );
      canvas.drawPath(smile, _stroke(_outline, 3 + happy * .35));
    }

    if (!sleepy && faceStyle == AvatarFaceStyle.dimples) {
      for (final x in const [39.3, 60.7]) {
        canvas.drawCircle(
          const Offset(0, 72).translate(x, 0),
          1.25,
          _fill(_outline.withValues(alpha: .68)),
        );
      }
    }
    canvas.drawCircle(
      Offset(35, 67 - happy * 1.7),
      2.2 + happy * .45,
      _fill(AvatarPalette.cheek.withValues(alpha: .42 + happy * .18)),
    );
    canvas.drawCircle(
      Offset(65, 67 - happy * 1.7),
      2.2 + happy * .45,
      _fill(AvatarPalette.cheek.withValues(alpha: .42 + happy * .18)),
    );
  }

  @override
  bool shouldRepaint(_AvatarPainter oldDelegate) =>
      skin != oldDelegate.skin ||
      hair != oldDelegate.hair ||
      hairColor != oldDelegate.hairColor ||
      headwear != oldDelegate.headwear ||
      faceStyle != oldDelegate.faceStyle ||
      background != oldDelegate.background ||
      proofToday != oldDelegate.proofToday ||
      framed != oldDelegate.framed ||
      ember != oldDelegate.ember ||
      eyeOpen != oldDelegate.eyeOpen ||
      headBob != oldDelegate.headBob ||
      breath != oldDelegate.breath ||
      happy != oldDelegate.happy ||
      sleepy != oldDelegate.sleepy;
}
