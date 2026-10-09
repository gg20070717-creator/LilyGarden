extends RefCounted
## Shared readable text treatment, without adding any UI copy.
static func apply(label: Label, font_size: int = 36) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 0)
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color(1, 1, 1, 0.96)
	backing.content_margin_left = 16
	backing.content_margin_right = 16
	backing.content_margin_top = 8
	backing.content_margin_bottom = 8
	backing.corner_radius_top_left = 6
	backing.corner_radius_top_right = 6
	backing.corner_radius_bottom_left = 6
	backing.corner_radius_bottom_right = 6
	label.add_theme_stylebox_override("normal", backing)
