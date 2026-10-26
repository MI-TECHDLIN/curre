import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'grants.dart';
import 'models.dart';
import 'proof.dart';
import 'sessions.dart';

class CurreLocalStore {
  CurreLocalStore(this._preferences);

  static const String _settingsKey = 'curre.settings.v1';
  static const String _plansKey = 'curre.plans.v1';
  static const String _grantsKey = 'curre.grants.v1';
  static const String _attemptsKey = 'curre.attempts.v1';
  static const String _doorUsesKey = 'curre.doorUses.v1';
  static const String _onboardingKey = 'curre.onboarding.v1';
  static const String _planHistoryKey = 'curre.planHistory.v1';
  static const String _grantHistoryKey = 'curre.grantHistory.v1';
  static const String _taskTracesKey = 'curre.taskTraces.v1';
  static const String _proofRecordsKey = 'curre.proofRecords.v1';
  static const Duration historyRetention = Duration(days: 30);

  static Future<CurreLocalStore> open({DateTime? now}) async {
    final store = CurreLocalStore(await SharedPreferences.getInstance());
    final instant = now ?? DateTime.now();
    await store.loadAttempts(now: instant);
    await store.loadActiveGrants(now: instant);
    await store.loadPlanHistory(now: instant);
    await store.loadGrantHistory(now: instant);
    store.loadTaskTraces(now: instant);
    store.loadProofRecords(now: instant);
    return store;
  }

  final SharedPreferences _preferences;

  bool get isOnboardingComplete =>
      _preferences.getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingComplete(bool complete) =>
      _preferences.setBool(_onboardingKey, complete);

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
    final day = _today(now, timeZone);
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
    final day = _today(now, timeZone);
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

  /// Records that one of a plan's apps was opened from its row on Home.
  /// Uses are kept for the current Curre day only, like plans.
  Future<void> recordDoorUse(
    DoorUse use, {
    required DateTime now,
    CurreTimeZone timeZone = const SystemCurreTimeZone(),
  }) async {
    final current = await loadTodayDoorUses(now: now, timeZone: timeZone);
    final updated = <DoorUse>[
      ...current,
      if (use.date == _today(now, timeZone)) use,
    ]..sort((a, b) => a.at.compareTo(b.at));
    await _writeDoorUses(updated);
  }

  Future<List<DoorUse>> loadTodayDoorUses({
    required DateTime now,
    CurreTimeZone timeZone = const SystemCurreTimeZone(),
  }) async {
    final day = _today(now, timeZone);
    final all = _readList(_doorUsesKey, DoorUse.fromJson);
    final current = all.where((use) => use.date == day).toList(growable: false);
    if (current.length != all.length) await _writeDoorUses(current);
    return current;
  }

  /// Records that a planned task started. A trace only matters until the
  /// task's note is written, so traces follow the 30-day history.
  Future<void> appendTaskTrace(TaskTrace trace, {required DateTime now}) async {
    final current = loadTaskTraces(now: now);
    await _writeTaskTraces(<TaskTrace>[
      ...current.where((item) => item.id != trace.id),
      trace,
    ]);
  }

  List<TaskTrace> loadTaskTraces({required DateTime now}) {
    final all = _readEach(_taskTracesKey, TaskTrace.fromJson);
    final cutoff = now.toUtc().subtract(historyRetention);
    final current = all.where((trace) => !trace.at.isBefore(cutoff)).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    if (current.length != all.length) unawaited(_writeTaskTraces(current));
    return current;
  }

  /// Saves the one record a planned task keeps. Supported proof is never
  /// replaced by weaker evidence (see [ProoflightRules.preferRecord]).
  Future<void> upsertProofRecord(
    ProofRecord record, {
    required DateTime now,
  }) async {
    final current = loadProofRecords(now: now);
    final previous = current.where((item) => item.id == record.id).firstOrNull;
    await _writeProofRecords(<ProofRecord>[
      ...current.where((item) => item.id != record.id),
      ProoflightRules.preferRecord(previous, record),
    ]);
  }

  /// Proof records are kept for good, because the best run and every proof
  /// day outlive the 30-day history. Their words do not: past 30 days a
  /// record keeps only what the streak needs. A note still waiting for its
  /// answer keeps its words until it is judged.
  List<ProofRecord> loadProofRecords({required DateTime now}) {
    final cutoff = now.toUtc().subtract(historyRetention);
    var compacted = false;
    final records = <ProofRecord>[];
    for (final record in _readEach(_proofRecordsKey, ProofRecord.fromJson)) {
      final hasWords = record.note.isNotEmpty || record.taskText.isNotEmpty;
      if (hasWords &&
          !record.isPending &&
          record.submittedAt.isBefore(cutoff)) {
        records.add(record.withoutText());
        compacted = true;
      } else {
        records.add(record);
      }
    }
    records.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
    if (compacted) unawaited(_writeProofRecords(records));
    return records;
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

  Future<void> appendPlanHistory(Plan plan, {required DateTime now}) async {
    final current = await loadPlanHistory(now: now);
    final cutoff = now.toUtc().subtract(historyRetention);
    final updated = <Plan>[
      ...current.where((item) => item.id != plan.id),
      if (!plan.endsAt.isBefore(cutoff)) plan,
    ]..sort((a, b) => a.endsAt.compareTo(b.endsAt));
    await _writePlanHistory(updated);
  }

  Future<List<Plan>> loadPlanHistory({required DateTime now}) async {
    final all = _readList(_planHistoryKey, Plan.fromJson);
    final cutoff = now.toUtc().subtract(historyRetention);
    final current = all
        .where((plan) => !plan.endsAt.isBefore(cutoff))
        .toList(growable: false);
    if (current.length != all.length) await _writePlanHistory(current);
    return current;
  }

  Future<void> appendGrantHistory(Grant grant, {required DateTime now}) async {
    final current = await loadGrantHistory(now: now);
    final cutoff = now.toUtc().subtract(historyRetention);
    final updated = <Grant>[
      ...current.where(
        (item) =>
            item.packageName != grant.packageName ||
            item.grantedAt != grant.grantedAt,
      ),
      if (!grant.grantedAt.isBefore(cutoff)) grant,
    ]..sort((a, b) => a.grantedAt.compareTo(b.grantedAt));
    await _writeGrantHistory(updated);
  }

  Future<List<Grant>> loadGrantHistory({required DateTime now}) async {
    final all = _readList(_grantHistoryKey, Grant.fromJson);
    final cutoff = now.toUtc().subtract(historyRetention);
    final current = all
        .where((grant) => !grant.grantedAt.isBefore(cutoff))
        .toList(growable: false);
    if (current.length != all.length) await _writeGrantHistory(current);
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

  /// Clears private history without disrupting today's plan or an active
  /// unlock grant. Every word written after a task goes too; proof days
  /// stay, as dates and levels only (see [ProoflightRules.forgetWords]).
  Future<void> clearHistory() async {
    final proofDays = ProoflightRules.forgetWords(
      _readEach(_proofRecordsKey, ProofRecord.fromJson),
    );
    await Future.wait(<Future<bool>>[
      _preferences.remove(_attemptsKey),
      _preferences.remove(_planHistoryKey),
      _preferences.remove(_grantHistoryKey),
      _preferences.remove(_taskTracesKey),
    ]);
    await _writeProofRecords(proofDays);
  }

  /// Curre's current local day, which begins at the morning session
  /// boundary rather than at midnight.
  LocalDate _today(DateTime now, CurreTimeZone timeZone) =>
      SessionSchedule.fromSettings(
        loadSettings(),
        timeZone: timeZone,
      ).current(now).localStartDate;

  Future<void> _writeTaskTraces(List<TaskTrace> traces) async {
    traces.sort((a, b) => a.at.compareTo(b.at));
    await _preferences.setString(
      _taskTracesKey,
      jsonEncode(traces.map((trace) => trace.toJson()).toList()),
    );
  }

  Future<void> _writeProofRecords(List<ProofRecord> records) async {
    records.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
    await _preferences.setString(
      _proofRecordsKey,
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }

  Future<void> _writeDoorUses(Iterable<DoorUse> uses) async {
    await _preferences.setString(
      _doorUsesKey,
      jsonEncode(uses.map((use) => use.toJson()).toList()),
    );
  }

  Future<void> _writeAttempts(Iterable<Attempt> attempts) async {
    await _preferences.setString(
      _attemptsKey,
      jsonEncode(attempts.map((attempt) => attempt.toJson()).toList()),
    );
  }

  Future<void> _writePlanHistory(Iterable<Plan> plans) async {
    await _preferences.setString(
      _planHistoryKey,
      jsonEncode(plans.map((plan) => plan.toJson()).toList()),
    );
  }

  Future<void> _writeGrantHistory(Iterable<Grant> grants) async {
    await _preferences.setString(
      _grantHistoryKey,
      jsonEncode(grants.map((grant) => grant.toJson()).toList()),
    );
  }

  /// Like [_readList], but one unreadable entry is skipped instead of
  /// clearing the rest: Prooflight's records hold a streak that took weeks
  /// to earn.
  List<T> _readEach<T>(
    String key,
    T Function(Map<String, Object?> json) decode,
  ) {
    final encoded = _preferences.getString(key);
    if (encoded == null) return <T>[];
    final Object? values;
    try {
      values = jsonDecode(encoded);
    } on FormatException {
      _preferences.remove(key);
      return <T>[];
    }
    if (values is! List) {
      _preferences.remove(key);
      return <T>[];
    }
    final result = <T>[];
    for (final value in values) {
      try {
        result.add(decode(_asObject(value)));
      } on Object {
        // Skipped; the next write leaves it out.
      }
    }
    return result;
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
