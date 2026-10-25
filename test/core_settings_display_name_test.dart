import 'dart:convert';

import 'package:curre/core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Settings _roundTrip(Settings settings) => Settings.fromJson(
  jsonDecode(jsonEncode(settings.toJson())) as Map<String, Object?>,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings.displayName', () {
    test('defaults to no name and leaves it out of the JSON', () {
      final settings = Settings();
      expect(settings.displayName, isNull);
      expect(settings.toJson().containsKey('displayName'), isFalse);
      expect(_roundTrip(settings).displayName, isNull);
    });

    test('round-trips through JSON, including non-Latin names and emoji', () {
      for (final name in [
        'Chidi',
        'Oluwadamilare Adeyemi-Okonkwo',
        '张伟',
        'Adaeze 🌅',
      ]) {
        final settings = Settings(displayName: name, unlockMinutes: 7);
        expect(settings.toJson()['displayName'], name);
        final restored = _roundTrip(settings);
        expect(restored.displayName, name);
        expect(restored.toJson(), settings.toJson());
      }
    });

    test('settings saved before names existed still load, with no name', () {
      final legacy = Settings(unlockMinutes: 6).toJson()..remove('displayName');
      expect(Settings.fromJson(legacy).displayName, isNull);
    });

    test('trims and collapses whitespace; a blank name is no name', () {
      expect(
        Settings(displayName: '  Chidi   Okafor ').displayName,
        'Chidi Okafor',
      );
      expect(Settings(displayName: '   ').displayName, isNull);
      expect(Settings(displayName: '').displayName, isNull);
      expect(
        Settings.fromJson({...Settings().toJson(), 'displayName': ' \t '})
            .displayName,
        isNull,
      );
    });

    test('rejects a name that is not a string', () {
      expect(
        () => Settings.fromJson({...Settings().toJson(), 'displayName': 42}),
        throwsFormatException,
      );
    });

    test('survives the local store', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = await CurreLocalStore.open();
      await store.saveSettings(Settings(displayName: 'Chidi'));
      expect(store.loadSettings().displayName, 'Chidi');
    });
  });

  group('Settings.avatarId', () {
    test('defaults to no avatar and leaves it out of legacy JSON', () {
      final settings = Settings();
      expect(settings.avatarId, isNull);
      expect(settings.toJson().containsKey('avatarId'), isFalse);
      expect(_roundTrip(settings).avatarId, isNull);
    });

    test('round-trips through JSON and trims the stable ID', () {
      final settings = Settings(displayName: 'Ada', avatarId: '  avatar-07  ');
      expect(settings.avatarId, 'avatar-07');
      expect(_roundTrip(settings).toJson(), settings.toJson());
    });

    test('settings saved before avatars existed still load', () {
      final legacy = Settings(displayName: 'Ada').toJson()..remove('avatarId');
      expect(Settings.fromJson(legacy).avatarId, isNull);
    });

    test('blank IDs become null and non-string IDs are rejected', () {
      expect(Settings(avatarId: '  ').avatarId, isNull);
      expect(
        () => Settings.fromJson({...Settings().toJson(), 'avatarId': 7}),
        throwsFormatException,
      );
    });

    test('copyWith changes and explicitly clears the selection', () {
      final settings = Settings(avatarId: 'avatar-02');
      expect(settings.copyWith().avatarId, 'avatar-02');
      expect(settings.copyWith(avatarId: 'avatar-11').avatarId, 'avatar-11');
      expect(settings.copyWith(clearAvatarId: true).avatarId, isNull);
    });

    test('survives the local store', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = await CurreLocalStore.open();
      await store.saveSettings(
        Settings(displayName: 'Ada', avatarId: 'avatar-07'),
      );
      expect(store.loadSettings().avatarId, 'avatar-07');
    });
  });
}
