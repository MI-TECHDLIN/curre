# Curre

**Curre opens the task, not the app.**

Curre is an Android launcher. You tell it what you're about to do — "learn
the G chord on YouTube and find a music shop on Maps until 7" — and it
builds you a small Home made only of the apps that task needs, each one
landing on the actual search or chat instead of a feed. Apps you've chosen
to keep off your Home stay hidden until you say, in your own words, why you
need one right now.

Built for the [Clocked Build Challenge](https://clocked.rezolve.ai/challenge),
entering Best Overall and Best Use of Decide, Extract or Fill.

## The problem

Most focus apps gate the app, not the use. The same app is often both the
need and the trap: messaging a friend on Instagram is fine, the feed that
follows is the problem. An app-level block or AI "bouncer" treats both the
same, so people work around it — which is why in-app feed blockers exist at
all. Curre's bet is that the phone already has what it needs to open the
*task* inside an app, not just the app: published shortcuts, conversation
shortcuts, and a handful of query links, chosen by what you said you meant
to do.

## What Curre is

- **Task Doors.** Fill picks which installed apps (and which of their own
  shortcut labels — "Messages", "Search") a plan needs. Extract copies the
  exact words for the search or the end time, verbatim, with positions.
  The result: a Home row for YouTube lands on search results for "the G
  chord," not YouTube's front page. See `lib/doors/` for the pure routing
  policy and `MainActivity.kt` for how Android turns a door choice into a
  shortcut launch, a query link, or a plain open.
- **"Why now?"** Apps you hide stay off Home. Opening one asks why, in your
  own words. Decide sorts that reason into `task`, `person`,
  `time_sensitive`, `browse`, or `unclear`; Guard screens the text first.
  The gate answers with one of five outcomes — **open** (with a time-bound
  grant), **later**, **specify**, **flagged**, or **unavailable** — and
  every outcome except a flagged one still has an escape: "Not now," with
  the app opening anyway after a visible **30-second wait** if you still
  want in.
- **Prooflight.** A completed task only counts if Curre watched you start
  it — through a Task Door or an explicit offline start. A completion note
  then goes through Protect → Guard → Decide → Extract → Verify. Decide must
  find a specific result and Verify must find no clear conflict with the
  planned task. A specific, traced completion raises a proof day; an honest
  check-off without a note stays an honest check-off. The summary is rebuilt
  from records each time, never stored as a counter.
- **Gentle intercept.** A small foreground service notices when a hidden
  app comes to the front — from the recent-apps list, a link, or a
  notification tap — and brings up Curre's "Why now?" gate instead of
  letting it open silently.

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

Three routes, one `clocked-sdk` `pipeline()` call each. The phone owns all
state; the backend stores nothing and logs only route/status/latency/credits
— never the intention, reason, or note text. Full contract and response
shapes: [`server/README.md`](server/README.md).

| Route | Clocked steps | What it decides |
| --- | --- | --- |
| `POST /v1/plan` | Fill → Extract | Which installed apps appear on the next Home, which shortcut each uses, and the exact search words/end time, as visible highlights. |
| `POST /v1/unlock` | Protect → Guard → Decide → Extract | Protect's spans replace personal details only in the copy saved to History. Guard can stop an instruction; Decide selects one of five outcomes and a door; Extract supplies the target, person and grant length. |
| `POST /v1/proof` | Protect → Guard → Decide → Extract → Verify | Protect changes the note History keeps. Decide's specific-completion gate and Extract's evidence span still apply; Verify vetoes a note only when a claim clearly conflicts with the planned task, and supplies the short follow-up reason. |

Measured against the real Clocked API, sequentially, 2026-10-25
(`server/scripts/measure.py`; see `server/README.md` for the full table and
method):

| Route | Samples | Credits/call, mean (range) | p50 latency | p95 latency |
| --- | ---: | ---: | ---: | ---: |
| `/v1/plan` | 10 | 5.30 (4–11) | 274 ms | 858 ms |
| `/v1/unlock` | 25 | 4.76 (4–7) | 260 ms | 344 ms |

The current five-step `/v1/proof` pipeline has one sanitized real sample:
**10 credits and 900 ms** client-observed round trip. It has not been through
the same 10+ sample latency sweep yet. The added Protect step was also seen
at 65–72 ms inside two real pipelines; see `server/README.md` for the exact
measurement scope and credit budget.

## Architecture

```mermaid
flowchart LR
    subgraph Phone["Android phone"]
        UI["Flutter UI & local controller\n(lib/app, lib/core)"]
        Store["Local store\nplans · grants · history · proof\n(SharedPreferences)"]
        Kotlin["Kotlin platform channel\n(MainActivity, GentleInterceptService,\nQuietNotificationListenerService)"]
    end

    Android["Android OS\nHome role · LauncherApps shortcuts ·\nUsageEvents · NotificationListener"]

    subgraph Backend["Curre backend (FastAPI, stateless)"]
        Routes["/v1/plan · /v1/unlock · /v1/proof\n/healthz"]
    end

    Clocked["Clocked API\nFill · Extract · Decide · Guard · Protect · Verify"]

    UI <--> Store
    UI <--> Kotlin
    Kotlin <--> Android
    UI -- "HTTPS, X-App-Key" --> Routes
    Routes -- "one pipeline() call per route" --> Clocked
```

The backend is the only thing that holds the Clocked API key — a key inside
the APK could be extracted, so the phone never calls Clocked directly.

## Privacy

Curre's own backend stores no plan, reason, or note text; it logs route,
status, latency, and credits only. Clocked, the processor that judges that
text, documents that it retains successful response bodies for idempotent
retries and clears them on a scheduled maintenance window after they're
older than 24 hours; usage/account records persist longer. ([Clocked
security page](https://clocked.rezolve.ai/security), read 2026-10-26.) All
of Curre's own plans, grants, attempts, and proof notes live only on the
phone in local storage, age out automatically, and clear with History —
but that local storage is not encrypted, so it isn't protected against a
compromised or backed-up device.

Before a judged unlock reason or proof note is written to History, Protect's
source spans replace names, phone numbers, email addresses, addresses, card
numbers and bank-account numbers with visible placeholders such as `[name]`
and `[phone]`. The gate and completion sheet keep using the original words.
If Protect does not answer, Curre keeps the words as typed and shows no false
privacy marker.

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
