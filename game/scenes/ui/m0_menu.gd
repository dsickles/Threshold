extends Control
## M0 test menu: a "tap to begin" screen, then one button per M0 check.
## Throwaway M0 scaffolding, not game code. The checks themselves come in
## DAS-67 (Smoothness), DAS-68 (Rhythm timing) and DAS-69 (Viewpoints).
## The Partner's rough first playable (DAS-73) also starts from here until the
## House exists; this menu stands in for the House around it.

const SMOOTHNESS_SCENE := "res://scenes/m0_checks/smoothness/smoothness_check.tscn"
const VIEWPOINTS_SCENE := "res://scenes/m0_checks/viewpoints_check.tscn"
const RHYTHM_CHECK := preload("res://scenes/ui/m0_rhythm_check.tscn")
const PARTNER := preload("res://scenes/chapters/partner/partner.tscn")

@onready var _begin_button: Button = %BeginButton
@onready var _menu: Control = %Menu
@onready var _status: Label = %Status


func _ready() -> void:
	_menu.hide()
	_begin_button.pressed.connect(_on_begin_pressed)
	%SmoothnessButton.pressed.connect(get_tree().change_scene_to_file.bind(SMOOTHNESS_SCENE))
	%RhythmButton.pressed.connect(_open_check.bind(RHYTHM_CHECK))
	%ViewpointsButton.pressed.connect(get_tree().change_scene_to_file.bind(VIEWPOINTS_SCENE))
	%PartnerButton.pressed.connect(_open_partner)


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


# Stub for the House hook: the real House warms here once the floor plan is
# settled. The chapter only reports that it finished.
func _open_partner() -> void:
	var partner := PARTNER.instantiate()
	partner.finished.connect(func() -> void:
		partner.queue_free()
		_status.text = "The Partner finished. (The House warming is stubbed for now.)")
	partner.tree_exited.connect(_menu.show)
	_status.text = ""
	_menu.hide()
	add_child(partner)
