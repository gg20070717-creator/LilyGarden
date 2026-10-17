extends Control
const FONT = preload("res://ui_font.tres")
const MOON_EDGE_FADE = preload("res://shaders/moon_fragment_edge_fade.gdshader")
var choice: Resource
var token_kind: StringName = &"moon"
var puzzle
var light_backing := false
var word_color := Color.BLACK
var word_font_size: int = 46
var moonlight_style := false
var _hover_light := 0.0
var _drag_preview := false
var _hover_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if puzzle != null else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	if token_kind == &"moon":
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_configure_moon_material()
	resized.connect(queue_redraw)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	queue_redraw()

func _get_drag_data(at_position: Vector2) -> Variant:
	if puzzle == null or choice == null or not puzzle.can_drag(token_kind, choice.choice_id):
		return null
	var preview = Control.new()
	preview.set_script(get_script())
	preview.choice = choice
	preview.token_kind = token_kind
	preview.light_backing = light_backing
	preview.word_color = word_color
	preview.word_font_size = word_font_size
	preview.moonlight_style = moonlight_style
	preview._drag_preview = true
	preview.size = size
	preview.position = -at_position
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_drag_preview(preview)
	modulate.a = 0.35
	return {"kind": token_kind, "choice_id": choice.choice_id, "puzzle_instance": puzzle.get_instance_id()}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0
		if moonlight_style and token_kind == &"word" and is_inside_tree():
			_set_hover(Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position()))

func _on_mouse_entered() -> void:
	_set_hover(true)

func _on_mouse_exited() -> void:
	_set_hover(false)

func _set_hover(hovered: bool) -> void:
	if not moonlight_style or token_kind != &"word" or puzzle == null:
		return
	if _hover_tween != null:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_method(_set_hover_light, _hover_light, 1.0 if hovered else 0.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _set_hover_light(value: float) -> void:
	_hover_light = value
	queue_redraw()

func _exit_tree() -> void:
	if _hover_tween != null:
		_hover_tween.kill()

func _draw() -> void:
	if choice == null:
		return
	if light_backing:
		if token_kind == &"moon":
			draw_circle(size * 0.5, minf(size.x, size.y) * 0.48, Color(1, 1, 1, 0.96), true, -1.0, true)
		else:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.96))
	if token_kind == &"word":
		var font_size: int = word_font_size
		var text: String = choice.word
		var text_size := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var at := Vector2((size.x - text_size.x) * 0.5, (size.y + FONT.get_ascent(font_size)) * 0.5 - 5)
		if moonlight_style:
			_draw_moonlight_word(at, text, font_size)
		else:
			if word_color != Color.BLACK:
				draw_string(FONT, at + Vector2(1, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.03, 0.07, 0.11, 0.9))
			draw_string(FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, word_color)
	elif choice.moon_texture != null:
		_draw_moon_texture(choice.moon_texture)
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

func _configure_moon_material() -> void:
	if choice == null or choice.moon_texture == null:
		return
	var texture: Texture2D = choice.moon_texture
	if not texture.has_meta("moon_reference_diameter"):
		return
	var source_texture: Texture2D = texture
	var source_region := Rect2(Vector2.ZERO, texture.get_size())
	while source_texture is AtlasTexture:
		var atlas_texture := source_texture as AtlasTexture
		source_region.position += atlas_texture.region.position
		source_texture = atlas_texture.atlas
	var source_size := source_texture.get_size()
	var uv_rect := Rect2(source_region.position / source_size, source_region.size / source_size)
	var edge_material := ShaderMaterial.new()
	edge_material.shader = MOON_EDGE_FADE
	edge_material.set_shader_parameter("source_rect", Vector4(uv_rect.position.x, uv_rect.position.y, uv_rect.size.x, uv_rect.size.y))
	edge_material.set_shader_parameter("source_size_px", source_region.size)
	var moon_center: Vector2 = texture.get_meta("moon_reference_center", source_region.size * 0.5)
	edge_material.set_shader_parameter("moon_center_px", moon_center)
	material = edge_material

func _draw_moon_texture(texture: Texture2D) -> void:
	var texture_size := texture.get_size()
	var draw_scale := minf(size.x / texture_size.x, size.y / texture_size.y)
	var reference_center := texture_size * 0.5
	if texture.has_meta("moon_reference_diameter"):
		var reference_diameter := maxf(float(texture.get_meta("moon_reference_diameter")), 1.0)
		draw_scale = minf(size.x, size.y) * 0.76 / reference_diameter
		reference_center = texture.get_meta("moon_reference_center", reference_center)
	# Keep all phases on the same lunar circle, including the drag preview.
	var rendered_size := texture_size * draw_scale
	draw_texture_rect(texture, Rect2(size * 0.5 - reference_center * draw_scale, rendered_size), false)

func _draw_moonlight_word(at: Vector2, text: String, font_size: int) -> void:
	var light := 1.0 if _drag_preview else _hover_light
	# Raise only the painted text; the original drag and drop rectangle stays fixed.
	at.y -= 3.0 * light
	var ink := Color(0.89, 0.96, 1.0) if word_color == Color.BLACK else word_color
	ink = ink.lerp(Color(0.99, 1.0, 1.0, ink.a), 0.26 * light)
	draw_string_outline(FONT, at + Vector2(0, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 2, Color(0.02, 0.07, 0.12, 0.65))
	draw_string_outline(FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 10, Color(0.32, 0.72, 0.91, 0.035 + 0.025 * light))
	draw_string_outline(FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color(0.44, 0.81, 0.98, 0.075 + 0.045 * light))
	draw_string_outline(FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 2, Color(0.59, 0.88, 1.0, 0.16 + 0.07 * light))
	draw_string(FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)

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
