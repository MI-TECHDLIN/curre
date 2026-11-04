# Demo film

Curre's 2:59 demo is rendered in code, not recorded on a phone. Widget tests
film the real app in this checkout frame by frame; HyperFrames composes those
phone shots with motion graphics; Kokoro speaks the narration offline; the
music and the few sound effects are synthesised in code. The shot list is in
[storyboard.md](storyboard.md), the words and their cues in
[narration.json](narration.json), scene lengths in
[motion/scenes.json](motion/scenes.json).

## Render it

Needs Flutter (`flutter` on PATH), ffmpeg, Python 3 with numpy, and Node 22+.
Output goes to `$FILM_OUT` (default `/tmp/curre-film`; about 0.5 GB while
rendering).

```bash
demo/tool/render.sh shots            # film the phone shots (~10 min)
demo/tool/render.sh voice            # Kokoro voiceover (~3 min; sets up its venv once)
demo/tool/render.sh motion           # build demo/motion/index.html and render the picture (~35 min)
demo/tool/render.sh mix              # music, effects, voice -> final mp4s
demo/tool/render.sh all              # all four, failing on any request without a live capture
demo/tool/render.sh preview [NAME]   # PNG stills every 0.5 s of one shot instead of video
```

Final files in `$FILM_OUT`: `curre-demo.mp4` (voiced, -16 LUFS),
`curre-demo-music-only.mp4` (-18 LUFS), `voice/curre-demo.srt` (captions),
`voice/voice-timing.json` (where every line lands).

## Swap in a new voice

The picture never moves for a new voice: each line is placed at its cue.

1. Record the 35 lines of `narration.json` in order in one file (any voice:
   your own, ElevenLabs, anything), leaving a short pause between lines.
2. Write `starts.txt`: one line per narration line, the second (or `m:ss.mmm`)
   where that line starts in your take. `start end` also works.
3. `demo/tool/voice.sh take take.wav --starts starts.txt` cuts the lines,
   trims their silence and places them; it stops and names any line that
   would run into the next (it fits a line by up to 1.15x first).
4. `demo/tool/render.sh mix` (no picture re-render needed).

To change words, edit `narration.json` (and `at`, the cue in seconds from its
scene's start) and run `demo/tool/render.sh voice` then `mix`. `say` respells
words for Kokoro only (Curre is said KOO-reh).

## How it works

- `film/shots_test.dart`: one widget test per shot, driving the real
  `CurreApp` with real taps, typing and scrolling. `film/director.dart`
  captures each frame of the 392×850 phone screen at 3× (1176×2550) and pipes
  it to ffmpeg, so camera zooms to 2.5× still show text drawn above delivery
  resolution. A JSON sidecar beside each clip records every tap and every
  named zoom target. `tool/film_engine.sh` (from the Pinne film) drops
  Flutter's boxy test font so the bundled Geologica, Newsreader and Atkinson
  Hyperlegible Mono render as on a phone.
- `film/world.dart`: the controller over the test fakes, with a clock that
  moves with the film, and Tobi's phone (apps, shortcuts, a WhatsApp and an
  Instagram conversation shortcut).
- `film/demo_server.dart`: answers the app's `/v1/plan`, `/v1/unlock`,
  `/v1/proof` and `/v1/later` calls from `film/fixtures/`, which are the
  deployed server's real answers to the exact requests the app makes in the
  film. Every request is logged to `$FILM_OUT/requests/`; `render.sh capture`
  (with `CURRE_APP_KEY_FILE` set to a file holding the app key) replays new
  ones against the deployed server once. The key is only ever sent as a
  header, never printed or saved.
- `tool/build_motion.py` writes `motion/index.html` (a HyperFrames
  composition, pinned to 0.9.11 in `motion/package.json`) from the scene table,
  the shot sidecars and the voice timing; `tool/hf.sh` runs the pinned CLI
  (`demo/tool/hf.sh check --json`, `snapshot --at 12,40`, `render`).
- Style follows the captain's motion-graphics guide (prompt 10, the SaaS
  promo), recoloured to Curre: a calm "Liquid Glass" stage of frosted cards
  and slow pastel blobs, kinetic type for the hook and section titles, the
  real screens as filmed with camera punch-ins on what matters and one short
  line each. Moves used: Rise, Pop, Count-up, Checklist tick, Typewriter,
  Slide-in, Punch-in, Reframe, Bar fill.
- Sound follows the guide's rule: ticks on checks, a counter while numbers
  roll, pops as the opening's notifications land, soft taps, a chime on the
  end card; no whooshes. `tool/make_music.py` (from the Pinne film) writes a
  sample-free pad that ducks under the voice.

## What is real and what is drawn

Every Curre screen is the real app from this checkout, and every verdict,
plan, proof judgement and ranking is the deployed server's real answer.
Earlier proof days, rest days, saved Later items and past "Why now?" moments
are seeded, since the film cannot live through two weeks; the notification
listener's held and given-back states are set on the fake gateway as the
Kotlin service reports them. The status bar, the video search the YouTube
door opens, the chat with Ada, the notification shade, the home-app list,
the touch dots and everything outside the phone are film drawings in
Curre's tokens, with no OS, handset or third-party branding.
