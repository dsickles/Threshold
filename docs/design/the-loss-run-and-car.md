# The Protector (the Loss): the run and the car (draft)

**Status:** Draft for Dan to decide, 2026-10-22, updated 2026-10-25 for Dan's first answer: **a 3D run seen from behind, like Temple Run** (DAS-94, made with the [narrative-craft skill](../../.claude/skills/narrative-craft/SKILL.md)). Nothing here is decided until Dan says so. Answers the open question in [scope.md](../scope.md): "What the Loss and the Silence show, the run's tap action, its obstacles, the fade and the car" (needed by M1). Once Dan settles it, the answer moves to scope.md "Settled questions" and this file stops saying "draft". The code tickets (DAS-97 the run, DAS-98 the car and the House in grief) wait until he approves it.

Built from: [roadmap.md](../roadmap.md) M1 ("a hand-built runner path (3–4 minutes) ending in the fade, no warning, skip or retry"; "the Silence: the car, rain, no words"; success criterion 4), [gdd.md](gdd.md) §2 The Protector, [requirements.md](requirements.md) FR6, FR19, FR20, UX-DR26 and UX-DR28, [epic-2-stories.md](stories/epic-2-stories.md) Stories 2.1–2.4, [EXPERIENCE.md](ux/EXPERIENCE.md) (the Loss rows and the Jordan flow), [game-architecture.md](game-architecture.md) §4.2, [house-floor-plan.md](house-floor-plan.md) (the bedside lamp starts it; home through the front door), the [continuity ledger](continuity-ledger.md) and the Partner as built (DAS-73).

What the docs already fix: no warning, no skip, no retry, no title card; it starts from an ordinary tap on the bedside lamp; the run starts sunny and clear while the couple is planning and dreaming, and the UI doesn't label that; a fixed, hand-built obstacle sequence on a flat tiled path, not random; the pacing runs euphoria, confusion, panic, silence; a stumble never ends the run; the runner (the baby) fades even after perfect play; no "Chapter failed. Try again?"; no hit-shake with reduced motion; no care UI; then the car, rain and no words; then the House in grief, coming in through the front door. Leaving mid-chapter starts it again from the beginning, and nothing saves until the car is over.

Lines marked **Choice** are mine where the docs say nothing. Lines marked **Dan** are his calls; the full list, each with a recommended answer, is at the end. **No story words are written here**: the run and the car have none, and nothing below is on-screen text.

## The feeling

**Helplessness after competence: doing everything right, and it still goes.** Just before: the warm House after the Partner, the test on the counter, the sesame-seed note on the fridge. Just after: rain, a parked car, nobody speaking, then the gray House. The run has to make the player feel capable and needed first, so that being unable to help lands as loss, not as losing.

## The recommendation: "Clear the way"

**Central image:** a small light running away from the camera down a path, and the player's taps clearing the path ahead of it. The light is the same kind of light as the Partner's, now small and new. Leo is a fixer (narrative-design.md), and here the player's hands do exactly what a fixer does: see the problem coming and move it. It works, beautifully, for most of the run. Then the light goes out on a stretch of path where there is nothing left to fix.

Why this one (principle 1, the verb carries the feeling): the GDD and the game brief call the chapter "Pathfinder" and "clearing the path for the family", and the Protector archetype is protecting. Making the player the protector, not the runner, means the loss happens *to someone they were looking after*, which is the true shape of this grief for a father. And because the light fades where there is no obstacle at all, the fade can't be read as the player's mistake, which is what success criterion 4 needs.

### What the screen shows

**Dan, 2026-10-25: 3D, seen from behind, like Temple Run.** The camera follows just behind and a little above the light, and the path runs away into the distance. Held sideways (1280×720, scope.md). The House is already 3D, so this uses the same renderer, ordinary fog and lamp-style lighting, with no CompositorEffects.

All simple shapes, no final art (M1):

- **The path:** a raised walkway of plain square tiles, about three tiles wide, floating over a soft void, running into the distance. **Choice:** like Temple Run, it bends left and right and rises and dips on its own; the camera swings round each bend with the light. The player never steers: the bends are scenery, not choices. Ordinary distance fog hides where the path is being built ahead.
- **The light (the runner):** a soft glowing ball in the middle of the path, in the lower middle of the screen, bobbing as it runs. It always stays in the middle of the path; the world comes toward it. Same warm amber as the Partner's heart, smaller. It lights the tiles around it, so it is also the scene's main lamp.
- **Obstacles** come down the path toward the light, three kinds, all plain shapes:
  - **Stone:** a rounded block in the middle of the path. Cleared, it rolls off the edge and drops away.
  - **Branch:** a low bar across the path. Cleared, it lifts up and out of the way.
  - **Gap:** missing tiles across the path. Cleared, tiles rise up from below to fill it.
- **The sky and the void:** plain colours (a gradient sky dome, fog the same colour) that change with each part of the run (below).
- **The future silhouettes:** **Choice:** flat, softly lit cut-outs standing out in the void beside the path, passing by as the light runs, like the Partner's silhouettes of their past. They are never tappable and never labelled. **Dan:** which moments they are (story, not mine to pick; a placeholder list is in Dan's calls). None of them is a crib (there is no crib until the Anchor) and none becomes a House object.
- **Not a car:** the runner is the light, never a vehicle, so the run can't read as a car accident (Dan's note, 2026-10-25, [story-beats.md](story-beats.md)).
- **No HUD:** no score, no distance counter, no meter, no pause button on screen (the tab-hidden pause still works).

### The one tap action

**Tap anywhere to clear the next obstacle.** When an obstacle comes within reach of the light, it lights up softly (a warm outline, so it reads without colour alone). A tap anywhere on the screen clears the nearest lit obstacle, with a small, satisfying sound. The whole screen is the target, so it is far over 44 px, and nothing depends on hover. Click is tap.

- **Reach:** an obstacle is in reach from about 1.3 s before it would touch the light in the euphoria, 1.0 s in the confusion and 0.8 s in the panic. **Choice**, to tune in playtests. Even the shortest is generous: this is not a skill test.
- **A tap with nothing in reach** makes a small ripple where the finger landed, and nothing else. No penalty, no sound of failure. (The Partner's lesson: punishing extra taps is what makes people say a game "counted my tap wrong".)
- **Every tap that has something to clear, clears it.** No obstacle ever needs two taps, and no tap is ever silently ignored. Honest input is the first protection against "unfair".
- **Choice:** tap anywhere, not "tap the obstacle itself". It is one obvious action for a cold tester, it is what the Partner taught them minutes ago, and moving targets are hard to hit with a thumb. **Dan:** see call 2.
- **No swipes.** Temple Run steers, jumps and slides with swipes. Here the light never needs steering: the path bends on its own, and clearing is the only action. That keeps the one tap scheme (CLAUDE.md) and avoids a real problem on Dan's phone: in Safari a swipe in from the edge goes back a page, and a swipe can bring the hidden toolbar back. **Dan:** see call 11.

**What a stumble does.** If an obstacle reaches the light uncleared, the light goes through it: the stone cracks apart, the branch snaps, the light hops over the gap with a lurch. A dull, soft thud (not a buzzer). The light flickers dimmer for about 0.6 s and recovers fully. It never slows, never stops, never falls, and never loses ground. There is no count of stumbles and nothing carries over: by the time the next obstacle arrives, the light is exactly as it was. No screen shake, ever, not only with reduced motion (UX-DR26, "Loss does not add juice").

### The run, part by part

The whole run is one fixed timeline, the same length for every player: about 3 minutes 35 seconds from the lamp click to black. Nothing the player does moves it earlier or later. **Choice:** times below are from the lamp click.

| Time | Part | Sky and world | Music | Obstacles |
|---|---|---|---|---|
| 0:00–0:05 | Dark | Black. The lamp has just clicked off. A breath of quiet. | None | None |
| 0:05–1:25 | **Euphoria** | The light fades up out of the black into a warm, sunny morning. Wide, clear, golden; long gentle bends. The future silhouettes pass by beside the path. The light grows a little over this part. | The song, bright (see "Music and sound") | 12, one every 2 bars, landing on the beat. Easy. |
| 1:25–2:15 | **Confusion** | The sun goes hazy, the fog closes in and the colour starts to drain toward gray. Wind. The bends come sharper and less evenly. The silhouettes blur and thin out. Tiles at the path's edges crack and drop away into the void as the light passes (only beside and behind it, never in its way). | The song plays on, but wind and the first rain start to rise over it | 12, off the beat and at uneven gaps, so they stop feeling like a dance |
| 2:15–2:55 | **Panic** | Dark and stormy. Rain. The fog is close, so the path ahead appears late. The path narrows to one tile wide, and each tile cracks and falls away just after the light crosses it, so the path seems to give way under it, but it always lands. No silhouettes. | The storm takes over: rain, wind and thunder drown the song until only scraps of it come through | 25, in tight clusters of two or three |
| 2:55–3:35 | **Silence** | Everything stops at once: the music, the wind, the rain, the obstacles. The path is whole again, wide, flat and straight, and the fog lifts so it can be seen running far ahead with nothing on it. The world is fully gray. | None | None |

**The obstacle sequence.** Hand-built and fixed (FR20). Times are when each one would reach the light; S stone, B branch, G gap.

- **Euphoria (12):** 0:13 S, 0:18 S, 0:24 B, 0:29 S, 0:34 G, 0:40 B, 0:45 S, 0:50 G, 0:56 B, 1:01 S, 1:06 G, 1:12 S. The first two are both stones, alone, so a cold tester learns the tap on the simplest shape before anything else appears. 1:12 to 1:25 is clear: the brightest, happiest stretch, with nothing to do but watch.
- **Confusion (12):** 1:29 S, 1:33 G, 1:39 B, 1:42 S, 1:48 S, 1:50 B, 1:56 G, 1:59 S, 2:02 B, 2:06 G, 2:09 S, 2:13 G.
- **Panic (25, clusters 0.6 s apart):** 2:17 S S; 2:20 B S G; 2:25 G S; 2:28 S B S; 2:32 B G; 2:36 S S G; 2:39 G B; 2:43 S G S; 2:47 B S; 2:51 G B S (the last at 2:52).

**Every obstacle can be cleared.** A player who taps well clears all 49 and never stumbles. That is on purpose: FR19 and the GDD say the runner fades "despite the player's perfect play", so perfect play has to be possible. What the player can't stop is the path giving way behind and under the light, which has nothing to tap. **Dan:** the GDD also says "obstacles become unavoidable"; see call 3.

**Why no randomness at all:** with a fixed list, Dan can tune each obstacle by hand, every tester plays the same run, and the playtest compares like with like.

### How the fade lands

In one line: **the music stops, the light runs on alone down an empty path, slows to a stop, and goes out. Then the screen goes black and the car begins.** The run doesn't just stop, and there is no blank ending: the car follows it within seconds.

Second by second (the same for a perfect run and a stumbling one, because nothing in it depends on play):

1. **2:55, everything stops dead.** The storm and the last scraps of the song cut out at once (the end of the song in a short "tape stop", the effect the Partner's song tool already has). The path straightens and the fog lifts: the player can see the path running far ahead, empty. The light is fully bright, exactly as bright for every player, because stumbles never carry over.
2. **2:55–3:05, it keeps running.** Ten seconds in total silence on the clear, gray path. Nothing comes. A tap makes the small ripple where the finger lands; it never reaches the light. **Dan:** call 4.
3. **3:05–3:15, it slows to a stop.** The camera slows with it and comes to rest just behind it.
4. **3:15–3:25, it goes out.** The light dims and shrinks to nothing. The tiles it was lighting go dark with it. No sound when it goes out, no flash, no sting.
5. **3:25–3:35, the empty path.** The gray path, still, with nothing on it. Then black.
6. **3:35, the storm again.** Over black, the same storm fades up, heard now from inside a car, and the car begins (below). It is the storm from the run: it was real.

No text, no "the end", no score, no button. The obstacles stop *before* the fade on purpose: the light doesn't go out because something hit it. Nobody can point at a moment and say "if I'd tapped that, it would have lived". That is the truest thing the run can say to people who have been through this, and the main protection against "unfair".

### Music and sound

**The song is not replaced: the storm drowns it** (Dan, 2026-10-25: the sounds of the storm overtake the song, and the couple sits in the car in the same storm, with the same sounds). The Partner as built uses "Dreamy Lo-Fi Beat" (NewEraMusic via Pixabay, Pixabay Content Licence, already cleared for edited use in the game, [CREDITS.md](../../game/assets/audio/partner/CREDITS.md)). The Loss picks up the couple's song where the Partner left it, so the joy is the same joy (principle 5), and nothing is ever swapped in for it: the weather simply takes it away.

1. **0:05–1:25, the song**, bright.
2. **1:25–2:15, the storm comes in.** Wind and the first rain rise under and then over the song as the sky goes hazy. The song keeps playing, getting further away.
3. **2:15–2:55, the storm takes over.** Heavy rain, wind and thunder. The song is drowned until only scraps of it come through.
4. **2:55, everything stops dead.** Storm and song together. This is the silence the roadmap asks for (euphoria, confusion, panic, silence), and the light goes out in it, with nothing to hear.
5. **3:35, the same storm, from inside the car.** The same recordings, muffled as if on a car roof and windows. The player knows that sound: the run and the car are the same night.

**Decided (Dan, 2026-10-25): the storm stops for the fade, then comes back in the car.** Keeping the storm going through the fade would lose the silence, which is the one stretch where the light visibly goes out with nothing touching it. Stopping it, then bringing back the very same storm over black, says the run was the night itself.

**Why this is better than a new track:** one sound runs from the run into the car and on into the House, where the rain is on the windows (the ledger's rain row), so the weather carries the loss home. It needs no second track to find, license or tempo-check. **Choice:** the car's storm is mostly rain on the roof, with thunder only far off, once or twice, so it stays close to FR6 ("no words, just the sound of rain").

All of it is made **ahead of time** by a script, the way `tools/partner/make_song.py` makes the Partner's track, and played as ordinary recorded audio. Nothing is generated or bent live: the browser's default audio mode drops on-the-fly effects (game-architecture §3.2).

| Part | Sound | Source |
|---|---|---|
| Dark | The lamp click (the House's sound for the lamp), then nothing | House |
| Euphoria | The song's bright version, as at the Partner's best | Partner's song, edited |
| Confusion | The song, with wind and rain rising over it | Partner's song; storm recordings: free licensed sound effects (Pixabay or CC0), listed in CREDITS.md, or AI-made (ADR-0005) |
| Panic | The storm, loud: heavy rain, wind, thunder, scraps of the song under it | The same storm recordings and song, mixed offline |
| Clear / stumble | A soft, warm click for a clear; a dull thud for a stumble | Same |
| Silence | Nothing. Not the House hum, not a tone. | — |
| Car | The same storm, heard from inside: rain on the roof, thunder far off once or twice; the engine ticking as it cools, fading out in the first 20 seconds | The run's storm recordings, muffled; one engine-tick recording. The House's rain after the Loss uses the same recordings. |

**Timing:** obstacles in the euphoria land on the song's beat (the song is 90 beats a minute, so one obstacle every 2 bars is every 5.3 s). The confusion and panic obstacles are off the beat on purpose, as the storm takes the beat away. The reach windows are wide, so the run needs none of the Partner's precise tap timing or calibration (ADR-0006); Godot's own audio clock is enough to keep obstacles on the beat. **Hiding the tab** pauses the music and the run together and saves nothing.

### The look, inside the rules

- **The gray drain** (Story 2.1, "a gray drain the chapter can fill in"): the sky, fog, light and tile colours are authored per part and ease toward `house-grief` (#5C534C) across the confusion and panic. By the silence the run is the same gray as the House it hands back to. No CompositorEffects and no volumetric fog; colours, ordinary fog and the light do it in the browser.
- **Rain** in the panic is simple particles (CPU particles, which the web renderer handles well), cheap on a phone.
- **On the phone:** a few hundred plain tiles, three obstacle shapes, one moving light and fog. Old tiles are removed behind the camera, so the scene stays small. It must meet the same iPhone headroom bar as the House (scope.md), checked on Dan's phone.
- **No flash, no shake, no confetti, no slow-motion**, in any setting.

## The car (the Silence)

**Central image:** the House's front door, seen through rain on a windshield. The first tap of the whole game crossed that door at dusk on moving day (view P, the porch). Now the player sees it again, at night, from the car, and doesn't want to go in yet (principle 2, change the familiar).

**Choice: the car is parked outside the House**, engine off, after the drive home from the hospital in the night. The hospital is never shown. This joins the floor plan's facts: the player comes in through the front door and finds the keys dropped on the entry floor.

**What is seen.** The same kind of fixed views as the House, in simple shapes, at night:

| View | Shows |
|---|---|
| **C1 Windshield** (the car opens here) | Rain running down the glass, wipers still. Through it, the House: the porch light on, the front door. |
| **C2 Maya** | The passenger seat. Maya as a simple dark shape, turned toward her window, rain on the glass beside her. Nothing to tap. |
| **C3 The wheel** | Leo's hands on the wheel, the keys still in the ignition. The keys are not tappable (they are kept for the Arrival). |

**What can be tapped.** Only the views: tap a view's ring to glide to it (2.0 s, as in the House), short-drag to look a little. No words, no subtitles, no objective text, no HUD, no skip (Story 2.3). Nothing to do with Maya: Leo can only be there. **Choice:** holding her hand is the Arrival's ending (the Partner's rhythm returns as holding the hand), so it is not spent here.

**How long.** At least 60 seconds from when the car fades in. **Choice:** the rain fades up over black for 3 s first, so the silence of the run turns into rain before anything is seen.

**How it ends (Dan, call 8).** After 60 s the front door, seen from C1, quietly gets the same ring every House doorway has. Nothing else changes. When the player taps it, the car door opens (the rain gets louder for a moment), the screen goes to black over 2 s, and the chapter reports that it finished. The player chooses when to go in, and can sit as long as they like; there is still nothing to skip, because the minute in the car always happens.

**Handing back to the House.** The chapter only reports `finished` (no Stoic/Vulnerable answer here). The core table turns that into the House in grief; the House opens at the entry (E1), gray, with rain on the windows and the keys dropped on the floor, as the floor plan says. **For the code tickets:** the House must have its gray mood and the E1 view set *before* it is shown, so the player never glimpses the warm bedroom where they left it. That is the core table's and the House's job (DAS-92, DAS-98), not the chapter's. M1 ends there, in the gray House, with no card.

## Leaving, pausing, saving

- **Hiding the tab** pauses the run (or the car) and saves nothing.
- **Closing the tab or reloading** anywhere in the run or the car starts the Loss again from the lamp click next time, with no warning screen (D6, EXPERIENCE.md "Jordan"). The save is written only after the car, when the chapter finishes.
- Nothing ever asks "are you sure?", offers a retry, or shows a skip.

## Alternatives considered

**A2. The same run, in 2D seen from the side.** This was the first draft's view: the path scrolls right to left and the light stays a third of the way in. Cheaper to build, and easy to read on a phone. Dan chose 3D (2026-10-25): the view from behind puts the player with the light, looking where it's going, which makes the path ahead and its giving way much more felt. Better at: cost.

**B. "Run with her": the player is the runner, tap to jump.** The classic one-button runner (the light, or the couple, jumps over obstacles). Simplest to understand. But the player *is* the thing that fades, which turns the fade into "I died", the language of failing a level. To make obstacles "unavoidable", jumps would have to fail even when timed well, which is exactly what testers call unfair. Better at: instant familiarity.

**C. "Lay the path": tap in rhythm to lay each stone ahead of the light.** The truest "pathfinder": the path is dark ahead and the player builds it stone by stone on the beat; later the stones crack as they're laid. Strong image of providing. But it is the Partner's verb again (tap in time), which blunts the contrast between chapters, and it brings back the rhythm-timing risk ("counted my tap wrong") in the one chapter that must never feel unfair. Better at: a direct line to Leo's "provide" flaw.

**D. A 3D lane runner, with steering.** The view Dan chose, but with Temple Run's controls: tap left or right (or swipe) to change lanes or turn at corners. More like the game it comes from. But steering adds a second action and a way to fail that has nothing to do with protecting the light, a tap-side rule is easy to get wrong held sideways, and swipes fight Safari on the phone. Better at: being a familiar game.

What the recommendation gives up: A2's lower cost, B's and D's instant familiarity (mitigated by teaching on two lone stones) and C's direct "provider" image (the clearing verb carries "protector" instead, which is this chapter's archetype).

## Ledger changes

Added to the [continuity ledger](continuity-ledger.md), all `proposed`:

- **Fact: the night of the loss.** A night in month 2 (FR17). They leave for the hospital in the night (never shown) and come home in the car in the rain.
- **Place: the car**, parked outside the House on the night of the loss (the Silence). Seen only then in M1. An idea for later: the same car takes them to the hospital in the Arrival.
- **Object: the porch light.** On at dusk on moving day; on again through the rain from the car (left on when they rushed out).
- **Object: car keys** (changed): in the ignition in the car, seen but not tappable, before they are dropped on the entry floor.
- **Sound: the couple's song** (the Partner's song): the Partner; then the Loss's euphoria; drowned by the storm in the confusion and panic; stopped dead at the silence.
- **Sound: the storm** (new): rises in the run's confusion, takes over in the panic, stops dead in the silence, comes back the same in the car, and its rain carries into the House.
- **Sound: rain** (changed): part of the storm; starts in the run's confusion, stops dead in the silence, comes back in the car and carries into the House.
- **Motif: the small light.** The Partner's lights and heart; the runner in the Loss, which fades. Introduced, so it should be paid off later (an idea: a small light in the Tuner or the Arrival; M2 decides).
- **Motif: moments of their life as silhouettes.** The Partner shows their past together; the Loss shows the future they imagine, and takes it away. Paid off later if the Arrival shows one come true (M2 decides).
- **Motif: coming home through the front door.** The first tap of the game; home from the car after the Loss. Leaving through it with the keys is still the Arrival's.

## Checks this design must pass

From the roadmap, the stories, CLAUDE.md and the narrative-craft skill. None is optional, and the ones that need Dan's phone wait for Dan.

**Rules (CLAUDE.md):**

- **No warning, no skip, no retry.** Nothing before the lamp click points at the loss (the lamp is "going to sleep"). No title card. No skip control anywhere in the run or the car. No retry, "try again" or "chapter failed" at the fade or after.
- **One result.** Every player reaches the same fade, the same car and the same House. Stumbles change nothing that lasts. The chapter offers no Stoic/Vulnerable answer.
- **One tap scheme.** Tap anywhere (the run) and tap a ring (the car). No swipes, WASD, stick, mouse-look or gamepad. Nothing on hover. Targets over 44 px.
- **No CompositorEffects, no volumetric fog.** Colours, ordinary fog, the light and particles only.
- **The UI never explains the metaphor.** No words on screen at all; nothing names the light, the parts of the run or what happened.
- **Saves only between chapters.** Hidden tab pauses; leaving restarts from the lamp.

**Tests the code tickets add** (headless, `game/tests/`, the repo's own runner):

- The obstacle list matches this doc: 49 obstacles, 12/12/25 by part, none after 2:52, none in the silence.
- **The perfect run and the empty run reach the same ending:** play the run with every obstacle cleared, and again with no taps at all; both reach the fade at the same time, with the light at the same brightness at 2:55, and both finish the chapter once.
- A tap with nothing in reach clears nothing and changes nothing; a tap with something in reach always clears exactly one.
- A stumble never changes the light's speed or position, and the light is back to full within a second.
- The chapter reports `finished` exactly once, only after the car, with no answer; leaving mid-run writes no save.
- Browser test (tests/web): the run opens from the lamp, has no console errors, and plays through to the car and back to the House.

**Needs Dan's device:** the run's feel on his iPhone (plain Safari, sideways, Hide Toolbar) and laptop Chrome; whether the reach windows feel fair; whether the silence lands; the car's length.

**Story 2.2's "10–15 minutes"** is the full chapter in M3+. M1's run is 3–4 minutes (roadmap), so this draft is sized to that; M3 lengthens the euphoria and adds set pieces without changing the shape.

### What success criterion 4 needs, and how the playtest checks it

Criterion 4: "Asked afterwards, most testers describe the Loss in emotional words, not 'unfair.' Nobody looks for a retry out of frustration. Nobody calls it cheap or exploitative."

**What the design does for it:**

1. **The fade is not caused by play.** No obstacle in the silence; the light is equally bright for everyone; it goes out on a clear path.
2. **Input is honest.** Every tap with something in reach works; stray taps cost nothing; no obstacle needs two taps; perfect play is possible.
3. **No game-over language.** No score, counter, buzzer, shake, "game over" sound or screen, and no retry to look for.
4. **Joy first.** 80 seconds of easy, on-the-beat success to the couple's own song, so there is something to lose.
5. **Not cheap or exploitative.** Restraint: no graphic image, no blood, no hospital, no words telling the player how to feel. The loss is shown only as a light going out and a song stopping. The car gives the player a minute of quiet with someone else in it.

**How the M1 playtest checks it** (written up in `docs/playtests/`, as the roadmap asks):

- **Watch, don't help.** Note if the tester, during or right after the fade, reloads the page, looks for a menu or back button, taps hard and repeatedly on the empty screen, or says "wait, what did I do?". Any of those after the fade is "looking for a retry".
- **Ask after the whole session, open first:** "How would you describe the second part (the running) to a friend?" Write their words down exactly. Then: "How did the ending of that part feel?" Only then, if they haven't said it: "Did anything feel like it was your fault?" Never ask "was it unfair?" (it plants the word).
- **Sort the words** into emotional (sad, gutted, quiet, helpless, heartbreaking, "I didn't expect that") and fairness or mechanics (unfair, broken, bug, rigged, cheap, "I couldn't do anything about the controls").
- **Passes if:** at least 3 of the 5 testers use emotional words, nobody uses "unfair", "cheap" or "exploitative" (or says so in other words), and nobody looks for a retry. **If it fails, fix the Loss before building anything else** (roadmap).
- **Care for testers:** the M1 playtest note should say whether any tester has been through a loss, if they choose to share it, and Dan should know some testers may have. That is for the playtest, not the game (the game gives no warning).

## Dan's calls

Each has my recommended answer. Calls 1–5 and 11 shape the run (DAS-97); 6–9 the car (DAS-98); 10 is a doc conflict.

1. **The concept: "Clear the way"** (the small light runs; the player's taps clear its path; it goes out on a clear stretch after the music stops)? *Recommended: yes.* Alternatives: the player as the runner, tapping to jump (B); laying the path in rhythm (C); a lane runner with steering (D). **Part decided (Dan, 2026-10-25): 3D, seen from behind, like Temple Run, built that way straight away (no 2D test first).** The concept itself is still open.
2. **Tap anywhere, or tap the obstacle itself?** *Recommended: tap anywhere* (one obvious action for a cold tester, what the Partner just taught, fair on a phone). Tapping the obstacle itself feels more hands-on, and could be tried in a playtest if the run feels too easy.
3. **Can every obstacle be cleared?** The GDD says both "obstacles become unavoidable" and "fades despite the player's perfect play", and those pull against each other. *Recommended: every obstacle can be cleared; what can't be stopped is the path giving way and the light going out.* An obstacle no tap can clear is the thing testers will most likely call unfair.
4. **Taps during the silence:** a small ripple where the finger lands that never reaches the light, or nothing at all? *Recommended: the ripple.* With nothing at all, a tester may think the game froze; the ripple says "you're still here, and there's nothing to fix".
5. **Music.** Decided in outline (Dan, 2026-10-25): the Partner's song, drowned by a storm, and the same storm in the car. **Decided (Dan, 2026-10-25): the storm stops dead with the song at 2:55, the light goes out in silence, and the same storm comes back over black for the car.**
6. **The future silhouettes on the horizon:** keep them, and which moments? *Recommended: keep them, 4 to 6 moments.* **PLACEHOLDER ideas, not decided, Dan's to replace:** a walk with a pram, a small hand around a finger, a first birthday, a child on Leo's shoulders. Rules: no crib, nothing that later becomes a House object, simple silhouettes in the Partner's placeholder style.
7. **The car: parked outside the House at night, Maya in the passenger seat turned to her window, three views (windshield, Maya, the wheel)?** *Recommended: yes.* The other way is the car still driving home, which shows motion but loses the front door through the windshield.
8. **How the car ends:** the front door gets a ring after 60 s and the player taps it to go in, or the car fades out on its own after a fixed time? *Recommended: the ring after 60 s.* The player chooses when to go in, and the first door of the game is the last tap of the Loss. The risk is someone not noticing the ring; the playtest watches for it ("nobody gets stuck", criterion 2).
9. **The car's sound: rain and a cooling engine only,** or also the turn signal still ticking, which the player can tap off? The blinker would be the dark stretch's "one beat of human awkwardness" (narrative-design.md) and the one thing Leo can still fix. *Recommended: rain and the engine only*, as FR6 says ("no words, just the sound of rain"); the awkward beat comes a minute later with the lasagna note in the fridge. If you like the blinker, it is cheap to add.
10. **When is the loss?** The floor plan says the run is "the night after the test"; FR17 says the Loss is month 2, and the sesame-seed note says week 5. *Recommended: month 2, some weeks after the test* (FR17 is the newer, more specific line, and the journal page is dated month 2). If you agree, the floor plan line changes to "a night some weeks after the test" and decision-history records it.

11. **Swipes or no swipes?** Temple Run steers, jumps and slides with swipes. *Recommended: no swipes; the path bends on its own and tap anywhere is the only action.* Swipes would break the one tap scheme (a CLAUDE.md rule, so changing it is a bigger decision), add a way to fail that isn't about protecting the light, and fight Safari on the iPhone (an edge swipe goes back a page; a swipe can bring the hidden toolbar back).

When these are answered: the answers go into this file, scope.md's open question moves to "Settled questions", the ledger rows become `decided`, and DAS-97 can start.
