#!/usr/bin/env bash
# PreToolUse hook for Bash: in cloud threads, installs Godot (tools/godot-setup.sh)
# right before the first command that runs it, so threads that only edit text
# never pay for the download. Adds the web export templates when the command
# exports. Does nothing on Dan's PC, which uses the Godot in DASSoft\Tools.
[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0

cmd="$(jq -r '.tool_input.command // empty' 2>/dev/null)" || exit 0

# Godot in command position (godot, "$GODOT", .../Godot_v4...), so the word in
# a grep, a file name or a commit message doesn't trigger the download.
starts='(^|[;&|(`]|\bthen|\bdo)[[:space:]]*((exec|time|timeout [0-9]+[a-z]?|[A-Za-z_]+=[^[:space:]]*)[[:space:]]+)*'
godot='(godot|"?\$\{?GODOT\}?"?|[^[:space:]]*Godot_v[^[:space:]]*)([[:space:]]|$)'
grep -qE "$starts$godot" <<< "$cmd" || exit 0

args=()
grep -q -- '--export' <<< "$cmd" && args+=(--templates)

if ! out="$(bash "$CLAUDE_PROJECT_DIR/tools/godot-setup.sh" "${args[@]}" 2>&1)"; then
    echo "Godot setup failed, so this command was not run:" >&2
    echo "$out" >&2
    echo "Check that the environment allows downloads from github.com." >&2
    exit 2
fi
[ -n "$out" ] && echo "$out" >&2
exit 0
