# Browser tests

These play the exported web build in Chromium, the way a player would, and
fail if something only the browser shows is broken: the page not loading,
console errors, sound not starting after the first tap, or a screen that
won't open or go back. They run at three sizes: laptop (1280×720), phone
(393×852, touch) and sideways phone (852×393, touch).

They complement Dan's own tests on his iPhone; they never replace them.
Chromium is not Safari, and headless Chromium has no speaker, so timing,
feel and real sound are still checked by playing.

## Running them

```bash
bash tools/publish.sh          # from the repo root: exports build/web/
cd tests/web
npm ci                         # first time only
npx playwright install chromium  # first time only (not in Claude cloud threads; Chromium is already there)
npx playwright test
```

Screenshots of each screen land in `tests/web/test-results/<test>/`, and the
full report (with screenshots and, on failure, a trace) in
`tests/web/playwright-report/`. In CI each size runs as its own job, and both
are its "browser-test-results-<size>" download on the run's page
(`.github/workflows/browser-tests.yml`).

## How they see inside the game

Godot draws everything on one canvas, so the page has no buttons to find. A
small autoload, `game/_core/test_probe/web_test_probe.gd`, fixes that. It only
runs in a web build opened with `?probe` in the address (players never get
it), and each frame it writes to `window.thresholdProbe`:

- `scene`: the current scene's file path
- `overlays`: screens opened on top of it (like the Rhythm check over the menu)
- `buttons`: every visible button, with its text, centre and whether it is disabled
- `progress`: the finished-chapter list (`finished`) and whether the last save was kept (`saveOk`)

Adding `&finish=partner` (or `&finish=partner:vulnerable`) to the address
records that chapter as finished when the game starts, so a test can make a
save without playing the chapter: `game.open("&finish=partner")`. Each test
starts with empty browser storage, so saves never leak between tests.

The helpers in `specs/game.ts` use it:

| Helper | Does |
|---|---|
| `game.open()` | Loads `index.html?probe` and waits for the first scene |
| `game.tap("Text")` | Waits for an enabled button whose text starts with "Text", then taps it (touch on phone sizes, click on laptop) |
| `game.waitForScene(path, overlays)` | Waits until that scene (and those overlays) is showing |
| `game.findButton("Text")` | Waits for a button and returns it |
| `game.audioStates()` | The state of each audio context on the page (`"running"` means sound is on) |
| `game.screenshot("name")` | Saves a named screenshot to the results and report |

Every test also fails on any console error or uncaught page error.

Headless Chromium lets sound play before any tap, so the helpers apply the
phone rule themselves: audio starts paused and only resumes after a real tap.

## Adding a test

1. Put it in `specs/` as `<name>.spec.ts` (one file per chapter or screen,
   for example `partner.spec.ts`). Import `test`, `expect` and the scene paths
   from `./game`; add new scene paths there.
2. Start from `game.open()` (or the `beforeEach` in `m0.spec.ts`), tap through
   with `game.tap(...)`, check with `game.waitForScene(...)` and
   `game.findButton(...)`, and take a `game.screenshot(...)` of each screen.
3. If a test needs to see something the probe doesn't report, add it to
   `web_test_probe.gd` rather than guessing at pixel positions.
4. Export, run the tests, and look at the screenshots before opening the PR.

Never skip, disable or loosen a test to get green; fix the game or the test.
