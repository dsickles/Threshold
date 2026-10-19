extends Control
## The Partner (rough first playable, DAS-73). Tap anywhere when a light
## reaches the ring around the glow. Built from the draft song and beat chart
## (m1-prep/partner-song-and-beat-chart.md), which Dan has not settled yet.
##
## The chapter only reports that it finished (the `finished` signal). It never
## touches the House; whatever opened it decides what happens next.

signal finished

enum State { LOADING, WAITING, PLAYING, PAUSED, TEST_SHOWN, DONE }
enum Judged { PENDING, HIT, MISSED }

const CHART_PATH := "res://scenes/chapters/partner/beat_chart.json"
const SONG := preload("res://assets/audio/partner/placeholder_song.mp3")  # PLACEHOLDER song
const MISS_SOUNDS: Array[AudioStream] = [  # PLACEHOLDER for the awkward laughter
	preload("res://assets/audio/partner/placeholder_miss_1.wav"),
	preload("res://assets/audio/partner/placeholder_miss_2.wav"),
	preload("res://assets/audio/partner/placeholder_miss_3.wav"),
]

# Judging (draft "Judging taps"; to tune in playtests). Good must stay under
# half the closest gap between notes (250 ms) so one tap can't count twice.
const PERFECT_WINDOW := 0.050
const GOOD_WINDOW := 0.110
# A tap reaches the game a little after the touch it is timed from, so a note
# waits this much longer before it counts as missed. Judging still uses
# GOOD_WINDOW. GOOD_WINDOW + MISS_GRACE must stay under the 250 ms gap.
const MISS_GRACE := 0.100
# How far an intro tap may be from its note and still set the sound delay.
const CALIBRATION_WINDOW := 0.250
const MAX_SOUND_DELAY := 0.250
const LAUGH_GAP := 4.0  # At most one laugh every 2 bars.
const RING_SIZE := 0.13  # The ring's radius, as a share of the screen's shorter side.
const TRAVEL := 1.5  # A light takes 3 beats to reach the ring.
const FILL_TIME := 6.0  # After the last note, the glow fills the screen.
const TEST_HOLD := 5.0  # PLACEHOLDER: how long the test holds is Dan's call.
const HEARTBEAT := 1.0  # Beats 1 and 3 at 120 BPM: 60 a minute.
# Test info in the corner for Dan's checks. Turn off before cold playtests:
# no score or tally is shown to players.
const SHOW_TEST_INFO := true

# DESIGN.md colours.
const SURFACE := Color("#1C1916")
const INK := Color("#F4EFE6")
const INK_MUTED := Color("#9A9084")
const ACCENT := Color("#C4A574")
const HOPE := Color("#E8D4A8")

# Kept for the rest of the session, so a replay starts from the last delay.
static var _sound_delay := 0.0

var _state := State.LOADING
var _notes: PackedFloat64Array = []
var _judged: PackedByteArray = []
var _next := 0  # First note not yet passed the ring.
var _passed := 0  # Notes hit or missed so far, for the glow's growth.
var _intro_end := 0.0
var _song_length := 0.0
var _song_start := 0.0  # Where bar 1 beat 1 falls in the song file.
var _silent: Array[Vector2] = []  # Bars where the band stops: no heartbeat.
var _calibration: Array[float] = []
static var _calibrated := false  # A replay's calibration starts from the last delay.
var _last_laugh := -INF
var _last_laugh_index := -1
var _flash := 0.0
var _song_time := -1.0
var _test_held := 0.0  # Seconds the test has been on screen.
var _late_offsets: Array[float] = []  # After the intro, for the test info.

@onready var _conductor: Node = %Conductor
@onready var _judgement: Label = %Judgement
@onready var _prompt: Label = %Prompt
@onready var _test_info: Label = %TestInfo
@onready var _laugh_player: AudioStreamPlayer = %LaughPlayer


func _ready() -> void:
	_load_chart()
	_judgement.modulate.a = 0.0
	_test_info.visible = SHOW_TEST_INFO
	_conductor.load_song(SONG)
	_refresh_test_info()


func _load_chart() -> void:
	var chart: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CHART_PATH))
	var offset: float = chart.start_offset_ms / 1000.0
	_song_start = offset
	for ms: float in chart.notes_ms:
		_notes.append(offset + ms / 1000.0)
	_judged.resize(_notes.size())
	_intro_end = offset + chart.intro_end_ms / 1000.0
	_song_length = offset + chart.song_length_ms / 1000.0
	for span: Array in chart.silent_ms:
		_silent.append(Vector2(offset + span[0] / 1000.0, offset + span[1] / 1000.0))
	if _calibrated:
		_calibration.append(_sound_delay)
	for i in range(1, _notes.size()):
		if _notes[i] - _notes[i - 1] < 2.0 * GOOD_WINDOW:
			push_error("Partner chart: notes %d and %d are too close to judge apart" % [i - 1, i])


func _notification(what: int) -> void:
	# Native builds only; the web pauses when the tab is hidden (see Conductor).
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _state == State.PLAYING:
		_conductor.pause()


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
		_on_tap()


func _on_tap() -> void:
	match _state:
		State.LOADING:
			if _conductor.has_failed():
				queue_free()  # Back to whatever opened the chapter.
		State.WAITING:
			_state = State.PLAYING
			_conductor.start()
		State.PAUSED:
			_conductor.resume()  # The web resumes in its own touch handler.
		State.PLAYING:
			_judge_tap(_conductor.tap_time())


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta * 3.0, 0.0)
	_judgement.modulate.a = maxf(_judgement.modulate.a - delta * 1.6, 0.0)
	match _state:
		State.LOADING:
			if _conductor.is_ready():
				_state = State.WAITING
		State.PLAYING, State.PAUSED:
			_state = State.PAUSED if _conductor.is_paused() else State.PLAYING
			if _state == State.PLAYING:
				_song_time = _conductor.song_time()
				_mark_misses()
				if _song_time >= _song_length or _conductor.has_song_ended():
					_conductor.stop()
					_state = State.TEST_SHOWN
					_test_held = 0.0
		State.TEST_SHOWN:
			_test_held += delta
			if _test_held >= TEST_HOLD:
				_state = State.DONE
				finished.emit()
	_refresh_prompt()
	# Judgement sits just above the ring, which scales with the screen.
	var ring := minf(size.x, size.y) * RING_SIZE
	_judgement.position = Vector2((size.x - _judgement.size.x) / 2.0,
			size.y / 2.0 - ring - _judgement.size.y - 12.0)
	queue_redraw()


func _judge_tap(raw: float) -> void:
	if raw < 0.0:
		return
	if raw < _intro_end:
		_calibrate(raw)
	var t := raw - _sound_delay
	var i := _next
	while i < _notes.size() and _notes[i] <= t + GOOD_WINDOW:
		var offset := t - _notes[i]
		if _judged[i] == Judged.PENDING and absf(offset) <= GOOD_WINDOW:
			_judged[i] = Judged.HIT
			_passed += 1
			_flash = 1.0
			_show_judgement("Perfect" if absf(offset) <= PERFECT_WINDOW else "Good")
			if raw >= _intro_end:
				_late_offsets.append(offset)
				_refresh_test_info()
			return
		i += 1
	# A stray tap (no note near it) does nothing: no Miss, no laughter.


# Intro taps set the sound delay: the middle of how early or late they land,
# measured from the tap as heard, before any delay is applied.
func _calibrate(raw: float) -> void:
	var nearest := INF
	for note in _notes:
		if note >= _intro_end:
			break
		if absf(raw - note) < absf(nearest):
			nearest = raw - note
	if absf(nearest) > CALIBRATION_WINDOW:
		return
	_calibration.append(nearest)
	_calibrated = true
	var sorted := _calibration.duplicate()
	sorted.sort()
	var mid := sorted.size() / 2
	var median: float = sorted[mid] if sorted.size() % 2 == 1 \
			else (sorted[mid - 1] + sorted[mid]) / 2.0
	_sound_delay = clampf(median, -MAX_SOUND_DELAY, MAX_SOUND_DELAY)
	_refresh_test_info()


func _mark_misses() -> void:
	var t := _song_time - _sound_delay
	while _next < _notes.size() and _notes[_next] + GOOD_WINDOW + MISS_GRACE < t:
		if _judged[_next] == Judged.PENDING:
			_judged[_next] = Judged.MISSED
			_passed += 1
			_show_judgement("Miss")
			_laugh(_notes[_next])
		_next += 1


func _laugh(note_time: float) -> void:
	if note_time < _intro_end or note_time - _last_laugh < LAUGH_GAP:
		return
	var index := randi() % MISS_SOUNDS.size()
	if index == _last_laugh_index:
		index = (index + 1) % MISS_SOUNDS.size()
	_last_laugh = note_time
	_last_laugh_index = index
	_laugh_player.stream = MISS_SOUNDS[index]
	_laugh_player.play()


func _show_judgement(text: String) -> void:
	_judgement.text = text
	_judgement.modulate.a = 1.0


func _refresh_prompt() -> void:
	# PLACEHOLDER UI words. Browsers need one tap before any sound can play.
	match _state:
		State.LOADING:
			_prompt.text = "Couldn't load the song." if _conductor.has_failed() else ""
		State.WAITING:
			_prompt.text = "Tap to begin"
		State.PAUSED:
			_prompt.text = "Tap to continue"
		_:
			_prompt.text = ""


## For the browser tests' probe (game/_core/test_probe/web_test_probe.gd):
## what the canvas shows, since the tests can't read it.
func probe_state() -> Dictionary:
	return {
		"state": State.keys()[_state],
		"prompt": _prompt.text,
		"song_time": _song_time,
		"hits": _judged.count(Judged.HIT),
		"misses": _judged.count(Judged.MISSED),
		"clock": "browser" if _conductor.uses_browser_clock else "Godot",
	}


func _refresh_test_info() -> void:
	var lines := PackedStringArray([
		"Test info · clock: %s" % ("browser" if _conductor.uses_browser_clock else "Godot"),
		"Sound delay: %+d ms from %d intro taps"
				% [roundi(_sound_delay * 1000.0), _calibration.size()],
	])
	if not _late_offsets.is_empty():
		var mean := 0.0
		for offset in _late_offsets:
			mean += offset
		mean /= _late_offsets.size()
		lines.append("Hits after the intro: average %+d ms (+ is late)" % roundi(mean * 1000.0))
	_test_info.text = "\n".join(lines)


func _draw() -> void:
	var c := size / 2.0
	var ring := minf(size.x, size.y) * RING_SIZE
	draw_rect(Rect2(Vector2.ZERO, size), SURFACE)

	if _state == State.TEST_SHOWN or _state == State.DONE:
		_draw_test(c, ring)
		return

	var t := _song_time if _song_time >= 0.0 else 0.0
	var progress := float(_passed) / _notes.size()
	var glow_color := ACCENT.lerp(HOPE, progress)

	# The heart: swells on each heartbeat, grows and warms as the song goes on.
	var pulse := 0.0
	if _state == State.PLAYING or _state == State.PAUSED:
		if not _is_silent(t) and t < _notes[-1]:
			pulse = exp(-fposmod(t - _song_start, HEARTBEAT) * 6.0)
	else:
		pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * TAU / 2.0)  # Waiting.
	var radius := ring * (0.45 + 0.4 * progress) * (1.0 + 0.12 * pulse + 0.1 * _flash)
	for k in range(6, 0, -1):
		var layer := glow_color
		layer.a = 0.10 + 0.05 * _flash
		draw_circle(c, radius * (1.0 + k * 0.18), layer)
	draw_circle(c, radius, glow_color)

	# The ring marks "now".
	var ring_color := INK
	ring_color.a = 0.45
	draw_arc(c, ring, 0.0, TAU, 96, ring_color, 2.0, true)

	_draw_lights(c, ring, t)

	# After the last note the glow fills the screen while the chord rings out.
	if t > _notes[-1]:
		var fill := clampf((t - _notes[-1]) / FILL_TIME, 0.0, 1.0)
		var cover := (size / 2.0).length() * 1.1
		var fill_color := HOPE
		fill_color.a = fill
		draw_circle(c, lerpf(radius, cover, ease(fill, 0.4)), fill_color)


func _is_silent(t: float) -> bool:
	for span in _silent:
		if t >= span.x and t < span.y:
			return true
	return false


# Connection Nodes: lights that drift in from the left and right edges, in
# turn, and reach the ring exactly on their note.
func _draw_lights(c: Vector2, ring: float, t: float) -> void:
	var t_judged := t - _sound_delay
	var light_radius := ring * 0.16
	var first := maxi(_next - 4, 0)
	for i in range(first, _notes.size()):
		var until := _notes[i] - t_judged
		if until > TRAVEL:
			break
		if _judged[i] == Judged.HIT:
			continue  # Merged into the glow.
		var side := -1.0 if i % 2 == 0 else 1.0
		var start := Vector2(c.x + side * (size.x / 2.0 + light_radius), c.y)
		var arrive := Vector2(c.x + side * ring, c.y)
		var pos := start.lerp(arrive, 1.0 - until / TRAVEL)  # Keeps drifting past the ring.
		var color := HOPE
		color.a = clampf((TRAVEL - until) / 0.3, 0.0, 1.0)
		if _judged[i] == Judged.MISSED:
			color = INK_MUTED
			color.a = clampf(0.5 + until * 1.5, 0.0, 0.5)  # Dims as it drifts through.
		if color.a > 0.0:
			draw_circle(pos, light_radius, color)


# PLACEHOLDER staging for the one ending: a positive test, two lines, no
# words. What it lies on, any words and how long it holds are Dan's calls.
func _draw_test(c: Vector2, ring: float) -> void:
	var stick := Vector2(ring * 0.9, ring * 3.2)
	var body := Rect2(c - stick / 2.0, stick)
	draw_rect(body, INK)
	var window := Rect2(c + Vector2(-stick.x * 0.3, -stick.y * 0.2), Vector2(stick.x * 0.6, stick.y * 0.3))
	draw_rect(window, Color("#D9D2C6"))
	var line := Vector2(window.size.x * 0.7, 4.0)
	for y in [0.35, 0.65]:
		var top_left := window.position + Vector2((window.size.x - line.x) / 2.0, window.size.y * y)
		draw_rect(Rect2(top_left, line), Color("#8B3A32"))
