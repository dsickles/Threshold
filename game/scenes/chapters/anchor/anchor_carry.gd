extends RefCounted
## The Anchor's carry, as numbers only (DAS-138): how far Leo has walked with
## the crib, how far he leans, the falls, Maya's line and the assist. No
## drawing, no sound and no input here, so the tests can play it on its own
## clock. anchor.gd draws it and feeds it the two hold zones.
##
## This is the scripted wobble, the cheap test the scope asks for
## (docs/scope.md, "Anchor: scripted wobble or real physics"): one lean
## value with momentum, tipped by the load's own weight, the wind and the
## clutter, and pushed back by the hold zones. No ragdoll. It always moves
## in fixed steps of STEP seconds (the physics step), however the frames
## fall, so it plays the same at any frame rate.
##
## The lean runs from -1 (fully over to the left) to 1 (fully right); at
## either end the crib touches the ground. A fall never ends the chapter:
## Leo picks the crib up and carries on from where he was. After the third
## fall Maya says "You've got this." and an invisible assist steadies him
## (FR28): no badge, no toast, no "Stability Assist ON.".

enum Stage { STEADY, STORM, SET_DOWN, DONE }

## The physics step, in seconds.
const STEP := 1.0 / 60.0

## Where the storm starts and where the crib is set down, in metres along
## the way from the front of the House to the living-room window.
const STORM_AT := 22.0
const LENGTH := 105.0
## Walking speed when upright, in metres a second. Leaning slows him down.
const WALK := 0.75
const LEAN_SLOWS := 0.7
const SLOWEST := 0.3

## How hard the load tips further the more it leans (per second squared,
## per unit of lean): the weight that makes it an act of balance.
const TIP_STEADY := 0.55
const TIP_STORM := 0.85
## How hard a held zone leans him (per second squared).
const PUSH := 2.4
## How quickly a swing dies down by itself (per second).
const DAMPING := 1.3
## The small wobble of walking with something big in your arms.
const WOBBLE_STEADY := 0.18
const WOBBLE_STORM := 0.32

## After a fall: the crib lies on the ground for FALLEN_TIME, then Leo lifts
## it back up over PICK_UP_TIME.
const FALLEN_TIME := 2.2
const PICK_UP_TIME := 1.0
## Maya speaks on the third fall.
const MAYA_AFTER_FALLS := 3
## How long after that fall lands her line comes, and how long it shows.
const MAYA_DELAY := 0.6
const MAYA_SHOWS := 4.5
const MAYA_LINE := "You've got this."

## The assist after the third fall: the load tips less, the wind and the
## clutter push less, and he steadies himself a little without being asked.
const ASSIST_TIP := 0.3
const ASSIST_PUSH_BACK := 1.6
const ASSIST_CALM := 1.2
const ASSIST_WIND := 0.5
## Each fall after the third steadies him a little more, so even a player who
## keeps pushing the wrong way gets there (FR28: never a hard reset wall).
const ASSIST_GROWS := 0.6
const ASSIST_MOST := 4.0

## Setting the crib down by the window takes this long; then the chapter ends.
const SET_DOWN_TIME := 4.0

## The storm, authored, the same every time: gusts of wind through the
## House, each [where it starts (m), how long it lasts (m), which way
## (-1 left, 1 right), how hard at its peak (per second squared)].
const GUSTS := [
	[26.0, 4.0, 1, 1.3],
	[33.0, 5.0, -1, 1.6],
	[41.0, 3.0, 1, 2.0],
	[47.0, 6.0, -1, 1.7],
	[56.0, 3.5, 1, 2.2],
	[61.0, 3.5, -1, 2.2],
	[69.0, 6.0, 1, 1.9],
	[78.0, 4.0, -1, 2.4],
	[84.0, 3.0, 1, 2.0],
	[90.0, 5.0, -1, 1.8],
]
## Clutter he steps over or knocks into: [where (m), which way it jolts the
## load, how hard (a sudden swing, per second)]. Two in the calm part, so
## the first jolts come before the wind.
const CLUTTER := [
	[9.0, 1, 0.35],
	[16.0, -1, 0.4],
	[29.0, -1, 0.6],
	[37.5, 1, 0.7],
	[52.0, -1, 0.75],
	[65.0, 1, 0.8],
	[74.0, -1, 0.7],
	[87.5, 1, 0.8],
	[96.0, -1, 0.6],
]

var stage := Stage.STEADY
## Seconds into the chapter (stops while paused, which anchor.gd handles).
var time := 0.0
## Metres walked.
var distance := 0.0
## -1 (all the way left) to 1 (all the way right).
var lean := 0.0
## How fast the lean is changing (per second).
var swing := 0.0
## -1 while the left zone is held, 1 while the right is, 0 for neither or both.
var hold := 0
var falls := 0
## When the last fall landed (chapter seconds), or -INF.
var fell_at := -INF
## The side the last fall went to.
var fell_to := 0
var assisted := false
## When Maya's line started (chapter seconds), or INF before it.
var maya_at := INF
var set_down_at := INF

var _carry := 0.0  # Time left over between physics steps.
var _clutter_done := 0


## Moves the carry on by `delta` seconds, in fixed physics steps.
func advance(delta: float) -> void:
	_carry += delta
	while _carry >= STEP - 0.000001 and stage != Stage.DONE:
		_carry -= STEP
		_step(STEP)


## -1 for the left zone, 1 for the right, 0 for none (or both at once).
func set_hold(side: int) -> void:
	hold = clampi(side, -1, 1)


func is_fallen() -> bool:
	return time - fell_at < FALLEN_TIME


func is_picking_up() -> bool:
	return not is_fallen() and time - fell_at < FALLEN_TIME + PICK_UP_TIME


## True while Leo is carrying and can lean (not on the ground, not lifting,
## not setting down, not finished).
func is_carrying() -> bool:
	return stage in [Stage.STEADY, Stage.STORM] and not is_fallen() and not is_picking_up()


## Maya's line while it shows, else "".
func subtitle() -> String:
	if time >= maya_at and time < maya_at + MAYA_SHOWS:
		return MAYA_LINE
	return ""


## 0 in the calm, rising to 1 over the first few metres of the storm, and
## easing off again as he reaches the window.
func storm() -> float:
	var rise := clampf((distance - STORM_AT) / 6.0, 0.0, 1.0)
	var settle := clampf((LENGTH - distance) / 8.0, 0.0, 1.0)
	if stage == Stage.SET_DOWN or stage == Stage.DONE:
		settle = 0.0
	return rise * lerpf(0.35, 1.0, settle)


## The wind on the load right now (per second squared, + is to the right).
func wind() -> float:
	var push := 0.0
	for gust: Array in GUSTS:
		var into: float = (distance - gust[0]) / gust[1]
		if into > 0.0 and into < 1.0:
			push += gust[2] * gust[3] * sin(PI * into)
	return push * (ASSIST_WIND if assisted else 1.0)


## How much a shiver shakes Leo's arms (0 to 1): small wobbles show as a
## nervous tremble instead of a twitch (story 7.2, "a shiver can cover a
## visible jitter").
func shiver() -> float:
	if not is_carrying():
		return 0.0
	return clampf((absf(lean) - 0.2) / 0.6, 0.0, 1.0) * 0.8 + 0.2 * storm()


## How hard the assist pulls him upright (0 before the third fall).
func assist_push_back() -> float:
	if not assisted:
		return 0.0
	return minf(ASSIST_PUSH_BACK + ASSIST_GROWS * (falls - MAYA_AFTER_FALLS), ASSIST_MOST)


## How far along the way he is, 0 to 1.
func progress() -> float:
	return clampf(distance / LENGTH, 0.0, 1.0)


func _step(dt: float) -> void:
	time += dt
	match stage:
		Stage.STEADY, Stage.STORM:
			_carry_step(dt)
		Stage.SET_DOWN:
			lean = move_toward(lean, 0.0, dt)
			swing = 0.0
			if time - set_down_at >= SET_DOWN_TIME:
				stage = Stage.DONE


func _carry_step(dt: float) -> void:
	if is_fallen():
		return
	if is_picking_up():
		# Lifting it back up: the lean comes home, nothing else moves.
		var left := FALLEN_TIME + PICK_UP_TIME - (time - fell_at)
		lean = lerpf(lean, 0.0, clampf(dt / maxf(left, dt), 0.0, 1.0))
		swing = 0.0
		return
	var storming := stage == Stage.STORM
	var tip := ASSIST_TIP if assisted else (TIP_STORM if storming else TIP_STEADY)
	var wobble := (WOBBLE_STORM if storming else WOBBLE_STEADY) * (ASSIST_WIND if assisted else 1.0)
	var force := tip * lean + wind() + hold * PUSH + wobble * _wobble(time)
	if assisted:
		force += -assist_push_back() * lean - ASSIST_CALM * swing
	swing += force * dt
	swing *= exp(-DAMPING * dt)
	lean += swing * dt
	if absf(lean) >= 1.0:
		_fall()
		return
	distance += WALK * maxf(1.0 - LEAN_SLOWS * absf(lean), SLOWEST) * dt
	while _clutter_done < CLUTTER.size() and distance >= CLUTTER[_clutter_done][0]:
		var bump: Array = CLUTTER[_clutter_done]
		swing += bump[1] * bump[2] * (ASSIST_WIND if assisted else 1.0)
		_clutter_done += 1
	if stage == Stage.STEADY and distance >= STORM_AT:
		stage = Stage.STORM
	if distance >= LENGTH:
		distance = LENGTH
		stage = Stage.SET_DOWN
		set_down_at = time


func _fall() -> void:
	fell_to = int(signf(lean))
	lean = clampf(lean, -1.0, 1.0)
	swing = 0.0
	falls += 1
	fell_at = time
	if falls == MAYA_AFTER_FALLS:
		maya_at = time + MAYA_DELAY
		assisted = true


## The walking wobble: a few slow, uneven swells, the same every time.
static func _wobble(t: float) -> float:
	return 0.6 * sin(t * 1.7) + 0.3 * sin(t * 3.1 + 1.3) + 0.25 * sin(t * 0.53 + 0.4)
