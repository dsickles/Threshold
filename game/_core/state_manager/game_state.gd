extends Node
## The finished-chapter list: which chapters the player has finished, in
## order, with the Stoic/Vulnerable answer each gave (if any). It is the only
## story state that is saved; story facts, House mood and journal entries are
## looked up from it by the core table (game-architecture 2.1). Settings are
## saved alongside it. Autoloaded as GameState.
##
## Saves only when a chapter finishes: the chapter framework (the Chapters
## autoload) emits chapter_finished once the House is back, and that is
## recorded here. Leaving a chapter early, hiding the tab or closing it
## mid-chapter saves nothing. Storage and the save format: ADR-0007.

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

var _finished: Array[Dictionary] = []
var _settings := {}
var _file := SaveFile.new()


func _ready() -> void:
	load_save()
	# Deferred, so the Chapters autoload is there whichever order autoloads
	# load in, and looked up by path so this file doesn't depend on it.
	_connect_to_chapters.call_deferred()


func _connect_to_chapters() -> void:
	var chapters := get_node_or_null("/root/Chapters")
	if chapters != null and chapters.has_signal("chapter_finished"):
		chapters.connect("chapter_finished", _on_chapter_finished)


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
	for entry: Dictionary in data.finished:
		_finished.append({"chapter": entry.chapter, "answer": entry.get("answer", "")})
	_settings = data.get("settings", {})
	progress_changed.emit()
	return true


## Records a finished chapter and saves. The result is the chapter
## framework's: {"chapter": "partner", "answer": ""} where answer is "",
## "stoic" or "vulnerable". The chapter must be the next one in story order;
## finishing one that is already finished changes nothing.
## Returns whether the save was kept (false also means a bad result).
func record_chapter_result(result: Dictionary) -> bool:
	var chapter: String = str(result.get("chapter", ""))
	var answer: String = str(result.get("answer", ""))
	if is_finished(chapter):
		return last_save_ok
	if chapter != next_chapter():
		push_warning("GameState: '%s' is not the next chapter (expected '%s')." % [chapter, next_chapter()])
		return false
	if not answer in ANSWERS:
		push_warning("GameState: bad answer for '%s': '%s'" % [chapter, answer])
		return false
	_finished.append({"chapter": chapter, "answer": answer})
	progress_changed.emit()
	return _save()


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


## Whether there is a save to continue from.
func has_save() -> bool:
	return _file.exists()


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


# Test-only chapters (such as the menu's stand-in) aren't story chapters and
# are never saved.
func _on_chapter_finished(result: Dictionary) -> void:
	if str(result.get("chapter", "")) in STORY_ORDER:
		record_chapter_result(result)


func _save() -> bool:
	last_save_ok = _file.write(to_save_data())
	if not last_save_ok:
		save_failed.emit()
	return last_save_ok


func _clear() -> void:
	_finished.clear()
	_settings = {}


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
		if not entry.get("answer", "") in ANSWERS:
			return false
	return true
