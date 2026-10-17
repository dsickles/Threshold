# UX Decision Log — Threshold

Workspace: `_bmad-output/planning-artifacts/ux-designs/ux-Threshold_New-2026-09-20/`
Opened: 2026-09-20
Intent: Create
Status: final

Decisions captured here are canonical. DESIGN.md and EXPERIENCE.md are distilled at Finalize.

---

## 2026-09-20 — Intake (brain dump)

**Sources confirmed:** current planning artifacts — `gdd.md`, `game-brief.md`, `narrative-design.md`, `game-architecture.md`, `decision-history.md`, `brainstorming-session-2025-11-22.md`. Live (non-archive) extras added 2026-09-20: `docs/agent-reports/report-designer-samus.md`, `report-narrative-sophia.md`, `report-dev-gordon.md`, `report-architect-glados.md`, `docs/adr/adr-001-engine-selection.md`. No additional visual files. Archive copies excluded as superseded.

**Hub / home (stated):**
- Primary hub inspiration: *What Remains of Edith Finch* (also takes place in a home).
- Additional hub inspirations: *Gone Home*; adventure games such as *Syberia* (spoken “Siberia”).
- Hub UX posture: **minimal HUD**, not too much going on, leave room for the player to observe themselves and not get distracted in the main home.

**Mini-games (stated):**
- Each mini-game may have a **different HUD**.
- It is OK if players are slightly unsure at first; the **interaction itself** should be straightforward for that mini-game type.
- Borrow / steal design approaches from each mini-game’s named inspirations. Spoken “ARC” = **narrative arc**, not a game title.
- High-level **consistency principle** across mini-games: recurring HUD kinds occupy stable slots when they appear (example given: mini-map always same corner; resource/key always same corner). **Example slot positions are NOT locked** — principle is consistent placement, not those specific corners.

**Polish / process (stated):**
- Want some polish.
- Do not get mired in obsessive design thinking; priority is **completing the game**.

**Not yet stated (resolved in later entries):** stakes, working mode, ARC, form-factor.

---

## 2026-09-20 — Source extract (planning artifacts)

Extracted by subagents. Locked names reused verbatim. Brainstorm-only / superseded items (deckbuilder Provider, Role Model, Outsider, calendar hub) are **not** UX decisions.

**Identity:** *Threshold* — narrative anthology (adventure / multi-genre) about becoming a father. Pillars: Genre-as-Metaphor, Emotional Authenticity, The Transition. Protagonist **Leo**; partner **Maya**; antagonist/ally **The House**. Tone: grounded & raw + surreal/metaphorical; every dark segment has levity.

**Form-factor / input (from sources, not yet confirmed as UX-pass scope):** PC/Steam primary, mobile secondary. Mouse/touch-first. Hub: first-person 3D, WASD + mouse look, `RayCast3D` interact, crosshair change / object highlight. Engine/UI: Godot 4.x, Godot **Control** nodes. Shared Input / Audio / Settings across genres.

**Hub (The New House):** Persistent first-person house; starts empty and cold; visually evolves after every minigame (furniture, lighting, shadows). House creaks / glows / rots with Leo’s state. Loop: Hub → The Story Sequence → The Trigger (object) → The Minigame → Resolution. Story sequences: Edith Finch–style first-person narrative. Unified Hub UI (1 of 8 UI sets). Journal is an `Interactable`. Story Gates: completing a minigame is the “Key” to the next room/chapter. Named rooms: ABSENT.

**Seven archetypes + Ending (verbatim):**
1. **The Partner (The Spark)** — Rhythm; Connection Nodes; Perfect/Good/Miss.
2. **The Protector (The Loss)** — Auto-runner / pathfinder; forced narrative loss.
3. **The Novice (The Science)** — WarioWare-style; micro-game titles OPEN THE BOX!, MIX THE POWDER!, INJECT THE BUTT!, DON’T FAINT!
4. **The Provider (The Cost)** — *Papers, Please*; stamps Approve/Deny; Due Date; Bank Account meter; **Reflowed Reader View** on mobile.
5. **The Tuner (The Connection)** — *Oxenfree* radio; knobs/sliders; waveforms.
6. **The Anchor (The Growth)** — *Death Stranding* cargo; left/right triggers or keys; **Maya’s Voice** then invisible **Stability Assist**.
7. **The Mourner (The Nesting)** — Zen unpacking; drag-and-drop.
- **The Ending** — remix of Tuning the baby monitor + Rhythm hand-holding.

**Systems:** Fail-forward + **Stress**; optional **Mastery** (insights / hub mementos); Adaptive Difficulty; **Dad’s Journal**; Stoic/Vulnerable micro-choices change Journal tone only. Auto-save after minigame; minigame `save_checkpoint()`.

**UI named in sources:** 7 distinct minigame UI sets + 1 unified Hub UI. HUD pieces named: subtitle (`NarrativeTrigger.gd`), hub crosshair. Title / pause / settings / credits screens: ABSENT. Accessibility beyond Reflowed Reader View + Adaptive Difficulty / Stability Assist: ABSENT.

**Visual:** Eclectic per minigame; unified grounded hub (high-fidelity 3D or detailed hand-drawn — unresolved). Familiar-yet-novel everyday objects. Hub Realistic vs per-minigame post-process. Dynamic score + domestic ASMR.

**Scope:** 2–3 hours total; ~10–15 min per minigame. First slice: Hub + The Provider + The Protector. Polish-without-obsession stated by developer.

**Inspiration lock vs dump:** Edith Finch (hub/story sequences) is in sources. *Gone Home* and *Syberia* are dump-only. *Papers, Please*, *Oxenfree*, *Death Stranding*, *WarioWare*, *Unpacking*, *Florence*, *Firewatch* named in sources. Game titled **ARC**: ABSENT from extracts (developer later clarified spoken “ARC” = narrative arc).

**Form-factor note:** PC/Steam-primary in this extract is **superseded** by the 2026-09-20 form-factor call (web → mobile → PC/Steam).

---

## 2026-09-20 — Calls (ARC, mood, stakes, sources, form-factor)

**ARC:** Narrative arc, not a game.

**Mood:**
- Mini-games reflect the mood of their inspirations (not just the mechanic).
- **The Protector (The Loss)** needs extra care — different, challenging subject.
- Narrative mood is nonlinear: up, then down, then a run of ups / adjustment (not a simple climb).
- Aligns with existing Novice tonal-ramp mitigation (desaturated/quiet after Loss, then color/chaos as IVF hormones) from Sophia/Samus reports.

**Anything else:** Developer asked the facilitator to name remaining blockers rather than invent more UX. Logged below.

**Stakes:** **Hobby** (first game). More serious than a jam. Polish should **approach indie**. Process must look thorough — public-facing portfolio. Reality: hobby; aspiration: indie-adjacent finish.

**Working mode:** Fast path with a short blocker walk. Complete the game; weeks/months of process are acceptable. Skip creative-tool rabbit holes. Remaining non-blockers get `[ASSUMPTION]` tags at distill. Documents the thoroughness without obsessive design.

**Form-factor (LOCKED, supersedes GDD PC-primary):**
1. **Web mini-game** first
2. **Mobile** second
3. **PC / Steam** third
Godot 4.x stays — HTML5 + mobile export is the reason.

**Conflict:** GDD/brief/architecture still say PC/Steam primary, mouse/keyboard hub, first slice Hub+Provider+Protector. Developer call wins for this UX pass. Architecture `FirstPersonController` WASD+mouse-look is **superseded** for the House (tap-to-walk / tap-to-look, one scheme).

---

## 2026-09-20 — Source extract (live agent reports + ADR)

Archive copies not read. These `docs/` files still exist; treated as discussion sources. Snapshot headers say they are not living specs; commitments already folded into GDD/architecture.

**Samus (designer):** Anchor difficulty polarizing → `StabilityAssist` + Maya’s voice as the story beat. Provider mobile 10pt invoices → Reflowed Reader View / tap-to-focus large-text overlay. Ready with mitigations.

**Sophia (narrative):** Novice slapstick after miscarriage = tonal whiplash → start slow/somber, chaos = IVF drugs; desaturated grading bleeds to color. Ending baby must not feel generic → Tuner + Partner mechanic callbacks; baby shader fidelity.

**Gordon (dev):** Anchor physics jitter → `_integrate_forces()` smoothing or lean into shiver animation. Provider/Protector proc-gen blandness → 50 invoice Micro-Stories; Protector set-piece chunks.

**Glados (architect):** Low-end mobile post-process → `QualityManager`; outlines critical for gameplay clarity (keep even if fog goes). GameState flag integrity → unit tests.

**ADR-001:** Godot 4.x accepted (re-accepted 2026-09-20). Anthology = scenes; 2D/3D hybrid; HTML5/mobile-capable. Console not a target.

---

## 2026-09-20 — Remaining UX blockers

Non-blockers (will `[ASSUMPTION]` if unanswered): title/pause/settings as thin chrome; exact HUD slot corners; hub art 3D vs hand-drawn; full a11y spec beyond reader view + subtitles + adaptive difficulty; named Leo journeys distilled from GDD loop.

**Blocker A — LOCKED.** “Web” = how people open the game (a browser), not a standalone minigame product. First session: the player is **in the House**, a few minutes of quiet exploration and discovery, then is **led naturally to the first minigame**. The House is always the frame.

**Blocker B — LOCKED.** One movement system for web and mobile (do not maintain two schemes). **Tap to walk / tap to look.** No virtual sticks. On a computer, tap = click. Architecture WASD + mouse-look for the House is superseded.

**Blocker C — LOCKED.** No extra screen before the pregnancy-loss chapter. The player walks in like any other room. Care is in how the chapter feels (quiet, the run you cannot win, then silence). No warning. No skip button.

---

## 2026-09-20 — Concern scan (what this UX carries)

Carries: web + mobile (+ later PC) as one tap/click scheme; hub diegesis (almost no overlay); seven chapter UIs that steal mood from their inspirations; Loss chapter with no warning chrome; nonlinear mood (up, down, then a run of ups); journal + subtitles; Provider readable paperwork on a phone; Adaptive Difficulty / Maya’s voice assist; QualityManager on low-end; portfolio-thorough but ship-complete.

Does not carry (hobby, skip unless asked): i18n, dark-mode product toggle, gamepad, Steam-first store UX, full colorblind suite, remapping of a two-scheme FPS.

---

## 2026-09-20 — Fast-path assumptions (batched)

Tagged `[ASSUMPTION]` in the spines. Developer can overturn any of these.

- First minigame after the quiet house is **The Partner (The Spark)** — that is the story opening. Production first-slice (Hub + Provider + Protector) is a build order, not the player’s first chapter.
- Title is thin: Play / Continue / Settings. Pause replaces, never stacks. Device/browser back = pause or leave Settings.
- Hub art: grounded 3D (architecture already assumes `CharacterBody3D` / house layers). Hand-drawn remains a skin, not a second navigation model.
- Recurring HUD kinds, when they exist, keep **stable slots**: status/resource = top-start; spatial (minimap) = bottom-start; primary action (stamp, confirm) = bottom-end or center per genre. Exact pixels not locked.
- Interactables: object highlight in-world; no persistent button legend in the House.
- “Naturally led” to the first minigame = GDD **The Trigger** (an object you can tap) plus House light/sound — no popup quest marker.
- Accessibility floor: subtitles on; Reflowed Reader View in Provider; tap targets ≥ 44px; reduced-motion mutes camera sway and hit-shake only. No skip for Loss.
- Named journeys use player **Alex** (phone, first session) and **Jordan** (laptop, Loss chapter). Avatar is Leo.

---

## 2026-09-20 — Player journeys (from dump + GDD; Fast path)

### Alex, first time, phone browser
1. Opens Threshold in the browser. Thin title. Taps Play.
2. Is in the House. Empty, quiet. Tap to walk, tap to look. Almost no HUD.
3. Wanders a few minutes. Something in the room can be tapped (The Trigger).
4. **Climax:** the first minigame begins (assumed: The Partner). The House HUD stays gone; a different, simpler chapter UI takes over.
5. Afterward, back in the House. It has changed a little.

### Jordan, The Protector (The Loss), laptop
1. Jordan is already in the House. No warning screen. A trigger like any other.
2. The runner starts hopeful.
3. Paths crumble. Perfect play still does not save the run.
4. **Climax:** silence. No retry banner fighting for focus. Back in the House. It has changed. The next chapter can start slow and gray (Novice ramp).

---

## 2026-09-20 — Fast-path spines drafted

`DESIGN.md` and `EXPERIENCE.md` written as `status: draft` with `[ASSUMPTION]` tags. Not finalized (no reviewer gate, no key-screen mocks, no `status: final`).

---

## 2026-09-21 — Assumptions accepted

Developer: on board with all Fast-path assumptions. Those items are now **locked decisions**, not tags. Spines updated to drop `[ASSUMPTION]`. Finalize started.

No developer visual imports (`imports/` empty). Nothing to reconcile from Figma/mood boards.

---

## 2026-09-21 — Reviewer Gate (lens 1 only)

Completeness / rubric walker ran. Wrote `review-rubric.md`, `validation-report.md`, `validation-report.html`.

Verdict: adequate as intent, thin as extract contract. 0 critical · 5 high · 15 medium · 14 low.

**Resolved in spines after the report snapshot:**
- One kebab-case component glossary in YAML, DESIGN.Components, and EXPERIENCE Component Patterns.
- Dual visual + behavioral spec per remaining component. Tap-to-move / tap-to-look stay Interaction Primitives.
- Title Continue hidden with no checkpoint; Journal empty / first entry / tone states; menu focus; save-error; Due Date; Partner miss / Tuner static / invalid drop.
- `typography.reader`; `meter-stress` wired; subtitle contrast floor; `{colors.house-hope}` used.
- Display names **Reflowed Reader View** and **Dad's Journal**. Key Flow H3s match locked journeys. Story Sequence folded into Alex; added Anchor assist flow and Ending flow. Sam logged as extra UJ for Provider.
- `mockups/` and `wireframes/` folders created.

**Left as non-blockers:** 8-digit `subtitle-bg` hex (documented as surface@80%); accent/meter-bank/focus-ring share a swatch on purpose; no colorblind suite; brainstorming file remains log-only (superseded).

---

## 2026-09-22 — Key screens

Rendered offline HTML (phone frame). Working copies in `.working/`; promoted to `mockups/`. Spines link them. Spines win on conflict.

- `mockups/key-title.html` — cold open; Play focused; Continue omitted.
- `mockups/key-house.html` — chrome diagram only (highlight + Pause). The room is the 3D House, not this drawing.
- `mockups/key-pause.html` — scrim + panel; Resume focused.
- `mockups/key-provider.html` — desk with Bank Account / Due Date / APPROVE / DENY, plus Reflowed Reader View.

Spine-only (not mocked): The Story Sequence, The Partner, The Protector, The Novice, The Tuner, The Anchor, The Mourner, The Ending, Dad's Journal, Settings.

## 2026-09-22 — Mock read-back

Developer accepts title, pause, and the Provider **concept** as high-level behavior. Provider details and examples are a later minigame breakout, not this pass.

House behavior is accepted as described. The HTML picture is too abstract to envision the room; it stays a chrome diagram. The playable House is the grounded 3D space.

---

## 2026-09-22 — Finalized

Developer: “this works. proceed.” Spine-only surfaces stay spine-only. Minigame detail is a later breakout.

Editorial: both spines match the reference shape (DESIGN.md section order locked by the design spec; EXPERIENCE.md required sections present). No cuts. Token example on EXPERIENCE.md no longer uses a fake path.

`status: final` on DESIGN.md and EXPERIENCE.md. `updated: 2026-09-22`.

Dropped source ideas: `reconcile-sources.md`.

---
