---
status: accepted
date: 2026-10-19
supersedes: the open question "Which automated-test addon to use for the core table and saves" in scope.md
---

# Saves are one JSON file in Godot's user folder, tested without an addon

**Recommendation, Dan can revisit:** the game saves the finished-chapter list and settings as one small JSON file, `user://save.json`, written with Godot's own `FileAccess`. In the browser Godot keeps `user://` in the page's own storage (IndexedDB), so the save survives a reload or a closed tab. On PC/Steam the same code writes an ordinary file in the player's user folder, which Steam Cloud can sync later. One code path for every platform, no addon.

The core table and saves are tested with the small test runner already in the repo (`game/tests/`, decision-history 18), not an addon. It already covers what an addon would add here: fresh copies per test, checks that don't stop the test, and failing on any script error.

## What is saved

```json
{
  "finished": [
    {"chapter": "partner", "answer": "vulnerable"},
    {"chapter": "protector", "answer": ""}
  ],
  "settings": {}
}
```

- `finished` is the finished-chapter list in story order. `answer` is `""`, `"stoic"` or `"vulnerable"`. Each entry is the chapter framework's result as handed back (`ChapterResult`, [game/_core/chapters/README.md](../../game/_core/chapters/README.md)), so it also carries `"house": {...}` when a chapter leaves House state the core table can't look up (for example where the Mourner put things); the key is left out otherwise. Story facts, House mood, House objects and journal entries are not saved; the core table looks them up from this list (game-architecture 2.1).
- `settings` is empty until the settings screen exists (Final milestone).
- Only `GameState` (`game/_core/state_manager/game_state.gd`) writes it, and only when the chapter runner reports a finished chapter (`ChapterRunner.chapter_finished`, connected to `GameState.record_chapter_result`). Only results that pass `ChapterResult.is_story_result` are recorded, so the menu's test-only stand-in never saves. Test-only chapters, leaving a chapter early, hiding the tab or closing it mid-chapter save nothing.

## Considered

- **The browser's localStorage, reached through `JavaScriptBridge`.** It writes instantly, but only exists in the browser, so PC/Steam would need a second way to save and a second set of tests. Rejected for one code path.
- **Godot resource files (`.tres`) or `ConfigFile`.** A resource file can carry code that runs when it loads, which a save file should never do. `ConfigFile` would work; JSON was already the plan in game-architecture 5.1 and is easy to read when debugging.
- **A test addon (GUT or gdUnit4).** Would mean an outside dependency and a second way of writing tests next to the runner threads already use. Not worth it while the runner does the job.

## Consequences

- **No save versions, as game-architecture 5.1 says.** A save that is missing, unreadable or impossible (chapters out of story order, an unknown chapter or answer) counts as no save, and the game starts fresh instead of crashing. Old test saves may be lost when the format changes.
- **Impossible stories can't be saved.** A chapter is only recorded if it is the next one in story order, and finishing one twice changes nothing.
- **"Couldn't save."** In private browsing or a blocked frame the browser has no lasting storage. `GameState` then still records the chapter, sets `last_save_ok` to false, emits `save_failed`, and play carries on. A broken or impossible save file doesn't count as a save (`has_save()` is false), so Continue will never offer an empty game. Showing the message on screen comes with the title and pause screens in M2.
- **A short gap in the browser.** Godot copies the file into IndexedDB a moment after writing it. Closing the tab within that moment could lose the chapter just finished. Players go back to the House after a chapter, so this is accepted.
- **New keys don't break older saves.** If something else needs saving later, it is a new key; a save without it still loads.
- **Revisit** if saving in Safari on Dan's iPhone turns out unreliable (then localStorage for the web build only), or if the test runner becomes a burden (then pick an addon).
