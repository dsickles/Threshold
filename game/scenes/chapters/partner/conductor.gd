extends Node
## The Partner's Conductor: plays the song and answers two questions, "how far
## into the song is the sound the player hears right now?" and "how far into
## the song was the latest tap?". It hides which clock answers them
## (ADR-0006): the browser's audio clock on the web, Godot's clock elsewhere.
## Switching clocks is a change to this file only.
##
## Song times are seconds from the start of the song file; -1 means not playing.

# Runs once in the page. Its own AudioContext, separate from Godot's.
const BROWSER_JS := """
window.partnerConductor = window.partnerConductor || (function () {
	var ctx = new (window.AudioContext || window.webkitAudioContext)();
	var buf = null, src = null, t0 = 0, lastTouch = -1;
	// The streak layer: a second track in time with the song, through its own volume.
	var layerBuf = null, layerSrc = null, layerPending = false, layerGain = ctx.createGain();
	layerGain.gain.value = 0;
	layerGain.connect(ctx.destination);
	var active = false, playing = false, failed = false, hiddenPause = false, ended = false;
	// Browsers only start sound inside a real touch handler, and Godot sees
	// the touch a frame later, so unlock and timestamp here.
	function onTouch(e) {
		if (!active) { return; }
		if (e.type === 'pointerdown') { lastTouch = e.timeStamp; }
		if (ctx.state !== 'running' && !document.hidden) {
			hiddenPause = false;
			ctx.resume();
		}
	}
	['pointerdown', 'touchend', 'click'].forEach(function (type) {
		window.addEventListener(type, onTouch, true);
	});
	// Hiding the tab pauses the song; the chart follows the song's clock, so
	// they stay in step. A tap resumes it (see onTouch).
	document.addEventListener('visibilitychange', function () {
		if (active && playing && document.hidden) {
			hiddenPause = true;
			ctx.suspend();
		}
	});
	function heardAt(perfMs) {
		if (ctx.state === 'running' && ctx.getOutputTimestamp) {
			var ts = ctx.getOutputTimestamp();
			if (ts.contextTime > 0) {
				return ts.contextTime + (perfMs - ts.performanceTime) / 1000 - t0;
			}
		}
		var latency = ctx.outputLatency || ctx.baseLatency || 0;
		var ago = ctx.state === 'running' ? (performance.now() - perfMs) / 1000 : 0;
		return ctx.currentTime - ago - latency - t0;
	}
	return {
		open: function () { active = true; },
		close: function () {
			this.stop();
			active = false;
			lastTouch = -1;
			buf = null;  // The decoded song is large; free it once the chapter closes.
			layerBuf = null;
			layerPending = false;
			ctx.suspend();
		},
		load: function (b64) {
			buf = null;
			failed = false;
			var bytes = atob(b64), data = new Uint8Array(bytes.length);
			for (var i = 0; i < bytes.length; i++) { data[i] = bytes.charCodeAt(i); }
			ctx.decodeAudioData(data.buffer,
				function (decoded) { buf = decoded; },
				function () { failed = true; });
		},
		// The song waits for its layer, so a quick first tap still gets it. If
		// the layer can't be decoded, the song plays without it.
		loadLayer: function (b64) {
			layerBuf = null;
			layerPending = true;
			var bytes = atob(b64), data = new Uint8Array(bytes.length);
			for (var i = 0; i < bytes.length; i++) { data[i] = bytes.charCodeAt(i); }
			ctx.decodeAudioData(data.buffer,
				function (decoded) { layerBuf = decoded; layerPending = false; },
				function () { layerPending = false; });
		},
		layerPlaying: function () { return layerSrc !== null; },
		setLayer: function (level) { layerGain.gain.setTargetAtTime(level, ctx.currentTime, 0.05); },
		state: function () { return failed ? 'failed' : (buf && !layerPending ? 'ready' : 'loading'); },
		start: function (from) {
			this.stop();
			src = ctx.createBufferSource();
			src.buffer = buf;
			src.connect(ctx.destination);
			var mine = src;  // Ignore the end of a song stopped by a restart.
			src.onended = function () { if (src === mine) { ended = true; } };
			ended = false;
			t0 = ctx.currentTime + 0.1 - from;  // Song time 0, even when starting part-way.
			src.start(t0 + from, from);
			if (layerBuf) {
				layerSrc = ctx.createBufferSource();
				layerSrc.buffer = layerBuf;
				layerSrc.connect(layerGain);
				layerSrc.start(t0 + from, from);
			}
			playing = true;
		},
		stop: function () {
			if (src) { src.stop(); src.disconnect(); src = null; }
			if (layerSrc) { layerSrc.stop(); layerSrc.disconnect(); layerSrc = null; }
			layerGain.gain.value = 0;
			playing = false;
			hiddenPause = false;
		},
		// 'interrupted' is Safari's state for a phone call or another app's sound.
		// Like a hidden tab: the song stops until the next tap (onTouch).
		pause: function () {
			if (active && playing) {
				hiddenPause = true;
				ctx.suspend();
			}
		},
		ended: function () { return ended; },
		paused: function () { return playing && (hiddenPause || ctx.state === 'interrupted'); },
		songTime: function () { return playing ? heardAt(performance.now()) : -1; },
		tapTime: function () {
			if (!playing) { return -1; }
			// A touch older than a few frames isn't this tap; use now.
			var now = performance.now();
			return heardAt(lastTouch >= 0 && now - lastTouch < 100 ? lastTouch : now);
		}
	};
})();
"""

var uses_browser_clock := OS.has_feature("web")

var _player: AudioStreamPlayer
var _layer_player: AudioStreamPlayer
var _layer_level := 0.0
var _output_latency := 0.0
var _playing := false
var _native_finished := false


## Hands the Conductor its song, and a layer that plays in time with it at
## the volume set_layer_level() gives. On the web, the browser decodes them in
## the background; wait for is_ready() before start().
func load_song(stream: AudioStreamMP3, layer: AudioStreamMP3 = null) -> void:
	if uses_browser_clock:
		JavaScriptBridge.eval(BROWSER_JS, true)
		JavaScriptBridge.eval("window.partnerConductor.open()", true)
		JavaScriptBridge.eval("window.partnerConductor.load('%s')"
				% Marshalls.raw_to_base64(stream.data), true)
		if layer:
			JavaScriptBridge.eval("window.partnerConductor.loadLayer('%s')"
					% Marshalls.raw_to_base64(layer.data), true)
		return
	if layer:
		_layer_player = AudioStreamPlayer.new()
		_layer_player.stream = layer
		_layer_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		_layer_player.volume_db = -80.0
		add_child(_layer_player)
	_player = AudioStreamPlayer.new()
	_player.stream = stream
	# Stream playback runs through Godot's mixer, which the clock reading needs.
	_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	# Once the song ends, the playback position jumps back to 0.
	_player.finished.connect(func() -> void: _native_finished = true)
	add_child(_player)


func is_ready() -> bool:
	if uses_browser_clock:
		return JavaScriptBridge.eval("window.partnerConductor.state()", true) == "ready"
	return _player != null


## True if the browser could not decode the song.
func has_failed() -> bool:
	return uses_browser_clock \
			and JavaScriptBridge.eval("window.partnerConductor.state()", true) == "failed"


## Starts the song, `from` seconds in (the browser tests skip to the ending).
func start(from := 0.0) -> void:
	_playing = true
	if uses_browser_clock:
		JavaScriptBridge.eval("window.partnerConductor.start(%f)" % from, true)
		return
	# Read once: it can be slow, and it doesn't change while playing.
	_output_latency = AudioServer.get_output_latency()
	_native_finished = false
	_player.play(from)
	if _layer_player:
		_layer_player.play(from)


func stop() -> void:
	_playing = false
	if uses_browser_clock:
		JavaScriptBridge.eval("window.partnerConductor.close()", true)
	elif _player:
		_player.stop()
		if _layer_player:
			_layer_player.stop()
	_layer_level = 0.0


## How loud the layer plays, 0 (silent) to 1.
func set_layer_level(level: float) -> void:
	level = clampf(level, 0.0, 1.0)
	# Small steps are skipped, but silent and full are always reached.
	if not _playing or level == _layer_level \
			or (absf(level - _layer_level) < 0.01 and level != 0.0 and level != 1.0):
		return
	_layer_level = level
	if uses_browser_clock:
		JavaScriptBridge.eval("window.partnerConductor.setLayer(%f)" % level, true)
	elif _layer_player:
		_layer_player.volume_db = linear_to_db(maxf(level, 0.0001))


## Pauses the song until the next tap. Native builds pause here when the
## window loses focus; the web pauses on its own when the tab is hidden, and
## here for the "Turn your phone sideways" screen.
func pause() -> void:
	if _playing and uses_browser_clock:
		JavaScriptBridge.eval("window.partnerConductor.pause()", true)
	elif _playing:
		_player.stream_paused = true
		if _layer_player:
			_layer_player.stream_paused = true


## Native only: the web resumes inside the touch handler itself.
func resume() -> void:
	if not uses_browser_clock and _player:
		_player.stream_paused = false
		if _layer_player:
			_layer_player.stream_paused = false


## True while the streak layer is playing along with the song.
func is_layer_playing() -> bool:
	if not _playing:
		return false
	if uses_browser_clock:
		return _is_true(JavaScriptBridge.eval("window.partnerConductor.layerPlaying()", true))
	return _layer_player != null and _layer_player.playing


func is_paused() -> bool:
	if not _playing:
		return false
	if uses_browser_clock:
		return _is_true(JavaScriptBridge.eval("window.partnerConductor.paused()", true))
	return _player.stream_paused


## True once the whole song file has played, in case it is shorter than the
## chart says.
func has_song_ended() -> bool:
	if not _playing:
		return false
	if uses_browser_clock:
		return _is_true(JavaScriptBridge.eval("window.partnerConductor.ended()", true))
	return _native_finished


func song_time() -> float:
	if not _playing:
		return -1.0
	if uses_browser_clock:
		var t: Variant = JavaScriptBridge.eval("window.partnerConductor.songTime()", true)
		return t if t != null else -1.0
	if _native_finished:
		return _player.stream.get_length()
	return _player.get_playback_position() \
			+ AudioServer.get_time_since_last_mix() - _output_latency


## Song time of the tap being handled now. On the web it comes from the touch
## event's own timestamp; natively it is read when Godot handles the press.
func tap_time() -> float:
	if not _playing:
		return -1.0
	if uses_browser_clock:
		var t: Variant = JavaScriptBridge.eval("window.partnerConductor.tapTime()", true)
		return t if t != null else -1.0
	return song_time()


# A JavaScript true can come back as 1, not true, and 1 == true is an error
# in GDScript, so read either.
static func _is_true(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
	return false


func _exit_tree() -> void:
	stop()
