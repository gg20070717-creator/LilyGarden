shader_type canvas_item;
render_mode unshaded, blend_mix;

// One source PNG supplies both the title and its anti-aliased alpha mask.
uniform vec2 tilt_degrees = vec2(0.0);
uniform float rect_aspect = 2.090909;
uniform float camera_distance : hint_range(2.0, 6.0) = 3.0;
uniform float content_scale : hint_range(0.65, 0.95) = 0.88;
uniform float elapsed = 0.0;
uniform float sheen_cycle : hint_range(2.0, 30.0) = 10.0;
uniform float base_brightness : hint_range(0.5, 1.0) = 0.82;
uniform float sheen_strength : hint_range(0.0, 1.0) = 0.60;
uniform float sheen_width : hint_range(0.05, 0.5) = 0.22;
uniform float glow_strength : hint_range(0.0, 0.15) = 0.025;
uniform bool sheen_enabled = true;
uniform vec4 blue_tint : source_color = vec4(0.47, 0.78, 1.0, 1.0);
uniform vec4 purple_tint : source_color = vec4(0.80, 0.69, 0.97, 1.0);
uniform sampler2D highlight_mask : hint_default_white, filter_linear, repeat_disable;
uniform bool use_highlight_mask = false;

varying vec4 item_modulate;

void vertex() {
    // Fragment COLOR already includes a texture sample at the original UV.
    // Save the vertex modulation separately before re-projecting the texture.
    item_modulate = COLOR;
}

void fragment() {
    float aspect = max(rect_aspect, 0.1);
    vec2 angle = radians(tilt_degrees);
    float cy = cos(angle.x);
    float sy = sin(angle.x);
    float cx = cos(angle.y);
    float sx = sin(angle.y);
    // The title is a single plane rotated by Ry(yaw) * Rx(pitch).
    vec3 axis_x = vec3(cy, 0.0, -sy);
    vec3 axis_y = vec3(sy * sx, cx, cy * sx);
    vec3 normal = vec3(sy * cx, -sx, cy * cx);
    vec2 q = (UV - vec2(0.5)) * vec2(aspect, 1.0) / content_scale;
    float denominator = camera_distance * normal.z - dot(normal.xy, q);
    float ray_t = camera_distance * normal.z / max(denominator, 0.001);
    vec3 hit = vec3(q * ray_t, camera_distance * (1.0 - ray_t));
    vec2 source_uv = vec2(dot(axis_x, hit) / aspect, dot(axis_y, hit)) + vec2(0.5);

    if (source_uv.x < 0.0 || source_uv.y < 0.0 || source_uv.x > 1.0 || source_uv.y > 1.0) {
        COLOR = vec4(0.0);
    } else {
        vec4 source = texture(TEXTURE, source_uv);
        vec3 ink = source.rgb * base_brightness;
        float phase = fract(elapsed / max(sheen_cycle, 0.1) + 0.44);
        float center = mix(-0.4, 1.4, phase);
        float coordinate = source_uv.x + 0.12 * (source_uv.y - 0.5);
        float band = (coordinate - center) / max(sheen_width, 0.01);
        float sweep = exp(-0.5 * band * band);
        float mask_value = 1.0;
        if (use_highlight_mask) {
            mask_value = texture(highlight_mask, source_uv).r;
        }
        float enabled = sheen_enabled ? 1.0 : 0.0;
        vec3 tint = mix(blue_tint.rgb, purple_tint.rgb, smoothstep(-0.8, 0.8, band));
        float amount = sweep * sheen_strength * mask_value * enabled;
        ink = mix(ink, tint, clamp(amount, 0.0, 1.0));
        float core = exp(-pow(band / 0.16, 2.0)) * 0.34 * mask_value * enabled;
        ink = mix(ink, vec3(0.96, 0.98, 1.0), core);

        // A very faint local halo, independent of HDR/bloom project settings.
        float halo = 0.0;
        if (glow_strength > 0.0 && sheen_enabled) {
            vec2 pixel = TEXTURE_PIXEL_SIZE * 2.0;
            float nearby = (
                texture(TEXTURE, source_uv + vec2(pixel.x, 0.0)).a +
                texture(TEXTURE, source_uv - vec2(pixel.x, 0.0)).a +
                texture(TEXTURE, source_uv + vec2(0.0, pixel.y)).a +
                texture(TEXTURE, source_uv - vec2(0.0, pixel.y)).a +
                texture(TEXTURE, source_uv + pixel).a +
                texture(TEXTURE, source_uv - pixel).a +
                texture(TEXTURE, source_uv + vec2(pixel.x, -pixel.y)).a +
                texture(TEXTURE, source_uv + vec2(-pixel.x, pixel.y)).a
            ) / 8.0;
            halo = max(nearby - source.a, 0.0) * glow_strength * sweep * mask_value;
        }
        float out_alpha = source.a + halo * (1.0 - source.a);
        vec3 premultiplied = ink * source.a + tint * halo * (1.0 - source.a);
        vec3 straight_rgb = premultiplied / max(out_alpha, 0.00001);
        COLOR = vec4(straight_rgb, out_alpha) * item_modulate;
    }
}
