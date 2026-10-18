extends Control
## M0 check 2 (DAS-68): tap along to a click track and see how early or late
## the taps land. Throwaway M0 scaffolding, not game code.
##
## Two clocks, to compare on a phone:
## - Godot (the default): the Partner's planned method (architecture 4.4):
##   playback position + time since last mix - output latency. Drifted on
##   iPhone Safari.
## - Browser (web only, the comparison toggle): the click is scheduled in the
##   browser's own audio system, and a tap is timed from the touch itself
##   against the browser's record of what the speaker is playing right now.
## The click is exactly one beat long and loops, so a tap's offset is its
## distance to the nearest click.

const RECENT_TAPS := 20
const LISTED_TAPS := 10
# Placeholder: the real Good window is decided when the Partner is built.
const GOOD_WINDOW_MS := 100.0
const FINE_STEP_MS := 5.0
const COARSE_STEP_MS := 25.0

# Runs once in the page. Keeps its own AudioContext, separate from Godot's.
const BROWSER_CLOCK_JS := """
window.m0Click = window.m0Click || (function () {
	var ctx = new (window.AudioContext || window.webkitAudioContext)();
	var buf = null, src = null, t0 = 0, lastTouch = -1, method = '', active = false;
	// Browsers only allow sound to start inside a real touch handler, and
	// Godot handles input a frame later, so unlock and timestamp here.
	// Only while the check is open, so this context sleeps the rest of the time.
	function onTouch(e) {
		if (!active) { return; }
		if (e.type === 'pointerdown') { lastTouch = e.timeStamp; }
		if (ctx.state !== 'running') { ctx.resume(); }
	}
	['pointerdown', 'touchend', 'click'].forEach(function (type) {
		window.addEventListener(type, onTouch, true);
	});
	return {
		open: function () { active = true; },
		close: function () {
			this.stop();
			active = false;
			lastTouch = -1;
			ctx.suspend();
		},
		load: function (b64, rate) {
			var bytes = atob(b64), n = bytes.length / 2;
			buf = ctx.createBuffer(1, n, rate);
			var data = buf.getChannelData(0);
			for (var i = 0; i < n; i++) {
				var v = bytes.charCodeAt(2 * i) | (bytes.charCodeAt(2 * i + 1) << 8);
				data[i] = (v >= 32768 ? v - 65536 : v) / 32768;
			}
		},
		start: function () {
			this.stop();
			src = ctx.createBufferSource();
			src.buffer = buf;
			src.loop = true;
			src.connect(ctx.destination);
			t0 = ctx.currentTime + 0.1;
			src.start(t0);
		},
		stop: function () {
			if (src) { src.stop(); src.disconnect(); src = null; }
		},
		// Seconds from the first click to the moment the tap was heard.
		lastTapTime: function () {
			var touch = lastTouch >= 0 ? lastTouch : performance.now();
			if (ctx.getOutputTimestamp) {
				var ts = ctx.getOutputTimestamp();
				if (ts.contextTime > 0) {
					method = 'output timestamp';
					return ts.contextTime + (touch - ts.performanceTime) / 1000 - t0;
				}
			}
			method = 'current time';
			var latency = ctx.outputLatency || ctx.baseLatency || 0;
			return ctx.currentTime - (performance.now() - touch) / 1000 - latency - t0;
		},
		method: function () { return method; }
	};
})();
"""

var _beat_seconds: float
var _browser_available := OS.has_feature("web")
var _use_browser_clock := false
var _running := false
var _output_latency_seconds := -1.0  # Godot clock; unknown until it starts.
var _delay_ms := 0.0
# Half a beat. Offsets are measured around the current adjustment, so any
# value works; past half a beat it would only repeat the other side.
var _delay_limit_ms: float
# Offsets in seconds before the delay adjustment, so changing the adjustment
# re-scores taps already made.
var _raw_offsets: Array[float] = []

@onready var _player: AudioStreamPlayer = %ClickPlayer
@onready var _start_button: Button = %StartButton
@onready var _clock_button: Button = %ClockButton
@onready var _tap_pad: Button = %TapPad
@onready var _results: Label = %Results
@onready var _delay_value: Label = %DelayValue


func _ready() -> void:
	# Stream playback runs through Godot's mixer, which the Godot clock reading
	# depends on. The web default (samples) bypasses it.
	_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	var click: AudioStreamWAV = _player.stream
	_beat_seconds = click.get_length()
	_delay_limit_ms = _beat_seconds * 1000.0 / 2.0
	if _browser_available:
		JavaScriptBridge.eval(BROWSER_CLOCK_JS, true)
		JavaScriptBridge.eval("window.m0Click.open()", true)
		JavaScriptBridge.eval("window.m0Click.load('%s', %d)"
				% [Marshalls.raw_to_base64(click.data), click.mix_rate], true)
	_clock_button.disabled = not _browser_available
	_start_button.pressed.connect(_on_start_pressed)
	_clock_button.pressed.connect(_on_clock_pressed)
	_tap_pad.button_down.connect(_on_tap)
	%DelayDownCoarseButton.pressed.connect(_change_delay.bind(-COARSE_STEP_MS))
	%DelayDownButton.pressed.connect(_change_delay.bind(-FINE_STEP_MS))
	%DelayUpButton.pressed.connect(_change_delay.bind(FINE_STEP_MS))
	%DelayUpCoarseButton.pressed.connect(_change_delay.bind(COARSE_STEP_MS))
	%ClearButton.pressed.connect(_on_clear_pressed)
	%BackButton.pressed.connect(queue_free)
	_set_running(false)


func _exit_tree() -> void:
	_set_running(false)
	if _browser_available:
		JavaScriptBridge.eval("window.m0Click.close()", true)


func _on_start_pressed() -> void:
	_set_running(not _running)


func _on_clock_pressed() -> void:
	_set_running(false)
	_use_browser_clock = not _use_browser_clock
	_raw_offsets.clear()
	_refresh()


func _set_running(running: bool) -> void:
	if running:
		if _use_browser_clock:
			JavaScriptBridge.eval("window.m0Click.start()", true)
		else:
			# Read once: it can be slow, and it doesn't change while playing.
			_output_latency_seconds = AudioServer.get_output_latency()
			_player.play()
	else:
		_player.stop()
		if _browser_available:
			JavaScriptBridge.eval("window.m0Click.stop()", true)
	_running = running
	_start_button.text = "Stop click" if running else "Start click"
	_clock_button.text = "Clock: browser" if _use_browser_clock else "Clock: Godot"
	_tap_pad.disabled = not running
	_refresh()


func _on_tap() -> void:
	if not _running:
		return
	var heard: float
	if _use_browser_clock:
		var tap_time: Variant = JavaScriptBridge.eval("window.m0Click.lastTapTime()", true)
		if tap_time == null:
			return  # The browser side failed; skip this tap.
		heard = tap_time
	else:
		# Read when Godot handles the press, a frame or more after the touch;
		# the browser clock uses the touch's own time.
		heard = _player.get_playback_position() \
				+ AudioServer.get_time_since_last_mix() - _output_latency_seconds
	_raw_offsets.append(_wrap_to_beat(heard))
	if _raw_offsets.size() > RECENT_TAPS:
		_raw_offsets.pop_front()
	_refresh()


func _change_delay(step_ms: float) -> void:
	_delay_ms = clampf(_delay_ms + step_ms, -_delay_limit_ms, _delay_limit_ms)
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


func _clock_text() -> String:
	if _use_browser_clock:
		var method: String = JavaScriptBridge.eval("window.m0Click.method()", true)
		return "Clock: browser (%s)" % (method if method != "" else "no taps yet")
	if _output_latency_seconds < 0.0:
		return "Clock: Godot (reported delay unknown until started)"
	return "Clock: Godot (reported delay %d ms)" % roundi(_output_latency_seconds * 1000.0)


func _refresh() -> void:
	_delay_value.text = "Sound delay: %+d ms (taps late: press +)" % roundi(_delay_ms)
	if _raw_offsets.is_empty():
		_results.text = "Tap along to the click.\n\n%s" % _clock_text()
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

	var newest := PackedStringArray()
	for i in range(count - 1, maxi(count - LISTED_TAPS, 0) - 1, -1):
		newest.append("%+d" % roundi(offsets_ms[i]))

	var lines := PackedStringArray([
		"Last %d taps. Average: %s" % [count, _describe(mean)],
		"Spread: ±%d ms" % roundi(spread),
		"Within ±%d ms (Good, placeholder): %d of %d" % [roundi(GOOD_WINDOW_MS), good, count],
		"Newest first: %s" % " ".join(newest),
		_clock_text(),
	])
	_results.text = "\n".join(lines)


func _describe(offset_ms: float) -> String:
	var ms := roundi(absf(offset_ms))
	if ms == 0:
		return "on the beat"
	return "%d ms %s" % [ms, "late" if offset_ms > 0.0 else "early"]
