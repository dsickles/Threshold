extends TestCase
## The M0 menu (DAS-66): tap to begin, then one button per M0 check, chapter
## and save action, all fitting on every screen (DAS-76).

const MENU := preload("res://scenes/ui/m0_menu.tscn")


func test_tap_to_begin_shows_the_menu() -> void:
	var menu := add_scene(MENU)
	check(not menu.get_node("%Menu").visible, "menu hidden before the first tap")
	tap(menu.get_node("%BeginButton"))
	check(menu.get_node("%Menu").visible, "menu shown after tapping to begin")
	check(not menu.get_node("%BeginButton").visible, "begin button gone after tapping it")


const SCREENS := [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]


func test_every_button_is_on_screen_and_big_enough_on_every_screen() -> void:
	for screen in SCREENS:
		set_screen(screen)
		var menu := add_scene(MENU)
		tap(menu.get_node("%BeginButton"))
		await frames(2)
		_check_menu_fits(menu, screen)
		menu.free()


# M1 adds the Loss and the Silence (and a test chapter may join them), so the
# menu must still fit with three rows of chapter buttons.
func test_the_menu_still_fits_with_six_chapters() -> void:
	for screen in SCREENS:
		set_screen(screen)
		var menu := add_scene(MENU)
		var chapters: Control = menu.get_node("%Chapters")
		var template: Button = menu.get_node("%StandInButton")
		while chapters.get_child_count() < 6:
			var extra := template.duplicate(0) as Button
			extra.unique_name_in_owner = false
			extra.text = "Extra chapter %d" % chapters.get_child_count()
			chapters.add_child(extra)
		tap(menu.get_node("%BeginButton"))
		await frames(2)
		_check_menu_fits(menu, screen)
		menu.free()


# Every button and line is inside the screen, no two buttons overlap, and each
# button is at least 44px both in the game's own units and on the real screen
# (the window's size: points on a phone).
func _check_menu_fits(menu: Node, screen: Vector2i) -> void:
	var view := get_viewport().get_visible_rect()
	var to_screen := float(screen.x) / view.size.x
	var menu_box: Control = menu.get_node("%Menu")
	check(view.encloses(menu_box.get_global_rect()),
			"menu inside the screen on %s (menu %s, screen %s)" % [screen, menu_box.get_global_rect(), view])
	var buttons: Array[Button] = []
	_collect_buttons(menu_box, buttons)
	check(buttons.size() >= 7, "found the menu's buttons on %s" % screen)
	for i in buttons.size():
		var rect := buttons[i].get_global_rect()
		var label := "%s on %s" % [buttons[i].text, screen]
		check(view.encloses(rect), "%s is on screen (is %s)" % [label, rect])
		check(rect.size.x >= 44.0 and rect.size.y >= 44.0, "%s is at least 44px (is %s)" % [label, rect.size])
		var real := rect.size * to_screen
		check(real.x >= 44.0 and real.y >= 44.0,
				"%s is at least 44px on the real screen (is %s)" % [label, real])
		for j in range(i + 1, buttons.size()):
			check(not rect.intersects(buttons[j].get_global_rect()),
					"%s doesn't overlap %s" % [label, buttons[j].text])
	for name in ["SaveStatus", "Status"]:
		var line: Control = menu.get_node("%" + name)
		check(view.encloses(line.get_global_rect()), "%s line on screen on %s" % [name, screen])


func _collect_buttons(node: Node, out: Array[Button]) -> void:
	if node is Button and node.is_visible_in_tree():
		out.append(node)
	for child in node.get_children():
		_collect_buttons(child, out)


func test_begin_button_is_big_enough_to_tap() -> void:
	var menu := add_scene(MENU)
	await frames()
	var begin: Control = menu.get_node("%BeginButton")
	check(begin.size.x >= 44.0 and begin.size.y >= 44.0, "BeginButton is at least 44px (is %s)" % begin.size)


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


func test_ui_style_button_opens_the_ui_style_check() -> void:
	await _check_scene_button("UiStyleButton", "res://scenes/m0_checks/ui_style_check.tscn")


# DAS-93: the gray-box House opens from the menu at a core-table story point:
# moving day (on the porch), or after the opening beat (in the living room,
# with the back hall open).
func test_house_moving_day_opens_the_house_at_the_start() -> void:
	await _check_house_button("HouseStartButton", HouseTable.START, "P")


func test_house_hall_open_opens_the_house_with_the_hall_open() -> void:
	await _check_house_button("HouseHallOpenButton", HouseTable.AFTER_OPENING, "L1")


func _check_house_button(button: String, point: StringName, view: String) -> void:
	await _check_scene_button(button, "res://scenes/house/house.tscn")
	var house := get_tree().current_scene
	if house != null and house.scene_file_path == "res://scenes/house/house.tscn":
		check_eq(house.story_point, point, "%s's story point" % button)
		check_eq(house._current, view, "%s starts in the point's arrival room" % button)
	get_tree().unload_current_scene()
	await frames()


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
