extends Control
## M0 check 2 (DAS-68): tap along to a click track and see how early or late
## the taps land. Throwaway M0 scaffolding, not game code.
##
## Tap time is read from the sound clock the same way the Partner will
## (architecture 4.4): playback position + time since last mix - output latency.
## The click file is exactly one beat long and loops, so a tap's offset is its
## distance to the nearest click.

const RECENT_TAPS := 20
# Placeholder: the real Good window is decided when the Partner is built.
const GOOD_WINDOW_MS := 100.0
const FINE_STEP_MS := 5.0
const COARSE_STEP_MS := 25.0
# Half a beat. Offsets are measured around the current adjustment, so any
# value works; past half a beat it would only repeat the other side.
const DELAY_LIMIT_MS := 300.0

var _beat_seconds: float
var _output_latency_seconds := -1.0  # Unknown until the click first starts.
var _delay_ms := 0.0
# Offsets in seconds before the delay adjustment, so changing the adjustment
# re-scores taps already made.
var _raw_offsets: Array[float] = []

@onready var _player: AudioStreamPlayer = %ClickPlayer
@onready var _start_button: Button = %StartButton
@onready var _tap_pad: Button = %TapPad
@onready var _results: Label = %Results
@onready var _delay_value: Label = %DelayValue


func _ready() -> void:
	# Stream playback runs through Godot's mixer, which the sound-clock reading
	# depends on. The web default (samples) bypasses it.
	_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	_beat_seconds = _player.stream.get_length()
	_start_button.pressed.connect(_on_start_pressed)
	_tap_pad.button_down.connect(_on_tap)
	%DelayDownCoarseButton.pressed.connect(_change_delay.bind(-COARSE_STEP_MS))
	%DelayDownButton.pressed.connect(_change_delay.bind(-FINE_STEP_MS))
	%DelayUpButton.pressed.connect(_change_delay.bind(FINE_STEP_MS))
	%DelayUpCoarseButton.pressed.connect(_change_delay.bind(COARSE_STEP_MS))
	%ClearButton.pressed.connect(_on_clear_pressed)
	%BackButton.pressed.connect(queue_free)
	_tap_pad.disabled = true
	_refresh()


func _on_start_pressed() -> void:
	if _player.playing:
		_player.stop()
		_start_button.text = "Start click"
		_tap_pad.disabled = true
		return
	# Read once: it can be slow, and it doesn't change while playing.
	_output_latency_seconds = AudioServer.get_output_latency()
	_player.play()
	_start_button.text = "Stop click"
	_tap_pad.disabled = false
	_refresh()


func _on_tap() -> void:
	if not _player.playing:
		return
	var heard := _player.get_playback_position() \
			+ AudioServer.get_time_since_last_mix() - _output_latency_seconds
	_raw_offsets.append(_wrap_to_beat(heard))
	if _raw_offsets.size() > RECENT_TAPS:
		_raw_offsets.pop_front()
	_refresh()


func _change_delay(step_ms: float) -> void:
	_delay_ms = clampf(_delay_ms + step_ms, -DELAY_LIMIT_MS, DELAY_LIMIT_MS)
	_refresh()


func _on_clear_pressed() -> void:
	_raw_offsets.clear()
	_refresh()


# Distance to the nearest click, from half a beat early to half a beat late.
func _wrap_to_beat(seconds: float) -> float:
	var offset := fposmod(seconds, _beat_seconds)
	if offset >= _beat_seconds / 2.0:
		offset -= _beat_seconds
	return offset


func _refresh() -> void:
	_delay_value.text = "Sound delay: %+d ms (taps late: press +)" % roundi(_delay_ms)
	var latency_text := "Reported sound delay: unknown until the click starts"
	if _output_latency_seconds >= 0.0:
		latency_text = "Reported sound delay: %d ms" % roundi(_output_latency_seconds * 1000.0)
	if _raw_offsets.is_empty():
		_results.text = "Tap along to the click.\n\n%s" % latency_text
		return

	var offsets_ms: Array[float] = []
	for raw in _raw_offsets:
		offsets_ms.append(_wrap_to_beat(raw - _delay_ms / 1000.0) * 1000.0)
	var count := offsets_ms.size()
	var mean := 0.0
	for offset in offsets_ms:
		mean += offset
	mean /= count
	var variance := 0.0
	var good := 0
	for offset in offsets_ms:
		variance += (offset - mean) ** 2
		if absf(offset) <= GOOD_WINDOW_MS:
			good += 1
	var spread := sqrt(variance / count)

	var lines := PackedStringArray([
		"Last %d taps" % count,
		"Average: %s" % _describe(mean),
		"Spread: ±%d ms" % roundi(spread),
		"Within ±%d ms (Good, placeholder): %d of %d" % [roundi(GOOD_WINDOW_MS), good, count],
		"",
		latency_text,
	])
	_results.text = "\n".join(lines)


func _describe(offset_ms: float) -> String:
	var ms := roundi(absf(offset_ms))
	if ms == 0:
		return "on the beat"
	return "%d ms %s" % [ms, "late" if offset_ms > 0.0 else "early"]
