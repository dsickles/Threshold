shader_type canvas_item;
// The Anchor's storm (DAS-138): rain driven across the House, the dark
// coming in round the edges, and now and then a flash of lightning. A canvas
// shader over the drawn House, so it runs in the browser (no
// CompositorEffects, no volumetric fog). PLACEHOLDER look.

uniform float clock = 0.0;
// 0 in the calm, 1 in the full storm.
uniform float storm : hint_range(0.0, 1.0) = 0.0;
// 0 to 1 just after a lightning strike.
uniform float flash : hint_range(0.0, 1.0) = 0.0;
// Which way the wind drives the rain: -1 left, 1 right.
uniform float wind = 0.0;
uniform float aspect = 1.7778;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// One layer of rain: thin streaks falling at an angle, in columns.
float rain_layer(vec2 uv, float scale, float speed, float slant, float seed) {
	vec2 p = uv * vec2(scale * aspect, scale * 0.25);
	p.x += p.y * slant;
	p.y += clock * speed;
	vec2 cell = floor(p);
	vec2 inside = fract(p);
	float h = hash(cell + seed);
	float column = smoothstep(0.06, 0.0, abs(inside.x - h));
	float streak = smoothstep(0.0, 0.3, inside.y) * smoothstep(1.0, 0.6, inside.y);
	return column * streak * step(0.45, h);
}

void fragment() {
	vec2 uv = UV;
	float slant = 0.15 + wind * 0.35;
	float rain = rain_layer(uv, 38.0, 9.0, slant, 1.0) * 0.55
			+ rain_layer(uv, 22.0, 6.0, slant * 0.8, 7.0) * 0.35;
	rain *= storm;
	// The dark coming in round the edges as the storm grows.
	vec2 c = (uv - 0.5) * vec2(aspect, 1.0);
	float vignette = smoothstep(0.35, 1.1, length(c)) * (0.25 + 0.5 * storm);
	float dark = 0.12 + 0.38 * storm;
	vec3 colour = mix(vec3(0.02, 0.025, 0.04), vec3(0.75, 0.8, 0.9), rain);
	float alpha = clamp(dark + vignette + rain * 0.6, 0.0, 0.92);
	// Lightning washes the House pale for a moment.
	colour = mix(colour, vec3(0.85, 0.88, 1.0), flash);
	alpha = mix(alpha, 0.35, flash);
	COLOR = vec4(colour, alpha);
}
