# Threshold

A narrative anthology game about becoming a father, built in Godot 4 (GDScript) for the browser first, then phone, then PC/Steam. Dan is a product manager, not a professional engineer; he builds it with Claude Code. Use the words in [GLOSSARY.md](GLOSSARY.md).

## Talking to Dan

- Plain language. No jargon without a one-line explanation.
- Recommend one option and say why; don't hand over an unranked list.
- Ask Dan only for decisions that are really his (story, feel, scope, anything public). Find facts yourself.
- Short answers. Say what is done, what is not, and what was not checked.

## Where things are

| What | Where |
|---|---|
| Build order and milestone success criteria | [docs/roadmap.md](docs/roadmap.md) |
| What is in v1, what is Later, open questions | [docs/scope.md](docs/scope.md) |
| Decisions and why | [docs/adr/](docs/adr/) (newest wins) and [docs/design/decision-history.md](docs/design/decision-history.md) |
| Game design | [docs/design/gdd.md](docs/design/gdd.md), [narrative-design.md](docs/design/narrative-design.md), [game-brief.md](docs/design/game-brief.md) |
| Technical design | [docs/design/game-architecture.md](docs/design/game-architecture.md) |
| UX | [docs/design/ux/EXPERIENCE.md](docs/design/ux/EXPERIENCE.md) (behavior), [DESIGN.md](docs/design/ux/DESIGN.md) (look) |
| Requirements | [docs/design/requirements.md](docs/design/requirements.md) |
| Per-chapter acceptance criteria | [docs/design/stories/](docs/design/stories/) (reference, not a plan) |
| Playtest notes | [docs/playtests/](docs/playtests/) |
| Work tracking | Linear (see "Agent skills" below once set up) |

`archive/` holds the old BMAD-era files exactly as they were. Do not read or use it unless Dan asks; reading it is blocked in `.claude/settings.json`.

## When documents disagree

1. The newer decision wins: ADRs and dated rulings beat older text. `docs/scope.md` decides what is in v1.
2. Don't pick silently. Tell Dan what conflicts, recommend a fix, and wait.
3. Once decided: record it (an ADR if it is hard to reverse or surprising, otherwise a dated line in scope.md), fix the out-of-date line in the doc, and add a decision-history entry for what it replaced.

## Rules that must not break

- One tap scheme everywhere. Click = tap. No WASD, virtual stick, mouse-look or gamepad. The House uses fixed viewpoints.
- The Loss (The Protector) has no warning, no skip and no retry.
- Each chapter has one result. Only spoken words and journal wording may differ (Stoic/Vulnerable).
- Saves happen only between chapters. Hiding the tab pauses but never saves.
- The House must look right without volumetric fog. No Godot CompositorEffects (they don't run in the browser).
- The UI never explains the metaphor.
- Before starting a ticket, check it is v1 in docs/scope.md. If it isn't, ask Dan.

## Building and testing

Not set up yet (milestone M0). When it is, record here: the pinned Godot version, how to run the game, how to run tests, how to export the web build, and where the private test link lives. Automated tests cover the core table and save/load; everything else is checked by playing, including on Dan's phone.
