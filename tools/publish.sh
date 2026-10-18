#!/usr/bin/env bash
# Cloud (Linux) version of check.ps1 + publish.ps1, for Claude threads.
# Installs Godot 4.7.2, its web export templates and butler if missing,
# error-checks every script, exports the "Web" preset to build/web/,
# and uploads to itch.io only when run with --upload (after Dan says "upload").
#
#   bash tools/publish.sh            # install, check, export
#   bash tools/publish.sh --upload   # ...and push to dsickles/threshold:html5
#
# Needs: network access to github.com and broth.itch.zone / itch.io,
# and BUTLER_API_KEY set in the environment for --upload.
set -euo pipefail

GODOT_VERSION="4.7.2"
ITCH_TARGET="dsickles/threshold:html5"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="$REPO_DIR/game"
OUT_DIR="$REPO_DIR/build/web"
TOOLS_DIR="${THRESHOLD_TOOLS:-$HOME/.cache/threshold-tools}"
GODOT="${GODOT:-$TOOLS_DIR/Godot_v${GODOT_VERSION}-stable_linux.x86_64}"
BUTLER="${BUTLER:-$TOOLS_DIR/butler/butler}"
TEMPLATES_DIR="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
RELEASES="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable"

upload=false
[ "${1:-}" = "--upload" ] && upload=true

mkdir -p "$TOOLS_DIR"

if [ ! -x "$GODOT" ]; then
    echo "Installing Godot $GODOT_VERSION..."
    curl -sSfL -o "$TOOLS_DIR/godot.zip" "$RELEASES/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
    unzip -oq "$TOOLS_DIR/godot.zip" -d "$TOOLS_DIR"
    rm "$TOOLS_DIR/godot.zip"
    chmod +x "$GODOT"
fi

if [ ! -f "$TEMPLATES_DIR/web_nothreads_release.zip" ]; then
    echo "Installing web export templates (large download)..."
    curl -sSfL -o "$TOOLS_DIR/templates.tpz" "$RELEASES/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
    mkdir -p "$TEMPLATES_DIR"
    # Only the web templates and version file; the rest is over 1 GB of other platforms.
    unzip -oqj "$TOOLS_DIR/templates.tpz" 'templates/web_*' 'templates/version.txt' -d "$TEMPLATES_DIR"
    rm "$TOOLS_DIR/templates.tpz"
fi

if $upload && [ ! -x "$BUTLER" ]; then
    echo "Installing butler..."
    curl -sSfL -o "$TOOLS_DIR/butler.zip" "https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default"
    unzip -oq "$TOOLS_DIR/butler.zip" -d "$TOOLS_DIR/butler"
    rm "$TOOLS_DIR/butler.zip"
    chmod +x "$BUTLER"
fi

# Error check, same as check.ps1: import first, then check each script.
"$GODOT" --headless --path "$PROJECT_DIR" --import > /dev/null 2>&1 || { echo "Import failed."; exit 1; }
failed=0
while IFS= read -r file; do
    res="res://${file#"$PROJECT_DIR"/}"
    if output=$("$GODOT" --headless --path "$PROJECT_DIR" --check-only --script "$res" 2>&1) \
        && ! grep -qE 'SCRIPT ERROR|Parse Error' <<< "$output"; then
        echo "ok   $res"
    else
        echo "FAIL $res"
        echo "$output"
        failed=$((failed + 1))
    fi
done < <(find "$PROJECT_DIR" -name '*.gd' -not -path '*/.godot/*' | sort)
if [ "$failed" -gt 0 ]; then echo "$failed script(s) failed."; exit 1; fi
echo "All scripts passed."

# Headless checks with a fake clock (no test addon yet; that is chosen in M1).
if ! output=$("$GODOT" --headless --path "$PROJECT_DIR" --script res://tests/partner_ending_check.gd 2>&1); then
    echo "Partner ending check failed:"; echo "$output"; exit 1
fi
echo "Partner ending check passed."

# Export, outside game/ so Godot never imports the previous build.
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
"$GODOT" --headless --path "$PROJECT_DIR" --export-release "Web" "$OUT_DIR/index.html" > /dev/null 2>&1 || true
[ -f "$OUT_DIR/index.html" ] && [ -f "$OUT_DIR/index.pck" ] || { echo "Export failed."; exit 1; }
echo "Exported to build/web/."

if ! $upload; then
    echo "Not uploaded. Run with --upload once Dan says \"upload\"."
    exit 0
fi

[ -n "${BUTLER_API_KEY:-}" ] || { echo "BUTLER_API_KEY is not set."; exit 1; }
branch="$(git -C "$REPO_DIR" branch --show-current)"
version="${branch##*/}-$(git -C "$REPO_DIR" rev-parse --short HEAD)"
"$BUTLER" push "$OUT_DIR" "$ITCH_TARGET" --userversion "$version"
echo "Uploaded as version $version."
