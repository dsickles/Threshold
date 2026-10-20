extends TestCase
## The Partner, rough first playable (DAS-73), on a fake clock instead of real
## sound. Sound timing on a real phone is still Dan's to check.

const PARTNER := preload("res://scenes/chapters/partner/partner.tscn")
const PARTNER_SCRIPT := preload("res://scenes/chapters/partner/partner.gd")
const MENU := preload("res://scenes/ui/m0_menu.tscn")
const STEP := 1.0 / 60.0


class FakeConductor extends Node:
	var t := -1.0
	var tap := -1.0
	var paused := false
	var uses_browser_clock := false
	func is_ready() -> bool: return true
	func has_failed() -> bool: return false
	func start(from := 0.0) -> void: t = from
	func stop() -> void: pass
	func pause() -> void: paused = true
	func resume() -> void: paused = false
	func is_paused() -> bool: return paused
	func has_song_ended() -> bool: return false
	func song_time() -> float: return t
	func tap_time() -> float: return tap


var _partner: Node
var _fake: FakeConductor


func before_each() -> void:
	# The sound delay is kept between runs on purpose; tests start from none.
	PARTNER_SCRIPT._sound_delay = 0.0
	PARTNER_SCRIPT._calibrated = false
	_partner = add_scene(PARTNER)
	_fake = FakeConductor.new()
	_partner.add_child(_fake)
	_partner._conductor = _fake
	_partner._process(STEP)  # Loading -> waiting for the first tap.


func test_first_tap_starts_the_song() -> void:
	check_eq(_partner.probe_state().prompt, "Tap to begin", "prompt before the song")
	_partner._on_tap()
	check_eq(_partner.probe_state().state, "PLAYING", "state after the first tap")
	check_eq(_fake.t, 0.0, "song started")


func test_no_taps_still_reaches_the_test_and_reports_finished() -> void:
	var reported := [false]
	_partner.finished.connect(func() -> void: reported[0] = true)
	_partner._on_tap()
	_play_to_end(func(_t: float) -> void: pass)
	check_eq(_partner.probe_state().state, "TEST_SHOWN", "state after the song")
	check_eq(_partner.probe_state().misses, _partner._notes.size(), "every note missed")
	# Dan, 2026-10-20: "'honey' from her, a jubilant 'yes' from him, and then
	# they both laugh", in that order, then gone.
	var said: Array[String] = []
	for i in ceili(_partner.TEST_LINES_END / STEP) + 1:
		_partner._process(STEP)
		var line: String = _partner.probe_state().subtitle
		if line != "" and (said.is_empty() or said[-1] != line):
			said.append(line)
	check_eq(said, ["Honey.", "Yes!", "(They both laugh.)"], "what they say at the test")
	check_eq(_partner.probe_state().subtitle, "", "subtitles gone after the lines")
	_partner._on_tap()
	check(not reported[0], "a tap while the test holds does nothing")
	for i in ceili((_partner.TEST_HOLD - _partner.TEST_LINES_END) / STEP) + 1:
		_partner._process(STEP)
	check(not reported[0], "the test waits for a tap after it has held")
	check(_partner.probe_state().can_leave, "the quiet ring shows after the hold")
	_partner._on_tap()
	check(reported[0], "a tap after the hold reports finished")


func test_every_tap_early_still_reaches_the_test() -> void:
	_partner._on_tap()
	var notes: PackedFloat64Array = _partner._notes
	var next := [0]
	_play_to_end(func(t: float) -> void:
		# 300 ms early: outside Good, and outside the intro's calibration
		# window, so the sound delay can't move to meet the taps.
		if next[0] < notes.size() and t >= notes[next[0]] - 0.300:
			_tap(t)
			next[0] += 1)
	check_eq(_partner.probe_state().state, "TEST_SHOWN", "state after the song")
	check_eq(_partner.probe_state().misses, notes.size(), "every early tap missed")


func test_taps_on_the_note_are_perfect() -> void:
	_partner._on_tap()
	var note: float = _partner._notes[0]
	_step_to(note)
	_tap(note + 0.02)
	check_eq(_partner._judged[0], _partner.Judged.HIT, "first note")
	check_eq(_partner.get_node("%Judgement").text, "Perfect", "judgement shown")


func test_a_stray_tap_does_nothing() -> void:
	_partner._on_tap()
	var early: float = _partner._notes[0] - 0.5
	_step_to(early)
	_tap(early)
	check_eq(_partner.probe_state().hits, 0, "hits")
	check_eq(_partner.probe_state().misses, 0, "misses")
	check_eq(_partner.get_node("%Judgement").text, "", "no judgement shown")


# A tap timed inside the Good window that reaches the game after the window
# has passed must still count (input-lag grace), not become a Miss.
func test_a_late_arriving_tap_inside_the_window_still_hits() -> void:
	_partner._on_tap()
	var note: float = _partner._notes[0]
	_step_to(note + _partner.GOOD_WINDOW + 0.05)
	_tap(note + 0.150)
	check_eq(_partner._judged[0], _partner.Judged.HIT, "first note")


func test_intro_taps_set_the_sound_delay() -> void:
	_partner._on_tap()
	for i in 4:
		var note: float = _partner._notes[i]
		_step_to(note + 0.08)
		_tap(note + 0.08)
	check_near(_partner._sound_delay, 0.08, 0.001, "sound delay from four taps 80 ms late")
	check_eq(_partner.probe_state().hits, 4, "intro taps still count as hits")


# Hopper, 2026-10-20: one intro tap 240 ms late, while finding the beat, set
# the delay for the whole song and turned every on-time tap after it into a Miss.
func test_one_stray_intro_tap_does_not_set_the_sound_delay() -> void:
	_partner._on_tap()
	for i in _partner.MIN_CALIBRATION_TAPS - 1:
		var note: float = _partner._notes[i]
		_step_to(note + 0.24)
		_tap(note + 0.24)
	check_eq(_partner._sound_delay, 0.0, "no delay until enough intro taps")


func test_lights_fall_from_the_top_to_the_heart() -> void:
	var c: Vector2 = _partner._heart_centre()
	var r := 10.0
	var appear: Vector2 = _partner._light_position(c, r, _partner.TRAVEL)
	check_near(appear.y, -r, 0.001, "a light appears just above the top")
	check_near(appear.x, c.x, 0.001, "in the heart's lane")
	check(_partner._light_position(c, r, _partner.TRAVEL / 2.0).y < c.y, "above the heart before its note")
	check_near(_partner._light_position(c, r, 0.0).y, c.y, 0.001, "at the heart on its note")


func test_misses_in_the_intro_never_laugh() -> void:
	_partner._on_tap()
	_step_to(_partner._intro_end - 0.2)
	check(_partner.probe_state().misses > 0, "intro notes were missed")
	check_eq(_partner._last_laugh, -INF, "no laugh in the intro")


func test_hidden_tab_pauses_and_a_tap_resumes_without_counting() -> void:
	_partner._on_tap()
	var note: float = _partner._notes[0]
	_step_to(note - 0.5)
	_fake.paused = true  # What the Conductor reports while the tab is hidden.
	for i in 30:
		_partner._process(STEP)  # The song's clock is frozen too.
	check_eq(_partner.probe_state().state, "PAUSED", "state while hidden")
	check_eq(_partner.probe_state().prompt, "Tap to continue", "prompt while hidden")
	_fake.tap = note
	_partner._on_tap()
	_partner._process(STEP)
	check_eq(_partner.probe_state().state, "PLAYING", "state after the tap")
	check_eq(_partner._judged[0], _partner.Judged.PENDING, "the resume tap was not judged")


func test_the_menu_opens_the_partner_and_takes_it_back_when_finished() -> void:
	_partner.free()  # It takes every tap, so it would swallow the menu's.
	var menu := add_scene(MENU)
	tap(menu.get_node("%BeginButton"))
	await frames()
	var button: Control = menu.get_node("%PartnerButton")
	check(button.size.x >= 44.0 and button.size.y >= 44.0, "Partner button is at least 44px")
	tap(button)
	var partner := menu.get_node_or_null("Partner")
	if not check(partner != null, "Partner opened"):
		return
	check(not menu.get_node("%Menu").visible, "menu hidden while the Partner plays")
	partner.finished.emit()
	await frames()
	check(not is_instance_valid(partner), "Partner closed when finished")
	check(menu.get_node("%Menu").visible, "menu back after the Partner finished")


func _tap(t: float) -> void:
	_fake.tap = t
	_partner._on_tap()


func _step_to(t: float) -> void:
	while _fake.t < t:
		_fake.t += STEP
		_partner._process(STEP)


func _play_to_end(on_frame: Callable) -> void:
	while _fake.t < _partner._song_length + 1.0 and _partner.probe_state().state == "PLAYING":
		_fake.t += STEP
		on_frame.call(_fake.t)
		_partner._process(STEP)


func test_judgement_sits_below_the_heart_on_every_screen() -> void:
	for screen in [Vector2i(1280, 720), Vector2i(393, 852), Vector2i(852, 393)]:
		set_screen(screen)
		await frames()
		_partner._process(STEP)
		var heart_bottom: float = _partner._heart_centre().y + _partner._heart_size()
		var label: Control = _partner.get_node("%Judgement")
		check(label.get_rect().position.y >= heart_bottom,
				"judgement clear of the heart at %s (label top %s, heart bottom %s)"
				% [screen, label.get_rect().position.y, heart_bottom])
		check(label.get_rect().end.y <= _partner.size.y, "judgement on screen at %s" % screen)


func test_the_chart_matches_the_draft() -> void:
	var notes: PackedFloat64Array = _partner._notes
	# Dan, 2026-10-20: easier than the draft's 388 notes, 250 ms apart.
	check_eq(notes.size(), 308, "notes in the chart")
	var closest := INF
	for i in range(1, notes.size()):
		closest = minf(closest, notes[i] - notes[i - 1])
	check(closest >= 0.500 - 0.0001, "no two notes closer than 500 ms (closest %s s)" % closest)
	# Bar 100, beat 1 at 120 BPM: 99 bars of 2 s after bar 1, beat 1.
	check_near(notes[-1] - _partner._song_start, 198.0, 0.0001, "last note at bar 100, beat 1")


# Dan, 2026-10-20: on a first run most people should get most beats at least
# Good, with fewer than 5 misses. A modelled first-timer: each tap lands a
# little late on average (40 ms, which the intro's calibration takes out),
# give or take 60 ms. A model, not a measurement; real players are Dan's check.
func test_a_typical_first_run_gets_most_beats_with_few_misses() -> void:
	var runs := 10
	var misses := 0
	var good_or_better := 0
	var notes: PackedFloat64Array = _partner._notes
	for run in runs:
		_partner.free()
		before_each()
		var rng := RandomNumberGenerator.new()
		rng.seed = run
		var taps: Array[float] = []
		for note in notes:
			taps.append(note + 0.040 + rng.randfn(0.0, 0.060))
		_partner._on_tap()
		var next := [0]
		_play_to_end(func(t: float) -> void:
			while next[0] < taps.size() and taps[next[0]] <= t:
				_tap(taps[next[0]])
				next[0] += 1)
		misses += _partner.probe_state().misses
		good_or_better += _partner.probe_state().hits
	var mean_misses := float(misses) / runs
	check(mean_misses < 5.0, "fewer than 5 misses a run on average (%.1f)" % mean_misses)
	check(float(good_or_better) / (runs * notes.size()) >= 0.95,
			"most beats Good or better (%d of %d)" % [good_or_better, runs * notes.size()])
