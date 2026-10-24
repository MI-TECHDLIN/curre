import 'package:curre/doors/query_door_allowlist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('query templates encode user words as data', () {
    const query = 'G chord & #practice';

    for (final id in <String>['youtube', 'maps', 'web']) {
      final target = QueryDoorAllowlist.encodedTarget(id, query)!;
      expect(target, isNot(contains(query)));
      expect(Uri.parse(target).queryParameters.values, contains(query));
    }
  });

  test('only fixed query door identifiers are allowed', () {
    expect(QueryDoorAllowlist.permits('youtube'), isTrue);
    expect(QueryDoorAllowlist.permits('maps'), isTrue);
    expect(QueryDoorAllowlist.permits('web'), isTrue);
    expect(QueryDoorAllowlist.permits('spotify'), isFalse);
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
      QueryDoorAllowlist.permits('web', packageName: 'com.instagram.android'),
      isFalse,
    );
  });
}
