class QueryDoorTemplate {
  const QueryDoorTemplate({
    required this.id,
    required this.label,
    required this.actionLabel,
    required this.packageName,
    required this.buildUri,
  });

  final String id;
  final String label;
  final String actionLabel;
  final String? packageName;
  final String Function(String query) buildUri;
}

abstract final class QueryDoorAllowlist {
  static final Map<String, QueryDoorTemplate> entries =
      Map<String, QueryDoorTemplate>.unmodifiable(<String, QueryDoorTemplate>{
        'youtube': QueryDoorTemplate(
          id: 'youtube',
          label: 'YouTube search',
          actionLabel: 'Search',
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
          actionLabel: 'Search',
          packageName: 'com.google.android.apps.maps',
          buildUri: (query) => Uri(
            scheme: 'geo',
            path: '0,0',
            queryParameters: <String, String>{'q': query},
          ).toString(),
        ),
        'spotify': QueryDoorTemplate(
          id: 'spotify',
          label: 'Spotify search',
          actionLabel: 'Search',
          packageName: 'com.spotify.music',
          buildUri: (query) => 'spotify:search:${Uri.encodeComponent(query)}',
        ),
        'play_store': QueryDoorTemplate(
          id: 'play_store',
          label: 'Play Store search',
          actionLabel: 'Search',
          packageName: 'com.android.vending',
          buildUri: (query) => Uri.https(
            'play.google.com',
            '/store/search',
            <String, String>{'q': query, 'c': 'apps'},
          ).toString(),
        ),
        'gmail_compose': QueryDoorTemplate(
          id: 'gmail_compose',
          label: 'Gmail draft',
          actionLabel: 'Draft',
          packageName: 'com.google.android.gm',
          buildUri: (query) => Uri(
            scheme: 'mailto',
            queryParameters: <String, String>{'subject': query},
          ).toString(),
        ),
        'calendar_event': QueryDoorTemplate(
          id: 'calendar_event',
          label: 'Google Calendar event',
          actionLabel: 'New event',
          packageName: 'com.google.android.calendar',
          buildUri: (query) => Uri(
            scheme: 'content',
            host: 'com.android.calendar',
            path: '/events',
            queryParameters: <String, String>{'title': query},
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
