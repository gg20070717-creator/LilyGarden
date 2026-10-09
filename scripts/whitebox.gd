@tool
extends StaticBody2D
## Editable collision footprint, optional artwork and a whitebox fallback.

## Art replaces only the drawing. Keep size/solid as the gameplay footprint.
@export var artwork: Texture2D:
	set(value):
		artwork = value
		_refresh()
## Zero fits the texture proportionally inside size. Set explicitly for backgrounds.
@export var artwork_size := Vector2.ZERO:
	set(value):
		artwork_size = value
		queue_redraw()
@export var artwork_offset := Vector2.ZERO:
	set(value):
		artwork_offset = value
		queue_redraw()
@export var draw_placeholder := true:
	set(value):
		draw_placeholder = value
		queue_redraw()

@export var size := Vector2(100, 80):
	set(value):
		size = value
		_refresh()
@export_multiline var label := "":
	set(value):
		label = value
		_refresh()
@export var shade := Color(0.9, 0.9, 0.9):
	set(value):
		shade = value
		queue_redraw()
@export var solid := true:
	set(value):
		solid = value
		_refresh()
@export var oval := false:
	set(value):
		oval = value
		_refresh()
@export var label_size := 24:
	set(value):
		label_size = value
		_refresh()

func _ready() -> void:
	_refresh()

func _ellipse_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(48):
		var angle := TAU * index / 48.0
		points.append(Vector2(cos(angle), sin(angle)) * size * 0.5)
	return points

func _refresh() -> void:
	queue_redraw()
	if not is_inside_tree():
		return
	var collision := get_node_or_null("Collision") as CollisionShape2D
	if collision:
		if oval:
			var shape := ConvexPolygonShape2D.new()
			shape.points = _ellipse_points()
			collision.shape = shape
		else:
			var shape := RectangleShape2D.new()
			shape.size = size
			collision.shape = shape
		collision.disabled = not solid
	var text := get_node_or_null("Label") as Label
	if text:
		text.text = label
		text.visible = artwork == null and not label.is_empty()
		text.add_theme_font_size_override("font_size", label_size)
		text.position = -size * 0.5
		text.size = size

func _draw() -> void:
	if artwork != null:
		var rendered_size := artwork_size
		if rendered_size == Vector2.ZERO:
			var source_size := artwork.get_size()
			rendered_size = source_size * minf(size.x / source_size.x, size.y / source_size.y)
		draw_texture_rect(artwork, Rect2(artwork_offset - rendered_size * 0.5, rendered_size), false)
		return
	if not draw_placeholder:
		return
	if oval:
		var points := _ellipse_points()
		draw_colored_polygon(points, shade)
		points.append(points[0])
		draw_polyline(points, Color(0.25, 0.25, 0.25), 3.0, true)
	else:
		var rect := Rect2(-size * 0.5, size)
		draw_rect(rect, shade)
		draw_rect(rect, Color(0.25, 0.25, 0.25), false, 3.0)
