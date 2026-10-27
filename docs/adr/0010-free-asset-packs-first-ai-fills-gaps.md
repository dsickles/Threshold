---
status: accepted
date: 2026-10-26
supersedes: the asset part of ADR-0005 ("v1 uses AI-generated models, textures, images, music and sound"). ADR-0005's text dialogue and no voice acting stay.
---

# v1 uses free asset packs first; AI-generated assets only fill gaps

ADR-0005 said v1 uses AI-generated art and audio because there were no existing assets. Free asset packs with licenses that allow selling on Steam give a more consistent look than AI models, with clear terms. Dan chose "packs first, AI fills gaps" in the project thread, 2026-10-26 (thread "Find free asset packs for Threshold"), recorded in DAS-101.

## Decision

- Look for a free pack first for any model, texture, image, sound or music. Use an AI-generated asset only when no pack has what is needed.
- Licenses allowed: **CC0** (best), **CC-BY** (with a credit), and royalty-free licenses that allow commercial use in a game, such as the Sonniss GDC bundles. Not allowed: non-commercial (NC), no-changes (ND), or "personal use only".
- Every outside asset, and every AI-generated one, gets a line in the root [CREDITS.md](../../CREDITS.md) (file, source, author, license) in the same PR that adds it. A folder may also keep its own CREDITS.md with longer notes (as `game/assets/audio/partner/` does); the root file is still the full list.
- Copy only the files used into `game/`, never a whole pack. Use glTF models and 1k or 2k textures, to keep the web build within the load and memory bar in [scope.md](../scope.md).
- Where to look first is in [design/asset-sources.md](../design/asset-sources.md). The House's look (realistic or soft low-poly) is an open question in [scope.md](../scope.md).

## Consequences

- Fewer AI-generated assets, so a shorter AI disclosure when the game is submitted to Steam. Steam still requires one for any AI asset that stays.
- AI-generated or code-generated assets already in the game (the Partner's placeholder sounds and silhouettes from `tools/partner/`) stay until a pack or final art replaces them. The Partner's song is already a licensed Pixabay track, which fits this ADR. Pixabay music can be registered with YouTube's Content ID, so check that track before it is final.
- Mixing packs can look patchy. Keep each place (the House, each chapter) to one or two matching sources.
- Final art is still not in M1 ([roadmap.md](../roadmap.md)); this ADR says where assets come from, not when they are added.
