extends CanvasLayer
## The "Turn your phone sideways" screen (scope.md, 2026-10-19: the game is
## sideways on every screen). Autoloaded as TurnSideways. It is off until the
## game starts (title.gd calls watch()), so the M0 test menu and its checks
## still open on an upright phone.
##
## While a phone is held upright it covers everything and pauses the game:
## the House stops where it is, and a chapter that is playing pauses as it
## does when the tab is hidden (ChapterRunner.pause_chapter()). Turning the
## phone back takes the screen away and the game carries on from there; a
## paused chapter waits for a tap, as it does after a hidden tab.

const SURFACE := Color(0.11, 0.098, 0.086)

## Whether this is a phone or tablet. Left null it asks the device (a touch
## screen); tests set it.
var assume_touch: Variant = null

var _watching := false
var _cover: Control
# Whether this screen paused the game, so it only unpauses its own pause.
var _paused_it := false


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cover = Control.new()
	_cover.name = "Cover"
	_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Every tap stops here while it shows.
	_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	var background := ColorRect.new()
	background.color = SURFACE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cover.add_child(background)
	var words := Label.new()
	words.name = "Words"
	words.text = "Turn your phone sideways"
	words.theme_type_variation = &"LabelReader"
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.set_anchors_preset(Control.PRESET_FULL_RECT)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cover.add_child(words)
	add_child(_cover)
	_cover.hide()
	get_viewport().size_changed.connect(_check)


## Starts showing the screen whenever the phone is upright.
func watch() -> void:
	_watching = true
	_check()


## Stops watching and takes the screen away (tests, and the test menu).
func stop_watching() -> void:
	_watching = false
	_check()


func is_showing() -> bool:
	return _cover.visible


func _check() -> void:
	var size := get_viewport().get_visible_rect().size
	var upright := _watching and size.y > size.x and _is_touch()
	if upright == _cover.visible:
		return
	_cover.visible = upright
	if upright:
		if not get_tree().paused:
			get_tree().paused = true
			_paused_it = true
		ChapterRunner.of(get_tree()).pause_chapter()
	elif _paused_it:
		get_tree().paused = false
		_paused_it = false


func _is_touch() -> bool:
	if assume_touch != null:
		return assume_touch
	return DisplayServer.is_touchscreen_available()
