extends Control
## The Novice (the Long Haul), rough M2 playable (DAS-133). Six months of
## IVF as micro-games: the Injection first (Maya asks Leo to help with her
## shot; one Stoic/Vulnerable line), then numb, frantic and exhausted months
## of "OPEN THE BOX!", "MIX THE POWDER!" and "INJECT THE BUTT!", ending on a
## positive test. From docs/design/story-beats.md §3 and
## docs/design/stories/epic-3-stories.md. The order of the games and how
## each phase plays are in novice_plan.gd (a DRAFT design for Dan to tune).
##
## Fail-forward: a game that runs out of time just moves on, and every player
## reaches the same test. The chapter only reports that it finished, with the
## Injection's answer; it never touches the House or saved state. Leaving
## part-way gives no result, so the next visit starts again from the quiet
## kitchen. Placeholder art, drawn here; no sound yet.

signal finished(answer: String)

const NovicePlan := preload("res://scenes/chapters/novice/novice_plan.gd")
const Game := NovicePlan.Game
const Phase := NovicePlan.Phase

enum Beat { QUIET, TALK, CHOICE, REPLY, GAMES, RESULT, DONE }
enum Stage { GAP, PLAY, OUTRO }

const QUIET_TIME := 3.0  # The gray kitchen, nothing said yet.
const LINE_TIME := 3.6  # Each spoken line, unless a tap moves it on.
const LINE_MIN := 0.6  # A tap sooner than this doesn't skip the line.
const OUTRO_TIME := 0.9  # After a game, before the next one's pause.
const TEST_LINE_TIME := 2.5  # The test's second line coming through.
const TEST_HOLD := 8.0  # The test holds before a tap can go back.
const COLOUR_RATE := 0.5  # Saturation gained or lost a second: a slow fade.
const FLINCH_TIME := 0.35

# PLACEHOLDER: every line below is Claude's stand-in until Dan writes or
# approves the Injection's words (story-beats.md §3, "Words (Dan)").
const MAYA_ASKS: Array[String] = [
	"Maya: The nurse showed you. You watched.",  # PLACEHOLDER
	"Maya: I can't reach. It has to be you.",  # PLACEHOLDER
]
const LEO_LINES := {
	ChapterResult.STOIC: "Okay. I've got this.",  # PLACEHOLDER
	ChapterResult.VULNERABLE: "I'm scared I'll hurt you.",  # PLACEHOLDER
}
const MAYA_REPLIES := {
	ChapterResult.STOIC: "Maya: Okay. On three.",  # PLACEHOLDER
	ChapterResult.VULNERABLE: "Maya: Me too. Do it anyway.",  # PLACEHOLDER
}

# The kitchen at night, and the loud colours of the frantic months. Gray
# comes from the saturation, never from separate gray art.
const NIGHT := Color("#22304A")
const WALL := Color("#3B4F6B")
const COUNTER := Color("#6B4E3A")
const FRIDGE := Color("#C9D3D8")
const MOON := Color("#F2E6B8")
const LOUD: Array[Color] = [Color("#FF5FA2"), Color("#FFD23F"), Color("#3BCEAC"), Color("#7A5CFF")]
const CARDBOARD := Color("#C89B6A")
const CARDBOARD_DARK := Color("#9C744B")
const MIX := Color("#7FD1FF")
const BAND := Color("#3BCEAC")
const SKIN := Color("#E8B49A")
const SKIN_DARK := Color("#C98F78")
const TARGET := Color("#E0475B")
const STEEL := Color("#DDE3E8")
const PAPER := Color("#F4EFE6")
const INK := Color("#2A2520")
const TEST_LINE := Color("#C2185B")

## Off for tests, which step the chapter's clock themselves.
var auto_advance := true

var _t := 0.0  # Seconds into the chapter; stops while paused.
var _beat := Beat.QUIET
var _beat_t := 0.0
var _lines: Array[String] = []
var _line := 0
var _answer := ChapterResult.NO_ANSWER
var _round := -1
var _r := {}  # The round playing now (NovicePlan.round_at).
var _stage := Stage.GAP
var _stage_t := 0.0
var _won := false
var _results: Array[String] = []  # "won" or "missed", one a round.
var _presses := 0  # Presses in this phase, for the taps that don't take.
var _pending: Array[Array] = []  # [when it lands, pressed] for a lagging tap.
var _holding := false
var _press_dropped := false  # The press didn't take, so its release doesn't either.
var _taps := 0  # Taps on the box this round.
var _level := 0.0  # The powder's mix, 0 to 1.
var _needle := 0.0  # The needle's sway, -1 to 1 around the target.
var _flinch := 0.0
var _saturation := 0.0
var _frenzy := 0.0  # How much of the frantic months' loud colour shows.
var _paused := false
var _test_t := 0.0
var _finished_sent := false

var _subtitle: Label
var _shout: Label
var _choices: HBoxContainer
var _choice_buttons := {}
var _document: JavaScriptObject
var _visibility_callback: JavaScriptObject


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_screen()
	# Browser tests can start part-way in (see web_test_probe.gd).
	var from: String = get_tree().root.get_meta("novice_start_at", "")
	if from == "games":
		_answer = ChapterResult.STOIC
		_start_games()
	elif from == "result":
		_answer = ChapterResult.STOIC
		_start_result()
	if OS.has_feature("web"):
		# Hiding the tab pauses the chapter; Godot doesn't say so on the web.
		_document = JavaScriptBridge.get_interface("document")
		_visibility_callback = JavaScriptBridge.create_callback(_on_visibility_change)
		_document.addEventListener("visibilitychange", _visibility_callback)
	_update_screen()


func _exit_tree() -> void:
	if _document:
		_document.removeEventListener("visibilitychange", _visibility_callback)
		_document = null


func _build_screen() -> void:
	_shout = Label.new()
	_shout.name = "Shout"
	_shout.theme_type_variation = &"LabelMicroShout"
	_shout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shout.hide()
	add_child(_shout)

	_subtitle = Label.new()
	_subtitle.name = "Subtitle"
	_subtitle.theme_type_variation = &"LabelSubtitle"
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle.hide()
	add_child(_subtitle)

	_choices = HBoxContainer.new()
	_choices.name = "Choices"
	_choices.alignment = BoxContainer.ALIGNMENT_CENTER
	_choices.add_theme_constant_override("separation", 24)
	_choices.hide()
	add_child(_choices)
	for answer: String in [ChapterResult.STOIC, ChapterResult.VULNERABLE]:
		var button := Button.new()
		button.name = answer.capitalize() + "Button"
		button.theme_type_variation = &"ButtonQuiet"
		button.text = LEO_LINES[answer]
		button.custom_minimum_size = Vector2(0, 64)
		button.pressed.connect(choose.bind(answer))
		_choices.add_child(button)
		_choice_buttons[answer] = button
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	var w := size.x
	var h := size.y
	_subtitle.size = Vector2(minf(w - 48.0, 1100.0), 0.0)
	_subtitle.position = Vector2((w - _subtitle.size.x) / 2.0, h * 0.84)
	_choices.reset_size()
	_choices.position = Vector2((w - _choices.size.x) / 2.0, h * 0.84)
	_shout.reset_size()
	_shout.pivot_offset = _shout.size / 2.0
	_shout.position = Vector2((w - _shout.size.x) / 2.0, h * 0.08)


func _process(delta: float) -> void:
	if auto_advance:
		advance(delta)


# --- The clock.

## Moves the chapter on by `delta` seconds. Called each frame, or by tests.
func advance(delta: float) -> void:
	if _paused or _beat == Beat.DONE:
		return
	_t += delta
	_beat_t += delta
	_saturation = move_toward(_saturation, _target_saturation(), COLOUR_RATE * delta)
	var frantic := 1.0 if _beat == Beat.GAMES and _r.phase == Phase.FRANTIC else 0.0
	_frenzy = move_toward(_frenzy, frantic, COLOUR_RATE * delta)
	match _beat:
		Beat.QUIET:
			if _beat_t >= QUIET_TIME:
				_start_lines(Beat.TALK, MAYA_ASKS)
		Beat.TALK, Beat.REPLY:
			if _beat_t >= LINE_TIME:
				_next_line()
		Beat.GAMES:
			_advance_round(delta)
		Beat.RESULT:
			_test_t += delta
	_update_screen()


func _target_saturation() -> float:
	match _beat:
		Beat.GAMES:
			return _r.saturation
		Beat.RESULT, Beat.DONE:
			return 0.6
	return 0.0


# --- The Injection: Maya asks, Leo answers, then the first shot.

func _start_lines(beat: Beat, lines: Array[String]) -> void:
	_beat = beat
	_beat_t = 0.0
	_lines = lines
	_line = 0


func _next_line() -> void:
	_line += 1
	_beat_t = 0.0
	if _line < _lines.size():
		return
	if _beat == Beat.TALK:
		_beat = Beat.CHOICE
	else:
		_start_games()


## Leo's one line: stoic or vulnerable. Either leads to the same shot.
func choose(answer: String) -> void:
	if _beat != Beat.CHOICE or _paused:
		return
	_answer = answer
	var lines: Array[String] = ["Leo: " + LEO_LINES[answer], MAYA_REPLIES[answer]]
	_start_lines(Beat.REPLY, lines)
	_update_screen()


# --- The six months of micro-games.

func _start_games() -> void:
	_beat = Beat.GAMES
	_beat_t = 0.0
	_round = -1
	_next_round()


func _next_round() -> void:
	_round += 1
	if _round >= NovicePlan.count():
		_start_result()
		return
	var phase_before: Variant = _r.get("phase")
	_r = NovicePlan.round_at(_round)
	if _r.phase != phase_before:
		_presses = 0
	_stage = Stage.GAP
	_stage_t = 0.0
	_won = false
	_pending.clear()
	_holding = false
	_press_dropped = false
	_taps = 0
	_level = 0.0
	_needle = 0.0
	_flinch = 0.0


func _advance_round(delta: float) -> void:
	_stage_t += delta
	_flinch = maxf(0.0, _flinch - delta)
	match _stage:
		Stage.GAP:
			if _stage_t >= _r.gap:
				_stage = Stage.PLAY
				_stage_t = 0.0
		Stage.PLAY:
			while not _pending.is_empty() and _pending[0][0] <= _t and _stage == Stage.PLAY:
				_land(_pending.pop_front()[1])
			if _stage != Stage.PLAY:
				return
			if _r.game == Game.POWDER and _holding:
				_level = minf(1.0, _level + _r.rise * delta)
			if _r.game == Game.INJECT:
				_needle = sin(_stage_t * _r.sway)
			if _stage_t >= _r.limit:
				_end_round(false)
		Stage.OUTRO:
			if _stage_t >= OUTRO_TIME:
				_next_round()


# A press or release reaching the game, after any lag.
func _land(pressed: bool) -> void:
	match _r.game:
		Game.BOX:
			if pressed:
				_taps += 1
				if _taps >= _r.box_taps:
					_end_round(true)
		Game.POWDER:
			if pressed:
				_holding = true
			elif _holding:
				_holding = false
				var band: Vector2 = _r.band
				if _level >= band.x and _level <= band.y:
					_end_round(true)
				else:
					_level = 0.0  # Spilled, or not mixed: start again.
					_flinch = FLINCH_TIME
		Game.INJECT:
			if pressed:
				if absf(_needle) <= _r.target:
					_end_round(true)
				else:
					_flinch = FLINCH_TIME


func _end_round(won: bool) -> void:
	_won = won
	_results.append("won" if won else "missed")
	_stage = Stage.OUTRO
	_stage_t = 0.0
	_pending.clear()
	_holding = false


# --- The positive test.

func _start_result() -> void:
	_beat = Beat.RESULT
	_beat_t = 0.0
	_test_t = 0.0


func _finish() -> void:
	if _finished_sent:
		return
	_finished_sent = true
	_beat = Beat.DONE
	finished.emit(_answer)


# --- Taps. One scheme: a tap, or a press and hold for the powder.

func _input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventScreenTouch:
		if event.index != 0:
			return
		pressed = event.pressed
	elif event is InputEventMouseButton:
		# Touches also arrive as emulated clicks; skip those so a tap isn't
		# counted twice.
		if event.button_index != MOUSE_BUTTON_LEFT or event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		pressed = event.pressed
	else:
		return
	if _paused:
		get_viewport().set_input_as_handled()
		if pressed:
			resume()
		return
	if _beat == Beat.CHOICE:
		return  # The two buttons take it.
	get_viewport().set_input_as_handled()
	if pressed:
		press()
	else:
		release()


## A finger down (or the mouse button), anywhere on the screen.
func press() -> void:
	if _paused:
		return
	match _beat:
		Beat.TALK, Beat.REPLY:
			if _beat_t >= LINE_MIN:
				_next_line()
		Beat.GAMES:
			if _stage != Stage.PLAY:
				return
			_presses += 1
			# The second press of the stretch is the first that doesn't take,
			# so it is felt straight away; then every drop_every-th after it.
			if _r.drop_every > 0 and _presses % _r.drop_every == 2 % _r.drop_every:
				_press_dropped = true  # Worn out: this one doesn't take.
				return
			_press_dropped = false
			_pending.append([_t + _r.lag, true])
			advance(0.0)
		Beat.RESULT:
			if _test_t >= TEST_HOLD:
				_finish()
	_update_screen()


## The finger coming up.
func release() -> void:
	if _paused or _beat != Beat.GAMES or _stage != Stage.PLAY:
		return
	if _press_dropped:
		_press_dropped = false
		return
	_pending.append([_t + _r.lag, false])
	advance(0.0)


# --- Pausing when the tab is hidden. Never saves.

## Stops the chapter's clock until the next tap. Any hold is let go.
func pause() -> void:
	if _beat == Beat.DONE:
		return
	_paused = true
	_holding = false
	_pending.clear()
	_update_screen()


## The tap after coming back; it isn't counted as a move.
func resume() -> void:
	_paused = false
	_update_screen()


func _notification(what: int) -> void:
	# Native builds; the web says so through visibilitychange (see _ready).
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED] \
			and not OS.has_feature("web"):
		pause()


func _on_visibility_change(_args: Array) -> void:
	if _document and _document.hidden:
		pause()


# --- What is on screen.

func _update_screen() -> void:
	var line := ""
	if _beat in [Beat.TALK, Beat.REPLY] and _line < _lines.size():
		line = _lines[_line]
	_subtitle.text = line
	_subtitle.visible = line != ""
	_choices.visible = _beat == Beat.CHOICE and not _paused
	var shouting := _beat == Beat.GAMES and _stage == Stage.PLAY
	_shout.visible = shouting
	if shouting:
		_shout.text = NovicePlan.SHOUTS[_r.game]
		_style_shout()
	_layout()
	queue_redraw()


# Quiet in the numb months, loud in the frantic ones, tired at the end.
func _style_shout() -> void:
	match _r.phase:
		Phase.NUMB:
			_shout.modulate = Color(0.8, 0.8, 0.8, 0.55)
			_shout.scale = Vector2.ONE * 0.7
		Phase.FRANTIC:
			_shout.modulate = LOUD[_round % LOUD.size()].lightened(0.2)
			_shout.scale = Vector2.ONE * 1.25
		Phase.EXHAUSTED:
			_shout.modulate = Color(0.85, 0.8, 0.75, 0.7)
			_shout.scale = Vector2.ONE * 0.85


# A colour as the picture shows it now: gray in the numb months, colour
# bleeding in as the months go frantic.
func _c(colour: Color) -> Color:
	var gray := colour.get_luminance()
	return Color(lerpf(gray, colour.r, _saturation), lerpf(gray, colour.g, _saturation),
			lerpf(gray, colour.b, _saturation), colour.a)


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var u := minf(w, h) * 0.12
	_draw_kitchen(w, h, u)
	var centre := Vector2(w * 0.5, h * 0.48)
	if _flinch > 0.0:
		centre.x += sin(_flinch * 60.0) * u * 0.08
	match _beat:
		Beat.GAMES:
			match _r.game:
				Game.BOX:
					_draw_box(centre, u)
				Game.POWDER:
					_draw_powder(centre, u)
				Game.INJECT:
					_draw_inject(centre, u)
		Beat.RESULT, Beat.DONE:
			_draw_test(centre, u, w, h)
	if _subtitle.visible:
		var r := _subtitle.get_rect().grow_individual(16.0, 8.0, 16.0, 8.0)
		draw_rect(r, Color("#1C1916CC"))
	if _paused:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.55))


func _draw_kitchen(w: float, h: float, u: float) -> void:
	draw_rect(Rect2(0.0, 0.0, w, h), _c(WALL).darkened(0.35))
	# The frantic months: loud rays behind everything.
	if _frenzy > 0.0:
		var middle := Vector2(w * 0.5, h * 0.48)
		var reach := maxf(w, h)
		for i in 16:
			var a := TAU * i / 16.0
			var b := TAU * (i + 0.5) / 16.0
			var colour := _c(LOUD[i % LOUD.size()])
			colour.a = 0.55 * _frenzy
			draw_colored_polygon(PackedVector2Array([middle,
					middle + Vector2.from_angle(a) * reach, middle + Vector2.from_angle(b) * reach]), colour)
	# The window, at night.
	var window := Rect2(w * 0.07, h * 0.1, w * 0.2, h * 0.32)
	draw_rect(window, _c(NIGHT))
	draw_circle(window.position + window.size * Vector2(0.7, 0.3), u * 0.25, _c(MOON))
	draw_rect(window, _c(PAPER).darkened(0.5), false, 6.0)
	# The fridge, and the counter along the bottom.
	draw_rect(Rect2(w * 0.82, h * 0.18, w * 0.13, h * 0.6), _c(FRIDGE).darkened(0.25))
	draw_line(Vector2(w * 0.82, h * 0.4), Vector2(w * 0.95, h * 0.4), _c(INK), 3.0)
	draw_rect(Rect2(0.0, h * 0.78, w, h * 0.22), _c(COUNTER).darkened(0.2))
	# The calendar: just the month's number.
	if _beat == Beat.GAMES:
		var page := Rect2(w * 0.68, h * 0.08, u * 1.1, u * 1.2)
		draw_rect(page, _c(PAPER).darkened(0.1))
		draw_rect(Rect2(page.position, Vector2(page.size.x, page.size.y * 0.22)), _c(TARGET).darkened(0.1))
		var font := get_theme_default_font()
		var digits := str(_r.month)
		var font_size := int(u * 0.7)
		var text_w := font.get_string_size(digits, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, Vector2(page.position.x + (page.size.x - text_w) / 2.0,
				page.position.y + page.size.y * 0.85), digits, HORIZONTAL_ALIGNMENT_LEFT, -1,
				font_size, _c(INK))


func _draw_box(centre: Vector2, u: float) -> void:
	var body := Rect2(centre - Vector2(u * 1.3, u * 0.5), Vector2(u * 2.6, u * 1.6))
	draw_rect(body, _c(CARDBOARD))
	draw_rect(body, _c(CARDBOARD_DARK), false, 4.0)
	var open := 1.0 if _won else float(_taps) / float(_r.box_taps)
	if _won:
		# The vials inside.
		for i in 4:
			var x := body.position.x + u * (0.45 + i * 0.55)
			draw_rect(Rect2(x, body.position.y - u * 0.35, u * 0.3, u * 0.7), _c(LOUD[i % LOUD.size()]))
	var hinge := body.position
	draw_set_transform(hinge, -open * 1.9)
	draw_rect(Rect2(0.0, -u * 0.25, body.size.x, u * 0.25), _c(CARDBOARD_DARK))
	draw_set_transform(Vector2.ZERO)


func _draw_powder(centre: Vector2, u: float) -> void:
	var vial := Rect2(centre - Vector2(u * 0.45, u * 1.4), Vector2(u * 0.9, u * 2.6))
	draw_rect(vial, _c(PAPER).darkened(0.6))
	var level := 1.0 if _won and _level <= 0.0 else _level
	var fill_h := vial.size.y * level
	draw_rect(Rect2(vial.position.x, vial.end.y - fill_h, vial.size.x, fill_h), _c(MIX))
	var band: Vector2 = _r.band
	for edge in [band.x, band.y]:
		var y: float = vial.end.y - vial.size.y * edge
		draw_line(Vector2(vial.position.x - u * 0.25, y), Vector2(vial.end.x + u * 0.25, y), _c(BAND), 5.0)
	draw_rect(vial, _c(STEEL), false, 5.0)
	draw_rect(Rect2(vial.position + Vector2(-u * 0.1, -u * 0.3), Vector2(vial.size.x + u * 0.2, u * 0.3)),
			_c(TARGET).darkened(0.2))
	if _holding:
		# The swirl while it mixes.
		var swirl := Vector2(vial.get_center().x, vial.end.y - fill_h * 0.5)
		draw_arc(swirl, u * 0.25, _t * 8.0, _t * 8.0 + PI, 16, _c(PAPER), 3.0)
	if _level >= 1.0:
		draw_circle(Vector2(vial.end.x + u * 0.2, vial.position.y + u * 0.1), u * 0.12, _c(MIX))


func _draw_inject(centre: Vector2, u: float) -> void:
	var low := centre + Vector2(0.0, u * 0.7)
	draw_circle(low + Vector2(-u * 0.8, 0.0), u * 1.0, _c(SKIN))
	draw_circle(low + Vector2(u * 0.8, 0.0), u * 1.0, _c(SKIN))
	draw_line(low + Vector2(0.0, -u * 0.6), low + Vector2(0.0, u * 0.9), _c(SKIN_DARK), 4.0)
	var target := low + Vector2(-u * 0.9, -u * 0.35)
	var half := u * 1.6  # The sway's half-width.
	draw_arc(target, maxf(half * _r.target, u * 0.12), 0.0, TAU, 32, _c(TARGET), 4.0)
	var x := target.x + (0.0 if _won else _needle * half)
	var tip_y := target.y if _won else target.y - u * 0.5
	draw_line(Vector2(x, tip_y - u * 0.5), Vector2(x, tip_y), _c(STEEL), 3.0)
	draw_rect(Rect2(x - u * 0.16, tip_y - u * 1.5, u * 0.32, u * 1.0), _c(PAPER))
	draw_rect(Rect2(x - u * 0.16, tip_y - u * 1.1, u * 0.32, u * 0.6), _c(MIX))
	draw_rect(Rect2(x - u * 0.3, tip_y - u * 1.65, u * 0.6, u * 0.15), _c(STEEL))


func _draw_test(centre: Vector2, u: float, w: float, h: float) -> void:
	var stick := Rect2(centre - Vector2(u * 2.2, u * 0.35), Vector2(u * 4.4, u * 0.7))
	draw_rect(stick, _c(PAPER))
	draw_rect(Rect2(stick.position, Vector2(u * 1.2, stick.size.y)), _c(LOUD[3]).lightened(0.3))
	var window := Rect2(stick.position + Vector2(u * 2.0, u * 0.15), Vector2(u * 1.3, u * 0.4))
	draw_rect(window, _c(PAPER).darkened(0.12))
	var line_x := window.position.x + window.size.x * 0.3
	draw_line(Vector2(line_x, window.position.y), Vector2(line_x, window.end.y), _c(TEST_LINE), 5.0)
	# The second line comes through.
	var second := _c(TEST_LINE)
	second.a = clampf(_test_t / TEST_LINE_TIME, 0.0, 1.0)
	line_x = window.position.x + window.size.x * 0.7
	draw_line(Vector2(line_x, window.position.y), Vector2(line_x, window.end.y), second, 5.0)
	if _test_t >= TEST_HOLD:
		# A quiet ring: the player can go back when ready.
		var ring := _c(PAPER)
		ring.a = 0.4 + 0.2 * sin((_test_t - TEST_HOLD) * TAU / 3.0)
		draw_arc(Vector2(w / 2.0, h - 56.0), 22.0, 0.0, TAU, 64, ring, 2.5, true)


# --- For tests, the browser probe and the playtest overlay.

## Seconds into the chapter, for the playtest overlay's clock.
func playtest_time() -> float:
	return _t


func probe_state() -> Dictionary:
	return {
		"beat": Beat.keys()[_beat],
		"round": _round,
		"game": Game.keys()[_r.game] if _beat == Beat.GAMES else "",
		"phase": Phase.keys()[_r.phase] if _beat == Beat.GAMES else "",
		"stage": Stage.keys()[_stage] if _beat == Beat.GAMES else "",
		"month": _r.get("month", 0) if _beat == Beat.GAMES else 0,
		"shout": _shout.text if _shout.visible else "",
		"subtitle": _subtitle.text if _subtitle.visible else "",
		"saturation": _saturation,
		"paused": _paused,
		"results": _results.duplicate(),
		"answer": _answer,
		"canGoBack": _beat == Beat.RESULT and _test_t >= TEST_HOLD,
		"time": _t,
	}
