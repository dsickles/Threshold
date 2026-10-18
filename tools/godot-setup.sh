#!/usr/bin/env bash
# Installs Godot 4.7.2 for cloud (Linux) Claude threads and CI, only if it is
# missing, and links it as "godot" in ~/.local/bin so any command can run it.
# Safe to run again and again: it does nothing once everything is there.
#
#   bash tools/godot-setup.sh               # Godot only (enough to run, check or test)
#   bash tools/godot-setup.sh --templates   # ...plus the web export templates
#   bash tools/godot-setup.sh --butler      # ...plus butler, for uploading to itch.io
#
# Scripts that need Godot source it, so they also get $GODOT, $BUTLER and the
# other paths below:  source "$REPO_DIR/tools/godot-setup.sh" --templates
# Text-only work never needs this. A Claude hook (.claude/hooks/godot-setup.sh)
# runs it automatically before any Bash command that calls Godot.
set -euo pipefail

GODOT_VERSION="4.7.2"
TOOLS_DIR="${THRESHOLD_TOOLS:-$HOME/.cache/threshold-tools}"
GODOT="${GODOT:-$TOOLS_DIR/Godot_v${GODOT_VERSION}-stable_linux.x86_64}"
BUTLER="${BUTLER:-$TOOLS_DIR/butler/butler}"
TEMPLATES_DIR="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
RELEASES="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable"

want_templates=false
want_butler=false
for arg in "$@"; do
    case "$arg" in
        --templates) want_templates=true ;;
        --butler) want_butler=true ;;
        *) echo "godot-setup.sh: unknown option $arg" >&2; exit 1 ;;
    esac
done

mkdir -p "$TOOLS_DIR"

if [ ! -x "$GODOT" ]; then
    echo "Installing Godot $GODOT_VERSION..."
    curl -sSfL -o "$TOOLS_DIR/godot.zip" "$RELEASES/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
    unzip -oq "$TOOLS_DIR/godot.zip" -d "$TOOLS_DIR"
    rm "$TOOLS_DIR/godot.zip"
    chmod +x "$GODOT"
fi

# ~/.local/bin is on PATH in the cloud containers, so plain "godot" works.
mkdir -p "$HOME/.local/bin"
[ "$(readlink "$HOME/.local/bin/godot" 2>/dev/null)" = "$GODOT" ] || ln -sf "$GODOT" "$HOME/.local/bin/godot"

if $want_templates && [ ! -f "$TEMPLATES_DIR/web_nothreads_release.zip" ]; then
    echo "Installing web export templates (large download)..."
    curl -sSfL -o "$TOOLS_DIR/templates.tpz" "$RELEASES/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
    mkdir -p "$TEMPLATES_DIR"
    # Only the web templates and version file; the rest is over 1 GB of other platforms.
    unzip -oqj "$TOOLS_DIR/templates.tpz" 'templates/web_*' 'templates/version.txt' -d "$TEMPLATES_DIR"
    rm "$TOOLS_DIR/templates.tpz"
fi

if $want_butler && [ ! -x "$BUTLER" ]; then
    echo "Installing butler..."
    curl -sSfL -o "$TOOLS_DIR/butler.zip" "https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default"
    unzip -oq "$TOOLS_DIR/butler.zip" -d "$TOOLS_DIR/butler"
    rm "$TOOLS_DIR/butler.zip"
    chmod +x "$BUTLER"
fi
