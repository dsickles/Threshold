class_name SaveFile
extends RefCounted
## Reads and writes the one save file as JSON under user:// (ADR-0007).
## In the browser, Godot keeps user:// in the page's IndexedDB; on PC it is a
## normal file. GameState decides what goes in it and when; this only stores it.

## Where the game's save lives. Tests pass their own path.
const DEFAULT_PATH := "user://save.json"

var path: String


func _init(save_path: String = DEFAULT_PATH) -> void:
	path = save_path


## Writes the data. Returns false if it could not be kept: the file could not
## be written, or the browser has no lasting storage (private browsing, a
## blocked frame). Writes a temporary file first, so a failed write never
## leaves half a save behind.
func write(data: Dictionary) -> bool:
	if not OS.is_userfs_persistent():
		return false
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	var ok := file.get_error() == OK
	file.close()
	if not ok:
		DirAccess.remove_absolute(temp)
		return false
	return DirAccess.rename_absolute(temp, path) == OK


## The saved data, or an empty Dictionary if there is no save or it can't be
## read as JSON. Never errors: an unreadable save counts as no save.
func read() -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return {}
	return json.data


func exists() -> bool:
	return FileAccess.file_exists(path)


func erase() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
