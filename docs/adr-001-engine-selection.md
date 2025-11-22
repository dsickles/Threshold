# ADR-001: Game Engine Selection

**Status:** Proposed
**Date:** 2025-11-22
**Context:** _Threshold_ is a Narrative Anthology requiring seamless transitions between a 3D Hub and various 2D/3D Minigames (Deckbuilder, Rhythm, etc.).

## The Options

### 1. Godot 4.x (Current Choice)

- **Pros:**
  - **Scene System:** Godot's "Everything is a Scene" philosophy is perfect for an anthology. A Minigame is just a Scene. The Hub is a Scene. Nesting them is trivial.
  - **2D/3D Hybrid:** Godot has dedicated 2D and 3D engines. You aren't faking 2D in a 3D world (like Unity) or fighting a 3D-first workflow (like Unreal).
  - **GDScript:** Python-like syntax is highly readable and extremely efficient for AI agents to generate and debug.
  - **Lightweight:** Fast startup and iteration time, crucial for a project with many small, distinct parts.
- **Cons:**
  - **Console Porting:** Native console support is improving but still requires third-party partners (W4 Games) compared to Unity/Unreal's out-of-the-box support.
  - **Asset Store:** Smaller than Unity's. You'll build more systems from scratch (though AI helps here).

### 2. Unity

- **Pros:**
  - **Asset Store:** You could buy a "Deckbuilder Kit," a "Rhythm Game Kit," and a "Runner Kit" to save time.
  - **C#:** Industry standard, strongly typed (good for large teams/codebases).
  - **Platform Support:** Easiest path to consoles/mobile.
- **Cons:**
  - **Bloat:** A project with 7 different game kits can become a tangled mess of conflicting dependencies.
  - **Workflow:** Unity's "Scene" management is heavier. Switching contexts isn't as fluid as Godot's node tree.
  - **Pricing/Trust:** Recent runtime fee controversies (though walked back) have shaken indie trust.

### 3. Unreal Engine 5

- **Pros:**
  - **Visuals:** Unmatched 3D rendering for the Hub.
  - **Blueprints:** Visual scripting is powerful.
- **Cons:**
  - **Overkill:** Using Nanite/Lumen for a 2D WarioWare minigame is like using a tank to deliver a pizza.
  - **2D Support:** Paper2D is neglected compared to Godot/Unity tools.

## The Verdict: Why Godot?

For _Threshold_, **Godot is the superior choice** for three specific reasons:

1.  **The Anthology Structure:**
    In Godot, switching from a 3D First-Person Controller (Hub) to a 2D Card Game (Provider) is as simple as `change_scene_to_file()`. The engine doesn't care. In Unity, managing these vastly different contexts often requires fighting the engine's assumptions.

2.  **The "Mixed Media" Art Style:**
    Godot's Shader Language is accessible and powerful. Creating the "Glitch" or "Noir" post-processing effects is straightforward and performant.

3.  **AI-Assisted Development:**
    Since you are working with AI agents (us!), **GDScript** is a superpower. It is concise. We can write a full Minigame Controller in 50 lines of GDScript that might take 150 lines of C#. This means less context window usage and fewer bugs.

## Decision

**We will proceed with Godot 4.x.**
The friction of building systems from scratch (vs. buying Unity assets) is outweighed by the speed of iteration and the architectural fit for a multi-genre game.
