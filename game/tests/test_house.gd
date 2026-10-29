extends TestCase
## The gray-box House (DAS-93): the M1 rooms, furniture and 18 views from
## docs/design/house-floor-plan.md, moved through by tapping rings (ADR-0008).

const HOUSE := preload("res://scenes/house/house.tscn")
const SCREENS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]
## The 17 views in house-floor-plan.md "Views (M1)", plus H2 at the end of
## the back hall (Dan, 2026-10-25).
const M1_VIEWS: Array[String] = ["P", "E1", "E2", "L1", "L2", "L3", "L4", "K1", "K2", "K3",
		"H1", "H2", "B1", "B2", "B3", "BA", "C1", "S1"]
## Every door open: each ring any view can ever have in M1.
const ALL_OPEN := {
	"front_door": "open", "entry_opening": "open", "kitchen_opening": "open",
	"hall_opening": "open", "bedroom_door": "open", "en_suite_door": "open",
	"closet_door": "open", "spare_room_door": "open", "office_door": "open", "hall_bath_door": "open",
}


func _open_house(doors: Dictionary = {}, point: StringName = &"start") -> Node:
	var house := HOUSE.instantiate()
	house.story_point = point
	house.door_states = doors.duplicate()
	add_child(house)
	return house


# Finishes the glide under way, as if its whole time had passed.
func _finish_glide(house: Node) -> void:
	if house._tween and house._tween.is_valid():
		house._tween.custom_step(house.GLIDE_SECONDS + 0.1)
	await frames()


# Puts the camera at a view straight away, as if the player had glided there.
func _stand_at(house: Node, view: String) -> void:
	if house._tween:
		house._tween.kill()
	house._current = view
	house._set_base(HouseLayout.view_transform(view))
	house._arrive()


func _same_place(a: Transform3D, b: Transform3D) -> bool:
	return a.origin.distance_to(b.origin) < 0.01 and a.basis.z.distance_to(b.basis.z) < 0.01


func _ring_targets(house: Node) -> Array[String]:
	var targets: Array[String] = []
	for ring: Dictionary in house._ring_data:
		targets.append(ring.target)
	targets.sort()
	return targets


# --- Rooms and furniture.

func test_every_m1_room_is_built() -> void:
	var house := _open_house()
	for room in ["porch", "entry", "living_room", "kitchen", "back_hall", "bedroom", "en_suite", "closet",
			"hall_bath", "office", "spare_room"]:
		check(HouseLayout.ROOMS.has(room), "%s is in the layout" % room)
		check(house.find_child("Floor_%s" % room, true, false) != null, "%s has a floor" % room)
	check_eq(HouseLayout.ROOMS.office.doorway_view, "", "the office is never entered in M1")
	check_eq(HouseLayout.ROOMS.hall_bath.doorway_view, "", "the hall bathroom is never entered in M1")
	var walls := house.get_node("BaseLayer").get_child_count()
	check(walls > 60, "walls, floors and ceilings built (%d pieces)" % walls)


func test_furniture_stands_in_the_room_the_floor_plan_puts_it() -> void:
	var house := _open_house()
	var expected := ["entry_table", "couch", "tv_console", "tv", "av_receiver", "speaker_left",
			"speaker_right", "dining_table", "counter_north_left", "counter_north_right",
			"counter_east", "counter_south", "sink", "fridge", "oven", "bed",
			"nightstand_lamp_side", "nightstand_list_side", "dresser_north", "dresser_east",
			"lounge_chair", "ottoman", "spare_boxes_west", "spare_boxes_east"]
	var ids: Array = HouseLayout.FURNITURE.map(func(item: Array) -> String: return item[0])
	for id in expected:
		check(id in ids, "%s is in the layout" % id)
	for item: Array in HouseLayout.FURNITURE:
		var centre: Vector3 = item[2]
		check_eq(HouseLayout.room_at(Vector2(centre.x, centre.z)), item[1], "%s's room" % item[0])
		check(house.find_child("Furniture_%s" % item[0], true, false) != null, "%s is built" % item[0])


# Furniture is gray blocks: nothing to tap (no buttons besides the rings and
# the chapter objects' tap areas, DAS-95). On moving day there is no chapter
# object, so only rings show.
func test_only_rings_and_chapter_objects_can_be_tapped() -> void:
	var house := _open_house(ALL_OPEN)
	await frames()
	var objects: Array = house._object_buttons.values()
	for button in house.find_children("*", "BaseButton", true, false):
		check(button in house._rings or button in objects, "%s is a ring or a chapter object" % button.name)
	for button: Button in objects:
		check(not button.visible, "%s can't be tapped on moving day" % button.name)


# --- Views and rings.

func test_all_18_views_exist_in_their_rooms() -> void:
	check_eq(HouseLayout.VIEWS.size(), 18, "number of views")
	for view in M1_VIEWS:
		if not check(HouseLayout.VIEWS.has(view), "view %s exists" % view):
			continue
		var data: Dictionary = HouseLayout.VIEWS[view]
		var stand: Vector2 = data.stand
		check(HouseLayout.room_at(stand) != "", "%s stands inside the House" % view)
	for room: String in HouseLayout.ROOMS:
		var doorway: String = HouseLayout.ROOMS[room].doorway_view
		if doorway != "":
			check_eq(HouseLayout.VIEWS[doorway].kind, "doorway", "%s's doorway view" % room)
			check_eq(HouseLayout.VIEWS[doorway].room, room, "%s's doorway view's room" % room)


func test_each_view_rings_every_doorway_in_its_room_its_other_wall_views_and_the_way_back() -> void:
	for view in M1_VIEWS:
		var room: String = HouseLayout.VIEWS[view].room
		var expected: Array[String] = []
		for door: String in HouseLayout.DOORS:
			var data: Dictionary = HouseLayout.DOORS[door]
			var next := ""
			if data.a == room:
				next = data.b
			elif data.b == room and not data.get("one_way", false):
				next = data.a
			if next != "" and HouseLayout.ROOMS[next].doorway_view != "":
				expected.append(HouseLayout.ROOMS[next].doorway_view)
		for other: String in HouseLayout.VIEWS:
			if other != view and HouseLayout.VIEWS[other].room == room \
					and HouseLayout.VIEWS[other].kind == "wall":
				expected.append(other)
		# From a wall view, back out to where the room was entered.
		var entered: String = HouseLayout.ROOMS[room].doorway_view
		if HouseLayout.VIEWS[view].kind == "wall":
			expected.append(entered)
		expected.sort()
		var got: Array[String] = []
		for ring in HouseLayout.rings_for(view, ALL_OPEN):
			got.append(ring.target)
		got.sort()
		check_eq(got, expected, "rings in %s with every door open" % view)
	# A few by name, from the floor plan.
	var living: Array[String] = []
	for ring in HouseLayout.rings_for("L1", ALL_OPEN):
		living.append(ring.target)
	living.sort()
	check_eq(living, ["E1", "H1", "K1", "L2", "L3", "L4"], "L1's rings")
	var bed_wall: Array[String] = []
	for ring in HouseLayout.rings_for("B2", ALL_OPEN):
		bed_wall.append(ring.target)
	check("B1" in bed_wall, "from the bed wall, back to the bedroom: %s" % [bed_wall])
	var hall_end: Array[String] = []
	for ring in HouseLayout.rings_for("H2", HouseTable.doors(HouseTable.START)):
		hall_end.append(ring.target)
	check("H1" in hall_end, "from the end of the hall, back to its front: %s" % [hall_end])


func test_from_each_view_every_ring_leads_to_the_view_it_names() -> void:
	var house := _open_house(ALL_OPEN)
	await frames()
	for view in M1_VIEWS:
		for i in HouseLayout.rings_for(view, ALL_OPEN).size():
			_stand_at(house, view)
			await frames()
			var ring: Dictionary = house._ring_data[i]
			var button: Button = house._rings[i]
			check(button.visible, "%s: ring to %s shown" % [view, ring.target])
			tap(button)
			await _finish_glide(house)
			check_eq(house._current, ring.target, "%s: tapping the ring to %s" % [view, ring.target])
			check(_same_place(house._camera.global_transform, HouseLayout.view_transform(ring.target)),
					"%s: camera at %s after the glide" % [view, ring.target])


func test_doorway_rings_are_solid_wall_rings_outlined_and_each_says_where_it_goes() -> void:
	var house := _open_house(ALL_OPEN)
	for view in M1_VIEWS:
		_stand_at(house, view)
		await frames()
		for i in house._ring_data.size():
			var ring: Button = house._rings[i]
			var data: Dictionary = house._ring_data[i]
			var style := ring.get_theme_stylebox("normal") as StyleBoxFlat
			var where := "%s: ring to %s" % [view, data.target]
			if data.door != "":
				check(style.bg_color.a >= 0.8, "%s (a doorway) is solid" % where)
			else:
				check(style.bg_color.a <= 0.2, "%s (a wall) is an outline" % where)
			check(style.border_width_left > 0, "%s has a rim" % where)
			check_eq(house.ring_label(ring).text, HouseLayout.VIEWS[data.target].label,
					"%s is labelled" % where)
	for view in M1_VIEWS:
		check(String(HouseLayout.VIEWS[view].get("label", "")) != "", "view %s has a label" % view)


func test_ring_labels_cannot_be_tapped() -> void:
	var house := _open_house()
	await frames()
	var ring: Button = house.ring_to("E1")
	check_eq(house.ring_label(ring).mouse_filter, Control.MOUSE_FILTER_IGNORE, "the label lets taps through")


func test_rings_stay_on_screen_at_least_44px_and_apart_from_every_view() -> void:
	var house := _open_house(ALL_OPEN)
	for screen in SCREENS:
		set_screen(screen)
		for view in M1_VIEWS:
			_stand_at(house, view)
			await frames(2)
			_check_rings(house, "%s at %s" % [screen, view], screen)


func _check_rings(house: Node, where: String, screen: Vector2i) -> void:
	var view := house.get_viewport().get_visible_rect()
	var to_screen := float(screen.x) / view.size.x
	var shown: Array[Rect2] = []
	for i in house._ring_data.size():
		var ring: Button = house._rings[i]
		var rect := ring.get_global_rect()
		var name: String = house._ring_data[i].target
		check(ring.visible, "%s: ring to %s visible" % [where, name])
		check(rect.size.x >= 44.0 and rect.size.y >= 44.0, "%s: ring to %s at least 44px" % [where, name])
		check(rect.size.x * to_screen >= 44.0, "%s: ring to %s at least 44px on the real screen" % [where, name])
		check(view.encloses(rect), "%s: ring to %s on screen (%s)" % [where, name, rect])
		var label: Label = house.ring_label(ring)
		var words := label.get_global_rect()
		check(label.visible and label.text != "", "%s: ring to %s has a label" % [where, name])
		check(view.encloses(words), "%s: label for %s on screen (%s)" % [where, name, words])
		if ring.text == "":
			check(words.position.y >= rect.end.y, "%s: label for %s under its ring" % [where, name])
		else:
			# Pinned: beside the ring, on the side towards the middle.
			var inward := words.position.x >= rect.end.x if ring.text == "‹" else words.end.x <= rect.position.x
			check(inward and absf(words.get_center().y - rect.get_center().y) < 1.0,
					"%s: label for pinned %s beside its ring" % [where, name])
		for other in shown:
			check(not rect.intersects(other) and not words.intersects(other),
					"%s: ring or label to %s overlaps another ring or label" % [where, name])
		shown.append(rect)
		shown.append(words)
	for i in range(house._ring_data.size(), house._rings.size()):
		check(not house._rings[i].visible, "%s: spare ring %d hidden" % [where, i])


func test_turning_the_phone_places_rings_on_what_they_lead_to_straight_away() -> void:
	var house := _open_house(ALL_OPEN)
	set_screen(Vector2i(1280, 720))
	_stand_at(house, "L1")
	await frames(2)
	for screen in [Vector2i(390, 844), Vector2i(844, 390), Vector2i(390, 844)]:
		set_screen(screen)
		# By the end of the frame the phone turned in, the rings fit its new
		# shape, with no glide or drag needed.
		await frames(1)
		var size := house.get_viewport().get_visible_rect().size
		check_eq(house._camera.keep_aspect,
				Camera3D.KEEP_WIDTH if size.y > size.x else Camera3D.KEEP_HEIGHT, "%s: camera shape" % screen)
		var ring: Button = house.ring_to("K1")
		if not check(ring != null and ring.text == "", "%s: the kitchen ring is in view" % screen):
			continue
		var at_once := ring.get_global_rect().get_center()
		# Placed again once things have settled, every ring stays put.
		await frames(2)
		house._place_rings()
		check(ring.get_global_rect().get_center().distance_to(at_once) < 1.0,
				"%s: the kitchen ring was right straight away (%s, then %s)"
				% [screen, at_once, ring.get_global_rect().get_center()])


func test_off_screen_rings_pin_to_the_edge_with_an_arrow() -> void:
	var house := _open_house(ALL_OPEN)
	await frames()
	# Looking into the en-suite from its doorway, the bedroom is behind you.
	_stand_at(house, "BA")
	await frames(2)
	var back: Button = house.ring_to("B1")
	if not check(back != null, "BA has a ring back to the bedroom"):
		return
	check(back.text == "‹" or back.text == "›", "the ring behind you shows an arrow (%s)" % back.text)
	var screen := house.get_viewport().get_visible_rect().size
	var centre := back.get_global_rect().get_center()
	check(centre.x < screen.x * 0.25 or centre.x > screen.x * 0.75, "it sits at a side edge (%s)" % centre)
	# A ring on something in view has no arrow.
	_stand_at(house, "H1")
	await frames(2)
	var spare: Button = house.ring_to("S1")
	check(spare != null and spare.text == "", "the spare room door ahead has a plain ring")


# --- Moving.

func test_the_house_starts_on_the_porch_facing_the_front_door() -> void:
	var house := _open_house()
	check_eq(house._current, "P", "starting view")
	check(_same_place(house._camera.global_transform, HouseLayout.view_transform("P")), "camera on the porch")
	check_eq(_ring_targets(house), ["E1"], "the only way is in through the front door")


func test_a_glide_takes_two_seconds() -> void:
	var house := _open_house()
	await frames()
	var from: Transform3D = house._camera.global_transform
	tap(house.ring_to("E1"))
	check_eq(house._current, "E1", "heading for the entry")
	house._tween.custom_step(1.0)
	var mid: Transform3D = house._camera.global_transform
	check(not _same_place(mid, from) and not _same_place(mid, HouseLayout.view_transform("E1")),
			"halfway, between the two views")
	house._tween.custom_step(0.5)
	check(not _same_place(house._camera.global_transform, HouseLayout.view_transform("E1")),
			"not there after 1.5 s")
	house._tween.custom_step(0.6)
	check(_same_place(house._camera.global_transform, HouseLayout.view_transform("E1")),
			"there after 2.1 s")
	check_near(house.GLIDE_SECONDS, 2.0, 1e-6, "glide time")


# Going through a doorway, the camera stays in the two rooms or the doorway
# itself: it never passes through a wall.
func test_glides_through_doorways_never_pass_through_a_wall() -> void:
	for view in M1_VIEWS:
		for ring in HouseLayout.rings_for(view, ALL_OPEN):
			if ring.door == "":
				continue
			var door: Dictionary = HouseLayout.DOORS[ring.door]
			var rooms := [HouseLayout.room_at(HouseLayout.VIEWS[view].stand),
					HouseLayout.room_at(HouseLayout.VIEWS[ring.target].stand)]
			var house := _open_house(ALL_OPEN)
			_stand_at(house, view)
			house._go_to(ring.target, ring.door)
			var near_door := false
			for step in 200:
				house._tween.custom_step(house.GLIDE_SECONDS / 200.0)
				var at: Vector3 = house._camera.global_transform.origin
				var floor_point := Vector2(at.x, at.z)
				var in_doorway: bool = floor_point.distance_to(door.at) <= door.width / 2.0
				near_door = near_door or floor_point.distance_to(door.at) < 0.1
				check(in_doorway or HouseLayout.room_at(floor_point) in rooms,
						"%s to %s: step %d at %s is in %s or the doorway" % [view, ring.target, step,
						floor_point, rooms])
			if rooms[0] != rooms[1]:
				check(near_door, "%s to %s passes through the middle of the doorway" % [view, ring.target])
			house.free()


# Rings hide while gliding, so a glide can't be turned mid-way through a wall,
# and come back on arrival.
func test_rings_hide_during_a_glide_and_come_back_on_arrival() -> void:
	var house := _open_house()
	await frames()
	tap(house.ring_to("E1"))
	house._tween.custom_step(0.6)
	await frames()
	check(house._rings.all(func(ring: Button) -> bool: return not ring.visible), "no rings mid-glide")
	check(house.ring_to("E2") == null, "nothing to tap mid-glide")
	await _finish_glide(house)
	check(house.ring_to("E2") != null and house.ring_to("E2").visible, "the entry's rings on arrival")
	check(house.ring_to("L1") != null, "and its doorway to the living room")


# The camera never backs up: through every doorway, it keeps getting closer.
func test_glides_through_doorways_never_back_up() -> void:
	for view in M1_VIEWS:
		for ring in HouseLayout.rings_for(view, ALL_OPEN):
			if ring.door == "":
				continue
			var house := _open_house(ALL_OPEN)
			_stand_at(house, view)
			house._go_to(ring.target, ring.door)
			var goal := HouseLayout.view_transform(ring.target).origin
			var last := INF
			for step in 20:
				house._tween.custom_step(house.GLIDE_SECONDS / 20.0)
				var left: float = house._camera.global_transform.origin.distance_to(goal)
				check(left <= last + 0.05, "%s to %s: no backing up at step %d (%.2f m, was %.2f m)"
						% [view, ring.target, step, left, last])
				last = left
			house.free()


func test_a_short_drag_looks_around_a_little_and_the_next_glide_resets_it() -> void:
	var house := _open_house()
	await frames()
	tap(house.ring_to("E1"))
	await _finish_glide(house)
	var still: Transform3D = house._camera.global_transform
	var drag := InputEventMouseMotion.new()
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	drag.relative = Vector2(-4000.0, 4000.0)
	drag.position = Vector2(640, 360)
	get_viewport().push_input(drag, true)
	var turned: Transform3D = house._camera.global_transform
	check(turned.origin.distance_to(still.origin) < 0.001, "dragging doesn't move the camera")
	var angle := turned.basis.z.angle_to(still.basis.z)
	check(angle > deg_to_rad(5.0), "dragging turns the view (%.1f°)" % rad_to_deg(angle))
	check(angle < deg_to_rad(25.0), "but only a little (%.1f°)" % rad_to_deg(angle))
	tap(house.ring_to("L1"))
	await _finish_glide(house)
	check(_same_place(house._camera.global_transform, HouseLayout.view_transform("L1")),
			"the next view is framed as it should be")


# Tap is the only verb: keys and mouse movement without a press do nothing.
func test_keys_and_hover_do_nothing() -> void:
	var house := _open_house()
	await frames()
	tap(house.ring_to("E1"))
	await _finish_glide(house)
	var still: Transform3D = house._camera.global_transform
	for key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_LEFT, KEY_SPACE, KEY_ENTER]:
		var press := InputEventKey.new()
		press.keycode = key
		press.physical_keycode = key
		press.pressed = true
		get_viewport().push_input(press, true)
		var release := press.duplicate() as InputEventKey
		release.pressed = false
		get_viewport().push_input(release, true)
	var hover := InputEventMouseMotion.new()
	hover.relative = Vector2(300.0, 200.0)
	hover.position = Vector2(640, 360)
	get_viewport().push_input(hover, true)
	await frames()
	check_eq(house._current, "E1", "still in the entry")
	check(_same_place(house._camera.global_transform, still), "camera hasn't moved")
	for ring: Button in house._rings:
		check_eq(ring.focus_mode, Control.FOCUS_NONE, "rings take no keyboard focus")
		check(ring.get_theme_stylebox("hover") == ring.get_theme_stylebox("normal"),
				"a ring looks the same hovered or not")
		check(ring.get_theme_color("font_hover_color") == ring.get_theme_color("font_color"),
				"a ring's arrow looks the same hovered or not")


# --- Doors, from the story point.

func test_at_the_start_every_open_view_can_be_reached_and_the_living_room_always() -> void:
	var doors := HouseTable.doors(HouseTable.START)
	var reached := HouseLayout.reachable("P", doors)
	reached.sort()
	check_eq(reached, ["E1", "E2", "K1", "K2", "K3", "L1", "L2", "L3", "L4", "P"],
			"views reached at the start: porch, entry, living room and kitchen")
	for view in reached:
		var onward := HouseLayout.reachable(view, doors)
		check(onward.any(func(v: String) -> bool: return HouseLayout.VIEWS[v].room == "living_room"),
				"the living room can be reached from %s" % view)


func test_with_the_hall_open_the_bedroom_can_be_reached_and_the_living_room_always() -> void:
	# After the opening beat, arriving in the living room.
	var doors := HouseTable.doors(HouseTable.AFTER_OPENING)
	var reached := HouseLayout.reachable("L1", doors)
	for view in ["H1", "B1", "B2", "B3", "BA"]:
		check(view in reached, "%s can be reached with the hall open" % view)
	for view in ["C1", "S1", "P"]:
		check(not view in reached, "%s stays out of reach (boxes, shut doors)" % view)
	for view in reached:
		var onward := HouseLayout.reachable(view, doors)
		check("L1" in onward, "the living room can be reached from %s" % view)


func test_doors_are_real_door_sizes_and_fit_their_wall_openings() -> void:
	# Oversized doors make rooms read small (Dan, 2026-10-24).
	for door_id: String in HouseLayout.DOORS:
		var door: Dictionary = HouseLayout.DOORS[door_id]
		if not door.get("panel", false):
			continue
		check(door.width >= 0.7 and door.width <= 0.95, "%s is a real door's width (%s m)" % [door_id, door.width])
		var found := false
		for wall: Dictionary in HouseLayout.WALLS:
			var along_x: bool = is_equal_approx(wall.from.y, wall.to.y)
			var on_line: bool = is_equal_approx(wall.from.y, door.at.y) if along_x else is_equal_approx(wall.from.x, door.at.x)
			if not on_line:
				continue
			var middle: float = door.at.x if along_x else door.at.y
			for opening: Array in wall.openings:
				if opening.size() < 5 and opening[0] < middle and middle < opening[1]:
					found = true
					check(is_equal_approx(opening[1] - opening[0], door.width),
							"%s's wall opening is as wide as the door" % door_id)
		check(found, "%s has an opening in a wall" % door_id)
	check(HouseLayout.DOOR_HEIGHT < 2.1, "doors are a real door's height")


# How much of the screen a box covers: the share of a grid of screen points
# whose ray from the camera hits it before any wall.
func _screen_share(house: Node, box: MeshInstance3D) -> float:
	var camera: Camera3D = house._camera
	var size := house.get_viewport().get_visible_rect().size
	var walls := house.get_node("BaseLayer").find_children("*", "MeshInstance3D", true, false)
	var hits := 0
	var count := 0
	for col in 32:
		for row in 18:
			count += 1
			var point := Vector2((col + 0.5) / 32.0 * size.x, (row + 0.5) / 18.0 * size.y)
			var from := camera.project_ray_origin(point)
			var dir := camera.project_ray_normal(point)
			var at := _ray_distance(from, dir, box)
			if at == INF:
				continue
			var hidden := false
			for wall: MeshInstance3D in walls:
				if _ray_distance(from, dir, wall) < at:
					hidden = true
					break
			if not hidden:
				hits += 1
	return float(hits) / count


# How far along a ray a box is, or INF if the ray misses it.
static func _ray_distance(from: Vector3, dir: Vector3, mesh: MeshInstance3D) -> float:
	var to_box := mesh.global_transform.affine_inverse()
	var local_from := to_box * from
	var local_dir := to_box.basis * dir
	var box := mesh.get_aabb()
	var near := 0.0
	var far := INF
	for axis in 3:
		if absf(local_dir[axis]) < 1e-6:
			if local_from[axis] < box.position[axis] or local_from[axis] > box.end[axis]:
				return INF
			continue
		var t1 := (box.position[axis] - local_from[axis]) / local_dir[axis]
		var t2 := (box.end[axis] - local_from[axis]) / local_dir[axis]
		near = maxf(near, minf(t1, t2))
		far = minf(far, maxf(t1, t2))
	return near if near <= far else INF


func test_an_open_door_swings_out_of_the_view_through_it() -> void:
	var house := _open_house(ALL_OPEN)
	await frames()
	var screen := house.get_viewport().get_visible_rect().size
	for door_id: String in HouseLayout.DOORS:
		var door: Dictionary = HouseLayout.DOORS[door_id]
		var view: String = HouseLayout.ROOMS[door.b].doorway_view
		if not door.get("panel", false) or view == "":
			continue
		_stand_at(house, view)
		var pivot: Node3D = house.find_child("Door_%s" % door_id, true, false)
		# The front door opens as the player goes in.
		pivot.rotation.y = house._open_angle(door_id)
		var panel: MeshInstance3D = pivot.get_child(0)
		check(_screen_share(house, panel) < 0.15, "%s: the open %s takes at most a sliver of the view (%d%%)"
				% [view, door_id, roundi(_screen_share(house, panel) * 100.0)])


func test_shut_and_blocked_doors_cannot_be_gone_through() -> void:
	var house := _open_house({}, HouseTable.START)
	await frames()
	_stand_at(house, "L1")
	check(house.ring_to("H1") == null, "boxes in the back-hall opening: no ring to the hall")
	check(house.find_child("Boxes_hall_opening", true, false) != null, "the boxes are there")
	var doors: Dictionary = house.door_states
	check(not HouseLayout.can_pass("spare_room_door", "back_hall", doors), "the spare room door is shut")
	check(not HouseLayout.can_pass("hall_bath_door", "back_hall", doors), "the hall bathroom is shut")
	check(not HouseLayout.can_pass("bedroom_door", "back_hall", doors), "the bedroom door is shut")
	check(not HouseLayout.can_pass("closet_door", "bedroom", doors), "the closet is closed")
	check(not HouseLayout.can_pass("front_door", "entry", doors), "no way back out to the porch")
	var spare: Node3D = house.find_child("Door_spare_room_door", true, false)
	check(spare != null and is_zero_approx(spare.rotation.y), "the spare room door panel is closed")
	# The office never opens in M1, even if its door were open: no view inside.
	check(not HouseLayout.can_pass("office_door", "back_hall", ALL_OPEN), "the office has no view to go to")
	check(not HouseLayout.can_pass("hall_bath_door", "back_hall", ALL_OPEN), "the hall bathroom has no view to go to")


func test_an_unknown_story_point_is_reported_and_shows_the_start() -> void:
	expect_error("no story point 'nowhere'")
	var house := _open_house({}, &"nowhere")
	check_eq(house.story_point, HouseTable.START, "the start instead")
	check_eq(house.door_states, HouseTable.doors(HouseTable.START), "the start's doors")


func test_which_doors_are_open_comes_from_the_story_point() -> void:
	var start := _open_house({}, &"start")
	await frames()
	_stand_at(start, "L1")
	check(start.ring_to("H1") == null, "start: the hall is blocked")
	start.free()
	var opened := _open_house({}, HouseTable.AFTER_OPENING)
	await frames()
	_stand_at(opened, "L1")
	check(opened.ring_to("H1") != null, "hall open: a ring to the hall")
	check(opened.find_child("Boxes_hall_opening", true, false) == null, "hall open: no boxes in the way")
	check(opened.find_child("Boxes_office_door", true, false) != null, "hall open: boxes against the office")
	check(opened.find_child("Boxes_closet_door", true, false) != null, "hall open: boxes in front of the closet")
	var custom := _open_house({"front_door": "open", "entry_opening": "shut"})
	await frames()
	_stand_at(custom, "E1")
	check(custom.ring_to("L1") == null, "a door shut by the state passed in has no ring")


func test_door_states_and_the_arrival_room_come_from_the_core_table() -> void:
	var arrivals := {HouseTable.START: "P", HouseTable.AFTER_OPENING: "L1",
			HouseTable.AFTER_PARTNER: "B1", HouseTable.AFTER_LOSS: "E1"}
	for point: StringName in HouseTable.POINTS:
		var house := _open_house({}, point)
		await frames()
		check_eq(house.door_states, HouseTable.doors(point), "%s: the table's doors" % point)
		check_eq(house._current, arrivals[point], "%s: arrives at the table's room" % point)
		check(_same_place(house._camera.global_transform, HouseLayout.view_transform(arrivals[point])),
				"%s: the camera is there" % point)
		house.free()
	# Through the story, the rooms the table opens are the ones you can reach.
	var partner := HouseLayout.reachable("B1", HouseTable.doors(HouseTable.AFTER_PARTNER))
	for view in ["C1", "S1", "L1", "K1"]:
		check(view in partner, "after the Partner: %s can be reached" % view)
	var loss := HouseLayout.reachable("E1", HouseTable.doors(HouseTable.AFTER_LOSS))
	check(not "S1" in loss, "after the Loss: the spare room is shut")
	check("B1" in loss and "C1" in loss, "after the Loss: the bedroom and closet stay open")


func test_with_no_story_point_set_the_house_shows_the_players_own() -> void:
	var house := HOUSE.instantiate()
	add_child(house)
	var point: StringName = get_node("/root/GameState").house_point()
	check_eq(house.story_point, point, "the player's story point")
	check_eq(house.door_states, HouseTable.doors(point), "and its doors")
	house.free()


func test_the_house_doors_and_rooms_are_the_core_tables() -> void:
	var ids: Array = HouseLayout.DOORS.keys()
	var table_ids: Array = []
	for door: StringName in HouseTable.DOORS:
		table_ids.append(String(door))
		if not check(HouseLayout.DOORS.has(String(door)), "the House has the table's %s" % door):
			continue
		var built: Dictionary = HouseLayout.DOORS[String(door)]
		var rooms := [String(HouseTable.DOORS[door].from), String(HouseTable.DOORS[door].to)]
		rooms.sort()
		var built_rooms := [built.a, built.b]
		built_rooms.sort()
		check_eq(built_rooms, rooms, "%s joins the table's rooms" % door)
	ids.sort()
	table_ids.sort()
	check_eq(ids, table_ids, "no door the table doesn't know")
	for room: StringName in HouseTable.ROOMS:
		check(HouseLayout.ROOMS.has(String(room)), "the House builds the table's %s" % room)


# --- Light.

func test_lamp_light_and_ordinary_fog_only() -> void:
	var house := _open_house()
	var env: Environment = house._world_env.environment
	check(env.fog_enabled, "ordinary fog on")
	check(not env.volumetric_fog_enabled, "no volumetric fog")
	check(house._world_env.compositor == null, "no CompositorEffects on the world")
	check(house._camera.compositor == null, "no CompositorEffects on the camera")
	var lights := house.get_node("LightingLayer").find_children("*", "Light3D", true, false)
	for light: Light3D in lights:
		check(light is OmniLight3D and light.name.begins_with("Lamp_"), "%s is a lamp" % light.name)
	check(house.find_children("*", "Light3D", true, false).size() == lights.size(),
			"no light outside the lamps")
	var lamps := house.get_node("LightingLayer").find_children("Lamp_*", "OmniLight3D", false, false)
	check(lamps.size() >= 9, "a lamp in each room that can be seen (%d)" % lamps.size())
	for lamp: OmniLight3D in lamps:
		check(not lamp.shadow_enabled, "%s has no shadows" % lamp.name)
