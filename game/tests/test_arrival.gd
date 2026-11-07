extends TestCase
## The Arrival (DAS-137), on the chapter's own clock and a fake song clock
## instead of real time and sound. Rules from docs/design/story-beats.md §8,
## epic-8-stories.md and the ticket's acceptance criteria. Whether the bag
## reads as a joke, whether the cry lands, and whether the taps line up with
## the heartbeat heard on a phone are Dan's to check.

const ARRIVAL := preload("res://scenes/chapters/arrival/arrival.tscn")
const Arrival := preload("res://scenes/chapters/arrival/arrival.gd")
const ArrivalCry := preload("res://scenes/chapters/arrival/arrival_cry.gd")
const ArrivalHand := preload("res://scenes/chapters/arrival/arrival_hand.gd")
const MENU := preload("res://scenes/ui/m0_menu.tscn")
const STEP := 0.1


class FakeConductor extends Node:
	var t := -1.0
	var tap := -1.0
	var paused := false
	var started := false
	var stopped := false
	var uses_browser_clock := false
	func is_ready() -> bool: return true
	func has_failed() -> bool: return false
	func start(from := 0.0) -> void:
		started = true
		t = from
	func stop() -> void: stopped = true
	func pause() -> void: paused = true
	func resume() -> void: paused = false
	func is_paused() -> bool: return paused
	func has_song_ended() -> bool: return false
	func song_time() -> float: return t
	func tap_time() -> float: return tap


var _arrival: Node
var _fake: FakeConductor
var _finishes := []


func before_each() -> void:
	_arrival = add_scene(ARRIVAL)
	_use_fake(_arrival)
	_finishes.clear()
	_arrival.finished.connect(func(...args: Array) -> void: _finishes.append(args))


func _use_fake(arrival: Node) -> FakeConductor:
	arrival.auto_advance = false
	var fake := FakeConductor.new()
	arrival.add_child(fake)
	arrival._conductor = fake
	if arrival == _arrival:
		_fake = fake
	return fake


# --- Helpers

func _run(seconds: float, arrival: Node = _arrival) -> void:
	for k in roundi(seconds / STEP):
		if not is_instance_valid(arrival):
			return
		# In the hand beat the song's clock moves with the chapter's.
		var fake: FakeConductor = arrival._conductor
		if fake.started and not fake.paused:
			fake.t += STEP
		arrival.advance(STEP)


func _run_until_beat(beat: int, limit: float, arrival: Node = _arrival) -> bool:
	var spent := 0.0
	while is_instance_valid(arrival) and arrival.beat != beat and spent < limit:
		_run(STEP, arrival)
		spent += STEP
	return is_instance_valid(arrival) and arrival.beat == beat


func _tap_target(rect: Rect2, arrival: Node = _arrival) -> void:
	arrival.tap_at(rect.get_center())


## Plays the door beat the shortest way: bag twice, keys, door.
func _through_the_door(arrival: Node = _arrival) -> void:
	_tap_target(arrival.bag_rect(), arrival)
	_tap_target(arrival.bag_rect(), arrival)
	_tap_target(arrival.keys_rect(), arrival)
	_tap_target(arrival.door_rect(), arrival)
	_run_until_beat(Arrival.Beat.CRY, 10.0, arrival)


func _find_the_cry(arrival: Node = _arrival) -> void:
	arrival.cry().set_knob(0, ArrivalCry.CRY_AT.x)
	arrival.cry().set_knob(1, ArrivalCry.CRY_AT.y)
	_run_until_beat(Arrival.Beat.HAND, 30.0, arrival)


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


func _turn_points(knob: Control, degrees: float) -> Array:
	var middle := knob.get_global_rect().get_center()
	var r: float = knob.radius() * 0.7
	var points := []
	for k in range(1, 13):
		points.append(middle + Vector2.from_angle(deg_to_rad(degrees * k / 12.0)) * r)
	return points


func _knob_start(knob: Control) -> Vector2:
	return knob.get_global_rect().get_center() + Vector2(knob.radius() * 0.7, 0.0)


func _all_nodes(node: Node, out: Array = []) -> Array:
	out.append(node)
	for child in node.get_children():
		_all_nodes(child, out)
	return out


func _words_on_screen() -> Array:
	var words := []
	for node in _all_nodes(_arrival):
		if node is Label and node.is_visible_in_tree() and node.text != "" and node.modulate.a > 0.0:
			words.append(node.text)
		if node is Button and node.is_visible_in_tree():
			words.append(node.text)
		if node is Control and node.tooltip_text != "":
			words.append(node.tooltip_text)
	return words


# 44 phone points in the stretched canvas's units.
func _min_units(screen: Vector2i) -> float:
	var view := get_viewport().get_visible_rect()
	var units_per_point := view.size.y / float(mini(screen.x, screen.y)) \
			if screen.x > screen.y else view.size.x / float(screen.x)
	return 44.0 * units_per_point


# --- Opening it

func test_the_menu_opens_the_arrival_through_the_chapter_runner() -> void:
	_arrival.free()  # So it can't take the menu's taps.
	var menu := add_scene(MENU)
	tap(menu.get_node("%BeginButton"))
	await frames()
	var button: Control = menu.get_node("%ArrivalButton")
	check(button.size.x >= 44.0 and button.size.y >= 44.0, "Arrival button is at least 44px")
	check_eq(button.text, "The Arrival (rough)", "the button's words")
	tap(button)
	var runner := ChapterRunner.of(get_tree())
	check_eq(runner.current_chapter(), &"arrival", "the runner is playing the Arrival")
	var arrival: Node = runner.get_child(0) if runner.get_child_count() > 0 else null
	if check(arrival != null and arrival.scene_file_path == ARRIVAL.resource_path, "the Arrival opened"):
		check(not menu.visible, "menu hidden while the Arrival plays")
		arrival.finished.emit()
		await frames()
		check(menu.visible, "menu back after the Arrival finished")
		check_eq(menu.get_node("%Status").text, "Finished arrival (answer: none)", "menu heard the result")
	runner.free()


func test_the_chapter_list_has_the_arrival_last() -> void:
	check_eq(ChapterList.scene_path(&"arrival"), ARRIVAL.resource_path, "the Arrival's scene")
	check_eq(ChapterList.STORY_ORDER[-1], &"arrival", "the last chapter in story order")


# --- The beats, in order

func test_the_beats_come_in_order_door_cry_hand_home() -> void:
	var seen := [Arrival.Beat.keys()[_arrival.beat]]
	_through_the_door()
	seen.append(Arrival.Beat.keys()[_arrival.beat])
	_find_the_cry()
	seen.append(Arrival.Beat.keys()[_arrival.beat])
	check(_run_until_beat(Arrival.Beat.HOME, 120.0), "home after the hand")
	seen.append(Arrival.Beat.keys()[_arrival.beat])
	check_eq(seen, ["DOOR", "CRY", "HAND", "HOME"], "the beats in order")
	_run(Arrival.HOME_TIME + 1.0)
	check_eq(_arrival.beat, Arrival.Beat.DONE, "done after the quiet hold")


# --- Out the door

func test_the_bag_wont_shut_on_the_first_try_then_does() -> void:
	check_eq(_arrival.next_door_target(), "bag", "the bag first")
	_tap_target(_arrival.bag_rect())
	check(not _arrival.bag_shut, "the first try doesn't shut it")
	check_eq(_arrival.bag_tries, 1, "one try")
	_run(Arrival.BURST_TIME)
	check_eq(_arrival.next_door_target(), "bag", "still the bag")
	_tap_target(_arrival.bag_rect())
	check(_arrival.bag_shut, "the second try shuts it")
	check_eq(_arrival.next_door_target(), "keys", "then the keys")


func test_the_door_opens_only_after_the_bag_and_the_keys() -> void:
	_tap_target(_arrival.door_rect())
	_tap_target(_arrival.keys_rect())
	check(not _arrival.door_opened and not _arrival.keys_taken, "nothing before the bag is shut")
	_tap_target(_arrival.bag_rect())
	_tap_target(_arrival.bag_rect())
	_tap_target(_arrival.door_rect())
	check(not _arrival.door_opened, "the door waits for the keys")
	_tap_target(_arrival.keys_rect())
	check(_arrival.keys_taken, "keys taken")
	_tap_target(Rect2(Vector2(2, 2), Vector2(4, 4)))
	check(not _arrival.door_opened, "a tap on nothing does nothing")
	_tap_target(_arrival.door_rect())
	check(_arrival.door_opened, "the door opens")
	check_eq(_arrival.beat, Arrival.Beat.DOOR, "it swings open first")
	_run(Arrival.DOOR_OPEN_TIME + STEP)
	check_eq(_arrival.beat, Arrival.Beat.CRY, "then the cry")


func test_the_door_beats_targets_are_at_least_44px_and_on_screen() -> void:
	for screen in [Vector2i(1280, 720), Vector2i(393, 852), Vector2i(852, 393)]:
		set_screen(screen)
		await frames(2)
		var view := get_viewport().get_visible_rect()
		var min_units := _min_units(screen)
		var rects := {"bag": _arrival.bag_rect(), "keys": _arrival.keys_rect(), "door": _arrival.door_rect()}
		for name: String in rects:
			var rect: Rect2 = rects[name]
			check(rect.size.x >= min_units and rect.size.y >= min_units,
					"%s at least 44 points on %s (is %s, needs %.0f)" % [name, screen, rect.size, min_units])
			check(view.encloses(rect), "%s on screen on %s" % [name, screen])
		check(not rects.bag.intersects(rects.keys) and not rects.bag.intersects(rects.door)
				and not rects.keys.intersects(rects.door), "the targets apart on %s" % screen)


func test_no_words_in_the_door_and_cry_beats() -> void:
	await frames()
	check_eq(_words_on_screen(), [], "no words at the door")
	_tap_target(_arrival.bag_rect())
	_run(0.5)
	check_eq(_words_on_screen(), [], "no words as the bag bursts")
	_through_the_door()
	_run(5.0)
	check_eq(_words_on_screen(), [], "no words while tuning")
	for k in 2:
		check_eq(_arrival.knob(k).tooltip_text, "", "knob %d has no tooltip" % (k + 1))
		check_eq(_arrival.knob(k).get_child_count(), 0, "knob %d has no label" % (k + 1))


# --- Hear the cry

func test_two_knobs_at_least_44px_and_on_screen_on_laptop_and_phones() -> void:
	_through_the_door()
	for screen in [Vector2i(1280, 720), Vector2i(393, 852), Vector2i(852, 393)]:
		set_screen(screen)
		await frames(2)
		var view := get_viewport().get_visible_rect()
		var picture: Control = _arrival.get_node("Screen")
		var min_units := _min_units(screen)
		for k in 2:
			var knob: Control = _arrival.knob(k)
			check(knob.is_visible_in_tree(), "knob %d shows in the cry beat" % (k + 1))
			var rect := knob.get_global_rect()
			check(rect.size.x >= min_units and rect.size.y >= min_units,
					"knob %d at least 44 points on %s (is %s, needs %.0f)" % [k + 1, screen, rect.size, min_units])
			check(view.encloses(rect), "knob %d on screen on %s" % [k + 1, screen])
			check(not rect.intersects(picture.get_global_rect()), "knob %d clear of the picture on %s" % [k + 1, screen])
		check(view.encloses(picture.get_global_rect()), "the picture on screen on %s" % screen)


func test_the_knobs_only_show_in_the_cry_beat() -> void:
	await frames()
	check(not _arrival.knob(0).is_visible_in_tree(), "no knobs at the door")
	_through_the_door()
	check(_arrival.knob(0).is_visible_in_tree(), "knobs for the cry")
	_find_the_cry()
	check(not _arrival.knob(0).is_visible_in_tree(), "no knobs for the hand")


func test_dragging_a_knob_turns_it_and_changes_the_waveform() -> void:
	_through_the_door()
	await frames()
	var knob: Control = _arrival.knob(0)
	var before_value: float = knob.value
	var before_trace: PackedVector2Array = _arrival.waveform_points()
	var before_strength: float = _arrival.cry().strength()
	# Clockwise, towards the cry on the first dial.
	_drag(_knob_start(knob), _turn_points(knob, 140.0))
	_arrival.advance(0.0)
	check(knob.value > before_value + 0.2, "the first knob turned up (%.2f to %.2f)" % [before_value, knob.value])
	check_near(_arrival.cry().knobs.x, knob.value, 0.0001, "the search heard the turn")
	check(_arrival.cry().strength() > before_strength, "more of the cry comes through")
	check(_arrival.waveform_points() != before_trace, "the waveform changed")


func test_off_the_signal_the_static_stays_with_no_popup() -> void:
	_through_the_door()
	var nodes_before := _all_nodes(_arrival).size()
	_arrival.cry().set_knob(0, 0.0)
	_arrival.cry().set_knob(1, 1.0)
	_run(20.0)
	check_eq(_arrival.cry().stage, ArrivalCry.Stage.SEARCH, "still searching")
	check_eq(_arrival.cry().clarity, 0.0, "all static")
	check(_arrival.sound_level("static") > 0.3, "the static is heard")
	check_eq(_all_nodes(_arrival).size(), nodes_before, "no popup or anything new on screen")
	check_eq(_words_on_screen(), [], "no wrong message")


func test_finding_the_cry_clears_the_static_like_the_tuner() -> void:
	_through_the_door()
	var mat := (_arrival.get_node("Screen") as ColorRect).material as ShaderMaterial
	check_eq(mat.get_shader_parameter("clarity"), 0.0, "all static at first")
	_arrival.cry().set_knob(0, ArrivalCry.CRY_AT.x)
	_arrival.cry().set_knob(1, ArrivalCry.CRY_AT.y)
	_run(ArrivalCry.LOCK_HOLD + STEP * 2.0)
	check_eq(_arrival.cry().stage, ArrivalCry.Stage.THROUGH, "the cry comes through")
	# Through is through: turning away doesn't lose it.
	_arrival.cry().set_knob(0, 0.0)
	check_near(_arrival.cry().knobs.x, ArrivalCry.CRY_AT.x, 0.0001, "the knobs stay once through")
	_run(ArrivalCry.CLEAR_TIME)
	check_near(mat.get_shader_parameter("clarity"), 1.0, 0.03, "the static has cleared")
	check(_arrival.sound_level("cry") > 0.9, "the cry is heard clearly")
	check(_arrival.sound_level("static") < 0.1, "the static has gone")


func test_a_player_who_never_touches_the_knobs_still_hears_the_cry() -> void:
	_through_the_door()
	check(_run_until_beat(Arrival.Beat.HAND, 120.0), "the hand beat comes, untouched")
	check(_arrival.cry().time < 100.0, "within 100 s (took %.0f s)" % _arrival.cry().time)


func test_the_cry_lock_widens_the_longer_the_search_goes_on() -> void:
	var cry := ArrivalCry.new()
	var at_start: float = cry.lock_within()
	cry.advance(ArrivalCry.ASSIST_AFTER)
	check_near(cry.lock_within(), at_start, 0.0001, "no help at first")
	cry.knobs = Vector2(0.0, 1.0)  # Far off, so it doesn't lock.
	for k in 200:
		cry.advance(STEP)
	check(cry.lock_within() > at_start, "wider after a while")


# --- Hold the hand

func test_the_hand_beat_judges_taps_perfect_good_and_miss_and_carries_on() -> void:
	_through_the_door()
	_find_the_cry()
	_run(STEP)
	check(_fake.started, "the song started")
	var notes: PackedFloat64Array = _arrival.hand().notes
	# Note 0, on time.
	_fake.t = notes[0]
	_fake.tap = notes[0]
	_arrival.tap_at(_arrival.hands_centre())
	check_eq(_arrival.probe_state().judgement, "Perfect", "on the note: Perfect")
	# Note 1, 120 ms late.
	_fake.t = notes[1] + 0.12
	_fake.tap = notes[1] + 0.12
	_arrival.tap_at(Vector2(10, 10))  # Anywhere: the whole screen is the tap.
	check_eq(_arrival.probe_state().judgement, "Good", "near the note: Good")
	# A stray tap half-way between notes does nothing.
	_fake.tap = (notes[1] + notes[2]) / 2.0
	var hits_before: int = _arrival.hand().hits()
	_arrival.tap_at(_arrival.hands_centre())
	check_eq(_arrival.hand().hits(), hits_before, "a stray tap does nothing")
	check_eq(_arrival.hand().misses(), 0, "and isn't a Miss")
	# Note 2 left alone: a Miss, and the beat goes on.
	_fake.t = notes[2] + 0.5
	_arrival.advance(STEP)
	check_eq(_arrival.probe_state().judgement, "Miss", "an untapped note: Miss")
	check_eq(_arrival.beat, Arrival.Beat.HAND, "the beat goes on")
	var judgement: Label = _arrival.get_node("Judgement")
	var below: float = _arrival.hands_centre().y
	check(judgement.position.y > below and judgement.position.y < below + _arrival._unit() * 0.4,
			"the word is near the hands")


func test_the_chart_leaves_room_so_one_tap_cant_count_twice() -> void:
	var hand := ArrivalHand.new()
	check_eq(hand.notes.size(), ArrivalHand.NOTE_COUNT, "every note")
	for i in range(1, hand.notes.size()):
		var gap := hand.notes[i] - hand.notes[i - 1]
		check(gap / 2.0 > ArrivalHand.GOOD_WINDOW + ArrivalHand.MISS_GRACE,
				"notes %d and %d far enough apart" % [i - 1, i])
	check(hand.last_note() < ArrivalHand.SONG_LENGTH, "the last note is inside the song")


func test_intro_taps_set_the_sound_delay() -> void:
	var hand := ArrivalHand.new()
	for k in ArrivalHand.INTRO_NOTES:
		hand.judge(hand.notes[k] + 0.1)
	check_near(hand.sound_delay, 0.1, 0.001, "the delay is the middle of the intro taps")
	var said := hand.judge(hand.notes[ArrivalHand.INTRO_NOTES] + 0.1)
	check_eq(said, "Perfect", "a tap as late as the sound is on time")


func test_no_score_or_grade_screen_after_the_hand() -> void:
	_through_the_door()
	_find_the_cry()
	check(_run_until_beat(Arrival.Beat.HOME, 120.0), "home")
	await frames()
	for node in _all_nodes(_arrival):
		if node is Label and node.is_visible_in_tree() and node.modulate.a > 0.0:
			check_eq(node.text, "", "no words at home: %s" % node.text)
		check(not node is Button, "no buttons at home")


func test_the_hand_beat_uses_the_browser_audio_clock_on_the_web() -> void:
	var real: Node = _arrival.get_node("%Conductor")
	check_eq(real.get_script().resource_path, "res://scenes/chapters/arrival/arrival_conductor.gd",
			"the Arrival's own Conductor, not the Partner's")
	check_eq(real.uses_browser_clock, OS.has_feature("web"), "the browser's clock on the web only")
	var source := FileAccess.get_file_as_string("res://scenes/chapters/arrival/arrival_conductor.gd")
	check(source.contains("window.arrivalConductor"), "its own browser object")
	check(source.contains("getOutputTimestamp"), "timed from the sound as heard (ADR-0006)")
	check(not source.contains("window.partnerConductor"), "never the Partner's browser object")


# --- Finishing and leaving

func test_finishes_once_with_no_answer_whether_or_not_the_player_missed() -> void:
	_through_the_door()
	_find_the_cry()
	check(_run_until_beat(Arrival.Beat.DONE, 200.0), "to the end with no taps")
	check(_arrival.hand().misses() == ArrivalHand.NOTE_COUNT, "every note missed")
	_run(10.0)
	check_eq(_finishes, [[]], "finished exactly once, with no answer")
	check(not _arrival.is_sound_playing(), "sound stops at the end")


func test_a_perfect_player_ends_the_same_way() -> void:
	_through_the_door()
	_find_the_cry()
	_run(STEP)
	var notes: PackedFloat64Array = _arrival.hand().notes
	var next := 0
	while _arrival.beat == Arrival.Beat.HAND:
		if next < notes.size() and _fake.t >= notes[next]:
			_fake.tap = _fake.t
			_arrival.tap_at(_arrival.hands_centre())
			next += 1
		_run(STEP)
	check_eq(_arrival.hand().misses(), 0, "nothing missed")
	_run(Arrival.HOME_TIME + 1.0)
	check_eq(_finishes, [[]], "the same one ending")


func test_finishing_hands_back_one_result_with_no_answer_through_the_runner() -> void:
	_arrival.free()
	var house := Control.new()
	add_child(house)
	var runner := ChapterRunner.of(get_tree())
	var results := []
	var left := []
	var on_finished := func(result: Dictionary) -> void: results.append(result)
	var on_left := func(id: StringName) -> void: left.append(id)
	runner.chapter_finished.connect(on_finished)
	runner.chapter_left.connect(on_left)
	check(runner.enter(&"arrival", house), "entered")
	var arrival: Node = runner.get_child(0)
	_use_fake(arrival)
	_through_the_door(arrival)
	_find_the_cry(arrival)
	_run(200.0, arrival)
	await frames()
	check_eq(results, [{"chapter": "arrival", "answer": ""}], "one result, no answer")
	check(ChapterResult.is_story_result(results[0]) if results.size() > 0 else false, "a real story result")
	check_eq(left, [], "not counted as leaving")
	check(house.visible, "the House is back")
	runner.chapter_finished.disconnect(on_finished)
	runner.chapter_left.disconnect(on_left)
	runner.free()


func test_leaving_part_way_gives_no_result_or_save_and_the_next_visit_starts_at_the_door() -> void:
	_arrival.free()
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
	runner.enter(&"arrival", house)
	var arrival: Node = runner.get_child(0)
	_use_fake(arrival)
	_through_the_door(arrival)
	_find_the_cry(arrival)
	_run(10.0, arrival)
	check_eq(arrival.beat, Arrival.Beat.HAND, "part-way in, at the hand beat")
	arrival.queue_free()  # Leaving: the page closed, say.
	await frames()
	check_eq(results, [], "no result")
	check_eq(left, [&"arrival"], "it left")
	check_eq(state.to_save_data(), saved_before, "nothing saved")
	runner.enter(&"arrival", house)
	var again: Node = runner.get_child(0)
	check_eq(again.beat, Arrival.Beat.DOOR, "the next visit starts at the door")
	check_eq(again.bag_tries, 0, "with the bag still to shut")
	check_eq(again.playtest_time(), 0.0, "from the start")
	runner.chapter_finished.disconnect(on_finished)
	runner.chapter_left.disconnect(on_left)
	runner.free()


func test_the_chapter_never_touches_the_house_another_chapter_or_saved_state() -> void:
	for file in ["arrival.gd", "arrival_cry.gd", "arrival_hand.gd", "arrival_knob.gd", "arrival_conductor.gd"]:
		var path: String = "res://scenes/chapters/arrival/" + file
		var source := FileAccess.get_file_as_string(path)
		check(source != "", "%s read" % file)
		var code := PackedStringArray()
		for line in source.split("\n"):
			if not line.strip_edges().begins_with("#"):
				code.append(line)
		var body := "\n".join(code)
		for forbidden in ["GameState", "/root/", "HouseTable", "scenes/house", "SaveFile", "user://",
				"res://scenes/chapters/partner", "res://scenes/chapters/tuner",
				"res://scenes/chapters/protector", "ChapterRunner", "preload(\"res://scenes/chapters/p",
				"partnerConductor"]:
			check(not body.contains(forbidden), "%s doesn't use %s" % [file, forbidden])


# --- Pause, keys, hover

func test_hiding_the_tab_pauses_everything_and_the_next_tap_resumes() -> void:
	var state := get_node("/root/GameState")
	var saved_before: Dictionary = state.to_save_data()
	_through_the_door()
	_run(2.0)
	_arrival.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(_arrival.is_paused(), "paused")
	var time_before: float = _arrival.playtest_time()
	var cry_before: float = _arrival.cry().time
	_run(20.0)
	check_eq(_arrival.playtest_time(), time_before, "the chapter's clock stopped")
	check_eq(_arrival.cry().time, cry_before, "the search stopped")
	check(not _arrival.is_sound_playing(), "the sound stopped")
	check(_arrival.get_node("Cry").stream_paused, "the cry paused")
	check_eq(state.to_save_data(), saved_before, "hiding never saves")
	var knob: Control = _arrival.knob(0)
	var value: float = knob.value
	_drag(_knob_start(knob), _turn_points(knob, 90.0))
	check(not _arrival.is_paused(), "the tap resumed it")
	check_eq(knob.value, value, "the resuming tap didn't turn the knob")
	check(_arrival.is_sound_playing(), "the sound is back")
	_run(1.0)
	check(_arrival.playtest_time() > time_before, "the clock runs again")


func test_hiding_the_tab_in_the_hand_beat_pauses_the_song_and_the_resume_tap_isnt_judged() -> void:
	_through_the_door()
	_find_the_cry()
	_run(6.0)
	_arrival.pause()
	check(_fake.paused, "the song paused")
	var song_before: float = _fake.t
	_run(5.0)
	check_eq(_fake.t, song_before, "the song's clock waits")
	var hits: int = _arrival.hand().hits()
	var misses: int = _arrival.hand().misses()
	_fake.tap = _arrival.hand().notes[_arrival.hand().next_note()]
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = _arrival.hands_centre()
	click.global_position = click.position
	get_viewport().push_input(click, true)
	check(not _arrival.is_paused(), "a tap resumed it")
	check(not _fake.paused, "the song resumed")
	check_eq(_arrival.hand().hits(), hits, "the resuming tap wasn't judged")
	check_eq(_arrival.hand().misses(), misses, "and missed nothing")


func test_keys_and_hover_do_nothing() -> void:
	await frames()
	for key in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_ENTER, KEY_SPACE, KEY_A, KEY_D]:
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = true
		get_viewport().push_input(event, true)
	var hover := InputEventMouseMotion.new()  # No button down.
	for rect: Rect2 in [_arrival.bag_rect(), _arrival.keys_rect(), _arrival.door_rect()]:
		hover.position = rect.get_center()
		hover.global_position = hover.position
		get_viewport().push_input(hover.duplicate(), true)
	check_eq(_arrival.bag_tries, 0, "keys and hovering don't touch the bag")
	check(not _arrival.is_paused(), "and don't pause")
	_through_the_door()
	var knobs_before: Vector2 = _arrival.cry().knobs
	for k in 2:
		for point: Vector2 in _turn_points(_arrival.knob(k), 180.0):
			hover.position = point
			hover.global_position = point
			get_viewport().push_input(hover.duplicate(), true)
	check_eq(_arrival.cry().knobs, knobs_before, "hovering doesn't turn the knobs")


func test_a_real_tap_on_the_bag_works_through_input() -> void:
	await frames()
	tap_at(_arrival.bag_rect().get_center())
	check_eq(_arrival.bag_tries, 1, "a tap on the bag counts once")


# --- Length, the look, the clock

func test_a_modelled_player_finishes_in_about_2_to_4_minutes() -> void:
	# Takes 3 s to find each thing at the door, then turns the knobs slowly
	# towards the cry (like a player sweeping the dials), and leaves the
	# hand beat to play out.
	for target in ["bag", "bag", "keys", "door"]:
		_run(3.0)
		var rect: Rect2 = {"bag": _arrival.bag_rect(), "keys": _arrival.keys_rect(),
				"door": _arrival.door_rect()}[target]
		_tap_target(rect)
	_run_until_beat(Arrival.Beat.CRY, 10.0)
	while _arrival.beat == Arrival.Beat.CRY:
		var knobs: Vector2 = _arrival.cry().knobs
		var toward: Vector2 = knobs.move_toward(_arrival.cry().target, 0.0025)  # 0.025 a second
		_arrival.cry().set_knob(0, toward.x)
		_arrival.cry().set_knob(1, toward.y)
		_run(STEP)
	_run_until_beat(Arrival.Beat.DONE, 200.0)
	var minutes: float = _arrival.playtest_time() / 60.0
	check(minutes >= 2.0 and minutes <= 4.0, "about 2 to 4 minutes (took %.1f)" % minutes)
	# And a player who never touches the knobs.
	var slow: Node = add_scene(ARRIVAL)
	_use_fake(slow)
	_through_the_door(slow)
	_run_until_beat(Arrival.Beat.DONE, 400.0, slow)
	var slow_minutes: float = slow.playtest_time() / 60.0
	check(slow_minutes <= 4.0, "even untouched, under 4 minutes (took %.1f)" % slow_minutes)


func test_the_look_is_a_canvas_shader_with_no_compositor_effects() -> void:
	var screen: ColorRect = _arrival.get_node("Screen")
	var mat := screen.material as ShaderMaterial
	if not check(mat != null, "the screen has a shader"):
		return
	check_eq(mat.shader.get_mode(), Shader.MODE_CANVAS_ITEM, "a canvas shader")
	for word in ["grain", "split", "tear"]:
		check(mat.shader.code.contains(word), "the shader has its %s" % word)
	for node in _all_nodes(_arrival):
		check(not (node is WorldEnvironment or node is Camera3D or node is SubViewport),
				"no 3D or compositor in the Arrival: %s" % node.get_class())


func test_the_playtest_clock_counts_the_chapter() -> void:
	_run(12.0)
	check_near(_arrival.playtest_time(), 12.0, 0.01, "seconds into the Arrival")
