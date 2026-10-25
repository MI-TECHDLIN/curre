import '../doors/door_models.dart' show ReasonKind;
export '../doors/door_models.dart' show ReasonKind;

import 'span.dart';

enum SessionName { morning, afternoon, evening }

enum PlanSource { clocked, manual }

enum GrantSource { clocked, override }

enum UnlockOutcome { open, later, specify, flagged, unavailable }

T _enumByWireValue<T extends Enum>(
  List<T> values,
  String value,
  String Function(T value) wireValue,
) {
  for (final candidate in values) {
    if (wireValue(candidate) == value) return candidate;
  }
  throw FormatException('Unknown enum value: $value');
}

extension SessionNameWire on SessionName {
  String get wireValue => name;

  static SessionName fromWireValue(String value) =>
      _enumByWireValue(SessionName.values, value, (value) => value.wireValue);
}

extension PlanSourceWire on PlanSource {
  String get wireValue => name;

  static PlanSource fromWireValue(String value) =>
      _enumByWireValue(PlanSource.values, value, (value) => value.wireValue);
}

extension GrantSourceWire on GrantSource {
  String get wireValue => name;

  static GrantSource fromWireValue(String value) =>
      _enumByWireValue(GrantSource.values, value, (value) => value.wireValue);
}

extension UnlockOutcomeWire on UnlockOutcome {
  String get wireValue => name;

  static UnlockOutcome fromWireValue(String value) =>
      _enumByWireValue(UnlockOutcome.values, value, (value) => value.wireValue);
}

extension ReasonKindWire on ReasonKind {
  String get wireValue => switch (this) {
    ReasonKind.timeSensitive => 'time_sensitive',
    _ => name,
  };

  static ReasonKind fromWireValue(String value) =>
      _enumByWireValue(ReasonKind.values, value, (value) => value.wireValue);
}

/// A calendar date without a time zone.
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.fromJson(Object? json) {
    if (json is! String) throw const FormatException('Date must be a string');
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(json);
    if (match == null) throw FormatException('Invalid local date: $json');
    final result = LocalDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    final normalized = DateTime.utc(result.year, result.month, result.day);
    if (normalized.year != result.year ||
        normalized.month != result.month ||
        normalized.day != result.day) {
      throw FormatException('Invalid local date: $json');
    }
    return result;
  }

  factory LocalDate.fromLocalDateTime(DateTime value) =>
      LocalDate(value.year, value.month, value.day);

  final int year;
  final int month;
  final int day;

  LocalDate addDays(int days) {
    final next = DateTime.utc(year, month, day).add(Duration(days: days));
    return LocalDate(next.year, next.month, next.day);
  }

  String toJson() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalDate other) => DateTime.utc(
    year,
    month,
    day,
  ).compareTo(DateTime.utc(other.year, other.month, other.day));

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toJson();
}

/// A wall-clock time, stored as minutes after midnight.
class LocalTime implements Comparable<LocalTime> {
  const LocalTime(this.hour, [this.minute = 0])
    : assert(hour >= 0 && hour <= 23),
      assert(minute >= 0 && minute <= 59);

  factory LocalTime.fromMinutes(int value) {
    if (value < 0 || value >= minutesPerDay) {
      throw RangeError.range(value, 0, minutesPerDay - 1, 'value');
    }
    return LocalTime(value ~/ 60, value % 60);
  }

  factory LocalTime.fromJson(Object? json) {
    if (json is! int) {
      throw const FormatException('Local time must be minutes after midnight');
    }
    try {
      return LocalTime.fromMinutes(json);
    } on RangeError {
      throw FormatException('Invalid local time: $json');
    }
  }

  static const int minutesPerDay = 24 * 60;

  final int hour;
  final int minute;

  int get minutesAfterMidnight => hour * 60 + minute;

  int toJson() => minutesAfterMidnight;

  @override
  int compareTo(LocalTime other) =>
      minutesAfterMidnight.compareTo(other.minutesAfterMidnight);

  @override
  bool operator ==(Object other) =>
      other is LocalTime && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class Settings {
  Settings({
    Map<SessionName, LocalTime>? sessionStarts,
    Set<String> essentials = const <String>{},
    Set<String> candidates = const <String>{},
    this.unlockMinutes = 5,
    this.threshold = 0.7,
    String? displayName,
    String? avatarId,
  }) : displayName = normalizeDisplayName(displayName),
       avatarId = _normalizeOptionalText(avatarId),
       sessionStarts = Map.unmodifiable(
         sessionStarts ??
             const <SessionName, LocalTime>{
               SessionName.morning: LocalTime(4),
               SessionName.afternoon: LocalTime(12),
               SessionName.evening: LocalTime(17),
             },
       ),
       essentials = Set.unmodifiable(essentials),
       candidates = Set.unmodifiable(candidates) {
    _validate();
  }

  factory Settings.fromJson(Map<String, Object?> json) {
    final startsJson = _map(json['sessionStarts'], 'sessionStarts');
    final starts = <SessionName, LocalTime>{};
    for (final entry in startsJson.entries) {
      starts[SessionNameWire.fromWireValue(entry.key)] = LocalTime.fromJson(
        entry.value,
      );
    }
    return Settings(
      sessionStarts: starts,
      essentials: _stringSet(json['essentials'], 'essentials'),
      candidates: _stringSet(json['candidates'], 'candidates'),
      unlockMinutes: _int(json['unlockMinutes'], 'unlockMinutes'),
      threshold: _number(json['threshold'], 'threshold').toDouble(),
      // Absent in settings saved before names existed, which still load.
      displayName: _nullableString(json['displayName'], 'displayName'),
      // Absent in settings saved before avatars existed, which still load.
      avatarId: _nullableString(json['avatarId'], 'avatarId'),
    );
  }

  final Map<SessionName, LocalTime> sessionStarts;
  final Set<String> essentials;
  final Set<String> candidates;
  final int unlockMinutes;
  final double threshold;

  /// What the greeting calls the user ("Good morning, Chidi"), or null when
  /// they have not given a name. Onboarding will ask for it; until then the
  /// greeting stands alone.
  final String? displayName;

  /// The stable ID of the chosen design-system avatar. A null or unknown ID
  /// deliberately falls back to the user's initial in the UI.
  final String? avatarId;

  Settings copyWith({
    Map<SessionName, LocalTime>? sessionStarts,
    Set<String>? essentials,
    Set<String>? candidates,
    int? unlockMinutes,
    double? threshold,
    String? displayName,
    bool clearDisplayName = false,
    String? avatarId,
    bool clearAvatarId = false,
  }) => Settings(
    sessionStarts: sessionStarts ?? this.sessionStarts,
    essentials: essentials ?? this.essentials,
    candidates: candidates ?? this.candidates,
    unlockMinutes: unlockMinutes ?? this.unlockMinutes,
    threshold: threshold ?? this.threshold,
    displayName: clearDisplayName ? null : displayName ?? this.displayName,
    avatarId: clearAvatarId ? null : avatarId ?? this.avatarId,
  );

  /// Trims [name] and collapses inner runs of whitespace; a blank name is
  /// no name, so the greeting never ends in a dangling comma.
  static String? normalizeDisplayName(String? name) {
    if (name == null) return null;
    final tidy = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    return tidy.isEmpty ? null : tidy;
  }

  static String? _normalizeOptionalText(String? value) {
    final tidy = value?.trim();
    return tidy == null || tidy.isEmpty ? null : tidy;
  }

  void _validate() {
    if (sessionStarts.length != SessionName.values.length ||
        !sessionStarts.keys.toSet().containsAll(SessionName.values)) {
      throw ArgumentError('A start time is required for every session');
    }
    final ordered = SessionName.values
        .map((session) => sessionStarts[session]!.minutesAfterMidnight)
        .toList(growable: false);
    if (!(ordered[0] < ordered[1] && ordered[1] < ordered[2])) {
      throw ArgumentError(
        'Session starts must be unique and ordered morning, afternoon, evening',
      );
    }
    if (unlockMinutes < 1 || unlockMinutes > 30) {
      throw RangeError.range(unlockMinutes, 1, 30, 'unlockMinutes');
    }
    if (!threshold.isFinite || threshold < 0 || threshold > 1) {
      throw RangeError.range(threshold, 0, 1, 'threshold');
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'sessionStarts': <String, Object?>{
      for (final session in SessionName.values)
        session.wireValue: sessionStarts[session]!.toJson(),
    },
    'essentials': essentials.toList()..sort(),
    'candidates': candidates.toList()..sort(),
    'unlockMinutes': unlockMinutes,
    'threshold': threshold,
    if (displayName != null) 'displayName': displayName,
    if (avatarId != null) 'avatarId': avatarId,
  };
}

class AppEntry {
  const AppEntry({
    required this.packageName,
    required this.label,
    required this.isEssential,
    required this.isCandidate,
  });

  factory AppEntry.fromJson(Map<String, Object?> json) => AppEntry(
    packageName: _string(json['package'], 'package'),
    label: _string(json['label'], 'label'),
    isEssential: _bool(json['isEssential'], 'isEssential'),
    isCandidate: _bool(json['isCandidate'], 'isCandidate'),
  );

  final String packageName;
  final String label;
  final bool isEssential;
  final bool isCandidate;

  Map<String, Object?> toJson() => <String, Object?>{
    'package': packageName,
    'label': label,
    'isEssential': isEssential,
    'isCandidate': isCandidate,
  };
}

class PlannedApp {
  const PlannedApp({required this.packageName, this.door, this.query});

  factory PlannedApp.fromJson(Map<String, Object?> json) => PlannedApp(
    packageName: _string(json['package'], 'package'),
    door: _nullableString(json['door'], 'door'),
    query: json['query'] == null
        ? null
        : SourceSpan.fromJson(_map(json['query'], 'query')),
  );

  final String packageName;
  final String? door;
  final SourceSpan? query;

  Map<String, Object?> toJson() => <String, Object?>{
    'package': packageName,
    if (door != null) 'door': door,
    if (query != null) 'query': query!.toJson(),
  };
}

class Plan {
  Plan({
    required this.id,
    required this.session,
    required this.date,
    required this.intention,
    required List<PlannedApp> apps,
    required DateTime endsAt,
    required this.source,
    this.endPhrase,
  }) : apps = List.unmodifiable(apps),
       endsAt = _asUtc(endsAt);

  factory Plan.fromJson(Map<String, Object?> json) => Plan(
    id: _string(json['id'], 'id'),
    session: SessionNameWire.fromWireValue(_string(json['session'], 'session')),
    date: LocalDate.fromJson(json['date']),
    intention: _string(json['intention'], 'intention'),
    apps: _list(json['apps'], 'apps')
        .map((value) => PlannedApp.fromJson(_map(value, 'apps[]')))
        .toList(growable: false),
    endsAt: _instant(json['endsAt'], 'endsAt'),
    endPhrase: json['endPhrase'] == null
        ? null
        : SourceSpan.fromJson(_map(json['endPhrase'], 'endPhrase')),
    source: PlanSourceWire.fromWireValue(_string(json['source'], 'source')),
  );

  final String id;
  final SessionName session;
  final LocalDate date;
  final String intention;
  final List<PlannedApp> apps;
  final DateTime endsAt;
  final SourceSpan? endPhrase;
  final PlanSource source;

  Set<String> get packages => apps.map((app) => app.packageName).toSet();

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'session': session.wireValue,
    'date': date.toJson(),
    'intention': intention,
    'apps': apps.map((app) => app.toJson()).toList(growable: false),
    'endsAt': endsAt.toIso8601String(),
    if (endPhrase != null) 'endPhrase': endPhrase!.toJson(),
    'source': source.wireValue,
  };
}

class Grant {
  Grant({
    required this.packageName,
    required this.reason,
    required this.task,
    required DateTime grantedAt,
    required DateTime expiresAt,
    required this.source,
    this.kind,
  }) : grantedAt = _asUtc(grantedAt),
       expiresAt = _asUtc(expiresAt) {
    if (!this.expiresAt.isAfter(this.grantedAt)) {
      throw ArgumentError('expiresAt must be after grantedAt');
    }
  }

  factory Grant.fromJson(Map<String, Object?> json) => Grant(
    packageName: _string(json['package'], 'package'),
    reason: _string(json['reason'], 'reason'),
    task: _nullableString(json['task'], 'task'),
    grantedAt: _instant(json['grantedAt'], 'grantedAt'),
    expiresAt: _instant(json['expiresAt'], 'expiresAt'),
    source: GrantSourceWire.fromWireValue(_string(json['source'], 'source')),
    kind: json['kind'] == null
        ? null
        : ReasonKindWire.fromWireValue(_string(json['kind'], 'kind')),
  );

  final String packageName;
  final String reason;
  final String? task;
  final DateTime grantedAt;
  final DateTime expiresAt;
  final GrantSource source;
  final ReasonKind? kind;

  bool isActiveAt(DateTime instant) => _asUtc(instant).isBefore(expiresAt);

  Map<String, Object?> toJson() => <String, Object?>{
    'package': packageName,
    'reason': reason,
    'task': task,
    'grantedAt': grantedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'source': source.wireValue,
    if (kind != null) 'kind': kind!.wireValue,
  };
}

class Attempt {
  Attempt({
    required DateTime at,
    required this.packageName,
    required this.outcome,
    required this.confidence,
    required this.overridden,
    this.kind,
    this.reason,
    List<SourceSpan> highlights = const <SourceSpan>[],
  }) : at = _asUtc(at),
       highlights = List.unmodifiable(highlights) {
    if (confidence != null &&
        (!confidence!.isFinite || confidence! < 0 || confidence! > 1)) {
      throw RangeError.range(confidence!, 0, 1, 'confidence');
    }
  }

  factory Attempt.fromJson(Map<String, Object?> json) => Attempt(
    at: _instant(json['at'], 'at'),
    packageName: _string(json['package'], 'package'),
    outcome: UnlockOutcomeWire.fromWireValue(
      _string(json['outcome'], 'outcome'),
    ),
    confidence: json['confidence'] == null
        ? null
        : _number(json['confidence'], 'confidence').toDouble(),
    overridden: _bool(json['overridden'], 'overridden'),
    kind: json['kind'] == null
        ? null
        : ReasonKindWire.fromWireValue(_string(json['kind'], 'kind')),
    reason: _nullableString(json['reason'], 'reason'),
    highlights: json['highlights'] == null
        ? const <SourceSpan>[]
        : _list(json['highlights'], 'highlights')
              .map((value) => SourceSpan.fromJson(_map(value, 'highlights[]')))
              .toList(growable: false),
  );

  final DateTime at;
  final String packageName;
  final UnlockOutcome outcome;
  final double? confidence;
  final bool overridden;
  final ReasonKind? kind;
  final String? reason;
  final List<SourceSpan> highlights;

  Map<String, Object?> toJson() => <String, Object?>{
    'at': at.toIso8601String(),
    'package': packageName,
    'outcome': outcome.wireValue,
    'confidence': confidence,
    'overridden': overridden,
    if (kind != null) 'kind': kind!.wireValue,
    if (reason != null) 'reason': reason,
    if (highlights.isNotEmpty)
      'highlights': highlights
          .map((span) => span.toJson())
          .toList(growable: false),
  };
}

/// One open of a plan's app from its row on Home: the start trace that
/// today's progress counts, and that a proof-backed streak will need before
/// it accepts a completion note.
class DoorUse {
  DoorUse({
    required this.planId,
    required this.date,
    required this.packageName,
    required DateTime at,
  }) : at = _asUtc(at);

  /// A use of [packageName]'s row on [plan], dated to the plan's Curre day.
  factory DoorUse.forPlan(Plan plan, String packageName, DateTime at) {
    if (!plan.packages.contains(packageName)) {
      throw ArgumentError.value(packageName, 'packageName', 'Not in the plan');
    }
    return DoorUse(
      planId: plan.id,
      date: plan.date,
      packageName: packageName,
      at: at,
    );
  }

  factory DoorUse.fromJson(Map<String, Object?> json) => DoorUse(
    planId: _string(json['planId'], 'planId'),
    date: LocalDate.fromJson(json['date']),
    packageName: _string(json['package'], 'package'),
    at: _instant(json['at'], 'at'),
  );

  final String planId;

  /// The Curre day of the plan the row belongs to.
  final LocalDate date;
  final String packageName;
  final DateTime at;

  Map<String, Object?> toJson() => <String, Object?>{
    'planId': planId,
    'date': date.toJson(),
    'package': packageName,
    'at': at.toIso8601String(),
  };
}

DateTime _asUtc(DateTime value) => value.toUtc();

DateTime _instant(Object? value, String name) {
  final text = _string(value, name);
  try {
    return DateTime.parse(text).toUtc();
  } on FormatException {
    throw FormatException('$name must be an ISO-8601 instant');
  }
}

String _string(Object? value, String name) {
  if (value is String) return value;
  throw FormatException('$name must be a string');
}

String? _nullableString(Object? value, String name) {
  if (value == null || value is String) return value as String?;
  throw FormatException('$name must be a string or null');
}

int _int(Object? value, String name) {
  if (value is int) return value;
  throw FormatException('$name must be an integer');
}

num _number(Object? value, String name) {
  if (value is num) return value;
  throw FormatException('$name must be a number');
}

bool _bool(Object? value, String name) {
  if (value is bool) return value;
  throw FormatException('$name must be a boolean');
}

List<Object?> _list(Object? value, String name) {
  if (value is List<Object?>) return value;
  throw FormatException('$name must be a list');
}

Map<String, Object?> _map(Object? value, String name) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    try {
      return value.cast<String, Object?>();
    } on TypeError {
      // Fall through to a useful format error.
    }
  }
  throw FormatException('$name must be an object');
}

Set<String> _stringSet(Object? value, String name) {
  final result = <String>{};
  for (final item in _list(value, name)) {
    result.add(_string(item, '$name[]'));
  }
  return result;
}
