// Proof square for the heavy switch: green only when the 3D picture is really
// being drawn at twice the screen's width (4x the pixels), gray otherwise.
shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;

uniform float screen_width = 1.0;

void fragment() {
	bool heavy_is_real = VIEWPORT_SIZE.x > screen_width * 1.5;
	ALBEDO = heavy_is_real ? vec3(0.2, 0.8, 0.3) : vec3(0.35);
}
