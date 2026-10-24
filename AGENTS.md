# Project agent memory

This file is the project's committed home for project-intrinsic agent knowledge: build, test, release, architecture, and sharp-edge notes that should travel with the code.

- The Android launcher channel contract lives in
  `android/app/src/main/kotlin/com/example/curre/MainActivity.kt`; its Dart
  adapter and pure door-order policy live in `lib/doors/`.
- Keep the Android package as `com.example.curre` until the separate package
  naming decision is made.
- Validate Flutter changes with `flutter analyze` and `flutter test`.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
