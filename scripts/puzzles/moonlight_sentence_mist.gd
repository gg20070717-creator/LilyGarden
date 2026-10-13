extends Control
## A quiet, soft-edged pool of blue shade beneath the sentence.
var opacity_value: float = 0.21:
	set(value):
		opacity_value = clampf(value, 0.0, 1.0)
		queue_redraw()

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if opacity_value <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
		return
	const LAYERS := 10
	const SEGMENTS := 64
	# All ten layers overlap at the center. Their combined opacity equals the
	# requested value rather than accumulating ten copies of that opacity.
	var layer_alpha := 1.0 - pow(1.0 - opacity_value, 1.0 / float(LAYERS))
	var center := size * 0.5
	for layer in range(LAYERS):
		var radius := size * 0.5 * lerpf(1.0, 0.64, float(layer) / float(LAYERS - 1))
		var points := PackedVector2Array()
		for index in range(SEGMENTS):
			var angle := TAU * float(index) / float(SEGMENTS)
			points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		draw_colored_polygon(points, Color(0.025, 0.07, 0.12, layer_alpha))
