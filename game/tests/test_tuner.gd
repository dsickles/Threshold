extends TestCase
## The Tuner (DAS-135), on the chapter's own clock instead of real time.
## Rules from docs/design/story-beats.md §5, epic-5-stories.md and the
## ticket's acceptance criteria. How the knobs feel under a thumb, whether
## the fridge hum reads as a joke and whether the heartbeat lands are Dan's
## to check on his phone.

const TUNER := preload("res://scenes/chapters/tuner/tuner.tscn")
const TunerSignal := preload("res://scenes/chapters/tuner/tuner_signal.gd")
const MENU := preload("res://scenes/ui/m0_menu.tscn")
const STEP := 0.1

var _tuner: Node
var _finishes := []


func before_each() -> void:
	_tuner = add_scene(TUNER)
	_tuner.auto_advance = false
	_finishes.clear()
	_tuner.finished.connect(func(...args: Array) -> void: _finishes.append(args))


# --- Helpers

func _search() -> RefCounted:
	return _tuner.search()


func _run(seconds: float) -> void:
	var steps := roundi(seconds / STEP)
	for k in steps:
		_tuner.advance(STEP)


func _run_until(stage: int, limit: float) -> bool:
	var spent := 0.0
	while _search().stage != stage and spent < limit:
		_tuner.advance(STEP)
		spent += STEP
	return _search().stage == stage


func _set_knobs(at: Vector2) -> void:
	_search().set_knob(0, at.x)
	_search().set_knob(1, at.y)


## A finger (or the mouse) pressed on `from`, moved through `through`, and lifted.
func _drag(from: Vector2, through: Array) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.button_mask = MOUSE_BUTTON_MASK_LEFT
	down.position = from
	down.global_position = from
	down.pressed = true
	get_viewport().push_input(down, true)
	var last := from
	for point: Vector2 in through:
		var move := InputEventMouseMotion.new()
		move.button_mask = MOUSE_BUTTON_MASK_LEFT
		move.position = point
		move.global_position = point
		move.relative = point - last
		last = point
		get_viewport().push_input(move, true)
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	up.button_mask = 0
	up.position = last
	up.global_position = last
	get_viewport().push_input(up, true)


## Points on a circle round `knob`'s middle, turning by `degrees` (positive
## is clockwise on screen), starting at its right-hand edge.
func _turn_points(knob: Control, degrees: float) -> Array:
	var middle := knob.get_global_rect().get_center()
	var r: float = knob.radius() * 0.7
	var points := []
	var steps := 12
	for k in range(1, steps + 1):
		var a := deg_to_rad(degrees * k / steps)
		points.append(middle + Vector2.from_angle(a) * r)
	return points


func _knob_start(knob: Control) -> Vector2:
	return knob.get_global_rect().get_center() + Vector2(knob.radius() * 0.7, 0.0)


func _all_nodes(node: Node, out: Array = []) -> Array:
	out.append(node)
	for child in node.get_children():
		_all_nodes(child, out)
	return out


# --- Opening it

func test_the_menu_opens_the_tuner_through_the_chapter_runner() -> void:
	_tuner.free()  # So it can't take the menu's taps.
	var menu := add_scene(MENU)
	tap(menu.get_node("%BeginButton"))
	await frames()
	var button: Control = menu.get_node("%TunerButton")
	check(button.size.x >= 44.0 and button.size.y >= 44.0, "Tuner button is at least 44px")
	check_eq(button.text, "The Tuner (rough)", "the button's words")
	tap(button)
	var runner := ChapterRunner.of(get_tree())
	check_eq(runner.current_chapter(), &"tuner", "the runner is playing the Tuner")
	var tuner: Node = runner.get_child(0) if runner.get_child_count() > 0 else null
	if check(tuner != null and tuner.scene_file_path == TUNER.resource_path, "the Tuner opened"):
		check(not menu.visible, "menu hidden while the Tuner plays")
		tuner.finished.emit()
		await frames()
		check(menu.visible, "menu back after the Tuner finished")
		check_eq(menu.get_node("%Status").text, "Finished tuner (answer: none)", "menu heard the result")
	runner.free()


func test_the_chapter_list_has_the_tuner() -> void:
	check_eq(ChapterList.scene_path(&"tuner"), TUNER.resource_path, "the Tuner's scene")


# --- The knobs

func test_two_knobs_at_least_44px_and_on_screen_on_laptop_and_phones() -> void:
	for screen in [Vector2i(1280, 720), Vector2i(393, 852), Vector2i(852, 393)]:
		set_screen(screen)
		await frames(2)
		var view := get_viewport().get_visible_rect()
		var picture: Control = _tuner.get_node("Screen")
		for k in 2:
			var knob: Control = _tuner.knob(k)
			var rect := knob.get_global_rect()
			# The stretched canvas: 44 phone points is more units on a phone.
			var units_per_point := view.size.y / float(mini(screen.x, screen.y)) \
					if screen.x > screen.y else view.size.x / float(screen.x)
			var min_units := 44.0 * units_per_point
			check(rect.size.x >= min_units and rect.size.y >= min_units,
					"knob %d at least 44 points on %s (is %s units, needs %.0f)" % [k + 1, screen, rect.size, min_units])
			check(view.encloses(rect), "knob %d on screen on %s" % [k + 1, screen])
			check(not rect.intersects(picture.get_global_rect()), "knob %d clear of the picture on %s" % [k + 1, screen])
		check(not _tuner.knob(0).get_global_rect().intersects(_tuner.knob(1).get_global_rect()),
				"the knobs apart on %s" % screen)
		check(view.encloses(picture.get_global_rect()), "the picture on screen on %s" % screen)


func test_dragging_a_knob_turns_it_and_changes_the_waveform() -> void:
	await frames()
	var knob: Control = _tuner.knob(0)
	var before_value: float = knob.value
	var before_trace: PackedVector2Array = _tuner.waveform_points()
	var before_strength: float = _search().strength()
	# Clockwise, towards the hum on the first dial.
	_drag(_knob_start(knob), _turn_points(knob, 120.0))
	_tuner.advance(0.0)
	check(knob.value > before_value + 0.2, "the first knob turned up (%.2f to %.2f)" % [before_value, knob.value])
	check_near(_search().knobs.x, knob.value, 0.0001, "the search heard the turn")
	check_near(_search().knobs.y, TunerSignal.KNOBS_START.y, 0.0001, "the other knob didn't move")
	check(_search().strength() > before_strength, "more of the signal comes through")
	check(_tuner.waveform_points() != before_trace, "the waveform changed")
	# And back the other way.
	var turned_up: float = knob.value
	_drag(_knob_start(knob), _turn_points(knob, -60.0))
	check(knob.value < turned_up, "anticlockwise turns it down")
	# The second knob turns on its own.
	var second: Control = _tuner.knob(1)
	var second_before: float = second.value
	_drag(_knob_start(second), _turn_points(second, 90.0))
	check(second.value > second_before, "the second knob turns")
	check_near(_search().knobs.y, second.value, 0.0001, "the search heard the second knob")


func test_a_knob_stops_at_each_end() -> void:
	await frames()
	var knob: Control = _tuner.knob(0)
	for k in 3:
		_drag(_knob_start(knob), _turn_points(knob, 170.0))
	check_near(knob.value, 1.0, 0.0001, "stops at the top")
	for k in 4:
		_drag(_knob_start(knob), _turn_points(knob, -170.0))
	check_near(knob.value, 0.0, 0.0001, "stops at the bottom")


func test_a_tap_alone_does_not_turn_a_knob() -> void:
	await frames()
	for k in 2:
		var knob: Control = _tuner.knob(k)
		var before: float = knob.value
		tap(knob)
		tap_at(_knob_start(knob))
		check_eq(knob.value, before, "a tap on knob %d" % (k + 1))


func test_the_knobs_rock_until_first_turned_as_the_only_hint() -> void:
	await frames()
	var knob: Control = _tuner.knob(0)
	check(knob.hinting and _tuner.knob(1).hinting, "both knobs hint at first")
	_drag(_knob_start(knob), _turn_points(knob, 40.0))
	check(not knob.hinting, "the first stops hinting once turned")
	check(_tuner.knob(1).hinting, "the other still hints")


# --- No words, no wrong popup

func test_the_chapter_shows_no_words_and_the_knobs_have_no_labels() -> void:
	await frames()
	_set_knobs(TunerSignal.HUM_AT)
	_run(40.0)
	for node in _all_nodes(_tuner):
		check(not (node is Label or node is RichTextLabel or node is Button or node is Window or node is AcceptDialog),
				"no words or popups: %s is a %s" % [node.name, node.get_class()])
		if node is Control:
			check_eq((node as Control).tooltip_text, "", "%s has no tooltip" % node.name)


func test_off_the_signal_the_static_stays_with_no_popup() -> void:
	var count_before := _all_nodes(_tuner).size()
	_run(30.0)
	check_eq(_search().stage, TunerSignal.Stage.SEARCH_HUM, "still searching")
	check_eq(_search().clarity, 0.0, "no picture")
	check(_search().strength() < 0.01, "nothing coming through")
	check(_tuner.sound_level("static") > 0.4, "the static is loud")
	check_eq(_tuner.sound_level("hum"), 0.0, "no hum")
	check_eq(_tuner.sound_level("heartbeat"), 0.0, "no heartbeat")
	check_eq(_all_nodes(_tuner).size(), count_before, "nothing new appeared")
	# Close but not on it: still static, still nothing popping up.
	_set_knobs(TunerSignal.HUM_AT + Vector2(0.12, -0.12))
	_run(5.0)
	check_eq(_search().stage, TunerSignal.Stage.SEARCH_HUM, "near isn't on it")
	check(_tuner.sound_level("static") > 0.2, "static stays when off the signal")
	check_eq(_all_nodes(_tuner).size(), count_before, "still nothing new")


# --- The beats

func test_the_beats_come_in_order_fridge_hum_then_heartbeat_then_picture() -> void:
	_run(3.0)
	# Finding the hum: a steady rhythm through the static.
	_set_knobs(TunerSignal.HUM_AT)
	check(_run_until(TunerSignal.Stage.HUM, 3.0), "on the hum, it locks in")
	_run(1.0)
	check(_tuner.sound_level("hum") > 0.6, "the hum comes through")
	check_eq(_tuner.sound_level("heartbeat"), 0.0, "no heartbeat in the hum")
	check_eq(_search().clarity, 0.0, "the hum clears no picture")
	# It cuts out: the fridge clicks off.
	check(_run_until(TunerSignal.Stage.HUM_LOST, TunerSignal.HUM_TIME), "the hum ends")
	check(_tuner.get_node("Click").playing, "the fridge clicks off")
	_run(0.5)
	check(_tuner.sound_level("hum") < 0.01, "the hum is gone")
	check(_tuner.sound_level("static") > 0.4, "static again")
	check(_run_until(TunerSignal.Stage.SEARCH_BABY, TunerSignal.HUM_LOST_TIME + 0.2), "searching again")
	# Closer, a faster pulse under the noise: louder the closer the knobs.
	var levels := []
	for away in [0.3, 0.2, 0.1]:
		_set_knobs(TunerSignal.BABY_AT + Vector2(away, away))
		_run(1.0)
		levels.append(_tuner.sound_level("heartbeat"))
	check(levels[0] < levels[1] and levels[1] < levels[2], "the pulse grows as the knobs close in: %s" % [levels])
	check_eq(_search().stage, TunerSignal.Stage.SEARCH_BABY, "not through yet")
	check_eq(_search().signal_kind(), &"heartbeat", "the pulse is the heartbeat")
	# Through: the heartbeat, and the picture clears.
	_set_knobs(TunerSignal.BABY_AT)
	check(_run_until(TunerSignal.Stage.THROUGH, 3.0), "on the heartbeat, it comes through")
	_run(TunerSignal.CLEAR_TIME)
	check_near(_search().clarity, 1.0, 0.001, "the picture is clear")
	check(_tuner.sound_level("heartbeat") > 0.9, "the heartbeat is loud")
	check(_tuner.sound_level("static") < 0.1, "the static has gone")
	check(_run_until(TunerSignal.Stage.DONE, TunerSignal.PICTURE_TIME + 0.2), "the picture held, then done")
	var order := []
	for entry in _search().history:
		order.append(TunerSignal.Stage.keys()[entry[0]])
	check_eq(order, ["SEARCH_HUM", "HUM", "HUM_LOST", "SEARCH_BABY", "THROUGH", "DONE"], "the beats in order")


func test_the_heartbeat_cant_be_found_before_the_hum() -> void:
	_set_knobs(TunerSignal.BABY_AT)
	_run(30.0)
	check_eq(_search().stage, TunerSignal.Stage.SEARCH_HUM, "still looking for the first signal")
	check_eq(_tuner.sound_level("heartbeat"), 0.0, "no heartbeat yet")
	check_eq(_search().clarity, 0.0, "no picture yet")


func test_the_signals_are_far_apart_on_the_dials() -> void:
	var apart := (TunerSignal.HUM_AT - TunerSignal.BABY_AT).abs()
	check(minf(apart.x, apart.y) > TunerSignal.NEAR, "finding the hum hears nothing of the heartbeat")
	var from_start := (TunerSignal.HUM_AT - TunerSignal.KNOBS_START).abs()
	check(maxf(from_start.x, from_start.y) > TunerSignal.NEAR, "the knobs start off the hum")


# --- One ending

func test_the_picture_clearing_is_the_only_ending_and_it_reports_once() -> void:
	_set_knobs(TunerSignal.HUM_AT)
	_run_until(TunerSignal.Stage.SEARCH_BABY, 30.0)
	_set_knobs(TunerSignal.BABY_AT)
	_run_until(TunerSignal.Stage.THROUGH, 5.0)
	# Through is through: turning away doesn't lose the picture.
	_set_knobs(Vector2(0.0, 0.0))
	check_eq(_search().knobs, TunerSignal.BABY_AT, "the knobs stay on the heartbeat once through")
	check(_run_until(TunerSignal.Stage.DONE, 30.0), "done")
	_run(10.0)
	check_eq(_finishes.size(), 1, "finished exactly once")
	check_eq(_finishes[0] if _finishes.size() > 0 else null, [], "with no answer")
	check_near(_search().clarity, 1.0, 0.001, "it ends on the clear picture")
	check(not _tuner.is_sound_playing(), "sound stops at the end")


func test_finishing_hands_back_one_result_with_no_answer_through_the_runner() -> void:
	_tuner.free()
	var house := Control.new()
	add_child(house)
	var runner := ChapterRunner.of(get_tree())
	var results := []
	var left := []
	var on_finished := func(result: Dictionary) -> void: results.append(result)
	var on_left := func(id: StringName) -> void: left.append(id)
	runner.chapter_finished.connect(on_finished)
	runner.chapter_left.connect(on_left)
	check(runner.enter(&"tuner", house), "entered")
	var tuner: Node = runner.get_child(0)
	tuner.auto_advance = false
	tuner.search().set_knob(0, TunerSignal.HUM_AT.x)
	tuner.search().set_knob(1, TunerSignal.HUM_AT.y)
	for k in 200:
		tuner.advance(STEP)
	tuner.search().set_knob(0, TunerSignal.BABY_AT.x)
	tuner.search().set_knob(1, TunerSignal.BABY_AT.y)
	for k in 300:
		if not is_instance_valid(tuner):
			break
		tuner.advance(STEP)
	await frames()
	check_eq(results, [{"chapter": "tuner", "answer": ""}], "one result, no answer")
	check(ChapterResult.is_story_result(results[0]) if results.size() > 0 else false, "a real story result")
	check_eq(left, [], "not counted as leaving")
	check(house.visible, "the House is back")
	runner.chapter_finished.disconnect(on_finished)
	runner.chapter_left.disconnect(on_left)
	runner.free()


func test_leaving_part_way_gives_no_result_or_save_and_the_next_visit_starts_from_the_static() -> void:
	_tuner.free()
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
	runner.enter(&"tuner", house)
	var tuner: Node = runner.get_child(0)
	tuner.auto_advance = false
	tuner.search().set_knob(0, TunerSignal.HUM_AT.x)
	tuner.search().set_knob(1, TunerSignal.HUM_AT.y)
	for k in 200:
		tuner.advance(STEP)
	check_eq(tuner.search().stage, TunerSignal.Stage.SEARCH_BABY, "part-way in")
	tuner.queue_free()  # Leaving: the page closed, say.
	await frames()
	check_eq(results, [], "no result")
	check_eq(left, [&"tuner"], "it left")
	check_eq(state.to_save_data(), saved_before, "nothing saved")
	runner.enter(&"tuner", house)
	var again: Node = runner.get_child(0)
	check_eq(again.search().stage, TunerSignal.Stage.SEARCH_HUM, "the next visit starts at the static")
	check_eq(again.search().time, 0.0, "from the start")
	check_eq(again.search().knobs, TunerSignal.KNOBS_START, "with the knobs back where they start")
	runner.chapter_finished.disconnect(on_finished)
	runner.chapter_left.disconnect(on_left)
	runner.free()


func test_the_chapter_never_touches_the_house_another_chapter_or_saved_state() -> void:
	for path in ["res://scenes/chapters/tuner/tuner.gd", "res://scenes/chapters/tuner/tuner_signal.gd",
			"res://scenes/chapters/tuner/tuner_knob.gd"]:
		var source := FileAccess.get_file_as_string(path)
		# Comments may talk about the House; the code may not reach it.
		for forbidden in ["GameState", "/root/", "HouseTable", "house_", "scenes/house", "SaveFile",
				"user://", "chapters/partner", "chapters/protector", "ChapterRunner"]:
			check(not source.contains(forbidden), "%s doesn't mention %s" % [path.get_file(), forbidden])


# --- Fail-forward

func test_the_lock_widens_the_longer_the_search_goes_on() -> void:
	var at_start: float = _search().lock_within()
	_run(TunerSignal.ASSIST_AFTER)
	check_near(_search().lock_within(), at_start, 0.0001, "no help in the first %d s" % TunerSignal.ASSIST_AFTER)
	_run(30.0)
	check(_search().lock_within() > at_start, "wider after a while")
	_run(TunerSignal.ASSIST_FULL - TunerSignal.ASSIST_AFTER - 30.0)
	check_eq(_search().stage, TunerSignal.Stage.SEARCH_HUM, "still searching")
	check_near(_search().lock_within(), TunerSignal.ASSIST_WITHIN, 0.0001, "as wide as it gets")


func test_a_player_who_never_touches_the_knobs_still_comes_through() -> void:
	check(_run_until(TunerSignal.Stage.DONE, 600.0), "done without touching anything (%.0f s)" % _search().time)
	check_eq(_finishes.size(), 1, "finished")
	print("    never touching the knobs: done at %.0f s" % _search().time)


func test_a_player_who_keeps_missing_still_comes_through() -> void:
	# Always turning, never stopping on it: knobs wander round the dials.
	var t := 0.0
	while _search().stage != TunerSignal.Stage.DONE and t < 600.0:
		_set_knobs(Vector2(0.5 + 0.45 * sin(t * 0.37), 0.5 + 0.45 * cos(t * 0.23)))
		_tuner.advance(STEP)
		t += STEP
	check_eq(_search().stage, TunerSignal.Stage.DONE, "done in the end (%.0f s)" % t)
	check_eq(_finishes.size(), 1, "finished once")


# --- How long it takes

# A modelled player who searches the way people turn a radio: one knob at a
# time, slowly (a whole turn in about 20 s), listening, going back to where
# it was loudest, then the other, then smaller nudges, and resting their
# hands now and then. M2's rough length is 2 to 4 minutes.
func test_a_modelled_searching_player_finishes_in_about_2_to_4_minutes() -> void:
	var speed := 1.0 / 20.0
	var knobs := TunerSignal.KNOBS_START
	var guard := 0
	while _search().stage != TunerSignal.Stage.DONE and guard < 100000:
		guard += 1
		if not _search().is_searching():
			_tuner.advance(STEP)
			continue
		var stage: int = _search().stage
		var span := 1.0
		var which := 0
		while _search().stage == stage and guard < 100000:
			# Sweep one knob across `span` round where it is, listening.
			var centre: float = knobs[which]
			var lo := clampf(centre - span / 2.0, 0.0, 1.0)
			var hi := clampf(centre + span / 2.0, 0.0, 1.0)
			var best := centre
			var best_strength := -1.0
			var v := lo
			while v <= hi and _search().stage == stage:
				knobs[which] = v
				_set_knobs(knobs)
				_tuner.advance(STEP)
				guard += 1
				if _search().strength() > best_strength:
					best_strength = _search().strength()
					best = v
				v += speed * STEP
			knobs[which] = best
			_set_knobs(knobs)
			# A breath, listening, before the next knob.
			for k in 10:
				if _search().stage == stage:
					_tuner.advance(STEP)
			which = 1 - which
			if which == 0:
				span = maxf(span * 0.4, 0.08)
	var took: float = _search().time
	print("    a modelled searching player: done at %.0f s" % took)
	check(took >= 100.0 and took <= 240.0, "about 2 to 4 minutes (took %.0f s)" % took)


# --- Pause, keys, hover

func test_hiding_the_tab_pauses_everything_and_the_next_tap_resumes() -> void:
	await frames()
	var state := get_node("/root/GameState")
	var saved_before: Dictionary = state.to_save_data()
	_set_knobs(TunerSignal.HUM_AT)
	_run(2.0)
	_tuner.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(_tuner.is_paused(), "paused")
	var time_before: float = _search().time
	var stage_before: int = _search().stage
	_run(20.0)
	check_eq(_search().time, time_before, "the clock stopped")
	check_eq(_search().stage, stage_before, "the beat waits")
	check_eq(_tuner.playtest_time(), time_before, "the playtest clock stopped too")
	check(not _tuner.is_sound_playing(), "the sound stopped")
	check(_tuner.get_node("Hum").stream_paused and _tuner.get_node("Heartbeat").stream_paused, "every loop paused")
	check_eq(state.to_save_data(), saved_before, "hiding never saves")
	# A drag while paused does nothing but wake it.
	var knob: Control = _tuner.knob(0)
	var value: float = knob.value
	_drag(_knob_start(knob), _turn_points(knob, 90.0))
	check(not _tuner.is_paused(), "the tap resumed it")
	check_eq(knob.value, value, "the resuming tap didn't turn the knob")
	check(_tuner.is_sound_playing(), "the sound is back")
	_run(1.0)
	check(_search().time > time_before, "the clock runs again")


func test_keys_and_hover_do_nothing() -> void:
	await frames()
	var knobs_before: Vector2 = _search().knobs
	for key in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_ENTER, KEY_SPACE, KEY_A, KEY_D]:
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = true
		get_viewport().push_input(event, true)
	for k in 2:
		var knob: Control = _tuner.knob(k)
		var hover := InputEventMouseMotion.new()  # No button down.
		for point: Vector2 in _turn_points(knob, 180.0):
			hover.position = point
			hover.global_position = point
			get_viewport().push_input(hover.duplicate(), true)
	check_eq(_search().knobs, knobs_before, "keys and hovering don't turn the knobs")
	check(not _tuner.is_paused(), "and don't pause")


# --- The look

func test_the_look_is_a_canvas_shader_with_no_compositor_effects() -> void:
	var screen: ColorRect = _tuner.get_node("Screen")
	var mat := screen.material as ShaderMaterial
	if not check(mat != null, "the screen has a shader"):
		return
	check_eq(mat.shader.get_mode(), Shader.MODE_CANVAS_ITEM, "a canvas shader")
	var code := mat.shader.code
	for word in ["grain", "split", "tear"]:
		check(code.contains(word), "the shader has its %s" % word)
	for node in _all_nodes(_tuner):
		check(not (node is WorldEnvironment or node is Camera3D or node is SubViewport),
				"no 3D or compositor in the Tuner: %s" % node.get_class())
	check_eq(mat.get_shader_parameter("clarity"), 0.0, "all static at first")
	_set_knobs(TunerSignal.HUM_AT)
	_run_until(TunerSignal.Stage.SEARCH_BABY, 30.0)
	_set_knobs(TunerSignal.BABY_AT)
	_run_until(TunerSignal.Stage.THROUGH, 5.0)
	_run(TunerSignal.CLEAR_TIME)
	check_near(mat.get_shader_parameter("clarity"), 1.0, 0.001, "clear at the end")


func test_the_playtest_clock_counts_the_chapter() -> void:
	_run(12.0)
	check_near(_tuner.playtest_time(), 12.0, 0.01, "seconds into the Tuner")
