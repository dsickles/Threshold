# Pull requests

How every Threshold PR is opened and made ready. CLAUDE.md points here.

## Draft first

Open each PR as a **draft**. It leaves draft (is marked "Ready for review") only when all of the following are true. Hopper reviews once the ticket reaches In Review, which happens only when the PR leaves draft (see "Linear status"), so this is the line between "still working" and "check my claim".

0. **The Linear ticket id comes first.** The body's first line after the attribution block is `Ticket: DAS-<n>` with its link, so reviewers pull the right ticket's criteria.
1. **Every acceptance criterion is in the PR body with its proof.** Copy each criterion from the Linear ticket word for word, in order, into the "Acceptance criteria" table in [the PR template](../../.github/pull_request_template.md). None is left out, merged or reworded.
2. **Each criterion has a status and proof.**
   - **Met:** a test name (file and test function), a `file:line`, or a CI run on the current head commit. "Tests pass" on its own is not proof; name the test that shows this criterion.
   - **Needs Dan's device:** something only a person can check (feel, sound on a real phone, Safari on the iPhone). Write exactly what Dan should do and what should happen. This waits for Dan; it is never skipped, deferred or marked "not tested".
   - **Not met:** say why. A PR with a Not met row stays in draft unless Dan agreed to it in the thread or on the ticket; link that.
3. **Tests that changed are listed.** Any existing test edited or deleted, any removed assert, wider tolerance or skip, goes under "Tests changed" with the reason.
4. **A self-review pass is done.** Before leaving draft, reread the whole diff against the ticket (not against your own plan), as if you were a reviewer seeing it cold. Run the repo's checks on the final commit, confirm each proof exists on that commit, and check CLAUDE.md's "Rules that must not break". Fix what you find, then record it in the "Self-review" section.
5. **CI is green on the latest commit.** The proof column points at that run, not an older one.

If a later push changes what a criterion depends on, update its row before asking for another review.

## Linear status

Move the ticket to **In Review** only when the PR leaves draft, never while it is still a draft. Hopper starts her review when a ticket reaches In Review, so moving it early makes her review unfinished work.

## Reviews

Hopper (an outside review bot) reviews every PR in Dan's repos, posting from Dan's account under a "Hopper review" heading. She checks the acceptance criteria table and test list first, then reads the code on her own for bugs and side effects outside the criteria. On every later push she rechecks the whole table and test list, since a new commit can break a criterion that was met before.

Her required changes are handled like any reviewer's: fix them or reply on the thread saying why not. Her "not blocking" notes do not hold up a merge. Merging stays with Dan.

Split of work: the thread proves everything a machine can (tests, error check, green CI on the latest commit, self-review). Hopper is the skeptic. Dan only checks what needs his hands on a device.

## Keeping this in place

The `implement` skill is copied from an outside source and `npx skills@latest update` overwrites it. After an update, check that its last steps still point here, and add the line back if not.
