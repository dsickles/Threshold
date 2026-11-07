extends TestCase
## The Anchor (DAS-138), on the chapter's own clock instead of real time.
## Rules from docs/design/story-beats.md §6, epic-7-stories.md and the
## ticket's acceptance criteria. Whether the zones are easy to hold with two
## thumbs, whether the weight feels heavy (the scripted-wobble test) and
## whether "You've got this." lands are Dan's to check on his phone.

const ANCHOR := preload("res://scenes/chapters/anchor/anchor.tscn")
const AnchorCarry := preload("res://scenes/chapters/anchor/anchor_carry.gd")
const MENU := preload("res://scenes/ui/m0_menu.tscn")
const STEP := 1.0 / 60.0

var _anchor: Node
var _finishes := []


func before_each() -> void:
	_anchor = add_scene(ANCHOR)
	_anchor.auto_advance = false
	_finishes.clear()
	_anchor.finished.connect(func(...args: Array) -> void: _finishes.append(args))


# --- Helpers

func _carry() -> RefCounted:
	return _anchor.carry()


func _run(seconds: float) -> void:
	for k in roundi(seconds / STEP):
		_anchor.advance(STEP)


func _run_until(done: Callable, limit: float) -> bool:
	var spent := 0.0
	while not done.call() and spent < limit:
		_anchor.advance(STEP)
		spent += STEP
	return done.call()


## A modelled player: sees the lean `react` seconds late, guesses where it is
## going, and holds the zone on the other side once it is past `dead`.
func _play_like_a_person(react: float, dead: float, look: float, limit: float) -> float:
	var seen := []
	var spent := 0.0
	var delay := roundi(react / STEP)
	while _carry().stage != AnchorCarry.Stage.DONE and spent < limit:
		seen.append(Vector2(_carry().lean, _carry().swing))
		var past: Vector2 = seen[seen.size() - 1 - delay] if seen.size() > delay else Vector2.ZERO
		var guess := past.x + past.y * look
		_carry().set_hold(-1 if guess > dead else (1 if guess < -dead else 0))
		_anchor.advance(STEP)
		spent += STEP
	return spent


func _press(point: Vector2, finger: int) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = finger
	touch.position = point
	touch.pressed = true
	get_viewport().push_input(touch, true)


func _lift(point: Vector2, finger: int) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = finger
	touch.position = point
	touch.pressed = false
	get_viewport().push_input(touch, true)


func _all_nodes(node: Node, out: Array = []) -> Array:
	out.append(node)
	for child in node.get_children():
		_all_nodes(child, out)
	return out


func _zone_centre(side: int) -> Vector2:
	return _anchor.zone(side).get_global_rect().get_center()


# --- Opening it

func test_the_menu_opens_the_anchor_through_the_chapter_runner() -> void:
	_anchor.free()  # So it can't take the menu's taps.
	var menu := add_scene(MENU)
	tap(menu.get_node("%BeginButton"))
	await frames()
	var button: Control = menu.get_node("%AnchorButton")
	check(button.size.x >= 44.0 and button.size.y >= 44.0, "Anchor button is at least 44px")
	check_eq(button.text, "The Anchor (rough)", "the button's words")
	tap(button)
	var runner := ChapterRunner.of(get_tree())
	check_eq(runner.current_chapter(), &"anchor", "the runner is playing the Anchor")
	var anchor: Node = runner.get_child(0) if runner.get_child_count() > 0 else null
	if check(anchor != null and anchor.scene_file_path == ANCHOR.resource_path, "the Anchor opened"):
		check(not menu.visible, "menu hidden while the Anchor plays")
		anchor.finished.emit()
		await frames()
		check(menu.visible, "menu back after the Anchor finished")
		check_eq(menu.get_node("%Status").text, "Finished anchor (answer: none)", "menu heard the result")
	runner.free()


func test_the_chapter_list_has_the_anchor() -> void:
	check_eq(ChapterList.scene_path(&"anchor"), ANCHOR.resource_path, "the Anchor's scene")


# --- The hold zones

func test_two_hold_zones_at_least_44px_on_laptop_and_phones() -> void:
	for screen in [Vector2i(1280, 720), Vector2i(393, 852), Vector2i(852, 393)]:
		set_screen(screen)
		await frames(2)
		var view := get_viewport().get_visible_rect()
		# The stretched canvas: 44 phone points is more units on a phone.
		var units_per_point := view.size.y / float(mini(screen.x, screen.y)) \
				if screen.x > screen.y else view.size.x / float(screen.x)
		var min_units := 44.0 * units_per_point
		var left: Rect2 = _anchor.zone(-1).get_global_rect()
		var right: Rect2 = _anchor.zone(1).get_global_rect()
		for pair in [["left", left], ["right", right]]:
			var rect: Rect2 = pair[1]
			check(rect.size.x >= min_units and rect.size.y >= min_units,
					"%s zone at least 44 points on %s (is %s units, needs %.0f)" % [pair[0], screen, rect.size, min_units])
			check(view.encloses(rect), "%s zone on screen on %s" % [pair[0], screen])
		check(not left.intersects(right), "the zones apart on %s" % screen)
		check(left.get_center().x < view.get_center().x and right.get_center().x > view.get_center().x,
				"left on the left, right on the right on %s" % screen)
		check_near(left.size.x, right.size.x, 0.01, "the same size on %s" % screen)


func test_holding_the_left_zone_leans_leo_left_and_the_right_zone_right() -> void:
	_run(0.5)
	var at := _zone_centre(-1)
	_press(at, 0)
	check_eq(_carry().hold, -1, "left held")
	check(_anchor.zone(-1).held, "the left zone shows it is held")
	_run(0.6)
	check(_carry().lean < -0.15, "leaning left (is %.2f)" % _carry().lean)
	_lift(at, 0)
	check_eq(_carry().hold, 0, "let go")
	check(not _anchor.zone(-1).held, "the left zone back to idle")
	_carry().lean = 0.0
	_carry().swing = 0.0
	at = _zone_centre(1)
	_press(at, 1)
	check_eq(_carry().hold, 1, "right held")
	_run(0.6)
	check(_carry().lean > 0.15, "leaning right (is %.2f)" % _carry().lean)
	_lift(at, 1)


func test_both_zones_at_once_cancel_and_a_touch_outside_them_does_nothing() -> void:
	_press(_zone_centre(-1), 0)
	_press(_zone_centre(1), 1)
	check_eq(_carry().hold, 0, "both held: no push either way")
	_lift(_zone_centre(1), 1)
	check_eq(_carry().hold, -1, "lifting the right leaves the left held")
	_lift(_zone_centre(-1), 0)
	_press(get_viewport().get_visible_rect().get_center() + Vector2(0, -200), 2)
	check_eq(_carry().hold, 0, "a touch in the House holds nothing")
	_lift(get_viewport().get_visible_rect().get_center() + Vector2(0, -200), 2)


func test_a_real_click_holds_and_an_emulated_click_from_a_touch_is_not_counted_twice() -> void:
	var at := _zone_centre(1)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = at
	down.global_position = at
	down.pressed = true
	get_viewport().push_input(down, true)
	check_eq(_carry().hold, 1, "a click holds the right zone")
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	get_viewport().push_input(up, true)
	check_eq(_carry().hold, 0, "lifting the click lets go")
	_press(at, 0)
	var emulated := down.duplicate() as InputEventMouseButton
	emulated.pressed = false
	emulated.device = InputEvent.DEVICE_ID_EMULATION
	get_viewport().push_input(emulated, true)
	check_eq(_carry().hold, 1, "the touch's copy as a click doesn't let go")
	_lift(at, 0)


func test_no_stick_meter_labels_or_words_but_mayas_line() -> void:
	for node in _all_nodes(_anchor):
		check(not (node is Button or node is Range or node is TextureProgressBar or node is LineEdit),
				"no button, stick, slider or meter: %s" % node.name)
		if node is Control:
			check_eq(node.tooltip_text, "", "no tooltip on %s" % node.name)
		if node is Label and node.is_visible_in_tree():
			check_eq(node.text, "", "no words on screen at the start: %s" % node.name)
	# Through a whole carry with three falls, the only words ever shown are hers.
	var seen := {}
	while _carry().stage != AnchorCarry.Stage.DONE and _carry().time < 400.0:
		_anchor.advance(STEP)
		for node in _all_nodes(_anchor):
			if node is Label and node.is_visible_in_tree() and node.text != "":
				seen[node.text] = true
	check_eq(seen.keys(), [AnchorCarry.MAYA_LINE], "only \"You've got this.\" was ever shown")
	# Nor is any other text in the code (comments may name what is banned).
	for path in ["res://scenes/chapters/anchor/anchor.gd", "res://scenes/chapters/anchor/anchor_carry.gd"]:
		for line in FileAccess.get_file_as_string(path).split("\n"):
			if line.strip_edges().begins_with("#"):
				continue
			for banned in ["Stability Assist", "Difficulty", "Low empathy"]:
				check(not line.contains(banned), "no \"%s\" in %s" % [banned, path.get_file()])


# --- The physics step and the shiver

func test_the_lean_moves_in_fixed_physics_steps_the_same_at_any_frame_rate() -> void:
	var a: RefCounted = AnchorCarry.new()
	var b: RefCounted = AnchorCarry.new()
	for k in 600:  # 10 s at 60 frames a second.
		a.advance(1.0 / 60.0)
	for k in 1440:  # The same 10 s at 144.
		b.advance(1.0 / 144.0)
	check_near(a.time, 10.0, 0.0001, "60 fps: 10 s")
	check_near(b.time, a.time, 0.0001, "144 fps: the same time")
	check_near(b.lean, a.lean, 0.0001, "the same lean")
	check_near(b.distance, a.distance, 0.0001, "the same distance")
	var c: RefCounted = AnchorCarry.new()
	c.advance(AnchorCarry.STEP * 0.5)
	check_eq(c.time, 0.0, "half a step does nothing yet")
	check(_anchor.has_method("_physics_process"), "the chapter steps it in the physics step")


func test_a_shiver_covers_small_wobbles() -> void:
	var carry: RefCounted = _carry()
	carry.lean = 0.0
	check(carry.shiver() < 0.05, "standing straight in the calm: no shiver")
	carry.lean = 0.5
	check(carry.shiver() > 0.3, "leaning: a shiver (is %.2f)" % carry.shiver())


# --- The beats

func test_the_beats_come_in_order_steady_then_the_storm_then_the_crib_set_down() -> void:
	var order := [_carry().stage]
	var storm_at_start: float = _carry().storm()
	while _carry().stage != AnchorCarry.Stage.DONE and _carry().time < 400.0:
		_anchor.advance(STEP)
		if order[-1] != _carry().stage:
			order.append(_carry().stage)
	check_eq(order, [AnchorCarry.Stage.STEADY, AnchorCarry.Stage.STORM, AnchorCarry.Stage.SET_DOWN,
			AnchorCarry.Stage.DONE], "steady, storm, set down, done")
	check_eq(storm_at_start, 0.0, "no storm at the start")
	check_near(_carry().distance, AnchorCarry.LENGTH, 0.001, "he reached the window")


func test_the_storm_has_wind_and_the_calm_has_none() -> void:
	var carry: RefCounted = _carry()
	carry.distance = 10.0
	check_eq(carry.wind(), 0.0, "no wind in the calm")
	var strongest := 0.0
	var d := AnchorCarry.STORM_AT
	while d < AnchorCarry.LENGTH:
		carry.distance = d
		strongest = maxf(strongest, absf(carry.wind()))
		d += 0.25
	check(strongest > AnchorCarry.TIP_STORM, "gusts in the storm strong enough to need a hold")
	carry.distance = 40.0
	check_near(carry.storm(), 1.0, 0.001, "full storm in the middle")


# --- Falls, Maya and the assist

func test_a_fall_keeps_the_player_in_the_chapter_and_carries_on_from_the_same_place() -> void:
	_run(2.0)
	var carry: RefCounted = _carry()
	var where: float = carry.distance
	carry.lean = 0.99
	carry.swing = 2.0
	_anchor.advance(STEP)
	check_eq(carry.falls, 1, "the crib touched the ground")
	check(carry.is_fallen(), "on the floor")
	check(_anchor.sound_heard("thud"), "the thud")
	_run(AnchorCarry.FALLEN_TIME + AnchorCarry.PICK_UP_TIME + 0.1)
	check(carry.is_carrying(), "picked up and carrying again")
	check_near(carry.distance, where, 0.2, "from the same place")
	check(carry.stage != AnchorCarry.Stage.DONE, "still in the chapter")
	check_eq(_finishes.size(), 0, "a fall doesn't end it")
	_run(3.0)
	check(carry.distance > where + 0.5, "and walking on")


func _fall_once() -> void:
	_run(0.5)
	_carry().lean = 0.995
	_carry().swing = 3.0
	_anchor.advance(STEP)
	_run(AnchorCarry.FALLEN_TIME + AnchorCarry.PICK_UP_TIME + 0.2)


func test_maya_speaks_only_on_the_third_fall_then_the_assist_with_no_badge() -> void:
	for k in 2:
		_fall_once()
		check_eq(_carry().falls, k + 1, "fall %d" % (k + 1))
		check(not _anchor.sound_heard("maya"), "Maya hasn't spoken after fall %d" % (k + 1))
		check(not _carry().assisted, "no help after fall %d" % (k + 1))
	check_eq(_anchor.get_node("Subtitle").visible, false, "no subtitle yet")
	_run(0.5)
	_carry().lean = 0.995
	_carry().swing = 3.0
	_anchor.advance(STEP)
	check_eq(_carry().falls, 3, "the third fall")
	_run(AnchorCarry.MAYA_DELAY + 0.1)
	check(_anchor.sound_heard("maya"), "her sound cue")
	var subtitle: Control = _anchor.get_node("Subtitle")
	check(subtitle.visible, "her line shows")
	var label: Label = subtitle.get_child(0)
	check_eq(label.text, "You've got this.", "her words")
	check(get_viewport().get_visible_rect().encloses(subtitle.get_global_rect()), "on screen")
	check(_carry().assisted, "and the assist is on")
	_run(AnchorCarry.MAYA_SHOWS + 0.5)
	check(not subtitle.visible, "her line goes")
	for node in _all_nodes(_anchor):
		if node is Label and node.is_visible_in_tree():
			check_eq(node.text, "", "no badge or toast after: %s" % node.name)


func test_the_assist_makes_it_steadier() -> void:
	# The same strong gust with nobody holding: without help he goes over,
	# with it he stays up.
	var without: RefCounted = AnchorCarry.new()
	var with_help: RefCounted = AnchorCarry.new()
	with_help.assisted = true
	with_help.falls = AnchorCarry.MAYA_AFTER_FALLS  # As after Maya's line.
	for carry: RefCounted in [without, with_help]:
		carry.distance = 55.0
		carry.stage = AnchorCarry.Stage.STORM
		carry.advance(6.0)
	check(without.falls > 0, "without help a gust takes him over")
	check_eq(with_help.falls, AnchorCarry.MAYA_AFTER_FALLS, "with help he rides it out")


func test_a_player_who_never_touches_the_zones_still_reaches_the_end() -> void:
	check(_run_until(func() -> bool: return _carry().stage == AnchorCarry.Stage.DONE, 300.0),
			"done within 5 minutes with no hands (took %.0f s)" % _carry().time)
	check(_carry().falls >= 3, "he fell, and Maya spoke")
	check_eq(_finishes.size(), 1, "and it finished")


func test_a_player_who_keeps_falling_still_finishes() -> void:
	# Holds the wrong way whenever he leans: falls as often as he can.
	var spent := 0.0
	while _carry().stage != AnchorCarry.Stage.DONE and spent < 600.0:
		var c: RefCounted = _carry()
		c.set_hold(int(signf(c.lean)) if absf(c.lean) > 0.05 else 1)
		_anchor.advance(STEP)
		spent += STEP
	check_eq(_carry().stage, AnchorCarry.Stage.DONE, "reached the window (took %.0f s, %d falls)" % [spent, _carry().falls])
	check(_carry().falls > 3, "after many falls")
	check(_carry().assist_push_back() > AnchorCarry.ASSIST_PUSH_BACK, "the assist grew with them")
	check_eq(_finishes.size(), 1, "finished once")


func test_a_modelled_player_takes_about_two_to_four_minutes() -> void:
	var took := _play_like_a_person(0.3, 0.12, 0.4, 400.0)
	check_eq(_carry().stage, AnchorCarry.Stage.DONE, "reached the window")
	check(took >= 120.0 and took <= 240.0, "about 2 to 4 minutes (took %.0f s)" % took)


func test_a_quick_steady_player_never_needs_mayas_help() -> void:
	var took := _play_like_a_person(0.25, 0.12, 0.5, 400.0)
	check(_carry().falls < AnchorCarry.MAYA_AFTER_FALLS,
			"a quick, steady player falls less than three times (%d)" % _carry().falls)
	check(took >= 120.0, "still about 2 minutes or more (took %.0f s)" % took)


func test_a_slower_player_falls_in_the_storm_not_the_calm() -> void:
	_play_like_a_person(0.4, 0.12, 0.0, 400.0)
	check(_carry().falls >= 1, "the storm gets him at least once")
	check_eq(_carry().stage, AnchorCarry.Stage.DONE, "and he still finishes")


# --- Shake and reduced motion

func test_a_fall_shakes_the_screen_but_not_with_reduced_motion() -> void:
	_run(0.5)
	_carry().lean = 0.995
	_carry().swing = 3.0
	_anchor.advance(STEP)
	_anchor.advance(STEP)
	check(_anchor.shake_offset().length() > 0.5, "a hit-shake on the fall")
	check(_anchor.get_node("World").position.length() > 0.5, "the House is knocked")
	_anchor.reduced_motion = true
	_anchor.advance(STEP)
	check_eq(_anchor.shake_offset(), Vector2.ZERO, "no hit-shake with reduced motion")
	check_eq(_anchor.get_node("World").position, Vector2.ZERO, "the House stays still")


# --- The look

func test_the_storm_is_a_canvas_shader_with_no_compositor_effects() -> void:
	var storm: ColorRect = _anchor.get_node("Storm")
	var mat := storm.material as ShaderMaterial
	if not check(mat != null, "the storm has a shader"):
		return
	check_eq(mat.shader.get_mode(), Shader.MODE_CANVAS_ITEM, "a canvas shader")
	for word in ["rain", "flash"]:
		check(mat.shader.code.contains(word), "the shader has its %s" % word)
	for node in _all_nodes(_anchor):
		check(not (node is WorldEnvironment or node is Camera3D or node is SubViewport or node is FogVolume),
				"no 3D, fog or compositor in the Anchor: %s" % node.get_class())
	check_eq(mat.get_shader_parameter("storm"), 0.0, "calm at first")
	_carry().distance = 40.0
	_carry().stage = AnchorCarry.Stage.STORM
	_anchor.advance(STEP)
	check(float(mat.get_shader_parameter("storm")) > 0.9, "the storm up in the middle")


# --- Finishing and leaving

func test_it_finishes_once_with_no_answer_and_the_sound_stops() -> void:
	check(_run_until(func() -> bool: return _carry().stage == AnchorCarry.Stage.DONE, 300.0), "done")
	_run(5.0)
	check_eq(_finishes.size(), 1, "finished exactly once")
	check_eq(_finishes[0] if _finishes.size() > 0 else null, [], "with no answer")
	check(not _anchor.is_sound_playing(), "the rain stops at the end")
	check(_anchor.sound_heard("set_down"), "the crib set down")


func test_finishing_hands_back_one_result_with_no_answer_through_the_runner() -> void:
	_anchor.free()
	var house := Control.new()
	add_child(house)
	var runner := ChapterRunner.of(get_tree())
	var results := []
	var on_finished := func(result: Dictionary) -> void: results.append(result)
	runner.chapter_finished.connect(on_finished)
	check(runner.enter(&"anchor", house), "entered")
	var anchor: Node = runner.get_child(0)
	anchor.auto_advance = false
	for k in roundi(300.0 / STEP):
		if not is_instance_valid(anchor) or anchor.carry().stage == AnchorCarry.Stage.DONE:
			break
		anchor.advance(STEP)
	await frames()
	check_eq(results, [{"chapter": "anchor", "answer": ""}], "one result, no answer")
	check(ChapterResult.is_story_result(results[0]) if results.size() > 0 else false, "a real story result")
	check(house.visible, "the House is back")
	runner.chapter_finished.disconnect(on_finished)
	runner.free()


func test_leaving_part_way_gives_no_result_or_save_and_the_next_visit_starts_at_the_beginning() -> void:
	_anchor.free()
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
	runner.enter(&"anchor", house)
	var anchor: Node = runner.get_child(0)
	anchor.auto_advance = false
	for k in roundi(60.0 / STEP):
		anchor.advance(STEP)
	check_eq(anchor.carry().stage, AnchorCarry.Stage.STORM, "part-way in, in the storm")
	anchor.queue_free()  # Leaving: the page closed, say.
	await frames()
	check_eq(results, [], "no result")
	check_eq(left, [&"anchor"], "it left")
	check_eq(state.to_save_data(), saved_before, "nothing saved")
	runner.enter(&"anchor", house)
	var again: Node = runner.get_child(0)
	check_eq(again.carry().stage, AnchorCarry.Stage.STEADY, "the next visit starts in the calm")
	check_eq(again.carry().distance, 0.0, "at the front of the House")
	check_eq(again.carry().falls, 0, "with no falls")
	runner.chapter_finished.disconnect(on_finished)
	runner.chapter_left.disconnect(on_left)
	runner.free()


func test_the_chapter_never_touches_the_house_another_chapter_or_saved_state() -> void:
	for path in ["res://scenes/chapters/anchor/anchor.gd", "res://scenes/chapters/anchor/anchor_carry.gd",
			"res://scenes/chapters/anchor/anchor_zone.gd"]:
		var source := FileAccess.get_file_as_string(path)
		for forbidden in ["GameState", "/root/", "HouseTable", "house_", "scenes/house", "SaveFile",
				"user://", "chapters/partner", "chapters/protector", "chapters/tuner", "ChapterRunner"]:
			check(not source.contains(forbidden), "%s doesn't mention %s" % [path.get_file(), forbidden])


# --- Pause

func test_hiding_the_tab_pauses_everything_and_never_saves_until_a_tap() -> void:
	var state := get_node("/root/GameState")
	var saved_before: Dictionary = state.to_save_data()
	_run(3.0)
	_press(_zone_centre(1), 0)
	_anchor.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(_anchor.is_paused(), "paused")
	check_eq(_carry().hold, 0, "pausing lets go of the zones")
	check(not _anchor.is_sound_playing(), "the sound stops")
	var frozen: Dictionary = {"t": _carry().time, "d": _carry().distance, "lean": _carry().lean}
	_run(5.0)
	check_eq({"t": _carry().time, "d": _carry().distance, "lean": _carry().lean}, frozen, "nothing moves")
	check(_anchor.get_node("Subtitle").visible == false, "no words while paused")
	check_eq(state.to_save_data(), saved_before, "nothing saved")
	tap_at(_zone_centre(-1))
	check(not _anchor.is_paused(), "a tap resumes")
	check_eq(_carry().hold, 0, "the tap that resumes doesn't hold a zone")
	check(_anchor.is_sound_playing(), "the sound is back")
	_run(1.0)
	check(_carry().time > frozen["t"], "the clock runs again")
	_lift(_zone_centre(1), 0)


# --- One tap scheme

func test_keys_and_hover_do_nothing() -> void:
	for key in [KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D, KEY_SPACE, KEY_ENTER]:
		var press := InputEventKey.new()
		press.keycode = key
		press.pressed = true
		get_viewport().push_input(press, true)
		check_eq(_carry().hold, 0, "key %s holds nothing" % OS.get_keycode_string(key))
	var hover := InputEventMouseMotion.new()
	hover.position = _zone_centre(-1)
	hover.global_position = hover.position
	get_viewport().push_input(hover, true)
	check_eq(_carry().hold, 0, "hovering over a zone holds nothing")
	check(not _anchor.zone(-1).held, "and doesn't light it")


func test_the_playtest_clock_counts_the_chapter() -> void:
	_run(12.0)
	check_near(_anchor.playtest_time(), 12.0, 0.02, "seconds into the Anchor")
