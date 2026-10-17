# Epic 5: Hear Them

Stories for [requirements.md](../requirements.md). When a story is built, its task file points at this file.

> **2026-10-17:** Reference acceptance criteria for this chapter, copied from BMAD. They are not the build plan: build order is in [roadmap.md](../../roadmap.md), v1 scope in [scope.md](../../scope.md), and work is tracked in Linear. Lines changed to match later decisions are marked _(updated 2026-10-17)_.

A player turns through the static until the baby comes through. Two knobs, no wrong popup, one cleared picture. Leaving in the middle starts the chapter over.

### Story 5.1: Turn through the static

As a player,
I want to turn knobs until a waveform moves,
So that finding the baby is something I do by ear and by hand.

**Acceptance Criteria:**

**Given** I tap this chapter's object
**When** the chapter starts
**Then** the House overlay is gone and I have two knobs
**And** each knob is at least 44px, and dragging it changes the waveform

**Given** a knob is on screen
**When** I look for a label or a tooltip
**Then** the waveform is the only reading

**Given** the knobs are off the signal
**When** I listen and look
**Then** the static stays, and there is no "wrong" popup

**Given** the chapter loads
**When** its look comes up
**Then** the picture is grainy and broken up, on the House look slot
**And** it does not use Godot CompositorEffects

**Given** I leave during the chapter
**When** I open the game again
**Then** this chapter starts from the first beat
**And** no save was written in the middle

### Story 5.2: Hear the baby come through

As a player,
I want the static to clear when I find the signal,
So that the picture of the baby is the reward.

**Acceptance Criteria:**

**Given** I bring the knobs onto the signal
**When** they are close enough
**Then** the static clears and the picture comes through
**And** that is the only ending

**Given** I keep missing the signal
**When** I continue to try
**Then** the chapter can still be finished
**And** there is still no wrong popup and no second ending

**Given** a phone-width browser
**When** I play the chapter
**Then** I can finish it in about 10–15 minutes
**And** this chapter's score is playing while I search

**Given** the picture has come through
**When** I am back in the House
**Then** the chapter reports that it finished, and the core turns that into one story fact and one House mood
**And** the House has changed in the same way for every player, and no personal keepsake appears

**Given** I tap the journal
**When** the new entry opens
**Then** the words are the same for every player
**And** the page sits in months 11–13

**Given** the chapter has finished
**When** the game saves
**Then** the save is written between chapters
