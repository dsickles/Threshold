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

Then add its scene to `ChapterList.SCENES`. The Partner (DAS-73) is the first
real chapter on the runner: the menu's "The Partner (rough)" button calls
`enter(&"partner", self)`.

The Protector (DAS-97) is the second: the menu's "The Protector (rough)"
button calls `enter(&"protector", self)` until the bedside lamp in the House
can start it.

The stand-in chapter (`game/scenes/chapters/stand_in/`) is the smallest
example. Tests: `game/tests/test_chapter_runner.gd` and
`tests/web/specs/chapters.spec.ts`.
