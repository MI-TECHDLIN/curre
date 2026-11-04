#!/usr/bin/env bash
# Renders the Curre demo film from the real app code in this checkout.
#
#   demo/tool/render.sh shots [NAME]     film the phone shots (all, or one by
#                                        test name) into $FILM_OUT/clips
#   demo/tool/render.sh preview [NAME]   PNG stills every 0.5 s instead
#   demo/tool/render.sh capture          replay recorded requests against the
#                                        deployed server (needs CURRE_APP_KEY_FILE)
#   demo/tool/render.sh voice            draft the Kokoro voiceover
#   demo/tool/render.sh motion           build and render the HyperFrames film
#   demo/tool/render.sh mix              mix voice, music and effects; final mp4s
#   demo/tool/render.sh all              shots, voice, motion, mix
#
# Output goes to $FILM_OUT (default /tmp/curre-film; it is large).
set -euo pipefail

demo="$(cd "$(dirname "$0")/.." && pwd)"
repo="$(dirname "$demo")"
export FILM_OUT="${FILM_OUT:-/tmp/curre-film}"
ffmpeg="${FFMPEG:-$(command -v ffmpeg)}"
mkdir -p "$FILM_OUT"
step="${1:-all}"
shift || true

shots() {
  local preview="$1" name="${2:-}"
  local engine
  engine="$("$demo/tool/film_engine.sh")"
  cd "$repo"
  flutter test \
    --local-engine-src-path="$engine" --local-engine=host_debug --local-engine-host=host_debug \
    --concurrency=1 --reporter=expanded \
    --dart-define=FILM_ROOT="$demo" \
    --dart-define=FILM_OUT="$FILM_OUT" \
    --dart-define=FILM_FFMPEG="$ffmpeg" \
    --dart-define=FILM_PREVIEW="$preview" \
    --dart-define=FILM_DEBUG="${FILM_DEBUG:-false}" --dart-define=FILM_STRICT="${FILM_STRICT:-false}" \
    ${name:+--plain-name "$name"} \
    demo/film/shots_test.dart
}

case "$step" in
  shots) shots false "${1:-}" ;;
  preview) shots true "${1:-}" ;;
  capture) python3 -I "$demo/tool/capture_live.py" "$FILM_OUT" "$@" ;;
  voice) "$demo/tool/voice.sh" "$@" ;;
  motion) python3 -I "$demo/tool/build_motion.py" "$FILM_OUT" && "$demo/tool/hf.sh" render "$@" ;;
  mix) python3 -I "$demo/tool/mix.py" "$FILM_OUT" "$@" ;;
  all)
    FILM_STRICT=true shots false
    "$demo/tool/voice.sh"
    python3 -I "$demo/tool/build_motion.py" "$FILM_OUT"
    "$demo/tool/hf.sh" render
    python3 -I "$demo/tool/mix.py" "$FILM_OUT"
    ;;
  *) echo "unknown step: $step" >&2; exit 2 ;;
esac
