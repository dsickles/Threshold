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
## doors, furniture and views are data in house_layout.gd. Close-ups, House objects, moods and the
## opening beat come in later tickets. For now it opens from the M0 menu.

const ACCENT := Color(0.769, 0.647, 0.455)
const INK := Color(0.957, 0.937, 0.902)
const SURFACE := Color(0.11, 0.098, 0.086)
const GLIDE_SECONDS := 2.0
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
}
const DUSK := Color(0.2, 0.22, 0.34)

## The story point the House shows. Set before adding the House to the tree
## (the M0 menu does); left empty, it is the player's own point
## (GameState.house_point()). `door_states`, if set, wins over its doors.
var story_point: StringName = &""
var door_states: Dictionary = {}

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
var _world_env: WorldEnvironment


func _ready() -> void:
	if story_point == &"":
		# The GameState autoload, looked up by path as the M0 menu does.
		story_point = get_node("/root/GameState").house_point()
	if not story_point in HouseTable.POINTS:
		push_error("House: no story point '%s'; showing the start." % story_point)
		story_point = HouseTable.START
	if door_states.is_empty():
		door_states = HouseTable.doors(story_point)
	_build_world()
	_camera = Camera3D.new()
	_camera.fov = 70.0
	_camera.near = 0.05
	add_child(_camera)
	_build_ui()
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
## under way, and each ring with the view it leads to, its label and its centre.
func probe_state() -> Dictionary:
	var rings: Array[Dictionary] = []
	for i in _ring_data.size():
		var centre := _rings[i].get_global_transform_with_canvas() * (_rings[i].size / 2.0)
		rings.append({"target": _ring_data[i].target, "label": ring_label(_rings[i]).text,
				"doorway": _ring_data[i].door != "", "x": centre.x, "y": centre.y})
	return {"view": _current, "gliding": is_gliding(), "rings": rings}


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
	_yaw = 0.0
	_pitch = 0.0
	# Rings hide during the glide and come back on arrival, so a glide is
	# never turned mid-way through a wall.
	_ring_data = []
	_show_rings()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_apply_glide.bind(from, to, via, across), 0.0, 1.0, GLIDE_SECONDS)
	_tween.finished.connect(_arrive)


func _arrive() -> void:
	_ring_data = HouseLayout.rings_for(_current, door_states)
	_show_rings()


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


# A short drag looks around a little, never far. Taps on rings are buttons,
# so only drags that start off a ring arrive here.
func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion == null or not (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) or is_gliding():
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

	_add_box(base, Vector3(8.5, -0.06, 7.0), Vector3(60.0, 0.1, 60.0), "ground")
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
	# The porch: two posts at the front, under the roof.
	for x in [0.15, 3.85]:
		_add_box(base, Vector3(x, HouseLayout.WALL_HEIGHT / 2.0, 14.35),
				Vector3(0.15, HouseLayout.WALL_HEIGHT, 0.15), "wood")

	for item: Array in HouseLayout.FURNITURE:
		var mesh := _add_box(props, item[2], item[3], item[4], "Furniture_%s" % item[0])
		mesh.rotation.y = deg_to_rad(item[5])
	for door_id: String in HouseLayout.DOORS:
		_add_door(props, door_id)

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
	if door.get("panel", false):
		var pivot := Node3D.new()
		pivot.name = "Door_%s" % door_id
		pivot.position = Vector3(at.x - width / 2.0, 0.0, at.y) if along_x \
				else Vector3(at.x, 0.0, at.y - width / 2.0)
		parent.add_child(pivot)
		var panel_size := Vector3(width, HouseLayout.DOOR_HEIGHT, 0.05) if along_x \
				else Vector3(0.05, HouseLayout.DOOR_HEIGHT, width)
		var offset := Vector3(width / 2.0, HouseLayout.DOOR_HEIGHT / 2.0, 0.0) if along_x \
				else Vector3(0.0, HouseLayout.DOOR_HEIGHT / 2.0, width / 2.0)
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
	if _door_along_x(door_id):
		return DOOR_OPEN_ANGLE if into.y < 0.0 else -DOOR_OPEN_ANGLE
	return DOOR_OPEN_ANGLE if into.x > 0.0 else -DOOR_OPEN_ANGLE


func _add_box_stack(parent: Node3D, door_id: String) -> void:
	var door: Dictionary = HouseLayout.DOORS[door_id]
	var stack := Node3D.new()
	stack.name = "Boxes_%s" % door_id
	parent.add_child(stack)
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
	porch.position = Vector3(2.0, 2.35, 12.4)
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
	add_child(layer)
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
