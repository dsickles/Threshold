# Where assets come from

Free sources to check first under [ADR-0010](../adr/0010-free-asset-packs-first-ai-fills-gaps.md) (packs first, AI only to fill gaps). Researched 2026-10-26 in the "Find free asset packs for Threshold" project thread; the longer write-up is the [Free asset packs for Threshold](https://claude.ai/artifact/PLLgB5fPmjBf8FCBhWWjFM) doc. In the game so far: the Loss's forest, from the Quaternius Stylized Nature MegaKit (DAS-106). Check each item's license on its own page before adding it, and add a line to [CREDITS.md](../../CREDITS.md).

## By place in the game

| Where | Source | License | Why | Watch out for |
|---|---|---|---|---|
| House furniture | [Poly Haven models](https://polyhaven.com/models) | CC0 | Realistic, fits the grounded House ([gdd.md](gdd.md), Art Style) | Small catalog; use 1k textures |
| House walls, floors, wood | [ambientCG](https://ambientcg.com) | CC0 | Realistic surfaces fill most of each view | 1k or 2k only |
| House light and sky through windows | [Poly Haven HDRIs](https://polyhaven.com/hdris) | CC0 | Natural reflections and sky | Large files; one small HDRI |
| House gaps (crib, fridge and so on) | [Sketchfab](https://sketchfab.com) downloadable models | Per model: use only CC0 or CC-BY | Wide range | Skip NonCommercial (NC) and NoDerivatives (ND); CC-BY needs a credit |
| The Loss run (path, trees, rocks) | Quaternius Stylized Nature MegaKit | CC0 | Simple shapes read well at speed | Keep counts low for phones |
| The car outside the House | Kenney Car Kit or Quaternius Cars | CC0 | Seen at night in rain | |
| The Novice and other cartoon chapters | [Kenney](https://kenney.nl/assets), [KayKit](https://kaylousberg.itch.io/furniture-bits) | CC0 | Bright, bold, one style | |
| Rain, glow, sparks | Kenney Particle Pack | CC0 | Ready-made particle images | |
| Chapter looks (noir, glitch, outlines) | [godotshaders.com](https://godotshaders.com) | Per shader (many CC0 or MIT) | Matches the shader plan in [game-architecture.md](game-architecture.md) 3.1 | No CompositorEffects (they don't run in the browser) |
| Provider paperwork fonts | Google Fonts, for example Courier Prime (OFL) or Special Elite (Apache 2.0) | Free commercial | Typewriter feel | Keep 4.5:1 contrast |
| House sounds, Foley | [Sonniss GDC bundles](https://gdc.sonniss.com/) | Royalty-free, commercial, no credit | Rain, room tone, hum, paper | Not CC0: never share the raw files |
| Any sound | [Freesound](https://freesound.org), CC0 filter | CC0 | Huge range | Many files are CC-BY or NC |
| UI clicks and taps | Kenney audio packs | CC0 | Consistent UI sounds | |

The shared fonts in [ux/DESIGN.md](ux/DESIGN.md) (Source Serif 4, Source Sans 3, IBM Plex Mono) are SIL Open Font License and need no change.

## Keeping the web build small

- Copy only the files used into `game/`, never a whole pack.
- glTF models, 1k textures (2k only where a texture fills the screen), and Godot's ETC2/ASTC texture compression for phones.
- Stay within the load and memory bar in [scope.md](../scope.md) (about 10 s to load, under about 500 MB).

## The House's look

Realistic: Poly Haven models and ambientCG surfaces (Dan, 2026-10-29, [scope.md](../scope.md)). Quaternius and KayKit are for the chapters, not the House.
