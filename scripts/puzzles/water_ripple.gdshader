shader_type canvas_item;
render_mode unshaded;

// Keep the delivered canvas intact; sample its shared alpha bounds at runtime.
uniform vec4 source_rect = vec4(0.036, 0.4448, 0.9216, 0.254);
uniform vec4 ripple_tint : source_color = vec4(0.38, 0.62, 0.78, 0.40);

void fragment() {
	vec2 water_uv = UV * 2.0 - 1.0;
	float edge_alpha = 1.0 - smoothstep(0.94, 1.0, length(water_uv));
	vec4 frame = texture(TEXTURE, source_rect.xy + UV * source_rect.zw);
	COLOR = vec4(ripple_tint.rgb, frame.a * ripple_tint.a * edge_alpha);
}
