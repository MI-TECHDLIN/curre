import 'package:curre/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const source = 'reply 😀 Ada on 0803 555';
  const redactions = <Redaction>[
    Redaction(kind: PersonalDetailKind.person, start: 8, end: 11),
    Redaction(kind: PersonalDetailKind.phone, start: 15, end: 23),
  ];

  test('redacts by code point and moves spans onto placeholders', () {
    final redacted = RedactedText.apply(source, redactions);

    expect(redacted.text, 'reply 😀 [name] on [phone]');
    expect(
      redacted.span(const SourceSpan(text: 'Ada', start: 8, end: 11))?.toJson(),
      <String, Object?>{'text': '[name]', 'start': 8, 'end': 14},
    );
    expect(
      redacted
          .span(const SourceSpan(text: '0803 555', start: 15, end: 23))
          ?.toJson(),
      <String, Object?>{'text': '[phone]', 'start': 18, 'end': 25},
    );
    expect(
      personalDetailPlaceholdersIn(redacted.text).map((span) => span.text),
      <String>['[name]', '[phone]'],
    );
  });

  test('an invalid Protect answer changes nothing', () {
    const invalid = <Redaction>[
      Redaction(kind: PersonalDetailKind.phone, start: 15, end: 40),
    ];
    final attempt = _attempt(source);

    expect(redactedHistoryText(source, invalid), source);
    expect(identical(redactedAttempt(attempt, invalid), attempt), isTrue);
  });

  test('attempt and grant History copies are redacted without changing live copies', () {
    final attempt = _attempt(source);
    final grant = Grant(
      packageName: 'chat.app',
      reason: source,
      task: 'Ada',
      grantedAt: DateTime.utc(2026, 10, 27, 8),
      expiresAt: DateTime.utc(2026, 10, 27, 8, 5),
      source: GrantSource.clocked,
      kind: ReasonKind.person,
    );

    final storedAttempt = redactedAttempt(attempt, redactions);
    final storedGrant = redactedGrant(
      grant,
      redactions,
      taskSpan: const SourceSpan(text: 'Ada', start: 8, end: 11),
    );

    expect(storedAttempt.reason, 'reply 😀 [name] on [phone]');
    expect(storedAttempt.highlights.single.text, '[name]');
    expect(storedGrant.reason, 'reply 😀 [name] on [phone]');
    expect(storedGrant.task, '[name]');
    expect(attempt.reason, source);
    expect(grant.reason, source);
    expect(grant.task, 'Ada');
  });

  test('proof History copy keeps its evidence aligned', () {
    final record = ProofRecord(
      id: 'proof-task',
      taskId: 'task',
      planId: 'plan',
      date: const LocalDate(2026, 10, 27),
      taskText: 'reply after rehearsal',
      note: source,
      submittedAt: DateTime.utc(2026, 10, 27, 8),
      judgement: ProofJudgement.vague,
      level: ProofLevel.selfReported,
      result: const SourceSpan(text: 'Ada', start: 8, end: 11),
    );

    final stored = redactedProofRecord(record, redactions);

    expect(stored.note, 'reply 😀 [name] on [phone]');
    expect(stored.result?.text, '[name]');
    expect(record.note, source);
  });
}

Attempt _attempt(String reason) => Attempt(
  at: DateTime.utc(2026, 10, 27, 8),
  packageName: 'chat.app',
  outcome: UnlockOutcome.open,
  confidence: .9,
  overridden: false,
  kind: ReasonKind.person,
  reason: reason,
  highlights: const <SourceSpan>[SourceSpan(text: 'Ada', start: 8, end: 11)],
);
