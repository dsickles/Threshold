extends TestCase
## The M0 rhythm timing check (DAS-68): start the click, tap along, and read
## how early or late the taps land.

const RHYTHM := preload("res://scenes/ui/m0_rhythm_check.tscn")

var _check: Node


func before_each() -> void:
	_check = add_scene(RHYTHM)


func _results() -> String:
	return _check.get_node("%Results").text


func test_tap_pad_works_only_while_the_click_plays() -> void:
	await frames()
	var pad: Button = _check.get_node("%TapPad")
	check(pad.disabled, "tap pad off before the click starts")
	tap(pad)
	check_eq(_check._raw_offsets.size(), 0, "taps counted before the click starts")
	tap(_check.get_node("%StartButton"))
	check(not pad.disabled, "tap pad on once the click starts")
	check_eq(_check.get_node("%StartButton").text, "Stop click", "start button text while playing")
	tap(pad)
	check_eq(_check._raw_offsets.size(), 1, "taps counted while the click plays")
	tap(_check.get_node("%StartButton"))
	check(pad.disabled, "tap pad off once the click stops")
	check_eq(_check.get_node("%StartButton").text, "Start click", "start button text when stopped")


func test_keeps_only_the_last_20_taps() -> void:
	await frames()
	tap(_check.get_node("%StartButton"))
	for i in 25:
		tap(_check.get_node("%TapPad"))
	check_eq(_check._raw_offsets.size(), 20, "taps kept")
	check(_results().begins_with("Last 20 taps."), "results count the last 20 taps")


func test_a_tap_is_measured_from_the_nearest_click() -> void:
	var beat: float = _check._beat_seconds
	check(beat > 0.0, "click has a length")
	check_near(_check._wrap_to_beat(0.0), 0.0, 1e-6, "tap on the click")
	check_near(_check._wrap_to_beat(0.03), 0.03, 1e-6, "tap just late")
	check_near(_check._wrap_to_beat(-0.03), -0.03, 1e-6, "tap just early")
	check_near(_check._wrap_to_beat(beat - 0.03), -0.03, 1e-6, "tap just before the next click")
	check_near(_check._wrap_to_beat(beat * 3.0 + 0.02), 0.02, 1e-6, "tap a few clicks in")
	check_near(_check._wrap_to_beat(beat * 0.5), -beat * 0.5, 1e-6,
			"exactly half a beat counts as early for the next click")


func test_scores_average_spread_and_good_taps() -> void:
	# Seconds: on time, 50 late, 80 early, 150 late, 200 early.
	_check._raw_offsets.assign([0.0, 0.05, -0.08, 0.15, -0.2])
	_check._refresh()
	var text := _results()
	check(text.contains("Last 5 taps. Average: 16 ms early"), "average in: " + text)
	# Spread of 0, 50, -80, 150, -200 around -16 ms.
	check(text.contains("Spread: ±118 ms"), "spread in: " + text)
	check(text.contains("Within ±100 ms (Good, placeholder): 3 of 5"), "Good count in: " + text)
	check(text.contains("Newest first: -200 +150 -80 +50 +0"), "newest taps in: " + text)


func test_sound_delay_rescores_taps_already_made() -> void:
	await frames()
	# Every tap 60 ms late.
	_check._raw_offsets.assign([0.06, 0.06, 0.06])
	_check._refresh()
	check(_results().contains("Average: 60 ms late"), "before adjusting: " + _results())
	tap(_check.get_node("%DelayUpCoarseButton"))  # +25
	tap(_check.get_node("%DelayUpCoarseButton"))  # +50
	tap(_check.get_node("%DelayUpButton"))  # +55
	tap(_check.get_node("%DelayUpButton"))  # +60
	check_eq(_check.get_node("%DelayValue").text, "Sound delay: +60 ms (taps late: press +)",
			"delay readout")
	check(_results().contains("Average: on the beat"), "after adjusting: " + _results())
	tap(_check.get_node("%DelayDownButton"))  # +55
	check(_results().contains("Average: 5 ms late"), "after stepping back: " + _results())


func test_sound_delay_stops_at_half_a_beat() -> void:
	await frames()
	var limit_ms: float = _check._beat_seconds * 1000.0 / 2.0
	for i in 100:
		tap(_check.get_node("%DelayUpCoarseButton"))
	check_near(_check._delay_ms, limit_ms, 1e-3, "delay up to its limit")
	for i in 200:
		tap(_check.get_node("%DelayDownCoarseButton"))
	check_near(_check._delay_ms, -limit_ms, 1e-3, "delay down to its limit")


func test_clear_forgets_taps() -> void:
	await frames()
	_check._raw_offsets.assign([0.01, 0.02])
	_check._refresh()
	tap(_check.get_node("%ClearButton"))
	check_eq(_check._raw_offsets.size(), 0, "taps after Clear")
	check(_results().begins_with("Tap along to the click."), "results after Clear: " + _results())


func test_browser_clock_only_offered_in_the_browser() -> void:
	# These tests run outside the browser, so the comparison toggle is off.
	check(_check.get_node("%ClockButton").disabled, "browser clock button off outside the browser")


func test_buttons_are_big_enough_on_a_phone() -> void:
	for screen in [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]:
		set_screen(screen)
		await frames(2)
		for button in _check.find_children("*", "Button", true, false):
			var size: Vector2 = (button as Control).size
			check(size.x >= 44.0 and size.y >= 44.0,
					"%s at least 44px on %s (is %s)" % [button.name, screen, size])
