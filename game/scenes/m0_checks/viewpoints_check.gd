extends Node3D
## M0 check 3 (DAS-69): a gray-box room with four viewpoints. Tap a ring on a
## thing to glide to a view looking at it. On-screen buttons change the glide duration so Dan
## can pick the one that feels right. Throwaway M0 scaffolding, not the House.

const MENU_SCENE := "res://scenes/ui/m0_menu.tscn"
const ACCENT := Color(0.769, 0.647, 0.455)

const ROOM_SIZE := Vector3(10.0, 3.0, 7.0)
const EYE_HEIGHT := 1.6

# Each viewpoint frames one thing: its ring sits on "focus", and the camera
# stands at "stand" looking at it.
const VIEWPOINTS: Array[Dictionary] = [
	{"focus": Vector3(-4.9, 1.6, -1.0), "stand": Vector3(-1.6, 0.0, 0.2)},  # Window
	{"focus": Vector3(1.6, 0.8, -2.3), "stand": Vector3(2.4, 0.0, 0.6)},  # Table
	{"focus": Vector3(-4.3, 0.9, 0.6), "stand": Vector3(-1.4, 0.0, 2.2)},  # Armchair
	{"focus": Vector3(0.0, 1.4, -3.1), "stand": Vector3(-0.6, 0.0, 0.4)},  # Shelf
]
# Where you start: in the doorway, looking into the room.
const START_STAND := Vector3(0.0, 0.0, 3.0)
const START_LOOK_AT := Vector3(0.0, 1.0, -1.0)

# Gray-box furniture: [centre, size, colour].
const PROPS: Array[Array] = [
	[Vector3(1.6, 0.375, -2.3), Vector3(1.6, 0.75, 0.9), Color(0.45, 0.36, 0.28)],  # Table
	[Vector3(-4.3, 0.45, 0.6), Vector3(1.0, 0.9, 1.0), Color(0.42, 0.3, 0.3)],  # Armchair
	[Vector3(0.0, 1.0, -3.3), Vector3(2.4, 2.0, 0.4), Color(0.4, 0.38, 0.34)],  # Shelf
	[Vector3(4.7, 0.5, 2.2), Vector3(0.6, 1.0, 1.4), Color(0.38, 0.36, 0.33)],  # Cabinet
	[Vector3(-4.95, 1.6, -1.0), Vector3(0.05, 1.2, 1.8), Color(0.75, 0.8, 0.85)],  # Window
]

const GLIDE_MIN := 0.2
const GLIDE_MAX := 3.0
const GLIDE_STEP := 0.2
const RING_SIZE := 110.0
const EDGE_MARGIN := 24.0
# Keeps pinned rings clear of the Back and glide buttons along the top.
const TOP_CLEAR := 160.0

var _glide_seconds := 2.0
var _current := -1
var _camera: Camera3D
var _tween: Tween
var _rings: Array[Button] = []
var _glide_label: Label


func _ready() -> void:
	_build_room()
	_camera = Camera3D.new()
	_camera.fov = 70.0
	add_child(_camera)
	_camera.global_transform = _look_from(START_STAND, START_LOOK_AT)
	_build_ui()


func _process(_delta: float) -> void:
	# Keep the view about as wide on a tall phone as on a laptop.
	var size := get_viewport().get_visible_rect().size
	_camera.keep_aspect = Camera3D.KEEP_WIDTH if size.y > size.x else Camera3D.KEEP_HEIGHT
	_place_rings()


func _viewpoint_transform(index: int) -> Transform3D:
	var vp: Dictionary = VIEWPOINTS[index]
	return _look_from(vp.stand, vp.focus)


func _look_from(stand: Vector3, target: Vector3) -> Transform3D:
	var eye := stand + Vector3.UP * EYE_HEIGHT
	return Transform3D.IDENTITY.translated(eye).looking_at(target, Vector3.UP)


func _go_to(index: int) -> void:
	if index == _current:
		return
	_current = index
	if _tween:
		_tween.kill()
	var from := _camera.global_transform
	var to := _viewpoint_transform(index)
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_apply_glide.bind(from, to), 0.0, 1.0, _glide_seconds)


func _apply_glide(t: float, from: Transform3D, to: Transform3D) -> void:
	_camera.global_transform = from.interpolate_with(to, t)


# Each viewpoint gets a tappable ring drawn over the thing it frames, so the
# target stays at least 44px however far away it is. A thing out of view gets
# its ring pinned to the screen edge on its side, with an arrow, so there is
# always somewhere visible to go.
func _place_rings() -> void:
	var screen := get_viewport().get_visible_rect()
	var half := RING_SIZE / 2.0
	var area := Rect2(
		Vector2(EDGE_MARGIN + half, TOP_CLEAR + half),
		screen.size - Vector2(2.0 * (EDGE_MARGIN + half), TOP_CLEAR + EDGE_MARGIN + 2.0 * half))
	var pinned_left: Array[Button] = []
	var pinned_right: Array[Button] = []
	for i in _rings.size():
		var ring := _rings[i]
		ring.visible = i != _current
		var focus: Vector3 = VIEWPOINTS[i].focus
		var point := _camera.unproject_position(focus)
		if _camera.is_position_behind(focus):
			var local := _camera.global_transform.affine_inverse() * focus
			point = Vector2(screen.size.x if local.x > 0.0 else 0.0, screen.size.y / 2.0)
		ring.text = ""
		if ring.visible and not area.has_point(point):
			point = point.clamp(area.position, area.end)
			var right := point.x > screen.size.x / 2.0
			ring.text = "›" if right else "‹"
			(pinned_right if right else pinned_left).append(ring)
		ring.position = point - ring.size / 2.0
	for side in [pinned_left, pinned_right]:
		_spread(side, area)


# Pinned rings on the same edge would sit on top of each other, so stack them.
func _spread(rings: Array[Button], area: Rect2) -> void:
	if rings.size() < 2:
		return
	rings.sort_custom(func(a: Button, b: Button) -> bool: return a.position.y < b.position.y)
	var gap := RING_SIZE + 16.0
	var mid := 0.0
	for ring in rings:
		mid += ring.position.y
	mid /= rings.size()
	var top := clampf(mid - gap * (rings.size() - 1) / 2.0, area.position.y - RING_SIZE / 2.0, area.end.y - RING_SIZE / 2.0 - gap * (rings.size() - 1))
	for k in rings.size():
		rings[k].position.y = top + gap * k


func _set_glide(seconds: float) -> void:
	_glide_seconds = clampf(snappedf(seconds, GLIDE_STEP), GLIDE_MIN, GLIDE_MAX)
	_glide_label.text = "Glide %.1f s" % _glide_seconds


func _build_room() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.11, 0.098, 0.086)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.5, 0.45)
	env.ambient_light_energy = 0.6
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0.0, 2.6, 0.0)
	lamp.light_color = Color(1.0, 0.85, 0.65)
	lamp.light_energy = 1.6
	lamp.omni_range = 12.0
	add_child(lamp)

	var half := ROOM_SIZE / 2.0
	var wall := Color(0.62, 0.59, 0.55)
	_add_box(Vector3(0.0, -0.05, 0.0), Vector3(ROOM_SIZE.x, 0.1, ROOM_SIZE.z), Color(0.33, 0.3, 0.27))
	_add_box(Vector3(0.0, ROOM_SIZE.y + 0.05, 0.0), Vector3(ROOM_SIZE.x, 0.1, ROOM_SIZE.z), wall)
	_add_box(Vector3(0.0, half.y, -half.z - 0.05), Vector3(ROOM_SIZE.x, ROOM_SIZE.y, 0.1), wall)
	_add_box(Vector3(0.0, half.y, half.z + 0.05), Vector3(ROOM_SIZE.x, ROOM_SIZE.y, 0.1), wall)
	_add_box(Vector3(-half.x - 0.05, half.y, 0.0), Vector3(0.1, ROOM_SIZE.y, ROOM_SIZE.z), wall)
	_add_box(Vector3(half.x + 0.05, half.y, 0.0), Vector3(0.1, ROOM_SIZE.y, ROOM_SIZE.z), wall)
	for prop in PROPS:
		_add_box(prop[0], prop[1], prop[2])


func _add_box(centre: Vector3, size: Vector3, colour: Color) -> void:
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	box.material = mat
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	mesh.position = centre
	add_child(mesh)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var ring_style := StyleBoxFlat.new()
	ring_style.bg_color = Color(ACCENT, 0.25)
	ring_style.border_color = Color(ACCENT, 0.95)
	ring_style.set_border_width_all(6)
	ring_style.set_corner_radius_all(int(RING_SIZE / 2.0))
	var ring_pressed := ring_style.duplicate() as StyleBoxFlat
	ring_pressed.bg_color = Color(ACCENT, 0.6)
	for i in VIEWPOINTS.size():
		var ring := Button.new()
		ring.custom_minimum_size = Vector2(RING_SIZE, RING_SIZE)
		ring.size = ring.custom_minimum_size
		for state in ["normal", "hover"]:
			ring.add_theme_stylebox_override(state, ring_style)
		ring.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		ring.add_theme_font_size_override("font_size", 56)
		for state in ["pressed", "hover_pressed"]:
			ring.add_theme_stylebox_override(state, ring_pressed)
		ring.pressed.connect(_go_to.bind(i))
		root.add_child(ring)
		_rings.append(ring)

	var back := Button.new()
	back.text = "Back to menu"
	back.custom_minimum_size = Vector2(0, 110)
	back.position = Vector2(24, 24)
	back.pressed.connect(get_tree().change_scene_to_file.bind(MENU_SCENE))
	root.add_child(back)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	root.add_child(bar)
	var shorter := Button.new()
	shorter.text = "−"
	shorter.custom_minimum_size = Vector2(110, 110)
	shorter.pressed.connect(func() -> void: _set_glide(_glide_seconds - GLIDE_STEP))
	bar.add_child(shorter)
	_glide_label = Label.new()
	_glide_label.custom_minimum_size = Vector2(200, 110)
	_glide_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glide_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(_glide_label)
	var longer := Button.new()
	longer.text = "+"
	longer.custom_minimum_size = Vector2(110, 110)
	longer.pressed.connect(func() -> void: _set_glide(_glide_seconds + GLIDE_STEP))
	bar.add_child(longer)
	_set_glide(_glide_seconds)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)

