# Project agent memory

This file is the project's committed home for project-intrinsic agent knowledge: build, test, release, architecture, and sharp-edge notes that should travel with the code.

- The Android launcher channel contract lives in
  `android/app/src/main/kotlin/com/mitech/curre/MainActivity.kt`; its Dart
  adapter and pure door-order policy live in `lib/doors/`.
- The permanent Android namespace and application ID are `com.mitech.curre`.
- Screen-facing notification, speech-input and Home-refresh plumbing lives in
  `lib/platform/`.
- Validate Flutter changes with `flutter analyze` and `flutter test`.
- The design system (tokens, theme, widgets) lives in `lib/design/`; import
  `design/design.dart`. The debug gallery (`lib/gallery/`) renders every
  widget and preview screen in light and dark. Change a Curre text style's
  weight with `.weight(w)`: `copyWith(fontWeight:)` leaves the variable
  font's `wght` axis where it was.
- Ask for icons through `CurreGlyph` (`lib/design/widgets/curre_glyph.dart`),
  not `SolarIconsBold` directly: solar_icons 0.2.0's Bold font drops some
  inner cut-outs (question mark, info dot, warning shield, clock hands), and
  the mapping there uses only glyphs checked by eye.
- The backend (`/v1/plan`, `/v1/unlock` over one `clocked-sdk` Pipeline call
  each) lives in `server/`; see `server/README.md` for setup, tests and the
  endpoint map. Validate backend changes with `server/.venv`'s `pytest` and
  `ruff check server`.
- Phone-owned models, sessions, visibility, grants, the typed backend client
  and local persistence live in `lib/core/`; its client reads
  `CURRE_API_BASE_URL` and `CURRE_APP_KEY` from `--dart-define`.
- The check-in card's water is core `DayProgress` (`lib/core/progress.dart`),
  which counts `DoorUse`s: a screen that opens a plan's app must call
  `CurreLocalStore.recordDoorUse`, or the water never rises. Motion (Peek,
  `LiveSky`, `RisingWater`) belongs to the check-in and moments of choice,
  never Home, and must hold still under reduce-motion.
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
