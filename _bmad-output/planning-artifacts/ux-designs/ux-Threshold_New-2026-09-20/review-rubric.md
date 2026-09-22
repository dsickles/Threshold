# Spine Pair Review — Threshold_New

## Overall verdict

A human can read this pair and implement the locked UX calls (web-first tap/click, quiet House, Loss with no warning chrome, recurring HUD slots, lamp-lit tokens). A downstream extractor cannot: component names diverge across YAML, DESIGN.md.Components, and EXPERIENCE.md.Component Patterns, several IA surfaces lack empty/error/focus states, and two named source beats (**The Story Sequence**, **The Ending**) never appear in a Key Flow. Tokens themselves resolve and carry hex; the contract is committed as intent, not as a joinable dictionary.

## 1. Flow coverage — adequate

Checked named player journeys in `sources` (only `.decision-log.md` names UJs) plus UX-facing requirement names in `gdd.md` / reports. Decision-log journeys: **Alex, first time, phone browser**; **Jordan, The Protector (The Loss), laptop**. Both have a named protagonist, numbered steps, a climax beat, and a failure path. Extra flow **Sam pays a bill** covers GDD **Reflowed Reader View**. GDD has no `UJ-*` / `FR-*` IDs.

### Findings

- **medium** GDD loop step **The Story Sequence** is named in IA and a State Patterns row, but no Key Flow includes it; Alex jumps House → Trigger (EXPERIENCE.md Key Flows; gdd.md Core Gameplay Loop). *Fix:* Add a numbered beat (or a short fourth flow) where a Volume fires a Story Sequence before The Trigger.
- **medium** GDD **The Ending** (Tuner + Partner reprise) is an IA surface and a State Patterns row, with no Key Flow (EXPERIENCE.md Information Architecture / Key Flows; gdd.md Player Progression). *Fix:* One short named-protagonist reprise flow with a climax and a fail-forward path.
- **medium** Named requirement **Stability Assist** / **Maya's Voice** has State Patterns + a11y, but no Key Flow shows repeated falls → voice → invisible assist (gdd.md The Anchor; EXPERIENCE.md State Patterns Assist). *Fix:* Either a dedicated Anchor flow or a failure branch on an existing journey.
- **low** Third protagonist **Sam** is not a source-named UJ (decision log locked Alex and Jordan only) (EXPERIENCE.md Key Flows). *Fix:* Keep the Provider flow; rename to a source journey or log Sam as a locked UJ.
- **low** Title **Continue** has no returning-player flow (EXPERIENCE.md IA Title). *Fix:* One resume flow, or fold Continue into Alex’s failure/tab-hidden path.

## 2. Token completeness — adequate

Frontmatter defines `name`, `description`, `colors` (all hex), nested `typography`, `rounded`, `spacing`, and `components`. Every `{path.to.token}` in DESIGN.md / EXPERIENCE.md prose resolves except the instructional literal `{path.to.token}`. No light/dark product mode (decision log: out of scope). Load-bearing contrast stated for `{colors.ink}` on `{colors.surface}` (≥ 4.5:1). Platform/engine notes stay semantic (Godot Control theme).

### Findings

- **medium** Reader size forks: `{typography.body}` is 16px, `{components.reader-view}` hard-codes `font-size: 20px`, and prose says Reflowed Reader View uses ≥ 20px `{typography.body}` on `{colors.ink}` paper (DESIGN.md Typography; frontmatter `typography.body` / `components.reader-view`). *Fix:* Add a `typography.reader` role at 20px and point both the component and the prose at it.
- **medium** `{colors.subtitle-bg}` is 8-digit `#1C1916CC`; spec examples are 6-digit hex. Subtitles over live House 3D have no stated contrast floor beyond ink-on-surface of the bar itself (DESIGN.md Colors / frontmatter). *Fix:* Split `subtitle-bg` (opaque) + opacity token, or state a scrim+text contrast target against a worst-case house plate.
- **medium** `{colors.meter-stress}` and stamp colors have hex but no contrast targets; `components.meter.fill` only references `{colors.meter-bank}` (DESIGN.md Colors; frontmatter `components.meter`). *Fix:* Wire `meter-stress` into the meter component; state number+shape contrast for Bank vs Stress vs stamps.
- **low** `{colors.accent}`, `{colors.meter-bank}`, and `{colors.focus-ring}` share `#C4A574` (DESIGN.md frontmatter). *Fix:* Keep three roles; note they are aliases, or derive two from one token.
- **low** Several refs target objects (`{typography.subtitle}`, `{typography.display}`, `{components.button-primary}`) not leaves (DESIGN.md Components / EXPERIENCE.md Accessibility Floor). *Fix:* Prefer `{typography.subtitle.fontSize}` (etc.) where code will flatten.
- **low** `{colors.house-hope}` is defined and tabled, never referenced as `{colors.house-hope}` (DESIGN.md Colors). *Fix:* Use it in Brand/Do's the way `{colors.house-grief}` is used, or drop it.

## 3. Component coverage — thin

Extracted names from YAML `components:`, DESIGN.md.Components, EXPERIENCE.md.Component Patterns, and in-prose uses. Dual-spec (visual row **and** behavioral row, same name) holds only for **Stamp** / stamp-approve|deny (partial) and **Reader View**. Everything else requires a human to join aliases.

| DESIGN.md.Components | YAML key | EXPERIENCE.md.Component Patterns |
| --- | --- | --- |
| Button (primary) | `button-primary` | — |
| Button (quiet) | `button-quiet` | — |
| Panel | `panel` | — |
| Subtitle bar | `subtitle-bar` | Subtitle |
| Interact highlight | `interact-highlight` | Interact |
| Journal | — | — (IA surface only) |
| Provider desk | — | — |
| Reader View | `reader-view` | Reader View |
| Rhythm judgment | — | Rhythm tap |
| Novice shout | — | Micro-game |
| Tuner knobs | — | Knobs |
| Anchor | — | Balance |
| Mourner | — | Drag-drop |
| — | `meter` | — |
| — | `stamp-approve` / `stamp-deny` | Stamp |
| — | — | Tap-to-move |
| — | — | Tap-to-look |
| — | — | Pause |

### Findings

- **high** Component names are not identical across YAML, DESIGN.md.Components, and EXPERIENCE.md.Component Patterns; a consumer cannot join visual + behavioral specs by name (both spines, Components / Component Patterns). *Fix:* One kebab-case glossary (`button-primary`, `subtitle-bar`, `interact-highlight`, `reader-view`, `stamp`, `knobs`, `rhythm-judgment`, `novice-shout`, `drag-drop`, `balance`, `journal`, `pause`, `meter`) used in all three places.
- **high** DESIGN-only visuals (Button primary/quiet, Panel, Journal, Provider desk, meter, Interact highlight, Rhythm judgment, Novice shout, Tuner knobs, Anchor, Mourner) lack EXPERIENCE behavioral rows under those names; EXPERIENCE-only rows (Tap-to-move, Tap-to-look, Pause, Micro-game, Balance, Drag-drop, Rhythm tap, Knobs) lack DESIGN visual rows (DESIGN.md Components; EXPERIENCE.md Component Patterns). *Fix:* After the name lock, give every remaining component one visual bullet **and** one behavioral rule row. Move tap-to-move / tap-to-look to Interaction Primitives only if they are not components.
- **medium** YAML `components:` omits Journal, knobs, rhythm, novice shout, pause, mourner drag-ghost, provider desk — chapter UIs have no machine-readable tokens (DESIGN.md frontmatter). *Fix:* Add component objects with `{path.to.token}` fills, even if sparse.
- **medium** Several DESIGN bullets are one-line mood, not anatomy (Anchor, Mourner, Journal) (DESIGN.md Components). *Fix:* State fill, type role, size, and state appearance the way Button/Panel do.

## 4. State coverage — thin

Walked every IA surface. Applicable state families for this web/mobile narrative: empty, cold-load, focus, error, interrupt/tab-hidden, fail-forward. N/A: permission-denied (no mic/camera). Offline is applicable because delivery is a browser.

Covered: Title cold open; House first wander; Story Sequence (as a state); In minigame; Fail-forward; The Loss; After Loss; Assist; Mastery; Tab hidden; Low-end; Ending.

### Findings

- **high** Title lists **Continue** but there is no empty-continue / no-save treatment (EXPERIENCE.md IA Title; State Patterns). *Fix:* Hide Continue when no checkpoint, or a one-line empty state.
- **high** **Journal** is an IA surface with no empty, first-entry, or Stoic/Vulnerable states (EXPERIENCE.md IA Journal; State Patterns). *Fix:* Three rows: empty journal, first entry after a chapter, tone-only change (no skin).
- **medium** Web-first, but no offline, save-error, or scene-load error (EXPERIENCE.md State Patterns; Foundation). *Fix:* At least: paused + last checkpoint on reload; a non-blocking “couldn’t save” on Pause/Title.
- **medium** Keyboard may activate the focused Control on menus, but Title / Pause / Settings have no Focus (or default-focus) state (EXPERIENCE.md Input Schemes; State Patterns). *Fix:* One Focus row: 2px `{colors.focus-ring}`, Resume/Play as default.
- **medium** Provider **Due Date** expiry is not a state — fail-forward is generic, timer-end UX is not (gdd.md The Provider; EXPERIENCE.md State Patterns / Sam flow). *Fix:* A Due Date row: number ticks, story continues, no desk-trap.
- **medium** **The Partner**, **The Tuner**, **The Mourner** only inherit “In minigame” / “Fail-forward”; no start, miss/static, invalid-drop, or complete treatments (EXPERIENCE.md IA; State Patterns). *Fix:* One row each, or fold into Fail-forward with surface-specific copy.
- **low** Reader View has no extract-fail / unreadable-document path (EXPERIENCE.md IA Reader View). *Fix:* Fallback: still stampable desk, short “can’t enlarge this page.”
- **low** House interact focus is a component, not a state (cold-load of the House / first highlight) (EXPERIENCE.md The New House). *Fix:* Optional; First wander already forbids markers.

## 5. Visual reference coverage — strong

Globbed `mockups/`, `wireframes/`, `imports/` under the UX workspace.

| Path | Files |
| --- | --- |
| `mockups/` | directory absent |
| `wireframes/` | directory absent |
| `imports/` | `.gitkeep` only |

Spines-win-on-conflict is stated in both files (DESIGN.md preamble; EXPERIENCE.md intro). No inline visual links, therefore no orphans and no unspecific figure references. Decision log: no developer imports, no key-screen mocks.

### Findings

- **low** `mockups/` and `wireframes/` do not exist (not even `.gitkeep`), so a later drop has no agreed folder (UX workspace root). *Fix:* Add the two folders with `.gitkeep`.
- **low** No composition reference; layout (480px menus, HUD slots) is prose-only (both spines). *Fix:* Not required for this pass; if mocks arrive, link each at IA / Layout and keep the conflict rule.

## 6. Bloat & overspecification — strong

DESIGN.md carries editorial voice in Brand & Style (allowed). EXPERIENCE.md is mostly tables and rules; Key Flows are journeys, not brand copy. Invented game sections (HUD & Diegetic UI, Input Schemes, Game Feel & Juice) match the game example and commit locked calls. Little pixel duplication beyond the 44px target (token + a11y floor).

### Findings

- **low** Tap target ≥ 44px is stated in YAML `min-height`, DESIGN.md Layout, and EXPERIENCE.md Accessibility Floor. *Fix:* YAML + one a11y sentence.
- **low** EXPERIENCE Key Flows slip a little editorial (“They might be slightly unsure”) (EXPERIENCE.md Alex flow). *Fix:* Trim to observable UI; keep climax.

## 7. Inheritance discipline — thin

All 11 `sources:` paths resolve on disk. EXPERIENCE.md token refs resolve to DESIGN.md tokens by name (`typography.numeric`, `typography.subtitle`, `spacing.safe`, `components.reader-view`, `colors.meter-bank`). Form-factor supersession of GDD PC-primary / architecture WASD is documented. Chapter names **The Partner** … **The Mourner**, **Leo**, **Maya**, **The New House**, **The Trigger**, **Connection Nodes**, **Bank Account**, **Due Date**, **QualityManager** match sources.

### Findings

- **high** Component names are not identical across all sections in both files (see §3) (DESIGN.md Components vs EXPERIENCE.md Component Patterns vs YAML keys). *Fix:* Same as §3 name lock; inheritance fails until then.
- **medium** GDD **Reflowed Reader View** vs spines **Reader View** (full name once in DESIGN.md Typography) (gdd.md Accessibility Note; EXPERIENCE.md IA / Components). *Fix:* Use **Reflowed Reader View** everywhere, YAML `reader-view` as the machine key only.
- **medium** GDD **Dad's Journal** vs spines **Journal** (gdd.md Player Progression; both spines). *Fix:* Pick one display name; keep `Journal` as the architecture class if that is the source of truth.
- **medium** Key Flow titles are not verbatim vs the locked journeys (“Alex, first time, phone browser”; “Jordan, The Protector (The Loss), laptop”) (`.decision-log.md`; EXPERIENCE.md Key Flows). *Fix:* Use the log titles as H3s.
- **low** IA drops parenthetical beat names **(The Spark)**, **(The Loss)**, **(The Science)**, etc. (gdd.md Mechanics; EXPERIENCE.md IA). *Fix:* Include them in the Surface column.
- **low** Intake listed `brainstorming-session-2025-11-22.md`; spines `sources:` omit it (`.decision-log.md` Intake; both frontmatters). *Fix:* Add it or note exclusion as superseded in the log only.

## 8. Shape fit — strong

DESIGN.md body order: Brand & Style → Colors → Typography → Layout & Spacing → Elevation & Depth → Shapes → Components → Do's and Don'ts. None omitted; none reordered. EXPERIENCE.md required defaults present: Foundation, Information Architecture, Voice and Tone, Component Patterns, State Patterns, Interaction Primitives, Accessibility Floor, Key Flows. Required-when-applicable: Inspiration & Anti-patterns (reference products + rejects in sources/log); Responsive & Platform (web / phone / PC). Invented sections HUD & Diegetic UI, Input Schemes, Game Feel & Juice earn their place (game-spine pattern; they carry locked input and Loss-juice rules). Dropped defaults: none of the required set. Status remains `draft` in frontmatter while the log says Finalize started — consistent with reviewer-gate pending.

### Findings

- **low** Unlabeled preamble sits above **Brand & Style** (DESIGN.md lines 112–116). *Fix:* Fold the House/chrome rule and the conflict sentence into Brand & Style or Layout.

## Mechanical notes

- Frontmatter: DESIGN.md has required `name` + `description`; extra `status`, `updated`, `sources` are useful. EXPERIENCE.md has `title`, `status`, `updated`, `form_factor`, `sources` — complete for this pair. `status: draft` on both.
- Cross-refs: all `{path.to.token}` paths exist except the instructional `{path.to.token}` on EXPERIENCE.md line 22 (not a token). No Mermaid.
- YAML: `fontWeight` values are unquoted integers (spec examples quote strings). `subtitle-bg` is 8-digit hex. Component `font: '{typography.subtitle}'` points at an object.
- Name drift (non-component): **The New House** vs **The House** (character vs hub — matches narrative-design.md, keep both); **MinigameTrigger** / **Door** / **Journal** in EXPERIENCE Interact match `game-architecture.md` class names.
- Conflict rule stated twice (once per spine). Fine if each file must stand alone; not a broken cross-ref.
- No broken source paths.
