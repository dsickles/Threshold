extends SceneTree
## Runs every test file in game/tests/ (test_*.gd) headless and exits non-zero
## if any test fails or any script error is printed while it runs.
## Run by tools/test.sh and tools/test.ps1 (and so by CI):
##   godot --headless --path game --script res://tests/run_tests.gd
## Add "-- <words>" to run only tests whose file or method name contains them:
##   godot --headless --path game --script res://tests/run_tests.gd -- rhythm

const TESTS_DIR := "res://tests/"
const DEFAULT_SCREEN := Vector2i(1280, 720)


# Catches script and engine errors, which otherwise only print and let the
# test carry on as if nothing happened.
class ErrorCatcher extends Logger:
	var errors := PackedStringArray()
	var _mutex := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String,
			rationale: String, _editor_notify: bool, error_type: int,
			_script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		var text := rationale if rationale != "" else code
		_mutex.lock()
		errors.append("%s (%s:%d in %s)" % [text, file, line, function])
		_mutex.unlock()

	func take() -> PackedStringArray:
		_mutex.lock()
		var taken := errors
		errors = PackedStringArray()
		_mutex.unlock()
		return taken


var _catcher := ErrorCatcher.new()


func _initialize() -> void:
	OS.add_logger(_catcher)
	_run.call_deferred()


func _run() -> void:
	var filter := " ".join(OS.get_cmdline_user_args()).to_lower()
	var passed := 0
	var failed := PackedStringArray()
	for path in _test_files():
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			failed.append(path)
			print("FAIL ", path, "\n       could not load")
			continue
		for method in _test_methods(script):
			var name := "%s %s" % [path.get_file().get_basename(), method]
			if filter != "" and not filter in name.to_lower():
				continue
			var problems := await _run_one(script, method)
			if problems.is_empty():
				passed += 1
				print("ok   ", name)
			else:
				failed.append(name)
				print("FAIL ", name)
				for problem in problems:
					print("       ", problem)
	print("%d passed, %d failed." % [passed, failed.size()])
	if passed == 0 and failed.is_empty():
		print("No tests matched.")
		quit(1)
		return
	quit(0 if failed.is_empty() else 1)


func _run_one(script: GDScript, method: String) -> PackedStringArray:
	_catcher.take()
	root.size = DEFAULT_SCREEN
	await process_frame
	var made: Object = script.new()
	if not made is TestCase:
		if not made is RefCounted:
			made.free()
		return PackedStringArray(["the file does not start with: extends TestCase"])
	var test: TestCase = made
	root.add_child(test)
	test.before_each()
	await test.call(method)
	test.after_each()
	var problems := test.failures()
	var expected := test.expected_errors()
	# Scenes the test changed to (with change_scene_to_file) don't belong to it.
	if current_scene != null and current_scene != test:
		current_scene.free()
	test.free()
	await process_frame  # Let anything queued for deletion go.
	problems.append_array(_unexpected(_catcher.take(), expected))
	return problems


# Errors a test said it expects (TestCase.expect_error) don't fail it; an
# expected error that never appeared does.
func _unexpected(errors: PackedStringArray, expected: PackedStringArray) -> PackedStringArray:
	var problems := PackedStringArray()
	var seen := {}
	for error in errors:
		var matched := false
		for text in expected:
			if text in error:
				seen[text] = true
				matched = true
		if not matched:
			problems.append(error)
	for text in expected:
		if not seen.has(text):
			problems.append("expected an error containing \"%s\", but none was printed" % text)
	return problems


func _test_files() -> PackedStringArray:
	var files := PackedStringArray()
	for file in DirAccess.get_files_at(TESTS_DIR):
		if file.begins_with("test_") and file.ends_with(".gd"):
			files.append(TESTS_DIR + file)
	files.sort()
	return files


func _test_methods(script: GDScript) -> PackedStringArray:
	var methods := PackedStringArray()
	for info in script.get_script_method_list():
		var method: String = info.name
		if method.begins_with("test_") and not method in methods:
			methods.append(method)
	return methods
