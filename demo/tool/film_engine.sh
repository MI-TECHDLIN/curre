#!/usr/bin/env bash
# Builds demo/.cache/engine: a "local engine" made of symlinks to the Flutter
# SDK's cached engine, whose flutter_tester drops --use-test-fonts.
#
# Why: `flutter test` always renders text with the blocky test font when a
# style names no font family. Some framework defaults name no family, so on a phone
# they use the system font (Roboto on Android). Without the flag, unnamed
# text resolves through the default family list, where film/fonts.dart has
# registered the SDK's own Roboto, as on a phone. Named fonts (Outfit, Plus
# Jakarta Sans, Material Icons) are unaffected.
set -euo pipefail

demo="$(cd "$(dirname "$0")/.." && pwd)"
flutter_root="$(cd "$(dirname "$(readlink -f "$(command -v flutter)")")/.." && pwd)"
cache="$flutter_root/bin/cache"
host="$cache/artifacts/engine/linux-x64"
out="$demo/.cache/engine/src/out/host_debug"

mkdir -p "$out/gen/dart-pkg"
ln -sfn "$cache/dart-sdk" "$out/dart-sdk"
ln -sfn "$cache/artifacts/engine/common/flutter_patched_sdk" "$out/flutter_patched_sdk"
ln -sfn "$cache/pkg/sky_engine" "$out/gen/dart-pkg/sky_engine"
for f in icudtl.dat isolate_snapshot.bin vm_isolate_snapshot.bin font-subset const_finder.dart.snapshot; do
  ln -sfn "$host/$f" "$out/$f"
done

rm -f "$out/flutter_tester"
cat > "$out/flutter_tester" <<SH
#!/usr/bin/env bash
args=()
for a in "\$@"; do [[ \$a == --use-test-fonts ]] || args+=("\$a"); done
exec "$host/flutter_tester" "\${args[@]}"
SH
chmod +x "$out/flutter_tester"
echo "$demo/.cache/engine/src"
