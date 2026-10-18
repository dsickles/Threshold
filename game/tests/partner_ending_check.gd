extends SceneTree
## Headless check that every way of playing the Partner reaches its one
## ending, using a fake clock instead of real audio. Not shipped (export
## excludes tests/). Run by tools/check.ps1 and tools/publish.sh:
##   godot --headless --path game --script res://tests/partner_ending_check.gd

const PARTNER := preload("res://scenes/chapters/partner/partner.tscn")
const STEP := 1.0 / 60.0

var _failures := PackedStringArray()


class FakeConductor extends Node:
	var t := -1.0
	var tap := -1.0
	var uses_browser_clock := false
	func is_ready() -> bool: return true
	func has_failed() -> bool: return false
	func start() -> void: t = 0.0
	func stop() -> void: pass
	func pause() -> void: pass
	func resume() -> void: pass
	func is_paused() -> bool: return false
	func has_song_ended() -> bool: return false
	func song_time() -> float: return t
	func tap_time() -> float: return tap


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_case_no_taps()
	_case_all_early()
	_case_late_tap_arrives_after_good_window()
	if _failures.is_empty():
		print("Partner ending check passed.")
		quit(0)
	else:
		for failure in _failures:
			printerr("FAIL ", failure)
		quit(1)


# Opens a fresh Partner on a fake clock and taps once to start the song.
func _open() -> Array:
	var partner := PARTNER.instantiate()
	partner._sound_delay = 0.0
	partner._calibrated = false
	root.add_child(partner)  # Runs _ready now: the tree is already running.
	var fake := FakeConductor.new()
	partner.add_child(fake)
	partner._conductor = fake
	partner._process(STEP)  # LOADING -> WAITING
	partner._on_tap()  # WAITING -> PLAYING
	return [partner, fake]


# Plays the song to the end; `on_frame` may tap. Returns the final state.
func _play(partner: Node, fake: FakeConductor, on_frame: Callable) -> int:
	while fake.t < partner._song_length + 1.0 and partner._state == partner.State.PLAYING:
		fake.t += STEP
		on_frame.call(fake.t)
		partner._process(STEP)
	return partner._state


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)


func _case_no_taps() -> void:
	var opened := _open()
	var partner: Node = opened[0]
	var state := _play(partner, opened[1], func(_t: float) -> void: pass)
	_expect(state == partner.State.TEST_SHOWN, "no taps: did not reach the test (state %d)" % state)
	_expect(partner._judged.count(partner.Judged.MISSED) == partner._notes.size(),
			"no taps: not every note was missed")
	partner.free()


# Every tap 150 ms early, outside the Good window until the intro calibrates.
func _case_all_early() -> void:
	var opened := _open()
	var partner: Node = opened[0]
	var fake: FakeConductor = opened[1]
	var notes: PackedFloat64Array = partner._notes
	var next := [0]
	var state := _play(partner, fake, func(t: float) -> void:
		if next[0] < notes.size() and t >= notes[next[0]] - 0.150:
			fake.tap = t
			partner._on_tap()
			next[0] += 1)
	_expect(state == partner.State.TEST_SHOWN, "all early: did not reach the test (state %d)" % state)
	partner.free()


# A tap timed inside the Good window that reaches the game after the window
# has passed must still count (input-lag grace), not become a Miss.
func _case_late_tap_arrives_after_good_window() -> void:
	var opened := _open()
	var partner: Node = opened[0]
	var fake: FakeConductor = opened[1]
	var note: float = partner._notes[0]
	while fake.t < note + partner.GOOD_WINDOW + 0.05:
		fake.t += STEP
		partner._process(STEP)
	fake.tap = note + 0.090
	partner._on_tap()
	_expect(partner._judged[0] == partner.Judged.HIT,
			"late-arriving tap: judged %d, expected a hit" % partner._judged[0])
	partner.free()
