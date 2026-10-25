# Epic 7: Carry the Weight

Stories for [requirements.md](../requirements.md). When a story is built, its task file points at this file.

> **2026-10-17:** Reference acceptance criteria for this chapter, copied from BMAD. They are not the build plan: build order is in [roadmap.md](../../roadmap.md), v1 scope in [scope.md](../../scope.md), and work is tracked in Linear. Lines changed to match later decisions are marked _(updated 2026-10-17)_.

A player carries the load with two hold zones, hears Maya, and can finish the chapter, including the crib with no instructions. This chapter is built after the others because physics in a phone browser is the risk. Leaving in the middle starts the chapter over.

### Story 7.1: Build the crib without instructions

As a player,
I want to be in the room while Leo builds the crib without instructions,
So that Maya's laugh can break the tension.

**Acceptance Criteria:**

**Given** I reach this beat in the House
**When** it starts
**Then** Leo is building the crib without instructions, and Maya laughs
**And** I still walk and look by tapping, subtitles can show, and the chapter display stays hidden

**Given** the beat offers a line
**When** I answer in a closed-off way or an open way
**Then** the spoken words can differ
**And** the laugh still happens, and the journal wording follows the answer _(updated 2026-10-17, ADR-0004)_

**Given** the beat is playing
**When** I look for a label on the laugh
**Then** the UI does not add one

### Story 7.2: Carry the load

As a player,
I want to keep a heavy, fragile load upright with two hold zones,
So that the weight is the play.

**Acceptance Criteria:**

**Given** I tap this chapter's object
**When** the carry starts
**Then** the House overlay is gone and I have a left hold zone and a right hold zone
**And** each zone is at least 44px, and they are the same on a phone and in a browser

**Given** the carry is playing
**When** I hold the left zone or the right zone
**Then** Leo leans that way
**And** there is no virtual stick, no trigger, and no stability meter

**Given** Leo is carrying the load
**When** the game keeps him upright
**Then** the correction is applied while the physics step runs
**And** a shiver can cover a visible jitter

**Given** the load touches the ground
**When** the run reacts
**Then** I stay in the chapter

**Given** the chapter loads
**When** its look comes up
**Then** it uses the look slot from the House
**And** it does not use Godot CompositorEffects

**Given** I leave during the carry
**When** I open the game again
**Then** this chapter starts from the first beat
**And** no save was written in the middle

### Story 7.3: Finish after the third fall

As a player,
I want Maya's voice after the third fall,
So that I can finish carrying the load.

**Acceptance Criteria:**

**Given** I have fallen fewer than three times
**When** I fall again
**Then** I am still in the same chapter, and Maya has not spoken yet

**Given** I fall a third time
**When** that fall lands
**Then** I hear Maya say "You've got this."
**And** I can finish the chapter, with no badge and no "Stability Assist ON."

**Given** reduced motion is on
**When** I fall
**Then** there is no hit-shake

**Given** a phone-width browser
**When** I play the carry
**Then** I can finish it in about 10–15 minutes
**And** this chapter's score is playing while I carry

**Given** I finish the carry
**When** I am back in the House
**Then** the chapter reports that it finished, and the core turns that into one story fact and one House mood
**And** the House has changed in the same way for every player, and no personal keepsake appears

**Given** I tap the journal
**When** the new entry opens
**Then** the words are the same for every player
**And** the page is dated for month 17 _(updated 2026-10-25, ADR-0009)_

**Given** the chapter has finished
**When** the game saves
**Then** the save is written between chapters
