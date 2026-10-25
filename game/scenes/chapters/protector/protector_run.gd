extends Node3D
## The Protector's run (DAS-97), in plain gray-box shapes: a small light runs
## away from the camera down a trail of square tiles through tall trees, and
## the father's hand keeps it safe. Tap the left or right of the screen and
## the hand moves the light one lane that way, out of the way of the stones
## and branches coming; with a gap in reach the tap also lays the hand
## across it. Seen from behind, like Temple Run; the path bends on its own.
## Built from docs/design/the-loss-run-and-car.md (Dan, 2026-10-25, revised
## after his first and second plays: calls 13 to 17).
##
## Everything follows one fixed timeline (run_plan.gd), the same for every
## player: the euphoria, the confusion, the panic, then the fade, where the
## light runs on in the rain, slows, settles into the father's open hand and
## goes out there. A stumble dims the light for a moment and changes nothing
## else. No words, no HUD, no retry, no skip, no shake, no flash.
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
const HAND_SOUND := preload("res://assets/audio/protector/placeholder_clear.wav")  # PLACEHOLDER
const STUMBLE_SOUND := preload("res://assets/audio/protector/placeholder_stumble.wav")  # PLACEHOLDER

## PASSED: it went by without touching the light (a stone or branch in
## another lane, or a gap the hand covered).
enum Status { PENDING, PASSED, STUMBLED }

const TILE := 1.6  # Metres from one tile's centre to the next.
const TILE_SIZE := Vector3(1.5, 0.3, 1.5)
const PATH_STEP := 1.0  # Metres between the path's stored points.
const BEHIND := 9.0  # Tiles are kept this far behind the light, then removed.
const AHEAD := 75.0  # And built this far ahead of it; the fog hides the end.
const CONTACT := 0.9  # An obstacle's centre is this far past the light when it touches.
const LIGHT_HEIGHT := 0.55
const LIGHT_RADIUS := 0.3
const LIGHT_COLOR := Color("#FFB45C")  # Warm amber, like the Partner's heart.
const SKIN := Color("#C8977A")  # The father's hand, in the gray box.
const GRAVITY := 14.0
const RIPPLE_TIME := 0.5
const SLOT := TILE * 2.0  # Trees and the forest floor come in slots this long.
const DRIFT_HOME := 2.0  # Seconds the light takes back to the middle as it slows.
const CRADLE_START := 187.0  # The hand starts to come in under the slowing light.

# The look of each part: sky (and fog), tiles, sun energy, ambient energy,
# fog density, sun colour, at run times between which it eases. Low gold sun
# between dark trunks, draining through the confusion to storm dark in the
# panic, and never lighter after (call 15). Colours, ordinary fog, one sun
# and lights only: no CompositorEffects, no volumetric fog.
const LOOKS := [
	[0.0, "#000000", "#000000", 0.0, 0.0, 0.03, "#FFC27A"],
	[RunPlan.EUPHORIA_START, "#000000", "#000000", 0.0, 0.0, 0.03, "#FFC27A"],
	[8.0, "#E3A15A", "#8E7B66", 1.7, 0.32, 0.012, "#FFC27A"],
	[RunPlan.CONFUSION_START, "#DE9752", "#8A775F", 1.6, 0.32, 0.014, "#FFBA70"],
	[100.0, "#8E8073", "#8C7E70", 0.6, 0.32, 0.026, "#D8C8B4"],
	[RunPlan.PANIC_START, "#4A4542", "#5A524C", 0.25, 0.28, 0.04, "#A8A8AC"],
	[142.0, "#22201F", "#3E3935", 0.06, 0.22, 0.06, "#9AA0A8"],
	[RunPlan.FADE_START, "#22201F", "#3E3935", 0.06, 0.22, 0.06, "#9AA0A8"],
	[RunPlan.STOPPED, "#1E1C1B", "#3A3532", 0.04, 0.2, 0.06, "#9AA0A8"],
	[RunPlan.BLACK, "#1E1C1B", "#3A3532", 0.04, 0.2, 0.06, "#9AA0A8"],
]

## False in tests, which move the clock with advance().
var auto_advance := true

var _t := 0.0
var _paused := false
var _ended := false
var _whole := false  # The fade: the path is whole and nothing falls.
var _music_started := false
var _obstacles: Array[Dictionary] = []
var _gap_rows := {}  # Row number -> the gap obstacle there.
var _last_stumble := -INF  # When the latest stumble happened.
var _lane := 0  # The lane the player last tapped: the one that counts.
var _lane_from_x := 0.0  # Where the light was when it set off for it.
var _lane_at := -INF  # When it set off.
var _lane_time := RunPlan.LANE_MOVE
var _push_dir := 0.0  # Which way the hand last pushed: -1 left, 1 right.
var _rows := {}  # Row number -> Array of 3 tiles.
var _row_falls := {}  # Row number -> when its first and last tiles fall.
var _slots := {}  # Slot number -> [left tree, right tree, ground].
var _path_points := PackedVector3Array()
var _path_heading := PackedFloat32Array()
var _ripples: Array[Vector3] = []  # x, y on screen, and age.

var _env: Environment
var _sun: DirectionalLight3D
var _camera: Camera3D
var _light: MeshInstance3D
var _light_material: StandardMaterial3D
var _lamp: OmniLight3D
var _hand: Node3D  # The hand that moves the light, and holds it at the end.
var _rain: CPUParticles3D
var _heavy_rain: CPUParticles3D
var _leaves: CPUParticles3D
var _tile_mesh: BoxMesh
var _tile_materials: Array[StandardMaterial3D] = []
var _trunk_mesh: CylinderMesh
var _canopy_mesh: SphereMesh
var _ground_mesh: BoxMesh
var _trunk_material: StandardMaterial3D
var _canopy_material: StandardMaterial3D
var _ground_material: StandardMaterial3D
var _skin: StandardMaterial3D
var _music: AudioStreamPlayer
var _hand_player: AudioStreamPlayer
var _stumble_player: AudioStreamPlayer
var _overlay: ColorRect
var _ripple_layer: Control
var _document: JavaScriptObject
var _visibility_callback: JavaScriptObject


func _ready() -> void:
	for plan in RunPlan.obstacles():
		var obstacle := plan.duplicate()
		obstacle.status = Status.PENDING
		obstacle.at = 0.0  # When it passed, was bridged or was stumbled.
		obstacle.bridged = false
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
## Obstacles before that point are passed over, neither passed nor stumbled.
func start_from(t: float) -> void:
	_t = t
	for obstacle in _obstacles:
		if obstacle.time < t:
			obstacle.status = Status.PASSED
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


## The lane that counts: the one last tapped, even while the hand is still
## moving the light there.
func lane() -> int:
	return _lane


## True from 3:05: the hand has come for the light, and taps only ripple.
func is_held() -> bool:
	return _t >= RunPlan.SLOW_START


func is_raining() -> bool:
	return _t >= RunPlan.RAIN_START


## True if obstacle `i` is a gap the hand can be laid across now.
func is_in_reach(i: int) -> bool:
	var obstacle := _obstacles[i]
	return obstacle.kind == RunPlan.Kind.GAP and obstacle.status == Status.PENDING \
			and not obstacle.bridged \
			and _t >= obstacle.time - RunPlan.reach(obstacle.part) and _t < obstacle.time


func obstacles() -> Array[Dictionary]:
	return _obstacles


func count(status: Status) -> int:
	var n := 0
	for obstacle in _obstacles:
		if obstacle.status == status and obstacle.at > -1000.0:
			n += 1
	return n


## A tap at a point on the screen: the left half moves the light one lane
## left, the right half one lane right (Dan, 2026-10-25, call 17). From an
## edge lane, a tap toward that edge leaves it where it is.
func tap(at: Vector2) -> int:
	var width := get_viewport().get_visible_rect().size.x
	var step := -1 if at.x < width / 2.0 else 1
	return tap_lane(clampi(_lane + step, -1, 1), at)


## A tap that sends the light to a lane. The hand moves the light there, and lays itself across a
## gap in reach; returns that gap's index, or -1. A tap that changes nothing
## (its own lane, no gap in reach) makes a ripple where it landed and nothing
## else: no penalty, no sound of failure. From 3:05 the hand is holding the
## light, and every tap only ripples.
func tap_lane(lane_tapped: int, at := Vector2.ZERO) -> int:
	if _paused:
		resume()  # The tap that brings the run back does nothing else.
		return -1
	if _ended:
		return -1
	if is_held():
		_ripples.append(Vector3(at.x, at.y, 0.0))
		return -1
	var bridged := -1
	for i in _obstacles.size():
		if is_in_reach(i):
			_obstacles[i].bridged = true
			_obstacles[i].at = _t
			bridged = i
			break
	var moved := lane_tapped != _lane
	if moved:
		_push_dir = signf(lane_tapped - _lane_x())
		_lane_from_x = _lane_x()
		_lane = lane_tapped
		_lane_at = _t
		_lane_time = RunPlan.LANE_MOVE
	if moved or bridged >= 0:
		_hand_player.play()
	else:
		_ripples.append(Vector3(at.x, at.y, 0.0))
	return bridged


func ripple_count() -> int:
	return _ripples.size()


func probe_state() -> Dictionary:
	var lit := 0
	var bridged := 0
	for i in _obstacles.size():
		if is_in_reach(i):
			lit += 1
		if _obstacles[i].bridged:
			bridged += 1
	return {
		"time": _t,
		"part": RunPlan.Part.keys()[part()],
		"paused": _paused,
		"lane": _lane,
		"in_reach": lit,
		"passed": count(Status.PASSED),
		"stumbled": count(Status.STUMBLED),
		"bridged": bridged,
		"brightness": light_brightness(),
		"size": RunPlan.light_size(_t),
		"held": is_held() and _hand.visible,
		"raining": is_raining() and _rain.emitting,
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
	if not _whole and _t >= RunPlan.FADE_START:
		# The obstacles have stopped, and the path is whole again.
		_whole = true
		for row in _rows.keys():
			_free_row(row)
	if _t >= RunPlan.SLOW_START and _lane_at < RunPlan.SLOW_START:
		# As it slows it drifts back to the middle, into the hand.
		_lane_from_x = _lane_x()
		_lane = 0
		_lane_at = RunPlan.SLOW_START
		_lane_time = DRIFT_HOME
		_push_dir = 0.0
	_update_sound()
	_update_obstacles()
	_update_rows()
	_update_trees()
	_update_light()
	_update_hand()
	_update_camera()
	_update_look()
	if not _ended and _t >= RunPlan.BLACK:
		_ended = true
		# PLACEHOLDER until the car (DAS-98), where the same rain carries on.
		_music.stop()
		ended.emit()


func _update_sound() -> void:
	# The song and the storm are one track from 0:05 to the black. The song
	# drowns under the storm by 2:55; the rain never stops.
	if not _music_started and _t >= RunPlan.EUPHORIA_START and _t < RunPlan.BLACK:
		_music_started = true
		_music.play(_t - RunPlan.EUPHORIA_START)


func _update_obstacles() -> void:
	var d := light_distance()
	for i in _obstacles.size():
		var obstacle := _obstacles[i]
		if obstacle.status == Status.PENDING and _t >= obstacle.time:
			# It reaches the light: blocked if the light's lane is one it
			# fills, or a gap the hand isn't across. Then the light goes
			# through it.
			var blocked: bool = (not obstacle.bridged) if obstacle.kind == RunPlan.Kind.GAP \
					else _lane in obstacle.lanes
			obstacle.status = Status.STUMBLED if blocked else Status.PASSED
			if blocked:
				obstacle.at = obstacle.time
				_last_stumble = obstacle.time
				if _t - obstacle.time < 0.5:
					_stumble_player.play()
			elif obstacle.kind != RunPlan.Kind.GAP:
				obstacle.at = obstacle.time
		var near: bool = obstacle.distance > d - BEHIND and obstacle.distance < d + AHEAD
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
	var high := ceili((d + AHEAD) / TILE)
	for row in _rows.keys():
		if row < low or row > high:
			_free_row(row)
	for row in range(maxi(low, 0), high + 1):
		if not _rows.has(row):
			_build_row(row)
			_pose_row(row)
		elif _row_moves(row):
			_pose_row(row)


# Most tiles stay where they were built. Only tiles falling away are moved
# again each moment.
func _row_moves(row: int) -> bool:
	var falls: Vector2 = _row_falls[row]
	return _t >= falls.x and _t <= falls.y + 2.6


func _update_trees() -> void:
	var d := light_distance()
	var low := floori((d - BEHIND - SLOT) / SLOT)
	var high := ceili((d + AHEAD) / SLOT)
	for slot in _slots.keys():
		if slot < low or slot > high:
			for node: Node in _slots[slot]:
				node.queue_free()
			_slots.erase(slot)
	for slot in range(maxi(low, 0), high + 1):
		if not _slots.has(slot):
			_build_slot(slot)
	# The wind: the trees sway, then bend, more in each part.
	var wind := _wind()
	if wind <= 0.0:
		return
	for slot in _slots.keys():
		for k in 2:
			var tree: Node3D = _slots[slot][k]
			var phase: float = tree.get_meta("phase")
			var lean := wind * (0.6 + 0.4 * sin(_t * 1.3 + phase)) + 0.25 * wind * sin(_t * 3.1 + phase * 2.0)
			tree.transform = tree.get_meta("base") * Transform3D(Basis(Vector3.BACK, lean), Vector3.ZERO)


## How hard the wind blows the trees over, in radians of lean.
func _wind() -> float:
	if _t < RunPlan.CONFUSION_START:
		return 0.0
	if _t < RunPlan.PANIC_START:
		return 0.035 * smoothstep(RunPlan.CONFUSION_START, RunPlan.PANIC_START, _t)
	if _t < RunPlan.FADE_START:
		return lerpf(0.035, 0.11, smoothstep(RunPlan.PANIC_START, RunPlan.PANIC_START + 8.0, _t))
	# The wind eases a little in the fade; the rain does not.
	return lerpf(0.11, 0.06, smoothstep(RunPlan.FADE_START, RunPlan.FADE_START + 10.0, _t))


# Where the light is across the path, in tiles from the middle.
func _lane_x() -> float:
	var f := smoothstep(0.0, _lane_time, _t - _lane_at) if _lane_time > 0.0 else 1.0
	return lerpf(_lane_from_x, float(_lane), f)


func _update_light() -> void:
	var d := light_distance()
	var b := light_brightness()
	var size := RunPlan.light_size(_t)
	var speed := clampf((RunPlan.distance(_t + 0.05) - d) / (0.05 * RunPlan.SPEED), 0.0, 1.0)
	var bob := 0.08 * sin(_t * TAU * 1.5) * speed
	var basis := _path_basis(d)
	var at := _path_at(d) + basis.x * _lane_x() * TILE
	_light.position = at + Vector3.UP * (LIGHT_HEIGHT + bob + _hop())
	_light.scale = Vector3.ONE * maxf(size, 0.001)
	_light.visible = b > 0.002 and size > 0.002
	_light_material.albedo_color = Color(LIGHT_COLOR, b)
	_lamp.position = _light.position + Vector3.UP * 0.4
	_lamp.light_energy = 2.4 * b
	_lamp.omni_range = 9.0 * maxf(size, 0.25)


# A gap the light goes over without the hand: it hops over with a lurch.
func _hop() -> float:
	var e := _t - _last_stumble
	if e < 0.0 or e >= 0.45:
		return 0.0
	for obstacle in _obstacles:
		if obstacle.kind == RunPlan.Kind.GAP and obstacle.status == Status.STUMBLED \
				and obstacle.at == _last_stumble:
			return 0.9 * sin(PI * e / 0.45)
	return 0.0


# The hand that moves the light: in from behind and below on the side it
# pushes from, across with the light, then back out of sight. From 3:05 it
# comes in under the light, palm up, and holds it as it stops and goes out;
# then it stays, empty, to the black.
func _update_hand() -> void:
	var d := light_distance()
	var basis := _path_basis(d)
	if _t >= CRADLE_START:
		var come := smoothstep(CRADLE_START, RunPlan.STOPPED - 1.0, _t)
		var rest := _path_at(d) + basis.x * _lane_x() * TILE + Vector3.UP * (LIGHT_HEIGHT - 0.22)
		var place := rest - basis.y * 1.6 * (1.0 - come) + basis.z * 2.5 * (1.0 - come)
		_hand.transform = Transform3D(basis, place)
		_hand.visible = true
		return
	var e := _t - _lane_at
	var total := 0.12 + RunPlan.LANE_MOVE + 0.45
	if _push_dir == 0.0 or e < 0.0 or e > total:
		_hand.visible = false
		return
	# Palm toward the light, fingers forward, on the far side from where it goes.
	var turned := basis * Basis(Vector3.BACK, -_push_dir * PI / 2.0)
	var beside := _path_at(d) + basis.x * (_lane_x() * TILE - _push_dir * 0.6) + Vector3.UP * LIGHT_HEIGHT
	var away := 0.0
	if e < 0.12:
		away = 1.0 - e / 0.12
	elif e > 0.12 + RunPlan.LANE_MOVE:
		away = (e - 0.12 - RunPlan.LANE_MOVE) / 0.45
	away = smoothstep(0.0, 1.0, away)
	_hand.transform = Transform3D(turned, beside + basis.z * 2.0 * away - basis.y * 1.2 * away)
	_hand.visible = true


func _update_camera() -> void:
	var d := light_distance()
	var from := _path_at(d - 4.0) + Vector3.UP * 2.1
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
	_sun.light_color = Color(a[6]).lerp(Color(b[6]), f)
	_tile_materials[0].albedo_color = tile
	_tile_materials[1].albedo_color = tile.darkened(0.08)
	# The rain never stops once it starts (call 15).
	_rain.emitting = is_raining()
	_rain.visible = is_raining()
	_heavy_rain.emitting = _t >= RunPlan.HEAVY_RAIN
	_heavy_rain.visible = _t >= RunPlan.HEAVY_RAIN
	_leaves.emitting = _t >= RunPlan.PANIC_START - 10.0
	_leaves.visible = _leaves.emitting
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
# and straight in the fade.
func _build_path() -> void:
	var end := RunPlan.distance(RunPlan.BLACK) + AHEAD + 20.0
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
	var fade := smoothstep(RunPlan.distance(RunPlan.FADE_START) - 45.0,
			RunPlan.distance(RunPlan.FADE_START) - 5.0, s)
	return Vector4(1.0 - confusion, confusion - panic, panic, 0.0) * (1.0 - fade)


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


# When a tile cracks and falls away, or INF if it never does. In the
# confusion some edge tiles drop just behind the light; in the panic each
# row falls just after the light crosses it. Both come from where the tile
# is, so they are the same for every player, and never in the light's way.
func _fall_time(row: int, column: int) -> float:
	if _whole:
		return INF
	var s := (row + 0.5) * TILE
	var trigger := INF
	if s >= RunPlan.distance(RunPlan.PANIC_START):
		trigger = s + TILE * 0.6
	elif s >= RunPlan.distance(RunPlan.CONFUSION_START) + 10.0 and column != 0 \
			and (row * 7 + column * 3 + 11) % 5 < 2:
		trigger = s + TILE * 0.8
	if trigger == INF:
		return INF
	return RunPlan.EUPHORIA_START + trigger / RunPlan.SPEED


func _build_row(row: int) -> void:
	var tiles := [null, null, null]
	var falls := Vector2(INF, -INF)
	# A gap is missing tiles across all three lanes; only the hand covers it.
	if not _gap_rows.has(row) or _whole:
		for column: int in RunPlan.LANES:
			var tile := MeshInstance3D.new()
			tile.mesh = _tile_mesh
			tile.material_override = _tile_materials[(row + column) & 1]
			tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
	for column: int in RunPlan.LANES:
		var tile: MeshInstance3D = _rows[row][column + 1]
		if tile == null:
			continue
		var place := Transform3D(basis, centre + basis.x * column * TILE)
		var fall: float = tile.get_meta("fall")
		var visible := true
		if _t > fall:
			# Cracks, then drops into the dark, turning a little.
			var e := _t - fall
			place.origin.y -= 0.5 * GRAVITY * e * e
			place.basis = place.basis.rotated(basis.z, column * 0.6 * e + 0.2 * e)
			visible = e < 2.5
		tile.transform = place
		tile.visible = visible


# --- The trees.

# A slot of forest: a tall dark trunk on each side of the trail, with its
# canopy high above, and the dark forest floor either side. Placed from the
# slot's number alone, so it is the same for every player.
func _build_slot(slot: int) -> void:
	var nodes: Array[Node3D] = []
	var s := (slot + 0.5) * SLOT
	var basis := _path_basis(s)
	var floor_at := _path_at(s) - basis.y * 0.9
	for side: int in [-1, 1]:
		var h := _hash01(slot, side)
		var tree := Node3D.new()
		var along := (h - 0.5) * SLOT * 0.8
		var out: float = side * (3.3 + 3.0 * _hash01(slot, side * 7))
		var root: Vector3 = _path_at(s + along) + basis.x * out - basis.y * 0.9
		var base := Transform3D(basis, root)
		tree.set_meta("base", base)
		tree.set_meta("phase", h * TAU)
		tree.transform = base
		var height := 10.0 + 5.0 * h
		var radius := 0.3 + 0.18 * _hash01(slot, side * 3)
		var trunk := MeshInstance3D.new()
		trunk.mesh = _trunk_mesh
		trunk.material_override = _trunk_material
		trunk.scale = Vector3(radius / 0.4, height, radius / 0.4)
		trunk.position = Vector3.UP * height / 2.0
		tree.add_child(trunk)
		var canopy := MeshInstance3D.new()
		canopy.mesh = _canopy_mesh
		canopy.material_override = _canopy_material
		canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		canopy.scale = Vector3.ONE * (2.4 + 1.2 * h)
		canopy.position = Vector3(-side * 0.8, height, 0.0)
		tree.add_child(canopy)
		add_child(tree)
		nodes.append(tree)
	var ground := Node3D.new()
	ground.transform = Transform3D(basis, floor_at)
	for side: int in [-1, 1]:
		var slab := MeshInstance3D.new()
		slab.mesh = _ground_mesh
		slab.material_override = _ground_material
		slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		slab.position = Vector3(side * (2.6 + _ground_mesh.size.x / 2.0), 0.0, 0.0)
		ground.add_child(slab)
	add_child(ground)
	nodes.append(ground)
	_slots[slot] = nodes


# A fixed number from 0 to 1 for a slot and side: scenery that looks
# scattered but is the same every time.
func _hash01(slot: int, side: int) -> float:
	var n := (slot * 73856093) ^ (side * 19349663 + 83492791)
	n = (n ^ (n >> 13)) * 1274126177
	return float(absi(n) % 10007) / 10007.0


# --- Obstacles.

func _make_obstacle(obstacle: Dictionary) -> Node3D:
	var node := Node3D.new()
	var first := floori(obstacle.distance / TILE)
	var line := StandardMaterial3D.new()
	line.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line.albedo_color = Color("#FFE2B0")
	var outline := Node3D.new()
	outline.name = "Outline"
	outline.set_meta("material", line)
	node.add_child(outline)
	if obstacle.kind == RunPlan.Kind.GAP:
		# The warm outline it gets when it comes into reach, so it reads
		# without colour alone: a bar along each of its edges.
		var bar := BoxMesh.new()
		bar.size = Vector3(TILE * 3.0 - 0.2, 0.06, 0.12)
		for edge in [first * TILE, (first + 2) * TILE]:
			var rim := MeshInstance3D.new()
			rim.mesh = bar
			rim.material_override = line
			rim.position = Vector3(0.0, 0.02, obstacle.distance - edge)
			outline.add_child(rim)
		# The hand that lies across it, fingers spanning the path.
		var hand := _make_hand()
		hand.name = "Hand"
		hand.visible = false
		hand.set_meta("centre", obstacle.distance - (first + 1) * TILE)
		node.add_child(hand)
		add_child(node)
		return node
	for lane: int in obstacle.lanes:
		var body := MeshInstance3D.new()
		match obstacle.kind:
			RunPlan.Kind.STONE:
				var mesh := SphereMesh.new()
				mesh.radius = 0.6
				mesh.height = 1.0
				body.mesh = mesh
				body.position = Vector3(lane * TILE, 0.5, 0.0)
				body.material_override = _solid(Color("#7D7268"))
			RunPlan.Kind.BRANCH:
				pass
		if body.mesh:
			node.add_child(body)
			_add_shell(outline, body, line)
	if obstacle.kind == RunPlan.Kind.BRANCH:
		# A fallen branch across its two lanes, low and thick.
		var lanes: Array = obstacle.lanes
		var mid: float = (lanes[0] + lanes[-1]) / 2.0
		var body := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.22
		mesh.bottom_radius = 0.28
		mesh.height = TILE * lanes.size() + 0.4
		body.mesh = mesh
		body.rotation = Vector3(0.0, 0.0, PI / 2.0)
		body.position = Vector3(mid * TILE, 0.45, 0.0)
		body.material_override = _solid(Color("#4E3A2C"))
		node.add_child(body)
		_add_shell(outline, body, line)
	add_child(node)
	return node


func _add_shell(outline: Node3D, body: MeshInstance3D, line: StandardMaterial3D) -> void:
	line.cull_mode = BaseMaterial3D.CULL_FRONT
	line.grow = true
	line.grow_amount = 0.07
	var shell := MeshInstance3D.new()
	shell.mesh = body.mesh
	shell.transform = body.transform
	shell.material_override = line
	outline.add_child(shell)


func _pose_obstacle(i: int, obstacle: Dictionary) -> void:
	var node: Node3D = obstacle.node
	var basis := _path_basis(obstacle.distance)
	var place := Transform3D(basis, _path_at(obstacle.distance))
	var outline: Node3D = node.get_node("Outline")
	var e: float = _t - obstacle.at
	# Lit softly as it comes close: a gap while the hand can be laid across
	# it; a stone or branch over the same stretch, so it is easy to read.
	var lit_from: float = obstacle.time - maxf(RunPlan.reach(obstacle.part), 0.8)
	var lit: bool = obstacle.status == Status.PENDING and _t >= lit_from \
			and not (obstacle.kind == RunPlan.Kind.GAP and obstacle.bridged)
	outline.visible = lit
	(outline.get_meta("material") as StandardMaterial3D).albedo_color.a = clampf((_t - lit_from) / 0.15, 0.0, 1.0)
	node.visible = true
	if obstacle.kind == RunPlan.Kind.GAP:
		node.transform = place
		var hand: Node3D = node.get_node("Hand")
		hand.visible = obstacle.bridged and _t < obstacle.time + 1.6
		if hand.visible:
			# Comes down from above and lies flat across the gap; lifts away
			# once the light is over.
			var down := smoothstep(0.0, 0.3, e)
			var up := smoothstep(obstacle.time + 0.6, obstacle.time + 1.5, _t)
			var across := Basis(Vector3.UP, -PI / 2.0).scaled(Vector3.ONE * 2.9)
			hand.transform = Transform3D(across, Vector3(-0.9, 0.1 + 3.0 * (1.0 - down) + 4.0 * up,
					hand.get_meta("centre")))
		return
	if obstacle.status == Status.STUMBLED:
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

	# The low sun, ahead and to the side, so the trunks throw long shadows
	# across the trail.
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-11.0, 155.0, 0.0)
	_sun.shadow_enabled = true
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_sun.directional_shadow_max_distance = 45.0
	add_child(_sun)

	_camera = Camera3D.new()
	_camera.fov = 58.0
	_camera.far = 400.0
	add_child(_camera)
	_camera.make_current()

	_tile_mesh = BoxMesh.new()
	_tile_mesh.size = TILE_SIZE
	for k in 2:
		_tile_materials.append(_solid(Color.GRAY))
	_trunk_mesh = CylinderMesh.new()
	_trunk_mesh.top_radius = 0.32
	_trunk_mesh.bottom_radius = 0.4
	_trunk_mesh.height = 1.0
	_trunk_mesh.radial_segments = 10
	_canopy_mesh = SphereMesh.new()
	_canopy_mesh.radius = 1.0
	_canopy_mesh.height = 1.4
	_canopy_mesh.radial_segments = 12
	_canopy_mesh.rings = 6
	_ground_mesh = BoxMesh.new()
	_ground_mesh.size = Vector3(10.0, 0.4, SLOT + 0.05)
	_trunk_material = _solid(Color("#2A1F17"))
	_canopy_material = _solid(Color("#2F3A22"))
	_ground_material = _solid(Color("#2E261D"))
	_skin = _solid(SKIN)
	_skin.roughness = 0.75

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
	_light.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_light)
	# The light lights the tiles around it: the scene's main lamp.
	_lamp = OmniLight3D.new()
	_lamp.light_color = LIGHT_COLOR
	_lamp.shadow_enabled = false
	add_child(_lamp)

	_hand = _make_hand()
	_hand.name = "Hand"
	_hand.visible = false
	add_child(_hand)

	# Rain from 1:50 to the black, heavier from 2:15, and leaves blowing in
	# the storm: simple CPU particles, cheap on a phone.
	_rain = _make_rain(160)
	_heavy_rain = _make_rain(520)
	_leaves = CPUParticles3D.new()
	_leaves.amount = 40
	_leaves.lifetime = 2.2
	_leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_leaves.emission_box_extents = Vector3(3.0, 3.0, 10.0)
	_leaves.position = Vector3(-9.0, 2.0, -9.0)
	_leaves.direction = Vector3(1.0, -0.2, 0.2)
	_leaves.spread = 20.0
	_leaves.initial_velocity_min = 6.0
	_leaves.initial_velocity_max = 10.0
	_leaves.gravity = Vector3(0.0, -1.5, 0.0)
	_leaves.angular_velocity_min = -200.0
	_leaves.angular_velocity_max = 200.0
	var leaf := QuadMesh.new()
	leaf.size = Vector2(0.14, 0.09)
	var brown := _solid(Color("#5B4630"))
	brown.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaf.material = brown
	_leaves.mesh = leaf
	_leaves.emitting = false
	_camera.add_child(_leaves)


func _make_rain(amount: int) -> CPUParticles3D:
	var rain := CPUParticles3D.new()
	rain.amount = amount
	rain.lifetime = 0.8
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(10.0, 0.1, 12.0)
	rain.position = Vector3(0.0, 7.0, -9.0)
	rain.direction = Vector3(0.12, -1.0, 0.0)
	rain.spread = 3.0
	rain.initial_velocity_min = 20.0
	rain.initial_velocity_max = 24.0
	rain.gravity = Vector3(0.0, -20.0, 0.0)
	var drop := BoxMesh.new()
	drop.size = Vector3(0.025, 0.6, 0.025)
	var wet := StandardMaterial3D.new()
	wet.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wet.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wet.albedo_color = Color(0.78, 0.8, 0.86, 0.5)
	drop.material = wet
	rain.mesh = drop
	rain.emitting = false
	_camera.add_child(rain)
	return rain


# The father's hand, in plain rounded shapes: a palm, four fingers and a
# thumb. Palm centre at the origin, fingers toward -z (forward), back of the
# hand up.
func _make_hand() -> Node3D:
	var hand := Node3D.new()
	var palm := MeshInstance3D.new()
	var palm_mesh := BoxMesh.new()
	palm_mesh.size = Vector3(0.82, 0.2, 0.9)
	palm.mesh = palm_mesh
	palm.material_override = _skin
	hand.add_child(palm)
	var finger_mesh := CapsuleMesh.new()
	finger_mesh.radius = 0.095
	finger_mesh.height = 0.78
	for k in 4:
		var finger := MeshInstance3D.new()
		finger.mesh = finger_mesh
		finger.material_override = _skin
		finger.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
		finger.position = Vector3(-0.3 + 0.2 * k, 0.0, -0.45 - 0.3 + 0.04 * absf(k - 1.5))
		hand.add_child(finger)
	var thumb := MeshInstance3D.new()
	var thumb_mesh := CapsuleMesh.new()
	thumb_mesh.radius = 0.11
	thumb_mesh.height = 0.6
	thumb.mesh = thumb_mesh
	thumb.material_override = _skin
	thumb.rotation = Vector3(-PI / 2.0, -0.6, 0.0)
	thumb.position = Vector3(0.5, -0.02, -0.15)
	hand.add_child(thumb)
	for part in hand.get_children():
		(part as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return hand


func _solid(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.9
	return mat


func _build_sound() -> void:
	_music = AudioStreamPlayer.new()
	_music.stream = MUSIC
	add_child(_music)
	_hand_player = AudioStreamPlayer.new()
	_hand_player.stream = HAND_SOUND
	add_child(_hand_player)
	_stumble_player = AudioStreamPlayer.new()
	_stumble_player.stream = STUMBLE_SOUND
	add_child(_stumble_player)


# The black for the fade-up and the end, and the ripples. Nothing on it can
# be tapped: each half of the screen moves the light a lane. No text, ever.
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
