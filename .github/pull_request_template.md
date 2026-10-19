Ticket: DAS-<n> (<Linear link>)

<!-- Fill every section. A PR stays in draft until the "Acceptance criteria" table is complete and the self-review is done. See docs/agents/pull-requests.md. -->

Before: <what a player or Dan sees today, in plain words>

After: <what they will see once this merges>

How: <a short paragraph on the approach>

## Acceptance criteria

Every criterion from the Linear ticket, copied word for word, in the ticket's order. One row each; none left out.

| # | Criterion (from the ticket) | Status | Proof |
|---|---|---|---|
| 1 | <copied text> | Met | `game/tests/test_x.gd` `test_name`; CI run <link> on `<head sha>` |
| 2 | <copied text> | Needs Dan's device | What Dan should do: <where to go, what to tap, what should happen> |
| 3 | <copied text> | Accepted by Dan | <why it is not met>; Dan's decision: <Linear comment by Dan, Dan's message in the project thread, or ADR; never a GitHub comment> |

Status is one of **Met**, **Needs Dan's device**, **Accepted by Dan** (link his decision: a Linear comment by Dan, his message in the project thread, or an ADR he signed off; never a GitHub comment, since everyone posts there as dsickles) or **Not met**. Proof is a test name, a `file:line`, or a CI run on the current head. "Needs Dan's device" waits for Dan and is never skipped.

## Depends on and merge order

Other open PRs this one needs or overlaps with, which merges first, and which PR removes any code the two duplicate. Write "None" if none.

## Out-of-scope changes

Anything in this PR the ticket did not ask for, and why. Write "None" if none.

## Tests changed

Every existing test this PR edits or deletes, and why. Write "None" if none. Any removed assert, wider tolerance, skip or test that no longer runs is listed here.

## Local checks

itch.io build: (filled in by the "Review build" check with the head sha, threshold-review; write "none" if the PR doesn't change the game. Never the live page.)

Pasted output of any check that ran only on a machine and not in CI (for example `tools/check.ps1`). Write "None" if everything ran in CI.

## Self-review

- [ ] Read the whole diff against the ticket, not against my own plan.
- [ ] Ran `bash tools/publish.sh` (or `tools/check.ps1` and `tools/test.ps1`) on the final commit: <result>.
- [ ] Every criterion above has proof that exists on the current head.
- [ ] Checked the "Rules that must not break" in CLAUDE.md.
- [ ] Found and fixed: <what the self-review caught, or "nothing">.

## Not checked

<anything not checked, and why>

## What to look for

<where to go, what to tap, what should happen; or "Nothing on screen changes">
