---
stepsCompleted:
  - step-01-validate-prerequisites
  - step-02-design-epics
inputDocuments:
  - _bmad-output/planning-artifacts/gdd.md
  - _bmad-output/planning-artifacts/game-architecture.md
  - _bmad-output/planning-artifacts/narrative-design.md
  - _bmad-output/planning-artifacts/ux-designs/ux-Threshold-2026-09-20/DESIGN.md
  - _bmad-output/planning-artifacts/ux-designs/ux-Threshold-2026-09-20/EXPERIENCE.md
  - _bmad-output/planning-artifacts/epic-structure-decisions-2026-09-22.md
---

# Threshold - Epic Breakdown

## Overview

This file is the list of epics. Each epic's stories live in their own file. When a story is built, its task file points at that epic's stories file.

| Epic | Stories |
| --- | --- |
| 1. The Spark in the New House | [epic-1-stories.md](epic-1-stories.md) |
| 2. The Loss | epic-2-stories.md, when written |
| 3. The Long Haul | epic-3-stories.md, when written |
| 4. The Cost | epic-4-stories.md, when written |
| 5. Hear Them | epic-5-stories.md, when written |
| 6. Make Space | epic-6-stories.md, when written |
| 7. Carry the Weight | epic-7-stories.md, when written |
| 8. The Arrival | epic-8-stories.md, when written |

## Requirements Inventory

### Functional Requirements

FR1: Threshold is a single-player narrative anthology. There is no multiplayer, no character customization, and no open city. The New House is a contained space.

FR2: The protagonist is Leo, a defined character. Maya is the partner. The baby is an NPC. Leo is a fixer who believes his value comes from what he provides, and his arc is learning he cannot fix everything and must be present. Maya is witty, resilient, and anxious; she over-researches everyday details and wants to be heard, not fixed. Their humor is couple comedy about those worries.

FR3: Gameplay is the language of emotion. When Leo feels overwhelmed, controls feel slippery. When he feels focused, gameplay is precise. The game does not explain the metaphor on screen.

FR4: The tone is grounded and serious. Clumsy-dad comedy is not the voice of the game. Every segment, including the dark ones, still contains one moment of levity or human awkwardness, and the UI does not underline that beat.

FR5: Dialogue is naturalistic couple shorthand: overlapping speech, unfinished sentences, and subtext. A line such as "Did you pay the gas bill?" carries the fear. The game does not put "Are we going to be okay?" on screen as an objective.

FR6: Three set-piece conversations exist. The Injection: Maya asks Leo to help with her IVF shot, and he is afraid of hurting her. The Silence: after the loss, they sit in the car with no words, only rain. The Panic: Leo tries to build the crib without instructions, and Maya laughs.

FR7: Dialogue offers Stoic or Vulnerable micro-choices. The choice does not change the plot. It changes the tone of that scene and the wording of the related Dad's Journal entry.

FR8: Voice scope is Leo internal monologue (heavy) and dialogue (medium), Maya dialogue (medium), and other voices such as a boss or doctor muffled and indistinct so attention stays on the couple.

FR9: Writing scope is about 5,000 words of dialogue and about 2,000 words of journal entries and flavor text.

FR10: The core loop is Hub (The New House), then a Story Sequence, then an object Trigger, then a minigame, then a resolution in which the House transforms. Nothing in the House requires a nested menu to start play. The object is the door.

FR11: Story Sequences are first-person narrative beats in the House, in the manner of What Remains of Edith Finch. They deliver plot between chapters, such as the decision to try IVF. The player still walks and looks with the same tap scheme. Subtitles may show. Chapter HUD does not.

FR12: Each minigame lasts about 10–15 minutes. Seven archetypes plus hub exploration and story sequences land in 2–3 hours total.

FR13: Most minigames fail forward. Failure may change the narrative outcome or raise Stress. It does not halt the story or show a game-over wall.

FR14: Each minigame may offer an optional Mastery goal. Mastery leaves an extra insight or memento in the House as an object, not a trophy toast.

FR15: Completing a minigame is the key that opens the next room or chapter. Named rooms and a floor plan are not specified and must not be invented.

FR16: Chronological play order is The Partner (natural conception), The Protector (miscarriage), The Novice (six months of IVF), then The Provider, The Tuner, The Anchor, and The Mourner (the pregnancy wait), then The Ending.

FR17: The calendar the journal and House can follow is Month 0 Partner, Month 2 Protector, Months 3–9 Novice, Month 10 Provider, Months 11–13 Tuner then Anchor then Mourner, and Month 14 the arrival. The Novice stretch starts desaturated and quiet. Color and chaos bleed in as the hormones take effect.

FR18: The Partner is a rhythm chapter about trying to conceive. The player hits Connection Nodes in time with Maya's heartbeat or voice. It starts slow and intimate and builds to a joyous crescendo. A missed cue plays as awkward laughter, the song still ends, and the result is a positive pregnancy test.

FR19: The Protector is a forced-loss runner. It starts sunny and clear while the couple is planning, then the path crumbles, obstacles become unavoidable, and the pacing runs euphoria, confusion, panic, silence. The runner fades even if the player played perfectly. There is no warning, no skip, and no retry prompt. Returning players resume in the changed House.

FR20: Protector obstacles are authored, stitched set pieces. They are not an unbounded random generator. Any stress modulation still serves that authored loss.

FR21: The Novice is a WarioWare-style chapter covering six months of egg retrievals and the absurdity of amateur science at home. A numbing bridge sits between the tragedy of The Protector and this chaos. It begins desaturated, slow, and quiet, then becomes funny, frantic, and colorful. The struggle ends in conception by IVF.

FR22: Novice micro-games are one gesture and a short prompt. The named set includes "OPEN THE BOX!", "MIX THE POWDER!", "INJECT THE BUTT!", and "DON'T FAINT!". The first production batch ships the framework plus three micro-games. The six-month montage has three phases: slow confused input, fast high-skill input, then exhaustion in which inputs sometimes ignore the player.

FR23: The Provider is a bureaucracy simulation in the manner of Papers, Please. The player reviews invoices, insurance claims, and bank statements, cross-references codes, denies bad bills, and approves valid payments before a Due Date timer expires. A Bank Account meter drains, and mistakes cost money. The system is felt as confusing. The UI does not announce that it is confusing.

FR24: Provider play is three acts: The Invoices, The Insurance, and The Audit. Documents grow more complex in Act 2. A sequence of bills can tell one micro-story, such as a specific injury, instead of unrelated random forms. When the Due Date reaches zero, the story fail-forwards and the desk does not trap the player.

FR25: Tapping a Provider document opens Reflowed Reader View: reflowed large type that replaces the page. It is not pinch-zoom and not a magnified screenshot of the desk texture. Stamps are applied on the desk, not inside the reader. If a page cannot reflow, the player stays on the desk and sees a short "can't enlarge this page."

FR26: The Tuner is a tactile frequency puzzle. The player turns knobs and sliders until waveforms align and the image clears, trying to hear the baby through monitor static. Misaligned controls stay noisy. There is no "wrong" popup. The cleared image is the reward.

FR27: The Anchor is a physics-balance chapter. Leo carries a heavy, fragile load through a storm or cluttered house. Growth is the strength to carry the new, not only shedding the old. Left and right are two on-screen hold zones, the same on browser and phone. They are not triggers, keys, or a virtual stick.

FR28: On The Anchor, the third fall plays Maya's Voice ("You've got this.") and then invisible Stability Assist so the story can be finished. There is no badge, difficulty toast, or cheat label. Further falls before the third stay in the same chapter and still fail forward. If the load touches the ground, Stress may rise. The chapter does not become a hard reset wall.

FR29: The Mourner is zen unpacking. The player packs away the grief of the miscarriage and clears pre-parent clutter (hobbies, old furniture, single life) to make room for the arrival. Grab, move, and drop. An invalid drop snaps back. Final placement can persist into the House.

FR30: The Ending reuses Tuner (hear the cry, tune the baby monitor) and Partner rhythm (hold the hand). The baby is those skills, not a cutscene-only model. A miss still fail-forwards. There is no game-over at the arrival. The House is the last room, not a credits menu.

FR31: The New House starts empty and cold and changes after every minigame: renovations, furniture, warmer light, or longer shadows, plus weather and state of repair. It creaks when Leo is anxious, glows when he is hopeful, and rots when he is grieving. Hope and grief are read in the room, not in a popup.

FR32: Dad's Journal is an object in the House. Entries track medical facts and emotional reality. The empty state is a blank dated page with no writing prompt. The first entry appears after a completed chapter. Stoic or Vulnerable changes the prose only.

FR33: Emotional pacing places a meditative chapter after high stress (The Mourner after The Provider) and uses Novice comedy and Tuner quiet joy to balance infertility and anxiety. Minigames adapt slightly so the player can complete the story.

FR34: One pointer scheme on every platform. Tap walks, looks, and interacts. A click is a tap. Drag and hold exist only for Tuner knobs, Mourner placement, a short look, and Anchor hold zones. Keyboard Enter activates the focused menu control and is not a second way to move.

FR35: The score shifts genre with the chapter (synthwave for The Provider, acoustic or piano for The Mourner). Sound design includes domestic detail: rain, the fridge hum, and the heartbeat on the monitor.

FR36: Each minigame has its own visual skin. The House stays one grounded world. A skin does not add a second control scheme or a second menu system.

### NonFunctional Requirements

NFR1: Ship one build in this order: browser first, mobile second, PC/Steam third. PC/Steam uses the same tap scheme and the same HUD. It is not a separate mouse-look build and not the performance target the game is tuned for first.

NFR2: The primary performance bar is a playable phone-width browser. On low-end devices, QualityManager may disable volumetric fog, SSAO, and expensive shaders, and may swap a Sobel outline for a cheaper unshaded outline. Outlines that show what can be tapped stay.

NFR3: The engine is Godot 4.x and the language is GDScript. The expected team is 1–3 people, using a mix of custom and modified store assets.

NFR4: There is no second movement scheme: no WASD House controls, no virtual stick, no mouse-look pointer lock, no gamepad or couch mode, and no control remapping in this pass.

NFR5: Save and load must preserve a valid story. Mutually exclusive states, such as pregnant and miscarried at the same time, must not coexist. A failed save does not block play. The last good checkpoint still loads.

NFR6: Accessibility for this pass is a hobby floor: tap targets at least 44px, subtitles on by default, Reflowed Reader View for long text, status never by hue alone, and a reduced-motion toggle. It is not a full AbleGamers checklist and does not include a colorblind filter suite.

NFR7: The Loss chapter cannot be skipped. Care is the content and the pacing, not an exit dialog.

NFR8: Dialogue stays near 5,000 words and journal or flavor text near 2,000 words, so chapter content does not blow the 2–3 hour game.

### Additional Requirements

- No starter template is specified. The first implementation story is a new Godot 4.x project and git repository, not a cloned kit.
- Project layout under `res://` is `_core/` (audio, save_system, state_manager), `assets/`, `scenes/hub/`, `scenes/minigames/` (one folder per chapter), `scenes/ui/`, and `scripts/`.
- `GameState.gd` is the brain. It tracks `current_act`, `minigames_completed`, narrative flags (`ivf_started`, `miscarriage_occurred`, `baby_born`), and house flags (at least `nursery_painted` and `boxes_packed`). `change_act` drives global music and lighting changes.
- `AudioManager` modulates a procedural hum (fridge or furnace) from an anxiety level. That field is not in the `GameState` example and must be added to state rather than left as a one-off.
- `HubManager.gd` is a visual state machine. The House is split into BaseLayer (walls), PropLayer (dynamic objects), and LightingLayer. On ready, nodes toggle from `GameState`. Example: after the miscarriage, hide the nursery crib and show boxes.
- A unit-test suite runs on every save and load and rejects invalid `GameState`.
- `HouseController.gd` moves a `CharacterBody3D` by a tap on the floor, changes view by a tap on a view target, and starts a chapter by a tap on a `MinigameTrigger`. The hit ray comes from the pointer, not the center of the camera. `Door`, `MinigameTrigger`, and `Journal` share an interactable base. The tappable object highlights. There is no crosshair.
- `NarrativeTrigger.gd` uses `Area3D` volumes. On enter it plays one voiceover through `AudioManager`, shows a subtitle, and usually disables itself after one play, tracked in `GameState`. Critical beats may ease the camera toward a point of interest.
- `MinigameLoader.gd` unloads or pauses the House, loads the minigame scene, passes difficulty and settings, and writes win or loss back into `GameState`.
- Chapter look comes from shared post-processing and shaders, not seven art pipelines. Provider: high-contrast black and white, rain, neon outlines on stamps and forms. Novice: saturation, Sobel outline, squash-and-stretch. Tuner: chromatic aberration, grain, fragmentation. House: realistic PBR plus volumetric fog as the grounding look. The GDD lines that allow a hand-drawn hub, or a neon crib as the Provider image, are not requirements.
- `QualityManager.gd` detects hardware at launch and applies the high-end versus low-end split in NFR2.
- Provider data is a `DocumentData` resource (text, type, valid codes, error flags) checked by a `DocumentValidator` against the player's stamp. Documents are Control nodes. Stamps are `TextureRect` marks for Approve and Deny. Act 2 may put more pages and smaller type on the desk texture. Smaller type must not be the phone reading path. Reflowed Reader View is.
- Protector uses a `CharacterBody2D` runner and a `TileMap` path. Obstacles are the stitched set pieces in FR20.
- Novice uses a `MicroGameManager` that instances `MicroGameBase` scenes, a montage for the six-month timeline, and `Engine.time_scale` to speed the montage. The first anthology batch is the framework plus three micro-games (FR22).
- Partner uses a scene-local `Conductor.gd` synced with `AudioServer.get_time_since_last_mix()` minus output latency. Beatmaps are JSON timestamp arrays. The listener scores Perfect, Good, or Miss from song time versus target time.
- Tuner uses a `SignalShader` with uniforms for frequency, amplitude, and noise offset, driven by two Control knobs. Within tolerance, noise alpha falls and the image shows through.
- Anchor uses `RigidBody3D` for Leo, `PhysicalBone3D` for limbs, and a `BalanceController` that applies torque in `_integrate_forces()`. Do not use `add_force()` in `_process()`. Physics jitter may be masked with a shivering animation. Input is the two hold zones in FR27. Architecture §4.6's "left/right triggers or keys" is superseded.
- Mourner uses a drag-drop controller with item states `IN_BOX`, `HELD`, and `PLACED`, and placement zones. The pointer model is tap and drag, matching the one scheme. Final placement may be stored on `GameState.house_state`.
- `SaveManager.gd` serializes `GameState` to JSON. The game auto-saves when a minigame completes. Every minigame implements `save_checkpoint()` for local state such as document progress or song position, including quit, crash, and the browser tab or phone going to the background.
- If the scene fails to load, return to the title with Play, and with Continue when a checkpoint exists.
- Build order is architecture §6. Phase 1: Godot project, git, `GameState`, `SaveManager`. Phase 2 first slice: playable 3D House, the tap controls, `MinigameLoader`, The Partner, and a return to a changed House. Phase 3: shader pipeline and House states wired to `GameState`. Phase 4 Batch 1: Provider, Protector, and Novice. Batch 2: Tuner and Mourner. Batch 3: Anchor. Then connect any remaining minigames to the House. Phase 5: dynamic audio mixing, save testing, and shader profiling against the browser and phone bar.
- Input, audio, and settings are shared across every genre.
- Decision history is not a source. Do not reintroduce a deckbuilder, The Role Model, The Outsider, an apartment or calendar hub, 30-minute chapters, a Provider-first slice, or PC-primary controls.

### UX Design Requirements

UX-DR1: Implement the House and shared-menu color tokens exactly: surface `#1C1916`, surface-raised `#2A2520`, ink `#F4EFE6`, ink-muted `#9A9084`, accent `#C4A574`, border `#3D3832`, scrim `#0C0B0A`, subtitle-bg `#1C1916` at 80% opacity, house-hope `#E8D4A8`, house-grief `#5C534C`, stamp-approve `#2F6B4F`, stamp-deny `#8B3A32`, meter-bank `#C4A574`, meter-stress `#8B3A32`, focus-ring `#C4A574`. Bank, accent, and focus-ring are one swatch used as three roles. Chapter skins may replace this palette while that minigame is loaded.

UX-DR2: Godot Control theme uses Source Serif 4 for display (32px, weight 600, line-height 1.2), Source Sans 3 for body (16px, 400, 1.45) and subtitles (18px, 500, 1.4), IBM Plex Mono for numbers (16px, 500, 1.2), reader text (Source Sans 3, 20px, 400, 1.45), and micro-shout (Source Sans 3, 28px, 700, line-height 1.1, letter-spacing 0.04em). Digits do not animate or restyle mid-count. The Novice shout is the only all-caps, high-weight overlay, and it never appears in the House.

UX-DR3: Layout is an 8px grid with a 24px safe inset on phone and on desktop. Corner radius is 4, 8, 12, or full pill. Menus are one column, about 480px wide, centered on the scrim. Phone is the layout default: one column, notch inset, primary actions in bottom-end thumb reach. A wide desktop window gives more room to the House. It does not grow a PC HUD.

UX-DR4: Contrast floor is ink on surface at least 4.5:1, and ink on the subtitle scrim at least 4.5:1 over a worst-case bright House plate. Muted ink is never the only cue for something the player must do. Bank versus Stress uses number, track shape, and stamp. Hue is extra. Approve and Deny are read as the words APPROVE and DENY. A chapter skin must keep one high-contrast text-on-surface pair.

UX-DR5: `button-primary` is accent fill, surface label, 8px radius, at least 44px tall. Use one per screen when possible (Play on the title, Resume on pause). Pressed state is a slightly darker fill.

UX-DR6: `button-quiet` is transparent, ink label, 1px border, at least 44px tall, for Settings, Continue, and other secondary actions. When there is no checkpoint, Continue is omitted. It is not a disabled control.

UX-DR7: `panel` is surface-raised, 1px border, 8px radius. It is used for pause and Settings only. Panels never stack.

UX-DR8: `subtitle-bar` is ink on the subtitle scrim at subtitle size, bottom-center, with no speaker nameplate in the House. It shows while the line plays, then leaves. Subtitles are on by default.

UX-DR9: `interact-highlight` is an accent outline or warmth on a Door, MinigameTrigger, or Journal that is in range, and it turns off when nothing is in range. There is no crosshair, quest marker, or persistent prompt plaque. If it cannot be tapped, it is not the path. No hover-only affordance.

UX-DR10: `stamp` is a circular APPROVE or DENY word mark in the approve and deny colors, ink on paper, not a HUD chip. A tap stamps. A hold is not required.

UX-DR11: `reader-view` (display name Reflowed Reader View) is ink-colored paper with surface-colored type at reader size. It replaces the document. Dismiss returns to the desk.

UX-DR12: `meter` is a rectangular track in the border color, filled with meter-bank or meter-stress, with the number always visible in numeric type, in the top-start slot. Due Date and Bank Account use this slot. Do not invent a meter the chapter does not need. Empty corners stay empty.

UX-DR13: `journal` is Dad's Journal. The opened page is display serif on surface-raised. Stoic or Vulnerable does not swap the skin.

UX-DR14: `pause` is the scrim over the scene plus one panel: Resume, Settings, and back to title. It replaces whatever overlay was up. Default focus is Resume, with a 2px focus ring. Quitting to title mid-chapter asks for a second tap ("Leave this?"). Backgrounding the browser tab or interrupting the phone pauses and calls `save_checkpoint()`. Browser back returns to Settings or pause, not a broken scene stack. "Couldn't save." is a non-blocking line. Play continues, and the last checkpoint still loads.

UX-DR15: The title offers Play, Continue, and Settings over a faint view of the House. Play is the default focus. Continue is hidden when there is no checkpoint. Play with no save starts a new wander in the House.

UX-DR16: Settings, from the title or from pause, contains subtitles, reduced motion, and quality (QualityManager). It is one level deep.

UX-DR17: `knobs` are Tuner dials at least 44px, in accent. The waveform is the value. There is no legend plate or tooltip.

UX-DR18: `rhythm-judgment` shows Perfect, Good, or Miss in numeric type near the hit, in ink. There is no combo tower and no grade screen in the House.

UX-DR19: `novice-shout` uses micro-shout type, full-screen or upper-third, then it is gone. Early micro-games are slow and quiet. The shout style stays inside The Novice.

UX-DR20: `drag-drop` ghosts in accent. An invalid drop uses the stress color and snaps back. There is no inventory grid unless an item is in hand.

UX-DR21: `balance` is two hold zones, at least 44px, idle color border, left and right tap-hold. Almost no other HUD. Maya's voice is the assist cue. There is no Stability meter.

UX-DR22: `provider-desk` lays documents out as Control pages on ink-colored paper. Tap opens `reader-view`. Stamps happen on the desk. Due Date and Bank Account sit in the top-start meter slot. A mis-stamp drains money in the stress color. The number ticks in numeric type. The stamp sound is an ink thunk.

UX-DR23: House overlay is subtitles and, when needed, a small pause control. No health, minimap, quest log, or stick. During a minigame the House chrome is gone and the chapter skin is up. Recurring HUD kinds keep their regions: status or resource top-start, a spatial map bottom-start only if that chapter truly needs one, primary action bottom-end, or center when the genre is the document itself.

UX-DR24: Tap-to-move walks Leo to a point on the floor or navmesh. Tap-to-look taps a view target or uses a short drag. Both use the same control path on web and mobile. They are not separate components from the House controls.

UX-DR25: Menu focus draws a 2px focus ring on the focused Control. Default is Play on the title and Resume on pause. Enter activates that Control. Prompts use words or the object itself. No Xbox or PlayStation glyphs.

UX-DR26: Reduced motion removes camera sway, hit-shake, and any required color-bleed animation. The Novice saturation change may be a cut or a slow fade. Tuner static may clear without a celebratory effect. Loss does not add juice.

UX-DR27: First wander in the House can last minutes with no objective marker. The Trigger is noticed from light, sound, and `interact-highlight`. A Story Sequence may ease the camera toward a beat while the HUD stays empty except the subtitle bar. Leaving the tab resumes in the House, not at the title, once a checkpoint exists.

UX-DR28: The Loss presentation adds no care UI, warning, skip, or "Chapter failed. Try again?" After it, the House reads grief with `house-grief`. Hope in the House reads as glow biased toward `house-hope`. The Novice then starts gray and slow.

UX-DR29: Partner feedback is a short sound plus Perfect, Good, or Miss. A miss may be awkward laughter. Anchor feedback is weight and jitter. Mourner feedback is a soft placement and household ASMR. A successful tap in the House is a highlight or a footfall, not a UI burst.

UX-DR30: UI has two layers. The world holds the House, highlights, and diegetic objects. The overlay holds subtitles, the thin title or pause, chapter HUD, and Reader View. Pause replaces the overlay. Reader View replaces the invoice. No stacked modals.

UX-DR31: Copy must not say "Low empathy warning.", "Difficulty increased.", "Stability Assist ON.", or explain a metaphor in a tooltip. Maya's assist line is "You've got this."

UX-DR32: These surfaces exist and only these roles: Title, The New House, Story Sequence, Trigger, The Partner, The Protector, The Novice, The Provider, The Tuner, The Anchor, The Mourner, The Ending, Dad's Journal, pause, Settings, and Reflowed Reader View. Spines win over the HTML mockups if they conflict. Provider copy in the mock is a behavior sample, not final chapter text.

### FR Coverage Map

FR1: Epic 1 — One player, Leo, in the New House. No second player, no character creator, no city.

FR2: Epic 1 — Leo and Maya are themselves from the first visit. Later epics continue their story.

FR3: Epic 1 — The House and The Partner carry how Leo feels. Each later chapter does that for its own play.

FR4: Epic 1 — The tone stays grounded. The Partner's human beat is the missed cue. Each later chapter keeps one beat like that.

FR5: Epic 1 — The opening story beat uses couple shorthand. The shot scene is Epic 3. The crib scene is Epic 7. The car after the loss (Epic 2) has no dialogue.

FR6: Epic 2 (the quiet car), Epic 3 (the shot), Epic 7 (the crib). Write the quiet car and the numb stretch in Epic 3 in the same week.

FR7: Epic 1 — One closed-off or open line in the opening. The spoken words can differ. The journal, the items, and the story stay the same. Later dialogue chapters may offer the same kind of line.

FR8: Epic 1 — Leo and Maya can be heard in the opening and in The Partner. Muffled outside voices belong to the chapters that need them.

FR9: Every epic — Dialogue is sketched across the whole game. Word count, pacing, and phone speed are checked while each chapter is built. The guide stays loose. Epic 8 does not own these checks.

FR10: Epic 1 — One full loop: the House, one story beat, a trigger, The Partner, a House that has changed.

FR11: Epic 1 — The first story beat, still walked with the same taps. Later epics add their own beats.

FR12: Epic 1 owns The Partner's length. Each chapter epic owns its own stretch of about 10–15 minutes. The 2–3 hour total is checked loosely as the game grows.

FR13: Epic 1 — A miss in The Partner still finishes the song and the same ending. Each chapter epic moves the story on to its one ending.

FR14: No epic grants a personal keepsake. A harder optional moment must leave the House objects the same for every player.

FR15: Epic 1 — Finishing The Partner lets the story move on. Named rooms are not invented. Later epics use the same rule.

FR16: Players meet the chapters as Partner, Loss, Long Haul, Cost, Tuner, Anchor, Mourner, Arrival. The epics below are the build order.

FR17: Epic 1 is month 0. Epic 2 is month 2. Epic 3 is months 3–9. Epic 4 is month 10. In play order, Epics 5, 7, and 6 are months 11–13. Epic 8 is month 14.

FR18: Epic 1 — The Partner.

FR19: Epic 2 — The loss, with no warning, skip, or retry.

FR20: Epic 2 — Authored obstacles, not an open-ended random run.

FR21: Epic 3 — The long treatment stretch, the numb bridge, and the positive test. It does not restage conception.

FR22: Epic 3 — The small-game framework plus three small games in the first batch.

FR23: Epic 4 — The bills for that pregnancy.

FR24: Epic 4 — One ending. If the due date runs out, the story still moves on and the journal line stays the same.

FR25: Epic 4 — Large-type reading and stamps on the desk.

FR26: Epic 5 — Static until the baby comes through.

FR27: Epic 7 — Two on-screen hold zones, the same on a browser and a phone.

FR28: Epic 7 — On the third fall, Maya's voice, then help that is not labeled. The story can be finished.

FR29: Epic 6 — Unpacking grief and the clutter from before the baby. What remains in the House is the same for every player.

FR30: Epic 8 — Hear the cry, hold the hand, and the House is the last room.

FR31: Epic 1 — The House starts empty and cold and changes after The Partner, the same way for every player. Each later chapter epic adds its own change, also the same for every player.

FR32: Epic 1 — The journal object, the blank page, and the first entry. The words are the same for every player. Later epics add their own entry, with the same rule.

FR33: Checked as the game grows. In play order, the quiet unpacking follows the bills. Build order does not change that.

FR34: Epic 1 — One tap scheme for walk, look, and interact.

FR35: Epic 1 — House sounds, including a recorded fridge hum, and the heartbeat or voice in The Partner. Each chapter epic adds its own score.

FR36: Epic 1 — The shared look setup, plus the House's own light and ordinary fog. Each chapter epic fills in its own look. The House does not depend on volumetric fog.

## Epic List

Build order. Players still meet the chapters as Partner, Loss, Long Haul, Cost, Tuner, Anchor, Mourner, Arrival.

These calls override conflicting lines in the requirements inventory above: saves happen only between chapters; the House is built for the browser and volumetric fog is an extra on PC only; a chapter has one result; spoken dialogue may differ while items, journal words, and story beats stay the same; a save can hold a past loss and a current pregnancy; old test saves may fail to open; word count, pacing, and phone speed stay loose and ongoing.

### Epic 1: The Spark in the New House

A player can walk the House in a browser, play The Partner, return to a House that has changed, and come back later to that same House.

**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR7, FR8, FR10, FR11, FR12, FR13, FR15, FR18, FR31, FR32, FR34, FR35, FR36

**Stories:** [epic-1-stories.md](epic-1-stories.md)

### Epic 2: The Loss

A player goes through the miscarriage with no warning, skip, or retry, sits in the quiet car in the rain, and returns to a House in grief. Write this chapter's words in the same week as the numb stretch in Epic 3.

**FRs covered:** FR6, FR19, FR20

**Stories:** epic-2-stories.md, when written

### Epic 3: The Long Haul

A player crosses the numb stretch after the loss, lives through six months of treatment, helps with the shot, and ends on a positive test. The first batch is the framework plus three small games. This chapter does not restage conception. Write the numb stretch in the same week as the quiet car in Epic 2.

**FRs covered:** FR6, FR21, FR22

**Stories:** epic-3-stories.md, when written

### Epic 4: The Cost

A player works the bills for that pregnancy, reads them in large type, stamps them on the desk, and still gets through when the due date runs out. This chapter does not restage conception.

**FRs covered:** FR23, FR24, FR25

**Stories:** epic-4-stories.md, when written

### Epic 5: Hear Them

A player turns through the static until the baby comes through.

**FRs covered:** FR26

**Stories:** epic-5-stories.md, when written

### Epic 6: Make Space

A player puts away the grief and the clutter from before the baby. The layout that remains in the House is the same for every player.

**FRs covered:** FR29

**Stories:** epic-6-stories.md, when written

### Epic 7: Carry the Weight

A player carries the load with two hold zones, hears Maya, and can finish the chapter, including the crib with no instructions. This is built after the other chapters because physics in a phone browser is the risk.

**FRs covered:** FR6, FR27, FR28

**Stories:** epic-7-stories.md, when written

### Epic 8: The Arrival

A player hears the cry, holds the hand, and the House is the last room. Built after Carry the Weight.

**FRs covered:** FR30

**Stories:** epic-8-stories.md, when written

Epic 1 stands alone. Epics 2–7 need Epic 1. Epic 3 assumes Epic 2 has happened. Epic 8 needs Epic 1 and Epic 5, and it is built after every chapter epic. FR9, FR14, FR16, FR17, and FR33 are shared across the list as mapped above.

