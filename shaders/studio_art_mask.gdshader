shader_type canvas_item;

// The source pack uses opaque white canvases. TEXTURE is a white silhouette
// mask, so source pixels and enclosed white details can stay unchanged.
uniform sampler2D source_texture : source_color, filter_nearest, repeat_disable;
uniform vec4 source_rect = vec4(0.0, 0.0, 1.0, 1.0);

void fragment() {
	vec4 source_pixel = texture(source_texture, source_rect.xy + UV * source_rect.zw);
	COLOR *= source_pixel;
}
