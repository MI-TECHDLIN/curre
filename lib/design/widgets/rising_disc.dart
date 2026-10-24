import 'package:flutter/material.dart';

import '../curre_colors.dart';
import '../curre_tokens.dart';

/// The 60-second override's rising disc (design report 3.8 / 4.6): an
/// ember disc with a 2 dp ink edge that rises **linearly** — never eased —
/// from fully below the horizon to fully above it over [duration]. Time is
/// information here, so it is never curved like Curre's other motion.
///
/// This widget draws its own short horizon segment so it is legible on its
/// own (gallery, tests); a real override screen may instead line it up
/// with the screen's own [HorizonLine] and pass a transparent one here —
/// nothing about the rise animation depends on which line is drawn.
class RisingDisc extends StatefulWidget {
  const RisingDisc({
    super.key,
    this.duration = CurreMotion.countdown,
    this.diameter = 56,
    this.autoStart = true,
    this.onComplete,
    this.semanticLabel,
  });

  final Duration duration;
  final double diameter;
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
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener(_onStatus);
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
    final height = widget.diameter * 2;
    final radius = widget.diameter / 2;

    return Semantics(
      label: widget.semanticLabel ?? 'Opens in',
      child: SizedBox(
        width: widget.diameter,
        height: height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Linear: `_controller.value` is used directly, with no curve.
            final t = _controller.value;
            final centerY = (height - radius) - t * (height - widget.diameter);
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: height / 2 - CurreSpace.horizon / 2,
                  left: 0,
                  right: 0,
                  child: Container(height: CurreSpace.horizon, color: c.horizon),
                ),
                Positioned(
                  top: centerY - radius,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: widget.diameter,
                      height: widget.diameter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.ember,
                        border: Border.all(color: c.ink, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
