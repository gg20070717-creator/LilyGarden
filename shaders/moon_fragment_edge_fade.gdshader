shader_type canvas_item;
render_mode unshaded;

// AtlasTexture supplies source-image UVs; convert them to its local crop first.
uniform vec4 source_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 source_size_px = vec2(1.0);
uniform vec2 moon_center_px = vec2(0.5);
uniform float edge_feather_px = 18.0;

void fragment() {
	vec2 local_uv = (UV - source_rect.xy) / max(source_rect.zw, vec2(0.000001));
	vec2 local_pixel = local_uv * source_size_px;
	vec2 center_to_edges = min(moon_center_px, source_size_px - moon_center_px);
	float outer_radius_px = min(center_to_edges.x, center_to_edges.y);
	float distance_px = length(local_pixel - moon_center_px);
	float inner_radius_px = max(outer_radius_px - edge_feather_px, 0.0);
	COLOR.a *= 1.0 - smoothstep(inner_radius_px, outer_radius_px, distance_px);
}
