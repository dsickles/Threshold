# The Partner: screen, song and beat chart (draft)

**Status:** Draft for Dan to edit, 2026-10-18. Gaps 1, 2 and 4 and part of 3 decided by Dan on 2026-10-19 (see "Gaps only Dan can fill"); the rest is not decided. Answers the open question in [scope.md](../scope.md): "What The Partner shows on screen, its song, and its beat chart" (needed by M1). Once Dan settles it, the answer moves to scope.md "Settled questions" and this file stops saying "draft".

Built from: [roadmap.md](../roadmap.md) M1 ("a short Partner (3–4 minutes): one song, one beat chart, missed taps as awkward laughter"), [gdd.md](gdd.md) §1 The Partner, [requirements.md](requirements.md) FR18, UX-DR18 and UX-DR29, [epic-1-stories.md](stories/epic-1-stories.md) Story 1.2, [game-architecture.md](game-architecture.md) §4.4, [ADR-0005](../adr/0005-ai-assets-text-dialogue-v1.md) (AI music, no voice acting), the M0 rhythm check (DAS-68) and [ADR-0006](../adr/0006-partner-browser-audio-clock.md) (the browser's audio clock).

What the docs fix: tap in time with Maya's heartbeat or voice ("Connection Nodes"); starts slow and intimate, builds to a joyous crescendo; a miss is awkward laughter and the song keeps going; Perfect, Good or Miss near the hit, in numeric type; no combo, no grade screen; one ending, a positive pregnancy test; the hits must line up with the sound heard on a phone.

Every line marked **Choice** is something I picked where the docs say nothing. Lines marked **Dan** are gaps only Dan can fill. The full list is at the end.

## The short version

An abstract, warm screen: a soft glow in the middle pulses with Maya's heartbeat, and small lights drift in from the edges to meet it on the beat. Tap anywhere when a light reaches the ring. One instrumental song at a fixed 120 beats per minute, 3 minutes 28 seconds. The heartbeat starts at a resting 60 a minute (every other beat) and the chart fills in until the end is twice as busy as the song's beat.

## What is on screen

**Choice: abstract, not the couple.** Three options were possible:

1. **Abstract light and heartbeat (recommended).** Cheapest to build, works on any phone, no character models or animation, and intimate without being literal about conception. It never explains the metaphor, which the UI must not do.
2. The couple shown in the bedroom. Needs two animated characters and is hard to keep tasteful and grounded with AI-generated art.
3. The couple dancing in the kitchen. Charming, but the same character cost, and it moves the scene away from conception.

The screen, in the abstract version:

- **Background:** dark and warm (`surface` #1C1916), nearly empty. No House chrome.
- **The heart:** a soft glow in the centre that swells on each heartbeat. A thin ring around it marks "now".
- **Connection Nodes:** small lights that appear at the screen edge and drift in to the ring, arriving exactly on their beat. Each one takes 1.5 seconds (3 beats) to travel. **Choice:** they come alternately from the left and right, so a busy passage reads as two sides meeting, not a stream from one place.
- **Tap anywhere** on the screen. **Choice:** one big tap target instead of lanes; the docs ask for "one obvious tap-in-time", and it is the easiest thing for a cold tester on a phone.
- **On a hit:** the light merges into the glow, which grows a little and warms. Perfect or Good appears beside the ring in IBM Plex Mono, in ink (UX-DR18), then fades.
- **On a miss:** the light dims and drifts through the ring. "Miss" appears the same way. Sometimes laughter plays (see below).
- **Progress without a meter:** the glow is small and amber (`accent`) at the start and has grown and warmed toward `house-hope` by the end. At the last note it fills the screen.
- **Orientation:** everything is centred, so it works held sideways or upright. **Dan:** the docs never decide the game's orientation (the M0 checks were held sideways). This screen doesn't force the answer.

## Judging taps

| Rule | Value | Why |
|---|---|---|
| Perfect | within ±50 ms of the note | **Choice**, to tune in playtests |
| Good | within ±110 ms | **Choice.** Generous on purpose: success criterion 3 is "nobody says the rhythm counted my tap wrong". It must stay under 125 ms (half the closest gap between notes, 250 ms) so one tap can never be counted for two notes. The M0 check used 100 ms as a placeholder. |
| Miss | the note passes the ring by more than 110 ms with no tap | |
| Stray tap (no note within ±110 ms) | Nothing happens. No Miss, no laughter. | **Choice.** Punishing extra taps is the usual cause of "it counted my tap wrong". |
| Which note a tap counts for | The nearest note that hasn't been hit, within the Good window | |
| Score | None shown. No combo, no grade screen, no end tally. | Story 1.2, UX-DR18 |

**Clock and sound delay:** decided since this draft was first written. On the web the Partner times taps with the browser's own audio clock ([ADR-0006](../adr/0006-partner-browser-audio-clock.md)), and the "tap along to calibrate" step is in v1 to set each device's remaining offset (scope.md, decision-history 14).

**Choice: the calibration happens inside the song's intro.** The first notes (bars 3–8) are a plain heartbeat at 60 a minute. The player taps along; those taps are judged and shown as normal but never laugh, and they set the player's sound delay before the real song starts. Tap-along calibration with no separate screen. **Dan:** or would you rather calibration be its own screen (it could then also serve the Arrival's rhythm reprise)?

## Missed taps as awkward laughter

- **Choice:** a pool of about six short laughs (half a second to a second), Leo's and Maya's, shy and fond, never mocking. Picked at random, never the same one twice in a row.
- **Choice:** at most one laugh every 2 bars (4 seconds). Other misses only dim. A laugh on every miss in the busy final section would turn awkward into annoying.
- No laugh in the intro (bars 1–8).
- **Dan:** laughter is a human voice sound. [ADR-0005](../adr/0005-ai-assets-text-dialogue-v1.md) rules out voice acting in v1. My reading is that wordless sounds (laughs, a breath) count as sound effects, not voice acting, and can be AI-generated. That is your call.

## The song

**Choice:** one instrumental track, no lyrics or singing. Lyrics would need writing (Dan's) and singing would be voice work.

| Property | Value |
|---|---|
| Tempo | **120 beats per minute, exactly, the whole way through.** No speed-ups or slow-downs; the build in energy comes from the chart and the arrangement, not the tempo. A fixed tempo makes the chart simple and the calibration trustworthy. |
| Time | 4/4 |
| Length | 104 bars = 3 minutes 28 seconds (inside the 3–4 minutes in the roadmap) |
| Mood | **Choice:** warm, intimate neo-soul: electric piano, round bass, brushed drums. **Dan:** the genre is yours. The GDD gives other chapters genres (synthwave for the Provider, piano for the Mourner) but none for the Partner. |
| The heartbeat | A soft "lub-dub" heartbeat is part of the mix, on beats 1 and 3 of each bar (60 a minute) for the first 32 bars. From bar 33 the kick drum takes over its role. |
| The ending | The last note (bar 100, beat 1) is the loudest moment. Bars 101–104 let one held chord ring out while the screen fills with light. |

### Sections

| Bars | Time | Section | What the music does | Taps per second |
|---|---|---|---|---|
| 1–8 | 0:00–0:16 | Intro: heartbeat alone | Heartbeat only, a pad underneath. Notes start at bar 3. | 0.75 |
| 9–32 | 0:16–1:04 | A: Close | Electric piano enters, very sparse. Quiet, slow, intimate. | 1.25 |
| 33–56 | 1:04–1:52 | B: Playful | Bass and brushed drums enter; a light, bouncy feel. One silent bar at bar 48 (see below). | 2.0 |
| 57–88 | 1:52–2:56 | C: Build | Strings or pads rise; more drums; the energy climbs. | 2.3 |
| 89–100 | 2:56–3:20 | D: Crescendo | Everything in, handclaps, the joyous peak. Ends on one big hit. | 3.0 |
| 101–104 | 3:20–3:28 | Outro | One held chord rings out. No notes. | 0 |

**Bar 48, a stumble:** **Choice:** the whole band stops for one bar, then comes back. A small, human, awkward pause halfway through, which the docs ask every chapter to have ("one beat of human awkwardness"). It has no notes, so it can't be "failed". **Dan:** what that pause *means* is story; keep it or cut it.

### Making the song

The music is AI-generated ([ADR-0005](../adr/0005-ai-assets-text-dialogue-v1.md)). AI music tools often drift off tempo, which would break a beat chart. So before a song is accepted:

1. Put it in an audio editor with a 120 BPM click and find the exact time of bar 1, beat 1 (this is the chart's **start offset**).
2. Check bar 100, beat 1 still lands within about 10 ms of where 120 BPM says it should (3:18.000 plus the offset). If it drifts, the track is rejected.
3. If no tool holds the tempo, the fallback is to build the track from fixed-tempo loops in a free audio editor. **Dan:** which tool you generate with, and checking its commercial terms (ADR-0005), are yours.

File format: Ogg Vorbis, which Godot plays well in the browser.

## The beat chart

The chart is written here in bars and beats so it can be read and edited. In the game it is stored as a JSON list of times in milliseconds ([game-architecture.md](game-architecture.md) §4.4). The conversion is plain arithmetic at 120 BPM (500 ms a beat):

`time_ms = start_offset_ms + ((bar - 1) * 4 + (beat - 1)) * 500`

where `beat` can be 1, 1.5, 2, 2.5 and so on ("1.5" means halfway between beats 1 and 2).

### Patterns (one bar each)

| Pattern | Beats with a note | Notes | Feel |
|---|---|---|---|
| H Heart | 1, 3 | 2 | Resting heartbeat, 60 a minute |
| L Lub-dub | 1, 1.5, 3, 3.5 | 4 | The heartbeat's double beat |
| Q Quarters | 1, 2, 3, 4 | 4 | Steady, every beat |
| S Skip | 1, 2, 2.5, 3, 4 | 5 | A little skip in the middle |
| R Run | 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5 | 8 | Every half beat; only near the end |
| X Last | 1 | 1 | The final hit |
| – Rest | none | 0 | |

### Bar by bar

| Bars | Patterns | Notes |
|---|---|---|
| 1–2 | – – | 0 |
| 3–8 | H H H H H H | 12 |
| 9–32 | (H H H L) six times | 60 |
| 33–56 | (Q Q Q S) six times, except bar 48 is – | 97 |
| 57–80 | (L Q L S) six times | 102 |
| 81–84 | S S S S | 20 |
| 85–88 | L L R R | 24 |
| 89–100 | R L R L R L R L R R R X | 73 |
| 101–104 | – – – – | 0 |
| **Total** | | **388** |

About 1.9 taps a second on average, from 0.75 at the start to 3 in the crescendo. **Choice:** the busiest bars (R, four taps a second) appear only in the last 30 seconds, where the docs want it "frantic". If cold testers struggle, the first thing to tune is turning some R bars into L bars.

## Ending

After the last note the glow fills the screen and the chord rings out. Then the screen settles on **a positive pregnancy test**, two lines, no words (Story 1.2: "the result is a positive pregnancy test, and that is the only ending"). Then back to the House, now warm ([house-floor-plan.md](house-floor-plan.md)).

**Dan, 2026-10-19:** the test moment should be exciting: a moment of recognition, reflection and celebration, lasting about 30 seconds to a minute. **Proposed:** the music swells and resolves around the test, and the screen holds on it for at least 30 seconds with nothing to tap; then a quiet ring appears and the player goes back to the House when they are ready, so the moment lasts between 30 seconds and however long they want. **Words (Dan, 2026-10-20):** Maya says "Honey…", Leo a jubilant "Yes!", then they both laugh. Still open: what the test is lying on (proposed: the bathroom counter).

## Checks this design must pass

These come from the roadmap and stories. None is optional, and the ones that need Dan's phone wait for Dan.

- **On Dan's iPhone 17 Pro (Safari) and laptop Chrome:** the hits line up with the sound actually heard (Story 1.2). Before M1 playtests, the same on a real mid-range Android spot check (roadmap success criterion 1).
- **M1 success criterion 3:** across the 5 cold testers, nobody says the rhythm "counted my tap wrong".
- **Every miss path finishes the song** and reaches the same ending: play with no taps at all, and with every tap early, and the test still appears and the House still warms.
- **The chart file matches this table:** 388 notes, none closer than 250 ms, the last at bar 100 beat 1. Checked by a test in `game/tests/` (the repo's own runner, no addon).
- **Song tempo check** (above) before the song is used.
- **Hiding the tab pauses the song and the chart together**, and they are still in step when the tab comes back (M1 "pause when the browser tab is hidden").
- **Tap target:** the whole screen, so well over 44 px. Nothing depends on hover.

## Gaps only Dan can fill

1. ~~Abstract light and heartbeat, or show the couple?~~ **Decided (Dan, 2026-10-19): abstract light and heartbeat.**
2. ~~The song's genre and mood.~~ **Decided (Dan, 2026-10-19): warm neo-soul, instrumental, 120 BPM.**
3. **Laughter:** wordless laughs count as sound effects under ADR-0005, not voice acting (**decided, Dan, 2026-10-19**). Whose: both of them (Dan, 2026-10-20).
4. ~~Calibration inside the intro, or its own screen?~~ **Decided (Dan, 2026-10-19): inside the intro.**
5. **The bar-48 stumble:** halfway through the song, the whole band stops for one bar (2 seconds, nothing to tap), then comes back in, like a couple fumbling and laughing. It is the chapter's "one beat of human awkwardness". **Decided (Dan, 2026-10-19): keep it,** as a plain fumble.
6. **The test moment:** length and feel decided (Dan, 2026-10-19; see "Ending"). Words decided (Dan, 2026-10-20): Maya says "Honey…", Leo a jubilant "Yes!", then they both laugh (subtitles; the laughs are sound effects). Still open: what the test is lying on (proposed: the bathroom counter, where it sits in the House afterwards).
7. **Orientation: decided (Dan, 2026-10-19): sideways** for the whole game (recorded in scope.md). Why: PC and Steam, and the browser on a laptop, are sideways, so one layout serves every platform; upright on phones would mean a second layout for every view and menu (Florence did this when it moved from phones to Switch and PC). The project is already set up for 1280×720 sideways, the type-scale ruling in scope.md (2026-10-18) assumes a sideways phone, and every M0 test was done sideways. Premium story games on phones (*What Remains of Edith Finch*, *Gris*) are mostly sideways; upright is where free casual games live. Cost: people hold phones upright in the browser, so the web build needs a "turn your phone sideways" screen.
8. **Which AI music tool.** Dan, 2026-10-19: it must be free and allow commercial use; **Stable Audio 3 is the pick to start with**, not locked. Checked 2026-10-19: Suno, Udio, ElevenLabs and AIVA free plans are personal use only, so they are out. Three that fit:
   - **Stable Audio 3 Medium** (Stability AI, open weights, May 2026). Free under the Stability Community License for anyone earning under $1M a year, and you own the output. Trained only on licensed music, which matters for Steam's AI disclosure. Good at instrumental tracks up to about 6 minutes. *Recommended.*
   - **ACE-Step 1.5** (MIT licence). Free, runs on an ordinary Windows PC with a modest graphics card, and has a free web demo. Makes full songs, including vocals. What it was trained on is less clear.
   - **YuE** (Apache 2.0). Free for commercial use if you credit "YuE by HKUST/M-A-P". Needs a very large graphics card (24 GB), so it would have to run on a rented machine.
   Re-check the licence text when the song is actually made, and keep a copy of it with the song.
