extends Node3D
## The Protector's run (DAS-97): a small light runs away from the camera
## down a trail of square stepping stones through tall trees, and
## the father's hand keeps it safe. Tap the left or right of the screen and
## the hand moves the light one lane that way, out of the way of the stones
## and branches coming; hold a finger down with a gap in reach and the hand
## lays across it. Seen from behind, like Temple Run; the path bends on its
## own. Built from docs/design/the-loss-run-and-car.md (Dan, 2026-10-25,
## revised after each of his plays: calls 13 to 20).
##
## Everything follows one fixed timeline (run_plan.gd), the same for every
## player: the euphoria, the confusion, the panic, then the fade, where the
## light runs on in the rain, stops against a fallen tree it can't get past,
## and the father's hand comes under it; it goes out there. A stumble dims
## the light for a moment and changes nothing else. No words but the two
## hints at the start ("tap here", "hold"), no HUD, no retry, no skip, no
## shake, no flash.
##
## The run only reports `ended` (2:40, black). The chapter (protector.gd)
## decides what follows. It never touches the House or saved state.
##
## The run's clock moves in advance(), from _process; tests turn
## auto_advance off and move it themselves.
##
## The forest, the stepping stones, the stones and the fallen tree are from
## Quaternius's Stylized Nature MegaKit (CC0, DAS-106); the hand, the light,
## the fireflies and the rain are still drawn here.

## 2:40: the screen is black and the run is over.
signal ended

const RunPlan := preload("res://scenes/chapters/protector/run_plan.gd")
const HandMesh := preload("res://scenes/chapters/protector/hand_mesh.gd")
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
const GRAVITY := 14.0
const RIPPLE_TIME := 0.5
const SLOT := TILE * 2.0  # Trees and the forest floor come in slots this long.
const DRIFT_HOME := 2.0  # Seconds the light takes back to the middle as it slows.
const TREE_RADIUS := 0.75  # The fallen tree's trunk: taller than the light (call 20).
const TREE_LENGTH := 15.0  # Across the path and out past both edges into the trees.
const TREE_GAP := 1.0  # The light stops this far short of it (Dan, 2026-10-30).
const HINT_COLOR := Color(1.0, 0.97, 0.9, 0.85)
const HINT_SIZE := 34  # The hints' letters, in points.
const HINT_OUTLINE := 6  # The dark edge round them, so they read on the bright sky.
const GAP_SEEN := 3.0  # A gap's edges show faintly from this long before it arrives (call 21).
const GAP_FAINT := 0.35  # How bright they are until the gap is in reach.
const WARM_END := 3.0  # Everything is drawn once, unseen, in the dark before this.
const HOLD_START := 0.2  # A press this long is a hold, not a tap (call 19). Choice, to tune.
const MODELS := "res://assets/models/protector/"
const TREES := ["Pine_1", "Pine_2", "Pine_4", "Pine_5"]
const DEAD_TREES := ["DeadTree_1", "DeadTree_2"]
const STEPPING_STONES := ["RockPath_Square_Small_1", "RockPath_Square_Small_2", "RockPath_Square_Small_3"]
const STONE := "Rock_Medium_2"
# The undergrowth on the forest floor, with how big each is drawn (from the
# pack's own size) and how many go on each side in a patch. Only three
# kinds of material (leaves, grass, rock), so each patch is three draws.
const UNDERGROWTH := [
	["Fern_1", 0.22, 2], ["Grass_Common_Tall", 0.8, 2], ["Plant_1_Big", 0.35, 1],
	["Clover_1", 0.7, 1], ["Rock_Medium_1", 0.35, 1],
]
const PATCHES := 6  # Undergrowth patches, both sides of the trail, shared by every slot.
# How far from the camera the trees and the undergrowth are drawn, in
# metres. Each fades in over the last FADE_BAND of it, not all at once (Dan,
# 2026-10-30: "lots of pop in"). The path and what is in the way are built
# AHEAD, small and deep in the fog by then.
const UNDERGROWTH_SEEN := 36.0  # Past this it is too small to make out.
const TREES_SEEN := 60.0  # Past this the fog has mostly hidden them.
const FADE_BAND := 12.0
const FLOOR_TOP := 0.2  # The forest floor's height above the slot's floor point (m).
const FLOOR_STEP := 0.01  # How much higher every other slot's floor is (m).
const MAX_DENSITY := 2.0  # Pixels to each of the screen's points the 3D is drawn at, at most.

# The look of each part: sky (and fog), tiles, sun energy, ambient energy,
# fog density, sun colour, at run times between which it eases. Low gold sun
# between dark trunks, draining through the confusion to storm dark in the
# panic, and never lighter after (call 15). Colours, ordinary fog, one sun
# and lights only: no CompositorEffects, no volumetric fog.
const LOOKS := [
	[0.0, "#000000", "#000000", 0.0, 0.0, 0.03, "#FFC27A"],
	[RunPlan.EUPHORIA_START, "#000000", "#000000", 0.0, 0.0, 0.03, "#FFC27A"],
	[RunPlan.EUPHORIA_START + 3.0, "#E3A15A", "#8E7B66", 1.7, 0.32, 0.012, "#FFC27A"],
	[RunPlan.CONFUSION_START, "#DE9752", "#8A775F", 1.6, 0.32, 0.014, "#FFBA70"],
	[RunPlan.CONFUSION_START + 12.0, "#8E8073", "#8C7E70", 0.6, 0.32, 0.026, "#D8C8B4"],
	[RunPlan.PANIC_START, "#4A4542", "#5A524C", 0.25, 0.28, 0.04, "#A8A8AC"],
	[RunPlan.PANIC_START + 6.0, "#22201F", "#3E3935", 0.06, 0.22, 0.06, "#9AA0A8"],
	[RunPlan.FADE_START, "#22201F", "#3E3935", 0.06, 0.22, 0.06, "#9AA0A8"],
	[RunPlan.STOPPED, "#1E1C1B", "#3A3532", 0.04, 0.2, 0.06, "#9AA0A8"],
	[RunPlan.BLACK, "#1E1C1B", "#3A3532", 0.04, 0.2, 0.06, "#9AA0A8"],
]

## False in tests, which move the clock with advance().
var auto_advance := true
## The real clock, in seconds, that tells a tap from a hold: how long the
## finger is really down, not how far the run moved, so one slow frame can't
## turn a quick tap into a hold. Tests that step the run swap in its own clock.
var real_clock: Callable = func() -> float: return Time.get_ticks_usec() / 1000000.0
## When the finger went down, and when it came up (or now, while it is still
## down), on real_clock. On the web these are the browser's own times for the
## touch or click, because Godot only hears of it at the next frame: after a
## slow frame a quick tap would otherwise look long. Elsewhere, and in tests,
## the moment Godot hears of it.
var down_clock: Callable = func() -> float: return real_clock.call()
var up_clock: Callable = func() -> float: return real_clock.call()

var _t := 0.0
var _scale_before := 1.0  # The 3D's scale before the run, put back after.
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
var _press_at := -1.0  # When the finger went down; -1 when none is down.
var _press_real := 0.0  # The same moment by real_clock.
var _last_up := -INF  # When the last press lifted, by up_clock.
var _last_release := {}  # The last press's times, for the browser tests.
var _press_pos := Vector2.ZERO
var _press_index := 0  # Which finger: only the first one down counts.
var _holding := false  # The press has lasted HOLD_START: a hold.
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
var _tree: Node3D  # The fallen tree the light stops against (call 20).
var _tree_distance := 0.0
var _rain: CPUParticles3D
var _heavy_rain: CPUParticles3D
var _leaves: CPUParticles3D
var _tile_meshes: Array[Mesh] = []  # The stepping stones,
var _tile_fits: Array[Transform3D] = []  # and how each is sized to TILE_SIZE.
var _tile_materials: Array[StandardMaterial3D] = []
var _tree_meshes: Array[Mesh] = []
var _dead_tree_meshes: Array[Mesh] = []
var _patches: Array[Mesh] = []
var _plants := {}  # Undergrowth model -> its shape, shared by every patch.
var _trunk_mesh: CylinderMesh
var _ground_mesh: PlaneMesh
var _trunk_material: StandardMaterial3D
var _canopy_material: StandardMaterial3D
var _ground_material: StandardMaterial3D
var _skin: StandardMaterial3D
# Shared by every obstacle and hand, so none is built while the light runs.
# Only each obstacle's outline material is its own, since each fades in at
# its own moment; it is the same kind as the one drawn behind the black, so
# it costs no first-time stutter.
var _stone_mesh: Mesh
var _stone_material: StandardMaterial3D
var _branch_meshes := {}  # Lanes it spans -> CylinderMesh.
var _branch_material: StandardMaterial3D
var _bar_mesh: BoxMesh
var _hand_mesh: ArrayMesh
var _warm: Node3D  # One of each thing drawn in the dark, then freed (_build_warm).
var _firefly_mesh: SphereMesh
var _firefly_halo_mesh: SphereMesh
var _firefly_material: StandardMaterial3D  # Shared by the fireflies between the trees.
var _firefly_halo: StandardMaterial3D
var _last_fireflies: Array[Node3D] = []  # The ones left when the path empties (call 18).
var _music: AudioStreamPlayer
var _hand_player: AudioStreamPlayer
var _stumble_player: AudioStreamPlayer
var _overlay: ColorRect
var _ripple_layer: Control
var _tap_hints: Array[Label] = []  # "tap here", on the left half and the right.
var _hold_hint: Label
var _document: JavaScriptObject
var _visibility_callback: JavaScriptObject


func _ready() -> void:
	for plan in RunPlan.obstacles():
		var obstacle := plan.duplicate()
		obstacle.status = Status.PENDING
		obstacle.at = 0.0  # When it passed, was bridged or was stumbled.
		obstacle.bridged = false
		obstacle.lifted_at = -1.0  # When a hold ended before the light reached it.
		obstacle.distance = RunPlan.distance(plan.time) + CONTACT
		obstacle.node = null
		_obstacles.append(obstacle)
		if obstacle.kind == RunPlan.Kind.GAP:
			var first := floori(obstacle.distance / TILE)
			_gap_rows[first] = obstacle
			_gap_rows[first + 1] = obstacle
	_scale_before = get_viewport().scaling_3d_scale
	_build_path()
	_build_world()
	_build_sound()
	_build_screen()
	# A phone's screen has up to 3 pixels to each point. The forest is drawn
	# at no more than 2, which looks the same at arm's length and is about
	# half the work (Dan, 2026-10-30: it stuttered). Words stay sharp.
	get_viewport().scaling_3d_scale = scale_for(DisplayServer.screen_get_scale())
	if OS.has_feature("web"):
		_use_browser_times()
		_bring_sound_back()
		# Hiding the tab pauses the run; Godot doesn't say so on the web.
		_document = JavaScriptBridge.get_interface("document")
		_visibility_callback = JavaScriptBridge.create_callback(_on_visibility_change)
		_document.addEventListener("visibilitychange", _visibility_callback)
	_update()


# The browser notes when the first finger (or the left button) went down and
# came up, by its own clock; press() and release() read those times.
func _use_browser_times() -> void:
	JavaScriptBridge.eval("""
		if (!window.thresholdPointer) {
			const p = window.thresholdPointer = { down: -1, up: -1, touchEnd: -1 };
			const opts = { capture: true, passive: true };
			window.addEventListener('touchstart', (e) => {
				if (e.touches.length === 1) p.down = e.timeStamp / 1000;
			}, opts);
			window.addEventListener('touchend', (e) => {
				if (e.touches.length === 0) p.up = p.touchEnd = e.timeStamp / 1000;
			}, opts);
			window.addEventListener('mousedown', (e) => {
				if (e.button === 0 && e.timeStamp / 1000 - p.touchEnd > 1) p.down = e.timeStamp / 1000;
			}, opts);
			window.addEventListener('mouseup', (e) => {
				if (e.button === 0 && e.timeStamp / 1000 - p.touchEnd > 1) p.up = e.timeStamp / 1000;
			}, opts);
		}
	""", true)
	real_clock = func() -> float: return float(JavaScriptBridge.eval("performance.now() / 1000", true))
	down_clock = func() -> float: return _browser_time("down")
	# The finger may already be up in the browser before Godot hears of it.
	up_clock = func() -> float:
		var up := _browser_time("up")
		return up if up >= _browser_time("down") else real_clock.call()


# After the tab has been away, the first tap brings the sound back (Dan,
# 2026-10-27, call 20: it was lost and never came back). Safari can leave the
# page's sound stopped, or say it is running while it is silent, so the tap
# restarts every audio context the page made (the export's head_include keeps
# the list). It runs in the browser's own tap handler, which is the only place
# a phone lets sound start. Only while the run is on screen.
func _bring_sound_back() -> void:
	JavaScriptBridge.eval("""
		if (!window.thresholdSoundBack) {
			const back = window.thresholdSoundBack = { on: false, away: false, restarts: 0 };
			document.addEventListener('visibilitychange', () => {
				if (document.hidden) back.away = true;
			});
			const tapped = () => {
				if (!back.on || document.hidden) return;
				for (const ctx of window.thresholdAudioContexts || []) {
					if (ctx.state === 'closed') continue;
					if (ctx.state !== 'running') {
						ctx.resume();
					} else if (back.away) {
						// Both asked for inside the tap, so a phone allows the resume.
						back.restarts += 1;
						ctx.suspend();
						ctx.resume();
					}
				}
				back.away = false;
			};
			for (const type of ['touchend', 'mouseup', 'keydown']) {
				window.addEventListener(type, tapped, true);
			}
		}
		window.thresholdSoundBack.on = true;
		window.thresholdSoundBack.away = false;
	""", true)


func _browser_time(which: String) -> float:
	var at: Variant = JavaScriptBridge.eval("window.thresholdPointer.%s" % which, true)
	return float(at) if at != null and float(at) >= 0.0 else real_clock.call()


func _exit_tree() -> void:
	get_viewport().scaling_3d_scale = _scale_before
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (window.thresholdSoundBack) window.thresholdSoundBack.on = false;", true)
	if _document:
		_document.removeEventListener("visibilitychange", _visibility_callback)
		_document = null


func _process(delta: float) -> void:
	if auto_advance:
		advance(delta)
	_age_ripples(delta)


## How much of the screen's own pixel density the 3D is drawn at, for a
## screen with `screen_scale` pixels to each point: at most MAX_DENSITY.
static func scale_for(screen_scale: float) -> float:
	return minf(1.0, MAX_DENSITY / maxf(screen_scale, 1.0))


## Moves the run's clock on by `delta` seconds (nothing moves while paused).
func advance(delta: float) -> void:
	if _paused or _ended:
		return
	_t += delta
	if _press_at >= 0.0 and not _holding and _up_time() - _press_real >= HOLD_START:
		_start_hold()
	if _holding:
		_lay_hand_across()
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
	# The finger is gone by the time anyone comes back.
	if _holding:
		_let_go()
	_press_at = -1.0
	_holding = false


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


## True from 2:15: the light is slowing at the fallen tree, the hand is
## coming for it, and taps only ripple.
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


## A finger (or the mouse button) goes down at a point on the screen.
## Nothing moves yet: if it lifts within HOLD_START it is a tap, and if it
## stays down it is a hold (Dan, 2026-10-27, call 19). The press that brings
## a paused run back does nothing else.
func press(at: Vector2) -> void:
	if _paused:
		resume()
		return
	if _ended or _press_at >= 0.0:
		return
	_press_at = _t
	_press_real = down_clock.call()
	# A browser time from before the last lift belongs to an earlier press
	# (one the browser didn't note, such as a second finger): use now.
	if _press_real <= _last_up:
		_press_real = real_clock.call()
	_press_pos = at


## The finger lifts. A quick press was a tap, and moves the light a lane
## now; the end of a hold lifts the hand from a gap the light hasn't reached.
func release(at: Vector2) -> void:
	if _press_at < 0.0:
		return
	# How long the finger was really down decides, whatever the frames saw.
	# Held long enough is a hold, even if no frame has come since to say so:
	# a slow frame must not turn a hold into a tap. And a quick tap is a tap
	# even if a slow frame took it for a hold: the browser can hand the page
	# the lift only after that frame (CI's phone runs, 2026-10-27), so the
	# hand comes off and the lane moves.
	_last_up = _up_time()
	var was_hold: bool = _last_up - _press_real >= HOLD_START
	_last_release = {"down": _press_real, "up": _last_up, "hold": was_hold, "now": real_clock.call()}
	_press_at = -1.0
	var was_holding := _holding
	_holding = false
	if was_hold or was_holding:
		_let_go()
	if not was_hold:
		tap(at)


# When the finger lifted, or now if it hasn't. A browser lift from before this
# press belongs to an earlier one (a click just after a touch, which the
# browser hook ignores): use now (Hopper, 2026-10-27).
func _up_time() -> float:
	var up: float = up_clock.call()
	# The same time is this press's own lift: a tap the browser sent at once.
	return up if up >= _press_real else real_clock.call()


func is_holding() -> bool:
	return _holding


## A tap at a point on the screen: the left half moves the light one lane
## left, the right half one lane right (Dan, 2026-10-25, call 17). From an
## edge lane, a tap toward that edge leaves it where it is.
func tap(at: Vector2) -> bool:
	var width := get_viewport().get_visible_rect().size.x
	var step := -1 if at.x < width / 2.0 else 1
	return tap_lane(clampi(_lane + step, -1, 1), at)


## A tap that sends the light to a lane: the hand moves the light there.
## Returns whether it moved. A tap that changes nothing (its own lane) makes
## a ripple where it landed and nothing else: no penalty, no sound of
## failure. A tap never bridges a gap; a hold does (call 19). From 2:15 the
## hand is holding the light, and every tap only ripples.
func tap_lane(lane_tapped: int, at := Vector2.ZERO) -> bool:
	if _paused:
		resume()  # The tap that brings the run back does nothing else.
		return false
	if _ended:
		return false
	var moved := lane_tapped != _lane and not is_held()
	if moved:
		_push_dir = signf(lane_tapped - _lane_x())
		_lane_from_x = _lane_x()
		_lane = lane_tapped
		_lane_at = _t
		_lane_time = RunPlan.LANE_MOVE
		_hand_player.play()
	else:
		_ripples.append(Vector3(at.x, at.y, 0.0))
	return moved


# The press has lasted long enough to be a hold. With nothing to lay the
# hand across now, it ripples; a gap that comes into reach while the finger
# stays down still gets the hand.
func _start_hold() -> void:
	_holding = true
	var any := false
	for i in _obstacles.size():
		if is_in_reach(i):
			any = true
	if not any or is_held():
		_ripples.append(Vector3(_press_pos.x, _press_pos.y, 0.0))


# While the finger is down, the hand lies across every gap in reach.
func _lay_hand_across() -> int:
	var bridged := -1
	if is_held():
		return bridged
	for i in _obstacles.size():
		if is_in_reach(i):
			_obstacles[i].bridged = true
			_obstacles[i].at = _t
			_obstacles[i].lifted_at = -1.0
			_hand_player.play()
			bridged = i
	return bridged


# The finger lifts: the hand comes up off any gap the light hasn't reached,
# so that gap is open again when it arrives. Once the light is on the hand,
# letting go changes nothing.
func _let_go() -> void:
	for obstacle in _obstacles:
		if obstacle.kind == RunPlan.Kind.GAP and obstacle.bridged and obstacle.status == Status.PENDING:
			obstacle.bridged = false
			obstacle.lifted_at = _t


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
		"holding": _holding,
		"pressed": _press_at >= 0.0,
		"last_release": _last_release,
		"brightness": light_brightness(),
		"size": RunPlan.light_size(_t),
		"held": is_held() and _hand.visible,
		"raining": is_raining() and _rain.emitting,
		"fireflies": fireflies_glowing(),
		"hints": hints_shown(),
		"music": is_music_playing(),
		"ended": _ended,
	}


func _input(event: InputEvent) -> void:
	# One tap scheme: a touch, or a real mouse click, going down and lifting
	# (a tap or a hold, call 19). Touches also arrive as emulated clicks,
	# which are skipped so a press isn't counted twice.
	if event is InputEventScreenTouch:
		if event.index != _press_index and _press_at >= 0.0:
			return  # Only the first finger down counts.
		_press_index = event.index
	elif not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT
			and event.device != InputEvent.DEVICE_ID_EMULATION):
		return
	get_viewport().set_input_as_handled()
	if event.pressed:
		press(event.position)
	else:
		release(event.position)


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
		# The obstacles have stopped, and the path is whole again: no tile
		# still whole will fall, and every row built from now on is whole.
		# Tiles already falling behind the light carry on, so nothing snaps
		# back, and nothing is rebuilt all in one frame.
		_whole = true
		for row in _rows.keys():
			var falls := Vector2(INF, -INF)
			for tile: Variant in _rows[row]:
				if not is_instance_valid(tile):
					continue
				if _t < float(tile.get_meta("fall")):
					tile.set_meta("fall", INF)
				else:
					falls = Vector2(minf(falls.x, tile.get_meta("fall")), maxf(falls.y, tile.get_meta("fall")))
			_row_falls[row] = falls
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
	_update_fireflies()
	_update_light()
	_update_hand()
	_update_camera()
	_update_look()
	_update_hints()
	_tree.visible = light_distance() > _tree_distance - AHEAD
	if _warm and _t >= WARM_END:
		_warm.queue_free()
		_warm = null
	elif _warm:
		# The sun and the light's lamp are on too, behind the black, so
		# everything is ready to be drawn lit before the light fades up.
		_sun.light_energy = 1.7
		_lamp.light_energy = 2.4
		# Far enough to reach everything drawn here: the seed-sized light's
		# own reach falls short, and the hand's skin then got ready only
		# when the hand first came near the light, with a hitch.
		_lamp.omni_range = 12.0
	if not _ended and _t >= RunPlan.BLACK:
		_ended = true
		# PLACEHOLDER until the car (DAS-98), where the same rain carries on.
		_music.stop()
		ended.emit()


func _update_sound() -> void:
	# The song and the storm are one track from 0:03 to the black. The song
	# drowns under the storm by 2:08; the rain never stops.
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
# pushes from, across with the light, then back out of sight. Once the light
# has stopped at the fallen tree (2:17) it comes in under it, palm up,
# and holds it as it goes out; then it stays, empty, to the black.
func _update_hand() -> void:
	var d := light_distance()
	var basis := _path_basis(d)
	if _t >= RunPlan.STOPPED:
		var come := smoothstep(RunPlan.STOPPED, RunPlan.HELD - 0.5, _t)
		var rest := _path_at(d) + basis.x * _lane_x() * TILE + Vector3.UP * (LIGHT_HEIGHT - 0.22)
		var place := rest - basis.y * 1.6 * (1.0 - come) + basis.z * 2.5 * (1.0 - come)
		# Palm up, fingers forward, cupped a little round the light.
		_hand.transform = Transform3D(basis * Basis(Vector3.BACK, PI), place)
		_hand.visible = true
		return
	var e := _t - _lane_at
	var total := 0.12 + RunPlan.LANE_MOVE + 0.45
	if _push_dir == 0.0 or e < 0.0 or e > total:
		_hand.visible = false
		return
	# On the far side from where it goes, standing up as a hand does to push
	# something sideways: fingers up and a little forward, palm to the light
	# and a little ahead of it, so from behind the camera sees its back and
	# fingers, not its edge.
	var fingers := Vector3(0.0, 1.0, -0.35).normalized()
	var palm := Vector3(_push_dir, 0.0, -0.6).normalized()
	var x := (-palm).cross(-fingers)
	var turned := basis * Basis(x * _push_dir, -palm, -fingers).orthonormalized()
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
	# The stones' own colours show through the light of each part.
	tile = tile.lerp(Color.WHITE, 0.35)
	_tile_materials[0].albedo_color = tile
	_tile_materials[1].albedo_color = tile.darkened(0.08)
	# The rain never stops once it starts (call 15).
	_rain.emitting = is_raining()
	_rain.visible = is_raining()
	# The first drops are faint and thicken as the rain is heard (call 21).
	(_rain.mesh.material as StandardMaterial3D).albedo_color.a = lerpf(0.15, 0.5,
			smoothstep(RunPlan.RAIN_START, RunPlan.RAIN_START + 10.0, _t))
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
	if _warm:
		# Behind the black, unseen: one ripple, and the "hold" hint's word in
		# its own font, size and outline, so neither the first real ripple (a
		# hold with no gap in reach) nor the hint at the first gaps stops to
		# get its drawing ready (Dan, 2026-10-30: "when i did the first hold
		# it stuttered").
		var middle := _ripple_layer.size / 2.0
		_ripple_layer.draw_arc(middle, 30.0, 0.0, TAU, 40, Color(1, 1, 1, 0.01), 3.0, true)
		var font := _ripple_layer.get_theme_font("font", "Label")
		_ripple_layer.draw_string_outline(font, middle, RunPlan.HOLD_HINT, HORIZONTAL_ALIGNMENT_LEFT, -1,
				HINT_SIZE, HINT_OUTLINE, Color(0, 0, 0, 0.01))
		_ripple_layer.draw_string(font, middle, RunPlan.HOLD_HINT, HORIZONTAL_ALIGNMENT_LEFT, -1,
				HINT_SIZE, Color(HINT_COLOR, 0.01))
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
			var kind := (row * 5 + column * 3 + 7) % _tile_meshes.size()
			tile.mesh = _tile_meshes[kind]
			tile.lod_bias = 0.5
			tile.set_meta("fit", _tile_fits[kind])
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
		tile.transform = place * tile.get_meta("fit")
		tile.visible = visible


# --- The trees.

# A slot of forest: a tall tree on one side of the trail, the next slot's on
# the other (the pack's pines are bushy, and each one costs a phone more than
# the gray-box trunk did), and the dark forest floor either side with its
# undergrowth. Placed from the slot's number alone, so it is the same for
# every player. Toward the panic more of the trees are dead (Choice, DAS-106).
func _build_slot(slot: int) -> void:
	var nodes: Array[Node3D] = []
	var s := (slot + 0.5) * SLOT
	var basis := _path_basis(s)
	var floor_at := _path_at(s) - basis.y * 0.9
	var dead_share := 0.45 * smoothstep(RunPlan.distance(RunPlan.CONFUSION_START),
			RunPlan.distance(RunPlan.PANIC_START), s)
	for side: int in [-1, 1]:
		var h := _hash01(slot, side)
		var tree := Node3D.new()
		var along := (h - 0.5) * SLOT * 0.8
		# Far enough out that the pines' lowest branches clear the trail.
		var out: float = side * (4.8 + 3.5 * _hash01(slot, side * 7))
		var root: Vector3 = _path_at(s + along) + basis.x * out - basis.y * 0.9
		var base := Transform3D(basis, root)
		tree.set_meta("base", base)
		tree.set_meta("phase", h * TAU)
		tree.transform = base
		nodes.append(tree)
		add_child(tree)
		if (slot + (0 if side < 0 else 1)) % 2 == 0:
			continue  # This side's tree is in the next slot.
		var dead := _hash01(slot, side * 5) < dead_share
		var kinds := _dead_tree_meshes if dead else _tree_meshes
		var model := MeshInstance3D.new()
		model.mesh = kinds[int(_hash01(slot, side * 3) * kinds.size()) % kinds.size()]
		# 10 to 15 m tall, like the trunks they replace, but no wider than
		# the pack's, so their branches stay out of the way where the path
		# bends. Turned at random.
		var height := 10.0 + 5.0 * h
		model.scale = Vector3(0.9, height / model.mesh.get_aabb().end.y, 0.9)
		model.rotation.y = TAU * _hash01(slot, side * 9)
		model.lod_bias = 0.25  # The pack's simpler shapes sooner: the fog hides the difference.
		model.visibility_range_end = TREES_SEEN
		tree.add_child(model)
	var ground := Node3D.new()
	ground.transform = Transform3D(basis, floor_at)
	for side: int in [-1, 1]:
		var slab := MeshInstance3D.new()
		slab.mesh = _ground_mesh
		slab.material_override = _ground_material
		slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Every other slot 1 cm higher, so where neighbours overlap one is
		# plainly on top and their surfaces don't flicker through each other.
		# A flat sheet, not a box, so the step has no edge to show as a line.
		slab.position = Vector3(side * (2.6 + _ground_mesh.size.x / 2.0), FLOOR_TOP + FLOOR_STEP * (slot % 2), 0.0)
		ground.add_child(slab)
	var patch := MeshInstance3D.new()
	patch.mesh = _patches[int(_hash01(slot, 19) * PATCHES) % PATCHES]
	patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	patch.visibility_range_end = UNDERGROWTH_SEEN
	patch.position = Vector3.UP * FLOOR_TOP
	ground.add_child(patch)
	add_child(ground)
	nodes.append(ground)
	# A firefly on each side, drifting between the trunks. Each has its own
	# threshold, so as the storm comes they go one by one (firefly_density).
	for side: int in [-1, 1]:
		var h := _hash01(slot, side * 11)
		var firefly := _make_firefly(_firefly_material, _firefly_halo)
		var along := (_hash01(slot, side * 13) - 0.5) * SLOT
		var at: float = s + along
		firefly.set_meta("base", _path_at(at) + _path_basis(at).x * side * (2.4 + 3.0 * h)
				+ Vector3.UP * (0.4 + 2.4 * _hash01(slot, side * 17)))
		firefly.set_meta("threshold", h)
		firefly.set_meta("phase", h * TAU * 3.0)
		add_child(firefly)
		nodes.append(firefly)
	_slots[slot] = nodes


# --- The fireflies.

# A firefly: a small warm point and a faint glow round it, both unshaded and
# not dimmed by the fog, so they show through the storm. They light nothing:
# the world never gets lighter from them.
func _make_firefly(core: StandardMaterial3D, halo: StandardMaterial3D) -> Node3D:
	var firefly := Node3D.new()
	for part: Array in [[_firefly_mesh, core], [_firefly_halo_mesh, halo]]:
		var mesh := MeshInstance3D.new()
		mesh.mesh = part[0]
		mesh.material_override = part[1]
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		firefly.add_child(mesh)
	return firefly


func _firefly_material_with(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.disable_fog = true
	mat.albedo_color = colour
	return mat


func _build_last_fireflies() -> void:
	var rest := RunPlan.distance(RunPlan.STOPPED)
	for plan: Array in RunPlan.LAST_FIREFLIES:
		var at: float = rest + plan[0]
		var firefly := _make_firefly(_firefly_material.duplicate(), _firefly_halo.duplicate())
		firefly.position = _path_at(at) + _path_basis(at).x * plan[1] + Vector3.UP * plan[2]
		firefly.set_meta("plan", plan)
		firefly.visible = false
		add_child(firefly)
		_last_fireflies.append(firefly)


func _update_fireflies() -> void:
	var density := RunPlan.firefly_density(_t)
	for slot in _slots.keys():
		var nodes: Array = _slots[slot]
		for k in range(3, nodes.size()):
			var firefly: Node3D = nodes[k]
			firefly.visible = firefly.get_meta("threshold") < density
			if firefly.visible:
				var phase: float = firefly.get_meta("phase")
				firefly.position = firefly.get_meta("base") + Vector3(0.3 * sin(_t * 0.7 + phase),
						0.18 * sin(_t * 1.1 + phase * 1.7), 0.3 * cos(_t * 0.6 + phase))
	# The last ones: low by the trail from the panic on, each going out at its
	# own moment once the path is empty, and some never.
	for k in _last_fireflies.size():
		var firefly := _last_fireflies[k]
		var glow := RunPlan.firefly_glow(firefly.get_meta("plan"), _t)
		firefly.visible = _t >= RunPlan.PANIC_START and glow > 0.0
		if firefly.visible:
			var shimmer := 0.8 + 0.2 * sin(_t * (1.1 + 0.37 * k) + k * 2.1)
			(firefly.get_child(0) as MeshInstance3D).material_override.albedo_color.a = glow * shimmer
			(firefly.get_child(1) as MeshInstance3D).material_override.albedo_color.a = 0.22 * glow * shimmer


## How many of the last fireflies are glowing now (for tests).
func fireflies_glowing() -> int:
	var n := 0
	for firefly in _last_fireflies:
		if firefly.visible and RunPlan.firefly_glow(firefly.get_meta("plan"), _t) > 0.5:
			n += 1
	return n


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
	# A gap's edges show through the fog, so the empty space reads in the
	# dark too (Dan, 2026-10-27, call 21).
	line.disable_fog = obstacle.kind == RunPlan.Kind.GAP
	var outline := Node3D.new()
	outline.name = "Outline"
	outline.set_meta("material", line)
	node.add_child(outline)
	if obstacle.kind == RunPlan.Kind.GAP:
		# A pale rim along each of its edges, faint as it comes and bright
		# once it is in reach, so it reads without colour alone.
		for edge in [first * TILE, (first + 2) * TILE]:
			var rim := MeshInstance3D.new()
			rim.mesh = _bar_mesh
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
				body.mesh = _stone_mesh
				body.position = Vector3(lane * TILE, 0.5, 0.0)
				body.material_override = _stone_material
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
		body.mesh = _branch_mesh(lanes.size())
		body.rotation = Vector3(0.0, 0.0, PI / 2.0)
		body.position = Vector3(mid * TILE, 0.45, 0.0)
		body.material_override = _branch_material
		node.add_child(body)
		_add_shell(outline, body, line)
	add_child(node)
	return node


func _branch_mesh(lanes: int) -> CylinderMesh:
	if not _branch_meshes.has(lanes):
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.22
		mesh.bottom_radius = 0.28
		# Short, ending just past the middle of its second lane, so the free lane
		# beside it is plainly empty (Dan, 2026-10-27, call 20).
		mesh.height = TILE * (lanes - 1) + 0.6  # Shorter again (call 21).
		_branch_meshes[lanes] = mesh
	return _branch_meshes[lanes]


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
	# A gap's edges also show faintly from GAP_SEEN before it arrives.
	var reach_from: float = obstacle.time - maxf(RunPlan.reach(obstacle.part), 0.8)
	var gap: bool = obstacle.kind == RunPlan.Kind.GAP
	var lit_from: float = obstacle.time - GAP_SEEN if gap else reach_from
	var lit: bool = obstacle.status == Status.PENDING and _t >= lit_from \
			and not (gap and obstacle.bridged)
	outline.visible = lit
	var glow := clampf((_t - reach_from) / 0.15, 0.0, 1.0)
	if gap:
		glow = maxf(glow, GAP_FAINT * clampf((_t - lit_from) / 0.3, 0.0, 1.0))
	(outline.get_meta("material") as StandardMaterial3D).albedo_color.a = glow
	node.visible = true
	if obstacle.kind == RunPlan.Kind.GAP:
		node.transform = place
		var hand: Node3D = node.get_node("Hand")
		var lifting: bool = obstacle.lifted_at >= 0.0 and _t < obstacle.lifted_at + 0.35
		hand.visible = (obstacle.bridged and _t < obstacle.time + 1.6) or lifting
		if lifting and not obstacle.bridged:
			# Let go too soon: the hand lifts off before the light gets there.
			var off := smoothstep(obstacle.lifted_at, obstacle.lifted_at + 0.35, _t)
			var flat := Basis(Vector3.UP, -PI / 2.0).scaled(Vector3.ONE * 2.9)
			hand.transform = Transform3D(flat, Vector3(-0.9, 0.1 + 3.0 * off, hand.get_meta("centre")))
		elif hand.visible:
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

	# The stepping stones: each fills a tile, its top where the box's was.
	var path_rocks: Texture2D = load(MODELS + "PathRocks_Diffuse.png")
	# Placed by a transform, not reshaped, so they keep the pack's simpler
	# shapes for when they are far away.
	for stone: String in STEPPING_STONES:
		var mesh := _pack_mesh(stone)
		_tile_meshes.append(mesh)
		# A little bigger than the tile, so the stones meet across the lanes
		# and from row to row: no sky shows between them.
		_tile_fits.append(_fit(mesh, Vector3(TILE + 0.1, TILE_SIZE.y, TILE + 0.1)))
	for k in 2:
		var tile := _solid(Color.GRAY)
		tile.albedo_texture = path_rocks
		_plain(tile)
		_tile_materials.append(tile)
	# Darker bark than the pack's, so the trunks still stand dark against the
	# low sun (call 15). Set on the run's own copies of the pack's materials.
	for tree: String in TREES:
		var mesh := _pack_mesh(tree)
		(mesh.surface_get_material(0) as StandardMaterial3D).albedo_color = Color(0.55, 0.5, 0.47)
		_tree_meshes.append(mesh)
	for tree: String in DEAD_TREES:
		_dead_tree_meshes.append(_pack_mesh(tree))
	for k in PATCHES:
		_patches.append(_undergrowth(k))
	_trunk_mesh = CylinderMesh.new()
	_trunk_mesh.top_radius = 0.32
	_trunk_mesh.bottom_radius = 0.4
	_trunk_mesh.height = 1.0
	_trunk_mesh.radial_segments = 10
	_ground_mesh = PlaneMesh.new()
	# Longer than a slot, so neighbours overlap and no line shows between
	# them where the path bends.
	_ground_mesh.size = Vector2(10.0, SLOT + 0.5)
	# The dead trees' bark: on the fallen tree's own shape (_canopy_material),
	# and wrapped round the plain trunk and branches, which are stretched.
	_canopy_material = _dead_tree_meshes[0].surface_get_material(0)
	_trunk_material = _bark(Vector3(3.0, 6.0, 1.0))
	_branch_material = _bark(Vector3(2.0, 1.0, 1.0))
	# The forest floor: pine needles and leaves (Poly Haven, CC0; the pack has
	# no ground of its own), a little darker than the texture under the
	# trees. It repeats every 1.7 m across and twice along each slab: small
	# enough that the leaves read through the haze (Hopper, round 2).
	_ground_material = _solid(Color(0.8, 0.76, 0.72))
	_ground_material.albedo_texture = load(MODELS + "ForestLeaves04_Diffuse.jpg")
	_ground_material.uv1_scale = Vector3(6.0, 2.0, 1.0)
	# Seen almost edge-on, it would blur to a flat brown without the
	# sharpening _plain gives it.
	_plain(_ground_material)
	# The hand's skin and nails are in its vertex colours (hand_mesh.gd).
	_skin = _solid(Color.WHITE)
	_skin.vertex_color_use_as_albedo = true
	_skin.vertex_color_is_srgb = true
	_skin.roughness = 0.65
	# A stone fills the same space as the gray-box one: 1.2 m across, 1 m tall.
	_stone_mesh = _fitted(_pack_mesh(STONE), Vector3(1.2, 1.0, 1.2))
	_stone_material = _stone_mesh.surface_get_material(0)
	for mesh: Mesh in _tree_meshes + _dead_tree_meshes:
		for i in mesh.get_surface_count():
			_fade_in(mesh.surface_get_material(i), TREES_SEEN)
	for mesh: Mesh in _patches:
		for i in mesh.get_surface_count():
			_fade_in(mesh.surface_get_material(i), UNDERGROWTH_SEEN)
	_bar_mesh = BoxMesh.new()
	_bar_mesh.size = Vector3(TILE * 3.0 - 0.2, 0.08, 0.2)
	_hand_mesh = HandMesh.build()
	_firefly_mesh = SphereMesh.new()
	_firefly_mesh.radius = 0.06
	_firefly_mesh.height = 0.12
	_firefly_mesh.radial_segments = 8
	_firefly_mesh.rings = 4
	_firefly_halo_mesh = SphereMesh.new()
	_firefly_halo_mesh.radius = 0.24
	_firefly_halo_mesh.height = 0.48
	_firefly_halo_mesh.radial_segments = 8
	_firefly_halo_mesh.rings = 4
	_firefly_material = _firefly_material_with(Color("#FFC46A"))
	_firefly_halo = _firefly_material_with(Color("#FFB45C", 0.22))

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
	_build_tree()

	# Rain from 1:23 to the black, heavier from 1:43, and leaves blowing in
	# the storm: simple CPU particles, cheap on a phone.
	_rain = _make_rain(160)  # Starts faint and thickens (call 21): _update_look.
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
	_build_last_fireflies()
	_build_warm()


# The web build makes each new kind of thing ready the first time it is
# drawn, and on a phone that is a visible stutter: the first stone, the first
# gap and its hand, the first rain, the first moment the sun and lamp are
# on. So one of each is drawn, lit, in the first 3 s, while the screen is
# still covered in black, then freed.
func _build_warm() -> void:
	_warm = Node3D.new()
	_warm.name = "Warm"
	_warm.position = Vector3(0.0, 0.0, -6.0)
	_camera.add_child(_warm)
	var unseen := func(material: StandardMaterial3D) -> StandardMaterial3D:
		var copy: StandardMaterial3D = material.duplicate()
		copy.albedo_color.a = 0.0
		return copy
	var line := StandardMaterial3D.new()
	line.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	var outline := Node3D.new()
	_warm.add_child(outline)
	var stone := MeshInstance3D.new()
	stone.mesh = _stone_mesh
	stone.material_override = _stone_material
	_warm.add_child(stone)
	_add_shell(outline, stone, line)
	for lanes in [1, 2]:  # The obstacles' branches, and the fallen tree's.
		var branch := MeshInstance3D.new()
		branch.mesh = _branch_mesh(lanes)
		branch.material_override = _branch_material
		_warm.add_child(branch)
	# A gap's rim, which the fog doesn't dim.
	var rim_line := StandardMaterial3D.new()
	rim_line.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rim_line.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rim_line.disable_fog = true
	rim_line.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	var rim := MeshInstance3D.new()
	rim.mesh = _bar_mesh
	rim.material_override = rim_line
	_warm.add_child(rim)
	_warm.add_child(_make_hand())
	var trunk := MeshInstance3D.new()
	trunk.mesh = _trunk_mesh
	trunk.material_override = _trunk_material
	_warm.add_child(trunk)
	# The pack's shapes, so the dead trees of the panic and the fallen tree's
	# bark are ready before they first come into view.
	for mesh: Mesh in _tree_meshes + _dead_tree_meshes + _patches + _tile_meshes:
		var model := MeshInstance3D.new()
		model.mesh = mesh
		model.scale = Vector3.ONE * 0.01
		_warm.add_child(model)
	var fallen := MeshInstance3D.new()
	fallen.mesh = _dead_tree_meshes[0]
	fallen.material_override = _canopy_material
	fallen.scale = Vector3.ONE * 0.01
	_warm.add_child(fallen)
	_warm.add_child(_make_firefly(unseen.call(_firefly_material), unseen.call(_firefly_halo)))
	# The song too, silent, so starting it at 0:03 doesn't catch.
	var song := AudioStreamPlayer.new()
	song.stream = MUSIC
	song.volume_db = -80.0
	_warm.add_child(song)
	song.play()
	var ball := MeshInstance3D.new()
	ball.mesh = _light.mesh
	ball.material_override = unseen.call(_light_material)
	_warm.add_child(ball)
	for source: CPUParticles3D in [_heavy_rain, _leaves]:
		var copy := CPUParticles3D.new()
		_warm.add_child(copy)
		copy.amount = 4
		copy.mesh = source.mesh.duplicate()
		copy.mesh.material = unseen.call(source.mesh.material)
		copy.emitting = true


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


# The father's hand (hand_mesh.gd): palm centre at the origin, fingers
# toward -z (forward), back of the hand up. One shape, so one draw.
func _make_hand() -> Node3D:
	var hand := Node3D.new()
	var shape := MeshInstance3D.new()
	shape.mesh = _hand_mesh
	shape.material_override = _skin
	shape.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hand.add_child(shape)
	return hand


func _solid(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.9
	return mat


# Fades `material` in by its object's distance from the camera: not drawn at
# `far`, whole FADE_BAND nearer, dithered between (works in the browser).
func _fade_in(material: BaseMaterial3D, far: float) -> void:
	material.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_OBJECT_DITHER
	material.distance_fade_min_distance = far
	material.distance_fade_max_distance = far - FADE_BAND


# The dead trees' bark from the pack, repeated `repeat` times over a shape.
func _bark(repeat: Vector3) -> StandardMaterial3D:
	var mat: StandardMaterial3D = _canopy_material.duplicate()
	mat.uv1_scale = repeat
	return mat


# --- The pack's models.

# The one shape in a model from the pack, with copies of its materials, so
# what the run changes in them (darker bark, fading in) stays in the run.
func _pack_mesh(model: String) -> Mesh:
	var scene: Node = (load(MODELS + model + ".gltf") as PackedScene).instantiate()
	var mesh: ArrayMesh = (scene.find_children("*", "MeshInstance3D")[0] as MeshInstance3D).mesh.duplicate()
	scene.free()
	for i in mesh.get_surface_count():
		var mat: BaseMaterial3D = mesh.surface_get_material(i).duplicate()
		# Leaves and grass are thin cards, seen from both sides, with
		# see-through edges; everything else is a plain solid.
		if not (mat.resource_name.begins_with("Leaves") or mat.resource_name.begins_with("Grass")):
			_plain(mat)
		mesh.surface_set_material(i, mat)
	return mesh


# A textured solid as every other one is: one side, no see-through edges, no
# bump map, sharp when seen edge-on. Each difference is another shader the
# phone has to build before the run can start (Dan, 2026-10-30: "it takes a
# long time to load"), so the stones, the bark, the path and the floor
# share one.
func _plain(mat: BaseMaterial3D) -> void:
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.normal_enabled = false
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC


# What scales and moves a shape so it fills a box of `size` centred on the origin.
func _fit(mesh: Mesh, size: Vector3) -> Transform3D:
	var box := mesh.get_aabb()
	var k := size / box.size
	return Transform3D(Basis.from_scale(k), -box.get_center() * k)


# The shape itself, reshaped that way.
func _fitted(mesh: Mesh, size: Vector3) -> ArrayMesh:
	return _merged([[mesh, _fit(mesh, size)]])


# One shape from several placed ones, one surface per material, so a patch of
# undergrowth is drawn in a few calls, not one for each plant.
func _merged(parts: Array) -> ArrayMesh:
	# By the material's name: each of the pack's models has its own copy of
	# the same leaves, grass or rock, and one of each is enough.
	var tools := {}  # Material name -> SurfaceTool.
	var materials := {}  # Material name -> the first material of that name.
	for part: Array in parts:
		var mesh: Mesh = part[0]
		for i in mesh.get_surface_count():
			var material := mesh.surface_get_material(i)
			var key := material.resource_name
			if not tools.has(key):
				tools[key] = SurfaceTool.new()
				materials[key] = material
			(tools[key] as SurfaceTool).append_from(mesh, i, part[1])
	var out := ArrayMesh.new()
	for key: String in tools:
		var tool: SurfaceTool = tools[key]
		tool.set_material(materials[key])
		tool.commit(out)
	return out


# A patch of undergrowth a slot long: ferns, grass, leafy plants and a small
# rock each side, scattered from the path's edges into the trees, on the
# forest floor at y = 0. Patch k is the same every time.
func _undergrowth(k: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * k + 1
	var parts := []
	for plant: Array in UNDERGROWTH:
		if not _plants.has(plant[0]):
			_plants[plant[0]] = _pack_mesh(plant[0])
		var mesh: Mesh = _plants[plant[0]]
		for n: int in plant[2] * 2:
			var side := -1 if n % 2 == 0 else 1
			var size: float = plant[1] * rng.randf_range(0.8, 1.25)
			var at := Vector3(side * rng.randf_range(2.8, 9.0), 0.0, rng.randf_range(-SLOT, SLOT) / 2.0)
			var turn := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
			parts.append([mesh, Transform3D(turn, at)])
	return _merged(parts)


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


# The black for the fade-up and the end, the ripples and the two hints.
# Nothing on it can be tapped: each half of the screen moves the light a
# lane. The hints are the only words, ever (call 20).
func _build_screen() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ripple_layer = Control.new()
	_ripple_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ripple_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ripple_layer.draw.connect(_draw_ripples)
	layer.add_child(_ripple_layer)
	# "tap here" in the middle of each half, a little below the middle of the
	# screen; "hold" in the middle, above the light.
	for half: float in [0.25, 0.75]:
		var hint := _hint("HintLeft" if half < 0.5 else "HintRight", RunPlan.TAP_HINT, half, 0.62)
		layer.add_child(hint)
		_tap_hints.append(hint)
	_hold_hint = _hint("HintHold", RunPlan.HOLD_HINT, 0.5, 0.42)
	layer.add_child(_hold_hint)
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color.BLACK
	layer.add_child(_overlay)


# A hint: plain words, centred on a point given as a share of the screen.
func _hint(node_name: String, text: String, x: float, y: float) -> Label:
	var hint := Label.new()
	hint.name = node_name
	hint.text = text
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", HINT_SIZE)
	hint.add_theme_color_override("font_color", HINT_COLOR)
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	hint.add_theme_constant_override("outline_size", HINT_OUTLINE)
	hint.anchor_left = x
	hint.anchor_right = x
	hint.anchor_top = y
	hint.anchor_bottom = y
	hint.offset_left = -200.0
	hint.offset_right = 200.0
	hint.offset_top = -30.0
	hint.offset_bottom = 30.0
	hint.visible = false
	return hint


# The hints fade in and out on the timeline alone (RunPlan.hints), the same
# on every run: the Loss is played once (call 20).
func _update_hints() -> void:
	var tap := 0.0
	var hold := 0.0
	for hint: Array in RunPlan.hints(_t):
		if hint[0] == RunPlan.TAP_HINT:
			tap = hint[1]
		else:
			hold = hint[1]
	for label in _tap_hints:
		label.visible = tap > 0.0
		label.modulate.a = tap
	_hold_hint.visible = hold > 0.0
	_hold_hint.modulate.a = hold


## The words on screen now: only ever the hints.
func hints_shown() -> Array[String]:
	var out: Array[String] = []
	for label: Label in _tap_hints + [_hold_hint]:
		if label.visible:
			out.append(label.text)
	return out


# The fallen tree (call 20): a great trunk lying across the whole path where
# the light comes to rest, out past both edges into the trees, its roots at
# one end and its crown at the other, with a few broken branches. It is not an
# obstacle: nothing lights it up, and nothing gets past it. It shares the
# trees' shapes, so drawing it costs no first-time stutter.
func _build_tree() -> void:
	_tree_distance = RunPlan.distance(RunPlan.STOPPED) + LIGHT_RADIUS + TREE_GAP + TREE_RADIUS
	_tree = Node3D.new()
	_tree.name = "FallenTree"
	_tree.transform = Transform3D(_path_basis(_tree_distance), _path_at(_tree_distance))
	var trunk := MeshInstance3D.new()
	trunk.mesh = _trunk_mesh
	trunk.material_override = _trunk_material
	trunk.rotation = Vector3(0.0, 0.08, PI / 2.0)
	trunk.scale = Vector3(TREE_RADIUS / 0.4, TREE_LENGTH, TREE_RADIUS / 0.4)
	trunk.position = Vector3(0.8, TREE_RADIUS - 0.1, 0.0)
	_tree.add_child(trunk)
	# A dead tree from the pack lies along it, its roots at one end and its
	# bare crown spread out past the path's right-hand edge; the plain trunk
	# gives it its thickness where it crosses the path.
	var dead := MeshInstance3D.new()
	dead.name = "DeadTree"
	dead.mesh = _dead_tree_meshes[0]
	dead.material_override = _canopy_material
	var lying := Basis(Vector3.BACK, -PI / 2.0).rotated(Vector3.RIGHT, 1.6)
	var length := TREE_LENGTH + 3.0
	dead.transform = Transform3D(lying.scaled(Vector3.ONE * length / dead.mesh.get_aabb().end.y),
			Vector3(0.8 - TREE_LENGTH / 2.0, TREE_RADIUS - 0.1, 0.0))
	_tree.add_child(dead)
	for stub: Array in [[-1.7, 0.6, -0.5], [0.9, -0.7, 0.4], [3.4, 0.9, -0.2]]:
		var branch := MeshInstance3D.new()
		branch.mesh = _branch_mesh(1)
		# The obstacle branch's shape, kept at the stubs' first length (1 m)
		# when call 21 shortened the obstacles.
		branch.scale = Vector3(1.0, 1.0 / _branch_mesh(1).height, 1.0)
		branch.material_override = _branch_material
		branch.rotation = Vector3(stub[1], 0.0, stub[2])
		branch.position = Vector3(stub[0], TREE_RADIUS * 1.6, -0.2)
		_tree.add_child(branch)
	for part in _tree.get_children():
		(part as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_tree.visible = false
	add_child(_tree)


## Where the fallen tree lies, in metres along the path (for tests).
func tree_distance() -> float:
	return _tree_distance
