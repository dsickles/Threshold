extends Control
## UI style check (DAS-72): one line of each DESIGN.md text size and each
## button kind from the shared theme (assets/ui/threshold_theme.tres), shown
## at true size, so Dan can check them on a sideways iPhone. The bottom line
## says how much this screen shrinks the 1280x720 layout and what size body
## text comes out at, in points.
## Test scaffolding like the other M0 checks, not game code.

const MENU_SCENE := "res://scenes/ui/m0_menu.tscn"
## The shrink the theme's sizes were worked out for: a sideways iPhone 17 Pro
## in Safari with the toolbar hidden is 402 points tall, and the layout is
## 720 tall.
const THEME_SHOWN_SCALE := 402.0 / 720.0
const BODY_DESIGN_PT := 16.0

@onready var _measure: Label = %Measure


func _ready() -> void:
	%BackButton.pressed.connect(get_tree().change_scene_to_file.bind(MENU_SCENE))
	resized.connect(_show_measure)
	_show_measure()


## How big one layout unit is on the real screen, in points (CSS pixels in a
## browser): the window's size in points over the layout's visible size.
static func shown_scale(window_pixels: Vector2, pixels_per_point: float, layout: Vector2) -> float:
	if layout.y <= 0.0 or pixels_per_point <= 0.0:
		return 0.0
	return window_pixels.y / pixels_per_point / layout.y


func current_shown_scale() -> float:
	return shown_scale(Vector2(get_window().size), DisplayServer.screen_get_scale(),
			get_viewport().get_visible_rect().size)


func body_points() -> float:
	return get_theme_default_font_size() * current_shown_scale()


func _show_measure() -> void:
	if _measure == null:
		return
	_measure.text = "Shown at %d%% here, so body text is %.1f pt (DESIGN.md: %d pt at %d%%)." % [
		roundi(current_shown_scale() * 100.0), body_points(),
		roundi(BODY_DESIGN_PT), roundi(THEME_SHOWN_SCALE * 100.0)]


func probe_state() -> Dictionary:
	return {"shownScale": current_shown_scale(), "bodyPoints": body_points()}
