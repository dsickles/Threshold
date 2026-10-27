# Pull requests

How every Threshold PR is opened and made ready. CLAUDE.md points here.

## Draft first

Open each PR as a **draft**. It leaves draft (is marked "Ready for review") only when all of the following are true. Hopper reviews once the ticket reaches In Review, which happens only when the PR leaves draft (see "Linear status"), so this is the line between "still working" and "check my claim".

0. **The Linear ticket id comes first.** The body's first line is `Ticket: DAS-<n>` with its link (in a Claude Project thread, the first line after the required two-line attribution block), so reviewers pull the right ticket's criteria. There is no PR without a ticket. Before the first commit, check there is a Linear ticket for the work; if the thread started without one (research, a quick fix, a decision to record), create it first, then branch. Without a ticket nothing moves to In Review, so Hopper never reviews.
1. **Every acceptance criterion is in the PR body with its proof.** Copy each criterion from the Linear ticket word for word, in order, into the "Acceptance criteria" table in [the PR template](../../.github/pull_request_template.md). None is left out, merged or reworded.
2. **Each criterion has a status and proof.**
   - **Met:** a test name (file and test function), a `file:line`, or a CI run on the current head commit. "Tests pass" on its own is not proof; name the test that shows this criterion.
   - **Needs Dan's device:** something only a person can check (feel, sound on a real phone, Safari on the iPhone). Write exactly what Dan should do and what should happen. This waits for Dan; it is never skipped, deferred or marked "not tested".
   - **Accepted by Dan:** the criterion is not met, but Dan signed off on that. Link his decision: a Linear comment by Dan (D S), a message Dan wrote in the project thread, or an ADR Dan signed off. Never a GitHub comment: Claude, Dan and Hopper all post as `dsickles`, so a GitHub comment can't show Dan made the call. Hopper marks such rows Unproven, which is a required change.
   - **Not met:** say why. A PR with a Not met row stays in draft.
3. **Tests that changed are listed.** Any existing test edited or deleted, any removed assert, wider tolerance, skip or test that no longer runs, goes under "Tests changed" with the reason.
4. **A self-review pass is done.** Before leaving draft, reread the whole diff against the ticket (not against your own plan), as if you were a reviewer seeing it cold. Run the repo's checks on the final commit, confirm each proof exists on that commit, and check CLAUDE.md's "Rules that must not break". Fix what you find, then record it in the "Self-review" section.
5. **CI is green on the latest commit.** The proof column points at that run, not an older one, and at tests CI actually runs (Hopper checks the test count in the log).
6. **A review build is on itch.io.** The "Review build" GitHub check (`.github/workflows/review-build.yml`) does this, not the thread: on every push to a non-draft PR that changes `game/` or `tools/`, it uploads the head commit to the private review page (https://dsickles.itch.io/threshold-review) and rewrites the `itch.io build:` line in the PR body to `itch.io build: <short sha>, threshold-review`. It never touches the live page (https://dsickles.itch.io/threshold), so it needs no "upload" from Dan. Leave the template's `itch.io build:` line in place for it to fill, or write `itch.io build: none` for a PR with no game change. Wait for that check to pass before moving the ticket to In Review; a pass always means a build was uploaded. A push that changes only docs doesn't trigger a new build, so the sha in the body stays on the last game change and Hopper marks the preview "not viewed for this head"; that's expected. Hopper smoke-tests the build only when that sha matches the head commit; otherwise she reviews the code only and notes the preview wasn't viewed. Hopper loads that build and runs the flows the PR touches; a failure there is a required change. She can't hear sound, use real touch or judge rhythm timing to the frame, so those stay "Needs Dan's device" rows.
7. **The other template sections are filled in.** "Depends on and merge order" (other open PRs this one needs or overlaps, which merges first, and which PR removes any code the two duplicate), "Out-of-scope changes" (anything not asked for by the ticket, or "None"), and "Local checks" (pasted output of any check that only ran on a machine, not in CI).

If a later push changes what a criterion depends on, update its row before asking for another review.

Rows marked "Needs Dan's device" don't hold up Hopper's approval: she approves the code and lists them as waiting on Dan. Dan records each result on the PR; his device test and merge are the sign-off.

## Linear status

Hopper's review starts only when a ticket's status changes to **In Review**.

- Move the ticket to In Review only when the PR leaves draft, never while it is still a draft.
- After each round of fixes (for Hopper or anyone else), once CI (including "Review build") is green on the new commit, move the ticket back to **In Progress** and then to **In Review** again. Without that status change Hopper never sees the fixes.
- When Dan merges the PR, the thread that owns it moves the ticket to **Done**. Hopper never marks Done.

## Reviews

Hopper (an outside review bot) reviews every PR in Dan's repos, posting from Dan's account under a "Hopper review" heading. She checks the acceptance criteria table and test list first, then reads the code on her own for bugs and side effects outside the criteria. On every later push she rechecks the whole table and test list, since a new commit can break a criterion that was met before.

Her required changes are handled like any reviewer's: fix them or reply on the thread saying why not. Her "not blocking" notes do not hold up a merge. Merging stays with Dan.

Split of work: the thread proves everything a machine can (tests, error check, green CI on the latest commit, self-review). Hopper is the skeptic. Dan only checks what needs his hands on a device.

## Telling Hopper when the flow changes

Hopper doesn't read this repo's rules on her own. Whenever a change alters how PRs, reviews, review builds or Linear statuses work (this file, the PR template, the "Pull requests" section of CLAUDE.md, or `.github/workflows/`), the thread's reply to Dan ends with a copy-and-paste prompt for Hopper in a code block: what changed, what she should do differently, and what stays the same. Dan sends it to her.

## Keeping this in place

The `implement` skill is copied from an outside source and `npx skills@latest update` overwrites it. After an update, check that its last steps still point here, and add the line back if not.
