import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../design/design.dart';
import '../../doors/door_models.dart';
import '../../l10n/l10n.dart';
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
  Widget content = angle == 0
      ? child
      : Transform.rotate(angle: angle, child: child);
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
      label: context.l10n.sceneStory,
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
                context.l10n.sceneBusTime,
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
          ? context.l10n.sceneMagnetEmpty
          : context.l10n.sceneMagnetApps(
              shown.map((app) => app.label).join(', '),
            ),
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
          ? context.l10n.sceneInitial
          : context.l10n.sceneFace,
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
      label: context.l10n.sceneHome,
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
    Widget door(Color tint, String package, String app, String to) => Container(
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
                  name == null
                      ? context.l10n.goodMorning
                      : context.l10n.goodMorningName(name!),
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
              context.l10n.planExampleGuitar,
              style: _sceneType(context, size: 8.6, you: true),
            ),
          ),
          const SizedBox(height: 7),
          door(
            _cardPink,
            'com.google.android.youtube',
            'YouTube',
            context.l10n.sceneSearch(context.l10n.sceneGChord),
          ),
          door(
            _cardBlue,
            'com.spotify.music',
            'Spotify',
            context.l10n.sceneSearch(context.l10n.sceneWorship),
          ),
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
            context.l10n.miniAllApps(context.l10n.hiddenAppsCount(2)),
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
      label: context.l10n.scenePlan,
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
