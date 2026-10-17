# Epic 1: The Spark in the New House

Stories for [epics.md](epics.md). When a story is built, its task file points at this file.

A player can walk the House in a browser, play The Partner, return to a House that has changed, and come back later to that same House. The rough chapter and the save come before the menus. The House's mood comes from ordinary fog, lamp light, color, corner shading, and sound. Volumetric fog is a PC extra and the House must still read without it.

### Story 1.1: Walk the new House

As a player,
I want to walk the empty House by tapping,
So that I can look around before anything else asks me to play.

**Acceptance Criteria:**

**Given** a new Godot 4 project in git, using GDScript, with `_core/`, `assets/`, `scenes/hub/`, `scenes/minigames/`, `scenes/ui/`, and `scripts/`
**When** I open the game in a browser
**Then** I am in the New House, and it reads empty and cold
**And** the House is lit by lamps and ordinary fog, and it still reads if volumetric fog is unavailable

**Given** I am in the House
**When** I tap the floor
**Then** Leo walks to that point
**And** a tap on a view target turns the view, the hit comes from the pointer, and a click is the same as a tap

**Given** a door, a chapter object, or the journal is in reach
**When** I can tap it
**Then** it highlights, and the highlight turns off when nothing is in reach
**And** there is no crosshair, no quest marker, and no prompt plaque

**Given** the House is up
**When** I listen
**Then** the fridge hum is a recorded loop whose volume and pitch can change
**And** keyboard keys, a virtual stick, and mouse-look are not ways to move

### Story 1.2: Play The Partner

As a player,
I want to play the rhythm chapter and return to a House that has changed,
So that the first chapter is playable before the menus are polished.

**Acceptance Criteria:**

**Given** I am in the House
**When** I tap The Partner's object
**Then** the House steps aside, the chapter starts, and the House overlay is gone

**Given** The Partner is playing
**When** I tap with Maya's heartbeat or voice
**Then** I see Perfect, Good, or Miss near the hit
**And** a miss plays as awkward laughter, the song keeps going, and there is no grade screen

**Given** I reach the end, whether or not I missed
**When** the song finishes
**Then** the result is a positive pregnancy test, and that is the only ending
**And** the chapter reports that it finished, and the core turns that into one story fact and one House mood

**Given** the chapter has finished
**When** I am back in the House
**Then** the House has warmed in the same way for every player
**And** no personal keepsake appears for a better performance

**Given** a phone browser
**When** I play The Partner on a phone
**Then** the hits line up with the sound I actually hear

### Story 1.3: Come back to the House

As a player,
I want the game to remember the House after a chapter, and to forget a chapter I left in the middle,
So that I can close the tab and return to the same place in the story.

**Acceptance Criteria:**

**Given** I have finished The Partner and I am back in the House
**When** the game saves
**Then** the save is written only then, between chapters
**And** the save keeps what has already happened separate from what is true now

**Given** a save that records a past miscarriage and a current pregnancy
**When** the game loads it
**Then** the load succeeds and both facts remain

**Given** I close the tab during The Partner
**When** I open the game again
**Then** The Partner starts from the first beat
**And** hiding the tab does not write a save

**Given** the browser will not keep a save, such as private browsing or a frame with storage blocked
**When** a save is attempted
**Then** I see "Couldn't save." and play continues
**And** the last good between-chapter save still loads when one exists

**Given** a save from an older test build that this build cannot read
**When** the game tries to open it
**Then** the open fails, and Play still starts a new visit to the House

### Story 1.4: Start from the title and pause

As a player,
I want a title and a pause menu,
So that I can start, continue, or leave without losing my place in the House.

**Acceptance Criteria:**

**Given** there is no save
**When** the title appears
**Then** I see Play and Settings, Continue is absent, and Play is the focused control
**And** Play starts a new visit to the House

**Given** a between-chapter save exists
**When** the title appears
**Then** Continue is shown and returns me to that House

**Given** I am playing
**When** I pause
**Then** one panel shows Resume, Settings, and back to title, over the scene, and it replaces whatever else was up
**And** Resume is focused, Enter activates the focused control, and a 2px ring shows the focus

**Given** I am in a chapter
**When** I choose back to title
**Then** a second tap asks "Leave this?" before I leave

**Given** the browser tab is about to hide
**When** the tab loses focus
**Then** the game pauses before the browser freezes it
**And** the pause does not save, and returning to the same tab resumes where I was

### Story 1.5: Change settings

As a player,
I want subtitles, reduced motion, and a quality setting that changes the House,
So that I can play the same game on a phone browser and on a larger window.

**Acceptance Criteria:**

**Given** I am on the title or on pause
**When** I open Settings
**Then** I see subtitles, reduced motion, and quality, one level deep, and I can get back without a broken stack

**Given** a new game
**When** I have not changed Settings
**Then** subtitles are on

**Given** reduced motion is on
**When** the House or The Partner plays
**Then** camera sway and hit-shake are gone

**Given** the game is starting
**When** the device check runs
**Then** it picks a quality, and the quality control in Settings changes something I can see in the House, such as corner shading or ordinary fog

**Given** a phone-width window and a wide window
**When** I look at the title, pause, or Settings
**Then** the menu is one column, about 480px, with at least a 24px inset and 44px targets
**And** a wide window gives the extra room to the House

### Story 1.6: Choose one line in the opening

As a player,
I want one story beat in the House where I can answer in a closed-off way or an open way,
So that the couple can sound like themselves before The Partner.

**Acceptance Criteria:**

**Given** I am walking the House
**When** I enter the opening story beat
**Then** I still walk and look by tapping, subtitles can show, and the chapter display stays hidden

**Given** the beat offers the line
**When** I choose the closed-off reply or the open reply
**Then** the spoken words differ
**And** the story facts, the House objects, and the next step into The Partner stay the same

**Given** I have heard the beat once
**When** I pass that spot again in the same visit
**Then** it does not play a second time

### Story 1.7: Read the first journal page

As a player,
I want to pick up Dad's Journal,
So that the House holds a record of the chapter I finished.

**Acceptance Criteria:**

**Given** I have not finished a chapter
**When** I tap the journal
**Then** I see a blank dated page and no writing prompt

**Given** I have finished The Partner
**When** I tap the journal
**Then** the first entry is there, in the same words for every player
**And** the closed-off reply and the open reply from the opening both leave that same entry

**Given** the journal is open
**When** I look at the page
**Then** it uses the display serif on the raised surface, and the dialogue choice does not change the page's look

### Story 1.8: Swap the chapter look

As a player,
I want The Partner to have its own look and the House to return to its own look when the chapter ends,
So that later chapters can change the picture without rebuilding the House.

**Acceptance Criteria:**

**Given** The Partner loads
**When** the chapter starts
**Then** it sets the current look, including one empty full-screen filter layer that a chapter can fill in
**And** the setup does not use Godot CompositorEffects

**Given** The Partner ends
**When** I am back in the House
**Then** the House look is back, with its own lighting and ordinary fog
**And** the House still reads with volumetric fog left off

**Given** I change the quality setting
**When** I return to the House
**Then** the visible quality change from Story 1.5 is still there
