# The House: floor plan (draft)

**Status:** Draft for Dan to edit, 2026-10-18. Not decided. Answers the open question in [scope.md](../scope.md): "The House's small floor plan: which rooms, where the chapter objects sit" (needed by M1). Once Dan settles it, the answer moves to scope.md "Settled questions" and this file stops saying "draft".

Built from: [ADR-0003](../adr/0003-house-fixed-viewpoints.md) (fixed viewpoints), [roadmap.md](../roadmap.md) M1 (2–3 rooms, lamp light, ordinary fog, warmer after the Partner, gray after the Loss), [gdd.md](gdd.md) Hub Evolution, [epic-1-stories.md](stories/epic-1-stories.md), [epic-2-stories.md](stories/epic-2-stories.md) Story 2.4 (crib put away, boxes out), [EXPERIENCE.md](ux/EXPERIENCE.md) (first wander, no quest markers), [game-architecture.md](game-architecture.md) §2.

Every line marked **Choice** is something I picked where the docs say nothing. Lines marked **Dan** are gaps only Dan can fill (story, feel, scope). The full list is at the end.

## The short version

A one-storey, 3 bedroom, 2 bath house on moving-in evening. A hall runs across the middle. Off it: the main bedroom (with its own bathroom), the spare room (later the nursery), a third bedroom used as Leo's den, a hall bathroom, and an open living room and kitchen. M1 builds the hall, the main bedroom and the living room with kitchen, plus a view into the spare room through its doorway. The Partner starts from a record player in the bedroom. The Loss starts from the car keys on the hall table.

## Plan

```
                                  N
   +-------------------+----------+-------------------+
   |                   |          |                   |
   |   BEDROOM 1       |  BATH 2  |   BEDROOM 2       |
   |   (main; record   |  (hall)  |   spare room      |
   |    player)        |          |   (nursery later) |
   |        +--------+ |          |                   |
   |        | BATH 1 | |          |                   |
   |        |(en-    | |          |                   |
   |        | suite) | |          |                   |
   +---D----+--------+-+----D-----+--------D----------+
   |   b                               h2        h1   D  <- front door
   |                     HALL                  [keys] |
   +-------D-----------------------------+------D-----+
   |                                     |            |
   |   LIVING ROOM        KITCHEN        |  BEDROOM 3 |
   |   l1 (couch)  (window)  k1          |  (Leo's    |
   |                    (fridge, table)  |   den)     |
   |                                     |            |
   +-------------------------------------+------------+

   D = doorway    h1, h2, b, l1, k1 = viewpoints (M1)
```

About 16 m by 11 m, one storey, 3 bedrooms and 2 bathrooms (Dan, 2026-10-18). **Choice:** one storey, because stairs are awkward to frame with fixed viewpoints and add rooms M1 doesn't need. The living room and kitchen are one open space so a single shot can show the fridge, the table and the rain window together.

Because the player only ever sees framed shots ([ADR-0003](../adr/0003-house-fixed-viewpoints.md)), each room only needs the walls and objects its viewpoints can see. Rooms can be open-backed sets.

## Rooms

| Room | In M1? | What it is for | Key objects |
|---|---|---|---|
| Hall | Yes | Where the player starts, just inside the front door. Every room opens off it, so nobody can get lost. | Hall table with the **car keys** (the Loss's chapter object); moving boxes; coat hook |
| Bedroom 1 (main) | Yes | The couple's room. The Partner starts here. | **Record player** on a moving box (the Partner's chapter object); mattress on the floor at first, bed frame later; nightstand |
| Bath 1 (en-suite, off the main bedroom) | No; its door is seen, shut, from b | **Choice:** where the positive test is taken. In M2 its door can stand open after the Partner. | Sink, mirror |
| Living room and kitchen | Yes | The everyday room. The opening story beat happens here. Holds most of the House's sounds. | Fridge (the recorded hum); kitchen table; couch; big window (rain after the Loss) |
| Bedroom 2: spare room (later the nursery) | Seen through its doorway only | Where hope and grief show most: the crib after the Partner, boxes after the Loss. | Crib, then boxes |
| Bedroom 3: Leo's den | No; its door is seen, shut, from h1 | **Choice:** Leo's pre-parent stuff (guitar, games console, old armchair) and a desk. Gives the Provider a real desk and the Mourner the "single guy" clutter to clear. | Desk, Leo's things |
| Bath 2 (hall) | No | **Choice:** the everyday bathroom; nothing in the story needs it yet. | — |

M1 is "2–3 rooms" in the roadmap, so the bigger house doesn't grow M1: it builds three rooms plus one doorway shot into the spare room. The other three rooms are closed doors in M1 and get built in M2 as chapters need them. **Choice:** the doorway shot, because the crib appearing and then being put away is the clearest House change the docs describe (Story 2.4), and success criterion 5 is that testers notice the House changed. The spare room becomes a full room in M2.

## Viewpoints (M1)

Five viewpoints. The player starts at **h1**.

| Viewpoint | Where | What the shot shows | Can tap to go to |
|---|---|---|---|
| h1 Front door | Hall, just inside the front door | Down the hall: the hall table with the keys close by, the bedroom door with warm light spilling from it, the living room doorway | h2, b, l1 |
| h2 Spare room door | Hall, at the spare room's open door | Into the spare room: empty at first, then the crib, then boxes | h1, b, l1 |
| b Bedroom | Main bedroom doorway | The mattress, the record player on its box, the window, the shut en-suite door | h1, h2 |
| l1 Living room | By the couch | The window, the kitchen beyond, the fridge | h1, k1 |
| k1 Kitchen | By the fridge | Back across the room to the couch and the window; the kitchen table | l1, h1 |

The glide duration is settled by the M0 fixed-viewpoint check (DAS-69), not here.

## Getting the player to the first chapter object

Roadmap success criterion 2: at least 4 of 5 cold testers find the first object within about 3 minutes, with no markers. The docs say light and sound do this work, not UI.

**Choice:** the record player is the only warm light in the cold House, and its doorway is visible from the very first shot (h1). It plays a faint crackle when the player is near. It highlights (`interact-highlight`) when it can be tapped from the current viewpoint. The car keys are also visible from h1 but do nothing until the Partner is finished.

## How the House changes in M1

The core table turns the finished-chapter list into a House mood and the House objects ([game-architecture.md](game-architecture.md) §2.1). M1 needs three rows.

| Finished chapters | House mood | What changes | Active chapter object |
|---|---|---|---|
| none | Cold | Bare bulbs, cool light, boxes everywhere, mattress on the floor, spare room empty, fridge hum | Record player |
| Partner | Warm (light biased to `house-hope`) | Lamps on, a rug, bed frame up, boxes half unpacked, the record player's lid closed, the **positive test on the nightstand**, a **crib in the spare room** | Car keys |
| Partner, Protector | Grief (`house-grief`, the one gray filter M1 allows) | Lamps off or dim, rain on the windows, the crib taken apart and back in its box, boxes stacked in the spare room, the test gone | None (end of M1; see below) |

**Choices** in that table:
- **The crib arrives after the Partner.** The couple buys it too early, out of hope. Story 2.4 needs a crib that can be put away, and the docs never say when it appears. The Anchor later has "The Panic: Leo tries to build the crib without instructions"; putting that same crib back together would tie the two together. **Dan:** the story meaning of that is yours.
- **The positive test stays in the House** on the nightstand after the Partner, so the result of the chapter can be seen in the room. It is gone after the Loss.
- **Rain starts after the Loss**, so the House carries on the sound of the Silence in the car.

## Chapter objects

The docs name the hub objects only as "the object is the door". These are proposals.

| Chapter | Object | Where | Why this one |
|---|---|---|---|
| The Partner | Record player | Bedroom | A rhythm chapter starts from music; warm light makes it findable |
| The Protector (the Loss) | Car keys | Hall table | An ordinary, hopeful errand (heading to an appointment). The Loss ends in the car, so the keys bookend it. Gives no warning. **Dan:** the errand is story. |
| The Novice | Medication box in the fridge | Kitchen | IVF drugs are kept in the fridge; the fridge already hums |
| The Provider | Pile of bills | Desk in Leo's den | The desk chapter starts from a real desk, in the room of his old life |
| The Tuner | Baby monitor or home doppler | Bedroom nightstand | Listening for the baby |
| The Anchor | The crib's flat-pack box | Spare room | The load, and The Panic |
| The Mourner | Unpacked moving boxes | Spare room and Leo's den | Packing away grief in the nursery-to-be, and clearing the den's pre-parent clutter |
| The Arrival | Hospital bag | By the front door | Leaving for the birth; the House is the last room |
| Dad's Journal (M2) | Journal | Living room, by the window | Seen from l1 and k1 |

Only the first two are needed in M1. The rest are a sketch so M2 doesn't paint itself into a corner.

## Where the opening story beat sits

M1 includes "the opening story beat with the closed-off/open line, as text". **Choice:** it fires the first time the player arrives at **l1** (living room). That keeps the beat off the path the eye is first pulled along (h1 to the bedroom), so a tester can wander first, as [EXPERIENCE.md](ux/EXPERIENCE.md) wants ("minutes of nothing required").

**Dan:** if the beat must play before the Partner can start, the record player needs to wait for it. The docs don't say. My default: it does **not** have to play first; a player can go straight to the record player.

## What the player sees of Leo and Maya

**Choice:** nobody is shown in the House in M1. Maya's lines in the opening beat appear as subtitles only, as if she is in the next room. The House is first person, so Leo is never seen. This keeps M1 free of character models and animation. **Dan:** whether Maya is ever seen in the House is a feel and story call.

## Checks this plan must pass

These come from the roadmap and stories. None is optional.

- **M1 success criterion 2:** 5 cold testers, no instructions. At least 4 find the record player within about 3 minutes. Nobody gets stuck moving around.
- **M1 success criterion 5:** most testers notice the House changed, without being asked.
- **Every viewpoint can reach every room in at most two taps**, and no viewpoint is a dead end (checked by playing on Dan's phone and laptop).
- **The House reads without volumetric fog** (CLAUDE.md rule): lamp light and ordinary fog only, no CompositorEffects.
- **Tap targets at least 44 px**; viewpoint markers and objects never rely on hover.
- **Core table automated tests:** each of the three finished-chapter lists above gives the right House mood and active object. (The test addon is still an open M1 question in [scope.md](../scope.md).)

## Gaps only Dan can fill

1. **The two chapter objects:** record player for the Partner, car keys for the Loss. Keep, or pick others?
2. **The errand behind the keys** (where they are driving when the Loss happens).
3. **The crib:** does it appear after the Partner, and is it the same crib Leo rebuilds in the Anchor?
4. **Moving-in evening** as the starting time. Is the first visit the day they move in?
5. **Must the opening beat play before the Partner can start?** (Default: no.)
6. **Is Maya ever seen in the House?** (Default for M1: no.)
7. **The end of M1:** after the House in grief, there is no next chapter object. Does the build just leave the player in the gray House, or end on a card? (Default: leave them in the House; no text.)
8. **The third bedroom as Leo's den** (pre-parent stuff and a desk). Keep, or another use?
9. **The words of the opening beat** and its closed-off/open line. Not drafted here; CLAUDE.md says Claude doesn't invent story or dialogue.
