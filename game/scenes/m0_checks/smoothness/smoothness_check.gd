extends Node3D
## M0 Check 1 (DAS-67): a gray-box room with lamp light and ordinary fog, plus
## on-screen numbers for the iPhone headroom bar in docs/scope.md.
## Throwaway M0 scaffolding, not game code.

const MENU_SCENE := "res://scenes/ui/m0_menu.tscn"
const RUN_SECONDS := 120.0
const WORK_BAR_MS := 4.0
const MEMORY_BAR_MB := 500.0
const LOAD_BAR_S := 10.0
# One missed frame at 60 fps is about 33 ms; anything over 25 ms counts.
const HITCH_MS := 25.0
# Shaders compile and the heavy buffer is built in the first moments, so
# nothing is counted then. Godot's process-time number lags by up to a second.
const WARMUP_SECONDS := 2.0
# Redraw the numbers a few times a second so they can be read.
const STATS_REFRESH_SECONDS := 0.25
# Heavy = the 3D picture drawn at 2x width and 2x height = 4x the pixels.
const HEAVY_SCALE := 2.0

@onready var _camera: Camera3D = %Camera
@onready var _stats: Label = %Stats
@onready var _heavy_button: Button = %HeavyButton
@onready var _back_button: Button = %BackButton
@onready var _proof_square: MeshInstance3D = %ProofSquare

var _camera_start: Vector3
var _look_target := Vector3(0.0, 1.0, -1.5)
var _sway_time := 0.0
var _last_frame_usec := 0
var _load_s := -1.0

var _elapsed := 0.0
var _frames := 0
var _work_samples := 0
var _work_ms_total := 0.0
var _next_work_sample := 0.0
var _next_stats_refresh := 0.0
var _worst_ms := 0.0
var _hitches := 0


func _ready() -> void:
	_camera_start = _camera.position
	_heavy_button.toggled.connect(_on_heavy_toggled)
	_back_button.pressed.connect(_on_back_pressed)
	_load_s = _measure_load_seconds()
	_reset_run()


func _process(delta: float) -> void:
	_sway_time += delta
	# Slow sway so any stutter is easy to see.
	_camera.position = _camera_start + Vector3(sin(_sway_time * 0.5) * 0.8, sin(_sway_time * 0.3) * 0.1, 0.0)
	_camera.look_at(_look_target)

	var screen_width := float(get_window().size.x)
	(_proof_square.material_override as ShaderMaterial).set_shader_parameter("screen_width", screen_width)

	# Real clock time, because Godot smooths delta and that can hide hitches.
	var now_usec := Time.get_ticks_usec()
	var frame_ms := (now_usec - _last_frame_usec) / 1000.0
	_last_frame_usec = now_usec
	_elapsed += delta
	if _elapsed > WARMUP_SECONDS:
		_frames += 1
		_worst_ms = maxf(_worst_ms, frame_ms)
		if frame_ms > HITCH_MS:
			_hitches += 1
		# Godot refreshes its process-time number once a second.
		if _elapsed >= _next_work_sample:
			_work_samples += 1
			_work_ms_total += _work_ms_now()
			_next_work_sample = _elapsed + 1.0
	if _elapsed >= _next_stats_refresh:
		_stats.text = _stats_text()
		_next_stats_refresh = _elapsed + STATS_REFRESH_SECONDS


func _stats_text() -> String:
	var heavy := _heavy_button.button_pressed
	var window_size := get_window().size
	var scale := get_viewport().scaling_3d_scale
	var lines: PackedStringArray = []
	lines.append("Smoothness: %s" % ("HEAVY (4x pixels)" if heavy else "normal"))
	var run_note := "done" if _elapsed >= RUN_SECONDS else "keep going"
	lines.append("Time %s of %s (%s)" % [_clock(_elapsed), _clock(RUN_SECONDS), run_note])
	var counted_s := _elapsed - WARMUP_SECONDS
	var fps_avg := "%.1f" % (_frames / counted_s) if counted_s > 0.0 else "-"
	lines.append("FPS %d now, %s average" % [Engine.get_frames_per_second(), fps_avg])
	lines.append("Worst frame %.0f ms, hitches %d" % [_worst_ms, _hitches])
	var work_avg := "%.2f" % (_work_ms_total / _work_samples) if _work_samples > 0 else "-"
	lines.append("Game work %.2f ms now, %s average (bar %.0f)" % [_work_ms_now(), work_avg, WORK_BAR_MS])
	lines.append("  (slowest frame of each second)")
	lines.append("Memory %s (bar %.0f MB)" % [_memory_text(), MEMORY_BAR_MB])
	lines.append("Load %s (bar %.0f s)" % ["%.1f s" % _load_s if _load_s >= 0.0 else "n/a", LOAD_BAR_S])
	lines.append("3D drawn at %d x %d" % [roundi(window_size.x * scale), roundi(window_size.y * scale)])
	return "\n".join(lines)


# Godot's built-in process timer: the game's own work in a frame, in ms.
# Godot reports the slowest frame of the last second, so this runs high.
func _work_ms_now() -> float:
	return Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0


func _clock(seconds: float) -> String:
	var whole := int(seconds)
	return "%d:%02d" % [whole / 60, whole % 60]


# Godot's own memory (the web page's engine memory) plus graphics memory.
# Safari's own overhead is not included.
func _memory_text() -> String:
	var video_mb := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	var engine_bytes := _web_engine_memory_bytes()
	if engine_bytes < 0:
		engine_bytes = OS.get_static_memory_usage()
	return "%.0f MB" % (engine_bytes / 1048576.0 + video_mb)


func _web_engine_memory_bytes() -> int:
	if not OS.has_feature("web"):
		return -1
	var js := "(() => { try { return engine.rtenv.HEAPU8.length; } catch (e) { return -1; } })()"
	var result: Variant = JavaScriptBridge.eval(js, true)
	return int(result) if result != null else -1


# Seconds from opening the page until the engine started running.
func _measure_load_seconds() -> float:
	if not OS.has_feature("web"):
		return -1.0
	var page_ms: Variant = JavaScriptBridge.eval("performance.now()", true)
	if page_ms == null:
		return -1.0
	return (float(page_ms) - Time.get_ticks_msec()) / 1000.0


func _reset_run() -> void:
	_elapsed = 0.0
	_frames = 0
	_work_samples = 0
	_work_ms_total = 0.0
	_next_work_sample = WARMUP_SECONDS
	_next_stats_refresh = 0.0
	_last_frame_usec = Time.get_ticks_usec()
	_worst_ms = 0.0
	_hitches = 0


func _on_heavy_toggled(on: bool) -> void:
	get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	get_viewport().scaling_3d_scale = HEAVY_SCALE if on else 1.0
	_heavy_button.text = "Heavy: on" if on else "Heavy: off"
	_reset_run()


func _on_back_pressed() -> void:
	get_viewport().scaling_3d_scale = 1.0
	get_tree().change_scene_to_file(MENU_SCENE)
