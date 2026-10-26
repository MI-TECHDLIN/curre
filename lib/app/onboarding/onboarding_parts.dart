import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../curre_controller.dart';

/// The colour blocks onboarding's stages are made of. Each step has its
/// own sky, and the order follows a night turning into morning: the story
/// starts late at night with a phone in hand and ends with the first plan
/// of the day.
enum StageTone { night, lilac, coral, peach, dawn, sky, sage, mint }

/// One stage's colours: its [sky], the [ink] set on it (text, lines,
/// controls; AA or better on [sky]), a [deep] block for grounds and back
/// shapes, a [glow] block for the shape behind the subject, and grain.
@immutable
class StagePalette {
  const StagePalette({
    required this.sky,
    required this.ink,
    required this.deep,
    required this.glow,
    required this.grainDark,
    required this.grainLight,
    required this.isDark,
  });

  /// A palette for any sky colour, with [ink] chosen for contrast.
  factory StagePalette.fromSky(Color sky, {Color? ink}) {
    final isDark = sky.computeLuminance() < .22;
    final resolvedInk =
        ink ?? (isDark ? const Color(0xFFF4EFE6) : const Color(0xFF1E1A16));
    return StagePalette(
      sky: sky,
      ink: resolvedInk,
      deep: isDark
          ? Color.lerp(sky, Colors.black, .26)!
          : Color.lerp(sky, resolvedInk, .12)!,
      glow: isDark
          ? Color.lerp(sky, resolvedInk, .11)!
          : Color.lerp(sky, Colors.white, .32)!,
      grainDark: (isDark ? Colors.black : resolvedInk).withValues(
        alpha: isDark ? .16 : .055,
      ),
      grainLight: Colors.white.withValues(alpha: isDark ? .05 : .16),
      isDark: isDark,
    );
  }

  final Color sky;
  final Color ink;
  final Color deep;
  final Color glow;
  final Color grainDark;
  final Color grainLight;
  final bool isDark;

  static StagePalette of(StageTone tone, Brightness brightness) {
    final light = brightness == Brightness.light;
    return switch (tone) {
      StageTone.night => StagePalette.fromSky(
        light ? const Color(0xFF2E3876) : const Color(0xFF232B6E),
        ink: light ? const Color(0xFFF4EFE6) : const Color(0xFFECE8FA),
      ),
      StageTone.lilac => StagePalette.fromSky(
        light ? const Color(0xFFD8CBE8) : const Color(0xFF3A3158),
        ink: light ? null : const Color(0xFFECE8FA),
      ),
      StageTone.coral => StagePalette.fromSky(
        light ? const Color(0xFFF59C8B) : const Color(0xFF5A2A26),
        ink: light ? null : const Color(0xFFF9D5CE),
      ),
      StageTone.peach => StagePalette.fromSky(
        light ? const Color(0xFFF9D9B6) : const Color(0xFF4A3220),
        ink: light ? null : const Color(0xFFF7E1C6),
      ),
      StageTone.dawn => StagePalette.fromSky(
        light ? const Color(0xFFF7B9A2) : const Color(0xFF55261D),
        ink: light ? null : const Color(0xFFFFDCCB),
      ),
      StageTone.sky => StagePalette.fromSky(
        light ? const Color(0xFF96D0E6) : const Color(0xFF16506A),
        ink: light ? const Color(0xFF0C3442) : const Color(0xFFD2F0FA),
      ),
      StageTone.sage => StagePalette.fromSky(
        light ? const Color(0xFFBFD8B2) : const Color(0xFF2B3A27),
        ink: light ? null : const Color(0xFFDDE9CF),
      ),
      StageTone.mint => StagePalette.fromSky(
        light ? const Color(0xFFCFE8C9) : const Color(0xFF1F3A22),
        ink: light ? const Color(0xFF1D4A22) : const Color(0xFFBFE5B8),
      ),
    };
  }
}

/// The step counter as a sunrise: a horizon with one tick per step and a
/// small sun that climbs a little higher at every step. TalkBack hears
/// "Step 3 of 10".
class SunriseProgress extends StatelessWidget {
  const SunriseProgress({
    super.key,
    required this.step,
    required this.total,
    required this.ink,
  });

  /// 1-based.
  final int step;
  final int total;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    return Semantics(
      label: 'Step $step of $total',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: step.toDouble()),
        duration: CurreMotion.of(context, CurreMotion.rise),
        curve: CurreMotion.riseCurve,
        builder: (context, value, _) => CustomPaint(
          size: const Size(double.infinity, 28),
          painter: _SunrisePainter(
            position: value,
            total: total,
            ink: ink,
            sun: colors.ember,
          ),
        ),
      ),
    );
  }
}

class _SunrisePainter extends CustomPainter {
  _SunrisePainter({
    required this.position,
    required this.total,
    required this.ink,
    required this.sun,
  });

  final double position;
  final int total;
  final Color ink;
  final Color sun;

  @override
  void paint(Canvas canvas, Size size) {
    final lineY = size.height - 6;
    const pad = 9.0;
    final span = size.width - pad * 2;
    double xAt(double step) => pad + span * (step - 1) / (total - 1);
    final done = xAt(position);

    final faint = Paint()
      ..color = ink.withValues(alpha: .28)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final strong = Paint()
      ..color = ink
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pad, lineY), Offset(size.width - pad, lineY), faint);
    canvas.drawLine(Offset(pad, lineY), Offset(done, lineY), strong);
    for (var i = 1; i <= total; i++) {
      final x = xAt(i.toDouble());
      canvas.drawCircle(
        Offset(x, lineY),
        2.2,
        i <= position + .01 ? strong : faint,
      );
    }

    // The sun climbs from half under the line to sitting on it.
    final t = ((position - 1) / (total - 1)).clamp(0.0, 1.0);
    const radius = 7.0;
    final center = Offset(done, lineY - radius * (.15 + .85 * t) - 1);
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, lineY - 1));
    final rays = Paint()
      ..color = sun
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final angle = math.pi + (i + 1) * math.pi / 6;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + dir * (radius + 3),
        center + dir * (radius + 3 + 3.5 * t),
        rays,
      );
    }
    canvas.drawCircle(center, radius, Paint()..color = sun);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = sceneInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SunrisePainter old) =>
      old.position != position ||
      old.total != total ||
      old.ink != ink ||
      old.sun != sun;
}

/// Lays a scene out on a fixed design canvas of [width] × [height] and
/// scales it to the space it gets, so an illustration keeps its
/// composition on every phone. Words inside the art don't follow the
/// system text size (they are part of the picture; what they say is also
/// given in plain text outside it).
class SceneCanvas extends StatelessWidget {
  const SceneCanvas({
    super.key,
    required this.children,
    this.width = 390,
    this.height = 250,
  });

  final double width;
  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: width / height,
      child: FittedBox(
        fit: BoxFit.contain,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(clipBehavior: Clip.none, children: children),
          ),
        ),
      ),
    );
  }
}

/// Runs one scene's entrance: layers wrapped in [RiseIn] arrive in order,
/// each rising a little and fading in. Reduced motion shows the final
/// picture at once.
class SceneEntrance extends StatefulWidget {
  const SceneEntrance({super.key, required this.child});

  final Widget child;

  @override
  State<SceneEntrance> createState() => _SceneEntranceState();
}

class _SceneEntranceState extends State<SceneEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _EntranceScope(animation: _controller, child: widget.child);
}

class _EntranceScope extends InheritedWidget {
  const _EntranceScope({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_EntranceScope oldWidget) =>
      oldWidget.animation != animation;
}

/// One layer of a [SceneEntrance]: [order] 0 arrives first.
class RiseIn extends StatelessWidget {
  const RiseIn({
    super.key,
    required this.order,
    required this.child,
    this.distance = 18,
  });

  final int order;
  final double distance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_EntranceScope>();
    if (scope == null) return child;
    final start = (order * .11).clamp(0.0, .62);
    final curved = CurvedAnimation(
      parent: scope.animation,
      curve: Interval(start, start + .38, curve: CurreMotion.riseCurve),
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) => Opacity(
        opacity: curved.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * distance),
          child: child,
        ),
      ),
    );
  }
}

/// A large, tappable choice: a picture, a title, an optional line, and a
/// check that fills in when chosen. Selection shows as an ember outline, a
/// filled check and "selected" for TalkBack, never by colour alone.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.dense = false,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final bool dense;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final radius = BorderRadius.circular(dense ? 18 : 20);
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? [title, ?subtitle].join(', '),
      excludeSemantics: true,
      onTap: onTap,
      child: AnimatedContainer(
        duration: CurreMotion.of(context, CurreMotion.quick),
        decoration: BoxDecoration(
          color: colors.raised,
          borderRadius: radius,
          border: Border.all(
            color: selected ? colors.ember : colors.hairline,
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.ember.withValues(alpha: .28),
                    offset: const Offset(3, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashFactory: NoSplash.splashFactory,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: dense ? 60 : 72),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: dense ? CurreSpace.s3 : CurreSpace.s4,
                  vertical: CurreSpace.s3,
                ),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      SizedBox(width: dense ? CurreSpace.s2 + 2 : CurreSpace.s3),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: type.label
                                .weight(dense ? 620 : 660)
                                .copyWith(fontSize: dense ? 15 : 16),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: type.caption.copyWith(color: colors.ink2),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: CurreSpace.s2),
                    _CheckDot(selected: selected),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckDot extends StatelessWidget {
  const _CheckDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    return SizedBox.square(
      dimension: 28,
      child: AnimatedSwitcher(
        duration: CurreMotion.of(context, CurreMotion.quick),
        child: selected
            ? CurreGlyph(
                CurreGlyphKind.check,
                key: const ValueKey('on'),
                size: 28,
                color: colors.ember,
              )
            : Container(
                key: const ValueKey('off'),
                margin: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.ink3, width: 2),
                ),
              ),
      ),
    );
  }
}

/// A plain tile for an app: the first letter of its name on a soft colour
/// picked from its package, so the same app always looks the same. Used
/// where Curre lists apps without their real icons (no cue to open them).
class AppMonogram extends StatelessWidget {
  const AppMonogram({
    super.key,
    required this.label,
    required this.packageName,
    this.size = 40,
  });

  final String label;
  final String packageName;
  final double size;

  static const _fills = <Color>[
    Color(0xFFFCC35A),
    Color(0xFF96D0E6),
    Color(0xFFBFD8B2),
    Color(0xFFF2C4BF),
    Color(0xFFD8CBE8),
    Color(0xFFF5E7D5),
    Color(0xFFF59C8B),
    Color(0xFFCFE8C9),
  ];

  static Color fillFor(String packageName) {
    var hash = 5;
    for (final unit in packageName.codeUnits) {
      hash = (hash * 33 + unit) & 0x7fffffff;
    }
    return _fills[hash % _fills.length];
  }

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<CurreType>()!;
    final trimmed = label.trim();
    final letter = trimmed.isEmpty
        ? '?'
        : String.fromCharCode(trimmed.runes.first).toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fillFor(packageName),
          borderRadius: BorderRadius.circular(size * .3),
          border: Border.all(color: sceneInk, width: math.max(1.5, size * .045)),
        ),
        child: Text(
          letter,
          style: type.label
              .weight(760)
              .copyWith(
                fontSize: size * .44,
                height: 1,
                color: sceneInk,
              ),
        ),
      ),
    );
  }
}

/// An app as it appears in an illustration: its real icon when the phone
/// gives one (scenes sit above the horizon, where icons belong), else its
/// [AppMonogram].
class SceneAppTile extends StatelessWidget {
  const SceneAppTile({
    super.key,
    required this.controller,
    required this.packageName,
    required this.label,
    this.size = 44,
  });

  final CurreController controller;
  final String packageName;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: controller.iconFor(packageName),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return AppMonogram(
            label: label,
            packageName: packageName,
            size: size,
          );
        }
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * .28),
            border: Border.all(color: sceneInk, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * .28 - 2),
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
        );
      },
    );
  }
}
