/// What Curre knows about well-known apps, to make setup quicker: which
/// ones tend to pull people in, and an everyday example of what a plan
/// might open each one for. Matching is by package name, so it never sends
/// anything anywhere.
library;

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
