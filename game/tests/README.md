# Tests

Headless gameplay and logic tests. They run without a window, sound or a
person, in a few seconds, and in every PR check (`.github/workflows/check.yml`
runs `tools/publish.sh`, which runs `tools/test.sh`). Nothing in this folder is
exported to the web build (`exclude_filter="tests/*"` in `export_presets.cfg`).

There is no test addon. `run_tests.gd` is a small runner and `test_case.gd` is
the base every test file extends. It also covers the core table and saves
(ADR-0007).

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
   sound (as the Partner's ending check does). Sound timing on a real phone is
   still Dan's to check.
8. Run `bash tools/test.sh` and make sure the new test fails if you break the
   thing it checks, then passes again.

Tests may read a scene's private variables (`_current`, `_raw_offsets`) when
that is the clearest way to check a rule, but prefer what a player would see:
labels, buttons, the camera.

Never skip, disable or loosen a test to get a PR green. If a test is wrong,
fix the test and say why in the PR.

## Older stand-alone checks

A file named `*_check.gd` here that is not `test_*` is a stand-alone SceneTree
script (for example the Partner's ending check). `tools/test.sh` and
`tools/test.ps1` run each one too and fail if it exits non-zero. New tests
should be `test_*.gd` files instead; a stand-alone check can be moved over
whenever its owner next touches it.

## What is covered

| File | Covers |
|---|---|
| `test_game_state.gd` | Progress and saves: finishing a chapter saves it, the next visit reads it back, story order kept, House state saved with its chapter, out-of-order, repeated, test-only and unknown results refused, broken or impossible saves start fresh, a save that can't be written (including private browsing) is reported and play carries on, hiding or closing never saves, starting new deletes the save |
| `test_m0_menu.gd` | Tap to begin, button sizes, each M0 check opens and Back returns |
| `test_smoothness_check.gd` | Warmup, hitch and worst-frame counting, the 2-minute run, Heavy and Shadow switches, Back |
| `test_rhythm_check.gd` | Tap pad only while the click plays, last 20 taps, offset to the nearest click, average, spread and Good count, sound delay re-scoring and limits, Clear, 44px buttons on phone screens |
| `test_viewpoints_check.gd` | Start in the doorway, tap a ring to glide to its view, changing mind mid-glide, glide time and its limits, rings on screen, 44px and not overlapping on laptop and phone screens from every viewpoint, Back |
