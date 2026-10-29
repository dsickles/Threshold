# Decision History: Threshold

**Created:** 2026-09-20
**Purpose:** Record superseded planning decisions so later BMAD/GDS workflows treat the canonical docs as current truth without forgetting how they were reached.

**2026-10-17:** Moved off BMAD. This file now lives in `docs/design/` and keeps logging superseded decisions (entries 8 onward). New decisions are recorded as ADRs in [docs/adr/](../adr/); this file records what they replaced.

Verbatim November 2025 originals live in [archive/2025-11-22-original/](../../archive/2026-10-bmad/_bmad-output/planning-artifacts/archive/2025-11-22-original/).

The documents were written in one day, in this order: brainstorming session → game brief → GDD / narrative / architecture (with a pre-mortem from four agents). Later documents already contain most of the design that later replaced the brief. This file exists because the brief, ADR, and a few leftover GDD/architecture lines were never updated after those later documents landed.

---

## 1. The Provider is a bureaucracy sim, not a deckbuilder

| | |
|---|---|
| **Was** | Roguelike Deckbuilder (_Slay the Spire_ style). Life deals Event Cards; you play Resource Cards (money, energy, time). "Worry" cards clog the hand. |
| **Became** | Bureaucracy Simulation (_Papers, Please_ style). Cross-reference invoices, insurance claims, and bank statements. Stamp Approve/Deny. A draining bank-account meter. |
| **Why** | Deckbuilding is a more sophisticated game mechanic than this project wants. The emotional target is dehumanizing paperwork and the feeling that the system is designed to confuse and bankrupt you — a desk of forms does that more directly than a card loop. |
| **Where it first appeared** | Brainstorming session; game brief (executive summary example, Primary Mechanics, Phase 1 prototype, next-steps paper prototype); ADR-001 (context, Unity kit example, "2D Card Game" verdict). |
| **Where it was replaced** | GDD § "The Provider (The Cost)"; architecture § 4.1. |
| **Archive** | `archive/2025-11-22-original/bmm-brainstorming-session-2025-11-22.md`, `bmm-game-brief-Threshold-2025-11-22.md`, `adr-001-engine-selection.md` |
| **Canonical** | `game-brief.md`, `gdd.md`, `game-architecture.md`, `docs/adr/adr-001-engine-selection.md` |

---

## 2. The Role Model (Reverse RPG) was cut; The Anchor replaced it

| | |
|---|---|
| **Was** | _The Role Model_: Reverse RPG / Stat Decay. Start with high "Bad Traits" (Ego, Impatience) and lose levels in them. |
| **Became** | _The Anchor_: Physics balancing (_Death Stranding_ cargo style). Carry a heavy, fragile load through the final stretch. Growth is finding the strength to carry the new, not only shedding the old. |
| **Why** | Self-growth stayed as a theme, but a stat-decay RPG was a whole extra genre for a 2–3 hour anthology. Physics balance makes the same metaphor playable in one contained scene. |
| **Where it first appeared** | Brainstorming session; game brief Primary Mechanics. |
| **Where it was replaced** | GDD § "The Anchor (The Growth)"; narrative beat "Growth (Anchor)"; architecture § 4.6. |
| **Archive** | `archive/2025-11-22-original/bmm-brainstorming-session-2025-11-22.md`, `bmm-game-brief-Threshold-2025-11-22.md` |
| **Canonical** | `gdd.md`, `narrative-design.md`, `game-brief.md` |

---

## 3. The Outsider became The Tuner

| | |
|---|---|
| **Was** | _The Outsider_: Hidden Object / Signal Decoding. Scan static-filled ultrasound monitors for a clear signal. |
| **Became** | _The Tuner_: Tactile frequency puzzle (_Oxenfree_ radio style). Turn knobs and sliders until waveforms align and the image clears. |
| **Why** | The connection metaphor survived. Hidden-object scanning was too passive; physically tuning a signal makes the effort to bond with someone you have not met yet into the mechanic. |
| **Where it first appeared** | Brainstorming session; game brief Primary Mechanics. A leftover GDD Difficulty Curve line still said "_The Outsider_." |
| **Where it was replaced** | GDD § "The Tuner (The Connection)"; narrative beat "Connection (Tuner)"; architecture § 4.5. |
| **Archive** | `archive/2025-11-22-original/bmm-brainstorming-session-2025-11-22.md`, `bmm-game-brief-Threshold-2025-11-22.md`, `bmm-gdd-Threshold-2025-11-22.md` |
| **Canonical** | `gdd.md`, `narrative-design.md`, `game-brief.md` |

---

## 4. The story is a fertility journey, not a 9-month pregnancy

| | |
|---|---|
| **Was** | "Chronicle the 9 months of pregnancy and the immediate aftermath." Brief target audience was expectant/new dads, no fertility-struggle framing. |
| **Became** | Natural conception attempt → miscarriage during _The Protector_ → six months of IVF in _The Novice_ → pregnancy (_Provider, Tuner, Anchor, Mourner_) → birth. About a 14-month timeline. Audience includes people who have navigated fertility struggles. |
| **Why** | The GDD and narrative work on 2025-11-22 expanded the premise so loss and trying-again are the emotional spine, not a footnote. The brief was never updated. |
| **Where it first appeared** | Game brief Core Concept and Content Framework. |
| **Where it was replaced** | GDD executive summary and narrative arc; entire narrative-design document. |
| **Archive** | `archive/2025-11-22-original/bmm-game-brief-Threshold-2025-11-22.md` |
| **Canonical** | `gdd.md`, `narrative-design.md`, `game-brief.md` |

---

## 5. The hub is The New House, not an apartment/calendar/journal

| | |
|---|---|
| **Was** | Contemporary apartment/house; hub described as "a calendar, a journal, or the living room." GDD asset line still said "1 Main Hub (Apartment)." |
| **Became** | **The New House**: a first-person 3D hub that starts empty and cold and visually evolves after every minigame. It is also a character — it creaks, glows, and rots with Leo's internal state. |
| **Why** | Later design needed a persistent 3D space that could carry Edith Finch–style story sequences and physically manifest the psyche. A menu calendar could not do that. |
| **Where it first appeared** | Game brief World and Setting; leftover GDD Asset Requirements. |
| **Where it was replaced** | GDD Core Gameplay Loop and Hub Evolution; narrative "The House (Antagonist/Ally)"; architecture Hub System. |
| **Archive** | `archive/2025-11-22-original/bmm-game-brief-Threshold-2025-11-22.md`, `bmm-gdd-Threshold-2025-11-22.md` |
| **Canonical** | `gdd.md`, `narrative-design.md`, `game-architecture.md`, `game-brief.md` |

---

## 6. Total length is 2–3 hours, not ~30 minutes per minigame

| | |
|---|---|
| **Was** | Brief: 2–3 hours total. GDD: "~30 Minutes" per minigame (about 3.5 hours of minigames before hub and story). Architecture checkpoints assumed ~30m sessions. Designer pre-mortem also referred to a 30-minute Provider session. |
| **Became** | **2–3 hours total** including hub exploration, story sequences, and all seven archetypes. Each minigame targets **~10–15 minutes**. |
| **Why** | Settled 2026-09-20 when migrating these docs. The brief's total-length promise is the product constraint; thirty-minute chapters would blow past it. |
| **Where it first appeared** | GDD Core Gameplay Loop; architecture § 5.1 Checkpoints. |
| **Where it was replaced** | `gdd.md`, `game-brief.md`, `game-architecture.md` (2026-09-20 reconciliation). |
| **Archive** | `archive/2025-11-22-original/bmm-gdd-Threshold-2025-11-22.md`, `bmm-architecture-Threshold-2025-11-22.md` |
| **Canonical** | `game-brief.md`, `gdd.md`, `game-architecture.md` |

---

## 7. First slice is Hub + Provider + Protector, not The Novice

> _Superseded twice: on 2026-09-22 by House + The Partner, then on 2026-10-17 by "Spark to Silence" (entry 8)._

| | |
|---|---|
| **Was** | Brief MVP: Hub + Provider + Protector. Architecture Phase 2: build _The Novice_ (WarioWare) first; Protector slipped to production Batch 3. |
| **Became** | **First slice = Hub + _The Provider_ + _The Protector_.** Architecture Phase 1 remains the skeleton (GameState, SaveManager, greybox Hub). Phase 2 builds Provider and Protector and wires them to the Hub. _The Novice_ moves into production Batch 1 with _The Partner_. |
| **Why** | Settled 2026-09-20 when migrating these docs. The brief's MVP already named the two archetypes that prove the emotional contrast (bureaucracy anxiety vs. the forced-loss runner). Building Novice first would delay that proof. |
| **Where it first appeared** | Architecture § 6 Phase 2. |
| **Where it was replaced** | `game-brief.md`, `game-architecture.md` (2026-09-20 reconciliation). GDD Development Epics already listed Hub → Provider → Protector. |
| **Archive** | `archive/2025-11-22-original/bmm-architecture-Threshold-2025-11-22.md` |
| **Canonical** | `game-brief.md`, `gdd.md`, `game-architecture.md` |

---

## 8. First playable is "Spark to Silence"; whole game rough before depth (2026-10-17)

| | |
|---|---|
| **Was** | Epic 1 = 3D House + The Partner + title, pause, settings, quality, save, journal and look system. Then chapters in build order, Anchor last. |
| **Became** | M1 = rough House + short Partner + the Loss + the Silence + House in grief. M2 = every chapter rough, start to finish. Then chapter depth, then polish. |
| **Why** | The Partner alone tests only joy. The Loss is the biggest creative risk and needs the joy before it. Building the whole game rough early protects finishing it. |
| **Record** | [ADR-0002](../adr/0002-build-order-spark-to-silence.md), [roadmap.md](../roadmap.md) |

---

## 9. House uses fixed viewpoints, not tap-to-walk (2026-10-17)

| | |
|---|---|
| **Was** | Tap the floor and Leo walks there (navmesh). |
| **Became** | Tap a viewpoint; the camera glides to a framed shot. Short look-drag allowed. |
| **Why** | Much less work for one person with AI-generated assets; hides asset flaws; frames story beats. |
| **Record** | [ADR-0003](../adr/0003-house-fixed-viewpoints.md) |

---

## 10. Journal wording follows Stoic/Vulnerable; no Mastery in v1 (2026-10-17)

| | |
|---|---|
| **Was** | O1/O4: same journal words for every player. GDD/FR14: optional Mastery keepsakes. |
| **Became** | The Stoic/Vulnerable answer changes the matching journal wording. Mastery moves to "Later". |
| **Record** | [ADR-0004](../adr/0004-journal-wording-varies-no-mastery.md) |

---

## 11. AI-generated assets and text dialogue in v1 (2026-10-17)

| | |
|---|---|
| **Was** | Voice acting for Leo and Maya; asset source unspecified. |
| **Became** | AI-generated art and audio; dialogue as text with subtitles. Voice moves to "Later". |
| **Record** | [ADR-0005](../adr/0005-ai-assets-text-dialogue-v1.md) |

---

## 12. Story state is the list of finished chapters (2026-10-17)

| | |
|---|---|
| **Was** | A dictionary of narrative flags, checked by a test suite on every save/load for impossible combinations. |
| **Became** | The save holds the ordered list of finished chapters (plus Stoic/Vulnerable answers and settings). One core table derives story facts, House mood and journal entries. Impossible states cannot be saved. |
| **Why** | Follows directly from O1 (one result per chapter) and O2 (past and present facts together); simpler and safer. |
| **Record** | [game-architecture.md](game-architecture.md) §2.1 |

---

## 13. Performance bar is headroom on Dan's iPhone, not a bought mid-range phone (2026-10-17)

| | |
|---|---|
| **Was** | Roadmap M1 criterion: "smooth on one chosen mid-range phone"; the benchmark phone was an open M0 question. |
| **Became** | Dan's iPhone 17 Pro in Safari must show about 4× headroom (game work ≤ 4 ms per frame, 4× pixels still about 60 fps, memory and load limits), plus one spot check on a real mid-range Android before M1 playtests. |
| **Why** | Dan has only flagship iPhones and chose not to buy a ~$400 test phone. Measuring spare capacity on a fast phone approximates a phone about 4× slower. |
| **Record** | [scope.md](../scope.md) "Settled questions"; [roadmap.md](../roadmap.md) M1 criterion 1 |

---

## 14. Rhythm chapters get a "tap along to calibrate" step (2026-10-17)

| | |
|---|---|
| **Was** | One fixed adjustment for the phone's sound delay was expected to be enough; calibration was only a fallback to propose if the M0 rhythm check failed. |
| **Became** | A "tap along to calibrate" step is in v1. |
| **Why** | M0 Check 2 (DAS-68): laptop Chrome held steady at about −65 ms, but iPhone Safari with Godot's clock needed about −150 ms and the average drifted while Dan tapped on the beat, so no single fixed number worked. |
| **Record** | [scope.md](../scope.md) v1 table and "Settled questions" |

---

## 15. Sound plays even in iPhone silent mode (2026-10-17)

| | |
|---|---|
| **Was** | Nothing decided; Safari's default lets the ring/silent switch mute web audio, so a player in silent mode heard nothing. |
| **Became** | The web build sets Safari's audio session to "playback", so the game's sound plays in silent mode. |
| **Why** | Dan's call during the M0 rhythm check (DAS-68), where the setting was first added for testing. Rhythm chapters depend on sound. |
| **Record** | [scope.md](../scope.md) v1 table |

---

## 16. The Partner times taps with the browser's audio clock on the web (2026-10-18)

| | |
|---|---|
| **Was** | The Partner tracked song position with Godot's mix clock minus output latency (game-architecture 4.4). |
| **Became** | On the web it uses the browser's own audio clock and the touch's timestamp; native builds keep Godot's clock. |
| **Why** | M0 Check 2 (DAS-68) on iPhone Safari: Godot's clock needed about −150 ms and drifted one way; the browser clock needed about −70 ms, kept nearly every tap Good and wandered rather than drifted. Dan's call, 2026-10-18. |
| **Record** | [ADR-0006](../adr/0006-partner-browser-audio-clock.md), [game-architecture.md](game-architecture.md) 4.4 |

---

## 17. M0 viewpoint check judged by Dan alone; tap a thing to look at it (2026-10-18)

| | |
|---|---|
| **Was** | The viewpoint check passed only if Dan plus one or two people new to it moved around without getting lost. Viewpoints were spots you tapped to stand on. |
| **Became** | Dan judged it alone and passed it. A viewpoint frames one thing: you tap the thing and glide to a view looking at it; things out of view pin their ring to the screen edge with an arrow. Glide 2.0 s. |
| **Why** | Dan is developing and testing solo for now, so there are no other testers. Standing on the tapped spot went against what he expects; looking at what you tapped also fits later, when a tapped thing starts a task. Dan's call, 2026-10-18 (DAS-69). |
| **Record** | [scope.md](../scope.md) Settled questions, [2026-10-18 viewpoints playtest](../playtests/2026-10-18-m0-viewpoints.md) |

---

## 18. Automated gameplay tests start in M0, without an addon (2026-10-18)

| | |
|---|---|
| **Was** | No automated tests in M0; the test addon and the first tests (core table, saves) came in M1. Everything else was checked only by playing. |
| **Became** | Headless gameplay and logic tests in `game/tests/`, run by a small runner written in the repo, in every PR check. They cover the M0 checks now; every later feature adds its own. The addon question for the core table stays open for M1. |
| **Why** | Threads were proving their work with one-off scripted runs that were then thrown away. Kept as tests, those runs catch breakage before a build reaches Dan's phone. Dan's call, 2026-10-18. |
| **Record** | [scope.md](../scope.md) Settled questions, [game/tests/README.md](../../game/tests/README.md) |

---

## 19. Browser tests from M0 (2026-10-18)

| | |
|---|---|
| **Was** | Nothing tested the exported web build itself; only the script check and export, and Dan's phone. |
| **Became** | Playwright plays the exported web build in Chromium on every PR, at laptop and phone sizes, and checks it loads, has no console errors, starts sound only after a tap, and opens and leaves each screen. A test-only probe (web, `?probe` only) tells the tests what is on the canvas. |
| **Why** | So threads can prove more of their own work before it reaches Dan. Dan's call, 2026-10-18. His phone tests still decide feel, timing and Safari. |
| **Record** | [scope.md](../scope.md) Settled questions, [tests/web/README.md](../../tests/web/README.md) |

---

## 20. Saves built in M1, as a JSON file, tested without an addon (2026-10-19)

| | |
|---|---|
| **Was** | Save/Continue came in M2 (roadmap). Which test addon covers the core table and saves was open for M1. |
| **Became** | The save system is built in M1 (Continue and the title screen stay in M2). One JSON file in Godot's user folder, kept in IndexedDB on the web. The repo's own test runner covers it; no addon. |
| **Why** | Every chapter after the Partner needs the same way to record that it is finished. Dan asked for it now (2026-10-19). One code path works on web and PC; the runner already does what an addon would. |
| **Record** | [ADR-0007](../adr/0007-saves-json-file-in-user-folder.md), [scope.md](../scope.md) Settled questions |

---

## 21. House views: doorway views, wall views and close-ups (2026-10-19)

| | |
|---|---|
| **Was** | ADR-0003: tap a viewpoint (a spot or a doorway) and the camera glides there. Objects were tapped to use them directly. |
| **Became** | Each room has a doorway view and 2–4 wall views. Tapping an object opens its close-up; tapping it again does its one action. House objects that don't start a chapter are never required, scored or saved. |
| **Why** | Fits the M0 finding that tapping a thing should look at it (entry 17), hides AI-art flaws, and gives one verb for walls, House objects and chapter objects. Dan's call, 2026-10-19. |
| **Record** | [ADR-0008](../adr/0008-house-doorway-and-wall-views-close-ups.md) |

---

## 22. Claude may draft story words when Dan asks (2026-10-22)

| | |
|---|---|
| **Was** | CLAUDE.md: don't invent story, dialogue or journal wording; placeholders only. The narrative-craft skill never wrote story words. |
| **Became** | Claude drafts story words only when Dan asks, marks every line as a draft until he approves it, and tells him. |
| **Why** | Dan asked for drafts of the M1 House writing (2026-10-20) and approved them with edits; a first draft to react to was faster for him. Dan's call, 2026-10-22. |
| **Record** | CLAUDE.md "Changing things"; `.claude/skills/narrative-craft/SKILL.md`; [m1-words-draft.md](m1-words-draft.md) |

---

## 23. The House floor plan settled for M1 (2026-10-22)

| | |
|---|---|
| **Was** | The House's small floor plan was an open question in scope.md, with [house-floor-plan.md](house-floor-plan.md) marked "draft". |
| **Became** | Settled for M1 as the floor plan has it, until it can be seen in the game. Its remaining open calls are M2's. The core table (`game/_core/house/house_table.gd`) builds the four M1 story points from it. The opening beat's answer is held in memory and saved with the Partner's result. |
| **Why** | The House can't be built on a draft, and the open calls only matter after the Loss. Dan's call, 2026-10-22. |
| **Record** | [scope.md](../scope.md) Settled questions; [ADR-0007](../adr/0007-saves-json-file-in-user-folder.md) (the `opening` key); DAS-92 |

---

## 24. The House at real room sizes (2026-10-24)

| | |
|---|---|
| **Was** | Room sizes came from reading the floor-plan drawing at 40 px to the metre: about 17 by 12 m, with a 13 by 20 ft entry and oversized doors. |
| **Became** | Real sizes in feet for about 1,900 sq ft of living space, same layout: a coat closet in the entry, a dining area between the living room and the kitchen, the en-suite along the bedroom's north wall, hanging closets in the office and spare room. Ordinary furniture and door sizes. Draft until Dan OKs it in the game. |
| **Why** | In the first build the House read far smaller than its numbers and the rooms felt wrong; the drawing had no real sizes. Dan's calls, 2026-10-24. |
| **Record** | [house-floor-plan.md](house-floor-plan.md) "Real sizes"; [scope.md](../scope.md) Settled questions; DAS-93 (PR #30) |

---

## 25. Backing out of a room, the bathroom and the end of the hall (2026-10-25)

| | |
|---|---|
| **Was** | 17 views. A wall view had rings only to the room's doorways and its other wall views, so from the bed wall there was no way back to the bedroom's doorway view. The en-suite (ring "En-suite") was only looked into from its doorway. The back hall had one view, from its front end. |
| **Became** | 18 views. Every wall view has a ring back to its room's doorway view. The en-suite's ring says "Bathroom" and its view stands inside it, showing the vanity, toilet and shower. A new wall view, H2 ("End of hall"), stands near the far end of the hall to see the shut office and spare room doors. |
| **Why** | Dan's review of the real-size House in the game, 2026-10-25. |
| **Record** | [house-floor-plan.md](house-floor-plan.md) "Views (M1)"; [scope.md](../scope.md) Settled questions; DAS-93 (PR #30) |

---

## 26. The pregnancy runs full term; the story runs about 18 months (2026-10-25)

| | |
|---|---|
| **Was** | FR17: Provider month 10, Tuner, Anchor and Mourner months 11–13, the Arrival month 14. About a 14-month timeline (§4). That made the IVF pregnancy about five months long. |
| **Became** | Provider 10, Tuner 12, Anchor and Mourner 17, the Arrival 18: a normal pregnancy of about 40 weeks, with no premature birth. |
| **Why** | The journal pages are dated, and players who have been through IVF would notice a five-month pregnancy. Found in the story pass; Dan's call, 2026-10-25. |
| **Record** | [ADR-0009](../adr/0009-full-term-pregnancy-timeline.md); FR17 in [requirements.md](requirements.md); [narrative-design.md](narrative-design.md) timeline; the journal-date lines in [stories/](stories/) epics 5–8 |

---

## 27. No crib after the Loss (2026-10-25)

| | |
|---|---|
| **Was** | Story 2.4: after the Loss "the crib is put away, and boxes are out". |
| **Became** | There is no crib until the Anchor (one crib, one lifeline). After the Loss the spare room door is simply shut. |
| **Why** | The floor plan and continuity ledger already had no crib until the Anchor (Dan, 2026-10-19). Dan agreed the floor plan wins, 2026-10-25. |
| **Record** | [epic-2-stories.md](stories/epic-2-stories.md) Story 2.4; [continuity-ledger.md](continuity-ledger.md) (Crib) |

---

## 28. The Loss's run is 3D, seen from behind (2026-10-25)

| | |
|---|---|
| **Was** | game-architecture §4.2 and requirements: a 2D runner (`CharacterBody2D` on a `TileMap` path). The first Loss draft (2026-10-22) followed it with a side-on 2D view. |
| **Became** | A 3D run seen from behind, like Temple Run: the camera follows the light down a path that bends on its own. Built that way straight away, with no 2D test first. |
| **Why** | Dan's call, 2026-10-25: Temple Run is the game he had in mind. Seen from behind, the player looks where the light is going, so the path ahead and its giving way are felt more. The tap action, the timeline and the fade are unchanged. |
| **Record** | [the-loss-run-and-car.md](the-loss-run-and-car.md); [game-architecture.md](game-architecture.md) §4.2; [requirements.md](requirements.md) |

---

## 29. The loss is a night in month 2, some weeks after the test (2026-10-25)

| | |
|---|---|
| **Was** | The floor plan: the Loss starts "the night after the test". |
| **Became** | A night in month 2, some weeks after the test. |
| **Why** | FR17 puts the Loss at month 2 and the fridge note says week 5, so "the night after" didn't fit. Found in the Loss design; Dan's call, 2026-10-25. |
| **Record** | [house-floor-plan.md](house-floor-plan.md); [the-loss-run-and-car.md](the-loss-run-and-car.md) call 10; [continuity-ledger.md](continuity-ledger.md) (The night of the loss) |

---

## 30. The Loss is the night itself; nothing off screen is named (2026-10-25)

| | |
|---|---|
| **Was** | The car was "the drive home from the hospital", and the ledger said they left for the hospital in the night. Dan's story-pass note left open whether the loss was found at the first scan instead (story-beats). |
| **Became** | The night of the Loss: the lamp goes off, the run is that night, and the car comes later that same night. The scan is not used in the Loss. Moments are named only by what happens in the game (the lamp, the run, the car), never by places or events the player doesn't see; an object the player sees, such as the hospital bag, keeps its name. |
| **Why** | Hopper found the errand question unanswered after #28 merged. Dan picked the night of the Loss, then asked that the docs not name the hospital, since it is never seen. Dan's calls, 2026-10-25, in the project thread. |
| **Record** | [the-loss-run-and-car.md](the-loss-run-and-car.md) call 12; [continuity-ledger.md](continuity-ledger.md) (The night of the loss, Car keys, The car); [story-beats.md](story-beats.md) (the Loss, the Provider's bill); [house-floor-plan.md](house-floor-plan.md) (the dropped keys); `.claude/skills/narrative-craft/SKILL.md` |

---

## 31. Free asset packs first; AI only fills gaps (2026-10-26)

| | |
|---|---|
| **Was** | v1 art, music and sound are AI-generated (ADR-0005, §11). |
| **Became** | Free packs with commercial licenses first (CC0, CC-BY, royalty-free such as Sonniss); AI-generated assets only where no pack fits. Every asset is listed in CREDITS.md. Text dialogue and no voice acting are unchanged. |
| **Why** | Packs look more consistent than AI models, have clear terms for Steam, and shrink the AI disclosure. Dan's call, 2026-10-26, in the project thread. |
| **Record** | [ADR-0010](../adr/0010-free-asset-packs-first-ai-fills-gaps.md); [scope.md](../scope.md); [CREDITS.md](../../CREDITS.md); [asset-sources.md](asset-sources.md); DAS-101 |

---

## 32. M1.5, an asset pass after M1 (2026-10-26)

| | |
|---|---|
| **Was** | Final art came later (M3+ chapter looks, then Polish & Ship); M1 lists "final art" as not in M1, and no milestone covered an art pass on what is built. |
| **Became** | Finish M1, then M1.5 replaces the gray-box art of what M1 built (the House, the Loss and its car, the Partner) with free packs under ADR-0010, and AI-made Partner pictures where no pack fits (Dan, 2026-10-27: no art budget). |
| **Why** | Free packs make an art pass cheap now, and the House and Loss gain the most from it. Dan's call, 2026-10-26, in the project thread. |
| **Record** | [roadmap.md](../roadmap.md); DAS-104 |

---

## 33. The Loss's run: the father's hand and three lanes, trees, and a storm that never stops (2026-10-25)

| | |
|---|---|
| **Was** | The first Loss design and its rough build: tap anywhere clears the next obstacle; a pale, open path floating over a void; at 2:55 the song and storm stop dead, the world turns a lighter gray, and the light goes out in silence. |
| **Became** | Tap the left or right of the screen and the father's hand moves the light one lane that way (changed the same day after Dan's second play, call 17: at first each third of the screen was a lane); with a gap in reach the hand also lies across it. A trail through tall trees at the end of the day, with real shadows. The song drowns under a storm that never stops, through the light going out and into the car, and nothing gets lighter. The light starts as small as the fridge note's sesame seed and goes out in the father's open hand. |
| **Why** | Dan's first play of the rough build, 2026-10-25: tap anywhere was too easy and too like the Partner; the light should be visibly protected by an outside force, the father; the setting was too bright and ethereal; the silence after the song felt like a mistake, the storm didn't come through, and the lighter gray read as the storm ending; the light needed to read as the baby, subtly. Still one tap scheme: lanes are tapped, never swiped. |
| **Record** | [the-loss-run-and-car.md](the-loss-run-and-car.md) calls 13 to 16 (and 2, 4, 5, 11); [continuity-ledger.md](continuity-ledger.md) (Rain, the couple's song, the small light, the father's hand); [scope.md](../scope.md) |

---

## 34. The Loss's ending: fireflies go out at random, and a shorter storm (2026-10-26)

| | |
|---|---|
| **Was** | From 2:55 the light runs on down an empty path, slows and goes out in the father's hand with nothing else happening; the panic lasts 40 s with 25 obstacles (49 in all) and black is at 3:35. |
| **Became** | Fireflies drift along the trail from the euphoria; when the path empties at 2:45 they go out one by one at random (a fixed order that looks random), some never, and one or two still glow as the light goes out in the hand. The panic lasts 30 s with 17 obstacles (41 in all), and everything after it moves 10 s earlier: black at 3:25. |
| **Why** | Dan's third play, 2026-10-26: the storm felt a little long, and the light going out needed something to happen that shows the randomness more explicitly in the last 45 seconds. Fireflies show chance without giving the loss a cause the player could have stopped. Dan may still want more, possibly a last obstacle nobody can clear (open). |
| **Record** | [the-loss-run-and-car.md](the-loss-run-and-car.md) call 18; [continuity-ledger.md](continuity-ledger.md) (Fireflies, the small light, the couple's song); [scope.md](../scope.md) |

---

## 35. The Loss's gaps: press and hold, not the lane tap (2026-10-27)

| | |
|---|---|
| **Was** | A tap on the left or right half moved the light one lane and, with a gap in reach, also laid the father's hand across it. |
| **Became** | A tap (under 0.2 s) moves the lane, when the finger lifts. Pressing and holding anywhere lays the hand across a gap in reach for as long as the finger is down; letting go before the gap reaches the light lifts it and the light stumbles. A hold never moves the lane. Still one pointer, click is tap, nothing on hover. |
| **Why** | Dan's third play, 2026-10-26: "closing the gap is a different action than moving lanes, and having them be exactly the same doesn't quite feel right". He picked press and hold on a decision card (2026-10-27) over tapping the light itself, a double tap, or no change. |
| **Record** | [the-loss-run-and-car.md](the-loss-run-and-car.md) call 19 (and 13); [scope.md](../scope.md) |

## 36. The Loss's run: about 2:45, hints, and a fallen tree at the end (2026-10-27)

| | |
|---|---|
| **Was** | 5 s of black; the euphoria 0:05–1:25 (12 obstacles: 0:13 S M, 0:18 S L+R, 0:24 B LM, 0:29 S R, 0:34 G, 0:40 B MR, 0:45 S L, 0:50 G, 0:56 B LM, 1:01 S M, 1:06 G, 1:12 S L+R); the confusion 1:25–2:15 (12: 1:29 S L+M, 1:33 G, 1:39 B MR, 1:42 S L, 1:48 S R, 1:50 B LM, 1:56 G, 1:59 S M+R, 2:02 B LM, 2:06 G, 2:09 S L+R, 2:13 G); the panic 2:15–2:45 (17 in clusters 0.6 s apart, gap reach 0.8 s: 2:17 S L, S R; 2:20 B LM, S M, G; 2:25 G, S R; 2:28 S M, B MR, S M; 2:32 B LM, G; 2:36 S R, S M, G; 2:39 G, B MR); the song gone at 2:45; the light slowed to a stop on the empty path from 2:55 to 3:05, settling into the hand, out by 3:15; black at 3:25. Branches reached close to the free lane. No words on screen at all. After switching tabs the sound could stay lost. |
| **Became** | 3 s of black; the euphoria 0:03–1:03 (9 obstacles); the confusion 1:03–1:43 (10); the panic 1:43–2:08 (12, clusters 0.8 s apart, gap reach 1.0 s, ending on a single stone); the song gone at 2:08; a fallen tree across the whole path, where the light stops at 2:22 and the hand then comes under it; out by 2:35; black at 2:45. Shorter branches. "tap here" on both halves at the start and "hold" for the first two gaps. The sound comes back with the tab. |
| **Why** | Dan's fourth play, 2026-10-27: the start and the song felt long coming straight from the Partner's same song; he wanted about 2:45 in all; the far side of a branch didn't read as clear; both actions needed a word on screen the first time; in the dark the obstacles got too rapid and a miss could look like the reason for the loss; and he asked for "some sort of 'final unclearable obstacle' that the light runs into and can't get past, and then the hand comes in". Dan picked the fallen tree on a decision card (2026-10-27), over a gap too wide for the hand, or the path just ending. |
| **Record** | [the-loss-run-and-car.md](the-loss-run-and-car.md) call 20 (and 3, 4); [scope.md](../scope.md); [continuity-ledger.md](continuity-ledger.md) |

---

## 37. The House's look is realistic; M1.5 starts before M1 ends (2026-10-29)

| | |
|---|---|
| **Was** | The House's look, realistic or soft low-poly, was an open question for M3+, with realistic recommended; M1.5 started only once M1 was done. |
| **Became** | Realistic (Poly Haven and ambientCG, CC0), tried on the living room on Dan's phone first. The Loss and House art passes start now, alongside the last M1 tickets. |
| **Why** | Dan asked to swap the whole House and the whole Loss to asset packs now, "as nice as possible while maintaining performance targets", and picked realistic on a decision card. |
| **Record** | [scope.md](../scope.md); [roadmap.md](../roadmap.md); [asset-sources.md](asset-sources.md); DAS-106, DAS-107 |

---

## What did not change

- Godot 4.x and GDScript.
- Genre-as-metaphor anthology with seven chapters plus intro/outro.
- Fail-forward progression and optional mastery goals.
- ~~PC/Steam primary, mobile secondary, mouse/touch-first.~~ _Changed 2026-09-20 (UX pass): browser first, mobile second, PC/Steam third, one tap scheme._
- Pre-mortem mitigations (QualityManager, Stability Assist as Maya's voice, reflowed invoice reader, `_integrate_forces()` smoothing, Novice tonal ramp) — those already lived in the GDD and architecture and stay there.

---

## How to use this in later GDS workflows

- Treat the files in `docs/design/` and `docs/adr/` as current. Where they disagree, the newer decision wins (see `CLAUDE.md`).
- The brainstorming session and agent reports are in `archive/2026-10-bmad/` as dated source material, not specs.
- If a new workflow rediscovers "deckbuilder," "Role Model," "Outsider," or "9 months of pregnancy," it is reading archive or brainstorm text. Point it here.
