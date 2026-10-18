# The House: floor plan (draft)

**Status:** Draft for Dan to edit, 2026-10-18. Not decided. Answers the open question in [scope.md](../scope.md): "The House's small floor plan: which rooms, where the chapter objects sit" (needed by M1). Once Dan settles it, the answer moves to scope.md "Settled questions" and this file stops saying "draft".

Built from: [ADR-0003](../adr/0003-house-fixed-viewpoints.md) (fixed viewpoints), [roadmap.md](../roadmap.md) M1 (2–3 rooms, lamp light, ordinary fog, warmer after the Partner, gray after the Loss), [gdd.md](gdd.md) Hub Evolution, [narrative-design.md](narrative-design.md) ("Story Gates: completing a minigame is the key to unlock the next room/chapter"), [epic-1-stories.md](stories/epic-1-stories.md), [epic-2-stories.md](stories/epic-2-stories.md) Story 2.4 (crib put away, boxes out), [EXPERIENCE.md](ux/EXPERIENCE.md) (first wander, no quest markers), [game-architecture.md](game-architecture.md) §2.

Dan's direction, 2026-10-18: **3 bedrooms, 2 bathrooms.** The living room and kitchen are always open, because every house has them. The nursery is not near the front door. Think about where Leo starts, how he moves through the House as the story goes, and how places open up after each chapter.

Every line marked **Choice** is something I picked where the docs say nothing. Lines marked **Dan** are gaps only Dan can fill. The full list is at the end.

## The idea: the House opens from the front to the back

The House is laid out like a real one-storey house: the shared rooms at the front, the private rooms at the back. The story walks Leo deeper into it.

- **The front** (entry, living room, kitchen) is the everyday House. It is always open, from the first second to the last.
- **The back hall and the main bedroom** are the couple's private life. They open after the opening story beat.
- **The nursery** is the deepest room, the last door at the far end of the back hall. It is the future. It opens with hope after the Partner, shuts after the Loss, and is the last room the game ends in ("the House is the last room", FR30).
- **Leo's den** (the third bedroom) is his old life, near the front door. It opens when the bills arrive (the Provider) and is cleared out in the Mourner.

So the House grows as the story does, and the room the player can't get into says as much as the rooms they can.

## Plan

```
                          BACK (garden)
   +----------------+--------------------------------+
   |                |                                |
   |   BEDROOM 2    |   BEDROOM 1 (main)             |
   |   NURSERY      |   record player       +------+ |
   |   (last room)  |                       |BATH 1| |
   |                |                       |en-   | |
   |                |                       |suite | |
   +-------D--------+-----------D-----------+--D---+-+
   |   n                        b   BACK HALL        |
   +--------+--------+------------------------D------+  <- day one: boxes
   |        |        |                                |     stacked here
   | BATH 2 |BEDROOM 3|          KITCHEN     k1        |
   | (hall) |Leo's den|        fridge, table           |
   |        |        |                                |
   +---D----+---D----+                                |
   |                 |                                |
   |  ENTRY    h1    D          LIVING ROOM  l1       |
   |  [keys]         |          couch, big window     |
   |                 |                                |
   +-------D---------+--------------------------------+
           ^ front door          FRONT (street)

   D = doorway    h1, l1, k1, bh, b, n = viewpoints
```

About 16 m by 12 m, one storey. **Choice:** one storey, because stairs are awkward to frame with fixed viewpoints. The front-to-back depth does the job a second floor would (the nursery is as far from the front door as it can be).

Because the player only ever sees framed shots ([ADR-0003](../adr/0003-house-fixed-viewpoints.md)), each room only needs the walls and objects its viewpoints can see. Rooms can be open-backed sets, and a room that isn't open yet is just a closed door.

## Where Leo starts

**Choice:** just inside the front door (**h1**), on the evening they move in. The House is cold and full of boxes. From that first shot the player sees the entry with the hall table and its car keys, and through a wide doorway the living room with its big window. The kitchen is beyond. Nothing else is open, so there is nowhere to get lost. **Dan:** moving-in evening is a story choice.

## How the House opens up, chapter by chapter

The core table turns the finished-chapter list into the House mood, the open rooms and the active chapter object ([game-architecture.md](game-architecture.md) §2.1). A chapter never opens a room itself. An open door is a tappable viewpoint marker; a closed one isn't tappable and doesn't highlight ("if it cannot be tapped, it is not the path").

| Point in the story | Rooms open | What changes | Active chapter object |
|---|---|---|---|
| Start | Entry, living room, kitchen | Cold: bare bulbs, cool light, boxes everywhere. Moving boxes stacked in the kitchen's doorway to the back hall. | None until the opening beat |
| After the opening story beat | + back hall, main bedroom | The boxes in the back-hall doorway have been moved; a warm lamp is on at the end of the hall, in the bedroom | Record player (bedroom) |
| After the Partner | + **nursery** | Warm (`house-hope`): lamps on, a rug, bed frame up. The **nursery door at the end of the hall stands open**, and inside is a crib, bought too early. The positive test is on the bedroom nightstand. | Car keys (entry) |
| After the Loss | − nursery | Grief (`house-grief`, the one gray filter M1 allows): lamps dim, rain on the windows. **The nursery door is shut again** and can't be tapped. The test is gone. | None (the end of M1) |
| After the Novice (M2) | (same) | Pregnant again. Color starts coming back. | Bills on the desk in Leo's den, which opens |
| After the Provider (M2) | + Leo's den | | Baby monitor (bedroom nightstand) for the Tuner |
| After the Tuner (M2) | + nursery again | The nursery reopens, full of the boxes it was shut on. A flat-pack crib is delivered to the entry. | Crib box (entry) for the Anchor |
| After the Anchor (M2) | (same) | The crib stands in the nursery among the boxes | The boxes in the nursery and the den's clutter, for the Mourner |
| After the Mourner (M2) | (same) | The nursery is finished; the den is cleared | Hospital bag by the front door, for the Arrival |
| After the Arrival (M2) | (same) | The game ends in the nursery: the last room | — |

Rows marked M2 are a sketch so M2 doesn't paint itself into a corner. Only the first four rows are built in M1.

**Choices** in that table:
- **The opening beat opens the back of the House.** It now has to play before the Partner can start (the earlier draft said it didn't). It gives the first wander a reason to happen in the living room, and makes the bedroom the first room the story opens.
- **The nursery opens after the Partner and shuts after the Loss.** The most hopeful room in the House is the one that is taken away. Story 2.4 needs a crib that can be put away; shutting its room is a stronger way to show it than boxes alone.
- **The crib arrives after the Partner** and is the same crib Leo puts back together in the Anchor ("The Panic"). **Dan:** the story meaning of that is yours.
- **Rain starts after the Loss**, so the House keeps the sound of the Silence in the car.
- **The two bathrooms are never chapter rooms.** The en-suite is where the test is taken (its door can stand ajar after the Partner); the hall bathroom is just there, as in a real house.

## Rooms

| Room | Opens | What it is for | Key objects |
|---|---|---|---|
| Entry | Start | Where Leo starts and leaves from. The Loss and the Arrival start here: both chapters start with leaving the House. | Hall table with the **car keys** (the Loss); later the crib box and the hospital bag |
| Living room | Start | The everyday room. The opening story beat. | Couch, big window (rain after the Loss); Dad's Journal (M2) by the window |
| Kitchen | Start | Open to the living room, so one shot shows both. Holds the House's sounds. | Fridge (the recorded hum; IVF drugs for the Novice), kitchen table |
| Back hall | After the opening beat | Joins the private rooms; looks straight down at the nursery door | Boxes on day one |
| Bedroom 1 (main) + Bath 1 (en-suite) | After the opening beat | The couple's room. The Partner starts here. | **Record player** on a moving box (the Partner); mattress on the floor, bed frame later; nightstand |
| Bedroom 2: nursery | After the Partner; shut after the Loss; reopens after the Tuner | The future | Crib, then boxes, then the finished room |
| Bedroom 3: Leo's den | After the Novice (M2) | Leo's old life: guitar, games console, old armchair, a desk | Bills (the Provider); clutter (the Mourner) |
| Bath 2 (off the entry) | Never needed; a shut door in M1 | Ordinary, as in a real house; nothing in the story needs it | — |

## M1 build

M1 is "2–3 rooms" in the roadmap. This plan builds the **front room** (entry, living room and kitchen as one open space), the **back hall**, the **main bedroom**, and the **nursery** seen from its doorway only. The den and both bathrooms are closed doors. That is three rooms plus a corridor and a doorway view, which is at the top of "2–3 rooms". **Dan:** OK, or should M1 drop the nursery view and show the crib some other way?

### Viewpoints (M1)

Six viewpoints. The player starts at **h1**.

| Viewpoint | Where | What the shot shows | Open | Taps to |
|---|---|---|---|---|
| h1 Entry | Just inside the front door | The hall table and keys; the living room and its window through a wide doorway | Always | l1 |
| l1 Living room | By the couch | The window, the kitchen beyond, and the boxes stacked in the back-hall doorway | Always | h1, k1 |
| k1 Kitchen | By the fridge | Back across the room to the couch and the window; the back-hall doorway | Always | l1, h1, bh (once open) |
| bh Back hall | Just inside the back hall | Straight down the hall to the nursery door at the end; the bedroom door with its lamp | After the opening beat | k1, b, n (while open) |
| b Bedroom | Main bedroom doorway | The mattress, the record player on its box, the window, the en-suite door | After the opening beat | bh |
| n Nursery door | The nursery doorway | Into the nursery: the crib | After the Partner, until the Loss | bh |

The glide duration is settled by the M0 fixed-viewpoint check (DAS-69), not here.

## Getting the player to the first chapter object

Roadmap success criterion 2: at least 4 of 5 cold testers find the first object within about 3 minutes, with no markers. The docs say light and sound do this work, not UI.

**Choice:** the path is short and has only one way forward. From h1 the only open way is into the living room (1 tap). Arriving at l1 plays the opening beat. After it, the boxes in the back-hall doorway are gone and a warm lamp shows down the hall. That lamp is the only warm light in the cold House. In the bedroom the record player gives a faint crackle and highlights (`interact-highlight`). At least four taps from the start, all along one lit path.

## Where the opening story beat sits

It fires the first time the player arrives at **l1** (living room). Maya's lines appear as subtitles. When it ends, the back of the House opens (see above).

**Choice:** nobody is shown in the House in M1. Maya's lines appear as subtitles only, as if she is in the next room. The House is first person, so Leo is never seen. This keeps M1 free of character models and animation. **Dan:** whether Maya is ever seen in the House is a feel and story call.

## Checks this plan must pass

These come from the roadmap and stories. None is optional.

- **M1 success criterion 2:** 5 cold testers, no instructions. At least 4 find the record player within about 3 minutes. Nobody gets stuck moving around.
- **M1 success criterion 5:** most testers notice the House changed, without being asked.
- **No dead ends:** from every open viewpoint, the player can get back to the entry, and every open room is reachable (checked by playing on Dan's phone and laptop at each of the four M1 points in the story).
- **Closed rooms are never tappable and never highlight**, and a room that shuts (the nursery after the Loss) can't be reached by any route.
- **The House reads without volumetric fog** (CLAUDE.md rule): lamp light and ordinary fog only, no CompositorEffects.
- **Tap targets at least 44 px**; viewpoint markers and objects never rely on hover.
- **Core table automated tests:** each M1 point in the story (start, after the opening beat, after the Partner, after the Loss) gives the right House mood, open rooms and active chapter object. (The test addon is still an open M1 question in [scope.md](../scope.md).)

## Gaps only Dan can fill

1. **The two M1 chapter objects:** record player for the Partner, car keys for the Loss. Keep, or pick others?
2. **The errand behind the keys** (where they are driving when the Loss happens).
3. **The crib:** bought too early after the Partner, and the same crib Leo rebuilds in the Anchor?
4. **The nursery shutting after the Loss** and reopening after the Tuner (when the pregnancy feels real). Right moments?
5. **Moving-in evening** as the start.
6. **Leo's den** as the third bedroom, opening for the Provider.
7. **The M1 build size:** three rooms plus a corridor and the nursery doorway view.
8. **Is Maya ever seen in the House?** (Default for M1: no.)
9. **The end of M1:** after the House in grief there is no next chapter object. Leave the player in the gray House, or end on a card? (Default: leave them in the House; no text.)
10. **The words of the opening beat** and its closed-off/open line. Not drafted here; CLAUDE.md says Claude doesn't invent story or dialogue.
