class_name ChapterPause
extends CanvasLayer
## The pause button over every chapter, and the panel it opens (DAS-130).
## The chapter runner makes one for each chapter it starts and frees it when
## the chapter closes; a chapter never makes its own. How pausing works for
## a chapter: game/_core/chapters/README.md, "Pausing".
##
## The button sits in the top-right corner (the playtest overlay has the
## top-left). Tapping it asks the runner to pause; the panel then covers the
## chapter with a dim scrim and one Resume button, until that is tapped.
## Settings and Back to title join this panel in M2 (docs/roadmap.md).
## There is no way to leave the chapter from here: leaving the Loss part-way
## and starting again from the lamp would be a retry.

## The pause button was tapped.
signal pause_tapped
## Resume was tapped (or Enter pressed while the panel is up).
signal resume_tapped

## Above the chapters' own layers, below the playtest overlay (100).
const LAYER := 90
## The smallest tap target: 44 on a sideways phone is 79 on the 720-tall
## layout (game/assets/ui/README.md).
const BUTTON_SIZE := 79.0
const MARGIN := 16.0
const SCRIM := Color(0.0, 0.0, 0.0, 0.6)
const BAR_COLOR := Color("#F4EFE6")  # DESIGN.md ink.

var _button: Button
var _scrim: ColorRect
var _panel: PanelContainer
var _resume: Button
var _button_shown := true


func _init() -> void:
	layer = LAYER
	name = "ChapterPause"
	_button = Button.new()
	_button.name = "PauseButton"
	_button.theme_type_variation = &"ButtonQuiet"
	_button.focus_mode = Control.FOCUS_NONE  # Taps only; Enter is for Resume.
	# Taps reach it through _input, before the chapter can take them.
	_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_button.offset_left = -MARGIN - BUTTON_SIZE
	_button.offset_right = -MARGIN
	_button.offset_top = MARGIN
	_button.offset_bottom = MARGIN + BUTTON_SIZE
	_button.draw.connect(_draw_bars)
	add_child(_button)

	_scrim = ColorRect.new()
	_scrim.name = "Scrim"
	_scrim.color = SCRIM
	_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP  # Taps off the panel do nothing.
	_scrim.visible = false
	add_child(_scrim)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scrim.add_child(centre)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	centre.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 29)
	_panel.add_child(column)
	var title := Label.new()
	title.name = "Title"
	title.text = "Paused"
	title.theme_type_variation = &"LabelSubtitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_resume = Button.new()
	_resume.name = "ResumeButton"
	_resume.text = "Resume"
	_resume.theme_type_variation = &"ButtonPrimary"
	_resume.custom_minimum_size = Vector2(BUTTON_SIZE * 3.0, BUTTON_SIZE)
	_resume.pressed.connect(resume_tapped.emit)
	column.add_child(_resume)


func pause_button() -> Button:
	return _button


func resume_button() -> Button:
	return _resume


## A chapter can go without the button (its shows_pause_button() returns
## false). It can still be paused through the runner.
func show_button(on: bool) -> void:
	_button_shown = on
	_button.visible = on and not is_open()


func is_open() -> bool:
	return _scrim.visible


## Shows the panel over the chapter, with Resume focused.
func open() -> void:
	_scrim.visible = true
	_button.visible = false
	_resume.grab_focus()


func close() -> void:
	_scrim.visible = false
	_button.visible = _button_shown
	_resume.release_focus()


# The chapter hears taps in its own _input, which runs before any button
# does, so the pause button is checked here. The runner adds this layer after
# the chapter, and _input runs last-added first, so this sees the tap first.
# Once the panel is up the chapter is paused and hears nothing, and the
# panel's own buttons work as usual.
func _input(event: InputEvent) -> void:
	if is_open() or not _button.visible:
		return
	# Only the press: a hold that started elsewhere still lifts in the chapter.
	if not (event is InputEventScreenTouch or event is InputEventMouseButton) \
			or not event.pressed:
		return
	if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not _button.get_global_rect().has_point(event.position):
		return
	get_viewport().set_input_as_handled()
	pause_tapped.emit()


# Two bars, the usual pause sign, so it needs no words.
func _draw_bars() -> void:
	var size := _button.size
	var bar := Vector2(size.x * 0.13, size.y * 0.42)
	var gap := size.x * 0.12
	var top := (size.y - bar.y) / 2.0
	var left := (size.x - bar.x * 2.0 - gap) / 2.0
	_button.draw_rect(Rect2(Vector2(left, top), bar), BAR_COLOR)
	_button.draw_rect(Rect2(Vector2(left + bar.x + gap, top), bar), BAR_COLOR)
