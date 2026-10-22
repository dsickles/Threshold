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
	var layer_level := 0.0
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
	func set_layer_level(level: float) -> void: layer_level = level
	func is_layer_playing() -> bool: return t >= 0.0


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
			_tap(notes[next[0]] - 0.300)
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
	var state := get_node("/root/GameState")
	state.start_new()
	var menu := add_scene(MENU)
	tap(menu.get_node("%BeginButton"))
	await frames()
	var button: Control = menu.get_node("%PartnerButton")
	check(button.size.x >= 44.0 and button.size.y >= 44.0, "Partner button is at least 44px")
	tap(button)
	# The menu stands in for the House; the chapter runner (DAS-75) plays it.
	var runner := ChapterRunner.of(get_tree())
	# GameState listens to the runner it found at start-up; earlier tests free
	# theirs, so hook this one up the same way.
	if not runner.chapter_finished.is_connected(state.record_chapter_result):
		runner.chapter_finished.connect(state.record_chapter_result)
	var partner: Node = runner.get_child(0) if runner.get_child_count() > 0 else null
	if not check(partner != null and partner.scene_file_path == PARTNER.resource_path, "Partner opened"):
		runner.free()
		return
	check(not menu.visible, "menu hidden while the Partner plays")
	partner.finished.emit()
	await frames()
	check(not is_instance_valid(partner), "Partner closed when finished")
	check(menu.visible and menu.get_node("%Menu").visible, "menu back after the Partner finished")
	check_eq(menu.get_node("%Status").text, "Finished partner (answer: none)", "menu heard the result")
	check(state.is_finished("partner"), "the Partner's result was saved")
	state.start_new()
	runner.free()  # It lives on the root, so it would outlast this test.


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
	# Dan, 2026-10-20: easier than the draft's 388 notes, 250 ms apart, then more varied.
	# Dan, 2026-10-21: a real crescendo in the last bars, but the triplets
	# there were "too fast": the most notes in a row, never faster. Later the
	# same day: a real track at 90 BPM (bars of 8/3 s), so the chart follows it.
	# After playing it: "The tap should [go] along with the song. Period", so
	# every note sits on the track's grid of sixteenths, whose hits land 25 ms
	# after its bar lines.
	var bar := 8.0 / 3.0
	var beat := bar / 4.0
	check_eq(notes.size(), 144, "notes in the chart")
	check_near(_partner._song_start, 0.025, 0.0001, "the track's hits land 25 ms after its bar lines")
	for note in notes:
		var sixteenths: float = (note - _partner._song_start) / (beat / 4.0)
		if absf(sixteenths - roundf(sixteenths)) > 0.01:
			check(false, "note at %s s is off the track's grid" % note)
	check_near(_partner._crescendo - _partner._song_start, 52 * bar, 0.001, "crescendo from bar 53")
	var closest := INF
	for i in range(1, notes.size()):
		closest = minf(closest, notes[i] - notes[i - 1])
	check(closest >= 0.500 - 0.0001, "no two notes closer than 500 ms (closest %s s)" % closest)
	var in_crescendo := 0
	for note in notes:
		if note >= _partner._crescendo:
			in_crescendo += 1
	# On its clear hits (2, 3 and 4; beat 1 is the ducked kick), then the last.
	check_eq(in_crescendo, 34, "notes in the crescendo, then the last")
	# Dan, 2026-10-20: "more variation in the beat": some notes fall between beats.
	var between := 0
	for note in notes:
		var off_beat: float = fposmod(note - _partner._song_start, beat)
		if off_beat > 0.002 and off_beat < beat - 0.002:
			between += 1
	check(between >= 20, "notes between the beats (%d)" % between)
	check_near(notes[-1] - _partner._song_start, 64 * bar, 0.001, "last note at bar 65, beat 1")
	check_near(_partner._heartbeat, 2.0 * beat, 0.0001, "the heart beats on beats 1 and 3")


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


# Dan, 2026-10-21: "a streak of hits warms the screen and adds a layer to the
# song, which settles back after a miss".
func test_a_streak_warms_and_a_miss_lets_it_settle_back() -> void:
	_partner._on_tap()
	var notes: PackedFloat64Array = _partner._notes
	var streak: int = _partner.STREAK_FULL
	for i in streak:
		_step_to(notes[i])
		_tap(notes[i])
	check_eq(_partner._streak, streak, "streak after %d hits" % streak)
	check_eq(_partner._bursts.size() > 0, true, "a hit sends out sparkles")
	_step_to(notes[streak] - 0.05)
	check(_partner._warmth > 0.9, "warm after a full streak (%.2f)" % _partner._warmth)
	check(_fake.layer_level > 0.9, "the layer is up (%.2f)" % _fake.layer_level)
	check(_partner._bursts.is_empty(), "sparkles fade")
	_step_to(notes[streak] + _partner.GOOD_WINDOW + _partner.MISS_GRACE + 0.05)
	check_eq(_partner._streak, 0, "a miss ends the streak")
	check(_partner._warmth > 0.8, "warmth settles, it doesn't drop (%.2f)" % _partner._warmth)
	_step_to(_fake.t + 2.0 / _partner.WARM_FALL)
	check(_partner._warmth < 0.05, "and is gone a while after (%.2f)" % _partner._warmth)
	check(_fake.layer_level < 0.05, "the layer too (%.2f)" % _fake.layer_level)


# The crescendo's colours: none before it starts, in full on the last note.
func test_the_crescendo_blooms_to_full_on_the_last_note() -> void:
	var notes: PackedFloat64Array = _partner._notes
	var start: float = _partner._crescendo
	check_eq(_partner._bloom(start - 1.0), 0.0, "no bloom before the crescendo")
	var mid: float = _partner._bloom((start + notes[-1]) / 2.0)
	check(mid > 0.4 and mid < 0.6, "halfway through, half bloomed (%.2f)" % mid)
	check_eq(_partner._bloom(notes[-1]), 1.0, "full on the last note")


# Dan, 2026-10-21: "every streak grants *the next* silhouette, even if you
# just get 8, miss, then 8 again", for all of them without long streaks.
func test_each_streak_of_8_brings_in_the_next_moment() -> void:
	_partner._on_tap()
	var notes: PackedFloat64Array = _partner._notes
	var streak: int = _partner.MOMENT_STREAK
	for i in streak - 1:
		_step_to(notes[i])
		_tap(notes[i])
	check_eq(_partner.probe_state().moments, 0, "none after %d hits" % (streak - 1))
	_step_to(notes[streak - 1])
	_tap(notes[streak - 1])
	check_eq(_partner.probe_state().moments, 1, "the first after %d in a row" % streak)
	# Miss one, then 8 more in a row: the next one comes, once 12 s have
	# passed since the first.
	var i := streak + 1
	for k in streak:
		_step_to(notes[i])
		_tap(notes[i])
		i += 1
	var first: float = _partner._moment_times[0]
	check(_partner._song_time - first < _partner.MOMENT_GAP, "this chart's intro is quicker than the gap")
	check_eq(_partner.probe_state().moments, 1, "not before the gap")
	while _partner._song_time - first < _partner.MOMENT_GAP:
		_step_to(notes[i])
		_tap(notes[i])
		i += 1
	check_eq(_partner.probe_state().moments, 2, "8, a miss, then 8 again: the next one")


func test_a_miss_starts_the_count_again() -> void:
	_partner._on_tap()
	var notes: PackedFloat64Array = _partner._notes
	var streak: int = _partner.MOMENT_STREAK
	for i in streak - 1:
		_step_to(notes[i])
		_tap(notes[i])
	# Note streak - 1 is missed; then streak - 1 more is one short again.
	var i := streak
	for k in streak - 1:
		_step_to(notes[i])
		_tap(notes[i])
		i += 1
	check_eq(_partner.probe_state().moments, 0, "7, a miss, then 7: none yet")
	_step_to(notes[i])
	_tap(notes[i])
	check_eq(_partner.probe_state().moments, 1, "the eighth after the miss brings one")


func test_hitting_every_note_shows_every_moment_spread_across_the_song() -> void:
	_partner._on_tap()
	var notes: PackedFloat64Array = _partner._notes
	var next := [0]
	_play_to_end(func(t: float) -> void:
		while next[0] < notes.size() and notes[next[0]] <= t:
			_tap(notes[next[0]])
			next[0] += 1)
	var times: Array[float] = _partner._moment_times
	check_eq(times.size(), _partner.MOMENTS.size(), "all %d moments" % _partner.MOMENTS.size())
	for k in range(1, times.size()):
		check(times[k] - times[k - 1] >= _partner.MOMENT_GAP - 0.001, "at least 12 s apart (%d)" % k)
	check(times[-1] > notes[-1] * 0.6, "the last comes late in the song (%.0f s)" % times[-1])


func test_a_typical_first_run_shows_every_moment() -> void:
	var notes: PackedFloat64Array = _partner._notes
	for run in 10:
		_partner.free()
		before_each()
		var rng := RandomNumberGenerator.new()
		rng.seed = run
		_partner._on_tap()
		var taps: Array[float] = []
		for note in notes:
			taps.append(note + 0.040 + rng.randfn(0.0, 0.060))
		var next := [0]
		_play_to_end(func(t: float) -> void:
			while next[0] < taps.size() and taps[next[0]] <= t:
				_tap(taps[next[0]])
				next[0] += 1)
		check_eq(_partner.probe_state().moments, _partner.MOMENTS.size(),
				"every moment on a typical run (seed %d)" % run)


func test_moments_stay_clear_of_the_heart_and_on_screen() -> void:
	for screen in [Vector2i(1280, 720), Vector2i(393, 852), Vector2i(852, 393)]:
		set_screen(screen)
		await frames()
		var c: Vector2 = _partner._heart_centre()
		var lane := Rect2(c.x - _partner._heart_size() * 1.2, 0, _partner._heart_size() * 2.4,
				_partner.size.y)
		var screen_rect := Rect2(Vector2.ZERO, _partner.size)
		for k in _partner.MOMENTS.size():
			var rect: Rect2 = _partner._moment_rect(k)
			check(screen_rect.encloses(rect), "moment %d on screen at %s" % [k + 1, screen])
			check(not rect.intersects(lane), "moment %d clear of the hearts at %s" % [k + 1, screen])
			check(rect.size.x >= 60.0, "moment %d big enough to see at %s (%.0f px)"
					% [k + 1, screen, rect.size.x])
			for j in k:
				check(not rect.intersects(_partner._moment_rect(j)),
						"moments %d and %d don't overlap at %s" % [j + 1, k + 1, screen])


# Hopper, 2026-10-21: the browser hands a JavaScript true back as 1, and
# 1 == true is an error in GDScript, so "is the layer playing" (and "has the
# song ended") came back empty on the web.
func test_the_conductor_reads_browser_true_and_false() -> void:
	var conductor := preload("res://scenes/chapters/partner/conductor.gd")
	check(conductor._is_true(true), "true")
	check(conductor._is_true(1), "1")
	check(not conductor._is_true(false), "false")
	check(not conductor._is_true(0), "0")
	check(not conductor._is_true(null), "nothing")


func test_recording_plays_with_no_notes_and_keeps_every_tap() -> void:
	check_eq(_partner._record_buttons.size(), 3, "record buttons on the waiting screen")
	_partner.start_recording(29)
	var from: float = 28 * 2.0 * _partner._heartbeat
	check(absf(_fake.t - (from + _partner._song_start - 1.0)) < 0.001, "starts a second before bar 29")
	for at: float in [from + 0.5, from + 1.25, from + 1.3]:
		_fake.t = at + _partner._song_start
		_fake.tap = _fake.t
		_partner._process(STEP)
		_partner._on_tap()
	check_eq(_partner.probe_state().recorded, 3, "every tap kept, even close ones")
	check_eq(_partner.probe_state().misses, 0, "no notes, so no misses")
	check_eq(_fake.layer_level > 0.0, true, "the full song, unmuffled")
	_fake.t = _partner._song_length + 0.1
	_partner._process(STEP)
	check_eq(_partner.probe_state().state, "DONE", "stops at the end of the song")
	var text: String = _partner._recorder.text()
	check(text.begins_with("partner-taps from=%d: " % roundi(from * 1000.0)), "pasteable text: " + text)
	check_eq(text.get_slice(": ", 1).split(",").size(), 3, "three taps in the text")
