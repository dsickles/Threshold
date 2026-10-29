extends TestCase
## The opening flow (DAS-95): "Tap to begin", the porch, the opening beat at
## the living room's doorway view (L1), the record player's close-up starting
## the Partner, and the bedside lamp starting the Protector's run. Saves come
## only when the Partner finishes. Also the "Turn your phone sideways" screen.

const TITLE := preload("res://scenes/ui/title.tscn")
const HOUSE := preload("res://scenes/house/house.tscn")
const PARTNER := "res://scenes/chapters/partner/partner.tscn"
const PROTECTOR := "res://scenes/chapters/protector/protector.tscn"
const SCREENS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(844, 390)]
## The approved words (m1-words-draft.md section 1).
const WORDS_DOC := "../docs/design/m1-words-draft.md"

var _state: Node
var _runner: ChapterRunner


func before_each() -> void:
	_state = get_node("/root/GameState")
	_state.start_new()
	_runner = ChapterRunner.of(get_tree())
	# GameState listens to the runner it found at start-up; earlier tests free
	# theirs, so hook this one up the same way, before any House does.
	if not _runner.chapter_finished.is_connected(_state.record_chapter_result):
		_runner.chapter_finished.connect(_state.record_chapter_result)


func after_each() -> void:
	var turn := get_node("/root/TurnSideways")
	turn.stop_watching()
	turn.assume_touch = null
	get_tree().paused = false
	_state.start_new()
	# The runner lives on the root, so it would outlast this test.
	_runner.free()


func _open_house(point: StringName = &"") -> Node:
	var house := HOUSE.instantiate()
	house.story_point = point
	add_child(house)
	return house


func _finish_glide(house: Node) -> void:
	if house._tween and house._tween.is_valid():
		house._tween.custom_step(house.GLIDE_SECONDS + 0.1)
	await frames()


func _stand_at(house: Node, view: String) -> void:
	if house._tween:
		house._tween.kill()
	house._current = view
	house._set_base(HouseLayout.view_transform(view))
	house._arrive()


# Plays the opening beat through, choosing `answer` for Leo's line, and
# returns every line shown, as "Who: line".
func _play_beat(beat: Control, answer: String) -> Array[String]:
	var shown: Array[String] = []
	for i in 2000:
		if beat.is_done():
			break
		if beat.is_choosing():
			await frames()  # Laid out once it shows.
			tap(beat.choice_button(answer))
		beat.step(0.05)
		var line: String = beat.current_line()
		if line != "":
			var said := "%s: %s" % [beat.current_speaker(), line]
			if shown.is_empty() or shown[-1] != said:
				shown.append(said)
	return shown


# The opening beat's lines from the words doc, by their number (1, 2, 3a...).
func _approved_lines() -> Dictionary:
	var path := ProjectSettings.globalize_path("res://").path_join(WORDS_DOC)
	var text := FileAccess.get_file_as_string(path)
	var start := text.find("### \"Did you lock the door?\"")
	var end := text.find("### Alternatives")
	var lines := {}
	if start < 0 or end < start:
		return lines
	for row in text.substr(start, end - start).split("\n"):
		var cells := row.split("|")
		if cells.size() >= 5 and cells[1].strip_edges() in ["1", "2", "3a", "3b", "4a", "4b", "5"]:
			var who := "Leo" if cells[2].strip_edges().begins_with("Leo") else "Maya"
			lines[cells[1].strip_edges()] = "%s: %s" % [who, cells[3].strip_edges()]
	return lines


# Walks into the living room for the first time: the opening beat starts.
func _arrive_at_l1(house: Node) -> Control:
	_stand_at(house, "E1")
	tap(house.ring_to("L1"))
	await _finish_glide(house)
	return house.opening_beat()


func _object_tap(house: Node, object_id: String) -> void:
	await frames()
	tap(house.object_button(object_id))
	await frames()


# The record player's needle goes down (0.8 s), then the Partner starts.
func _lower_needle(house: Node) -> void:
	if house._needle and house._needle.is_valid():
		house._needle.custom_step(1.0)
	await frames()


func _chapter() -> Node:
	return _runner.get_child(0) if _runner.get_child_count() > 0 else null


func _save_on_disk() -> Dictionary:
	return SaveFile.new("user://test_saves/autoload_save.json").read()


# --- Tap to begin, then the porch.

func test_the_game_opens_on_tap_to_begin_then_the_porch() -> void:
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), TITLE.resource_path,
			"the game opens on the title")
	var title := add_scene(TITLE)
	await frames()
	var begin: Button = title.get_node("%BeginButton")
	check(begin.is_visible_in_tree() and begin.text == "Tap to begin", "Tap to begin shows")
	check(begin.size.x >= 44.0 and begin.size.y >= 44.0, "Tap to begin is at least 44px")
	# Nothing plays before the first tap (the browser wouldn't let it).
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D"]:
		for player in get_tree().root.find_children("*", type, true, false):
			check(not player.playing, "%s is quiet before the first tap" % player.name)
	tap(begin)
	await frames(2)
	var house := get_tree().current_scene
	if check(house != null and house.scene_file_path == HOUSE.resource_path, "the first tap opens the House"):
		check_eq(house.story_point, HouseTable.START, "a new game starts on moving day")
		check_eq(house._current, "P", "on the porch")
	get_tree().unload_current_scene()
	await frames()


func test_the_test_menu_opens_only_when_asked_for() -> void:
	check(not preload("res://scenes/ui/title.gd").wants_menu(), "no ?probe&menu: the game, not the menu")


func test_the_house_opens_at_the_players_own_point() -> void:
	_state.record_chapter_result(ChapterResult.make(&"partner"))
	var house := _open_house()
	check_eq(house.story_point, HouseTable.AFTER_PARTNER, "after a saved Partner")
	check_eq(house._current, "B1", "in the bedroom, where the Partner began")


# --- The opening beat.

func test_the_opening_beat_plays_on_first_arrival_at_l1_with_the_approved_words() -> void:
	var approved := _approved_lines()
	check_eq(approved.size(), 7, "the words doc has the beat's seven lines")
	for answer: String in ["stoic", "vulnerable"]:
		_state.start_new()
		var house := _open_house(HouseTable.START)
		check(house.opening_beat() == null, "%s: no beat on the porch" % answer)
		var beat := await _arrive_at_l1(house)
		if not check(beat != null, "%s: the beat starts at L1" % answer):
			house.free()
			continue
		var reply := "a" if answer == "stoic" else "b"
		var expected: Array[String] = [approved.get("1", "?"), approved.get("2", "?"),
				approved.get("3" + reply, "?"), approved.get("4" + reply, "?"), approved.get("5", "?")]
		check_eq(await _play_beat(beat, answer), expected, "%s: the lines, in order, exactly" % answer)
		check_eq(_state.opening_answer(), answer, "%s: the answer is held" % answer)
		house.free()


func test_only_leos_line_and_mayas_reply_differ_by_the_choice() -> void:
	var lines := {}
	for answer: String in ["stoic", "vulnerable"]:
		_state.start_new()
		var house := _open_house(HouseTable.START)
		var beat := await _arrive_at_l1(house)
		lines[answer] = await _play_beat(beat, answer)
		lines[answer + "_doors"] = house.door_states.duplicate()
		lines[answer + "_point"] = house.story_point
		house.free()
	var a: Array = lines.stoic
	var b: Array = lines.vulnerable
	if check_eq(a.size(), b.size(), "same number of lines"):
		for i in a.size():
			check_eq(a[i] != b[i], i == 2 or i == 3, "line %d differs only if it is Leo's line or Maya's reply" % (i + 1))
	check_eq(lines.stoic_doors, lines.vulnerable_doors, "the same House either way")
	check_eq(lines.stoic_point, lines.vulnerable_point, "the same story point either way")


func test_the_choice_is_leos_two_lines_and_says_nothing_else() -> void:
	var house := _open_house(HouseTable.START)
	var beat := await _arrive_at_l1(house)
	for i in 400:
		if beat.is_choosing():
			break
		beat.step(0.05)
	check(beat.is_choosing(), "the beat waits for Leo's line")
	beat.step(60.0)
	check(beat.is_choosing(), "however long it takes")
	var texts: Array[String] = []
	for label in beat.find_children("*", "Label", true, false):
		if (label as Label).is_visible_in_tree() and label.text != "":
			texts.append(label.text)
	check_eq(texts, [] as Array[String], "no words besides the two lines (nothing explains the choice)")
	for answer: String in ["stoic", "vulnerable"]:
		var button: Button = beat.choice_button(answer)
		check(button.is_visible_in_tree(), "%s line shows" % answer)
		check_eq(button.text, beat.LEO_LINES[answer], "%s button is Leo's line" % answer)
		check(button.size.y >= 44.0 and button.size.x >= 44.0, "%s button is at least 44px" % answer)
		check(button.get_theme_stylebox("hover") == button.get_theme_stylebox("normal"),
				"%s button looks the same hovered" % answer)


func test_the_opening_beat_plays_once() -> void:
	var house := _open_house(HouseTable.START)
	_stand_at(house, "K1")
	check(house.opening_beat() == null, "not in the kitchen")
	var beat := await _arrive_at_l1(house)
	await _play_beat(beat, "stoic")
	await frames()
	check(house.opening_beat() == null, "gone once it ends")
	_stand_at(house, "L3")
	_stand_at(house, "L1")
	check(house.opening_beat() == null, "not again on coming back to L1")
	var again := _open_house()
	_stand_at(again, "L1")
	check(again.opening_beat() == null, "not again in the same visit")


# Every ring the player can see, with its label, as screen rects.
func _ring_rects(house: Node) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for ring: Button in house._rings:
		if ring.is_visible_in_tree():
			rects.append(ring.get_global_rect().merge(house.ring_label(ring).get_global_rect()))
	return rects


func test_rings_keep_clear_of_the_subtitles_and_the_choice() -> void:
	for screen in SCREENS:
		set_screen(screen)
		_state.start_new()
		var house := _open_house(HouseTable.START)
		var beat := await _arrive_at_l1(house)
		var checked := 0
		for i in 2000:
			if beat.is_done():
				break
			await frames(2)
			var covered: Array[Control] = [beat._bar,
					beat.choice_button("stoic"), beat.choice_button("vulnerable")]
			var rings := _ring_rects(house)
			check(not rings.is_empty(), "%s: the rings still show during the beat" % screen)
			for control in covered:
				if not control.is_visible_in_tree():
					continue
				checked += 1
				for rect in rings:
					check(not rect.intersects(control.get_global_rect()),
							"%s: no ring over %s (%s, %s)" % [screen, control.name, rect, control.get_global_rect()])
			if beat.is_choosing():
				tap(beat.choice_button("stoic"))
			beat.step(0.5)
		check(beat.is_done(), "%s: the beat played through" % screen)
		check(checked > 0, "%s: the subtitles and the choice were checked" % screen)
		house.free()
		await frames()


func test_walking_away_mid_beat_lets_maya_finish_and_the_hall_still_opens() -> void:
	var house := _open_house(HouseTable.START)
	var beat := await _arrive_at_l1(house)
	for i in 400:
		if beat.current_line() != "":
			break
		beat.step(0.05)
	check_eq(beat.current_line(), "Did you lock the front door?", "Maya has started")
	var away: Button = house.ring_to("E1")
	if not check(away != null and away.is_visible_in_tree(), "a ring out of the living room can be tapped"):
		house.free()
		return
	tap(away)
	await _finish_glide(house)
	check_eq(house._current, "E1", "walked back to the entry")
	check(house.opening_beat() == beat, "the beat carries on")
	var said := await _play_beat(beat, "vulnerable")
	check_eq(said.size(), 5, "all five lines, from the entry")
	await frames()
	check_eq(house.story_point, HouseTable.AFTER_OPENING, "the House moves on after it")
	check_eq(_state.opening_answer(), "vulnerable", "the answer is held")
	_stand_at(house, "L1")
	check(house.opening_beat() == null, "and it doesn't start again back at L1")
	check(house.ring_to("H1") != null, "the hall is open")


func test_after_the_opening_beat_the_back_hall_and_bedroom_open_and_the_record_player_works() -> void:
	var house := _open_house(HouseTable.START)
	check(house.find_child("Boxes_hall_opening", true, false) != null, "boxes in the hall opening at first")
	check(not house.is_lamp_lit(), "the bedside lamp is off at first")
	var beat := await _arrive_at_l1(house)
	await _play_beat(beat, "vulnerable")
	await frames()
	var point: StringName = _state.house_point()
	check_eq(point, HouseTable.AFTER_OPENING, "the core table's point after the beat")
	check_eq(house.story_point, point, "the House shows it")
	check_eq(house.door_states, HouseTable.doors(point), "doors from the core table")
	check_eq(HouseTable.room_state(point, HouseTable.BACK_HALL), HouseTable.OPEN, "back hall open")
	check_eq(HouseTable.room_state(point, HouseTable.BEDROOM), HouseTable.OPEN, "bedroom open")
	check(house.find_child("Boxes_hall_opening", true, false) == null, "the boxes have left the hall opening")
	check(house.ring_to("H1") != null, "a ring into the hall from L1")
	var reachable := HouseLayout.reachable("L1", house.door_states)
	check("B1" in reachable and "B3" in reachable, "the bedroom and the record player's corner can be reached")
	check(house.is_lamp_lit(), "the bedside lamp is lit")
	check_eq(HouseTable.chapter_object(point), HouseTable.RECORD_PLAYER, "the core table's chapter object")
	check(house.object_works("record_player"), "the record player works")
	check(not house.object_works("bedside_lamp"), "the lamp doesn't yet")


# --- Close-ups and the record player.

func test_the_record_player_close_up_then_a_tap_starts_the_partner() -> void:
	var house := _open_house(HouseTable.AFTER_OPENING)
	_stand_at(house, "B3")
	await frames()
	var button: Button = house.object_button("record_player")
	check(button.is_visible_in_tree(), "the record player can be tapped from the corner")
	await _object_tap(house, "record_player")
	check_eq(house.close_up(), "record_player", "the first tap glides to its close-up")
	check(_chapter() == null, "nothing starts on the first tap")
	await _finish_glide(house)
	check(house._camera.global_transform.origin.distance_to(
			HouseLayout.close_up_transform("record_player").origin) < 0.01, "at the close-up")
	check(house._ring_data.is_empty(), "no rings at a close-up")
	await _object_tap(house, "record_player")
	check(_chapter() == null, "the needle goes down first")
	var arm_rest: float = house._arm.position.y
	await _lower_needle(house)
	check(house._arm.position.y < arm_rest, "the needle is lowered")
	var partner := _chapter()
	if check(partner != null and partner.scene_file_path == PARTNER, "the second tap starts the Partner"):
		check(not house.visible and not house._ui_layer.visible, "the House is hidden while it plays")


func test_tapping_off_a_close_up_steps_back_to_the_view_it_was_opened_from() -> void:
	for setup: Array in [[HouseTable.AFTER_OPENING, "B3", "record_player"],
			[HouseTable.AFTER_PARTNER, "B2", "bedside_lamp"]]:
		var house := _open_house(setup[0])
		var view: String = setup[1]
		var where: String = setup[2]
		_stand_at(house, view)
		await _object_tap(house, where)
		await _finish_glide(house)
		check_eq(house.close_up(), where, "%s: its close-up" % where)
		tap_at(Vector2(30.0, 30.0))
		await _finish_glide(house)
		check_eq(house.close_up(), "", "%s: stepped back" % where)
		check_eq(house._current, view, "%s: to the view it was opened from" % where)
		check(house._camera.global_transform.origin.distance_to(HouseLayout.view_transform(view).origin) < 0.01,
				"%s: the camera is back" % where)
		check(house._rings.any(func(ring: Button) -> bool: return ring.is_visible_in_tree()),
				"%s: the view's rings are back" % where)
		check(_chapter() == null, "%s: nothing started" % where)
		if where == "bedside_lamp":
			check(house.is_lamp_lit(), "the lamp is still on")
		house.free()
		await frames()


func test_chapter_objects_can_be_tapped_at_least_44px_and_hover_does_nothing() -> void:
	for screen in SCREENS:
		set_screen(screen)
		for setup: Array in [[HouseTable.AFTER_OPENING, "B3", "record_player"],
				[HouseTable.AFTER_PARTNER, "B2", "bedside_lamp"]]:
			var house := _open_house(setup[0])
			_stand_at(house, setup[1])
			await frames(2)
			var button: Button = house.object_button(setup[2])
			var where := "%s at %s" % [setup[2], screen]
			var to_screen := float(screen.x) / house.get_viewport().get_visible_rect().size.x
			if check(button.is_visible_in_tree(), "%s can be tapped" % where):
				var rect := button.get_global_rect()
				check(rect.size.x * to_screen >= 44.0 and rect.size.y * to_screen >= 44.0,
						"%s is at least 44px on the real screen" % where)
				check(house.get_viewport().get_visible_rect().has_point(rect.get_center()), "%s on screen" % where)
				check(button.get_theme_stylebox("hover") is StyleBoxEmpty, "%s shows nothing on hover" % where)
			house.free()


# --- Saving.

func test_nothing_is_saved_before_the_partner_finishes_and_then_the_save_holds_it_and_the_answer() -> void:
	var house := _open_house()
	var beat := await _arrive_at_l1(house)
	await _play_beat(beat, "vulnerable")
	await frames()
	check(not _state.has_save(), "nothing saved after the opening beat")
	check(_save_on_disk().is_empty(), "no save file after the opening beat")
	_stand_at(house, "B3")
	await _object_tap(house, "record_player")
	await _finish_glide(house)
	await _object_tap(house, "record_player")
	await _lower_needle(house)
	var partner := _chapter()
	if not check(partner != null, "the Partner started"):
		return
	check(_save_on_disk().is_empty(), "no save file while the Partner plays")
	partner.finished.emit()
	await frames()
	var saved := _save_on_disk()
	check_eq(saved.get("finished"), [{"chapter": "partner", "answer": ""}], "the save holds the Partner")
	check_eq(saved.get("opening"), "vulnerable", "and the opening's answer")
	check(house.visible, "the House is back")
	check_eq(house.story_point, HouseTable.AFTER_PARTNER, "at the \"after the Partner\" point")
	check_eq(house._current, "B1", "in the bedroom")
	check_eq(house.close_up(), "", "not at the close-up")
	check(house.ring_to("B2") != null, "with its rings")
	check(house.object_works("bedside_lamp"), "and the bedside lamp works")


func test_leaving_before_the_partner_finishes_and_coming_back_plays_the_opening_again() -> void:
	var house := _open_house()
	var beat := await _arrive_at_l1(house)
	await _play_beat(beat, "stoic")
	await frames()
	_stand_at(house, "B3")
	await _object_tap(house, "record_player")
	await _finish_glide(house)
	await _object_tap(house, "record_player")
	await _lower_needle(house)
	var partner := _chapter()
	if check(partner != null, "the Partner started"):
		# Left part-way (its song didn't load, say): no result.
		partner.queue_free()
		await frames()
		check(house.visible, "the House is back")
		check_eq(house.story_point, HouseTable.AFTER_OPENING, "nothing moved on")
		check_eq(house._current, "B3", "back at the view the close-up was opened from")
		check(house.object_works("record_player"), "the record player works again")
	check(_save_on_disk().is_empty(), "nothing saved")
	house.free()
	# The tab is closed and the game opened again: it reads the save.
	_state.load_save()
	check(not _state.opening_beat_done(), "the opening beat is forgotten")
	check_eq(_state.house_point(), HouseTable.START, "back to moving day")
	var again := _open_house()
	check_eq(again._current, "P", "on the porch again")
	var replay := await _arrive_at_l1(again)
	check(replay != null, "the opening beat plays again")


# --- The bedside lamp starts the Protector.

func test_the_bedside_lamp_works_only_after_the_partner() -> void:
	var house := _open_house(HouseTable.AFTER_OPENING)
	_stand_at(house, "B2")
	await frames()
	check(house.is_lamp_lit(), "lit, leading the way to the bedroom")
	check(not house.object_button("bedside_lamp").visible, "but it can't be tapped before the Partner")
	house.free()
	var after := _open_house(HouseTable.AFTER_PARTNER)
	_stand_at(after, "B2")
	await frames()
	check(after.object_button("bedside_lamp").visible, "it can be tapped after the Partner")
	check(not after.object_button("record_player").visible, "and the record player can't")


func test_turning_off_the_bedside_lamp_starts_the_run_with_no_warning_title_card_or_skip() -> void:
	_state.record_chapter_result(ChapterResult.make(&"partner"))
	var house := _open_house()
	_stand_at(house, "B2")
	await _object_tap(house, "bedside_lamp")
	check_eq(house.close_up(), "bedside_lamp", "the first tap glides to its close-up")
	await _finish_glide(house)
	check(house.is_lamp_lit(), "still lit at its close-up")
	tap(house.object_button("bedside_lamp"))
	check(not house.is_lamp_lit(), "the second tap turns it off")
	var run := _chapter()
	if not check(run != null and run.scene_file_path == PROTECTOR, "and the run starts straight away"):
		return
	await frames()
	check_eq(run.find_children("*", "BaseButton", true, false).size(), 0, "nothing to press: no skip")
	check_eq(run.find_children("*", "Label", true, false).filter(
			func(label: Label) -> bool: return label.is_visible_in_tree() and label.text != ""
			).size(), 0, "no words on screen: no warning, no title card")
	check(not house._ui_layer.visible, "the House's rings are hidden")
	check(house._world_env.get_parent() == null, "the House's light and fog give way to the run's")
	run.finished.emit()
	await frames()
	check(_state.is_finished("protector"), "the run's result is saved")
	check(house.visible and house._ui_layer.visible, "the House is back")
	check(house._world_env.is_inside_tree(), "with its light and fog")
	check_eq(house.story_point, HouseTable.AFTER_LOSS, "after the Loss")
	check_eq(house._current, "E1", "in the entry")
	check(not house.is_lamp_lit(), "the lamp stays off")


# --- Turn your phone sideways.

func test_an_upright_phone_shows_turn_your_phone_sideways_and_turning_it_continues_where_it_was() -> void:
	var turn := get_node("/root/TurnSideways")
	turn.assume_touch = true
	var house := _open_house(HouseTable.START)
	_stand_at(house, "P")
	tap(house.ring_to("E1"))
	await frames()
	check(house.is_gliding(), "gliding in through the front door")
	set_screen(Vector2i(390, 844))
	await frames(2)
	check(not turn.is_showing(), "not before the game has started (the test menu)")
	turn.watch()
	await frames(2)
	check(turn.is_showing(), "upright: the screen shows")
	check(get_tree().paused, "and the game waits")
	var words: Label = turn.get_node("Cover/Words")
	check_eq(words.text, "Turn your phone sideways", "its words")
	var at: Transform3D = house._camera.global_transform
	for i in 5:
		await get_tree().process_frame
	check(house._camera.global_transform.is_equal_approx(at), "the glide holds still while upright")
	set_screen(Vector2i(844, 390))
	await frames(2)
	check(not turn.is_showing(), "sideways: the screen goes")
	check(not get_tree().paused, "the game carries on")
	check(house.is_gliding(), "from where it was")
	await _finish_glide(house)
	check_eq(house._current, "E1", "and arrives")


func test_turning_upright_pauses_a_chapter_until_a_tap() -> void:
	var turn := get_node("/root/TurnSideways")
	turn.assume_touch = true
	turn.watch()
	_state.record_chapter_result(ChapterResult.make(&"partner"))
	var house := _open_house()
	_stand_at(house, "B2")
	await _object_tap(house, "bedside_lamp")
	await _finish_glide(house)
	tap(house.object_button("bedside_lamp"))
	var run := _chapter()
	if not check(run != null, "the run started"):
		return
	await frames()
	set_screen(Vector2i(390, 844))
	await frames(2)
	check(turn.is_showing(), "the screen shows over the run")
	check(run.run().is_paused(), "the run pauses")
	set_screen(Vector2i(844, 390))
	await frames(2)
	check(not get_tree().paused, "sideways again")
	check(run.run().is_paused(), "the run waits for a tap, as after a hidden tab")


func test_a_laptop_window_never_shows_turn_your_phone_sideways() -> void:
	var turn := get_node("/root/TurnSideways")
	turn.assume_touch = false
	turn.watch()
	set_screen(Vector2i(390, 844))
	await frames(2)
	check(not turn.is_showing(), "no touch screen: a narrow window just shows the game")
