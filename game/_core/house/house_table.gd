class_name HouseTable
extends RefCounted
## The core table (game-architecture 2.1): what the House shows at each story
## point. The House reads only this table; chapters never write story facts.
## Which point the player is at comes from GameState's finished-chapter list,
## plus whether the opening beat has played (held in memory until the
## Partner's save; see GameState.finish_opening_beat).
##
## M1 has four story points. Every value here comes from
## docs/design/house-floor-plan.md ("How the House opens up", "Rooms",
## "Chapter objects are always ready", "House objects through the story") and
## docs/design/continuity-ledger.md. Change those first, then this.

# --- Story points, in play order.
const START := &"start"
const AFTER_OPENING := &"after_opening"
const AFTER_PARTNER := &"after_partner"
const AFTER_LOSS := &"after_loss"
const POINTS: Array[StringName] = [START, AFTER_OPENING, AFTER_PARTNER, AFTER_LOSS]

# --- House moods.
const COLD := &"cold"
const WARM := &"warm"
const GRAY := &"gray"

# --- Room and door states.
const OPEN := &"open"
const SHUT := &"shut"
## Moving boxes stacked in the way: it reads "not yet" (Dan, 2026-10-19).
const BOXED := &"boxed"

# --- Rooms.
const PORCH := &"porch"
const ENTRY := &"entry"
const LIVING_ROOM := &"living_room"
const KITCHEN := &"kitchen"
const BACK_HALL := &"back_hall"
const BEDROOM := &"bedroom"
const EN_SUITE := &"en_suite"
const CLOSET := &"closet"
const HALL_BATH := &"hall_bath"
const OFFICE := &"office"
const SPARE_ROOM := &"spare_room"
const ROOMS: Array[StringName] = [
	PORCH, ENTRY, LIVING_ROOM, KITCHEN, BACK_HALL, BEDROOM,
	EN_SUITE, CLOSET, HALL_BATH, OFFICE, SPARE_ROOM,
]

## The doors and openings between rooms. "one_way": you can go through it
## from "from" to "to" only (the front door: the porch is seen only at the
## very start).
const DOORS := {
	&"front_door": {"from": PORCH, "to": ENTRY, "one_way": true},
	&"entry_opening": {"from": ENTRY, "to": LIVING_ROOM},
	&"kitchen_opening": {"from": LIVING_ROOM, "to": KITCHEN},
	&"hall_opening": {"from": LIVING_ROOM, "to": BACK_HALL},
	&"bedroom_door": {"from": BACK_HALL, "to": BEDROOM},
	&"en_suite_door": {"from": BEDROOM, "to": EN_SUITE},
	&"closet_door": {"from": BEDROOM, "to": CLOSET},
	&"hall_bath_door": {"from": BACK_HALL, "to": HALL_BATH},
	&"office_door": {"from": BACK_HALL, "to": OFFICE},
	&"spare_room_door": {"from": BACK_HALL, "to": SPARE_ROOM},
}

# --- Chapter objects: tapping one starts its chapter.
const NO_CHAPTER_OBJECT := &""
const RECORD_PLAYER := &"record_player"
const BEDSIDE_LAMP := &"bedside_lamp"
const CHAPTER_OBJECTS := {
	RECORD_PLAYER: {"chapter": &"partner", "room": BEDROOM, "view": &"B3"},
	BEDSIDE_LAMP: {"chapter": &"protector", "room": BEDROOM, "view": &"B2"},
}

## The House objects: where each one is. They reward looking; they are never
## required, scored or saved.
const HOUSE_OBJECTS := {
	&"leo_moving_box": {"room": ENTRY, "view": &"E1"},
	&"record_crate": {"room": LIVING_ROOM, "view": &"L4"},
	&"big_window": {"room": LIVING_ROOM, "view": &"L2"},
	&"pizza_box": {"room": KITCHEN, "view": &"K3"},
	&"fridge": {"room": KITCHEN, "view": &"K2"},
	&"photo": {"room": BEDROOM, "view": &"B1"},
	&"mayas_list": {"room": BEDROOM, "view": &"B2"},
	&"positive_test": {"room": EN_SUITE, "view": &"BA"},
	&"closet_clothes": {"room": CLOSET, "view": &"C1"},
	&"onesie": {"room": SPARE_ROOM, "view": &"S1"},
	&"leos_things": {"room": SPARE_ROOM, "view": &"S1"},
	&"car_keys": {"room": ENTRY, "view": &"E1"},
	&"couch_blanket": {"room": LIVING_ROOM, "view": &"L1"},
}

## What the House shows at each story point. "arrive_in" is the room the
## player is in when the point begins. "objects" maps each House object that
## is there to its state; an object that isn't listed isn't there.
const TABLE := {
	START: {
		"mood": COLD,
		"arrive_in": PORCH,
		"chapter_object": NO_CHAPTER_OBJECT,
		"rooms": {
			PORCH: OPEN, ENTRY: OPEN, LIVING_ROOM: OPEN, KITCHEN: OPEN,
			BACK_HALL: BOXED, BEDROOM: SHUT, EN_SUITE: SHUT, CLOSET: SHUT,
			HALL_BATH: SHUT, OFFICE: SHUT, SPARE_ROOM: SHUT,
		},
		"doors": {
			&"front_door": OPEN, &"entry_opening": OPEN, &"kitchen_opening": OPEN,
			&"hall_opening": BOXED, &"bedroom_door": SHUT, &"en_suite_door": SHUT,
			&"closet_door": SHUT, &"hall_bath_door": SHUT, &"office_door": SHUT,
			&"spare_room_door": SHUT,
		},
		"objects": {
			&"leo_moving_box": &"packed",
			&"record_crate": &"full",
			&"big_window": &"dusk",
			&"pizza_box": &"two_slices_left",
			&"fridge": &"nearly_empty",
		},
	},
	AFTER_OPENING: {
		"mood": COLD,
		"arrive_in": LIVING_ROOM,
		"chapter_object": RECORD_PLAYER,
		"rooms": {
			PORCH: SHUT, ENTRY: OPEN, LIVING_ROOM: OPEN, KITCHEN: OPEN,
			BACK_HALL: OPEN, BEDROOM: OPEN, EN_SUITE: OPEN, CLOSET: BOXED,
			HALL_BATH: SHUT, OFFICE: BOXED, SPARE_ROOM: SHUT,
		},
		"doors": {
			&"front_door": SHUT, &"entry_opening": OPEN, &"kitchen_opening": OPEN,
			&"hall_opening": OPEN, &"bedroom_door": OPEN, &"en_suite_door": OPEN,
			&"closet_door": BOXED, &"hall_bath_door": SHUT, &"office_door": BOXED,
			&"spare_room_door": SHUT,
		},
		"objects": {
			&"record_crate": &"full",
			&"big_window": &"dusk",
			&"pizza_box": &"two_slices_left",
			&"fridge": &"nearly_empty",
			&"photo": &"wrapped",
			&"mayas_list": &"on_nightstand",
		},
	},
	AFTER_PARTNER: {
		"mood": WARM,
		"arrive_in": BEDROOM,
		"chapter_object": BEDSIDE_LAMP,
		"rooms": {
			PORCH: SHUT, ENTRY: OPEN, LIVING_ROOM: OPEN, KITCHEN: OPEN,
			BACK_HALL: OPEN, BEDROOM: OPEN, EN_SUITE: OPEN, CLOSET: OPEN,
			HALL_BATH: SHUT, OFFICE: BOXED, SPARE_ROOM: OPEN,
		},
		"doors": {
			&"front_door": SHUT, &"entry_opening": OPEN, &"kitchen_opening": OPEN,
			&"hall_opening": OPEN, &"bedroom_door": OPEN, &"en_suite_door": OPEN,
			&"closet_door": OPEN, &"hall_bath_door": SHUT, &"office_door": BOXED,
			&"spare_room_door": OPEN,
		},
		"objects": {
			&"record_crate": &"one_missing",
			&"big_window": &"dusk",
			&"fridge": &"mayas_note",
			&"photo": &"hung",
			&"mayas_list": &"on_nightstand",
			&"positive_test": &"on_counter",
			&"closet_clothes": &"half_unpacked",
			&"onesie": &"on_lounge_chair",
			&"leos_things": &"half_unpacked",
		},
	},
	AFTER_LOSS: {
		"mood": GRAY,
		"arrive_in": ENTRY,
		"chapter_object": NO_CHAPTER_OBJECT,
		"rooms": {
			PORCH: SHUT, ENTRY: OPEN, LIVING_ROOM: OPEN, KITCHEN: OPEN,
			BACK_HALL: OPEN, BEDROOM: OPEN, EN_SUITE: OPEN, CLOSET: OPEN,
			HALL_BATH: SHUT, OFFICE: BOXED, SPARE_ROOM: SHUT,
		},
		"doors": {
			&"front_door": SHUT, &"entry_opening": OPEN, &"kitchen_opening": OPEN,
			&"hall_opening": OPEN, &"bedroom_door": OPEN, &"en_suite_door": OPEN,
			&"closet_door": OPEN, &"hall_bath_door": SHUT, &"office_door": BOXED,
			&"spare_room_door": SHUT,
		},
		"objects": {
			&"record_crate": &"one_missing",
			&"big_window": &"rain",
			&"fridge": &"food_from_family",
			&"photo": &"hung",
			&"mayas_list": &"on_nightstand",
			&"closet_clothes": &"half_unpacked",
			&"car_keys": &"dropped",
			&"couch_blanket": &"unfolded",
		},
	},
}


## The story point for a finished-chapter list (GameState.finished_chapters())
## and whether the opening beat has played (GameState.opening_beat_done()).
## Anything past the Loss is still AFTER_LOSS until M2 adds its points.
static func point_for(finished: Array[String], opening_done: bool) -> StringName:
	if "protector" in finished:
		return AFTER_LOSS
	if "partner" in finished:
		return AFTER_PARTNER
	return AFTER_OPENING if opening_done else START


## cold, warm or gray.
static func mood(point: StringName) -> StringName:
	return _row(point).get("mood", COLD)


## The room the player is in when the point begins.
static func arrive_in(point: StringName) -> StringName:
	return _row(point).get("arrive_in", PORCH)


## Every room's state (OPEN, SHUT or BOXED).
static func rooms(point: StringName) -> Dictionary:
	return _row(point).get("rooms", {}).duplicate()


static func room_state(point: StringName, room: StringName) -> StringName:
	return rooms(point).get(room, SHUT)


## The rooms the player can be in, in ROOMS order.
static func open_rooms(point: StringName) -> Array[StringName]:
	var open: Array[StringName] = []
	for room in ROOMS:
		if room_state(point, room) == OPEN:
			open.append(room)
	return open


## Every door's state (OPEN, SHUT or BOXED).
static func doors(point: StringName) -> Dictionary:
	return _row(point).get("doors", {}).duplicate()


static func door_state(point: StringName, door: StringName) -> StringName:
	return doors(point).get(door, SHUT)


## The chapter object that starts the next chapter, or NO_CHAPTER_OBJECT.
## It works the moment the player reaches it (Dan, 2026-10-19).
static func chapter_object(point: StringName) -> StringName:
	return _row(point).get("chapter_object", NO_CHAPTER_OBJECT)


## The chapter a chapter object starts ("" for none).
static func chapter_for_object(object: StringName) -> StringName:
	return CHAPTER_OBJECTS.get(object, {}).get("chapter", &"")


## Each House object that is there, mapped to its state.
static func house_objects(point: StringName) -> Dictionary:
	return _row(point).get("objects", {}).duplicate()


## A House object's state, or &"" when it isn't there.
static func object_state(point: StringName, object: StringName) -> StringName:
	return house_objects(point).get(object, &"")


## The rooms that can be reached from `from` through open doors.
static func reachable_from(point: StringName, from: StringName) -> Array[StringName]:
	var reached: Array[StringName] = [from]
	var queue: Array[StringName] = [from]
	while not queue.is_empty():
		var room: StringName = queue.pop_front()
		for next in _next_rooms(point, room):
			if not next in reached:
				reached.append(next)
				queue.append(next)
	return reached


static func _next_rooms(point: StringName, room: StringName) -> Array[StringName]:
	var next: Array[StringName] = []
	for door: StringName in DOORS:
		if door_state(point, door) != OPEN:
			continue
		var ends: Dictionary = DOORS[door]
		if ends.from == room:
			next.append(ends.to)
		elif ends.to == room and not ends.get("one_way", false):
			next.append(ends.from)
	return next


static func _row(point: StringName) -> Dictionary:
	if not TABLE.has(point):
		push_error("HouseTable: unknown story point '%s'." % point)
		return {}
	return TABLE[point]
