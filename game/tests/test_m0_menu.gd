extends TestCase
## The M0 menu (DAS-66): tap to begin, then one button per M0 check.

const MENU := preload("res://scenes/ui/m0_menu.tscn")


func test_tap_to_begin_shows_the_menu() -> void:
	var menu := add_scene(MENU)
	check(not menu.get_node("%Menu").visible, "menu hidden before the first tap")
	tap(menu.get_node("%BeginButton"))
	check(menu.get_node("%Menu").visible, "menu shown after tapping to begin")
	check(not menu.get_node("%BeginButton").visible, "begin button gone after tapping it")


func test_buttons_are_big_enough_to_tap() -> void:
	var menu := add_scene(MENU)
	tap(menu.get_node("%BeginButton"))
	await frames()
	for name in ["BeginButton", "SmoothnessButton", "RhythmButton", "ViewpointsButton",
			"TestSaveButton", "ClearSaveButton"]:
		var button: Control = menu.get_node("%" + name)
		check(button.size.x >= 44.0 and button.size.y >= 44.0,
				"%s is at least 44px (is %s)" % [name, button.size])


func test_rhythm_check_opens_over_the_menu_and_back_returns() -> void:
	var menu := add_scene(MENU)
	tap(menu.get_node("%BeginButton"))
	await frames()
	tap(menu.get_node("%RhythmButton"))
	var check_node := menu.get_node_or_null("M0RhythmCheck")
	if not check(check_node != null, "rhythm check opened"):
		return
	check(not menu.get_node("%Menu").visible, "menu hidden while the check is open")
	await frames()
	tap(check_node.get_node("%BackButton"))
	await frames()
	check(not is_instance_valid(check_node), "rhythm check closed by Back")
	check(menu.get_node("%Menu").visible, "menu back after closing the check")


func test_smoothness_button_opens_the_smoothness_check() -> void:
	await _check_scene_button("SmoothnessButton",
			"res://scenes/m0_checks/smoothness/smoothness_check.tscn")


func test_viewpoints_button_opens_the_viewpoints_check() -> void:
	await _check_scene_button("ViewpointsButton", "res://scenes/m0_checks/viewpoints_check.tscn")


func _check_scene_button(button: String, scene_path: String) -> void:
	var menu := add_scene(MENU)
	tap(menu.get_node("%BeginButton"))
	await frames()
	tap(menu.get_node("%" + button))
	await frames(2)
	var scene := get_tree().current_scene
	check(scene != null and scene.scene_file_path == scene_path,
			"%s opens %s" % [button, scene_path])


func test_test_save_records_the_next_chapter_and_clear_save_forgets_it() -> void:
	var state := get_node("/root/GameState")
	state.start_new()
	var menu := add_scene(MENU)
	tap(menu.get_node("%BeginButton"))
	await frames()
	var saved: Label = menu.get_node("%SaveStatus")
	check_eq(saved.text, "Saved: none", "nothing saved at first")
	tap(menu.get_node("%TestSaveButton"))
	check_eq(saved.text, "Saved: partner", "after one test save")
	check(state.has_save(), "written to the save file")
	tap(menu.get_node("%TestSaveButton"))
	check_eq(saved.text, "Saved: partner, protector", "after two")
	tap(menu.get_node("%ClearSaveButton"))
	check_eq(saved.text, "Saved: none", "after clearing")
	check(not state.has_save(), "save file deleted")


func test_test_save_is_off_once_every_chapter_is_saved() -> void:
	var state := get_node("/root/GameState")
	state.start_new()
	for chapter in ChapterList.STORY_ORDER:
		state.record_chapter_result(ChapterResult.make(chapter))
	var menu := add_scene(MENU)
	check(menu.get_node("%TestSaveButton").disabled, "nothing left to save")
	state.start_new()
