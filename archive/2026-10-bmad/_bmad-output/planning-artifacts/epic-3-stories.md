# Epic 3: The Long Haul

Stories for [epics.md](epics.md). When a story is built, its task file points at this file.

A player crosses the numb stretch after the loss, lives through six months of treatment, helps with the shot, and ends on a positive test. The first batch is the framework plus three small games. This chapter does not replay The Partner. Write the numb stretch in the same week as the quiet car in Epic 2. Leaving in the middle starts the chapter over.

### Story 3.1: Cross the numb stretch

As a player,
I want the stretch after the loss to begin quiet and gray,
So that the humor arrives slowly instead of all at once.

**Acceptance Criteria:**

**Given** the loss is already in the past
**When** I tap this chapter's object
**Then** the House steps aside and the chapter starts slow, quiet, and gray
**And** there is no warning and no shout yet

**Given** the chapter loads
**When** its look comes up
**Then** it uses the look slot from the House
**And** it does not use Godot CompositorEffects

**Given** I leave during the chapter
**When** I open the game again
**Then** this chapter starts from the first beat
**And** no save was written in the middle

### Story 3.2: Play three small games

As a player,
I want to play three short games about the treatment,
So that the amateur science is something I do with my hands.

**Acceptance Criteria:**

**Given** the small-game set is running
**When** I play the first batch
**Then** I can finish "OPEN THE BOX!", "MIX THE POWDER!", and "INJECT THE BUTT!"
**And** "DON'T FAINT!" is outside this batch

**Given** a small game is on screen
**When** it asks me to act
**Then** it is one gesture and a short shout
**And** the shout leaves when the gesture is done

**Given** I am still in the early stretch
**When** a small game starts
**Then** it is slow and quiet
**And** the shout style stays inside this chapter

### Story 3.3: Live the six months

As a player,
I want the small games to carry me through six months,
So that the treatment feels long, then frantic, then exhausting.

**Acceptance Criteria:**

**Given** the montage is playing
**When** I am in the early months
**Then** the inputs feel slow and confused

**Given** the montage is playing
**When** I am in the middle months
**Then** the games run faster and ask for more skill
**And** the picture has become saturated and frantic

**Given** the montage is playing
**When** I am in the last stretch
**Then** an input sometimes does not take

**Given** reduced motion is on
**When** the picture gains color
**Then** the change is a cut or a slow fade

**Given** a phone-width browser
**When** I play the montage
**Then** I can finish this chapter's play in about 10–15 minutes
**And** the UI does not explain the joke

### Story 3.4: Help with the shot

As a player,
I want Maya to ask me to help with the shot,
So that I can be afraid of hurting her and still be in the room.

**Acceptance Criteria:**

**Given** I am in the treatment stretch
**When** the shot beat starts
**Then** Maya asks Leo to help with her IVF shot, and he is afraid of hurting her
**And** I still walk and look by tapping, subtitles can show, and the chapter display stays hidden

**Given** the beat offers a line
**When** I answer in a closed-off way or an open way
**Then** the spoken words can differ
**And** the shot still happens, and the journal words stay the same

**Given** the beat is playing
**When** I look for a label on the awkwardness
**Then** the UI does not add one

### Story 3.5: End on a positive test

As a player,
I want the long stretch to end on a positive test,
So that the story can move on without playing The Partner again.

**Acceptance Criteria:**

**Given** I reach the end of the six months
**When** the chapter finishes
**Then** the result is a positive test after IVF
**And** the chapter does not replay The Partner

**Given** the chapter finishes
**When** control returns
**Then** the chapter reports that it finished, and the core turns that into the new pregnancy and one House mood
**And** the loss stays in the past, and that is the only ending

**Given** I am back in the House
**When** I look around
**Then** the House has changed in the same way for every player
**And** the small-game shout is gone, and no personal keepsake appears

**Given** I tap the journal
**When** the new entry opens
**Then** the words are the same for every player
**And** the page sits in months 3–9

**Given** the chapter has finished and the loss is already saved
**When** the game saves
**Then** the save keeps the loss in the past and the pregnancy now
**And** loading that save keeps both
