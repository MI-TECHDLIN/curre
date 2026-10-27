import 'package:curre/core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 10, 27, 12);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('saved item round-trips its target and private-detail positions', () {
    final item = _item(
      'one',
      now,
      target: const SourceSpan(text: 'Ada’s post', start: 4, end: 14),
      redactions: const <Redaction>[
        Redaction(kind: PersonalDetailKind.person, start: 4, end: 7),
      ],
    );

    final restored = LaterItem.fromJson(item.toJson());

    expect(restored.toJson(), item.toJson());
    expect(restored.savedAt.isUtc, isTrue);
    expect(restored.target?.text, 'Ada’s post');
    expect(restored.redactions?.single.kind, PersonalDetailKind.person);
  });

  test('items age out at seven days and the shelf keeps at most twenty', () {
    final current = LaterShelfRules.current(<LaterItem>[
      _item('fresh', now.subtract(const Duration(days: 6, hours: 23))),
      _item('edge', now.subtract(const Duration(days: 7))),
      _item('stale', now.subtract(const Duration(days: 8))),
    ], now);

    expect(current.map((item) => item.id), <String>['fresh']);

    var kept = <LaterItem>[];
    for (var index = 0; index < 21; index++) {
      kept = LaterShelfRules.add(
        kept,
        _item('item-$index', now.add(Duration(minutes: index))),
        now.add(Duration(minutes: index)),
      );
    }
    expect(kept, hasLength(20));
    expect(kept.first.id, 'item-1');
    expect(kept.last.id, 'item-20');
  });

  test(
    'ranking picks fitting items in result order and fallback is newest first',
    () {
      final items = <LaterItem>[
        _item('one', now.subtract(const Duration(hours: 4))),
        _item('two', now.subtract(const Duration(hours: 3))),
        _item('three', now.subtract(const Duration(hours: 2))),
        _item('four', now.subtract(const Duration(hours: 1))),
      ];

      final ranked = LaterShelfRules.arrange(
        items,
        ranks: <LaterRank>[
          LaterRank(id: 'three', score: .99, fits: true),
          LaterRank(id: 'one', score: .8, fits: false),
          LaterRank(id: 'four', score: .7, fits: true),
          LaterRank(id: 'two', score: .6, fits: true),
        ],
      );
      final fallback = LaterShelfRules.arrange(items);

      expect(ranked.doors.map((item) => item.id), <String>[
        'three',
        'four',
        'two',
      ]);
      expect(ranked.waiting, 1);
      expect(ranked.ranked, isTrue);
      expect(fallback.doors.map((item) => item.id), <String>[
        'four',
        'three',
        'two',
      ]);
      expect(fallback.waiting, 1);
      expect(fallback.ranked, isFalse);

      final noMatch = LaterShelfRules.arrange(
        items,
        ranks: <LaterRank>[
          LaterRank(id: 'one', score: .1, fits: false),
        ],
      );
      expect(noMatch.isEmpty, isTrue);
      expect(noMatch.waiting, 4);
    },
  );

  test(
    'local storage prunes old items and Clear history removes the shelf',
    () async {
      final store = await CurreLocalStore.open(now: now);
      await store.saveLaterItem(
        _item('old', now.subtract(const Duration(days: 8))),
        now: now.subtract(const Duration(days: 8)),
      );
      expect(store.loadLaterItems(now: now), isEmpty);

      final fresh = _item('fresh', now.subtract(const Duration(hours: 1)));
      await store.saveLaterItem(fresh, now: now);
      await store.dismissLaterShelf(const LocalDate(2026, 10, 27));

      final reopened = await CurreLocalStore.open(now: now);
      expect(reopened.loadLaterItems(now: now).single.toJson(), fresh.toJson());
      expect(reopened.laterShelfDismissedOn, const LocalDate(2026, 10, 27));

      await reopened.clearHistory();
      expect(reopened.loadLaterItems(now: now), isEmpty);
      expect(reopened.laterShelfDismissedOn, isNull);
    },
  );
}

LaterItem _item(
  String id,
  DateTime savedAt, {
  SourceSpan? target,
  List<Redaction>? redactions,
}) => LaterItem(
  id: id,
  packageName: 'app.$id',
  appLabel: 'App $id',
  reason: 'see $id later',
  target: target,
  redactions: redactions,
  savedAt: savedAt,
);
