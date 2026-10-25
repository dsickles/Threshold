extends TestCase
## The Protector's run (DAS-97), on the run's own clock instead of real time.
## The rules come from docs/design/the-loss-run-and-car.md, "Checks this
## design must pass". Feel, sound and the fade's weight are Dan's to check on
## his phone.

const PROTECTOR := preload("res://scenes/chapters/protector/protector.tscn")
const RunPlan := preload("res://scenes/chapters/protector/run_plan.gd")
const MENU := preload("res://scenes/ui/m0_menu.tscn")
const STEP := 1.0 / 10.0

var _chapter: Node
var _run: Node


func before_each() -> void:
	_chapter = add_scene(PROTECTOR)
	_run = _chapter.run()
	_run.auto_advance = false


func test_the_obstacle_list_matches_the_design() -> void:
	var list := RunPlan.obstacles()
	check_eq(list.size(), 49, "obstacles in the run")
	var by_part := {}
	for obstacle in list:
		by_part[obstacle.part] = by_part.get(obstacle.part, 0) + 1
	check_eq(by_part.get(RunPlan.Part.EUPHORIA, 0), 12, "in the euphoria")
	check_eq(by_part.get(RunPlan.Part.CONFUSION, 0), 12, "in the confusion")
	check_eq(by_part.get(RunPlan.Part.PANIC, 0), 25, "in the panic")
	check_eq(by_part.get(RunPlan.Part.SILENCE, 0), 0, "in the silence")
	check_eq(by_part.get(RunPlan.Part.DARK, 0), 0, "in the dark")
	check_near(list[-1].time, 172.2, 0.001, "the last one (2:52)")
	for i in range(1, list.size()):
		check(list[i].time > list[i - 1].time, "obstacle %d comes after the one before" % i)
	# The first two are lone stones, so the tap is learned on the simplest shape.
	check_eq([list[0].kind, list[1].kind], [RunPlan.Kind.STONE, RunPlan.Kind.STONE], "the first two")
	check(list[1].time - list[0].time > 5.0, "the first two are alone")
	# The euphoria's land on the song's beat: every 2 bars at 90 BPM from 0:13.
	var design := [13, 18, 24, 29, 34, 40, 45, 50, 56, 61, 66, 72]
	for k in 12:
		check_near(list[k].time, 13.0 + k * 16.0 / 3.0, 0.001, "euphoria obstacle %d on the beat" % k)
		check_near(list[k].time, design[k], 0.5, "euphoria obstacle %d at the design's time" % k)
	check_eq(list[11].time < 73.0, true, "1:12 to 1:25 is clear")
	# Each part's times and shapes, as the design lists them.
	var kinds := ""
	for obstacle in list:
		kinds += "SBG"[obstacle.kind]
	check_eq(kinds, "SSBSGBSGBSGS" + "SGBSSBGSBGSG" + "SSBSGGSSBSBGSSGGBSGSBSGBS", "the kinds in order")


func test_the_obstacle_sequence_is_fixed_not_random() -> void:
	check_eq(RunPlan.obstacles(), RunPlan.obstacles(), "the same list every time")
	var other: Node = add_scene(PROTECTOR).run()
	other.auto_advance = false
	for i in _run.obstacles().size():
		check_eq(other.obstacles()[i].distance, _run.obstacles()[i].distance, "obstacle %d in the same place" % i)
	check_eq(other._path_points, _run._path_points, "the same path")


func test_the_run_starts_from_the_lamp_with_no_title_or_skip() -> void:
	check_eq(_run.time(), 0.0, "starts at the lamp click")
	check_eq(_run.part(), RunPlan.Part.DARK, "a breath of dark first")
	check_eq(_run.light_brightness(), 0.0, "the light is not up yet")
	check(not _run.is_music_playing(), "no music in the dark")
	_assert_no_words_or_buttons(_chapter)


func test_the_music_starts_at_five_seconds_and_stops_dead_at_the_silence() -> void:
	_step_to(4.9)
	check(not _run._music.playing, "silent in the dark")
	_step_to(5.1)
	check(_run._music.playing, "the song from 0:05")
	_step_to(176.0)
	check(not _run._music.playing, "nothing after 2:55")


func test_a_perfect_run_and_an_empty_run_reach_the_same_ending() -> void:
	var perfect := _play(true)
	var empty := _play(false)
	check_eq(perfect.cleared, 49, "the perfect run clears every obstacle")
	check_eq(perfect.stumbled, 0, "and never stumbles")
	check_eq(empty.cleared, 0, "the empty run clears nothing")
	check_eq(empty.stumbled, 49, "and stumbles on every obstacle")
	check_eq(perfect.brightness_at_silence, 1.0, "the light is fully bright at 2:55 after a perfect run")
	check_eq(empty.brightness_at_silence, perfect.brightness_at_silence, "and exactly as bright after an empty one")
	check_eq(empty.distance_at_silence, perfect.distance_at_silence, "the light is in the same place at 2:55")
	check_near(perfect.out_at, RunPlan.OUT, STEP, "the perfect run's light goes out at 3:25")
	check_eq(empty.out_at, perfect.out_at, "the empty run's at the same moment")
	check_near(perfect.finished_at, RunPlan.BLACK, STEP, "the perfect run finishes at 3:35")
	check_eq(empty.finished_at, perfect.finished_at, "the empty run at the same moment")
	check_eq(perfect.finishes, 1, "the perfect run finishes once")
	check_eq(empty.finishes, 1, "the empty run finishes once")


func test_a_tap_with_nothing_in_reach_clears_nothing_and_changes_nothing() -> void:
	var first: Dictionary = _run.obstacles()[0]
	_step_to(first.time - RunPlan.reach(first.part) - 0.2)
	var before := _snapshot()
	check_eq(_run.tap(Vector2(100, 100)), -1, "nothing cleared")
	check_eq(_snapshot(), before, "nothing changed")
	check_eq(_run.ripple_count(), 1, "a small ripple where the finger landed")


func test_a_tap_with_something_in_reach_clears_exactly_one() -> void:
	# The first panic cluster: two stones 0.6 s apart, both in reach at once.
	var i := _first_in(RunPlan.Part.PANIC)
	var a: Dictionary = _run.obstacles()[i]
	_step_to(a.time - 0.1)
	check(_run.is_in_reach(i) and _run.is_in_reach(i + 1), "two in reach")
	check_eq(_run.tap(Vector2(640, 360)), i, "the tap clears the nearest")
	check_eq(_run.count(_run.Status.CLEARED), 1, "exactly one cleared")
	check(_run.is_in_reach(i + 1), "the next is still there to clear")
	check_eq(_run.tap(Vector2(640, 360)), i + 1, "the next tap clears the next")
	check_eq(_run.ripple_count(), 0, "a tap that clears makes no ripple")


func test_every_obstacle_can_be_cleared_at_the_edge_of_its_reach() -> void:
	for i in _run.obstacles().size():
		var obstacle: Dictionary = _run.obstacles()[i]
		_step_to(obstacle.time - RunPlan.reach(obstacle.part) + 0.01)
		check(_run.is_in_reach(i), "obstacle %d in reach as its window opens" % i)
		_run.tap(Vector2.ZERO)
	check_eq(_run.count(_run.Status.CLEARED), 49, "all cleared")


func test_a_tap_anywhere_on_the_screen_clears() -> void:
	var first: Dictionary = _run.obstacles()[0]
	_step_to(first.time - 0.5)
	tap_at(Vector2(4, 4))  # The far corner, through the viewport like a player.
	check_eq(first.status, _run.Status.CLEARED, "a tap in the corner clears it")


func test_a_stumble_never_changes_the_lights_speed_or_position_and_it_recovers() -> void:
	var first: Dictionary = _run.obstacles()[0]
	_step_to(first.time - 0.05)
	var before: float = _run.light_distance()
	_step_to(first.time + 0.05)
	check_eq(first.status, _run.Status.STUMBLED, "the light went through it")
	check_near(_run.light_distance() - before, RunPlan.SPEED * 0.1, 0.05, "no slower through the stumble")
	check_eq(_run.light_distance(), RunPlan.distance(_run.time()), "where an unstumbled light would be")
	check(_run.light_brightness() < 1.0, "the light flickers dimmer")
	_step_to(first.time + 1.0)
	check_eq(_run.light_brightness(), 1.0, "and is fully back within a second")
	check(not _run.has_ended(), "a stumble never ends the run")


func test_taps_in_the_silence_never_reach_the_light() -> void:
	_step_to(180.0)
	check_eq(_run.part(), RunPlan.Part.SILENCE, "the silence")
	var before := _snapshot()
	for k in 5:
		check_eq(_run.tap(Vector2(640, 360)), -1, "nothing to clear in the silence")
	check_eq(_snapshot(), before, "the light runs on unchanged")
	check_eq(_run.ripple_count(), 5, "each tap only ripples")


func test_hiding_the_tab_pauses_the_run_and_saves_nothing() -> void:
	var state := get_node("/root/GameState")
	state.start_new()
	_step_to(30.0)
	_run.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(_run.is_paused(), "paused when the window is hidden")
	_run.advance(5.0)
	check_near(_run.time(), 30.0, STEP, "the clock stopped")
	check(not state.has_save(), "nothing saved")
	check_eq(_run.tap(Vector2(640, 360)), -1, "the tap that resumes clears nothing")
	check_eq(_run.ripple_count(), 0, "and makes no ripple")
	check(not _run.is_paused(), "running again after a tap")
	_run.advance(1.0)
	check_near(_run.time(), 31.0, STEP, "picks up where it paused")


func test_leaving_mid_run_saves_nothing_and_next_time_starts_from_the_lamp() -> void:
	_chapter.free()
	var state := get_node("/root/GameState")
	state.start_new()
	state.record_chapter_result(ChapterResult.make(&"partner"))
	var house := Node.new()
	add_child(house)
	var runner := ChapterRunner.of(get_tree())
	var left: Array[StringName] = []
	runner.chapter_left.connect(func(id: StringName) -> void: left.append(id))
	check(runner.enter(&"protector", house), "the run starts")
	var run: Node = runner.get_child(0).run()
	run.auto_advance = false
	run.advance(100.0)
	runner.get_child(0).queue_free()  # Closing the tab part-way, say.
	await frames()
	check_eq(left, [&"protector"], "left without a result")
	check_eq(state.finished_chapters(), ["partner"], "nothing saved for the Protector")
	check(runner.enter(&"protector", house), "it can start again")
	check_eq(runner.get_child(0).run().time(), 0.0, "from the lamp click, not where it was left")
	runner.get_child(0).free()
	await frames()
	state.start_new()
	runner.free()


func test_the_chapter_reports_finished_once_with_no_answer_and_is_saved() -> void:
	_chapter.free()
	var state := get_node("/root/GameState")
	state.start_new()
	state.record_chapter_result(ChapterResult.make(&"partner"))
	var house := Node.new()
	add_child(house)
	var runner := ChapterRunner.of(get_tree())
	if not runner.chapter_finished.is_connected(state.record_chapter_result):
		runner.chapter_finished.connect(state.record_chapter_result)
	var results: Array[Dictionary] = []
	runner.chapter_finished.connect(func(result: Dictionary) -> void: results.append(result))
	runner.enter(&"protector", house)
	var run: Node = runner.get_child(0).run()
	run.auto_advance = false
	run.advance(RunPlan.BLACK - 1.0)
	check(results.is_empty(), "not finished before the black")
	check_eq(state.finished_chapters(), ["partner"], "nothing saved before it finishes")
	run.advance(2.0)
	await frames()
	check_eq(results, [ChapterResult.make(&"protector")], "finished once, with no answer")
	check_eq(state.finished_chapters(), ["partner", "protector"], "saved when it finished")
	state.start_new()
	runner.free()


func test_the_menu_opens_the_protector_and_takes_it_back() -> void:
	_chapter.free()
	var menu := add_scene(MENU)
	tap(menu.get_node("%BeginButton"))
	await frames()
	var button: Control = menu.get_node("%ProtectorButton")
	check(button.size.x >= 44.0 and button.size.y >= 44.0, "Protector button is at least 44px")
	tap(button)
	var runner := ChapterRunner.of(get_tree())
	var chapter: Node = runner.get_child(0) if runner.get_child_count() > 0 else null
	if not check(chapter != null and chapter.scene_file_path == PROTECTOR.resource_path, "the Protector opened"):
		runner.free()
		return
	check(not menu.visible, "menu hidden while it plays")
	var run: Node = chapter.run()
	run.auto_advance = false
	run.advance(RunPlan.BLACK + 0.1)
	await frames()
	check(not is_instance_valid(chapter), "closed when finished")
	check(menu.visible, "menu back afterwards")
	check_eq(menu.get_node("%Status").text, "Finished protector (answer: none)", "menu heard the result")
	runner.free()


func test_no_compositor_effects_or_volumetric_fog() -> void:
	var env: Environment = _run._env
	check(env.fog_enabled, "ordinary fog")
	check(not env.volumetric_fog_enabled, "no volumetric fog")
	check_eq(_run._camera.compositor, null, "no CompositorEffects")
	for node in _all(_chapter):
		if node is WorldEnvironment:
			check_eq(node.compositor, null, "no CompositorEffects on the world")


func test_nothing_on_screen_has_words_a_button_or_a_count_all_run() -> void:
	for t in [10.0, 100.0, 150.0, 180.0, 200.0, 214.0]:
		_step_to(t)
		_assert_no_words_or_buttons(_chapter)


func test_the_path_narrows_in_the_panic_and_is_whole_in_the_silence() -> void:
	_step_to(60.0)
	check_eq(_tiles_in(_row_at(_run.light_distance() + 10.0)), 3, "three tiles wide in the euphoria")
	_step_to(150.0)
	check_eq(_tiles_in(_row_at(_run.light_distance() + 10.0)), 1, "one tile wide in the panic")
	_step_to(176.0)
	var row := _row_at(_run.light_distance() + 10.0)
	check_eq(_tiles_in(row), 3, "whole again in the silence")
	for tile in _run._rows[row]:
		check_eq(tile.get_meta("fall"), INF, "nothing falls in the silence")


func test_the_light_runs_on_slows_stops_and_goes_out() -> void:
	_step_to(184.0)
	check_eq(_run.light_brightness(), 1.0, "fully bright as it runs on alone")
	var a: float = _run.light_distance()
	_step_to(185.0)
	check_near(_run.light_distance() - a, RunPlan.SPEED, 0.01, "still at full speed at 3:04")
	_step_to(195.0)
	var stopped: float = _run.light_distance()
	_step_to(200.0)
	check_eq(_run.light_distance(), stopped, "stopped by 3:15")
	check(_run.light_brightness() < 1.0 and _run.light_brightness() > 0.0, "going out")
	_step_to(205.5)
	check_eq(_run.light_brightness(), 0.0, "out by 3:25")
	check(not _run._light.visible, "nothing left of it")
	check(not _run.has_ended(), "the empty path stays until 3:35")


func test_the_world_drains_to_the_house_in_grief_by_the_silence() -> void:
	_step_to(60.0)
	var euphoria: Color = _run._env.background_color
	_step_to(180.0)
	check_eq(_run._env.background_color, Color("#5C534C"), "the sky is the House's grief gray")
	check(euphoria.s > 0.2, "the euphoria is warm, not gray")
	check(_run._env.fog_density < 0.01, "the fog lifts in the silence")


# --- Helpers.

func _step_to(t: float) -> void:
	while _run.time() < t - 0.0001 and not _run.has_ended() and not _run.is_paused():
		_run.advance(minf(STEP, t - _run.time()))


# Plays the whole run on a fresh chapter, tapping every obstacle as soon as it
# is in reach (perfect) or never tapping (empty).
func _play(perfect: bool) -> Dictionary:
	var chapter: Node = add_scene(PROTECTOR)
	var run: Node = chapter.run()
	run.auto_advance = false
	var out := {"finishes": 0, "finished_at": -1.0, "out_at": -1.0}
	chapter.finished.connect(func() -> void:
		out.finishes += 1
		out.finished_at = run.time())
	for k in ceili((RunPlan.BLACK + 2.0) / STEP):
		run.advance(STEP)
		if perfect:
			for i in run.obstacles().size():
				if run.is_in_reach(i):
					run.tap(Vector2(640, 360))
		if not out.has("brightness_at_silence") and run.time() >= RunPlan.SILENCE_START:
			out.brightness_at_silence = run.light_brightness()
			out.distance_at_silence = run.light_distance()
		if out.out_at < 0.0 and run.time() > RunPlan.STOPPED and run.light_brightness() == 0.0:
			out.out_at = run.time()
	out.cleared = run.count(run.Status.CLEARED)
	out.stumbled = run.count(run.Status.STUMBLED)
	chapter.free()
	return out


func _snapshot() -> Dictionary:
	var statuses := []
	for obstacle in _run.obstacles():
		statuses.append(obstacle.status)
	return {
		"statuses": statuses,
		"distance": _run.light_distance(),
		"brightness": _run.light_brightness(),
		"time": _run.time(),
	}


func _first_in(part: RunPlan.Part) -> int:
	for i in _run.obstacles().size():
		if _run.obstacles()[i].part == part:
			return i
	return -1


func _row_at(s: float) -> int:
	return floori(s / _run.TILE)


func _tiles_in(row: int) -> int:
	var n := 0
	for tile in _run._rows.get(row, []):
		if tile != null:
			n += 1
	return n


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out


func _assert_no_words_or_buttons(root: Node) -> void:
	for node in _all(root):
		check(not node is Label and not node is RichTextLabel and not node is BaseButton
				and not node is Label3D, "nothing to read or press: %s" % node.get_path())
