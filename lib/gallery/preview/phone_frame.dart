import 'package:flutter/material.dart';

import '../../design/design.dart';

/// Renders [child] at a fixed phone size (390×844 by default; the detail
/// pass uses 360 dp) under a full [curreTheme] for [brightness], so the
/// debug gallery shows real composed Flutter screens whatever the device's
/// own theme is. Preview compositions only, not routes the app pushes.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({
    super.key,
    required this.brightness,
    required this.label,
    required this.child,
    this.size = defaultSize,
  });

  final Brightness brightness;
  final String label;
  final Widget child;
  final Size size;

  static const defaultSize = Size(390, 844);
  static const narrowSize = Size(360, 740);
  static const bezel = 6.0;

  @override
  Widget build(BuildContext context) {
    final theme = curreTheme(brightness);
    final screen = MediaQuery.of(context).copyWith(size: size, padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.extension<CurreType>()!.meta),
        const SizedBox(height: CurreSpace.s2),
        Container(
          width: size.width + bezel * 2,
          height: size.height + bezel * 2,
          padding: const EdgeInsets.all(bezel),
          decoration: BoxDecoration(color: const Color(0xFF1E1A16), borderRadius: BorderRadius.circular(44 + bezel)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(44),
            child: MediaQuery(
              data: screen,
              child: Theme(
                data: theme,
                child: Material(color: theme.scaffoldBackgroundColor, child: child),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A light/dark pair of [PhoneFrame]s, side by side.
class PhoneFramePair extends StatelessWidget {
  const PhoneFramePair({super.key, required this.builder, this.size = PhoneFrame.defaultSize});

  final WidgetBuilder builder;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final dp = '${size.width.round()} dp';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhoneFrame(
            brightness: Brightness.light,
            label: 'Light · $dp',
            size: size,
            child: Builder(builder: builder),
          ),
          const SizedBox(width: CurreSpace.s6),
          PhoneFrame(
            brightness: Brightness.dark,
            label: 'Dark · $dp',
            size: size,
            child: Builder(builder: builder),
          ),
        ],
      ),
    );
  }
}
