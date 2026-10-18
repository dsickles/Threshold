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

## Suggesting the next ticket

When a ticket is done and you tell Dan what comes next, never say "use the same opening steps". Give him the exact prompts to paste.

**In a Claude Project (claude.ai), not a desktop session:** skip the prompts and worktrees below. Each ticket gets its own thread with a fresh context, so tell Dan the exact line to post in the project chat (for example "Do DAS-69"), one per ticket. Steps 1–2 below still apply: check which tickets are ready, which can run in parallel, and agree the merge plan first. Cloud threads can error-check, export and upload with `bash tools/publish.sh` (see "Building and testing"), but only upload after Dan says "upload" in that thread. Playing the build, including on Dan's phone, is still Dan's. Anything a later thread must know goes in the repo or Linear, not just the thread.

1. Look in Linear for tickets in the current milestone that are Todo, labelled `v1`, and whose blockers are all Done.
2. Decide which of them can run at the same time. Two tickets can run in parallel only if neither needs the other's result and they won't edit the same files. If they would share a file (for example, each adds its button to the M0 menu), say so and say which to merge first. If unsure, run them one after another. Parallel sessions share one itch.io page and each upload replaces the last, so tell Dan which session's build is live.
   - **Agree the merge plan before any parallel session starts.** Before giving the prompts, write a short merge plan and wait for Dan to OK it. Don't leave it to the end of a session, where it is easy to miss.
     - **GitHub:** the order the branches merge into main, which shared files will conflict, and who fixes each conflict. Default: the first branch merges as-is; each later branch pulls the new main, fixes conflicts and re-checks before its PR is merged.
     - **itch.io:** who uploads and when. Default: one build is live at a time. Each session waits for Dan to say "upload", Dan tests it on the phone, then that branch merges and the next session uploads. Once everything is merged, upload once more from main so the live build has it all.
     - Put each session's part of the plan into its prompt (its place in the merge order, and "don't upload until Dan says"), so no session merges or uploads out of turn.
3. Give one prompt per session, each in its own code block, and say which session it is for. If only one ticket should run now, give one prompt and say which ticket follows.
   - **First (or only) session:** the main folder, `C:\Users\Sickl\.cursor\DASSoft\Threshold`.
   - **Each extra parallel session:** its own worktree next to it, named after the ticket (for example `C:\Users\Sickl\.cursor\DASSoft\Threshold-das-68`). Remind Dan to add that folder to Cursor (File → Add Folder to Workspace).
   - Use the ticket's Linear branch name (`gitBranchName`).

Prompt for the main folder (fill in the `<...>` parts):

```
Before doing anything else, check where you are:

1. Run "git rev-parse --show-toplevel" and "git branch --show-current" and tell me the results.
2. The folder must be exactly C:\Users\Sickl\.cursor\DASSoft\Threshold, not any worktree. If you are anywhere else, stop and tell me; don't create or enter a worktree.
3. Run "git status" and show me. If there are uncommitted changes you didn't make, stop and ask me.
4. Switch to main, pull the latest, and make a new branch named <linear-branch-name>.

Then run /implement <DAS-n>. Start with step-by-step instructions for any parts only I can do.
```

Prompt for a parallel worktree session:

```
Before doing anything else, set up and check your own worktree:

1. In C:\Users\Sickl\.cursor\DASSoft\Threshold, run "git fetch origin", then "git worktree add C:\Users\Sickl\.cursor\DASSoft\Threshold-<das-n> -b <linear-branch-name> origin/main". If the folder or branch already exists, stop and tell me.
2. Work only inside C:\Users\Sickl\.cursor\DASSoft\Threshold-<das-n>. Never edit files in the main Threshold folder.
3. Run "git rev-parse --show-toplevel", "git branch --show-current" and "git status" there and show me the results.

Then run /implement <DAS-n>. Start with step-by-step instructions for any parts only I can do. Another session is working on <other DAS-n> at the same time; don't touch <shared files, if any>.
```

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
- **Cloud (Claude threads):** `bash tools/publish.sh` installs Godot 4.7.2, the web export templates and butler if they are missing, then error-checks and exports the same way. Add `--upload` to push to itch.io, only after Dan says "upload"; the build's version on itch is the branch's last part plus its commit. The cloud environment must allow github.com and itch.io downloads and have `BUTLER_API_KEY` set.
- **Automatic PR checks:** `.github/workflows/check.yml` runs `bash tools/publish.sh` (no `--upload`) on PRs and main pushes that touch `game/`, `tools/` or the workflow (docs-only PRs skip it), so such a PR shows a red X if any script has an error or the web export breaks. CI never uploads to itch.io.
- **Private test link:** https://dsickles.itch.io/threshold (restricted, password-protected; Dan holds the password, never write it in the repo).

Automated tests cover the core table and save/load; everything else is checked by playing, including on Dan's phone.

Claude can't see the game running. End every change Dan needs to play with a short "what to look for" list: where to go, what to tap, and what should happen.
