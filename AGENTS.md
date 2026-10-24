# Project agent memory

This file is the project's committed home for project-intrinsic agent knowledge: build, test, release, architecture, and sharp-edge notes that should travel with the code.

- The Android launcher channel contract lives in
  `android/app/src/main/kotlin/com/mitech/curre/MainActivity.kt`; its Dart
  adapter and pure door-order policy live in `lib/doors/`.
- The permanent Android namespace and application ID are `com.mitech.curre`.
- Screen-facing notification, speech-input and Home-refresh plumbing lives in
  `lib/platform/`.
- Validate Flutter changes with `flutter analyze` and `flutter test`.
- The backend (`/v1/plan`, `/v1/unlock` over one `clocked-sdk` Pipeline call
  each) lives in `server/`; see `server/README.md` for setup, tests and the
  endpoint map. Validate backend changes with `server/.venv`'s `pytest` and
  `ruff check server`.
- Phone-owned models, sessions, visibility, grants, the typed backend client
  and local persistence live in `lib/core/`; its client reads
  `CURRE_API_BASE_URL` and `CURRE_APP_KEY` from `--dart-define`.
- clocked-sdk 0.7.0 response shapes are easy to get wrong: Decide answers
  are under `result["answers"]` (a `choice` answer's label is `["choice"]`,
  a `multiselect` answer's labels are `["selected"]`); Fill and Extract
  answers are both under `result["fields"]`, where a Fill `choice` or
  `multiselect` field's chosen value(s) are `["value"]` instead. See the
  module docstring in `server/app/clocked_pipeline.py` for the full set.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
