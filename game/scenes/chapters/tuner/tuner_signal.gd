extends RefCounted
## The Tuner's search, as plain numbers, so it can be tested without a
## screen or sound (DAS-135). Two knobs, each 0 to 1. Somewhere on the two
## dials is a signal; the closer both knobs are to it, the stronger it comes
## through. Beats, in order (docs/design/story-beats.md §5):
##
##   SEARCH_HUM   static; the only signal to find is the fridge's hum
##   HUM          the false signal: a steady rhythm through the static
##   HUM_LOST     the fridge clicks off; static again
##   SEARCH_BABY  closer, a faster pulse under the noise
##   THROUGH      the heartbeat, and the picture clears. The only ending.
##   DONE         the picture has been held; the chapter finishes
##
## Nothing here can fail. The longer a search goes on, the wider the signal
## gets, and later it drifts towards wherever the knobs are, so a player who
## never finds it (or never touches the knobs) still comes through
## (FR33: minigames adapt so the player can finish the story).

enum Stage { SEARCH_HUM, HUM, HUM_LOST, SEARCH_BABY, THROUGH, DONE }

## Where the knobs start, and where each signal sits on the two dials. Far
## enough apart that finding the hum doesn't also find the heartbeat.
const KNOBS_START := Vector2(0.1, 0.9)
const HUM_AT := Vector2(0.68, 0.3)
const BABY_AT := Vector2(0.27, 0.78)

## How far from the signal a knob still hears some of it (on each dial).
const NEAR := 0.35
## How close both knobs must be, and for how long, to lock onto a signal.
const LOCK_WITHIN := 0.04
const LOCK_HOLD := 1.5
## The help, per search: after ASSIST_AFTER seconds the lock widens, up to
## ASSIST_WITHIN by ASSIST_FULL; after DRIFT_AFTER the signal also moves
## towards the knobs at DRIFT_SPEED (dial units a second).
const ASSIST_AFTER := 40.0
const ASSIST_FULL := 100.0
const ASSIST_WITHIN := 0.2
const DRIFT_AFTER := 90.0
const DRIFT_SPEED := 0.015

## How long each timed beat lasts (seconds).
const HUM_TIME := 12.0
const HUM_LOST_TIME := 2.5
const CLEAR_TIME := 5.0  # The static clearing to the picture.
const PICTURE_TIME := 18.0  # The picture and the heartbeat, held.

var stage := Stage.SEARCH_HUM
var knobs := KNOBS_START
var target := HUM_AT
## Seconds since the chapter began (only while not paused).
var time := 0.0
## Seconds into the current beat.
var stage_time := 0.0
## 0 (all static) to 1 (the picture is clear). Rises only in THROUGH.
var clarity := 0.0
## Each time a stage starts: [stage, time].
var history: Array = [[Stage.SEARCH_HUM, 0.0]]

var _held := 0.0  # Seconds both knobs have been within the lock.


func set_knob(which: int, value: float) -> void:
	if stage >= Stage.THROUGH:
		return  # Through is through: the picture can't be lost again.
	knobs[which] = clampf(value, 0.0, 1.0)


func is_searching() -> bool:
	return stage == Stage.SEARCH_HUM or stage == Stage.SEARCH_BABY


## The signal being searched for (or playing) now: the hum, the heartbeat or
## none.
func signal_kind() -> StringName:
	match stage:
		Stage.SEARCH_HUM, Stage.HUM:
			return &"hum"
		Stage.SEARCH_BABY, Stage.THROUGH, Stage.DONE:
			return &"heartbeat"
	return &""


## How close the knobs are to the signal, on each dial (0 means on it).
func distances() -> Vector2:
	return (knobs - target).abs()


## 0 to 1: how much of the signal comes through the static at the knobs.
## Each knob counts for half, so turning either one is heard.
func strength() -> float:
	match stage:
		Stage.HUM_LOST:
			return 0.0
		Stage.THROUGH, Stage.DONE:
			return 1.0
	var d := distances()
	return (_near(d.x) + _near(d.y)) / 2.0


static func _near(d: float) -> float:
	return pow(clampf(1.0 - d / NEAR, 0.0, 1.0), 2.0)


## How close both knobs must be to lock on, now: wider the longer the
## search has gone on.
func lock_within() -> float:
	if not is_searching():
		return LOCK_WITHIN
	var help := clampf((stage_time - ASSIST_AFTER) / (ASSIST_FULL - ASSIST_AFTER), 0.0, 1.0)
	return lerpf(LOCK_WITHIN, ASSIST_WITHIN, help)


func is_on_signal() -> bool:
	var d := distances()
	return maxf(d.x, d.y) <= lock_within()


## Moves the search on by `delta` seconds.
func advance(delta: float) -> void:
	if stage == Stage.DONE:
		return
	time += delta
	stage_time += delta
	match stage:
		Stage.SEARCH_HUM, Stage.SEARCH_BABY:
			if stage_time > DRIFT_AFTER:
				target = target.move_toward(knobs, DRIFT_SPEED * delta)
			_held = _held + delta if is_on_signal() else 0.0
			if _held >= LOCK_HOLD:
				_go(Stage.HUM if stage == Stage.SEARCH_HUM else Stage.THROUGH)
		Stage.HUM:
			if stage_time >= HUM_TIME:
				_go(Stage.HUM_LOST)
		Stage.HUM_LOST:
			if stage_time >= HUM_LOST_TIME:
				target = BABY_AT
				_go(Stage.SEARCH_BABY)
		Stage.THROUGH:
			clarity = clampf(stage_time / CLEAR_TIME, 0.0, 1.0)
			if stage_time >= CLEAR_TIME + PICTURE_TIME:
				_go(Stage.DONE)


func _go(next: Stage) -> void:
	stage = next
	stage_time = 0.0
	_held = 0.0
	history.append([next, time])
