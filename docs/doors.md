# Production doors

Curre never turns model output into a URL. The model can return only the
user's exact words and a fixed door identifier chosen by the phone. Android
then builds one of the patterns below. If a fixed door fails, Curre copies the
words and opens an app-published Search shortcut, or opens the app when that
shortcut does not exist.

Conversation doors are also phone-owned. Curre reads dynamic, pinned and
cached shortcuts through `LauncherApps`, keeps only conversation shortcuts,
and starts one only when the extracted name exactly or wholly matches a local
shortcut label or `ShortcutInfo.persons` name. Otherwise it says that it will
open the app and uses the same copied-words fallback. See Android's
[conversation shortcut guidance][android-conversations] and
[`LauncherApps` reference][launcher-apps].

## Matrix

| App | Production door | Exact pattern or action | First-party contract reviewed | Fallback | Phone check |
| --- | --- | --- | --- | --- | --- |
| YouTube | Search | `ACTION_VIEW https://www.youtube.com/results?search_query=<encoded words>` restricted to `com.google.android.youtube` | [YouTube search help][youtube-search] documents the search destination, but not this Android deep-link shape | Search shortcut, else app; words copied | Yes |
| Google Maps | Search | `ACTION_VIEW geo:0,0?q=<encoded words>` restricted to `com.google.android.apps.maps` | [Maps intents][maps-intents] | Search shortcut, else app; words copied | Yes |
| Spotify | Search | `ACTION_VIEW spotify:search:<encoded words>` restricted to `com.spotify.music` | [Spotify content linking][spotify-linking] documents the package and `spotify:` scheme, but not the `search:` path | Search shortcut, else app; words copied | Yes |
| Play Store | Search apps | `ACTION_VIEW https://play.google.com/store/search?q=<encoded words>&c=apps` restricted to `com.android.vending` | [Google Play links][play-links] | Search shortcut, else app; words copied | Yes |
| Gmail | New draft | `ACTION_SENDTO mailto:` with `Intent.EXTRA_SUBJECT=<words>`, restricted to `com.google.android.gm` | [Android email intents][common-intents] | Search shortcut, else app; words copied | Yes |
| Google Calendar | New event | `ACTION_INSERT CalendarContract.Events.CONTENT_URI` with `Events.TITLE=<words>`, restricted to `com.google.android.calendar` | [Android calendar intents][common-intents] | Search shortcut, else app; words copied | Yes |
| Google app | No fixed query door | No app-specific contract is assumed; Android's web-search intent is generic | [Android search intents][common-intents] | App-published Search shortcut, else app; words copied | Yes, shortcut inventory |
| Chrome | No fixed query door | No package-specific query contract is assumed | [Android search intents][common-intents] | App-published Search shortcut, else app; words copied | Yes, shortcut inventory |
| WhatsApp | Matched local conversation only | `LauncherApps.startShortcut` after a local conversation/person-name match; `wa.me` is not built from a display name because it requires a full phone number | [WhatsApp click to chat][whatsapp-chat], [Android conversations][android-conversations] | Search shortcut, else app; name copied | Yes |
| Telegram | Matched local conversation only | `LauncherApps.startShortcut` after a local match; Telegram links are not built from a display name because they require a username or phone number | [Telegram deep links][telegram-links], [Android conversations][android-conversations] | Search shortcut, else app; name copied | Yes |
| Instagram | Matched local conversation only | `LauncherApps.startShortcut` after a local conversation/person-name match | [Android conversations][android-conversations] | Search shortcut, else app; name copied | Yes |
| Messages | Matched local conversation only | `LauncherApps.startShortcut` after a local match; `smsto:` is not built from a display name because Android's contract requires a phone number | [Android messaging intents][common-intents], [Android conversations][android-conversations] | Search shortcut, else app; name copied | Yes |
| Phone | No name-based fixed door | `tel:` is not built from a display name because Android's dial contract requires a phone number | [Android phone intents][common-intents] | App; name copied | No new door |
| TikTok | No fixed query door | No stable first-party free-text Android contract found | — | App-published Search shortcut, else app; words copied | Yes, shortcut inventory |
| X | No fixed query door | No stable first-party free-text Android contract found | — | App-published Search shortcut, else app; words copied | Yes, shortcut inventory |
| Reddit | No fixed query door | No stable first-party free-text Android contract found | — | App-published Search shortcut, else app; words copied | Yes, shortcut inventory |
| Netflix | No fixed query door | No stable first-party free-text Android contract found | — | App-published Search shortcut, else app; words copied | Yes, shortcut inventory |
| Amazon | No fixed query door | No stable first-party free-text Android contract found | — | App-published Search shortcut, else app; words copied | Yes, shortcut inventory |
| Duolingo | No fixed query door | No stable first-party free-text Android contract found | — | App-published Search shortcut, else app; words copied | Yes, shortcut inventory |
| Google Keep | No fixed note door | Android defines `ACTION_CREATE_NOTE`, but no Keep-specific handling contract is assumed | [Android note intents][common-intents], [Google note actions][note-intents] | App-published Search shortcut, else app; words copied | Yes, shortcut inventory |

The Door Lab includes every app above so the installed packages, published
shortcuts, conversation metadata, fixed intents and fallbacks can be checked
on the submission phone. The native Kotlin additions in this matrix have not
been compiled or exercised on that phone yet.

[android-conversations]: https://developer.android.com/develop/ui/views/notifications/conversations
[launcher-apps]: https://developer.android.com/reference/android/content/pm/LauncherApps
[youtube-search]: https://support.google.com/youtube/answer/16090438
[maps-intents]: https://developers.google.com/maps/documentation/android-sdk/intents
[spotify-linking]: https://developer.spotify.com/documentation/android/tutorials/content-linking
[play-links]: https://developer.android.com/distribute/marketing-tools/linking-to-google-play
[common-intents]: https://developer.android.com/guide/components/intents-common
[whatsapp-chat]: https://faq.whatsapp.com/5913398998672934
[telegram-links]: https://core.telegram.org/api/links
[note-intents]: https://developers.google.com/android/reference/com/google/android/gms/actions/NoteIntents
