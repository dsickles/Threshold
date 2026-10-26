extends TestCase
## The Protector's run (DAS-97), on the run's own clock instead of real time.
## The rules come from docs/design/the-loss-run-and-car.md, "Checks this
## design must pass" (revised after Dan's first play, calls 13 to 16). Feel,
## sound and the fade's weight are Dan's to check on his phone.

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
	check_eq(list.size(), 41, "obstacles in the run")
	var by_part := {}
	for obstacle in list:
		by_part[obstacle.part] = by_part.get(obstacle.part, 0) + 1
	check_eq(by_part.get(RunPlan.Part.EUPHORIA, 0), 12, "in the euphoria")
	check_eq(by_part.get(RunPlan.Part.CONFUSION, 0), 12, "in the confusion")
	check_eq(by_part.get(RunPlan.Part.PANIC, 0), 17, "in the panic")
	check_eq(by_part.get(RunPlan.Part.FADE, 0), 0, "none as the light goes out")
	check_eq(by_part.get(RunPlan.Part.DARK, 0), 0, "in the dark")
	check_near(list[-1].time, 159.6, 0.001, "the last one (2:40)")
	for i in range(1, list.size()):
		check(list[i].time > list[i - 1].time, "obstacle %d comes after the one before" % i)
	# The euphoria's land on the song's beat: every 2 bars at 90 BPM from 0:13.
	var design := [13, 18, 24, 29, 34, 40, 45, 50, 56, 61, 66, 72]
	for k in 12:
		check_near(list[k].time, 13.0 + k * 16.0 / 3.0, 0.001, "euphoria obstacle %d on the beat" % k)
		check_near(list[k].time, design[k], 0.5, "euphoria obstacle %d at the design's time" % k)
	check_eq(list[11].time < 73.0, true, "1:12 to 1:25 is clear")
	# Each one's shape and lanes, in order, as the design lists them.
	var specs := ""
	for obstacle in list:
		specs += _spec(obstacle) + " "
	check_eq(specs.strip_edges(), " ".join([
		"S:M S:LR B:LM S:R G B:MR S:L G B:LM S:M G S:LR",
		"S:LM G B:MR S:L S:R B:LM G S:MR B:LM G S:LR G",
		"S:L S:R B:LM S:M G G S:R S:M B:MR S:M B:LM G S:R S:M G G B:MR",
	]), "the shapes and lanes in order")
	# The first is a lone stone straight ahead, so the tap is learned first.
	check_eq(_spec(list[0]), "S:M", "the first is a stone in the light's lane")
	check(list[1].time - list[0].time > 5.0, "and alone")


func test_every_obstacle_can_be_avoided_by_perfect_play() -> void:
	var list := RunPlan.obstacles()
	for i in list.size():
		var obstacle: Dictionary = list[i]
		if obstacle.kind == RunPlan.Kind.GAP:
			check_eq(obstacle.lanes, RunPlan.LANES, "gap %d is across all three lanes" % i)
			check(RunPlan.reach(obstacle.part) >= 0.8, "gap %d can be bridged" % i)
		else:
			check(not RunPlan.free_lanes(obstacle).is_empty(), "obstacle %d leaves a lane free" % i)
	# Inside each panic cluster one lane stays free all the way through.
	var start := 0
	while start < list.size() and list[start].part != RunPlan.Part.PANIC:
		start += 1
	var clusters := 0
	var i := start
	while i < list.size():
		var free: Array[int] = []
		free.assign(RunPlan.LANES)
		var j := i
		while j < list.size() and (j == i or list[j].time - list[j - 1].time < 0.7):
			free = free.filter(func(lane: int) -> bool: return not lane in list[j].lanes \
					or list[j].kind == RunPlan.Kind.GAP)
			j += 1
		check(not free.is_empty(), "the cluster at %.1f s has a lane free all through" % list[i].time)
		clusters += 1
		i = j
	check_eq(clusters, 7, "seven panic clusters")
	# Outside a cluster, at least 2 s before an obstacle that needs a new lane.
	for k in range(1, start):
		check(list[k].time - list[k - 1].time >= 2.0, "time to move before obstacle %d" % k)


func test_the_obstacle_sequence_is_fixed_not_random() -> void:
	check_eq(RunPlan.obstacles(), RunPlan.obstacles(), "the same list every time")
	var other: Node = add_scene(PROTECTOR).run()
	other.auto_advance = false
	for i in _run.obstacles().size():
		check_eq(other.obstacles()[i].distance, _run.obstacles()[i].distance, "obstacle %d in the same place" % i)
	check_eq(other._path_points, _run._path_points, "the same path")
	for slot in _run._slots:
		check_eq(other._slots[slot][0].transform, _run._slots[slot][0].transform, "the same trees")


func test_the_run_starts_from_the_lamp_with_no_title_or_skip() -> void:
	check_eq(_run.time(), 0.0, "starts at the lamp click")
	check_eq(_run.part(), RunPlan.Part.DARK, "a breath of dark first")
	check_eq(_run.light_brightness(), 0.0, "the light is not up yet")
	check(not _run.is_music_playing(), "no music in the dark")
	check_eq(_run.lane(), 0, "the light starts in the middle lane")
	_assert_no_words_or_buttons(_chapter)


func test_the_music_starts_at_five_seconds_and_the_storm_plays_to_the_black() -> void:
	_step_to(4.9)
	check(not _run._music.playing, "silent in the dark")
	_step_to(5.1)
	check(_run._music.playing, "the song from 0:05")
	_step_to(166.0)
	check(_run._music.playing, "the storm goes on after the song is gone (no dead stop)")
	_step_to(204.5)
	check(_run._music.playing, "still playing as it goes black")
	check(_run.MUSIC.get_length() >= RunPlan.BLACK - RunPlan.EUPHORIA_START - 0.1,
			"the track runs from 0:05 to 3:25")


func test_a_perfect_run_and_an_empty_run_reach_the_same_ending() -> void:
	var perfect := _play(true)
	var empty := _play(false)
	check_eq(perfect.passed, 41, "the perfect run gets past every obstacle")
	check_eq(perfect.stumbled, 0, "and never stumbles")
	var in_the_middle := 0
	for obstacle in RunPlan.obstacles():
		if 0 in obstacle.lanes:
			in_the_middle += 1
	check_eq(empty.stumbled, in_the_middle, "the empty run stumbles on everything in the middle lane")
	check_eq(empty.passed, 41 - in_the_middle, "and only gets past what isn't")
	check_eq(perfect.brightness_at_fade, 1.0, "the light is fully bright at 2:45 after a perfect run")
	check_eq(empty.brightness_at_fade, perfect.brightness_at_fade, "and exactly as bright after an empty one")
	check_eq(empty.distance_at_fade, perfect.distance_at_fade, "the light is as far along at 2:45")
	check_eq(empty.lane_when_held, perfect.lane_when_held, "and in the same lane once the hand holds it")
	check_near(perfect.out_at, RunPlan.OUT, STEP, "the perfect run's light goes out at 3:15")
	check_eq(empty.out_at, perfect.out_at, "the empty run's at the same moment")
	check_near(perfect.finished_at, RunPlan.BLACK, STEP, "the perfect run finishes at 3:25")
	check_eq(empty.finished_at, perfect.finished_at, "the empty run at the same moment")
	check_eq(perfect.finishes, 1, "the perfect run finishes once")
	check_eq(empty.finishes, 1, "the empty run finishes once")


func test_a_tap_on_a_lane_always_moves_the_light_there() -> void:
	_step_to(8.0)
	for lane: int in [-1, 1, 0, 1, -1]:
		_run.tap_lane(lane)
		check_eq(_run.lane(), lane, "the light goes to lane %d" % lane)
	check_eq(_run.ripple_count(), 0, "a tap that moves the light makes no ripple")
	_step_to(9.0)
	check_near(_run._lane_x(), -1.0, 0.001, "and is all the way there a moment later")
	check(not _run._hand.visible, "the hand has drawn back out of sight")


func test_a_tap_on_the_left_or_right_moves_the_light_one_lane_that_way() -> void:
	_step_to(8.0)
	var size: Vector2 = _run.get_viewport().get_visible_rect().size
	var left := Vector2(4, size.y / 2.0)
	var right := Vector2(size.x - 4, 4)
	# Through the viewport, like a player.
	tap_at(right)
	check_eq(_run.lane(), 1, "from the middle, a tap on the right goes one lane right")
	tap_at(right)
	check_eq(_run.lane(), 1, "already at the right edge: it stays")
	check_eq(_run.ripple_count(), 1, "and that tap only ripples")
	tap_at(left)
	check_eq(_run.lane(), 0, "from the right lane, a tap on the left goes to the middle")
	tap_at(Vector2(size.x / 2.0 - 1.0, size.y - 4))
	check_eq(_run.lane(), -1, "just left of the middle counts as the left, top to bottom")
	tap_at(Vector2(size.x / 2.0 + 1.0, 4))
	tap_at(right)
	check_eq(_run.lane(), 1, "two taps on the right move it two lanes")


func test_the_father_s_hand_moves_the_light() -> void:
	_step_to(8.0)
	check(not _run._hand.visible, "no hand until it has something to do")
	_run.tap_lane(1)
	_step_to(8.2)
	check(_run._hand.visible, "the hand comes in to move the light")
	check(_run._hand.global_position.distance_to(_run._light.global_position) < 1.5, "beside the light")


func test_a_tap_that_changes_nothing_changes_nothing() -> void:
	var first: Dictionary = _run.obstacles()[0]
	_step_to(first.time - 2.0)
	var before := _snapshot()
	check_eq(_run.tap_lane(0, Vector2(640, 360)), -1, "no gap bridged")
	check_eq(_snapshot(), before, "nothing changed: it was already in that lane")
	check_eq(_run.ripple_count(), 1, "a small ripple where the finger landed")


func test_a_tap_with_a_gap_in_reach_bridges_exactly_that_gap() -> void:
	var i := _first_gap_from(0)
	var gap: Dictionary = _run.obstacles()[i]
	_step_to(gap.time - 0.5)
	check(_run.is_in_reach(i), "the gap is in reach")
	check_eq(_run.tap_lane(1), i, "the tap lays the hand across it")
	check_eq(_run.lane(), 1, "and moves the light to the lane tapped")
	check(not _run.is_in_reach(i), "it needs no second tap")
	var next := _first_gap_from(i + 1)
	check(not _run.obstacles()[next].bridged, "the next gap is still open")
	_step_to(gap.time - 0.3)
	check(gap.node.get_node("Hand").visible, "the hand is seen across the gap")
	_step_to(gap.time + 0.1)
	check_eq(gap.status, _run.Status.PASSED, "the light runs over the hand, no stumble")


func test_every_gap_can_be_bridged_at_the_edge_of_its_reach() -> void:
	var gaps := 0
	for i in _run.obstacles().size():
		var obstacle: Dictionary = _run.obstacles()[i]
		if obstacle.kind != RunPlan.Kind.GAP:
			continue
		gaps += 1
		_step_to(obstacle.time - RunPlan.reach(obstacle.part) + 0.01)
		check(_run.is_in_reach(i), "gap %d in reach as its window opens" % i)
		check_eq(_run.tap_lane(_run.lane()), i, "gap %d bridged" % i)
	check_eq(gaps, 12, "every gap")
	_step_to(166.0)
	for obstacle in _run.obstacles():
		if obstacle.kind == RunPlan.Kind.GAP:
			check_eq(obstacle.status, _run.Status.PASSED, "the light crossed every gap on the hand")


func test_the_lane_tapped_counts_even_while_the_hand_is_still_moving_it() -> void:
	var first: Dictionary = _run.obstacles()[0]  # A stone in the middle lane.
	_step_to(first.time - 0.05)
	_run.tap_lane(-1)
	_step_to(first.time + 0.05)
	check_eq(first.status, _run.Status.PASSED, "a tap just in time always counts")


func test_a_stumble_never_changes_the_lights_speed_position_or_lane_and_it_recovers() -> void:
	var first: Dictionary = _run.obstacles()[0]
	_step_to(first.time - 0.05)
	var before: float = _run.light_distance()
	_step_to(first.time + 0.05)
	check_eq(first.status, _run.Status.STUMBLED, "the light went through it")
	check_near(_run.light_distance() - before, RunPlan.SPEED * 0.1, 0.05, "no slower through the stumble")
	check_eq(_run.light_distance(), RunPlan.distance(_run.time()), "where an unstumbled light would be")
	check_eq(_run.lane(), 0, "still in its lane")
	check(_run.light_brightness() < 1.0, "the light flickers dimmer")
	_step_to(first.time + 1.0)
	check_eq(_run.light_brightness(), 1.0, "and is fully back within a second")
	check(not _run.has_ended(), "a stumble never ends the run")


func test_the_light_starts_as_small_as_a_seed_and_grows() -> void:
	_step_to(7.0)
	check(RunPlan.light_size(_run.time()) < 0.25, "as small as a sesame seed as it fades up")
	_step_to(45.0)
	var half: float = RunPlan.light_size(_run.time())
	check(half > 0.25 and half < 1.0, "growing through the euphoria")
	_step_to(RunPlan.CONFUSION_START)
	check_eq(RunPlan.light_size(_run.time()), 1.0, "grown by the end of it")


func test_after_the_song_taps_still_move_the_light_until_the_hand_holds_it() -> void:
	_step_to(170.0)
	check_eq(_run.part(), RunPlan.Part.FADE, "the obstacles have stopped")
	_run.tap_lane(1)
	check_eq(_run.lane(), 1, "a tap still does what it says")
	_step_to(RunPlan.SLOW_START + 0.1)
	check(_run.is_held(), "from 2:55 the hand has come for it")
	check_eq(_run.lane(), 0, "the light drifts back to the middle")
	var before := _snapshot()
	for k in 5:
		check_eq(_run.tap_lane(-1, Vector2(100, 100)), -1, "nothing to bridge")
	check_eq(_snapshot(), before, "the taps change nothing")
	check_eq(_run.ripple_count(), 5, "each tap only ripples")


func test_the_light_slows_settles_into_the_hand_and_goes_out_there() -> void:
	_step_to(RunPlan.SLOW_START - 1.0)
	check_eq(_run.light_brightness(), 1.0, "fully bright as it runs on in the rain")
	var a: float = _run.light_distance()
	_step_to(RunPlan.SLOW_START)
	check_near(_run.light_distance() - a, RunPlan.SPEED, 0.01, "still at full speed at 2:54")
	_step_to(RunPlan.STOPPED)
	var stopped: float = _run.light_distance()
	check(_run._hand.visible, "the hand is there as it stops")
	var under: Vector3 = _run._light.global_position - _run._hand.global_position
	check(under.length() < 0.6 and under.y > 0.0, "the light rests in the open hand, just above the palm")
	_step_to(RunPlan.STOPPED + 5.0)
	check_eq(_run.light_distance(), stopped, "stopped by 3:05")
	check(_run.light_brightness() < 1.0 and _run.light_brightness() > 0.0, "going out")
	_step_to(RunPlan.OUT + 0.5)
	check_eq(_run.light_brightness(), 0.0, "out by 3:15")
	check(not _run._light.visible, "nothing left of it")
	check(_run._hand.visible, "the empty hand stays")
	check(not _run.has_ended(), "until 3:25")


func test_the_rain_never_stops_and_nothing_gets_lighter_after_the_panic() -> void:
	_step_to(RunPlan.RAIN_START - 1.0)
	check(not _run._rain.emitting, "dry before 1:50")
	var sky_before: float = _run._env.background_color.get_luminance()
	_step_to(RunPlan.PANIC_START + 0.5)
	var last := INF
	var last_sun := INF
	while _run.time() < RunPlan.BLACK - 0.2:
		check(_run._rain.emitting and _run._heavy_rain.emitting, "raining at %.0f s" % _run.time())
		var sky: float = _run._env.background_color.get_luminance()
		check(sky <= last + 0.0001, "no lighter at %.0f s" % _run.time())
		check(_run._sun.light_energy <= last_sun + 0.0001, "the sun no brighter at %.0f s" % _run.time())
		last = sky
		last_sun = _run._sun.light_energy
		_step_to(_run.time() + 5.0)
	check(_run._rain.emitting, "still raining at the black")
	check(last < sky_before, "the end is darker than the confusion")


func test_the_euphoria_is_low_gold_sun_between_dark_trees() -> void:
	_step_to(40.0)
	var sky: Color = _run._env.background_color
	check(sky.s > 0.3 and sky.h < 0.15, "a warm gold sky")
	check(_run._sun.shadow_enabled, "the sun throws the trunks' shadows")
	check(_run._sun.light_energy > 4.0 * _run._env.ambient_light_energy, "strong sun, low fill: contrast")
	check(_run._slots.size() > 20, "trees all along the trail")
	for slot in _run._slots:
		for k in 2:
			var tree: Node3D = _run._slots[slot][k]
			var across: float = (tree.global_position - _run._path_at((slot + 0.5) * _run.SLOT)).length()
			check(across > 3.0, "slot %d's trees stand clear of the trail" % slot)


func test_the_trees_bend_in_the_storm() -> void:
	_step_to(60.0)
	var tree: Node3D = _run._slots.values()[-1][0]
	check_eq(tree.transform, tree.get_meta("base"), "still in the euphoria")
	_step_to(150.0)
	tree = _run._slots.values()[-1][0]
	check(not tree.transform.is_equal_approx(tree.get_meta("base")), "bending in the panic")


func test_hiding_the_tab_pauses_the_run_and_saves_nothing() -> void:
	var state := get_node("/root/GameState")
	state.start_new()
	_step_to(30.0)
	_run.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(_run.is_paused(), "paused when the window is hidden")
	_run.advance(5.0)
	check_near(_run.time(), 30.0, STEP, "the clock stopped")
	check(not state.has_save(), "nothing saved")
	var lane: int = _run.lane()
	check_eq(_run.tap_lane(lane + 1, Vector2(640, 360)), -1, "the tap that resumes bridges nothing")
	check_eq(_run.lane(), lane, "and moves nothing")
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
	for t in [10.0, 100.0, 150.0, 170.0, 190.0, 204.0]:
		_step_to(t)
		_assert_no_words_or_buttons(_chapter)


func test_the_path_is_three_lanes_and_gives_way_only_behind_the_light() -> void:
	for t in [60.0, 110.0, 150.0]:
		_step_to(t)
		check_eq(_tiles_in(_row_at(_run.light_distance() + 12.0)), 3, "three lanes ahead at %.0f s" % t)
	for row in _run._rows:
		for tile in _run._rows[row]:
			if tile != null and tile.get_meta("fall") != INF:
				var falls_at := RunPlan.distance(tile.get_meta("fall"))
				check(falls_at > (row + 1) * _run.TILE - 0.01, "row %d falls only once the light is past it" % row)
	_step_to(166.0)
	var row := _row_at(_run.light_distance() + 10.0)
	check_eq(_tiles_in(row), 3, "whole once the obstacles stop")
	for tile in _run._rows[row]:
		check_eq(tile.get_meta("fall"), INF, "nothing falls after 2:45")


# --- Helpers.

func _step_to(t: float) -> void:
	while _run.time() < t - 0.0001 and not _run.has_ended() and not _run.is_paused():
		_run.advance(minf(STEP, t - _run.time()))


# Plays the whole run on a fresh chapter: a perfect player, who moves the
# light to a lane free of whatever comes in the next second and bridges each
# gap as soon as it is in reach, or one who never taps.
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
			var safe := _safe_lane(run)
			var gap := false
			for i in run.obstacles().size():
				gap = gap or run.is_in_reach(i)
			if safe != run.lane() or gap:
				run.tap_lane(safe)
		if not out.has("brightness_at_fade") and run.time() >= RunPlan.FADE_START:
			out.brightness_at_fade = run.light_brightness()
			out.distance_at_fade = run.light_distance()
		if not out.has("lane_when_held") and run.time() >= RunPlan.SLOW_START + 1.0:
			out.lane_when_held = run.lane()
		if out.out_at < 0.0 and run.time() > RunPlan.STOPPED and run.light_brightness() == 0.0:
			out.out_at = run.time()
	out.passed = run.count(run.Status.PASSED)
	out.stumbled = run.count(run.Status.STUMBLED)
	chapter.free()
	return out


# The lane free of every stone and branch arriving in the next second,
# staying put if it can.
func _safe_lane(run: Node) -> int:
	var free: Array[int] = []
	free.assign(RunPlan.LANES)
	for obstacle in run.obstacles():
		if obstacle.status == run.Status.PENDING and obstacle.kind != RunPlan.Kind.GAP \
				and obstacle.time - run.time() < 1.0:
			var left := free.filter(func(lane: int) -> bool: return not lane in obstacle.lanes)
			if left.is_empty():
				break
			free.assign(left)
	return run.lane() if run.lane() in free else free[0]


func _spec(obstacle: Dictionary) -> String:
	if obstacle.kind == RunPlan.Kind.GAP:
		return "G"
	var out: String = "SBG"[obstacle.kind] + ":"
	for lane: int in obstacle.lanes:
		out += "LMR"[lane + 1]
	return out


func _snapshot() -> Dictionary:
	var statuses := []
	for obstacle in _run.obstacles():
		statuses.append([obstacle.status, obstacle.bridged])
	return {
		"statuses": statuses,
		"distance": _run.light_distance(),
		"brightness": _run.light_brightness(),
		"lane": _run.lane(),
		"time": _run.time(),
	}


func _first_gap_from(start: int) -> int:
	for i in range(start, _run.obstacles().size()):
		if _run.obstacles()[i].kind == RunPlan.Kind.GAP:
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


# The web build stutters the first time it draws a new kind of thing, so
# one of everything is drawn behind the black first, and obstacles share
# their shapes (Dan saw blips, 2026-10-25).
func test_everything_is_drawn_once_behind_the_black_before_the_light() -> void:
	check(_run._warm != null, "drawn at the start")
	check(_run._sun.light_energy > 0.0 and _run._lamp.light_energy > 0.0, "lit, behind the black")
	check_eq(_run._overlay.color.a, 1.0, "the screen is still black")
	_step_to(RunPlan.EUPHORIA_START)
	check(_run._warm == null, "gone before the light fades up")
	var stones: Array[Mesh] = []
	for obstacle: Dictionary in _run._obstacles:
		if obstacle.kind == RunPlan.Kind.STONE and obstacle.node:
			for child in obstacle.node.get_children():
				if child is MeshInstance3D:
					stones.append(child.mesh)
	_step_to(40.0)
	for obstacle: Dictionary in _run._obstacles:
		if obstacle.kind == RunPlan.Kind.STONE and obstacle.node:
			for child in obstacle.node.get_children():
				if child is MeshInstance3D:
					stones.append(child.mesh)
	check(stones.size() >= 2, "stones to compare (%d)" % stones.size())
	for mesh in stones:
		check(mesh == _run._stone_mesh, "every stone shares one shape")



# Call 18: fireflies between the trees in the euphoria, fewer in the storm;
# when the path empties the last ones go out one by one, in a fixed order
# that looks random, and some are still glowing when the light goes out.
func test_the_fireflies_go_out_at_random_once_the_path_is_empty() -> void:
	_step_to(40.0)
	check(_slot_fireflies_visible() >= 20, "fireflies between the trees in the euphoria (%d)" % _slot_fireflies_visible())
	var euphoria := _slot_fireflies_visible()
	_step_to(RunPlan.PANIC_START + 12.0)
	check(_slot_fireflies_visible() < euphoria / 3, "few left in the storm")
	_step_to(RunPlan.FADE_START - 0.1)
	var all := RunPlan.LAST_FIREFLIES.size()
	check_eq(_run.fireflies_glowing(), all, "every last one glowing until the path is empty")
	_step_to(RunPlan.FADE_START + 0.5)
	check_eq(_slot_fireflies_visible(), 0, "only the last ones are left")
	var gaps: Array[float] = []
	var last := RunPlan.FADE_START
	var never := 0
	for firefly: Array in RunPlan.LAST_FIREFLIES:
		if firefly[3] < 0.0:
			never += 1
			continue
		check(firefly[3] >= RunPlan.FADE_START, "none goes out before the path is empty")
		check(firefly[3] + RunPlan.FIREFLY_OUT_TIME <= RunPlan.OUT, "each goes out before the light is out")
		gaps.append(firefly[3] - last)
		last = firefly[3]
	check(never >= 2, "some never go out")
	gaps.sort()
	check(gaps[-1] > 3.0 * gaps[0], "no rhythm: uneven gaps between them")
	_step_to(RunPlan.STOPPED + 5.0)
	var glowing: int = _run.fireflies_glowing()
	check(glowing >= never and glowing < all, "some gone, some still glowing as the light goes out")
	var near := false
	for firefly: Node3D in _run._last_fireflies:
		if firefly.visible and firefly.global_position.distance_to(_run._light.global_position) < 8.0:
			near = true
	check(near, "one still glowing near the hand as the light goes out")
	_step_to(RunPlan.OUT + 1.0)
	check_eq(_run.fireflies_glowing(), never, "the ones that never go out outlast the light")


func _slot_fireflies_visible() -> int:
	var n := 0
	for slot in _run._slots:
		var nodes: Array = _run._slots[slot]
		for k in range(3, nodes.size()):
			if nodes[k].visible:
				n += 1
	return n
