extends TestCase
## Pausing a chapter while playing (DAS-130): the pause button over every
## chapter, the Resume panel it opens, and carrying on from there. The
## chapter runner owns both; a chapter only stops what Godot can't stop for it.

const STAND_IN := preload("res://scenes/chapters/stand_in/stand_in_chapter.tscn")
const PARTNER := preload("res://scenes/chapters/partner/partner.tscn")
const PARTNER_SCRIPT := preload("res://scenes/chapters/partner/partner.gd")
const IPHONE_SIDEWAYS := Vector2i(874, 402)
const TO_LAYOUT := 720.0 / 402.0
const STEP := 1.0 / 60.0

## A chapter that notes every tap it hears, every frame it runs, and the
## runner's calls to its pause_chapter() and resume_chapter().
const LISTENER := """
extends Control
signal finished
var taps := 0
var frames := 0
var paused_calls := 0
var resumed_calls := 0
@export var shows_button := true
func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		taps += 1
		get_viewport().set_input_as_handled()
func _process(_delta: float) -> void:
	frames += 1
func pause_chapter() -> void:
	paused_calls += 1
func resume_chapter() -> void:
	resumed_calls += 1
func shows_pause_button() -> bool:
	return shows_button
"""


## The Partner's Conductor, on a fake clock (as in test_partner.gd).
class FakeConductor extends Node:
	var t := -1.0
	var tap := -1.0
	var held := false
	var uses_browser_clock := false
	func is_ready() -> bool: return true
	func has_failed() -> bool: return false
	func start(from := 0.0) -> void: t = from
	func stop() -> void: pass
	func pause() -> void: pass
	func resume() -> void: pass
	func hold() -> void: held = true
	func release() -> void: held = false
	func is_paused() -> bool: return held
	func has_song_ended() -> bool: return false
	func song_time() -> float: return t
	func tap_time() -> float: return tap
	func set_layer_level(_level: float) -> void: pass
	func is_layer_playing() -> bool: return t >= 0.0


var _house: Control


func before_each() -> void:
	_house = Control.new()
	_house.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_house)


func after_each() -> void:
	# The runner lives on the root, so it would outlast this test.
	ChapterRunner.of(get_tree()).free()


func _listener_scene(shows_button := true) -> PackedScene:
	var script := GDScript.new()
	script.source_code = LISTENER
	script.reload()
	var node := Control.new()
	node.set_script(script)
	node.shows_button = shows_button
	var scene := PackedScene.new()
	scene.pack(node)
	node.free()
	return scene


func _enter(scene: PackedScene, id := ChapterList.STAND_IN) -> Node:
	var runner := ChapterRunner.of(get_tree())
	check(runner.enter_scene(id, scene, _house), "entered")
	return runner.get_child(0)


func _pause_layer() -> ChapterPause:
	return ChapterRunner.of(get_tree()).pause_layer()


# --- The button

func test_a_pause_button_shows_top_right_while_a_chapter_plays() -> void:
	var runner := ChapterRunner.of(get_tree())
	check(runner.pause_layer() == null, "no pause button in the House")
	_enter(STAND_IN)
	await frames()
	var button := _pause_layer().pause_button()
	check(button.is_visible_in_tree(), "the button shows over the chapter")
	var rect := button.get_global_rect()
	var screen := button.get_viewport_rect().size
	check(rect.end.x <= screen.x and rect.end.x > screen.x - 120.0, "at the right edge")
	check(rect.position.y >= 0.0 and rect.position.y < 40.0, "at the top")
	check(not button.get_global_rect().intersects(Rect2(0, 0, 240, 60)),
			"clear of the playtest overlay in the top-left")
	tap(_enter_check_finish())
	await frames()
	check(runner.pause_layer() == null, "gone once the chapter is over")


func _enter_check_finish() -> Control:
	return ChapterRunner.of(get_tree()).get_child(0).get_node("%FinishButton")


func test_the_pause_button_is_at_least_44_points_on_a_sideways_phone() -> void:
	set_screen(IPHONE_SIDEWAYS)
	_enter(STAND_IN)
	await frames(2)
	var size := _pause_layer().pause_button().get_global_rect().size
	check(size.x >= 44.0 * TO_LAYOUT - 0.5 and size.y >= 44.0 * TO_LAYOUT - 0.5,
			"pause button is %s on the layout, at least 44 points on the phone" % size)
	tap(_pause_layer().pause_button())
	await frames()
	var resume := _pause_layer().resume_button().get_global_rect().size
	check(resume.y >= 44.0 * TO_LAYOUT - 0.5, "Resume is at least 44 points tall on the phone")


# --- Pausing

func test_tapping_pause_stops_the_chapter_and_it_never_hears_that_tap() -> void:
	var chapter := _enter(_listener_scene())
	await frames(2)
	check(chapter.frames > 0, "the chapter runs before the pause")
	tap(_pause_layer().pause_button())
	await frames()
	var runner := ChapterRunner.of(get_tree())
	check(runner.is_paused(), "paused")
	check_eq(chapter.taps, 0, "the chapter didn't hear the pause tap")
	check_eq(chapter.paused_calls, 1, "the chapter's own pause_chapter() ran")
	check(not chapter.can_process(), "the chapter's processing stopped")
	var at: int = chapter.frames
	await frames(3)
	check_eq(chapter.frames, at, "nothing moves while paused")


func test_while_paused_one_panel_says_paused_with_resume_focused() -> void:
	_enter(_listener_scene())
	await frames()
	tap(_pause_layer().pause_button())
	await frames()
	var layer := _pause_layer()
	check(layer.is_open(), "the panel is up")
	check(layer.get_node("Scrim").is_visible_in_tree(), "a scrim covers the chapter")
	check(not layer.pause_button().is_visible_in_tree(), "the pause button steps aside")
	var title := layer.find_child("Title", true, false) as Label
	check(title != null and title.text == "Paused" and title.is_visible_in_tree(), "says Paused")
	var resume := layer.resume_button()
	check_eq(resume.text, "Resume", "one Resume button")
	check_eq(resume.theme_type_variation, &"ButtonPrimary", "button-primary")
	check(resume.has_focus(), "Resume has the focus")
	var buttons := layer.find_children("*", "BaseButton", true, false).filter(
			func(b: BaseButton) -> bool: return b.is_visible_in_tree())
	check_eq(buttons.size(), 1, "no other button: no skip, leave or retry")


func test_taps_off_the_panel_do_nothing_and_never_reach_the_chapter() -> void:
	var chapter := _enter(_listener_scene())
	await frames()
	tap(_pause_layer().pause_button())
	await frames()
	for point in [Vector2(40, 40), Vector2(640, 680), Vector2(1240, 360), Vector2(1230, 50)]:
		tap_at(point)
	await frames()
	check(ChapterRunner.of(get_tree()).is_paused(), "still paused")
	check_eq(chapter.taps, 0, "the chapter heard none of them")


func test_a_stand_in_button_under_the_scrim_cannot_be_tapped() -> void:
	var finished := []
	ChapterRunner.of(get_tree()).chapter_finished.connect(func(r: Dictionary) -> void: finished.append(r))
	_enter(STAND_IN)
	await frames()
	var finish := _enter_check_finish()
	tap(_pause_layer().pause_button())
	await frames()
	tap(finish)
	await frames()
	check(finished.is_empty(), "Finish under the scrim did nothing")
	check(ChapterRunner.of(get_tree()).is_running(), "still in the chapter")


# --- Resuming

func test_resume_carries_on_where_the_player_left_off() -> void:
	var chapter := _enter(_listener_scene())
	await frames()
	tap(_pause_layer().pause_button())
	await frames()
	tap(_pause_layer().resume_button())
	await frames()
	var runner := ChapterRunner.of(get_tree())
	check(not runner.is_paused(), "resumed")
	check_eq(chapter.resumed_calls, 1, "the chapter's own resume_chapter() ran")
	check(chapter.can_process(), "the chapter runs again")
	check(not _pause_layer().is_open(), "panel gone")
	check(_pause_layer().pause_button().is_visible_in_tree(), "the pause button is back")
	check_eq(chapter.taps, 0, "the Resume tap didn't reach the chapter")
	var at: int = chapter.frames
	await frames(2)
	check(chapter.frames > at, "moving again")
	tap_at(Vector2(640, 360))
	check_eq(chapter.taps, 1, "the chapter hears taps again")


func test_enter_activates_resume() -> void:
	_enter(_listener_scene())
	await frames()
	tap(_pause_layer().pause_button())
	await frames()
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	get_viewport().push_input(enter)
	var up := enter.duplicate() as InputEventKey
	up.pressed = false
	get_viewport().push_input(up)
	await frames()
	check(not ChapterRunner.of(get_tree()).is_paused(), "Enter resumed")


func test_the_chapter_keeps_its_own_process_mode_after_resuming() -> void:
	var chapter := _enter(_listener_scene())
	chapter.process_mode = Node.PROCESS_MODE_ALWAYS
	var runner := ChapterRunner.of(get_tree())
	runner.pause()
	runner.resume()
	check_eq(chapter.process_mode, Node.PROCESS_MODE_ALWAYS, "its own process mode back")


func test_pausing_and_resuming_never_saves() -> void:
	var state := get_node("/root/GameState")
	state.start_new()
	_enter(_listener_scene())
	await frames()
	tap(_pause_layer().pause_button())
	await frames()
	check(not state.has_save(), "nothing saved on pause")
	tap(_pause_layer().resume_button())
	await frames()
	check(not state.has_save(), "nothing saved on resume")
	state.start_new()


func test_a_chapter_can_go_without_the_button() -> void:
	var chapter := _enter(_listener_scene(false))
	await frames()
	var button := _pause_layer().pause_button()
	check(not button.is_visible_in_tree(), "no pause button")
	tap_at(button.get_global_rect().get_center())
	check(not ChapterRunner.of(get_tree()).is_paused(), "that corner doesn't pause")
	check_eq(chapter.taps, 1, "the chapter hears a tap there")
	var runner := ChapterRunner.of(get_tree())
	runner.pause()
	runner.resume()
	check(not button.is_visible_in_tree(), "still no button after a pause and resume")


# --- Each chapter

func test_the_partner_holds_its_song_and_the_chart_stays_in_step() -> void:
	PARTNER_SCRIPT._sound_delay = 0.0
	PARTNER_SCRIPT._calibrated = false
	var partner := _enter(PARTNER, &"partner")
	var fake := FakeConductor.new()
	partner.add_child(fake)
	partner._conductor = fake
	partner._process(STEP)
	partner._on_tap()  # The song starts.
	var note: float = partner._notes[0]
	fake.t = note - 1.0
	partner._process(STEP)
	tap(_pause_layer().pause_button())
	await frames()
	check(fake.held, "the song is held")
	check_eq(partner.probe_state().hits + partner.probe_state().misses, 0, "the pause tap judged nothing")
	tap_at(Vector2(640, 360))
	check_eq(partner.probe_state().hits + partner.probe_state().misses, 0, "a tap while paused judges nothing")
	tap(_pause_layer().resume_button())
	await frames()
	check(not fake.held, "the song carries on")
	fake.t = note
	fake.tap = note
	partner._process(STEP)
	tap_at(Vector2(640, 360))
	check_eq(partner._judged[0], partner.Judged.HIT, "the first note after resuming is a hit")


func test_the_loss_shows_no_pause_button_but_can_still_be_paused() -> void:
	var chapter := _enter(preload("res://scenes/chapters/protector/protector.tscn"), &"protector")
	var run: Node = chapter.run()
	run.auto_advance = false
	run.advance(10.0)
	await frames()
	check(not _pause_layer().pause_button().is_visible_in_tree(),
			"no pause button in the Loss (docs/design/the-loss-run-and-car.md)")
	var runner := ChapterRunner.of(get_tree())
	runner.pause()
	check(run.is_paused(), "the run is paused")
	check(not run.is_music_playing(), "its music stopped")
	run.advance(5.0)
	check_near(run.time(), 10.0, STEP, "its clock stopped")
	runner.resume()
	check(not run.is_paused(), "the run carries on")
	run.advance(1.0)
	check_near(run.time(), 11.0, STEP, "from where it paused")
