# Epic 2: The Loss

Stories for [epics.md](epics.md). When a story is built, its task file points at this file.

A player goes through the miscarriage with no warning, skip, or retry, sits in the quiet car in the rain, and returns to a House in grief. Write this chapter's words in the same week as the numb stretch in Epic 3. The run is a flat tiled path. Leaving in the middle starts the chapter over.

### Story 2.1: Enter the loss with no warning

As a player,
I want the miscarriage chapter to start from an ordinary tap,
So that I am in the run before I understand what it is.

**Acceptance Criteria:**

**Given** I am in the House after The Partner
**When** I tap this chapter's object
**Then** the House steps aside and the run starts
**And** there is no warning, no skip, and no title card

**Given** the run has just started
**When** I look
**Then** the path is clear and the picture is sunny
**And** the House overlay is gone

**Given** the chapter loads
**When** its look comes up
**Then** it uses the look slot from the House, including a gray drain the chapter can fill in
**And** it does not use Godot CompositorEffects

**Given** I leave during the run, by closing the tab or by leaving to the title
**When** I open the game again
**Then** this chapter starts from the first beat
**And** no save was written in the middle of the run

### Story 2.2: Run a path that fails anyway

As a player,
I want to run the hopeful path until it falls apart,
So that the loss happens during the play, even when I do everything right.

**Acceptance Criteria:**

**Given** the run is underway
**When** I play the opening stretch
**Then** the couple is planning and dreaming, and the UI does not label that beat
**And** this chapter's score is playing

**Given** the run continues
**When** the path starts to fail
**Then** I meet a fixed sequence of authored obstacles on a tiled path
**And** the sequence is not an open-ended random generator

**Given** I stumble on an obstacle
**When** the run reacts
**Then** the chapter does not end, and I am not offered a retry
**And** the run still continues toward the same ending

**Given** I play the run without a stumble
**When** I reach the end
**Then** the runner still fades
**And** the pacing has moved through euphoria, confusion, panic, and silence

**Given** the fade has happened
**When** the chapter would otherwise offer another try
**Then** there is no "Chapter failed. Try again?" and no skip

**Given** reduced motion is on
**When** the path fails and the runner fades
**Then** there is no hit-shake and no failure celebration

**Given** a phone-width browser
**When** I play the run
**Then** I can finish it in one sitting of about 10–15 minutes

### Story 2.3: Sit in the quiet car

As a player,
I want to sit with the rain after the run,
So that the loss can be quiet.

**Acceptance Criteria:**

**Given** the runner has faded
**When** the next beat starts
**Then** we are in the car and the sound is rain

**Given** the car beat is playing
**When** I listen for a line
**Then** no one speaks
**And** there is no subtitle, no objective, and no choice of what to say

**Given** the car beat is playing
**When** I tap a view
**Then** I can look
**And** the chapter display stays hidden, and there is no skip

### Story 2.4: Return to a House in grief

As a player,
I want to come back to the House after the loss,
So that the rooms show the grief and the story has moved on.

**Acceptance Criteria:**

**Given** the car beat has finished
**When** I am back in the House
**Then** the chapter reports that it finished, and the core turns that into the loss and the House's grief
**And** that is the only ending, and finishing is what lets the story move on

**Given** I am back in the House
**When** I look around
**Then** the House reads grief for every player, the crib is put away, and boxes are out
**And** no personal keepsake appears for how I ran

**Given** I tap the journal
**When** the new entry opens
**Then** the words are the same for every player
**And** the page is dated for month 2

**Given** I am back in the House
**When** I listen
**Then** the House sound is back

**Given** the chapter has finished
**When** the game saves
**Then** the save is written between chapters and includes the loss
