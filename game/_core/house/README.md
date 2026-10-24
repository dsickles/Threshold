# The House table (the core table)

The one table that turns the finished-chapter list into what the House shows
([game-architecture.md](../../../docs/design/game-architecture.md) §2.1). The
House reads it; chapters never write story facts. Every row comes from
[house-floor-plan.md](../../../docs/design/house-floor-plan.md) and the
[continuity ledger](../../../docs/design/continuity-ledger.md): change those
first, then `house_table.gd`.

## Reading it (the House side)

```gdscript
var point := GameState.house_point()        # start, after_opening, after_partner or after_loss
HouseTable.mood(point)                       # cold, warm or gray
HouseTable.room_state(point, &"spare_room")  # open, shut or boxed
HouseTable.door_state(point, &"office_door") # open, shut or boxed
HouseTable.chapter_object(point)             # record_player, bedside_lamp or &"" (none)
HouseTable.house_objects(point)              # {object: state} for each House object that is there
HouseTable.arrive_in(point)                  # the room the player is in when the point begins
```

| Point | When | Mood | Chapter object |
|---|---|---|---|
| `start` | A new game, or the opening beat hasn't played yet | cold | none |
| `after_opening` | The opening beat has played this visit | cold | record player (starts the Partner) |
| `after_partner` | The Partner is finished | warm | bedside lamp (starts the Loss) |
| `after_loss` | The Loss is finished (end of M1) | gray | none |

Rooms and doors are `open`, `shut`, or `boxed` (moving boxes in the way). A
room that isn't open is never tappable. `reachable_from(point, room)` lists the
rooms the player can get to through open doors; the tests use it to check that
the House never has a dead end.

House object ids and states (`photo`: `wrapped` then `hung`; `fridge`:
`nearly_empty`, `mayas_note`, `food_from_family`; and so on) are the names the
House scene uses to show the right thing. Their words live in
[m1-words-draft.md](../../../docs/design/m1-words-draft.md).

## The opening beat

The opening beat is not a chapter, and saves happen only between chapters, so
GameState holds its answer in memory:

```gdscript
GameState.finish_opening_beat("stoic")  # or "vulnerable": Leo's closed-off or open line
GameState.opening_beat_done()           # true; the House is now at after_opening
GameState.opening_answer()              # "stoic"
```

It is written to the save only with the Partner's result (the `opening` key,
[ADR-0007](../../../docs/adr/0007-saves-json-file-in-user-folder.md)). If the
player leaves before the Partner finishes, it is forgotten and the opening beat
plays again next visit.

Tests: `game/tests/test_house_table.gd`, and the opening beat in
`game/tests/test_game_state.gd`.
