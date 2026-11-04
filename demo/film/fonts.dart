import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the fonts the app bundles (Geologica, Newsreader Italic, Atkinson
/// Hyperlegible Mono and the Solar icon font), plus the phone's system font
/// and the Material icons, the way they are found on an Android phone.
Future<void> loadFilmFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> load(String family, List<Future<ByteData>> files) async {
    final loader = FontLoader(family);
    files.forEach(loader.addFont);
    await loader.load();
  }

  Future<ByteData> file(String path) =>
      File(path).readAsBytes().then(ByteData.sublistView);

  await load('Geologica', [
    rootBundle.load('assets/fonts/Geologica[CRSV,SHRP,slnt,wght].ttf'),
  ]);
  await load('Newsreader', [
    rootBundle.load('assets/fonts/Newsreader-Italic[opsz,wght].ttf'),
  ]);
  await load('AtkinsonHyperlegibleMono', [
    rootBundle.load('assets/fonts/AtkinsonHyperlegibleMono[wght].ttf'),
  ]);
  await load('packages/solar_icons/SolarIcons', [
    rootBundle.load('packages/solar_icons/fonts/SolarIcons.ttf'),
  ]);

  final sdk = Platform.environment['FLUTTER_ROOT']!;
  final material = '$sdk/bin/cache/artifacts/material_fonts';
  // Styles that name no family use the phone's system font: Roboto on
  // Android. The engine looks for its Linux default family "Ubuntu" first,
  // so the SDK's Roboto is registered under that name too.
  for (final family in ['Roboto', 'Ubuntu']) {
    await load(family, [
      for (final face in ['Light', 'Regular', 'Medium', 'Bold', 'Black'])
        file('$material/Roboto-$face.ttf'),
    ]);
  }
  await load('MaterialIcons', [file('$material/MaterialIcons-Regular.otf')]);
}
