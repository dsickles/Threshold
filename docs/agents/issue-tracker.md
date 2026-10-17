# Issue tracker: Linear

Work for this repo lives in Linear, workspace **dassoft**, team **DASSoft** (key `DAS`). Claude reaches it through the Linear connector (the Linear MCP tools). The DASSoft team also holds Dan's other apps, so always scope to Threshold.

## Structure

- **Initiative:** `Threshold` (I-3). Everything for this game sits under it.
- **Projects = milestones.** One Linear project per milestone in `docs/roadmap.md`, all linked to the Threshold initiative:
  - `Threshold M0 Setup`
  - `Threshold M1 Spark to Silence`
  - `Threshold M2 The Whole Story, Rough`
  - `Threshold M3+ Chapter depth` (may later split into one project per chapter)
  - `Threshold Final: Polish & Ship`
  New milestone projects follow the same `Threshold <milestone>` naming and get added to the initiative.
- **Issues roll up to projects.** Every Threshold issue belongs to exactly one milestone project.
- **Scope labels:** label group `Threshold scope` with `v1` and `later` (pick one). Every Threshold issue gets one. Source of truth for scope is `docs/scope.md`; if they disagree, ask Dan.
- **Statuses:** the team's own: Backlog, Todo, In Progress, In Review, Done, Canceled, Duplicate.
- **No triage labels.** Where a skill says to apply `ready-for-agent`, set status **Todo** instead. Backlog means not ready yet.

## When a skill says "publish to the issue tracker"

- **A spec** (`/to-spec`): create one issue titled `Spec: <name>` in the milestone project it belongs to, labelled `v1` (or `later`), status Todo. If the spec covers a whole milestone, also put a link to it in the project description.
- **Tickets** (`/to-tickets`): create each ticket as a **sub-issue of the spec issue**, in the same project, with the same scope label, status Todo. Create blockers first and record order with Linear's native **blocked by** relation.
- Before creating anything, check `docs/scope.md`. Don't create v1 issues for things marked Later.

## When a skill says "fetch the relevant ticket"

Get the issue by its identifier (for example `DAS-123`) or URL, including its description, comments, sub-issues and blocking relations. State its title before starting.

## Working a ticket

- Move it to **In Progress** when starting and **In Review** when the work is committed and ready for Dan to check.
- Dan moves it to **Done** after checking, unless he says Claude may close it.
- Comment on the issue with what changed, what was checked, and anything not checked.
- A ticket is ready to start when all its blockers are Done.

## New ideas mid-build

Create an issue labelled `later` in the relevant milestone project (or the Final project if unsure) and add a row to the Later table in `docs/scope.md`. Don't build it.
