// The Arrival's screen for the cry beat (DAS-137): static over a picture,
// the same grain, colour split and broken lines as the Tuner's screen
// (scenes/chapters/tuner/tuner_screen.gdshader, copied, not shared), so
// hearing the cry clears the static the same way (Story 8.1). A canvas
// shader on one rectangle, never a CompositorEffect (they don't run in the
// browser).
// What the static clears to is PROPOSED and a PLACEHOLDER: a small warm
// light, the Loss's small light come back (continuity ledger, "The small
// light": "an idea: a small light in the Tuner or the Arrival"). No baby
// model (FR30). It waits on Dan's photos (story-beats.md §8).
shader_type canvas_item;

uniform float clarity : hint_range(0.0, 1.0) = 0.0; // 1: the picture is clear
uniform float signal_level : hint_range(0.0, 1.0) = 0.0; // how much of the cry comes through
uniform float cry : hint_range(0.0, 1.0) = 0.0; // the cry's loudness now, for the flicker
uniform float clock = 0.0; // seconds; stops while paused
uniform float aspect = 1.6; // width over height of the rectangle

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// PLACEHOLDER picture: a dark warm room and a small light in the middle of it.
vec3 picture(vec2 uv) {
	vec2 p = vec2((uv.x - 0.5) * aspect, uv.y - 0.5);
	float r = length(p);
	vec3 room = mix(vec3(0.20, 0.13, 0.10), vec3(0.08, 0.06, 0.05), clamp(r * 1.4, 0.0, 1.0));
	float glow = exp(-r * r / 0.03) * 0.9 + exp(-r * r / 0.002) * 0.8;
	vec3 light = vec3(1.0, 0.86, 0.62) * glow;
	return room + light;
}

void fragment() {
	vec2 uv = UV;
	float lost = 1.0 - clarity;
	float t = clock;
	// Broken lines: bands slip sideways while the signal is lost.
	float row = floor(uv.y * 48.0);
	float tear = (hash(vec2(row, floor(t * 12.0))) - 0.5) * step(0.8, hash(vec2(row * 0.37, floor(t * 7.0))));
	uv.x += tear * 0.12 * lost;
	// Colour split, and a small kick with the cry.
	float split = 0.012 * lost + 0.004 * cry;
	vec3 seen_colour = vec3(picture(uv + vec2(split, 0.0)).r, picture(uv).g, picture(uv - vec2(split, 0.0)).b);
	float seen = clamp(clarity + signal_level * 0.25, 0.0, 1.0);
	seen_colour *= seen * (1.0 + cry * 0.1);
	// Static: grain, brightest when nothing is coming through.
	float grain = hash(floor(UV * vec2(320.0, 180.0)) + floor(t * 30.0) * 1.7);
	float amount = lost * (0.85 - signal_level * 0.35);
	vec3 colour = mix(seen_colour, vec3(grain) * 0.75, clamp(amount, 0.0, 1.0));
	colour += (grain - 0.5) * 0.05;
	vec2 edge = UV - 0.5;
	colour *= 1.0 - dot(edge, edge) * 0.9;
	COLOR = vec4(colour, 1.0);
}
