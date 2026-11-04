import 'package:flutter/material.dart';

import '../core/models.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

const String defaultLanguageCode = 'en';

extension CurreLocalizationsContext on BuildContext {
  /// Widget tests that mount a screen without [MaterialApp]'s delegates still
  /// get the English source copy. The production app always has the delegate.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('en'));
}

/// The saved preference is null when Curre follows the phone. Unknown values
/// from a future build also fall back to the phone instead of breaking startup.
Locale? curreLocaleForPreference(String? languageCode) {
  if (languageCode == null) return null;
  final locale = Locale(languageCode);
  return AppLocalizations.supportedLocales.any(
        (supported) => supported.languageCode == locale.languageCode,
      )
      ? locale
      : null;
}

String effectiveLanguageCode({
  required String? preference,
  required Locale phoneLocale,
}) {
  final preferred = curreLocaleForPreference(preference);
  if (preferred != null) return preferred.languageCode;
  final phone = phoneLocale.languageCode;
  return AppLocalizations.supportedLocales.any(
        (supported) => supported.languageCode == phone,
      )
      ? phone
      : defaultLanguageCode;
}

AppLocalizations curreLocalizationsFor(String languageCode) =>
    lookupAppLocalizations(
      curreLocaleForPreference(languageCode) ??
          const Locale(defaultLanguageCode),
    );

extension LocalizedSessionName on SessionName {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    SessionName.morning => l10n.sessionMorning,
    SessionName.afternoon => l10n.sessionAfternoon,
    SessionName.evening => l10n.sessionEvening,
  };
}
