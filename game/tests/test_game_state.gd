extends TestCase
## Progress and saves (DAS-74, ADR-0007): the finished-chapter list, saved
## only when a chapter finishes, read back on the next visit, and a bad or
## missing save treated as a fresh start.

const GAME_STATE := preload("res://_core/state_manager/game_state.gd")
const SAVE_PATH := "user://test_saves/save.json"
const STAND_IN := preload("res://scenes/chapters/stand_in/stand_in_chapter.tscn")

var _states: Array[Node] = []


## A save file in a browser with no lasting storage (private browsing).
class PrivateBrowsingSaveFile extends SaveFile:
	func storage_lasts() -> bool:
		return false


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	SaveFile.new(SAVE_PATH).erase()


func after_each() -> void:
	for state in _states:
		state.free()
	SaveFile.new(SAVE_PATH).erase()


## A GameState on the test's own save file, as the game would have after
## starting (it reads the save).
func _fresh_state(path: String = SAVE_PATH) -> Node:
	var state: Node = GAME_STATE.new()
	_states.append(state)
	state.use_save_file(SaveFile.new(path))
	state.load_save()
	return state


func _write_raw(text: String) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_game_state_is_an_autoload() -> void:
	check(get_tree().root.has_node("GameState"), "GameState is autoloaded")


func test_a_new_game_has_nothing_finished_and_starts_with_the_partner() -> void:
	var state := _fresh_state()
	check_eq(state.finished_chapters(), [] as Array[String], "finished chapters")
	check_eq(state.next_chapter(), "partner", "next chapter")
	check(not state.has_save(), "no save yet")


func test_finishing_a_chapter_saves_it_and_the_next_visit_reads_it_back() -> void:
	var state := _fresh_state()
	check(state.record_chapter_result({"chapter": "partner", "answer": "vulnerable"}), "recorded")
	check(state.last_save_ok, "save kept")
	check(state.has_save(), "save written")
	var next_visit := _fresh_state()
	check_eq(next_visit.finished_chapters(), ["partner"] as Array[String], "finished after reload")
	check_eq(next_visit.answer_for("partner"), "vulnerable", "answer after reload")
	check_eq(next_visit.next_chapter(), "protector", "next chapter after reload")


func test_chapters_stay_in_the_order_they_were_finished() -> void:
	var state := _fresh_state()
	state.record_chapter_result({"chapter": "partner", "answer": "stoic"})
	state.record_chapter_result({"chapter": "protector", "answer": ""})
	state.record_chapter_result({"chapter": "novice", "answer": "vulnerable"})
	var next_visit := _fresh_state()
	check_eq(next_visit.finished_chapters(), ["partner", "protector", "novice"] as Array[String],
			"order after reload")
	check_eq(next_visit.answer_for("partner"), "stoic", "partner answer")
	check_eq(next_visit.answer_for("protector"), "", "protector has no answer")
	check_eq(next_visit.answer_for("novice"), "vulnerable", "novice answer")


func test_a_chapter_out_of_story_order_is_not_recorded() -> void:
	var state := _fresh_state()
	check(not state.record_chapter_result({"chapter": "protector", "answer": ""}),
			"protector before partner refused")
	check_eq(state.finished_chapters(), [] as Array[String], "nothing finished")
	check(not state.has_save(), "nothing saved")


func test_finishing_a_chapter_again_changes_nothing() -> void:
	var state := _fresh_state()
	state.record_chapter_result({"chapter": "partner", "answer": "stoic"})
	check(not state.record_chapter_result({"chapter": "partner", "answer": "vulnerable"}),
			"second finish not recorded")
	check_eq(state.finished_chapters(), ["partner"] as Array[String], "partner listed once")
	check_eq(state.answer_for("partner"), "stoic", "first answer kept")


func test_an_unknown_answer_is_not_recorded() -> void:
	var state := _fresh_state()
	check(not state.record_chapter_result({"chapter": "partner", "answer": "angry"}), "refused")
	check_eq(state.finished_chapters(), [] as Array[String], "nothing finished")


func test_a_malformed_result_is_not_recorded() -> void:
	var state := _fresh_state()
	for result in [
		{"chapter": "partner"},
		{"chapter": "partner", "answer": "", "house": {"shelf": Vector2(1, 2)}},
		{"chapter": "partner", "answer": "", "house": "boxed"},
		{"chapter": "partner", "answer": "", "mood": "warm"},
		{"chapter": &"partner", "answer": ""},
	]:
		check(not state.record_chapter_result(result), "refused %s" % [result])
	check_eq(state.finished_chapters(), [] as Array[String], "nothing finished")
	check(not state.has_save(), "nothing saved")


func test_a_test_only_chapter_from_the_chapter_framework_is_never_saved() -> void:
	var state := _fresh_state()
	check(not state.record_chapter_result({"chapter": "stand_in", "answer": ""}), "stand-in refused")
	check_eq(state.finished_chapters(), [] as Array[String], "stand-in not recorded")
	check(not state.has_save(), "nothing saved")
	check(state.record_chapter_result({"chapter": "partner", "answer": ""}), "a story chapter is saved")


func test_house_state_a_chapter_leaves_is_saved_with_it() -> void:
	var state := _fresh_state()
	state.record_chapter_result({"chapter": "partner", "answer": "", "house": {"crib": "boxed"}})
	state.record_chapter_result({"chapter": "protector", "answer": ""})
	var next_visit := _fresh_state()
	check_eq(next_visit.house_state_for("partner"), {"crib": "boxed"}, "partner house state")
	check_eq(next_visit.house_state_for("protector"), {}, "no house state for protector")
	check(not "house" in next_visit.to_save_data().finished[1], "empty house left out")


func test_finishing_the_arrival_leaves_no_next_chapter() -> void:
	var state := _fresh_state()
	for chapter in ChapterList.STORY_ORDER:
		state.record_chapter_result(ChapterResult.make(chapter))
	check_eq(state.next_chapter(), "", "no next chapter")
	check_eq(_fresh_state().finished_chapters().size(), 8, "all eight saved")


func test_a_broken_save_starts_fresh_without_errors() -> void:
	_write_raw("{ this is not json")
	var state := _fresh_state()
	check_eq(state.finished_chapters(), [] as Array[String], "fresh start")
	check(not state.has_save(), "a broken save is not a save to continue from")
	check_eq(state.next_chapter(), "partner", "next chapter")


func test_an_impossible_save_starts_fresh() -> void:
	for text in [
		'{"finished": [{"chapter": "protector", "answer": ""}], "settings": {}}',
		'{"finished": [{"chapter": "partner", "answer": "angry"}], "settings": {}}',
		'{"finished": [{"chapter": "nursery"}], "settings": {}}',
		'{"finished": [{"chapter": "partner", "answer": "", "house": 3}], "settings": {}}',
		'{"finished": "partner"}',
		'[1, 2, 3]',
		'',
	]:
		_write_raw(text)
		var state := _fresh_state()
		check_eq(state.finished_chapters(), [] as Array[String], "fresh start for %s" % text)
		check(not state.has_save(), "no save to continue from for %s" % text)


func test_a_failed_save_keeps_the_last_good_save() -> void:
	_fresh_state().record_chapter_result({"chapter": "partner", "answer": "stoic"})
	var state: Node = GAME_STATE.new()
	_states.append(state)
	state.use_save_file(PrivateBrowsingSaveFile.new(SAVE_PATH))
	check(state.load_save(), "earlier save loaded")
	check(state.record_chapter_result({"chapter": "protector", "answer": ""}), "protector recorded")
	check(not state.last_save_ok, "the new save wasn't kept")
	check(state.has_save(), "still a save to continue from")
	var next_visit := _fresh_state()
	check_eq(next_visit.finished_chapters(), ["partner"] as Array[String], "old save intact")
	check_eq(next_visit.answer_for("partner"), "stoic", "old answer intact")


func test_a_save_that_cannot_be_written_is_reported_and_play_carries_on() -> void:
	var state := _fresh_state("user://test_saves/no/such/folder/save.json")
	var failed := [false]
	state.save_failed.connect(func() -> void: failed[0] = true)
	check(state.record_chapter_result({"chapter": "partner", "answer": ""}), "chapter recorded")
	check(failed[0], "save_failed emitted")
	check(not state.has_save(), "no save to continue from")
	check(not state.last_save_ok, "last_save_ok is false")
	check_eq(state.finished_chapters(), ["partner"] as Array[String], "progress kept in memory")
	check_eq(state.next_chapter(), "protector", "play carries on")


func test_private_browsing_is_reported_as_not_saved_and_play_carries_on() -> void:
	var state: Node = GAME_STATE.new()
	_states.append(state)
	state.use_save_file(PrivateBrowsingSaveFile.new(SAVE_PATH))
	var failed := [false]
	state.save_failed.connect(func() -> void: failed[0] = true)
	check(state.record_chapter_result({"chapter": "partner", "answer": ""}), "chapter recorded")
	check(failed[0], "save_failed emitted")
	check(not state.last_save_ok, "last_save_ok is false")
	check(not state.has_save(), "no save to continue from")
	check(not FileAccess.file_exists(SAVE_PATH), "nothing written")
	check_eq(state.next_chapter(), "protector", "play carries on")


func test_hiding_or_leaving_the_game_does_not_save() -> void:
	var state := _fresh_state()
	add_child(state)
	for what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT,
			NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST]:
		state.notification(what)
	check(not state.has_save(), "no save from hiding or closing")
	remove_child(state)


func test_a_chapter_finished_through_the_chapter_runner_is_saved() -> void:
	var state := _fresh_state()
	add_child(state)  # Its _ready connects it to the runner.
	state.use_save_file(SaveFile.new(SAVE_PATH))
	var runner := ChapterRunner.of(get_tree())
	var house := Control.new()
	add_child(house)
	# The stand-in isn't a story chapter, so it is never saved.
	runner.enter_scene(ChapterList.STAND_IN, STAND_IN, house)
	runner.get_child(0).finished.emit("")
	await frames()
	check(not state.has_save(), "stand-in not saved")
	# The stand-in's scene, entered as the Partner, finishes like a real chapter.
	runner.enter_scene(&"partner", STAND_IN, house)
	runner.get_child(-1).finished.emit("vulnerable")
	await frames()
	check_eq(_fresh_state().finished_chapters(), ["partner"] as Array[String], "partner saved")
	check_eq(_fresh_state().answer_for("partner"), "vulnerable", "answer saved")
	remove_child(state)
	runner.free()


func test_starting_new_forgets_progress_and_deletes_the_save() -> void:
	var state := _fresh_state()
	state.record_chapter_result({"chapter": "partner", "answer": ""})
	state.start_new()
	check_eq(state.finished_chapters(), [] as Array[String], "nothing finished")
	check(not state.has_save(), "save deleted")
	check_eq(_fresh_state().next_chapter(), "partner", "next visit starts fresh")


# --- The opening beat's answer (DAS-92): held in memory, saved with the Partner.

func test_the_opening_beats_answer_is_held_but_not_saved_before_the_partner() -> void:
	var state := _fresh_state()
	check(not state.opening_beat_done(), "not played yet")
	check_eq(state.house_point(), HouseTable.START, "House at the start")
	check(state.finish_opening_beat("stoic"), "opening beat recorded")
	check(state.opening_beat_done(), "played")
	check_eq(state.opening_answer(), "stoic", "answer held")
	check_eq(state.house_point(), HouseTable.AFTER_OPENING, "House after the opening beat")
	check(not state.has_save(), "nothing saved")
	check(not FileAccess.file_exists(SAVE_PATH), "no save file written")
	check(not "opening" in state.to_save_data(), "not in the save data")


func test_leaving_before_the_partner_finishes_plays_the_opening_beat_again() -> void:
	var state := _fresh_state()
	state.finish_opening_beat("vulnerable")
	var next_visit := _fresh_state()
	check(not next_visit.opening_beat_done(), "opening beat plays again")
	check_eq(next_visit.opening_answer(), "", "answer forgotten")
	check_eq(next_visit.house_point(), HouseTable.START, "House back at the start")


func test_the_opening_beats_answer_is_saved_with_the_partners_result() -> void:
	var state := _fresh_state()
	state.finish_opening_beat("vulnerable")
	# Leaving a chapter, hiding the tab or failing a save doesn't write it.
	state.notification(NOTIFICATION_APPLICATION_PAUSED)
	check(not state.has_save(), "still nothing saved")
	check(state.record_chapter_result({"chapter": "partner", "answer": ""}), "partner recorded")
	check_eq(state.to_save_data().get("opening"), "vulnerable", "in the save data")
	var next_visit := _fresh_state()
	check_eq(next_visit.opening_answer(), "vulnerable", "answer read back")
	check(next_visit.opening_beat_done(), "opening beat doesn't play again")
	check_eq(next_visit.house_point(), HouseTable.AFTER_PARTNER, "House after the Partner")
	next_visit.record_chapter_result({"chapter": "protector", "answer": ""})
	check_eq(_fresh_state().opening_answer(), "vulnerable", "kept by later saves")
	check_eq(_fresh_state().house_point(), HouseTable.AFTER_LOSS, "House after the Loss")


func test_the_opening_beat_plays_once_and_takes_only_a_stoic_or_vulnerable_answer() -> void:
	var state := _fresh_state()
	for answer in ["", "angry"]:
		check(not state.finish_opening_beat(answer), "refused '%s'" % answer)
	check(not state.opening_beat_done(), "not played")
	check(state.finish_opening_beat("stoic"), "stoic recorded")
	check(not state.finish_opening_beat("vulnerable"), "second time refused")
	check_eq(state.opening_answer(), "stoic", "first answer kept")


func test_a_partner_saved_without_the_opening_beat_does_not_play_it_again() -> void:
	# The M0 menu starts the Partner without the House.
	_fresh_state().record_chapter_result({"chapter": "partner", "answer": ""})
	var state := _fresh_state()
	check(state.opening_beat_done(), "counts as played")
	check_eq(state.opening_answer(), "", "no answer")
	check(not state.finish_opening_beat("stoic"), "can't be played after the Partner")
	check(not "opening" in state.to_save_data(), "nothing to save")


func test_starting_new_forgets_the_opening_beat() -> void:
	var state := _fresh_state()
	state.finish_opening_beat("stoic")
	state.start_new()
	check(not state.opening_beat_done(), "forgotten")


func test_a_save_with_an_opening_answer_but_no_partner_is_impossible() -> void:
	for text in [
		'{"finished": [], "opening": "stoic", "settings": {}}',
		'{"finished": [{"chapter": "partner", "answer": ""}], "opening": "angry", "settings": {}}',
		'{"finished": [{"chapter": "partner", "answer": ""}], "opening": 3, "settings": {}}',
	]:
		_write_raw(text)
		var state := _fresh_state()
		check(not state.has_save(), "no save to continue from for %s" % text)
		check(not state.opening_beat_done(), "opening beat plays for %s" % text)
