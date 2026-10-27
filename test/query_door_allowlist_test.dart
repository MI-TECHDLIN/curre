import 'package:curre/doors/query_door_allowlist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('query templates encode user words as data', () {
    const query = 'G chord & #practice';

    for (final id in <String>[
      'youtube',
      'maps',
      'play_store',
      'gmail_compose',
      'calendar_event',
    ]) {
      final target = QueryDoorAllowlist.encodedTarget(id, query)!;
      expect(target, isNot(contains(query)));
      expect(Uri.parse(target).queryParameters.values, contains(query));
    }

    final spotify = QueryDoorAllowlist.encodedTarget('spotify', query)!;
    expect(spotify, startsWith('spotify:search:'));
    expect(spotify, isNot(contains(query)));
    expect(
      Uri.decodeComponent(spotify.substring('spotify:search:'.length)),
      query,
    );
  });

  test('only fixed query door identifiers are allowed', () {
    expect(QueryDoorAllowlist.permits('youtube'), isTrue);
    expect(QueryDoorAllowlist.permits('maps'), isTrue);
    expect(QueryDoorAllowlist.permits('spotify'), isTrue);
    expect(QueryDoorAllowlist.permits('play_store'), isTrue);
    expect(QueryDoorAllowlist.permits('gmail_compose'), isTrue);
    expect(QueryDoorAllowlist.permits('calendar_event'), isTrue);
    expect(QueryDoorAllowlist.permits('web'), isFalse);
    expect(
      QueryDoorAllowlist.encodedTarget('https://attacker.test', 'x'),
      isNull,
    );
  });

  test('package-bound doors cannot be used for another app', () {
    expect(
      QueryDoorAllowlist.permits(
        'youtube',
        packageName: 'com.google.android.youtube',
      ),
      isTrue,
    );
    expect(
      QueryDoorAllowlist.permits(
        'youtube',
        packageName: 'com.instagram.android',
      ),
      isFalse,
    );
    expect(
      QueryDoorAllowlist.permits('spotify', packageName: 'com.spotify.music'),
      isTrue,
    );
    expect(
      QueryDoorAllowlist.permits(
        'spotify',
        packageName: 'com.google.android.youtube',
      ),
      isFalse,
    );
    expect(
      QueryDoorAllowlist.permits(
        'gmail_compose',
        packageName: 'com.google.android.gm',
      ),
      isTrue,
    );
    expect(
      QueryDoorAllowlist.permits(
        'calendar_event',
        packageName: 'com.google.android.gm',
      ),
      isFalse,
    );
  });

  test('every production query door is reachable from its package', () {
    for (final entry in QueryDoorAllowlist.entries.values) {
      expect(entry.packageName, isNotNull, reason: entry.id);
      expect(
        QueryDoorAllowlist.forPackage(entry.packageName!),
        same(entry),
        reason: entry.id,
      );
    }
  });

  test('non-search doors describe the action they really open', () {
    expect(QueryDoorAllowlist.byId('gmail_compose')!.actionLabel, 'Draft');
    expect(QueryDoorAllowlist.byId('calendar_event')!.actionLabel, 'New event');
  });
}
