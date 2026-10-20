extends Control
## M0 test menu: a "tap to begin" screen, then one button per M0 check.
## Throwaway M0 scaffolding, not game code. The checks themselves come in
## DAS-67 (Smoothness), DAS-68 (Rhythm timing) and DAS-69 (Viewpoints).
## Until the House exists, the menu also stands in for it when starting a
## chapter through the chapter runner (DAS-75). "Test save" records the next
## story chapter as finished, so saving can be checked on a phone before any
## story chapter is playable (DAS-74); the line under it shows what is saved.

const SMOOTHNESS_SCENE := "res://scenes/m0_checks/smoothness/smoothness_check.tscn"
const VIEWPOINTS_SCENE := "res://scenes/m0_checks/viewpoints_check.tscn"
const RHYTHM_CHECK := preload("res://scenes/ui/m0_rhythm_check.tscn")

@onready var _begin_button: Button = %BeginButton
@onready var _menu: Control = %Menu
@onready var _status: Label = %Status
@onready var _save_status: Label = %SaveStatus


func _ready() -> void:
	_menu.hide()
	_begin_button.pressed.connect(_on_begin_pressed)
	%SmoothnessButton.pressed.connect(get_tree().change_scene_to_file.bind(SMOOTHNESS_SCENE))
	%RhythmButton.pressed.connect(_open_check.bind(RHYTHM_CHECK))
	%ViewpointsButton.pressed.connect(get_tree().change_scene_to_file.bind(VIEWPOINTS_SCENE))
	%StandInButton.pressed.connect(_enter_chapter.bind(ChapterList.STAND_IN))
	var chapters := ChapterRunner.of(get_tree())
	chapters.chapter_finished.connect(_on_chapter_finished)
	chapters.chapter_left.connect(_on_chapter_left)
	%TestSaveButton.pressed.connect(_on_test_save_pressed)
	%ClearSaveButton.pressed.connect(_game_state().start_new)
	_game_state().progress_changed.connect(_show_progress)
	_game_state().save_failed.connect(_show_progress)
	_show_progress()


# Browsers play no sound until the first tap, so everything starts from here.
func _on_begin_pressed() -> void:
	_begin_button.hide()
	_menu.show()


# The check covers the menu and frees itself on Back.
func _open_check(scene: PackedScene) -> void:
	var check := scene.instantiate()
	check.tree_exited.connect(_menu.show)
	_menu.hide()
	add_child(check)


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
