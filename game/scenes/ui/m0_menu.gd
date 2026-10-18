extends Control
## M0 test menu: a "tap to begin" screen, then one button per M0 check.
## Throwaway M0 scaffolding, not game code. The checks themselves come in
## DAS-67 (Smoothness), DAS-68 (Rhythm timing) and DAS-69 (Viewpoints).

const SMOOTHNESS_SCENE := "res://scenes/m0_checks/smoothness/smoothness_check.tscn"
const RHYTHM_CHECK := preload("res://scenes/ui/m0_rhythm_check.tscn")

@onready var _begin_button: Button = %BeginButton
@onready var _menu: Control = %Menu
@onready var _status: Label = %Status


func _ready() -> void:
	_menu.hide()
	_begin_button.pressed.connect(_on_begin_pressed)
	%SmoothnessButton.pressed.connect(get_tree().change_scene_to_file.bind(SMOOTHNESS_SCENE))
	for button: Button in [%ViewpointsButton]:
		button.pressed.connect(_on_check_pressed.bind(button.text))
	%RhythmButton.pressed.connect(_open_check.bind(RHYTHM_CHECK))


# Browsers play no sound until the first tap, so everything starts from here.
func _on_begin_pressed() -> void:
	_begin_button.hide()
	_menu.show()


func _on_check_pressed(check_name: String) -> void:
	_status.text = "%s: placeholder, not built yet." % check_name


# The check covers the menu and frees itself on Back.
func _open_check(scene: PackedScene) -> void:
	var check := scene.instantiate()
	check.tree_exited.connect(_menu.show)
	_menu.hide()
	add_child(check)
