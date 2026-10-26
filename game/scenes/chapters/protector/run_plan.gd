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

const EUPHORIA_START := 5.0
const CONFUSION_START := 85.0
const PANIC_START := 135.0
const FADE_START := 165.0  # 2:45: the obstacles stop; the song is gone under the rain.
const SLOW_START := 175.0  # 2:55: the light slows, and the father's hand comes under it.
const STOPPED := 185.0  # 3:05: it has stopped in his hand, and goes out.
const OUT := 195.0  # 3:15: it is out; the empty hand.
const BLACK := 205.0  # 3:25: black. The car begins (DAS-98).
const RAIN_START := 110.0  # 1:50: the first rain. It never stops (call 15).
const HEAVY_RAIN := 135.0

## The three lanes, in tiles from the middle. The light starts in the middle.
const LANES := [-1, 0, 1]
const LANE_MOVE := 0.25  # Seconds the hand takes to move the light across.

## How long before a gap would touch the light the hand can be laid across
## it, by the part it touches in. Choice, to tune in playtests: generous on
## purpose. Stones and branches have no reach: what counts is the lane.
const REACH := {
	Part.EUPHORIA: 1.3,
	Part.CONFUSION: 1.0,
	Part.PANIC: 0.8,
}

const SPEED := 9.0  # Metres a second, the same all run until it slows.
const STUMBLE_DIM := 0.45  # The light's brightness at the start of a stumble.
const STUMBLE_TIME := 0.6  # How long until it is fully bright again.
const SEED_SIZE := 0.2  # As small as the fridge note's sesame seed, at first.

# Each obstacle is "kind:lanes": S stone, B branch, G gap (all three lanes);
# lanes L, M, R. "S:LR" is two stones at once, left and right.
# The euphoria's land on the song's beat: 90 BPM, one every 2 bars (16/3 s),
# from 0:13. The song starts on a bar line at 0:05.
const BEAT_START := 13.0
const TWO_BARS := 16.0 / 3.0
const EUPHORIA := ["S:M", "S:LR", "B:LM", "S:R", "G", "B:MR", "S:L", "G", "B:LM", "S:M", "G", "S:LR"]
# Confusion: off the beat and at uneven gaps. Panic: clusters 0.6 s apart,
# each with one lane free all the way through.
const CONFUSION := [
	[89.0, "S:LM"], [93.0, "G"], [99.0, "B:MR"], [102.0, "S:L"], [108.0, "S:R"], [110.0, "B:LM"],
	[116.0, "G"], [119.0, "S:MR"], [122.0, "B:LM"], [126.0, "G"], [129.0, "S:LR"], [133.0, "G"],
]
const CLUSTER_GAP := 0.6
const PANIC := [
	[137.0, ["S:L", "S:R"]], [140.0, ["B:LM", "S:M", "G"]], [145.0, ["G", "S:R"]],
	[148.0, ["S:M", "B:MR", "S:M"]], [152.0, ["B:LM", "G"]], [156.0, ["S:R", "S:M", "G"]],
	[159.0, ["G", "B:MR"]],
]  # Its last three clusters were cut to shorten the storm (call 18).
# The fireflies left along the trail when the path empties (call 18): how far
# each sits from where the light comes to rest (metres along the path), how
# far to the side (metres, + right), how high, and when it goes out (-1:
# never). Hand-placed so the order looks random but is the same every time:
# one, then one far off, then two close together; some never go out, and one
# is still glowing beside the hand as the light goes out.
const LAST_FIREFLIES := [
	[-95.0, -3.2, 0.9, 167.5], [-45.0, 4.0, 1.6, 171.0], [-63.0, -4.5, 2.2, 172.2],
	[10.0, 3.0, 0.7, 176.8], [-9.0, -2.8, 1.2, 179.0], [23.0, -5.5, 2.6, 182.5],
	[15.0, 5.0, 1.9, 183.1], [6.0, 2.6, 0.5, 188.0], [29.0, 1.5, 3.0, 191.5],
	[-105.0, 3.5, 1.1, -1.0], [4.0, -2.4, 0.9, -1.0], [18.0, 3.6, 1.3, -1.0], [35.0, -3.8, 2.0, -1.0],
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
	# Slows evenly to a stop over 10 s.
	var slow := STOPPED - SLOW_START
	var s := minf(t, STOPPED) - SLOW_START
	return SPEED * (SLOW_START - EUPHORIA_START) + SPEED * (s - s * s / (2.0 * slow))


## The light's brightness from the timeline alone, 0 to 1: it fades up out of
## the black, is full all run, and goes out from 3:05 to 3:15.
static func base_brightness(t: float) -> float:
	if t < EUPHORIA_START:
		return 0.0
	if t < EUPHORIA_START + 2.0:
		return smoothstep(EUPHORIA_START, EUPHORIA_START + 2.0, t)
	if t < STOPPED:
		return 1.0
	return 1.0 - smoothstep(STOPPED, OUT, t)


## How big the light is: as small as a sesame seed when it fades up, grown
## by the end of the euphoria, then shrinking to nothing as it goes out.
static func light_size(t: float) -> float:
	var grown := lerpf(SEED_SIZE, 1.0, smoothstep(EUPHORIA_START, CONFUSION_START, t))
	return grown * (1.0 - smoothstep(STOPPED, OUT, t))


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
	if t < 120.0:
		return lerpf(1.0, 0.35, smoothstep(CONFUSION_START, 120.0, t))
	if t < PANIC_START + 10.0:
		return lerpf(0.35, 0.08, smoothstep(120.0, PANIC_START + 10.0, t))
	return 0.08 if t < FADE_START else 0.0
