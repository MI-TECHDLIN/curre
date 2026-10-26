import 'platform_channel.dart';

/// Which screen opened when Curre asked Android to let the user choose a
/// home screen app.
enum HomeSettingsOpened {
  /// Android's home app picker: the user can choose straight away.
  homeApps,

  /// Android's default apps list, one tap ("Home app") from the picker.
  defaultApps,

  /// The phone's main Settings screen; the user has to find the picker.
  settings,

  /// Nothing opened (no such screen, or not running on Android).
  none,
}

abstract interface class HomeSettingsGateway {
  Future<HomeSettingsOpened> openHomeSettings();
}

/// Opens the place where the user picks their home screen app, so they can
/// switch from Curre to another one (or back). Android owns that choice;
/// Curre only takes the user there.
class HomeSettingsService implements HomeSettingsGateway {
  const HomeSettingsService();

  @override
  Future<HomeSettingsOpened> openHomeSettings() async {
    try {
      final opened = await currePlatformChannel.invokeMethod<String>(
        'openHomeSettings',
      );
      return switch (opened) {
        'home' => HomeSettingsOpened.homeApps,
        'defaultApps' => HomeSettingsOpened.defaultApps,
        'settings' => HomeSettingsOpened.settings,
        _ => HomeSettingsOpened.none,
      };
    } on Object {
      return HomeSettingsOpened.none;
    }
  }
}
