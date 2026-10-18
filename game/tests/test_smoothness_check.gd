extends TestCase
## The M0 smoothness check (DAS-67): the numbers it shows for the iPhone
## headroom bar. These tests check the counting; the bar itself is judged on
## the phone.

const SMOOTHNESS := preload("res://scenes/m0_checks/smoothness/smoothness_check.tscn")

var _check: Node


func before_each() -> void:
	_check = add_scene(SMOOTHNESS)
	# The tests drive frames by hand, so the real frame loop must not add any.
	_check.set_process(false)
	_check._reset_run()


func after_each() -> void:
	get_viewport().scaling_3d_scale = 1.0


# One frame of `seconds`, `frame_ms` long by the real clock.
func _frame(seconds: float, frame_ms: float = 16.0) -> void:
	_check._last_frame_usec = Time.get_ticks_usec() - int(frame_ms * 1000.0)
	_check._process(seconds)


func test_nothing_counts_during_warmup() -> void:
	for i in 4:
		_frame(0.5, 100.0)
	check_eq(_check._frames, 0, "frames counted in the first 2 s")
	check_eq(_check._hitches, 0, "hitches counted in the first 2 s")
	_frame(0.5)
	check_eq(_check._frames, 1, "frames counted after warmup")


func test_counts_hitches_and_the_worst_frame() -> void:
	_frame(_check.WARMUP_SECONDS + 0.1)
	_frame(0.016, 16.0)
	_frame(0.016, 24.0)
	_frame(0.040, 40.0)
	_frame(0.016, 16.0)
	check_eq(_check._hitches, 1, "frames over 25 ms")
	check(_check._worst_ms >= 40.0 and _check._worst_ms < 60.0,
			"worst frame about 40 ms (is %.1f)" % _check._worst_ms)


func test_run_says_done_after_two_minutes() -> void:
	_frame(60.0)
	check(_check._stats_text().contains("(keep going)"), "still running at 1:00")
	_frame(61.0)
	var text: String = _check._stats_text()
	check(text.contains("Time 2:01 of 2:00 (done)"), "done after 2:00, in: " + text)


func test_heavy_draws_four_times_the_pixels_and_restarts_the_run() -> void:
	await frames()
	_frame(10.0)
	var heavy: Button = _check.get_node("%HeavyButton")
	tap(heavy)
	check_near(get_viewport().scaling_3d_scale, 2.0, 1e-6, "3D scale with Heavy on")
	check_eq(heavy.text, "Heavy: on", "heavy button text")
	check_near(_check._elapsed, 0.0, 1e-6, "run restarted after Heavy")
	check(_check._stats_text().begins_with("Smoothness: HEAVY (4x pixels)"), "stats say heavy")
	tap(heavy)
	check_near(get_viewport().scaling_3d_scale, 1.0, 1e-6, "3D scale with Heavy off")


func test_shadow_button_turns_the_lamp_shadow_off_and_on() -> void:
	await frames()
	var button: Button = _check.get_node("%ShadowButton")
	var lamp: OmniLight3D = _check.get_node("%LampLight")
	var was_on := lamp.shadow_enabled
	tap(button)
	check_eq(lamp.shadow_enabled, not was_on, "shadow after one tap")
	tap(button)
	check_eq(lamp.shadow_enabled, was_on, "shadow after two taps")


func test_back_resets_the_scale_and_opens_the_menu() -> void:
	await frames()
	tap(_check.get_node("%HeavyButton"))
	tap(_check.get_node("%BackButton"))
	check_near(get_viewport().scaling_3d_scale, 1.0, 1e-6, "3D scale after Back")
	await frames(2)
	var scene := get_tree().current_scene
	check(scene != null and scene.scene_file_path == "res://scenes/ui/m0_menu.tscn",
			"Back opens the M0 menu")


func test_clock_reads_minutes_and_seconds() -> void:
	check_eq(_check._clock(0.0), "0:00", "clock at 0")
	check_eq(_check._clock(65.9), "1:05", "clock at 65.9 s")
	check_eq(_check._clock(120.0), "2:00", "clock at 120 s")
