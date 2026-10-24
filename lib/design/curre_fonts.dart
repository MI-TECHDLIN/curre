import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The three bundled OFL font families and the licence asset each one ships.
/// [registerCurreLicenses] (called once at startup) registers them, so
/// `showLicensePage` (Settings → licences) lists them. Curre never fetches
/// fonts at runtime.
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

/// Credit for the icon designs. The `solar_icons` package's own BSD-3
/// licence is collected by Flutter automatically; the Solar designs
/// themselves are 480 Design's, under CC BY 4.0, which asks for this credit.
const curreIconCredit =
    'Icons: Solar icon set by 480 Design '
    '(https://www.figma.com/community/file/1166831539721848736), '
    'licensed under CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/). '
    'Used through the solar_icons Flutter package; three glyphs are '
    'recomposed in code where the package font drops a cut-out.';

/// Registers every outside asset's licence or credit: the three OFL fonts
/// and the Solar icon credit. Call once at startup.
void registerCurreLicenses() {
  registerCurreFontLicenses();
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(['Solar icons (480 Design)'], curreIconCredit);
  });
}
