# Threshold - Game Architecture Document

**2026-10-17:** Copied out of BMAD into `docs/design/`. Updated for the 2026-09-22 rulings (saves only between chapters, one result per chapter, past and present facts together, House built for the browser) and for [ADR-0002](../adr/0002-build-order-spark-to-silence.md), [ADR-0003](../adr/0003-house-fixed-viewpoints.md), [ADR-0005](../adr/0005-ai-assets-text-dialogue-v1.md). Code examples are illustrations, not final code.

**Author:** Glados (with Dan)
**Engine:** Godot 4.x
**Language:** GDScript
**Project Structure:** Modular Anthology
**Reconciled:** 2026-09-22. House controls and first-slice order follow the final UX: one tap scheme; browser, then mobile, then PC/Steam; first slice is the 3D House plus _The Partner_. Minigame duration stays ~10–15 minutes. The 2026-09-20 first-slice note in [decision-history.md](decision-history.md) is superseded for build order only. Original: [archive/2025-11-22-original/bmm-architecture-Threshold-2025-11-22.md](../../archive/2026-10-bmad/_bmad-output/planning-artifacts/archive/2025-11-22-original/bmm-architecture-Threshold-2025-11-22.md).

---

## 1. High-Level Architecture

### Core Philosophy

_Threshold_ is an **Anthology** of distinct minigames wrapped in a **Persistent Hub**. The architecture must support:

1.  **Isolation:** Minigames should be self-contained scenes/modules to prevent code conflicts.
2.  **Persistence:** A global `GameManager` tracks the narrative state and modifies the Hub accordingly.
3.  **Shared Systems:** Input, Audio, and Settings must be unified across all genres. Input is one tap scheme on every platform: browser first, mobile second, PC/Steam third.

### Directory Structure

```
res://
├── _core/                  # Shared systems (Singletons, Utils)
│   ├── audio/
│   ├── save_system/
│   └── state_manager/
├── assets/                 # Shared assets (Fonts, UI, Common Sounds)
├── scenes/
│   ├── hub/                # The House (Main Scene)
│   ├── minigames/          # Self-contained minigame folders
│   │   ├── provider/
│   │   ├── protector/
│   │   └── ...
│   └── ui/                 # Menus, HUDs
└── scripts/                # Global scripts
```

---

## 2. Core Systems

### 2.1 Game State Manager (`GameState.gd`)

- **Role:** The "Brain" of the game. Tracks where the player is in the story.
- **Data:** The saved state is the **ordered list of finished chapters**, the Stoic/Vulnerable answers given, and settings. Everything else is looked up from that list in **one table in the core**: story facts (miscarriage happened, pregnant now, baby born), House mood, House objects, and the journal entries. A chapter only reports "I finished" (and, where a scene offers it, the Stoic/Vulnerable answer, which picks journal wording). Chapters never write story facts themselves.
- **Past and present:** Facts are either history (the miscarriage happened) or current (Maya is pregnant). Both can be true at once. Because facts are derived from the finished-chapter list, impossible combinations cannot be saved, so no separate validator is needed.
- **Function:** `change_act(new_act)` triggers global events (music change, lighting shift).

### 2.2 The Hub System (`HubManager.gd`)

- **Visual State Machine:** A system to toggle prop visibility and lighting based on `GameState`.
- **Implementation:**
  - **Layers:** The House scene is divided into `BaseLayer` (Walls), `PropLayer` (Dynamic Objects), and `LightingLayer`.
  - **Logic:** On `ready()`, the Hub checks `GameState` and enables/disables nodes.
  - _Example:_ `if GameState.narrative_flags.miscarriage_occurred: $Nursery/Crib.hide(); $Nursery/Boxes.show()`
  - **Tests:** Automated tests cover the core table (each finished-chapter list gives the right facts and House mood) and save/load.

### 2.3 House Controls (`HouseController.gd`)

One tap scheme, like a tap adventure game. Click is tap. Browser first, mobile second, PC/Steam third. Story Sequences use this same scheme. No WASD, no virtual stick, and no mouse-look. The House uses **fixed viewpoints** ([ADR-0003](../adr/0003-house-fixed-viewpoints.md)).

- **Move:** Tap a viewpoint marker or doorway. The camera glides to that framed shot.
- **Look:** At a viewpoint, a short drag turns the view a little.
- **Use:** Tap an object (`MinigameTrigger`, `Journal`, `Door`) to use it.
- **Hit test:** Ray from the pointer into the House, not from the center of the camera.
- **Interactable Class:** Base class for tappable objects.
- **Visual Feedback:** Highlight the object that can be tapped. No crosshair. If it cannot be tapped, it is not the path.

### 2.4 Storytelling System (`NarrativeTrigger.gd`)

- **Inspiration:** _What Remains of Edith Finch_.
- **Mechanism:** A story beat is attached to a viewpoint or object in the House and fires when the player arrives there or taps it.
- **Behavior:**
  - **On Arrive:** Shows the beat's lines as subtitles (text only in v1, [ADR-0005](../adr/0005-ai-assets-text-dialogue-v1.md); voice later via `AudioManager`).
  - **One-Shot:** Most triggers disable themselves after playing once (tracked in `GameState`).
  - **Focus:** Optional "Look At" force (smoothly rotates camera to a POI) for critical story beats.

### 2.5 Minigame Manager (`MinigameLoader.gd`)

- **Role:** Handles the transition between the Hub and Minigames.
- **Features:**
  - **Scene Swapping:** Unloads the Hub (or pauses it) and loads the Minigame scene.
  - **Context Passing:** Passes difficulty/settings to the Minigame.
  - **Result Handling:** Receives "finished" from the Minigame (one result per chapter) and adds it to the finished-chapter list in `GameState`.

---

## 3. Art & Audio Pipeline

### 3.1 Shader-Based Art Styles (Striking & Memorable)

To achieve the "Familiar yet Novel" aesthetic without 7 distinct asset pipelines, we will use **Heavy Post-Processing & Stylized Shaders**.

- **The Provider (Noir):** High-contrast B&W shader + Rain particles + Neon outlines for key objects (Stamps, Forms).
- **The Novice (Cartoon):** Saturation boost + Outline (Sobel) shader + "Squash & Stretch" vertex displacement.
- **The Tuner (Glitch):** Chromatic aberration + Noise grain + Object fragmentation shaders.
- **The Hub (Grounded):** Simple models with lamp lighting, ordinary fog, corner shading (SSAO), color shifts and sound, acting as the "Grounding" element. The browser build cannot use volumetric fog; it is an optional PC-only extra and the House must never depend on it. Godot CompositorEffects are not used (they do not run in the browser).

### 3.2 Audio System (`AudioManager.gd`)

- **Dynamic Mixing:** Uses AudioBuses to crossfade between "Hub Ambience" and "Minigame Music".
- **The Hum:** A recorded sound loop (fridge/furnace) whose pitch and volume change with the House mood. Not generated sound: the browser's default audio mode drops on-the-fly sound generation and effects.

### 3.3 Quality Manager (`QualityManager.gd`)

- **Role:** Detects hardware capabilities on launch.
- **Logic:**
  - **High End:** Enables SSAO and high-res shaders (plus volumetric fog on the PC build only).
  - **Low End (Mobile):** Disables SSAO and ordinary fog. Switches "Sobel Outline" to a cheaper "Unshaded" technique to maintain gameplay clarity without the performance cost.

---

## 4. Minigame Specifics (Technical)

### 4.1 The Provider (Bureaucracy Sim)

- **Structure:** 3 Acts (The Invoices, The Insurance, The Audit).
- **Nodes:** `Control` nodes for Documents, `TextureRect` for Stamps (`Approve`, `Deny`).
- **Data:** `DocumentData` Resource (Text, Type, ValidCodes, ErrorFlags). The bills are a fixed, hand-written set telling one injury story, not randomly generated.
- **Logic:** `DocumentValidator` class checks if the player's "Stamp" matches the document's validity state.
- **Pacing:** Documents get more complex (more pages, smaller font) in Act 2.

### 4.2 The Protector (Pathfinder)

- **Nodes:** `CharacterBody2D` for the Runner, `TileMap` for the path.
- **Logic:** A fixed, authored sequence of obstacles ending in the forced loss. Not random.

### 4.3 The Novice (WarioWare)

- **Structure:** A `MicroGameManager` that randomly instantiates small scenes (`MicroGameBase`).
- **Montage System:** Represents the 6-month timeline.
  - _Phase 1 (Month 1-2):_ Slow, confused inputs.
  - _Phase 2 (Month 3-5):_ Fast, frantic, high-skill inputs.
  - _Phase 3 (Month 6):_ Exhaustion mechanics (inputs ignore player occasionally).
- **Timing:** Uses `Engine.time_scale` to speed up the game over the 6-month montage.

### 4.4 The Partner (Rhythm)

- **Core System:** `Conductor.gd` (Singleton for this scene).
- **Logic:** On the web, plays the song through the browser's audio system and times each tap from the touch's own timestamp against the browser's output clock ([ADR-0006](../adr/0006-partner-browser-audio-clock.md)). Native builds track song position with `AudioServer.get_time_since_last_mix()` - `AudioServer.get_output_latency()`. A per-device offset from the "tap along to calibrate" step is applied on top.
- **Data:** Beatmaps stored as JSON arrays of timestamps.
- **Input:** `InputListener` checks the difference between `current_song_time` and `target_beat_time` to determine "Perfect/Good/Miss".

### 4.5 The Tuner (Frequency Puzzle)

- **Visuals:** Heavy reliance on **Shaders**.
  - `SignalShader.gdshader`: Accepts uniforms for `frequency`, `amplitude`, and `noise_offset`.
- **Input:** Two "Knobs" (UI Controls) that modify these shader uniforms.
- **Win Condition:** When player values match target values (within a tolerance threshold), the noise texture alpha is reduced to reveal the underlying image.

### 4.6 The Anchor (Physics Balance)

- **Nodes:** `RigidBody3D` for Leo, `PhysicalBone3D` for limbs.
- **Logic:** `BalanceController` applies forces to keep the center of mass upright.
- **Input:** Two on-screen hold zones (left and right), the same on phone and browser. No triggers or keys.
- **Open question for M2:** full ragdoll physics in a phone browser is a risk. A simpler scripted wobble on a balance value may feel just as heavy and be far more reliable. Decide with a cheap test in M2.
- **Fail State:** If the load touches the ground, the player stays in the chapter. After the third fall, Maya's line ("You've got this.") and invisible Stability Assist.
- **Physics Smoothing:** Use `_integrate_forces()` to apply smooth torque. Do not use `add_force()` in `_process()`.
- **Jitter Masking:** If physics jitter occurs, blend in a "Shivering" animation layer to make it look like character nervousness.

### 4.7 The Mourner (Unpacking)

- **Interaction:** `DragDropController` (Raycast from mouse).
- **Physics:** `Area2D` for items. `CollisionShape2D` for "Valid Placement Zones" (Shelves).
- **Logic:** Items have a `state` enum (IN_BOX, HELD, PLACED).
- **Persistence:** The final placement of items is saved to `GameState.house_state` to persist in the Hub if needed.

---

## 5. Data & Persistence

### 5.1 Save System (`SaveManager.gd`)

- **Format:** JSON, stored in the browser. _2026-10-19: one file, `user://save.json`, written by `GameState` with Godot's `FileAccess`; on the web Godot keeps it in IndexedDB ([ADR-0007](../adr/0007-saves-json-file-in-user-folder.md))._
- **Content:** The finished-chapter list and settings (see §2.1).
- **Triggers:** Save only **between chapters**, when a chapter finishes. No mid-chapter checkpoints. Closing the tab mid-chapter restarts that chapter next time. Hiding the tab pauses the game but does not save.
- **Failure:** In private browsing or a blocked frame the save can fail. Show "Couldn't save." and keep playing. Old test saves may fail to open; there is no save versioning.

---

## 6. Development Roadmap (Technical)

_Superseded 2026-10-17 by [ADR-0002](../adr/0002-build-order-spark-to-silence.md)._ See [roadmap.md](../roadmap.md). The 2026-09-22 phase list is in the archive and git history.
