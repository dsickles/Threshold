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
| What The Partner shows on screen, its song, and its beat chart (draft: [design/partner-song-and-beat-chart.md](design/partner-song-and-beat-chart.md)) | M1 |
| What "Stress" is, whether it lasts beyond a chapter, and what it changes | M2 |
| Anchor: scripted wobble or real physics | M2 (cheap test) |

## Settled questions

| Question | Answer | Decided |
|---|---|---|
| Exact Godot 4.x version to pin | Godot **4.7.2** standard build (not .NET). Stay on it through v1; upgrade only if a bug forces it. | 2026-10-17 |
| Which phone is the performance benchmark | No mid-range phone is bought. The bar is **headroom on Dan's iPhone 17 Pro (Safari)**, sized for a phone about 4× slower: (1) steady 60 fps for 2 minutes, no visible stutter; (2) the game's own work at or under 4 ms per frame (a quarter of the 16.7 ms budget), shown on screen; (3) a test-only "heavy" switch that draws 4× the pixels still holds about 60 fps; (4) under about 500 MB memory and under about 10 s to load on home Wi‑Fi. Before M1 playtests, one spot check on a real mid-range Android (a borrowed phone or a free cloud-device trial). | 2026-10-17 |
| Which browsers must pass in M0 | Safari on Dan's iPhone 17 Pro and Chrome on Dan's laptop. His iPhone 17 and the Android spot check are extras. Chrome on iPhone uses Safari's engine, so it adds nothing. | 2026-10-17 |
| How House rings show where they go | Two kinds of ring: a ring through a doorway to another room is solid gold, a ring to a wall view in the same room is a gold outline (fill vs outline, not colour alone). Each ring has a short label under it naming where it goes (beside it, towards the middle, when it is pinned to the screen edge). The label words come from the floor plan's names ("Kitchen", "TV wall", "Big window") and are placeholders until Dan approves them. Object close-ups (later ticket) will need a third look. Dan's call on the decision card in the [DAS-93 project thread](https://claude.ai/code/project/chan_01Heqb6NDEptT8ADwVXQfsSV?thread=cmsg_01Heqb6NDEptT8ADwVXQfsSV9RUG5L7TvQZgrPD5CWCkhv), after playing the review build. | 2026-10-23 |
| Where the private test link lives | A restricted, password-protected itch.io page. Web builds are exported single-threaded (no special server headers needed). Builds are uploaded with butler, itch.io's official upload tool (approved outside tool). Dan owns the itch.io account and logs butler in himself. | 2026-10-17 |
| How the rhythm-timing check is judged | A click track Dan taps along to; the screen shows average early/late. Passes if, after one fixed adjustment for the phone's sound delay, the average is within about 30 ms and nearly every tap would score Good. If it fails, a "tap along to calibrate" setting is proposed to Dan as a scope change. _2026-10-17: it failed on iPhone Safari with Godot's clock (average drifted); Dan added the calibrate step to v1 (see v1 table) 2026-10-18: the browser's audio clock did better on iPhone (about −70 ms, no one-way drift, average 20–47 ms early), so the Partner uses it on the web ([ADR-0006](adr/0006-partner-browser-audio-clock.md)); calibration still sets the rest._ | 2026-10-17 |
| How the fixed-viewpoint check is judged | By feel: a gray-box room with 3–4 viewpoints, tap to glide between them. Passes if Dan plus one or two people new to it move around without getting lost and without explanation. Settles the glide duration. _2026-10-18: Dan judged it alone (no other testers for now); passed. Tapping a thing glides to a view looking at it, off-screen spots pin to the screen edge with an arrow, glide 2.0 s ([playtest](playtests/2026-10-18-m0-viewpoints.md))._ | 2026-10-17 |
| Automated tests in M0 | None. M0 only sets up Godot's built-in script error check. The test addon is chosen in M1 with the core table. _2026-10-18: Dan asked for automated gameplay tests now. A small test runner in the repo (`game/tests/`, no addon) runs headless in the PR check and covers the M0 checks (menu, smoothness counting, rhythm scoring, viewpoints). Which addon to use for the core table and saves is still open for M1. Browser tests too: Playwright (approved outside tool) plays the web export in Chromium on every PR ([tests/web](../tests/web/README.md)). They add to his phone tests, never replace them._ | 2026-10-17 |
| Which automated-test addon to use for the core table and saves | None: the test runner in the repo (`game/tests/`) covers the core table and saves. Saves are one JSON file in Godot's user folder, kept in the browser's own storage on the web ([ADR-0007](adr/0007-saves-json-file-in-user-folder.md)). | 2026-10-19 |
| Saving in M1 | The save system (finished-chapter list saved when a chapter ends, read back on the next visit) is built in M1 so every chapter after the Partner uses it. The Continue button, title screen and "Couldn't save." message stay in M2. Dan's call. | 2026-10-19 |
| How Dan plays the test build on his iPhone (DAS-91) | In **plain Safari, held sideways, with Hide Toolbar** (the "aA" or ··· button by the address). A web page can't hide Safari's bars on iPhone, so itch.io's fullscreen button only fills the Safari window. Adding the page to the Home Screen does hide the bars, but there the Partner's taps landed off target and the chapter didn't respond, so it is not used. A private page of our own that installs as a full-screen app is the fallback if this stops being enough. Dan, 2026-10-22: "Hide toolbar was sufficient!" | 2026-10-22 |
| Phone orientation for the whole game | **Sideways.** One layout for phone, laptop browser and PC/Steam; every M0 test was sideways and the project is 1280×720. The web build needs a "turn your phone sideways" screen for people holding the phone upright. | 2026-10-19 |
| The House's small floor plan: which rooms, where the chapter objects sit | **Settled for M1** as [design/house-floor-plan.md](design/house-floor-plan.md) has it: one storey, the M1 rooms and views, the four M1 story points, the chapter objects and the 18 House object entries. It can change once it can be seen in the game. Its open calls (the spare room's later role, the memory box, the record player's later life) are M2's. The core table (`game/_core/house/house_table.gd`, DAS-92) follows it. Dan, 2026-10-22: "settled for M1 until it can be seen in the game". | 2026-10-22 |
| UI type scale and button style (DAS-66 review) | The DESIGN.md type scale means the size seen on a sideways phone; the 1280×720 layout sizes are scaled up to match. One shared button and text theme for every screen. Lists of equal choices use button-quiet; button-primary is for the one main action. Built in M1 when the first real menu is made (DAS-72); the M0 screens stay as they are. | 2026-10-18 |
