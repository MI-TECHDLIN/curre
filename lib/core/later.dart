import 'api_models.dart';
import 'span.dart';

/// A "Not now" reason kept for a later plan: the app, the reason in the
/// user's words and the words Extract picked out of it. It lives only on
/// the phone and ages out after [LaterShelfRules.keepFor].
class LaterItem {
  LaterItem({
    required this.id,
    required this.packageName,
    required this.appLabel,
    required this.reason,
    required DateTime savedAt,
    this.target,
    List<Redaction>? redactions,
  }) : redactions = redactions == null ? null : List.unmodifiable(redactions),
       savedAt = savedAt.toUtc();

  factory LaterItem.fromJson(Map<String, Object?> json) => LaterItem(
    id: _string(json['id'], 'id'),
    packageName: _string(json['package'], 'package'),
    appLabel: _string(json['appLabel'], 'appLabel'),
    reason: _string(json['reason'], 'reason'),
    target: json['target'] == null
        ? null
        : SourceSpan.fromJson(
            Map<String, Object?>.from(json['target']! as Map),
          ),
    redactions: switch (json['redactions']) {
      null => null,
      final List<Object?> values =>
        values
            .map(
              (value) =>
                  Redaction.fromJson(Map<String, Object?>.from(value! as Map)),
            )
            .toList(growable: false),
      _ => throw const FormatException('redactions must be a list or null'),
    },
    savedAt: DateTime.parse(_string(json['savedAt'], 'savedAt')),
  );

  final String id;
  final String packageName;
  final String appLabel;
  final String reason;

  /// What the user wanted to find or see, as they wrote it.
  final SourceSpan? target;

  /// Personal-detail positions from the original reason. They stay on the
  /// phone with the reason and are used only if opening it adds to History.
  final List<Redaction>? redactions;
  final DateTime savedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'package': packageName,
    'appLabel': appLabel,
    'reason': reason,
    'target': target?.toJson(),
    'redactions': redactions
        ?.map((redaction) => redaction.toJson())
        .toList(growable: false),
    'savedAt': savedAt.toIso8601String(),
  };
}

/// What the Later shelf shows after a plan: the saved items that fit it,
/// best first, and how many others keep waiting.
class LaterShelf {
  LaterShelf({
    required List<LaterItem> doors,
    required this.waiting,
    required this.ranked,
  }) : doors = List.unmodifiable(doors);

  static final empty = LaterShelf(
    doors: const <LaterItem>[],
    waiting: 0,
    ranked: false,
  );

  final List<LaterItem> doors;

  /// Saved items not offered this time.
  final int waiting;

  /// Whether [doors] were ordered against the plan, rather than newest
  /// first because the plan couldn't be read.
  final bool ranked;

  /// A successful ranking can leave every saved item waiting. In that case
  /// there is no useful door to show at this check-in.
  bool get isEmpty => doors.isEmpty;

  LaterShelf without(String id) {
    final kept = doors.where((item) => item.id != id).toList(growable: false);
    return LaterShelf(doors: kept, waiting: waiting, ranked: ranked);
  }
}

/// The Later shelf's rules. Pure: the store and the screens call these.
abstract final class LaterShelfRules {
  static const keepFor = Duration(days: 7);
  static const maxItems = 20;
  static const maxDoors = 3;

  /// The items still kept at [now], oldest first.
  static List<LaterItem> current(Iterable<LaterItem> items, DateTime now) {
    final cutoff = now.toUtc().subtract(keepFor);
    return items.where((item) => item.savedAt.isAfter(cutoff)).toList()
      ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
  }

  /// Adds [item]. The same reason saved again for the same app replaces the
  /// older copy, and past [maxItems] the oldest go first.
  static List<LaterItem> add(
    Iterable<LaterItem> items,
    LaterItem item,
    DateTime now,
  ) {
    final kept = current(items, now)
      ..removeWhere(
        (old) =>
            old.id == item.id ||
            (old.packageName == item.packageName &&
                _same(old.reason, item.reason)),
      )
      ..add(item);
    final overflow = kept.length - maxItems;
    return overflow > 0 ? kept.sublist(overflow) : kept;
  }

  /// The shelf for a plan. With [ranks] (best first, from the plan's
  /// reading), only the items that fit are offered, in that order. Without
  /// them, the newest come first.
  static LaterShelf arrange(List<LaterItem> items, {List<LaterRank>? ranks}) {
    if (items.isEmpty) return LaterShelf.empty;
    if (ranks == null) {
      final newest = [...items]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
      final doors = newest.take(maxDoors).toList(growable: false);
      return LaterShelf(
        doors: doors,
        waiting: items.length - doors.length,
        ranked: false,
      );
    }
    final byId = {for (final item in items) item.id: item};
    final doors = <LaterItem>[
      for (final rank in ranks)
        if (rank.fits && byId[rank.id] != null) byId[rank.id]!,
    ].take(maxDoors).toList(growable: false);
    return LaterShelf(
      doors: doors,
      waiting: items.length - doors.length,
      ranked: true,
    );
  }

  static bool _same(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();
}

String _string(Object? value, String name) {
  if (value is String) return value;
  throw FormatException('$name must be a string');
}
