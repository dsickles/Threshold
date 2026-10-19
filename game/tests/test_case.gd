class_name TestCase
extends Node
## Base for gameplay and logic tests. Each test file in game/tests/ is named
## test_*.gd, extends TestCase, and has methods named test_*. The runner
## (run_tests.gd) gives every test method a fresh copy of the file, added to
## the scene tree, so anything a test adds with add_scene() is freed after it.
## Test methods may await. See game/tests/README.md.

var _failures := PackedStringArray()


## Called before each test method. Override if a file needs setup.
func before_each() -> void:
	pass


## Called after each test method, even when it failed.
func after_each() -> void:
	pass


func failures() -> PackedStringArray:
	return _failures


# --- Checks. Each records a failure and carries on, so one run shows them all.

func check(ok: bool, what: String) -> bool:
	if not ok:
		_failures.append(what)
	return ok


func check_eq(actual: Variant, expected: Variant, what: String) -> bool:
	return check(actual == expected, "%s: got %s, expected %s" % [what, actual, expected])


func check_near(actual: float, expected: float, tolerance: float, what: String) -> bool:
	return check(absf(actual - expected) <= tolerance,
			"%s: got %s, expected %s (±%s)" % [what, actual, expected, tolerance])


# --- Helpers.

## Instantiates a scene under this test, so it is freed when the test ends.
## Its _ready runs now.
func add_scene(scene: PackedScene) -> Node:
	var node := scene.instantiate()
	add_child(node)
	return node


## Waits for `count` frames, so deferred calls, scene changes and queue_free
## take effect.
func frames(count: int = 1) -> void:
	for i in count:
		await get_tree().process_frame


## Sets the window size, to check a layout on a phone-sized screen. The
## runner sets 1280 x 720 (a laptop) before each test.
func set_screen(size: Vector2i) -> void:
	get_tree().root.size = size


## Taps the middle of a control the way a player would: a press then a release
## at that point on screen, sent through the viewport. So the tap only lands
## if the control is visible, enabled and not covered by something else.
func tap(control: Control) -> void:
	tap_at(control.get_global_rect().get_center())


## Taps a point in the game's own screen coordinates (after stretching).
func tap_at(point: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = point
	down.global_position = point
	down.pressed = true
	get_viewport().push_input(down, true)
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	get_viewport().push_input(up, true)
