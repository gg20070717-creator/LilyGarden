shader_type canvas_item;
render_mode unshaded;

uniform sampler2D mask_texture : filter_linear, repeat_disable;
uniform bool textured = false;
uniform bool ellipse = false;
uniform vec2 content_center = vec2(0.0);
uniform vec2 content_size = vec2(1.0);
uniform vec2 screen_scale = vec2(1.0);
uniform vec4 source_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 source_texel_size = vec2(0.001);
uniform vec4 glow_color : source_color = vec4(1.0);
uniform float outline_width_px = 3.2;
uniform float halo_radius_px = 9.0;
uniform float intensity = 0.0;

varying vec2 local_position;
varying vec4 item_color;

void vertex() {
	local_position = VERTEX;
	item_color = COLOR;
}

float source_alpha(vec2 point) {
	vec2 uv = (point - content_center) / content_size + vec2(0.5);
	if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
		return 0.0;
	}
	// Match AtlasTexture clipping and avoid filtering pixels from nearby regions.
	vec2 source_uv = source_rect.xy + uv * source_rect.zw;
	vec2 first_texel = source_rect.xy + source_texel_size * 0.5;
	vec2 last_texel = source_rect.xy + source_rect.zw - source_texel_size * 0.5;
	return texture(mask_texture, clamp(source_uv, first_texel, last_texel)).a;
}

float shape_distance(vec2 point) {
	vec2 p = (point - content_center) * screen_scale;
	vec2 half_size = max(content_size * screen_scale * 0.5, vec2(0.001));
	if (ellipse) {
		// Gradient-corrected ellipse distance preserves thickness on long ovals.
		float k0 = length(p / half_size);
		float k1 = length(p / (half_size * half_size));
		if (k1 < 0.00001) {
			return -min(half_size.x, half_size.y);
		}
		return k0 * (k0 - 1.0) / k1;
	}
	vec2 q = abs(p) - half_size;
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
}

void fragment() {
	float alpha = 0.0;
	if (textured) {
		float center = source_alpha(local_position);
		float edge = 0.0;
		float halo_near = 0.0;
		float halo_middle = 0.0;
		float halo_far = 0.0;
		// Only the highlighted object and its short fade-out use these samples.
		for (int i = 0; i < 16; i++) {
			float angle = float(i) * 6.28318530718 / 16.0;
			vec2 direction = vec2(cos(angle), sin(angle)) / screen_scale;
			edge = max(edge, source_alpha(local_position + direction * outline_width_px));
			halo_near += source_alpha(local_position + direction * (outline_width_px + halo_radius_px * 0.35));
			halo_middle += source_alpha(local_position + direction * (outline_width_px + halo_radius_px * 0.75));
			halo_far += source_alpha(local_position + direction * (outline_width_px + halo_radius_px * 1.25));
		}
		float halo = (halo_near * 0.55 + halo_middle * 0.3 + halo_far * 0.15) / 16.0;
		alpha = max(edge * 0.97, halo * 0.9) * (1.0 - center);
	} else {
		float distance_px = shape_distance(local_position);
		float outside = smoothstep(-0.25, 0.75, distance_px);
		float edge = 1.0 - smoothstep(outline_width_px - 0.6, outline_width_px + 0.6, distance_px);
		float halo_distance = max(distance_px - outline_width_px, 0.0) / halo_radius_px;
		float halo = exp(-halo_distance * halo_distance * 2.0) * 0.42;
		alpha = max(edge * 0.97, halo) * outside;
	}
	COLOR = vec4(glow_color.rgb, alpha * glow_color.a * intensity) * item_color;
}
