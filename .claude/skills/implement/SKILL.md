---
name: implement
description: "Implement a piece of work based on a spec or set of tickets. Use when the user says /implement <ticket>, or asks to implement or \"do\" a Linear ticket such as DAS-69."
---

Implement the work described by the user in the spec or tickets.

If the user passes a ticket reference, fetch it from the issue tracker and state its title before starting. If the reference is ambiguous, ask.

Call the Skill tool with "tdd" where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, call the Skill tool with "code-review" to review the work.

Commit your work to the current branch.

If you open a pull request, follow `docs/agents/pull-requests.md`: open it as a draft, and before it leaves draft list every acceptance criterion from the ticket in the PR body with its proof, and do a self-review pass.
