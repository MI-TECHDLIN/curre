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

/// The longest app or shortcut label the backend takes, in code points.
const int maxApiLabelLength = 60;

/// The most apps one plan request carries.
const int maxPlanCandidates = 30;

/// The most shortcut labels sent for one app.
const int maxShortcutLabels = 15;

/// Labels the plan and unlock steps already use for "no specific part of
/// the app", so a shortcut with one of them would be ambiguous.
const Set<String> _reservedShortcutLabels = <String>{'The app itself', 'app'};

/// An app or shortcut label tidied for the backend: whitespace (including
/// the newlines some apps put in their names) collapsed and cut to
/// [maxApiLabelLength] code points. Null when nothing usable is left.
String? cleanApiLabel(String value) {
  final collapsed = value.trim().split(RegExp(r'\s+')).join(' ');
  final cut = String.fromCharCodes(collapsed.runes.take(maxApiLabelLength))
      .trimRight();
  return cut.isEmpty ? null : cut;
}

/// The shortcut labels worth sending, in order: an empty, over-long,
/// repeated or reserved one is dropped rather than failing the request,
/// and at most [maxShortcutLabels] are kept.
List<String> cleanShortcutLabels(Iterable<String> labels) {
  final kept = <String>[];
  for (final raw in labels) {
    final label = raw.trim().split(RegExp(r'\s+')).join(' ');
    if (label.isEmpty ||
        label.runes.length > maxApiLabelLength ||
        _reservedShortcutLabels.contains(label) ||
        kept.contains(label)) {
      continue;
    }
    kept.add(label);
    if (kept.length == maxShortcutLabels) break;
  }
  return List.unmodifiable(kept);
}

/// One installed app as the phone knows it, before it is cleaned into a
/// [PlanCandidate].
typedef PlanAppInfo = ({
  String id,
  String label,
  Iterable<String> shortcutLabels,
  bool hasQueryDoor,
});

/// Turns the phone's apps into candidates every backend version accepts,
/// so one odd app never fails the whole plan: an app with an empty id or
/// label, or an id already used, is left out; labels are tidied and a
/// repeated label gets a number ("Notes 2"); shortcut labels are cleaned
/// with [cleanShortcutLabels]; at most [maxPlanCandidates] are kept.
List<PlanCandidate> planCandidatesFrom(Iterable<PlanAppInfo> apps) {
  final candidates = <PlanCandidate>[];
  final ids = <String>{};
  final labels = <String>{};
  for (final app in apps) {
    if (candidates.length == maxPlanCandidates) break;
    if (app.id.trim().isEmpty || ids.contains(app.id)) continue;
    final base = cleanApiLabel(app.label);
    if (base == null) continue;
    var label = base;
    for (var n = 2; labels.contains(label); n++) {
      final suffix = ' $n';
      final room = maxApiLabelLength - suffix.length;
      label =
          '${String.fromCharCodes(base.runes.take(room)).trimRight()}$suffix';
    }
    ids.add(app.id);
    labels.add(label);
    candidates.add(
      PlanCandidate(
        id: app.id,
        label: label,
        shortcutLabels: cleanShortcutLabels(app.shortcutLabels),
        hasQueryDoor: app.hasQueryDoor,
      ),
    );
  }
  return List.unmodifiable(candidates);
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
    this.language = 'en',
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
    _checkLanguage(language);
  }

  final SessionName session;
  final String intention;
  final List<PlanCandidate> candidates;
  final String language;

  Map<String, Object?> toJson() => <String, Object?>{
    'session': session.wireValue,
    'intention': intention,
    'language': language,
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
    this.language = 'en',
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
    _checkLanguage(language);
  }

  final String appLabel;
  final String? planIntention;
  final String reason;
  final List<String> shortcutLabels;
  final double threshold;
  final String language;

  Map<String, Object?> toJson() => <String, Object?>{
    'app_label': appLabel,
    if (planIntention != null) 'plan_intention': planIntention,
    'reason': reason,
    'shortcut_labels': shortcutLabels,
    'threshold': threshold,
    'language': language,
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
  String get wireValue => switch (this) {
    PersonalDetailKind.person => 'person',
    PersonalDetailKind.phone => 'phone',
    PersonalDetailKind.email => 'email',
    PersonalDetailKind.address => 'address',
    PersonalDetailKind.creditCard => 'credit_card',
    PersonalDetailKind.bankAccount => 'bank_account',
  };

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

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind.wireValue,
    'start': start,
    'end': end,
  };
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
  ProofRequest({required this.task, required this.note, this.language = 'en'}) {
    _checkLength(task, 'task', minimum: 1, maximum: 500);
    _checkLength(note, 'note', minimum: 1, maximum: 300);
    _checkLanguage(language);
  }

  /// The plan in the user's words.
  final String task;

  /// What the user said changed, finished or became clear.
  final String note;
  final String language;

  Map<String, Object?> toJson() => <String, Object?>{
    'task': task,
    'note': note,
    'language': language,
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

/// One saved "Not now" reason, as the Later shelf sends it to be ranked.
class LaterRequestItem {
  LaterRequestItem({
    required this.id,
    required this.appLabel,
    required this.text,
  }) {
    _checkLength(id, 'id', minimum: 1, maximum: 64);
    _checkLength(appLabel, 'appLabel', minimum: 1, maximum: 60);
    _checkLength(text, 'text', minimum: 1, maximum: 300);
  }

  final String id;
  final String appLabel;
  final String text;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'app_label': appLabel,
    'text': text,
  };
}

class LaterRequest {
  LaterRequest({
    required this.plan,
    required List<LaterRequestItem> items,
    this.language = 'en',
  }) : items = List.unmodifiable(items) {
    _checkLength(plan, 'plan', minimum: 1, maximum: 500);
    if (items.isEmpty || items.length > 20) {
      throw RangeError.range(items.length, 1, 20, 'items.length');
    }
    _checkUnique(items.map((item) => item.id), 'item ids');
    _checkLanguage(language);
  }

  /// The plan sentence the saved items are ranked against.
  final String plan;
  final List<LaterRequestItem> items;
  final String language;

  Map<String, Object?> toJson() => <String, Object?>{
    'plan': plan,
    'language': language,
    'items': items.map((item) => item.toJson()).toList(growable: false),
  };
}

/// How well one saved item fits the plan. [fits] is whether it is worth
/// offering now; [score] orders them.
class LaterRank {
  LaterRank({required this.id, required this.score, required this.fits}) {
    if (!score.isFinite || score < 0 || score > 1) {
      throw RangeError.range(score, 0, 1, 'score');
    }
  }

  factory LaterRank.fromJson(Map<String, Object?> json) => LaterRank(
    id: _string(json['id'], 'id'),
    score: _number(json['score'], 'score').toDouble(),
    fits: switch (json['fits']) {
      final bool value => value,
      _ => throw const FormatException('fits must be a boolean'),
    },
  );

  final String id;
  final double score;
  final bool fits;
}

class LaterResponse {
  LaterResponse({required List<LaterRank> items, required this.usage})
    : items = List.unmodifiable(items);

  factory LaterResponse.fromJson(Map<String, Object?> json) => LaterResponse(
    items: _list(json['items'], 'items')
        .map((value) => LaterRank.fromJson(_map(value, 'items[]')))
        .toList(growable: false),
    usage: ApiUsage.fromJson(_map(json['usage'], 'usage')),
  );

  /// Best first.
  final List<LaterRank> items;
  final ApiUsage usage;
}

void _checkLength(String value, String name, {int minimum = 0, int? maximum}) {
  final length = value.runes.length;
  if (length < minimum || (maximum != null && length > maximum)) {
    throw RangeError.range(length, minimum, maximum, '$name code-point length');
  }
}

void _checkLanguage(String value) {
  if (!RegExp(r'^[a-z]{2}$').hasMatch(value)) {
    throw ArgumentError.value(value, 'language', 'must be a two-letter code');
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
