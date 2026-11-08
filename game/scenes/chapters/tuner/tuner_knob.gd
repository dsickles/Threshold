extends Control
## One of the Tuner's two knobs (DESIGN.md `knobs`): a large dial in the
## accent colour, with no label, scale or tooltip; the waveform is the only
## reading (UX-DR17). Drag round it to turn it, like a real knob: the value
## follows the angle the finger moves through, from 0 to 1 over SWEEP, with
## a stop at each end. A tap alone does nothing. Works the same with a finger
## or a mouse (touches arrive as clicks, the one tap scheme).

signal turned(value: float)

## The whole turn from 0 to 1, like a radio's dial: 300 degrees.
const SWEEP := deg_to_rad(300.0)
## Near the middle the angle jumps about, so moves there don't turn it.
const DEAD_MIDDLE := 0.2
const ACCENT := Color("#C4A574")
const SURFACE := Color("#2A2520")
const INK := Color("#F4EFE6")

var value := 0.0
## Until the first turn, the knob rocks a little, the only hint that it
## turns (no words).
var hinting := true

var _dragging := false
var _last_angle := 0.0
var _last_point := Vector2.ZERO
var _hint_time := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	focus_mode = FOCUS_NONE


func set_value(v: float) -> void:
	value = clampf(v, 0.0, 1.0)
	queue_redraw()


func _process(delta: float) -> void:
	if hinting:
		_hint_time += delta
		queue_redraw()


func radius() -> float:
	return minf(size.x, size.y) / 2.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_dragging = event.pressed
		if _dragging:
			_last_angle = _angle_at(event.position)
			_last_point = event.position
	elif event is InputEventMouseMotion and _dragging:
		accept_event()
		var point: Vector2 = event.position
		var crossed_middle := _passes_middle(_last_point, point)
		var angle := _angle_at(point)
		var moved := wrapf(angle - _last_angle, -PI, PI)
		_last_angle = angle
		_last_point = point
		# Through the middle the angle flips: count only the turning done
		# outside it, so a drag across the knob never jumps it (Hopper,
		# DAS-135 round 1).
		if crossed_middle:
			return
		if is_zero_approx(moved):
			return
		hinting = false
		var before := value
		set_value(value + moved / SWEEP)
		if value != before:
			turned.emit(value)


# True if the straight move from `a` to `b` touches the knob's middle.
func _passes_middle(a: Vector2, b: Vector2) -> bool:
	var middle := size / 2.0
	var closest := Geometry2D.get_closest_point_to_segment(middle, a, b)
	return closest.distance_to(middle) < radius() * DEAD_MIDDLE


func _angle_at(point: Vector2) -> float:
	return (point - size / 2.0).angle()


## Stops a drag that is under way (the tab was hidden, say).
func let_go() -> void:
	_dragging = false


func _draw() -> void:
	var middle := size / 2.0
	var r := radius()
	# The rocking hint: a few degrees either way, then still for a moment.
	var rock := 0.0
	if hinting:
		var phase := fmod(_hint_time, 2.4)
		rock = sin(phase / 0.8 * TAU) * deg_to_rad(9.0) if phase < 0.8 else 0.0
	# 0 is down and to the left, 1 down and to the right, like a radio.
	var angle := PI / 2.0 + (TAU - SWEEP) / 2.0 + value * SWEEP + rock
	draw_circle(middle, r, SURFACE)
	draw_arc(middle, r - 3.0, 0.0, TAU, 64, ACCENT, 4.0, true)
	# Grip ridges round the rim, so it reads as a knob and shows it turning.
	for k in 24:
		var a := angle + k * TAU / 24.0
		var dir := Vector2.from_angle(a)
		draw_line(middle + dir * (r - 14.0), middle + dir * (r - 6.0), ACCENT.darkened(0.35), 2.0, true)
	draw_circle(middle, r * 0.62, SURFACE.lightened(0.06))
	var pointer := Vector2.from_angle(angle)
	draw_line(middle + pointer * r * 0.18, middle + pointer * r * 0.58, INK, 6.0, true)
	draw_circle(middle + pointer * r * 0.58, 3.0, INK)
