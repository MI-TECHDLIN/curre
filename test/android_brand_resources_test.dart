import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const res = 'android/app/src/main/res';

  test('legacy Peek launcher icons are crisp at every Android density', () {
    const sizes = <String, int>{
      'mipmap-mdpi': 48,
      'mipmap-hdpi': 72,
      'mipmap-xhdpi': 96,
      'mipmap-xxhdpi': 144,
      'mipmap-xxxhdpi': 192,
    };

    for (final entry in sizes.entries) {
      final dimensions = _pngDimensions(
        File('$res/${entry.key}/ic_launcher.png'),
      );
      expect(dimensions, (entry.value, entry.value), reason: entry.key);
    }
  });

  test('adaptive icon includes mask-safe Peek art and Android 13 mono art', () {
    final adaptive = File('$res/mipmap-anydpi-v26/ic_launcher.xml')
        .readAsStringSync();
    final themed = File('$res/mipmap-anydpi-v33/ic_launcher.xml')
        .readAsStringSync();
    final foreground = File('$res/drawable/ic_launcher_foreground.xml')
        .readAsStringSync();
    final monochrome = File('$res/drawable/ic_launcher_monochrome.xml')
        .readAsStringSync();

    expect(adaptive, contains('@drawable/ic_launcher_foreground'));
    expect(adaptive, contains('@color/curre_icon_warm'));
    expect(themed, contains('<monochrome'));
    expect(themed, contains('@drawable/ic_launcher_monochrome'));
    expect(foreground, contains('android:viewportWidth="108"'));
    expect(foreground, contains('M28,73 C28,57 39.6,44 54,44'));
    expect(foreground, contains('M30,73 L78,73'));
    expect(foreground, contains('#FFE85F2E'));
    expect(monochrome, contains('M28,73 C28,57 39.6,44 54,44'));
    expect(monochrome, contains('#FFFFFFFF'));
  });

  test(
    'Android 12 splash and the Flutter launch window share brand colors',
    () {
      final light = File('$res/values-v31/styles.xml').readAsStringSync();
      final dark = File('$res/values-night-v31/styles.xml').readAsStringSync();
      final colors = File('$res/values/colors.xml').readAsStringSync();
      final nightColors = File('$res/values-night/colors.xml')
          .readAsStringSync();
      final splash = File('$res/drawable/ic_splash_peek.xml')
          .readAsStringSync();

      for (final styles in <String>[light, dark]) {
        expect(styles, contains('windowSplashScreenBackground'));
        expect(styles, contains('@drawable/ic_splash_peek'));
        expect(styles, contains('postSplashScreenTheme'));
      }
      expect(colors, contains('#FBDCC4'));
      expect(nightColors, contains('#13111A'));
      expect(splash, contains('android:viewportWidth="108"'));
    },
  );

  test('rich local notification resources avoid exact-alarm permission', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final smallIcon = File('$res/drawable/ic_stat_curre.xml')
        .readAsStringSync();

    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
    expect(manifest, contains('ScheduledNotificationReceiver'));
    expect(manifest, contains('ScheduledNotificationBootReceiver'));
    expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher"'));
    expect(manifest, isNot(contains('SCHEDULE_EXACT_ALARM')));
    expect(manifest, isNot(contains('USE_EXACT_ALARM')));
    expect(smallIcon, contains('#FFFFFFFF'));
    expect(
      _pngDimensions(File('$res/drawable-nodpi/curre_notification_art.png')),
      (1024, 512),
    );
  });
}

(int, int) _pngDimensions(File file) {
  final bytes = file.readAsBytesSync();
  expect(bytes.length, greaterThanOrEqualTo(24), reason: file.path);
  expect(bytes.sublist(0, 8), <int>[
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
  ], reason: file.path);
  final header = ByteData.sublistView(bytes);
  return (header.getUint32(16), header.getUint32(20));
}
