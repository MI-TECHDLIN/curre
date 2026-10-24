import 'models.dart';
import 'span.dart';

class ApiUsage {
  const ApiUsage({required this.credits, required this.modelMilliseconds})
    : assert(credits >= 0),
      assert(modelMilliseconds >= 0);

  factory ApiUsage.fromJson(Map<String, Object?> json) => ApiUsage(
    credits: _integer(json['credits'], 'credits'),
    modelMilliseconds: _number(json['model_ms'], 'model_ms').toDouble(),
  );

  final int credits;
  final double modelMilliseconds;

  Map<String, Object?> toJson() => <String, Object?>{
    'credits': credits,
    'model_ms': modelMilliseconds,
  };
}

class PlanCandidate {
  PlanCandidate({
    required this.id,
    required this.label,
    List<String> shortcutLabels = const <String>[],
    this.hasQueryDoor = false,
  }) : shortcutLabels = List.unmodifiable(shortcutLabels) {
    _checkLength(id, 'id', minimum: 1);
    _checkLength(label, 'label', minimum: 1, maximum: 60);
    _checkLabels(shortcutLabels, 'shortcutLabels');
  }

  final String id;
  final String label;
  final List<String> shortcutLabels;
  final bool hasQueryDoor;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'label': label,
    'shortcut_labels': shortcutLabels,
    'query_door': hasQueryDoor,
  };
}

class PlanRequest {
  PlanRequest({
    required this.session,
    required this.intention,
    required List<PlanCandidate> candidates,
  }) : candidates = List.unmodifiable(candidates) {
    _checkLength(intention, 'intention', minimum: 1, maximum: 500);
    if (candidates.length < 2 || candidates.length > 30) {
      throw RangeError.range(candidates.length, 2, 30, 'candidates.length');
    }
    _checkUnique(candidates.map((candidate) => candidate.id), 'candidate ids');
    _checkUnique(
      candidates.map((candidate) => candidate.label),
      'candidate labels',
    );
  }

  final SessionName session;
  final String intention;
  final List<PlanCandidate> candidates;

  Map<String, Object?> toJson() => <String, Object?>{
    'session': session.wireValue,
    'intention': intention,
    'candidates': candidates
        .map((candidate) => candidate.toJson())
        .toList(growable: false),
  };
}

class PlanSelection {
  const PlanSelection({required this.id, this.door, this.query});

  factory PlanSelection.fromJson(Map<String, Object?> json) => PlanSelection(
    id: _string(json['id'], 'id'),
    door: _nullableString(json['door'], 'door'),
    query: json['query'] == null
        ? null
        : SourceSpan.fromJson(_map(json['query'], 'query')),
  );

  final String id;
  final String? door;
  final SourceSpan? query;
}

class PlanResponse {
  PlanResponse({
    required List<PlanSelection> apps,
    required this.usage,
    this.endPhrase,
  }) : apps = List.unmodifiable(apps);

  factory PlanResponse.fromJson(Map<String, Object?> json) => PlanResponse(
    apps: _list(json['apps'], 'apps')
        .map((value) => PlanSelection.fromJson(_map(value, 'apps[]')))
        .toList(growable: false),
    endPhrase: json['end_phrase'] == null
        ? null
        : SourceSpan.fromJson(_map(json['end_phrase'], 'end_phrase')),
    usage: ApiUsage.fromJson(_map(json['usage'], 'usage')),
  );

  final List<PlanSelection> apps;
  final SourceSpan? endPhrase;
  final ApiUsage usage;

  String? endTextFromIntention(String intention) =>
      endPhrase == null ? null : sliceExtractSpan(intention, endPhrase!);
}

class UnlockRequest {
  UnlockRequest({
    required this.appLabel,
    required this.reason,
    this.planIntention,
    List<String> shortcutLabels = const <String>[],
  }) : shortcutLabels = List.unmodifiable(shortcutLabels) {
    _checkLength(appLabel, 'appLabel', minimum: 1, maximum: 60);
    if (planIntention != null) {
      _checkLength(planIntention!, 'planIntention', maximum: 500);
    }
    _checkLength(reason, 'reason', minimum: 8, maximum: 300);
    _checkLabels(shortcutLabels, 'shortcutLabels');
  }

  final String appLabel;
  final String? planIntention;
  final String reason;
  final List<String> shortcutLabels;

  Map<String, Object?> toJson() => <String, Object?>{
    'app_label': appLabel,
    if (planIntention != null) 'plan_intention': planIntention,
    'reason': reason,
    'shortcut_labels': shortcutLabels,
  };
}

class GuardInfo {
  const GuardInfo({required this.category, required this.quote});

  factory GuardInfo.fromJson(Map<String, Object?> json) => GuardInfo(
    category: _string(json['category'], 'category'),
    quote: SourceSpan.fromJson(_map(json['quote'], 'quote')),
  );

  final String category;

  /// Offsets index the backend's composed Guard text, not the bare reason.
  /// Render [SourceSpan.text] directly unless that composed text is available.
  final SourceSpan quote;
}

class UnlockResponse {
  const UnlockResponse({
    required this.outcome,
    this.kind,
    this.confidence,
    this.door,
    this.target,
    this.person,
    this.minutes,
    this.guard,
    this.usage,
  });

  factory UnlockResponse.fromJson(Map<String, Object?> json) => UnlockResponse(
    outcome: UnlockOutcomeWire.fromWireValue(
      _string(json['outcome'], 'outcome'),
    ),
    kind: json['kind'] == null
        ? null
        : ReasonKindWire.fromWireValue(_string(json['kind'], 'kind')),
    confidence: json['confidence'] == null
        ? null
        : _number(json['confidence'], 'confidence').toDouble(),
    door: _nullableString(json['door'], 'door'),
    target: json['target'] == null
        ? null
        : SourceSpan.fromJson(_map(json['target'], 'target')),
    person: json['person'] == null
        ? null
        : SourceSpan.fromJson(_map(json['person'], 'person')),
    minutes: json['minutes'] == null
        ? null
        : _integer(json['minutes'], 'minutes'),
    guard: json['guard'] == null
        ? null
        : GuardInfo.fromJson(_map(json['guard'], 'guard')),
    usage: json['usage'] == null
        ? null
        : ApiUsage.fromJson(_map(json['usage'], 'usage')),
  );

  const UnlockResponse.unavailable()
    : outcome = UnlockOutcome.unavailable,
      kind = null,
      confidence = null,
      door = null,
      target = null,
      person = null,
      minutes = null,
      guard = null,
      usage = null;

  final UnlockOutcome outcome;
  final ReasonKind? kind;
  final double? confidence;
  final String? door;
  final SourceSpan? target;
  final SourceSpan? person;
  final int? minutes;
  final GuardInfo? guard;
  final ApiUsage? usage;

  String? targetTextFromReason(String reason) =>
      target == null ? null : sliceExtractSpan(reason, target!);

  String? personTextFromReason(String reason) =>
      person == null ? null : sliceExtractSpan(reason, person!);

  /// Guard offsets do not index [reason]; the literal quote is authoritative.
  String? get guardQuoteText => guard?.quote.text;
}

void _checkLength(String value, String name, {int minimum = 0, int? maximum}) {
  final length = value.runes.length;
  if (length < minimum || (maximum != null && length > maximum)) {
    throw RangeError.range(length, minimum, maximum, '$name code-point length');
  }
}

void _checkLabels(List<String> labels, String name) {
  for (final label in labels) {
    _checkLength(label, '$name[]', minimum: 1, maximum: 60);
  }
  _checkUnique(labels, name);
}

void _checkUnique(Iterable<String> values, String name) {
  final list = values.toList(growable: false);
  if (list.toSet().length != list.length) {
    throw ArgumentError('$name must be unique');
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

num _number(Object? value, String name) {
  if (value is num) return value;
  throw FormatException('$name must be a number');
}

int _integer(Object? value, String name) {
  if (value is int) return value;
  throw FormatException('$name must be an integer');
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
      // Fall through.
    }
  }
  throw FormatException('$name must be an object');
}
