# Threshold Scope

The single answer to "is this in v1?". If a design doc describes something marked **Later** here, that doc keeps the idea but marks it "Not in v1". Claude checks this file before starting any ticket and asks Dan before building anything that is not v1.

**How to change it:** Dan decides. A change that is hard to reverse or surprising gets an ADR in [adr/](adr/); everything else is just an edit to this table with a date. New ideas that come up mid-build go under **Later** (and get a `later` label in Linear), not into v1.

## v1

| Feature | Notes | Decided |
|---|---|---|
| Browser first, then phone, then PC/Steam | One build, one tap scheme | 2026-09-20 |
| The New House as the hub, with fixed viewpoints | Real 3D, simple models | [ADR-0003](adr/0003-house-fixed-viewpoints.md) |
| All seven chapters plus The Arrival | 10–15 min each, 2–3 hours total | GDD |
| One result per chapter; fail-forward | Same facts and House objects for every player | 2026-09-22 O1 |
| Stoic/Vulnerable answers | Change spoken words and journal wording only | [ADR-0004](adr/0004-journal-wording-varies-no-mastery.md) |
| Dad's Journal | One entry per chapter | GDD |
| The Loss with no warning, skip or retry | | 2026-09-20 |
| Saves only between chapters | No mid-chapter checkpoints | 2026-09-22 D6 |
| Text dialogue with subtitles | No voice acting | [ADR-0005](adr/0005-ai-assets-text-dialogue-v1.md) |
| AI-generated art, music and sound | Check commercial terms before release | [ADR-0005](adr/0005-ai-assets-text-dialogue-v1.md) |
| House sounds (rain, fridge hum, heartbeat) | Recorded loops, not generated sound | 2026-09-22 |
| Maya's assist in the Anchor ("You've got this.") | Subtitle plus sound cue | GDD, ADR-0005 |
| Settings: subtitles, reduced motion, quality | | UX spec |
| Large-text reader for Provider paperwork | | UX spec |
| Accessibility "hobby floor" | 44px targets, subtitles on, no hue-only status | UX spec |
| "Tap along to calibrate" sound-delay step | The player taps along to a click once to set their device's sound delay for rhythm chapters. Added because one fixed adjustment did not hold steady on iPhone Safari in the M0 rhythm check. | 2026-10-17 |
| Sound plays in iPhone silent mode | The web build sets Safari's audio session to "playback", so the ring/silent switch does not mute the game | 2026-10-17 |

## Later (not in v1)

| Feature | Why later | Decided |
|---|---|---|
| Mastery goals and keepsakes | Scope | [ADR-0004](adr/0004-journal-wording-varies-no-mastery.md) |
| Voice acting | Cost | [ADR-0005](adr/0005-ai-assets-text-dialogue-v1.md) |
| Volumetric fog | PC-only extra; the browser can't do it | 2026-09-22 D3 |
| Free walking in the House | Replaced by fixed viewpoints | [ADR-0003](adr/0003-house-fixed-viewpoints.md) |
| "DON'T FAINT!" micro-game | Long Haul first batch is three micro-games | Epic 3 |
| Colorblind filters, control remapping, gamepad | Beyond the hobby floor | UX spec |

## Open questions (decide before the milestone that needs them)

| Question | Needed by |
|---|---|
| The House's small floor plan: which rooms, where the chapter objects sit | M1 |
| What The Partner shows on screen, its song, and its beat chart | M1 |
| What "Stress" is, whether it lasts beyond a chapter, and what it changes | M2 |
| Anchor: scripted wobble or real physics | M2 (cheap test) |
| Which automated-test addon to use for the core table and saves | M1 |

## Settled questions

| Question | Answer | Decided |
|---|---|---|
| Exact Godot 4.x version to pin | Godot **4.7.2** standard build (not .NET). Stay on it through v1; upgrade only if a bug forces it. | 2026-10-17 |
| Which phone is the performance benchmark | No mid-range phone is bought. The bar is **headroom on Dan's iPhone 17 Pro (Safari)**, sized for a phone about 4× slower: (1) steady 60 fps for 2 minutes, no visible stutter; (2) the game's own work at or under 4 ms per frame (a quarter of the 16.7 ms budget), shown on screen; (3) a test-only "heavy" switch that draws 4× the pixels still holds about 60 fps; (4) under about 500 MB memory and under about 10 s to load on home Wi‑Fi. Before M1 playtests, one spot check on a real mid-range Android (a borrowed phone or a free cloud-device trial). | 2026-10-17 |
| Which browsers must pass in M0 | Safari on Dan's iPhone 17 Pro and Chrome on Dan's laptop. His iPhone 17 and the Android spot check are extras. Chrome on iPhone uses Safari's engine, so it adds nothing. | 2026-10-17 |
| Where the private test link lives | A restricted, password-protected itch.io page. Web builds are exported single-threaded (no special server headers needed). Builds are uploaded with butler, itch.io's official upload tool (approved outside tool). Dan owns the itch.io account and logs butler in himself. | 2026-10-17 |
| How the rhythm-timing check is judged | A click track Dan taps along to; the screen shows average early/late. Passes if, after one fixed adjustment for the phone's sound delay, the average is within about 30 ms and nearly every tap would score Good. If it fails, a "tap along to calibrate" setting is proposed to Dan as a scope change. _2026-10-17: it failed on iPhone Safari with Godot's clock (average drifted); Dan added the calibrate step to v1 (see v1 table)._ | 2026-10-17 |
| How the fixed-viewpoint check is judged | By feel: a gray-box room with 3–4 viewpoints, tap to glide between them. Passes if Dan plus one or two people new to it move around without getting lost and without explanation. Settles the glide duration. | 2026-10-17 |
| Automated tests in M0 | None. M0 only sets up Godot's built-in script error check. The test addon is chosen in M1 with the core table. | 2026-10-17 |
