# Game Brief: Threshold

**Date:** 2025-11-22
**Reconciled:** 2026-09-20
**Author:** Dan (with Samus Shepard)
**Status:** Canonical (reconciled from the 2025-11-22 draft)

Superseded ideas from the original draft (Roguelike Deckbuilder, The Role Model, The Outsider, a 9-month-only timeline, apartment hub) are recorded in [decision-history.md](decision-history.md). The 2025-11-22 text is archived at [archive/2025-11-22-original/bmm-game-brief-Threshold-2025-11-22.md](archive/2025-11-22-original/bmm-game-brief-Threshold-2025-11-22.md).

---

## Executive Summary

**Threshold** is a multi-genre narrative anthology that explores the emotional complexity of becoming a father. Unlike traditional parenting simulators that focus on the _mechanics_ of childcare, Threshold focuses on the _internal psychology_ of the father—the anxiety of providing, the instinct to protect, and the struggle to connect.

By utilizing a "Genre-as-Metaphor" approach, the game presents distinct emotional challenges as unique gameplay experiences (e.g., medical billing as a Bureaucracy Simulation, active listening as a Rhythm Game). The result is a deeply relatable, emotionally resonant journey that captures the transition from "Me" to "Us."

---

## Game Vision

### Core Concept

A collection of distinct, metaphor-rich minigames that chronicle the arduous journey to parenthood—including the struggles of infertility, IVF, and loss—culminating in the birth and the immediate aftermath. Each chapter represents a specific archetypal fear or hope of the expectant father.

### Elevator Pitch

_Threshold_ is _What Remains of Edith Finch_ meets _WarioWare_, wrapped in the emotional honesty of _Papers, Please_. It is an anthology of fatherhood where every mechanic is a metaphor for the anxiety and joy of bringing new life into the world.

### Vision Statement

To create a game that makes players _feel_ the weight and wonder of parenthood, validating the complex mix of excitement and terror that defines the experience.

---

## Target Market

### Primary Audience

- **Demographic:** Males 25-40 (Expectant fathers, new dads, or those who have navigated fertility struggles).
- **Psychographic:** Players who enjoy narrative-heavy indie games (_Firewatch_, _Unpacking_) and appreciate experimental mechanics.

### Secondary Audience

- **Partners:** Women/Partners interested in the "other side" of the pregnancy experience.
- **Narrative Gamers:** Fans of emotional storytelling regardless of parental status.

### Market Context

While there are many "Dad Games" (often comedic like _Octodad_ or _Who's Your Daddy_), there is a significant gap for a serious, emotionally grounded exploration of fatherhood. _Threshold_ fills this niche with high-quality narrative and innovative design.

---

## Game Fundamentals

### Core Gameplay Pillars

1.  **Genre-as-Metaphor:** Every gameplay mechanic must directly serve the emotional theme of the scene. (e.g., Anxiety = Unstable controls).
2.  **Emotional Authenticity:** The game does not shy away from the scary, boring, or difficult parts of the process.
3.  **The Transition:** The overarching progression tracks the protagonist's growth from a self-centered individual to a selfless provider/protector.

### Primary Mechanics (The Anthology)

Listed in chronological story order:

- **The Partner:** Rhythm Game (Active listening and emotional attunement).
- **The Protector:** Auto-Runner / Pathfinder Puzzle (Clearing the path for the family; a forced narrative loss).
- **The Novice:** WarioWare-style Minigames (Chaotic skill learning during IVF).
- **The Provider:** Bureaucracy Simulation (Insurance claims, medical billing, and the dehumanizing fight with paperwork).
- **The Tuner:** Tactile Frequency Puzzle (Finding a clear signal in the ultrasound/monitor static).
- **The Anchor:** Physics Balancing (Carrying the weight of the new life through the final stretch).
- **The Mourner:** Zen Unpacking (Making space by letting go of the old life and the grief of loss).

### Player Experience Goals

- **Anxiety:** Feeling overwhelmed by resources and responsibilities.
- **Vigilance:** Feeling a hyper-awareness of danger.
- **Tenderness:** Feeling a quiet, profound connection in small moments.
- **Growth:** Feeling the satisfaction of shedding old habits.

---

## Scope and Constraints

### Target Platforms

- **Primary:** PC / Steam.
- **Secondary:** Mobile (iOS/Android) - Design should account for touch controls where possible.

### Development Timeline

- **Phase 1:** First slice — Hub + _The Provider_ + _The Protector_ - 1 Month.
- **Phase 2:** Vertical Slice (3 Archetypes) - 3 Months.
- **Phase 3:** Full Production - 9-12 Months.

### Technical Constraints

- **Input:** Mouse/Touch-first design to support both PC and Mobile potential.
- **Engine:** Godot 4.x.

---

## Reference Framework

### Inspiration Games

- **_Papers, Please:_** For using mundane tasks to create high-stakes emotional tension.
- **_What Remains of Edith Finch:_** For the anthology structure and varied mechanics.
- **_Unpacking:_** For environmental storytelling and the "Mourner" mechanic.
- **_Florence:_** For interactive narrative beats.

### Key Differentiators

- **Serious Tone:** Avoids the "clumsy dad" trope for a grounded, realistic take.
- **Mechanical Variety:** Keeps the experience fresh by constantly shifting genres.
- **Male Emotional Focus:** Explores a perspective rarely centered in emotional narratives.

---

## Content Framework

### World and Setting

- **Setting:** Contemporary, grounded reality. A house that changes over time.
- **Hub:** **The New House** — a first-person, grounded 3D space that anchors the varied minigame experiences and visually evolves with the narrative.

### Narrative Approach

- **Structure:** Linear timeline from the attempt to conceive through loss, IVF, pregnancy, and birth, with "Minigame" chapters.
- **Tone:** Intimate, honest, vulnerable.

### Content Volume

- **Length:** 2-3 hours total gameplay, including hub exploration, story sequences, and all seven archetypes.
- **Minigame duration:** About 10-15 minutes each, so the full journey stays inside that window.
- **Chapters:** 7 distinct segments (The 7 archetypes + Intro/Outro).

---

## Art and Audio Direction

### Visual Style

- **Eclectic / Mixed Media:** Each genre/archetype has its own distinct visual identity to match the emotion (e.g., _The Provider_ might be gritty/noir, _The Novice_ might be bright/cartoonish).
- **Unified Hub:** The New House shares a consistent, grounded style (high-fidelity 3D or detailed hand-drawn) to tie it all together.

### Audio Style

- **Dynamic Score:** Shifts genres along with the visuals (Synthwave for _Provider_, Acoustic for _Mourner_).
- **Sound Design:** High-fidelity, ASMR-like focus on domestic sounds (heartbeats, paper crumpling, rain).

---

## Risk Assessment

### Key Risks

- **Cohesion:** The game might feel disjointed due to multiple genres/art styles.
  - _Mitigation:_ Strong narrative framing and a unified "Hub" UI.
- **Scope Creep:** Building 7 different game engines is expensive.
  - _Mitigation:_ Keep each minigame mechanically simple (MVP approach).
- **Niche Appeal:** "Fatherhood" might feel exclusionary to some players.
  - _Mitigation:_ Focus on universal themes of responsibility and change.

---

## Success Criteria

### MVP Definition

A playable build featuring the **Hub** and **2 Polished Archetypes** (Provider + Protector) that demonstrates the emotional contrast.

### Success Metrics

- **Emotional Impact:** Playtesters report feeling specific, intended emotions.
- **Cohesion:** Players understand how the minigames connect to the larger narrative.

---

## Next Steps

### Immediate Actions

1.  **Prototype the first slice:** Greybox Hub plus _The Provider_ (Bureaucracy Sim) and _The Protector_ (Pathfinder).
2.  **Visual Style Guide:** Create a mood board for the New House and those 2 key archetypes.
3.  **Narrative Outline:** Already captured in `gdd.md` and `narrative-design.md`; keep those documents as the source of truth for the 7 archetypes mapped onto the fertility timeline.

---

_This Game Brief is the product-vision input for the Game Design Document._
