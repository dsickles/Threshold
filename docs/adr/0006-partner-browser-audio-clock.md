---
status: accepted
date: 2026-10-18
supersedes: the Partner's timing method in game-architecture 4.4 (Godot's mix clock) for the web build
---

# The Partner times taps with the browser's audio clock on the web

In the web build, the Partner plays its music through the browser's own audio system (Web Audio, reached from GDScript with Godot's built-in `JavaScriptBridge`) and times each tap from the touch event's own timestamp against the browser's record of what the speaker is playing. It no longer uses Godot's `get_playback_position() + get_time_since_last_mix() - get_output_latency()`.

The M0 rhythm check (DAS-68, [playtest note](../playtests/2026-10-17-m0-rhythm.md)) compared both on an iPhone 17 Pro in Safari. Godot's clock needed about −150 ms and its average slid one way while Dan tapped on the beat, which no fixed adjustment can fix. The browser clock needed about −70 ms, kept 19–20 of 20 taps within the placeholder Good window, and its average wandered (20 ms early in one run, 47 ms early in the next) rather than sliding.

## Consequences

- Neither clock met the 30 ms bar on one fixed adjustment, so the "tap along to calibrate" step (decision-history 14) stays in v1 and sets the remaining offset per device.
- The browser clock exists only in the web build. Native builds (PC/Steam, later) use Godot's clock, which held steady in laptop Chrome; the Conductor hides which clock is in use from the rest of the chapter.
- Browsers only start audio inside a real touch handler, so the Partner's page script unlocks and timestamps touches itself, as the M0 check does.
- No new addon or library: `JavaScriptBridge` ships with Godot.
- Revisit once the Partner is playable: compare both clocks on the iPhone in the real chapter. The comparison here is thin, since the Godot-clock run on the iPhone has no tap numbers. Because the Conductor hides the clock, switching is a change to one file.
