extends Control
## Code-native item placeholder; a texture can replace it without changing pickup logic.
var artwork: Texture2D
var placeholder_type: StringName

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if artwork != null:
		var image_size := artwork.get_size()
		var fit := minf(size.x / image_size.x, size.y / image_size.y)
		var fitted := image_size * fit
		draw_texture_rect(artwork, Rect2((size - fitted) * 0.5, fitted), false)
	elif placeholder_type == &"key":
		var radius := minf(size.x, size.y) * 0.19
		var ring := Vector2(size.x * 0.26, size.y * 0.45)
		var shaft_end := Vector2(size.x * 0.87, ring.y)
		draw_arc(ring, radius, 0, TAU, 64, Color.BLACK, 6, true)
		draw_line(ring + Vector2(radius, 0), shaft_end, Color.BLACK, 6, true)
		for fraction in [0.68, 0.84]:
			var tooth := Vector2(size.x * fraction, ring.y)
			draw_line(tooth, tooth + Vector2(0, radius * 0.8), Color.BLACK, 6, true)
