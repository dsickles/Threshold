# Chapters: entering, playing, coming back

The shared system that starts a chapter from the House, gives it the screen,
and brings the player back with the chapter's one result
([game-architecture.md](../../../docs/design/game-architecture.md) §2.1 and §2.5).
Until the House exists, the M0 menu stands in for it.

| File | What it is |
|---|---|
| `chapter_list.gd` (`ChapterList`) | The eight chapter ids in story order, and the scene each one starts from |
| `chapter_result.gd` (`ChapterResult`) | The result shape, and the check for a real story result |
| `chapter_runner.gd` (`ChapterRunner`) | Starts a chapter, hides and pauses the House, brings it back |
| `chapter_pause.gd` (`ChapterPause`) | The pause button over every chapter and the Resume panel it opens (DAS-130) |

## Starting a chapter (the House side)

```gdscript
var chapters := ChapterRunner.of(get_tree())
chapters.chapter_finished.connect(_on_chapter_finished)  # result: Dictionary
chapters.chapter_left.connect(_on_chapter_left)          # id: StringName
chapters.enter(&"partner", self)  # `self` is the House: hidden and paused until the chapter is over
```

- The House is hidden and paused, not unloaded, so it comes back exactly as the
  player left it (same viewpoint, same everything).
- `chapter_finished` is sent after the House is back. That is when the
  finished-chapter list records the result and the game saves (saves happen
  only between chapters).
- `chapter_left` means the chapter closed without finishing (for example its
  song failed to load). There is no result and nothing is saved.
- Only one chapter plays at a time; a second `enter()` is refused.
- The runner is not an autoload. It lives at `/root/ChapterRunner` and is made
  the first time `ChapterRunner.of()` is called.

## The chapter result

A plain Dictionary that saves as JSON as it is:

```json
{"chapter": "partner", "answer": ""}
{"chapter": "mourner", "answer": "vulnerable", "house": {"...": "..."}}
```

| Key | Value |
|---|---|
| `chapter` | The id: `partner`, `protector`, `novice`, `provider`, `tuner`, `anchor`, `mourner` or `arrival` |
| `answer` | `""` if the chapter offers no choice, else `stoic` or `vulnerable` (changes spoken words and journal wording only, [ADR-0004](../../../docs/adr/0004-journal-wording-varies-no-mastery.md)) |
| `house` | Optional. Only for something the House must keep that the core table can't look up (for example where the Mourner's things were put). Plain JSON values only: String, bool, int, float, null, Arrays and String-keyed Dictionaries of those (no Vector2, Node and so on). |

Nothing else goes in it. Story facts, House mood and journal entries are looked
up from the finished-chapter list in the core table, never reported by a
chapter. `ChapterResult.is_story_result(result)` is true only for a
well-formed result from a real chapter; record only those. The menu's
test-only stand-in chapter (`stand_in`) fails it on purpose.

## Making a chapter (the chapter side)

A chapter is a scene. Its root node:

1. Has a signal named `finished`, and emits it once when the chapter is over:
   - `finished.emit()` when the chapter offers no Stoic/Vulnerable choice;
   - `finished.emit("stoic")` or `finished.emit("vulnerable")` when it does;
   - `finished.emit(answer, {...})` only if it has something for `house`.
   Emitting anything else (a non-String answer, more than two arguments, a
   `house` that isn't plain JSON) is a bug in the chapter: the runner prints
   an error, drops the bad part, and still brings the House back.
2. Frees itself (`queue_free()`) only to leave **without** finishing.
3. Never touches the House, another chapter, or saved state. The runner and
   the core table do that.
4. Handles its own pause when the tab is hidden.
5. Optionally, for the pause button (see "Pausing" below): `pause_chapter()`
   and `resume_chapter()` for anything Godot can't stop on its own, and
   `shows_pause_button()` returning false to go without the button.

Then add its scene to `ChapterList.SCENES`. The Partner (DAS-73) is the first
real chapter on the runner: the menu's "The Partner (rough)" button calls
`enter(&"partner", self)`.

The Protector (DAS-97) is the second: the menu's "The Protector (rough)"
button calls `enter(&"protector", self)` until the bedside lamp in the House
can start it.

## Pausing

Every chapter gets a pause button in the top-right corner (the playtest
overlay has the top-left), 44 points on a sideways phone. The runner owns it;
a chapter never makes its own (DAS-130).

- Tapping it calls `runner.pause()`: the chapter's `pause_chapter()` runs if
  it has one, then the chapter's `process_mode` is set to disabled, which
  stops its `_process`, `_input` and Godot's own sound. A dim scrim and one
  panel ("Paused", Resume) cover the chapter; taps off the panel do nothing.
- Resume (a tap, or Enter, since it has the focus) calls `runner.resume()`:
  the chapter's own process mode comes back, then its `resume_chapter()` runs.
- Pausing never saves, and the panel has no way to skip, leave or retry.
  Settings and Back to title join it in M2.
- `pause_chapter()` is for what Godot doesn't stop: the Partner holds its
  song, which the browser plays (`Conductor.hold()` / `release()`); the
  Protector's run stops its clock and music. On the web, a Godot sound left
  on the default (sample) playback type keeps playing when its node is
  disabled, so a chapter with music stops it here.
- The pause layer is an internal child of the runner, after the chapter, so
  it hears the pause button's tap before the chapter's `_input` does, and
  `runner.get_children()` still lists only the chapter.
- `shows_pause_button()` returning false hides the button. The Loss does,
  because its design has no pause button on screen
  (`docs/design/the-loss-run-and-car.md`); it still pauses when the tab is
  hidden.

The stand-in chapter (`game/scenes/chapters/stand_in/`) is the smallest
example. Tests: `game/tests/test_chapter_runner.gd`, `game/tests/test_chapter_pause.gd`,
`tests/web/specs/chapters.spec.ts` and `tests/web/specs/pause.spec.ts`.
