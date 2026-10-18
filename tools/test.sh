#!/usr/bin/env bash
# Runs the headless tests in game/tests/ with Godot 4.7.2 (Linux, for Claude
# threads and CI). tools/publish.sh runs this after the error check, so a
# failing test stops the export and the upload.
#
#   bash tools/test.sh            # every test
#   bash tools/test.sh rhythm     # only tests whose file or name contains "rhythm"
#
# Uses the Godot that tools/publish.sh installs (or $GODOT). Run publish.sh
# once first in a fresh container.
set -euo pipefail

GODOT_VERSION="4.7.2"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="$REPO_DIR/game"
TOOLS_DIR="${THRESHOLD_TOOLS:-$HOME/.cache/threshold-tools}"
GODOT="${GODOT:-$TOOLS_DIR/Godot_v${GODOT_VERSION}-stable_linux.x86_64}"
# A test that waits forever must not hang CI.
LIMIT_SECONDS=300

[ -x "$GODOT" ] || { echo "Godot not found at $GODOT. Run bash tools/publish.sh once first."; exit 1; }
"$GODOT" --headless --path "$PROJECT_DIR" --import > /dev/null 2>&1 || { echo "Import failed."; exit 1; }

failed=0
echo "Running tests in game/tests/..."
if ! timeout "$LIMIT_SECONDS" "$GODOT" --headless --path "$PROJECT_DIR" \
        --script res://tests/run_tests.gd -- "$@"; then
    failed=1
fi

# Older stand-alone checks (game/tests/*_check.gd not named test_*, each its
# own SceneTree script) run one by one. New tests should be test_*.gd files.
if [ "$#" -eq 0 ]; then
    while IFS= read -r file; do
        res="res://${file#"$PROJECT_DIR"/}"
        if output=$(timeout "$LIMIT_SECONDS" "$GODOT" --headless --path "$PROJECT_DIR" --script "$res" 2>&1); then
            echo "ok   $res"
        else
            echo "FAIL $res"
            echo "$output"
            failed=1
        fi
    done < <(find "$PROJECT_DIR/tests" -maxdepth 1 -name '*_check.gd' -not -name 'test_*' | sort)
fi

if [ "$failed" -ne 0 ]; then echo "Tests failed."; exit 1; fi
echo "All tests passed."
