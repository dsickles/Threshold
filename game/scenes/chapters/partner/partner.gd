extends Control
## The Partner (rough first playable, DAS-73). Tap anywhere when a light
## falling from the top reaches the heart. Built from the draft song and beat
## chart (m1-prep/partner-song-and-beat-chart.md), which Dan has not settled
## yet, with Dan's 2026-10-20 changes: a heart, lights that fall from the top,
## easier timing, and an ending with a real-looking test and the couple.
##
## The chapter only reports that it finished (the `finished` signal). It never
## touches the House; whatever opened it decides what happens next.

signal finished

enum State { LOADING, WAITING, PLAYING, PAUSED, TEST_SHOWN, DONE }
enum Judged { PENDING, HIT, MISSED }

const CHART_PATH := "res://scenes/chapters/partner/beat_chart.json"
const SONG := preload("res://assets/audio/partner/placeholder_song.mp3")  # PLACEHOLDER song
const COUPLE_IMAGE := preload("res://assets/images/partner/placeholder_couple.png")  # PLACEHOLDER
const TEST_IMAGE := preload("res://assets/images/partner/placeholder_test.png")  # PLACEHOLDER
const TEST_IMAGE_ASPECT := 0.24  # Its height over its width.
const CELEBRATE_SOUND := preload("res://assets/audio/partner/placeholder_celebrate.wav")  # PLACEHOLDER
const MISS_SOUNDS: Array[AudioStream] = [  # PLACEHOLDER for the awkward laughter
	preload("res://assets/audio/partner/placeholder_miss_1.wav"),
	preload("res://assets/audio/partner/placeholder_miss_2.wav"),
	preload("res://assets/audio/partner/placeholder_miss_3.wav"),
]

# Judging, widened after Dan's 2026-10-20 play ("most people should be able to
# get most beats on at least good, with less than 5 misses"); to tune in
# playtests. Good must stay under half the closest gap between notes (500 ms)
# so one tap can't count twice.
const PERFECT_WINDOW := 0.070
const GOOD_WINDOW := 0.160
# A tap reaches the game a little after the touch it is timed from, so a note
# waits this much longer before it counts as missed. Judging still uses
# GOOD_WINDOW. GOOD_WINDOW + MISS_GRACE must stay under the 500 ms gap.
const MISS_GRACE := 0.080
# How far an intro tap may be from its note and still set the sound delay.
const CALIBRATION_WINDOW := 0.250
const MAX_SOUND_DELAY := 0.250
const MIN_CALIBRATION_TAPS := 3
const LAUGH_GAP := 4.0  # At most one laugh every 2 bars.
const RING_SIZE := 0.13  # The heart's half-height, as a share of the screen's shorter side.
const HEART_HEIGHT := 0.6  # Where the heart sits, as a share of the screen's height.
const TRAVEL := 2.0  # A light takes 4 beats to fall from the top to the heart.
const FILL_TIME := 6.0  # After the last note, the light fills the screen.
# Dan, 2026-10-19: the test holds at least 30 seconds with nothing to tap;
# then a quiet ring shows the player can go back when ready.
const TEST_HOLD := 30.0
# What they say when the test appears (Dan, 2026-10-20: "'honey' from her, a
# jubilant 'yes' from him, and then they both laugh"), as subtitles for now:
# seconds after the test appears, and the line. No voices recorded yet.
const TEST_LINES := [
	[2.5, "Honey."],
	[4.2, "Yes!"],
	[5.6, "(They both laugh.)"],  # PLACEHOLDER caption wording for the laugh.
]
const TEST_LINES_END := 9.0
const HEARTBEAT := 1.0  # Beats 1 and 3 at 120 BPM: 60 a minute.
# Test info in the corner for Dan's checks. Turn off before cold playtests:
# no score or tally is shown to players.
const SHOW_TEST_INFO := true

# The Partner's own palette (Dan, 2026-10-20: the first build was "brown on
# brown"): a dusk plum to wine, a rose heart that warms to coral as the song
# builds, cream lights, and a peach dawn for the ending. Text keeps DESIGN.md's ink.
const INK := Color("#F4EFE6")
const BG_TOP := Color("#221726")
const BG_BOTTOM := Color("#43202F")
const HEART_START := Color("#B4475E")
const HEART_END := Color("#F28C78")
const LIGHT := Color("#FFE8C2")
const MISSED := Color("#7E6878")
const DAWN_TOP := Color("#FBE3C8")
const DAWN_BOTTOM := Color("#E7A08F")
const COUPLE := Color("#B65866")  # Tints the placeholder couple.

# Kept for the rest of the session, so a replay starts from the last delay.
static var _sound_delay := 0.0

var _state := State.LOADING
var _notes: PackedFloat64Array = []
var _judged: PackedByteArray = []
var _next := 0  # First note not yet passed the heart.
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
var _heart_shape := PackedVector2Array()  # A heart, half-height 1, centred on 0.

@onready var _conductor: Node = %Conductor
@onready var _judgement: Label = %Judgement
@onready var _prompt: Label = %Prompt
@onready var _test_info: Label = %TestInfo
@onready var _laugh_player: AudioStreamPlayer = %LaughPlayer
@onready var _celebrate_player: AudioStreamPlayer = %CelebratePlayer
@onready var _subtitle: Label = %Subtitle


func _ready() -> void:
	_load_chart()
	_heart_shape = _make_heart()
	_celebrate_player.stream = CELEBRATE_SOUND
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
			_start()
		State.PAUSED:
			_conductor.resume()  # The web resumes in its own touch handler.
		State.PLAYING:
			_judge_tap(_conductor.tap_time())
		State.TEST_SHOWN:
			if _test_held >= TEST_HOLD:
				_state = State.DONE
				_conductor.stop()
				finished.emit()


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
				# The test shows once the light has filled the screen; the last
				# chord keeps ringing under it.
				if _song_time >= _notes[-1] + FILL_TIME or _song_time >= _song_length \
						or _conductor.has_song_ended():
					_state = State.TEST_SHOWN
					_test_held = 0.0
					_celebrate_player.play()
		State.TEST_SHOWN:
			_test_held += delta
	_refresh_subtitle()
	_refresh_prompt()
	# Judgement sits just below the heart, which scales with the screen.
	_judgement.position = Vector2((size.x - _judgement.size.x) / 2.0,
			_heart_centre().y + _heart_size() * 1.05 + 8.0)
	queue_redraw()


func _start() -> void:
	# Browser tests can start part-way in (see web_test_probe.gd); notes
	# before that point are passed over without a Miss or a laugh.
	var from: float = get_tree().root.get_meta("partner_start_from", 0.0)
	if from > 0.0:
		while _next < _notes.size() and _notes[_next] < from:
			_judged[_next] = Judged.MISSED
			_next += 1
			_passed += 1
		_last_laugh = from
	_state = State.PLAYING
	_conductor.start(from)


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
	# One stray tap while finding the beat mustn't set the delay for the
	# whole song: wait for a few before trusting the middle of them.
	if _calibration.size() < MIN_CALIBRATION_TAPS:
		_refresh_test_info()
		return
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


func _refresh_subtitle() -> void:
	var line := ""
	if _state == State.TEST_SHOWN and _test_held < TEST_LINES_END:
		for entry in TEST_LINES:
			if _test_held >= entry[0]:
				line = entry[1]
	_subtitle.text = line
	_subtitle.visible = line != ""
	# Bottom centre, just below the test.
	_subtitle.size = Vector2.ZERO
	_subtitle.position = Vector2((size.x - _subtitle.get_minimum_size().x) / 2.0,
			minf(_test_centre_y() + _test_length() * TEST_IMAGE_ASPECT / 2.0 + 16.0,
			size.y - _subtitle.get_minimum_size().y - 12.0))


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
		"can_leave": _state == State.TEST_SHOWN and _test_held >= TEST_HOLD,
		"subtitle": _subtitle.text,
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




func _heart_centre() -> Vector2:
	return Vector2(size.x / 2.0, size.y * HEART_HEIGHT)


func _heart_size() -> float:
	return minf(size.x, size.y) * RING_SIZE


# The classic heart curve, centred and scaled to a half-height of 1.
func _make_heart() -> PackedVector2Array:
	var points := PackedVector2Array()
	for k in 96:
		var a := TAU * k / 96.0
		points.append(Vector2(16.0 * pow(sin(a), 3),
				-(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))))
	var box := Rect2(points[0], Vector2.ZERO)
	for point in points:
		box = box.expand(point)
	var out := PackedVector2Array()
	for point in points:
		out.append((point - box.get_center()) / (box.size.y / 2.0))
	return out


func _draw_heart(centre: Vector2, half_height: float, color: Color, filled := true,
		width := 2.0) -> void:
	var points := PackedVector2Array()
	for point in _heart_shape:
		points.append(centre + point * half_height)
	if filled:
		draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, color, width if not filled else 1.5, true)  # Smooths the edge.


func _draw_gradient(top: Color, bottom: Color, alpha := 1.0) -> void:
	top.a *= alpha
	bottom.a *= alpha
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
			PackedColorArray([top, top, bottom, bottom]))


# Lub-dub: a strong beat, then a softer one just after it.
func _lub_dub(since: float) -> float:
	var pulse := exp(-since * 9.0)
	if since > 0.2:
		pulse += 0.6 * exp(-(since - 0.2) * 9.0)
	return pulse


func _draw() -> void:
	if _state == State.TEST_SHOWN or _state == State.DONE:
		_draw_ending()
		return

	var c := _heart_centre()
	var heart := _heart_size()
	var t := _song_time if _song_time >= 0.0 else 0.0
	var progress := float(_passed) / _notes.size()
	var heart_color := HEART_START.lerp(HEART_END, progress)
	_draw_gradient(BG_TOP, BG_BOTTOM)

	# The heart beats, and grows and warms as the song goes on.
	var pulse := 0.0
	if _state == State.PLAYING or _state == State.PAUSED:
		if not _is_silent(t) and t < _notes[-1]:
			pulse = _lub_dub(fposmod(t - _song_start, HEARTBEAT))
	else:
		pulse = _lub_dub(fposmod(Time.get_ticks_msec() / 1000.0, 2.0 * HEARTBEAT))  # Waiting.

	# A soft warm light behind it, wider as the song builds.
	for k in range(8, 0, -1):
		var halo := heart_color
		halo.a = 0.035 + 0.02 * progress
		draw_circle(c, heart * (1.2 + k * (0.35 + 0.25 * progress)), halo)

	var inner := heart * (0.55 + 0.35 * progress) * (1.0 + 0.1 * pulse + 0.08 * _flash)
	for k in range(4, 0, -1):
		var glow := heart_color
		glow.a = 0.12 + 0.06 * _flash
		_draw_heart(c, inner * (1.0 + k * 0.12), glow)
	_draw_heart(c, inner, heart_color)

	# The outline marks "now"; a hit sends a ripple out from it.
	var outline := INK
	outline.a = 0.5
	_draw_heart(c, heart, outline, false, 2.0)
	if _flash > 0.0:
		var ripple := LIGHT
		ripple.a = _flash * 0.7
		_draw_heart(c, heart * (1.0 + 0.35 * (1.0 - _flash)), ripple, false, 3.0)

	_draw_lights(c, heart, t)

	# After the last note the light fills the screen while the chord rings out.
	if t > _notes[-1]:
		var fill := clampf((t - _notes[-1]) / FILL_TIME, 0.0, 1.0)
		var cover := size.length() * 1.1
		var fill_color := DAWN_TOP
		fill_color.a = fill
		draw_circle(c, lerpf(inner, cover, ease(fill, 0.4)), fill_color)


func _is_silent(t: float) -> bool:
	for span in _silent:
		if t >= span.x and t < span.y:
			return true
	return false


# Where a light is `until` seconds before its note: just above the top of the
# screen when it appears, the heart's centre on the note, then on down.
func _light_position(c: Vector2, light_radius: float, until: float) -> Vector2:
	return Vector2(c.x, lerpf(-light_radius, c.y, 1.0 - until / TRAVEL))


# Connection Nodes: lights that fall from the top in one lane and reach the
# heart's centre exactly on their note.
func _draw_lights(c: Vector2, heart: float, t: float) -> void:
	var t_judged := t - _sound_delay
	var light_radius := heart * 0.2
	# The target (Dan, 2026-10-20: "too hard to see exactly where the point of
	# tapping should be"): a faint lane down to a ring the size of a light in
	# the heart's centre. Tap when a light fills the ring. It brightens as the
	# next light gets close.
	var lane := LIGHT
	lane.a = 0.08
	draw_line(Vector2(c.x, 0.0), c, lane, light_radius * 2.0)
	var soon := 0.0
	if _next < _notes.size():
		soon = clampf(1.0 - (_notes[_next] - t_judged) / 0.5, 0.0, 1.0)
	var target := LIGHT
	target.a = 0.55 + 0.45 * soon
	draw_circle(c, light_radius * 1.25, Color(BG_BOTTOM, 0.35))
	draw_arc(c, light_radius * 1.25, 0.0, TAU, 64, target, 2.5 + 2.0 * soon, true)
	var first := maxi(_next - 4, 0)
	for i in range(first, _notes.size()):
		var until := _notes[i] - t_judged
		if until > TRAVEL:
			break
		if _judged[i] == Judged.HIT:
			continue  # Merged into the heart.
		var pos := _light_position(c, light_radius, until)
		var color := LIGHT
		color.a = clampf((TRAVEL - until) / 0.3, 0.0, 1.0)
		if _judged[i] == Judged.MISSED:
			color = MISSED
			color.a = clampf(0.6 + until * 1.5, 0.0, 0.6)  # Dims as it falls through.
		if color.a <= 0.0:
			continue
		var halo := color
		halo.a *= 0.18
		draw_circle(pos, light_radius * 1.8, halo)
		draw_circle(pos, light_radius, color)


# The one ending: a positive test in front of the couple holding each other,
# on a warm dawn, with sparkles rising. Words, what the test lies on, and real
# art are still Dan's calls; the couple and the sound are PLACEHOLDERS.
func _draw_ending() -> void:
	var held := _test_held
	draw_rect(Rect2(Vector2.ZERO, size), DAWN_TOP)
	_draw_gradient(DAWN_TOP, DAWN_BOTTOM, clampf(held / 1.5, 0.0, 1.0))
	_draw_sparkles(held)
	_draw_couple(clampf((held - 0.3) / 2.5, 0.0, 1.0))
	var show := ease(clampf((held - 0.8) / 1.2, 0.0, 1.0), 0.4)
	_draw_test(Vector2(size.x / 2.0, _test_centre_y() + (1.0 - show) * 30.0), show)
	if held >= TEST_HOLD:
		# A quiet ring: the player can go back when ready.
		var ring := Color("#8E3F55")
		ring.a = 0.4 + 0.2 * sin((held - TEST_HOLD) * TAU / 3.0)
		draw_arc(Vector2(size.x / 2.0, size.y - 56.0), 22.0, 0.0, TAU, 64, ring, 2.5, true)


func _draw_sparkles(held: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 46:
		var x := rng.randf() * size.x
		var speed := rng.randf_range(14.0, 40.0)
		var y := fposmod(rng.randf() * size.y - held * speed, size.y + 40.0) - 20.0
		var r := rng.randf_range(1.5, 4.0)
		var color := Color.WHITE
		color.a = clampf(held / 2.0, 0.0, 1.0) \
				* (0.35 + 0.35 * sin(held * rng.randf_range(1.5, 3.0) + k))
		if color.a > 0.0:
			draw_circle(Vector2(x, y), r * 2.5, Color(color, color.a * 0.25))
			draw_circle(Vector2(x, y), r, color)


# PLACEHOLDER silhouette of the couple holding each other, foreheads
# together (tools/partner/placeholder_couple.svg), until real art (ADR-0005).
# It stands on the bottom of the screen; returns its size.
func _couple_size() -> float:
	return minf(size.y * 0.95, size.x * 1.1)


# The test is held up between them, below their faces.
func _test_centre_y() -> float:
	return maxf(size.y - _couple_size() * 0.3, size.y * 0.5)


func _test_length() -> float:
	return minf(size.x * 0.78, 560.0)


func _draw_couple(alpha: float) -> void:
	var side := _couple_size()
	var rect := Rect2(Vector2((size.x - side) / 2.0, size.y - side), Vector2(side, side))
	# A soft light behind their heads.
	for k in range(6, 0, -1):
		draw_circle(rect.position + Vector2(side * 0.5, side * 0.32), side * (0.12 + k * 0.07),
				Color(1.0, 0.97, 0.9, 0.06 * alpha))
	if alpha > 0.0:
		draw_texture_rect(COUPLE_IMAGE, rect, false, Color(COUPLE, alpha))


# A positive pregnancy test, lying flat, with a plus in its window (Dan,
# 2026-10-20: "needs to have a plus/positive sign"). PLACEHOLDER picture
# (tools/partner/placeholder_test.svg).
func _draw_test(c: Vector2, show: float) -> void:
	if show <= 0.0:
		return
	var stick := Vector2(_test_length(), _test_length() * TEST_IMAGE_ASPECT)
	var rect := Rect2(c - stick / 2.0, stick)
	# The picture itself, darkened and a little lower, is its shadow.
	draw_texture_rect(TEST_IMAGE, Rect2(rect.position + Vector2(6, stick.y * 0.14), stick), false,
			Color(0.35, 0.1, 0.15, 0.3 * show))
	draw_texture_rect(TEST_IMAGE, rect, false, Color(1, 1, 1, show))
