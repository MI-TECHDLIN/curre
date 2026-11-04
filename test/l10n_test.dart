import 'dart:convert';
import 'dart:io';

import 'package:curre/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English, Spanish, French, Portuguese and German ship together', () {
    expect(
      AppLocalizations.supportedLocales
          .map((locale) => locale.languageCode)
          .toSet(),
      {'en', 'es', 'fr', 'pt', 'de'},
    );

    final english = _messages('en').keys
        .where((key) => !key.startsWith('@'))
        .toSet();
    for (final language in const ['es', 'fr', 'pt', 'de']) {
      final translated = _messages(language).keys
          .where((key) => !key.startsWith('@'))
          .toSet();
      expect(
        translated,
        english,
        reason: '$language must translate every message',
      );
    }
  });

  test('the central product questions are natural in every language', () {
    expect(curreLocalizationsFor('en').whyNow, 'Why now?');
    expect(curreLocalizationsFor('es').whyNow, '¿Por qué ahora?');
    expect(curreLocalizationsFor('fr').whyNow, 'Pourquoi maintenant ?');
    expect(curreLocalizationsFor('pt').whyNow, 'Porquê agora?');
    expect(curreLocalizationsFor('de').whyNow, 'Warum jetzt?');
  });

  test(
    'manual choice wins, unsupported phone languages fall back to English',
    () {
      expect(
        effectiveLanguageCode(
          preference: 'de',
          phoneLocale: const Locale('es'),
        ),
        'de',
      );
      expect(
        effectiveLanguageCode(
          preference: null,
          phoneLocale: const Locale('fr', 'CA'),
        ),
        'fr',
      );
      expect(
        effectiveLanguageCode(
          preference: null,
          phoneLocale: const Locale('ja'),
        ),
        'en',
      );
    },
  );
}

Map<String, Object?> _messages(String language) =>
    jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync())
        as Map<String, Object?>;
