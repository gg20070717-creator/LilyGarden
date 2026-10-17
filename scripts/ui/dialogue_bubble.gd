extends Control
## Shared artwork backing with a text area kept inside the rounded body.
const TEXTURE = preload("res://resources/art/ui/dialogue_bubble.tres")
const BODY_INSET := Vector2(0.16, 0.18)
const BODY_SIZE := Vector2(0.68, 0.58)
var tail_on_right := false:
	set(value):
		tail_on_right = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(queue_redraw)

func _draw() -> void:
	var destination := Rect2(Vector2.ZERO, size)
	if tail_on_right:
		# Negative width flips the texture while retaining its drawing origin.
		destination.size.x = -size.x
	draw_texture_rect(TEXTURE, destination, false)

func content_rect() -> Rect2:
	return Rect2(size * BODY_INSET, size * BODY_SIZE)

static func fit_text(label: Label, rect: Rect2, preferred_size: int, minimum_size: int = 24) -> void:
	var font := label.get_theme_font("font")
	var font_size := preferred_size
	var spacing := label.get_theme_constant("line_spacing")
	while font_size > minimum_size:
		var measured := font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, font_size)
		var lines := maxi(1, int(ceilf(measured.y / maxf(1.0, font.get_height(font_size)))))
		if measured.y + spacing * (lines - 1) <= rect.size.y:
			break
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)
	label.position = rect.position
	label.size = rect.size
	label.clip_text = true
