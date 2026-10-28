extends TestCase
## The chapter runner (DAS-75): enter a chapter from the House, play it, come
## back with its one result. The M0 menu stands in for the House.

const MENU := preload("res://scenes/ui/m0_menu.tscn")
const STAND_IN := preload("res://scenes/chapters/stand_in/stand_in_chapter.tscn")

var _finished: Array[Dictionary] = []
var _left: Array[StringName] = []


func after_each() -> void:
	# The runner lives on the root, so it would outlast this test.
	ChapterRunner.of(get_tree()).free()


func _runner() -> ChapterRunner:
	var runner := ChapterRunner.of(get_tree())
	runner.chapter_finished.connect(func(result: Dictionary) -> void: _finished.append(result))
	runner.chapter_left.connect(func(id: StringName) -> void: _left.append(id))
	return runner


func _house() -> Control:
	var house := Control.new()
	house.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(house)
	return house


func _chapter(runner: ChapterRunner) -> Control:
	return runner.get_child(0) as Control


# --- The result

func test_a_result_is_the_chapter_and_its_answer() -> void:
	check_eq(ChapterResult.make(&"partner"), {"chapter": "partner", "answer": ""}, "no answer")
	check_eq(ChapterResult.make(&"novice", ChapterResult.STOIC),
			{"chapter": "novice", "answer": "stoic"}, "with an answer")
	check_eq(ChapterResult.make(&"mourner", ChapterResult.VULNERABLE, {"shelf": ["photo"]}),
			{"chapter": "mourner", "answer": "vulnerable", "house": {"shelf": ["photo"]}},
			"with something for the House")


func test_a_result_survives_saving_as_json() -> void:
	var result := ChapterResult.make(&"tuner", ChapterResult.VULNERABLE)
	check_eq(JSON.parse_string(JSON.stringify(result)), result, "same after JSON")
	# Floats, since JSON brings every number back as a float.
	var with_house := ChapterResult.make(&"mourner", ChapterResult.STOIC,
			{"shelf": ["photo", {"x": 1.5, "kept": true, "note": null}], "boxes": 3.0})
	check(ChapterResult.is_story_result(with_house), "nested House counts")
	check_eq(JSON.parse_string(JSON.stringify(with_house)), with_house, "nested House same after JSON")


func test_a_house_value_that_json_would_change_doesnt_count() -> void:
	var bad := {
		"a Vector2": {"shelf": Vector2(1, 2)},
		"a Vector2 in a list": {"shelf": [1, Vector2(1, 2)]},
		"a number key": {1: "photo"},
		"a StringName key": {&"shelf": "photo"},
		"a deep Vector2": {"room": {"shelf": {"at": Vector2i(1, 2)}}},
		"an infinite number": {"x": INF},
	}
	for what in bad:
		var result := {"chapter": "mourner", "answer": "", "house": bad[what]}
		check(not ChapterResult.is_story_result(result), "%s doesn't count" % what)
	var node := Node.new()
	check(not ChapterResult.is_story_result({"chapter": "mourner", "answer": "", "house": {"n": node}}),
			"a Node doesn't count")
	node.free()


func test_only_real_chapter_results_count_as_story() -> void:
	for id in ChapterList.STORY_ORDER:
		check(ChapterResult.is_story_result(ChapterResult.make(id)), "%s counts" % id)
	check(not ChapterResult.is_story_result(ChapterResult.make(ChapterList.STAND_IN)),
			"the stand-in doesn't count")
	check(not ChapterResult.is_story_result({"chapter": "partner", "answer": "brave"}),
			"an unknown answer doesn't count")
	check(not ChapterResult.is_story_result({"chapter": "partner"}), "a missing answer doesn't count")
	check(not ChapterResult.is_story_result({"chapter": "partner", "answer": "", "mood": "warm"}),
			"extra story facts don't count")
	check(not ChapterResult.is_story_result({"chapter": "partner", "answer": "", "house": "x"}),
			"a House value that isn't a dictionary doesn't count")


func test_story_order_has_all_eight_chapters() -> void:
	check_eq(ChapterList.STORY_ORDER, [&"partner", &"protector", &"novice", &"provider",
			&"tuner", &"anchor", &"mourner", &"arrival"], "story order")


# --- Entering and coming back

func test_entering_hides_and_pauses_the_house() -> void:
	var runner := _runner()
	var house := _house()
	check(runner.enter(ChapterList.STAND_IN, house), "entered")
	check(runner.is_running(), "running")
	check_eq(runner.current_chapter(), ChapterList.STAND_IN, "current chapter")
	check(not house.visible, "House hidden")
	check_eq(house.process_mode, Node.PROCESS_MODE_DISABLED, "House paused")
	check(_chapter(runner) != null and _chapter(runner).is_visible_in_tree(), "chapter on screen")


func test_finishing_brings_the_house_back_with_the_result() -> void:
	var runner := _runner()
	var house := _house()
	house.process_mode = Node.PROCESS_MODE_ALWAYS
	runner.enter(ChapterList.STAND_IN, house)
	await frames()
	var chapter := _chapter(runner)
	tap(chapter.get_node("%FinishButton"))
	await frames()
	check_eq(_finished, [{"chapter": "stand_in", "answer": ""}], "one result")
	check(_left.is_empty(), "not counted as leaving")
	check(house.visible, "House shown again")
	check_eq(house.process_mode, Node.PROCESS_MODE_ALWAYS, "House's own process mode back")
	check(not runner.is_running(), "nothing running")
	check(not is_instance_valid(chapter), "chapter freed")


func test_the_answer_comes_back_in_the_result() -> void:
	var runner := _runner()
	runner.enter(ChapterList.STAND_IN, _house())
	await frames()
	tap(_chapter(runner).get_node("%VulnerableButton"))
	await frames()
	check_eq(_finished, [{"chapter": "stand_in", "answer": "vulnerable"}], "vulnerable")
	runner.enter(ChapterList.STAND_IN, _house())
	await frames()
	tap(_chapter(runner).get_node("%StoicButton"))
	await frames()
	check_eq(_finished.back(), {"chapter": "stand_in", "answer": "stoic"}, "stoic")


func test_the_house_is_already_back_when_the_result_arrives() -> void:
	var runner := ChapterRunner.of(get_tree())
	var house := _house()
	var seen := {}
	runner.chapter_finished.connect(func(_result: Dictionary) -> void:
		seen["house_visible"] = house.visible
		seen["running"] = runner.is_running())
	runner.enter(ChapterList.STAND_IN, house)
	await frames()
	tap(_chapter(runner).get_node("%FinishButton"))
	check_eq(seen, {"house_visible": true, "running": false}, "state when the result arrives")


func test_leaving_without_finishing_gives_no_result() -> void:
	var runner := _runner()
	var house := _house()
	runner.enter(ChapterList.STAND_IN, house)
	await frames()
	tap(_chapter(runner).get_node("%LeaveButton"))
	await frames()
	check(_finished.is_empty(), "no result")
	check_eq(_left, [ChapterList.STAND_IN], "left the stand-in")
	check(house.visible, "House shown again")
	check(not runner.is_running(), "nothing running")


func test_a_chapter_that_finishes_twice_gives_one_result() -> void:
	var runner := _runner()
	runner.enter(ChapterList.STAND_IN, _house())
	var chapter := _chapter(runner)
	chapter.finished.emit("")
	chapter.finished.emit("stoic")
	await frames()
	check_eq(_finished.size(), 1, "one result")
	check(_left.is_empty(), "freeing after finishing isn't leaving")


func test_a_finished_chapter_on_its_way_out_cant_report_for_the_next() -> void:
	var runner := _runner()
	runner.enter(ChapterList.STAND_IN, _house())
	var first := _chapter(runner)
	first.finished.emit("")
	# The next chapter starts before the first is gone.
	runner.enter(ChapterList.STAND_IN, _house())
	await frames()
	check(runner.is_running(), "second chapter still running")
	check(_left.is_empty(), "the first leaving isn't reported as the second leaving")


# A chapter that only emits `finished` with no answer, like the Partner.
func test_a_chapter_with_a_plain_finished_signal_works() -> void:
	var scene := PackedScene.new()
	var chapter := Control.new()
	chapter.set_script(_plain_chapter_script())
	scene.pack(chapter)
	chapter.free()
	var runner := _runner()
	check(runner.enter_scene(&"partner", scene, _house()), "entered")
	_chapter(runner).finished.emit()
	await frames()
	check_eq(_finished, [{"chapter": "partner", "answer": ""}], "result")
	check(ChapterResult.is_story_result(_finished[0]), "counts as a story result")


# A chapter that emits the wrong thing is a bug in that chapter, so it is
# reported, but the player still gets the House back and the story goes on.
func test_a_chapter_that_emits_the_wrong_thing_still_brings_the_house_back() -> void:
	var cases := {
		"a non-String answer": [true],
		"too many arguments": ["stoic", {}, "extra"],
		"a House that isn't a dictionary": ["stoic", "x"],
		"a House that isn't plain JSON": ["vulnerable", {"at": Vector2(1, 2)}],
	}
	expect_error("unknown answer")
	expect_error("at most 2")
	expect_error("isn't plain JSON")
	var runner := _runner()
	for what in cases:
		var house := _house()
		house.process_mode = Node.PROCESS_MODE_ALWAYS
		runner.enter(ChapterList.STAND_IN, house)
		var chapter := _chapter(runner)
		chapter.finished.emit.callv(cases[what])
		await frames()
		check(house.visible, "%s: House shown again" % what)
		check_eq(house.process_mode, Node.PROCESS_MODE_ALWAYS, "%s: House process mode back" % what)
		check(not runner.is_running(), "%s: nothing running" % what)
		check(not is_instance_valid(chapter), "%s: chapter freed" % what)
	check_eq(_finished, [
		{"chapter": "stand_in", "answer": ""},
		{"chapter": "stand_in", "answer": "stoic"},
		{"chapter": "stand_in", "answer": "stoic"},
		{"chapter": "stand_in", "answer": "vulnerable"},
	], "one result each, falling back to no answer and no House")
	check(_left.is_empty(), "none counted as leaving")


func test_only_one_chapter_plays_at_a_time() -> void:
	var runner := _runner()
	var house := _house()
	runner.enter(ChapterList.STAND_IN, house)
	var first := _chapter(runner)
	var other := _house()
	check(not runner.enter(ChapterList.STAND_IN, other), "second enter refused")
	check_eq(runner.get_child_count(), 1, "one chapter on screen")
	check_eq(_chapter(runner), first, "still the first chapter")
	check(other.visible, "the second caller isn't hidden")
	await frames()
	tap(first.get_node("%FinishButton"))
	await frames()
	check(house.visible, "the first House comes back")
	check_eq(_finished.size(), 1, "one result")


# The menu asks for the runner in its _ready. As the main scene that happens
# while the root is still setting up, which only the browser tests can recreate
# (they caught "Parent node is busy"); this checks the runner still joins.
func test_the_house_can_ask_for_the_runner_while_the_root_adds_it() -> void:
	var script := GDScript.new()
	script.source_code = "extends Node\nfunc _ready():\n\tChapterRunner.of(get_tree())\n"
	script.reload()
	var house := Node.new()
	house.set_script(script)
	get_tree().root.add_child(house)
	await frames()
	var runner := ChapterRunner.of(get_tree())
	check_eq(runner.get_parent(), get_tree().root, "runner joined the root")
	house.free()


# --- From the menu, as a player

func test_menu_starts_the_stand_in_and_shows_its_result() -> void:
	var menu := add_scene(MENU)
	tap(menu.get_node("%BeginButton"))
	await frames()
	tap(menu.get_node("%StandInButton"))
	await frames()
	var runner := ChapterRunner.of(get_tree())
	check(runner.is_running(), "chapter started")
	check(not menu.visible, "menu hidden while the chapter plays")
	tap(_chapter(runner).get_node("%StoicButton"))
	await frames()
	check(menu.visible, "menu back")
	check(menu.get_node("%Menu").visible, "menu buttons back")
	check_eq(menu.get_node("%Status").text, "Finished stand_in (answer: stoic)", "status")


func test_menu_says_when_the_chapter_was_left() -> void:
	var menu := add_scene(MENU)
	tap(menu.get_node("%BeginButton"))
	await frames()
	tap(menu.get_node("%StandInButton"))
	await frames()
	tap(_chapter(ChapterRunner.of(get_tree())).get_node("%LeaveButton"))
	await frames()
	check(menu.visible, "menu back")
	check_eq(menu.get_node("%Status").text, "Left stand_in without finishing", "status")


func test_stand_in_buttons_are_big_enough_on_a_phone() -> void:
	for screen in [Vector2i(390, 844), Vector2i(844, 390), Vector2i(1280, 720)]:
		set_screen(screen)
		var runner := _runner()
		runner.enter(ChapterList.STAND_IN, _house())
		await frames(2)
		var view := get_viewport().get_visible_rect()
		for name in ["FinishButton", "StoicButton", "VulnerableButton", "LeaveButton"]:
			var button: Control = _chapter(runner).get_node("%" + name)
			var rect := button.get_global_rect()
			check(rect.size.x >= 44.0 and rect.size.y >= 44.0,
					"%s at least 44px on %s (is %s)" % [name, screen, rect.size])
			check(view.encloses(rect), "%s on screen on %s" % [name, screen])
		runner.free()
		_finished.clear()


# --- Playtests

# Every rough chapter gives the playtest overlay its clock (CLAUDE.md,
# "Rough chapters"), so Dan can say when in it something happened.
func test_every_chapter_has_a_playtest_clock() -> void:
	for id: StringName in ChapterList.SCENES:
		if not ChapterList.is_story_chapter(id):
			continue
		var chapter: Node = load(ChapterList.scene_path(id)).instantiate()
		check(chapter.has_method("playtest_time"), "%s has playtest_time()" % id)
		chapter.free()


func _plain_chapter_script() -> GDScript:
	var script := GDScript.new()
	script.source_code = "extends Control\nsignal finished\n"
	script.reload()
	return script
