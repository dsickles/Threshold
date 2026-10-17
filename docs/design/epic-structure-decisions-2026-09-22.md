# Threshold — Epic Structure Decisions (2026-09-22)

Outcome of the party-mode pressure test of the working epic list. Dan made the calls marked **Decided**. The items that were **Open** were ruled on 2026-09-22 and are listed under "Ruled on 2026-09-22."

This file does not edit `epics.md` or any other planning doc. Where a decision conflicts with an existing doc, it is listed under "Doc conflicts" so the docs can be updated later.

## Epic list (build order)

The numbers are the order the epics get built. Players still play the chapters in story order: Partner, Loss, Long Haul, Cost, Tuner, Anchor, Mourner, Arrival.

1. **The Spark in the New House** — browser, walk the House, play The Partner, return to a changed House, come back later. Owns the tap scheme, title, pause, settings, save, one Story Sequence, the first journal entry, the chapter-result contract, and the chapter-look scaffold.
2. **The Loss** — miscarriage with no warning, skip, or retry. The Silence (car, rain). House in grief.
3. **The Long Haul** — numb bridge after the loss, six months of IVF, ends on the positive test. The Injection. Framework plus three micro-games in the first batch. Does not restage conception.
4. **The Cost** — bills for that pregnancy, Reflowed Reader View, stamps, Due Date fail-forward. Does not restage conception.
5. **Hear Them** — Tuner. Static until the baby comes through.
6. **Make Space** — Mourner. Unpack grief and pre-parent clutter. Placement can persist in the House.
7. **Carry the Weight** — Anchor hold zones, Maya's voice, Stability Assist. The Panic: crib without instructions. Built last among the chapters because it is the riskiest (physics on a phone browser).
8. **The Arrival** — ending reprise of Tuner and Partner. Built after Carry the Weight so the ending is tested with the full story in place.

Dependencies from the original rules still hold: Epic 1 stands alone; Epics 2–7 need Epic 1; The Long Haul assumes The Loss happened; The Arrival needs Epic 1 and Hear Them. In practice The Arrival is also built after every chapter epic.

## Decided

**D1 — Epic order follows what makes sense to build, not play order.** Make Space is 6, Carry the Weight is 7, The Arrival is 8. (Epics 6, 7, 8)

**D2 — Epic 1 stays one epic.** No split into "play it once" and "come back tomorrow." Story order inside Epic 1:
- A rough, playable Partner comes early, not as the last story. Drop the wording "The Partner is the payoff."
- Save and "close the tab and come back" come early too, right after the rough Partner. Menus and polish come after that.
(Epic 1)

**D3 — The House is designed for the browser.** Its mood comes from ordinary fog, lamp light, color that drains or warms, corner shadowing (SSAO), and sound. Volumetric fog is an optional extra on the PC/Steam build only. The House must never depend on it. (Epic 1)

**D4 — Chapter looks: Epic 1 builds the scaffold only.** Godot builds a look from several pieces (the 3D scene's lighting and fog, full-screen filters, and effects on single objects), not one filter system. So Epic 1 builds:
- the device check at startup, and a quality setting in Settings that actually changes something;
- a "current look" slot: a chapter sets its look when it loads, and the House look comes back automatically when the chapter ends;
- one empty full-screen filter layer that chapters plug into;
- the House's own lighting and fog.

Each chapter epic builds its own look inside that scaffold (for example, The Loss adds the gray drain). Do not use Godot's CompositorEffects; they don't run in the browser. (Epic 1, then every chapter epic)

**D5 — Browser checks go inside the stories they belong to.** They are not a separate spike story.
- The Partner story checks beat timing in a real phone browser.
- The save story checks that saves persist, and that "Couldn't save." shows when they don't (private browsing, or the game inside a frame with storage blocked).
- The pause story checks that the game pauses when the tab is hidden. Pause has to fire as the tab loses focus, because the browser freezes the game right after.
(Epic 1)

**D6 — Saves happen only between chapters.** No mid-chapter checkpoints. Closing the tab or quitting mid-chapter restarts that chapter from its beginning next time. This includes The Loss. Pausing when the tab is hidden still happens; it just doesn't save. Chapter epics do not implement mid-chapter save. (Epic 1, every chapter epic)

**D7 — The Loss and The Long Haul stay separate epics.** (Epics 2, 3)

## Ruled on 2026-09-22 (were Open)

**O1 — One result per chapter.** A chapter ends one way. Every player gets the same items, the same journal words, and the same big story beats. Spoken dialogue may differ. A finished chapter reports that it finished. One list in the core turns that into the story facts and the House mood. The chapter does not write those itself. (Epic 1, every chapter epic)

**O2 — The past and the present can both be true.** The miscarriage stays in the past. After The Long Haul, Maya is pregnant again. A save from that point must open with both. (Epics 1, 3)

**O3 — Old test saves may fail to open.** No version number and no work to keep older test saves loading. (Epic 1)

**O4 — One dialogue choice in Epic 1's opening story beat.** Leo can answer in a closed-off way or an open way. The spoken words can differ. Items, journal words, and big story beats stay the same. (Epic 1)

**O5 — Quality checks stay loose and ongoing.** Word count, pacing, and phone speed are checked while the game is built. Dialogue is sketched across the whole story so one early chapter does not use up the words. The word guide stays loose. The Arrival is only the ending: hear the cry, hold the hand, and the House is the last room. (Epic 8, every chapter epic)

**O6 — Write The Silence and the numb bridge in the same week.** (Epics 2, 3)

## Per-chapter checklist (from the original rules, adjusted)

Each chapter epic restates its share of: tone, one awkwardness beat, fail-forward to the one ending, the same House objects for every player, 10–15 minutes, House state, journal entry, score, and skin (its look, built inside the D4 scaffold).

Under D6, no mid-chapter save. Under O5, phone speed and pacing are checked as the chapter is built, and the writing stays inside a loose whole-game sketch. There is no hard leftover-word gate.

## Browser facts behind D3–D5

From the Godot 4.7 manual ([Overview of renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html), [Exporting for the Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)):

- Web exports use only the Compatibility renderer (WebGL 2).
- **Works in the browser:** ordinary fog, SSAO, glow, color adjustments, full-screen filter shaders, and per-object shaders.
- **Doesn't work in the browser:** volumetric fog, depth-of-field blur, decals, particle trails, and CompositorEffects.
- **Audio:** by default, the browser plays sound through its own Web Audio system. That keeps latency low, but it drops audio effects (like reverb) and on-the-fly sound generation. Switching back to Godot's own sound system raises latency.
  - The fridge hum should be a recorded loop with volume and pitch changes, not generated sound.
  - Partner beat timing reads Godot's sound clock. Whether that clock matches what the browser is actually playing is unverified, so it must be tested (D5).
- **Saves:** saves are stored in the browser. They don't persist in private mode, or in a frame where third-party storage is blocked. `OS.is_userfs_persistent()` exists, but the manual says it can report false positives.
- **Hidden tab:** the browser freezes the game when the tab is hidden.
- An unofficial WebGPU fork of Godot exists. It is a beta, and Windows browsers are unfinished. Not used.

## Doc conflicts to fix later (not edited here)

- `game-architecture.md` §5.1 and the Additional Requirements in `epics.md`: "every minigame implements `save_checkpoint()`" for quit, crash, and backgrounding. This conflicts with D6.
- `EXPERIENCE.md` and UX-DR14: "Tab hidden / phone interrupt: `pause` + `save_checkpoint()`. Resume where they were." Under D6 the game still pauses, but it does not save mid-chapter, and a reload restarts the chapter.
- `EXPERIENCE.md`, the Jordan Loss flow: "Rage-quit. Auto-save already wrote the chapter complete." Under D6, quitting mid-Loss restarts The Loss.
- `game-architecture.md` §3.1 and §3.3, `gdd.md`, and the Additional Requirements in `epics.md`: "Standard PBR plus volumetric fog" as the House's grounding look. This conflicts with D3; volumetric fog is PC only.
- `game-architecture.md` §2.1, "Pregnant and Miscarried don't coexist." O2 is accepted, so this line is superseded. A past miscarriage and a current pregnancy can both be true.
- `game-architecture.md` §6 builds Batch 2 as Tuner and Mourner and Batch 3 as Anchor. This already matches D1.
