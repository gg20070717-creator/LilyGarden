extends Control
const FONT = preload("res://ui_font.tres")
var choice: Resource
var token_kind: StringName = &"moon"
var puzzle
var light_backing := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if puzzle != null else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	queue_redraw()

func _get_drag_data(at_position: Vector2) -> Variant:
	if puzzle == null or choice == null or not puzzle.can_drag(token_kind, choice.choice_id):
		return null
	var preview = Control.new()
	preview.set_script(get_script())
	preview.choice = choice
	preview.token_kind = token_kind
	preview.light_backing = light_backing
	preview.size = size
	preview.position = -at_position
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_drag_preview(preview)
	modulate.a = 0.35
	return {"kind": token_kind, "choice_id": choice.choice_id, "puzzle_instance": puzzle.get_instance_id()}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0

func _draw() -> void:
	if choice == null:
		return
	if light_backing:
		if token_kind == &"moon":
			draw_circle(size * 0.5, minf(size.x, size.y) * 0.48, Color(1, 1, 1, 0.96), true, -1.0, true)
		else:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.96))
	if token_kind == &"word":
		var font_size := 46
		var text: String = choice.word
		var text_size := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(FONT, Vector2((size.x - text_size.x) * 0.5, (size.y + FONT.get_ascent(font_size)) * 0.5 - 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)
	elif choice.moon_texture != null:
		draw_texture_rect(choice.moon_texture, Rect2(Vector2.ZERO, size), false)
	else:
		var radius := minf(size.x, size.y) * 0.38
		var center := size * 0.5
		if choice.moon_fraction >= 0.999:
			draw_circle(center, radius, Color.WHITE, true, -1.0, true)
			draw_circle(center, radius, Color(0.15, 0.15, 0.15), false, 3.0, true)
		else:
			var outline := _moon_outline(center, radius, choice.moon_fraction)
			draw_colored_polygon(outline, Color.WHITE)
			outline.append(outline[0])
			draw_polyline(outline, Color(0.15, 0.15, 0.15), 3.0, true)

func _moon_outline(center: Vector2, radius: float, illumination: float) -> PackedVector2Array:
	# The outside is a circular semicircle; the terminator is an elliptical arc.
	# At half moon the ellipse narrows to a line, then bows out toward full moon.
	var points := PackedVector2Array()
	const SEGMENTS := 64
	for index in range(SEGMENTS + 1):
		var angle := -PI * 0.5 + PI * index / SEGMENTS
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	var ellipse_width := 1.0 - 2.0 * clampf(illumination, 0.0, 1.0)
	for index in range(1, SEGMENTS):
		var angle := PI * 0.5 - PI * index / SEGMENTS
		points.append(center + Vector2(ellipse_width * cos(angle), sin(angle)) * radius)
	return points

# An occupied slot remains a drop target even when its word covers it.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return puzzle != null and token_kind == &"word" and puzzle.slot_ids.find(choice.choice_id) >= 0 and puzzle.accepts_drag(data, &"word")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	puzzle.assign_word(data["choice_id"], puzzle.slot_ids.find(choice.choice_id))
