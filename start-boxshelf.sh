#!/usr/bin/env bash
# Start Boxshelf on Linux. The .bat files in this folder are for Windows.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  echo "Boxshelf needs Node.js and npm." >&2
  exit 1
fi
if ! command -v unzip >/dev/null 2>&1; then
  echo "Boxshelf needs unzip (to unpack Electron)." >&2
  exit 1
fi

if [[ ! -d node_modules/electron ]]; then
  echo "Installing Boxshelf the first time. This takes a minute..."
  npm install --no-audit --no-fund
  npm install-scripts approve electron >/dev/null 2>&1 || true
fi

electron=node_modules/electron/dist/electron
if [[ ! -x "$electron" ]]; then
  echo "Unpacking Electron..."
  zip=$(node --input-type=commonjs -e '
    const { downloadArtifact } = require("@electron/get");
    const { version } = require("./node_modules/electron/package.json");
    downloadArtifact({
      version,
      artifactName: "electron",
      platform: process.platform,
      arch: process.arch,
      checksums: require("./node_modules/electron/checksums.json"),
    }).then((p) => process.stdout.write(p)).catch((e) => { console.error(e); process.exit(1); });
  ')
  rm -rf node_modules/electron/dist
  mkdir -p node_modules/electron/dist
  unzip -q -o "$zip" -d node_modules/electron/dist
  printf 'electron' > node_modules/electron/path.txt
  chmod +x "$electron"
fi

args=()
if [[ "${1:-}" == "--windowed" || "${1:-}" == "window" ]]; then
  args+=(--windowed)
fi
exec "$electron" . "${args[@]}"
