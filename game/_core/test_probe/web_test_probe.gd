extends Node
## Lets the browser tests (tests/web/) see inside the canvas. Only runs in a
## web build opened with "?probe" in the address, so players never get it.
## Each frame it writes the current scene, any screen opened on top of it,
## every visible button with its centre, and the finished-chapter list to
## window.thresholdProbe, where Playwright reads it. "&finish=<chapter>" or
## "&finish=<chapter>:<answer>" in the address records that chapter as
## finished when the game starts, so a test can make a save without playing. Positions are in the game's own screen units (1280
## wide on a laptop), and "size" is the whole screen in those units.

var _window: JavaScriptObject


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	var search: Variant = JavaScriptBridge.eval("window.location.search", true)
	if search == null or not String(search).contains("probe"):
		return
	_window = JavaScriptBridge.get_interface("window")
	print("Threshold test probe on")
	_finish_chapter_from_address(String(search))


func _process(_delta: float) -> void:
	if _window == null:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var overlays: Array[String] = []
	for child in scene.get_children():
		if child.scene_file_path != "":
			overlays.append(child.scene_file_path)
	var buttons: Array[Dictionary] = []
	_collect_buttons(get_tree().root, buttons)
	_window.thresholdProbe = JSON.stringify({
		"scene": scene.scene_file_path,
		"size": {"x": get_viewport().get_visible_rect().size.x, "y": get_viewport().get_visible_rect().size.y},
		"overlays": overlays,
		"buttons": buttons,
		"progress": {
			"finished": _game_state().to_save_data().finished,
			"saveOk": _game_state().last_save_ok,
		},
	})


func _finish_chapter_from_address(search: String) -> void:
	for part in search.trim_prefix("?").split("&"):
		if not part.begins_with("finish="):
			continue
		var value := part.trim_prefix("finish=").uri_decode().split(":")
		_game_state().record_chapter_result({
			"chapter": value[0],
			"answer": value[1] if value.size() > 1 else "",
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


# Looked up by path: the stand-alone script check doesn't know autoload names.
func _game_state() -> Node:
	return get_node("/root/GameState")
