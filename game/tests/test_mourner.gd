extends TestCase
## The Mourner (DAS-136), on the chapter's own clock instead of real time.
## Rules from docs/design/story-beats.md §7, epic-6-stories.md and the
## ticket's acceptance criteria. How dragging feels under a thumb, whether
## the old things read as levity and whether the memory box lands are Dan's
## to check on his phone.

const MOURNER := preload("res://scenes/chapters/mourner/mourner.tscn")
const MournerRoom := preload("res://scenes/chapters/mourner/mourner_room.gd")
const Stage := MournerRoom.Stage
const MENU := preload("res://scenes/ui/m0_menu.tscn")
const STEP := 0.1
const OLD_THINGS: Array[StringName] = [&"poster", &"guitar", &"games_box", &"tshirts_box", &"stuff_box"]

var _mourner: Node
var _finishes := []


func before_each() -> void:
	_mourner = add_scene(MOURNER)
	_mourner.auto_advance = false
	_finishes.clear()
	_mourner.finished.connect(func(...args: Array) -> void: _finishes.append(args))


# --- Helpers

func _room() -> RefCounted:
	return _mourner.room()


func _run(seconds: float, chapter: Node = null) -> void:
	var who := chapter if chapter else _mourner
	for k in roundi(seconds / STEP):
		if not is_instance_valid(who):
			return
		who.advance(STEP)


func _run_until(stage: int, limit: float) -> bool:
	var spent := 0.0
	while _room().stage != stage and spent < limit:
		_mourner.advance(STEP)
		spent += STEP
	return _room().stage == stage


## A finger (or the mouse) pressed on `from`, moved in steps to `to`, and lifted.
func _drag(from: Vector2, to: Vector2, lift := true) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.button_mask = MOUSE_BUTTON_MASK_LEFT
	down.position = from
	down.global_position = from
	down.pressed = true
	get_viewport().push_input(down, true)
	var last := from
	for k in range(1, 9):
		var point := from.lerp(to, k / 8.0)
		var move := InputEventMouseMotion.new()
		move.button_mask = MOUSE_BUTTON_MASK_LEFT
		move.position = point
		move.global_position = point
		move.relative = point - last
		last = point
		get_viewport().push_input(move, true)
	if not lift:
		return
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	up.button_mask = 0
	up.position = last
	up.global_position = last
	get_viewport().push_input(up, true)


## Drags a thing from its middle to the middle of its place, as a player would.
func _put_away(id: StringName, chapter: Node = null) -> void:
	var who := chapter if chapter else _mourner
	var to: StringName = MournerRoom.thing(id).to
	_drag(who.thing_rect(id).get_center(), who.place_rect(to).get_center())


## Plays the whole room, the old things in `order`.
func _play(order: Array[StringName], chapter: Node = null) -> void:
	var who := chapter if chapter else _mourner
	_run(MournerRoom.DOOR_TIME + STEP, who)
	for id in order:
		_put_away(id, who)
		_run(0.5, who)
	_run(MournerRoom.FOUND_TIME + STEP, who)
	_put_away(&"memory_box", who)
	_run(MournerRoom.LIGHT_TIME + MournerRoom.COME_IN_TIME + STEP, who)
	_put_away(&"monitor", who)
	_run(MournerRoom.COME_IN_TIME + STEP, who)
	_put_away(&"crib", who)


func _all_nodes(node: Node, out: Array = []) -> Array:
	out.append(node)
	for child in node.get_children():
		_all_nodes(child, out)
	return out


# --- Opening it

func test_the_menu_opens_the_mourner_through_the_chapter_runner() -> void:
	_mourner.free()  # So it can't take the menu's taps.
	var menu := add_scene(MENU)
	tap(menu.get_node("%BeginButton"))
	await frames()
	var button: Control = menu.get_node("%MournerButton")
	check(button.size.x >= 44.0 and button.size.y >= 44.0, "Mourner button is at least 44px")
	check_eq(button.text, "The Mourner (rough)", "the button's words")
	tap(button)
	var runner := ChapterRunner.of(get_tree())
	check_eq(runner.current_chapter(), &"mourner", "the runner is playing the Mourner")
	var mourner: Node = runner.get_child(0) if runner.get_child_count() > 0 else null
	if check(mourner != null and mourner.scene_file_path == MOURNER.resource_path, "the Mourner opened"):
		check(not menu.visible, "menu hidden while the Mourner plays")
		mourner.finished.emit()
		await frames()
		check(menu.visible, "menu back after the Mourner finished")
		check_eq(menu.get_node("%Status").text, "Finished mourner (answer: none)", "menu heard the result")
	runner.free()


func test_the_chapter_list_has_the_mourner() -> void:
	check_eq(ChapterList.scene_path(&"mourner"), MOURNER.resource_path, "the Mourner's scene")


# --- Picking up and putting down

func test_pressing_a_thing_picks_it_up_and_a_ghost_follows_the_finger() -> void:
	await frames()
	_run(MournerRoom.DOOR_TIME + STEP)
	var start: Rect2 = _mourner.thing_rect(&"poster")
	var to := start.get_center() + Vector2(200, 150)
	_drag(start.get_center(), to, false)
	check_eq(_mourner.held(), &"poster", "the poster is held")
	var ghost: Rect2 = _mourner.ghost_rect()
	check(ghost.has_point(to), "the ghost is under the finger")
	check_near(ghost.size.x, start.size.x, 0.5, "the ghost is the thing's size")
	check_eq(_mourner.thing_rect(&"poster"), start, "the thing itself stays where it was (shown faint) while held")
	for node in _all_nodes(_mourner):
		check(not (node is GridContainer or node is ItemList or node is FlowContainer),
				"no inventory grid: %s is a %s" % [node.name, node.get_class()])


func test_a_drop_where_it_cant_stay_slides_back_and_shakes() -> void:
	await frames()
	_run(MournerRoom.DOOR_TIME + STEP)
	var home: Rect2 = _mourner.thing_rect(&"games_box")
	var wrong: Vector2 = _mourner.place_rect(&"giveaway").get_center()  # The games are stored.
	_drag(home.get_center(), wrong)
	check(not &"games_box" in _room().placed, "not placed")
	check(_mourner.is_going_back(&"games_box"), "it goes back")
	# More than colour: it moves home, shaking from side to side on the way.
	var turns := 0
	var last_x: float = _mourner.back_position(&"games_box").x
	var last_step := 0.0
	for k in 40:
		_mourner.advance(0.02)
		if not _mourner.is_going_back(&"games_box"):
			break
		var x: float = _mourner.back_position(&"games_box").x
		if last_step != 0.0 and signf(x - last_x) != signf(last_step):
			turns += 1
		last_step = x - last_x
		last_x = x
	check(turns >= 2, "it shakes as it goes back (%d turns)" % turns)
	_run(1.0)
	check(not _mourner.is_going_back(&"games_box"), "it got back")
	check_eq(_mourner.thing_rect(&"games_box"), home, "it is back where it started")
	check(&"games_box" in _room().movable(), "and can be picked up again")


func test_a_drop_on_its_place_sets_it_down_softly_with_a_household_sound() -> void:
	await frames()
	_run(MournerRoom.DOOR_TIME + STEP)
	_put_away(&"guitar")
	check(&"guitar" in _room().placed, "the guitar is placed")
	check(_mourner.is_settling(&"guitar"), "it settles softly")
	check_eq(_mourner.last_sound(), "place", "a soft knock")
	_put_away(&"tshirts_box")
	check_eq(_mourner.last_sound(), "bag", "a rustle into the bag")
	_run(1.0)
	check(not _mourner.is_settling(&"guitar"), "settled")
	check_eq(_mourner.thing_rect(&"guitar"), _mourner.place_rect(&"guitar_wall"), "the guitar is in its place")


func test_a_tap_alone_moves_nothing() -> void:
	await frames()
	_run(MournerRoom.DOOR_TIME + STEP)
	tap(_mourner)  # Wherever: nothing moves on a tap.
	tap_at(_mourner.thing_rect(&"poster").get_center())
	check_eq(_room().placed, [] as Array[StringName], "nothing placed")
	check_eq(_mourner.held(), &"", "nothing held")


func test_things_and_places_at_least_44_points_and_on_screen_on_laptop_and_phones() -> void:
	for screen in [Vector2i(1280, 720), Vector2i(393, 852), Vector2i(852, 393)]:
		set_screen(screen)
		await frames(2)
		var view := get_viewport().get_visible_rect()
		var units_per_point := view.size.y / float(mini(screen.x, screen.y)) \
				if screen.x > screen.y else view.size.x / float(screen.x)
		var min_units := 44.0 * units_per_point
		for t: Dictionary in MournerRoom.THINGS:
			var r: Rect2 = _mourner.thing_rect(t.id)
			check(r.size.x >= min_units and r.size.y >= min_units,
					"%s at least 44 points on %s (is %s, needs %.0f)" % [t.id, screen, r.size, min_units])
			check(view.encloses(r), "%s on screen on %s" % [t.id, screen])
		for place: StringName in MournerRoom.PLACES:
			var r: Rect2 = _mourner.place_rect(place)
			check(r.size.x >= min_units and r.size.y >= min_units,
					"place %s at least 44 points on %s" % [place, screen])
			check(view.encloses(r), "place %s on screen on %s" % [place, screen])


func test_no_place_overlaps_another() -> void:
	var places := MournerRoom.PLACES.keys()
	for a in places.size():
		for b in range(a + 1, places.size()):
			check(not (MournerRoom.PLACES[places[a]] as Rect2).intersects(MournerRoom.PLACES[places[b]]),
					"%s and %s are apart" % [places[a], places[b]])


# --- The beats

func test_the_beats_come_in_order() -> void:
	await frames()
	check_eq(_room().stage, Stage.DOOR, "the door opens first")
	check_eq(_room().movable(), [] as Array[StringName], "nothing to move while the door opens")
	_run(MournerRoom.DOOR_TIME + STEP)
	check_eq(_room().stage, Stage.OLD_THINGS, "Leo's old things")
	check_eq(_room().movable(), OLD_THINGS, "only the old things can be moved")
	check(not &"memory_box" in _room().visible_unplaced(), "the memory box is under the boxes, not seen yet")
	_run(5.0)
	var full_before: float = _mourner.sound_level("full")
	for id in OLD_THINGS.slice(0, 4):
		_put_away(id)
	check_eq(_room().stage, Stage.OLD_THINGS, "still the old things with one left")
	check(not &"memory_box" in _room().movable(), "the memory box can't be found before the old things are cleared")
	_put_away(OLD_THINGS[4])
	check_eq(_room().stage, Stage.MEMORY_BOX, "then the memory box")
	check(&"memory_box" in _room().visible_unplaced(), "found under the boxes")
	check_eq(_room().movable(), [] as Array[StringName], "coming out from under them")
	_run(MournerRoom.FOUND_TIME + STEP)
	check_eq(_room().movable(), [&"memory_box"] as Array[StringName], "then only the memory box")
	check(full_before > 0.9 and _mourner.sound_level("full") < 0.05, "the music thins (%.2f to %.2f)" % [full_before, _mourner.sound_level("full")])
	check(_mourner.sound_level("thin") > 0.9, "but doesn't stop")
	_put_away(&"memory_box")
	check_eq(MournerRoom.thing(&"memory_box").to, &"high_shelf", "it goes to the high shelf")
	check_eq(_room().stage, Stage.LIGHT, "then the empty room")
	var light_before: float = _room().light
	_run(MournerRoom.LIGHT_TIME + STEP)
	check(_room().light > 0.99 and light_before < 0.4, "in good light")
	check_eq(_room().stage, Stage.MONITOR, "then the monitor comes in")
	check(not &"crib" in _room().movable(), "not the crib yet")
	_run(MournerRoom.COME_IN_TIME + STEP)
	_put_away(&"monitor")
	check_eq(_room().stage, Stage.CRIB, "then the crib")
	_run(MournerRoom.COME_IN_TIME + STEP)
	_put_away(&"crib")
	check_eq(_room().placed.back(), &"crib", "the crib is the last placement")
	check_eq(_room().stage, Stage.ENDING, "a held moment")
	check_eq(_finishes.size(), 0, "not finished yet")
	_run(MournerRoom.ENDING_TIME + STEP)
	check_eq(_finishes.size(), 1, "finished")


func test_the_room_ends_the_same_whatever_order_things_went_in() -> void:
	await frames()
	_play(OLD_THINGS)
	var first: Dictionary = _room().layout()
	check_eq(first.size(), MournerRoom.THINGS.size(), "everything placed")
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	for k in 4:
		var order: Array[StringName] = OLD_THINGS.duplicate()
		for i in range(order.size() - 1, 0, -1):  # Shuffle.
			var j := rng.randi_range(0, i)
			var swap := order[i]
			order[i] = order[j]
			order[j] = swap
		var other := add_scene(MOURNER)
		other.auto_advance = false
		_play(order, other)
		check_eq(other.room().layout(), first, "the same room after %s" % [order])
		for t: Dictionary in MournerRoom.THINGS:
			check_eq(other.room().rect_of(t.id), _room().rect_of(t.id), "%s in the same spot" % t.id)
		other.free()


func test_what_remains_is_the_nursery() -> void:
	await frames()
	_play(OLD_THINGS)
	var layout: Dictionary = _room().layout()
	check_eq(layout.get("crib"), "crib_spot", "the crib")
	check_eq(layout.get("monitor"), "monitor_shelf", "the monitor")
	check_eq(layout.get("memory_box"), "high_shelf", "the memory box on the high shelf")
	check_eq(layout.get("guitar"), "guitar_wall", "the guitar kept on the wall (a proposal)")


func test_the_chapter_shows_no_words() -> void:
	await frames()
	_run(30.0)
	for node in _all_nodes(_mourner):
		check(not (node is Label or node is RichTextLabel or node is Button or node is Window or node is AcceptDialog
				or node is LineEdit or node is TextEdit),
				"no words or popups: %s is a %s" % [node.name, node.get_class()])
		if node is Control:
			check_eq((node as Control).tooltip_text, "", "%s has no tooltip" % node.name)
	for path in ["res://scenes/chapters/mourner/mourner.gd", "res://scenes/chapters/mourner/mourner_room.gd"]:
		var source := FileAccess.get_file_as_string(path)
		for drawing_words in ["draw_string", "draw_char", "draw_multiline_string", "Label.new", "tooltip"]:
			check(not source.contains(drawing_words), "%s draws no words (%s)" % [path.get_file(), drawing_words])


# --- Nobody gets stuck

func test_after_a_while_without_a_placement_the_next_place_is_shown() -> void:
	await frames()
	_run(MournerRoom.DOOR_TIME + STEP)
	_run(MournerRoom.HINT_AFTER - 1.0)
	check_eq(_room().hint(), &"", "no hint at first")
	_run(1.5)
	check_eq(_room().hint(), &"poster", "the next thing's place is shown")
	_put_away(&"poster")
	check_eq(_room().hint(), &"", "a placement clears it")
	_run(MournerRoom.HINT_AFTER + 0.5)
	check_eq(_room().hint(), &"guitar", "and it comes back for the next thing")


func test_a_slow_player_is_shown_every_place_and_finishes() -> void:
	await frames()
	var spent := 0.0
	while not _room().is_done() and spent < 600.0:
		var hint: StringName = _room().hint()
		if hint != &"":
			_put_away(hint)  # Follows the hint and nothing else.
		_mourner.advance(STEP)
		spent += STEP
	check(_room().is_done(), "finished in %.0f s by following the hints" % spent)
	check_eq(_finishes.size(), 1, "reported finished")


# --- One result, no save

func test_it_reports_finished_exactly_once_with_no_answer() -> void:
	await frames()
	_play(OLD_THINGS)
	_run(MournerRoom.ENDING_TIME + 5.0)
	check_eq(_finishes, [[]], "finished once, with nothing")


func test_finishing_hands_back_one_result_with_no_answer_through_the_runner() -> void:
	_mourner.free()
	var house := Control.new()
	add_child(house)
	var runner := ChapterRunner.of(get_tree())
	var results := []
	var left := []
	var on_finished := func(result: Dictionary) -> void: results.append(result)
	var on_left := func(id: StringName) -> void: left.append(id)
	runner.chapter_finished.connect(on_finished)
	runner.chapter_left.connect(on_left)
	check(runner.enter(&"mourner", house), "entered")
	var mourner: Node = runner.get_child(0)
	mourner.auto_advance = false
	await frames()
	_play(OLD_THINGS, mourner)
	_run(MournerRoom.ENDING_TIME + 1.0, mourner)
	await frames()
	check_eq(results, [{"chapter": "mourner", "answer": ""}], "one result, no answer")
	check(ChapterResult.is_story_result(results[0]) if results.size() > 0 else false, "a real story result")
	check_eq(left, [], "not counted as leaving")
	check(house.visible, "the House is back")
	runner.chapter_finished.disconnect(on_finished)
	runner.chapter_left.disconnect(on_left)
	runner.free()


func test_leaving_part_way_gives_no_result_or_save_and_the_next_visit_starts_full() -> void:
	_mourner.free()
	var state := get_node("/root/GameState")
	var saved_before: Dictionary = state.to_save_data()
	var house := Control.new()
	add_child(house)
	var runner := ChapterRunner.of(get_tree())
	var results := []
	var left := []
	var on_finished := func(result: Dictionary) -> void: results.append(result)
	var on_left := func(id: StringName) -> void: left.append(id)
	runner.chapter_finished.connect(on_finished)
	runner.chapter_left.connect(on_left)
	runner.enter(&"mourner", house)
	var mourner: Node = runner.get_child(0)
	mourner.auto_advance = false
	await frames()
	_run(MournerRoom.DOOR_TIME + STEP, mourner)
	_put_away(&"poster", mourner)
	_put_away(&"guitar", mourner)
	check_eq(mourner.room().placed.size(), 2, "part-way in")
	mourner.queue_free()  # Leaving: the page closed, say.
	await frames()
	check_eq(results, [], "no result")
	check_eq(left, [&"mourner"], "it left")
	check_eq(state.to_save_data(), saved_before, "nothing saved")
	runner.enter(&"mourner", house)
	var again: Node = runner.get_child(0)
	check_eq(again.room().stage, Stage.DOOR, "the next visit starts at the door")
	check_eq(again.room().placed, [] as Array[StringName], "with the room full again")
	runner.chapter_finished.disconnect(on_finished)
	runner.chapter_left.disconnect(on_left)
	runner.free()


func test_the_chapter_never_touches_the_house_another_chapter_or_saved_state() -> void:
	for path in ["res://scenes/chapters/mourner/mourner.gd", "res://scenes/chapters/mourner/mourner_room.gd"]:
		var source := FileAccess.get_file_as_string(path)
		# Comments may talk about the House; the code may not reach it.
		for forbidden in ["GameState", "/root/", "HouseTable", "house_", "scenes/house", "SaveFile",
				"user://", "chapters/partner", "chapters/protector", "chapters/tuner", "chapters/anchor",
				"ChapterRunner"]:
			check(not source.contains(forbidden), "%s doesn't mention %s" % [path.get_file(), forbidden])


# --- The score

func test_the_score_is_a_placeholder_piano_loop_that_plays() -> void:
	await frames()
	_run(3.0)
	check(_mourner.is_sound_playing(), "the score plays")
	check(_mourner.sound_level("thin") > 0.9 and _mourner.sound_level("full") > 0.9, "both layers up")
	for player_name in ["ScoreFull", "ScoreThin"]:
		var player: AudioStreamPlayer = _mourner.get_node(player_name)
		var wav := player.stream as AudioStreamWAV
		check(wav != null and wav.loop_mode != AudioStreamWAV.LOOP_DISABLED, "%s loops" % player_name)
		check(player.stream.resource_path.get_file().begins_with("placeholder_"), "%s is marked a placeholder" % player_name)
	check_near(_mourner.get_node("ScoreFull").stream.get_length(), _mourner.get_node("ScoreThin").stream.get_length(),
			0.01, "the two layers are the same length, so they stay in step")


# --- Pausing

func test_hiding_the_tab_pauses_everything_and_the_next_tap_resumes() -> void:
	await frames()
	_run(MournerRoom.DOOR_TIME + 1.0)
	var poster: Rect2 = _mourner.thing_rect(&"poster")
	_drag(poster.get_center(), poster.get_center() + Vector2(120, 120), false)
	check_eq(_mourner.held(), &"poster", "holding the poster")
	_mourner.pause()
	check(_mourner.is_paused(), "paused")
	check_eq(_mourner.held(), &"", "what was held is let go")
	check(not _mourner.is_sound_playing(), "the sound stops")
	var frozen: float = _room().time
	_run(5.0)
	check_eq(_room().time, frozen, "the clock stops")
	check_eq(get_node("/root/GameState").to_save_data().finished, [], "nothing saved")
	# Let go of the held poster before the resume tap.
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	get_viewport().push_input(up, true)
	tap_at(_mourner.thing_rect(&"guitar").get_center())
	check(not _mourner.is_paused(), "a tap resumes")
	check_eq(_mourner.held(), &"", "and the resume tap picks nothing up")
	check(_mourner.is_sound_playing(), "the sound is back")
	_run(1.0)
	check(_room().time > frozen, "the clock runs again")
	check_eq(_mourner.thing_rect(&"poster"), poster, "the poster went back")


func test_keys_and_hover_do_nothing() -> void:
	await frames()
	_run(MournerRoom.DOOR_TIME + STEP)
	for key in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_ENTER, KEY_SPACE, KEY_A, KEY_D, KEY_TAB]:
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = true
		get_viewport().push_input(event, true)
	var hover := InputEventMouseMotion.new()  # No button down.
	for id in OLD_THINGS:
		hover.position = _mourner.thing_rect(id).get_center()
		hover.global_position = hover.position
		get_viewport().push_input(hover.duplicate(), true)
	check_eq(_mourner.held(), &"", "nothing picked up")
	check_eq(_room().placed, [] as Array[StringName], "nothing placed")
	check(not _mourner.is_paused(), "and nothing paused")


# --- The look

func test_the_look_uses_no_compositor_effects() -> void:
	for node in _all_nodes(_mourner):
		check(not (node is WorldEnvironment or node is Camera3D or node is SubViewport),
				"no 3D or compositor in the Mourner: %s" % node.get_class())
	for path in ["res://scenes/chapters/mourner/mourner.gd", "res://scenes/chapters/mourner/mourner.tscn"]:
		check(not FileAccess.get_file_as_string(path).contains("Compositor"), "%s has no CompositorEffect" % path.get_file())


# --- Length

## A first-time player: looks round the room for a while, then takes a few
## seconds to find each thing and where it goes, and gets one wrong.
func test_a_modelled_player_finishes_in_about_2_to_4_minutes() -> void:
	await frames()
	var look_first := 8.0
	var per_thing := 10.0
	_run(MournerRoom.DOOR_TIME + look_first)
	var wrong_once := true
	while not _room().is_done() and _room().time < 600.0:
		var ids: Array[StringName] = _room().movable()
		if ids.is_empty():
			_mourner.advance(STEP)
			continue
		_run(per_thing)
		if wrong_once:
			wrong_once = false
			_drag(_mourner.thing_rect(ids[0]).get_center(), _mourner.place_rect(&"crib_spot").get_center())
			_run(3.0)
		_put_away(ids[0])
	var minutes: float = _room().time / 60.0
	check(minutes >= 2.0 and minutes <= 4.0, "about 2 to 4 minutes (took %.1f)" % minutes)
	check_eq(_finishes.size(), 1, "and finished")


func test_the_playtest_clock_counts_the_chapter() -> void:
	_run(12.0)
	check_near(_mourner.playtest_time(), 12.0, 0.01, "seconds into the Mourner")
