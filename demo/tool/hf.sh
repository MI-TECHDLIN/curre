#!/usr/bin/env bash
# Runs the pinned HyperFrames CLI (0.9.11) on demo/motion, with npm's cache
# kept in demo/.cache so nothing is written outside the checkout.
#   demo/tool/hf.sh render          render the picture to $FILM_OUT/curre-demo-picture.mp4
#   demo/tool/hf.sh <any command>   e.g. check --json, snapshot --at 12,40
set -euo pipefail
demo="$(cd "$(dirname "$0")/.." && pwd)"
out="${FILM_OUT:-/tmp/curre-film}"
export npm_config_cache="$demo/.cache/npm"
cd "$demo/motion"
[[ -x node_modules/.bin/hyperframes ]] || npm install --no-audit --no-fund --silent
if [[ ${1:-} == render ]]; then
  shift
  exec node_modules/.bin/hyperframes render . -o "$out/curre-demo-picture.mp4" --quality high --workers 2 "$@"
fi
exec node_modules/.bin/hyperframes "$@"
