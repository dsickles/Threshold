extends Control
## The start of the game (DAS-95): "Tap to begin", then the House at the
## player's story point (the porch at dusk on a new game). Browsers play no
## sound until the first tap, so nothing plays before it.
##
## The M0 test menu is for tests only: "?probe&menu" in the address on the web
## (or "-- --menu" after Godot's own arguments elsewhere) opens it instead.
## "menu" alone does nothing, so a player can't stumble on it.
## While the game is playing, a phone held upright gets the "Turn your phone
## sideways" screen (TurnSideways); the test menu doesn't.

const HOUSE_SCENE := "res://scenes/house/house.tscn"
const MENU_SCENE := "res://scenes/ui/m0_menu.tscn"

@onready var _begin_button: Button = %BeginButton


func _ready() -> void:
	if wants_menu():
		# Deferred: the root is still adding this scene.
		get_tree().change_scene_to_file.call_deferred(MENU_SCENE)
		return
	_begin_button.pressed.connect(_on_begin_pressed)
	get_node("/root/TurnSideways").watch()


## Whether the address (or the command line) asks for the test menu.
static func wants_menu() -> bool:
	if OS.has_feature("web"):
		var asked: Variant = JavaScriptBridge.eval(
				"(p => p.has('probe') && p.has('menu'))(new URLSearchParams(window.location.search))", true)
		return bool(asked)
	return "--menu" in OS.get_cmdline_user_args()


func _on_begin_pressed() -> void:
	_begin_button.disabled = true
	get_tree().change_scene_to_file(HOUSE_SCENE)
