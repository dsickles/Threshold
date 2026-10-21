"""PLACEHOLDER silhouettes for the Partner, until real art (ADR-0005).

    python3 tools/partner/make_silhouettes.py
    cd tests/web && node ../../tools/partner/make_images.mjs

Writes tools/partner/placeholder_couple.svg (the final picture: the couple
standing, holding each other, about to kiss) and placeholder_moment_01..12.svg
(the streak moments: the couple enjoying life together; Dan, 2026-10-21,
"out at a restaurant, holding hands and walking, cuddling on a couch,
laughing at a bar, dancing, etc."; later the bar was cut and a wedding added
before moving in). make_images.mjs renders them to PNGs;
the game tints them warm red.

The people are posed puppets: each limb is a rounded stroke between joints,
so the figures read as two people rather than one shape. He is drawn white
and she light grey, so after tinting they are two close shades of red.
Dan's references were photos and clip art of couples in silhouette.
"""
import math
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
HIM = "#ffffff"
HER = "#d6d6d6"
PROP = "#ffffff"
PROP_BACK = "#bdbdbd"  # Furniture behind them, a shade darker.

UPPER_ARM, FOREARM, THIGH, SHIN = 30, 28, 44, 44


def vec(angle, length, side):
    """A segment `length` long, `angle` degrees from straight down, positive
    toward `side` (+1 the viewer's right, -1 left)."""
    a = math.radians(angle)
    return side * math.sin(a) * length, math.cos(a) * length


def add(p, q):
    return p[0] + q[0], p[1] + q[1]


class Figure:
    """One person, seen side on (facing +1 right or -1 left) or from the
    front (facing 0). Limb angles are degrees from straight down: side on,
    positive is the way they face; from the front, positive is outward.
    `lean` tips the body: forward side on, toward the viewer's right from
    the front. Side on, limb 0 is the far one and 1 the near one; from the
    front, 0 is on the viewer's left and 1 on the right."""

    def __init__(self, hip, facing=1, woman=False, scale=1.0, lean=0.0, head=0.0,
                 arms=((-10, -10), (10, 10)), legs=((-6, 0), (6, 0)),
                 hair=1.0, skirt=0.0, sway=0.0, shins=None, dress=40):
        self.s = scale * (0.92 if woman else 1.0)
        self.hip = hip
        self.f = facing
        self.woman = woman
        self.lean = lean
        self.head_tilt = head
        self.arms = [list(a) for a in arms]
        self.legs = [list(l) for l in legs]
        self.hair = hair
        self.skirt = skirt
        self.sway = sway
        self.dress = dress  # Skirt length; a wedding dress reaches the ground.
        self.leg_lengths = shins or (THIGH, SHIN)
        self.colour = HER if woman else HIM

    # Body directions.
    def up(self, extra=0.0, length=1.0):
        if self.f == 0:
            a = math.radians(self.lean + extra)
            return math.sin(a) * length, -math.cos(a) * length
        return vec(180 - self.lean - extra, length, self.f)

    def across(self, length=1.0):
        u = self.up()
        return -u[1] * length, u[0] * length

    @property
    def neck(self):
        return add(self.hip, self.up(0, 56 * self.s))

    @property
    def shoulder_mid(self):
        return add(self.hip, self.up(0, 49 * self.s))

    @property
    def head(self):
        return add(self.neck, self.up(self.head_tilt, 17 * self.s))

    def shoulder(self, i):
        if self.f:
            return self.shoulder_mid
        w = (11 if self.woman else 14) * self.s
        return add(self.shoulder_mid, self.across(w if i else -w))

    def hip_joint(self, i):
        if self.f:
            return self.hip
        w = 6.5 * self.s
        return add(self.hip, self.across(w if i else -w))

    def side(self, i):
        return self.f if self.f else (1 if i else -1)

    def chain(self, start, angles, lengths, side):
        points = [start]
        for angle, length in zip(angles, lengths):
            points.append(add(points[-1], vec(angle, length * self.s, side)))
        return points

    def arm(self, i):
        return self.chain(self.shoulder(i), self.arms[i], (UPPER_ARM, FOREARM), self.side(i))

    def leg(self, i):
        return self.chain(self.hip_joint(i), self.legs[i], self.leg_lengths, self.side(i))

    def hand(self, i):
        return self.arm(i)[-1]

    def reach(self, i, target, elbow=-1):
        """Bend arm i so its hand is at `target`. elbow -1 bends down/back."""
        self.arms[i] = list(solve(self.shoulder(i), target, UPPER_ARM * self.s, FOREARM * self.s,
                                  self.side(i), elbow))

    def step(self, i, target, knee=1):
        """Bend leg i so its foot is at `target`. knee +1 bends forward/out."""
        self.legs[i] = list(solve(self.hip_joint(i), target, self.leg_lengths[0] * self.s,
                                  self.leg_lengths[1] * self.s, self.side(i), knee))

    def svg(self, layer="all"):
        s, c = self.s, self.colour
        out = []

        def line(points, width):
            d = " ".join(f"{x:.1f},{y:.1f}" for x, y in points)
            out.append(f'<polyline points="{d}" fill="none" stroke="{c}" stroke-width="{width * s:.1f}" '
                       f'stroke-linecap="round" stroke-linejoin="round"/>')

        def draw_leg(i):
            points = self.leg(i)
            line(points, 11 if self.woman else 13)
            shin = self.legs[i][1]
            toe = add(points[-1], vec(shin + 90, 8 * s, self.side(i)))
            line([points[-1], toe], 7)

        def draw_arm(i):
            line(self.arm(i), 8 if self.woman else 9.5)

        far, near = (0, 1)
        if self.f and layer in ("all", "far"):
            draw_arm(far)
            draw_leg(far)
        if layer == "far":
            return "".join(out)
        if layer in ("all", "body"):
            out.append(self._hair_back())
            if not self.f:
                draw_leg(0)
                draw_leg(1)
            if self.skirt:
                out.append(self._skirt())
            out.append(self._torso())
            out.append(self._head())
            if not self.f:
                draw_arm(0)
                draw_arm(1)
        if self.f and layer in ("all", "near"):
            draw_leg(near)
            draw_arm(near)
        return "".join(out)

    def _hair_back(self):
        if not self.woman or self.hair <= 0:
            return ""
        s, c = self.s, self.colour
        hx, hy = self.head
        down = self.up(self.head_tilt, -1)
        length = 32 * s * self.hair
        if self.f == 0:
            # From the front: hair falls either side of the face to the shoulders.
            pts = []
            for k in range(13):
                a = math.pi * k / 12
                pts.append(add((hx, hy), (-math.cos(a) * 13 * s, -math.sin(a) * 13 * s)))
            bottom = add((hx, hy), (down[0] * length + self.sway, down[1] * length))
            pts.append(add(bottom, (13 * s, 0)))
            pts.append(add(bottom, (-13 * s, 0)))
            d = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
            return f'<polygon points="{d}" fill="{c}" stroke="{c}" stroke-width="{6 * s:.1f}" stroke-linejoin="round"/>'
        back = self.across(-1 if self.f > 0 else 1)
        back = (-self.f * abs(back[0]) if back[0] else -self.f, back[1])
        crown = add((hx, hy), self.up(self.head_tilt, 9 * s))
        nape = add((hx, hy), (-self.f * 9 * s, 0))
        tip = add(nape, (down[0] * length - self.f * (4 * s + self.sway), down[1] * length))
        ctrl = add(nape, (-self.f * 12 * s, length * 0.4))
        return (f'<path d="M {crown[0]:.1f},{crown[1]:.1f} Q {ctrl[0] - self.f * 6 * s:.1f},{ctrl[1] - 14 * s:.1f} '
                f'{tip[0]:.1f},{tip[1]:.1f} Q {nape[0] + self.f * 4 * s:.1f},{nape[1] + length * 0.5:.1f} '
                f'{hx + self.f * 2 * s:.1f},{hy + 6 * s:.1f} Z" fill="{c}"/>')

    def _torso(self):
        s, c = self.s, self.colour
        wh = (12.5 if self.woman else 11) * s
        waist = (9.5 if self.woman else 11) * s
        ws = (11 if self.woman else 15) * s if self.f else (14 if self.woman else 18) * s
        mid = add(self.hip, self.up(0, 26 * s))
        top = self.shoulder_mid
        pts = [add(self.hip, self.across(-wh)), add(mid, self.across(-waist)), add(top, self.across(-ws)),
               add(top, self.up(0, 4 * s)), add(top, self.across(ws)), add(mid, self.across(waist)),
               add(self.hip, self.across(wh))]
        d = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
        neck_top = add(self.neck, self.up(self.head_tilt, 6 * s))
        return (f'<polygon points="{d}" fill="{c}" stroke="{c}" stroke-width="{7 * s:.1f}" stroke-linejoin="round"/>'
                f'<line x1="{top[0]:.1f}" y1="{top[1]:.1f}" x2="{neck_top[0]:.1f}" y2="{neck_top[1]:.1f}" '
                f'stroke="{c}" stroke-width="{9 * s:.1f}" stroke-linecap="round"/>')

    def _skirt(self):
        s, c = self.s, self.colour
        wh = 12 * s
        length = self.dress * s
        flare = (16 + 14 * self.skirt) * s
        down = self.up(0, -1)
        hem = add(self.hip, (down[0] * length + self.sway * 0.5, down[1] * length))
        left, right = add(self.hip, self.across(-wh)), add(self.hip, self.across(wh))
        a = add(hem, self.across(-flare))
        b = add(hem, self.across(flare))
        return (f'<path d="M {left[0]:.1f},{left[1]:.1f} L {a[0]:.1f},{a[1]:.1f} '
                f'Q {hem[0]:.1f},{hem[1] + 4 * s:.1f} {b[0]:.1f},{b[1]:.1f} L {right[0]:.1f},{right[1]:.1f} Z" '
                f'fill="{c}" stroke="{c}" stroke-width="{4 * s:.1f}" stroke-linejoin="round"/>')

    def _head(self):
        s, c = self.s, self.colour
        hx, hy = self.head
        tilt = self.lean + self.head_tilt
        rot = tilt if self.f == 0 else self.f * tilt
        out = [f'<ellipse cx="{hx:.1f}" cy="{hy:.1f}" rx="{10 * s:.1f}" ry="{12 * s:.1f}" fill="{c}" '
               f'transform="rotate({rot:.1f} {hx:.1f} {hy:.1f})"/>']
        if self.f:
            # A small nose and chin so the face reads side on.
            nose = add((hx, hy), vec(180 - tilt - 100, 9.5 * s, self.f))
            chin = add((hx, hy), vec(180 - tilt - 145, 9 * s, self.f))
            out.append(f'<circle cx="{nose[0]:.1f}" cy="{nose[1]:.1f}" r="{3 * s:.1f}" fill="{c}"/>')
            out.append(f'<circle cx="{chin[0]:.1f}" cy="{chin[1]:.1f}" r="{4 * s:.1f}" fill="{c}"/>')
        crown = add((hx, hy), self.up(self.head_tilt, 3.5 * s))
        if self.f:
            crown = add(crown, (-self.f * 2 * s, 0))
        rx, ry = (12, 9.5) if self.woman else (11, 8.5)
        out.append(f'<ellipse cx="{crown[0]:.1f}" cy="{crown[1]:.1f}" rx="{rx * s:.1f}" ry="{ry * s:.1f}" '
                   f'fill="{c}" transform="rotate({rot:.1f} {crown[0]:.1f} {crown[1]:.1f})"/>')
        return "".join(out)


def solve(start, target, l1, l2, side, bend):
    """Two-segment reach from `start` to `target`: (upper, lower) angles."""
    dx, dy = target[0] - start[0], target[1] - start[1]
    dist = min(math.hypot(dx, dy), (l1 + l2) * 0.999)
    reach = math.degrees(math.atan2(side * dx, dy))
    cos_a = (l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist)
    upper = reach + bend * math.degrees(math.acos(max(-1.0, min(1.0, cos_a))))
    ex, ey = vec(upper, l1, side)
    lower = math.degrees(math.atan2(side * (dx - ex), dy - ey))
    return upper, lower


def svg(width, height, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" '
            f'width="{width * 4}" height="{height * 4}">{body}</svg>\n')


def stroke(d, width=4.0, colour=PROP, fill="none"):
    return (f'<path d="{d}" fill="{fill}" stroke="{colour}" stroke-width="{width}" '
            f'stroke-linecap="round" stroke-linejoin="round"/>')


def rect(x, y, w, h, r=2.0, colour=PROP):
    return f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{r}" fill="{colour}"/>'


def star(x, y, r):
    pts = []
    for k in range(8):
        a = math.pi / 4 * k
        rr = r if k % 2 == 0 else r * 0.32
        pts.append(f"{x + rr * math.sin(a):.1f},{y - rr * math.cos(a):.1f}")
    return f'<polygon points="{" ".join(pts)}" fill="{PROP}"/>'


def heart(x, y, r, colour=PROP):
    return (f'<path d="M {x} {y + r} C {x - 2 * r} {y - 0.2 * r}, {x - r} {y - 1.4 * r}, {x} {y - 0.5 * r} '
            f'C {x + r} {y - 1.4 * r}, {x + 2 * r} {y - 0.2 * r}, {x} {y + r} Z" fill="{colour}"/>')


# The final picture: standing close, his arms round her waist, hers round
# his neck, foreheads almost touching. Light between their legs and a
# shade apart in colour, so they read as two people.
def couple():
    him = Figure((120, 122), facing=-1, lean=8, head=25, legs=((5, 2), (-3, 0)))
    her = Figure((90, 128), facing=1, woman=True, lean=4, head=-28, legs=((6, 3), (-4, 0)),
                 hair=1.3)
    back = add(her.hip, her.up(0, 24 * her.s))
    him.reach(0, add(back, (-6, -4)))
    him.reach(1, add(back, (-10, 2)))
    her.reach(0, add(him.shoulder_mid, (-2, 2)), elbow=-1)
    her.reach(1, add(him.shoulder_mid, (-10, 14)), elbow=-1)
    return svg(200, 220, him.svg("far") + her.svg("far") + him.svg("body") + her.svg("body")
               + her.svg("near") + him.svg("near"))


def moments():
    """The twelve streak moments, in the order they come in. Dan, 2026-10-21:
    no bar (too like dinner); a wedding, then moving in, last before the
    final embrace."""
    scenes = []

    # 1. Dinner at a restaurant, a candle between them.
    her = Figure((54, 120), facing=1, woman=True, scale=0.9, lean=6, legs=((82, 0), (86, 0)))
    him = Figure((146, 118), facing=-1, scale=0.9, lean=6, legs=((82, 0), (86, 0)))
    her.reach(1, (82, 98))
    her.reach(0, (80, 100))
    him.reach(1, (118, 98))
    him.reach(0, (120, 100))
    chairs = (stroke("M 40 124 L 62 124 M 42 124 L 42 162 M 60 124 L 60 162 M 40 124 L 36 84", 4, PROP_BACK)
              + stroke("M 160 122 L 138 122 M 158 122 L 158 162 M 140 122 L 140 162 M 160 122 L 164 82", 4,
                       PROP_BACK))
    table = (rect(76, 100, 48, 5, 2) + stroke("M 100 104 L 100 160 M 88 161 L 112 161", 4)
             + rect(97, 86, 6, 14, 1)
             + '<path d="M 100 70 Q 105 79 100 84 Q 95 79 100 70 Z" fill="#ffffff"/>')
    scenes.append(chairs + her.svg() + him.svg() + table)

    # 2. Hiking together: up a trail with backpacks, she is a step ahead
    # and reaches back to give him a hand up.
    def ground(x):
        return 166 - 0.3 * x

    hills = (stroke("M -4 120 L 40 62 L 70 100 L 112 40 L 160 104 L 186 76 L 210 110", 3, PROP_BACK)
             + "".join(f'<path d="M {x} {y} l -7 16 l 14 0 Z M {x} {y + 8} l -9 18 l 18 0 Z" fill="{PROP_BACK}"/>'
                       + stroke(f"M {x} {y + 26} l 0 6", 3, PROP_BACK)
                       for x, y in ((20, 104), (176, 88))))
    trail = f'<path d="M -4 {ground(-4):.1f} L 204 {ground(204):.1f} L 204 184 L -4 184 Z" fill="{PROP}"/>'
    him = Figure((70, 86), facing=1, scale=0.76, lean=12, head=-8)
    her = Figure((122, 74), facing=1, woman=True, scale=0.76, lean=6, head=-20, hair=1.1)
    him.step(0, (54, ground(54) - 1), knee=1)
    him.step(1, (86, ground(86) - 1), knee=1)
    her.step(0, (110, ground(110) - 1), knee=1)
    her.step(1, (136, ground(136) - 1), knee=1)
    meet = (98, 76)
    her.reach(1, meet, elbow=-1)
    him.reach(1, meet, elbow=-1)
    stick_top = add(him.hip, (-12, 4))
    him.reach(0, stick_top, elbow=-1)
    stick = stroke(f"M {stick_top[0]:.1f} {stick_top[1] - 8:.1f} L {stick_top[0] - 10:.1f} {ground(stick_top[0] - 10):.1f}", 3)
    her.reach(0, add(her.hip, (-6, 12)))

    def pack(fig, w, h):
        c = add(add(fig.hip, fig.up(0, 32 * fig.s)), (-12 * fig.s, 0))
        return (f'<rect x="{c[0] - w / 2:.1f}" y="{c[1] - h / 2:.1f}" width="{w}" height="{h}" rx="4" '
                f'fill="{PROP_BACK}" transform="rotate({fig.lean:.1f} {c[0]:.1f} {c[1]:.1f})"/>')

    scenes.append(hills + trail + pack(him, 16, 26) + pack(her, 13, 20) + him.svg() + her.svg() + stick)

    # 3. Sharing an umbrella in the rain, close, from the front.
    her = Figure((84, 104), facing=0, woman=True, scale=0.85, lean=6, head=10, skirt=0.2,
                 legs=((3, 0), (-2, 0)))
    him = Figure((118, 100), facing=0, scale=0.85, lean=-1, legs=((-2, 0), (4, 0)))
    her.reach(1, add(him.shoulder(0), (2, 16)), elbow=1)
    her.reach(0, add(her.hip, (-10, 14)))
    grip = (102, 62)
    him.reach(0, grip, elbow=-1)
    him.reach(1, add(him.hip, (14, 16)))
    umbrella = (stroke(f"M {grip[0]} {grip[1] + 8} L {grip[0]} 22", 3)
                + f'<path d="M 46 40 Q 102 -6 158 40 Q 144 32 130 40 Q 116 32 102 40 Q 88 32 74 40 '
                f'Q 60 32 46 40 Z" fill="{PROP}"/>'
                + stroke(f"M {grip[0]} {grip[1] + 8} q 0 6 -5 6", 3))
    rain = "".join(stroke(f"M {x} {y} l -3 9", 1.8) for x, y in
                   [(24, 52), (36, 90), (20, 128), (40, 150), (178, 58), (168, 96), (184, 130),
                    (164, 148), (30, 20), (176, 18)])
    scenes.append(rain + her.svg() + him.svg() + umbrella)

    # 4. Dancing: a slow dance, close, his arm round her back, their other
    # hands raised together; she leans back a little and her skirt swings.
    him = Figure((116, 102), facing=-1, scale=0.9, lean=-2, head=10, legs=((-8, -2), (14, 4)))
    her = Figure((86, 104), facing=1, woman=True, scale=0.88, lean=-8, head=-16, sway=-8, skirt=1.1,
                 hair=1.3, legs=((-6, -2), (8, 2)))
    meet = (98, 30)
    her.reach(1, meet, elbow=-1)
    him.reach(0, add(meet, (2, 2)), elbow=-1)
    back = add(her.hip, her.up(0, 26 * her.s))
    him.reach(1, add(back, (-8, 0)))
    her.reach(0, add(him.shoulder_mid, (0, 18)), elbow=-1)
    def note(x, y, double=False):
        if double:
            return (stroke(f"M {x} {y} l 0 -14 l 9 -3 l 0 14", 2.2) + f'<circle cx="{x - 2}" cy="{y}" r="3.2" fill="{PROP}"/>'
                    + f'<circle cx="{x + 7}" cy="{y - 3}" r="3.2" fill="{PROP}"/>')
        return (stroke(f"M {x} {y} l 0 -13 q 6 3 5 9", 2.2)
                + f'<circle cx="{x - 2}" cy="{y}" r="3.2" fill="{PROP}"/>')

    notes = (note(50, 48, True) + note(66, 22) + note(140, 26, True) + note(156, 56)
             + note(40, 84) + note(166, 92, True))
    scenes.append(notes + him.svg("far") + her.svg("far") + her.svg("body") + him.svg("body")
                  + her.svg("near") + him.svg("near"))

    # 5. Bike rides side by side: both bikes on the same road, hers on the
    # far side, a little behind.
    def bike(x, y, colour=PROP, s=1.0):
        r = 17 * s
        return (f'<circle cx="{x - 28 * s:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="none" stroke="{colour}" stroke-width="3.5"/>'
                f'<circle cx="{x + 28 * s:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="none" stroke="{colour}" stroke-width="3.5"/>'
                + stroke(f"M {x - 28 * s:.1f} {y:.1f} L {x - 6 * s:.1f} {y - 26 * s:.1f} L {x + 20 * s:.1f} {y - 26 * s:.1f} "
                         f"L {x + 28 * s:.1f} {y:.1f} M {x - 6 * s:.1f} {y - 26 * s:.1f} L {x:.1f} {y:.1f} "
                         f"L {x + 20 * s:.1f} {y - 26 * s:.1f} M {x - 12 * s:.1f} {y - 32 * s:.1f} "
                         f"L {x - 2 * s:.1f} {y - 32 * s:.1f} M {x - 6 * s:.1f} {y - 26 * s:.1f} L {x - 7 * s:.1f} {y - 32 * s:.1f} "
                         f"M {x + 20 * s:.1f} {y - 26 * s:.1f} L {x + 17 * s:.1f} {y - 38 * s:.1f} L {x + 24 * s:.1f} {y - 40 * s:.1f}",
                         3, colour))

    def rider(fig, x, y, s=1.0):
        fig.hip = (x - 7 * s, y - 36 * s)
        fig.reach(0, (x + 22 * s, y - 39 * s))
        fig.reach(1, (x + 24 * s, y - 40 * s))
        fig.step(0, (x - 7 * s, y + 7 * s))
        fig.step(1, (x + 8 * s, y - 4 * s))
        return fig

    # Same ground line under both (wheel bottoms at y 160). Each bike is
    # sized to its rider: his is bigger by as much as he is taller.
    bs = 0.88
    ms = round(bs * 0.86 / (0.84 * 0.92), 2)
    hx, hy = 56, 160 - 17 * bs
    mx, my = 136, 160 - 17 * ms
    her = rider(Figure((0, 0), facing=1, woman=True, scale=0.84, lean=28, head=-16, sway=6,
                       shins=(42, 42)), hx, hy, bs)
    him = rider(Figure((0, 0), facing=1, scale=0.86, lean=30, head=-18, shins=(42, 42)), mx, my, ms)
    road = stroke("M 10 161 L 190 161", 2.5, PROP_BACK)
    scenes.append(road + bike(hx, hy, HER, bs) + her.svg() + bike(mx, my, PROP, ms) + him.svg())

    # 6. Cooking together: he holds the pan, she tastes from a spoon.
    him = Figure((140, 118), facing=-1, scale=0.9, lean=6, head=8)
    her = Figure((64, 120), facing=1, woman=True, scale=0.9, lean=14, head=-4)
    him.reach(1, (122, 106))
    him.reach(0, (116, 100))
    her.reach(1, add(her.head, (12, 8)))
    her.reach(0, (82, 108))
    counter = rect(34, 112, 132, 7, 2) + rect(40, 119, 120, 50, 3)
    pan = stroke("M 86 106 L 112 106 L 108 112 L 90 112 Z M 112 107 L 124 106", 3)
    steam = stroke("M 94 100 q 4 -6 0 -12 q -4 -6 0 -12 M 104 100 q 4 -6 0 -12", 2)
    spoon = stroke(f"M {her.hand(1)[0]:.1f} {her.hand(1)[1]:.1f} l 7 -8", 2.5)
    scenes.append(him.svg() + her.svg() + counter + pan + steam + spoon)

    # 7. A piggyback ride: she is on his back, chest to his back, her head
    # above his shoulder and an arm over it; her legs wrap forward round his
    # waist and he holds them.
    him = Figure((112, 100), facing=1, scale=0.88, lean=15, head=-15, legs=((-12, -4), (14, 2)))
    her = Figure((92, 86), facing=1, woman=True, scale=0.82, lean=15, head=-10, sway=8, hair=1.1, shins=(54, 40),
                 legs=((86, 4), (94, 2)))
    chest = add(him.shoulder_mid, (8, 10))
    her.reach(0, add(chest, (2, -2)), elbow=-1)
    her.reach(1, chest, elbow=-1)
    him.reach(0, add(her.leg(0)[1], (-4, 4)), elbow=-1)
    him.reach(1, add(her.leg(1)[1], (-6, 4)), elbow=-1)
    scenes.append(her.svg("far") + her.svg("body") + him.svg("far") + him.svg("body")
                  + her.svg("near") + him.svg("near"))

    # 8. Cuddling on the couch, from the front: her head on his shoulder,
    # his arm round her, her hands in her lap.
    sofa_back = rect(26, 70, 148, 52, 10, PROP_BACK)
    sofa_front = (rect(26, 116, 148, 18, 6, PROP_BACK) + rect(16, 92, 22, 46, 8, PROP_BACK)
                  + rect(162, 92, 22, 46, 8, PROP_BACK)
                  + stroke("M 36 136 L 36 148 M 164 136 L 164 148", 5, PROP_BACK))
    her = Figure((78, 118), facing=0, woman=True, scale=0.82, lean=14, head=12, shins=(6, 30),
                 legs=((4, 2), (-2, 0)))
    him = Figure((122, 116), facing=0, scale=0.85, lean=-3, shins=(6, 32), legs=((-2, 0), (4, 2)))
    him.reach(0, add(her.shoulder(0), (-2, 6)), elbow=1)
    him.reach(1, add(him.hip, (10, 4)))
    lap = add(her.hip, (4, -2))
    her.reach(0, add(lap, (-2, 0)))
    her.reach(1, add(lap, (2, 2)))
    # The seat is behind their legs: they sit on it, shins down in front.
    scenes.append(sofa_back + sofa_front + him.svg("body") + him.svg("near") + her.svg() + him.svg("far"))

    # 9. A picnic: sitting on a blanket, facing each other.
    blanket = '<path d="M 14 164 L 186 164 L 174 152 L 26 152 Z" fill="#ffffff"/>'
    basket = rect(88, 134, 24, 18, 3) + stroke("M 92 134 Q 100 120 108 134", 3)
    her = Figure((50, 150), facing=1, woman=True, scale=0.85, lean=-8, head=-6)
    her.step(0, (86, 152), knee=1)
    her.step(1, (84, 152), knee=1)
    her.reach(0, (36, 152), elbow=1)
    her.reach(1, add(her.leg(1)[1], (-2, -4)))
    him = Figure((152, 150), facing=-1, scale=0.85, lean=-14, head=-6)
    him.step(0, (118, 152), knee=1)
    him.step(1, (112, 146), knee=1)
    him.reach(0, (168, 152), elbow=1)
    him.reach(1, (114, 136))
    apple = '<circle cx="114" cy="132" r="4" fill="#ffffff"/>'
    scenes.append(blanket + basket + her.svg() + him.svg() + apple)

    # 10. Under the stars: sitting on a hill, seen from behind, her head on
    # his shoulder, him pointing up at the sky, her hands in her lap.
    stars = "".join(star(x, y, r) for x, y, r in
                    [(24, 30, 6), (60, 14, 4), (100, 26, 5), (150, 16, 7), (178, 44, 4), (40, 70, 3.5),
                     (132, 58, 3), (186, 90, 3)])
    hill = '<path d="M 0 180 L 0 150 Q 100 124 200 150 L 200 180 Z" fill="#bdbdbd"/>'
    her = Figure((88, 140), facing=0, woman=True, scale=0.8, lean=14, head=12, shins=(10, 10),
                 legs=((4, 2), (-2, 0)))
    him = Figure((118, 138), facing=0, scale=0.82, lean=-4, shins=(10, 10), legs=((-2, 0), (4, 2)))
    him.reach(0, add(her.shoulder(0), (0, 6)), elbow=1)
    him.reach(1, (164, 40), elbow=-1)
    lap = add(her.hip, (4, -2))
    her.reach(0, add(lap, (-2, 0)))
    her.reach(1, add(lap, (2, 2)))
    scenes.append(stars + him.svg("body") + him.svg("near") + her.svg() + him.svg("far") + hill)

    # 11. Their wedding: under an arch, from the front, holding hands; her
    # dress to the ground, a veil and a bouquet.
    arch = (stroke("M 26 166 L 26 72 Q 100 -30 174 72 L 174 166", 5, PROP_BACK)
            + "".join(heart(x, y, 4.5, PROP_BACK) for x, y in
                      [(26, 100), (174, 100), (38, 52), (162, 52), (66, 26), (134, 26), (100, 14)]))
    her = Figure((84, 108), facing=0, woman=True, scale=0.8, head=4, skirt=1.0, dress=84,
                 legs=((3, 0), (-3, 0)), hair=0.9)
    him = Figure((122, 104), facing=0, scale=0.82, head=-3, legs=((-2, 0), (3, 0)))
    meet = (104, 118)
    her.reach(1, meet, elbow=1)
    him.reach(0, meet, elbow=1)
    bouquet_at = add(her.hip, (-4, -14))
    her.reach(0, bouquet_at, elbow=1)
    him.reach(1, add(him.hip, (16, 14)))
    hx, hy = her.head
    veil = (f'<path d="M {hx - 8:.1f} {hy - 8:.1f} Q {hx - 30:.1f} {hy + 30:.1f} {hx - 26:.1f} {hy + 74:.1f} '
            f'L {hx - 8:.1f} {hy + 70:.1f} Q {hx - 12:.1f} {hy + 20:.1f} {hx + 2:.1f} {hy - 10:.1f} Z" '
            f'fill="{PROP}"/>')
    bouquet = "".join(f'<circle cx="{bouquet_at[0] + dx:.1f}" cy="{bouquet_at[1] + dy:.1f}" r="4.2" fill="{PROP}"/>'
                      for dx, dy in [(0, -2), (-5, 1), (5, 1), (-2, 5), (3, 5)])
    bouquet += stroke(f"M {bouquet_at[0]:.1f} {bouquet_at[1] + 6:.1f} l 0 10", 2.5)
    scenes.append(arch + veil + him.svg() + her.svg() + bouquet)

    # 12. Moving in: carrying boxes toward their new front door.
    house = (stroke("M 150 166 L 150 82 L 174 60 L 198 82 L 198 166", 4)
             + rect(162, 118, 22, 48, 2) + heart(186, 98, 4))
    her = Figure((48, 102), facing=1, woman=True, scale=0.85, lean=3, legs=((-16, -24), (18, 2)))
    him = Figure((104, 98), facing=1, scale=0.85, lean=3, legs=((20, 2), (-16, -26)))
    for fig, (bx, by, bw, bh) in ((her, (60, 66, 24, 20)), (him, (118, 58, 30, 26))):
        fig.reach(0, (bx + bw - 2, by + bh * 0.6))
        fig.reach(1, (bx + 2, by + bh * 0.7), elbow=-1)
    boxes = rect(60, 66, 24, 20, 2) + rect(118, 58, 30, 26, 2) + stroke("M 118 70 L 148 70", 1.5, PROP_BACK)
    scenes.append(house + her.svg("far") + him.svg("far") + her.svg() + him.svg() + boxes)

    return [svg(200, 180, body) for body in scenes]


def main():
    (HERE / "placeholder_couple.svg").write_text(couple())
    for k, scene in enumerate(moments(), start=1):
        (HERE / f"placeholder_moment_{k:02d}.svg").write_text(scene)
    print("Wrote placeholder_couple.svg and 12 moments")


if __name__ == "__main__":
    main()
