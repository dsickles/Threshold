extends CanvasLayer
## A small frame-rate counter and clock in the top-left corner, for Dan's
## playtests while the chapters are rough: so he can say when a
## slowdown happened. Only in web builds made for the review page
## (tools/publish.sh --review sets window.thresholdPlaytest) or opened with
## "?overlay" in the address, so players never see it.
##
## It shows on every screen: the frames a second, the time since the game
## opened, the time into the chapter playing (its playtest_time()), and the
## last slow frame: when it was and how long it took.

const SLOW_FRAME_MS := 50.0  # A frame this long is a visible stutter.

var _label: Label
var _clock := 0.0
var _last_slow := ""
var _last_ticks := 0


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	var on: Variant = JavaScriptBridge.eval(
			"window.thresholdPlaytest === true || new URLSearchParams(window.location.search).has('overlay')", true)
	# The web hands a JavaScript true back as 1.
	if not on:
		return
	layer = 100
	JavaScriptBridge.eval("window.thresholdOverlayOn = true")  # For tests/web.
	_label = Label.new()
	_label.position = Vector2(8.0, 6.0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.8))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)


func _process(delta: float) -> void:
	if _label == null:
		return
	_clock += delta
	var times := "game %s" % _mmss(_clock)
	var chapter := _chapter_time()
	if chapter >= 0.0:
		times += "  chapter %s" % _mmss(chapter)
	# The real gap since the last frame, from the wall clock.
	var ticks := Time.get_ticks_usec()
	var real_ms := (ticks - _last_ticks) / 1000.0 if _last_ticks > 0 else 0.0
	_last_ticks = ticks
	if real_ms >= SLOW_FRAME_MS:
		_last_slow = "slow %d ms at %s" % [roundi(real_ms), times]
	_label.text = "%d fps  %s\n%s" % [Engine.get_frames_per_second(), times, _last_slow]


# Seconds into the chapter playing, from its playtest_time(); -1 if none.
# Every rough chapter has one (CLAUDE.md, "Rough chapters").
func _chapter_time() -> float:
	var runner := get_tree().root.get_node_or_null("ChapterRunner")
	if runner == null:
		return -1.0
	for chapter in runner.get_children():
		if chapter.has_method("playtest_time"):
			return chapter.playtest_time()
	return -1.0


static func _mmss(seconds: float) -> String:
	var s := floori(seconds)
	return "%d:%02d" % [floori(s / 60.0), s % 60]
