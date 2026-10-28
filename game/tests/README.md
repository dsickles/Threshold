# Tests

Headless gameplay and logic tests. They run without a window, sound or a
person, in a few seconds, and in every PR check (`.github/workflows/check.yml`
runs `tools/publish.sh`, which runs `tools/test.sh`). Nothing in this folder is
exported to the web build (`exclude_filter="tests/*"` in `export_presets.cfg`).

There is no test addon. `run_tests.gd` is a small runner and `test_case.gd` is
the base every test file extends. Which addon to use for the core table and
saves is still decided in M1 (see `docs/scope.md`).

## Running them

| Where | Command |
|---|---|
| Cloud thread or CI | `bash tools/test.sh` (run `bash tools/publish.sh` once first to install Godot) |
| Dan's PC | `powershell -ExecutionPolicy Bypass -File tools/test.ps1` |
| Only some tests | add a word: `bash tools/test.sh rhythm` runs tests whose file or name contains "rhythm" |

Each test prints `ok` or `FAIL` with what went wrong. The run fails if any
check fails **or any script error is printed** while a test runs, so a crash
in game code fails the test that caused it.

## Adding tests

1. Make `game/tests/test_<thing>.gd` (one file per scene or system; use the
   words in `GLOSSARY.md`). It must start with `extends TestCase`.
2. Add methods named `test_<what should happen>`, written as a sentence, for
   example `test_tapping_a_ring_glides_to_its_view`. Each method gets a fresh
   copy of the file, so tests can't affect each other.
3. Open the scene with `add_scene(preload("res://..."))`. It is freed after
   the test.
4. Act like a player: `tap(button)` sends a real press and release at the
   middle of the control, so it only lands if the control is visible, enabled
   and not covered. `set_screen(Vector2i(390, 844))` checks a phone held
   upright (the runner resets to 1280 x 720 before each test).
5. Check with `check(ok, "what")`, `check_eq(actual, expected, "what")` or
   `check_near(actual, expected, tolerance, "what")`. Checks don't stop the
   test, so one run shows every failure.
6. `await frames()` waits a frame, for layout, scene changes and
   `queue_free`. For tweens and timers, step them yourself (for example
   `tween.custom_step(seconds)`) rather than waiting real time.
7. For audio or anything timed, give the scene a fake clock instead of real
   sound (as `test_partner.gd` does). Sound timing on a real phone is
   still Dan's to check.
8. Run `bash tools/test.sh` and make sure the new test fails if you break the
   thing it checks, then passes again.

A test that checks bad input is reported can call `expect_error("text")`
first: an error containing that text then doesn't fail the test, and the test
fails if it is never printed.

Tests may read a scene's private variables (`_current`, `_raw_offsets`) when
that is the clearest way to check a rule, but prefer what a player would see:
labels, buttons, the camera.

Never skip, disable or loosen a test to get a PR green. If a test is wrong,
fix the test and say why in the PR.

## Older stand-alone checks

A file named `*_check.gd` here that is not `test_*` is a stand-alone SceneTree
script. `tools/test.sh` and
`tools/test.ps1` run each one too and fail if it exits non-zero. New tests
should be `test_*.gd` files instead; a stand-alone check can be moved over
whenever its owner next touches it.

## What is covered

| File | Covers |
|---|---|
| `test_chapter_runner.gd` | The chapter result shape and JSON round trip, story order, entering hides and pauses the House, finishing brings it back with the result (and answer), leaving gives no result, one result per chapter, a chapter that emits the wrong thing still returns the House, House values must be plain JSON, one chapter at a time, the menu's stand-in chapter, 44px buttons on phone screens, every chapter has a clock for the playtest overlay |
| `test_game_state.gd` | Progress and saves: finishing a chapter saves it, the next visit reads it back, story order kept, House state saved with its chapter, out-of-order, repeated, test-only and malformed results refused (including House values that aren't plain JSON), broken or impossible saves start fresh, a save that can't be written (including private browsing) is reported, keeps the old save and lets play carry on, hiding or closing never saves, starting new deletes the save, the chapter runner's finished chapters are saved, the opening beat's answer is held in memory, not saved before the Partner, saved with the Partner's result and forgotten (so it plays again) if the player leaves first |
| `test_house_table.gd` | The core table for M1: which story point a finished-chapter list is at; each of the four points gives the right mood, open rooms, boxed and shut doors, arrival room and chapter object (and that object starts the next chapter); the living room, kitchen and entry are always open and the hall bathroom always shut; every open room can be reached and nothing else, the living room can be reached from every open room, the spare room by no route after the Loss; every House object is in an open room; the 18 House object entries (13 things) and their states at each point |
| `test_house.gd` | The gray-box House (DAS-93): every M1 room built, furniture in the room the floor plan puts it, only rings can be tapped, the 18 views (the 17 M1 views plus the end of the back hall), each view's rings (every doorway in its room, its other wall views, and from a wall view the way back to the room's doorway view), every ring leads to the view it names, rings on screen, 44px and apart from every view on laptop and phone screens, off-screen rings pin to the edge with an arrow, starts on the porch, 2.0 s glide, glides through doorways never pass through a wall or back up, an open door swings out of the view through it, doors are real door sizes and fit their wall openings, rings hide during a glide and come back on arrival, a short look-drag, keys and hover do nothing, reachability at the start and with the hall open, shut and boxed doors can't be gone through, door states and the arrival room come from the core table at every story point (and the player's own point when none is set), the House's doors and rooms are the core table's, turning the phone places rings right straight away, ring kinds and labels, an unknown story point is reported, lamp light and ordinary fog only |
| `test_m0_menu.gd` | Tap to begin, button sizes, each M0 check (including UI style) opens and Back returns, and the House buttons open the House at their story point |
| `test_ui_theme.gd` | The shared UI theme (DAS-72): it is the project theme and no screen carries its own, font sizes are DESIGN.md's scale × 720/402 and come out at those sizes on a sideways iPhone 17 Pro, button-primary (gold fill, dark label, slightly darker when pressed) and button-quiet (outline, light label, muted when off), hover looks the same as resting, a plain button is at least 44 points on the phone, the UI style check fits laptop and phone screens and Back returns |
| `test_smoothness_check.gd` | Warmup, hitch and worst-frame counting, the 2-minute run, Heavy and Shadow switches, Back |
| `test_rhythm_check.gd` | Tap pad only while the click plays, last 20 taps, offset to the nearest click, average, spread and Good count, sound delay re-scoring and limits, Clear, 44px buttons on phone screens, every chapter has a clock for the playtest overlay |
| `test_partner.gd` | The Partner on a fake clock: first tap starts the song, no taps and all-early taps reach the test and report finished, Perfect on the note, stray taps do nothing, late-arriving taps inside the window still hit, intro taps set the sound delay, no laughs in the intro, hidden tab pauses and the resume tap isn't judged, the menu opens it and takes it back, the judgement sits below the heart, the chart is Dan's plan from his own taps, 200 notes at 90 BPM on the track's eighths (25 ms after its bar lines), at least an eighth apart with some between the beats and 51 in the 12-bar crescendo, more than any other 12 bars, lights fall from the top to the heart, one stray intro tap does not set the sound delay, the test holds then waits for a tap, a streak warms the screen and turns up the song's layer and a miss lets it settle back, each streak of 8 brings in the next moment of their life (all 12 on a perfect or typical run, 8 s or more apart, on screen and clear of the hearts), the Conductor reads a browser true (1) as true, and a modelled first-time player (taps 40 ms late, give or take 60 ms) misses fewer than 5 notes a run |
| `test_protector.gd` | The Protector's run (DAS-97) on its own clock, as revised after each of Dan's plays (calls 13 to 21): the 31 obstacles match the design (9/10/12, the euphoria's on the beat, none after 2:05, shapes and lanes in order), every one can be avoided (a lane always free, a lane free through each panic cluster and 2 s between clusters, every gap bridgeable with at least 1 s), the same list, path and trees every time, no words or buttons on screen all run but the hints, "tap here" on both halves until the second stone and "hold" for the first two gaps only, the song from 0:03 and the storm on to the black, a perfect run and an empty run reach the same fade at the same moment with the light equally bright at 2:08, stop at the fallen tree in the same place with no stumble there, and finish once, a tap on the left or right moves the light one lane that way (two taps, two lanes; an edge tap only ripples), the father's hand moves it, a tap that changes nothing only ripples, a tap with a gap in reach only moves the lane, a hold with a gap in reach lays the hand across exactly that gap (and a hold from before the gap is in reach lays it when it is), letting go before the gap lifts the hand and the light stumbles, every gap can be bridged at the edge of its reach, a perfect one-finger run gets past all 31, the lane tapped counts even mid-move, a stumble never changes the light's speed, place or lane and it is fully bright within a second, the light starts as small as a seed and grows, after the song taps still move it until it slows at 2:20, it stops right against a fallen tree wider than the path and taller than the light that nothing gets past, the hand comes under it only once it has stopped, and it goes out there, the rain never stops and nothing gets lighter after the panic, the euphoria's low gold sun and trees, the trees bend in the storm, hiding the tab pauses it and saves nothing, leaving mid-run saves nothing and the next visit starts at the lamp, it finishes once with no answer and is saved then, the menu opens it and takes it back, no CompositorEffects or volumetric fog, three lanes that give way only behind the light, one of everything drawn behind the black first so nothing stutters the first time it appears, fireflies between the trees thin out in the storm and the last ones go out at uneven moments once the path is empty, some outlasting the light, a gap's edges showing through the dark faintly from 3 s out and brightly in reach, branches ending just past their second lane's middle, the first rain faint and thickening |
| `test_viewpoints_check.gd` | Start in the doorway, tap a ring to glide to its view, changing mind mid-glide, glide time and its limits, rings on screen, 44px and not overlapping on laptop and phone screens from every viewpoint, Back |
