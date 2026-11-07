extends TestCase
## The Novice (DAS-133), on the chapter's own clock instead of real time.
## The rules come from the ticket and docs/design/stories/epic-3-stories.md.
## Feel, and whether the three phases read, are Dan's to check on his phone.

const NOVICE := preload("res://scenes/chapters/novice/novice.tscn")
const NovicePlan := preload("res://scenes/chapters/novice/novice_plan.gd")
const MENU := preload("res://scenes/ui/m0_menu.tscn")
const GAME_STATE := preload("res://_core/state_manager/game_state.gd")
const SAVE_PATH := "user://test_saves/novice_save.json"
const STEP := 1.0 / 20.0

var _chapter: Node
var _finished: Array = []


func before_each() -> void:
	_chapter = add_scene(NOVICE)
	_chapter.auto_advance = false
	_chapter.finished.connect(func(answer: String) -> void: _finished.append(answer))


# --- Helpers.

func _state() -> Dictionary:
	return _chapter.probe_state()


func _run(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		_chapter.advance(minf(STEP, left))
		left -= STEP


# Runs until `ready` is true, or gives up after `limit` seconds.
func _run_until(ready: Callable, limit: float = 600.0) -> bool:
	var spent := 0.0
	while not ready.call():
		if spent > limit:
			return false
		_chapter.advance(STEP)
		spent += STEP
	return true


func _to_choice() -> void:
	_run_until(func() -> bool: return _state().beat == "CHOICE")


func _to_games(answer: String = ChapterResult.STOIC) -> void:
	_to_choice()
	_chapter.choose(answer)
	_run_until(func() -> bool: return _state().beat == "GAMES")


func _to_play() -> void:
	_run_until(func() -> bool: return _state().stage == "PLAY")


# Plays the round on screen as well as a player could: the box tapped until
# it opens, the powder let go in its band, the needle tapped over the target,
# allowing for the numb months' lag. Retries a tap that didn't take.
func _play_round_well() -> void:
	_to_play()
	var number: int = _state().round
	var r := NovicePlan.round_at(number)
	var held := false
	var pressed_at := -1.0
	while _state().round == number and _state().stage == "PLAY":
		var t: float = _chapter._stage_t
		match r.game:
			NovicePlan.Game.BOX:
				_chapter.press()
				_chapter.release()
			NovicePlan.Game.POWDER:
				var band: Vector2 = r.band
				var aim := (band.x + band.y) / 2.0
				if not held and not _chapter._holding and _chapter._pending.is_empty():
					_chapter.press()
					held = true
					pressed_at = t
				elif held and _chapter._holding and _chapter._level + r.rise * r.lag >= aim:
					_chapter.release()
					held = false
				elif held and not _chapter._holding and t - pressed_at > r.lag + 0.2:
					held = false  # That press didn't take: press again.
			NovicePlan.Game.INJECT:
				if _chapter._pending.is_empty() and absf(sin((t + r.lag) * r.sway)) <= r.target * 0.5:
					_chapter.press()
					_chapter.release()
		_chapter.advance(STEP)


# --- The start.

func test_it_starts_slow_quiet_and_gray_with_no_shout_yet() -> void:
	var s := _state()
	check_eq(s.beat, "QUIET", "starts in the quiet kitchen")
	check_eq(s.shout, "", "no shout at the start")
	check_eq(s.subtitle, "", "nothing said at first")
	check_eq(s.saturation, 0.0, "gray")
	check(not _chapter.get_node("Choices").visible, "no buttons to press")
	_run(2.9)
	check_eq(_state().beat, "QUIET", "still quiet nearly 3 s in: no warning")
	_run(0.2)
	check(_state().subtitle.begins_with("Maya:"), "then Maya speaks")
	check_eq(_state().shout, "", "still no shout while she asks")
	check_eq(_state().saturation, 0.0, "still gray")


func test_no_compositor_effects_and_nothing_explains_the_joke() -> void:
	var source: String = load("res://scenes/chapters/novice/novice.gd").source_code
	check(not source.contains("Compositor" + "Effect"), "no CompositorEffects in the chapter")
	check(_find(_chapter, "WorldEnvironment") == null, "no WorldEnvironment either")
	# The only words are the subtitles, Leo's two lines and the shouts; the
	# calendar shows a number only.
	_to_games()
	_run_until(func() -> bool: return _state().beat == "RESULT")
	for label: Label in _labels(_chapter):
		check(label.text == "" or label.name in ["Subtitle", "Shout"], "no other words: %s" % label.text)


func _find(node: Node, type: String) -> Node:
	if node.is_class(type):
		return node
	for child in node.get_children():
		var found := _find(child, type)
		if found:
			return found
	return null


func _labels(node: Node) -> Array[Label]:
	var out: Array[Label] = []
	if node is Label:
		out.append(node)
	for child in node.get_children():
		if not child is Button:
			out.append_array(_labels(child))
	return out


# --- The Injection.

func test_the_injection_offers_one_choice_and_both_lead_to_the_same_shot() -> void:
	var rounds := {}
	for answer in [ChapterResult.STOIC, ChapterResult.VULNERABLE]:
		_chapter.free()
		_finished.clear()
		before_each()
		_to_choice()
		var stoic: Button = _chapter.get_node("Choices/StoicButton")
		var vulnerable: Button = _chapter.get_node("Choices/VulnerableButton")
		await frames()
		check(stoic.is_visible_in_tree() and vulnerable.is_visible_in_tree(), "two answers on screen")
		tap(stoic if answer == ChapterResult.STOIC else vulnerable)
		check_eq(_state().beat, "REPLY", "%s: the tap chose" % answer)
		check(_state().subtitle.begins_with("Leo:"), "%s: Leo says his line" % answer)
		check(not _chapter.get_node("Choices").visible, "%s: the answers go" % answer)
		_run_until(func() -> bool: return _state().beat == "GAMES")
		_to_play()
		check_eq(_state().game, "INJECT", "%s: the first game is the shot" % answer)
		check_eq(_state().phase, "NUMB", "%s: slow and gentle" % answer)
		var order: Array[String] = []
		while _state().beat == "GAMES":
			var g: String = _state().game
			if order.is_empty() or order.size() <= _state().round:
				order.append(g)
			_chapter.advance(STEP)
		rounds[answer] = order
		_run_until(func() -> bool: return _state().canGoBack)
		_chapter.press()
		check_eq(_finished, [answer], "%s: finishes with that answer" % answer)
	check_eq(rounds[ChapterResult.STOIC], rounds[ChapterResult.VULNERABLE], "the same rest of the chapter")


func test_a_tap_moves_a_line_on_but_not_straight_away() -> void:
	_run(3.1)
	var first: String = _state().subtitle
	_chapter.press()
	check_eq(_state().subtitle, first, "a tap the moment it shows doesn't skip it")
	_run(0.6)
	_chapter.press()
	check(_state().subtitle != first, "a tap after that moves on")


# --- The micro-games.

func test_the_three_micro_games_can_each_be_finished_and_dont_faint_is_not_in() -> void:
	var games := {}
	for i in NovicePlan.count():
		games[NovicePlan.round_at(i).game] = true
	check_eq(games.size(), 3, "three micro-games")
	check_eq(NovicePlan.SHOUTS.values(), ["OPEN THE BOX!", "MIX THE POWDER!", "INJECT THE BUTT!"], "their shouts")
	check_eq(NovicePlan.Game.keys(), ["BOX", "POWDER", "INJECT"], "DON'T FAINT! is not a game here")
	_to_games()
	var won := {}
	while _state().beat == "GAMES":
		var number: int = _state().round
		_play_round_well()
		var results: Array = _state().results
		if results.size() > number and results[number] == "won":
			won[NovicePlan.round_at(number).game] = true
		_run_until(func() -> bool: return _state().round != number or _state().beat != "GAMES")
	check_eq(won.size(), 3, "each game won at least once")


func test_each_game_is_one_gesture_and_its_shout_leaves_when_done() -> void:
	_to_games()
	for number in 3:
		_to_play()
		var r := NovicePlan.round_at(number)
		check_eq(_state().shout, NovicePlan.SHOUTS[r.game], "round %d shouts its game" % number)
		_play_round_well()
		check_eq(_state().results[number], "won", "round %d won" % number)
		check_eq(_state().shout, "", "round %d: the shout leaves when it is done" % number)
		_run_until(func() -> bool: return _state().round != number)


func test_the_box_opens_with_taps_only() -> void:
	_to_games()
	_run_until(func() -> bool: return _state().round == 1 and _state().stage == "PLAY")
	check_eq(_state().game, "BOX", "the box")
	_chapter.press()
	_chapter.release()
	_run(0.4)  # The numb months' lag.
	check_eq(_state().results.size(), 2, "one tap opens it when numb")
	check_eq(_state().results[1], "won", "opened")


func test_the_powder_needs_a_hold_let_go_in_the_band() -> void:
	_to_games()
	_run_until(func() -> bool: return _state().round == 2 and _state().stage == "PLAY")
	check_eq(_state().game, "POWDER", "the powder")
	var r := NovicePlan.round_at(2)
	# A quick tap doesn't mix it.
	_chapter.press()
	_chapter.release()
	_run(1.0)
	check_eq(_state().results.size(), 2, "a tap doesn't finish it")
	check(_chapter._level < r.band.x, "and doesn't mix it enough")
	# Held too long it spills, and has to start again.
	_chapter.press()
	_run(1.0 / r.rise + 1.0)
	_chapter.release()
	_run(0.5)
	check_eq(_state().results.size(), 2, "spilled, not mixed")
	check_eq(_chapter._level, 0.0, "starts again")
	# Held into the band and let go: mixed.
	_chapter.press()
	_run(r.lag + (r.band.x + r.band.y) / 2.0 / r.rise - r.lag)
	_chapter.release()
	_run(r.lag + 0.1)
	check_eq(_state().results[2], "won", "let go in the band")


func test_the_needle_only_goes_in_over_the_target() -> void:
	_to_games()
	_to_play()
	var r := NovicePlan.round_at(0)
	# Wait until the needle is far off the target, allowing for the lag.
	_run_until(func() -> bool: return absf(sin((_chapter._stage_t + r.lag) * r.sway)) > 0.9)
	_chapter.press()
	_chapter.release()
	_run(r.lag + 0.05)
	check(_state().results.is_empty(), "a tap off the target doesn't go in")
	_play_round_well()
	check_eq(_state().results, ["won"], "a tap over it does")


# --- The six months.

func test_three_phases_numb_then_frantic_then_exhausted() -> void:
	var phases: Array[int] = []
	for i in NovicePlan.count():
		var phase: int = NovicePlan.round_at(i).phase
		if phases.is_empty() or phases[-1] != phase:
			phases.append(phase)
	check_eq(phases, [NovicePlan.Phase.NUMB, NovicePlan.Phase.FRANTIC, NovicePlan.Phase.EXHAUSTED],
			"numb, frantic, exhausted, in that order")
	var months: Array[int] = []
	for i in NovicePlan.count():
		months.append(NovicePlan.round_at(i).month)
	check_eq(months[0], 3, "from month 3")
	check_eq(months[-1], 9, "to month 9")
	for i in range(1, months.size()):
		check(months[i] >= months[i - 1], "months only go forward (%d)" % i)
	var numb := NovicePlan.TUNING[NovicePlan.Phase.NUMB]
	var frantic := NovicePlan.TUNING[NovicePlan.Phase.FRANTIC]
	check(frantic.limit < numb.limit, "frantic games are timed shorter")
	check(frantic.sway > numb.sway and frantic.rise > numb.rise, "and faster")
	check(frantic.box_taps > numb.box_taps, "and ask for more")
	check(NovicePlan.PHASES[NovicePlan.Phase.NUMB].lag > 0.0, "numb taps lag")
	check_eq(NovicePlan.PHASES[NovicePlan.Phase.FRANTIC].lag, 0.0, "frantic taps don't")
	check(NovicePlan.PHASES[NovicePlan.Phase.EXHAUSTED].drop_every > 0, "exhausted taps sometimes don't take")
	check_eq(NovicePlan.PHASES[NovicePlan.Phase.NUMB].drop_every, 0, "numb ones always do")


func test_numb_taps_lag_and_the_picture_stays_gray() -> void:
	_to_games()
	_run_until(func() -> bool: return _state().round == 1 and _state().stage == "PLAY")
	_chapter.press()
	_chapter.release()
	check_eq(_state().results.size(), 1, "the tap hasn't landed yet")
	_run(NovicePlan.PHASES[NovicePlan.Phase.NUMB].lag + STEP)
	check_eq(_state().results.size(), 2, "it lands a moment later")
	check_near(_state().saturation, 0.0, 0.001, "numb months are gray")


func test_frantic_months_are_in_colour_with_a_short_time_limit() -> void:
	_to_games()
	_run_until(func() -> bool: return _state().phase == "FRANTIC" and _state().stage == "PLAY")
	var start: float = _state().time
	var number: int = _state().round
	_run_until(func() -> bool: return _state().round != number)
	check(_state().time - start < NovicePlan.TUNING[NovicePlan.Phase.FRANTIC].limit + 1.5,
			"an untouched frantic game moves on within its limit")
	_run(3.0)
	check(_state().saturation > 0.9, "colour floods in (%.2f)" % _state().saturation)
	# A frantic tap lands straight away.
	_run_until(func() -> bool: return _state().game == "BOX" and _state().stage == "PLAY")
	var taps_before: int = _chapter._taps
	_chapter.press()
	_chapter.release()
	check_eq(_chapter._taps, taps_before + 1, "no lag when frantic")


func test_in_the_exhausted_stretch_some_taps_dont_take() -> void:
	_to_games()
	_run_until(func() -> bool: return _state().phase == "EXHAUSTED" and _state().stage == "PLAY")
	check_eq(_state().game, "BOX", "a box first")
	var landed: Array[int] = []
	for i in 6:
		var before: int = _chapter._taps
		_chapter.press()
		_chapter.release()
		landed.append(_chapter._taps - before)
		if _state().stage != "PLAY":
			break
	check(0 in landed, "a tap that doesn't take: %s" % [landed])
	check(1 in landed, "and taps that do")
	_run(3.0)
	check(_state().saturation < 0.5, "the colour drains again (%.2f)" % _state().saturation)


# --- Fail-forward and the one result.

func test_no_taps_and_every_game_won_reach_the_same_test() -> void:
	# No taps in any game: every one times out and moves on.
	_to_games(ChapterResult.VULNERABLE)
	check(_run_until(func() -> bool: return _state().beat == "RESULT", 400.0), "no taps reaches the test")
	var missed: Array = _state().results
	check_eq(missed.size(), NovicePlan.count(), "every game came up")
	check(not "won" in missed, "none won")
	var long: float = _state().time
	check(long < 240.0, "under 4 minutes even with no taps (%.0f s)" % long)
	_run_until(func() -> bool: return _state().canGoBack)
	_chapter.press()
	_chapter.press()
	check_eq(_finished, [ChapterResult.VULNERABLE], "finished once")
	# Every game won.
	_chapter.free()
	_finished.clear()
	before_each()
	_to_games(ChapterResult.VULNERABLE)
	while _state().beat == "GAMES":
		var number: int = _state().round
		_play_round_well()
		_run_until(func() -> bool: return _state().round != number or _state().beat != "GAMES")
	check_eq(_state().beat, "RESULT", "a perfect run reaches the same test")
	check(not "missed" in _state().results, "every game won (%s)" % [_state().results])
	check(_state().time > 60.0, "and still takes over a minute (%.0f s)" % _state().time)
	_run_until(func() -> bool: return _state().canGoBack)
	_chapter.press()
	_chapter.press()
	check_eq(_finished, [ChapterResult.VULNERABLE], "finished once")


func test_it_ends_on_the_positive_test_and_records_novice_after_the_loss() -> void:
	_to_games()
	_run_until(func() -> bool: return _state().beat == "RESULT")
	check_eq(_state().shout, "", "the shouts are gone at the test")
	_chapter.press()
	check(_finished.is_empty(), "the test holds: an early tap doesn't leave")
	_run(8.0)
	check(_state().canGoBack, "then a tap can go back")
	_chapter.press()
	check_eq(_finished, [ChapterResult.STOIC], "finished with the answer")
	var source: String = load("res://scenes/chapters/novice/novice.gd").source_code
	check(not source.contains("scenes/chapters/partner"), "the Partner isn't replayed")
	# Through the runner, after the Partner and the Loss, it is saved third.
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	SaveFile.new(SAVE_PATH).erase()
	var state: Node = GAME_STATE.new()
	state.use_save_file(SaveFile.new(SAVE_PATH))
	state.load_save()
	add_child(state)
	state.record_chapter_result(ChapterResult.make(&"partner"))
	state.record_chapter_result(ChapterResult.make(&"protector"))
	var runner := ChapterRunner.of(get_tree())
	var house := Control.new()
	add_child(house)
	check(runner.enter(&"novice", house), "the runner starts the Novice")
	var chapter: Node = runner.get_child(0)
	chapter.auto_advance = false
	chapter._answer = ChapterResult.VULNERABLE
	chapter._start_result()
	chapter.advance(8.1)
	chapter.press()
	await frames()
	check_eq(state.finished_chapters(), ["partner", "protector", "novice"] as Array[String],
			"novice recorded after protector")
	check_eq(state.answer_for("novice"), ChapterResult.VULNERABLE, "with its answer")
	state.queue_free()
	runner.free()
	SaveFile.new(SAVE_PATH).erase()


# --- One tap scheme.

func test_real_taps_and_holds_play_it_and_hover_does_nothing() -> void:
	_to_games()
	_run_until(func() -> bool: return _state().round == 1 and _state().stage == "PLAY")
	var hover := InputEventMouseMotion.new()
	hover.position = get_viewport().get_visible_rect().get_center()
	get_viewport().push_input(hover, true)
	_run(1.0)
	check_eq(_state().results.size(), 1, "hovering does nothing")
	tap_at(get_viewport().get_visible_rect().get_center())
	_run(0.5)
	check_eq(_state().results[1], "won", "a real tap opens the box")


func test_the_answer_buttons_are_at_least_44px_and_on_screen() -> void:
	for screen in [Vector2i(390, 844), Vector2i(844, 390), Vector2i(1280, 720)]:
		set_screen(screen)
		_chapter.free()
		before_each()
		_to_choice()
		await frames(2)
		var view := get_viewport().get_visible_rect()
		for name in ["StoicButton", "VulnerableButton"]:
			var rect: Rect2 = _chapter.get_node("Choices/" + name).get_global_rect()
			check(rect.size.x >= 44.0 and rect.size.y >= 44.0, "%s at least 44px on %s (is %s)" % [name, screen, rect.size])
			check(view.encloses(rect), "%s on screen on %s (%s in %s)" % [name, screen, rect, view])


# --- Pausing and leaving.

func test_hiding_the_tab_pauses_until_a_tap_and_never_saves() -> void:
	_to_games()
	_to_play()
	_chapter.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(_state().paused, "paused")
	var time: float = _state().time
	_run(5.0)
	check_eq(_state().time, time, "the clock stops")
	check_eq(_state().results.size(), 0, "the game doesn't time out")
	_chapter.press()
	check(_state().paused, "a press that isn't a tap on screen doesn't count")
	tap_at(get_viewport().get_visible_rect().get_center())
	check(not _state().paused, "a tap brings it back")
	_run(0.5)
	check_eq(_state().results.size(), 0, "and that tap wasn't a move")
	check(not FileAccess.file_exists(SAVE_PATH), "nothing saved")


func test_leaving_part_way_gives_no_result_and_starts_again_next_time() -> void:
	var runner := ChapterRunner.of(get_tree())
	var house := Control.new()
	add_child(house)
	var left: Array = []
	var done: Array = []
	runner.chapter_left.connect(func(id: StringName) -> void: left.append(id))
	runner.chapter_finished.connect(func(result: Dictionary) -> void: done.append(result))
	runner.enter(&"novice", house)
	var chapter: Node = runner.get_child(0)
	chapter.auto_advance = false
	chapter.advance(30.0)
	chapter.queue_free()
	await frames()
	check_eq(left, [&"novice"], "left without finishing")
	check(done.is_empty(), "no result")
	runner.enter(&"novice", house)
	check_eq(runner.get_child(0).probe_state().beat, "QUIET", "the next visit starts from the first beat")
	runner.free()


func test_the_playtest_clock_counts_the_chapter() -> void:
	check_eq(_chapter.playtest_time(), 0.0, "starts at 0")
	_run(4.0)
	check_near(_chapter.playtest_time(), 4.0, 0.01, "counts the chapter's seconds")


func test_the_menu_opens_the_novice_and_takes_it_back() -> void:
	_chapter.free()
	var menu := add_scene(MENU)
	tap(menu.get_node("%BeginButton"))
	await frames()
	var button: Control = menu.get_node("%NoviceButton")
	check(button.size.x >= 44.0 and button.size.y >= 44.0, "Novice button is at least 44px")
	tap(button)
	var runner := ChapterRunner.of(get_tree())
	var chapter: Node = runner.get_child(0) if runner.get_child_count() > 0 else null
	if not check(chapter != null and chapter.scene_file_path == NOVICE.resource_path, "the Novice opened"):
		runner.free()
		return
	check(not menu.visible, "menu hidden while it plays")
	chapter.auto_advance = false
	chapter._answer = ChapterResult.STOIC
	chapter._start_result()
	chapter.advance(8.1)
	chapter.press()
	await frames()
	check(not is_instance_valid(chapter), "closed when finished")
	check(menu.visible, "menu back afterwards")
	check_eq(menu.get_node("%Status").text, "Finished novice (answer: stoic)", "menu heard the result")
	runner.free()
