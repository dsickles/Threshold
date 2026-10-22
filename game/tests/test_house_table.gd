extends TestCase
## The core table for M1 (DAS-92): each story point gives the House its mood,
## open rooms, chapter object and House objects, as house-floor-plan.md and
## the continuity ledger say, and the House never has a dead end.

const T := preload("res://_core/house/house_table.gd")


func _rooms(names: Array) -> Array[StringName]:
	var rooms: Array[StringName] = []
	rooms.assign(names)
	return rooms


func _sorted(rooms: Array) -> Array:
	var copy: Array = []
	copy.assign(rooms)
	copy.sort()
	return copy


# --- Which story point a finished-chapter list is at.

func test_a_new_game_is_at_the_start() -> void:
	check_eq(T.point_for([] as Array[String], false), T.START, "nothing finished")


func test_the_opening_beat_moves_the_house_on_before_any_chapter_is_finished() -> void:
	check_eq(T.point_for([] as Array[String], true), T.AFTER_OPENING, "opening played")


func test_finishing_the_partner_and_the_loss_move_the_house_on() -> void:
	check_eq(T.point_for(["partner"] as Array[String], true), T.AFTER_PARTNER, "after the Partner")
	check_eq(T.point_for(["partner", "protector"] as Array[String], true), T.AFTER_LOSS,
			"after the Loss")


# --- Each M1 point: mood, open rooms and the next chapter object.

func test_start_is_cold_with_only_the_front_of_the_house_open_and_no_chapter_object() -> void:
	check_eq(T.mood(T.START), T.COLD, "mood")
	check_eq(T.open_rooms(T.START), _rooms([T.PORCH, T.ENTRY, T.LIVING_ROOM, T.KITCHEN]),
			"open rooms")
	check_eq(T.room_state(T.START, T.BACK_HALL), T.BOXED, "boxes in the back-hall doorway")
	check_eq(T.chapter_object(T.START), T.NO_CHAPTER_OBJECT, "no chapter object")
	check_eq(T.arrive_in(T.START), T.PORCH, "starts on the porch")


func test_after_the_opening_beat_the_hall_and_bedroom_open_and_the_record_player_waits() -> void:
	var point := T.AFTER_OPENING
	check_eq(T.mood(point), T.COLD, "still cold")
	check_eq(T.open_rooms(point),
			_rooms([T.ENTRY, T.LIVING_ROOM, T.KITCHEN, T.BACK_HALL, T.BEDROOM, T.EN_SUITE]),
			"open rooms")
	check_eq(T.room_state(point, T.OFFICE), T.BOXED, "boxes against the office door")
	check_eq(T.room_state(point, T.CLOSET), T.BOXED, "boxes in the way of the closet")
	check_eq(T.room_state(point, T.SPARE_ROOM), T.SHUT, "spare room shut")
	check_eq(T.room_state(point, T.PORCH), T.SHUT, "porch only at the very start")
	check_eq(T.chapter_object(point), T.RECORD_PLAYER, "record player")
	check_eq(T.chapter_for_object(T.RECORD_PLAYER), &"partner", "it starts the Partner")


func test_after_the_partner_the_house_is_warm_the_spare_room_is_ajar_and_the_lamp_waits() -> void:
	var point := T.AFTER_PARTNER
	check_eq(T.mood(point), T.WARM, "warm")
	check_eq(T.open_rooms(point),
			_rooms([T.ENTRY, T.LIVING_ROOM, T.KITCHEN, T.BACK_HALL, T.BEDROOM, T.EN_SUITE,
					T.CLOSET, T.SPARE_ROOM]),
			"open rooms")
	check_eq(T.room_state(point, T.OFFICE), T.BOXED, "office still boxed")
	check_eq(T.chapter_object(point), T.BEDSIDE_LAMP, "bedside lamp")
	check_eq(T.chapter_for_object(T.BEDSIDE_LAMP), &"protector", "it starts the Loss")
	check_eq(T.arrive_in(point), T.BEDROOM, "back in the bedroom, where the Partner began")


func test_after_the_loss_the_house_is_gray_the_spare_room_is_shut_and_nothing_waits() -> void:
	var point := T.AFTER_LOSS
	check_eq(T.mood(point), T.GRAY, "gray")
	check_eq(T.open_rooms(point),
			_rooms([T.ENTRY, T.LIVING_ROOM, T.KITCHEN, T.BACK_HALL, T.BEDROOM, T.EN_SUITE,
					T.CLOSET]),
			"open rooms")
	check_eq(T.room_state(point, T.SPARE_ROOM), T.SHUT, "spare room shut, no boxes")
	check_eq(T.door_state(point, &"spare_room_door"), T.SHUT, "spare room door shut, no boxes")
	check_eq(T.chapter_object(point), T.NO_CHAPTER_OBJECT, "M1 ends with no chapter object")
	check_eq(T.arrive_in(point), T.ENTRY, "home through the front door into the entry")


func test_the_chapter_object_always_starts_the_next_chapter_in_story_order() -> void:
	var finished_at := {
		T.AFTER_OPENING: [] as Array[String],
		T.AFTER_PARTNER: ["partner"] as Array[String],
	}
	for point: StringName in finished_at:
		var finished: Array[String] = finished_at[point]
		var next := String(ChapterList.STORY_ORDER[finished.size()])
		check_eq(String(T.chapter_for_object(T.chapter_object(point))), next,
				"%s: chapter object starts %s" % [point, next])


func test_the_living_room_and_kitchen_are_open_at_every_point() -> void:
	for point in T.POINTS:
		check_eq(T.room_state(point, T.LIVING_ROOM), T.OPEN, "%s: living room" % point)
		check_eq(T.room_state(point, T.KITCHEN), T.OPEN, "%s: kitchen" % point)
		check_eq(T.room_state(point, T.ENTRY), T.OPEN, "%s: entry" % point)


func test_the_hall_bathroom_stays_shut_in_m1() -> void:
	for point in T.POINTS:
		check_eq(T.room_state(point, T.HALL_BATH), T.SHUT, "%s: hall bathroom" % point)


# --- No dead ends.

func test_at_every_point_every_open_room_can_be_reached_and_nothing_else() -> void:
	for point in T.POINTS:
		var reached := T.reachable_from(point, T.arrive_in(point))
		check_eq(_sorted(reached), _sorted(T.open_rooms(point)),
				"%s: rooms reached from %s" % [point, T.arrive_in(point)])


func test_at_every_point_the_living_room_can_be_reached_from_every_open_room() -> void:
	for point in T.POINTS:
		for room in T.open_rooms(point):
			check(T.LIVING_ROOM in T.reachable_from(point, room),
					"%s: living room reached from %s" % [point, room])


func test_the_player_arrives_in_an_open_room() -> void:
	for point in T.POINTS:
		check_eq(T.room_state(point, T.arrive_in(point)), T.OPEN, "%s: arrival room" % point)


func test_the_spare_room_cannot_be_reached_by_any_route_after_the_loss() -> void:
	for room in T.ROOMS:
		check(not T.SPARE_ROOM in T.reachable_from(T.AFTER_LOSS, room) or room == T.SPARE_ROOM,
				"spare room not reached from %s" % room)


func test_a_boxed_room_has_a_boxed_door_and_a_shut_room_has_no_open_door() -> void:
	for point in T.POINTS:
		for door: StringName in T.DOORS:
			var to: StringName = T.DOORS[door].to
			var state := T.door_state(point, door)
			match T.room_state(point, to):
				T.BOXED:
					check_eq(state, T.BOXED, "%s: %s in front of a boxed room" % [point, door])
				T.SHUT:
					check(state != T.OPEN, "%s: %s open into a shut room" % [point, door])


func test_every_room_and_door_has_a_state_at_every_point() -> void:
	for point in T.POINTS:
		check_eq(_sorted(T.rooms(point).keys()), _sorted(T.ROOMS),
				"%s: rooms listed" % point)
		check_eq(T.doors(point).size(), T.DOORS.size(), "%s: doors listed" % point)
		for door: StringName in T.DOORS:
			check(T.doors(point).has(door), "%s: %s listed" % [point, door])


# --- Chapter objects and House objects.

func test_the_active_chapter_object_is_in_an_open_room() -> void:
	for point in T.POINTS:
		var object := T.chapter_object(point)
		if object == T.NO_CHAPTER_OBJECT:
			continue
		var room: StringName = T.CHAPTER_OBJECTS[object].room
		check_eq(T.room_state(point, room), T.OPEN, "%s: %s's room" % [point, object])


func test_every_house_object_is_known_and_in_an_open_room() -> void:
	for point in T.POINTS:
		for object: StringName in T.house_objects(point):
			check(T.HOUSE_OBJECTS.has(object), "%s: %s is a known House object" % [point, object])
			var room: StringName = T.HOUSE_OBJECTS.get(object, {}).get("room", &"")
			check_eq(T.room_state(point, room), T.OPEN, "%s: %s's room" % [point, object])


func test_m1_has_the_18_house_object_entries_from_the_floor_plan() -> void:
	var entries := {}
	var things := {}
	for point in T.POINTS:
		var objects := T.house_objects(point)
		for object: StringName in objects:
			entries["%s=%s" % [object, objects[object]]] = true
			things[object] = true
	check_eq(entries.size(), 18, "entries (each object in each of its states)")
	check_eq(things.size(), 13, "separate things")


func test_house_objects_follow_the_floor_plan_at_each_point() -> void:
	var expected := {
		T.START: {
			&"leo_moving_box": &"packed", &"record_crate": &"full", &"big_window": &"dusk",
			&"pizza_box": &"two_slices_left", &"fridge": &"nearly_empty",
		},
		T.AFTER_OPENING: {
			&"record_crate": &"full", &"big_window": &"dusk", &"pizza_box": &"two_slices_left",
			&"fridge": &"nearly_empty", &"photo": &"wrapped", &"mayas_list": &"on_nightstand",
		},
		T.AFTER_PARTNER: {
			&"record_crate": &"one_missing", &"big_window": &"dusk", &"fridge": &"mayas_note",
			&"photo": &"hung", &"mayas_list": &"on_nightstand", &"positive_test": &"on_counter",
			&"closet_clothes": &"half_unpacked", &"onesie": &"on_lounge_chair",
			&"leos_things": &"half_unpacked",
		},
		T.AFTER_LOSS: {
			&"record_crate": &"one_missing", &"big_window": &"rain",
			&"fridge": &"food_from_family", &"photo": &"hung", &"mayas_list": &"on_nightstand",
			&"closet_clothes": &"half_unpacked", &"car_keys": &"dropped",
			&"couch_blanket": &"unfolded",
		},
	}
	for point: StringName in expected:
		check_eq(T.house_objects(point), expected[point], "%s: House objects" % point)


func test_the_test_and_onesie_are_gone_after_the_loss_and_the_pizza_after_the_partner() -> void:
	check_eq(T.object_state(T.AFTER_LOSS, &"positive_test"), &"", "test gone")
	check_eq(T.object_state(T.AFTER_LOSS, &"onesie"), &"", "onesie gone")
	check_eq(T.object_state(T.AFTER_PARTNER, &"pizza_box"), &"", "pizza gone")
	check_eq(T.object_state(T.AFTER_OPENING, &"leo_moving_box"), &"",
			"moving box carried to the spare room")


func test_an_unknown_story_point_is_reported() -> void:
	expect_error("unknown story point")
	check_eq(T.mood(&"nursery"), T.COLD, "falls back without crashing")
