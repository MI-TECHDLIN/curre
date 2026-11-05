/// What Curre knows about well-known apps, to make setup quicker: which
/// ones tend to pull people in, and an everyday example of what a plan
/// might open each one for. Matching is by package name, so it never sends
/// anything anywhere.
library;

import 'dart:math' as math;

import '../../l10n/l10n.dart';

/// Apps that commonly turn a quick look into an hour, most common first.
/// Onboarding lists the ones installed before every other app.
const commonPullPackages = <String>[
  'com.instagram.android',
  'com.google.android.youtube',
  'com.zhiliaoapp.musically',
  'com.ss.android.ugc.trill',
  'com.facebook.katana',
  'com.twitter.android',
  'com.snapchat.android',
  'com.reddit.frontpage',
  'com.netflix.mediaclient',
  'com.instagram.barcelona',
  'com.pinterest',
  'com.android.chrome',
  'org.telegram.messenger',
  'com.linkedin.android',
  'com.whatsapp',
];

/// A plain example of what a plan could open an app for, shown under its
/// name while choosing apps. Only a hint: it is never saved.
const appTaskExamples = <String, String>{
  'com.google.android.youtube': 'Learn something, like a guitar chord',
  'com.google.android.apps.maps': 'Find the way somewhere',
  'com.whatsapp': 'Reply to someone',
  'org.telegram.messenger': 'Reply to someone',
  'com.google.android.apps.messaging': 'Text someone back',
  'com.spotify.music': 'Play one playlist',
  'com.android.chrome': 'Look one thing up',
  'com.google.android.gm': 'Answer an email',
  'com.google.android.calendar': 'Check what’s on today',
  'com.google.android.keep': 'Write something down',
  'com.google.android.photos': 'Find a photo',
  'com.google.android.apps.photos': 'Find a photo',
  'com.google.android.drive': 'Open a file',
  'com.google.android.apps.docs': 'Open a file',
  'com.instagram.android': 'Reply to a message',
  'com.netflix.mediaclient': 'Watch one episode',
  'com.facebook.katana': 'Check one group',
  'com.linkedin.android': 'Answer a message',
  'com.zhiliaoapp.musically': 'Post one video',
  'com.ss.android.ugc.trill': 'Post one video',
  'com.twitter.android': 'Post one thing',
  'com.reddit.frontpage': 'Read one thread',
  'com.pinterest': 'Find one idea',
  'com.snapchat.android': 'Reply to a friend',
};

/// Apps a plan often needs, picked for the user to start with when they
/// have not chosen any yet (they can untick any of them).
const commonTaskPackages = <String>[
  'com.google.android.youtube',
  'com.google.android.apps.maps',
  'com.whatsapp',
  'com.spotify.music',
  'com.android.chrome',
  'com.google.android.gm',
  'com.google.android.calendar',
  'com.google.android.keep',
];

/// The apps plans can use after setup: every app the user didn't hide,
/// everyday task apps first, up to [max]. [eligible] is sorted by name and
/// leaves out Curre and the apps always on Home. Plans need two apps to
/// choose from, so if hiding left fewer, the defaults come back first.
Set<String> defaultPlanApps({
  required List<String> eligible,
  required Set<String> hidden,
  int max = 30,
}) {
  final kept = eligible.where((package) => !hidden.contains(package)).toSet();
  final defaultsFirst = [
    for (final package in commonTaskPackages)
      if (eligible.contains(package)) package,
    for (final package in appTaskExamples.keys)
      if (eligible.contains(package)) package,
    ...eligible,
  ];
  final picked = <String>{};
  for (final package in defaultsFirst) {
    if (picked.length >= max) break;
    if (kept.contains(package)) picked.add(package);
  }
  final minimum = math.min(2, eligible.length);
  for (final package in defaultsFirst) {
    if (picked.length >= minimum) break;
    picked.add(package);
  }
  return picked;
}

/// The live line under "What pulls you in?": exactly what Curre will hide,
/// and that nothing else is.
String hiddenSummary(List<String> labels) {
  if (labels.isEmpty) return 'Nothing hidden yet. Every app opens as usual.';
  final shown = labels.length <= 3 ? labels : labels.take(2).toList();
  final more = labels.length - shown.length;
  final names = more > 0
      ? '${shown.join(', ')} and $more more'
      : shown.length == 1
      ? shown.single
      : '${shown.sublist(0, shown.length - 1).join(', ')} and ${shown.last}';
  return 'Hidden: $names. Every other app opens as usual.';
}

String localizedHiddenSummary(List<String> labels, AppLocalizations l10n) {
  if (labels.isEmpty) return l10n.nothingHiddenYet;
  if (labels.length == 1) return l10n.hiddenSummaryOne(labels.single);
  final shown = labels.length <= 3 ? labels : labels.take(2).toList();
  final more = labels.length - shown.length;
  final names = more > 0
      ? l10n.hiddenSummaryMore(shown.join(', '), more)
      : shown.length == 2
      ? l10n.hiddenNamesTwo(shown.first, shown.last)
      : shown.join(', ');
  return l10n.hiddenSummaryMany(names);
}

String? localizedAppTaskExample(String packageName, AppLocalizations l10n) =>
    switch (packageName) {
      'com.google.android.youtube' => l10n.taskExampleLearn,
      'com.google.android.apps.maps' => l10n.taskExampleFindWay,
      'com.whatsapp' || 'org.telegram.messenger' => l10n.taskExampleReply,
      'com.google.android.apps.messaging' => l10n.taskExampleTextBack,
      'com.spotify.music' => l10n.taskExamplePlaylist,
      'com.android.chrome' => l10n.taskExampleLookUp,
      'com.google.android.gm' => l10n.taskExampleEmail,
      'com.google.android.calendar' => l10n.taskExampleToday,
      'com.google.android.keep' => l10n.taskExampleWrite,
      'com.google.android.photos' ||
      'com.google.android.apps.photos' => l10n.taskExamplePhoto,
      'com.google.android.drive' ||
      'com.google.android.apps.docs' => l10n.taskExampleFile,
      'com.instagram.android' ||
      'com.linkedin.android' => l10n.taskExampleMessage,
      'com.netflix.mediaclient' => l10n.taskExampleEpisode,
      'com.facebook.katana' => l10n.taskExampleGroup,
      'com.zhiliaoapp.musically' ||
      'com.ss.android.ugc.trill' => l10n.taskExampleVideo,
      'com.twitter.android' => l10n.taskExamplePost,
      'com.reddit.frontpage' => l10n.taskExampleThread,
      'com.pinterest' => l10n.taskExampleIdea,
      'com.snapchat.android' => l10n.taskExampleFriend,
      _ => null,
    };
