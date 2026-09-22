---
name: Threshold
description: Quiet domestic chrome for The New House, with seven chapter skins that steal mood from their inspirations. Web and mobile first.
status: final
updated: 2026-09-22
sources:
  - '{planning_artifacts}/gdd.md'
  - '{planning_artifacts}/game-brief.md'
  - '{planning_artifacts}/narrative-design.md'
  - '{planning_artifacts}/game-architecture.md'
  - '{planning_artifacts}/decision-history.md'
  - '{planning_artifacts}/ux-designs/ux-Threshold_New-2026-09-20/.decision-log.md'
  - '{project-root}/docs/agent-reports/report-designer-samus.md'
  - '{project-root}/docs/agent-reports/report-narrative-sophia.md'
  - '{project-root}/docs/agent-reports/report-dev-gordon.md'
  - '{project-root}/docs/agent-reports/report-architect-glados.md'
  - '{project-root}/docs/adr/adr-001-engine-selection.md'
colors:
  surface: '#1C1916'
  surface-raised: '#2A2520'
  ink: '#F4EFE6'
  ink-muted: '#9A9084'
  accent: '#C4A574'
  border: '#3D3832'
  scrim: '#0C0B0A'
  subtitle-bg: '#1C1916CC'
  house-hope: '#E8D4A8'
  house-grief: '#5C534C'
  stamp-approve: '#2F6B4F'
  stamp-deny: '#8B3A32'
  meter-bank: '#C4A574'
  meter-stress: '#8B3A32'
  focus-ring: '#C4A574'
typography:
  display:
    fontFamily: 'Source Serif 4, Georgia, serif'
    fontSize: 32px
    fontWeight: 600
    lineHeight: 1.2
  body:
    fontFamily: 'Source Sans 3, Segoe UI, sans-serif'
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.45
  subtitle:
    fontFamily: 'Source Sans 3, Segoe UI, sans-serif'
    fontSize: 18px
    fontWeight: 500
    lineHeight: 1.4
  numeric:
    fontFamily: 'IBM Plex Mono, ui-monospace, monospace'
    fontSize: 16px
    fontWeight: 500
    lineHeight: 1.2
  reader:
    fontFamily: 'Source Sans 3, Segoe UI, sans-serif'
    fontSize: 20px
    fontWeight: 400
    lineHeight: 1.45
  micro-shout:
    fontFamily: 'Source Sans 3, Segoe UI, sans-serif'
    fontSize: 28px
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: 0.04em
rounded:
  sm: 4px
  md: 8px
  lg: 12px
  full: 9999px
  DEFAULT: 8px
spacing:
  '1': 4px
  '2': 8px
  '3': 12px
  '4': 16px
  '5': 24px
  '6': 32px
  '7': 48px
  gutter: 16px
  safe: 24px
components:
  button-primary:
    background: '{colors.accent}'
    color: '{colors.surface}'
    rounded: '{rounded.md}'
    min-height: 44px
  button-quiet:
    background: transparent
    color: '{colors.ink}'
    border: '1px solid {colors.border}'
    min-height: 44px
  panel:
    background: '{colors.surface-raised}'
    border: '1px solid {colors.border}'
    rounded: '{rounded.md}'
  subtitle-bar:
    background: '{colors.subtitle-bg}'
    color: '{colors.ink}'
    fontFamily: '{typography.subtitle.fontFamily}'
    fontSize: '{typography.subtitle.fontSize}'
  interact-highlight:
    color: '{colors.accent}'
  stamp:
    approve: '{colors.stamp-approve}'
    deny: '{colors.stamp-deny}'
    rounded: '{rounded.full}'
  reader-view:
    background: '{colors.ink}'
    color: '{colors.surface}'
    fontSize: '{typography.reader.fontSize}'
  meter:
    track: '{colors.border}'
    fill: '{colors.meter-bank}'
    fill-stress: '{colors.meter-stress}'
    numeric: '{typography.numeric.fontFamily}'
  journal:
    background: '{colors.surface-raised}'
    color: '{colors.ink}'
    fontFamily: '{typography.display.fontFamily}'
  pause:
    background: '{colors.scrim}'
    panel: '{components.panel}'
  knobs:
    min-size: 44px
    color: '{colors.accent}'
  rhythm-judgment:
    fontFamily: '{typography.numeric.fontFamily}'
    fontSize: '{typography.numeric.fontSize}'
    color: '{colors.ink}'
  novice-shout:
    fontFamily: '{typography.micro-shout.fontFamily}'
    fontSize: '{typography.micro-shout.fontSize}'
    color: '{colors.ink}'
  drag-drop:
    ghost: '{colors.accent}'
    invalid: '{colors.meter-stress}'
  balance:
    zone-min: 44px
    color: '{colors.border}'
  provider-desk:
    paper: '{colors.ink}'
    ink: '{colors.surface}'
---

# DESIGN.md — Threshold

## Brand & Style

The House is the picture; chrome recedes. Chapter UIs may look unlike each other. Recurring HUD *kinds* share stable regions; empty corners stay empty. Spines win on conflict with any later mock.

Threshold should feel like being left alone in someone else's house. The visual identity of **The New House** is grounded, domestic, and a little empty at first — Edith Finch / Gone Home / Syberia as mood, not as a copied HUD. Overlay UI in the House is almost absent so the player can look.

Each minigame is allowed to look like the genre it is stealing from (*Papers, Please* paperwork, WarioWare shouts, Oxenfree knobs, Death Stranding weight, Unpacking stillness). Those skins are chapter costumes. They take the stage; they do not redesign the House.

The House itself changes: cold and sparse, then furniture, warmer light, or longer shadows, depending on the story. Hope reads as glow. Grief reads as rot and quiet. UI does not explain that with icons. The room does.

Serious, not “clumsy dad.” Intimate, not arcade. Polish is real; chrome is not the product.

## Colors

Hub and shared menus use a lamp-lit interior palette so overlays sit on the 3D house without looking like a second game.

| Role | Token | Hex | Use |
| --- | --- | --- | --- |
| Surface | `surface` | `#1C1916` | Title, pause, settings scrim fill |
| Raised | `surface-raised` | `#2A2520` | Panels, journal page chrome |
| Ink | `ink` | `#F4EFE6` | Primary readable text |
| Muted | `ink-muted` | `#9A9084` | Secondary labels, idle hints |
| Accent | `accent` | `#C4A574` | Focus, interact highlight, primary tap |
| Border | `border` | `#3D3832` | Hairlines only |
| Scrim | `scrim` | `#0C0B0A` | Pause / title dim over the House |
| Hope | `house-hope` | `#E8D4A8` | Light bias when the House glows (`{colors.house-hope}`) |
| Grief | `house-grief` | `#5C534C` | Desaturation bias after Loss / early Novice |
| Approve | `stamp-approve` | `#2F6B4F` | `stamp` Approve mark |
| Deny | `stamp-deny` | `#8B3A32` | `stamp` Deny mark + Stress / drain |
| Bank | `meter-bank` | `#C4A574` | Bank Account meter fill (shape + number, not hue alone). Same hex as `accent` / `focus-ring` — three roles, one swatch. |
| Stress | `meter-stress` | `#8B3A32` | Drain fill (`{components.meter.fill-stress}`); always paired with a number or stamp |
| Focus | `focus-ring` | `#C4A574` | 2px ring on the focused Control (alias of `accent`) |
| Subtitle bg | `subtitle-bg` | `#1C1916CC` | Subtitle scrim: `{colors.surface}` at 80% opacity |

Contrast: `{colors.ink}` on `{colors.surface}` is the load-bearing pair (body text, menus) — target ≥ 4.5:1. `{colors.ink}` on `{colors.subtitle-bg}` over a worst-case bright House plate must stay ≥ 4.5:1 (the 80% scrim is the floor). `{colors.ink-muted}` is never the only cue for something the player must do. Bank vs Stress: number + track shape + stamp; hue is extra. `{colors.stamp-approve}` / `{colors.stamp-deny}` are read as word marks (APPROVE / DENY), not color alone.

Chapter skins may replace this palette entirely while that minigame is loaded. They must still keep one high-contrast text-on-surface pair.

## Typography

Godot **Control** theme. Two families, not a poster.

- **Source Serif 4** (`{typography.display}`) — title, journal headings, anything that should feel written.
- **Source Sans 3** (`{typography.body}`, `{typography.subtitle}`) — menus, subtitles, buttons.
- **IBM Plex Mono** (`{typography.numeric}`) — Due Date, Bank Account, timers, rhythm judgments. Digits must not dance.

Scale from 16px body: 16 / 18 subtitle / 20 reader (`{typography.reader.fontSize}`) / 28 micro-shout / 32 display. Novice shouts (`{typography.micro-shout}`) are the only all-caps, high-weight overlay. They are a chapter costume, not a hub voice.

**Reflowed Reader View** uses `{typography.reader}` on `{colors.ink}` paper (`{components.reader-view}`), never a zoomed screenshot of 10-point type.

## Layout & Spacing

8px grid (`{spacing.2}`). Touch-first: tap targets ≥ 44px. `{spacing.safe}` inset from screen edges and notches on phones; the same inset on desktop web so one layout serves both.

**The New House:** no corner HUD stack. Subtitles sit bottom-center when VO/dialogue is playing, then leave. Interactable objects highlight in the world (`{colors.accent}`); there is no persistent prompt plaque.

**Minigames, recurring slots:** when a chapter needs a kind of HUD, that *kind* always lives in the same region so muscle memory carries across genres:

- Status / resource / key / Bank Account → **top-start**
- Spatial / minimap (only if a chapter truly needs one) → **bottom-start**
- Primary action (stamp, confirm, hold) → **bottom-end**, or center when the genre *is* the document (Provider desk)

Do not invent meters the chapter does not need. Empty corners stay empty.

Menus: single column, max ~480px, centered over `{colors.scrim}`. One level deep.

Visual reference (spines win on conflict): [title](mockups/key-title.html), [House](mockups/key-house.html), [pause](mockups/key-pause.html), [Provider desk and Reflowed Reader View](mockups/key-provider.html).

## Elevation & Depth

The House is the depth. UI has two layers only:

1. **World** — house, highlights, diegetic objects (Journal, Trigger, stamps-on-paper).
2. **Overlay** — subtitles, thin title/pause, chapter HUD, Reader View.

No stacked modals. Pause **replaces** the overlay; it does not sit on a minigame menu on a journal. Reader View replaces the invoice texture; it is not a zoom lens over the desk.

## Shapes

`{rounded.md}` (8px) for panels and buttons — slightly soft, household, not pills. Stamps can be circular (`{rounded.full}`) because they are objects. Meters are rectangular tracks with a number; they do not pretend to be health hearts.

Focus is a 2px `{colors.focus-ring}` on the focused Control. Same ring for tap-focus and keyboard-focus if a keyboard is present later.

## Components

Shared kebab-case names with EXPERIENCE.md Component Patterns. Visual spec here; behavior there.

- **button-primary** — `{components.button-primary}`. `{colors.accent}` fill, `{colors.surface}` label, `{rounded.md}`, min-height 44px. One per screen when possible (Play, Resume). Pressed: slightly darker fill.
- **button-quiet** — `{components.button-quiet}`. Transparent, `{colors.ink}` label, 1px `{colors.border}`. Settings, Continue, secondary. Disabled Continue (no save): `{colors.ink-muted}` and not tappable — or omit the control.
- **panel** — `{components.panel}`. `{colors.surface-raised}`, 1px `{colors.border}`, `{rounded.md}`. Pause and Settings only.
- **subtitle-bar** — `{components.subtitle-bar}`. `{colors.ink}` on `{colors.subtitle-bg}` at `{typography.subtitle.fontSize}`. Bottom-center. No nameplate in the House.
- **interact-highlight** — outline or warmth on the object, `{colors.accent}`. No persistent crosshair in the House. Off when nothing is in range.
- **stamp** — circular (`{rounded.full}`) APPROVE / DENY word marks in `{colors.stamp-approve}` / `{colors.stamp-deny}`. Ink on paper, not a HUD chip.
- **reader-view** — **Reflowed Reader View**. `{components.reader-view}`: `{colors.ink}` paper, `{colors.surface}` type, `{typography.reader.fontSize}` (20px). Replaces the invoice; not a zoom.
- **meter** — rectangular track `{colors.border}`; fill `{colors.meter-bank}` or `{colors.meter-stress}`; number in `{typography.numeric}`. Top-start slot. Never hue-only.
- **journal** — **Dad's Journal**. In-world object; opened page is serif `{typography.display.fontFamily}` on `{colors.surface-raised}`. Stoic/Vulnerable changes the entry’s words, not the skin.
- **pause** — `{colors.scrim}` over the scene; single `{components.panel}` column. Replaces overlay; never stacks.
- **knobs** — Tuner. Large Control dials, min 44px. Waveform is the feedback; no legend plate.
- **rhythm-judgment** — Perfect / Good / Miss as short `{typography.numeric}` near the hit, `{colors.ink}`. Not a combo tower.
- **novice-shout** — `{typography.micro-shout}` full-screen or upper-third, then gone.
- **drag-drop** — Mourner. Ghost uses `{colors.accent}`; invalid drop uses `{colors.meter-stress}` and snaps back. No inventory grid unless an item is in hand.
- **balance** — Anchor. Two hold-zones, min 44px, `{colors.border}` idle. Almost no other HUD. Maya’s voice is the assist cue, not a meter labeled “Stability.”
- **provider-desk** — Documents as `Control` pages on `{colors.ink}` paper. Stamps and **Reflowed Reader View** live here. Due Date + Bank Account use `meter` in the top-start slot.

## Do's and Don'ts

- Do keep the House visually quiet. If a hub overlay is not earning the look, delete it.
- Do let each minigame look like its inspiration while that scene is up.
- Do put the same *kinds* of HUD in the same regions when they appear.
- Do make paperwork readable on a phone with Reader View, not pinch-zoom.
- Do let Loss desaturate toward `{colors.house-grief}` in the world, and hope bias toward `{colors.house-hope}` — not with a popup.
- Don't put a virtual stick, a minimap, or a quest marker in the House.
- Don't warn, skip, or title-card the miscarriage chapter.
- Don't use hue alone for Bank Account vs Stress — number + shape + stamp.
- Don't stack menus.
- Don't treat PC/Steam as the visual default; design the phone-width column first.
