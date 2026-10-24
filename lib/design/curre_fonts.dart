import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The three bundled OFL font families and the licence asset each one ships.
/// Call [registerCurreFontLicenses] once at startup so `showLicensePage`
/// (Settings → licences) lists them. Curre never fetches fonts at runtime.
const Map<String, String> curreFontLicenseAssets = {
  'Geologica': 'assets/licenses/OFL-Geologica.txt',
  'Newsreader': 'assets/licenses/OFL-Newsreader.txt',
  'AtkinsonHyperlegibleMono': 'assets/licenses/OFL-AtkinsonHyperlegibleMono.txt',
};

void registerCurreFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in curreFontLicenseAssets.entries) {
      final text = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}
