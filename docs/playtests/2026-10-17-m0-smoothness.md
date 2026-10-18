# M0 Check 1: phone smoothness (DAS-67)

The bar is the iPhone headroom bar in [../scope.md](../scope.md), "Settled questions". Rename this file to the day of the phone test if it isn't 2026-10-17.

## First step: does the browser build allow the 4× setting?

Yes. The heavy switch draws the 3D room at twice the screen's width and height (Godot's 3D resolution scale set to 2.0), which is 4× the pixels. A small square near the top of the screen proves it: gray when off, green only when the 3D picture really is twice the screen's width. Checked in Chrome on the laptop (local build, 2026-10-17). **Confirm the square turns green on the iPhone too**; if it stays gray there, the switch is not doing its job on Safari.

## How the numbers are measured

Hold the phone sideways. The buttons are sized for a sideways phone (about 60 px tall); held upright they shrink below 44 px.

- **The first 2 seconds of each run are not counted** in any average, the worst frame or hitches (shaders get built then).
- **FPS:** frames drawn per second. "Average" is over the current run.
- **Worst frame / hitches:** the slowest single frame, and how many frames took over 25 ms (one missed frame at 60 fps), timed with the real clock.
- **Game work** (judged against the 4 ms bar): the real average, every frame, of the time from the start of Godot's per-frame update (physics first, then everything else) to just before drawing. The check's own readout runs after drawing, so it is not counted. Changed after the first phone test (2026-10-18), because the first version averaged each second's *slowest* frame and timed the readout too.
- **Godot's timer** (for reference, not judged): Godot's built-in process timer. It reports the slowest frame of each second and also covers some of Godot's own housekeeping, so it reads higher than Game work.
- **Shadow switch** (test-only): turns the lamp's shadow off, to see how much of the drawing cost is the shadow.
- **Memory:** the memory the page has set aside for Godot (it only grows, never shrinks) plus Godot's graphics memory. Safari's own overhead is not included, so it is a rough figure, not the whole picture.
- **Load:** seconds from opening the game page to the engine starting. For a fair number, use a private tab so nothing is cached.
- Turning Heavy or Shadow on or off starts a new run (the timer goes back to 0:00).

## Results

Tested 2026-10-18 from the itch.io build. Numbers at 2:00.

| Bar | iPhone 17 Pro, Safari, Heavy off | iPhone 17 Pro, Safari, Heavy on | Desktop Chrome (stands in for laptop) |
|---|---|---|---|
| Steady 60 fps for 2 min | **Pass**: 59.9 average (worst frame and hitches not noted) | 55.3 average, worst frame 26 ms, 1 hitch | 60 fps (other numbers not noted) |
| Game work ≤ 4 ms average | **Fail as shown**: 4.3 ms | 3.84 ms (not judged) | not noted |
| Heavy still about 60 fps | (n/a) | **Near miss**: 55.3, about 8% under 60 | (n/a) |
| Memory under about 500 MB | **Pass**: 70 MB | **Pass**: 130 MB | not noted |
| Load under about 10 s on home Wi‑Fi | **Pass**: 1.2 s | 1.2 s | not noted |
| Proof square green with Heavy on | (n/a) | not noted (3D drawn at 4500 x 1752, 2x the 2250 x 876 of Heavy off) | |
| Visible stutter? | None seen | not noted | not noted |

### Why game work reads over the bar

Heavy on (more drawing) read *lower* than Heavy off, 3.84 against 4.3 ms. That points at the measurement, not the room. The number is each second's slowest frame, not a true average. And the check's own readout (rebuilding the text panel and asking the browser for memory, four times a second) runs inside the very work being timed, so the slowest frame of every second is probably the one where the readout updates. The room itself does almost nothing per frame.

### Re-test (new game-work timing and shadow switch)

To fill in. Numbers at 2:00 on the iPhone 17 Pro, Safari.

| Run | FPS average | Worst frame, hitches | Game work average | Godot's timer |
|---|---|---|---|---|
| Heavy off, shadow on | | | | |
| Heavy on, shadow on | | | | |
| Heavy on, shadow off | | | | |

If Heavy with the shadow off holds about 60 fps, the shadow is the cost and a cheaper shadow is the fix. If not, the cost is the pixel count, and drawing the 3D a little less sharp on slower phones is a scope decision for Dan.

## Dan's verdict

To fill in.

## If a bar fails

Stop and record which one here. Don't loosen the bar; the fix gets decided with Dan.
