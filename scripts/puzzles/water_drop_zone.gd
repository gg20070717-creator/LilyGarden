extends Control
var puzzle
var drop_polygon := PackedVector2Array()
## Fragment-only bounds in local coordinates, including the caller's scaled margin.
var fragment_drop_rect := Rect2()
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

func contains_fragment_local(point: Vector2) -> bool:
	return fragment_drop_rect.has_point(point) if fragment_drop_rect.has_area() else contains_local(point)

func _has_point(point: Vector2) -> bool:
	if puzzle != null and get_viewport().gui_is_dragging():
		var data: Variant = get_viewport().gui_get_drag_data()
		if puzzle.accepts_drag(data, &"moon"):
			return contains_fragment_local(point)
	return contains_local(point)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if puzzle == null:
		return false
	if puzzle.accepts_drag(data, &"moon"):
		return contains_fragment_local(at_position)
	return puzzle.accepts_drag(data, &"word") and contains_local(at_position)

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

