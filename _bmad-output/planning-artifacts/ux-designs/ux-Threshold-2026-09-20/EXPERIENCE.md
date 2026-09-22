---
title: 'EXPERIENCE.md — Threshold'
status: final
updated: 2026-09-22
form_factor: Web first, mobile second, PC/Steam third. One tap/click scheme.
sources:
  - '{planning_artifacts}/gdd.md'
  - '{planning_artifacts}/game-brief.md'
  - '{planning_artifacts}/narrative-design.md'
  - '{planning_artifacts}/game-architecture.md'
  - '{planning_artifacts}/decision-history.md'
  - '{planning_artifacts}/ux-designs/ux-Threshold-2026-09-20/.decision-log.md'
  - '{project-root}/docs/agent-reports/report-designer-samus.md'
  - '{project-root}/docs/agent-reports/report-narrative-sophia.md'
  - '{project-root}/docs/agent-reports/report-dev-gordon.md'
  - '{project-root}/docs/agent-reports/report-architect-glados.md'
  - '{project-root}/docs/adr/adr-001-engine-selection.md'
---

# EXPERIENCE.md — Threshold

Visual identity: `DESIGN.md`. Token references point at that file’s frontmatter, for example `{colors.ink}`. Spines win on conflict with mocks.

## Foundation

*Threshold* is a narrative anthology about becoming a father. People open it **in a browser** first, on a **phone** second, on **PC/Steam** third. Godot 4.x, **Control** nodes, shared Input / Audio / Settings. One movement and tap language everywhere — do not maintain a second stick-and-mouse-look stack.

The persistent world is **The New House**. The player is **Leo**. Maya is the partner. The House creaks, glows, and rots with Leo’s state. Minigames are isolated scenes loaded from object **Triggers**; the House unloads or pauses, then returns changed.

Form-factor is phone-width and tap-first even in a desktop browser (click = tap). Couch/gamepad is out of scope for this pass.

## Information Architecture

The House is the map. Menus are thin.

| Surface | Reached from | Purpose |
| --- | --- | --- |
| Title | Cold open | Play / Continue / Settings. Continue hidden if no checkpoint. |
| The New House | Play, or after a minigame | Quiet explore. Minimal overlay. Object Triggers. Dad's Journal. Story Sequences. |
| The Story Sequence | Volume in the House | First-person narrative beat (Edith Finch–style). Still tap to walk/look. |
| The Trigger | Tappable object | Starts the current chapter’s minigame. |
| The Partner (The Spark) | First Trigger | Rhythm / Connection Nodes. |
| The Protector (The Loss) | Trigger, no warning | Forced-loss runner. |
| The Novice (The Science) | After Loss, slow start | WarioWare micro-games; tonal ramp. |
| The Provider (The Cost) | Trigger | Paperwork desk, `stamp`, **Reflowed Reader View**. |
| The Tuner (The Connection) | Trigger | `knobs`, waveforms, clear signal. |
| The Anchor (The Growth) | Trigger | `balance`; Maya’s Voice then Stability Assist. |
| The Mourner (The Nesting) | Trigger | `drag-drop` unpack / let go. |
| The Ending | Late House | Tuner + Partner mechanics reprise. |
| Dad's Journal | Tappable Journal object | Entries; Stoic/Vulnerable changes tone only. |
| pause | One control from anywhere | Resume / Settings / Back to title. Replaces; never stacks. |
| Settings | Title or pause | Subtitles, reduced-motion, quality (QualityManager). |
| Reflowed Reader View | Tap a Provider document | `reader-view`. Large-type reflow. Replaces the page, not a zoom. |

Loop (verbatim from GDD): **Hub (The New House)** → **The Story Sequence** → **The Trigger** → **The Minigame** → **Resolution** (House transforms).

Story Gates: finishing a minigame is the Key to the next room/chapter. Named rooms are not specified; do not invent a floor plan here.

Nothing in the House should require a nested menu to “go play the game.” The object is the door.

Composition (spines win on conflict): [title](mockups/key-title.html) cold open, Continue hidden; [House](mockups/key-house.html) chrome diagram only — highlight and Pause over the 3D room; [pause](mockups/key-pause.html) replaces the view; [Provider](mockups/key-provider.html) desk plus Reflowed Reader View. Provider copy in that file is a behavior sample; chapter detail is a later breakout.

## Voice and Tone

Microcopy. Brand posture lives in DESIGN.md.

Natural, unfinished, couple shorthand. Do not explain the metaphor on-screen.

| Do | Don't |
| --- | --- |
| Subtitles of what was said. | “Low empathy warning.” |
| “You’ve got this.” (Maya, when assist kicks in) | “Difficulty increased.” / “Stability Assist ON.” |
| Perfect / Good / Miss (rhythm, short) | Combo multipliers, grade screens in the House |
| OPEN THE BOX! (Novice, as the micro-game *is* the shout) | The same shout style in the House |
| Journal that sounds like Leo | UI that tells the player “the insurance company is confusing” |
| Silence after Loss | “Chapter failed. Try again?” |
| “Did you pay the gas bill?” | “Are we going to be okay?” as on-screen objective |

Every dark stretch still has one beat of human awkwardness (narrative lock). UI does not underline it.

## Component Patterns

Behavioral. Visuals in DESIGN.md.Components.

| Component | Use | Rules |
| --- | --- | --- |
| button-primary | Title, pause | Tap confirms. Default focus on Play (cold) or Resume (pause), 2px `{colors.focus-ring}`. |
| button-quiet | Title, pause, Settings | Tap opens the secondary path. Continue is omitted when there is no checkpoint — not a disabled tease. |
| panel | pause, Settings | Single column, one level deep. Never stacks on another panel. |
| subtitle-bar | VO / dialogue | Shows while audio plays; then gone. On by default. |
| interact-highlight | House objects | Tap the highlighted object (Door, MinigameTrigger, Journal). Off when nothing is in range. |
| stamp | Provider | Tap Approve or Deny. Hold not required. Word mark is the cue, not hue. |
| reader-view | Provider, especially phone | Display name **Reflowed Reader View**. Tap document → reflowed `{typography.reader.fontSize}` text. Dismiss returns to desk. If a page cannot reflow: stay on the desk, short “can’t enlarge this page.” |
| meter | Provider top-start | Bank Account uses `{colors.meter-bank}`; drain / error uses `{colors.meter-stress}`. Number always visible. |
| journal | Dad's Journal object | Tap to open. Empty: blank dated page, no prompt. First entry appears after a chapter. Stoic/Vulnerable changes words only. |
| pause | Global | Replaces overlay. Auto-pause if the browser tab backgrounds (`save_checkpoint()`). |
| knobs | Tuner | Large dials; value is the waveform, not a tooltip. |
| rhythm-judgment | Partner | Tap in time with Connection Nodes. Perfect / Good / Miss near the hit. |
| novice-shout | Novice | Short prompt, one gesture, next. Early games are slow and quiet. |
| drag-drop | Mourner | Grab, move, drop. Invalid drop snaps back. |
| balance | Anchor | Left/right tap-hold of two large on-screen zones — not a virtual stick. Same two hold-zones on web and mobile. After three falls: Maya’s Voice, then invisible Stability Assist. |
| provider-desk | The Provider | Documents live on the desk. Tap opens `reader-view`. Stamps apply on the desk, not inside the reader. |

## State Patterns

| State | Surface | Treatment |
| --- | --- | --- |
| Cold open | Title | Quiet; House already faintly visible under scrim. Play is default focus. Continue is hidden if no checkpoint. |
| No save | Title | Continue omitted. Play starts a new wander in the House. |
| Menu focus | Title, pause, Settings | 2px `{colors.focus-ring}` on the focused Control. Default: Play (title) or Resume (pause). Keyboard Enter activates that Control. |
| First wander | The New House | Minutes of nothing required. No objective marker. Trigger is an object that can be noticed. |
| The Story Sequence | House | Optional look-at camera for a beat; HUD still empty except `subtitle-bar`. |
| In minigame | Chapter UI | Hub chrome gone. Chapter skin up. |
| Fail-forward | Most chapters | Progress continues; Stress may rise. No game-over wall. |
| The Loss | The Protector (The Loss) | Hopeful start → crumple → fade even on perfect play → silence. **No warning. No skip. No retry nag.** |
| After Loss | House + The Novice (The Science) | House reads grief (`{colors.house-grief}`). Novice begins desaturated and slow; color and chaos bleed in. |
| Partner miss | The Partner (The Spark) | Missed cue: awkward laughter, no fail screen. Song still ends. |
| Tuner static | The Tuner (The Connection) | Misaligned knobs stay noisy; aligned knobs clear the image. No “wrong” popup. |
| Invalid drop | The Mourner (The Nesting) | Ghost snaps back (`drag-drop`). |
| Due Date | The Provider (The Cost) | Number ticks to zero; story fail-forwards; the desk does not trap them. |
| Assist | The Anchor (The Growth) | After three falls, Maya’s Voice, then invisible Stability Assist. Never a labeled cheat badge. |
| Journal empty | Dad's Journal | Blank dated page. No “write something” prompt. |
| Journal first entry | Dad's Journal | Entry appears after the last completed chapter. |
| Journal tone | Dad's Journal | Stoic or Vulnerable changes the prose of that entry; no skin swap. |
| Mastery | Optional | Extra insight or a memento appears in the House — an object, not a trophy toast. |
| Tab hidden / phone interrupt | Any | `pause` + `save_checkpoint()`. Resume where they were. |
| Couldn’t save | pause, Title | Non-blocking line: “Couldn’t save.” Last checkpoint still loads. Play is not blocked. |
| Offline / reload | Any | Last checkpoint. Scene-load failure returns to Title with Play (and Continue if a checkpoint exists). |
| Low-end | Any | QualityManager may drop fog; outlines that aid clarity stay. |
| Ending | The Ending | Tuner-to-hear / Partner-to-hold reprise. Skills, not a cutscene-only baby. |

## Interaction Primitives

- **Tap** is the verb: walk, look, interact, stamp, hit a beat, start a micro-game.
- **Tap-to-move** (House, The Story Sequence): tap a point on the floor / navmesh to walk there. One system on phone and desktop. No virtual stick. Not a DESIGN component.
- **Tap-to-look** (House): tap a look target or drag a short look. Same Control path on web and mobile. Not a second scheme. Not a DESIGN component.
- **Drag** only where the genre is tactile (`knobs`, `drag-drop`, look-drag).
- **Hold** only for `balance` side-zones, not for “hold to confirm skip Loss” — Loss has no skip.
- Destructive menu actions (quit to title mid-chapter) use a second tap: “Leave this?”
- Browser back: Settings or `pause`, not a broken scene stack.
- No hover-only affordances. If it cannot be tapped, it is not the path.

## HUD & Diegetic UI

**House: diegetic first.** The room, the light, the objects, the Journal you pick up. Non-diegetic overlay is subtitles and, when needed, a tiny pause control. No health, no minimap, no quest log, no stick.

**Minigames: steal the source genre’s HUD**, then throw away anything that would fight the phone.

Information hierarchy:

1. What you are touching right now (document, knob, beat, load).
2. The one number that chapter cares about (Bank Account, Due Date) — top-start slot if present.
3. Everything else off.

During Loss, do not add care-UI. The care is the run going quiet. During Story Sequences, fade chapter HUD; keep subtitles.

## Input Schemes

**One scheme.** Pointer (finger or mouse). Click = tap.

- Move: tap world to walk.
- Look: tap/drag look. No mouse-look pointer-lock. No WASD as the House design (architecture’s `FirstPersonController` is a superseded default for this UX).
- Interact: tap highlighted object.
- A keyboard on a computer may activate the same focused Control (Enter) for menus only. It is not a second movement mode.
- Prompts: no Xbox/PlayStation glyphs. If a prompt exists, it is the word or the object.
- Remapping: not in this pass (hobby, one pointer scheme).

## Game Feel & Juice

Felt response is small and physical, not celebratory chrome.

- Tap accepted: object highlight or footfall, not a UI burst.
- Partner hit: short audio + Perfect/Good/Miss; missed cue can be awkward laughter (GDD).
- Provider `stamp`: ink thunk. Bank number ticks in `{typography.numeric.fontFamily}`.
- Tuner: static clears; the image is the reward.
- Anchor: weight and jitter; shiver can mask physics; assist is a voice, not fireworks.
- Mourner: soft place, household ASMR.
- Loss: juice dies. No confetti of failure. Rain, then the House.

Reduced-motion: no camera sway, no hit-shake, no color-bleed animation required — still allow the Novice saturation change as a cut or slow fade.

## Accessibility Floor

Behavioral. Contrast lives in DESIGN.md.

- Tap targets ≥ 44px.
- Subtitles on by default; size uses `{typography.subtitle.fontSize}`.
- **Reflowed Reader View**: `{typography.reader.fontSize}` reflowed text, high contrast; not pinch-zoom as the only path.
- Do not rely on hue alone for Bank vs Stress vs stamps.
- Reduced-motion toggle in Settings.
- Adaptive Difficulty and Stability Assist exist so the *story* can be finished; they are not advertised as accessibility product features, but they serve the same people.
- **No skip control for the Loss chapter** (developer lock). Care is content and pacing, not an exit dialog.
- Low-end: keep gameplay-clarity outlines (Glados/Samus).

This is a hobby floor with portfolio honesty — not a full AbleGamers checklist. No colorblind filter suite in v1.

## Inspiration & Anti-patterns

**Lifted (hub):** *What Remains of Edith Finch* (house as anthology frame, room to look); *Gone Home* (walk a home and notice); *Syberia* (adventure tap/click, not FPS twitch).

**Lifted (chapters):** *Papers, Please* (Provider desk, stamps, system-that-confuses); *WarioWare* (Novice, after a slow respectful start); *Oxenfree* radio (Tuner); *Death Stranding* cargo (Anchor); *Unpacking* (Mourner); *Florence* (small interactive story beats).

**Rejected:** virtual sticks; a second mouse-look scheme for “real PC”; warning/skip chrome on miscarriage; calendar/journal-as-the-hub; quest markers in the House; clumsy-dad comedy as the UI voice; explaining the metaphor in tooltips.

## Responsive & Platform

- **Phone (second, but the layout default):** one column, `{spacing.safe}` against notches, Reader View mandatory for long text, two-thumb reach for primary actions (bottom-end).
- **Desktop browser (first delivery):** same tap/click language. Larger window does not grow a PC HUD. House uses more of the view; menus stay ~480px.
- **PC/Steam (third):** same scheme. Keyboard is menus-only unless revisited later.
- QualityManager: low-end mobile may lose fog; do not lose the outline that tells you what you can tap.

## Key Flows

### Alex, first time, phone browser

Alex has never played this. They tap a link. Title. Play (Continue is hidden).

1. They are in the House. It is quiet and a bit empty. Almost no HUD.
2. A Volume fires **The Story Sequence**. `subtitle-bar` only. They still tap to walk and look.
3. They tap the floor. Leo walks. They tap to look. They are not taught a stick.
4. They notice something they can tap — The Trigger — because of `interact-highlight`, not a marker.
5. **Climax:** **The Partner (The Spark)** starts. Hub overlay gone. One obvious tap-in-time (`rhythm-judgment`).
6. They return. The House has changed a little. They can keep looking.

Failure: they never find the object — the House still does not spawn a quest marker. Light, sound, and the object’s presence do the work. If they leave the tab, they resume in the House, not at the title.

### Jordan, The Protector (The Loss), laptop

Jordan already knows the House. They tap a trigger like the others. There is no warning.

1. The runner feels hopeful. Sunny, clear.
2. The path starts to fail. Doing well does not save it.
3. The runner fades.
4. **Climax:** silence. Rain. No “try again?” fighting for the click. Back in the House, which now reads grief (`{colors.house-grief}`).
5. The next play (**The Novice (The Science)**) starts slow and gray, then gets chaotic as the long haul begins.

Failure: rage-quit. Auto-save already wrote the chapter complete / the story moved. Returning does not force a warning; they are in the changed House.

### Sam pays a bill on a phone (The Provider)

Locked extra UJ for **Reflowed Reader View** / **The Provider (The Cost)**.

1. Sam is at `provider-desk`. Documents are too small to live as a texture.
2. They tap a form. **Reflowed Reader View** (`{components.reader-view}`) reflows it at `{typography.reader.fontSize}`.
3. They dismiss, then `stamp` Approve or Deny on the desk.
4. The Bank Account `meter` in the top-start slot ticks (`{typography.numeric.fontFamily}`, `{colors.meter-bank}`).
5. **Climax:** one ugly invoice with a real Micro-Story. They were not told the system is confusing; they had to find the typo.

Failure: mis-stamp. Money drains (`{colors.meter-stress}`). Due Date may hit zero; story still fail-forwards. The desk does not trap them.

### Alex, The Anchor (The Growth), Stability Assist

1. Alex is carrying the load with `balance` hold-zones.
2. They fall. They fall again.
3. Third fall.
4. **Climax:** Maya’s Voice (“You’ve got this.”). Invisible Stability Assist. No badge, no difficulty toast.
5. They finish. Back in the House.

Failure: more falls before the third — same chapter, fail-forward, assist still arrives after three.

### Jordan, The Ending

1. Jordan is late in the House. A Trigger starts **The Ending**.
2. They use Tuner `knobs` to hear the cry.
3. They use Partner tap (`rhythm-judgment`) to hold the hand.
4. **Climax:** the baby is those skills, not a plastic cutscene model.
5. The House is the last room, not a credits menu.

Failure: a miss on the reprise still fail-forwards; there is no game-over at the arrival.
