extends TestCase
## Progress and saves (DAS-74, ADR-0007): the finished-chapter list, saved
## only when a chapter finishes, read back on the next visit, and a bad or
## missing save treated as a fresh start.

const GAME_STATE := preload("res://_core/state_manager/game_state.gd")
const SAVE_PATH := "user://test_saves/save.json"

var _states: Array[Node] = []


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
	check(state.record_chapter_result({"chapter": "partner", "answer": "vulnerable"}), "save kept")
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
	state.record_chapter_result({"chapter": "partner", "answer": "vulnerable"})
	check_eq(state.finished_chapters(), ["partner"] as Array[String], "partner listed once")
	check_eq(state.answer_for("partner"), "stoic", "first answer kept")


func test_an_unknown_answer_is_not_recorded() -> void:
	var state := _fresh_state()
	check(not state.record_chapter_result({"chapter": "partner", "answer": "angry"}), "refused")
	check_eq(state.finished_chapters(), [] as Array[String], "nothing finished")


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
	for chapter in GAME_STATE.STORY_ORDER:
		state.record_chapter_result({"chapter": chapter, "answer": ""})
	check_eq(state.next_chapter(), "", "no next chapter")
	check_eq(_fresh_state().finished_chapters().size(), 8, "all eight saved")


func test_a_broken_save_starts_fresh_without_errors() -> void:
	_write_raw("{ this is not json")
	var state := _fresh_state()
	check_eq(state.finished_chapters(), [] as Array[String], "fresh start")
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
		check_eq(_fresh_state().finished_chapters(), [] as Array[String], "fresh start for %s" % text)


func test_a_save_that_cannot_be_written_is_reported_and_play_carries_on() -> void:
	var state := _fresh_state("user://test_saves/no/such/folder/save.json")
	var failed := [false]
	state.save_failed.connect(func() -> void: failed[0] = true)
	check(not state.record_chapter_result({"chapter": "partner", "answer": ""}), "reported as not kept")
	check(failed[0], "save_failed emitted")
	check(not state.last_save_ok, "last_save_ok is false")
	check_eq(state.finished_chapters(), ["partner"] as Array[String], "progress kept in memory")
	check_eq(state.next_chapter(), "protector", "play carries on")


func test_hiding_or_leaving_the_game_does_not_save() -> void:
	var state := _fresh_state()
	add_child(state)
	for what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT,
			NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST]:
		state.notification(what)
	check(not state.has_save(), "no save from hiding or closing")
	remove_child(state)


func test_starting_new_forgets_progress_and_deletes_the_save() -> void:
	var state := _fresh_state()
	state.record_chapter_result({"chapter": "partner", "answer": ""})
	state.start_new()
	check_eq(state.finished_chapters(), [] as Array[String], "nothing finished")
	check(not state.has_save(), "save deleted")
	check_eq(_fresh_state().next_chapter(), "partner", "next visit starts fresh")
