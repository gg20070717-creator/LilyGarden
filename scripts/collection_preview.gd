extends Control
## Item artwork, with the shared key icon as the fallback for key pickups.
const KEY_ICON: Texture2D = preload("res://resources/art/ui/key_icon.tres")
var artwork: Texture2D
var placeholder_type: StringName

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var texture := artwork
	if texture == null and placeholder_type == &"key":
		texture = KEY_ICON
	if texture != null:
		var image_size := texture.get_size()
		var fit := minf(size.x / image_size.x, size.y / image_size.y)
		var fitted := image_size * fit
		draw_texture_rect(texture, Rect2((size - fitted) * 0.5, fitted), false)
