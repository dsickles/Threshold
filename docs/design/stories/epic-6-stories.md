# Epic 6: Make Space

Stories for [requirements.md](../requirements.md). When a story is built, its task file points at this file.

> **2026-10-17:** Reference acceptance criteria for this chapter, copied from BMAD. They are not the build plan: build order is in [roadmap.md](../../roadmap.md), v1 scope in [scope.md](../../scope.md), and work is tracked in Linear. Lines changed to match later decisions are marked _(updated 2026-10-17)_.

A player puts away the grief and the clutter from before the baby. What remains in the House is the same for every player. The score is acoustic or piano. Leaving in the middle starts the chapter over.

### Story 6.1: Pick up and put down

As a player,
I want to pick an item up and set it down,
So that making space is a series of small placements.

**Acceptance Criteria:**

**Given** I tap this chapter's object
**When** the chapter starts
**Then** the House overlay is gone and I can pick an item up

**Given** I am holding an item
**When** I drag it
**Then** I see a ghost of it
**And** I do not see an inventory grid

**Given** I drop an item where it cannot stay
**When** I let go
**Then** it snaps back
**And** the rejection is shown by more than color

**Given** the chapter loads
**When** its look comes up
**Then** it uses the look slot from the House
**And** it does not use Godot CompositorEffects

**Given** I leave during the chapter
**When** I open the game again
**Then** this chapter starts from the first item
**And** no save was written in the middle

### Story 6.2: Clear out the old life

As a player,
I want to put away the grief and the clutter from before the baby,
So that the room is being made ready.

**Acceptance Criteria:**

**Given** the chapter is underway
**When** I handle the items
**Then** I am packing away the miscarriage and the hobbies, furniture, and single life from before the baby

**Given** I place an item where it can stay
**When** I let go
**Then** the placement is soft, and I hear a household sound

**Given** I am unpacking
**When** I listen
**Then** the score is acoustic or piano
**And** the UI does not label the feeling of letting go

**Given** a phone-width browser
**When** I play the chapter
**Then** I can finish it in about 10–15 minutes

### Story 6.3: Leave the same House

As a player,
I want the House to show the same room after I am done,
So that every player comes back to the same home.

**Acceptance Criteria:**

**Given** I finish putting things away
**When** I am back in the House
**Then** the chapter reports that it finished, and the core turns that into one story fact and one House mood
**And** what was put away and what remains are the same for every player

**Given** I dropped items in a different order than another player
**When** we are both back in the House
**Then** the House shows the same layout

**Given** I tap the journal
**When** the new entry opens
**Then** the words are the same for every player
**And** the page is dated for month 17 _(updated 2026-10-25, ADR-0009)_, and no personal keepsake appears

**Given** the chapter has finished
**When** the game saves
**Then** the save is written between chapters
