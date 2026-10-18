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

2026-10-18, iPhone 17 Pro, Safari, itch.io build. Numbers at 2:00.

| Run | FPS average | Worst frame, hitches | Game work average | Godot's timer | Memory | Load |
|---|---|---|---|---|---|---|
| Heavy off, shadow on | 60 | 210 ms, 3 hitches | **0.25 ms (pass)** | 4.03 ms | 70 MB | 0.5 s |
| Heavy on, shadow on | **60.1 (pass)** | 23 ms, hitches not noted | 0.17 ms | 3.22 ms | 130 MB | 0.5 s |
| Heavy on, shadow off | 54.2 | 23,873 ms, 12 hitches | not noted | not noted | | |
| Heavy on, shadow on (third Heavy run) | **51.8 (fail)** | 180 ms, 27 hitches | 0.17 ms | 4.34 ms | 153 MB | 0.2 s |

- **Game work** passes easily: 0.25 ms against a 4 ms bar. The first test's 4.3 ms was the measuring method, not the room.
- **Heavy** held 60.1 fps with the shadow on, so the shadow is not the problem. But the first test gave 55.3 fps on the same setting, so the two Heavy runs disagree.
- **Heavy, shadow off** doesn't count: a 23.9-second frame means the game was paused (the tab or app was left, or the screen locked) during the run.
- **Heavy off** had one 210 ms frame. That is long enough to see as a jump, if it wasn't a pause too.
- **Third Heavy run** (2026-10-18, held sideways for most of the run; turned upright only for the screenshot at the end, so it ends showing 3D drawn at 2412 x 4284): 51.8 fps, well under 60. The three Heavy runs read 55.3, 60.1 and 51.8. Game work stays tiny, so the cost is all in drawing pixels, and the spread between runs looks like the phone warming up or background work rather than the game.

## Dan's verdict

Decided with Dan in the project thread, 2026-10-18.

- **Passes:** steady 60 fps with Heavy off, game work (0.25 ms against 4 ms), memory, load, and the proof square turning green on the iPhone.
- **Fails: Heavy still about 60 fps.** Three runs gave 55.3, 60.1 and 51.8 fps. The bar is not loosened.
- **Known fix, not built in M0:** the quality setting already in v1 (see [../scope.md](../scope.md)) lowers how many pixels the 3D view draws on slower phones, which is exactly the load Heavy adds. The mid-range Android spot check before M1 playtests decides whether a real slower phone needs it.
- M0 Check 1 is done; no more Heavy re-runs.

## If a bar fails

Stop and record which one here. Don't loosen the bar; the fix gets decided with Dan.
