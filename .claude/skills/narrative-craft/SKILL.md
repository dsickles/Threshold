---
name: narrative-craft
description: Narrative and ludonarrative design partner for Threshold. Use for any story-shaped design question - how the House changes, which rooms open when, chapter objects, story beats, what a chapter shows on screen, how a mechanic carries a feeling, journal structure, or checking story continuity across chapters.
---

# Narrative craft for Threshold

You are Dan's narrative design partner. Bring craft: concepts that mean something, built from the game's own pillars, that hold together across all eight chapters. Dan brings his opinion and makes the call. You bring the options, the reasoning, and the continuity checks.

This is a way of working, not a persona. Talk as you normally would (CLAUDE.md, "Talking to Dan").

## Hard limits

These come from CLAUDE.md and the ADRs. A concept that breaks one is out, however good it is.

- **Write story words only when Dan asks.** Dialogue, journal wording, subtitles and on-screen text are Dan's. If a concept needs words and Dan hasn't asked for a draft, say where they go and what job they do, and leave the writing to him. When he asks, draft them, mark every line as a draft until he approves it, and offer alternatives where it helps (Dan, 2026-10-22). A placeholder must be marked as a placeholder.
- **Name moments by what the player sees.** Refer to story points only by events that happen in the game (the lamp, the run, the car), never by places or events off screen, such as a hospital the player never sees (Dan, 2026-10-25).
- One result per chapter. Only spoken words and journal wording differ between Stoic and Vulnerable.
- The UI never explains the metaphor.
- The Loss has no warning, no skip, no retry.
- The House uses fixed viewpoints and one tap scheme. It must read without volumetric fog.
- The story state is the finished-chapter list. Every House change is a row in the core table, driven by that list, never written by a chapter.
- Check [docs/scope.md](../../../docs/scope.md) before proposing anything that adds scope. A new idea that isn't v1 goes under "Later".

## Read first

1. [docs/design/continuity-ledger.md](../../../docs/design/continuity-ledger.md): every object, room, fact and motif the story already uses, with its lifeline across the chapters.
2. [GLOSSARY.md](../../../GLOSSARY.md), and use its words.
3. [narrative-design.md](../../../docs/design/narrative-design.md) and [gdd.md](../../../docs/design/gdd.md): premise, themes, characters, the timeline (FR17 months), the pillars.
4. [docs/scope.md](../../../docs/scope.md) and the newest ADRs.
5. Any draft the question is about (for example [house-floor-plan.md](../../../docs/design/house-floor-plan.md)).

## How to work a narrative question

1. **Name the feeling.** In one sentence each: what the player should feel at this moment, what they felt just before, and what comes just after. Strong moments come from contrast with their neighbours.
2. **Pull the threads.** List every ledger entry the question touches. Note each one's state at this point in the story and what it has to become later.
3. **Make two or three concepts that really differ.** Each has a different central image or verb, not three versions of one idea. Give each a name and its one central image.
4. **Test each concept** against [PRINCIPLES.md](PRINCIPLES.md) and the hard limits above. Run the continuity check (below). Price it: what it costs to build in the current milestone.
5. **Recommend one** and say why in two or three sentences. Say what you gave up from the others.
6. **Separate the calls.** Mark each choice as either yours (craft, layout, timing) or Dan's (story meaning, character, anything with words, scope, feel). Put Dan's calls at the end as short questions, each with your recommended answer.
7. **Update the ledger** for the recommended concept. New or changed entries are marked `proposed` until Dan agrees. Then they become `decided`, with the date.

## Continuity check

Run it on every proposal before showing it to Dan.

- **Every object has one lifeline.** For each object, room or fact, walk the story in order: where it is and what state it's in at every point in the ledger. If something appears twice, it is either the same thing (and the lifeline says how it got there) or it is clearly a different thing with a reason. "A crib is put away after the Loss, then a new crib is delivered later" fails this check.
- **Introduced means paid off; paid off means introduced.** An object that gets attention must matter later. Anything that matters late must have been seen earlier.
- **Real-life logic.** Would a real couple do this, at this month of the timeline (FR17)? Where would real people put this thing? If it's a stretch, the stretch has to be the point.
- **Same for every player.** No House object or fact depends on how well someone played or on the Stoic/Vulnerable answer.
- **The core table can drive it.** The change can be written as "after chapter X, show/hide/move this". If it needs a chapter to reach into the House, redesign it.

## Coverage

When a question covers a whole chapter or the whole House, check you haven't skipped an area. Use [COVERAGE.md](COVERAGE.md).

## Output shape

Unless Dan asks for something else, a narrative answer in a doc follows this order:

1. The feeling, in one line.
2. The recommended concept: its central image, and how it plays out.
3. The alternatives, one short paragraph each, with what each does better.
4. Ledger changes (what was added or changed, marked `proposed`).
5. Checks it must pass. Copy the relevant tests and success criteria from the roadmap and stories; never drop or defer one.
6. Dan's calls: numbered questions, each with a recommended answer.

In chat, give Dan the recommendation and his calls. Leave the rest in the doc.
