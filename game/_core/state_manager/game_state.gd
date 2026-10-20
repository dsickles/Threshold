extends Node
## The finished-chapter list: which chapters the player has finished, in
## order, with the Stoic/Vulnerable answer each gave (if any). It is the only
## story state that is saved; story facts, House mood and journal entries are
## looked up from it by the core table (game-architecture 2.1). Settings, and
## any House state a chapter hands back that the core table can't look up,
## are saved alongside it. Autoloaded as GameState.
##
## Saves only when a chapter finishes: the chapter runner's chapter_finished
## (game/_core/chapters/README.md) is connected to record_chapter_result.
## Leaving a chapter early, hiding the tab or closing it mid-chapter saves
## nothing. Chapter ids and the result shape come from ChapterList and
## ChapterResult. Storage and the save format: ADR-0007.

## Emitted after a chapter is added to the finished-chapter list.
signal progress_changed
## Emitted when a save could not be kept, so the game can show
## "Couldn't save." and carry on.
signal save_failed

## Whether the last save was kept. True until a save fails.
var last_save_ok := true

# Whether a valid save is on disk: one was loaded or written.
var _has_save := false

var _finished: Array[Dictionary] = []
var _settings := {}
var _file := SaveFile.new()


func _ready() -> void:
	load_save()
	ChapterRunner.of(get_tree()).chapter_finished.connect(record_chapter_result)


## Uses a different save file (tests use their own). Clears what is in
## memory; call load_save() to read the new file.
func use_save_file(file: SaveFile) -> void:
	_file = file
	_clear()


## Reads the save, replacing what is in memory. A save that is missing,
## unreadable or impossible (chapters out of story order, or an entry that
## isn't a story result) counts as no save: the game starts fresh. Returns whether a save
## was loaded.
func load_save() -> bool:
	_clear()
	var data := _file.read()
	if data.is_empty() or not _is_valid(data):
		return false
	_has_save = true
	for entry: Dictionary in data.finished:
		_finished.append(_entry(entry.chapter, entry.answer, entry.get("house", {})))
	_settings = data.get("settings", {})
	progress_changed.emit()
	return true


## Records a finished chapter and saves. The result is a ChapterResult and
## must pass ChapterResult.is_story_result, so the menu's test-only stand-in
## and malformed results (a missing answer, House values that aren't plain
## JSON) are never saved. The chapter must be the next one in story order;
## finishing one that is already finished changes nothing.
## Returns whether the chapter was recorded (false: refused, or already
## finished). Whether the save was kept is separate: see last_save_ok and
## save_failed, since a chapter is recorded and play carries on even when the
## save can't be written.
func record_chapter_result(result: Dictionary) -> bool:
	if not ChapterResult.is_story_result(result):
		if result.get("chapter") != String(ChapterList.STAND_IN):
			push_warning("GameState: not a story result: %s" % [result])
		return false
	var chapter: String = result.chapter
	if is_finished(chapter):
		return false
	if chapter != next_chapter():
		push_warning("GameState: '%s' is not the next chapter (expected '%s')." % [chapter, next_chapter()])
		return false
	_finished.append(_entry(chapter, result.answer, result.get("house", {})))
	progress_changed.emit()
	_save()
	return true


## The finished chapters' ids, in the order they were finished.
func finished_chapters() -> Array[String]:
	var ids: Array[String] = []
	for entry in _finished:
		ids.append(entry.chapter)
	return ids


func is_finished(chapter: String) -> bool:
	return chapter in finished_chapters()


## The next chapter to play, or "" once The Arrival is finished.
func next_chapter() -> String:
	var order := ChapterList.STORY_ORDER
	return String(order[_finished.size()]) if _finished.size() < order.size() else ""


## The Stoic/Vulnerable answer given in a finished chapter ("" if none).
func answer_for(chapter: String) -> String:
	for entry in _finished:
		if entry.chapter == chapter:
			return entry.answer
	return ""


func settings() -> Dictionary:
	return _settings.duplicate(true)


## House state a finished chapter left (empty if none).
func house_state_for(chapter: String) -> Dictionary:
	for entry in _finished:
		if entry.chapter == chapter:
			return entry.get("house", {}).duplicate(true)
	return {}


## Whether there is a valid save to continue from. A broken or impossible
## save file doesn't count.
func has_save() -> bool:
	return _has_save


## Forgets all progress and deletes the save (a new game).
func start_new() -> void:
	_clear()
	_file.erase()
	last_save_ok = true
	progress_changed.emit()


## Everything that is saved, as written to the file.
func to_save_data() -> Dictionary:
	var finished: Array[Dictionary] = []
	for entry in _finished:
		finished.append(entry.duplicate(true))
	return {"finished": finished, "settings": _settings.duplicate(true)}


func _save() -> void:
	last_save_ok = _file.write(to_save_data())
	if last_save_ok:
		_has_save = true
	else:
		save_failed.emit()


func _clear() -> void:
	_has_save = false
	_finished.clear()
	_settings = {}


# "house" is left out when empty, as in the chapter result.
static func _entry(chapter: String, answer: String, house: Dictionary) -> Dictionary:
	var entry := {"chapter": chapter, "answer": answer}
	if not house.is_empty():
		entry.house = house.duplicate(true)
	return entry


static func _is_valid(data: Dictionary) -> bool:
	if not data.get("finished") is Array or not data.get("settings", {}) is Dictionary:
		return false
	var finished: Array = data.finished
	if finished.size() > ChapterList.STORY_ORDER.size():
		return false
	for i in finished.size():
		var entry: Variant = finished[i]
		if not entry is Dictionary or not ChapterResult.is_story_result(entry):
			return false
		if entry.chapter != String(ChapterList.STORY_ORDER[i]):
			return false
	return true
