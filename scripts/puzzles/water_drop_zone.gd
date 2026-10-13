extends Control
var puzzle
var drop_polygon := PackedVector2Array()
var draw_surface := true:
	set(value):
		if draw_surface != value:
			draw_surface = value
			queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)

func contains_local(point: Vector2) -> bool:
	if size.x <= 0 or size.y <= 0:
		return false
	if drop_polygon.size() >= 3:
		return Geometry2D.is_point_in_polygon(point, drop_polygon)
	var normalized := (point - size * 0.5) / (size * 0.5)
	return normalized.length_squared() <= 1.0

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return puzzle != null and contains_local(at_position) and (puzzle.accepts_drag(data, &"moon") or puzzle.accepts_drag(data, &"word"))

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data["kind"] == &"moon":
		puzzle.add_moon(data["choice_id"])
	else:
		puzzle.remove_word(data["choice_id"])

func _draw() -> void:
	if not draw_surface:
		return
	var points := PackedVector2Array()
	for index in range(96):
		var angle := TAU * index / 96.0
		points.append(size * 0.5 + Vector2(cos(angle), sin(angle)) * size * 0.5)
	draw_colored_polygon(points, Color(0.94, 0.94, 0.94))
	points.append(points[0])
	draw_polyline(points, Color(0.2, 0.2, 0.2), 3.0, true)

