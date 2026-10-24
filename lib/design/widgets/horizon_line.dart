import 'package:flutter/material.dart';

import '../curre_colors.dart';
import '../curre_tokens.dart';

/// Curre's signature device (design report 3.1): a 2 dp line, in `ink`
/// (light) or `moon`/dark-mode `ink` normally, or the current on-sky colour
/// when it sits over a sky band. [color] lets a caller pass that on-sky
/// colour explicitly; otherwise it falls back to the theme's horizon ink.
///
/// When [scanning] is true, an ember scan runs along the line on a 1.2 s
/// linear loop — Curre's only "busy" indicator; there is never a spinner.
class HorizonLine extends StatefulWidget {
  const HorizonLine({
    super.key,
    this.color,
    this.scanning = false,
    this.thickness = CurreSpace.horizon,
    this.semanticLabel,
  });

  final Color? color;
  final bool scanning;
  final double thickness;
  final String? semanticLabel;

  @override
  State<HorizonLine> createState() => _HorizonLineState();
}

class _HorizonLineState extends State<HorizonLine> with SingleTickerProviderStateMixin {
  static const _scanDuration = Duration(milliseconds: 1200);

  late final AnimationController _controller = AnimationController(vsync: this, duration: _scanDuration);

  /// Exposed for tests, so they can assert on this widget's own animation
  /// instead of the binding's global transient-callback count (which other
  /// widgets' implicit animations can also hold open briefly).
  @visibleForTesting
  AnimationController get controller => _controller;

  @override
  void initState() {
    super.initState();
    if (widget.scanning) _controller.repeat();
  }

  @override
  void didUpdateWidget(HorizonLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scanning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.scanning && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curreColors = Theme.of(context).extension<CurreColors>();
    final lineColor = widget.color ?? curreColors?.horizon ?? const Color(0xFF1E1A16);

    return Semantics(
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel == null,
      child: SizedBox(
        height: widget.thickness,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(color: lineColor, height: widget.thickness, width: double.infinity),
                if (widget.scanning)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final scanWidth = width * 0.22;
                      final x = (width + scanWidth) * _controller.value - scanWidth;
                      return Positioned(
                        left: x,
                        top: 0,
                        child: Container(
                          width: scanWidth,
                          height: widget.thickness,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0x00E85F2E), Color(0xFFE85F2E), Color(0x00E85F2E)]),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
