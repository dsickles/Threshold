// The Tuner's screen (DAS-135): static over a scan picture. A canvas shader
// on one rectangle, never a CompositorEffect (they don't run in the browser).
// The chapter look from requirements.md: grain, colour split and broken-up
// lines while the signal is lost; all of it falls away as `clarity` rises.
// The scan picture itself is a PLACEHOLDER drawn here (an ultrasound fan
// with a small bean-shaped baby in it) until real art is made (ADR-0010).
shader_type canvas_item;

uniform float clarity : hint_range(0.0, 1.0) = 0.0; // 1: the picture is clear
uniform float signal_level : hint_range(0.0, 1.0) = 0.0; // how much signal is coming through
uniform float hum : hint_range(0.0, 1.0) = 0.0; // the false signal: slow rolling bars
uniform float beat : hint_range(0.0, 1.0) = 0.0; // the heartbeat's flicker, on each beat
uniform float clock = 0.0; // seconds; stops while paused
uniform float aspect = 1.6; // width over height of the rectangle

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float smooth_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// PLACEHOLDER scan picture, in the rectangle's own units (y down).
float scan(vec2 uv) {
	vec2 p = vec2((uv.x - 0.5) * aspect, uv.y);
	vec2 apex = vec2(0.0, 0.04);
	vec2 d = p - apex;
	float r = length(d);
	float a = atan(d.x, d.y);
	float fan = step(abs(a), 0.62) * step(0.12, r) * step(r, 0.95);
	float speckle = smooth_noise(vec2(a * 60.0, r * 90.0)) * 0.55 + 0.15;
	speckle *= smoothstep(0.95, 0.5, r);
	// The sac: a dark oval in the middle of the fan.
	vec2 sac = (p - vec2(0.02, 0.55)) / vec2(0.36, 0.24);
	float in_sac = smoothstep(1.05, 0.9, length(sac));
	float rim = smoothstep(1.2, 1.0, length(sac)) - in_sac;
	// The baby: a head and a curled body, bright.
	float head = smoothstep(0.075, 0.06, length(p - vec2(-0.12, 0.52)));
	vec2 body_p = (p - vec2(0.03, 0.58)) / vec2(0.15, 0.085);
	float body = smoothstep(1.0, 0.85, length(body_p));
	float baby = max(head, body) * (0.75 + 0.25 * smooth_noise(p * 40.0));
	float picture = speckle * (1.0 - in_sac * 0.85) + rim * 0.35 + baby * 0.85;
	return picture * fan;
}

void fragment() {
	vec2 uv = UV;
	float lost = 1.0 - clarity;
	float t = clock;
	// Broken lines: bands of the picture slip sideways while the signal is lost.
	float row = floor(uv.y * 48.0);
	float tear = (hash(vec2(row, floor(t * 12.0))) - 0.5) * step(0.8, hash(vec2(row * 0.37, floor(t * 7.0))));
	uv.x += tear * 0.12 * lost;
	// The false signal rolls slow bars down the screen, steady as a hum.
	float bars = hum * 0.18 * sin((uv.y - t * 0.35) * 18.0);
	// Colour split.
	float split = 0.012 * lost + 0.004 * beat;
	float red = scan(uv + vec2(split, 0.0));
	float green = scan(uv);
	float blue = scan(uv - vec2(split, 0.0));
	vec3 picture = vec3(red, green, blue) * vec3(0.92, 0.97, 1.0);
	// The picture shows only as the signal comes through.
	float seen = clamp(clarity + signal_level * 0.25, 0.0, 1.0);
	picture *= seen * (1.0 + beat * 0.12);
	// Static: grain, brightest when nothing is coming through.
	float grain = hash(floor(UV * vec2(320.0, 180.0)) + floor(t * 30.0) * 1.7);
	float amount = lost * (0.85 - signal_level * 0.35);
	vec3 noise = vec3(grain) * 0.75 + bars;
	vec3 colour = mix(picture, noise, clamp(amount, 0.0, 1.0));
	// A little grain is left even when clear, like a real screen.
	colour += (grain - 0.5) * 0.05;
	// Dark edges.
	vec2 edge = UV - 0.5;
	colour *= 1.0 - dot(edge, edge) * 0.9;
	COLOR = vec4(colour, 1.0);
}
