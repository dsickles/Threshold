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
| Work tracking | Linear: Threshold initiative, one project per milestone (see "Agent skills" below) |

`archive/` holds the old BMAD-era files exactly as they were. Do not read or use it unless Dan asks; reading it is blocked in `.claude/settings.json`.

## When documents disagree

1. The newer decision wins: ADRs and dated rulings beat older text. `docs/scope.md` decides what is in v1.
2. Don't pick silently. Tell Dan what conflicts, recommend a fix, and wait.
3. Once decided: record it (an ADR if it is hard to reverse or surprising, otherwise a dated line in scope.md), fix the out-of-date line in the doc, and add a decision-history entry for what it replaced.

## Rules that must not break

- One tap scheme everywhere. Click = tap. No WASD, virtual stick, mouse-look or gamepad. The House uses fixed viewpoints.
- Nothing works only on hover. Tap targets are at least 44px.
- The Loss (The Protector) has no warning, no skip and no retry.
- Each chapter has one result. Only spoken words and journal wording may differ (Stoic/Vulnerable).
- Saves happen only between chapters. Hiding the tab pauses but never saves.
- The House must look right without volumetric fog. No Godot CompositorEffects (they don't run in the browser).
- The UI never explains the metaphor.
- Before starting a ticket, check it is v1 in docs/scope.md. If it isn't, ask Dan.

## Changing things

- Ask before adding a Godot addon, plugin, library or other outside dependency.
- Keep the House and each chapter separate: a chapter must not reach into the House or another chapter, except through the shared systems in game-architecture.md.
- Don't invent story, dialogue or journal wording. If a placeholder is needed, mark it clearly as a placeholder and tell Dan.
- Don't delete or rewrite design docs. The one exception is fixing an out-of-date line after a decision (see "When documents disagree").
- Dan follows along in Cursor. When only one session is writing, work in the main Threshold folder on a new branch, not a worktree. Use a worktree only when several sessions write at once, and tell Dan its full path so he can add it to his Cursor window (File → Add Folder to Workspace).

## Agent skills

### Issue tracker

Linear, team DASSoft, under the Threshold initiative; one project per milestone, issues roll up to projects, `v1`/`later` labels, status Todo means ready. See `docs/agents/issue-tracker.md`.

### Domain docs

Single-context: `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

### Installed skills

Matt Pocock's skills, copied into `.claude/skills/` (versions in `skills-lock.json`; update with `npx skills@latest update`). Typical flow: `/grill-with-docs` to agree a milestone or decision → `/to-spec` → `/to-tickets` → `/implement` one ticket at a time. Also: `prototype`, `tdd` (core table and saves only), `diagnosing-bugs`, `/wait-what` (Dan asks for a plain re-explanation), `/handoff`. Claude Code also has a built-in `/code-review`; `/implement` is meant to use this repo's `code-review` skill.

## Building and testing

Pinned engine: **Godot 4.7.2**, standard build (not .NET). Private test link: a password-protected itch.io page, uploaded with butler (see `docs/scope.md`, "Settled questions").

- **Project folder:** `game/` (open `game/project.godot`). It lives in its own folder so Godot never imports `docs/` or `archive/`. Renderer: Compatibility. `.godot/` and `build/` are ignored; commit each `.uid` file with its script.
- **Tools:** Godot and butler live in `DASSoft\Tools`, next to this repo (paths in `tools/paths.ps1`; override with the `GODOT` / `BUTLER` environment variables). Export templates for 4.7.2 must be installed in `%APPDATA%\Godot\export_templates\4.7.2.stable\`.
- **Run:** open `game/project.godot` in `Godot_v4.7.2-stable_win64.exe` and press Play (F5).
- **Error check (no editor):** `powershell -ExecutionPolicy Bypass -File tools/check.ps1`. It runs Godot's built-in script check on every `.gd` file and exits non-zero on any error.
- **Tests:** none yet. The test addon is chosen in M1, together with the core table.
- **Export and publish:** `powershell -ExecutionPolicy Bypass -File tools/publish.ps1`. It error-checks, exports the "Web" preset (single-threaded) to `build/web/` at the repo root (outside `game/`, so Godot never imports old builds), then runs one butler command: `butler push build/web dsickles/threshold:html5`. butler is logged in once on Dan's PC.
- **Private test link:** https://dsickles.itch.io/threshold (restricted, password-protected; Dan holds the password, never write it in the repo).

Automated tests cover the core table and save/load; everything else is checked by playing, including on Dan's phone.

Claude can't see the game running. End every change Dan needs to play with a short "what to look for" list: where to go, what to tap, and what should happen.
