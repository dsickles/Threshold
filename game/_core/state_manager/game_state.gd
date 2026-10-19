extends Node
## The finished-chapter list: which chapters the player has finished, in
## order, with the Stoic/Vulnerable answer each gave (if any). It is the only
## story state that is saved; story facts, House mood and journal entries are
## looked up from it by the core table (game-architecture 2.1). Settings, and
## any House state a chapter hands back that the core table can't look up,
## are saved alongside it. Autoloaded as GameState.
##
## Saves only when a chapter finishes, in record_chapter_result. Pending
## DAS-75: the chapter runner's chapter_finished signal is not connected to it
## yet; the chapter framework PR adds that line. Leaving a chapter early,
## hiding the tab or closing it mid-chapter saves nothing. Storage and the
## save format: ADR-0007.

## Emitted after a chapter is added to the finished-chapter list.
signal progress_changed
## Emitted when a save could not be kept, so the game can show
## "Couldn't save." and carry on.
signal save_failed

## Every chapter, in story order. Players always meet them in this order, so
## the finished-chapter list is always the start of it.
const STORY_ORDER: Array[String] = [
	"partner", "protector", "novice", "provider",
	"tuner", "anchor", "mourner", "arrival",
]
const ANSWERS: Array[String] = ["", "stoic", "vulnerable"]

## Whether the last save was kept. True until a save fails.
var last_save_ok := true

# Whether a valid save is on disk: one was loaded or written.
var _has_save := false

var _finished: Array[Dictionary] = []
var _settings := {}
var _file := SaveFile.new()


func _ready() -> void:
	load_save()


## Uses a different save file (tests use their own). Clears what is in
## memory; call load_save() to read the new file.
func use_save_file(file: SaveFile) -> void:
	_file = file
	_clear()


## Reads the save, replacing what is in memory. A save that is missing,
## unreadable or impossible (chapters out of story order, unknown chapters or
## answers) counts as no save: the game starts fresh. Returns whether a save
## was loaded.
func load_save() -> bool:
	_clear()
	var data := _file.read()
	if data.is_empty() or not _is_valid(data):
		return false
	_has_save = true
	for entry: Dictionary in data.finished:
		_finished.append(_entry(entry.chapter, entry.get("answer", ""), entry.get("house", {})))
	_settings = data.get("settings", {})
	progress_changed.emit()
	return true


## Records a finished chapter and saves. The result is the chapter
## framework's: {"chapter": "partner", "answer": ""} where answer is "",
## "stoic" or "vulnerable", plus "house" (a Dictionary) only when the chapter
## leaves House state. The chapter must be the next one in story order;
## finishing one that is already finished changes nothing, and test-only
## chapters (not in STORY_ORDER, like the menu's stand-in) are never saved.
## Returns whether the chapter was recorded (false: refused, or already
## finished). Whether the save was kept is separate: see last_save_ok and
## save_failed, since a chapter is recorded and play carries on even when the
## save can't be written.
func record_chapter_result(result: Dictionary) -> bool:
	var chapter: String = str(result.get("chapter", ""))
	var answer: String = str(result.get("answer", ""))
	var house: Variant = result.get("house", {})
	if not chapter in STORY_ORDER:
		return false
	if is_finished(chapter):
		return false
	if chapter != next_chapter():
		push_warning("GameState: '%s' is not the next chapter (expected '%s')." % [chapter, next_chapter()])
		return false
	if not answer in ANSWERS or not house is Dictionary:
		push_warning("GameState: bad result for '%s': %s" % [chapter, result])
		return false
	_finished.append(_entry(chapter, answer, house))
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
	return STORY_ORDER[_finished.size()] if _finished.size() < STORY_ORDER.size() else ""


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
	if finished.size() > STORY_ORDER.size():
		return false
	for i in finished.size():
		var entry: Variant = finished[i]
		if not entry is Dictionary:
			return false
		if entry.get("chapter") != STORY_ORDER[i]:
			return false
		if not entry.get("answer", "") in ANSWERS or not entry.get("house", {}) is Dictionary:
			return false
	return true
