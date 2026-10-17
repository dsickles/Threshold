extends Control
## M0 test menu: a "tap to begin" screen, then one button per M0 check.
## Throwaway M0 scaffolding, not game code. The checks themselves come in
## DAS-67 (Smoothness), DAS-68 (Rhythm timing) and DAS-69 (Viewpoints).

@onready var _begin_button: Button = %BeginButton
@onready var _menu: Control = %Menu
@onready var _status: Label = %Status


func _ready() -> void:
	_menu.hide()
	_begin_button.pressed.connect(_on_begin_pressed)
	for button: Button in [%SmoothnessButton, %RhythmButton, %ViewpointsButton]:
		button.pressed.connect(_on_check_pressed.bind(button.text))


# Browsers play no sound until the first tap, so everything starts from here.
func _on_begin_pressed() -> void:
	_begin_button.hide()
	_menu.show()


func _on_check_pressed(check_name: String) -> void:
	_status.text = "%s: placeholder, not built yet." % check_name
