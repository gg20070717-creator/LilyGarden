shader_type canvas_item;
render_mode unshaded;

// Separable Gaussian blur. A BackBufferCopy between passes preserves the X pass.
// https://docs.godotengine.org/en/stable/tutorials/shaders/custom_postprocessing.html
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 direction = vec2(1.0, 0.0);
uniform float radius : hint_range(0.0, 8.0) = 4.0;

void fragment() {
	// Dense samples avoid repeated outlines around the pixel-art furniture.
	vec2 step_uv = direction * SCREEN_PIXEL_SIZE * (radius / 4.0);
	vec3 blurred = vec3(0.0);
	for (int tap = -12; tap <= 12; tap++) {
		float offset = float(tap);
		float weight = exp(-offset * offset / 32.0) * 0.0999083581;
		blurred += texture(screen_texture, SCREEN_UV + step_uv * offset).rgb * weight;
	}
	COLOR = vec4(blurred, 1.0);
}
