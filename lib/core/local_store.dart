import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'grants.dart';
import 'models.dart';
import 'sessions.dart';

class CurreLocalStore {
  CurreLocalStore(this._preferences);

  static const String _settingsKey = 'curre.settings.v1';
  static const String _plansKey = 'curre.plans.v1';
  static const String _grantsKey = 'curre.grants.v1';
  static const String _attemptsKey = 'curre.attempts.v1';
  static const Duration historyRetention = Duration(days: 30);

  static Future<CurreLocalStore> open({DateTime? now}) async {
    final store = CurreLocalStore(await SharedPreferences.getInstance());
    final instant = now ?? DateTime.now();
    await store.loadAttempts(now: instant);
    await store.loadActiveGrants(now: instant);
    return store;
  }

  final SharedPreferences _preferences;

  Future<void> saveSettings(Settings settings) async {
    await _preferences.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Settings loadSettings() {
    final encoded = _preferences.getString(_settingsKey);
    if (encoded == null) return Settings();
    try {
      return Settings.fromJson(_decodeObject(encoded));
    } on Object {
      _preferences.remove(_settingsKey);
      return Settings();
    }
  }

  /// Persists plans for Curre's current local day, which begins at the morning
  /// session boundary rather than at midnight.
  Future<void> saveTodayPlans(
    Iterable<Plan> plans, {
    required DateTime now,
    CurreTimeZone timeZone = const SystemCurreTimeZone(),
  }) async {
    final day = SessionSchedule.fromSettings(
      loadSettings(),
      timeZone: timeZone,
    ).current(now).localStartDate;
    final values = plans
        .where((plan) => plan.date == day)
        .map((plan) => plan.toJson())
        .toList(growable: false);
    await _preferences.setString(_plansKey, jsonEncode(values));
  }

  Future<List<Plan>> loadTodayPlans({
    required DateTime now,
    CurreTimeZone timeZone = const SystemCurreTimeZone(),
  }) async {
    final day = SessionSchedule.fromSettings(
      loadSettings(),
      timeZone: timeZone,
    ).current(now).localStartDate;
    final all = _readList(_plansKey, Plan.fromJson);
    final current = all
        .where((plan) => plan.date == day)
        .toList(growable: false);
    if (current.length != all.length) {
      await _preferences.setString(
        _plansKey,
        jsonEncode(current.map((plan) => plan.toJson()).toList()),
      );
    }
    return current;
  }

  Future<void> saveActiveGrants(
    Iterable<Grant> grants, {
    required DateTime now,
  }) async {
    final current = activeGrants(grants, now);
    await _preferences.setString(
      _grantsKey,
      jsonEncode(current.map((grant) => grant.toJson()).toList()),
    );
  }

  Future<List<Grant>> loadActiveGrants({required DateTime now}) async {
    final all = _readList(_grantsKey, Grant.fromJson);
    final current = activeGrants(all, now);
    if (current.length != all.length) {
      await saveActiveGrants(current, now: now);
    }
    return current;
  }

  Future<void> appendAttempt(Attempt attempt, {required DateTime now}) async {
    final attempts = await loadAttempts(now: now);
    final cutoff = now.toUtc().subtract(historyRetention);
    final updated = <Attempt>[
      ...attempts,
      if (!attempt.at.isBefore(cutoff)) attempt,
    ]..sort((a, b) => a.at.compareTo(b.at));
    await _writeAttempts(updated);
  }

  Future<List<Attempt>> loadAttempts({required DateTime now}) async {
    final all = _readList(_attemptsKey, Attempt.fromJson);
    final cutoff = now.toUtc().subtract(historyRetention);
    final current =
        all
            .where((attempt) => !attempt.at.isBefore(cutoff))
            .toList(growable: false)
          ..sort((a, b) => a.at.compareTo(b.at));
    if (current.length != all.length) await _writeAttempts(current);
    return current;
  }

  /// Clears the 30-day attempt history without disrupting today's plan or an
  /// active unlock grant.
  Future<void> clearHistory() async {
    await _preferences.remove(_attemptsKey);
  }

  Future<void> _writeAttempts(Iterable<Attempt> attempts) async {
    await _preferences.setString(
      _attemptsKey,
      jsonEncode(attempts.map((attempt) => attempt.toJson()).toList()),
    );
  }

  List<T> _readList<T>(
    String key,
    T Function(Map<String, Object?> json) decode,
  ) {
    final encoded = _preferences.getString(key);
    if (encoded == null) return <T>[];
    try {
      final values = jsonDecode(encoded);
      if (values is! List) throw const FormatException('Expected a list');
      return values
          .map((value) => decode(_asObject(value)))
          .toList(growable: false);
    } on Object {
      _preferences.remove(key);
      return <T>[];
    }
  }
}

Map<String, Object?> _decodeObject(String encoded) =>
    _asObject(jsonDecode(encoded));

Map<String, Object?> _asObject(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.cast<String, Object?>();
  throw const FormatException('Expected an object');
}
