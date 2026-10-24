import 'package:flutter/material.dart';

import '../../design/design.dart';

/// A small fade-and-rise entrance, staggered by [index] — the "lively but
/// calm motion at moments of choice" the captain's redesign steer asked
/// for (2026-10-24), built entirely from existing tokens ([CurreMotion]'s
/// `rise` duration, `stagger` gap and `riseCurve`), never a bounce.
class StaggeredReveal extends StatefulWidget {
  const StaggeredReveal({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: CurreMotion.rise);
  late final Animation<double> _value = CurvedAnimation(parent: _controller, curve: CurreMotion.riseCurve);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `MediaQuery.disableAnimationsOf` must run from here, not `initState`
    // (it depends on an InheritedWidget, which isn't attached yet then).
    if (_started) return;
    _started = true;
    _controller.duration = CurreMotion.of(context, CurreMotion.rise);
    Future.delayed(CurreMotion.stagger * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _value,
      builder: (context, child) {
        return Opacity(
          opacity: _value.value.clamp(0, 1),
          child: Transform.translate(offset: Offset(0, (1 - _value.value) * 14), child: child),
        );
      },
      child: widget.child,
    );
  }
}
