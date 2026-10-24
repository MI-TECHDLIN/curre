import 'package:flutter/material.dart';

import '../curre_colors.dart';
import '../curre_tokens.dart';

/// The 60-second override's rising sun (design report 3.8 / 4.6): an ember
/// disc with a 2 dp ink edge that rises **linearly**, never eased, from
/// fully below the horizon to fully above it over [duration]. Time is
/// information here, so it never gets the curves the rest of Curre's
/// motion uses. Below the line the disc is hidden, as a real sunrise is.
///
/// It draws its own line, [width] long (by default 2.4 discs), in
/// [lineColor] (the theme's horizon by default), over an optional
/// [groundColor] band, so it can sit on paper or inside a sky card.
/// [initialProgress] starts the rise part-way (a wait that is already
/// running). The disc never carries a face: the gate is mascot-free.
class RisingDisc extends StatefulWidget {
  const RisingDisc({
    super.key,
    this.duration = CurreMotion.countdown,
    this.diameter = 56,
    this.width,
    this.lineColor,
    this.groundColor,
    this.initialProgress = 0,
    this.autoStart = true,
    this.onComplete,
    this.semanticLabel,
  });

  final Duration duration;
  final double diameter;
  final double? width;
  final Color? lineColor;
  final Color? groundColor;
  final double initialProgress;
  final bool autoStart;
  final VoidCallback? onComplete;
  final String? semanticLabel;

  @override
  State<RisingDisc> createState() => _RisingDiscState();
}

class _RisingDiscState extends State<RisingDisc> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.initialProgress.clamp(0.0, 1.0),
    )..addStatusListener(_onStatus);
    if (widget.autoStart) _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onComplete?.call();
  }

  @override
  void didUpdateWidget(RisingDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  /// Exposed for tests: drives the animation without a real clock.
  @visibleForTesting
  AnimationController get controller => _controller;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<CurreColors>()!;
    final d = widget.diameter;
    final width = widget.width ?? d * 2.4;
    final groundH = d * .42;
    final lineY = d + 6;
    final height = lineY + groundH;

    return Semantics(
      label: widget.semanticLabel ?? 'Opens in',
      child: SizedBox(
        width: width,
        height: height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Linear: the controller's value is used directly, no curve.
            final t = _controller.value;
            // At t = 0 the disc's top sits on the line (hidden below it);
            // at t = 1 its bottom sits on the line (fully risen).
            final discTop = lineY - t * d;
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                if (widget.groundColor != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: lineY,
                    bottom: 0,
                    child: ColoredBox(color: widget.groundColor!),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: lineY,
                  child: ClipRect(
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned(
                          top: discTop,
                          left: (width - d) / 2,
                          child: Container(
                            width: d,
                            height: d,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.ember,
                              border: Border.all(color: const Color(0xFF1E1A16), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: lineY - CurreSpace.horizon / 2,
                  left: 0,
                  right: 0,
                  child: Container(height: CurreSpace.horizon, color: widget.lineColor ?? c.horizon),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
