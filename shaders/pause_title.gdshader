shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec4 sample_color = texture(TEXTURE, UV);
	float ink = clamp((sample_color.r - 26.0 / 255.0) / (1.0 - 26.0 / 255.0), 0.0, 1.0);
	COLOR = vec4(vec3(1.0), sample_color.a * ink);
}
