extends Control
## The opening beat (DAS-95): the first time the player reaches the living
## room's doorway view (L1), Maya talks from the next room, as subtitles;
## nobody is on screen. Leo's one line is the player's choice: closed-off
## (Stoic) or open (Vulnerable). Only that line and Maya's reply differ. The
## words are Dan's approved ones, docs/design/m1-words-draft.md section 1,
## used exactly.
##
## The House shows it over the view, and the player can still tap rings while
## it plays (EXPERIENCE.md, The Story Sequence). It emits `finished` with the
## answer once the last line has gone; the House then opens the hall.

signal finished(answer: String)

const MAYA := "Maya"
const LEO := "Leo"
## Lines 1 and 2, before Leo's.
const OPENING_LINES: Array[String] = [
	"Did you lock the front door?",
	"Leo… are we really doing this? The house. All of it.",
]
## Line 3: what Leo says, by answer.
const LEO_LINES := {
	"stoic": "We're doing it. I've got a plan.",
	"vulnerable": "Honestly? I'm a little scared. The good kind.",
}
## Line 4: Maya's reply to it.
const REPLIES := {
	"stoic": "Of course you do.",
	"vulnerable": "Me too. The good kind.",
}
## Line 5, the same for everyone.
const LAST_LINE := "Now please move your boxes out of the hall. I want to put a record on."

## A quiet moment on arrival before Maya speaks, and between lines.
const LEAD_IN := 1.0
const GAP := 0.5
## How long a line stays: long enough to read (EXPERIENCE.md, subtitle-bar).
const BASE_HOLD := 1.6
const HOLD_PER_CHARACTER := 0.055

const SUBTITLE_BG := Color(0.11, 0.098, 0.086, 0.8)

# Each step: {"who", "text"}; a choice is {"choice": true}.
var _steps: Array[Dictionary] = []
var _index := -1
var _clock := 0.0
var _answer := ""
var _done := false
var _bar: PanelContainer
var _who: Label
var _line: Label
var _choices: HBoxContainer
var _choice_buttons := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Taps go through to the rings, except on the choice.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	for text in OPENING_LINES:
		_steps.append({"who": MAYA, "text": text})
	_steps.append({"choice": true})
	_clock = -LEAD_IN
	_show_step()


## Moves the beat on by `delta` seconds. The House's clock: it stops while the
## game is paused. A choice waits for the player however long it takes.
func step(delta: float) -> void:
	if _done or is_choosing():
		return
	_clock += delta
	if _clock < 0.0:
		return
	if _index < 0:
		_next()
		return
	if _clock >= hold_for(_steps[_index].text) + GAP:
		_next()


func _process(delta: float) -> void:
	step(delta)


## Seconds a line stays up.
static func hold_for(text: String) -> float:
	return BASE_HOLD + HOLD_PER_CHARACTER * text.length()


## Leo's line: "stoic" (closed-off) or "vulnerable" (open).
func choose(answer: String) -> void:
	if not is_choosing() or not answer in LEO_LINES:
		return
	_answer = answer
	_steps.append({"who": LEO, "text": LEO_LINES[answer]})
	_steps.append({"who": MAYA, "text": REPLIES[answer]})
	_steps.append({"who": MAYA, "text": LAST_LINE})
	_next()


func is_choosing() -> bool:
	return _index >= 0 and _index < _steps.size() and _steps[_index].has("choice")


func is_done() -> bool:
	return _done


## The line showing now, or "" between lines.
func current_line() -> String:
	return _line.text if _bar.visible else ""


## Who is speaking now, or "" between lines.
func current_speaker() -> String:
	return _who.text if _bar.visible else ""


## The choice's buttons, by answer.
func choice_button(answer: String) -> Button:
	return _choice_buttons.get(answer)


## For the browser tests, through the House's probe_state().
func probe_state() -> Dictionary:
	return {"who": current_speaker(), "line": current_line(), "choosing": is_choosing(), "done": _done}


func _next() -> void:
	_index += 1
	_clock = 0.0
	if _index >= _steps.size():
		_done = true
		_show_step()
		finished.emit(_answer)
		return
	_show_step()


func _show_step() -> void:
	var line: Dictionary = _steps[_index] if _index >= 0 and _index < _steps.size() else {}
	_bar.visible = line.has("text")
	_choices.visible = line.has("choice")
	if line.has("text"):
		_who.text = line.who
		_line.text = line.text


# The subtitle bar along the bottom (DESIGN.md subtitle-bar), and the choice
# just above it: Leo's two lines, as equal quiet buttons. Nothing says it is
# a choice or what it means.
func _build() -> void:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.anchor_left = 0.1
	column.anchor_right = 0.9
	column.anchor_top = 1.0
	column.anchor_bottom = 1.0
	column.offset_bottom = -32.0
	column.offset_top = -32.0
	column.grow_vertical = Control.GROW_DIRECTION_BEGIN
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 16)
	add_child(column)

	_choices = HBoxContainer.new()
	_choices.name = "Choice"
	_choices.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choices.alignment = BoxContainer.ALIGNMENT_CENTER
	_choices.add_theme_constant_override("separation", 24)
	column.add_child(_choices)
	for answer: String in ["stoic", "vulnerable"]:
		var button := Button.new()
		button.name = "Choice_%s" % answer
		button.text = LEO_LINES[answer]
		button.theme_type_variation = &"ButtonQuiet"
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0.0, 96.0)
		button.pressed.connect(choose.bind(answer))
		_choices.add_child(button)
		_choice_buttons[answer] = button

	_bar = PanelContainer.new()
	_bar.name = "SubtitleBar"
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scrim := StyleBoxFlat.new()
	scrim.bg_color = SUBTITLE_BG
	scrim.set_corner_radius_all(12)
	scrim.set_content_margin_all(18.0)
	_bar.add_theme_stylebox_override("panel", scrim)
	column.add_child(_bar)
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_theme_constant_override("separation", 2)
	_bar.add_child(words)
	_who = Label.new()
	_who.theme_type_variation = &"LabelMuted"
	_who.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.add_child(_who)
	_line = Label.new()
	_line.name = "Line"
	_line.theme_type_variation = &"LabelSubtitle"
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(_line)
