#!/usr/bin/env bash
# Cloud (Linux) version of check.ps1 + publish.ps1, for Claude threads.
# Installs Godot 4.7.2, its web export templates and butler if missing
# (via tools/godot-setup.sh), error-checks every script, runs the tests
# (tools/test.sh), exports the "Web" preset to build/web/, and uploads to
# itch.io only when run with --upload (after Dan says "upload").
#
#   bash tools/publish.sh            # install, check, test, export
#   bash tools/publish.sh --upload   # ...and push to dsickles/threshold:html5
#
# Needs: network access to github.com and broth.itch.zone / itch.io,
# and BUTLER_API_KEY set in the environment for --upload.
set -euo pipefail

ITCH_TARGET="dsickles/threshold:html5"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="$REPO_DIR/game"
OUT_DIR="$REPO_DIR/build/web"

upload=false
[ "${1:-}" = "--upload" ] && upload=true

# Install whatever is missing; this also sets $GODOT and $BUTLER.
setup_args=(--templates)
$upload && setup_args+=(--butler)
source "$REPO_DIR/tools/godot-setup.sh" "${setup_args[@]}"

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

# Headless gameplay and logic tests (game/tests/).
GODOT="$GODOT" bash "$REPO_DIR/tools/test.sh"

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
