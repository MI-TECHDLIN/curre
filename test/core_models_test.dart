import 'dart:convert';

import 'package:curre/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('model JSON', () {
    test('round-trips settings and every persisted entity', () {
      final settings = Settings(
        sessionStarts: const <SessionName, LocalTime>{
          SessionName.morning: LocalTime(5, 15),
          SessionName.afternoon: LocalTime(13),
          SessionName.evening: LocalTime(18, 30),
        },
        essentials: const <String>{'phone', 'messages'},
        candidates: const <String>{'youtube', 'maps'},
        unlockMinutes: 7,
        threshold: 0.75,
      );
      final app = const AppEntry(
        packageName: 'com.example.app',
        label: 'Example',
        isEssential: false,
        isCandidate: true,
      );
      final span = const SourceSpan(text: '教程', start: 2, end: 4);
      final plan = Plan(
        id: 'plan-1',
        session: SessionName.morning,
        date: const LocalDate(2026, 10, 24),
        intention: '看教程 till 8',
        apps: <PlannedApp>[
          PlannedApp(packageName: 'com.youtube', door: 'Search', query: span),
        ],
        endsAt: DateTime.parse('2026-10-24T10:00:00+02:00'),
        endPhrase: const SourceSpan(text: 'till 8', start: 5, end: 11),
        source: PlanSource.clocked,
      );
      final grant = Grant(
        packageName: 'com.youtube',
        reason: 'watch 教程',
        task: '教程',
        grantedAt: DateTime.parse('2026-10-24T09:00:00+01:00'),
        expiresAt: DateTime.parse('2026-10-24T09:10:00+01:00'),
        source: GrantSource.clocked,
        kind: ReasonKind.task,
      );
      final attempt = Attempt(
        at: DateTime.parse('2026-10-24T09:00:00-04:00'),
        packageName: 'com.youtube',
        outcome: UnlockOutcome.specify,
        confidence: 0.41,
        overridden: true,
        kind: ReasonKind.timeSensitive,
        reason: 'reply Ada now',
        highlights: const <SourceSpan>[
          SourceSpan(text: 'Ada', start: 6, end: 9),
        ],
      );

      expect(
        _roundTrip(settings.toJson(), Settings.fromJson),
        settings.toJson(),
      );
      expect(_roundTrip(app.toJson(), AppEntry.fromJson), app.toJson());
      expect(_roundTrip(plan.toJson(), Plan.fromJson), plan.toJson());
      expect(_roundTrip(grant.toJson(), Grant.fromJson), grant.toJson());
      expect(_roundTrip(attempt.toJson(), Attempt.fromJson), attempt.toJson());
      expect(plan.endsAt.isUtc, isTrue);
      expect(grant.grantedAt.isUtc, isTrue);
      expect(attempt.at.isUtc, isTrue);
      expect(attempt.kind!.wireValue, 'time_sensitive');
      expect(attempt.reason, 'reply Ada now');
      expect(attempt.highlights.single.text, 'Ada');
    });

    test('rejects unordered session starts and unknown enums', () {
      expect(
        () => Settings(
          sessionStarts: const <SessionName, LocalTime>{
            SessionName.morning: LocalTime(12),
            SessionName.afternoon: LocalTime(4),
            SessionName.evening: LocalTime(17),
          },
        ),
        throwsArgumentError,
      );
      expect(
        () => UnlockOutcomeWire.fromWireValue('deny'),
        throwsFormatException,
      );
    });
  });

  group('Unicode spans', () {
    test('slices emoji and non-Latin text by code point', () {
      const source = 'go 😀 看教程 now';
      const emoji = SourceSpan(text: '😀', start: 3, end: 4);
      const chinese = SourceSpan(text: '看教程', start: 5, end: 8);

      expect(sliceExtractSpan(source, emoji), '😀');
      expect(sliceExtractSpan(source, chinese), '看教程');
      expect(source.substring(chinese.start, chinese.end), isNot('看教程'));
    });

    test('rejects out-of-range or mismatched spans', () {
      expect(() => sliceByCodePoints('abc', 1, 4), throwsRangeError);
      expect(
        () => sliceExtractSpan(
          'abc',
          const SourceSpan(text: 'z', start: 1, end: 2),
        ),
        throwsFormatException,
      );
    });

    test('guard quote is literal and is not sliced from the reason', () {
      final response = UnlockResponse.fromJson(<String, Object?>{
        'outcome': 'flagged',
        'guard': <String, Object?>{
          'category': 'instruction override',
          'quote': <String, Object?>{
            'text': 'ignore rules',
            'start': 57,
            'end': 69,
          },
        },
      });

      expect(response.guardQuoteText, 'ignore rules');
      expect(response.guard!.quote.start, 57);
    });
  });
}

Map<String, Object?> _roundTrip<T>(
  Map<String, Object?> value,
  T Function(Map<String, Object?>) decode,
) {
  final json = jsonDecode(jsonEncode(value)) as Map<String, Object?>;
  final decoded = decode(json);
  return (decoded as dynamic).toJson() as Map<String, Object?>;
}
