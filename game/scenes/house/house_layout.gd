class_name HouseLayout
extends RefCounted
## The M1 House as data: rooms, walls, doorways, furniture and the 17 views,
## from docs/design/house-floor-plan.md ("M1 build", "Views (M1)",
## "Furniture") and its drawing. Moving between views follows ADR-0008.
## house.gd builds the gray-box House from this; the tests check it.
##
## Units are metres. x runs west to east (0 to 17) and z runs from the back
## of the House to the front (0 to 12, the street side), the same way the
## floor-plan drawing reads (40 px to the metre). y is up.

const WALL_HEIGHT := 2.7
const DOOR_HEIGHT := 2.1
const EYE_HEIGHT := 1.6
## Height of a doorway's ring, about where a hand would reach for it.
const RING_HEIGHT := 1.3

## Door states, set per story point (house-floor-plan.md, "How the House
## opens up"). Open: you can go through. Shut: the door is closed. Blocked:
## moving boxes are stacked in the way.
const OPEN := "open"
const SHUT := "shut"
const BLOCKED := "blocked"

## Each room's floor area (one or more rectangles, x/z position and size) and
## its doorway view, if it has one. A room with no doorway view (the office,
## the hall bathroom) is never entered in M1.
const ROOMS := {
	"porch": {"rects": [Rect2(0, 12, 4, 2.5)], "doorway_view": "P"},
	"entry": {"rects": [Rect2(0, 6, 4, 6)], "doorway_view": "E1"},
	"living": {"rects": [Rect2(4, 7.5, 7, 4.5)], "doorway_view": "L1"},
	"kitchen": {"rects": [Rect2(11, 7.5, 6, 4.5)], "doorway_view": "K1"},
	"hall": {"rects": [Rect2(4, 6, 9, 1.5)], "doorway_view": "H1"},
	"bedroom": {"rects": [Rect2(3, 0, 4, 2.5), Rect2(0, 2.5, 7, 3.5)], "doorway_view": "B1"},
	"ensuite": {"rects": [Rect2(0, 0, 3, 2.5)], "doorway_view": "BA"},
	"closet": {"rects": [Rect2(7, 0, 2, 3)], "doorway_view": "C1"},
	"bath2": {"rects": [Rect2(7, 3, 2, 3)], "doorway_view": ""},
	"office": {"rects": [Rect2(9, 0, 4, 6)], "doorway_view": ""},
	"spare": {"rects": [Rect2(13, 0, 4, 7.5)], "doorway_view": "S1"},
}

## Walls, each a straight line from "from" to "to" (x, z), with openings
## along it: [start, end, bottom, top], as x (or z) positions on the
## wall's own line, not distances from its start, plus "glass"
## for a window. The living room and kitchen share no wall (open plan), nor
## do the two halves of the entry.
const WALLS: Array[Dictionary] = [
	# Outside walls.
	{"from": Vector2(0, 0), "to": Vector2(17, 0), "openings": [
		[3.4, 4.8, 0.9, 2.1, "glass"], [14.0, 15.3, 0.9, 2.1, "glass"]]},
	{"from": Vector2(0, 12), "to": Vector2(17, 12), "openings": [
		[1.4, 2.6, 0.0, DOOR_HEIGHT], [5.5, 9.5, 0.5, 2.3, "glass"], [11.8, 13.2, 0.9, 2.1, "glass"]]},
	{"from": Vector2(0, 0), "to": Vector2(0, 12), "openings": [[3.5, 4.9, 1.0, 2.1, "glass"]]},
	{"from": Vector2(17, 0), "to": Vector2(17, 12), "openings": [
		[2.2, 3.6, 0.9, 2.1, "glass"], [8.5, 9.4, 1.0, 2.1, "glass"]]},
	# En-suite.
	{"from": Vector2(3, 0), "to": Vector2(3, 2.5), "openings": [[1.0, 1.9, 0.0, DOOR_HEIGHT]]},
	{"from": Vector2(0, 2.5), "to": Vector2(3, 2.5), "openings": []},
	# Bedroom's east wall: the walk-in closet's door.
	{"from": Vector2(7, 0), "to": Vector2(7, 6), "openings": [[1.7, 2.6, 0.0, DOOR_HEIGHT]]},
	{"from": Vector2(7, 3), "to": Vector2(9, 3), "openings": []},
	{"from": Vector2(9, 0), "to": Vector2(9, 6), "openings": []},
	# Office and spare room; the spare room's door is at the hall's far end.
	{"from": Vector2(13, 0), "to": Vector2(13, 7.5), "openings": [[6.15, 7.35, 0.0, DOOR_HEIGHT]]},
	# The back hall's north side: bedroom, hall bathroom, office.
	{"from": Vector2(0, 6), "to": Vector2(13, 6), "openings": [
		[5.2, 6.2, 0.0, DOOR_HEIGHT], [7.7, 8.5, 0.0, DOOR_HEIGHT], [10.5, 11.5, 0.0, DOOR_HEIGHT]]},
	# Entry to the hall and the living room: the wide opening.
	{"from": Vector2(4, 6), "to": Vector2(4, 12), "openings": [[8.3, 11.2, 0.0, DOOR_HEIGHT]]},
	# The back hall's south side, then the spare room and kitchen.
	{"from": Vector2(4, 7.5), "to": Vector2(17, 7.5), "openings": [[4.6, 6.1, 0.0, DOOR_HEIGHT]]},
]

## Doorways between rooms. "at" is the middle of the doorway (x, z) and
## "width" its width. "panel": it has a door that can be shut. "one_way": you
## can only go from "a" to "b" (the front door: the porch is only at the
## start). "boxes": which side a stack of boxes stands on when blocked ("a",
## "b", or "" for in the doorway). A ring for going from "b" back to "a" can
## sit somewhere else ("ring_b"): the en-suite, closet and spare room are
## only looked into from their doorway, so the way back is behind you.
const DOORS := {
	"front_door": {"a": "porch", "b": "entry", "at": Vector2(2.0, 12.0), "width": 1.2,
			"panel": true, "one_way": true},
	"entry_living": {"a": "entry", "b": "living", "at": Vector2(4.0, 9.75), "width": 2.9},
	"living_kitchen": {"a": "living", "b": "kitchen", "at": Vector2(11.0, 9.75), "width": 4.5},
	"hall_opening": {"a": "living", "b": "hall", "at": Vector2(5.35, 7.5), "width": 1.5,
			"boxes": ""},
	"bedroom_door": {"a": "hall", "b": "bedroom", "at": Vector2(5.7, 6.0), "width": 1.0,
			"panel": true},
	"ensuite_door": {"a": "bedroom", "b": "ensuite", "at": Vector2(3.0, 1.45), "width": 0.9,
			"panel": true, "ring_b": Vector2(5.6, 2.8)},
	"closet_door": {"a": "bedroom", "b": "closet", "at": Vector2(7.0, 2.15), "width": 0.9,
			"boxes": "b", "ring_b": Vector2(4.4, 3.0)},
	"spare_door": {"a": "hall", "b": "spare", "at": Vector2(13.0, 6.75), "width": 1.2,
			"panel": true, "ring_b": Vector2(9.5, 6.75)},
	"office_door": {"a": "hall", "b": "office", "at": Vector2(11.0, 6.0), "width": 1.0,
			"panel": true, "boxes": "a"},
	"bath2_door": {"a": "hall", "b": "bath2", "at": Vector2(8.1, 6.0), "width": 0.8,
			"panel": true},
}

## The 17 M1 views, in the floor plan's order. "stand" is where the camera
## stands (x, z), "look" what it looks at. A wall view's ring sits on what it
## looks at, unless "ring" says otherwise (L3's would sit in the hall opening,
## on top of the doorway's own ring). "label" is the word under the ring that
## leads there, from the floor plan's names for rooms and walls (placeholder
## UI words until Dan approves them).
const VIEWS := {
	"P": {"label": "Porch", "room": "porch", "kind": "doorway", "stand": Vector2(2.0, 14.2),
			"look": Vector3(2.0, 1.3, 12.0)},
	"E1": {"label": "Entry", "room": "entry", "kind": "doorway", "stand": Vector2(1.9, 11.6),
			"look": Vector3(2.8, 1.0, 7.0)},
	"E2": {"label": "Entry table", "room": "entry", "kind": "wall", "stand": Vector2(2.9, 9.0),
			"look": Vector3(0.3, 0.9, 9.6)},
	"L1": {"label": "Living room", "room": "living", "kind": "doorway", "stand": Vector2(4.5, 9.9),
			"look": Vector3(12.0, 1.0, 9.6)},
	"L2": {"label": "Big window", "room": "living", "kind": "wall", "stand": Vector2(7.0, 9.3),
			"look": Vector3(7.5, 1.3, 12.0)},
	"L3": {"label": "Hall corner", "room": "living", "kind": "wall", "stand": Vector2(7.6, 10.4),
			"look": Vector3(5.35, 1.1, 7.5), "ring": Vector3(4.3, 2.0, 7.6)},
	"L4": {"label": "TV wall", "room": "living", "kind": "wall", "stand": Vector2(8.3, 9.6),
			"look": Vector3(8.3, 1.0, 7.5)},
	"K1": {"label": "Kitchen", "room": "kitchen", "kind": "doorway", "stand": Vector2(11.4, 8.9),
			"look": Vector3(16.5, 1.0, 9.8)},
	"K2": {"label": "Fridge", "room": "kitchen", "kind": "wall", "stand": Vector2(15.05, 10.3),
			"look": Vector3(15.05, 1.0, 7.6)},
	"K3": {"label": "Dining table", "room": "kitchen", "kind": "wall", "stand": Vector2(15.2, 10.4),
			"look": Vector3(12.5, 0.8, 10.4)},
	"H1": {"label": "Back hall", "room": "hall", "kind": "doorway", "stand": Vector2(4.5, 6.75),
			"look": Vector3(13.0, 1.2, 6.75)},
	"B1": {"label": "Bedroom", "room": "bedroom", "kind": "doorway", "stand": Vector2(5.7, 5.5),
			"look": Vector3(1.0, 1.0, 3.8)},
	"B2": {"label": "Bed wall", "room": "bedroom", "kind": "wall", "stand": Vector2(4.4, 4.2),
			"look": Vector3(0.0, 1.0, 4.2)},
	"B3": {"label": "Corner", "room": "bedroom", "kind": "wall", "stand": Vector2(4.6, 2.9),
			"look": Vector3(6.6, 1.0, 0.4)},
	"BA": {"label": "En-suite", "room": "ensuite", "kind": "doorway", "stand": Vector2(3.7, 1.45),
			"look": Vector3(0.4, 1.1, 1.2)},
	"C1": {"label": "Closet", "room": "closet", "kind": "doorway", "stand": Vector2(6.2, 2.15),
			"look": Vector3(8.8, 1.2, 1.4)},
	"S1": {"label": "Spare room", "room": "spare", "kind": "doorway", "stand": Vector2(13.5, 6.8),
			"look": Vector3(16.3, 1.0, 1.0)},
}

## Where the House starts: on the porch, facing the front door.
const START_VIEW := "P"

## Furniture as gray blocks, where house-floor-plan.md "Furniture" puts it:
## [id, room, centre, size, colour name, turn in degrees]. Not tappable.
const FURNITURE: Array[Array] = [
	["entry_table", "entry", Vector3(0.3, 0.4, 9.8), Vector3(0.5, 0.8, 1.8), "wood", 0.0],
	["coat_hook", "entry", Vector3(0.05, 1.7, 8.6), Vector3(0.08, 0.1, 0.5), "dark", 0.0],
	["couch", "living", Vector3(8.15, 0.42, 10.6), Vector3(2.3, 0.85, 0.9), "fabric", 9.0],
	["tv_console", "living", Vector3(8.3, 0.25, 7.8), Vector3(2.0, 0.5, 0.45), "wood", 0.0],
	["tv", "living", Vector3(8.3, 1.0, 7.75), Vector3(1.6, 0.9, 0.08), "dark", 0.0],
	["av_receiver", "living", Vector3(8.3, 0.58, 7.85), Vector3(0.45, 0.15, 0.35), "dark", 0.0],
	["speaker_left", "living", Vector3(7.0, 0.55, 7.8), Vector3(0.3, 1.1, 0.35), "dark", 0.0],
	["speaker_right", "living", Vector3(9.6, 0.55, 7.8), Vector3(0.3, 1.1, 0.35), "dark", 0.0],
	["dining_table", "kitchen", Vector3(12.5, 0.38, 10.4), Vector3(1.6, 0.75, 1.0), "wood", 0.0],
	["dining_chair_1", "kitchen", Vector3(12.05, 0.45, 9.65), Vector3(0.45, 0.9, 0.45), "wood", 0.0],
	["dining_chair_2", "kitchen", Vector3(12.95, 0.45, 9.65), Vector3(0.45, 0.9, 0.45), "wood", 0.0],
	["dining_chair_3", "kitchen", Vector3(12.05, 0.45, 11.15), Vector3(0.45, 0.9, 0.45), "wood", 0.0],
	["dining_chair_4", "kitchen", Vector3(12.95, 0.45, 11.15), Vector3(0.45, 0.9, 0.45), "wood", 0.0],
	["counter_north_left", "kitchen", Vector3(13.3, 0.45, 7.85), Vector3(2.6, 0.9, 0.6), "granite", 0.0],
	["sink", "kitchen", Vector3(13.95, 0.91, 7.85), Vector3(0.9, 0.04, 0.45), "steel", 0.0],
	["fridge", "kitchen", Vector3(15.05, 0.9, 7.95), Vector3(0.9, 1.8, 0.8), "steel", 0.0],
	["counter_north_right", "kitchen", Vector3(16.22, 0.45, 7.85), Vector3(1.45, 0.9, 0.6), "granite", 0.0],
	["counter_east", "kitchen", Vector3(16.65, 0.45, 10.05), Vector3(0.6, 0.9, 3.8), "granite", 0.0],
	["oven", "kitchen", Vector3(16.33, 0.45, 10.0), Vector3(0.04, 0.7, 0.75), "dark", 0.0],
	["counter_south", "kitchen", Vector3(15.57, 0.45, 11.65), Vector3(1.55, 0.9, 0.6), "granite", 0.0],
	["bed", "bedroom", Vector3(1.1, 0.3, 4.2), Vector3(2.1, 0.6, 1.6), "fabric", 0.0],
	["headboard", "bedroom", Vector3(0.08, 0.6, 4.2), Vector3(0.1, 1.2, 1.6), "wood", 0.0],
	["nightstand_lamp_side", "bedroom", Vector3(0.3, 0.3, 3.03), Vector3(0.5, 0.6, 0.55), "wood", 0.0],
	["nightstand_list_side", "bedroom", Vector3(0.3, 0.3, 5.38), Vector3(0.5, 0.6, 0.55), "wood", 0.0],
	["dresser_north", "bedroom", Vector3(4.1, 0.45, 0.28), Vector3(1.4, 0.9, 0.45), "wood", 0.0],
	["dresser_east", "bedroom", Vector3(6.7, 0.45, 4.15), Vector3(0.5, 0.9, 1.5), "wood", 0.0],
	["vanity", "ensuite", Vector3(0.3, 0.45, 1.5), Vector3(0.55, 0.9, 1.3), "granite", 0.0],
	["mirror", "ensuite", Vector3(0.03, 1.5, 1.5), Vector3(0.04, 0.8, 1.0), "glass", 0.0],
	["bathtub", "ensuite", Vector3(1.6, 0.3, 0.42), Vector3(2.2, 0.6, 0.75), "white", 0.0],
	["closet_shelf_north", "closet", Vector3(8.0, 1.7, 0.25), Vector3(1.9, 0.04, 0.45), "wood", 0.0],
	["closet_shelf_east", "closet", Vector3(8.75, 1.7, 1.5), Vector3(0.45, 0.04, 2.9), "wood", 0.0],
	["lounge_chair", "spare", Vector3(16.2, 0.45, 0.85), Vector3(0.8, 0.9, 0.8), "leather", 45.0],
	["ottoman", "spare", Vector3(15.45, 0.22, 1.7), Vector3(0.5, 0.45, 0.5), "leather", 45.0],
	["spare_boxes_west", "spare", Vector3(13.3, 0.4, 4.05), Vector3(0.5, 0.8, 1.3), "box", 0.0],
	["spare_boxes_east", "spare", Vector3(16.7, 0.4, 6.25), Vector3(0.5, 0.8, 1.3), "box", 0.0],
]

## Stand-in story points until the core table (DAS-92) is on main; then the
## House reads its door states from there. "start" is moving day; "hall_open"
## is after the opening beat (the boxes cleared from the back hall), so the
## bedroom can be reached from the test menu before the opening beat exists.
const STAND_IN_POINTS := {
	&"start": {
		"front_door": OPEN, "entry_living": OPEN, "living_kitchen": OPEN,
		"hall_opening": BLOCKED, "bedroom_door": OPEN, "ensuite_door": OPEN,
		"closet_door": BLOCKED, "spare_door": SHUT, "office_door": SHUT, "bath2_door": SHUT,
	},
	&"hall_open": {
		"front_door": OPEN, "entry_living": OPEN, "living_kitchen": OPEN,
		"hall_opening": OPEN, "bedroom_door": OPEN, "ensuite_door": OPEN,
		"closet_door": BLOCKED, "spare_door": SHUT, "office_door": BLOCKED, "bath2_door": SHUT,
	},
}


## Whether you can go through a doorway, from the given room, with these door
## states. Only open doors into a room that has a doorway view can be gone
## through; a door missing from the states counts as shut.
static func can_pass(door_id: String, from_room: String, doors: Dictionary) -> bool:
	var door: Dictionary = DOORS[door_id]
	if doors.get(door_id, SHUT) != OPEN:
		return false
	if from_room != door.a and from_room != door.b:
		return false
	if door.get("one_way", false) and from_room != door.a:
		return false
	return ROOMS[other_room(door_id, from_room)].doorway_view != ""


static func other_room(door_id: String, room: String) -> String:
	var door: Dictionary = DOORS[door_id]
	return door.b if room == door.a else door.a


## The rings shown in a view: one for every doorway in its room that can be
## gone through (leading to the next room's doorway view), and one for each
## of the room's other wall views. Each is {target, at, door}; "door" is the
## doorway gone through, or "" for a wall view.
static func rings_for(view_id: String, doors: Dictionary) -> Array[Dictionary]:
	var room: String = VIEWS[view_id].room
	var rings: Array[Dictionary] = []
	for door_id: String in DOORS:
		if not can_pass(door_id, room, doors):
			continue
		var door: Dictionary = DOORS[door_id]
		var spot: Vector2 = door.get("ring_b", door.at) if room == door.b else door.at
		rings.append({
			"target": ROOMS[other_room(door_id, room)].doorway_view,
			"at": Vector3(spot.x, RING_HEIGHT, spot.y),
			"door": door_id,
		})
	for other: String in VIEWS:
		var view: Dictionary = VIEWS[other]
		if other == view_id or view.room != room or view.kind != "wall":
			continue
		rings.append({"target": other, "at": view.get("ring", view.look), "door": ""})
	return rings


## Every view that can be reached from `from` by tapping rings.
static func reachable(from: String, doors: Dictionary) -> Array[String]:
	var seen: Array[String] = [from]
	var queue: Array[String] = [from]
	while not queue.is_empty():
		var view: String = queue.pop_front()
		for ring in rings_for(view, doors):
			if not ring.target in seen:
				seen.append(ring.target)
				queue.append(ring.target)
	return seen


## Where the camera stands for a view, looking at what it frames.
static func view_transform(view_id: String) -> Transform3D:
	var view: Dictionary = VIEWS[view_id]
	var eye := Vector3(view.stand.x, EYE_HEIGHT, view.stand.y)
	return Transform3D.IDENTITY.translated(eye).looking_at(view.look, Vector3.UP)


## The room a point on the floor (x, z) is in, or "" if none.
static func room_at(point: Vector2) -> String:
	for room: String in ROOMS:
		for rect: Rect2 in ROOMS[room].rects:
			if rect.has_point(point):
				return room
	return ""
