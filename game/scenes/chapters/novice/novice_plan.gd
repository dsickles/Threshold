extends RefCounted
## The Novice's plan (DAS-133): the order of its micro-games across the six
## months, and how each phase plays. Pure data, so the tests can read it.
## From docs/design/story-beats.md §3 and stories/epic-3-stories.md. A DRAFT
## design for the M2 rough version: Dan tunes it after playing.
##
## Numb (early months): slow, gray and quiet; taps take a moment to land.
## Frantic (middle months): colour floods in, faster games, a short time
## limit, more to do. Exhausted (last stretch): slower again, colour drains,
## and some taps don't take. A game that runs out of time just moves on.

enum Game { BOX, POWDER, INJECT }
enum Phase { NUMB, FRANTIC, EXHAUSTED }

## The shouts are the games' names in the GDD. "DON'T FAINT!" is Later
## (docs/scope.md).
const SHOUTS := {
	Game.BOX: "OPEN THE BOX!",
	Game.POWDER: "MIX THE POWDER!",
	Game.INJECT: "INJECT THE BUTT!",
}

## Per phase: how colourful the picture is (0 gray, 1 full colour), how long
## a tap takes to land, which taps don't take (one in every N presses,
## starting with the second; 0 for none),
## and the pause before each game.
const PHASES := {
	Phase.NUMB: {"saturation": 0.0, "lag": 0.35, "drop_every": 0, "gap": 1.6},
	Phase.FRANTIC: {"saturation": 1.0, "lag": 0.0, "drop_every": 0, "gap": 0.6},
	Phase.EXHAUSTED: {"saturation": 0.3, "lag": 0.0, "drop_every": 3, "gap": 1.4},
}

## How fast each game is in each phase.
## BOX: taps to open the lid. POWDER: how fast the mix rises while held (of
## the whole vial a second) and the band to let go in. INJECT: how fast the
## needle sways (radians a second) and how close to the target counts (as a
## share of the sway's half-width).
const TUNING := {
	Phase.NUMB: {
		"limit": 10.0, "box_taps": 1, "rise": 0.28, "band": Vector2(0.55, 0.8),
		"sway": 1.1, "target": 0.3,
	},
	Phase.FRANTIC: {
		"limit": 3.5, "box_taps": 4, "rise": 0.9, "band": Vector2(0.65, 0.85),
		"sway": 4.2, "target": 0.2,
	},
	Phase.EXHAUSTED: {
		"limit": 7.0, "box_taps": 2, "rise": 0.35, "band": Vector2(0.55, 0.8),
		"sway": 1.6, "target": 0.28,
	},
}

## The rounds in order: the game, its phase and the month (3–9) it is in.
## The first is the Injection's own shot, right after Maya asks.
const ROUNDS := [
	[Game.INJECT, Phase.NUMB, 3],
	[Game.BOX, Phase.NUMB, 3],
	[Game.POWDER, Phase.NUMB, 4],
	[Game.INJECT, Phase.NUMB, 4],
	[Game.BOX, Phase.FRANTIC, 5],
	[Game.POWDER, Phase.FRANTIC, 5],
	[Game.INJECT, Phase.FRANTIC, 5],
	[Game.BOX, Phase.FRANTIC, 6],
	[Game.INJECT, Phase.FRANTIC, 6],
	[Game.POWDER, Phase.FRANTIC, 6],
	[Game.POWDER, Phase.FRANTIC, 7],
	[Game.BOX, Phase.FRANTIC, 7],
	[Game.INJECT, Phase.FRANTIC, 7],
	[Game.BOX, Phase.FRANTIC, 7],
	[Game.BOX, Phase.EXHAUSTED, 8],
	[Game.POWDER, Phase.EXHAUSTED, 8],
	[Game.INJECT, Phase.EXHAUSTED, 9],
	[Game.BOX, Phase.EXHAUSTED, 9],
]


## Round `i` as a dictionary: game, phase, month, and its phase's settings.
static func round_at(i: int) -> Dictionary:
	var row: Array = ROUNDS[i]
	var out := {"game": row[0], "phase": row[1], "month": row[2]}
	out.merge(PHASES[row[1]])
	out.merge(TUNING[row[1]])
	return out


static func count() -> int:
	return ROUNDS.size()
