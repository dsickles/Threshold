extends Node3D
## The Protector's run (DAS-97), in plain gray-box shapes: a small light runs
## away from the camera down a path of square tiles, and a tap anywhere
## clears the next obstacle in its way. Seen from behind, like Temple Run;
## the player never steers. Built from docs/design/the-loss-run-and-car.md,
## which Dan approved on 2026-10-25.
##
## Everything follows one fixed timeline (run_plan.gd), the same for every
## player: the euphoria, the confusion, the panic, then the silence, where
## the light runs on alone, slows, stops and goes out on an empty path. A
## stumble dims the light for a moment and changes nothing else. No words,
## no HUD, no retry, no skip, no shake.
##
## The run only reports `ended` (3:35, black). The chapter (protector.gd)
## decides what follows. It never touches the House or saved state.
##
## The run's clock moves in advance(), from _process; tests turn
## auto_advance off and move it themselves.

## 3:35: the screen is black and the run is over.
signal ended

const RunPlan := preload("res://scenes/chapters/protector/run_plan.gd")
const MUSIC := preload("res://assets/audio/protector/run.mp3")
const CLEAR_SOUND := preload("res://assets/audio/protector/placeholder_clear.wav")  # PLACEHOLDER
const STUMBLE_SOUND := preload("res://assets/audio/protector/placeholder_stumble.wav")  # PLACEHOLDER

enum Status { PENDING, CLEARED, STUMBLED }

const TILE := 1.6  # Metres from one tile's centre to the next.
const TILE_SIZE := Vector3(1.5, 0.3, 1.5)
const COLUMNS := [-1, 0, 1]  # Left, middle, right, in tiles from the middle.
const PATH_STEP := 1.0  # Metres between the path's stored points.
const BEHIND := 9.0  # Tiles are kept this far behind the light, then removed.
const AHEAD := 75.0  # And built this far ahead of it; the fog hides the end.
const AHEAD_SILENCE := 190.0  # The fog lifts in the silence, so further.
const CONTACT := 0.9  # An obstacle's centre is this far past the light when it touches.
const LIGHT_HEIGHT := 0.55
const LIGHT_RADIUS := 0.3
const LIGHT_COLOR := Color("#FFB45C")  # Warm amber, like the Partner's heart.
const GRAVITY := 14.0
const RIPPLE_TIME := 0.5

# The look of each part: sky (and fog), tiles, sun, ambient light, fog
# density, at run times between which it eases. It drains toward the House
# in grief (#5C534C) through the confusion and the panic. Colours, ordinary
# fog and lights only: no CompositorEffects, no volumetric fog.
const LOOKS := [
	[0.0, "#000000", "#000000", 0.0, 0.0, 0.03],
	[RunPlan.EUPHORIA_START, "#000000", "#000000", 0.0, 0.0, 0.03],
	[8.0, "#F3D7A6", "#E9D5B4", 1.1, 0.7, 0.018],
	[RunPlan.CONFUSION_START, "#F7DDAE", "#EEDBBB", 1.2, 0.75, 0.016],
	[100.0, "#CDBBA2", "#CDBDA6", 0.7, 0.6, 0.03],
	[RunPlan.PANIC_START, "#8C8279", "#958B82", 0.35, 0.5, 0.045],
	[142.0, "#2E2B2A", "#5A524C", 0.08, 0.3, 0.075],
	[RunPlan.SILENCE_START - 0.01, "#2A2827", "#544C46", 0.08, 0.3, 0.075],
	[RunPlan.SILENCE_START, "#5C534C", "#6F665F", 0.25, 0.55, 0.006],
	[RunPlan.BLACK, "#5C534C", "#6F665F", 0.25, 0.55, 0.006],
]
const RAIN_START := 137.0

## False in tests, which move the clock with advance().
var auto_advance := true

var _t := 0.0
var _paused := false
var _ended := false
var _whole := false  # The silence: the path is whole and nothing falls.
var _music_started := false
var _obstacles: Array[Dictionary] = []
var _gap_rows := {}  # Row number -> the gap obstacle there.
var _last_stumble := -INF  # When the latest stumble happened.
var _rows := {}  # Row number -> Array of 3 tiles (or null where none).
var _row_falls := {}  # Row number -> when its first and last tiles fall.
var _path_points := PackedVector3Array()
var _path_heading := PackedFloat32Array()
var _ripples: Array[Vector3] = []  # x, y on screen, and age.

var _env: Environment
var _sun: DirectionalLight3D
var _camera: Camera3D
var _light: MeshInstance3D
var _light_material: StandardMaterial3D
var _lamp: OmniLight3D
var _rain: CPUParticles3D
var _tile_mesh: BoxMesh
var _tile_materials: Array[StandardMaterial3D] = []
var _music: AudioStreamPlayer
var _clear_player: AudioStreamPlayer
var _stumble_player: AudioStreamPlayer
var _overlay: ColorRect
var _ripple_layer: Control
var _document: JavaScriptObject
var _visibility_callback: JavaScriptObject


func _ready() -> void:
	for plan in RunPlan.obstacles():
		var obstacle := plan.duplicate()
		obstacle.status = Status.PENDING
		obstacle.at = 0.0  # When it was cleared or stumbled.
		obstacle.distance = RunPlan.distance(plan.time) + CONTACT
		obstacle.node = null
		_obstacles.append(obstacle)
		if obstacle.kind == RunPlan.Kind.GAP:
			var first := floori(obstacle.distance / TILE)
			_gap_rows[first] = obstacle
			_gap_rows[first + 1] = obstacle
	_build_path()
	_build_world()
	_build_sound()
	_build_screen()
	if OS.has_feature("web"):
		# Hiding the tab pauses the run; Godot doesn't say so on the web.
		_document = JavaScriptBridge.get_interface("document")
		_visibility_callback = JavaScriptBridge.create_callback(_on_visibility_change)
		_document.addEventListener("visibilitychange", _visibility_callback)
	_update()


func _exit_tree() -> void:
	if _document:
		_document.removeEventListener("visibilitychange", _visibility_callback)
		_document = null


func _process(delta: float) -> void:
	if auto_advance:
		advance(delta)
	_age_ripples(delta)


## Moves the run's clock on by `delta` seconds (nothing moves while paused).
func advance(delta: float) -> void:
	if _paused or _ended:
		return
	_t += delta
	_update()


## Starts the run part-way in, for the browser tests (web_test_probe.gd).
## Obstacles before that point are passed over, neither cleared nor stumbled.
func start_from(t: float) -> void:
	_t = t
	for obstacle in _obstacles:
		if obstacle.time < t:
			obstacle.status = Status.CLEARED
			obstacle.at = -1000.0
	_update()


func time() -> float:
	return _t


func part() -> RunPlan.Part:
	return RunPlan.part_at(_t)


func has_ended() -> bool:
	return _ended


## Pauses the run, the music and every moving thing, until the next tap.
func pause() -> void:
	if _paused or _ended:
		return
	_paused = true
	_music.stream_paused = true


func is_paused() -> bool:
	return _paused


func resume() -> void:
	_paused = false
	_music.stream_paused = false


func is_music_playing() -> bool:
	return _music.playing and not _music.stream_paused


## How far the light has run (metres). From the timeline only.
func light_distance() -> float:
	return RunPlan.distance(_t)


## The light's brightness now, 0 to 1: the timeline's, dimmed for a moment
## after a stumble.
func light_brightness() -> float:
	return RunPlan.base_brightness(_t) * RunPlan.stumble_factor(_t, _last_stumble)


## True if obstacle `i` can be cleared now: it is coming, and within reach.
func is_in_reach(i: int) -> bool:
	var obstacle := _obstacles[i]
	return obstacle.status == Status.PENDING \
			and _t >= obstacle.time - RunPlan.reach(obstacle.part) and _t < obstacle.time


func obstacles() -> Array[Dictionary]:
	return _obstacles


func count(status: Status) -> int:
	var n := 0
	for obstacle in _obstacles:
		if obstacle.status == status and obstacle.at > -1000.0:
			n += 1
	return n


## A tap anywhere. Clears the nearest obstacle in reach and returns its
## index; with nothing in reach, makes a ripple where it landed and returns
## -1. Nothing else: no penalty, no sound of failure.
func tap(at: Vector2) -> int:
	if _paused:
		resume()  # The tap that brings the run back clears nothing.
		return -1
	for i in _obstacles.size():
		if is_in_reach(i):
			_obstacles[i].status = Status.CLEARED
			_obstacles[i].at = _t
			_clear_player.play()
			return i
	if not _ended:
		_ripples.append(Vector3(at.x, at.y, 0.0))
	return -1


func ripple_count() -> int:
	return _ripples.size()


func probe_state() -> Dictionary:
	var lit := 0
	for i in _obstacles.size():
		if is_in_reach(i):
			lit += 1
	return {
		"time": _t,
		"part": RunPlan.Part.keys()[part()],
		"paused": _paused,
		"in_reach": lit,
		"cleared": count(Status.CLEARED),
		"stumbled": count(Status.STUMBLED),
		"brightness": light_brightness(),
		"music": is_music_playing(),
		"ended": _ended,
	}


func _input(event: InputEvent) -> void:
	# One tap scheme: a touch, or a real mouse click. Touches also arrive as
	# emulated clicks, which are skipped so a tap isn't counted twice.
	var pressed := false
	if event is InputEventScreenTouch:
		pressed = event.pressed
	elif event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
				and event.device != InputEvent.DEVICE_ID_EMULATION
	if pressed:
		get_viewport().set_input_as_handled()
		tap(event.position)


func _notification(what: int) -> void:
	# Native builds; the web says so through visibilitychange (see _ready).
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED] \
			and not OS.has_feature("web"):
		pause()


func _on_visibility_change(_args: Array) -> void:
	if _document and _document.hidden:
		pause()


# --- Each moment of the run.

func _update() -> void:
	if not _whole and _t >= RunPlan.SILENCE_START:
		# Everything stops at once, and the path is whole again.
		_whole = true
		for row in _rows.keys():
			_free_row(row)
	_update_sound()
	_update_obstacles()
	_update_rows()
	_update_light()
	_update_camera()
	_update_look()
	if not _ended and _t >= RunPlan.BLACK:
		_ended = true
		_music.stop()
		ended.emit()


func _update_sound() -> void:
	# The song and the storm are one track from 0:05 that ends itself at 2:55.
	if not _music_started and _t >= RunPlan.EUPHORIA_START and _t < RunPlan.SILENCE_START:
		_music_started = true
		_music.play(_t - RunPlan.EUPHORIA_START)
	if _t >= RunPlan.SILENCE_START and _music.playing:
		_music.stop()


func _update_obstacles() -> void:
	var d := light_distance()
	var ahead := AHEAD_SILENCE if _whole else AHEAD
	for i in _obstacles.size():
		var obstacle := _obstacles[i]
		# One that reaches the light uncleared: the light goes through it.
		if obstacle.status == Status.PENDING and _t >= obstacle.time:
			obstacle.status = Status.STUMBLED
			obstacle.at = obstacle.time
			_last_stumble = obstacle.time
			if _t - obstacle.time < 0.5:
				_stumble_player.play()
		var near: bool = obstacle.distance > d - BEHIND and obstacle.distance < d + ahead
		if near and obstacle.node == null:
			obstacle.node = _make_obstacle(obstacle)
		elif not near and obstacle.node != null:
			obstacle.node.queue_free()
			obstacle.node = null
		if obstacle.node:
			_pose_obstacle(i, obstacle)


func _update_rows() -> void:
	var d := light_distance()
	var low := floori((d - BEHIND) / TILE)
	var high := ceili((d + (AHEAD_SILENCE if _whole else AHEAD)) / TILE)
	for row in _rows.keys():
		if row < low or row > high:
			_free_row(row)
	for row in range(maxi(low, 0), high + 1):
		if not _rows.has(row):
			_build_row(row)
			_pose_row(row)
		elif _row_moves(row):
			_pose_row(row)


# Most tiles stay where they were built. Only a gap's tiles, and tiles
# falling away, are moved again each moment.
func _row_moves(row: int) -> bool:
	if _gap_rows.has(row):
		return true
	var falls: Vector2 = _row_falls[row]
	return _t >= falls.x and _t <= falls.y + 2.6


func _update_light() -> void:
	var d := light_distance()
	var b := light_brightness()
	var size := RunPlan.light_size(_t)
	var speed := clampf((RunPlan.distance(_t + 0.05) - d) / (0.05 * RunPlan.SPEED), 0.0, 1.0)
	var bob := 0.08 * sin(_t * TAU * 1.5) * speed
	var at := _path_at(d)
	_light.position = at + Vector3.UP * (LIGHT_HEIGHT + bob + _hop())
	_light.scale = Vector3.ONE * maxf(size, 0.001)
	_light.visible = b > 0.002 and size > 0.002
	_light_material.albedo_color = Color(LIGHT_COLOR, b)
	_lamp.position = _light.position + Vector3.UP * 0.4
	_lamp.light_energy = 2.4 * b
	_lamp.omni_range = 9.0 * maxf(size, 0.05)


# A gap the light goes over uncleared: it hops over with a lurch.
func _hop() -> float:
	var e := _t - _last_stumble
	if e < 0.0 or e >= 0.45:
		return 0.0
	for obstacle in _obstacles:
		if obstacle.kind == RunPlan.Kind.GAP and obstacle.status == Status.STUMBLED \
				and obstacle.at == _last_stumble:
			return 0.9 * sin(PI * e / 0.45)
	return 0.0


func _update_camera() -> void:
	var d := light_distance()
	var from := _path_at(d - 5.0) + Vector3.UP * 2.3
	var to := _path_at(d + 7.0) + Vector3.UP * 0.4
	_camera.look_at_from_position(from, to)


func _update_look() -> void:
	var k := 0
	while k < LOOKS.size() - 2 and _t >= LOOKS[k + 1][0]:
		k += 1
	var a: Array = LOOKS[k]
	var b: Array = LOOKS[k + 1]
	var f := clampf(inverse_lerp(a[0], b[0], _t), 0.0, 1.0) if b[0] > a[0] else 1.0
	var sky := Color(a[1]).lerp(Color(b[1]), f)
	var tile := Color(a[2]).lerp(Color(b[2]), f)
	_env.background_color = sky
	_env.fog_light_color = sky
	_env.ambient_light_color = sky.lerp(Color.WHITE, 0.3)
	_env.ambient_light_energy = lerpf(a[4], b[4], f)
	_env.fog_density = lerpf(a[5], b[5], f)
	_sun.light_energy = lerpf(a[3], b[3], f)
	_tile_materials[0].albedo_color = tile
	_tile_materials[1].albedo_color = tile.darkened(0.08)
	var raining := _t >= RAIN_START and _t < RunPlan.SILENCE_START
	_rain.visible = raining
	_rain.emitting = raining
	# Black before the light fades up, and black again at the very end.
	var black := 1.0 - smoothstep(RunPlan.EUPHORIA_START, RunPlan.EUPHORIA_START + 2.0, _t)
	black = maxf(black, smoothstep(RunPlan.BLACK - 1.5, RunPlan.BLACK, _t))
	_overlay.color = Color(0, 0, 0, black)


func _age_ripples(delta: float) -> void:
	for k in range(_ripples.size() - 1, -1, -1):
		_ripples[k].z += delta
		if _ripples[k].z >= RIPPLE_TIME:
			_ripples.remove_at(k)
	_ripple_layer.queue_redraw()


func _draw_ripples() -> void:
	for ripple in _ripples:
		var f := ripple.z / RIPPLE_TIME
		_ripple_layer.draw_arc(Vector2(ripple.x, ripple.y), lerpf(12.0, 56.0, f), 0.0, TAU, 40,
				Color(1, 1, 1, 0.5 * (1.0 - f)), 3.0, true)


# --- The path.

# Stored once: a point every metre, from the lamp to well past where the
# light stops. It bends and rises on its own (Choice: like Temple Run), gently
# in the euphoria, sharper and less evenly as the run goes on, and is flat
# and straight in the silence.
func _build_path() -> void:
	var end := RunPlan.distance(RunPlan.BLACK) + AHEAD_SILENCE + 20.0
	var heading := 0.0
	var at := Vector3.ZERO
	var s := 0.0
	while s <= end:
		at.y = _height(s)
		_path_points.append(at)
		_path_heading.append(heading)
		heading += _curvature(s) * PATH_STEP
		at += Vector3(sin(heading), 0.0, -cos(heading)) * PATH_STEP
		s += PATH_STEP


# How much of each part's shape the path has at distance s: 0 to 1 each.
func _weights(s: float) -> Vector4:
	var confusion := smoothstep(RunPlan.distance(RunPlan.CONFUSION_START) - 20.0,
			RunPlan.distance(RunPlan.CONFUSION_START) + 20.0, s)
	var panic := smoothstep(RunPlan.distance(RunPlan.PANIC_START) - 20.0,
			RunPlan.distance(RunPlan.PANIC_START) + 20.0, s)
	var silence := smoothstep(RunPlan.distance(RunPlan.SILENCE_START) - 45.0,
			RunPlan.distance(RunPlan.SILENCE_START) - 5.0, s)
	return Vector4(1.0 - confusion, confusion - panic, panic, 0.0) * (1.0 - silence)


func _curvature(s: float) -> float:
	var w := _weights(s)
	return w.x * 0.010 * sin(TAU * s / 260.0) \
			+ w.y * (0.028 * sin(TAU * s / 95.0) + 0.014 * sin(TAU * s / 37.0)) \
			+ w.z * (0.032 * sin(TAU * s / 70.0) + 0.018 * sin(TAU * s / 23.0))


func _height(s: float) -> float:
	var w := _weights(s)
	return w.x * 2.5 * sin(TAU * s / 300.0) + w.y * 3.0 * sin(TAU * s / 140.0) \
			+ w.z * 2.0 * sin(TAU * s / 80.0)


func _path_at(s: float) -> Vector3:
	var f := clampf(s / PATH_STEP, 0.0, _path_points.size() - 1.001)
	var i := int(f)
	return _path_points[i].lerp(_path_points[i + 1], f - i)


# The path's frame at s: x to the right, y up, z back toward the camera,
# tilted with the path's rises and dips.
func _path_basis(s: float) -> Basis:
	var f := clampf(s / PATH_STEP, 0.0, _path_heading.size() - 1.001)
	var i := int(f)
	var heading := lerpf(_path_heading[i], _path_heading[i + 1], f - i)
	var right := Vector3(cos(heading), 0.0, sin(heading))
	var forward := (_path_at(s + 0.5) - _path_at(s - 0.5)).normalized()
	return Basis(right, right.cross(forward), -forward)


# Which columns a row has. The euphoria and confusion are three tiles wide;
# the panic narrows to one; the silence is whole again.
func _columns(row: int) -> Array:
	var s := (row + 0.5) * TILE
	if _whole or s < RunPlan.distance(RunPlan.PANIC_START):
		return COLUMNS
	return [0]


# When a tile cracks and falls away, or INF if it never does. In the
# confusion some edge tiles drop as the light passes, only beside and
# behind it; in the panic each tile falls just after the light crosses it.
# Both come from where the tile is, so they are the same for every player.
func _fall_time(row: int, column: int) -> float:
	if _whole:
		return INF
	var s := (row + 0.5) * TILE
	var trigger := INF
	if s >= RunPlan.distance(RunPlan.PANIC_START):
		trigger = s + TILE * 0.6
	elif s >= RunPlan.distance(RunPlan.CONFUSION_START) + 10.0 and column != 0 \
			and (row * 7 + column * 3 + 11) % 5 < 2:
		trigger = s + 0.2
	if trigger == INF:
		return INF
	return RunPlan.EUPHORIA_START + trigger / RunPlan.SPEED


func _build_row(row: int) -> void:
	var tiles := [null, null, null]
	var falls := Vector2(INF, -INF)
	for column in _columns(row):
		var tile := MeshInstance3D.new()
		tile.mesh = _tile_mesh
		tile.material_override = _tile_materials[(row + column) & 1]
		var fall := _fall_time(row, column)
		tile.set_meta("fall", fall)
		if fall != INF:
			falls = Vector2(minf(falls.x, fall), maxf(falls.y, fall))
		add_child(tile)
		tiles[column + 1] = tile
	_rows[row] = tiles
	_row_falls[row] = falls


func _free_row(row: int) -> void:
	for tile: Node in _rows[row]:
		if tile:
			tile.queue_free()
	_rows.erase(row)
	_row_falls.erase(row)


func _pose_row(row: int) -> void:
	var s := (row + 0.5) * TILE
	var basis := _path_basis(s)
	var centre := _path_at(s) - basis.y * TILE_SIZE.y / 2.0
	var gap: Dictionary = _gap_rows.get(row, {})
	for column in COLUMNS:
		var tile: MeshInstance3D = _rows[row][column + 1]
		if tile == null:
			continue
		var place := Transform3D(basis, centre + basis.x * column * TILE)
		var fall: float = tile.get_meta("fall")
		var visible := true
		if _t > fall:
			# Cracks, then drops into the void, turning a little.
			var e := _t - fall
			place.origin.y -= 0.5 * GRAVITY * e * e
			place.basis = place.basis.rotated(basis.z, column * 0.6 * e + 0.2 * e)
			visible = e < 2.5
		if not gap.is_empty():
			# Missing until the gap is cleared; then the tiles rise up from below.
			if gap.status != Status.CLEARED:
				visible = false
			else:
				var rise := clampf((_t - gap.at) / 0.35, 0.0, 1.0)
				place.origin -= basis.y * 4.0 * pow(1.0 - rise, 2.0)
		tile.transform = place
		tile.visible = visible


# --- Obstacles.

func _make_obstacle(obstacle: Dictionary) -> Node3D:
	var node := Node3D.new()
	var body := MeshInstance3D.new()
	body.name = "Body"
	var first := floori(obstacle.distance / TILE)
	var width := TILE * _columns(first).size() - 0.2
	match obstacle.kind:
		RunPlan.Kind.STONE:
			var mesh := SphereMesh.new()
			mesh.radius = 0.5
			mesh.height = 0.85
			body.mesh = mesh
			body.position.y = 0.42
			body.material_override = _solid(Color("#8B8077"))
		RunPlan.Kind.BRANCH:
			var mesh := BoxMesh.new()
			mesh.size = Vector3(width, 0.18, 0.18)
			body.mesh = mesh
			body.position.y = 0.55
			body.material_override = _solid(Color("#6E5747"))
	node.add_child(body)
	# The warm outline it gets when it comes into reach, so it reads without
	# colour alone. A gap's is a bar along each of its edges.
	var line := StandardMaterial3D.new()
	line.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line.albedo_color = Color("#FFE2B0")
	var outline := Node3D.new()
	outline.name = "Outline"
	outline.set_meta("material", line)
	node.add_child(outline)
	if obstacle.kind == RunPlan.Kind.GAP:
		var bar := BoxMesh.new()
		bar.size = Vector3(width, 0.06, 0.12)
		for edge in [first * TILE, (first + 2) * TILE]:
			var rim := MeshInstance3D.new()
			rim.mesh = bar
			rim.material_override = line
			rim.position = Vector3(0.0, 0.02, obstacle.distance - edge)
			outline.add_child(rim)
	else:
		line.cull_mode = BaseMaterial3D.CULL_FRONT
		line.grow = true
		line.grow_amount = 0.07
		var shell := MeshInstance3D.new()
		shell.mesh = body.mesh
		shell.position = body.position
		shell.material_override = line
		outline.add_child(shell)
	add_child(node)
	return node


func _pose_obstacle(i: int, obstacle: Dictionary) -> void:
	var node: Node3D = obstacle.node
	var basis := _path_basis(obstacle.distance)
	var place := Transform3D(basis, _path_at(obstacle.distance))
	var outline: Node3D = node.get_node("Outline")
	var e: float = _t - obstacle.at
	var reach_for: float = _t - (obstacle.time - RunPlan.reach(obstacle.part))
	outline.visible = is_in_reach(i)
	(outline.get_meta("material") as StandardMaterial3D).albedo_color.a = clampf(reach_for / 0.15, 0.0, 1.0)
	node.visible = true
	if obstacle.kind == RunPlan.Kind.GAP:
		node.transform = place  # The gap is the missing tiles (_pose_row).
		return
	match obstacle.status:
		Status.CLEARED:
			node.visible = e < 2.0
			if obstacle.kind == RunPlan.Kind.STONE:
				# Rolls off the edge and drops away.
				var side := 1.0 if i % 2 else -1.0
				var across := 3.4 * smoothstep(0.0, 0.6, e)
				place.origin += basis.x * side * across
				if e > 0.45:
					place.origin.y -= 0.5 * GRAVITY * (e - 0.45) * (e - 0.45)
				place.basis = place.basis.rotated(basis.z, -side * across / 0.45)
			else:
				# Lifts up and out of the way.
				var up := smoothstep(0.0, 0.7, e)
				place.origin += basis.y * 4.0 * up
				place.basis = place.basis.rotated(basis.z, 0.5 * up)
				node.visible = e < 0.8
		Status.STUMBLED:
			# The light goes through it: the stone cracks apart, the branch
			# snaps. Shown by flattening and sinking it away; no shake.
			var gone := smoothstep(0.0, 0.5, e)
			place = place.scaled_local(Vector3(1.0 + 0.6 * gone, 1.0 - 0.9 * gone, 1.0 + 0.3 * gone))
			place.origin -= basis.y * 0.6 * gone
			node.visible = e < 0.6
	node.transform = place


# --- Building.

func _build_world() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	# Ordinary depth fog only: no volumetric fog, which the browser can't run.
	_env.fog_enabled = true
	_env.volumetric_fog_enabled = false
	var world := WorldEnvironment.new()
	world.environment = _env
	add_child(world)

	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-40.0, 30.0, 0.0)
	_sun.light_color = Color(1.0, 0.92, 0.8)
	_sun.shadow_enabled = false
	add_child(_sun)

	_camera = Camera3D.new()
	_camera.fov = 65.0
	_camera.far = 400.0
	add_child(_camera)
	_camera.make_current()

	_tile_mesh = BoxMesh.new()
	_tile_mesh.size = TILE_SIZE
	for k in 2:
		_tile_materials.append(_solid(Color.GRAY))

	_light_material = StandardMaterial3D.new()
	_light_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_light_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var ball := SphereMesh.new()
	ball.radius = LIGHT_RADIUS
	ball.height = LIGHT_RADIUS * 2.0
	_light = MeshInstance3D.new()
	_light.name = "Light"
	_light.mesh = ball
	_light.material_override = _light_material
	add_child(_light)
	# The light lights the tiles around it: the scene's main lamp.
	_lamp = OmniLight3D.new()
	_lamp.light_color = LIGHT_COLOR
	_lamp.shadow_enabled = false
	add_child(_lamp)

	# Rain in the panic: simple CPU particles, cheap on a phone.
	_rain = CPUParticles3D.new()
	_rain.amount = 350
	_rain.lifetime = 0.8
	_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain.emission_box_extents = Vector3(12.0, 0.1, 14.0)
	_rain.position = Vector3(0.0, 8.0, -10.0)
	_rain.direction = Vector3.DOWN
	_rain.spread = 4.0
	_rain.initial_velocity_min = 20.0
	_rain.initial_velocity_max = 24.0
	_rain.gravity = Vector3(0.0, -20.0, 0.0)
	var drop := BoxMesh.new()
	drop.size = Vector3(0.015, 0.45, 0.015)
	var wet := StandardMaterial3D.new()
	wet.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wet.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wet.albedo_color = Color(0.8, 0.82, 0.85, 0.45)
	drop.material = wet
	_rain.mesh = drop
	_camera.add_child(_rain)


func _solid(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.9
	return mat


func _build_sound() -> void:
	_music = AudioStreamPlayer.new()
	_music.stream = MUSIC
	add_child(_music)
	_clear_player = AudioStreamPlayer.new()
	_clear_player.stream = CLEAR_SOUND
	add_child(_clear_player)
	_stumble_player = AudioStreamPlayer.new()
	_stumble_player.stream = STUMBLE_SOUND
	add_child(_stumble_player)


# The black for the fade-up and the end, and the ripples. Nothing on it can
# be tapped: the whole screen is the target. No text, ever.
func _build_screen() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ripple_layer = Control.new()
	_ripple_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ripple_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ripple_layer.draw.connect(_draw_ripples)
	layer.add_child(_ripple_layer)
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color.BLACK
	layer.add_child(_overlay)
