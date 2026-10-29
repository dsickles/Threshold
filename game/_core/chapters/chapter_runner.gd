class_name ChapterRunner
extends Node
## Starts a chapter from the House, gives it the screen, and brings the player
## back with its one result. The shared system in
## docs/design/game-architecture.md §2.5. How to use it and how a chapter
## plugs in: game/_core/chapters/README.md.
##
## One runner lives at /root/ChapterRunner; get it with ChapterRunner.of(tree).
## It is not an autoload, so it adds nothing to project.godot.
## While a chapter plays, the House is hidden and paused, not unloaded, so it
## comes back exactly as the player left it.

## The chapter finished. `result` is a ChapterResult dictionary. Sent after
## the House is back, so this is the moment to record the result and save.
signal chapter_finished(result: Dictionary)
## The chapter closed without finishing (for example its song failed to load).
## No result: nothing is recorded or saved.
signal chapter_left(chapter: StringName)

const NODE_NAME := "ChapterRunner"

var _chapter: Node
var _id: StringName
var _house: Node
var _house_visible := true
var _house_process_mode := PROCESS_MODE_INHERIT


static var _instance: ChapterRunner

var _root: Window


## The runner for this game, made the first time it is asked for. It joins
## /root at the end of the frame (the House may ask while the root is still
## adding the House itself), or as soon as a chapter is entered.
static func of(tree: SceneTree) -> ChapterRunner:
	if not is_instance_valid(_instance):
		_instance = ChapterRunner.new()
		_instance.name = NODE_NAME
		_instance._root = tree.root
		_instance._join.call_deferred()
	return _instance


func _join() -> void:
	if get_parent() == null:
		_root.add_child(self)


func is_running() -> bool:
	return _chapter != null


## The id of the chapter playing now, or &"" if none.
func current_chapter() -> StringName:
	return _id if is_running() else &""


## Starts chapter `id` from `house` (the node to hide and pause until the
## chapter is over). Returns false, and changes nothing, if a chapter is
## already playing or `id` has no scene.
func enter(id: StringName, house: Node) -> bool:
	if _refuse_while_running(id):
		return false
	var path := ChapterList.scene_path(id)
	var scene := load(path) as PackedScene if path != "" else null
	if scene == null:
		push_error("ChapterRunner: no scene for chapter %s" % id)
		return false
	return enter_scene(id, scene, house)


## Like enter(), with the scene given directly. For tests and stand-ins.
func enter_scene(id: StringName, scene: PackedScene, house: Node) -> bool:
	if _refuse_while_running(id):
		return false
	_chapter = scene.instantiate()
	if not _chapter.has_signal("finished"):
		push_error("ChapterRunner: chapter %s has no `finished` signal" % id)
		_chapter.free()
		_chapter = null
		return false
	# Joins now if of() was called this same frame. A House that enters a
	# chapter from its own _ready while it is the main scene would hit
	# "Parent node is busy" here: start the chapter deferred in that case.
	_join()
	_id = id
	_house = house
	_hide_house()
	_chapter.finished.connect(_on_finished)
	_chapter.tree_exited.connect(_on_chapter_exited)
	add_child(_chapter)
	return true


## Pauses the chapter playing, if it can pause (it has a pause() method), as
## it would for a hidden tab: it waits for a tap to carry on. For the "Turn
## your phone sideways" screen.
func pause_chapter() -> void:
	if is_running() and _chapter.has_method("pause"):
		_chapter.pause()


# A second tap on a chapter object, say. Harmless, so only a warning.
func _refuse_while_running(id: StringName) -> bool:
	if is_running():
		push_warning("ChapterRunner: %s is still playing; can't start %s" % [_id, id])
	return is_running()


# A chapter emits `finished` with no arguments, or with its answer, or with
# its answer and a House dictionary. The arguments are untyped and checked
# here, so a chapter that emits the wrong thing still brings the House back
# (with no answer and nothing for the House) instead of leaving the player
# stuck.
func _on_finished(...args: Array) -> void:
	var answer := ChapterResult.NO_ANSWER
	var house := {}
	if args.size() > 2:
		push_error("ChapterRunner: %s finished with %d arguments; expected at most 2" % [_id, args.size()])
	if args.size() >= 1:
		if args[0] is String and args[0] in ChapterResult.ANSWERS:
			answer = args[0]
		else:
			push_error("ChapterRunner: %s finished with unknown answer %s" % [_id, args[0]])
	if args.size() >= 2:
		if args[1] is Dictionary and ChapterResult.is_plain_json(args[1]):
			house = args[1]
		else:
			push_error("ChapterRunner: %s finished with a House value that isn't plain JSON: %s" % [_id, args[1]])
	var result := ChapterResult.make(_id, answer, house)
	_chapter.queue_free()
	_close()
	chapter_finished.emit(result)


func _on_chapter_exited() -> void:
	var id := _id
	_close()
	chapter_left.emit(id)


# Disconnects first, so a chapter that is still on its way out can't report
# again, even once the next chapter has started.
func _close() -> void:
	_chapter.finished.disconnect(_on_finished)
	_chapter.tree_exited.disconnect(_on_chapter_exited)
	_chapter = null
	_id = &""
	_show_house()
	_house = null


func _hide_house() -> void:
	if not is_instance_valid(_house):
		return
	_house_process_mode = _house.process_mode
	_house.process_mode = PROCESS_MODE_DISABLED
	if "visible" in _house:
		_house_visible = _house.visible
		_house.visible = false


func _show_house() -> void:
	if not is_instance_valid(_house):
		return
	_house.process_mode = _house_process_mode
	if "visible" in _house:
		_house.visible = _house_visible
