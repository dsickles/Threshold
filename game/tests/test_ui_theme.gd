extends TestCase
## The shared UI theme (DAS-72): one theme for every screen, DESIGN.md's type
## scale as seen on a sideways iPhone, button-primary and button-quiet as
## DESIGN.md describes them, and the UI style check that shows it all.

const THEME_PATH := "res://assets/ui/threshold_theme.tres"
const UI_STYLE := preload("res://scenes/m0_checks/ui_style_check.tscn")
## A sideways iPhone 17 Pro in Safari with the toolbar hidden, in points.
const IPHONE_SIDEWAYS := Vector2i(874, 402)
## DESIGN.md sizes are what the player sees there; the 720-tall layout shrinks
## to 402/720, so each layout size is the DESIGN.md size x 720/402.
const TO_LAYOUT := 720.0 / 402.0
const DESIGN_SIZES := {
	"Label": 16, "LabelSubtitle": 18, "LabelReader": 20, "LabelMicroShout": 28, "LabelDisplay": 32,
}
const SURFACE := Color("#1C1916")
const RAISED := Color("#2A2520")
const INK := Color("#F4EFE6")
const MUTED := Color("#9A9084")
const ACCENT := Color("#C4A574")
const BORDER := Color("#3D3832")
## The theme is sized for a phone held sideways, the way the game is played
## (docs/scope.md, "How Dan plays the test build"), so the 44px check is on
## laptop and sideways screens; upright, the UI style check must still fit.
const SIDEWAYS_SCREENS := [Vector2i(1280, 720), IPHONE_SIDEWAYS, Vector2i(852, 393)]
const UPRIGHT := Vector2i(390, 844)


func _theme() -> Theme:
	return load(THEME_PATH)


func _layout(design_px: float) -> int:
	return roundi(design_px * TO_LAYOUT)


func test_the_shared_theme_is_the_project_theme() -> void:
	check_eq(ProjectSettings.get_setting("gui/theme/custom"), THEME_PATH, "project theme setting")
	var project_theme := ThemeDB.get_project_theme()
	check(project_theme != null and project_theme.resource_path == THEME_PATH,
			"the game runs with the shared theme")


# Screens use the shared theme instead of carrying their own copy.
func test_no_screen_carries_its_own_theme() -> void:
	var files := PackedStringArray()
	_find_files("res://scenes", files)
	check(files.size() > 5, "found the scenes and scripts")
	for path in files:
		var text := FileAccess.get_file_as_string(path)
		check(not text.contains("type=\"Theme\""), "%s has no theme of its own" % path)
		check(not text.contains("Theme.new()"), "%s builds no theme of its own" % path)


func _find_files(dir: String, out: PackedStringArray) -> void:
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".tscn") or file.ends_with(".gd"):
			out.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		_find_files(dir.path_join(sub), out)


func test_font_sizes_are_the_design_scale_scaled_for_the_phone() -> void:
	var theme := _theme()
	check_eq(theme.default_font_size, _layout(16), "body (the default) is 16 on the phone")
	check_eq(theme.default_font_size, 29, "body is 29 on the layout")
	for type in DESIGN_SIZES:
		if type == "Label":
			continue
		check_eq(theme.get_font_size("font_size", type), _layout(DESIGN_SIZES[type]),
				"%s is %d on the phone" % [type, DESIGN_SIZES[type]])


# What a player actually sees: each text style on the UI style check, on a
# sideways iPhone 17 Pro, comes out at its DESIGN.md size in points.
func test_text_on_a_sideways_iphone_is_the_design_size() -> void:
	set_screen(IPHONE_SIDEWAYS)
	var screen := add_scene(UI_STYLE)
	await frames(2)
	var shown: float = screen.current_shown_scale()
	check_near(shown, 402.0 / 720.0, 0.002, "the layout shrinks to 402/720")
	var names := {"Label": "Body", "LabelSubtitle": "Subtitle", "LabelReader": "Reader",
			"LabelMicroShout": "MicroShout", "LabelDisplay": "Display"}
	for type in DESIGN_SIZES:
		var label: Label = screen.get_node("%" + names[type])
		var points := label.get_theme_font_size("font_size") * shown
		check_near(points, DESIGN_SIZES[type], 0.5, "%s on the phone (is %.1f pt)" % [type, points])
	check_near(screen.body_points(), 16.0, 0.5, "the screen's own body measure")


func test_shown_scale_uses_points_not_device_pixels() -> void:
	var script: GDScript = UI_STYLE.instantiate().get_script()
	# An iPhone 17 Pro sideways is 2622 x 1206 pixels at 3 pixels a point.
	check_near(script.shown_scale(Vector2(2622, 1206), 3.0, Vector2(1565, 720)), 402.0 / 720.0, 0.001,
			"three pixels per point")
	check_eq(script.shown_scale(Vector2(100, 100), 1.0, Vector2.ZERO), 0.0, "no layout yet")


func test_button_primary_is_a_gold_fill_with_a_dark_label() -> void:
	var theme := _theme()
	check_eq(theme.get_type_variation_base("ButtonPrimary"), &"Button", "a kind of Button")
	var normal := theme.get_stylebox("normal", "ButtonPrimary") as StyleBoxFlat
	check(normal.draw_center, "filled")
	check_eq(normal.bg_color, ACCENT, "accent fill")
	check_eq(normal.corner_radius_top_left, _layout(8), "rounded.md corners")
	check_eq(theme.get_color("font_color", "ButtonPrimary"), SURFACE, "surface label")
	var pressed := theme.get_stylebox("pressed", "ButtonPrimary") as StyleBoxFlat
	check(pressed.bg_color.get_luminance() < ACCENT.get_luminance(), "pressed is slightly darker")
	check(pressed.bg_color.get_luminance() > ACCENT.get_luminance() * 0.7, "only slightly")


func test_button_quiet_is_an_outline_with_a_light_label() -> void:
	var theme := _theme()
	check_eq(theme.get_type_variation_base("ButtonQuiet"), &"Button", "a kind of Button")
	# Plain Buttons are quiet too, so a button nobody styled still looks right.
	for type in ["Button", "ButtonQuiet"]:
		var normal := _stylebox(theme, "normal", type)
		check(not normal.draw_center, "%s is transparent" % type)
		check_eq(normal.border_color, BORDER, "%s border colour" % type)
		check_eq(normal.border_width_left, _layout(1), "%s 1px border on the phone" % type)
		check_eq(normal.corner_radius_top_left, _layout(8), "%s rounded.md corners" % type)
		check_eq(_color(theme, "font_color", type), INK, "%s ink label" % type)
		check_eq(_color(theme, "font_disabled_color", type), MUTED, "%s off is muted" % type)
		var pressed := _stylebox(theme, "pressed", type)
		check(pressed.draw_center and pressed.bg_color == RAISED, "%s pressed fills" % type)
	check_eq(_color(theme, "font_color", "LabelMuted"), MUTED, "muted labels")
	check_eq(theme.get_color("font_color", "Label"), INK, "labels are ink")


# Hover must not show anything a tap can't: hover looks the same as resting,
# and every state has a focus ring for tap and keyboard alike.
func test_nothing_works_only_on_hover() -> void:
	var theme := _theme()
	for type in ["Button", "ButtonQuiet", "ButtonPrimary"]:
		check(_stylebox(theme, "hover", type) == _stylebox(theme, "normal", type),
				"%s hover looks like resting" % type)
		check(_stylebox(theme, "hover_pressed", type) == _stylebox(theme, "pressed", type),
				"%s hover while pressed looks like pressed" % type)
		check_eq(_color(theme, "font_hover_color", type), _color(theme, "font_color", type),
				"%s hover label" % type)
	var focus := theme.get_stylebox("focus", "Button") as StyleBoxFlat
	check_eq(focus.border_color, ACCENT, "focus ring is accent")
	check_eq(focus.border_width_top, _layout(2), "2px focus ring on the phone")


# Variations fall back to Button for anything they don't set themselves.
func _stylebox(theme: Theme, name: String, type: String) -> StyleBoxFlat:
	if theme.has_stylebox(name, type):
		return theme.get_stylebox(name, type)
	return theme.get_stylebox(name, "Button")


func _color(theme: Theme, name: String, type: String) -> Color:
	if theme.has_color(name, type):
		return theme.get_color(name, type)
	return theme.get_color(name, "Button")


# A one-word button with nothing else setting its size is still at least 44
# points tall on a sideways iPhone.
func test_a_plain_button_is_at_least_44_points_on_the_phone() -> void:
	set_screen(IPHONE_SIDEWAYS)
	for type in [&"", &"ButtonQuiet", &"ButtonPrimary"]:
		var button := Button.new()
		button.text = "Go"
		button.theme_type_variation = type
		add_child(button)
		var size := button.get_combined_minimum_size()
		check(size.y >= _layout(44), "%s is at least %d tall on the layout (is %s)" % [type, _layout(44), size])
		check(size.y * 402.0 / 720.0 >= 44.0, "%s is at least 44 pt on the phone" % type)
		button.free()


func test_ui_style_check_fits_every_screen() -> void:
	for screen in SIDEWAYS_SCREENS + [UPRIGHT]:
		set_screen(screen)
		var check_screen := add_scene(UI_STYLE)
		await frames(2)
		var view := get_viewport().get_visible_rect()
		var to_screen := float(screen.y) / view.size.y
		for child in check_screen.find_children("*", "Control", true, false):
			var control := child as Control
			if control is Label or control is Button:
				check(view.encloses(control.get_global_rect()),
						"%s on screen on %s (is %s)" % [control.name, screen, control.get_global_rect()])
			if control is Button and screen != UPRIGHT:
				var real := control.size * to_screen
				check(real.x >= 44.0 and real.y >= 44.0,
						"%s at least 44px on %s (is %s)" % [control.name, screen, real])
		check(check_screen.get_node("%Measure").text.contains("pt"), "the measure line is shown")
		check_screen.free()


func test_ui_style_buttons_use_the_right_kind() -> void:
	var screen := add_scene(UI_STYLE)
	check_eq(screen.get_node("%PrimaryButton").theme_type_variation, &"ButtonPrimary", "one primary")
	check(screen.get_node("%QuietOffButton").disabled, "an off quiet button to compare")


func test_back_returns_to_the_menu() -> void:
	var screen := add_scene(UI_STYLE)
	await frames()
	tap(screen.get_node("%BackButton"))
	await frames(2)
	var scene := get_tree().current_scene
	check(scene != null and scene.scene_file_path == "res://scenes/ui/m0_menu.tscn", "Back opens the menu")
