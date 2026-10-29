extends Control
## M0 test menu: a "tap to begin" screen, then one button per M0 check.
## Throwaway M0 scaffolding, not game code. The checks themselves come in
## DAS-67 (Smoothness), DAS-68 (Rhythm timing) and DAS-69 (Viewpoints).
## Until the House exists, the menu also stands in for it when starting a
## chapter through the chapter runner (DAS-75). "Test save" records the next
## story chapter as finished, so saving can be checked on a phone before any
## story chapter is playable (DAS-74); the line under it shows what is saved.
## The menu is scaled to fit whatever screen it is on, so every button stays
## on screen as chapters are added, and grows on an upright phone (DAS-76).
## Its look comes from the shared theme (DAS-72); "UI style" shows that theme
## at true size.
## The two House buttons open the gray-box House (DAS-93) at a story point
## from the core table: moving day (the start), or after the opening beat,
## with the back hall open so the bedroom can be reached.
## "The Protector (rough)" opens the Loss's run (DAS-97) straight away, for
## testing; in the game the bedside lamp in the House starts it (DAS-95).
## The game itself opens on the title (title.tscn); this menu only opens with
## "?probe&menu" in the address.

const SMOOTHNESS_SCENE := "res://scenes/m0_checks/smoothness/smoothness_check.tscn"
const VIEWPOINTS_SCENE := "res://scenes/m0_checks/viewpoints_check.tscn"
const UI_STYLE_SCENE := "res://scenes/m0_checks/ui_style_check.tscn"
const RHYTHM_CHECK := preload("res://scenes/ui/m0_rhythm_check.tscn")
const HOUSE := preload("res://scenes/house/house.tscn")
## How much of the screen the menu may cover, and how far it may grow.
const SCREEN_SHARE := 0.92
const MAX_SCALE := 2.4

@onready var _begin_button: Button = %BeginButton
@onready var _menu: Control = %Menu
@onready var _checks: GridContainer = %Checks
@onready var _chapters: GridContainer = %Chapters
@onready var _status: Label = %Status
@onready var _save_status: Label = %SaveStatus


func _ready() -> void:
	_menu.hide()
	_begin_button.pressed.connect(_on_begin_pressed)
	%SmoothnessButton.pressed.connect(get_tree().change_scene_to_file.bind(SMOOTHNESS_SCENE))
	%RhythmButton.pressed.connect(_open_check.bind(RHYTHM_CHECK))
	%ViewpointsButton.pressed.connect(get_tree().change_scene_to_file.bind(VIEWPOINTS_SCENE))
	%HouseStartButton.pressed.connect(_open_house.bind(HouseTable.START))
	%HouseHallOpenButton.pressed.connect(_open_house.bind(HouseTable.AFTER_OPENING))
	%UiStyleButton.pressed.connect(get_tree().change_scene_to_file.bind(UI_STYLE_SCENE))
	%PartnerButton.pressed.connect(_enter_chapter.bind(&"partner"))
	%ProtectorButton.pressed.connect(_enter_chapter.bind(&"protector"))
	%StandInButton.pressed.connect(_enter_chapter.bind(ChapterList.STAND_IN))
	var chapters := ChapterRunner.of(get_tree())
	chapters.chapter_finished.connect(_on_chapter_finished)
	chapters.chapter_left.connect(_on_chapter_left)
	%TestSaveButton.pressed.connect(_on_test_save_pressed)
	%ClearSaveButton.pressed.connect(_game_state().start_new)
	_game_state().progress_changed.connect(_show_progress)
	_game_state().save_failed.connect(_show_progress)
	_show_progress()
	resized.connect(_fit_menu)
	_menu.minimum_size_changed.connect(_fit_menu)
	_fit_menu()


# Browsers play no sound until the first tap, so everything starts from here.
func _on_begin_pressed() -> void:
	_begin_button.hide()
	_menu.show()


# Lays out the chapters, then scales the menu to the largest size that fits the screen (up to MAX_SCALE),
# centred. Containers reset their children's scale, so the menu is placed by
# hand rather than inside a container.
func _fit_menu() -> void:
	# Chapters stack in one column on an upright phone and three across on a
	# wide screen, so the menu's shape matches the screen's. The checks (and
	# the House buttons) go three across on a wide screen and two upright.
	var upright := size.y > size.x
	var columns := 1 if upright else 3
	if _chapters.columns != columns:
		_chapters.columns = columns
	var check_columns := 2 if upright else 3
	if _checks.columns != check_columns:
		_checks.columns = check_columns
	var natural := _menu.get_combined_minimum_size()
	if natural.x <= 0.0 or natural.y <= 0.0:
		return
	var room := size * SCREEN_SHARE
	var fit := minf(MAX_SCALE, minf(room.x / natural.x, room.y / natural.y))
	_menu.size = natural
	_menu.scale = Vector2(fit, fit)
	_menu.position = ((size - natural * fit) / 2.0).round()


# The check covers the menu and frees itself on Back.
func _open_check(scene: PackedScene) -> void:
	var check := scene.instantiate()
	check.tree_exited.connect(_menu.show)
	_menu.hide()
	add_child(check)


# The House replaces the menu; reloading the page comes back here.
func _open_house(point: StringName) -> void:
	var house := HOUSE.instantiate()
	house.story_point = point
	get_tree().change_scene_to_node(house)


# The menu stands in for the House: the runner hides it while the chapter
# plays and shows it again afterwards.
func _enter_chapter(id: StringName) -> void:
	_status.text = ""
	if not ChapterRunner.of(get_tree()).enter(id, self):
		_status.text = "Couldn't start %s" % id


func _on_chapter_finished(result: Dictionary) -> void:
	var answer: String = result["answer"] if result["answer"] != "" else "none"
	_status.text = "Finished %s (answer: %s)" % [result["chapter"], answer]


func _on_chapter_left(id: StringName) -> void:
	_status.text = "Left %s without finishing" % id


func _on_test_save_pressed() -> void:
	var next: String = _game_state().next_chapter()
	if next != "":
		_game_state().record_chapter_result(ChapterResult.make(StringName(next)))


func _show_progress() -> void:
	var state: Node = _game_state()
	var finished: Array[String] = state.finished_chapters()
	if not state.last_save_ok:
		_save_status.text = "Couldn't save."
	elif finished.is_empty():
		_save_status.text = "Saved: none"
	else:
		_save_status.text = "Saved: " + ", ".join(finished)
	%TestSaveButton.disabled = state.next_chapter() == ""


# Looked up by path: the stand-alone script check doesn't know autoload names.
func _game_state() -> Node:
	return get_node("/root/GameState")
