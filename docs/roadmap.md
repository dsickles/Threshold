# Threshold Roadmap

The order things get built in. Decided in [ADR-0002](adr/0002-build-order-spark-to-silence.md). What is in v1 at all is in [scope.md](scope.md). Day-to-day work is tracked in Linear: one Linear project per milestone below, all under the Threshold initiative (see [agents/issue-tracker.md](agents/issue-tracker.md)).

Players always meet the chapters in story order: Partner, Protector (the Loss), Novice (the Long Haul), Provider (the Cost), Tuner, Anchor, Mourner, The Arrival. The build order below is different on purpose.

## M0 Setup

Get to the point where a change can be seen on a phone.

- New Godot 4.7.2 project in this repo (pinned in `CLAUDE.md`).
- A web build that opens from a private link (password-protected itch.io page) on Dan's phone and on a laptop browser.
- Three quick technical checks, each a throwaway test, not real game code (how each is judged is in [scope.md](scope.md), "Settled questions"):
  1. A bare scene runs smoothly on Dan's phone browser and meets the iPhone headroom bar.
  2. Rhythm timing: taps line up with the sound actually heard on a phone browser.
  3. Fixed-viewpoint movement feels good by tap on a phone.

**Done when:** Dan can open a link on his phone and see the three checks answered.

## M1 Spark to Silence (first playable)

About 15 minutes, rough, played in one sitting.

**In:**
- A rough House: 2–3 rooms of simple shapes, lamp light, ordinary fog, fixed viewpoints.
- A "tap to begin" screen (browsers play no sound until the player taps once).
- The opening story beat with the closed-off/open line, as text.
- A short Partner (3–4 minutes): one song, one beat chart, missed taps as awkward laughter.
- A warmer House after the Partner.
- The Loss: a hand-built runner path (3–4 minutes) ending in the fade, no warning, skip or retry.
- The Silence: the car, rain, no words.
- The House in grief (gray).
- A tiny version of the finished-chapter list and core table driving the House mood.
- Pause when the browser tab is hidden (no save).

**Not in M1:** title and settings screens, quality setting, Continue, journal, chapter looks beyond one gray filter, final art (the first art pass is M1.5). _(updated 2026-10-19: was "save/Continue". The save system itself is built in M1; see scope.md.)_

**Success criteria:**
1. Runs from a link on Dan's phone and a laptop browser, meets the iPhone headroom bar in [scope.md](scope.md), and passes one spot check on a real mid-range Android. _(updated 2026-10-17: was "smooth on one chosen mid-range phone")_
2. 5 people play it cold, with no instructions. At least 4 find the first object within about 3 minutes; nobody gets stuck moving around.
3. Nobody says the rhythm "counted my tap wrong."
4. Asked afterwards, most testers describe the Loss in emotional words, not "unfair." Nobody looks for a retry out of frustration. Nobody calls it cheap or exploitative.
5. Most testers notice the House changed, without being asked.
6. Dan, having played it, wants to build the rest.

**If item 4 fails, fix the Loss before building anything else.** Playtest notes go in [playtests/](playtests/).

## M1.5 Asset pass

_Added 2026-10-26 (Dan): starts once M1 is done._ _(updated 2026-10-29: Dan started the House and Loss art now, while DAS-95, DAS-96 and DAS-98 are still open. The Loss art (DAS-106) changes only the run's look; the House art (DAS-107) waits for the open House tickets to merge, then pulls main.)_

Replace the gray-box art of everything M1 built with free asset packs, following [ADR-0010](adr/0010-free-asset-packs-first-ai-fills-gaps.md) (packs first, AI only to fill gaps). Sources: [design/asset-sources.md](design/asset-sources.md).

**In:**
- Decide the House's look (realistic or soft low-poly) on a one-room test played on Dan's phone first, then dress the M1 rooms in the chosen style.
- The Loss: trees, stones, branches and path from packs; the car from a pack.
- The Partner: AI-made art for the 12 moment pictures and the couple, in one matching style (Dan, 2026-10-27: no art budget, so AI where no pack fits, per ADR-0010); pack particles for the lights and sparkles; a warmer background; a better pregnancy test.
- Every asset listed in [CREDITS.md](../CREDITS.md); the web build still meets the load and memory bar in [scope.md](scope.md).

**Not in M1.5:** new chapters, new mechanics, or changes to how M1 plays.

**Done when:** Dan plays M1 on his phone with the new art, it still meets the iPhone headroom bar in scope.md, and he prefers it to the gray box.

## M2 The Whole Story, Rough

Every chapter as a short rough version (2–4 minutes), in story order, playable start to finish.

- All eight chapters, using the real approach for each mechanic, with placeholder art.
- The House changes after each chapter; journal entries (wording follows the Stoic/Vulnerable answer).
- Saves between chapters, Continue, a basic title and pause screen.
- A cheap Anchor test: decide scripted wobble vs. real physics.
- Rough whole-game pacing check against the 2–3 hour target.

**Done when:** someone can play from the first tap to The Arrival, and a playtest says the story holds together.

## M3+ Chapter depth

Bring each chapter up to its full 10–15 minutes and its own look, one chapter at a time. Order comes from M2 playtests and risk, not from story order. The reference acceptance criteria for each chapter are in [design/stories/](design/stories/).

## Final: Polish & Ship

Settings (subtitles, reduced motion, quality), performance on the phone bar, AI-content and licensing checks, PC/Steam build.
