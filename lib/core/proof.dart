import 'api_models.dart';
import 'models.dart';
import 'sessions.dart';
import 'span.dart';

// Prooflight's evidence and streak rules (proof audit §3). Everything here
// is pure: the rules read records and dates and never the clock, so a
// summary can be rebuilt at any time, including after a pending note is
// judged on a later day.

/// How Curre saw a planned task start: its door on Home, or the Start on
/// the task done away from the phone.
enum TaskTraceKind { door, offlineStart }

/// Where a completion note stands with the reader. [none] is a plain
/// check-off that was never sent; [pending] is a note still waiting for an
/// answer, kept on the phone and retried.
enum ProofJudgement { none, pending, vague, accepted }

/// The honest name for a completion's evidence (proof audit §1). Only
/// [supported] counts for Prooflight; Curre never calls it verified.
enum ProofLevel { selfReported, supported }

/// Decide's `specific_completion` probability a note needs to count.
const double proofSpecificCompletionThreshold = 0.75;

extension TaskTraceKindWire on TaskTraceKind {
  String get wireValue => switch (this) {
    TaskTraceKind.door => 'door',
    TaskTraceKind.offlineStart => 'offline_start',
  };

  static TaskTraceKind fromWireValue(String value) => switch (value) {
    'door' => TaskTraceKind.door,
    'offline_start' => TaskTraceKind.offlineStart,
    _ => throw FormatException('Unknown task trace kind: $value'),
  };
}

extension ProofJudgementWire on ProofJudgement {
  String get wireValue => name;

  static ProofJudgement fromWireValue(String value) => switch (value) {
    'none' => ProofJudgement.none,
    'pending' => ProofJudgement.pending,
    'vague' => ProofJudgement.vague,
    'accepted' => ProofJudgement.accepted,
    _ => throw FormatException('Unknown proof judgement: $value'),
  };
}

extension ProofLevelWire on ProofLevel {
  String get wireValue => switch (this) {
    ProofLevel.selfReported => 'self_reported',
    ProofLevel.supported => 'supported',
  };

  static ProofLevel fromWireValue(String value) => switch (value) {
    'self_reported' => ProofLevel.selfReported,
    'supported' => ProofLevel.supported,
    _ => throw FormatException('Unknown proof level: $value'),
  };
}

/// A task that existed in a saved plan before Curre saw it start (audit §3,
/// rule 2). Tasks come only from a [Plan], never from loose text, so there
/// is no way to complete something nobody committed to first: each of the
/// plan's doors is one task, and the plan itself is one more, for what is
/// done away from the phone.
class PlannedTask {
  const PlannedTask._({
    required this.id,
    required this.planId,
    required this.date,
    required this.text,
    this.packageName,
  });

  factory PlannedTask.forDoor(Plan plan, PlannedApp app) {
    if (!plan.apps.any((door) => door.packageName == app.packageName)) {
      throw ArgumentError('The app must belong to the plan');
    }
    return PlannedTask._(
      id: '${plan.id}:door:${app.packageName}',
      planId: plan.id,
      date: plan.date,
      text: plan.intention,
      packageName: app.packageName,
    );
  }

  factory PlannedTask.offline(Plan plan) => PlannedTask._(
    id: '${plan.id}:offline',
    planId: plan.id,
    date: plan.date,
    text: plan.intention,
  );

  final String id;
  final String planId;

  /// The plan's Curre day. A completion is always credited here, even when
  /// its note is judged days later.
  final LocalDate date;

  /// The plan in the user's own words, which the note is judged against.
  final String text;

  /// The app the task's door opens, or null for the task away from the
  /// phone.
  final String? packageName;

  bool get isOffline => packageName == null;
}

/// Curre's local evidence that a planned task was started: the door opened,
/// or Start was tapped. Only Curre's own launches count; nothing is read
/// from other apps.
class TaskTrace {
  TaskTrace({
    required this.id,
    required this.taskId,
    required this.planId,
    required this.date,
    required this.kind,
    required DateTime at,
    this.packageName,
  }) : at = at.toUtc();

  factory TaskTrace.forTask(
    PlannedTask task, {
    required TaskTraceKind kind,
    required DateTime at,
  }) => TaskTrace(
    id: 'trace-${at.toUtc().microsecondsSinceEpoch}-${task.id}',
    taskId: task.id,
    planId: task.planId,
    date: task.date,
    kind: kind,
    at: at,
    packageName: task.packageName,
  );

  factory TaskTrace.fromJson(Map<String, Object?> json) => TaskTrace(
    id: _string(json['id'], 'id'),
    taskId: _string(json['taskId'], 'taskId'),
    planId: _string(json['planId'], 'planId'),
    date: LocalDate.fromJson(json['date']),
    kind: TaskTraceKindWire.fromWireValue(_string(json['kind'], 'kind')),
    at: _instant(json['at'], 'at'),
    packageName: _nullableString(json['package'], 'package'),
  );

  final String id;
  final String taskId;
  final String planId;
  final LocalDate date;
  final TaskTraceKind kind;
  final DateTime at;
  final String? packageName;

  bool supports(PlannedTask task) =>
      taskId == task.id && planId == task.planId && date == task.date;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'taskId': taskId,
    'planId': planId,
    'date': date.toJson(),
    'kind': kind.wireValue,
    'at': at.toIso8601String(),
    if (packageName != null) 'package': packageName,
  };
}

/// The one completion record a planned task keeps. A vague first note, its
/// follow-up and a later answer to a pending note all replace the same
/// record, so a task adds at most one ray. The note stays on the phone so a
/// pending one can be sent again; the backend keeps nothing.
class ProofRecord {
  ProofRecord({
    required this.id,
    required this.taskId,
    required this.planId,
    required this.date,
    required this.taskText,
    required this.note,
    required DateTime submittedAt,
    required this.judgement,
    required this.level,
    this.packageName,
    this.traceId,
    this.result,
    this.learning,
    this.specificCompletion,
  }) : submittedAt = submittedAt.toUtc() {
    final probability = specificCompletion;
    if (probability != null &&
        (!probability.isFinite || probability < 0 || probability > 1)) {
      throw RangeError.range(probability, 0, 1, 'specificCompletion');
    }
    if (level == ProofLevel.supported &&
        (judgement != ProofJudgement.accepted ||
            traceId == null ||
            probability == null ||
            probability < proofSpecificCompletionThreshold)) {
      throw ArgumentError(
        'Supported proof needs an accepted note, a start trace and a '
        'specific-completion probability of at least '
        '$proofSpecificCompletionThreshold',
      );
    }
  }

  factory ProofRecord.fromJson(Map<String, Object?> json) => ProofRecord(
    id: _string(json['id'], 'id'),
    taskId: _string(json['taskId'], 'taskId'),
    planId: _string(json['planId'], 'planId'),
    date: LocalDate.fromJson(json['date']),
    taskText: _string(json['taskText'], 'taskText'),
    note: _string(json['note'], 'note'),
    submittedAt: _instant(json['submittedAt'], 'submittedAt'),
    judgement: ProofJudgementWire.fromWireValue(
      _string(json['judgement'], 'judgement'),
    ),
    level: ProofLevelWire.fromWireValue(_string(json['level'], 'level')),
    packageName: _nullableString(json['package'], 'package'),
    traceId: _nullableString(json['traceId'], 'traceId'),
    result: json['result'] == null
        ? null
        : SourceSpan.fromJson(_map(json['result'], 'result')),
    learning: json['learning'] == null
        ? null
        : SourceSpan.fromJson(_map(json['learning'], 'learning')),
    specificCompletion: json['specificCompletion'] == null
        ? null
        : _number(json['specificCompletion'], 'specificCompletion').toDouble(),
  );

  final String id;
  final String taskId;
  final String planId;

  /// The plan's Curre day, which the record keeps however late its note is
  /// judged.
  final LocalDate date;
  final String taskText;
  final String note;
  final DateTime submittedAt;
  final ProofJudgement judgement;
  final ProofLevel level;

  /// The door's app, or null for the task away from the phone.
  final String? packageName;
  final String? traceId;
  final SourceSpan? result;
  final SourceSpan? learning;
  final double? specificCompletion;

  /// The words Extract copied from the note for the proof card.
  SourceSpan? get caption => result ?? learning;

  bool get isPending => judgement == ProofJudgement.pending;

  /// Whether this record raises its day's sun. The constructor already
  /// refuses a supported record without its evidence.
  bool get countsForProoflight => level == ProofLevel.supported;

  /// The same record without the user's words: the streak keeps its days
  /// after the 30-day history drops the text.
  ProofRecord withoutText() => ProofRecord(
    id: id,
    taskId: taskId,
    planId: planId,
    date: date,
    taskText: '',
    note: '',
    submittedAt: submittedAt,
    judgement: judgement,
    level: level,
    packageName: packageName,
    traceId: traceId,
    specificCompletion: specificCompletion,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'taskId': taskId,
    'planId': planId,
    'date': date.toJson(),
    'taskText': taskText,
    'note': note,
    'submittedAt': submittedAt.toIso8601String(),
    'judgement': judgement.wireValue,
    'level': level.wireValue,
    if (packageName != null) 'package': packageName,
    if (traceId != null) 'traceId': traceId,
    if (result != null) 'result': result!.toJson(),
    if (learning != null) 'learning': learning!.toJson(),
    if (specificCompletion != null) 'specificCompletion': specificCompletion,
  };
}

/// What one completion changed, for the moment that follows it: the record
/// and the Prooflight summary before and after it was saved.
class ProofSubmission {
  const ProofSubmission({
    required this.record,
    required this.before,
    required this.after,
    this.kind,
    this.mismatch,
  });

  final ProofRecord record;
  final ProofSummary before;
  final ProofSummary after;

  /// How the reader classed the note, when it answered.
  final ProofKind? kind;

  /// The note's own claim that did not match the planned task, when Verify
  /// found a clear contradiction.
  final String? mismatch;

  bool get supported => record.countsForProoflight;

  /// Whether the record belongs to today. A task started just before the
  /// morning boundary keeps its plan's day, which is then yesterday.
  bool get isToday => record.date == after.today;

  /// The first supported task of its day: the sun rises and the run grows.
  bool get earnedProofDay =>
      supported &&
      !before.proofDates.contains(record.date) &&
      after.proofDates.contains(record.date);

  /// A later supported task on a day that already has its sun.
  bool get addedRay =>
      supported && !earnedProofDay && after.raysToday > before.raysToday;

  bool get earnedCloudDay => !before.cloudInHand && after.cloudInHand;

  /// The first proof day after a run ended.
  bool get startedNewRun => earnedProofDay && before.betweenRuns;
}

/// Prooflight's state, rebuilt from proof records for one Curre day. Nothing
/// in it is stored, so a pending note judged later lands on its original
/// day and every count follows.
class ProofSummary {
  ProofSummary({
    required this.today,
    required this.currentRun,
    required this.bestRun,
    required this.totalProofDays,
    required this.raysToday,
    required this.cloudInHand,
    required this.cloudDays,
    required Set<LocalDate> proofDates,
    required Set<LocalDate> pendingDates,
    required Set<LocalDate> cloudDates,
    this.towardCloud = 0,
    this.runStart,
    this.lastEndedRun,
    this.lastEndedOn,
  }) : proofDates = Set.unmodifiable(proofDates),
       pendingDates = Set.unmodifiable(pendingDates),
       cloudDates = Set.unmodifiable(cloudDates);

  /// Prooflight before any proof.
  factory ProofSummary.none(LocalDate today) => ProofSummary(
    today: today,
    currentRun: 0,
    bestRun: 0,
    totalProofDays: 0,
    raysToday: 0,
    cloudInHand: false,
    cloudDays: 0,
    proofDates: const <LocalDate>{},
    pendingDates: const <LocalDate>{},
    cloudDates: const <LocalDate>{},
  );

  /// The Curre day this summary was rebuilt for.
  final LocalDate today;

  /// Proof days in the run still going: "7 proof days". A cloud day adds
  /// nothing to it.
  final int currentRun;
  final int bestRun;

  /// Every proof day, across every run.
  final int totalProofDays;

  /// Tasks with supported proof today: one ray each.
  final int raysToday;

  /// An earned cloud day waiting to cover the next empty day.
  final bool cloudInHand;

  /// Empty days a cloud day has covered.
  final int cloudDays;
  final Set<LocalDate> proofDates;

  /// Days held open by a note still waiting for an answer.
  final Set<LocalDate> pendingDates;
  final Set<LocalDate> cloudDates;

  /// Proof days counted toward the next cloud day (0–6).
  final int towardCloud;

  /// The first proof day of the current run.
  final LocalDate? runStart;

  /// How many proof days the most recent run that ended had, and the empty
  /// day that ended it.
  final int? lastEndedRun;
  final LocalDate? lastEndedOn;

  /// A run has ended and the next one has not started yet.
  bool get betweenRuns => currentRun == 0 && lastEndedRun != null;
}

abstract final class ProoflightRules {
  static const double supportedThreshold = proofSpecificCompletionThreshold;

  /// Proof days that earn one cloud day (rule 7).
  static const int provedDaysPerCloud = 7;

  /// Uncovered empty days in a row that end a run (rule 8): one is
  /// forgiven, the second ends it.
  static const int uncoveredDaysThatEndARun = 2;

  /// The Curre day [instant] falls in. Days start at the configured morning
  /// session, not at midnight: sessions are ordered within one calendar
  /// day, so the current session's start date is the date of the morning
  /// it belongs to. The wall clock is read through [timeZone] on every
  /// call, so a time-zone or DST change moves today, never a stored day.
  static LocalDate curreDay(
    DateTime instant,
    Settings settings, {
    CurreTimeZone timeZone = const SystemCurreTimeZone(),
  }) => SessionSchedule.fromSettings(
    settings,
    timeZone: timeZone,
  ).current(instant).localStartDate;

  /// Rebuilds Prooflight from [records], as of [today]:
  ///
  /// - A day with at least one supported task is a proof day. It adds one
  ///   to the run however many tasks it has; each task is one ray.
  /// - Seven proof days earn a cloud day, held one at a time. Days only
  ///   count toward it while none is held.
  /// - An empty past day takes the cloud day if one is held: it keeps the
  ///   run going and adds nothing to it. Otherwise it is an uncovered day.
  ///   One is forgiven; a second in a row ends the run. Nothing is erased:
  ///   the best run and every proof day stay.
  /// - A day with a note still waiting for its answer is not empty, so an
  ///   outage never ends a run. Once judged, the day falls on either side.
  /// - Today is never empty: it is not over. Nor is a day after it, which a
  ///   proof can carry after the phone moves west across time zones; that
  ///   proof still counts.
  static ProofSummary summarize({
    required Iterable<ProofRecord> records,
    required LocalDate today,
  }) {
    final raysByDate = <LocalDate, Set<String>>{};
    final pendingDates = <LocalDate>{};
    for (final record in records) {
      if (record.countsForProoflight) {
        raysByDate
            .putIfAbsent(record.date, () => <String>{})
            .add(record.taskId);
      } else if (record.isPending && record.traceId != null) {
        pendingDates.add(record.date);
      }
    }
    final proofDates = raysByDate.keys.toSet();
    pendingDates.removeAll(proofDates);
    if (proofDates.isEmpty && pendingDates.isEmpty) {
      return ProofSummary.none(today);
    }

    var run = 0;
    var best = 0;
    var towardCloud = 0;
    var uncovered = 0;
    var cloudInHand = false;
    var cloudDays = 0;
    final cloudDates = <LocalDate>{};
    LocalDate? runStart;
    int? lastEndedRun;
    LocalDate? lastEndedOn;

    final recorded = <LocalDate>[...proofDates, ...pendingDates]..sort();
    final last = recorded.last.compareTo(today) > 0 ? recorded.last : today;
    for (
      var day = recorded.first;
      day.compareTo(last) <= 0;
      day = day.addDays(1)
    ) {
      if (proofDates.contains(day)) {
        if (run == 0) runStart = day;
        run++;
        if (run > best) best = run;
        uncovered = 0;
        if (!cloudInHand && ++towardCloud == provedDaysPerCloud) {
          cloudInHand = true;
          towardCloud = 0;
        }
      } else if (pendingDates.contains(day)) {
        uncovered = 0;
      } else if (run == 0 || day.compareTo(today) >= 0) {
        continue;
      } else if (cloudInHand) {
        cloudInHand = false;
        cloudDays++;
        cloudDates.add(day);
      } else if (++uncovered == uncoveredDaysThatEndARun) {
        lastEndedRun = run;
        lastEndedOn = day;
        run = 0;
        towardCloud = 0;
        uncovered = 0;
        runStart = null;
      }
    }

    return ProofSummary(
      today: today,
      currentRun: run,
      bestRun: best,
      totalProofDays: proofDates.length,
      raysToday: raysByDate[today]?.length ?? 0,
      cloudInHand: cloudInHand,
      cloudDays: cloudDays,
      proofDates: proofDates,
      pendingDates: pendingDates,
      cloudDates: cloudDates,
      towardCloud: towardCloud,
      runStart: runStart,
      lastEndedRun: lastEndedRun,
      lastEndedOn: lastEndedOn,
    );
  }

  /// The record for [task] after the reader's [response] to [note]. It is
  /// supported only with a start [trace] for this task from no later than
  /// the note, a specific completion at or above the threshold, and at
  /// least one span Extract copied; anything less is self-reported.
  static ProofRecord recordFromResponse({
    required PlannedTask task,
    required String note,
    required DateTime submittedAt,
    required ProofResponse response,
    TaskTrace? trace,
  }) {
    final submitted = submittedAt.toUtc();
    final matchingTrace =
        trace != null && trace.supports(task) && !trace.at.isAfter(submitted)
        ? trace
        : null;
    return ProofRecord(
      id: recordId(task),
      taskId: task.id,
      planId: task.planId,
      date: task.date,
      taskText: task.text,
      note: note,
      submittedAt: submitted,
      judgement: _judgement(response.outcome),
      level: _isSupported(response, hasTrace: matchingTrace != null)
          ? ProofLevel.supported
          : ProofLevel.selfReported,
      packageName: task.packageName,
      traceId: matchingTrace?.id,
      result: response.result,
      learning: response.learning,
      specificCompletion: response.specificCompletion,
    );
  }

  /// Applies a later answer to a pending note. The note, its time, its
  /// trace and its Curre day stay exactly as they were captured.
  static ProofRecord recordFromPending({
    required ProofRecord pending,
    required ProofResponse response,
  }) {
    if (!pending.isPending) {
      throw ArgumentError.value(
        pending.judgement,
        'pending',
        'Only a pending proof can be judged again',
      );
    }
    return ProofRecord(
      id: pending.id,
      taskId: pending.taskId,
      planId: pending.planId,
      date: pending.date,
      taskText: pending.taskText,
      note: pending.note,
      submittedAt: pending.submittedAt,
      judgement: _judgement(response.outcome),
      level: _isSupported(response, hasTrace: pending.traceId != null)
          ? ProofLevel.supported
          : ProofLevel.selfReported,
      packageName: pending.packageName,
      traceId: pending.traceId,
      result: response.result,
      learning: response.learning,
      specificCompletion: response.specificCompletion,
    );
  }

  /// A check-off (rule 5): useful and kept, but self-reported, so it never
  /// adds a proof day. A [note] typed first stays on the phone with it and
  /// is never sent.
  static ProofRecord checkOff({
    required PlannedTask task,
    required DateTime at,
    TaskTrace? trace,
    String note = '',
  }) => ProofRecord(
    id: recordId(task),
    taskId: task.id,
    planId: task.planId,
    date: task.date,
    taskText: task.text,
    note: note,
    submittedAt: at,
    judgement: ProofJudgement.none,
    level: ProofLevel.selfReported,
    packageName: task.packageName,
    traceId: trace != null && trace.supports(task) ? trace.id : null,
  );

  static String recordId(PlannedTask task) => 'proof-${task.id}';

  /// What Clear history leaves: every proof day, without a word the user
  /// wrote. Waiting notes and check-offs are only words, so they go.
  static List<ProofRecord> forgetWords(Iterable<ProofRecord> records) =>
      <ProofRecord>[
        for (final record in records)
          if (record.countsForProoflight) record.withoutText(),
      ];

  /// A later completion of the same task may improve its record, but never
  /// turns supported proof back into anything weaker.
  static ProofRecord preferRecord(ProofRecord? existing, ProofRecord incoming) {
    if (existing == null) return incoming;
    if (existing.id != incoming.id) {
      throw ArgumentError('Proof records must have the same id');
    }
    return existing.countsForProoflight && !incoming.countsForProoflight
        ? existing
        : incoming;
  }

  static ProofJudgement _judgement(ProofOutcome outcome) => switch (outcome) {
    ProofOutcome.pending => ProofJudgement.pending,
    ProofOutcome.vague => ProofJudgement.vague,
    ProofOutcome.accepted => ProofJudgement.accepted,
  };

  static bool _isSupported(ProofResponse response, {required bool hasTrace}) {
    final probability = response.specificCompletion;
    return response.outcome == ProofOutcome.accepted &&
        hasTrace &&
        (response.result != null || response.learning != null) &&
        probability != null &&
        probability >= supportedThreshold;
  }
}

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

num _number(Object? value, String name) {
  if (value is num) return value;
  throw FormatException('$name must be a number');
}

Map<String, Object?> _map(Object? value, String name) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.cast<String, Object?>();
  throw FormatException('$name must be an object');
}
