extends Control
## One of the Anchor's two hold zones (DAS-138, DESIGN.md `balance`): a large
## outlined area low on one side of the screen, where a thumb rests. No
## label, no arrow, no icon. Idle it is only an outline in the border colour;
## while held it fills a little, so a held zone shows by more than colour.
## anchor.gd reads the touches and says when it is held.

const BORDER := Color("#3D3832")
const HELD_FILL := Color("#C4A574", 0.22)
const HELD_EDGE := Color("#C4A574", 0.7)
const IDLE_FILL := Color("#2A2520", 0.35)
const EDGE := 3.0
const CORNER := 24.0

var held := false:
	set(value):
		if held != value:
			held = value
			queue_redraw()


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE  # anchor.gd handles every touch.


func _draw() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = HELD_FILL if held else IDLE_FILL
	box.border_color = HELD_EDGE if held else BORDER
	box.set_border_width_all(int(EDGE) + (1 if held else 0))
	box.set_corner_radius_all(int(CORNER))
	draw_style_box(box, Rect2(Vector2.ZERO, size))
