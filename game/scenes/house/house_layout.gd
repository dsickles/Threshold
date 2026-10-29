class_name HouseLayout
extends RefCounted
## The M1 House as data: rooms, walls, doorways, furniture and the 18 views,
## from docs/design/house-floor-plan.md ("M1 build", "Views (M1)",
## "Furniture") and its drawing. Moving between views follows ADR-0008.
## house.gd builds the gray-box House from this; the tests check it.
##
## Units are metres. x runs west to east (0 to 15.85) and z runs from the
## back of the House to the front (0 to 12.8, the street side), the same way
## the floor-plan drawing reads. The plan is drawn in feet (Dan's real room
## sizes, 2026-10-24: about 1,900 sq ft of living space), so the numbers here
## are feet times 0.3048. y is up.

const WALL_HEIGHT := 2.7
const DOOR_HEIGHT := 2.03
const EYE_HEIGHT := 1.6
## Height of a doorway's ring, about where a hand would reach for it.
const RING_HEIGHT := 1.3

## Door states, from the core table (HouseTable) for each story point. Open:
## you can go through. Shut: the door is closed. Boxed: moving boxes are
## stacked in the way. Room and door ids are the core table's.
const OPEN := HouseTable.OPEN
const SHUT := HouseTable.SHUT
const BOXED := HouseTable.BOXED

## Each room's floor area (one or more rectangles, x/z position and size) and
## its doorway view, if it has one. A room with no doorway view (the office,
## the hall bathroom) is never entered in M1.
const ROOMS := {
	"porch": {"rects": [Rect2(0.0, 10.973, 2.438, 1.829)], "doorway_view": "P"},
	"entry": {"rects": [Rect2(0.0, 7.01, 2.438, 3.962)], "doorway_view": "E1"},
	"living_room": {"rects": [Rect2(2.438, 7.01, 5.486, 5.486)], "doorway_view": "L1"},
	"kitchen": {"rects": [Rect2(7.925, 7.01, 7.925, 5.486)], "doorway_view": "K1"},
	"back_hall": {"rects": [Rect2(2.438, 5.791, 9.449, 1.219)], "doorway_view": "H1"},
	"bedroom": {"rects": [Rect2(3.048, 0.0, 3.048, 2.134), Rect2(0.0, 2.134, 6.096, 3.658)], "doorway_view": "B1"},
	"en_suite": {"rects": [Rect2(0.0, 0.0, 3.048, 2.134)], "doorway_view": "BA"},
	"closet": {"rects": [Rect2(6.096, 0.0, 1.829, 3.048)], "doorway_view": "C1"},
	"hall_bath": {"rects": [Rect2(6.096, 3.048, 1.829, 2.743)], "doorway_view": ""},
	"office": {"rects": [Rect2(7.925, 1.524, 3.962, 4.267)], "doorway_view": ""},
	"spare_room": {"rects": [Rect2(11.887, 2.438, 3.962, 4.572)], "doorway_view": "S1"},
}

## Walls, each a straight line from "from" to "to" (x, z), with openings
## along it: [start, end, bottom, top], as x (or z) positions on the
## wall's own line, not distances from its start, plus "glass"
## for a window. The living room and kitchen share no wall (open plan), nor
## do the two halves of the entry.
const WALLS: Array[Dictionary] = [
	# Outside walls: the back (north), stepping out at the office and spare room.
	{"from": Vector2(0.0, 0.0), "to": Vector2(7.925, 0.0), "openings": [[0.305, 1.067, 1.4, 2.1, "glass"], [3.81, 5.029, 0.9, 2.1, "glass"]]},
	{"from": Vector2(7.925, 1.524), "to": Vector2(11.887, 1.524), "openings": [[9.144, 10.668, 0.9, 2.1, "glass"]]},
	{"from": Vector2(11.887, 2.438), "to": Vector2(15.85, 2.438), "openings": [[12.802, 14.326, 0.9, 2.1, "glass"]]},
	{"from": Vector2(7.925, 0.0), "to": Vector2(7.925, 5.791), "openings": []},
	{"from": Vector2(11.887, 1.524), "to": Vector2(11.887, 7.01), "openings": [[6.001, 6.801, 0.0, DOOR_HEIGHT]]},
	# The front (the street side).
	{"from": Vector2(0.0, 10.973), "to": Vector2(2.438, 10.973), "openings": [[0.769, 1.669, 0.0, DOOR_HEIGHT]]},
	{"from": Vector2(2.438, 12.497), "to": Vector2(15.85, 12.497), "openings": [[3.658, 6.706, 0.5, 2.3, "glass"], [8.839, 10.668, 0.9, 2.1, "glass"]]},
	{"from": Vector2(0.0, 0.0), "to": Vector2(0.0, 10.973), "openings": [[3.353, 4.572, 1.0, 2.1, "glass"]]},
	{"from": Vector2(15.85, 2.438), "to": Vector2(15.85, 12.497), "openings": [[3.353, 4.572, 0.9, 2.1, "glass"], [8.23, 9.144, 1.0, 2.1, "glass"]]},
	# En-suite, along the bedroom's north wall; its door faces the bed wall.
	{"from": Vector2(3.048, 0.0), "to": Vector2(3.048, 2.134), "openings": []},
	{"from": Vector2(0.0, 2.134), "to": Vector2(3.048, 2.134), "openings": [[2.14, 2.89, 0.0, DOOR_HEIGHT]]},
	# Bedroom's east wall: the walk-in closet's door; the hall bath behind it.
	{"from": Vector2(6.096, 0.0), "to": Vector2(6.096, 5.791), "openings": [[0.591, 1.391, 0.0, DOOR_HEIGHT]]},
	{"from": Vector2(6.096, 3.048), "to": Vector2(7.925, 3.048), "openings": []},
	# The back hall's north side: bedroom, hall bathroom, office.
	{"from": Vector2(0.0, 5.791), "to": Vector2(11.887, 5.791), "openings": [[3.959, 4.759, 0.0, DOOR_HEIGHT], [6.712, 7.462, 0.0, DOOR_HEIGHT], [9.125, 9.925, 0.0, DOOR_HEIGHT]]},
	# The entry's back wall, with the coat closet behind it.
	{"from": Vector2(0.0, 7.01), "to": Vector2(2.438, 7.01), "openings": []},
	# Entry to the living room: the wide opening. The porch's side.
	{"from": Vector2(2.438, 5.791), "to": Vector2(2.438, 12.497), "openings": [[7.772, 10.363, 0.0, DOOR_HEIGHT]]},
	# The back hall's south side, then the spare room and kitchen.
	{"from": Vector2(2.438, 7.01), "to": Vector2(15.85, 7.01), "openings": [[2.905, 4.105, 0.0, DOOR_HEIGHT]]},
]

## Doorways between rooms. "at" is the middle of the doorway (x, z) and
## "width" its width. "panel": it has a door that can be shut. "one_way": you
## can only go from "a" to "b" (the front door: the porch is only at the
## start). "boxes": which side a stack of boxes stands on when boxed ("a",
## "b", or "" for in the doorway). A ring for going from "b" back to "a" can
## sit somewhere else ("ring_b"): the closet and spare room are only looked
## into from their doorway, so the way back is behind you. The en-suite is
## stood in (Dan, 2026-10-25), so its way back is its door.
## Doors open into "b" and are hung on their west (or north) end. "hinge":
## "end" hangs one on its east (or south) end, so an open door is out of the
## way of the view through it (the bedroom door blocked the bedroom, Dan
## 2026-10-24). "swing": how far it
## opens, in degrees (80 if not set); the front door and the en-suite door
## fold back flat against the wall.
const DOORS := {
	"front_door": {"a": "porch", "b": "entry", "at": Vector2(1.219, 10.973), "width": 0.9, "panel": true, "one_way": true, "swing": 170.0},
	"entry_opening": {"a": "entry", "b": "living_room", "at": Vector2(2.438, 9.068), "width": 2.591},
	"kitchen_opening": {"a": "living_room", "b": "kitchen", "at": Vector2(7.925, 9.754), "width": 5.486},
	"hall_opening": {"a": "living_room", "b": "back_hall", "at": Vector2(3.505, 7.01), "width": 1.2, "boxes": ""},
	"bedroom_door": {"a": "back_hall", "b": "bedroom", "at": Vector2(4.359, 5.791), "width": 0.8, "panel": true, "hinge": "end"},
	"en_suite_door": {"a": "bedroom", "b": "en_suite", "at": Vector2(2.515, 2.134), "width": 0.75, "panel": true, "swing": 170.0},
	"closet_door": {"a": "bedroom", "b": "closet", "at": Vector2(6.096, 0.991), "width": 0.8, "boxes": "b", "ring_b": Vector2(3.962, 2.743)},
	"spare_room_door": {"a": "back_hall", "b": "spare_room", "at": Vector2(11.887, 6.401), "width": 0.8, "panel": true, "hinge": "end", "ring_b": Vector2(9.144, 6.401)},
	"office_door": {"a": "back_hall", "b": "office", "at": Vector2(9.525, 5.791), "width": 0.8, "panel": true, "boxes": "a"},
	"hall_bath_door": {"a": "back_hall", "b": "hall_bath", "at": Vector2(7.087, 5.791), "width": 0.75, "panel": true},
}

## The 17 M1 views, in the floor plan's order, plus H2 at the far end of the
## back hall, to see its shut doors (Dan, 2026-10-25). "stand" is where the camera
## stands (x, z), "look" what it looks at. A wall view's ring sits on what it
## looks at, unless "ring" says otherwise (L3's would sit in the hall opening,
## on top of the doorway's own ring). "label" is the word under the ring that
## leads there, from the floor plan's names for rooms and walls (placeholder
## UI words until Dan approves them).
const VIEWS := {
	"P": {"label": "Porch", "room": "porch", "kind": "doorway", "stand": Vector2(1.219, 12.68),
			"look": Vector3(1.219, 1.3, 10.973)},
	"E1": {"label": "Entry", "room": "entry", "kind": "doorway", "stand": Vector2(1.219, 10.546),
			"look": Vector3(1.981, 1.0, 7.315)},
	"E2": {"label": "Entry table", "room": "entry", "kind": "wall", "stand": Vector2(1.981, 9.601),
			"look": Vector3(0.457, 1.0, 7.925)},
	"L1": {"label": "Living room", "room": "living_room", "kind": "doorway", "stand": Vector2(2.896, 9.144),
			"look": Vector3(12.192, 1.0, 9.449)},
	"L2": {"label": "Big window", "room": "living_room", "kind": "wall", "stand": Vector2(5.182, 8.382),
			"look": Vector3(5.182, 1.3, 12.497)},
	"L3": {"label": "Hall corner", "room": "living_room", "kind": "wall", "stand": Vector2(7.01, 10.973),
			"look": Vector3(3.505, 1.1, 7.01), "ring": Vector3(2.743, 2.0, 7.132)},
	"L4": {"label": "TV wall", "room": "living_room", "kind": "wall", "stand": Vector2(5.639, 11.43),
			"look": Vector3(5.639, 1.0, 7.01)},
	"K1": {"label": "Kitchen", "room": "kitchen", "kind": "doorway", "stand": Vector2(8.23, 8.839),
			"look": Vector3(15.545, 1.0, 10.058)},
	"K2": {"label": "Fridge", "room": "kitchen", "kind": "wall", "stand": Vector2(14.173, 10.058),
			"look": Vector3(14.173, 1.0, 7.01)},
	"K3": {"label": "Dining table", "room": "kitchen", "kind": "wall", "stand": Vector2(12.497, 9.754),
			"look": Vector3(9.754, 0.8, 9.677)},
	"H1": {"label": "Back hall", "room": "back_hall", "kind": "doorway", "stand": Vector2(2.743, 6.401),
			"look": Vector3(11.887, 1.2, 6.401)},
	"H2": {"label": "End of hall", "room": "back_hall", "kind": "wall", "stand": Vector2(7.925, 6.553),
			"look": Vector3(11.887, 1.1, 6.248), "ring": Vector3(7.925, 1.0, 6.553)},
	"B1": {"label": "Bedroom", "room": "bedroom", "kind": "doorway", "stand": Vector2(4.359, 5.334),
			"look": Vector3(0.61, 1.0, 3.962)},
	"B2": {"label": "Bed wall", "room": "bedroom", "kind": "wall", "stand": Vector2(3.658, 3.962),
			"look": Vector3(0.0, 1.0, 3.962)},
	"B3": {"label": "Corner", "room": "bedroom", "kind": "wall", "stand": Vector2(3.353, 3.962),
			"look": Vector3(5.791, 1.0, 0.305)},
	"BA": {"label": "Bathroom", "room": "en_suite", "kind": "doorway", "stand": Vector2(2.804, 1.829),
			"look": Vector3(0.762, 0.9, 0.457)},
	"C1": {"label": "Closet", "room": "closet", "kind": "doorway", "stand": Vector2(5.425, 0.991),
			"look": Vector3(7.772, 1.2, 0.914)},
	"S1": {"label": "Spare room", "room": "spare_room", "kind": "doorway", "stand": Vector2(12.375, 6.401),
			"look": Vector3(15.24, 1.0, 2.896)},
}

## Furniture as gray blocks, where house-floor-plan.md "Furniture" puts it:
## [id, room, centre, size, colour name, turn in degrees]. Not tappable.
const FURNITURE: Array[Array] = [
	["entry_table", "entry", Vector3(0.221, 0.4, 8.687), Vector3(0.381, 0.8, 1.219), "wood", 0.0],
	["coat_closet_door", "entry", Vector3(0.914, 1.015, 7.093), Vector3(0.8, 2.03, 0.04), "door", 0.0],
	["couch", "living_room", Vector3(5.258, 0.42, 9.906), Vector3(2.286, 0.85, 0.914), "fabric", 9.0],
	["tv_console", "living_room", Vector3(5.639, 0.25, 7.269), Vector3(1.829, 0.5, 0.457), "wood", 0.0],
	["tv", "living_room", Vector3(5.639, 1.0, 7.132), Vector3(1.6, 0.9, 0.08), "dark", 0.0],
	["av_receiver", "living_room", Vector3(5.639, 0.58, 7.3), Vector3(0.45, 0.15, 0.35), "dark", 0.0],
	["speaker_left", "living_room", Vector3(4.45, 0.55, 7.224), Vector3(0.3, 1.1, 0.35), "dark", 0.0],
	["speaker_right", "living_room", Vector3(6.828, 0.55, 7.224), Vector3(0.3, 1.1, 0.35), "dark", 0.0],
	["dining_table", "kitchen", Vector3(9.754, 0.38, 9.677), Vector3(1.829, 0.75, 1.067), "wood", 0.0],
	["dining_chair_1", "kitchen", Vector3(9.251, 0.45, 8.854), Vector3(0.45, 0.9, 0.45), "wood", 0.0],
	["dining_chair_2", "kitchen", Vector3(9.952, 0.45, 8.854), Vector3(0.45, 0.9, 0.45), "wood", 0.0],
	["dining_chair_3", "kitchen", Vector3(10.653, 0.45, 8.854), Vector3(0.45, 0.9, 0.45), "wood", 0.0],
	["dining_chair_4", "kitchen", Vector3(9.251, 0.45, 10.5), Vector3(0.45, 0.9, 0.45), "wood", 0.0],
	["dining_chair_5", "kitchen", Vector3(9.952, 0.45, 10.5), Vector3(0.45, 0.9, 0.45), "wood", 0.0],
	["dining_chair_6", "kitchen", Vector3(10.653, 0.45, 10.5), Vector3(0.45, 0.9, 0.45), "wood", 0.0],
	["counter_north_left", "kitchen", Vector3(12.68, 0.45, 7.346), Vector3(2.134, 0.9, 0.61), "granite", 0.0],
	["sink", "kitchen", Vector3(13.198, 0.91, 7.346), Vector3(0.8, 0.04, 0.45), "steel", 0.0],
	["fridge", "kitchen", Vector3(14.173, 0.9, 7.437), Vector3(0.914, 1.8, 0.792), "steel", 0.0],
	["counter_north_right", "kitchen", Vector3(15.225, 0.45, 7.346), Vector3(1.189, 0.9, 0.61), "granite", 0.0],
	["counter_east", "kitchen", Vector3(15.514, 0.45, 10.058), Vector3(0.61, 0.9, 4.816), "granite", 0.0],
	["oven", "kitchen", Vector3(15.203, 0.45, 9.677), Vector3(0.04, 0.7, 0.762), "dark", 0.0],
	["counter_south", "kitchen", Vector3(14.463, 0.45, 12.162), Vector3(1.494, 0.9, 0.61), "granite", 0.0],
	["bed", "bedroom", Vector3(1.158, 0.3, 3.962), Vector3(2.042, 0.6, 1.524), "fabric", 0.0],
	["headboard", "bedroom", Vector3(0.079, 0.6, 3.962), Vector3(0.1, 1.2, 1.524), "wood", 0.0],
	["nightstand_lamp_side", "bedroom", Vector3(0.259, 0.3, 2.972), Vector3(0.457, 0.6, 0.457), "wood", 0.0],
	["nightstand_list_side", "bedroom", Vector3(0.259, 0.3, 4.953), Vector3(0.457, 0.6, 0.457), "wood", 0.0],
	["dresser_north", "bedroom", Vector3(4.42, 0.45, 0.274), Vector3(1.524, 0.9, 0.488), "wood", 0.0],
	["dresser_east", "bedroom", Vector3(5.822, 0.45, 4.359), Vector3(0.488, 0.9, 1.524), "wood", 0.0],
	["vanity", "en_suite", Vector3(1.829, 0.45, 0.305), Vector3(1.219, 0.9, 0.549), "granite", 0.0],
	["mirror", "en_suite", Vector3(1.829, 1.5, 0.046), Vector3(0.914, 0.8, 0.04), "glass", 0.0],
	["toilet", "en_suite", Vector3(0.381, 0.38, 0.366), Vector3(0.701, 0.75, 0.488), "white", 0.0],
	["shower", "en_suite", Vector3(0.549, 0.08, 1.6), Vector3(1.036, 0.15, 1.006), "white", 0.0],
	["closet_shelf_north", "closet", Vector3(7.01, 1.7, 0.229), Vector3(1.768, 0.04, 0.396), "wood", 0.0],
	["closet_shelf_east", "closet", Vector3(7.696, 1.7, 1.737), Vector3(0.396, 0.04, 2.56), "wood", 0.0],
	["office_closet", "office", Vector3(11.582, 1.015, 4.572), Vector3(0.61, 2.03, 1.829), "door", 0.0],
	["spare_closet", "spare_room", Vector3(12.192, 1.015, 4.572), Vector3(0.61, 2.03, 1.829), "door", 0.0],
	["lounge_chair", "spare_room", Vector3(15.24, 0.45, 3.109), Vector3(0.8, 0.9, 0.8), "leather", 45.0],
	["ottoman", "spare_room", Vector3(14.448, 0.22, 4.054), Vector3(0.5, 0.45, 0.5), "leather", 45.0],
	["spare_boxes_west", "spare_room", Vector3(12.177, 0.4, 3.018), Vector3(0.5, 0.8, 1.0), "box", 0.0],
	["spare_boxes_east", "spare_room", Vector3(15.56, 0.4, 5.974), Vector3(0.5, 0.8, 1.0), "box", 0.0],
]

## The chapter objects (HouseTable.CHAPTER_OBJECTS) as gray blocks. "parts":
## [name, centre, size, colour name]; the "arm" part is the record player's
## tonearm, which lowers onto the record. "close_up" is where the camera
## stands for its close-up, looking at "look" (ADR-0008). Where they stand
## comes from house-floor-plan.md: the record player sits on a moving box in
## the bedroom's top-right corner (B3), the lamp on the bed's nightstand (B2).
const CHAPTER_OBJECTS := {
	"record_player": {
		"room": "bedroom",
		"parts": [
			["box", Vector3(5.55, 0.25, 0.4), Vector3(0.55, 0.5, 0.45), "box"],
			["body", Vector3(5.55, 0.56, 0.4), Vector3(0.46, 0.12, 0.36), "wood"],
			["record", Vector3(5.5, 0.63, 0.4), Vector3(0.3, 0.012, 0.3), "dark"],
			["arm", Vector3(5.72, 0.66, 0.4), Vector3(0.03, 0.03, 0.24), "steel"],
		],
		"close_up": {"stand": Vector3(5.2, 1.2, 1.05), "look": Vector3(5.55, 0.6, 0.4)},
	},
	"bedside_lamp": {
		"room": "bedroom",
		"parts": [
			["base", Vector3(0.259, 0.75, 2.972), Vector3(0.12, 0.3, 0.12), "wood"],
			["shade", Vector3(0.259, 1.0, 2.972), Vector3(0.32, 0.22, 0.32), "shade"],
		],
		"light": Vector3(0.45, 1.0, 2.972),
		"close_up": {"stand": Vector3(1.15, 1.3, 2.6), "look": Vector3(0.259, 0.85, 2.972)},
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
## of the room's other wall views, and from a wall view one back to the
## room's doorway view, where it was entered. Each is {target, at, door}; "door" is the
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
	# From a wall view, a way back out to where the room was entered (Dan,
	# 2026-10-25: from the bed wall you couldn't get back to the bedroom).
	var entered: String = ROOMS[room].doorway_view
	if VIEWS[view_id].kind == "wall" and entered != "":
		var back: Vector2 = VIEWS[entered].stand
		rings.append({"target": entered, "at": Vector3(back.x, RING_HEIGHT, back.y), "door": ""})
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


## Where the camera stands for a chapter object's close-up.
static func close_up_transform(object_id: String) -> Transform3D:
	var close: Dictionary = CHAPTER_OBJECTS[object_id].close_up
	return Transform3D.IDENTITY.translated(close.stand).looking_at(close.look, Vector3.UP)


## The box a chapter object fills, all its parts together.
static func object_bounds(object_id: String) -> AABB:
	var parts: Array = CHAPTER_OBJECTS[object_id].parts
	var bounds := AABB(parts[0][1] - parts[0][2] / 2.0, parts[0][2])
	for part: Array in parts:
		bounds = bounds.merge(AABB(part[1] - part[2] / 2.0, part[2]))
	return bounds
