# Validation Report — Threshold

- **DESIGN.md:** `_bmad-output/planning-artifacts/ux-designs/ux-Threshold-2026-09-20/DESIGN.md`
- **EXPERIENCE.md:** `_bmad-output/planning-artifacts/ux-designs/ux-Threshold-2026-09-20/EXPERIENCE.md`
- **Run at:** 2026-09-21

## Overall verdict

A human can read this pair and implement the locked UX calls (web-first tap/click, quiet House, Loss with no warning chrome, recurring HUD slots, lamp-lit tokens). A downstream extractor cannot: component names diverge across YAML, DESIGN.md.Components, and EXPERIENCE.md.Component Patterns, several IA surfaces lack empty/error/focus states, and two named source beats (**The Story Sequence**, **The Ending**) never appear in a Key Flow. Tokens themselves resolve and carry hex; the contract is committed as intent, not as a joinable dictionary.

No extra reviewers ran. Completeness (rubric walker) only.

## Category verdicts

- Flow coverage — adequate
- Token completeness — adequate
- Component coverage — thin
- State coverage — thin
- Visual reference coverage — strong
- Bloat & overspecification — strong
- Inheritance discipline — thin
- Shape fit — strong

## Findings by severity

### Critical (0)

None.

### High (5)

**Component coverage** — Names do not join across YAML, DESIGN, and EXPERIENCE (DESIGN.md Components; EXPERIENCE.md Component Patterns).
A consumer cannot match visual + behavioral specs by name.
Fix: One kebab-case glossary used in all three places.

**Component coverage** — Dual-spec missing for most components (both spines).
DESIGN-only visuals and EXPERIENCE-only behaviors.
Fix: After the name lock, one visual bullet and one behavioral row per remaining component. Tap-to-move / tap-to-look stay Interaction Primitives if they are not components.

**State coverage** — Title **Continue** has no empty / no-save treatment (EXPERIENCE.md IA Title; State Patterns).
Fix: Hide Continue when no checkpoint, or a one-line empty state.

**State coverage** — **Journal** has no empty, first-entry, or Stoic/Vulnerable states (EXPERIENCE.md IA Journal).
Fix: Three rows: empty, first entry after a chapter, tone-only change.

**Inheritance discipline** — Component names not identical across sections (same as component coverage).
Fix: Same name lock.

### Medium (15)

**Flow** — **The Story Sequence** has no Key Flow. Fix: numbered beat or a short fourth flow.
**Flow** — **The Ending** has no Key Flow. Fix: named-protagonist reprise with climax and fail-forward.
**Flow** — **Stability Assist** / Maya's Voice has no Key Flow of repeated falls → voice → assist.
**Token** — Reader size forks (16px body vs 20px reader). Fix: `typography.reader` at 20px.
**Token** — `subtitle-bg` is 8-digit hex; no contrast floor over live 3D. Fix: split opaque + opacity, or state a target.
**Token** — `meter-stress` not wired into `components.meter`. Fix: wire it; state Bank vs Stress contrast.
**Component** — YAML omits Journal, knobs, rhythm, shout, pause, drag-ghost, desk.
**Component** — Several DESIGN bullets are mood, not anatomy (Anchor, Mourner, Journal).
**State** — No offline / save-error / scene-load error.
**State** — Title / Pause / Settings have no Focus / default-focus state.
**State** — Provider Due Date expiry is not a state.
**State** — Partner / Tuner / Mourner only inherit generic in-minigame.
**Inheritance** — GDD **Reflowed Reader View** vs spines **Reader View**.
**Inheritance** — GDD **Dad's Journal** vs spines **Journal**.
**Inheritance** — Key Flow titles are not verbatim vs the locked journeys.

### Low (14)

Sam is not a source-named UJ; Title Continue has no returning-player flow; object-token refs; house-hope unused; accent/meter-bank/focus-ring share a hex; mockups/wireframes folders absent; 44px restated thrice; Key Flows slightly editorial; parenthetical beat names dropped in IA; brainstorming omitted from sources; unlabeled DESIGN preamble; Reader extract-fail; House interact as component not state; leaf-vs-object token paths.

## Reviewer files

- `review-rubric.md`
