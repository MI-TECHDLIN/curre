# Installing Curre for testing

These notes are for testers and judges installing a Curre APK directly
(from a browser download, a file manager or `adb install`) rather than from
an app store.

## 1. Install and set up (about a minute)

1. Install the APK that matches the phone (`app-arm64-v8a-release.apk` for
   almost every recent phone) and open Curre.
2. First run is five steps, counted `1 / 5` to `5 / 5`, with Back on every
   step after the first:
   1. **Welcome**: the problem, Curre's promise, and one line on privacy
      with a link to the full privacy details.
   2. **You**: your name and, if you like, a face (otherwise your initial).
   3. **What pulls you in?**: tick the apps where a quick look turns into
      an hour. They go to Hidden apps. Phone, Messages and Settings are
      always on Home.
   4. **Make Curre your home screen**: Android asks which home screen to
      use; choose Curre.
   5. **Your first plan**: one sentence ("Learn the G chord on YouTube till
      7"), or "I’ll plan later". Either way you land on Home.

Mornings start at 06:00; change that under Curre settings → Your day.

## 2. Questions Curre asks later, once each

Nothing else is asked during setup. Each of these comes up once, at the
moment it first helps, can be declined with "Not now", and always lives in
Curre settings with a line saying where it stands:

| Question | When Curre asks | In Curre settings |
| --- | --- | --- |
| Quiet nudges (Android's notification permission) | On Home, the first time a plan or a hidden app's time is running | Quiet nudges → Allow notifications |
| Usage access ("Ask “Why now?” when a hidden app opens") | The first time you open Hidden apps | Hidden apps |
| Notification access ("Keep hidden apps quiet") | A later visit to Hidden apps | Hidden apps |
| Microphone | The first time you tap a mic button | Voice typing |

## 3. "Restricted setting" on Android 13 and later

Android blocks Usage access and Notification access for apps installed
outside an app store. When you switch either on for Curre, Android may say
the setting is restricted, or that Curre was denied access. This is
expected, and it cannot (and must not) be bypassed. Allow it once:

1. Open Curre's **App info**. Curre shows an "Open Curre’s App info"
   button next to every place it asks for these; or open your phone's
   Settings, then Apps, then Curre.
2. Tap the **three dots** in the top right corner.
3. Tap **Allow restricted settings**.
4. Confirm with your PIN, pattern or fingerprint.
5. Come back to Curre and switch the access on again.

If access is still off when you come back, Curre shows these steps again and
carries on without it: plans, Hidden apps and "Bring back" all work; only the
"Why now?" check for apps opened from elsewhere and quiet notifications need
the access.
