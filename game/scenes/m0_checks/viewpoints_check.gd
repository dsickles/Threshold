extends Node3D
## M0 check 3 (DAS-69): a gray-box room with four viewpoints. Tap a ring to
## glide the camera there. On-screen buttons change the glide duration so Dan
## can pick the one that feels right. Throwaway M0 scaffolding, not the House.

const MENU_SCENE := "res://scenes/ui/m0_menu.tscn"
const ACCENT := Color(0.769, 0.647, 0.455)

const ROOM_SIZE := Vector3(10.0, 3.0, 7.0)
const EYE_HEIGHT := 1.6

# Where each viewpoint stands and what it looks at.
const VIEWPOINTS: Array[Dictionary] = [
	{"stand": Vector3(0.0, 0.0, 3.0), "look_at": Vector3(0.0, 1.0, -1.0)},  # Doorway
	{"stand": Vector3(-4.0, 0.0, -2.5), "look_at": Vector3(0.0, 1.0, 2.0)},  # Window
	{"stand": Vector3(3.8, 0.0, -2.5), "look_at": Vector3(-1.0, 1.0, 1.0)},  # Table
	{"stand": Vector3(-3.8, 0.0, 2.3), "look_at": Vector3(2.0, 1.0, -1.5)},  # Armchair
]

# Gray-box furniture: [centre, size, colour].
const PROPS: Array[Array] = [
	[Vector3(1.6, 0.375, -2.3), Vector3(1.6, 0.75, 0.9), Color(0.45, 0.36, 0.28)],  # Table
	[Vector3(-4.3, 0.45, 0.6), Vector3(1.0, 0.9, 1.0), Color(0.42, 0.3, 0.3)],  # Armchair
	[Vector3(0.0, 1.0, -3.3), Vector3(2.4, 2.0, 0.4), Color(0.4, 0.38, 0.34)],  # Shelf
	[Vector3(4.7, 0.5, 2.2), Vector3(0.6, 1.0, 1.4), Color(0.38, 0.36, 0.33)],  # Cabinet
	[Vector3(-4.95, 1.6, -1.0), Vector3(0.05, 1.2, 1.8), Color(0.75, 0.8, 0.85)],  # Window
	[Vector3(0.0, 1.05, 3.45), Vector3(1.2, 2.1, 0.05), Color(0.3, 0.24, 0.18)],  # Door
]

const GLIDE_MIN := 0.2
const GLIDE_MAX := 3.0
const GLIDE_STEP := 0.2
const RING_SIZE := 110.0

var _glide_seconds := 1.0
var _current := 0
var _camera: Camera3D
var _tween: Tween
var _rings: Array[Button] = []
var _glide_label: Label


func _ready() -> void:
	_build_room()
	_camera = Camera3D.new()
	_camera.fov = 70.0
	add_child(_camera)
	_camera.global_transform = _viewpoint_transform(_current)
	_build_ui()


func _process(_delta: float) -> void:
	# Keep the view about as wide on a tall phone as on a laptop.
	var size := get_viewport().get_visible_rect().size
	_camera.keep_aspect = Camera3D.KEEP_WIDTH if size.y > size.x else Camera3D.KEEP_HEIGHT
	_place_rings()


func _viewpoint_transform(index: int) -> Transform3D:
	var vp: Dictionary = VIEWPOINTS[index]
	var eye: Vector3 = vp.stand + Vector3.UP * EYE_HEIGHT
	return Transform3D.IDENTITY.translated(eye).looking_at(vp.look_at, Vector3.UP)


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


# Each viewpoint gets a ring on the floor in the 3D room and a tappable button
# drawn over it, so the target stays at least 44px however far away it is.
func _place_rings() -> void:
	var screen := get_viewport().get_visible_rect()
	for i in _rings.size():
		var ring := _rings[i]
		var floor_point: Vector3 = VIEWPOINTS[i].stand + Vector3.UP * 0.02
		var in_front := i != _current and not _camera.is_position_behind(floor_point)
		var point := _camera.unproject_position(floor_point)
		ring.visible = in_front and screen.grow(RING_SIZE).has_point(point)
		ring.position = point - ring.size / 2.0


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

	for vp in VIEWPOINTS:
		var disc := CylinderMesh.new()
		disc.top_radius = 0.35
		disc.bottom_radius = 0.35
		disc.height = 0.02
		var mat := StandardMaterial3D.new()
		mat.albedo_color = ACCENT
		mat.emission_enabled = true
		mat.emission = ACCENT
		mat.emission_energy_multiplier = 0.4
		disc.material = mat
		var mesh := MeshInstance3D.new()
		mesh.mesh = disc
		mesh.position = vp.stand + Vector3.UP * 0.01
		add_child(mesh)


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
	root.theme = _make_theme()
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


# Same look as the M0 menu.
func _make_theme() -> Theme:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.165, 0.145, 0.125, 0.9)
	normal.border_color = Color(0.239, 0.22, 0.196)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(16)
	normal.content_margin_left = 24
	normal.content_margin_right = 24
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.239, 0.22, 0.196)
	pressed.border_color = ACCENT
	var text := Color(0.957, 0.937, 0.902)
	var theme := Theme.new()
	theme.default_font_size = 32
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = ACCENT
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(8)
	theme.set_stylebox("focus", "Button", focus)
	for state in ["normal", "hover"]:
		theme.set_stylebox(state, "Button", normal)
	for state in ["pressed", "hover_pressed"]:
		theme.set_stylebox(state, "Button", pressed)
	for colour in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(colour, "Button", text)
	theme.set_color("font_color", "Label", text)
	return theme
