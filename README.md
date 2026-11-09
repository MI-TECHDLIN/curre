# Curre

![Curre: open the task, not the app — a phone Home made from what you said you're about to do](docs/images/cover.jpg)

**Curre opens the task, not the app.**

Curre is an Android launcher for a focused stretch of your life: exams, a
deadline, or a bad habit you want to break. It isn't meant to be your home
screen forever. You pick what the focus is for and when it ends; when that
day comes, Curre shows you how it went and hands your phone back to your old
home screen.

While the focus runs, you tell Curre what you're about to do — "learn
the G chord on YouTube and find a music shop on Maps until 7" — and it
builds you a small Home made only of the apps that task needs, each one
landing on an allowlisted search or a conversation shortcut the phone
actually exposes instead of promising a path that may not exist. Only the
few apps you chose to hide — the ones that pull you in — stay hidden until
you say, in your own words, why you need one right now; every other app
opens as usual.

**Who it's for:** anyone who needs their own phone to behave for a set
stretch and knows exactly when that stretch ends — a student clearing exam
week, someone heads-down on a deadline, or a person breaking a habit like
late-night scrolling. Not a permanent home screen, and not aimed at parental
control or managing someone else's phone.

Built for the [Clocked Build Challenge](https://clocked.rezolve.ai/challenge),
entering Best Overall and Best Use of Decide, Extract or Fill.

## Demo

[3:36 demo video](https://github.com/MI-TECHDLIN/curre/releases/download/V.1/curre-demo.mp4) —
rendered from the real app against live-captured server answers (see
`demo/README.md`). Attached to the
[`V1.0.0` release](https://github.com/MI-TECHDLIN/curre/releases/tag/V.1).

Write-up: [Curre: a phone launcher for one focused stretch of your life (Medium)](https://medium.com/@ezechukwumiracle52/curre-a-phone-launcher-for-one-focused-stretch-of-your-life-ad7a1bfd3891)

## Try it (for judges)

The fastest path: download `app-arm64-v8a-release.6.apk` from the [V1.0.0
release](https://github.com/MI-TECHDLIN/curre/releases/tag/V.1) and install
it per [`docs/install.md`](docs/install.md) — no build step needed. **This
release build is arm64 only**; a device or emulator needing a different ABI
(`armeabi-v7a` or `x86_64`) needs its own build from source (see below).
That build already points at the hosted backend,
`https://curre-zdfr.onrender.com`, which is live (`GET /healthz` →
`{"status": "ok"}`). It's Render's free tier, so the first request after
idle can take ~13 seconds to wake; the app shows a quiet "getting ready"
note while it does (see
[Uncertain results, missing information and failed requests](#uncertain-results-missing-information-and-failed-requests)).

To build from source instead, or to run it against your own backend, see
[Build and run](#build-and-run) below; `flutter analyze && flutter test`
and the backend's `pytest`/`ruff check .` (also under Build and run → Tests)
need no deployed backend or Clocked key beyond a non-empty placeholder.

## The problem

Most focus apps gate the app, not the use. The same app is often both the
need and the trap: messaging a friend on Instagram is fine, the feed that
follows is the problem. An app-level block or AI "bouncer" treats both the
same, so people work around it — which is why in-app feed blockers exist at
all. Curre's bet is that the phone already has what it needs to open the
*task* inside an app, not just the app: published shortcuts, conversation
shortcuts, and a handful of query links, chosen by what you said you meant
to do.

## A focus period, not forever

A launcher that asks "why now?" every time is a good friend for ten exam
days and an exhausting one for months. So Curre is built around a time-bound
**focus period** (`lib/core/focus.dart`):

- **Start: a goal and an end date.** During setup (the "About you" step) or
  later from Home or Curre settings, pick what it's for — *Exams*, *A
  deadline*, *Breaking a habit* or *Something else* — add a few words of
  your own ("Pass my maths finals"), and choose when it ends: 1 week, 2
  weeks, 3 weeks, 30 days, or any date on the calendar. A habit starts at
  21 days. People who set Curre up before focus periods existed see a gentle
  "Set a focus?" card on Home that they can put away.
- **During: calm and countable.** Home shows the goal and "N days left".
  Curre settings can move the end date (to extend) or end it now, after one
  confirm.
- **A rest day.** Once a week you can "Take today off": until the next
  morning, hidden apps open without asking why, their notifications come
  through, and Curre sends no reminders. A rest day never breaks your
  Prooflight run — it's skipped, not counted as empty.
- **End: a summary and the way back.** On the end date Curre sends one
  notification, and Home shows how it went: days of focus, days with proof,
  tasks proved, and how often a hidden app asked "Why now?" and stayed
  closed (from the last 30 days of History). Then two choices: **Start
  another focus period**, or **Go back to my old home screen**, which turns
  off "Why now?", the quieting of hidden apps and the "Plan your day"
  reminders, then opens Android's home screen choice. History and proof
  days stay on the phone.
- **Leaving early really leaves.** If you switch to another home screen at
  any time, Curre pauses "Why now?" and notification quieting until it is
  your home screen again. Your settings stay as you left them.

## What Curre is

![The Curre journey: Plan to Doors to Why now?/Proof to Later, wrapped by a focus period](docs/images/journey-diagram.jpg)

- **Task Doors.** Fill picks which installed apps (and which of their own
  shortcut labels — "Messages", "Search") a plan needs. Extract copies the
  exact words for the search or the end time, verbatim, with positions.
  The result: a Home row for YouTube lands on search results for "the G
  chord," not YouTube's front page. See `lib/doors/` for the pure routing
  policy and `MainActivity.kt` for how Android turns a door choice into a
  shortcut launch, a query link, or a plain open. Fixed doors cover YouTube,
  Google Maps, Spotify and Play Store searches, Gmail drafts, and Calendar
  events; every pattern and fallback is listed in
  [`docs/doors.md`](docs/doors.md). Spotify's documented URI scheme still
  needs verification on the submission phone. A chat is named only after a
  matching conversation shortcut is found on that phone; otherwise Curre
  says it will open the app.
- **Only the apps you pick are hidden.** Setup asks "What pulls you in?"
  (Instagram, TikTok…); exactly those leave Home, ask "Why now?" when they
  open and have their notifications held. Every other app — Camera, Maps,
  your bank, Clock — stays in **All apps** on Home and opens as usual, no
  question. "Hide this app" in All apps (or **Hidden apps → Hide another
  app**, or Curre settings → Your apps → Hidden apps) adds one; the same
  list stops hiding one. Phone, Messages, Settings and anything "Always on
  Home" can't be hidden. Plans choose only from apps you didn't hide, and a
  hidden app a plan uses is out for that plan. People who set Curre up when
  every unplanned app was hidden keep only their old picks hidden
  (`legacyHiddenApps` in `lib/core/visibility.dart`).
- **"Why now?"** Opening a hidden app asks why, in your own words. Decide
  sorts that reason into `task`, `person`, `time_sensitive`, `browse`, or
  `unclear`; Guard (injection) screens the text first.
  The gate answers with one of five outcomes — **open** (with a time-bound
  grant), **later**, **specify**, **flagged**, or **unavailable** — and
  every outcome except a flagged one still has an escape: "Not now," with
  the app opening anyway after a visible **30-second wait** if you still
  want in.
- **Saved for later.** A browsing reason can stay on the phone for up to
  seven days instead of disappearing. After the next plan, Rerank reads that
  plan against the saved reasons; Curre shows up to three matching items in
  Rerank's order as doors at the saved words. If that call fails, the newest
  items appear first without interrupting the check-in.
- **Times in your own words.** A check-in understands durations such as
  “2hrs”, “an hour and a half” and “20 min”, clock ends such as “until
  7:30pm”, and ranges such as “from 4 to 6”. An app can have its own time
  inside the plan. Confirmation shows the resulting clock times and lets you
  tap any one to adjust it. Explicit plans stop after six hours or at local
  midnight, whichever comes first.
- **Prooflight.** A completed task only counts if Curre watched you start
  it — through a Task Door or an explicit offline start. A completion note
  then goes through Protect (pii) → Guard (injection) → Decide → Extract →
  Verify (grounding). Decide must find a specific result and Verify
  (grounding) must find no clear conflict with the planned task. A specific,
  traced completion raises a proof day; an honest check-off without a note
  stays an honest check-off. The summary is rebuilt from records each time,
  never stored as a counter.
- **Gentle intercept.** A small foreground service notices when a hidden
  app comes to the front — from the recent-apps list, a link, or a
  notification tap — and brings up Curre's "Why now?" gate instead of
  letting it open silently.

## Notifications

Every Curre notification is silent (no sound, no vibration), avoids quiet
hours (22:00–07:00; reminders move to 07:00) and skips your rest day. Each
kind has its own switch under **Curre settings → Quiet nudges**, plus "Turn
all quiet nudges off"; Android's own notification settings for Curre work
too. On Android 13 and later Curre asks for permission once, in context,
the first time a nudge would help.

| Notification | When it comes | How to turn it off |
| --- | --- | --- |
| **Plan your day** | When your morning begins (new setups get one a day; the afternoon and evening ones are a separate switch) | Quiet nudges → *Plan your day* / *Afternoon and evening too* |
| **Plan ending** | Ten minutes before a plan ends | Quiet nudges → *Plan ending* |
| **Add your proof** | Five minutes after a plan ends (off by default for new setups) | Quiet nudges → *Add proof* |
| **App time up** | While a hidden app you brought back—or gave its own time inside a plan—is open, a countdown; then "hidden again" when the time is up | Quiet nudges → *App time up* |
| **Your focus is done** | The morning your focus period ends | Quiet nudges → *Focus ends* |
| **Hidden app check is on** | Always shown while "Why now?" is watching for hidden apps (Android requires it for the small background helper) | Curre settings → Hidden apps → *Ask "Why now?"* off |

"Plan your day", "Plan ending" and "Add your proof" offer **Snooze 10 min**.
Reminders are set a few days ahead and set again each new day, and Android
puts them back after a restart.

### Notifications from hidden apps are held, never deleted

With notification access, **Keep hidden apps quiet** holds ordinary
notifications from the apps you chose to hide — and only those; every other
app notifies as usual. Calls, alarms, system, ongoing and full-screen
notifications are never touched. Turn it off under Curre settings → Hidden
apps.

- **Held:** Android snoozes the original, so it comes back whole (its own
  tap action and replies). Curre also keeps a copy on the phone — app,
  title, text and time — saved to disk, so a restart loses nothing.
- **Given back** as soon as any of these happens: you open that app through
  "Why now?" or a plan, you stop hiding it, you take a rest day, your focus
  period ends (Android knows the end time and gives back by itself), you
  switch "Keep hidden apps quiet" off, or Curre stops being your home
  screen. Curre ends the snooze so the original reappears; anything Android
  no longer has (after a restart, or if it refused the snooze) comes back as
  one quiet Curre notification per app that opens it.
- **Missed notifications** (in Hidden apps) lists them: held ones with
  their text, given-back ones with app, title and time for 30 days. Tapping
  one opens it — through "Why now?" while the app is still hidden, straight
  once it's back. Text is kept only while a notification is held, and
  nothing leaves the phone.

The rule lives in `QuietNotificationListenerService.kt`, mirrored for
tests by `QuietNotificationPolicy` in `lib/platform/quiet_notifications.dart`.

## Languages

Curre ships in **English, Spanish, French, Portuguese and German**. It
follows the phone language on first launch; **Curre settings → Language**
can keep a different language for Curre alone. Adding another language is
one ARB file under [`lib/l10n/`](lib/l10n/); Flutter's `gen-l10n` checks that
every locale has the same messages, placeholders and plurals.

The selected two-letter language code travels with plan, Why-now, proof and
Later requests. Clocked still returns Curre's stable internal codes, while
Fill, Extract, Decide, Verify (grounding) and Rerank read the person's
original language; Extract spans stay verbatim so highlights continue to
index the words the person typed. Offline plan-end parsing and on-device Whisper hints understand
the same five languages.

`clocked-sdk` 0.7.0 does not impose a language allowlist in its client
source. A live Pipeline probe on 2026-11-04 exercised Fill, Extract, Decide,
Verify (`grounding` in the SDK) and Rerank once in each shipped language; all
25 steps returned HTTP 200. Each five-step pipeline used 7 credits, for
**35 credits total**:

| Language | Code | Credits | Model time |
| --- | --- | ---: | ---: |
| English | `en` | 7 | 165.5 ms |
| Spanish | `es` | 7 | 158.6 ms |
| French | `fr` | 7 | 166.1 ms |
| Portuguese | `pt` | 7 | 158.0 ms |
| German | `de` | 7 | 164.8 ms |

## Screenshots

Light and dark captures live in [`docs/screenshots/`](docs/screenshots/).

| Onboarding | Home | Plain words |
| --- | --- | --- |
| ![Onboarding](docs/screenshots/onboarding-light.jpg) | ![Home](docs/screenshots/home-light.png) | ![Plain words](docs/screenshots/plain-words-light.jpg) |

| Prooflight |
| --- |
| ![Prooflight](docs/screenshots/prooflight-light.jpg) |

Dark-theme counterparts: `onboarding-dark.jpg`, `home-dark.png`,
`plain-words-dark.jpg`, `prooflight-dark.jpg`.

## How Clocked powers Curre

![Four Clocked routes, one pipeline call each: /v1/plan, /v1/unlock, /v1/proof and /v1/later, with their Fill/Extract/Protect/Guard/Decide/Verify/Rerank steps](docs/images/clocked-routes-diagram.jpg)

Four routes: three make one `clocked-sdk` `pipeline()` call each, and the
Later shelf makes one `rerank()` call. The phone owns all state; the backend
stores nothing and logs only route/status/latency/credits — never the
intention, reason, saved item, or note text. Full contract and response
shapes: [`server/README.md`](server/README.md).

**The journey, and what each call changes:**

1. **Plan** (`/v1/plan`, check-in). You type what you're about to do; Fill
   picks which installed apps belong on the next Home and which shortcut
   each uses, and Extract copies the exact search words or end time
   verbatim. The app turns that straight into **doors** — the small Home
   for this task.
2. **Doors** (`lib/doors/`, no Clocked call). Each door from step 1 opens as
   an allowlisted search, a conversation shortcut, or a plain app open —
   whichever the phone actually has. This is where Plan's output becomes
   something tappable.
3. **Unlock or proof** (`/v1/unlock` when a hidden app opens mid-plan;
   `/v1/proof` when a task is checked off). Unlock's Decide step turns your
   "why now?" into one of five outcomes that opens, defers, or blocks the
   app; proof's Decide and Verify (grounding) steps turn a completion note
   into a proof day or an honest check-off. Either way, Protect (pii)'s
   output decides what History keeps, never what the gate or the sheet
   shows you live.
4. **Later** (`/v1/later`, after the next plan). Rerank reads the new plan
   against reasons saved from step 3's "later" outcomes and returns up to
   three as doors on that plan, in Rerank's order — turning a deferred
   reason from the past into a door in the present.

| Route | Clocked steps | What it decides |
| --- | --- | --- |
| `POST /v1/plan` | Fill → Extract | Which installed apps appear on the next Home, which shortcut each uses, and the exact search words/end time, as visible highlights. |
| `POST /v1/unlock` | Protect (pii) → Guard (injection) → Decide → Extract | Protect (pii)'s spans replace personal details only in the copy saved to History. Guard (injection) can stop an instruction; Decide selects one of five outcomes and a door; Extract supplies the target, person and grant length. |
| `POST /v1/proof` | Protect (pii) → Guard (injection) → Decide → Extract → Verify (grounding) | Protect (pii) changes the note History keeps. Decide's specific-completion gate and Extract's evidence span still apply; Verify (grounding) vetoes a note only when a claim clearly conflicts with the planned task, and supplies the short follow-up reason. |
| `POST /v1/later` | Rerank | Orders up to 20 phone-saved browsing reasons against the new plan. Only results with Rerank's `use` action become doors, capped at three; `skip` and `expand` stay saved for another plan. |

### Clocked endpoints by award group

Curre uses seven of the nine Clocked endpoints, meaningfully, each changing
what the app shows or does — not as an unused extra call:

| Group | Endpoint | Route(s) | What its output changes in the app |
| --- | --- | --- | --- |
| Decide, Extract, Fill | **Fill** | `/v1/plan` | Chooses which installed apps (and which shortcut of each) belong on the next Home (`server/app/clocked_pipeline.py`; mapped to doors in `lib/core/api_models.dart`). |
| Decide, Extract, Fill | **Extract** | `/v1/plan`, `/v1/unlock`, `/v1/proof` | Copies the verbatim search words/end time for a door (plan); the target, person and grant length (unlock); the result/learning span for a proof day (proof). |
| Decide, Extract, Fill | **Decide** | `/v1/unlock`, `/v1/proof` | Chooses the `open`/`later`/`specify`/`flagged`/`unavailable` outcome and door (unlock, see `UnlockOutcome` in `lib/core/models.dart`); gates whether a note is specific enough to raise a proof day (proof). |
| Protect, Guard, Inspect | **Protect (pii)** | `/v1/unlock`, `/v1/proof` | Replaces personal details in the copy written to History only (`lib/core/redaction.dart`); never changes what the live gate or completion sheet shows. |
| Protect, Guard, Inspect | **Guard (injection)** | `/v1/unlock`, `/v1/proof` | Can stop the pipeline outright, producing the `flagged` (unlock) or `vague` (proof) outcome (`GuardInfo` in `server/app/clocked_pipeline.py`). |
| Protect, Guard, Inspect | Inspect | *not used* | Inspect reviews scripts; Curre has no scripts to review, only short reasons and notes (see `server/README.md`). |
| Verify, Compare, Rerank | **Verify (grounding)** | `/v1/proof` | Vetoes a completion note only when a claim clearly contradicts the planned task, and supplies the short follow-up reason (`grounding` in the SDK). |
| Verify, Compare, Rerank | Compare | *not used* | Would duplicate the plan-vs-note judgment Verify already makes on the same inputs (see `server/README.md`). |
| Verify, Compare, Rerank | **Rerank** | `/v1/later` | Orders saved "later" reasons against the new plan; only `use`-ranked results, capped at three, become doors. |

Measured against the real Clocked API, sequentially, 2026-10-25
(`server/scripts/measure.py`; see `server/README.md` for the full table and
method):

| Route | Samples | Credits/call, mean (range) | p50 latency | p95 latency |
| --- | ---: | ---: | ---: | ---: |
| `/v1/plan` | 10 | 5.30 (4–11) | 274 ms | 858 ms |
| `/v1/unlock` | 25 | 4.76 (4–7) | 260 ms | 344 ms |

The current five-step `/v1/proof` pipeline has one sanitized real sample:
**10 credits and 900 ms** client-observed round trip. It has not been through
the same 10+ sample latency sweep yet. The added Protect (pii) step was also seen
at 65–72 ms inside two real pipelines; see `server/README.md` for the exact
measurement scope and credit budget.

The Later shelf's sanitized real Rerank fixture used **2 credits** and
reported **38.3 ms** of billable model time for six saved items. This was a
single contract sample, not a latency sweep.

## Uncertain results, missing information and failed requests

![Handling uncertain, missing and failed results: a defined fallback for a low-confidence Decide, a flagged instruction, missing fields, timeouts, a sleeping backend and Verify specifically](docs/images/fallbacks-diagram.jpg)

Curre never blocks you on a Clocked call that can't answer confidently. Each
case below has a defined fallback, so a bad network or an unsure model
degrades the feature instead of freezing it.

- **Low-confidence Decide ("why now?").** Decide's `kind` choice carries a
  confidence score; below the configured threshold (`DECIDE_THRESHOLD`,
  default `0.7`, clamped `0.5`–`0.9`) or when the reading is genuinely
  `unclear`, the outcome is `specify`, not a guess — Curre asks you to say a
  bit more rather than opening or blocking on a weak signal
  (`server/README.md` endpoint map; `UnlockOutcome` in `lib/core/models.dart`).
- **A clearly unsafe instruction.** Guard's `injection` check can stop the
  pipeline outright; that outcome is `flagged`, and — unlike every other
  outcome — it has no 30-second "Not now" escape.
- **Missing or odd fields.** `/v1/plan` cleans rather than rejects: a
  candidate app with a blank or repeated id/label, or a field of the wrong
  type, is dropped instead of failing the whole plan
  (`planCandidatesFrom`/`cleanShortcutLabels` in `lib/core/api_models.dart`,
  mirrored server-side in `server/app/models.py`). An Extract value that
  can't be found comes back as a null `value` with no fabricated span, and
  an Extract error on `/v1/plan` still returns Fill's apps without spans
  rather than discarding the whole answer. A Protect (pii) result that is
  missing, malformed, or out of range changes nothing — Curre keeps the
  original text and never claims it redacted something it didn't.
- **Timeouts and retries.** `/v1/plan` gets one automatic retry inside a
  12-second total budget (9 s first attempt, 250 ms pause, the remainder for
  the retry), both attempts sharing one `Idempotency-Key` so a retry can't
  double-bill a pipeline run (`lib/core/api_client.dart`,
  `server/README.md`). `/v1/unlock`, `/v1/proof`, and `/v1/later` don't
  retry; each has its own fallback instead (below).
- **A cold Render host.** The free-tier backend can take ~13 s to wake. The
  first call of a session gets a 30-second `coldStartBudget` instead of the
  normal timeout, and `CurreApiClient.waking` drives a "getting ready" note
  on the waiting screen while it does (`lib/core/api_client.dart`).
- **Offline or failed requests, per route.** Every transport error, timeout,
  non-2xx status, and malformed response is treated the same way, and
  always leaves the user with something usable rather than an error screen:
  - `/v1/plan` → the check-in falls back to a manual checklist built from
    the apps you typed, with no Clocked-chosen doors or highlights.
  - `/v1/unlock` → `unavailable`, which still gives the local 30-second
    override wait so a hidden app can be opened anyway.
  - `/v1/proof` → `pending`; the note stays on the phone and is credited to
    its task's original day once it can be judged, rather than lost or
    forced into a guess.
  - `/v1/later` → the shelf silently falls back to newest-first ordering
    instead of Rerank's order, with no interruption to check-in.
- **Verify (grounding), specifically.** An ordinary new detail in a proof
  note that Verify (grounding) simply wasn't told about (`not_stated`) does
  not veto it — only a claim that clearly contradicts the planned task does
  (`contradicted >= 0.6`).

## Architecture

```mermaid
flowchart LR
    subgraph Phone["Android phone"]
        UI["Flutter UI & local controller\n(lib/app, lib/core)"]
        Store["Local store\nplans · grants · saved items · history · proof\n(SharedPreferences)"]
        Kotlin["Kotlin platform channel\n(MainActivity, GentleInterceptService,\nQuietNotificationListenerService)"]
    end

    Android["Android OS\nHome role · LauncherApps shortcuts ·\nUsageEvents · NotificationListener"]

    subgraph Backend["Curre backend (FastAPI, stateless)"]
        Routes["/v1/plan · /v1/unlock · /v1/proof · /v1/later\n/healthz"]
    end

    Clocked["Clocked API\nFill · Extract · Decide · Guard (injection) · Protect (pii) · Verify (grounding) · Rerank"]

    UI <--> Store
    UI <--> Kotlin
    Kotlin <--> Android
    UI -- "HTTPS, X-App-Key" --> Routes
    Routes -- "one Clocked call per route" --> Clocked
```

The backend is the only thing that holds the Clocked API key — a key inside
the APK could be extracted, so the phone never calls Clocked directly.

## Privacy

Curre's own backend stores no plan, reason, saved item, or note text; it logs
route, status, latency, and credits only. For Later ordering, the new plan,
app label and saved reason are sent again; no package name leaves the phone.
Clocked, the processor that judges that text, documents that it retains
successful response bodies for idempotent retries and clears them on a
scheduled maintenance window after they're older than 24 hours;
usage/account records persist longer. ([Clocked security
page](https://clocked.rezolve.ai/security), read 2026-10-26.) All of Curre's
own plans, grants, attempts, saved reasons, and proof notes live only on the
phone in local storage, age out automatically, and clear with History — but
that local storage is not encrypted, so it isn't protected against a
compromised or backed-up device.

Before a judged unlock reason or proof note is written to History, Protect
(pii)'s source spans replace names, phone numbers, email addresses,
addresses, card numbers and bank-account numbers with visible placeholders
such as `[name]` and `[phone]`. The gate and completion sheet keep using the
original words. If Protect (pii) does not answer, Curre keeps the words as
typed and shows no false privacy marker.

## Build and run

### 1. Backend

```sh
cd server
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env   # fill in CLOCKED_API_KEY and APP_KEY
uvicorn app.main:app --reload   # local; see below for a deployed backend
```

Deploy for real use as one container on a host of your choice — e.g.
[Render](https://render.com)'s free Web Service plan:

1. Push `server/` (it has no server-specific build step beyond
   `pip install -r requirements.txt`; Render's Python runtime or the
   included `Dockerfile`-free `uvicorn app.main:app` start command both
   work) as a new Web Service, with `CLOCKED_API_KEY` and `APP_KEY` set as
   environment variables (never committed — `server/.env` is gitignored).
2. Render's free plan spins the service down after inactivity, and a cold
   start is too slow for a live demo. Add an external **keep-awake ping**:
   a free uptime monitor (e.g. UptimeRobot, cron-job.org) hitting
   `GET https://YOUR_BACKEND/healthz` every 10 minutes keeps it warm. The
   app also sends a non-blocking `GET /healthz` on boot and whenever
   check-in opens, which helps, but only once a user is already there.
3. Confirm readiness with `curl https://YOUR_BACKEND/healthz` →
   `{"status": "ok"}`.

### 2. App

Release builds need your own signing key — **release builds never use the
debug key**, and the build fails with a clear message if one isn't
configured:

```sh
keytool -genkeypair -v -keystore curre-release.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias curre
cp android/key.properties.example android/key.properties
# edit android/key.properties with your keystore path and passwords
```

See [`android/key.properties.example`](android/key.properties.example) for
the full keytool walkthrough (Windows PowerShell/cmd.exe included).
`android/key.properties` is gitignored; never commit it or the `.jks` file.

Then, from a clean checkout:

```sh
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release --split-per-abi \
  --dart-define=CURRE_API_BASE_URL=https://YOUR_BACKEND \
  --dart-define=CURRE_APP_KEY=YOUR_APP_KEY
```

`--split-per-abi` produces one smaller APK per CPU architecture under
`build/app/outputs/flutter-apk/` (`app-armeabi-v7a-release.apk`,
`app-arm64-v8a-release.apk`, `app-x86_64-release.apk`) instead of one
universal APK; install the one matching the test phone with
`adb install -r build/app/outputs/flutter-apk/app-<abi>-release.apk`.

**Installing the APK outside an app store (Android 13 and later).** Android
marks Usage access and Notification access as *restricted settings* for
sideloaded apps, so the first time you switch either on for Curre it says
the setting is restricted or that Curre was denied access. That is Android
working as intended and Curre never tries to get around it. Allow it once:
open Curre's **App info** (Curre offers a button for it), tap the
**three-dot menu** in the top right, tap **Allow restricted settings**,
confirm with your PIN or fingerprint, then come back to Curre and switch
access on. Curre stays fully usable if you skip this; only "Ask “Why now?”
when a hidden app opens" and "Keep hidden apps quiet" need it. Step-by-step
notes for testers and judges: [`docs/install.md`](docs/install.md).

Both dart-defines are required: without them, `lib/core/api_client.dart`
deliberately treats the app as offline — planning falls back to a manual
checklist, unlock becomes `unavailable`, and proof stays `pending` — rather
than failing outright.

### 3. Tests

```sh
flutter analyze && flutter test                      # app
(cd server && .venv/bin/pytest && .venv/bin/ruff check .)  # backend
```

A GitHub Actions workflow that runs all three (plus an Android debug build)
on every pull request is at [`docs/ci-workflow.yml`](docs/ci-workflow.yml)
rather than `.github/workflows/`: this repo's push credential has no
`workflow` OAuth scope, so GitHub rejects a push that touches that
directory with it. Copy the file to `.github/workflows/ci.yml` from an
account/token with that scope (or via the GitHub web UI) to turn it on.

## Project layout

See [`AGENTS.md`](AGENTS.md) for where things live (Android channel, design
system, doors, Prooflight, local notifications, backend) and sharp edges
worth knowing before changing code.

## Development history

Started during the challenge's building period (October 21 – November 10,
2026): the
[first commit](https://github.com/MI-TECHDLIN/curre/commit/b68b11b) landed
October 23, 2026. Built in public from there, one pull request per feature:
[commit and PR history](https://github.com/MI-TECHDLIN/curre/commits/main).
Roughly, in order: the backend and phone-owned launcher logic first (`/v1/plan`,
`/v1/unlock`, task doors); then the production Android screens, design system
and avatars; real Clocked integration and a Prooflight proof-day loop end to
end; the "why now?" gate with quieted notifications; voice typing, richer
onboarding and release signing; Verify (grounding)-backed proof and the reranked Later
shelf; five-step contextual onboarding and a calmly-handled waking host;
focus periods with a rest day and graceful ending; selective app-hiding with
held (not deleted) notifications; a code-rendered demo film; multilingual
support in five languages; and natural-language plan/app time parsing. See
`git log --oneline` for the exact sequence.

AI coding tools helped build Curre — pairing on code, tests, and this
documentation — the way a lint suggestion or a Stack Overflow answer would.
Every change was reviewed, and I'm responsible for what's in this
repository, working or not.

## Credits and licenses

Curre's own code is original. Everything below is a third-party package,
font, or asset it bundles or depends on, checked against `pubspec.yaml`,
`server/requirements.txt`, and the credits already shown in-app at
**Curre settings → About → Licences** (`registerCurreLicenses` in
`lib/design/curre_fonts.dart`, backed by `test/design/licenses_test.dart`).

**Fonts** (bundled under `assets/fonts/`, licences under `assets/licenses/`):
Geologica, Newsreader, and Atkinson Hyperlegible Mono — each under the
**SIL Open Font License 1.1**.

**Icon designs:** the Solar icon set by **480 Design**, under
**CC BY 4.0**, used through the `solar_icons` Flutter package
(see `lib/design/curre_fonts.dart`'s `curreIconCredit`).

**Illustration:** onboarding scene props (`lib/design/art/fluent_props.dart`)
are drawn as vectors from Microsoft's **Fluent Emoji** (Flat style), under
the **MIT License**. The launcher icon, splash, notification art, and human
profile avatars are original, code-drawn artwork.

**Phone (Flutter/Dart packages, see `pubspec.yaml`):** `http`,
`shared_preferences`, `flutter_lints` — BSD-3-Clause; `timezone` —
BSD-2-Clause; `intl`, `flutter_localizations` (Flutter SDK) —
BSD-3-Clause; `flutter_local_notifications` — BSD-3-Clause (Michael Bui);
`path_parsing` — MIT (Dan Field); `record`, `path_provider`, `crypto`,
`solar_icons` (package only) — BSD-3-Clause; `permission_handler` — MIT;
`sherpa_onnx` — Apache-2.0 (bundles ONNX Runtime, MIT). Voice typing runs
Whisper tiny (OpenAI, MIT) through `sherpa_onnx`; the model file is a
one-time download, never bundled in the repository or the APK (see
`lib/platform/voice_model.dart`).

**Backend (Python packages, see `server/requirements.txt`):**
`fastapi`, `pydantic`, `clocked-sdk` — MIT; `uvicorn`, `python-dotenv` —
BSD-3-Clause.

**The Clocked API itself** (`clocked-sdk` 0.7.0) is the processor this
project is built on, not a credited asset — see
[Privacy](#privacy) for what it stores and
[How Clocked powers Curre](#how-clocked-powers-curre) for how it's used.

**The demo film** (`demo/`, not part of the shipped app) is rendered in
code against this checkout; see `demo/README.md` for how. Its narration
voice is **Kokoro** (hexgrad/Kokoro-82M), under **Apache License 2.0**, run
offline through the MIT-licensed `kokoro-onnx`; music and sound effects are
synthesised in code, not sampled.

No other third-party code, stock art, or media is bundled in the app or
backend. The screenshots in `docs/screenshots/` and the demo video are
captures of this app.

## What I learned

Clocked's pipeline model (several steps, one call, one credit total) turned
out to fit a privacy constraint I hadn't planned around going in: because
Protect (pii)'s output only ever changes what gets written to History — never what
the live gate or completion sheet shows — a single `/v1/unlock` or
`/v1/proof` call could do both the judgment and the redaction without a
second round trip or a second place for personal text to leak into. The
other lesson was about confidence: treating anything short of a clear
Decide result as "ask again" rather than guessing (open or block) made the
gate feel fair even when it was wrong, because it was wrong in the direction
of asking the person, not deciding for them.

## Team

Solo entry.

| Name | Email | GitHub |
| --- | --- | --- |
| Ezechukwu Miracle | ezechukwumiracle52@gmail.com | [@MI-TECHDLIN](https://github.com/MI-TECHDLIN) |
