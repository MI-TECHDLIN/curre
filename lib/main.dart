import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/curre_controller.dart';
import 'app/home_screen.dart';
import 'app/onboarding_screen.dart';
import 'design/design.dart';
import 'doors/door_lab_screen.dart';
import 'gallery/gallery_screen.dart';

void main() {
  registerCurreLicenses();
  runApp(const CurreApp());
}

class CurreApp extends StatefulWidget {
  const CurreApp({
    super.key,
    this.controller,
    this.themeMode = ThemeMode.system,
  });

  /// Injection point for widget tests and review renders. Production creates
  /// the controller from SharedPreferences, Android channels and dart-defines.
  final CurreController? controller;
  final ThemeMode themeMode;

  @override
  State<CurreApp> createState() => _CurreAppState();
}

class _CurreAppState extends State<CurreApp> {
  Future<CurreController>? _bootstrap;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _bootstrap = CurreController.bootstrap();
    }
  }

  @override
  void dispose() {
    final future = _bootstrap;
    if (future != null) future.then((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Curre',
      debugShowCheckedModeBanner: false,
      themeMode: widget.themeMode,
      theme: curreTheme(Brightness.light),
      darkTheme: curreTheme(Brightness.dark),
      routes: <String, WidgetBuilder>{
        if (kDebugMode) '/door-lab': (_) => const DoorLabScreen(),
        if (kDebugMode) '/gallery': (_) => const DesignGalleryScreen(),
      },
      home: widget.controller == null
          ? FutureBuilder<CurreController>(
              future: _bootstrap,
              builder: (context, snapshot) {
                final controller = snapshot.data;
                if (controller != null) {
                  return _CurreRoot(controller: controller);
                }
                return const _BootScreen();
              },
            )
          : _CurreRoot(controller: widget.controller!),
    );
  }
}

class _CurreRoot extends StatelessWidget {
  const _CurreRoot({required this.controller});

  final CurreController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => controller.onboardingComplete
          ? HomeScreen(controller: controller)
          : OnboardingScreen(controller: controller),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<CurreType>()!;
    final colors = Theme.of(context).extension<CurreColors>()!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('curre', style: type.display),
            const SizedBox(height: CurreSpace.s4),
            SizedBox(width: 120, child: HorizonLine(color: colors.ink)),
          ],
        ),
      ),
    );
  }
}
