# Threshold - Game Design Document

**Author:** Dan (with Samus Shepard)
**Game Type:** Narrative Anthology (Adventure / Multi-Genre)
**Target Platform(s):** PC / Steam (Primary), Mobile (Secondary)

---

## Executive Summary

### Core Concept

**Threshold** is a narrative anthology that explores the emotional complexity of becoming a father through a series of distinct, metaphor-rich minigames. It chronicles the arduous journey to parenthood—including the struggles of infertility, IVF, and loss—culminating in the birth and immediate aftermath.

### Target Audience

- **Primary:** Males 25-40 (Expectant fathers, new dads, or those who have navigated fertility struggles).
- **Psychographic:** Fans of narrative-heavy indie games (_What Remains of Edith Finch_, _Firewatch_) who appreciate experimental mechanics and emotional storytelling.

### Unique Selling Points (USPs)

- **Genre-as-Metaphor:** Every mechanic directly serves an emotional theme (e.g., Anxiety = Unstable controls).
- **Emotional Authenticity:** A serious, grounded exploration of fatherhood, avoiding "clumsy dad" tropes.
- **The Anthology Structure:** A diverse collection of gameplay styles (Deckbuilder, Rhythm, Puzzle) tied together by a cohesive narrative.

---

## Goals and Context

### Project Goals

- To validate the complex mix of excitement and terror that defines impending fatherhood.
- To create a high-quality narrative experience that resonates with an underserved demographic.
- To demonstrate how varied gameplay mechanics can be used to tell a unified emotional story.

### Background and Rationale

Most games about parenting are either comedic simulations or management tycoons. _Threshold_ aims to fill the gap for a serious, introspective look at the _transition_ into fatherhood, using the medium's interactivity to make players _feel_ the specific anxieties and joys of the process.

---

## Core Gameplay

### Game Pillars

1.  **Metaphorical Mechanics:** Gameplay is the language of emotion. If the character feels overwhelmed, the controls feel slippery. If they feel focused, the gameplay is precise.
2.  **Grounded Reality:** The setting and narrative are realistic and relatable. The "magic" comes from the internal psychological interpretation of mundane events.
3.  **The Transition:** The progression mirrors the protagonist's growth from self-centeredness to selflessness.

### Core Gameplay Loop

### Core Gameplay Loop

1.  **Hub (The New House):** Player explores the house.
2.  **The Story Sequence:** Interactive, first-person narrative segments (à la _What Remains of Edith Finch_) that bridge the gap between chapters, delivering key plot points (e.g., the decision to try IVF).
3.  **The Trigger:** A specific object launches the Minigame.
4.  **The Minigame:** The metaphorical gameplay sequence. **Duration: ~30 Minutes.**
5.  **Resolution:** The House transforms visually.

### Win/Loss Conditions

- **Narrative Progression:** Most minigames are "fail-forward" – failure results in a different narrative outcome or increased "Stress" but does not halt progress.
- **Mastery:** Optional "Mastery" goals in each minigame unlock additional insights or mementos in the Hub.

---

## Game Mechanics: The Anthology (Chronological Order)

### 1. The Partner (The Spark)

- **Genre:** Rhythm Game.
- **Narrative Beat:** Trying to conceive naturally. Pure excitement and intimacy.
- **Mechanics:** Hitting "Connection Nodes" in time with the partner's heartbeat/voice.
- **Pacing:** Starts slow and intimate, builds to a frantic, joyous crescendo. Includes moments of awkward laughter (missed cues).
- **Ending:** The song ends in a crescendo. **Result: Positive Pregnancy Test.**

### 2. The Protector (The Loss)

- **Genre:** Auto-Runner / Pathfinder.
- **Narrative Beat:** Starts euphoric. The couple is planning, dreaming. Then, the miscarriage occurs _during_ the run.
- **Mechanics:**
  - **Start:** Clear paths, sunny visuals.
  - **Mid-Game:** The path begins to crumble. Obstacles become unavoidable.
  - **Pacing:** Euphoria -> Confusion -> Panic -> Silence.
  - **End:** The "Runner" (the baby avatar) fades away despite the player's perfect play. A forced narrative loss.

### 3. The Novice (The Science)

- **Genre:** WarioWare-style Minigames.
- **Narrative Beat:** The pivot to IVF. The absurdity of being an amateur scientist at home. **This covers a grueling 6-month period of multiple egg retrievals.**
- **Tone:** Starts slow, quiet, and desaturated. Ramps up to funny, frantic, and colorful as the "medication" takes effect.
- **Narrative Bridge:** The shift from _The Protector_ (Tragedy) to this chaos is bridged by a "Numbing" phase where the humor slowly bleeds in.
- **Mechanics:**
  - **Micro-Games:** "OPEN THE BOX!", "MIX THE POWDER!", "INJECT THE BUTT!", "DON'T FAINT!".
  - **Outcome:** Successful conception via IVF after a long struggle.

### 4. The Provider (The Cost)

- **Genre:** Bureaucracy Simulation (_Papers, Please_ style).
- **Narrative Beat:** The reality of the pregnancy sets in. The dehumanizing battle against insurance companies and medical billing.
- **Mechanics:**
  - **The Desk:** Player reviews invoices, insurance claims, and bank statements.
  - **The Task:** Cross-reference codes, find "errors" to deny bad bills, and approve valid payments before the "Due Date" timer expires.
  - **The Pressure:** A "Bank Account" meter drains constantly. Making mistakes costs money.
- **Metaphor:** The feeling that the system is designed to confuse and bankrupt you.
- **Accessibility Note:** On mobile devices, tapping a document must open a "Reflowed Reader View" (large text) rather than just zooming in, to prevent eye strain.

### 5. The Tuner (The Connection)

- **Genre:** Tactile Frequency Puzzle (_Oxenfree_ radio style).
- **Narrative Beat:** Connecting with the "Science Baby". Trying to find a clear voice in the static of the ultrasound/monitor.
- **Mechanics:** Physically turning dials and adjusting sliders to align waveforms and clear up the signal.
- **Metaphor:** The active effort required to bond with someone you haven't met.

### 6. The Anchor (The Growth)

- **Genre:** Physics Balancing (_Death Stranding_ cargo style).
- **Narrative Beat:** Carrying the weight. The physical endurance required to keep the family upright during the final stretch.
- **Mechanics:** Controlling Leo's balance while carrying a heavy, fragile load (the Crib? The Future?) through a storm/cluttered house.
- **Metaphor:** Growth is not just about shedding the old, but about finding the strength to carry the new.
- **Dynamic Difficulty:** If the player fails repeatedly, "Maya's Voice" (Audio Cue) encourages them, triggering an invisible "Stability Assist" to help them complete the level.

### 7. The Mourner (The Nesting)

- **Genre:** Zen Unpacking.
- **Narrative Beat:** Making space. Packing away the grief of the miscarriage, but also **clearing out the clutter of their pre-parent lives (hobbies, old furniture, "single guy" stuff)** to make room for the new arrival.

---

## Progression and Balance

### Player Progression

- **Narrative Arc:**
  1.  **The Spark:** Natural conception attempt (_The Partner_).
  2.  **The Loss:** Miscarriage (_The Protector_).
  3.  **The Science:** **6 Months of IVF** & Humor (_The Novice_).
  4.  **The Wait:** Pregnancy & Anxiety (_Provider, Tuner, Anchor, Mourner_).
- **Hub Evolution:** The **New House** starts empty and cold. It visually evolves after _every_ minigame—renovations complete, furniture appears, lighting warms up, or shadows lengthen depending on the narrative beat.
- **The Ending:** The final sequence re-uses mechanics from previous chapters (Tuning the baby monitor, Holding the hand via Rhythm) to show how the skills learned have prepared Leo for fatherhood.
- **Journal:** A "Dad's Journal" fills with entries, tracking both the medical facts and the emotional reality.

### Difficulty Curve

- **Emotional Pacing:** The game carefully balances tone. High-stress segments (_Provider_) are followed by meditative ones (_Mourner_).
- **Humor & Heart:** Moments of slapstick comedy (_The Novice_) and profound, quiet joy (_The Outsider_) are essential to balance the heavier themes of infertility and anxiety.
- **Adaptive Difficulty:** Minigames adjust slightly to ensure the player can complete the story.

---

## Art and Audio Direction

### Art Style

- **Eclectic Anthology:** Each minigame has a distinct visual style.
- **Striking & Memorable:** The art should not just be "functional" but **bold and stylized**. We aim for a "Familiar yet Novel" aesthetic—taking everyday objects (cribs, bottles) and rendering them in unexpected ways (e.g., a crib made of neon light in _The Provider_).
- **Unified Hub:** The **New House** uses a grounded, realistic style (High-fidelity 3D or detailed hand-drawn). It acts as a canvas for the narrative, changing lighting, weather, and state of repair to reflect the protagonist's internal state.

### Audio and Music

- **Dynamic Score:** The soundtrack shifts genres to match the gameplay (Synthwave for _Provider_, Acoustic/Piano for _Mourner_).
- **Sound Design:** High-fidelity "Domestic ASMR" – the sound of rain on the window, the hum of the fridge, the heartbeat on the monitor.

---

## Technical Specifications

### Performance Requirements

- **Target:** 60 FPS on mid-range PCs.
- **Mobile:** Optimized for touch inputs and lower-poly assets where necessary.

### Platform-Specific Details

- **PC:** Mouse/Keyboard support.
- **Mobile:** Touch gestures (Tap, Swipe, Pinch) mapped to minigame mechanics.

### Asset Requirements

- **Environments:** 1 Main Hub (Apartment) + 7 Minigame Environments.
- **Characters:** Protagonist (Dad), Partner (Mom), Baby (NPC).
- **UI:** 7 Distinct UI sets for the minigames + 1 Unified Hub UI.

---

## Development Epics

### Epic Structure

1.  **Core Framework:** Input system, Scene management, Save system.
2.  **The Hub:** **House** environment, Dynamic prop system, Visual state manager.
3.  **Archetype: Provider:** Bureaucracy logic, Document UI, Balancing.
4.  **Archetype: Protector:** Pathfinding logic, Obstacle interaction.
5.  **Archetype: Partner:** Rhythm input system, Music sync.
6.  **Archetype: Anchor:** Physics balance logic, Rigging.
7.  **Archetype: Novice:** Minigame manager, Micro-game collection.
8.  **Archetype: Tuner:** Signal processing shader, Frequency logic.
9.  **Archetype: Mourner:** Drag-and-drop physics, Inventory logic.
10. **Polish & Ship:** Audio integration, Localization, Bug fixing.

---

## Out of Scope

- **Multiplayer:** Strictly a single-player narrative experience.
- **Character Customization:** The protagonist is a defined character to support the specific narrative arc.
- **Open World:** The House is a contained space; no city exploration.

---

## Assumptions and Dependencies

- **Engine:** Godot 4.x.
- **Team:** Small indie team (1-3 devs).
- **Assets:** Will rely on a mix of custom and modified store assets to handle the variety of styles.
