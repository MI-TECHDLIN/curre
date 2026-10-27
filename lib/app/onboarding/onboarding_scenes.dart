import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../design/design.dart';
import '../../doors/door_models.dart';
import '../app_widgets.dart';
import '../curre_controller.dart';
import 'onboarding_parts.dart';

/// The illustrations of onboarding's twelve steps. Each one is a small scene
/// on a 390 × 250 design canvas ([SceneCanvas]) built from Curre's own
/// pieces: Peek, the avatar people ([AvatarFigure]), the user's own apps,
/// flat props ([CurrePropArt]) and sticker cards. The words on a step are
/// always outside its picture, so the art is decorative for TalkBack and
/// carries one short description instead.

const _paper = Color(0xFFFFFDF9);
const _marker = Color(0xFFFBE1A0);
const _ember = Color(0xFFE85F2E);
const _cardPink = Color(0xFFF7D3CC);
const _cardBlue = Color(0xFFCFE2F4);
const _cardGreen = Color(0xFFDDE9CF);

/// Wraps a scene with its description and entrance.
class _Scene extends StatelessWidget {
  const _Scene({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: label,
      excludeSemantics: true,
      child: SceneEntrance(child: SceneCanvas(children: children)),
    );
  }
}

/// Places [child] at [left], [top] on the canvas inside layer [order] of
/// the entrance, optionally turned by [angle] radians and floating.
Widget _at(
  double left,
  double top, {
  required Widget child,
  int order = 0,
  double angle = 0,
  double float = 0,
  double phase = 0,
}) {
  Widget content = angle == 0 ? child : Transform.rotate(angle: angle, child: child);
  if (float > 0) {
    content = SceneFloat(amplitude: float, phase: phase, child: content);
  }
  return Positioned(
    left: left,
    top: top,
    child: RiseIn(order: order, child: content),
  );
}

Widget _blob(StagePalette palette, Rect rect, {int seed = 3, Color? color}) =>
    Positioned.fromRect(
      rect: rect,
      child: RiseIn(
        order: 0,
        distance: 6,
        child: SceneBlob(color: color ?? palette.glow, seed: seed),
      ),
    );

Widget _horizon(StagePalette palette, double y) => Positioned(
  left: -40,
  right: -40,
  top: y,
  bottom: -60,
  child: Column(
    children: [
      Container(height: 2, color: palette.ink),
      Expanded(child: ColoredBox(color: palette.deep)),
    ],
  ),
);

TextStyle _sceneType(
  BuildContext context, {
  double size = 12,
  double weight = 600,
  Color color = sceneInk,
  bool you = false,
  bool mono = false,
}) {
  final type = Theme.of(context).extension<CurreType>()!;
  final base = you ? type.you : (mono ? type.meta : type.label);
  return base
      .weight(you ? 430 : weight)
      .copyWith(fontSize: size, height: 1.2, color: color, letterSpacing: 0);
}

// ---------------------------------------------------------------------------
// 1 · The problem: one quick look, an hour gone.

class StoryScene extends StatelessWidget {
  const StoryScene({super.key, required this.palette});

  final StagePalette palette;

  @override
  Widget build(BuildContext context) {
    return _Scene(
      label:
          'Late at night, a phone full of posts pulls a note that says “just check the bus time” into a tangle of yarn, while the sun is still asleep.',
      children: [
        _blob(palette, const Rect.fromLTWH(118, -4, 248, 226), seed: 5),
        for (final (x, y, s) in const [
          (34.0, 22.0, 13.0),
          (92.0, 6.0, 9.0),
          (360.0, 108.0, 10.0),
          (24.0, 128.0, 8.0),
          (238.0, 8.0, 8.0),
        ])
          _at(
            x,
            y,
            order: 1,
            child: CurrePropArt(CurreProp.star, size: s, outline: 0),
          ),
        _at(
          316,
          4,
          order: 1,
          float: 2.5,
          child: const CurrePropArt(CurreProp.crescentMoon, size: 54),
        ),
        _horizon(palette, 214),
        // Peek, asleep under the horizon: the sun isn't up yet.
        Positioned(
          left: 286,
          top: 150,
          width: 92,
          height: 64,
          child: RiseIn(
            order: 2,
            distance: 10,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: 92,
                child: const PeekMascot(
                  size: 92,
                  animate: false,
                  groundShadow: false,
                  lit: .32,
                  rays: 0,
                  eyesOpen: 0,
                  semanticLabel: null,
                ),
              ),
            ),
          ),
        ),
        _at(
          346,
          132,
          order: 3,
          float: 3,
          phase: .3,
          child: const CurrePropArt(CurreProp.zzz, size: 30, outline: 1.5),
        ),
        Positioned.fill(
          child: RiseIn(
            order: 2,
            distance: 0,
            child: const CustomPaint(painter: _ThreadPainter(color: _ember)),
          ),
        ),
        _at(
          16,
          36,
          order: 2,
          angle: -.08,
          child: SceneCard(
            color: _marker,
            radius: 6,
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 11),
            child: SizedBox(
              width: 92,
              child: Text(
                'Just check the bus time',
                style: _sceneType(context, size: 15, you: true),
              ),
            ),
          ),
        ),
        _at(
          142,
          14,
          order: 3,
          angle: .05,
          child: const ScenePhone(
            width: 116,
            height: 214,
            screen: _FeedScreen(),
          ),
        ),
        _at(
          62,
          146,
          order: 4,
          angle: -.1,
          child: const CurrePropArt(CurreProp.yarn, size: 66),
        ),
        _at(
          240,
          58,
          order: 5,
          angle: .07,
          child: SceneCard(
            radius: 30,
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CurrePropArt(CurreProp.alarmClock, size: 24, outline: 0),
                const SizedBox(width: 5),
                Text.rich(
                  TextSpan(
                    style: _sceneType(context, size: 11.5, mono: true),
                    children: [
                      const TextSpan(text: '23:02 '),
                      TextSpan(
                        text: '→',
                        style: _sceneType(context, size: 12, weight: 700),
                      ),
                      const TextSpan(text: ' 00:41'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _at(
          262,
          110,
          order: 6,
          float: 3,
          child: const CurrePropArt(CurreProp.heart, size: 28),
        ),
        _at(
          300,
          102,
          order: 6,
          float: 2.5,
          phase: .5,
          child: const CurrePropArt(CurreProp.popcorn, size: 30),
        ),
      ],
    );
  }
}

/// The thread from the note: into the phone, out again, tangled.
class _ThreadPainter extends CustomPainter {
  const _ThreadPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final into = Path()
      ..moveTo(84, 104)
      ..cubicTo(98, 150, 132, 106, 166, 120);
    canvas.drawPath(into, paint);
    // Out of the phone's lower edge and into a knot round the yarn.
    final tangle = Path()
      ..moveTo(158, 200)
      ..cubicTo(150, 214, 128, 212, 124, 198)
      ..cubicTo(120, 184, 144, 180, 142, 194)
      ..cubicTo(140, 210, 112, 214, 106, 200)
      ..cubicTo(100, 186, 126, 176, 130, 190)
      ..cubicTo(134, 204, 110, 222, 98, 208)
      ..cubicTo(88, 196, 104, 182, 116, 190);
    canvas.drawPath(tangle, paint);
  }

  @override
  bool shouldRepaint(covariant _ThreadPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// An endless feed that scrolls slowly on the phone in the first scene.
class _FeedScreen extends StatefulWidget {
  const _FeedScreen();

  @override
  State<_FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<_FeedScreen>
    with SingleTickerProviderStateMixin {
  static const _post = 74.0;
  static const _posts = <(String, Color, CurreProp?)>[
    ('avatar-02', _cardPink, CurreProp.heart),
    ('avatar-07', _cardBlue, null),
    ('avatar-10', _cardGreen, CurreProp.musicalNotes),
    ('avatar-04', _marker, CurreProp.popcorn),
  ];

  late final AnimationController _scroll = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll
        ..stop()
        ..value = .18;
    } else if (!_scroll.isAnimating) {
      _scroll.repeat();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final column = Column(
      children: [
        for (var round = 0; round < 2; round++)
          for (final (avatar, tint, prop) in _posts)
            SizedBox(
              height: _post,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 6, 7, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Avatar(avatarId: avatar, size: 13),
                        const SizedBox(width: 4),
                        Container(
                          width: 34,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D0C4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: tint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: prop == null
                            ? const _PlayMark()
                            : CurrePropArt(prop, size: 22, outline: 1),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
      ],
    );
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: double.infinity,
              child: AnimatedBuilder(
                animation: _scroll,
                child: column,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, 22 - _scroll.value * _post * _posts.length),
                  child: child,
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 20,
          child: ColoredBox(color: _paper),
        ),
      ],
    );
  }
}

class _PlayMark extends StatelessWidget {
  const _PlayMark();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size.square(22), painter: _PlayPainter());
}

class _PlayPainter extends CustomPainter {
  const _PlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, size.width / 2, Paint()..color = sceneInk);
    final r = size.width * .2;
    final triangle = Path()
      ..moveTo(c.dx - r * .7, c.dy - r)
      ..lineTo(c.dx + r * 1.1, c.dy)
      ..lineTo(c.dx - r * .7, c.dy + r)
      ..close();
    canvas.drawPath(triangle, Paint()..color = _paper);
  }

  @override
  bool shouldRepaint(covariant _PlayPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 2 · Privacy: your life stays on the phone; the words you type are read,
// then forgotten.

class PrivacyScene extends StatelessWidget {
  const PrivacyScene({super.key, required this.palette});

  final StagePalette palette;

  @override
  Widget build(BuildContext context) {
    return _Scene(
      label:
          'A phone keeps your contacts, chats and history safe behind a shield, while one typed sentence floats up to a cloud and fades away.',
      children: [
        _blob(palette, const Rect.fromLTWH(30, 4, 300, 232), seed: 9),
        Positioned.fill(
          child: RiseIn(
            order: 3,
            distance: 0,
            child: CustomPaint(painter: _DottedArcPainter(color: palette.ink)),
          ),
        ),
        _at(
          58,
          14,
          order: 1,
          angle: -.04,
          child: const ScenePhone(
            width: 124,
            height: 222,
            screen: _PhoneKeepsScreen(),
          ),
        ),
        _at(
          14,
          140,
          order: 2,
          float: 2.5,
          child: const CurrePropArt(CurreProp.shield, size: 80),
        ),
        _at(
          196,
          118,
          order: 3,
          angle: -.05,
          float: 3,
          phase: .4,
          child: SceneCard(
            radius: 16,
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
            child: SizedBox(
              width: 136,
              child: Text(
                '“Learn the G chord on YouTube till 7”',
                style: _sceneType(context, size: 13.5, you: true),
              ),
            ),
          ),
        ),
        _at(
          274,
          6,
          order: 4,
          float: 2,
          child: const CurrePropArt(CurreProp.cloud, size: 92),
        ),
        _at(
          346,
          70,
          order: 5,
          float: 2,
          phase: .6,
          child: const CurrePropArt(CurreProp.sparkles, size: 34),
        ),
      ],
    );
  }
}

class _DottedArcPainter extends CustomPainter {
  const _DottedArcPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(186, 128)
      ..cubicTo(214, 60, 252, 60, 288, 52);
    final paint = Paint()..color = color.withValues(alpha: .7);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null) canvas.drawCircle(tangent.position, 1.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedArcPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// What the phone keeps to itself: people, chats, days and app use.
class _PhoneKeepsScreen extends StatelessWidget {
  const _PhoneKeepsScreen();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, [Color color = const Color(0xFFD9D0C4)]) =>
        Container(
          width: width,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
    Widget bubble(Color color, double width, {bool right = false}) => Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: width,
        height: 16,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final id in const ['avatar-03', 'avatar-08', 'avatar-11'])
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Avatar(avatarId: id, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 8),
          bubble(_cardBlue, 70),
          bubble(_cardPink, 56, right: true),
          bubble(_cardBlue, 48),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: i.isEven ? _marker : const Color(0xFFEEE7DC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final h in const [14.0, 24.0, 10.0, 30.0, 18.0, 22.0])
                Container(
                  width: 9,
                  height: h,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: _cardGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          bar(64),
          const SizedBox(height: 4),
          bar(40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3 · The apps that pull you in, drawn toward a magnet. When the user
// moves on they sink below the horizon: off Home.

class PullScene extends StatelessWidget {
  const PullScene({
    super.key,
    required this.palette,
    required this.controller,
    required this.apps,
    this.sinking = false,
  });

  final StagePalette palette;
  final CurreController controller;
  final List<LaunchableApp> apps;
  final bool sinking;

  static const _spots = <(double, double, double, double)>[
    (40, 112, 52, -.16),
    (92, 54, 50, .1),
    (150, 124, 54, -.06),
    (196, 64, 50, .14),
    (226, 132, 46, -.1),
  ];

  @override
  Widget build(BuildContext context) {
    final shown = apps.take(_spots.length).toList(growable: false);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return _Scene(
      label: shown.isEmpty
          ? 'A magnet waits for the apps that pull you in.'
          : 'A magnet pulls ${shown.map((app) => app.label).join(', ')}.',
      children: [
        _blob(palette, const Rect.fromLTWH(26, 0, 330, 220), seed: 2),
        _horizon(palette, 216),
        _at(
          258,
          28,
          order: 1,
          float: 2,
          child: Transform.rotate(
            angle: math.pi / 2,
            child: const CurrePropArt(CurreProp.magnet, size: 116),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          height: 215,
          child: ClipRect(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: sinking ? 1 : 0),
              duration: reduce ? Duration.zero : CurreMotion.set * 2,
              curve: CurreMotion.setCurve,
              builder: (context, sink, child) => Transform.translate(
                offset: Offset(0, sink * 150),
                child: child,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final (i, (x, y, size, angle)) in _spots.indexed)
                    _at(
                      x,
                      y,
                      order: 2 + i,
                      angle: angle,
                      float: 3,
                      phase: i * .17,
                      child: i < shown.length
                          ? _PulledTile(
                              lines: palette.ink,
                              child: SceneAppTile(
                                controller: controller,
                                packageName: shown[i].packageName,
                                label: shown[i].label,
                                size: size,
                              ),
                            )
                          : i < 3 && shown.isEmpty
                          ? _GhostTile(size: size, ink: palette.ink)
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PulledTile extends StatelessWidget {
  const _PulledTile({required this.child, required this.lines});

  final Widget child;
  final Color lines;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Motion lines trail behind, away from the magnet.
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final w in const [14.0, 20.0, 12.0])
              Container(
                width: w,
                height: 3,
                margin: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: lines.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
        const SizedBox(width: 5),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0x331E1A16), offset: Offset(3, 4)),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

class _GhostTile extends StatelessWidget {
  const _GhostTile({required this.size, required this.ink});

  final double size;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 19),
      child: CustomPaint(
        painter: _DashedRoundRectPainter(color: ink.withValues(alpha: .6)),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              '?',
              style: _sceneType(
                context,
                size: size * .42,
                weight: 760,
                color: ink.withValues(alpha: .7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRoundRectPainter extends CustomPainter {
  const _DashedRoundRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.width * .3),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundRectPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ---------------------------------------------------------------------------
// 4 · Your name, on a "hello, my name is" sticker and in the greeting.

class NameScene extends StatelessWidget {
  const NameScene({super.key, required this.palette, required this.name});

  final StagePalette palette;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final shown = name;
    return _Scene(
      label: shown == null
          ? 'A blank “hello, my name is” sticker, waiting for your name.'
          : 'A “hello, my name is” sticker that says $shown.',
      children: [
        _blob(palette, const Rect.fromLTWH(40, 0, 310, 230), seed: 7),
        _at(
          56,
          30,
          order: 1,
          angle: -.07,
          child: SceneCard(
            radius: 18,
            outline: 2.2,
            shadow: const Offset(6, 7),
            child: SizedBox(
              width: 226,
              height: 156,
              child: Column(
                children: [
                  Container(
                    height: 58,
                    width: double.infinity,
                    color: _ember,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'HELLO',
                          style: _sceneType(
                            context,
                            size: 25,
                            weight: 860,
                            color: _paper,
                          ).copyWith(letterSpacing: 2.5, height: 1),
                        ),
                        Text(
                          'my name is',
                          style: _sceneType(
                            context,
                            size: 11.5,
                            weight: 600,
                            color: _paper,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            shown ?? 'your name',
                            maxLines: 1,
                            style: _sceneType(
                              context,
                              size: 40,
                              you: true,
                              color: shown == null
                                  ? const Color(0xFFB5ABA0)
                                  : sceneInk,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _at(
          58,
          14,
          order: 2,
          angle: -.3,
          child: const CurrePropArt(CurreProp.pin, size: 40),
        ),
        _at(
          196,
          176,
          order: 3,
          float: 2.5,
          child: SceneCard(
            radius: 30,
            padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Avatar(initial: shown ?? 'C', size: 24),
                const SizedBox(width: 7),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    shown == null ? 'Good morning' : 'Good morning, $shown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _sceneType(context, size: 11.5, weight: 680),
                  ),
                ),
              ],
            ),
          ),
        ),
        _at(
          296,
          70,
          order: 4,
          float: 2,
          phase: .3,
          child: const CurrePropArt(CurreProp.hotDrink, size: 70),
        ),
        _at(
          24,
          178,
          order: 4,
          float: 2,
          phase: .7,
          child: const CurrePropArt(CurreProp.sparkles, size: 36),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5 · The chosen face, standing in the light and waving.

class FaceScene extends StatelessWidget {
  const FaceScene({
    super.key,
    required this.palette,
    required this.avatarId,
    required this.initial,
  });

  final StagePalette palette;
  final String? avatarId;
  final String? initial;

  @override
  Widget build(BuildContext context) {
    return _Scene(
      label: avatarId == null
          ? 'Your initial, waving hello.'
          : 'The face you picked, waving hello.',
      children: [
        Positioned(
          left: 82,
          top: 6,
          width: 226,
          height: 226,
          child: RiseIn(
            order: 0,
            distance: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.glow,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Positioned(
          left: 104,
          top: 28,
          width: 182,
          height: 182,
          child: RiseIn(
            order: 0,
            distance: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.ink.withValues(alpha: .18),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        _at(
          102,
          34,
          order: 1,
          child: AvatarFigure(
            key: ValueKey(avatarId),
            avatarId: avatarId,
            initial: initial,
            pose: FigurePose.wave,
            height: 236,
            motion: AvatarMotion.reactOnce,
            expression: avatarId == null
                ? AvatarExpression.neutral
                : AvatarExpression.happy,
          ),
        ),
        _at(
          62,
          36,
          order: 2,
          float: 2.5,
          child: const CurrePropArt(CurreProp.sparkles, size: 40),
        ),
        _at(
          304,
          120,
          order: 3,
          float: 2,
          phase: .5,
          child: const CurrePropArt(CurreProp.star, size: 30),
        ),
        _at(
          44,
          150,
          order: 3,
          float: 2,
          phase: .2,
          child: const CurrePropArt(CurreProp.heart, size: 26),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 6 · Morning: Peek rises and wakes as the chosen start gets later.

class MorningScene extends StatelessWidget {
  const MorningScene({super.key, required this.palette, required this.start});

  final StagePalette palette;
  final LocalTime start;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final sky = colors.sky(Session.morning);
    final target =
        ((start.minutesAfterMidnight - 4 * 60) / (3 * 60)).clamp(0.0, 1.0);
    return _Scene(
      label: 'The sun rising at $start.',
      children: [
        _blob(palette, const Rect.fromLTWH(0, 20, 390, 210), seed: 4),
        Positioned(
          left: 22,
          top: 4,
          width: 346,
          height: 244,
          child: RiseIn(
            order: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: sceneInk, width: 2.2),
                boxShadow: const [
                  BoxShadow(color: Color(0x381E1A16), offset: Offset(6, 7)),
                ],
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: target),
                duration: CurreMotion.of(context, CurreMotion.sky),
                curve: CurreMotion.standard,
                builder: (context, t, _) => SkyScene(
                  session: Session.morning,
                  borderRadius: BorderRadius.circular(26),
                  groundHeight: 62,
                  sunAt: .74,
                  sunSize: 112,
                  sunRise: .2 + .8 * t,
                  lit: .45 + .55 * t,
                  rays: t,
                  eyesOpen: .25 + .75 * t,
                  animatePeek: t > .5,
                  live: true,
                  keepClear: const Rect.fromLTWH(0, 0, 170, 110),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      start.toString(),
                      style: Theme.of(context)
                          .extension<CurreType>()!
                          .figureXL
                          .copyWith(fontSize: 54, height: 1, color: sky.fg),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _at(
          48,
          176,
          order: 2,
          angle: -.08,
          child: const CurrePropArt(CurreProp.alarmClock, size: 56),
        ),
        _at(
          110,
          192,
          order: 3,
          child: const CurrePropArt(CurreProp.hotDrink, size: 42),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 7 · Curre as the home screen: a calm Home on the phone, and you.

class HomeScene extends StatelessWidget {
  const HomeScene({
    super.key,
    required this.palette,
    required this.controller,
    required this.name,
    required this.avatarId,
  });

  final StagePalette palette;
  final CurreController controller;
  final String? name;
  final String? avatarId;

  @override
  Widget build(BuildContext context) {
    return _Scene(
      label:
          'A phone showing Curre’s calm home screen: a greeting, one plan and two apps that open right at the task.',
      children: [
        _blob(palette, const Rect.fromLTWH(20, 10, 320, 226), seed: 12),
        _at(
          18,
          112,
          order: 1,
          float: 2.5,
          child: const CurrePropArt(CurreProp.house, size: 88),
        ),
        _at(
          112,
          10,
          order: 2,
          child: ScenePhone(
            width: 152,
            height: 268,
            screen: _MiniHome(
              controller: controller,
              name: name,
              avatarId: avatarId,
            ),
          ),
        ),
        _at(
          252,
          98,
          order: 3,
          child: AvatarFigure(
            avatarId: avatarId,
            initial: name,
            pose: FigurePose.relaxed,
            height: 168,
          ),
        ),
        _at(
          316,
          22,
          order: 4,
          float: 2,
          child: const CurrePropArt(CurreProp.sparkles, size: 36),
        ),
      ],
    );
  }
}

class _MiniHome extends StatelessWidget {
  const _MiniHome({
    required this.controller,
    required this.name,
    required this.avatarId,
  });

  final CurreController controller;
  final String? name;
  final String? avatarId;

  @override
  Widget build(BuildContext context) {
    Widget door(Color tint, String package, String app, String to) =>
        Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              SceneAppTile(
                controller: controller,
                packageName: package,
                label: app,
                size: 18,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app, style: _sceneType(context, size: 8, weight: 700)),
                    Text(
                      to,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _sceneType(context, size: 6.8, weight: 520),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name == null ? 'Good morning' : 'Good morning, $name',
                  maxLines: 2,
                  style: _sceneType(context, size: 10.5, weight: 740),
                ),
              ),
              Avatar(avatarId: avatarId, initial: name ?? 'C', size: 20),
            ],
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFCC35A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Learn the G chord on YouTube till 7',
              style: _sceneType(context, size: 8.6, you: true),
            ),
          ),
          const SizedBox(height: 7),
          door(_cardPink, 'com.google.android.youtube', 'YouTube',
              '→ Search “G chord”'),
          door(_cardBlue, 'com.spotify.music', 'Spotify',
              '→ Search “worship”'),
          const Spacer(),
          Container(height: 1.5, color: sceneInk),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final glyph in const [
                CurreGlyphKind.phone,
                CurreGlyphKind.messages,
                CurreGlyphKind.androidSettings,
                CurreGlyphKind.curreSettings,
              ])
                CurreGlyph(glyph, size: 11, color: sceneInk),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '12 hidden apps',
            textAlign: TextAlign.center,
            style: _sceneType(context, size: 6.5, weight: 560),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 8 · Apps that sneak back in: one of the user's own pull apps slips out of
// the recent apps list, a notification and a shared link point at it, and
// a sticker asks "Why now?".

class SneakScene extends StatelessWidget {
  const SneakScene({
    super.key,
    required this.palette,
    required this.controller,
    required this.app,
  });

  final StagePalette palette;
  final CurreController controller;

  /// The app shown sneaking back: the first one the user said pulls them
  /// in, or a familiar example.
  final LaunchableApp app;

  @override
  Widget build(BuildContext context) {
    return _Scene(
      label:
          '${app.label} slips back in from a notification, a shared link and the recent apps list, and Curre asks: Why now?',
      children: [
        _blob(palette, const Rect.fromLTWH(34, 2, 320, 230), seed: 8),
        Positioned.fill(
          child: RiseIn(
            order: 4,
            distance: 0,
            child: CustomPaint(painter: _SneakTrailPainter(color: palette.ink)),
          ),
        ),
        _at(
          138,
          10,
          order: 1,
          angle: -.03,
          child: const ScenePhone(
            width: 128,
            height: 232,
            screenColor: Color(0xFF3B3F5E),
            screen: _RecentAppsScreen(),
          ),
        ),
        _at(
          10,
          34,
          order: 2,
          angle: -.06,
          float: 2,
          child: SceneCard(
            radius: 14,
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SceneAppTile(
                  controller: controller,
                  packageName: app.packageName,
                  label: app.label,
                  size: 26,
                ),
                const SizedBox(width: 7),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${app.label} · now',
                      style: _sceneType(
                        context,
                        size: 8.5,
                        weight: 520,
                        color: const Color(0xFF6E6257),
                      ),
                    ),
                    Text(
                      '3 new posts',
                      style: _sceneType(context, size: 11.5, weight: 720),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _at(
          4,
          18,
          order: 3,
          angle: -.3,
          child: const CurrePropArt(CurreProp.bell, size: 30),
        ),
        _at(
          26,
          150,
          order: 3,
          angle: .05,
          float: 2.5,
          phase: .3,
          child: SceneCard(
            radius: 30,
            padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CurrePropArt(CurreProp.envelope, size: 24, outline: 0),
                const SizedBox(width: 6),
                Text(
                  'a shared link',
                  style: _sceneType(context, size: 11, mono: true),
                ),
              ],
            ),
          ),
        ),
        _at(
          226,
          104,
          order: 5,
          angle: .12,
          float: 3,
          phase: .5,
          child: _PulledTile(
            lines: palette.ink,
            child: SceneAppTile(
              controller: controller,
              packageName: app.packageName,
              label: app.label,
              size: 56,
            ),
          ),
        ),
        _at(
          238,
          24,
          order: 6,
          angle: .06,
          child: SceneCard(
            color: _marker,
            radius: 18,
            padding: const EdgeInsets.fromLTRB(12, 9, 14, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CurrePropArt(
                  CurreProp.speechBalloon,
                  size: 24,
                  outline: 0,
                ),
                const SizedBox(width: 6),
                Text(
                  'Why now?',
                  style: _sceneType(context, size: 16, weight: 760),
                ),
              ],
            ),
          ),
        ),
        _at(
          342,
          176,
          order: 7,
          float: 2,
          phase: .2,
          child: const CurrePropArt(CurreProp.sparkles, size: 32),
        ),
      ],
    );
  }
}

/// Dotted trails from the notification and the link to the phone.
class _SneakTrailPainter extends CustomPainter {
  const _SneakTrailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paths = [
      Path()
        ..moveTo(130, 70)
        ..cubicTo(146, 80, 150, 96, 160, 108),
      Path()
        ..moveTo(146, 166)
        ..cubicTo(156, 160, 158, 150, 166, 140),
    ];
    final paint = Paint()..color = color.withValues(alpha: .7);
    for (final path in paths) {
      for (final metric in path.computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 8) {
          final tangent = metric.getTangentForOffset(d);
          if (tangent != null) canvas.drawCircle(tangent.position, 1.7, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SneakTrailPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Android's recent apps on the phone: two cards, one leaving.
class _RecentAppsScreen extends StatelessWidget {
  const _RecentAppsScreen();

  @override
  Widget build(BuildContext context) {
    Widget card(Color tint) => Container(
      width: 74,
      height: 128,
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          for (final w in const [52.0, 40.0, 58.0, 30.0])
            Container(
              width: w,
              height: 4,
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D0C4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(-14, 6),
          child: Transform.rotate(angle: -.08, child: card(_cardGreen)),
        ),
        Transform.translate(
          offset: const Offset(10, -2),
          child: Transform.rotate(angle: .05, child: card(_cardBlue)),
        ),
        Positioned(
          bottom: 14,
          child: Container(
            width: 30,
            height: 3,
            decoration: BoxDecoration(
              color: _paper.withValues(alpha: .7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 9 · Hidden apps kept quiet: their notifications wait, asleep, beside a
// calm lock screen where only Home's apps get through, until the user
// brings them back.

class QuietScene extends StatelessWidget {
  const QuietScene({
    super.key,
    required this.palette,
    required this.controller,
    required this.apps,
  });

  final StagePalette palette;
  final CurreController controller;

  /// Hidden apps whose notifications wait quietly; the first two show.
  final List<LaunchableApp> apps;

  @override
  Widget build(BuildContext context) {
    final waiting = apps.take(2).toList(growable: false);
    return _Scene(
      label:
          'A calm lock screen where only a message gets through, while notifications from ${waiting.map((app) => app.label).join(' and ')} sleep quietly beside it until you bring them back.',
      children: [
        _blob(palette, const Rect.fromLTWH(24, 6, 330, 226), seed: 6),
        _at(
          18,
          30,
          order: 1,
          angle: -.12,
          float: 2,
          child: const CurrePropArt(CurreProp.bell, size: 72),
        ),
        _at(
          70,
          20,
          order: 2,
          float: 2.5,
          phase: .4,
          child: const CurrePropArt(CurreProp.zzz, size: 34, outline: 1.5),
        ),
        _at(
          6,
          150,
          order: 2,
          angle: -.05,
          child: SceneCard(
            radius: 30,
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: Text(
              'shh… waiting',
              style: _sceneType(context, size: 11.5, mono: true),
            ),
          ),
        ),
        _at(
          122,
          12,
          order: 3,
          child: ScenePhone(
            width: 136,
            height: 236,
            screenColor: const Color(0xFF2B2E5C),
            screen: _CalmLockScreen(controller: controller),
          ),
        ),
        for (final (i, app) in waiting.indexed)
          _at(
            250 + i * 14.0,
            64 + i * 56.0,
            order: 4 + i,
            angle: i.isEven ? .06 : -.04,
            float: 2,
            phase: .3 + i * .3,
            child: Opacity(
              opacity: .72,
              child: SceneCard(
                color: const Color(0xFFE9E4F0),
                radius: 12,
                shadow: const Offset(3, 4),
                padding: const EdgeInsets.fromLTRB(7, 6, 10, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SceneAppTile(
                      controller: controller,
                      packageName: app.packageName,
                      label: app.label,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      app.label,
                      style: _sceneType(context, size: 11, weight: 680),
                    ),
                  ],
                ),
              ),
            ),
          ),
        _at(
          328,
          30,
          order: 6,
          float: 2.5,
          phase: .7,
          child: const CurrePropArt(CurreProp.crescentMoon, size: 34),
        ),
        _at(
          250,
          190,
          order: 7,
          angle: -.04,
          child: SceneCard(
            color: _marker,
            radius: 30,
            padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CurreGlyph(CurreGlyphKind.rise, size: 15, color: sceneInk),
                const SizedBox(width: 5),
                Text(
                  'Bring back',
                  style: _sceneType(context, size: 12, weight: 720),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A lock screen with one message from an app that stays on Home.
class _CalmLockScreen extends StatelessWidget {
  const _CalmLockScreen({required this.controller});

  final CurreController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(9, 26, 9, 8),
      child: Column(
        children: [
          Text(
            '07:12',
            style: _sceneType(context, size: 30, weight: 360, color: _paper),
          ),
          Text(
            'Monday',
            style: _sceneType(
              context,
              size: 8.5,
              weight: 520,
              color: _paper.withValues(alpha: .8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SceneAppTile(
                  controller: controller,
                  packageName: 'com.google.android.apps.messaging',
                  label: 'Messages',
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ada · Messages',
                        style: _sceneType(
                          context,
                          size: 6.8,
                          weight: 560,
                          color: const Color(0xFF6E6257),
                        ),
                      ),
                      Text(
                        'Rehearsal at 8?',
                        style: _sceneType(context, size: 8.6, weight: 720),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: 30,
            height: 3,
            decoration: BoxDecoration(
              color: _paper.withValues(alpha: .7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 10 · A quiet nudge: one silent note when borrowed time is up.

class NudgeScene extends StatelessWidget {
  const NudgeScene({super.key, required this.palette});

  final StagePalette palette;

  @override
  Widget build(BuildContext context) {
    return _Scene(
      label:
          'A silent note on a lock screen: Instagram is hidden again, your 5 minutes are up.',
      children: [
        _blob(palette, const Rect.fromLTWH(24, 6, 330, 226), seed: 14),
        _at(
          30,
          34,
          order: 1,
          float: 2.5,
          child: Transform.rotate(
            angle: -.22,
            child: const CurrePropArt(CurreProp.bell, size: 84),
          ),
        ),
        _at(
          154,
          8,
          order: 3,
          child: ScenePhone(
            width: 156,
            height: 270,
            screenColor: const Color(0xFF2B2E5C),
            screen: Padding(
              padding: const EdgeInsets.fromLTRB(9, 26, 9, 8),
              child: Column(
                children: [
                  Text(
                    '07:12',
                    style: _sceneType(
                      context,
                      size: 34,
                      weight: 360,
                      color: _paper,
                    ),
                  ),
                  Text(
                    'Monday',
                    style: _sceneType(
                      context,
                      size: 8.5,
                      weight: 520,
                      color: _paper.withValues(alpha: .8),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SceneFloat(
                    amplitude: 2,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: _ember,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Curre · now',
                                  style: _sceneType(
                                    context,
                                    size: 6.5,
                                    weight: 520,
                                    color: const Color(0xFF6E6257),
                                  ),
                                ),
                                Text(
                                  'Instagram is hidden again',
                                  style: _sceneType(
                                    context,
                                    size: 8.4,
                                    weight: 720,
                                  ),
                                ),
                                Text(
                                  'Your 5 minutes are up.',
                                  style: _sceneType(
                                    context,
                                    size: 7.6,
                                    weight: 480,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _at(
          18,
          176,
          order: 4,
          angle: -.05,
          child: SceneCard(
            radius: 30,
            padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
            child: Text(
              'no sound · no buzz',
              style: _sceneType(context, size: 11.5, mono: true),
            ),
          ),
        ),
        _at(
          322,
          50,
          order: 5,
          float: 2,
          phase: .4,
          angle: .12,
          child: const CurrePropArt(CurreProp.hourglass, size: 52),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 11 · The apps plans can use: each one a task heading for an open door.

class AppsScene extends StatelessWidget {
  const AppsScene({
    super.key,
    required this.palette,
    required this.controller,
  });

  final StagePalette palette;
  final CurreController controller;

  static const _tasks = <(String, String, String, CurreProp)>[
    ('com.google.android.youtube', 'YouTube', 'Learn the G chord', CurreProp.guitar),
    ('com.google.android.apps.maps', 'Maps', 'Find the studio', CurreProp.pin),
    ('com.spotify.music', 'Spotify', 'Play Sunday worship', CurreProp.musicalNotes),
  ];

  @override
  Widget build(BuildContext context) {
    return _Scene(
      label:
          'Three small tasks, learn the G chord on YouTube, find the studio on Maps and play Sunday worship on Spotify, heading for an open door.',
      children: [
        _blob(palette, const Rect.fromLTWH(10, 8, 330, 222), seed: 21),
        Positioned(
          left: 250,
          top: 14,
          width: 112,
          height: 232,
          child: const RiseIn(order: 1, child: _OpenDoor()),
        ),
        for (final (i, (package, app, task, prop)) in _tasks.indexed)
          _at(
            const [14.0, 38.0, 10.0][i],
            const [22.0, 96.0, 170.0][i],
            order: 2 + i,
            angle: const [-.05, .04, -.03][i],
            float: 2.5,
            phase: i * .3,
            child: SceneCard(
              radius: 16,
              padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SceneAppTile(
                    controller: controller,
                    packageName: package,
                    label: controller.appFor(package)?.label ?? app,
                    size: 30,
                  ),
                  const SizedBox(width: 8),
                  Text(task, style: _sceneType(context, size: 13, weight: 680)),
                  const SizedBox(width: 6),
                  CurrePropArt(prop, size: 30, outline: 1.6),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A doorway with the door swung open and warm light inside.
class _OpenDoor extends StatelessWidget {
  const _OpenDoor();

  @override
  Widget build(BuildContext context) => const CustomPaint(
    size: Size(112, 232),
    painter: _OpenDoorPainter(),
  );
}

class _OpenDoorPainter extends CustomPainter {
  const _OpenDoorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = sceneInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round;
    final frame = RRect.fromRectAndCorners(
      const Rect.fromLTWH(14, 8, 92, 212),
      topLeft: const Radius.circular(10),
      topRight: const Radius.circular(10),
    );
    // Light spilling out onto the floor.
    final spill = Path()
      ..moveTo(14, 220)
      ..lineTo(106, 220)
      ..lineTo(80, 236)
      ..lineTo(-26, 236)
      ..close();
    canvas.drawPath(spill, Paint()..color = _marker.withValues(alpha: .75));
    canvas.drawRRect(frame, Paint()..color = _marker);
    canvas.drawRRect(frame, ink);
    // The open door, seen edge-on to the left of the frame.
    final door = Path()
      ..moveTo(14, 12)
      ..lineTo(-14, 26)
      ..lineTo(-14, 208)
      ..lineTo(14, 220)
      ..close();
    canvas.drawPath(door, Paint()..color = const Color(0xFFE19747));
    canvas.drawPath(door, ink);
    final panel = Path()
      ..moveTo(6, 40)
      ..lineTo(-6, 46)
      ..lineTo(-6, 104)
      ..lineTo(6, 102)
      ..close();
    canvas.drawPath(panel, Paint()..color = const Color(0xFFD3883E));
    canvas.drawCircle(
      const Offset(-8, 124),
      3.6,
      Paint()..color = const Color(0xFFF9C23C),
    );
  }

  @override
  bool shouldRepaint(covariant _OpenDoorPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 12 · The first plan: the sun is up, Peek is awake, and you wave hello.

/// The finale's sky fills the whole stage, behind the question too, so
/// Peek's morning light reaches across the screen. [stage] is the stage's
/// size; the horizon lines up with [PlanScene]'s ground.
class PlanBackdrop extends StatelessWidget {
  const PlanBackdrop({
    super.key,
    required this.session,
    required this.stage,
    required this.capHeight,
  });

  final SessionName session;
  final Size stage;
  final double capHeight;

  @override
  Widget build(BuildContext context) {
    final scale = stage.width / 390;
    final canvasHeight = stage.width * 250 / 390;
    return SkyScene(
      session: session.designSession,
      borderRadius: BorderRadius.zero,
      groundHeight: capHeight + (250 - PlanScene.horizon) * scale,
      sunAt: .74,
      sunSize: 132 * scale,
      sunRise: 1,
      animatePeek: true,
      live: true,
      keepClear: Rect.fromLTWH(
        0,
        0,
        stage.width,
        math.max(0, stage.height - canvasHeight - capHeight),
      ),
    );
  }
}

class PlanScene extends StatelessWidget {
  const PlanScene({super.key, required this.avatarId, required this.name});

  final String? avatarId;
  final String? name;

  /// Where the ground starts on the design canvas.
  static const horizon = 206.0;

  @override
  Widget build(BuildContext context) {
    return _Scene(
      label: 'The sun is up, and you wave good morning to Peek.',
      children: [
        _at(
          34,
          88,
          order: 1,
          child: AvatarFigure(
            avatarId: avatarId,
            initial: name,
            pose: FigurePose.wave,
            height: 178,
            motion: AvatarMotion.reactOnce,
            expression: AvatarExpression.happy,
          ),
        ),
        _at(
          196,
          44,
          order: 2,
          float: 2,
          child: const CurrePropArt(CurreProp.sparkles, size: 34),
        ),
      ],
    );
  }
}
