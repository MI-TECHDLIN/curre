import 'api_models.dart';
import 'models.dart';
import 'proof.dart';
import 'span.dart';

// What History keeps of a reason or a note: the user's words with each
// personal detail the reader found swapped for a plain placeholder. The
// live screen keeps the words as typed; only the stored copy changes.

/// The placeholder History shows in place of a personal detail.
String personalDetailPlaceholder(PersonalDetailKind kind) => switch (kind) {
  PersonalDetailKind.person => '[name]',
  PersonalDetailKind.phone => '[phone]',
  PersonalDetailKind.email => '[email]',
  PersonalDetailKind.address => '[address]',
  PersonalDetailKind.creditCard => '[card number]',
  PersonalDetailKind.bankAccount => '[account number]',
};

/// Every placeholder [personalDetailPlaceholder] can write, found in stored
/// text so History can mark them. A user who typed one literally sees it
/// marked too, which says nothing untrue.
final RegExp personalDetailPlaceholderPattern = RegExp(
  r'\[(?:name|phone|email|address|card number|account number)\]',
);

/// Spans of [text] that are placeholders, in code points.
List<SourceSpan> personalDetailPlaceholdersIn(String text) => [
  for (final match in personalDetailPlaceholderPattern.allMatches(text))
    SourceSpan(
      text: match[0]!,
      start: text.substring(0, match.start).runes.length,
      end: text.substring(0, match.end).runes.length,
    ),
];

/// [source] with [redactions] applied, and a way to carry spans of the
/// original over to the new text.
class RedactedText {
  RedactedText._(this.source, this.text, this._edits);

  /// [source] with every personal detail in [redactions] swapped for its
  /// placeholder. Redactions that do not fit [source] (out of range, out of
  /// order or overlapping) mean the answer does not belong to these words,
  /// so nothing is changed.
  factory RedactedText.apply(String source, List<Redaction> redactions) {
    final points = source.runes.toList(growable: false);
    var previousEnd = 0;
    for (final redaction in redactions) {
      if (redaction.start < previousEnd ||
          redaction.end <= redaction.start ||
          redaction.end > points.length) {
        return RedactedText._(source, source, const <_Edit>[]);
      }
      previousEnd = redaction.end;
    }
    final out = StringBuffer();
    final edits = <_Edit>[];
    var cursor = 0;
    var shift = 0;
    for (final redaction in redactions) {
      out.write(String.fromCharCodes(points.sublist(cursor, redaction.start)));
      final placeholder = personalDetailPlaceholder(redaction.kind);
      final length = placeholder.runes.length;
      out.write(placeholder);
      edits.add(
        _Edit(
          start: redaction.start,
          end: redaction.end,
          newStart: redaction.start + shift,
          newEnd: redaction.start + shift + length,
        ),
      );
      shift += length - (redaction.end - redaction.start);
      cursor = redaction.end;
    }
    out.write(String.fromCharCodes(points.sublist(cursor)));
    return RedactedText._(source, out.toString(), edits);
  }

  final String source;

  /// The words History keeps.
  final String text;
  final List<_Edit> _edits;

  bool get changed => _edits.isNotEmpty;

  /// [span] of [source], moved onto [text]. A span that starts or ends
  /// inside a personal detail grows to cover its whole placeholder, so a
  /// highlighted name stays highlighted as "[name]".
  SourceSpan? span(SourceSpan? span) {
    if (span == null) return null;
    final points = source.runes.length;
    if (span.start < 0 || span.end < span.start || span.end > points) {
      return null;
    }
    final start = _map(span.start, towardStart: true);
    final end = _map(span.end, towardStart: false);
    return SourceSpan(
      text: sliceByCodePoints(text, start, end),
      start: start,
      end: end,
    );
  }

  int _map(int offset, {required bool towardStart}) {
    var shift = 0;
    for (final edit in _edits) {
      if (offset <= edit.start) break;
      if (offset < edit.end) return towardStart ? edit.newStart : edit.newEnd;
      shift = edit.newEnd - edit.end;
    }
    return offset + shift;
  }
}

/// The copy of [text] History keeps. A missing or unusable Protect answer
/// deliberately leaves the words alone.
String redactedHistoryText(String text, List<Redaction>? redactions) {
  if (redactions == null || redactions.isEmpty) return text;
  return RedactedText.apply(text, redactions).text;
}

/// The unlock attempt History keeps, including highlights moved onto any
/// placeholders Protect introduced.
Attempt redactedAttempt(Attempt attempt, List<Redaction>? redactions) {
  final reason = attempt.reason;
  if (reason == null || redactions == null || redactions.isEmpty) {
    return attempt;
  }
  final redacted = RedactedText.apply(reason, redactions);
  if (!redacted.changed) return attempt;
  return Attempt(
    at: attempt.at,
    packageName: attempt.packageName,
    outcome: attempt.outcome,
    confidence: attempt.confidence,
    overridden: attempt.overridden,
    kind: attempt.kind,
    reason: redacted.text,
    highlights: <SourceSpan>[
      for (final span in attempt.highlights) ?redacted.span(span),
    ],
  );
}

/// The unlock grant History keeps. The active grant remains untouched, so
/// Home and its notification can keep using the words the person typed.
Grant redactedGrant(
  Grant grant,
  List<Redaction>? redactions, {
  SourceSpan? taskSpan,
}) {
  if (redactions == null || redactions.isEmpty) return grant;
  final redacted = RedactedText.apply(grant.reason, redactions);
  if (!redacted.changed) return grant;

  String? task = grant.task;
  if (taskSpan != null) {
    try {
      if (sliceExtractSpan(grant.reason, taskSpan) == task) {
        task = redacted.span(taskSpan)?.text ?? task;
      }
    } on Object {
      // A span that does not belong to this reason cannot safely move the
      // stored task. The reason still uses Protect's validated positions.
    }
  }
  return Grant(
    packageName: grant.packageName,
    reason: redacted.text,
    task: task,
    grantedAt: grant.grantedAt,
    expiresAt: grant.expiresAt,
    source: grant.source,
    kind: grant.kind,
  );
}

/// The copy of [record] History keeps: its note with [redactions] applied
/// and the marked words moved along. Without [redactions] the record is
/// kept as it is.
ProofRecord redactedProofRecord(
  ProofRecord record,
  List<Redaction>? redactions,
) {
  if (redactions == null || redactions.isEmpty) return record;
  final redacted = RedactedText.apply(record.note, redactions);
  if (!redacted.changed) return record;
  return ProofRecord(
    id: record.id,
    taskId: record.taskId,
    planId: record.planId,
    date: record.date,
    taskText: record.taskText,
    note: redacted.text,
    submittedAt: record.submittedAt,
    judgement: record.judgement,
    level: record.level,
    packageName: record.packageName,
    traceId: record.traceId,
    result: redacted.span(record.result),
    learning: redacted.span(record.learning),
    specificCompletion: record.specificCompletion,
  );
}

class _Edit {
  const _Edit({
    required this.start,
    required this.end,
    required this.newStart,
    required this.newEnd,
  });

  final int start;
  final int end;
  final int newStart;
  final int newEnd;
}
