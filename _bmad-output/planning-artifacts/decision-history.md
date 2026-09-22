# Decision History: Threshold

**Created:** 2026-09-20
**Purpose:** Record superseded planning decisions so later BMAD/GDS workflows treat the canonical docs as current truth without forgetting how they were reached.

Verbatim November 2025 originals live in [archive/2025-11-22-original/](archive/2025-11-22-original/).

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

## What did not change

- Godot 4.x and GDScript.
- Genre-as-metaphor anthology with seven chapters plus intro/outro.
- Fail-forward progression and optional mastery goals.
- PC/Steam primary, mobile secondary, mouse/touch-first.
- Pre-mortem mitigations (QualityManager, Stability Assist as Maya's voice, reflowed invoice reader, `_integrate_forces()` smoothing, Novice tonal ramp) — those already lived in the GDD and architecture and stay there.

---

## How to use this in later GDS workflows

- Treat `gdd.md`, `game-brief.md`, `narrative-design.md`, and `game-architecture.md` as current.
- Treat `brainstorming-session-2025-11-22.md` and `docs/agent-reports/` as dated source material, not specs.
- If a new workflow rediscovers "deckbuilder," "Role Model," "Outsider," or "9 months of pregnancy," it is reading archive or brainstorm text. Point it here.
