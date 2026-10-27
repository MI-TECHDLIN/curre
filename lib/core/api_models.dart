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
    this.threshold = 0.7,
    List<String> shortcutLabels = const <String>[],
  }) : shortcutLabels = List.unmodifiable(shortcutLabels) {
    _checkLength(appLabel, 'appLabel', minimum: 1, maximum: 60);
    if (planIntention != null) {
      _checkLength(planIntention!, 'planIntention', maximum: 500);
    }
    _checkLength(reason, 'reason', minimum: 8, maximum: 300);
    _checkLabels(shortcutLabels, 'shortcutLabels');
    if (!threshold.isFinite) {
      throw ArgumentError.value(threshold, 'threshold', 'must be finite');
    }
  }

  final String appLabel;
  final String? planIntention;
  final String reason;
  final List<String> shortcutLabels;
  final double threshold;

  Map<String, Object?> toJson() => <String, Object?>{
    'app_label': appLabel,
    if (planIntention != null) 'plan_intention': planIntention,
    'reason': reason,
    'shortcut_labels': shortcutLabels,
    'threshold': threshold,
  };
}

/// A kind of personal detail the reader looks for before a reason or note
/// is kept in History.
enum PersonalDetailKind {
  person,
  phone,
  email,
  address,
  creditCard,
  bankAccount,
}

extension PersonalDetailKindWire on PersonalDetailKind {
  static PersonalDetailKind fromWireValue(String value) => switch (value) {
    'person' => PersonalDetailKind.person,
    'phone' => PersonalDetailKind.phone,
    'email' => PersonalDetailKind.email,
    'address' => PersonalDetailKind.address,
    'credit_card' => PersonalDetailKind.creditCard,
    'bank_account' => PersonalDetailKind.bankAccount,
    _ => throw FormatException('Unknown personal detail: $value'),
  };
}

/// A personal detail found in the reason or note the phone sent, as
/// code-point offsets into that text. It carries no copy of the words.
class Redaction {
  const Redaction({required this.kind, required this.start, required this.end});

  factory Redaction.fromJson(Map<String, Object?> json) {
    final start = _integer(json['start'], 'start');
    final end = _integer(json['end'], 'end');
    if (start < 0 || end <= start) {
      throw FormatException('Invalid redaction [$start, $end)');
    }
    return Redaction(
      kind: PersonalDetailKindWire.fromWireValue(_string(json['kind'], 'kind')),
      start: start,
      end: end,
    );
  }

  final PersonalDetailKind kind;
  final int start;
  final int end;
}

List<Redaction>? _redactions(Object? value) => value == null
    ? null
    : _list(value, 'redactions')
          .map((item) => Redaction.fromJson(_map(item, 'redactions[]')))
          .toList(growable: false);

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
    this.redactions,
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
    redactions: _redactions(json['redactions']),
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
      redactions = null,
      usage = null;

  final UnlockOutcome outcome;
  final ReasonKind? kind;
  final double? confidence;
  final String? door;
  final SourceSpan? target;
  final SourceSpan? person;
  final int? minutes;
  final GuardInfo? guard;

  /// Personal details in the reason, for the copy History keeps; null when
  /// they could not be looked for, and the reason is kept as typed.
  final List<Redaction>? redactions;
  final ApiUsage? usage;

  String? targetTextFromReason(String reason) =>
      target == null ? null : sliceExtractSpan(reason, target!);

  String? personTextFromReason(String reason) =>
      person == null ? null : sliceExtractSpan(reason, person!);

  /// Guard offsets do not index [reason]; the literal quote is authoritative.
  String? get guardQuoteText => guard?.quote.text;
}

/// The backend's verdict on a completion note. [pending] covers every way
/// the note went unanswered: offline, a timeout, an error or a malformed
/// reply. It is never a judgement of the note.
enum ProofOutcome { accepted, vague, pending }

/// How Decide classed a completion note.
enum ProofKind { specificCompletion, vague, future, unrelated }

extension ProofKindWire on ProofKind {
  String get wireValue => switch (this) {
    ProofKind.specificCompletion => 'specific_completion',
    ProofKind.vague => 'vague',
    ProofKind.future => 'future',
    ProofKind.unrelated => 'unrelated',
  };

  static ProofKind fromWireValue(String value) => switch (value) {
    'specific_completion' => ProofKind.specificCompletion,
    'vague' => ProofKind.vague,
    'future' => ProofKind.future,
    'unrelated' => ProofKind.unrelated,
    _ => throw FormatException('Unknown proof kind: $value'),
  };
}

class ProofRequest {
  ProofRequest({required this.task, required this.note}) {
    _checkLength(task, 'task', minimum: 1, maximum: 500);
    _checkLength(note, 'note', minimum: 1, maximum: 300);
  }

  /// The plan in the user's words.
  final String task;

  /// What the user said changed, finished or became clear.
  final String note;

  Map<String, Object?> toJson() => <String, Object?>{
    'task': task,
    'note': note,
  };
}

class ProofResponse {
  const ProofResponse({
    required this.outcome,
    this.kind,
    this.specificCompletion,
    this.result,
    this.learning,
    this.mismatch,
    this.redactions,
    this.usage,
  });

  factory ProofResponse.fromJson(Map<String, Object?> json) => ProofResponse(
    outcome: switch (_string(json['outcome'], 'outcome')) {
      'accepted' => ProofOutcome.accepted,
      'vague' => ProofOutcome.vague,
      'pending' => ProofOutcome.pending,
      final value => throw FormatException('Unknown proof outcome: $value'),
    },
    kind: json['kind'] == null
        ? null
        : ProofKindWire.fromWireValue(_string(json['kind'], 'kind')),
    specificCompletion: json['specific_completion'] == null
        ? null
        : _number(
            json['specific_completion'],
            'specific_completion',
          ).toDouble(),
    result: json['result'] == null
        ? null
        : SourceSpan.fromJson(_map(json['result'], 'result')),
    learning: json['learning'] == null
        ? null
        : SourceSpan.fromJson(_map(json['learning'], 'learning')),
    mismatch: _nullableString(json['mismatch'], 'mismatch'),
    redactions: _redactions(json['redactions']),
    usage: json['usage'] == null
        ? null
        : ApiUsage.fromJson(_map(json['usage'], 'usage')),
  );

  const ProofResponse.pending()
    : outcome = ProofOutcome.pending,
      kind = null,
      specificCompletion = null,
      result = null,
      learning = null,
      mismatch = null,
      redactions = null,
      usage = null;

  final ProofOutcome outcome;

  /// Decide's choice, when the note was judged. A note Guard stopped is
  /// vague with no kind.
  final ProofKind? kind;

  /// Decide's probability for `specific_completion`.
  final double? specificCompletion;

  /// Spans Extract copied from the note; offsets index the note itself.
  final SourceSpan? result;
  final SourceSpan? learning;

  /// The note's own words that say something other than the planned task
  /// happened, when they kept the note from counting.
  final String? mismatch;

  /// Personal details in the note, for the copy History keeps; null when
  /// they could not be looked for, and the note is kept as typed.
  final List<Redaction>? redactions;
  final ApiUsage? usage;
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
