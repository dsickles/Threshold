extends RefCounted
## The Arrival's cry beat (DAS-137), as plain numbers, so it can be tested
## without a screen or sound. The same search as the Tuner's
## (scenes/chapters/tuner/tuner_signal.gd), copied and cut down to one
## signal: the player already knows the knobs, so there is no false signal
## this time, only the cry. Two knobs, each 0 to 1; the closer both are to
## the cry, the more of it comes through the static. Stages, in order
## (docs/design/story-beats.md §8, beat 2):
##
##   SEARCH    static; the cry is faint somewhere on the dials
##   THROUGH   the cry, and the static clears (the same clearing as the Tuner)
##   DONE      the cry has been held clear; the hand beat follows
##
## Nothing here can fail. The longer the search goes on, the wider the lock
## gets, and later the cry drifts towards wherever the knobs are, so a player
## who never finds it (or never touches the knobs) still comes through
## (FR33). The help comes sooner than in the Tuner: the knobs are learned.

enum Stage { SEARCH, THROUGH, DONE }

## Where the knobs start, and where the cry sits on the two dials.
const KNOBS_START := Vector2(0.15, 0.85)
const CRY_AT := Vector2(0.72, 0.38)

## How far from the cry a knob still hears some of it (on each dial).
const NEAR := 0.35
## How close both knobs must be, and for how long, to lock on.
const LOCK_WITHIN := 0.05
const LOCK_HOLD := 1.2
## The help: after ASSIST_AFTER seconds the lock widens, up to ASSIST_WITHIN
## by ASSIST_FULL; after DRIFT_AFTER the cry also moves towards the knobs at
## DRIFT_SPEED (dial units a second).
const ASSIST_AFTER := 25.0
const ASSIST_FULL := 60.0
const ASSIST_WITHIN := 0.2
const DRIFT_AFTER := 50.0
const DRIFT_SPEED := 0.02

const CLEAR_TIME := 4.0  # The static clearing.
const HOLD_TIME := 5.0  # The cry, held clear, before the hand beat.

var stage := Stage.SEARCH
var knobs := KNOBS_START
var target := CRY_AT
## Seconds since the beat began (only while not paused).
var time := 0.0
## Seconds into the current stage.
var stage_time := 0.0
## 0 (all static) to 1 (clear). Rises only once THROUGH.
var clarity := 0.0

var _held := 0.0  # Seconds both knobs have been within the lock.


func set_knob(which: int, value: float) -> void:
	if stage != Stage.SEARCH:
		return  # Through is through: the cry can't be lost again.
	knobs[which] = clampf(value, 0.0, 1.0)


func distances() -> Vector2:
	return (knobs - target).abs()


## 0 to 1: how much of the cry comes through the static at the knobs. Each
## knob counts for half, so turning either one is heard.
func strength() -> float:
	if stage != Stage.SEARCH:
		return 1.0
	var d := distances()
	return (_near(d.x) + _near(d.y)) / 2.0


static func _near(d: float) -> float:
	return pow(clampf(1.0 - d / NEAR, 0.0, 1.0), 2.0)


## How close both knobs must be to lock on, now: wider the longer the search
## has gone on.
func lock_within() -> float:
	if stage != Stage.SEARCH:
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
		Stage.SEARCH:
			if stage_time > DRIFT_AFTER:
				target = target.move_toward(knobs, DRIFT_SPEED * delta)
			_held = _held + delta if is_on_signal() else 0.0
			if _held >= LOCK_HOLD:
				_go(Stage.THROUGH)
		Stage.THROUGH:
			clarity = clampf(stage_time / CLEAR_TIME, 0.0, 1.0)
			if stage_time >= CLEAR_TIME + HOLD_TIME:
				_go(Stage.DONE)


func _go(next: Stage) -> void:
	stage = next
	stage_time = 0.0
	_held = 0.0
