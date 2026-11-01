extends Node
## The Protector (the Loss), rough M1 playable (DAS-97): the run, then the
## car. Design: docs/design/the-loss-run-and-car.md (Dan, 2026-10-25).
##
## Starts straight into the run: no warning, no title card, no skip. Nothing
## the player does ends it early or changes how it ends; there is no retry.
## The chapter only reports that it finished (no Stoic/Vulnerable answer),
## and never touches the House or saved state: the chapter runner and the
## core table do that. Leaving part-way gives no result, so the next visit
## starts again from the lamp.

signal finished

const ProtectorRun := preload("res://scenes/chapters/protector/protector_run.gd")

var _run: ProtectorRun


func _ready() -> void:
	_run = ProtectorRun.new()
	_run.name = "Run"
	add_child(_run)
	# Browser tests can start part-way in (see web_test_probe.gd).
	var from: float = get_tree().root.get_meta("protector_start_from", 0.0)
	if from > 0.0:
		_run.start_from(from)
	_run.ended.connect(_on_run_ended)


func run() -> ProtectorRun:
	return _run


func _on_run_ended() -> void:
	# PLACEHOLDER: the car (the Silence) goes here, from the black at 2:45,
	# and the chapter finishes only when the player goes in through the
	# front door (DAS-98). Until then it finishes at the black.
	finished.emit()


## Pauses the run until the next tap (the "Turn your phone sideways" screen).
func pause() -> void:
	_run.pause()


func probe_state() -> Dictionary:
	return _run.probe_state()


## Seconds into the run, for the playtest overlay's clock.
func playtest_time() -> float:
	return _run.time()
