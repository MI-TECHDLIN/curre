import 'package:curre/design/design.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the licences page lists the three OFL fonts and credits the Solar icons', () async {
    LicenseRegistry.reset();
    registerCurreLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    final packages = {for (final e in entries) ...e.packages};
    expect(packages, containsAll(['Geologica', 'Newsreader', 'AtkinsonHyperlegibleMono', 'Solar icons (480 Design)']));

    for (final e in entries) {
      final text = e.paragraphs.map((p) => p.text).join('\n');
      if (e.packages.contains('Geologica')) expect(text, contains('SIL OPEN FONT LICENSE'));
      if (e.packages.contains('Solar icons (480 Design)')) expect(text, contains('CC BY 4.0'));
    }
  });
}
