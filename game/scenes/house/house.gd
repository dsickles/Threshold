extends Node3D
## The House in gray-box (DAS-93): the M1 rooms as simple shapes, lit by lamps
## and ordinary fog only, and moved through by tap (ADR-0008). Every view
## shows a ring for each doorway in its room that can be gone through and for
## the room's other wall views; tapping one glides there in 2.0 s, and the
## next view's rings appear on arrival. A ring that is off screen pins to the
## screen edge with an arrow. A ring through a doorway (to another room) is
## solid; a ring to a wall view in the same room is an outline. Each has a
## short label under it saying where it goes. A short drag looks around a
## little. There is no back button.
##
## Which doors are open, shut or boxed in, and which room the player arrives
## in, come from the core table (HouseTable) at the story point. The rooms,
## doors, furniture and views are data in house_layout.gd.
##
## The opening flow (DAS-95): the game's title opens the House at the
## player's own story point. The opening beat plays the first time the player
## reaches the living room's doorway view (L1) on moving day; when it ends the
## House is at "after the opening beat" (the hall and bedroom open, the
## bedside lamp lit). The chapter objects work by close-up (ADR-0008): tap
## one to glide to its close-up, tap it again for its one action, tap
## anywhere else to step back to the view it was opened from. The record
## player's action starts the Partner and the bedside lamp's (turning it off)
## starts the Protector, through the chapter runner; when the chapter
## finishes the House comes back at the next story point, in the room it
## arrives in. House objects and moods come in DAS-96.

const ACCENT := Color(0.769, 0.647, 0.455)
const INK := Color(0.957, 0.937, 0.902)
const SURFACE := Color(0.11, 0.098, 0.086)
const GLIDE_SECONDS := 2.0
## The camera's lens: how tall a slice of the world it sees, in degrees (the
## width follows the screen's shape).
const LENS_FOV := 70.0
const RING_SIZE := 110.0
## Rings are never smaller than this on the real screen (points on a phone),
## comfortably over the 44px minimum, so they grow on an upright phone.
const RING_MIN_REAL := 64.0
const EDGE_MARGIN := 24.0
const RING_GAP := 16.0
## The label sits this far under its ring, in type this share of the ring.
const LABEL_GAP := 6.0
const LABEL_SHARE := 0.28
## How far a drag can turn the view, and how much per pixel dragged.
const LOOK_YAW_MAX := deg_to_rad(20.0)
const LOOK_PITCH_MAX := deg_to_rad(10.0)
const LOOK_PER_PIXEL := deg_to_rad(0.12)
const DOOR_OPEN_ANGLE := deg_to_rad(80.0)
const BOX_SIZE := 0.5
## A press and lift closer together than this (in screen units) is a tap, not
## a look-drag.
const TAP_SLOP := 16.0
## Where the opening beat plays.
const OPENING_BEAT_VIEW := "L1"
const OpeningBeat := preload("res://scenes/house/opening_beat.gd")
const WALL_THICKNESS := 0.12

const COLOURS := {
	"wall": Color(0.62, 0.6, 0.57),
	"floor": Color(0.36, 0.32, 0.28),
	"ceiling": Color(0.72, 0.7, 0.67),
	"porch": Color(0.3, 0.29, 0.28),
	"ground": Color(0.12, 0.13, 0.12),
	"door": Color(0.48, 0.4, 0.32),
	"box": Color(0.62, 0.5, 0.34),
	"wood": Color(0.45, 0.36, 0.28),
	"dark": Color(0.14, 0.13, 0.13),
	"fabric": Color(0.42, 0.42, 0.45),
	"granite": Color(0.5, 0.49, 0.47),
	"steel": Color(0.68, 0.69, 0.7),
	"white": Color(0.82, 0.82, 0.8),
	"leather": Color(0.36, 0.22, 0.14),
	"glass": Color(0.5, 0.56, 0.62),
	"shade": Color(0.72, 0.68, 0.6),
}
const LAMP_GLOW := Color(1.0, 0.86, 0.62)
const DUSK := Color(0.2, 0.22, 0.34)

## The story point the House shows. Set before adding the House to the tree
## (the M0 menu does); left empty, it is the player's own point
## (GameState.house_point()). `door_states`, if set, wins over its doors.
var story_point: StringName = &""
var door_states: Dictionary = {}
## How long a glide takes. Browser tests that aren't about the House can make
## it quicker ("&glide=" in the address, web_test_probe.gd).
var glide_seconds := GLIDE_SECONDS

var _current := ""
var _camera: Camera3D
var _tween: Tween
# The view's own camera place; a look-drag turns the camera away from it.
var _base := Transform3D.IDENTITY
var _yaw := 0.0
var _pitch := 0.0
var _rings: Array[Button] = []
var _ring_data: Array[Dictionary] = []
var _ring_root: Control
# Ring looks: [resting, pressed] for a doorway ring and for a wall ring.
var _door_styles: Array[StyleBoxFlat] = []
var _wall_styles: Array[StyleBoxFlat] = []
var _label_style: StyleBoxFlat
var _materials := {}
var _door_pivots := {}
# Each door's built nodes (its panel and any stack of boxes), so a new story
# point can rebuild them.
var _door_nodes := {}
var _props: Node3D
var _world_env: WorldEnvironment
var _ui_layer: CanvasLayer
# The chapter objects: their tap areas (invisible buttons over them) and the
# record player's arm and the bedside lamp's light and shade.
var _object_root: Control
var _object_buttons := {}
var _arm: Node3D
var _arm_rest := Transform3D.IDENTITY
var _needle: Tween
var _lamp_light: OmniLight3D
var _shade: MeshInstance3D
# The chapter object whose close-up the camera is at (or gliding to), or "".
# `_current` stays the view it was opened from.
var _close_up := ""
# True from a chapter object's action until its chapter has come and gone.
var _acting := false
var _playing_chapter: StringName = &""
var _beat: Control
var _press_at := Vector2.INF


func _ready() -> void:
	if story_point == &"":
		# The GameState autoload, looked up by path as the M0 menu does.
		story_point = get_node("/root/GameState").house_point()
	if not story_point in HouseTable.POINTS:
		push_error("House: no story point '%s'; showing the start." % story_point)
		story_point = HouseTable.START
	if door_states.is_empty():
		door_states = HouseTable.doors(story_point)
	glide_seconds = get_tree().root.get_meta("house_glide_seconds", glide_seconds)
	_build_world()
	_camera = Camera3D.new()
	_camera.fov = LENS_FOV
	_camera.near = 0.05
	add_child(_camera)
	_build_ui()
	visibility_changed.connect(_on_visibility_changed)
	var chapters := ChapterRunner.of(get_tree())
	chapters.chapter_finished.connect(_on_chapter_finished)
	chapters.chapter_left.connect(_on_chapter_left)
	# Deferred: the 3D view takes in its new size during the same frame, after
	# the signal, so placing straight away would use the old projection.
	get_viewport().size_changed.connect(_place_rings, CONNECT_DEFERRED)
	# The point's arrival room, at its doorway view.
	var arrival := String(HouseTable.arrive_in(story_point))
	_current = HouseLayout.ROOMS.get(arrival, {}).get("doorway_view", "")
	if _current == "":
		push_error("House: '%s' arrives in %s, which has no doorway view; starting in the living room." % [story_point, arrival])
		_current = HouseLayout.ROOMS.living_room.doorway_view
	_set_base(HouseLayout.view_transform(_current))
	_arrive()


# Keep the view about as wide on a tall phone as on a laptop. Set before
# rings are placed, so a turn of the phone places them with the new shape.
func _fit_camera() -> void:
	var size := get_viewport().get_visible_rect().size
	_camera.keep_aspect = Camera3D.KEEP_WIDTH if size.y > size.x else Camera3D.KEEP_HEIGHT


## Whether a glide is under way.
func is_gliding() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()


## For the browser tests (web_test_probe.gd): the view, whether a glide is
## under way, each ring with the view it leads to, its label and its centre,
## the story point, the close-up (if any), each chapter object that can be
## tapped now with its centre, and the opening beat while it plays.
func probe_state() -> Dictionary:
	var rings: Array[Dictionary] = []
	for i in _ring_data.size():
		var centre := _rings[i].get_global_transform_with_canvas() * (_rings[i].size / 2.0)
		rings.append({"target": _ring_data[i].target, "label": ring_label(_rings[i]).text,
				"doorway": _ring_data[i].door != "", "x": centre.x, "y": centre.y})
	var objects: Array[Dictionary] = []
	for id: String in _object_buttons:
		var button: Button = _object_buttons[id]
		if button.visible:
			var centre := button.get_global_transform_with_canvas() * (button.size / 2.0)
			objects.append({"id": id, "x": centre.x, "y": centre.y})
	return {"view": _current, "gliding": is_gliding(), "rings": rings, "point": String(story_point),
			"closeUp": _close_up, "objects": objects,
			"beat": _beat.probe_state() if _beat else null}


## The chapter object whose close-up the camera is at, or "".
func close_up() -> String:
	return _close_up


## A chapter object's tap area (an invisible button over it).
func object_button(object_id: String) -> Button:
	return _object_buttons.get(object_id)


## The opening beat while it plays, or null.
func opening_beat() -> Control:
	return _beat


# --- Moving.

func _go_to(target: String, door_id: String) -> void:
	if target == _current or is_gliding():
		return
	var from := _camera.global_transform
	var to := HouseLayout.view_transform(target)
	# Through a doorway, the glide passes through its middle, square to the
	# wall, rather than cutting through the wall beside it.
	var via := Vector3.INF
	var across := Vector3.ZERO
	if door_id != "":
		var here := HouseLayout.room_at(Vector2(from.origin.x, from.origin.z))
		var there := HouseLayout.room_at(Vector2(to.origin.x, to.origin.z))
		if here != there:
			var at: Vector2 = HouseLayout.DOORS[door_id].at
			via = Vector3(at.x, HouseLayout.EYE_HEIGHT, at.y)
			across = Vector3(0.0, 0.0, signf(to.origin.z - via.z)) if _door_along_x(door_id) \
					else Vector3(signf(to.origin.x - via.x), 0.0, 0.0)
	if door_id == "front_door":
		_open_door(door_id)
	_current = target
	_glide(to, via, across)


# Glides the camera from where it is to `to`, through `via` if it is set.
func _glide(to: Transform3D, via := Vector3.INF, across := Vector3.ZERO) -> void:
	var from := _camera.global_transform
	_yaw = 0.0
	_pitch = 0.0
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_apply_glide.bind(from, to, via, across), 0.0, 1.0, glide_seconds)
	_tween.finished.connect(_arrive)
	# Rings (and chapter objects' tap areas) hide during the glide and come
	# back on arrival, so a glide is never turned mid-way through a wall.
	_ring_data = []
	_show_rings()


# At a view: its rings, and the opening beat on first arrival at L1. At a
# close-up: no rings, only the object.
func _arrive() -> void:
	_ring_data = HouseLayout.rings_for(_current, door_states)
	if _close_up != "":
		_ring_data.clear()
	_show_rings()
	_start_opening_beat_if_due()


func _apply_glide(t: float, from: Transform3D, to: Transform3D, via: Vector3, across: Vector3) -> void:
	var origin := from.origin.lerp(to.origin, t)
	if via != Vector3.INF:
		origin = _through(t, from.origin, via, across, to.origin)
	var turn := from.basis.get_rotation_quaternion().slerp(to.basis.get_rotation_quaternion(), t)
	_set_base(Transform3D(Basis(turn), origin))


# A smooth path from `a` to `b` through the doorway at `via`, crossing it in
# direction `across`. Time is shared by distance, so the camera keeps an even
# pace on both sides of the door and never backs up.
static func _through(t: float, a: Vector3, via: Vector3, across: Vector3, b: Vector3) -> Vector3:
	var first := a.distance_to(via)
	var second := via.distance_to(b)
	var travelled := t * (first + second)
	if travelled <= first and first > 0.0:
		return _hermite(travelled / first, a, via - a, via, across * first)
	if second <= 0.0:
		return b
	return _hermite((travelled - first) / second, via, across * second, b, b - via)


static func _hermite(u: float, p0: Vector3, m0: Vector3, p1: Vector3, m1: Vector3) -> Vector3:
	var u2 := u * u
	var u3 := u2 * u
	return (2.0 * u3 - 3.0 * u2 + 1.0) * p0 + (u3 - 2.0 * u2 + u) * m0 \
			+ (-2.0 * u3 + 3.0 * u2) * p1 + (u3 - u2) * m1


func _set_base(base: Transform3D) -> void:
	_base = base
	_camera.global_transform = _base * Transform3D(Basis.from_euler(Vector3(_pitch, _yaw, 0.0)))


# A short drag looks around a little, never far. Taps on rings and chapter
# objects are buttons, so only presses that start off them arrive here. At a
# close-up there is no looking around: a tap off the object steps back.
func _unhandled_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press and press.button_index == MOUSE_BUTTON_LEFT:
		if press.pressed:
			_press_at = press.position
		elif _close_up != "" and press.position.distance_to(_press_at) < TAP_SLOP:
			step_back()
		return
	var motion := event as InputEventMouseMotion
	if motion == null or not (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) or is_gliding() \
			or _close_up != "":
		return
	_yaw = clampf(_yaw - motion.relative.x * LOOK_PER_PIXEL, -LOOK_YAW_MAX, LOOK_YAW_MAX)
	_pitch = clampf(_pitch - motion.relative.y * LOOK_PER_PIXEL, -LOOK_PITCH_MAX, LOOK_PITCH_MAX)
	_set_base(_base)
	_place_rings()


func _open_door(door_id: String) -> void:
	var pivot: Node3D = _door_pivots.get(door_id)
	if pivot == null:
		return
	create_tween().tween_property(pivot, "rotation:y", _open_angle(door_id), 0.6)


# --- Rings.

func _show_rings() -> void:
	while _rings.size() < _ring_data.size():
		_rings.append(_make_ring())
	for i in _rings.size():
		var ring := _rings[i]
		ring.visible = i < _ring_data.size()
		if ring.visible:
			_style_ring(ring, _ring_data[i])
	_place_rings()


func _make_ring() -> Button:
	var ring := Button.new()
	# Tap only: no keyboard focus, and hover looks the same as resting.
	ring.focus_mode = Control.FOCUS_NONE
	ring.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	ring.add_theme_font_size_override("font_size", 56)
	ring.pressed.connect(_on_ring_pressed.bind(ring))
	# The label under the ring. Taps go past it, as they do anywhere that
	# isn't a ring.
	var label := Label.new()
	label.name = "Label"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_stylebox_override("normal", _label_style)
	label.add_theme_color_override("font_color", INK)
	ring.add_child(label)
	_ring_root.add_child(ring)
	return ring


# A doorway ring is solid with a dark arrow; a wall ring is an outline with a
# light one. Either way, hovered looks the same as resting.
func _style_ring(ring: Button, data: Dictionary) -> void:
	var doorway: bool = data.door != ""
	var styles := _door_styles if doorway else _wall_styles
	for state in ["normal", "hover"]:
		ring.add_theme_stylebox_override(state, styles[0])
	for state in ["pressed", "hover_pressed"]:
		ring.add_theme_stylebox_override(state, styles[1])
	for colour in ["font_color", "font_hover_color", "font_pressed_color",
			"font_hover_pressed_color", "font_focus_color"]:
		ring.add_theme_color_override(colour, SURFACE if doorway else INK)
	ring_label(ring).text = HouseLayout.VIEWS[data.target].label


## The label under a ring.
func ring_label(ring: Button) -> Label:
	return ring.get_node("Label") as Label


func _on_ring_pressed(ring: Button) -> void:
	var index := _rings.find(ring)
	if index < 0 or index >= _ring_data.size():
		return
	_go_to(_ring_data[index].target, _ring_data[index].door)


## The ring (a visible Button) that leads to a view, or null.
func ring_to(view_id: String) -> Button:
	for i in _ring_data.size():
		if _ring_data[i].target == view_id:
			return _rings[i]
	return null


# Each ring is drawn over what it leads to, so it stays at least 44px however
# far away that is. One out of view pins to the screen edge on its side, with
# an arrow, so there is always somewhere visible to go. A ring's label sits
# under it, or beside it (towards the middle) when it is pinned, so pinned
# rings still stack closely. Each ring and its label are kept on screen
# together, and rings that would cover each other (or each other's labels)
# are pushed apart.
func _place_rings() -> void:
	_fit_camera()
	var screen := get_viewport().get_visible_rect()
	var ring_size := _ring_size()
	var half := ring_size / 2.0
	var area := Rect2(Vector2(EDGE_MARGIN + half, EDGE_MARGIN + half),
			screen.size - Vector2.ONE * 2.0 * (EDGE_MARGIN + half))
	var pinned_left: Array[Button] = []
	var pinned_right: Array[Button] = []
	var shown: Array[Button] = []
	# Each ring's footprint (ring and label), relative to the ring's position.
	var feet := {}
	for i in _ring_data.size():
		var ring := _rings[i]
		# Laid out from these sizes rather than the ring's and label's own,
		# which can lag a frame behind a turn of the phone.
		var disc := Vector2.ONE * ring_size
		ring.custom_minimum_size = disc
		ring.update_minimum_size()
		ring.size = disc
		var at: Vector3 = _ring_data[i].at
		var point := _camera.unproject_position(at)
		if _camera.is_position_behind(at):
			var local := _camera.global_transform.affine_inverse() * at
			point = Vector2(screen.size.x if local.x > 0.0 else 0.0, screen.size.y / 2.0)
		ring.text = ""
		var label := ring_label(ring)
		var words := _label_size(label, roundi(ring_size * LABEL_SHARE))
		label.size = words
		label.position = Vector2((ring_size - words.x) / 2.0, ring_size + LABEL_GAP)
		# Off to a side: pinned to that edge with an arrow, its label beside
		# it. Just above or below the screen (after a look-drag): held at the
		# edge.
		if point.x < area.position.x or point.x > area.end.x:
			var right := point.x > screen.size.x / 2.0
			ring.text = "›" if right else "‹"
			(pinned_right if right else pinned_left).append(ring)
			label.position = Vector2(-LABEL_GAP - words.x if right else ring_size + LABEL_GAP,
					(ring_size - words.y) / 2.0)
		feet[ring] = Rect2(Vector2.ZERO, disc).merge(Rect2(label.position, words))
		ring.position = point - disc / 2.0
		shown.append(ring)
	# Where each ring may go so that it and its label stay on screen.
	var bounds := {}
	for ring in shown:
		var foot: Rect2 = feet[ring]
		var lowest := Vector2.ONE * EDGE_MARGIN - foot.position
		var highest := screen.size - Vector2.ONE * EDGE_MARGIN - foot.end
		bounds[ring] = [lowest, highest]
		ring.position = ring.position.clamp(lowest, highest)
	for side in [pinned_left, pinned_right]:
		_spread(side, feet, bounds)
	_push_apart(shown, feet, bounds)
	_place_objects()


# A label's size at a font size. Measured here rather than asked of the
# label, which only takes in a new font size on the next frame.
func _label_size(label: Label, font_size: int) -> Vector2:
	label.add_theme_font_size_override("font_size", font_size)
	label.update_minimum_size()
	var font := label.get_theme_font("font")
	return font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) \
			+ _label_style.get_minimum_size()


# The ring's size in the game's units: RING_SIZE, or more where the game is
# drawn small (an upright phone shows the whole 1280-wide view in 390 points).
func _ring_size() -> float:
	# The window is in device pixels; a phone's screen scale turns them into
	# points (3 on most iPhones).
	var points := Vector2(get_window().size) / maxf(DisplayServer.screen_get_scale(), 1.0)
	var view := get_viewport().get_visible_rect().size
	if points.x <= 0.0 or view.x <= 0.0:
		return RING_SIZE
	return maxf(RING_SIZE, RING_MIN_REAL * view.x / points.x)


# Pinned rings on the same edge would sit on top of each other, so stack them.
func _spread(rings: Array[Button], feet: Dictionary, bounds: Dictionary) -> void:
	if rings.size() < 2:
		return
	rings.sort_custom(func(a: Button, b: Button) -> bool: return a.position.y < b.position.y)
	var tall: float = (feet[rings[0]] as Rect2).size.y
	var gap := tall + RING_GAP
	var mid := 0.0
	for ring in rings:
		mid += ring.position.y
	mid /= rings.size()
	var lowest: float = bounds[rings[0]][0].y
	var highest: float = bounds[rings[0]][1].y - gap * (rings.size() - 1)
	var top := clampf(mid - gap * (rings.size() - 1) / 2.0, lowest, maxf(lowest, highest))
	for k in rings.size():
		rings[k].position.y = top + gap * k


# Two things can sit close together on screen (a doorway and a wall beside
# it); their rings are nudged apart, labels and all, so both stay tappable
# and readable.
func _push_apart(rings: Array[Button], feet: Dictionary, bounds: Dictionary) -> void:
	for pass_index in 40:
		var moved := false
		for i in rings.size():
			for j in range(i + 1, rings.size()):
				var a := rings[i]
				var b := rings[j]
				var foot_a := Rect2(a.position + feet[a].position, feet[a].size).grow(RING_GAP / 2.0)
				var foot_b := Rect2(b.position + feet[b].position, feet[b].size).grow(RING_GAP / 2.0)
				if not foot_a.intersects(foot_b):
					continue
				var overlap := foot_a.intersection(foot_b).size
				var away := foot_b.get_center() - foot_a.get_center()
				var across := Vector2(overlap.x / 2.0 * (1.0 if away.x >= 0.0 else -1.0), 0.0)
				var up_down := Vector2(0.0, overlap.y / 2.0 * (1.0 if away.y >= 0.0 else -1.0))
				# Move along whichever direction needs less, unless the screen
				# edge stops that; then the other way.
				var pushes := [across, up_down] if overlap.x < overlap.y else [up_down, across]
				var start_a := a.position
				var start_b := b.position
				for push: Vector2 in pushes:
					a.position = (start_a - push).clamp(bounds[a][0], bounds[a][1])
					b.position = (start_b + push).clamp(bounds[b][0], bounds[b][1])
					if (b.position - a.position - (start_b - start_a)).length() >= push.length() * 1.9:
						break
				moved = true
		if not moved:
			return


# --- Building the gray-box House.

func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = DUSK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.48, 0.5)
	env.ambient_light_energy = 0.45
	# Ordinary depth fog only: no volumetric fog, which the browser can't run.
	env.fog_enabled = true
	env.fog_light_color = DUSK
	env.fog_density = 0.012
	env.volumetric_fog_enabled = false
	_world_env = WorldEnvironment.new()
	_world_env.environment = env
	add_child(_world_env)

	# The layers in game-architecture.md 2.2.
	var base := _layer("BaseLayer")
	var props := _layer("PropLayer")
	var lighting := _layer("LightingLayer")

	_add_box(base, Vector3(8.0, -0.06, 6.5), Vector3(60.0, 0.1, 60.0), "ground")
	for room: String in HouseLayout.ROOMS:
		for rect: Rect2 in HouseLayout.ROOMS[room].rects:
			var centre := rect.get_center()
			var floor_colour := "porch" if room == "porch" else "floor"
			_add_box(base, Vector3(centre.x, -0.05, centre.y), Vector3(rect.size.x, 0.1, rect.size.y),
					floor_colour, "Floor_%s" % room)
			_add_box(base, Vector3(centre.x, HouseLayout.WALL_HEIGHT + 0.05, centre.y),
					Vector3(rect.size.x, 0.1, rect.size.y), "ceiling", "Ceiling_%s" % room)
	for wall: Dictionary in HouseLayout.WALLS:
		_add_wall(base, wall)
	# The porch: two posts at its front corners, under the roof.
	var porch: Rect2 = HouseLayout.ROOMS.porch.rects[0]
	for x in [porch.position.x + 0.15, porch.end.x - 0.15]:
		_add_box(base, Vector3(x, HouseLayout.WALL_HEIGHT / 2.0, porch.end.y - 0.15),
				Vector3(0.15, HouseLayout.WALL_HEIGHT, 0.15), "wood")

	for item: Array in HouseLayout.FURNITURE:
		var mesh := _add_box(props, item[2], item[3], item[4], "Furniture_%s" % item[0])
		mesh.rotation.y = deg_to_rad(item[5])
	_props = props
	for door_id: String in HouseLayout.DOORS:
		_add_door(props, door_id)
	_add_chapter_objects(props, lighting)

	_add_lights(lighting)


func _layer(layer_name: String) -> Node3D:
	var layer := Node3D.new()
	layer.name = layer_name
	add_child(layer)
	return layer


# A wall is solid except for its openings; each opening keeps the wall below
# its bottom and above its top, and a window gets a pane of glass.
func _add_wall(parent: Node3D, wall: Dictionary) -> void:
	var from: Vector2 = wall.from
	var to: Vector2 = wall.to
	var along_x := is_equal_approx(from.y, to.y)
	var start := from.x if along_x else from.y
	var end := to.x if along_x else to.y
	var openings: Array = wall.openings.duplicate()
	openings.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var cursor := start
	for opening: Array in openings:
		_wall_piece(parent, wall, cursor, opening[0], 0.0, HouseLayout.WALL_HEIGHT)
		if opening[2] > 0.0:
			_wall_piece(parent, wall, opening[0], opening[1], 0.0, opening[2])
		_wall_piece(parent, wall, opening[0], opening[1], opening[3], HouseLayout.WALL_HEIGHT)
		if opening.size() > 4 and opening[4] == "glass":
			_wall_piece(parent, wall, opening[0], opening[1], opening[2], opening[3], "glass", 0.03)
		cursor = opening[1]
	_wall_piece(parent, wall, cursor, end, 0.0, HouseLayout.WALL_HEIGHT)


func _wall_piece(parent: Node3D, wall: Dictionary, a: float, b: float, bottom: float, top: float,
		colour := "wall", thickness := WALL_THICKNESS) -> void:
	if b - a <= 0.001 or top - bottom <= 0.001:
		return
	var from: Vector2 = wall.from
	var along_x := is_equal_approx(from.y, wall.to.y)
	var mid := (a + b) / 2.0
	var height := (bottom + top) / 2.0
	if along_x:
		_add_box(parent, Vector3(mid, height, from.y), Vector3(b - a, top - bottom, thickness), colour)
	else:
		_add_box(parent, Vector3(from.x, height, mid), Vector3(thickness, top - bottom, b - a), colour)


# A doorway with a door gets a panel on a hinge, swung open or shut; one that
# is boxed in gets a stack of moving boxes on the side the floor plan puts it.
func _add_door(parent: Node3D, door_id: String) -> void:
	var door: Dictionary = HouseLayout.DOORS[door_id]
	var state: String = door_states.get(door_id, HouseLayout.SHUT)
	var along_x := _door_along_x(door_id)
	var at: Vector2 = door.at
	var width: float = door.width
	_door_nodes[door_id] = []
	if door.get("panel", false):
		var pivot := Node3D.new()
		pivot.name = "Door_%s" % door_id
		_door_nodes[door_id].append(pivot)
		# Hinged at the doorway's west (or north) end, or its east (or south)
		# end when "hinge" says "end".
		var side := 1.0 if door.get("hinge", "") == "end" else -1.0
		pivot.position = Vector3(at.x + side * width / 2.0, 0.0, at.y) if along_x \
				else Vector3(at.x, 0.0, at.y + side * width / 2.0)
		parent.add_child(pivot)
		var panel_size := Vector3(width, HouseLayout.DOOR_HEIGHT, 0.05) if along_x \
				else Vector3(0.05, HouseLayout.DOOR_HEIGHT, width)
		var offset := Vector3(-side * width / 2.0, HouseLayout.DOOR_HEIGHT / 2.0, 0.0) if along_x \
				else Vector3(0.0, HouseLayout.DOOR_HEIGHT / 2.0, -side * width / 2.0)
		_add_box(pivot, offset, panel_size, "door")
		# The front door is shut until the player goes in; it opens then.
		if state == HouseLayout.OPEN and door_id != "front_door":
			pivot.rotation.y = _open_angle(door_id)
		_door_pivots[door_id] = pivot
	if state == HouseLayout.BOXED:
		_add_box_stack(parent, door_id)


# Whether the doorway lies along x (in a wall running east-west).
func _door_along_x(door_id: String) -> bool:
	var door: Dictionary = HouseLayout.DOORS[door_id]
	for wall: Dictionary in HouseLayout.WALLS:
		var from: Vector2 = wall.from
		var to: Vector2 = wall.to
		if is_equal_approx(from.y, to.y) and is_equal_approx(from.y, door.at.y) \
				and door.at.x > from.x and door.at.x < to.x:
			return true
	return false


# Which way a door swings: into room "b".
func _open_angle(door_id: String) -> float:
	var door: Dictionary = HouseLayout.DOORS[door_id]
	var into: Vector2 = HouseLayout.ROOMS[door.b].rects[0].get_center() - door.at
	# A panel hinged at the other end swings the other way to open into "b".
	var flip := -1.0 if door.get("hinge", "") == "end" else 1.0
	var angle: float = deg_to_rad(door.get("swing", rad_to_deg(DOOR_OPEN_ANGLE)))
	if _door_along_x(door_id):
		return flip * (angle if into.y < 0.0 else -angle)
	return flip * (angle if into.x > 0.0 else -angle)


func _add_box_stack(parent: Node3D, door_id: String) -> void:
	var door: Dictionary = HouseLayout.DOORS[door_id]
	var stack := Node3D.new()
	stack.name = "Boxes_%s" % door_id
	parent.add_child(stack)
	_door_nodes[door_id].append(stack)
	var along_x := _door_along_x(door_id)
	var centre: Vector2 = door.at
	var side: String = door.get("boxes", "")
	if side != "":
		var into: Vector2 = HouseLayout.ROOMS[door[side]].rects[0].get_center() - door.at
		var normal := Vector2(0.0, signf(into.y)) if along_x else Vector2(signf(into.x), 0.0)
		centre += normal * (BOX_SIZE / 2.0 + 0.1)
	var columns := maxi(1, floori(door.width / (BOX_SIZE + 0.05)))
	var heights := [3, 2, 3, 2]
	for c in columns:
		var across := (c - (columns - 1) / 2.0) * (BOX_SIZE + 0.05)
		var spot := centre + (Vector2(across, 0.0) if along_x else Vector2(0.0, across))
		for level in heights[c % heights.size()]:
			var box := _add_box(stack, Vector3(spot.x, BOX_SIZE * (level + 0.5), spot.y),
					Vector3.ONE * BOX_SIZE * (0.92 if level % 2 else 1.0), "box")
			box.rotation.y = deg_to_rad(((c * 7 + level * 13) % 11) - 5.0)


# Lamp light only: a bare bulb in each room that can be seen, and the porch
# light. No shadows, to keep phones smooth.
func _add_lights(parent: Node3D) -> void:
	for room: String in HouseLayout.ROOMS:
		if HouseLayout.ROOMS[room].doorway_view == "" or room == "porch":
			continue
		var rect: Rect2 = HouseLayout.ROOMS[room].rects[-1]
		var centre := rect.get_center()
		var light := OmniLight3D.new()
		light.name = "Lamp_%s" % room
		light.position = Vector3(centre.x, 2.4, centre.y)
		light.light_color = Color(1.0, 0.88, 0.72)
		light.light_energy = 1.1
		light.omni_range = rect.size.length() * 0.75 + 1.0
		light.shadow_enabled = false
		parent.add_child(light)
		var bulb := SphereMesh.new()
		bulb.radius = 0.06
		bulb.height = 0.12
		var bulb_mesh := MeshInstance3D.new()
		bulb_mesh.mesh = bulb
		bulb_mesh.material_override = _bulb_material()
		bulb_mesh.position = Vector3(centre.x, 2.55, centre.y)
		parent.add_child(bulb_mesh)
	var porch := OmniLight3D.new()
	porch.name = "Lamp_porch"
	var door: Vector2 = HouseLayout.DOORS.front_door.at
	porch.position = Vector3(door.x, 2.35, door.y + 0.4)
	porch.light_color = Color(1.0, 0.8, 0.55)
	porch.light_energy = 1.4
	porch.omni_range = 5.0
	parent.add_child(porch)


func _bulb_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.93, 0.8)
	return mat


func _add_box(parent: Node3D, centre: Vector3, size: Vector3, colour: String,
		node_name := "") -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	mesh.material_override = _material(colour)
	mesh.position = centre
	if node_name != "":
		mesh.name = node_name
	parent.add_child(mesh)
	return mesh


# One material per colour, shared, so the House draws quickly on a phone.
func _material(colour: String) -> StandardMaterial3D:
	if not _materials.has(colour):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = COLOURS[colour]
		if colour == "glass":
			# Windows show the dusk outside, lit or not.
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = DUSK.lightened(0.25)
		_materials[colour] = mat
	return _materials[colour]


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)
	_ui_layer = layer
	# Chapter objects' tap areas sit under the rings.
	_object_root = Control.new()
	_object_root.name = "Objects"
	_object_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_object_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_object_root)
	for id: String in HouseLayout.CHAPTER_OBJECTS:
		var button := Button.new()
		button.name = "Object_%s" % id
		# Tap only, and nothing to see: the object itself is what is tapped.
		button.focus_mode = Control.FOCUS_NONE
		for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		button.visible = false
		button.pressed.connect(_on_object_pressed.bind(id))
		_object_root.add_child(button)
		_object_buttons[id] = button
	_ring_root = Control.new()
	_ring_root.name = "Rings"
	_ring_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ring_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_ring_root)
	# A doorway ring is solid; a wall ring is an outline over a light veil.
	_door_styles = [_ring_look(0.9, Color(INK, 0.9)), _ring_look(1.0, INK)]
	_wall_styles = [_ring_look(0.12, Color(ACCENT, 0.95)), _ring_look(0.45, Color(ACCENT, 0.95))]
	# The label: light words on the subtitle scrim, so they read over a
	# bright wall.
	_label_style = StyleBoxFlat.new()
	_label_style.bg_color = Color(SURFACE, 0.8)
	_label_style.set_corner_radius_all(8)
	_label_style.content_margin_left = 12.0
	_label_style.content_margin_right = 12.0
	_label_style.content_margin_top = 2.0
	_label_style.content_margin_bottom = 4.0


func _ring_look(fill: float, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(ACCENT, fill)
	style.border_color = border
	style.set_border_width_all(6)
	# Larger than any ring, so it is always a circle.
	style.set_corner_radius_all(1000)
	return style


# --- Story points.

## Shows another story point: its doors, its boxes, the bedside lamp and
## which chapter object works. The camera stays where it is.
func set_point(point: StringName) -> void:
	story_point = point
	door_states = HouseTable.doors(point)
	for door_id: String in _door_nodes:
		for node: Node in _door_nodes[door_id]:
			node.free()
		_door_pivots.erase(door_id)
	_door_nodes.clear()
	for door_id: String in HouseLayout.DOORS:
		_add_door(_props, door_id)
	_set_lamp(HouseTable.bedside_lamp_lit(point))
	if _arm:
		_arm.transform = _arm_rest
	if not is_gliding():
		_arrive()


# The opening beat plays once, on first arrival at L1 on moving day. It is
# not saved on its own: until the Partner is saved, leaving and coming back
# plays it again (GameState.finish_opening_beat).
func _start_opening_beat_if_due() -> void:
	if _beat or _current != OPENING_BEAT_VIEW or story_point != HouseTable.START:
		return
	if get_node("/root/GameState").opening_beat_done():
		return
	_beat = OpeningBeat.new()
	_beat.name = "OpeningBeat"
	_beat.finished.connect(_on_opening_beat_finished)
	_ui_layer.add_child(_beat)


func _on_opening_beat_finished(answer: String) -> void:
	get_node("/root/GameState").finish_opening_beat(answer)
	_beat.queue_free()
	_beat = null
	# Maya's last line: the boxes go from the hall, and the lamp is on.
	set_point(HouseTable.AFTER_OPENING)


# --- Chapter objects and close-ups (ADR-0008).

# Each chapter object as gray blocks, and the bedside lamp's light.
func _add_chapter_objects(props: Node3D, lighting: Node3D) -> void:
	for id: String in HouseLayout.CHAPTER_OBJECTS:
		var data: Dictionary = HouseLayout.CHAPTER_OBJECTS[id]
		var object := Node3D.new()
		object.name = "ChapterObject_%s" % id
		props.add_child(object)
		for part: Array in data.parts:
			var mesh := _add_box(object, part[1], part[2], part[3], "%s_%s" % [id, part[0]])
			if part[0] == "arm":
				_arm = mesh
				_arm_rest = mesh.transform
			if part[0] == "shade":
				_shade = mesh
		if data.has("light"):
			_lamp_light = OmniLight3D.new()
			_lamp_light.name = "Lamp_bedside"
			_lamp_light.position = data.light
			_lamp_light.light_color = LAMP_GLOW
			_lamp_light.light_energy = 1.6
			_lamp_light.omni_range = 4.5
			_lamp_light.shadow_enabled = false
			lighting.add_child(_lamp_light)
	_set_lamp(HouseTable.bedside_lamp_lit(story_point))


## Whether the bedside lamp is on.
func is_lamp_lit() -> bool:
	return _lamp_light != null and _lamp_light.visible


func _set_lamp(lit: bool) -> void:
	if _lamp_light == null:
		return
	_lamp_light.visible = lit
	_shade.material_override = _glow_material() if lit else _material("shade")


func _glow_material() -> StandardMaterial3D:
	if not _materials.has("glow"):
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = LAMP_GLOW
		_materials["glow"] = mat
	return _materials["glow"]


## Whether a chapter object works now: it is the story point's chapter object
## and nothing else is under way.
func object_works(object_id: String) -> bool:
	return String(HouseTable.chapter_object(story_point)) == object_id and not _acting


## Glides to a chapter object's close-up.
func open_close_up(object_id: String) -> void:
	if is_gliding() or _close_up != "" or not object_works(object_id):
		return
	_close_up = object_id
	_glide(HouseLayout.close_up_transform(object_id))


## Steps back from a close-up to the view it was opened from.
func step_back() -> void:
	if _close_up == "" or is_gliding() or _acting:
		return
	_close_up = ""
	_glide(HouseLayout.view_transform(_current))


func _on_object_pressed(object_id: String) -> void:
	if is_gliding() or not object_works(object_id):
		return
	if _close_up != object_id:
		open_close_up(object_id)
		return
	_act(object_id)


# The object's one action. The record player lowers its needle, then the
# Partner begins. The lamp goes off and the Protector's run begins straight
# away: no warning, no title card, nothing to skip.
func _act(object_id: String) -> void:
	_acting = true
	_place_objects()
	var chapter := HouseTable.chapter_for_object(StringName(object_id))
	if object_id == "record_player" and _arm:
		_needle = create_tween().set_trans(Tween.TRANS_SINE)
		_needle.tween_property(_arm, "rotation:y", deg_to_rad(28.0), 0.5)
		_needle.tween_property(_arm, "position:y", _arm_rest.origin.y - 0.02, 0.3)
		_needle.tween_callback(_enter_chapter.bind(chapter))
		return
	if object_id == "bedside_lamp":
		_set_lamp(false)
	_enter_chapter(chapter)


func _enter_chapter(chapter: StringName) -> void:
	_playing_chapter = chapter
	if not ChapterRunner.of(get_tree()).enter(chapter, self):
		_playing_chapter = &""
		_back_to_view()


# The chapter finished: the House comes back at the next story point, in the
# room that point arrives in (the bedroom after the Partner, the entry after
# the Loss). GameState has already recorded and saved the result.
func _on_chapter_finished(result: Dictionary) -> void:
	if _playing_chapter == &"" or StringName(result.chapter) != _playing_chapter:
		return
	_playing_chapter = &""
	_acting = false
	_close_up = ""
	var point: StringName = get_node("/root/GameState").house_point()
	_current = HouseLayout.ROOMS.get(String(HouseTable.arrive_in(point)), {}).get("doorway_view", _current)
	_set_base(HouseLayout.view_transform(_current))
	set_point(point)


# Left without finishing: nothing changed, so back to the view the close-up
# was opened from, as it was.
func _on_chapter_left(chapter: StringName) -> void:
	if chapter != _playing_chapter:
		return
	_playing_chapter = &""
	_back_to_view()


func _back_to_view() -> void:
	_acting = false
	_close_up = ""
	if _arm:
		_arm.transform = _arm_rest
	_set_lamp(HouseTable.bedside_lamp_lit(story_point))
	_set_base(HouseLayout.view_transform(_current))
	_arrive()


# Each chapter object that works has a tap area over it: from any view in its
# room where it is in front of the camera, and at its own close-up. It is at
# least ring-sized, so it is easy to tap however small the object looks.
func _place_objects() -> void:
	var screen := get_viewport().get_visible_rect()
	var smallest := _ring_size()
	var room: String = HouseLayout.VIEWS[_current].room if HouseLayout.VIEWS.has(_current) else ""
	for id: String in _object_buttons:
		var button: Button = _object_buttons[id]
		var data: Dictionary = HouseLayout.CHAPTER_OBJECTS[id]
		var here: bool = _close_up == id if _close_up != "" else data.room == room
		var rect := _object_rect(id)
		button.visible = here and object_works(id) and not is_gliding() and rect.size != Vector2.ZERO \
				and screen.has_point(rect.get_center())
		if not button.visible:
			continue
		var size := rect.size.max(Vector2.ONE * smallest)
		button.position = rect.get_center() - size / 2.0
		button.size = size


# Where an object is on screen, or an empty rect if any of it is behind the
# camera.
func _object_rect(object_id: String) -> Rect2:
	var bounds := HouseLayout.object_bounds(object_id)
	var rect := Rect2()
	for i in 8:
		var corner := bounds.get_endpoint(i)
		if _camera.is_position_behind(corner):
			return Rect2()
		var point := _camera.unproject_position(corner)
		rect = Rect2(point, Vector2.ZERO) if i == 0 else rect.expand(point)
	return rect


# --- While a chapter plays.

# The chapter runner hides the House while a chapter plays. Its rings and
# words go too, and its light and fog (one WorldEnvironment at a time: the
# chapter may have its own).
func _on_visibility_changed() -> void:
	_ui_layer.visible = visible
	if visible:
		if _world_env.get_parent() == null:
			add_child(_world_env)
		_camera.make_current()
	elif _world_env.get_parent() == self:
		remove_child(_world_env)


func _exit_tree() -> void:
	# The WorldEnvironment is not in the tree while a chapter plays.
	if is_instance_valid(_world_env) and _world_env.get_parent() == null:
		_world_env.queue_free()
