import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'design/design.dart';
import 'doors/door_lab_screen.dart';
import 'gallery/gallery_screen.dart';

void main() {
  registerCurreLicenses();
  runApp(const CurreApp());
}

class CurreApp extends StatelessWidget {
  const CurreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Curre',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: curreTheme(Brightness.light),
      darkTheme: curreTheme(Brightness.dark),
      routes: {
        '/door-lab': (_) => const DoorLabScreen(),
        '/gallery': (_) => const DesignGalleryScreen(),
      },
      home: const _StarterHome(),
    );
  }
}

/// A placeholder landing page carrying the Curre theme, with a way to reach
/// the door spike and, in debug builds, the design gallery. Home, check-in
/// and the gate are a separate task.
class _StarterHome extends StatelessWidget {
  const _StarterHome();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<CurreType>()!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(CurreSpace.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('curre', style: t.display),
                const SizedBox(height: CurreSpace.s4),
                Text(
                  'Home, check-in and the gate are not built yet.',
                  style: t.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: CurreSpace.s8),
                FilledButton(
                  onPressed: () => Navigator.of(context).pushNamed('/door-lab'),
                  child: const Text('Open Door Lab'),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: CurreSpace.s3),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pushNamed('/gallery'),
                    child: const Text('Design gallery (debug)'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
