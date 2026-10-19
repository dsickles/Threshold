<!-- Fill every section. A PR stays in draft until the "Acceptance criteria" table is complete and the self-review is done. See docs/agents/pull-requests.md. -->

Ticket: DAS-<n> (<Linear link>)

Before: <what a player or Dan sees today, in plain words>

After: <what they will see once this merges>

How: <a short paragraph on the approach>

## Acceptance criteria

Every criterion from the Linear ticket, copied word for word, in the ticket's order. One row each; none left out.

| # | Criterion (from the ticket) | Status | Proof |
|---|---|---|---|
| 1 | <copied text> | Met | `game/tests/test_x.gd` `test_name`; CI run <link> on `<head sha>` |
| 2 | <copied text> | Needs Dan's device | What Dan should do: <where to go, what to tap, what should happen> |

Status is one of **Met**, **Needs Dan's device** or **Not met**. Proof is a test name, a `file:line`, or a CI run on the current head. "Needs Dan's device" waits for Dan and is never skipped.

## Tests changed

Every existing test this PR edits or deletes, and why. Write "None" if none. Any removed assert, wider tolerance or skip is listed here.

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
