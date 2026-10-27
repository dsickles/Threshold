---
status: accepted
date: 2026-10-17
supersedes: v1 voice-acting scope in narrative-design (Production Notes) and FR8
---

# v1 uses AI-generated assets and text dialogue

_2026-10-27: the asset part is superseded by [ADR-0010](0010-free-asset-packs-first-ai-fills-gaps.md): free asset packs first, AI only to fill gaps. Text dialogue and no voice acting still stand._

There are no existing art or audio assets, so v1 uses **AI-generated** models, textures, images, music and sound. Dialogue is **text with subtitles**, no voice acting. House sounds (rain, fridge hum, heartbeat) are still in. Voice acting moves to "Later" in [docs/scope.md](../scope.md).

## Consequences

- Before a public release, check each AI tool's terms allow commercial use. Steam requires a disclosure of AI-generated content when the game is submitted.
- Simple, consistent styles hold up better than detailed ones; fixed viewpoints ([ADR-0003](0003-house-fixed-viewpoints.md)) help hide flaws.
- Maya's assist line in the Anchor ("You've got this.") is a subtitle plus a sound cue in v1, not a recorded voice.
