#!/usr/bin/env bash
# Speaks demo/narration.json with Kokoro (Apache-2.0 model, run offline) and
# places the lines on the film's timing table. Sets up a local venv and the
# int8 model (~120 MB) in demo/.cache/tts on first use.
#
#   demo/tool/voice.sh                     speak every line, then place them
#   demo/tool/voice.sh take TAKE.wav --starts STARTS.txt
#                                          use a recorded take instead
set -euo pipefail
demo="$(cd "$(dirname "$0")/.." && pwd)"
out="${FILM_OUT:-/tmp/curre-film}"
tts="$demo/.cache/tts"
if [[ ${1:-} == take || ${1:-} == place ]]; then
  mode="$1"; shift
  exec python3 -I "$demo/tool/voice.py" "$mode" "$out" "$@"
fi
if [[ ! -x $tts/venv/bin/python ]]; then
  mkdir -p "$tts"
  python3 -m venv --system-site-packages "$tts/venv"
  "$tts/venv/bin/pip" install -q kokoro-onnx==0.4.7 soundfile==0.14.0
fi
base=https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0
for f in kokoro-v1.0.int8.onnx voices-v1.0.bin; do
  [[ -s $tts/$f ]] || curl -fsSL -o "$tts/$f" "$base/$f"
done
exec "$tts/venv/bin/python" "$demo/tool/voice.py" speak "$out" "$@"
