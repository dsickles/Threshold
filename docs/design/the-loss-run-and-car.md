# The Protector (the Loss): the run and the car

**Status:** Decided for M1 (Dan, 2026-10-25: every call answered; see "Dan's calls" at the end). First drafted 2026-10-22 (DAS-94, made with the [narrative-craft skill](../../.claude/skills/narrative-craft/SKILL.md)); updated 2026-10-25 for a 3D run seen from behind, like Temple Run, the storm that drowns the song, and Dan's answers; **revised 2026-10-25 after Dan's first play** of the rough build (calls 13 to 16): three lanes the father's hand moves the light between, a path through trees at the end of the day, the storm that never stops, and the light that starts as small as a sesame seed and goes out in his hand. Answers the question in [scope.md](../scope.md) "Settled questions": "What the Loss and the Silence show, the run's tap action, its obstacles, the fade and the car" (needed by M1). The code tickets (DAS-97 the run, DAS-98 the car and the House in grief) build from it; change this file first, then the code.

Built from: [roadmap.md](../roadmap.md) M1 ("a hand-built runner path (3–4 minutes) ending in the fade, no warning, skip or retry"; "the Silence: the car, rain, no words"; success criterion 4), [gdd.md](gdd.md) §2 The Protector, [requirements.md](requirements.md) FR6, FR19, FR20, UX-DR26 and UX-DR28, [epic-2-stories.md](stories/epic-2-stories.md) Stories 2.1–2.4, [EXPERIENCE.md](ux/EXPERIENCE.md) (the Loss rows and the Jordan flow), [game-architecture.md](game-architecture.md) §4.2, [house-floor-plan.md](house-floor-plan.md) (the bedside lamp starts it; home through the front door), the [continuity ledger](continuity-ledger.md) and the Partner as built (DAS-73).

What the docs already fix: no warning, no skip, no retry, no title card; it starts from an ordinary tap on the bedside lamp; the run starts sunny and clear while the couple is planning and dreaming, and the UI doesn't label that; a fixed, hand-built obstacle sequence on a flat tiled path, not random; the pacing runs euphoria, confusion, panic, silence; a stumble never ends the run; the runner (the baby) fades even after perfect play; no "Chapter failed. Try again?"; no hit-shake with reduced motion; no care UI; then the car, rain and no words; then the House in grief, coming in through the front door. Leaving mid-chapter starts it again from the beginning, and nothing saves until the car is over.

Lines marked **Choice** are Claude's picks where the docs say nothing; Dan approved the design with them on 2026-10-25, and the numbers (reach windows, timings) are to tune in playtests. Dan's answers are listed at the end. **No story words are written here**: the run and the car have none, and nothing below is on-screen text.

## The feeling

**Helplessness after competence: doing everything right, and it still goes.** Just before: the warm House after the Partner, the test on the counter, the sesame-seed note on the fridge. Just after: rain, a parked car, nobody speaking, then the gray House. The run has to make the player feel capable and needed first, so that being unable to help lands as loss, not as losing.

## The recommendation: "Clear the way"

**Central image:** a small light running away from the camera down a path, and the father's hand guiding it out of harm's way: moving it from lane to lane around what's coming, and laying itself across the gaps so it can cross. The light is the same kind of light as the Partner's, now small and new: it starts as small as the sesame seed on the fridge note and grows as it runs. Leo is a fixer (narrative-design.md), and here the player's hands, seen as his hand, do exactly what a fixer does: see the problem coming and move it. It works, beautifully, for most of the run. Then the light slows on a stretch of path where there is nothing left to fix, settles into his open hand, and goes out there.

**Dan, 2026-10-25, after his first play:** tap anywhere was too easy and too like the Partner; the light has to be visibly protected by a force outside it, the father doing his best, not obstacles vanishing on their own; and the light should read as the baby without being one. That is what the lanes, the hand and the sesame seed are for (calls 13 and 16).

Why this one (principle 1, the verb carries the feeling): the GDD and the game brief call the chapter "Pathfinder" and "clearing the path for the family", and the Protector archetype is protecting. Making the player the protector, not the runner, means the loss happens *to someone they were looking after*, which is the true shape of this grief for a father. And because the light fades where there is no obstacle at all, the fade can't be read as the player's mistake, which is what success criterion 4 needs.

### What the screen shows

**Dan, 2026-10-25: 3D, seen from behind, like Temple Run.** The camera follows just behind and a little above the light, and the path runs away into the distance. Held sideways (1280×720, scope.md). The House is already 3D, so this uses the same renderer, ordinary fog and lamp-style lighting, with no CompositorEffects.

All simple shapes, no final art (M1):

- **The setting (Dan, 2026-10-25, call 14): a path through tall trees at the end of the day.** The trail runs down an avenue of tall, dark trunks close on either side, like walls, under a canopy, with the low sun ahead between them: long dark trunk shadows across the path and gold between them, so the picture has real contrast. The trunks also give the eye something to judge speed by. It is the same evening that becomes the night of the Loss: the sun goes, the storm comes. An avenue of trunks rather than thick forest, so the lanes stay easy to read on a phone.
- **The path:** a trail of plain square tiles, three tiles wide (three lanes), raised a little above the dark forest floor, running into the distance; under it and in its gaps is darkness. **Choice:** like Temple Run, it bends left and right and rises and dips on its own; the camera swings round each bend with the light. The bends are scenery, not choices: the player chooses the lane, never the turn. Ordinary distance fog hides where the path is being built ahead.
- **The light (the runner):** a soft glowing ball in the lower middle of the screen, bobbing as it runs, in one of the three lanes (it starts in the middle). Same warm amber as the Partner's heart. **It starts as small as a sesame seed** and grows through the euphoria, the way the couple counted the weeks on the fridge note; nothing says so (call 16). It lights the tiles around it, so it is also the scene's main lamp, and by the end it is the last warm colour in the world.
- **The father's hand (call 13):** a large, soft hand, seen from behind like the camera, that comes in from the bottom edge of the screen to act and then draws back. It nudges the light across into another lane, lies flat across a gap so the light can run over it, and at the end holds the light in its open palm. Only the hand is ever seen, never the father. In the gray box it is plain rounded shapes in a warm skin tone.
- **Obstacles** come down the path toward the light, three kinds, all plain shapes:
  - **Stone:** a rounded block filling one lane. The light has to be in another lane when it arrives.
  - **Branch:** a fallen branch across two lanes. The light has to be in the lane it leaves free.
  - **Gap:** missing tiles across all three lanes. The light can't go round it: the hand has to lie across it.
- **The sky:** plain colours (the sky, fog the same colour) that change with each part of the run (below), from low gold to storm dark.
- **No silhouettes** (Dan, 2026-10-25: they might be too much and not sit well in the 3D run). The "planning and dreaming" of Story 2.2 is carried by the warm morning, the couple's song and the light growing, with nothing labelled.
- **Not a car:** the runner is the light, never a vehicle, so the run can't read as a car accident (Dan's note, 2026-10-25, [story-beats.md](story-beats.md)).
- **No HUD:** no score, no distance counter, no meter, no pause button on screen (the tab-hidden pause still works).

### The one tap action

**Tap the left or right half of the screen, and the father's hand moves the light one lane that way** (Dan, 2026-10-25, calls 13 and 17). From the left lane, a tap on the right moves it to the middle; two taps move it two lanes. A tap toward the edge from an edge lane leaves it where it is. Each half of the screen is a target, far over 44 px, and nothing depends on hover. Click is tap. The hand comes in, nudges the light across (about a quarter of a second) and draws back, with a small, soft sound.

**Changed (Dan, 2026-10-25, after his second play, call 17):** the first version made each third of the screen a lane; tapping "the lane" didn't match the feel of "move it left" or "move it right", and taps sometimes didn't do what he expected.

- **Gaps:** when a gap is in reach, the tap also lays the hand flat across it, and the light runs over the hand. Every tap with a gap in reach bridges it, on either side of the screen, and the light moves a lane as usual (or stays, at an edge). So it is still one action: tap the way you want the light to go; if there's a gap, the hand covers it.
- **Reach:** a gap is in reach from about 1.3 s before it would touch the light in the euphoria, 1.0 s in the confusion and 0.8 s in the panic, and lights up softly then (a warm outline, so it reads without colour alone). Stones and branches have no reach: they are seen coming far ahead, and all that matters is which lane the light is in when they arrive. **Choice**, to tune in playtests. Even the shortest is generous: this is not a skill test.
- **Which lane counts:** the lane the taps have sent it to, from the moment of the tap, even while the hand is still moving the light. A tap just in time always counts; a second tap while it is still moving sends it on one more lane. **Choice:** generous on purpose.
- **A tap that changes nothing** (toward the edge from an edge lane, with no gap in reach) makes a small ripple where the finger landed, and nothing else. No penalty, no sound of failure. (The Partner's lesson: punishing extra taps is what makes people say a game "counted my tap wrong".)
- **Every tap does what it says.** A tap on a side always moves the light one lane that way, unless it is already at that edge; a tap with a gap in reach always bridges it. No obstacle ever needs two taps, and no tap is ever silently ignored. Honest input is the first protection against "unfair".
- **No swipes** (call 11, kept). Temple Run changes lanes with swipes. Here the lanes are changed by tapping a side, so the one tap scheme (CLAUDE.md) holds, and it avoids a real problem on Dan's phone: in Safari a swipe in from the edge goes back a page, and a swipe can bring the hidden toolbar back.
- **Not tap anywhere** (call 2, changed): Dan found it too easy and too like the Partner, and nothing on screen did the clearing.

**What a stumble does.** If a stone or branch reaches the light in its lane, or a gap reaches it unbridged, the light goes through it: the stone cracks apart, the branch snaps, the light hops over the gap with a lurch. A dull, soft thud (not a buzzer). The light flickers dimmer for about 0.6 s and recovers fully. It never slows, never stops, never falls, never changes lane, and never loses ground. There is no count of stumbles and nothing carries over: by the time the next obstacle arrives, the light is exactly as it was. No screen shake, ever, not only with reduced motion (UX-DR26, "Loss does not add juice").

### The run, part by part

The whole run is one fixed timeline, the same length for every player: about 3 minutes 25 seconds from the lamp click to black (shortened 10 s by call 18). Nothing the player does moves it earlier or later. **Choice:** times below are from the lamp click.

| Time | Part | Sky and world | Music | Obstacles |
|---|---|---|---|---|
| 0:00–0:05 | Dark | Black. The lamp has just clicked off. A breath of quiet. | None | None |
| 0:05–1:25 | **Euphoria** | The light fades up out of the black, as small as a sesame seed, on the trail through the trees at the end of the day: low gold sun between dark trunks, long shadows across the path, long gentle bends. Fireflies drift between the trunks (call 18). The light grows over this part. | The song, bright (see "Music and sound") | 12, one every 2 bars, landing on the beat: one stone, one branch or one gap at a time. Easy. |
| 1:25–2:15 | **Confusion** | The sun goes behind cloud, the gold drains, the fog closes in and the trees seem closer. Wind: the trees start to sway. The bends come sharper and less evenly. Tiles at the path's edges crack and drop away behind the light (never in its way). Light rain from about 1:50. | The song plays on, but wind and the first rain start to rise over it | 12, off the beat and at uneven gaps, so they stop feeling like a dance; more of them block two lanes |
| 2:15–2:45 | **Panic** | Near dark and stormy. Heavy rain you can see, the trees black and bending in the wind, leaves blowing across the path. The fog is close, so the path ahead appears late. Each row of tiles cracks and falls away just after the light crosses it, so the path seems to give way under it, but it always lands. No lightning flashes (no flash, ever); the thunder is heard. | The storm takes over: rain, wind and thunder drown the song until it is gone under the rain by 2:45 | 17, in tight clusters of two or three, with a lane change inside some clusters and a gap in most |
| 2:45–3:25 | **The light goes out** | The obstacles stop and the path stops falling: whole, straight and empty. It is still night and still raining, as dark as the panic or darker; nothing gets lighter (call 15). The wind eases, the rain does not. The fireflies left along the trail go out one by one, at random; some never do (call 18). | The storm, without the song: rain and wind, thunder far off | None |

**The obstacle sequence.** Hand-built and fixed (FR20). Times are when each one would reach the light; S stone, B branch, G gap, with the lanes each stone or branch fills (L left, M middle, R right). Two stones at the same time are written "S L+R". The light starts in the middle lane.

- **Euphoria (12):** 0:13 S M, 0:18 S L+R, 0:24 B LM, 0:29 S R, 0:34 G, 0:40 B MR, 0:45 S L, 0:50 G, 0:56 B LM, 1:01 S M, 1:06 G, 1:12 S L+R. The first is a lone stone straight ahead, so a cold tester learns that a tap moves the light before anything else appears; the second sends them back to the middle, whichever side they went. 1:12 to 1:25 is clear: the brightest, happiest stretch, with nothing to do but watch.
- **Confusion (12):** 1:29 S L+M, 1:33 G, 1:39 B MR, 1:42 S L, 1:48 S R, 1:50 B LM, 1:56 G, 1:59 S M+R, 2:02 B LM, 2:06 G, 2:09 S L+R, 2:13 G.
- **Panic (17, clusters 0.6 s apart):** 2:17 S L, S R; 2:20 B LM, S M, G; 2:25 G, S R; 2:28 S M, B MR, S M; 2:32 B LM, G; 2:36 S R, S M, G; 2:39 G, B MR (the last at 2:40). ~~2:43 S L, G, S M; 2:47 B MR, S M; 2:51 G, B LM, S M~~ (cut by call 18). Inside each cluster one lane stays free all the way through, so a cluster never needs two lane changes 0.6 s apart; the free lane moves between clusters.

**Every obstacle can be cleared.** A player who taps well avoids all 41 and never stumbles: every stone and branch leaves a free lane, there are at least 2 s between obstacles that need different lanes outside a cluster, and every gap has its reach window. That is on purpose: FR19 and the GDD say the runner fades "despite the player's perfect play", so perfect play has to be possible. What the player can't stop is the path giving way behind and under the light, which has nothing to tap. **Dan:** the GDD also says "obstacles become unavoidable"; see call 3.

**Why no randomness at all:** with a fixed list, Dan can tune each obstacle by hand, every tester plays the same run, and the playtest compares like with like.

### How the fade lands

In one line: **the song is gone under the storm, the light runs on down an empty path in the rain while the fireflies along it go out at random, slows, settles into the father's open hand, and goes out there. Then the screen goes black and the car begins, in the same rain.** The run doesn't just stop, and there is no blank ending: the car follows it within seconds.

Second by second (the same for a perfect run and a stumbling one, because nothing in it depends on play):

1. **2:45, the song is gone.** The last of it has sunk under the rain; there is no dead stop and no moment of silence that could read as the game breaking (call 15). The obstacles have stopped and the path stops falling: it lies whole, straight and empty ahead, in the rain. The light is fully grown and fully bright, exactly as bright for every player, because stumbles never carry over.
2. **2:45–2:55, it keeps running.** Ten seconds on the empty path in the rain. Nothing comes. About a dozen fireflies glow low along the trail, ahead and to the sides, and from 2:47 they start to go out: one, then a few seconds later one far off, then two close together. No rhythm, no order, nothing near them when they go, the ones under the trees as often as the ones in the rain, so nothing reads as the cause (call 18). The order looks random but is fixed, the same for every player. A tap still moves the light to that lane, because every tap does what it says, but there is nothing left to move it away from.
3. **2:55–3:05, it slows to a stop.** The camera slows with it and comes to rest just behind it. As it slows it drifts back to the middle lane, and the father's hand comes in under it, palm up, on its own; the light settles into the open hand as it stops. From here a tap makes only a small ripple: the hand is already there. **Choice** (call 4, changed).
4. **3:05–3:15, it goes out in his hand.** The light dims and shrinks to nothing in the palm, while one or two fireflies still glow beside the path: it could have been any of them, and some outlast it (call 18). The tiles and the hand it was lighting go dark with it; it was the last warm colour, so the world is left gray. No sound when it goes out beyond the rain, no flash, no sting, no thunder.
5. **3:15–3:25, the empty hand.** The open hand, still, empty, rain falling on it and on the path. Then black, with the rain still falling.
6. **3:25, the car.** The rain carries on over black, and moves inside: the same storm, heard now from inside a car, and the car begins (below). It is the storm from the run: it was real.

No text, no "the end", no score, no button. The obstacles stop *before* the fade on purpose: the light doesn't go out because something hit it. It goes out in the hand that protected it all run: he did everything, and he is holding it when it goes. Nobody can point at a moment and say "if I'd tapped that, it would have lived". That is the truest thing the run can say to people who have been through this, and the main protection against "unfair".

### Music and sound

**The song is not replaced: the storm drowns it** (Dan, 2026-10-25: the sounds of the storm overtake the song, and the couple sits in the car in the same storm, with the same sounds). The Partner as built uses "Dreamy Lo-Fi Beat" (NewEraMusic via Pixabay, Pixabay Content Licence, already cleared for edited use in the game, [CREDITS.md](../../game/assets/audio/partner/CREDITS.md)). The Loss picks up the couple's song where the Partner left it, so the joy is the same joy (principle 5), and nothing is ever swapped in for it: the weather simply takes it away.

1. **0:05–1:25, the song**, bright.
2. **1:25–2:15, the storm comes in.** Wind and the first rain rise under and then over the song as the sky goes hazy. The song keeps playing, getting further away.
3. **2:15–2:45, the storm takes over.** Heavy rain, wind and thunder. The song is drowned, scraps of it coming through, until by 2:45 it is gone under the rain.
4. **2:45–3:25, the storm goes on without the song.** Rain and wind, the thunder far off and none while the light goes out. The rain never stops (call 15).
5. **3:25, the same storm, from inside the car.** The same recordings carry on over black and become muffled, as if on a car roof and windows. The player knows that sound: the run and the car are the same night.

**Changed (Dan, 2026-10-25, after his first play): the storm never stops.** The first build cut everything dead at 2:55. On the laptop the silence after it read as a mistake, and the lighter gray and the rain stopping read as the storm ending and the colour coming back. Now the song drowns instead of stopping, the rain carries on through the light going out and into the car, and nothing gets lighter. The roadmap's "silence" is the car (the Silence), and the absence of the song.

**Why this is better than a new track:** one sound runs from the run into the car and on into the House, where the rain is on the windows (the ledger's rain row), so the weather carries the loss home. It needs no second track to find, license or tempo-check. **Dan, 2026-10-25:** the storm in the car is still fairly loud, heavy rain on the roof with thunder in the background. Still no words (FR6).

**Recordings, not generated noise.** The first build's storm was noise made by the script as a stand-in, with tiny rain particles and nothing moving in the wind; on Dan's laptop it didn't read as a storm at all (2026-10-25). The storm must be real recordings (see the table), with rain you can see and trees bending in the wind on screen.

All of it is made **ahead of time** by a script, the way `tools/partner/make_song.py` makes the Partner's track, and played as ordinary recorded audio. Nothing is generated or bent live: the browser's default audio mode drops on-the-fly effects (game-architecture §3.2).

| Part | Sound | Source |
|---|---|---|
| Dark | The lamp click (the House's sound for the lamp), then nothing | House |
| Euphoria | The song's bright version, as at the Partner's best | Partner's song, edited |
| Confusion | The song, with wind and rain rising over it | Partner's song; storm recordings: free licensed sound effects (Pixabay or CC0), listed in CREDITS.md, or AI-made (ADR-0005) |
| Panic | The storm, loud: heavy rain, wind, thunder, scraps of the song under it until it is gone | The same storm recordings and song, mixed offline |
| The hand / stumble | A soft, warm sound when the hand moves the light or covers a gap; a dull thud for a stumble | Same |
| The light goes out | The storm without the song: rain and wind, thunder far off, none as the light goes out. Not the House hum, not a tone. | The same storm recordings |
| Car | The same storm, heard from inside: loud rain on the roof, thunder in the background; the engine ticking as it cools, fading out in the first 20 seconds | The run's storm recordings, muffled; one engine-tick recording. The House's rain after the Loss uses the same recordings. |

**Timing:** obstacles in the euphoria land on the song's beat (the song is 90 beats a minute, so one obstacle every 2 bars is every 5.3 s). The confusion and panic obstacles are off the beat on purpose, as the storm takes the beat away. The reach windows are wide, so the run needs none of the Partner's precise tap timing or calibration (ADR-0006); Godot's own audio clock is enough to keep obstacles on the beat. **Hiding the tab** pauses the music and the run together and saves nothing.

### The look, inside the rules

- **The gray drain** (Story 2.1, "a gray drain the chapter can fill in"): the sky, fog, light and tile colours are authored per part and drain from the low gold of the euphoria toward storm-dark grays across the confusion and panic. **It never gets lighter** (call 15): from the panic to the black every colour is as dark as the panic's or darker, and the last warm colour is the light itself, so when it goes out the world is gray. No CompositorEffects and no volumetric fog; colours, ordinary fog, one sun with ordinary shadows (the trunk shadows) and the light do it in the browser.
- **Rain** from about 1:50 to the black is simple particles (CPU particles, which the web renderer handles well), heavy enough in the panic to see as rain, cheap on a phone. **Wind** is the trees swaying and bending and leaves blowing, more in each part.
- **On the phone:** a few hundred plain tiles, plain trunks and canopies, three obstacle shapes, the hand, one moving light, one sun shadow and fog. Old tiles and trees are removed behind the camera, so the scene stays small. It must meet the same iPhone headroom bar as the House (scope.md), checked on Dan's phone. Obstacles share their shapes, and in the first 3 s, still behind the black, one of everything is drawn once (each shape, the hand, the lit sun and lamp, the rain and the song), so the first stone, gap, rain and song don't stutter (Dan saw blips, 2026-10-25). Review builds show the playtest overlay so Dan can give timestamps (CLAUDE.md, "Rough chapters").
- **No flash, no shake, no confetti, no slow-motion**, in any setting.

## The car (the Silence)

**Central image:** the House's front door, seen through rain on a windshield. The first tap of the whole game crossed that door at dusk on moving day (view P, the porch). Now the player sees it again, at night, from the car, and doesn't want to go in yet (principle 2, change the familiar).

**Choice: the car is parked outside the House**, engine off, later the same night as the run. Where they drove back from is never shown, so nothing in the game or these docs names it (Dan, 2026-10-25). This joins the floor plan's facts: the player comes in through the front door and finds the keys dropped on the entry floor.

**What is seen.** The same kind of fixed views as the House, in simple shapes, at night:

| View | Shows |
|---|---|
| **C1 Windshield** (the car opens here) | Rain running down the glass, wipers still. Through it, the House: the porch light on, the front door. |
| **C2 Maya** | The passenger seat. Maya as a simple dark shape, turned toward her window, rain on the glass beside her. Nothing to tap. |
| **C3 The wheel** | Leo's hands on the wheel, the keys still in the ignition. The keys are not tappable (they are kept for the Arrival). |

**What can be tapped.** Only the views: tap a view's ring to glide to it (2.0 s, as in the House), short-drag to look a little. No words, no subtitles, no objective text, no HUD, no skip (Story 2.3). Nothing to do with Maya: Leo can only be there. **Choice:** holding her hand is the Arrival's ending (the Partner's rhythm returns as holding the hand), so it is not spent here.

**How long.** At least 30 seconds from when the car fades in (Dan, 2026-10-25). **Choice:** the run's rain carries on over black for 3 s first and moves inside, muffled on the roof, before anything is seen (call 15).

**How it ends (Dan, 2026-10-25).** After 30 s the front door, seen from C1, quietly gets the same ring every House doorway has. Nothing else changes. When the player taps it, the car door opens (the rain gets louder for a moment), the screen goes to black over 2 s, and the chapter reports that it finished. The player chooses when to go in, and can sit as long as they like; there is still nothing to skip, because the time in the car always happens.

**Handing back to the House.** The chapter only reports `finished` (no Stoic/Vulnerable answer here). The core table turns that into the House in grief; the House opens at the entry (E1), gray, with rain on the windows and the keys dropped on the floor, as the floor plan says. **For the code tickets:** the House must have its gray mood and the E1 view set *before* it is shown, so the player never glimpses the warm bedroom where they left it. That is the core table's and the House's job (DAS-92, DAS-98), not the chapter's. M1 ends there, in the gray House, with no card.

## Leaving, pausing, saving

- **Hiding the tab** pauses the run (or the car) and saves nothing.
- **Closing the tab or reloading** anywhere in the run or the car starts the Loss again from the lamp click next time, with no warning screen (D6, EXPERIENCE.md "Jordan"). The save is written only after the car, when the chapter finishes.
- Nothing ever asks "are you sure?", offers a retry, or shows a skip.

## Alternatives considered

**A2. The same run, in 2D seen from the side.** This was the first draft's view: the path scrolls right to left and the light stays a third of the way in. Cheaper to build, and easy to read on a phone. Dan chose 3D (2026-10-25): the view from behind puts the player with the light, looking where it's going, which makes the path ahead and its giving way much more felt. Better at: cost.

**B. "Run with her": the player is the runner, tap to jump.** The classic one-button runner (the light, or the couple, jumps over obstacles). Simplest to understand. But the player *is* the thing that fades, which turns the fade into "I died", the language of failing a level. To make obstacles "unavoidable", jumps would have to fail even when timed well, which is exactly what testers call unfair. Better at: instant familiarity.

**C. "Lay the path": tap in rhythm to lay each stone ahead of the light.** The truest "pathfinder": the path is dark ahead and the player builds it stone by stone on the beat; later the stones crack as they're laid. Strong image of providing. But it is the Partner's verb again (tap in time), which blunts the contrast between chapters, and it brings back the rhythm-timing risk ("counted my tap wrong") in the one chapter that must never feel unfair. Better at: a direct line to Leo's "provide" flaw.

**D. A 3D lane runner, with steering.** The view Dan chose, but with Temple Run's controls: tap left or right (or swipe) to change lanes or turn at corners. More like the game it comes from. But steering adds a second action and a way to fail that has nothing to do with protecting the light, a tap-side rule is easy to get wrong held sideways, and swipes fight Safari on the phone. Better at: being a familiar game. **Chosen in part (Dan, 2026-10-25, after his first play):** lanes by tapping a third of the screen, no turns and no swipes, and the lane change is the father's hand protecting the light, not the light steering itself (call 13).

**E. Tap anywhere to clear the next obstacle** (the first build). One obvious action for a cold tester and what the Partner taught them minutes ago. Dan played it: too easy, too like the Partner, and the obstacles vanished with nothing visibly protecting the light. Better at: being impossible to get wrong.

What the recommendation gives up: A2's lower cost, B's and D's instant familiarity (mitigated by teaching on two lone stones) and C's direct "provider" image (the clearing verb carries "protector" instead, which is this chapter's archetype).

## Ledger changes

Added to the [continuity ledger](continuity-ledger.md); decided with Dan's answers on 2026-10-25 except where a row says an idea is for M2:

- **Fact: the night of the Loss.** A night in month 2 (FR17). The lamp goes off, the run is that night, and the car comes after it, outside the House in the rain.
- **Place: the car**, parked outside the House on the night of the loss (the Silence). Seen only then in M1. An idea for later: the same car is the one they leave in at the Arrival.
- **Object: the porch light.** On at dusk on moving day; on again through the rain from the car (left on when they rushed out).
- **Object: car keys** (changed): in the ignition in the car, seen but not tappable, before they are dropped on the entry floor.
- **Sound: the couple's song** (the Partner's song): the Partner; then the Loss's euphoria; drowned by the storm in the confusion and panic, gone under the rain by 2:45 (changed 2026-10-25: not stopped dead; 2:55 until call 18).
- **Sound: the storm** (new): rises in the run's confusion, takes over in the panic, never stops: on through the light going out, over black into the car, and its rain carries into the House (changed 2026-10-25: it no longer stops for the fade).
- **Sound: rain** (changed): part of the storm; starts in the run's confusion and never stops through the run, the car and into the House.
- **Motif: the small light.** The Partner's lights and heart; the runner in the Loss, which starts as small as the fridge note's sesame seed, grows, and goes out in the father's hand. Introduced, so it should be paid off later (an idea: a small light in the Tuner or the Arrival; M2 decides).
- **Motif: the father's hand** (new, 2026-10-25): in the Loss it guides the light, lies across the gaps and holds it as it goes out. Introduced, so it should be paid off later (an idea: the holding of hands in the Arrival; M2 decides).
- **Place: the trail through the trees** (new, 2026-10-25): the run's setting, at the end of the day turning to the storm. Seen only in the run.
- **Fireflies** (new, 2026-10-26, call 18): seen along the trail in the euphoria; fewer in the storm; when the path empties they go out one by one at random, some never; one or two still glow as the light goes out. Only in the run.
- **Motif: coming home through the front door.** The first tap of the game; home from the car after the Loss. Leaving through it with the keys is still the Arrival's.

## Checks this design must pass

From the roadmap, the stories, CLAUDE.md and the narrative-craft skill. None is optional, and the ones that need Dan's phone wait for Dan.

**Rules (CLAUDE.md):**

- **No warning, no skip, no retry.** Nothing before the lamp click points at the loss (the lamp is "going to sleep"). No title card. No skip control anywhere in the run or the car. No retry, "try again" or "chapter failed" at the fade or after.
- **One result.** Every player reaches the same fade, the same car and the same House. Stumbles change nothing that lasts. The chapter offers no Stoic/Vulnerable answer.
- **One tap scheme.** Tap the left or right half of the screen (the run) and tap a ring (the car). No swipes, WASD, stick, mouse-look or gamepad. Nothing on hover. Targets over 44 px.
- **No CompositorEffects, no volumetric fog.** Colours, ordinary fog, the light and particles only.
- **The UI never explains the metaphor.** No words on screen at all; nothing names the light, the parts of the run or what happened.
- **Saves only between chapters.** Hidden tab pauses; leaving restarts from the lamp.

**Tests the code tickets add** (headless, `game/tests/`, the repo's own runner):

- The obstacle list matches this doc: 41 obstacles, 12/12/17 by part, none after 2:42, none in the last part, every stone and branch leaves a lane free, and each panic cluster has one lane free all the way through.
- **The perfect run and the empty run reach the same ending:** play the run avoiding every obstacle, and again with no taps at all; both reach the fade at the same time, with the light at the same brightness at 2:45, and both finish the chapter once.
- A tap on the left or right half always moves the light one lane that way, unless it is already at that edge; a tap with a gap in reach always bridges exactly that gap; a tap that changes nothing (toward the edge from an edge lane, no gap in reach) changes nothing.
- A stumble never changes the light's speed, position along the path or lane, and the light is back to full within a second.
- The light starts small and grows through the euphoria; the hand holds it as it goes out.
- The rain is still falling at the black, and nothing gets lighter from the panic to the black.
- The fireflies go out in their fixed order, none before the path is empty, and some are still glowing when the light goes out.
- The chapter reports `finished` exactly once, only after the car, with no answer; leaving mid-run writes no save.
- Browser test (tests/web): the run opens from the lamp, has no console errors, and plays through to the car and back to the House.

**Needs Dan's device:** the run's feel on his iPhone (plain Safari, sideways, Hide Toolbar) and laptop Chrome; whether the lanes and the gap reach feel fair; whether the storm reads as a storm; whether the light going out in the hand lands; the car's length.

**Story 2.2's "10–15 minutes"** is the full chapter in M3+. M1's run is 3–4 minutes (roadmap), so this design is sized to that; M3 lengthens the euphoria and adds set pieces without changing the shape.

### What success criterion 4 needs, and how the playtest checks it

Criterion 4: "Asked afterwards, most testers describe the Loss in emotional words, not 'unfair.' Nobody looks for a retry out of frustration. Nobody calls it cheap or exploitative."

**What the design does for it:**

1. **The fade is not caused by play.** No obstacle in the last part; the light is equally bright for everyone; it goes out on a clear path, in the father's hand, while fireflies around it go out or don't, at random.
2. **Input is honest.** Every lane tap moves the light, every tap with a gap in reach bridges it; stray taps cost nothing; no obstacle needs two taps; perfect play is possible.
3. **No game-over language.** No score, counter, buzzer, shake, "game over" sound or screen, and no retry to look for.
4. **Joy first.** 80 seconds of easy, on-the-beat success to the couple's own song, so there is something to lose.
5. **Not cheap or exploitative.** Restraint: no graphic image, no blood, no hospital, no words telling the player how to feel. The loss is shown only as a light going out in a hand and a song drowning in the rain. The car gives the player time in the storm with someone else there, and no words.

**How the M1 playtest checks it** (written up in `docs/playtests/`, as the roadmap asks):

- **Watch, don't help.** Note if the tester, during or right after the fade, reloads the page, looks for a menu or back button, taps hard and repeatedly on the empty screen, or says "wait, what did I do?". Any of those after the fade is "looking for a retry".
- **Ask after the whole session, open first:** "How would you describe the second part (the running) to a friend?" Write their words down exactly. Then: "How did the ending of that part feel?" Only then, if they haven't said it: "Did anything feel like it was your fault?" Never ask "was it unfair?" (it plants the word).
- **Sort the words** into emotional (sad, gutted, quiet, helpless, heartbreaking, "I didn't expect that") and fairness or mechanics (unfair, broken, bug, rigged, cheap, "I couldn't do anything about the controls").
- **Passes if:** at least 3 of the 5 testers use emotional words, nobody uses "unfair", "cheap" or "exploitative" (or says so in other words), and nobody looks for a retry. **If it fails, fix the Loss before building anything else** (roadmap).
- **Care for testers:** the M1 playtest note should say whether any tester has been through a loss, if they choose to share it, and Dan should know some testers may have. That is for the playtest, not the game (the game gives no warning).

## Dan's calls

All answered, 2026-10-25 (call 18 on 2026-10-26). Calls 2, 4, 5 and 11 were revisited after Dan's first play of the rough build the same day (calls 13 to 16).

1. **The concept, "Clear the way":** **decided (Dan):** the light is the runner, and it disappears ("metaphorically interesting and heartbreaking"). **3D, seen from behind, like Temple Run**, built that way straight away (no 2D test first).
2. ~~**Tap anywhere** to clear the next obstacle in reach: **decided (Dan).**~~ **Changed by call 13.**
3. **Every obstacle can be cleared;** what can't be stopped is the path giving way and the light going out: **decided (Dan).** (The GDD's "obstacles become unavoidable" is read this way.)
4. **Taps during the silence** make a small ripple that never reaches the light: **decided (Dan).** **Changed with call 13:** lane taps still move the light until it slows (3:05; 2:55 since call 18); from then the hand holds it and a tap makes only the ripple (Choice).
5. **Music:** **decided (Dan):** the Partner's song, drowned by a storm; ~~everything stops at 2:55 and the light goes out in silence; the same storm comes back over black for the car.~~ **Changed by call 15.**
6. **Silhouettes:** **dropped (Dan):** they might be too much and not sit well in the 3D run.
7. **The car:** parked outside the House at night, Maya in the passenger seat turned to her window, three views (windshield, Maya, the wheel): **decided (Dan).**
8. **How the car ends:** the front door gets a ring **after 30 s** and the player taps it to go in: **decided (Dan).**
9. **The car's sound:** the storm and the cooling engine only, no blinker: **decided (Dan).** The storm is fairly loud, with thunder in the background.
10. **When is the loss:** month 2, some weeks after the test: **decided (Dan).** The floor plan line is fixed to match (decision-history 29).
11. **No swipes:** the path bends on its own and tapping is the only action: **decided (Dan).** Still true with the lanes (call 13): a lane is chosen by tapping, never swiping.
12. **The night of the Loss, not the drive to the first scan:** **decided (Dan, 2026-10-25).** The lamp goes off, the run is that night, and the car comes after it, later the same night. The scan is not used in the Loss. Moments are named only by what happens in the game (the lamp, the run, the car), never by places or events the player doesn't see (Dan, 2026-10-25, [project thread](https://claude.ai/code/project/chan_01Heqb6NDEptT8ADwVXQfsSV?thread=cmsg_01Heqb6NDEptT8ADwVXQfsSVMvnBrqVsaEwzQ4GogNduwV)). (Raised by Dan's story-pass note in [story-beats.md](story-beats.md); added after the merge, from Hopper's review.)
13. **The father's hand and three lanes** (after Dan's first play): ~~tap the left, middle or right third of the screen and the father's hand guides the light into that lane~~ (changed by call 17); with a gap in reach the tap also lays the hand across it; difficulty rises part by part; perfect play stays possible: **decided (Dan, 2026-10-25).** Replaces call 2. Dan's note: "it's too easy and too similar to the first level"; the light must be "visibly protected by a force outside the light... the dad doing his best to protect the light".
14. **The setting:** a path through tall trees at the end of the day, with real contrast (not tall grass, not the open, pale first build): **decided (Dan, 2026-10-25).**
15. **The ending's sound and light:** the song drowns under the storm instead of stopping; the rain never stops, through the light going out and into the car; nothing gets lighter after the panic: **decided (Dan, 2026-10-25).** Replaces the dead stop in call 5. Dan's notes: the silence "seems like it's a mistake"; "there was just no storm"; "at the end it would still be raining".
16. **The light as the baby, without saying so:** it starts as small as the fridge note's sesame seed and grows; at the end it settles into the father's open hand and goes out there; no heartbeat (the ledger keeps the baby's heartbeat for later): **decided (Dan, 2026-10-25).**
17. **Tap left or right to move one lane** (after Dan's second play): a tap on the left or right half of the screen moves the light one lane that way; two taps move it two lanes: **decided (Dan, 2026-10-25).** Replaces "tap a third of the screen for that lane" in call 13. Dan's note: "Tapping left or right should instead move the light to the left or right, not require user to tap to the lane correctly."
18. **Something visible puts the light out, and the storm is shorter** (after Dan's third play): fireflies drift along the trail from the euphoria; when the path empties they go out one by one at random, some never, and one or two still glow as the light goes out in the hand. The panic is cut from 40 s to 30 s (its last three clusters go, 49 obstacles become 41) and everything after it moves 10 s earlier, so black is at 3:25: **decided (Dan, 2026-10-26).** Dan's notes: "the storm part felt a little long"; "there needs to be something that happens for the light to go out... It seems a little random, which of course is the whole concept, but I want that be represented a little more explicitly in the last 45 seconds"; "we'll see if that's enough after it's delivered. i might want even another thing, including maybe a last obstacle that isn't clearable" (open; it would change call 3 and success criterion 4's "the fade is not caused by play"). Options weighed: [The Loss: what puts the light out](https://claude.ai/artifact/D23YGCY7cQzB1DCAca3ys3).
