extends Node
## Lets the browser tests (tests/web/) see inside the canvas. Only runs in a
## web build opened with "?probe" in the address, so players never get it.
## Each frame it writes the current scene, any screen opened on top of it,
## every visible button with its centre, and the `probe_state()` of any
## screen that has one (for screens with no buttons, like the Partner) to
## window.thresholdProbe, where Playwright reads it. Positions are in the
## game's own screen units (1280 wide on a laptop), and "size" is the whole
## screen in those units.

var _window: JavaScriptObject


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	var search: Variant = JavaScriptBridge.eval("window.location.search", true)
	if search == null or not String(search).contains("probe"):
		return
	_window = JavaScriptBridge.get_interface("window")
	# "&partner_from=190" starts the Partner's song that many seconds in, so a
	# test can reach its ending without playing the whole song.
	for part in String(search).trim_prefix("?").split("&"):
		if part.begins_with("partner_from="):
			get_tree().root.set_meta("partner_start_from", part.get_slice("=", 1).to_float())
	print("Threshold test probe on")


func _process(_delta: float) -> void:
	if _window == null:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var overlays: Array[String] = []
	var screens := {}
	if scene.has_method("probe_state"):
		screens[scene.scene_file_path] = scene.probe_state()
	# Chapters play under the chapter runner (game/_core/chapters/), not under
	# the scene that started them; they count as screens on top of it too.
	var on_top := scene.get_children()
	var runner := get_tree().root.get_node_or_null("ChapterRunner")
	if runner:
		on_top.append_array(runner.get_children())
	for child in on_top:
		if child.scene_file_path != "":
			overlays.append(child.scene_file_path)
			if child.has_method("probe_state"):
				screens[child.scene_file_path] = child.probe_state()
	var buttons: Array[Dictionary] = []
	_collect_buttons(get_tree().root, buttons)
	_window.thresholdProbe = JSON.stringify({
		"scene": scene.scene_file_path,
		"size": {"x": get_viewport().get_visible_rect().size.x, "y": get_viewport().get_visible_rect().size.y},
		"overlays": overlays,
		"buttons": buttons,
		"screens": screens,
	})


func _collect_buttons(node: Node, out: Array[Dictionary]) -> void:
	var button := node as BaseButton
	if button and button.is_visible_in_tree():
		var centre := button.get_global_transform_with_canvas() * (button.size / 2.0)
		out.append({
			"text": button.text if button is Button else "",
			"x": centre.x,
			"y": centre.y,
			"disabled": button.disabled,
		})
	for child in node.get_children():
		_collect_buttons(child, out)
