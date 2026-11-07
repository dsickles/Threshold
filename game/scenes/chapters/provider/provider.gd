extends Control
## The Provider (the Cost), rough M2 playable (DAS-134): a desk of bills in
## three acts, a large-type reader, APPROVE and DENY stamps, and the Due Date
## and Bank Account in the top-start corner. Design:
## docs/design/story-beats.md §4 (Dan, 2026-10-25) and
## docs/design/stories/epic-4-stories.md (reference).
##
## The chapter has one ending: the bills are done, or the Due Date runs out.
## Either way it reports `finished` once, with no answer, and never touches
## the House or saved state (the chapter runner and the core table do that).
## Leaving part-way gives no result, so the next visit starts from the first
## bill. Hiding the tab pauses the Due Date and the drain; it never saves.
##
## PLACEHOLDER look: plain high-contrast black and white boxes. No score yet
## (the synthwave track is a follow-up); the ink thunk is a generated
## placeholder (tools/provider/make_placeholder_audio.py).

signal finished

const Bills := preload("res://scenes/chapters/provider/bills.gd")
const THUNK := preload("res://assets/audio/provider/placeholder_thunk.wav")

## The Due Date, in days, and how long a day lasts.
const DUE_DAYS := 30
const SECONDS_PER_DAY := 6.0
const DUE_SECONDS := DUE_DAYS * SECONDS_PER_DAY
## The Bank Account, and how fast it drains (faster in the Audit).
const BANK_START := 9000.0
const DRAIN_PER_SECOND := 10.0
const AUDIT_DRAIN_PER_SECOND := 25.0
## How long a stamped bill stays on the desk before the next one comes.
const STAMPED_HOLD := 1.0
## How long "can't enlarge this page." stays up.
const CANT_ENLARGE_TIME := 2.5
## How long the "-$400" by the Bank Account stays up.
const DROP_TIME := 2.0
## After the last bill (or the Due Date), a beat, then the fade to black.
const END_HOLD := 1.5
const FADE_TIME := 1.5

## How big the bill's text is on the desk, per act. The Insurance is hard to
## read on the desk on purpose: the large-type page is how it is read.
const DESK_TEXT_SIZE := {
	Bills.Act.INVOICES: 26,
	Bills.Act.INSURANCE: 13,
	Bills.Act.AUDIT: 20,
}
const DESK_TITLE_SIZE := 30
const READER_TEXT_SIZE := 40
const CANT_ENLARGE := "can't enlarge this page."

const INK := Color(0.0, 0.0, 0.0)
const PAPER := Color(1.0, 1.0, 1.0)
const FAX := Color(0.82, 0.82, 0.82)

## Tests step the clock themselves (advance) instead of real time.
var auto_advance := true

var _t := 0.0  # Seconds since the desk opened.
var _due_left := DUE_SECONDS
var _bank := BANK_START
var _bill := 0
var _stamp := ""  # The stamp on the current bill, or "" if none yet.
var _stamped_for := 0.0
var _reading := false
var _paused := false
var _ending := false
var _end_for := 0.0
var _done := false
var _cant_enlarge_for := 0.0
var _drop_for := 0.0
var _thunks := 0
var _wrong := 0

var _paper: Button
var _paper_title: Label
var _paper_text: Label
var _mark: Label
var _cant_enlarge: Label
var _act_title: Label
var _reader: PanelContainer
var _reader_text: Label
var _reader_back: Button
var _approve: Button
var _deny: Button
var _due_number: Label
var _due_fill: ColorRect
var _bank_number: Label
var _bank_fill: ColorRect
var _bank_drop: Label
var _fade: ColorRect
var _thunk: AudioStreamPlayer
var _document: JavaScriptObject
var _visibility_callback: JavaScriptObject


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_build()
	_thunk = AudioStreamPlayer.new()
	_thunk.stream = THUNK
	add_child(_thunk)
	if OS.has_feature("web"):
		# Godot doesn't say when the tab is hidden on the web.
		_document = JavaScriptBridge.get_interface("document")
		_visibility_callback = JavaScriptBridge.create_callback(_on_visibility_change)
		_document.addEventListener("visibilitychange", _visibility_callback)
	_show_bill()
	_update_hud()


func _exit_tree() -> void:
	if _document:
		_document.removeEventListener("visibilitychange", _visibility_callback)
		_document = null


func _process(delta: float) -> void:
	if auto_advance:
		advance(delta)


## Moves the desk's clock on by `delta` seconds. Nothing moves while paused.
func advance(delta: float) -> void:
	if _paused or _done:
		return
	_t += delta
	if _cant_enlarge_for > 0.0:
		_cant_enlarge_for -= delta
		_cant_enlarge.visible = _cant_enlarge_for > 0.0
	if _drop_for > 0.0:
		_drop_for -= delta
		_bank_drop.visible = _drop_for > 0.0
	if _ending:
		_end_for += delta
		_fade.color.a = clampf((_end_for - END_HOLD) / FADE_TIME, 0.0, 1.0)
		if _end_for >= END_HOLD + FADE_TIME:
			_done = true
			finished.emit()
		return
	if not is_quiet():
		_due_left = maxf(0.0, _due_left - delta)
		_bank = maxf(0.0, _bank - drain_rate() * delta)
	_update_hud()
	if _stamp != "":
		_stamped_for += delta
		if _stamped_for >= STAMPED_HOLD:
			_next_bill()
	if not _ending and _due_left <= 0.0:
		_end()


# --- What the player does.

## Tapping the paper: large type if it can reflow, else the desk stays and
## says it can't.
func open_reader() -> void:
	if _ending or _stamp != "":
		return
	if not current().reflows:
		_cant_enlarge.visible = true
		_cant_enlarge_for = CANT_ENLARGE_TIME
		return
	_reader_text.text = reflowed(current())
	_reading = true
	_reader.visible = true
	_paper.visible = false


func close_reader() -> void:
	_reading = false
	_reader.visible = false
	_paper.visible = not _ending


## One tap on a stamp marks the paper with its word.
func stamp(which: String) -> void:
	if _ending or _stamp != "" or _paused:
		return
	_stamp = which
	_stamped_for = 0.0
	close_reader()
	_mark.text = "APPROVED" if which == Bills.APPROVE else "DENIED"
	_mark.visible = true
	_thunk.play()
	_thunks += 1
	if not Bills.is_right(_bill, which):
		_wrong += 1
		var cost: float = current().cost
		_bank = maxf(0.0, _bank - cost)
		_bank_drop.text = "-$%s" % _money(cost)
		_bank_drop.visible = true
		_drop_for = DROP_TIME
	_approve.disabled = true
	_deny.disabled = true
	_update_hud()


func pause() -> void:
	_paused = true


func resume() -> void:
	_paused = false


func _notification(what: int) -> void:
	# Native builds; the web says so through visibilitychange (see _ready).
	if OS.has_feature("web"):
		return
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		pause()
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED]:
		resume()


func _on_visibility_change(_args: Array) -> void:
	if _document == null:
		return
	if _document.hidden:
		pause()
	else:
		resume()


# --- The flow of bills.

func current() -> Dictionary:
	return Bills.BILLS[_bill]


## While the bill for the night of the Loss is on the desk, the Due Date
## doesn't count and nothing drains.
func is_quiet() -> bool:
	return not _ending and current().quiet


func drain_rate() -> float:
	return AUDIT_DRAIN_PER_SECOND if current().act == Bills.Act.AUDIT else DRAIN_PER_SECOND


func _next_bill() -> void:
	if _bill + 1 >= Bills.BILLS.size():
		_end()
		return
	_bill += 1
	_show_bill()


func _show_bill() -> void:
	var bill := current()
	_stamp = ""
	_stamped_for = 0.0
	_mark.visible = false
	_approve.disabled = false
	_deny.disabled = false
	_cant_enlarge.visible = false
	_cant_enlarge_for = 0.0
	_act_title.text = Bills.ACT_NAMES[bill.act]
	_paper_title.text = bill.title
	_paper_text.text = "\n".join(bill.lines)
	_paper_text.add_theme_font_size_override("font_size", DESK_TEXT_SIZE[bill.act])
	var style := _paper.get_theme_stylebox("normal") as StyleBoxFlat
	style.bg_color = PAPER if bill.reflows else FAX


# The bill as the large-type page shows it: the dotted leaders go, so each
# line wraps to the page instead of running off it.
static func reflowed(bill: Dictionary) -> String:
	var lines: Array[String] = [bill.title, ""]
	var leaders := RegEx.create_from_string("\\s*\\.{2,}\\s*")
	for line: String in bill.lines:
		lines.append(leaders.sub(line, ": ", true))
	return "\n".join(lines)


func _end() -> void:
	if _ending:
		return
	_ending = true
	_end_for = 0.0
	close_reader()
	_approve.disabled = true
	_deny.disabled = true
	_paper.disabled = true


func _update_hud() -> void:
	# A hair under a whole day counts as that day, so stepping in small bits
	# of time doesn't leave the number a day behind.
	_due_number.text = "%d days" % ceili(_due_left / SECONDS_PER_DAY - 0.0001)
	_due_fill.anchor_right = _due_left / DUE_SECONDS
	_bank_number.text = "$%s" % _money(_bank)
	_bank_fill.anchor_right = _bank / BANK_START


static func _money(amount: float) -> String:
	var whole := str(roundi(amount))
	var out := ""
	while whole.length() > 3:
		out = "," + whole.right(3) + out
		whole = whole.left(whole.length() - 3)
	return whole + out


# --- For tests, the browser probe and the playtest overlay.

func bill_index() -> int:
	return _bill


func act() -> int:
	return current().act


func due_left() -> float:
	return _due_left


func bank() -> float:
	return _bank


func is_reading() -> bool:
	return _reading


func is_paused() -> bool:
	return _paused


func is_ending() -> bool:
	return _ending


func thunks() -> int:
	return _thunks


## Seconds since the desk opened, for the playtest overlay's clock.
func playtest_time() -> float:
	return _t


func probe_state() -> Dictionary:
	var paper := _paper.get_global_rect()
	return {
		"time": _t,
		"bill": _bill,
		"act": Bills.ACT_NAMES[act()],
		"due": _due_number.text,
		"bank": _bank_number.text,
		"reading": _reading,
		"stamp": _stamp,
		"mark": _mark.text if _mark.visible else "",
		"cantEnlarge": _cant_enlarge.visible,
		"paused": _paused,
		"ending": _ending,
		"paper": {"x": paper.get_center().x, "y": paper.get_center().y, "visible": _paper.is_visible_in_tree()},
	}


# --- Building the desk.

func _build() -> void:
	var desk := ColorRect.new()
	desk.name = "Desk"
	desk.color = INK
	desk.set_anchors_preset(PRESET_FULL_RECT)
	desk.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(desk)
	_build_hud()
	_build_paper()
	_build_reader()
	_build_stamps()
	_act_title = _label("ActTitle", 32, PAPER)
	_act_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_act_title, 0.5, 0.0, -280, 16, 280, 70)
	_fade = ColorRect.new()
	_fade.name = "Fade"
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(PRESET_FULL_RECT)
	_fade.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_fade)


# Due Date and Bank Account, top-start corner. Each is a number and a track,
# so a drop shows in both, never by colour alone.
func _build_hud() -> void:
	var hud := VBoxContainer.new()
	hud.name = "Hud"
	hud.add_theme_constant_override("separation", 4)
	hud.mouse_filter = MOUSE_FILTER_IGNORE
	_place(hud, 0.0, 0.0, 24, 20, 324, 260)
	hud.add_child(_label("DueLabel", 22, PAPER, "DUE DATE"))
	_due_number = _label("DueNumber", 34, PAPER)
	hud.add_child(_due_number)
	_due_fill = _track(hud, "DueTrack")
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	hud.add_child(spacer)
	hud.add_child(_label("BankLabel", 22, PAPER, "BANK ACCOUNT"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	hud.add_child(row)
	_bank_number = _label("BankNumber", 34, PAPER)
	row.add_child(_bank_number)
	_bank_drop = _label("BankDrop", 34, PAPER)
	_bank_drop.visible = false
	row.add_child(_bank_drop)
	_bank_fill = _track(hud, "BankTrack")


func _track(parent: Control, track_name: String) -> ColorRect:
	var track := Panel.new()
	track.name = track_name
	track.custom_minimum_size = Vector2(280, 18)
	track.mouse_filter = MOUSE_FILTER_IGNORE
	var outline := StyleBoxFlat.new()
	outline.bg_color = INK
	outline.border_color = PAPER
	outline.set_border_width_all(2)
	track.add_theme_stylebox_override("panel", outline)
	parent.add_child(track)
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.color = PAPER
	fill.mouse_filter = MOUSE_FILTER_IGNORE
	fill.anchor_bottom = 1.0
	fill.anchor_right = 1.0
	track.add_child(fill)
	return fill


func _build_paper() -> void:
	_paper = Button.new()
	_paper.name = "Paper"
	_paper.focus_mode = FOCUS_NONE
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.set_content_margin_all(28)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		_paper.add_theme_stylebox_override(state, style)
	_place(_paper, 0.5, 0.5, -300, -280, 260, 300)
	_paper.pressed.connect(open_reader)
	var column := VBoxContainer.new()
	column.set_anchors_preset(PRESET_FULL_RECT)
	column.offset_left = 28
	column.offset_top = 28
	column.offset_right = -28
	column.offset_bottom = -28
	column.add_theme_constant_override("separation", 18)
	column.mouse_filter = MOUSE_FILTER_IGNORE
	_paper.add_child(column)
	_paper_title = _label("PaperTitle", DESK_TITLE_SIZE, INK)
	_paper_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_paper_title)
	_paper_text = _label("PaperText", 20, INK)
	_paper_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_paper_text)
	_mark = _label("Mark", 64, INK)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0)
	box.border_color = INK
	box.set_border_width_all(8)
	box.set_content_margin_all(12)
	_mark.add_theme_stylebox_override("normal", box)
	_mark.rotation_degrees = -12.0
	_mark.position = Vector2(110, 330)
	_mark.visible = false
	_paper.add_child(_mark)
	_cant_enlarge = _label("CantEnlarge", 29, PAPER, CANT_ENLARGE)
	_cant_enlarge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cant_enlarge.visible = false
	_place(_cant_enlarge, 0.5, 1.0, -300, -66, 260, -16)


# The large-type page: it replaces the paper, and leaves the Due Date, the
# Bank Account and the stamps where they are.
func _build_reader() -> void:
	_reader = PanelContainer.new()
	_reader.name = "Reader"
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.set_content_margin_all(24)
	_reader.add_theme_stylebox_override("panel", style)
	_place(_reader, 0.5, 0.0, -300, 16, 260, 0)
	_reader.anchor_bottom = 1.0
	_reader.offset_bottom = -16
	_reader.visible = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	_reader.add_child(column)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_reader_text = _label("ReaderText", READER_TEXT_SIZE, INK)
	_reader_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reader_text.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(_reader_text)
	_reader_back = _ink_button("ReaderBack", "Back to desk", 32, true)
	_reader_back.pressed.connect(close_reader)
	column.add_child(_reader_back)


func _build_stamps() -> void:
	var column := VBoxContainer.new()
	column.name = "Stamps"
	column.add_theme_constant_override("separation", 36)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	_place(column, 1.0, 0.5, -300, -150, -24, 150)
	_approve = _ink_button("ApproveStamp", "APPROVE", 44, false)
	_approve.custom_minimum_size = Vector2(260, 120)
	_approve.pressed.connect(stamp.bind(Bills.APPROVE))
	column.add_child(_approve)
	_deny = _ink_button("DenyStamp", "DENY", 44, false)
	_deny.custom_minimum_size = Vector2(260, 120)
	_deny.pressed.connect(stamp.bind(Bills.DENY))
	column.add_child(_deny)


# A black-and-white button. Its outline is always drawn, so what can be
# stamped is clear on every quality setting.
func _ink_button(button_name: String, text: String, size: int, on_paper: bool) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.focus_mode = FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 88)
	button.add_theme_font_size_override("font_size", size)
	var ground := PAPER if on_paper else INK
	var ink := INK if on_paper else PAPER
	var normal := StyleBoxFlat.new()
	normal.bg_color = ground
	normal.border_color = ink
	normal.set_border_width_all(5)
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(16)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = ink
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.border_color = Color(ink, 0.45)
	for state in ["normal", "hover"]:
		button.add_theme_stylebox_override(state, normal)
	for state in ["pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	for colour in ["font_color", "font_hover_color", "font_focus_color"]:
		button.add_theme_color_override(colour, ink)
	for colour in ["font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(colour, ground)
	button.add_theme_color_override("font_disabled_color", Color(ink, 0.45))
	return button


func _label(label_name: String, size: int, colour: Color, text := "") -> Label:
	var label := Label.new()
	label.name = label_name
	label.text = text
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label


# Anchors a control at (ax, ay) of the screen with the given offsets, and
# adds it to the desk.
func _place(control: Control, ax: float, ay: float, left: float, top: float,
		right: float, bottom: float) -> void:
	control.anchor_left = ax
	control.anchor_right = ax
	control.anchor_top = ay
	control.anchor_bottom = ay
	control.offset_left = left
	control.offset_top = top
	control.offset_right = right
	control.offset_bottom = bottom
	add_child(control)
