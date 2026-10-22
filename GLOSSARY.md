# Threshold

A narrative anthology game about becoming a father: seven short chapters in different genres, joined by a House that changes with the story. This glossary picks one name for each concept so docs, tickets and code all use the same words.

## Chapters

Each chapter is named for its archetype. The story beat in brackets is a description, not a second name.

**The Partner** (the Spark):
Rhythm chapter about trying to conceive naturally; ends on a positive test.
_Avoid_: The Spark in the New House (that was the old Epic 1 name)

**The Protector** (the Loss):
Runner chapter in which the miscarriage happens during play, whatever the player does.
_Avoid_: The Loss as a chapter name, runner chapter

**The Novice** (the Long Haul):
WarioWare-style chapter covering six months of IVF; ends on a positive test.
_Avoid_: The Long Haul, The Science, IVF chapter

**The Provider** (the Cost):
Paperwork-desk chapter about medical bills for the pregnancy.
_Avoid_: The Cost, bureaucracy chapter, deckbuilder

**The Tuner**:
Knob-and-waveform chapter about hearing the baby through monitor static.
_Avoid_: Hear Them, The Outsider

**The Anchor**:
Balance chapter about carrying a heavy, fragile load late in the pregnancy.
_Avoid_: Carry the Weight, The Role Model

**The Mourner**:
Unpacking chapter about putting away the grief and the old life to make room.
_Avoid_: Make Space, The Nesting

**The Arrival**:
The ending: the Tuner's knobs to hear the cry, the Partner's rhythm to hold the hand, then the House.
_Avoid_: The Ending, credits

**Chapter**:
One of the eight playable pieces above, each 10–15 minutes in v1.
_Avoid_: minigame (fine in old docs), level, epic

## The House and story

**The New House** (the House):
The persistent 3D hub the player returns to between chapters; it changes after every chapter.
_Avoid_: hub world, apartment, calendar

**Viewpoint**:
Any fixed camera shot in the House: a doorway view, a wall view or a close-up ([ADR-0008](docs/adr/0008-house-doorway-and-wall-views-close-ups.md)).
_Avoid_: waypoint, node, hotspot

**Doorway view**:
The view from a room's doorway looking into the whole room; where tapping a doorway takes you.
_Avoid_: entrance shot, establishing shot

**Wall view**:
A view framed on one wall or corner of a room, from the middle of it; reached by tapping that wall or corner.
_Avoid_: angle, camera position

**Close-up**:
The close view of one object, reached by tapping it; tapping the object again does its one action.
_Avoid_: inspect mode, zoom

**House object**:
An object in the House that can be looked at and acted on but doesn't start a chapter; never required, scored or saved.
_Avoid_: collectible, interactable (code name only), clue

**Story beat**:
A short first-person narrative scene in the House between chapters.
_Avoid_: Story Sequence (fine in old docs), cutscene

**Chapter object**:
The object in the House that starts the next chapter when tapped.
_Avoid_: Trigger, MinigameTrigger (code name only)

**House mood**:
How the House looks and sounds after a given chapter (warm, grieving, and so on).
_Avoid_: hub state

**Finished-chapter list**:
The ordered list of chapters the player has completed; the only story state that gets saved.
_Avoid_: flags, checkpoint

**Core table**:
The one lookup that turns the finished-chapter list into story facts, House mood, House objects and journal entries.
_Avoid_: result handler

**Stoic / Vulnerable answer**:
The closed-off or open line the player picks in some story beats; it changes spoken words and journal wording only.
_Avoid_: dialogue choice, branch

**Dad's Journal**:
The journal object in the House; one entry per finished chapter.
_Avoid_: diary, log

**Fail-forward**:
Failing inside a chapter never stops the story; every chapter reaches its one result.
_Avoid_: game over, retry

## Planning

**Milestone**:
A stage of the build in [docs/roadmap.md](docs/roadmap.md): M0 Setup, M1 Spark to Silence, M2 The Whole Story Rough, M3+ Chapter depth, Final Polish & Ship.
_Avoid_: epic, sprint, phase

**v1 / Later**:
Whether a feature is in the first full release, per [docs/scope.md](docs/scope.md).
_Avoid_: MVP, v2 (until v1 ships)
