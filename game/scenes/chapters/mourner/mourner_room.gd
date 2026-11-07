extends RefCounted
## The Mourner's room and its rules, apart from drawing and input, so tests
## can play it on a fake clock (DAS-136). Everything is in the room's own
## units: a ROOM_SIZE picture of the spare room seen from its doorway, which
## the chapter scales to fit the screen.
##
## Each thing has exactly one place, so the room ends the same for every
## player whatever order things go in (Story 6.3). Where each of Leo's old
## things goes (kept, stored or given away) is a PROPOSAL for Dan, as is the
## memory box going closed onto the high shelf (story-beats.md §7).
##
## Beats (story-beats.md §7): the door opens → Leo's old things, any order →
## the memory box, found under the boxes (the music thins) → the room empty,
## in good light → the baby monitor comes in → the crib comes in, the last
## placement → a held moment → done.

enum Stage { DOOR, OLD_THINGS, MEMORY_BOX, LIGHT, MONITOR, CRIB, ENDING, DONE }

const ROOM_SIZE := Vector2(1280.0, 720.0)
## Where the floor meets the back wall.
const FLOOR_Y := 470.0

## How long each timed beat lasts, in seconds.
const DOOR_TIME := 4.0
const LIGHT_TIME := 10.0
## How long something takes to come in through the door (the monitor, the crib).
const COME_IN_TIME := 2.5
## How long the memory box takes to come out from under the boxes, before it
## can be picked up.
const FOUND_TIME := 4.0
const ENDING_TIME := 10.0
## After this long without a placement, the next thing's place is shown.
const HINT_AFTER := 15.0
## How far outside a place a drop still counts, in room units.
const DROP_MARGIN := 40.0

## The places things can go. Each is at least 150 room units each way, so it
## stays at least 44 points on an upright phone (the smallest scale).
const PLACES := {
	&"storage": Rect2(20, 545, 230, 160),     # A storage tote, by the door: stored.
	&"giveaway": Rect2(1030, 545, 230, 160),  # A bag by the door: given away.
	&"guitar_wall": Rect2(770, 90, 150, 330), # The wall beside the chair: kept.
	&"high_shelf": Rect2(560, 30, 200, 160),  # The high shelf over the chair.
	&"monitor_shelf": Rect2(420, 300, 150, 160),
	&"crib_spot": Rect2(100, 250, 310, 260),  # Under the left window.
}

## Every thing, in the order a hint offers them. `from` is where it starts
## (its tap area, at least 150 units each way), `to` its one place, `stage`
## the beat it belongs to. `rest` is where it is drawn once placed: inside
## its place, or nowhere for things that go into the tote or the bag.
const THINGS := [
	{"id": &"poster", "stage": Stage.OLD_THINGS, "to": &"giveaway",
		"from": Rect2(400, 60, 150, 200)},
	{"id": &"guitar", "stage": Stage.OLD_THINGS, "to": &"guitar_wall",
		"from": Rect2(960, 250, 150, 280)},
	{"id": &"games_box", "stage": Stage.OLD_THINGS, "to": &"storage",
		"from": Rect2(660, 380, 180, 150)},
	{"id": &"tshirts_box", "stage": Stage.OLD_THINGS, "to": &"giveaway",
		"from": Rect2(560, 530, 190, 150)},
	{"id": &"stuff_box", "stage": Stage.OLD_THINGS, "to": &"storage",
		"from": Rect2(760, 530, 190, 150)},
	{"id": &"memory_box", "stage": Stage.MEMORY_BOX, "to": &"high_shelf",
		"from": Rect2(660, 545, 170, 150)},
	{"id": &"monitor", "stage": Stage.MONITOR, "to": &"monitor_shelf",
		"from": Rect2(1090, 330, 150, 160)},
	{"id": &"crib", "stage": Stage.CRIB, "to": &"crib_spot",
		"from": Rect2(880, 250, 330, 260)},
]

var stage: int = Stage.DOOR
## Seconds since the chapter opened (stops while paused).
var time := 0.0
## Seconds into the current stage.
var stage_time := 0.0
## How bright the room is, 0 (the door just opened) to 1 (good light).
var light := 0.0
## Ids of placed things, in the order they were placed.
var placed: Array[StringName] = []
## Seconds since the last placement (or since things could first be moved).
var idle := 0.0
## Each stage's start time, for tests and the overlay.
var stage_started := {}


func _init() -> void:
	stage_started[Stage.DOOR] = 0.0


func advance(delta: float) -> void:
	if stage == Stage.DONE:
		return
	time += delta
	stage_time += delta
	idle += delta
	match stage:
		Stage.DOOR:
			light = 0.35 * minf(stage_time / DOOR_TIME, 1.0)
			if stage_time >= DOOR_TIME:
				_go(Stage.OLD_THINGS)
		Stage.LIGHT:
			light = lerpf(0.35, 1.0, smoothstep(0.0, 1.0, stage_time / LIGHT_TIME))
			if stage_time >= LIGHT_TIME:
				_go(Stage.MONITOR)
		Stage.ENDING:
			if stage_time >= ENDING_TIME:
				_go(Stage.DONE)


func _go(next: int) -> void:
	stage = next
	stage_time = 0.0
	idle = 0.0
	stage_started[next] = time


static func thing(id: StringName) -> Dictionary:
	for t: Dictionary in THINGS:
		if t.id == id:
			return t
	return {}


## The ids of things that can be picked up now.
func movable() -> Array[StringName]:
	var out: Array[StringName] = []
	for t: Dictionary in THINGS:
		if t.id in placed or t.stage != stage:
			continue
		if stage in [Stage.MONITOR, Stage.CRIB] and stage_time < COME_IN_TIME:
			continue  # Still coming in through the door.
		if stage == Stage.MEMORY_BOX and stage_time < FOUND_TIME:
			continue  # Still coming out from under the boxes.
		out.append(t.id)
	return out


## Things on screen and not yet placed (movable or not): the clutter, then
## the memory box once found, then whatever has come in.
func visible_unplaced() -> Array[StringName]:
	var out: Array[StringName] = []
	for t: Dictionary in THINGS:
		if t.id in placed:
			continue
		if t.stage == Stage.OLD_THINGS or t.stage <= stage:
			out.append(t.id)
	return out


## Where a thing is drawn now when nobody is holding it, in room units. Things
## coming in slide from the right-hand edge.
func rect_of(id: StringName) -> Rect2:
	var t := thing(id)
	if id in placed:
		return PLACES[t.to]
	var r: Rect2 = t.from
	if t.stage == stage and stage in [Stage.MONITOR, Stage.CRIB] and stage_time < COME_IN_TIME:
		var k := smoothstep(0.0, 1.0, stage_time / COME_IN_TIME)
		r.position.x = lerpf(ROOM_SIZE.x + 20.0, r.position.x, k)
	if id == &"memory_box" and stage == Stage.MEMORY_BOX and stage_time < FOUND_TIME:
		# Slides out a little from where the boxes stood.
		var k := smoothstep(0.0, 1.0, stage_time / FOUND_TIME)
		r.position.y = lerpf(r.position.y - 12.0, r.position.y, k)
		r.position.x = lerpf(r.position.x + 40.0, r.position.x, k)
	return r


## The movable thing under `point` (topmost first), or &"".
func thing_at(point: Vector2) -> StringName:
	var ids := movable()
	ids.reverse()  # Later things are drawn on top.
	for id in ids:
		if rect_of(id).has_point(point):
			return id
	return &""


## Lets `id` go with its middle at `centre`. True if it landed in its place
## (it stays there); false if it can't stay where it was dropped (it goes back).
func drop(id: StringName, centre: Vector2) -> bool:
	if not id in movable():
		return false
	var t := thing(id)
	var place: Rect2 = PLACES[t.to]
	if not place.grow(DROP_MARGIN).has_point(centre):
		return false
	placed.append(id)
	idle = 0.0
	_after_placing()
	return true


func _after_placing() -> void:
	for t: Dictionary in THINGS:
		if t.stage == stage and not t.id in placed:
			return
	match stage:
		Stage.OLD_THINGS:
			_go(Stage.MEMORY_BOX)
		Stage.MEMORY_BOX:
			_go(Stage.LIGHT)
		Stage.MONITOR:
			_go(Stage.CRIB)
		Stage.CRIB:
			_go(Stage.ENDING)


## The thing whose place is shown after a while with no placement, or &"".
func hint() -> StringName:
	var ids := movable()
	if ids.is_empty() or idle < HINT_AFTER:
		return &""
	return ids[0]


## What is where at the end: each thing's id to the place it is in.
func layout() -> Dictionary:
	var out := {}
	for id in placed:
		out[String(id)] = String(thing(id).to)
	return out


func is_done() -> bool:
	return stage == Stage.DONE
