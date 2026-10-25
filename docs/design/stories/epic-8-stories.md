# Epic 8: The Arrival

Stories for [requirements.md](../requirements.md). When a story is built, its task file points at this file.

> **2026-10-17:** Reference acceptance criteria for this chapter, copied from BMAD. They are not the build plan: build order is in [roadmap.md](../../roadmap.md), v1 scope in [scope.md](../../scope.md), and work is tracked in Linear. Lines changed to match later decisions are marked _(updated 2026-10-17)_.

A player hears the cry, holds the hand, and the House is the last room. The cry uses the knobs from Hear Them. The hand uses the rhythm from The Partner. A miss still moves the story on. This chapter does not own the word-count check. Leaving in the middle starts the ending over.

### Story 8.1: Hear the cry

As a player,
I want to tune a monitor until I hear the cry,
So that the baby arrives through the same knobs I already learned.

**Acceptance Criteria:**

**Given** I am late in the House
**When** I tap the ending's object
**Then** the ending starts and the House overlay is gone

**Given** the ending is playing
**When** I turn the knobs
**Then** I am tuning to hear the cry, with the same waveform and the same clear-the-static result as Hear Them
**And** there is no "wrong" popup and no legend

**Given** I leave during the ending
**When** I open the game again
**Then** the ending starts from the first beat
**And** no save was written in the middle

### Story 8.2: Hold the hand

As a player,
I want to tap in time to hold the hand,
So that the arrival uses the rhythm I already learned.

**Acceptance Criteria:**

**Given** I can hear the cry
**When** I tap with the rhythm
**Then** I see Perfect, Good, or Miss near the hit
**And** a miss still continues, and there is no grade screen

**Given** a phone browser
**When** I tap the rhythm
**Then** the hits line up with the sound I actually hear

**Given** the hand beat ends
**When** I look at how the baby was present
**Then** the cry and the hand were play

### Story 8.3: Stay in the House

As a player,
I want the House to be the last room,
So that the arrival ends where the story lives.

**Acceptance Criteria:**

**Given** the cry and the hand are done
**When** the ending finishes
**Then** I am in the House
**And** there is no credits menu and no game-over

**Given** the ending finishes, whether or not I missed
**When** control returns
**Then** the chapter reports that it finished, and the core turns that into the arrival and one House mood
**And** that is the only ending

**Given** I am in the House
**When** I look around and open the journal
**Then** the House has changed in the same way for every player, and the entry words are the same
**And** the page is dated for month 18 _(updated 2026-10-25, ADR-0009)_, and no personal keepsake appears

**Given** the ending has finished
**When** the game saves
**Then** the save is written between chapters
