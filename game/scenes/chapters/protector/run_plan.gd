extends RefCounted
## The Protector's run as one fixed timeline (docs/design/the-loss-run-and-car.md,
## "The run, part by part"): when each part starts, the hand-built obstacle
## list, how far ahead an obstacle can be cleared, where the light is and how
## bright it is. Nothing here is random and nothing the player does moves the
## timeline, so every player gets the same run and the same fade.
##
## Times are seconds from the lamp click. The run scene (protector_run.gd)
## draws this; the tests check it.

enum Part { DARK, EUPHORIA, CONFUSION, PANIC, SILENCE }
enum Kind { STONE, BRANCH, GAP }

const EUPHORIA_START := 5.0
const CONFUSION_START := 85.0
const PANIC_START := 135.0
const SILENCE_START := 175.0
const SLOW_START := 185.0  # 3:05: the light slows to a stop.
const STOPPED := 195.0  # 3:15: it has stopped, and goes out.
const OUT := 205.0  # 3:25: it is out; the empty path.
const BLACK := 215.0  # 3:35: black. The car begins (DAS-98).

## How long before an obstacle would touch the light it can be cleared, by
## the part it touches in. Choice, to tune in playtests: generous on purpose.
const REACH := {
	Part.EUPHORIA: 1.3,
	Part.CONFUSION: 1.0,
	Part.PANIC: 0.8,
}

const SPEED := 9.0  # Metres a second, the same all run until it slows.
const STUMBLE_DIM := 0.45  # The light's brightness at the start of a stumble.
const STUMBLE_TIME := 0.6  # How long until it is fully bright again.

# The euphoria's obstacles land on the song's beat: 90 BPM, one every 2 bars
# (16/3 s), from 0:13. The song starts on a bar line at 0:05.
const BEAT_START := 13.0
const TWO_BARS := 16.0 / 3.0
const EUPHORIA_KINDS := "SSBSGBSGBSGS"
# Confusion: off the beat and at uneven gaps. Panic: clusters 0.6 s apart.
const CONFUSION := [
	[89.0, "S"], [93.0, "G"], [99.0, "B"], [102.0, "S"], [108.0, "S"], [110.0, "B"],
	[116.0, "G"], [119.0, "S"], [122.0, "B"], [126.0, "G"], [129.0, "S"], [133.0, "G"],
]
const CLUSTER_GAP := 0.6
const PANIC := [
	[137.0, "SS"], [140.0, "BSG"], [145.0, "GS"], [148.0, "SBS"], [152.0, "BG"],
	[156.0, "SSG"], [159.0, "GB"], [163.0, "SGS"], [167.0, "BS"], [171.0, "GBS"],
]
const KINDS := {"S": Kind.STONE, "B": Kind.BRANCH, "G": Kind.GAP}


## Every obstacle in the run, in order: {"time": when it would touch the
## light, "kind": Kind, "part": Part}.
static func obstacles() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k in EUPHORIA_KINDS.length():
		out.append(_obstacle(BEAT_START + k * TWO_BARS, EUPHORIA_KINDS[k]))
	for entry: Array in CONFUSION:
		out.append(_obstacle(entry[0], entry[1]))
	for cluster: Array in PANIC:
		var kinds: String = cluster[1]
		for k in kinds.length():
			out.append(_obstacle(cluster[0] + k * CLUSTER_GAP, kinds[k]))
	return out


static func _obstacle(time: float, kind: String) -> Dictionary:
	return {"time": time, "kind": KINDS[kind], "part": part_at(time)}


static func part_at(t: float) -> Part:
	if t < EUPHORIA_START:
		return Part.DARK
	if t < CONFUSION_START:
		return Part.EUPHORIA
	if t < PANIC_START:
		return Part.CONFUSION
	if t < SILENCE_START:
		return Part.PANIC
	return Part.SILENCE


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
## the black, is full all run, and goes out from 3:15 to 3:25.
static func base_brightness(t: float) -> float:
	if t < EUPHORIA_START:
		return 0.0
	if t < EUPHORIA_START + 2.0:
		return smoothstep(EUPHORIA_START, EUPHORIA_START + 2.0, t)
	if t < STOPPED:
		return 1.0
	return 1.0 - smoothstep(STOPPED, OUT, t)


## How big the light is: it grows a little over the euphoria, then shrinks to
## nothing as it goes out.
static func light_size(t: float) -> float:
	var grown := lerpf(0.8, 1.0, smoothstep(EUPHORIA_START, CONFUSION_START, t))
	return grown * (1.0 - smoothstep(STOPPED, OUT, t))


## The dimming a stumble at `stumbled_at` causes at time t: 1 is none. It is
## gone after STUMBLE_TIME, so nothing carries over to the next obstacle.
static func stumble_factor(t: float, stumbled_at: float) -> float:
	var since := t - stumbled_at
	if since < 0.0 or since >= STUMBLE_TIME:
		return 1.0
	return lerpf(STUMBLE_DIM, 1.0, since / STUMBLE_TIME)
