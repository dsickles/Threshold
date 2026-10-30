extends RefCounted
## The father's hand as one shape (Dan, 2026-10-30: "a better hand"): a palm
## that narrows to the wrist, four fingers of three joints each, curled a
## little as a relaxed hand is, a two-joint thumb with the pad of muscle at
## its root, and nails. Built from code, like the light, in one surface with
## the skin and the nails told apart by vertex colour, so it is one draw.
##
## Same footprint as the gray-box hand it replaces: palm centre at the
## origin, about 0.82 wide and 0.2 thick, fingers toward -z (forward), back
## of the hand up (+y), thumb on the +x side.

const SKIN := Color("#C8977A")
const NAIL := Color("#E2BBA8")
const KNUCKLES := -0.36  # Where the fingers leave the palm, on z.
const RINGS := 10  # Points around each part.

# The fingers from the thumb side: x at the knuckle, length, radius at the
# root, how far each fans out (radians, about y).
const FINGERS := [
	[0.29, 0.7, 0.105, -0.04],  # Index.
	[0.095, 0.78, 0.108, -0.01],
	[-0.1, 0.72, 0.102, 0.025],
	[-0.29, 0.56, 0.09, 0.07],  # Little finger.
]
const SEGMENTS := [0.46, 0.3, 0.24]  # Each joint's share of a finger's length.
const CURL := [0.1, 0.16, 0.12]  # How far each joint bends toward the palm.

static var _vertices := 0  # Added so far to the shape being built.


static func build() -> ArrayMesh:
	_vertices = 0
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# The palm: wide and flat at the knuckles, narrower at the wrist.
	_part(tool, Vector3(0.0, 0.0, 0.4), Vector3(0.0, 0.0, KNUCKLES + 0.06), 0.36, 0.42,
			Vector2(1.0, 0.28), 0.5, SKIN)
	# The wrist, a short way back, so the hand doesn't end in a cut edge.
	_part(tool, Vector3(0.0, 0.0, 0.7), Vector3(0.0, 0.0, 0.32), 0.26, 0.3,
			Vector2(1.0, 0.5), 0.75, SKIN)
	for finger: Array in FINGERS:
		var at := Vector3(finger[0], 0.0, KNUCKLES)
		var length: float = finger[1]
		var radius: float = finger[2]
		var heading := Basis(Vector3.UP, finger[3])
		var pitch := 0.0
		for k in SEGMENTS.size():
			pitch += CURL[k]
			var along: Vector3 = heading * Basis(Vector3.RIGHT, -pitch) * Vector3.FORWARD
			var to: Vector3 = at + along * length * SEGMENTS[k]
			var r0 := radius * (1.0 - 0.07 * k)
			var r1 := radius * (0.95 - 0.07 * k)
			_part(tool, at, to, r0, r1, Vector2(1.0, 0.86), 1.0, SKIN)
			if k == SEGMENTS.size() - 1:
				_nail(tool, at, to, r1, heading * Basis(Vector3.RIGHT, -pitch) * Vector3.UP)
			at = to
	# The thumb: the pad of muscle at its root, then two joints, turned in.
	var base := Vector3(0.3, -0.05, 0.22)
	var mid := Vector3(0.52, -0.07, -0.06)
	var knuckle := Vector3(0.64, -0.1, -0.28)
	var tip := Vector3(0.69, -0.12, -0.46)
	_part(tool, base, mid, 0.15, 0.12, Vector2(1.0, 0.75), 0.9, SKIN)
	_part(tool, mid, knuckle, 0.11, 0.1, Vector2(1.0, 0.85), 1.0, SKIN)
	_part(tool, knuckle, tip, 0.1, 0.085, Vector2(1.0, 0.85), 1.0, SKIN)
	# Its nail faces out and a little up, as a relaxed thumb's does.
	_nail(tool, knuckle, tip, 0.085, Vector3(0.8, 0.55, 0.0).normalized())
	tool.generate_normals()
	return tool.commit()


# A rounded, tapering part from `a` to `b`: radius r0 at a and r1 at b, its
# cross-section squashed by `flat` (x across, y up) and squared off by
# `round` (1 is an ellipse, smaller is boxier), with a dome at each end.
static func _part(tool: SurfaceTool, a: Vector3, b: Vector3, r0: float, r1: float,
		flat: Vector2, round: float, colour: Color) -> void:
	var axis := b - a
	var length := axis.length()
	var forward := axis / length
	var side := Vector3.UP.cross(forward).normalized()
	if side.length() < 0.5:
		side = Vector3.RIGHT
	var up := forward.cross(side).normalized()
	# The profile along the axis: (distance from a, radius), dome to dome.
	var profile: Array[Vector2] = []
	var caps := 4
	for k in caps + 1:
		var angle := -PI / 2.0 + PI / 2.0 * k / caps
		profile.append(Vector2(r0 * sin(angle), r0 * cos(angle)))
	for k in range(1, 3):
		var f := k / 3.0
		profile.append(Vector2(length * f, lerpf(r0, r1, f)))
	for k in caps + 1:
		var angle := PI / 2.0 * k / caps
		profile.append(Vector2(length + r1 * sin(angle), r1 * cos(angle)))
	var start := _vertices
	for p: Vector2 in profile:
		for j in RINGS:
			var turn := TAU * j / RINGS
			var c := cos(turn)
			var s := sin(turn)
			c = signf(c) * pow(absf(c), round)
			s = signf(s) * pow(absf(s), round)
			var at := a + forward * p.x + (side * c * flat.x + up * s * flat.y) * p.y
			tool.set_color(colour)
			tool.add_vertex(at)
	_vertices += profile.size() * RINGS
	_stitch(tool, start, profile.size())


# A nail on the back of a fingertip, from a little behind the tip to it.
# `back` is the way the back of the fingertip faces.
static func _nail(tool: SurfaceTool, a: Vector3, b: Vector3, radius: float, back: Vector3) -> void:
	var from := a.lerp(b, 0.35) + back * radius * 0.78
	var to := b + back * radius * 0.55 + (b - a).normalized() * radius * 0.35
	_part(tool, from, to, radius * 0.62, radius * 0.6, Vector2(1.0, 0.22), 0.7, NAIL)


# Joins the rings of one part into triangles, facing out.
static func _stitch(tool: SurfaceTool, start: int, rings: int) -> void:
	for i in rings - 1:
		for j in RINGS:
			var a := start + i * RINGS + j
			var b := start + i * RINGS + (j + 1) % RINGS
			var c := a + RINGS
			var d := b + RINGS
			for index: int in [a, c, b, b, c, d]:
				tool.add_index(index)
