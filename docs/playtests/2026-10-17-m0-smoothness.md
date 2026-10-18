# M0 Check 1: phone smoothness (DAS-67)

The bar is the iPhone headroom bar in [../scope.md](../scope.md), "Settled questions". Rename this file to the day of the phone test if it isn't 2026-10-17.

## First step: does the browser build allow the 4× setting?

Yes. The heavy switch draws the 3D room at twice the screen's width and height (Godot's 3D resolution scale set to 2.0), which is 4× the pixels. A small square near the top of the screen proves it: gray when off, green only when the 3D picture really is twice the screen's width. Checked in Chrome on the laptop (local build, 2026-10-17). **Confirm the square turns green on the iPhone too**; if it stays gray there, the switch is not doing its job on Safari.

## How the numbers are measured

- **FPS:** frames drawn per second. "Average" is over the current run.
- **Worst frame / hitches:** the slowest single frame, and how many frames took over 25 ms (one missed frame at 60 fps). The first 2 seconds of a run are not counted (shaders get built then).
- **Game work:** Godot's built-in process timer (the game's own work in a frame). Godot updates it once a second, so the readout is sampled once a second. In the laptop preview this number rose with Heavy on, so it may include some waiting on the graphics card. The 4 ms bar is judged with Heavy off.
- **Memory:** Godot's own memory in the page plus its graphics memory. Safari's own overhead is not included, so treat it as a floor, not the whole picture.
- **Load:** seconds from opening the game page to the engine starting. For a fair number, use a private tab so nothing is cached.
- Turning Heavy on or off starts a new run (the timer goes back to 0:00).

## Results

To fill in after the test. Device, browser, and the numbers at 2:00.

| Bar | iPhone 17 Pro, Safari, Heavy off | iPhone 17 Pro, Safari, Heavy on | Laptop Chrome |
|---|---|---|---|
| Steady 60 fps for 2 min (avg FPS, hitches) | | | |
| Game work ≤ 4 ms average | | (not judged) | |
| Heavy still about 60 fps | (n/a) | | (n/a) |
| Memory under about 500 MB | | | |
| Load under about 10 s on home Wi‑Fi | | (n/a) | |
| Proof square green with Heavy on | (n/a) | | |
| Visible stutter? | | | |

## Dan's verdict

To fill in.

## If a bar fails

Stop and record which one here. Don't loosen the bar; the fix gets decided with Dan.
