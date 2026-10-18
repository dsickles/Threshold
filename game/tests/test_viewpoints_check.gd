extends TestCase
## The M0 viewpoints check (DAS-69): tap a ring to glide to the view of a
## thing; buttons change how long the glide takes.

const VIEWPOINTS := preload("res://scenes/m0_checks/viewpoints_check.tscn")
const SCREENS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]

var _room: Node


func before_each() -> void:
	_room = add_scene(VIEWPOINTS)


# Finishes the glide that is under way, as if its whole time had passed.
func _finish_glide() -> void:
	if _room._tween and _room._tween.is_valid():
		_room._tween.custom_step(_room._glide_seconds + 0.1)
	await frames()


func _same_place(a: Transform3D, b: Transform3D) -> bool:
	return a.origin.distance_to(b.origin) < 0.01 and a.basis.z.distance_to(b.basis.z) < 0.01


func _button_with_text(text: String) -> Button:
	for button in _room.find_children("*", "Button", true, false):
		if button.text == text:
			return button
	return null


func test_starts_in_the_doorway() -> void:
	var start: Transform3D = _room._look_from(_room.START_STAND, _room.START_LOOK_AT)
	check(_same_place(_room._camera.global_transform, start), "camera starts in the doorway")
	check_eq(_room._current, -1, "no viewpoint chosen yet")


func test_tapping_a_ring_glides_to_its_view() -> void:
	await frames()
	for i in _room.VIEWPOINTS.size():
		var from: Transform3D = _room._camera.global_transform
		var to: Transform3D = _room._viewpoint_transform(i)
		var ring: Button = _room._rings[i]
		check(ring.visible, "ring %d visible before tapping it" % i)
		tap(ring)
		check_eq(_room._current, i, "viewpoint after tapping ring %d" % i)
		# Halfway through, the camera is between the two views, not jumped.
		_room._tween.custom_step(_room._glide_seconds / 2.0)
		var mid: Transform3D = _room._camera.global_transform
		check(not _same_place(mid, from) and not _same_place(mid, to),
				"camera halfway through the glide to %d" % i)
		await _finish_glide()
		check(_same_place(_room._camera.global_transform, to), "camera at viewpoint %d" % i)
		check(not ring.visible, "ring %d hidden while standing there" % i)


func test_tapping_another_ring_mid_glide_ends_at_the_new_view() -> void:
	await frames()
	tap(_room._rings[0])
	_room._tween.custom_step(_room._glide_seconds / 3.0)
	await frames()
	tap(_room._rings[2])
	await _finish_glide()
	check_eq(_room._current, 2, "viewpoint after changing mind")
	check(_same_place(_room._camera.global_transform, _room._viewpoint_transform(2)),
			"camera at the second ring's view")


func test_glide_buttons_change_the_glide_time_within_limits() -> void:
	await frames()
	var shorter := _button_with_text("−")
	var longer := _button_with_text("+")
	if not check(shorter != null and longer != null, "glide buttons found"):
		return
	check_near(_room._glide_seconds, 2.0, 1e-6, "starting glide time")
	tap(longer)
	check_near(_room._glide_seconds, 2.2, 1e-6, "glide time after +")
	check_eq(_room._glide_label.text, "Glide 2.2 s", "glide readout")
	for i in 20:
		tap(longer)
	check_near(_room._glide_seconds, _room.GLIDE_MAX, 1e-6, "glide time stops at its maximum")
	for i in 30:
		tap(shorter)
	check_near(_room._glide_seconds, _room.GLIDE_MIN, 1e-6, "glide time stops at its minimum")


func test_glide_takes_the_chosen_time() -> void:
	await frames()
	_room._set_glide(1.0)
	tap(_room._rings[1])
	_room._tween.custom_step(0.9)
	check(not _same_place(_room._camera.global_transform, _room._viewpoint_transform(1)),
			"not there yet after 0.9 s of a 1 s glide")
	_room._tween.custom_step(0.2)
	check(_same_place(_room._camera.global_transform, _room._viewpoint_transform(1)),
			"there after 1.1 s of a 1 s glide")


# From the doorway and from every viewpoint, on a laptop and on a phone held
# either way: every other viewpoint has a ring on screen, at least 44px, not
# on top of another ring or the buttons along the top.
func test_rings_stay_on_screen_and_tappable_everywhere() -> void:
	for screen in SCREENS:
		set_screen(screen)
		for stand in range(-1, _room.VIEWPOINTS.size()):
			if stand >= 0:
				tap(_room._rings[stand])
				await _finish_glide()
			await frames(2)
			_check_rings("%s from %s" % [screen, "doorway" if stand < 0 else "viewpoint %d" % stand])


func _check_rings(where: String) -> void:
	var visible_area := Rect2(Vector2.ZERO, _room.get_viewport().get_visible_rect().size)
	var top_buttons: Array[Rect2] = []
	for button in _room.find_children("*", "Button", true, false):
		if not button in _room._rings:
			top_buttons.append((button as Control).get_global_rect())
	var shown: Array[Rect2] = []
	for i in _room._rings.size():
		var ring: Button = _room._rings[i]
		if i == _room._current:
			check(not ring.visible, "%s: own ring hidden" % where)
			continue
		var rect := ring.get_global_rect()
		check(ring.visible, "%s: ring %d visible" % [where, i])
		check(rect.size.x >= 44.0 and rect.size.y >= 44.0, "%s: ring %d at least 44px" % [where, i])
		check(visible_area.encloses(rect), "%s: ring %d on screen (%s)" % [where, i, rect])
		for other in shown:
			check(not rect.intersects(other), "%s: ring %d overlaps another ring" % [where, i])
		for button in top_buttons:
			check(not rect.intersects(button), "%s: ring %d covers a button" % [where, i])
		shown.append(rect)


func test_back_returns_to_the_menu() -> void:
	await frames()
	tap(_button_with_text("Back to menu"))
	await frames(2)
	var scene := get_tree().current_scene
	check(scene != null and scene.scene_file_path == "res://scenes/ui/m0_menu.tscn",
			"Back opens the M0 menu")
