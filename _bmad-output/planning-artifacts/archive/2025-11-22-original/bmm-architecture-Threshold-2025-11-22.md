# Threshold - Game Architecture Document

**Author:** Glados (with Dan)
**Engine:** Godot 4.x
**Language:** GDScript
**Project Structure:** Modular Anthology

---

## 1. High-Level Architecture

### Core Philosophy

_Threshold_ is an **Anthology** of distinct minigames wrapped in a **Persistent Hub**. The architecture must support:

1.  **Isolation:** Minigames should be self-contained scenes/modules to prevent code conflicts.
2.  **Persistence:** A global `GameManager` tracks the narrative state and modifies the Hub accordingly.
3.  **Shared Systems:** Input, Audio, and Settings must be unified across all genres.

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

- **Role:** The "Brain" of the game. Tracks the timeline and narrative flags.
- **Data Structure:**
  ```gdscript
  var state = {
      "current_act": 1,
      "minigames_completed": [],
      "narrative_flags": {
          "ivf_started": false,
          "miscarriage_occurred": false,
          "baby_born": false
      },
      "house_state": {
          "nursery_painted": false,
          "boxes_packed": false
      }
  }
  ```
- **Function:** `change_act(new_act)` triggers global events (music change, lighting shift).

### 2.2 The Hub System (`HubManager.gd`)

- **Visual State Machine:** A system to toggle prop visibility and lighting based on `GameState`.
- **Implementation:**
  - **Layers:** The House scene is divided into `BaseLayer` (Walls), `PropLayer` (Dynamic Objects), and `LightingLayer`.
  - **Logic:** On `ready()`, the Hub checks `GameState` and enables/disables nodes.
  - _Example:_ `if GameState.narrative_flags.miscarriage_occurred: $Nursery/Crib.hide(); $Nursery/Boxes.show()`
  - **Validation:** A Unit Test suite runs on every save/load to validate `GameState` integrity (e.g., ensuring mutually exclusive flags like 'Pregnant' and 'Miscarried' don't coexist).

### 2.3 Player & Interaction (`FirstPersonController.gd`)

- **Movement:** Standard `CharacterBody3D` with WASD movement and Mouse Look.
- **Interaction:**
  - **RayCast3D:** Casts from the camera center to detect objects.
  - **Interactable Class:** A base class for all clickable objects (`Door`, `MinigameTrigger`, `Journal`).
  - **Visual Feedback:** Crosshair changes or object highlights when hovering over an `Interactable`.

### 2.4 Storytelling System (`NarrativeTrigger.gd`)

- **Inspiration:** _What Remains of Edith Finch_.
- **Mechanism:** `Area3D` triggers placed in the Hub.
- **Behavior:**
  - **On Enter:** Plays a specific Voiceover (VO) line via `AudioManager`.
  - **Subtitle:** Displays text on the HUD.
  - **One-Shot:** Most triggers disable themselves after playing once (tracked in `GameState`).
  - **Focus:** Optional "Look At" force (smoothly rotates camera to a POI) for critical story beats.

### 2.5 Minigame Manager (`MinigameLoader.gd`)

- **Role:** Handles the transition between the Hub and Minigames.
- **Features:**
  - **Scene Swapping:** Unloads the Hub (or pauses it) and loads the Minigame scene.
  - **Context Passing:** Passes difficulty/settings to the Minigame.
  - **Result Handling:** Receives `win/loss` data from the Minigame and updates `GameState`.

---

## 3. Art & Audio Pipeline

### 3.1 Shader-Based Art Styles (Striking & Memorable)

To achieve the "Familiar yet Novel" aesthetic without 7 distinct asset pipelines, we will use **Heavy Post-Processing & Stylized Shaders**.

- **The Provider (Noir):** High-contrast B&W shader + Rain particles + Neon outlines for key objects (Stamps, Forms).
- **The Novice (Cartoon):** Saturation boost + Outline (Sobel) shader + "Squash & Stretch" vertex displacement.
- **The Tuner (Glitch):** Chromatic aberration + Noise grain + Object fragmentation shaders.
- **The Hub (Realistic):** Standard PBR lighting + Volumetric fog, acting as the "Grounding" element.

### 3.2 Audio System (`AudioManager.gd`)

- **Dynamic Mixing:** Uses AudioBuses to crossfade between "Hub Ambience" and "Minigame Music".
- **The Hum:** A procedural sound loop (fridge/furnace) that modulates pitch/volume based on `GameState.anxiety_level`.

### 3.3 Quality Manager (`QualityManager.gd`)

- **Role:** Detects hardware capabilities on launch.
- **Logic:**
  - **High End:** Enables Volumetric Fog, SSAO, and High-Res Shaders.
  - **Low End (Mobile):** Disables Fog/SSAO. Switches "Sobel Outline" to a cheaper "Unshaded" technique to maintain gameplay clarity without the performance cost.

---

## 4. Minigame Specifics (Technical)

### 4.1 The Provider (Bureaucracy Sim)

- **Structure:** 3 Acts (The Invoices, The Insurance, The Audit).
- **Nodes:** `Control` nodes for Documents, `TextureRect` for Stamps (`Approve`, `Deny`).
- **Data:** `DocumentData` Resource (Text, Type, ValidCodes, ErrorFlags).
- **Logic:** `DocumentValidator` class checks if the player's "Stamp" matches the document's validity state.
- **Pacing:** Documents get more complex (more pages, smaller font) in Act 2.

### 4.2 The Protector (Pathfinder)

- **Nodes:** `CharacterBody2D` for the Runner, `TileMap` for the path.
- **Logic:** Procedural generation of obstacles based on "Stress" level.

### 4.3 The Novice (WarioWare)

- **Structure:** A `MicroGameManager` that randomly instantiates small scenes (`MicroGameBase`).
- **Montage System:** Represents the 6-month timeline.
  - _Phase 1 (Month 1-2):_ Slow, confused inputs.
  - _Phase 2 (Month 3-5):_ Fast, frantic, high-skill inputs.
  - _Phase 3 (Month 6):_ Exhaustion mechanics (inputs ignore player occasionally).
- **Timing:** Uses `Engine.time_scale` to speed up the game over the 6-month montage.

### 4.4 The Partner (Rhythm)

- **Core System:** `Conductor.gd` (Singleton for this scene).
- **Logic:** Tracks song position using `AudioServer.get_time_since_last_mix()` - `AudioServer.get_output_latency()` for precision.
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
- **Input:** Left/Right Triggers (or Keys) control left/right balance.
- **Fail State:** If the "Load" touches the ground, the run resets (or stress increases).
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

- **Format:** JSON.
- **Content:** Serializes the `GameState` dictionary.
- **Triggers:** Auto-save after every Minigame completion.
- **Checkpoints:** Due to minigame duration (~30m), minigames must implement a `save_checkpoint()` method to store local state (e.g., "Document State" or "Current Song") in case of quit/crash.

---

## 6. Development Roadmap (Technical)

### Phase 1: The Skeleton

1.  Setup Godot Project & Git.
2.  Implement `GameState` and `SaveManager`.
3.  Build a "Greybox" Hub with simple state switching.

### Phase 2: The First Slice (The Novice)

1.  Implement `MinigameLoader`.
2.  Build the "WarioWare" framework (`MicroGameManager`).
3.  Create 3 micro-games (Inject, Pay, Wait).

### Phase 3: The Hub & Shaders

1.  Model the House (Base Layer).
2.  Implement the Shader pipeline.
3.  Connect Hub states to `GameState`.

### Phase 4: The Anthology (Production)

1.  **Batch 1:** Build _The Partner_ (Rhythm) and _The Provider_ (Bureaucracy Sim).
2.  **Batch 2:** Build _The Tuner_ (Shaders) and _The Mourner_ (Physics).
3.  **Batch 3:** Build _The Anchor_ (Physics/Rigging) and _The Protector_ (Pathfinder).
4.  **Integration:** Connect all minigames to the Hub transitions.

### Phase 5: Polish & Ship

1.  Audio Integration (Dynamic Mixing).
2.  Save System rigorous testing.
3.  Performance Profiling (Shader optimization).
