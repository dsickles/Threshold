extends RefCounted
## The Protector's run as one fixed timeline (docs/design/the-loss-run-and-car.md,
## "The run, part by part"): when each part starts, the hand-built obstacle
## list and the lanes each one blocks, how far ahead a gap can be bridged,
## where the light is, how big and how bright. Nothing here is random and
## nothing the player does moves the timeline, so every player gets the same
## run and the same fade.
##
## Times are seconds from the lamp click. The run scene (protector_run.gd)
## draws this; the tests check it.

enum Part { DARK, EUPHORIA, CONFUSION, PANIC, FADE }
enum Kind { STONE, BRANCH, GAP }

# Shortened to about 2:45 after Dan's fourth play (call 20).
const EUPHORIA_START := 3.0
const CONFUSION_START := 63.0
const PANIC_START := 103.0
const FADE_START := 128.0  # 2:08: the obstacles stop; the song is gone under the rain.
const SLOW_START := 140.0  # 2:20: the light slows as it comes to the fallen tree.
const STOPPED := 142.0  # 2:22: it has stopped against the tree; the hand comes under it.
const HELD := 145.0  # 2:25: it is in his hand, and goes out.
const OUT := 155.0  # 2:35: it is out; the empty hand.
const BLACK := 165.0  # 2:45: black. The car begins (DAS-98).
const RAIN_START := 83.0  # 1:23: the first rain. It never stops (call 15).
const HEAVY_RAIN := 103.0

## The three lanes, in tiles from the middle. The light starts in the middle.
const LANES := [-1, 0, 1]
const LANE_MOVE := 0.25  # Seconds the hand takes to move the light across.

## How long before a gap would touch the light the hand can be laid across
## it, by the part it touches in. Choice, to tune in playtests: generous on
## purpose. Stones and branches have no reach: what counts is the lane.
const REACH := {
	Part.EUPHORIA: 1.3,
	Part.CONFUSION: 1.0,
	Part.PANIC: 1.0,  # 0.8 until call 20: the end of the storm is a little easier.
}

const SPEED := 9.0  # Metres a second, the same all run until it slows.
const STUMBLE_DIM := 0.45  # The light's brightness at the start of a stumble.
const STUMBLE_TIME := 0.6  # How long until it is fully bright again.
const SEED_SIZE := 0.2  # As small as the fridge note's sesame seed, at first.

# Each obstacle is "kind:lanes": S stone, B branch, G gap (all three lanes);
# lanes L, M, R. "S:LR" is two stones at once, left and right.
# The euphoria's land on the song's beat: 90 BPM, one every 2 bars (16/3 s),
# from 0:11. The song starts on a bar line at 0:03.
const BEAT_START := 11.0
const TWO_BARS := 16.0 / 3.0
const EUPHORIA := ["S:M", "S:LR", "B:LM", "S:R", "G", "B:MR", "S:L", "G", "B:LM"]
# Confusion: off the beat and at uneven gaps. Panic: clusters 0.8 s apart,
# each with one lane free all the way through, thinning out to a single
# stone at the end (call 20).
const CONFUSION := [
	[67.0, "S:LM"], [71.0, "G"], [76.0, "B:MR"], [79.0, "S:L"], [84.0, "S:R"], [86.0, "B:LM"],
	[91.0, "G"], [94.0, "S:MR"], [97.0, "B:LM"], [100.0, "G"],
]
const CLUSTER_GAP := 0.8
const PANIC := [
	[105.0, ["S:L", "S:R"]], [108.0, ["B:LM", "S:M", "G"]], [113.0, ["G", "S:R"]],
	[117.0, ["S:M", "B:MR"]], [121.0, ["B:LM", "G"]], [125.0, ["S:R"]],
]
# The hints, in Dan's words (call 20): "tap here" on both halves until the
# second obstacle has passed, and "hold" for the first two gaps only.
const TAP_HINT := "tap here"
const HOLD_HINT := "hold"
const HOLD_HINT_GAPS := 2
const HINT_LEAD := 1.0  # The "hold" shows this long before its gap is in reach.
const HINT_AFTER := 0.3  # And until this long after it has passed the light.
# The fireflies left along the trail when the path empties (call 18): how far
# each sits from where the light comes to rest (metres along the path), how
# far to the side (metres, + right), how high, and when it goes out (-1:
# never). Hand-placed so the order looks random but is the same every time:
# one, then one far off, then two close together; some never go out, and one
# is still glowing beside the hand as the light goes out. The ones beyond
# the fallen tree are high enough to be seen over it.
const LAST_FIREFLIES := [
	[-95.0, -3.2, 0.9, 130.25], [-45.0, 4.0, 1.6, 133.4], [-63.0, -4.5, 2.2, 134.5],
	[10.0, 3.0, 2.4, 138.6], [-9.0, -2.8, 1.2, 140.6], [23.0, -5.5, 2.6, 143.75],
	[15.0, 5.0, 2.4, 144.3], [-4.0, 2.8, 0.6, 148.7], [29.0, 1.5, 3.0, 151.85],
	[-105.0, 3.5, 1.1, -1.0], [-2.0, -2.6, 0.9, -1.0], [18.0, 3.6, 2.2, -1.0], [35.0, -3.8, 2.6, -1.0],
]
const FIREFLY_OUT_TIME := 0.8  # Seconds a firefly takes to go out.
const KINDS := {"S": Kind.STONE, "B": Kind.BRANCH, "G": Kind.GAP}
const LANE_NAMES := {"L": -1, "M": 0, "R": 1}


## Every obstacle in the run, in order: {"time": when it would touch the
## light, "kind": Kind, "lanes": the lanes it blocks, "part": Part}.
static func obstacles() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k in EUPHORIA.size():
		out.append(_obstacle(BEAT_START + k * TWO_BARS, EUPHORIA[k]))
	for entry: Array in CONFUSION:
		out.append(_obstacle(entry[0], entry[1]))
	for cluster: Array in PANIC:
		var each: Array = cluster[1]
		for k in each.size():
			out.append(_obstacle(cluster[0] + k * CLUSTER_GAP, each[k]))
	return out


static func _obstacle(time: float, spec: String) -> Dictionary:
	var kind: Kind = KINDS[spec[0]]
	var lanes: Array[int] = []
	if kind == Kind.GAP:
		lanes.assign(LANES)
	else:
		for name in spec.get_slice(":", 1):
			lanes.append(LANE_NAMES[name])
	return {"time": time, "kind": kind, "lanes": lanes, "part": part_at(time)}


## The lanes an obstacle leaves free. A gap leaves none: only the hand gets
## the light across it.
static func free_lanes(obstacle: Dictionary) -> Array[int]:
	var out: Array[int] = []
	for lane: int in LANES:
		if not lane in obstacle.lanes:
			out.append(lane)
	return out


static func part_at(t: float) -> Part:
	if t < EUPHORIA_START:
		return Part.DARK
	if t < CONFUSION_START:
		return Part.EUPHORIA
	if t < PANIC_START:
		return Part.CONFUSION
	if t < FADE_START:
		return Part.PANIC
	return Part.FADE


static func reach(part: Part) -> float:
	return REACH.get(part, 0.0)


## How far the light has run along the path at time t, in metres. It depends
## on the time only: a stumble never slows it, stops it or loses it ground.
static func distance(t: float) -> float:
	if t <= EUPHORIA_START:
		return 0.0
	if t <= SLOW_START:
		return SPEED * (t - EUPHORIA_START)
	# Slows evenly to a stop against the fallen tree.
	var slow := STOPPED - SLOW_START
	var s := minf(t, STOPPED) - SLOW_START
	return SPEED * (SLOW_START - EUPHORIA_START) + SPEED * (s - s * s / (2.0 * slow))


## The light's brightness from the timeline alone, 0 to 1: it fades up out of
## the black, is full all run, and goes out in the hand from 2:25 to 2:35.
static func base_brightness(t: float) -> float:
	if t < EUPHORIA_START:
		return 0.0
	if t < EUPHORIA_START + 2.0:
		return smoothstep(EUPHORIA_START, EUPHORIA_START + 2.0, t)
	if t < HELD:
		return 1.0
	return 1.0 - smoothstep(HELD, OUT, t)


## How big the light is: as small as a sesame seed when it fades up, grown
## by the end of the euphoria, then shrinking to nothing as it goes out.
static func light_size(t: float) -> float:
	var grown := lerpf(SEED_SIZE, 1.0, smoothstep(EUPHORIA_START, CONFUSION_START, t))
	return grown * (1.0 - smoothstep(HELD, OUT, t))


## The dimming a stumble at `stumbled_at` causes at time t: 1 is none. It is
## gone after STUMBLE_TIME, so nothing carries over to the next obstacle.
static func stumble_factor(t: float, stumbled_at: float) -> float:
	var since := t - stumbled_at
	if since < 0.0 or since >= STUMBLE_TIME:
		return 1.0
	return lerpf(STUMBLE_DIM, 1.0, since / STUMBLE_TIME)


## How brightly a last firefly glows at time t, 1 to 0: full until its time,
## then out over FIREFLY_OUT_TIME. One that never goes out stays at 1.
static func firefly_glow(firefly: Array, t: float) -> float:
	var out_at: float = firefly[3]
	if out_at < 0.0:
		return 1.0
	return 1.0 - smoothstep(out_at, out_at + FIREFLY_OUT_TIME, t)


## How many of the fireflies between the trees are out at time t, 0 to 1:
## all of them in the euphoria, fewer as the storm comes, none once the path
## is empty (only the last ones are left then).
static func firefly_density(t: float) -> float:
	if t < CONFUSION_START:
		return 1.0
	var thinned := CONFUSION_START + 28.0
	if t < thinned:
		return lerpf(1.0, 0.35, smoothstep(CONFUSION_START, thinned, t))
	if t < PANIC_START + 8.0:
		return lerpf(0.35, 0.08, smoothstep(thinned, PANIC_START + 8.0, t))
	return 0.08 if t < FADE_START else 0.0


static var _hint_list: Array[Dictionary] = []


## The hints on screen at time t (call 20): TAP_HINT from the fade-up until
## the second obstacle has passed, HOLD_HINT around the first two gaps.
## Each is [text, how visible, 0 to 1].
static func hints(t: float) -> Array:
	var out := []
	if _hint_list.is_empty():
		_hint_list = obstacles()  # Built once: this runs every frame.
	var list := _hint_list
	var tap_end: float = list[1].time + HINT_AFTER
	var tap := smoothstep(EUPHORIA_START + 1.0, EUPHORIA_START + 1.6, t) \
			* (1.0 - smoothstep(tap_end, tap_end + 0.4, t))
	if tap > 0.0:
		out.append([TAP_HINT, tap])
	var gaps := 0
	for obstacle in list:
		if obstacle.kind != Kind.GAP:
			continue
		gaps += 1
		if gaps > HOLD_HINT_GAPS:
			break
		var from: float = obstacle.time - reach(obstacle.part) - HINT_LEAD
		var to: float = obstacle.time + HINT_AFTER
		var hold := smoothstep(from, from + 0.3, t) * (1.0 - smoothstep(to, to + 0.4, t))
		if hold > 0.0:
			out.append([HOLD_HINT, hold])
	return out
