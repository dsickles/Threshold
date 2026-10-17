# Epic 4: The Cost

Stories for [epics.md](epics.md). When a story is built, its task file points at this file.

A player works the bills for that pregnancy, reads them in large type, stamps them on the desk, and still gets through when the due date runs out. This chapter does not replay conception. The score is synthwave. Leaving in the middle starts the chapter over.

### Story 4.1: Read a bill in large type

As a player,
I want to open a bill in large type,
So that I can read the paperwork on a phone.

**Acceptance Criteria:**

**Given** I tap this chapter's object
**When** the desk appears
**Then** the documents are pages on the desk, the House overlay is gone, and the score is synthwave
**And** the look is high-contrast black and white on the House look slot, with no Godot CompositorEffects

**Given** I tap a document
**When** the page can reflow
**Then** large type replaces the page
**And** dismissing it returns me to the desk

**Given** I tap a document
**When** the page cannot reflow
**Then** I stay on the desk and I see "can't enlarge this page."

**Given** the large-type page is up
**When** I look for a stamp
**Then** the stamps are on the desk

**Given** I leave during the chapter
**When** I open the game again
**Then** this chapter starts from the first bill
**And** no save was written in the middle

### Story 4.2: Stamp the desk

As a player,
I want to approve or deny a bill on the desk,
So that I can answer the paperwork with a stamp.

**Acceptance Criteria:**

**Given** a bill is on the desk
**When** I tap APPROVE or DENY
**Then** that word marks the paper, and I do not have to hold the tap
**And** I hear an ink thunk

**Given** I stamp a bill the wrong way
**When** the desk responds
**Then** the Bank Account number drops
**And** the drop is shown by the number and the track, not by color alone

**Given** I am at the desk
**When** I look at the top-start corner
**Then** Due Date and Bank Account are there, and each number is always visible
**And** empty corners stay empty

**Given** quality is on the low setting
**When** I look for what I can stamp
**Then** the outline on the stamps is still there

### Story 4.3: Work through the three acts

As a player,
I want to work invoices, then insurance, then the audit,
So that the bills become one story I have to untangle myself.

**Acceptance Criteria:**

**Given** I start the desk
**When** I move through the chapter
**Then** I play The Invoices, then The Insurance, then The Audit

**Given** I am in The Insurance
**When** I compare it with The Invoices
**Then** the bills are harder to read on the desk, and the large-type page is how I read them

**Given** a run of bills
**When** I read them in order
**Then** they follow one injury
**And** the UI never says the system is confusing

**Given** a phone-width browser
**When** I play the desk
**Then** I can finish it in about 10–15 minutes

### Story 4.4: Get through the due date

As a player,
I want the story to move on when the due date runs out,
So that the desk cannot trap me.

**Acceptance Criteria:**

**Given** the Due Date reaches zero
**When** the timer expires
**Then** the story moves on and the desk does not trap me
**And** the journal words are the same as a finished desk

**Given** I finish the bills or the timer expires
**When** I am back in the House
**Then** the chapter reports that it finished, and the core turns that into one story fact and one House mood
**And** the chapter does not replay conception, and that is the only ending

**Given** I am back in the House
**When** I look around and open the journal
**Then** the House has changed in the same way for every player, and the entry words are the same
**And** the page is dated for month 10, and no personal keepsake appears

**Given** the chapter has finished
**When** the game saves
**Then** the save is written between chapters
