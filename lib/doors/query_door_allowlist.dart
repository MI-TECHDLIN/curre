class QueryDoorTemplate {
  const QueryDoorTemplate({
    required this.id,
    required this.label,
    required this.packageName,
    required this.buildUri,
  });

  final String id;
  final String label;
  final String? packageName;
  final String Function(String query) buildUri;
}

abstract final class QueryDoorAllowlist {
  static final Map<String, QueryDoorTemplate> entries =
      Map<String, QueryDoorTemplate>.unmodifiable(<String, QueryDoorTemplate>{
        'youtube': QueryDoorTemplate(
          id: 'youtube',
          label: 'YouTube search',
          packageName: 'com.google.android.youtube',
          buildUri: (query) => Uri.https(
            'www.youtube.com',
            '/results',
            <String, String>{'search_query': query},
          ).toString(),
        ),
        'maps': QueryDoorTemplate(
          id: 'maps',
          label: 'Google Maps search',
          packageName: 'com.google.android.apps.maps',
          buildUri: (query) => Uri(
            scheme: 'geo',
            path: '0,0',
            queryParameters: <String, String>{'q': query},
          ).toString(),
        ),
        'web': QueryDoorTemplate(
          id: 'web',
          label: 'Web search',
          packageName: null,
          buildUri: (query) => Uri.https(
            'www.google.com',
            '/search',
            <String, String>{'q': query},
          ).toString(),
        ),
      });

  static QueryDoorTemplate? byId(String id) => entries[id];

  static QueryDoorTemplate? forPackage(String packageName) {
    for (final entry in entries.values) {
      if (entry.packageName == packageName) return entry;
    }
    return null;
  }

  static bool permits(String id, {String? packageName}) {
    final entry = byId(id);
    if (entry == null) return false;
    if (packageName == null) return true;
    return entry.packageName == packageName;
  }

  static String? encodedTarget(String id, String query) =>
      byId(id)?.buildUri(query);
}
