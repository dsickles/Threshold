extends TestCase
## The Protector's run (DAS-97), on the run's own clock instead of real time.
## The rules come from docs/design/the-loss-run-and-car.md, "Checks this
## design must pass" (revised after each of Dan's plays, calls 13 to 20). Feel,
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
	_run.real_clock = _run.time  # No real time passes here.


func test_the_obstacle_list_matches_the_design() -> void:
	var list := RunPlan.obstacles()
	check_eq(list.size(), 31, "obstacles in the run")
	var by_part := {}
	for obstacle in list:
		by_part[obstacle.part] = by_part.get(obstacle.part, 0) + 1
	check_eq(by_part.get(RunPlan.Part.EUPHORIA, 0), 9, "in the euphoria")
	check_eq(by_part.get(RunPlan.Part.CONFUSION, 0), 10, "in the confusion")
	check_eq(by_part.get(RunPlan.Part.PANIC, 0), 12, "in the panic")
	check_eq(by_part.get(RunPlan.Part.FADE, 0), 0, "none as the light goes out")
	check_eq(by_part.get(RunPlan.Part.DARK, 0), 0, "in the dark")
	check_near(list[-1].time, 125.0, 0.001, "the last one (2:05)")
	for i in range(1, list.size()):
		check(list[i].time > list[i - 1].time, "obstacle %d comes after the one before" % i)
	# The euphoria's land on the song's beat: every 2 bars at 90 BPM from 0:11.
	var design := [11, 16, 22, 27, 32, 38, 43, 48, 54]
	for k in 9:
		check_near(list[k].time, 11.0 + k * 16.0 / 3.0, 0.001, "euphoria obstacle %d on the beat" % k)
		check_near(list[k].time, design[k], 0.5, "euphoria obstacle %d at the design's time" % k)
	check_eq(list[8].time < 55.0, true, "0:54 to 1:03 is clear")
	# Each one's shape and lanes, in order, as the design lists them.
	var specs := ""
	for obstacle in list:
		specs += _spec(obstacle) + " "
	check_eq(specs.strip_edges(), " ".join([
		"S:M S:LR B:LM S:R G B:MR S:L G B:LM",
		"S:LM G B:MR S:L S:R B:LM G S:MR B:LM G",
		"S:L S:R B:LM S:M G G S:R S:M B:MR B:LM G S:R",
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
			check(RunPlan.reach(obstacle.part) >= 1.0, "gap %d can be bridged, with at least 1 s" % i)
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
		if i > start:
			check(list[i].time - list[i - 1].time >= 2.0, "time to move before the cluster at %.1f s" % list[i].time)
		while j < list.size() and (j == i or list[j].time - list[j - 1].time < 0.9):
			free = free.filter(func(lane: int) -> bool: return not lane in list[j].lanes \
					or list[j].kind == RunPlan.Kind.GAP)
			j += 1
		check(not free.is_empty(), "the cluster at %.1f s has a lane free all through" % list[i].time)
		clusters += 1
		i = j
	check_eq(clusters, 6, "six panic clusters, the last a single stone")
	# Outside a cluster, at least 2 s before an obstacle that needs a new lane.
	for k in range(1, start):
		check(list[k].time - list[k - 1].time >= 2.0, "time to move before obstacle %d" % k)


func test_the_obstacle_sequence_is_fixed_not_random() -> void:
	check_eq(RunPlan.obstacles(), RunPlan.obstacles(), "the same list every time")
	var other: Node = add_scene(PROTECTOR).run()
	other.auto_advance = false
	other.real_clock = other.time  # No real time passes here.
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


func test_the_music_starts_at_three_seconds_and_the_storm_plays_to_the_black() -> void:
	_step_to(2.9)
	check(not _run._music.playing, "silent in the dark")
	_step_to(3.1)
	check(_run._music.playing, "the song from 0:03")
	_step_to(RunPlan.FADE_START + 1.0)
	check(_run._music.playing, "the storm goes on after the song is gone (no dead stop)")
	_step_to(RunPlan.BLACK - 0.5)
	check(_run._music.playing, "still playing as it goes black")
	check(_run.MUSIC.get_length() >= RunPlan.BLACK - RunPlan.EUPHORIA_START - 0.1,
			"the track runs from 0:03 to 2:40")
	check(_run.MUSIC.get_length() < RunPlan.BLACK - RunPlan.EUPHORIA_START + 5.0,
			"and not on long past it")


func test_a_perfect_run_and_an_empty_run_reach_the_same_ending() -> void:
	var perfect := _play(true)
	var empty := _play(false)
	check_eq(perfect.passed, 31, "the perfect run gets past every obstacle")
	check_eq(perfect.stumbled, 0, "and never stumbles")
	var in_the_middle := 0
	for obstacle in RunPlan.obstacles():
		if 0 in obstacle.lanes:
			in_the_middle += 1
	check_eq(empty.stumbled, in_the_middle, "the empty run stumbles on everything in the middle lane")
	check_eq(empty.passed, 31 - in_the_middle, "and only gets past what isn't")
	check_eq(perfect.brightness_at_fade, 1.0, "the light is fully bright at 2:08 after a perfect run")
	check_eq(empty.brightness_at_fade, perfect.brightness_at_fade, "and exactly as bright after an empty one")
	check_eq(empty.distance_at_fade, perfect.distance_at_fade, "the light is as far along at 2:08")
	check_eq(empty.distance_stopped, perfect.distance_stopped, "and stops at the fallen tree in the same place")
	check_eq(empty.stumbled_at_fade, empty.stumbled, "the tree is no stumble, after an empty run")
	check_eq(perfect.stumbled_at_fade, 0, "or a perfect one")
	check_eq(empty.lane_when_held, perfect.lane_when_held, "and in the same lane once the hand holds it")
	check_near(perfect.out_at, RunPlan.OUT, STEP, "the perfect run's light goes out at 2:30")
	check_eq(empty.out_at, perfect.out_at, "the empty run's at the same moment")
	check_near(perfect.finished_at, RunPlan.BLACK, STEP, "the perfect run finishes at 2:40")
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
	check_eq(_run.tap_lane(0, Vector2(640, 360)), false, "nothing moved")
	check_eq(_snapshot(), before, "nothing changed: it was already in that lane")
	check_eq(_run.ripple_count(), 1, "a small ripple where the finger landed")


func test_a_hold_with_a_gap_in_reach_lays_the_hand_across_exactly_that_gap() -> void:
	var i := _first_gap_from(0)
	var gap: Dictionary = _run.obstacles()[i]
	_step_to(gap.time - 0.6)
	check(_run.is_in_reach(i), "the gap is in reach")
	var lane: int = _run.lane()
	_run.press(Vector2(900, 360))
	_step_to(gap.time - 0.5)
	check(not gap.bridged, "not yet: a press this short could still be a tap")
	_step_to(gap.time - 0.35)
	check(_run.is_holding(), "held: a hold")
	check(gap.bridged, "the hold lays the hand across it")
	check_eq(_run.lane(), lane, "and never moves the light a lane, on either side of the screen")
	var next := _first_gap_from(i + 1)
	check(not _run.obstacles()[next].bridged, "the next gap is still open")
	check(gap.node.get_node("Hand").visible, "the hand is seen across the gap")
	_step_to(gap.time + 0.1)
	_run.release(Vector2(900, 360))
	check_eq(gap.status, _run.Status.PASSED, "the light runs over the hand, no stumble")
	check_eq(_run.lane(), lane, "letting go of a hold moves nothing")


func test_a_tap_with_a_gap_in_reach_only_moves_the_lane() -> void:
	var i := _first_gap_from(0)
	var gap: Dictionary = _run.obstacles()[i]
	_step_to(gap.time - 0.6)
	var size: Vector2 = _run.get_viewport().get_visible_rect().size
	tap_at(Vector2(size.x - 4, size.y / 2.0))
	check_eq(_run.lane(), 1, "the tap moves the light")
	check(not gap.bridged, "and doesn't cross the gap: that takes a hold")
	_step_to(gap.time + 0.1)
	check_eq(gap.status, _run.Status.STUMBLED, "so the light stumbles over it")


func test_a_quick_press_moves_the_lane_when_the_finger_lifts() -> void:
	_step_to(8.0)
	var size: Vector2 = _run.get_viewport().get_visible_rect().size
	_run.press(Vector2(size.x - 4, 10))
	check_eq(_run.lane(), 0, "nothing moves while the finger is down")
	_step_to(8.0 + _run.HOLD_START - STEP)
	_run.release(Vector2(size.x - 4, 10))
	check_eq(_run.lane(), 1, "lifted in time: a tap, one lane right")
	_run.press(Vector2(4, 10))
	_step_to(9.0)
	_run.release(Vector2(4, 10))
	check_eq(_run.lane(), 1, "held: no lane move")
	check_eq(_run.ripple_count(), 1, "a hold with nothing to cross only ripples")


func test_a_quick_tap_on_a_slow_frame_still_moves_the_lane() -> void:
	# The phone can draw a frame longer than HOLD_START; how long the finger
	# is really down decides, not how far the run moved (Hopper, 2026-10-27).
	_step_to(8.0)
	var now := [100.0]
	_run.real_clock = func() -> float: return now[0]
	var size: Vector2 = _run.get_viewport().get_visible_rect().size
	_run.press(Vector2(size.x - 4, 10))
	_run.advance(0.3)
	now[0] += 0.05
	_run.release(Vector2(size.x - 4, 10))
	check_eq(_run.lane(), 1, "a 50 ms tap across a 0.3 s frame is still a tap")
	_run.press(Vector2(4, 10))
	now[0] += _run.HOLD_START
	_run.advance(STEP)
	check(_run.is_holding(), "really held for HOLD_START: a hold")
	_run.release(Vector2(4, 10))
	check_eq(_run.lane(), 1, "and the hold didn't move the lane")
	# Lifted after HOLD_START with no frame in between: still a hold.
	_run.press(Vector2(4, 10))
	now[0] += 0.25
	_run.release(Vector2(4, 10))
	check_eq(_run.lane(), 1, "a 0.25 s hold inside one slow frame doesn't move the lane")


func test_a_quick_tap_heard_after_a_slow_frame_is_still_a_tap() -> void:
	# On the web Godot hears of the finger lifting only at the next frame, so
	# the browser's own times for the touch decide (CI's phone run, 2026-10-27).
	_step_to(8.0)
	var now := [100.0]
	var up := [100.05]
	_run.real_clock = func() -> float: return now[0]
	_run.down_clock = func() -> float: return 100.0
	_run.up_clock = func() -> float: return up[0]
	var size: Vector2 = _run.get_viewport().get_visible_rect().size
	_run.press(Vector2(4, 10))
	now[0] = 100.9  # A slow frame; the finger lifted 50 ms after it went down.
	_run.advance(STEP)  # A frame comes before Godot hears of the lift.
	check(not _run.is_holding(), "already lifted in the browser: not a hold")
	_run.release(Vector2(4, 10))
	check_eq(_run.lane(), -1, "a 50 ms tap heard 0.9 s late is a tap")
	_run.down_clock = func() -> float: return 200.0
	up[0] = 200.25
	now[0] = 200.0
	_run.press(Vector2(size.x - 4, 10))
	_run.advance(STEP)
	now[0] = 200.9
	_run.release(Vector2(size.x - 4, 10))
	check_eq(_run.lane(), -1, "a 0.25 s hold heard late is still a hold")
	# A press the browser didn't note keeps the last press's time: not a hold
	# straight away (Hopper, 2026-10-27).
	now[0] = 300.0
	_run.up_clock = func() -> float: return now[0]
	_run.press(Vector2(size.x - 4, 10))
	_run.advance(STEP)
	check(not _run.is_holding(), "a stale browser time doesn't make a fresh press a hold")
	now[0] = 300.04
	_run.release(Vector2(size.x - 4, 10))
	check_eq(_run.lane(), 0, "it is a tap: one lane right")
	# A click just after a touch: the browser keeps the touch's old lift, which
	# is before this press. Held 0.3 s, it is still a hold (Hopper, 2026-10-27).
	_run.up_clock = func() -> float: return 300.04
	now[0] = 400.0
	_run.press(Vector2(4, 10))
	now[0] = 400.3
	_run.advance(STEP)
	check(_run.is_holding(), "an old lift doesn't stop a fresh press becoming a hold")
	_run.release(Vector2(4, 10))
	check_eq(_run.lane(), 0, "letting go of a hold doesn't move the lane")
	# A tap whose touch went down and up at the same browser time, heard a slow
	# frame later, is still a tap (CI's browser run on bb93c57).
	_run.down_clock = func() -> float: return 500.0
	_run.up_clock = func() -> float: return 500.0
	now[0] = 500.0
	_run.press(Vector2(size.x - 4, 10))
	now[0] = 500.9
	_run.advance(STEP)
	check(not _run.is_holding(), "a lift at the same moment as the press is not a hold")
	_run.release(Vector2(size.x - 4, 10))
	check_eq(_run.lane(), 1, "it is a tap: one lane right")
	# The lift reaches the page only after a slow frame took the press for a
	# hold: the browser's times still say tap (CI's phone runs, 2026-10-27).
	var lifted := [500.0]  # The last lift the page has heard of.
	_run.down_clock = func() -> float: return 600.0
	_run.up_clock = func() -> float: return lifted[0] if lifted[0] >= 600.0 else now[0]
	now[0] = 600.0
	_run.press(Vector2(4, 10))
	now[0] = 603.0
	_run.advance(STEP)
	check(_run.is_holding(), "a slow frame before the lift arrives takes it for a hold")
	lifted[0] = 600.0001
	_run.release(Vector2(4, 10))
	check(not _run.is_holding(), "the hand comes off")
	check_eq(_run.lane(), 0, "and the tap moves the lane: one lane left")


func test_at_the_fade_falling_tiles_carry_on_and_no_row_is_rebuilt() -> void:
	# At 2:45 the path is whole again, but nothing snaps back and nothing is
	# built again all at once (Hopper, 2026-10-27).
	_step_to(RunPlan.FADE_START - 0.05)
	var falling: MeshInstance3D = null
	var before := {}
	for row: int in _run._rows:
		before[row] = _run._rows[row].duplicate()
		for tile: Variant in _run._rows[row]:
			if tile != null and falling == null and _run.time() > float(tile.get_meta("fall")) + 0.1 \
					and tile.visible:
				falling = tile
	if not check(falling != null, "a panic tile is falling just before 2:45"):
		return
	var y := falling.position.y
	_run.advance(0.1)
	check(is_instance_valid(falling) and falling.position.y < y, "and it is still falling after 2:45")
	for row: int in before:
		if _run._rows.has(row):
			check_eq(_run._rows[row], before[row], "row %d is kept, not built again" % row)


func test_letting_go_before_the_gap_lifts_the_hand_and_the_light_stumbles() -> void:
	var i := _first_gap_from(0)
	var gap: Dictionary = _run.obstacles()[i]
	_step_to(gap.time - 0.8)
	_run.press(Vector2(640, 360))
	_step_to(gap.time - 0.4)
	check(gap.bridged, "the hand is across it")
	_run.release(Vector2(640, 360))
	check(not gap.bridged, "let go too soon: the hand lifts")
	check(gap.node.get_node("Hand").visible, "seen lifting away")
	_step_to(gap.time + 0.1)
	check_eq(gap.status, _run.Status.STUMBLED, "the light stumbles over the open gap")


func test_a_hold_from_before_the_gap_is_in_reach_lays_the_hand_when_it_is() -> void:
	var i := _first_gap_from(0)
	var gap: Dictionary = _run.obstacles()[i]
	var opens: float = gap.time - RunPlan.reach(gap.part)
	_step_to(opens - 1.0)
	_run.press(Vector2(640, 360))
	_step_to(opens - 0.2)
	check(_run.is_holding() and not gap.bridged, "held, but nothing in reach yet")
	_step_to(opens + 0.05)
	check(gap.bridged, "the hand goes down as soon as the gap is in reach")
	_step_to(gap.time + 0.1)
	_run.release(Vector2(640, 360))
	check_eq(gap.status, _run.Status.PASSED, "and the light crosses")


func test_every_gap_can_be_bridged_at_the_edge_of_its_reach() -> void:
	var gaps := 0
	for i in _run.obstacles().size():
		var obstacle: Dictionary = _run.obstacles()[i]
		if obstacle.kind != RunPlan.Kind.GAP:
			continue
		gaps += 1
		# A hold that starts as the window opens: down at the edge, held.
		var opens: float = obstacle.time - RunPlan.reach(obstacle.part)
		_step_to(opens - _run.HOLD_START + 0.01)
		_run.press(Vector2(640, 360))
		_step_to(opens + 0.11)
		check(obstacle.bridged, "gap %d bridged by a hold that starts as it comes into reach" % i)
		_step_to(obstacle.time + 0.05)
		_run.release(Vector2(640, 360))
	check_eq(gaps, 8, "every gap")
	_step_to(RunPlan.FADE_START + 1.0)
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
	_step_to(RunPlan.FADE_START + 5.0)
	check_eq(_run.part(), RunPlan.Part.FADE, "the obstacles have stopped")
	_run.tap_lane(1)
	check_eq(_run.lane(), 1, "a tap still does what it says")
	_step_to(RunPlan.SLOW_START + 0.1)
	check(_run.is_held(), "from 2:15 the hand is coming for it")
	check_eq(_run.lane(), 0, "the light drifts back to the middle")
	var before := _snapshot()
	for k in 5:
		check_eq(_run.tap_lane(-1, Vector2(100, 100)), false, "nothing moves")
	check_eq(_snapshot(), before, "the taps change nothing")
	check_eq(_run.ripple_count(), 5, "each tap only ripples")


func test_the_light_stops_at_the_tree_settles_into_the_hand_and_goes_out_there() -> void:
	_step_to(RunPlan.SLOW_START - 1.0)
	check_eq(_run.light_brightness(), 1.0, "fully bright as it runs on in the rain")
	var a: float = _run.light_distance()
	_step_to(RunPlan.SLOW_START)
	check_near(_run.light_distance() - a, RunPlan.SPEED, 0.01, "still at full speed at 2:14")
	_step_to(RunPlan.STOPPED)
	var stopped: float = _run.light_distance()
	check(not _run._hand.visible or _run._hand.global_position.y < _run._light.global_position.y - 0.5,
			"the hand only comes once it has stopped")
	_step_to(RunPlan.HELD)
	check(_run._hand.visible, "the hand has come under it")
	var under: Vector3 = _run._light.global_position - _run._hand.global_position
	check(under.length() < 0.6 and under.y > 0.0, "the light rests in the open hand, just above the palm")
	check_eq(_run.light_brightness(), 1.0, "still fully bright as the hand takes it")
	_step_to(RunPlan.HELD + 5.0)
	check_eq(_run.light_distance(), stopped, "stopped by 2:17")
	check(_run.light_brightness() < 1.0 and _run.light_brightness() > 0.0, "going out")
	_step_to(RunPlan.OUT + 0.5)
	check_eq(_run.light_brightness(), 0.0, "out by 2:30")
	check(not _run._light.visible, "nothing left of it")
	check(_run._hand.visible, "the empty hand stays")
	check(not _run.has_ended(), "until 2:40")


# Call 20: after the obstacles, a whole tree across the path that nothing
# gets past. It stops the light gently and is no obstacle to clear.
func test_the_light_stops_against_a_fallen_tree_it_cannot_get_past() -> void:
	var tree: Node3D = _run._tree
	check(not (tree in _run.obstacles().map(func(o: Dictionary) -> Variant: return o.node)), "not one of the obstacles")
	check_eq(RunPlan.part_at(RunPlan.STOPPED), RunPlan.Part.FADE, "it comes after the obstacles stop")
	# 12 s after the last one since Dan cut 5 s of the straight run (2026-10-30).
	check(RunPlan.STOPPED - RunPlan.obstacles()[-1].time >= 11.9, "well after the last one")
	check(_run.TREE_LENGTH > 3.0 * _run.TILE + 6.0, "wider than the path, out past both edges")
	check(2.0 * _run.TREE_RADIUS - 0.1 > _run.LIGHT_HEIGHT + _run.LIGHT_RADIUS, "taller than the light")
	_step_to(RunPlan.FADE_START + 1.0)
	var stumbled: int = _run.count(_run.Status.STUMBLED)
	_step_to(RunPlan.STOPPED - 8.0)
	check(tree.visible, "seen coming, ahead in the fog")
	_step_to(RunPlan.STOPPED)
	var front: float = _run.tree_distance() - _run.TREE_RADIUS
	var reach: float = _run.light_distance() + _run.LIGHT_RADIUS
	# A little short of it, not right against it (Dan, 2026-10-30).
	check(absf(front - reach - _run.TREE_GAP) < 0.25, "the light stops just short of it")
	check_eq(_run.light_brightness(), 1.0, "no flicker: it isn't hurt")
	check(_run._last_stumble < RunPlan.FADE_START, "no thud and no stumble since the obstacles stopped")
	check_eq(_run.count(_run.Status.STUMBLED), stumbled, "and it isn't a stumble")
	_step_to(RunPlan.BLACK - 1.0)
	check_eq(_run.light_distance(), RunPlan.distance(RunPlan.STOPPED), "it never gets past")
	for node in _all(tree):
		if node is GeometryInstance3D:
			check((node as GeometryInstance3D).material_override in [_run._trunk_material,
					_run._canopy_material, _run._branch_material], "nothing lights it up: %s" % node.name)


func test_the_hints_say_tap_here_at_the_start_and_hold_for_the_first_two_gaps() -> void:
	_step_to(1.0)
	check_eq(_run.hints_shown(), [], "nothing in the dark")
	_step_to(RunPlan.EUPHORIA_START + 2.0)
	check_eq(_run.hints_shown(), ["tap here", "tap here"], "tap here, on the left and the right")
	var size: Vector2 = _run.get_viewport().get_visible_rect().size
	var left: Label = _run._tap_hints[0]
	var right: Label = _run._tap_hints[1]
	check(left.get_global_rect().get_center().x < size.x / 2.0, "one on the left half")
	check(right.get_global_rect().get_center().x > size.x / 2.0, "one on the right half")
	check_eq(left.mouse_filter, Control.MOUSE_FILTER_IGNORE, "and they take no taps")
	var second: Dictionary = _run.obstacles()[1]
	_step_to(second.time)
	check_eq(_run.hints_shown(), ["tap here", "tap here"], "until the second stone has passed")
	_step_to(second.time + 1.0)
	check_eq(_run.hints_shown(), [], "then gone")
	var gaps := 0
	for i in _run.obstacles().size():
		var gap: Dictionary = _run.obstacles()[i]
		if gap.kind != RunPlan.Kind.GAP:
			continue
		gaps += 1
		var opens: float = gap.time - RunPlan.reach(gap.part)
		_step_to(opens - 2.0)
		check_eq(_run.hints_shown(), [], "no hint long before gap %d" % gaps)
		_step_to(opens - 0.3)
		check_eq(_run.hints_shown(), ["hold"] if gaps <= 2 else [], "hold, just before gap %d is in reach" % gaps)
		_step_to(gap.time)
		check_eq(_run.hints_shown(), ["hold"] if gaps <= 2 else [], "and until it reaches the light")
		_step_to(gap.time + 1.0)
		check_eq(_run.hints_shown(), [], "then gone")
		if gaps == 3:
			break
	check_eq(gaps, 3, "the first two gaps had it, the third didn't")


func test_the_rain_never_stops_and_nothing_gets_lighter_after_the_panic() -> void:
	_step_to(RunPlan.RAIN_START - 1.0)
	check(not _run._rain.emitting, "dry before 1:23")
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
	_step_to(RunPlan.PANIC_START + 15.0)
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
	_run.press(Vector2(1200, 360))
	_run.release(Vector2(1200, 360))
	check_eq(_run.lane(), lane, "the tap that resumes moves nothing")
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
	run.real_clock = run.time  # No real time passes here.
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
	run.real_clock = run.time  # No real time passes here.
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
	run.real_clock = run.time  # No real time passes here.
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
	for t in [10.0, 30.0, 80.0, 115.0, 135.0, 150.0, 164.0]:
		_step_to(t)
		_assert_no_words_or_buttons(_chapter)


func test_the_path_is_three_lanes_and_gives_way_only_behind_the_light() -> void:
	for t in [50.0, 88.0, 115.0]:
		_step_to(t)
		check_eq(_tiles_in(_row_at(_run.light_distance() + 12.0)), 3, "three lanes ahead at %.0f s" % t)
	for row in _run._rows:
		for tile in _run._rows[row]:
			if tile != null and tile.get_meta("fall") != INF:
				var falls_at := RunPlan.distance(tile.get_meta("fall"))
				check(falls_at > (row + 1) * _run.TILE - 0.01, "row %d falls only once the light is past it" % row)
	_step_to(RunPlan.FADE_START + 1.0)
	var row := _row_at(_run.light_distance() + 10.0)
	check_eq(_tiles_in(row), 3, "whole once the obstacles stop")
	for tile in _run._rows[row]:
		check_eq(tile.get_meta("fall"), INF, "nothing falls after 2:08")


# --- Helpers.

func _step_to(t: float) -> void:
	while _run.time() < t - 0.0001 and not _run.has_ended() and not _run.is_paused():
		_run.advance(minf(STEP, t - _run.time()))


# Plays the whole run on a fresh chapter: a perfect player, who moves the
# light to a lane free of whatever comes in the next second and holds a
# finger down across each gap, or one who never taps.
func _play(perfect: bool) -> Dictionary:
	var chapter: Node = add_scene(PROTECTOR)
	var run: Node = chapter.run()
	run.auto_advance = false
	run.real_clock = run.time  # No real time passes here.
	var out := {"finishes": 0, "finished_at": -1.0, "out_at": -1.0}
	chapter.finished.connect(func() -> void:
		out.finishes += 1
		out.finished_at = run.time())
	for k in ceili((RunPlan.BLACK + 2.0) / STEP):
		run.advance(STEP)
		if perfect:
			# One finger, like a player: it lifts to tap a lane, and holds
			# from just before a gap until the light is on the hand.
			var safe := _safe_lane(run)
			var gap_soon := false
			for obstacle in run.obstacles():
				if obstacle.kind == RunPlan.Kind.GAP and obstacle.status == run.Status.PENDING \
						and obstacle.time - run.time() < 1.2:
					gap_soon = true
			var down: bool = run._press_at >= 0.0
			# A finger on a gap the light hasn't reached stays down; the lane
			# can wait until the light is across.
			var crossing := false
			for obstacle in run.obstacles():
				if obstacle.kind == RunPlan.Kind.GAP and obstacle.status == run.Status.PENDING \
						and obstacle.bridged:
					crossing = true
			if down and crossing:
				pass
			elif safe != run.lane():
				if down:
					run.release(Vector2(640, 360))
				run.tap_lane(safe)
			elif gap_soon and not down:
				run.press(Vector2(640, 360))
			elif not gap_soon and down:
				run.release(Vector2(640, 360))
		if not out.has("brightness_at_fade") and run.time() >= RunPlan.FADE_START:
			out.brightness_at_fade = run.light_brightness()
			out.distance_at_fade = run.light_distance()
		if not out.has("stumbled_at_fade") and run.time() >= RunPlan.FADE_START:
			out.stumbled_at_fade = run.count(run.Status.STUMBLED)
		if not out.has("lane_when_held") and run.time() >= RunPlan.SLOW_START + 1.0:
			out.lane_when_held = run.lane()
		if not out.has("distance_stopped") and run.time() >= RunPlan.STOPPED:
			out.distance_stopped = run.light_distance()
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


# Nothing to read or press, but the two hints when they show (call 20).
func _assert_no_words_or_buttons(root: Node) -> void:
	for node in _all(root):
		if node is Label and node.name.begins_with("Hint") and node.text in [RunPlan.TAP_HINT, RunPlan.HOLD_HINT]:
			check(not node.visible or node.text in RunPlan.hints(_run.time()).map(
					func(h: Array) -> String: return h[0]), "a hint only when it's due: %s" % node.text)
			continue
		check(not node is Label and not node is RichTextLabel and not node is BaseButton
				and not node is Label3D, "nothing to read or press: %s" % node.get_path())


# The web build stutters the first time it draws a new kind of thing, so
# one of everything is drawn behind the black first, and obstacles share
# their shapes (Dan saw blips, 2026-10-25).
func test_everything_is_drawn_once_behind_the_black_before_the_light() -> void:
	check(_run._warm != null, "drawn at the start")
	check(_run._sun.light_energy > 0.0 and _run._lamp.light_energy > 0.0, "lit, behind the black")
	check_eq(_run._overlay.color.a, 1.0, "the screen is still black")
	# The light's glow reaches everything drawn there, so nothing it lights
	# (the hand above all) is first got ready mid-run, with a hitch.
	_run.advance(STEP)
	var lamp: OmniLight3D = _run._lamp
	for node in _all(_run._warm):
		if node is MeshInstance3D:
			check(lamp.global_position.distance_to((node as Node3D).global_position) < lamp.omni_range - 1.0,
					"in the light's reach: %s" % node.name)
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
	_step_to(RunPlan.HELD + 2.0)
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


# Call 21: the empty space of a gap reads even in the dark, the branches
# leave their free lane plainly empty, and the first rain is faint.
func test_a_gap_s_edges_show_through_the_dark_before_it_is_in_reach() -> void:
	var i := -1
	for k in _run.obstacles().size():
		if _run.obstacles()[k].kind == RunPlan.Kind.GAP and _run.obstacles()[k].part == RunPlan.Part.PANIC:
			i = k
			break
	var gap: Dictionary = _run.obstacles()[i]
	_step_to(gap.time - _run.GAP_SEEN - 0.2)
	var outline: Node3D = gap.node.get_node("Outline")
	check(not outline.visible, "nothing before it comes close")
	var line: StandardMaterial3D = outline.get_meta("material")
	check(line.disable_fog, "the fog doesn't hide its edges")
	_step_to(gap.time - _run.GAP_SEEN + 0.5)
	check(outline.visible, "its edges show faintly well before it is in reach")
	check(line.albedo_color.a > 0.2 and line.albedo_color.a < 0.5, "faint: %.2f" % line.albedo_color.a)
	_step_to(gap.time - RunPlan.reach(gap.part) + 0.2)
	check_eq(line.albedo_color.a, 1.0, "bright once it is in reach")


func test_a_branch_leaves_its_free_lane_plainly_empty() -> void:
	var mesh: CylinderMesh = _run._branch_mesh(2)
	# From the middle of its two lanes, it reaches just past the second one's middle.
	var reach := mesh.height / 2.0
	check(reach >= _run.TILE / 2.0 + _run.LIGHT_RADIUS - 0.001, "it still covers the light in both its lanes")
	check(reach < _run.TILE / 2.0 + 0.4, "and ends just past its second lane's middle")


func test_the_first_rain_is_faint_and_thickens() -> void:
	_step_to(RunPlan.RAIN_START + 0.5)
	var drops: StandardMaterial3D = _run._rain.mesh.material
	var first := drops.albedo_color.a
	check(first < 0.25, "the first drops are faint (%.2f)" % first)
	_step_to(RunPlan.RAIN_START + 12.0)
	check(drops.albedo_color.a > 2.0 * first, "and thicken as the rain is heard")
	# The pre-mixed track's rain starts where the drops do (Hopper, 2026-10-27).
	var script_path := ProjectSettings.globalize_path("res://").path_join("../tools/protector/make_audio.py")
	var mix := FileAccess.get_file_as_string(script_path)
	check(mix.contains("RAIN_SEEN = %.1f" % RunPlan.RAIN_START), "make_audio.py's RAIN_SEEN is RunPlan.RAIN_START")
	# And its ending is the run's (Hopper, 2026-10-30): the track was rebuilt
	# when Dan cut 5 s, so a later change can't leave it behind.
	for pair: Array in [["FADE", RunPlan.FADE_START], ["HELD", RunPlan.HELD], ["OUT_AT", RunPlan.OUT],
			["BLACK", RunPlan.BLACK]]:
		check(mix.contains("\n%s = %.1f" % pair), "make_audio.py's %s is %.1f, as in run_plan.gd" % pair)


# Dan, 2026-10-30, after playing the asset-pack forest on his phone: "lots of
# pop in" and "it stuttered a fair amount".
func test_the_forest_fades_in_and_is_light_on_a_phone() -> void:
	for mesh: Mesh in _run._tree_meshes + _run._dead_tree_meshes + _run._patches:
		for i in mesh.get_surface_count():
			var mat: BaseMaterial3D = mesh.surface_get_material(i)
			check_eq(mat.distance_fade_mode, BaseMaterial3D.DISTANCE_FADE_OBJECT_DITHER,
					"%s fades in, not all at once" % mat.resource_name)
			check(mat.distance_fade_min_distance > mat.distance_fade_max_distance,
					"%s: from nothing far off to whole nearer" % mat.resource_name)
	check(_run._ground_material.albedo_texture != null, "the forest floor is textured, not a flat colour")
	for mesh: Mesh in _run._patches:
		check_eq(mesh.get_surface_count(), 3, "a patch of undergrowth is three draws: leaves, grass, rock")
	# The run's changes stay in the run: the pack's own pine is untouched.
	var pine: Node = load(_run.MODELS + "Pine_1.gltf").instantiate()
	var own: BaseMaterial3D = (pine.find_children("*", "MeshInstance3D")[0] as MeshInstance3D).mesh.surface_get_material(0)
	check_eq(own.distance_fade_mode, BaseMaterial3D.DISTANCE_FADE_DISABLED, "the pack's pine doesn't fade")
	check(own.albedo_color.is_equal_approx(Color.WHITE), "and keeps its own colour")
	pine.free()
	var bark_seen := 0
	for mesh: Mesh in _run._tree_meshes + _run._dead_tree_meshes:
		for i in mesh.get_surface_count():
			var mat: BaseMaterial3D = mesh.surface_get_material(i)
			if mat.resource_name.contains("Bark"):
				bark_seen += 1
				check_eq(mat.transparency, BaseMaterial3D.TRANSPARENCY_DISABLED, "%s is solid" % mat.resource_name)
	check_eq(bark_seen, 6, "every tree's bark was checked")
	# An iPhone has 3 pixels to each point; a laptop 1 or 2.
	check_near(_run.scale_for(3.0), 2.0 / 3.0, 0.001, "3 pixels a point: the 3D is drawn at 2")
	check_eq(_run.scale_for(2.0), 1.0, "2 pixels a point: drawn at all of them")
	check_eq(_run.scale_for(1.0), 1.0, "1 pixel a point: drawn at all of them")
	var viewport := _run.get_viewport()
	check_near(viewport.scaling_3d_scale, _run.scale_for(DisplayServer.screen_get_scale()), 0.001, "set for this screen")
	var before: float = _run._scale_before
	viewport.scaling_3d_scale = 0.5  # As if this were a phone.
	_chapter.queue_free()
	await frames(2)
	check_eq(viewport.scaling_3d_scale, before, "and put back once the run is left")
