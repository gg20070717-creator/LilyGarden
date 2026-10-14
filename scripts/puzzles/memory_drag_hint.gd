extends Control
signal dismissed

const FONT = preload("res://ui_font.tres")
const HINT_SIZE := Vector2(460, 224)
const TEXT_COLOR := Color(0.82, 0.90, 0.96, 0.94)
const BORDER_COLOR := Color(0.54, 0.70, 0.79, 0.64)
const GLOW_COLOR := Color(0.44, 0.81, 0.98, 0.10)

var is_open := false
var _dismiss_pending := false
var _target_name := ""
var _fade_tween: Tween
var _first_line: Label
var _second_line: Label
var _footer: Label
var _panel := StyleBoxFlat.new()
var _mouse := StyleBoxFlat.new()
var _left_button := StyleBoxFlat.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = HINT_SIZE
	size = HINT_SIZE
	_setup_styles()
	_ensure_labels()
	if not is_open and not _dismiss_pending:
		hide()
	queue_redraw()


func _setup_styles() -> void:
	_panel.bg_color = Color(0.025, 0.065, 0.10, 0.76)
	_panel.border_color = BORDER_COLOR
	_panel.set_border_width_all(1)
	_panel.set_corner_radius_all(6)
	_panel.shadow_color = GLOW_COLOR
	_panel.shadow_size = 6
	_panel.shadow_offset = Vector2.ZERO
	_mouse.bg_color = Color(0.04, 0.10, 0.14, 0.36)
	_mouse.border_color = TEXT_COLOR
	_mouse.set_border_width_all(1)
	_mouse.set_corner_radius_all(8)
	_left_button.bg_color = Color(0.67, 0.86, 0.96, 0.64)
	_left_button.set_corner_radius_all(4)


func _ensure_labels() -> void:
	if is_instance_valid(_first_line):
		return
	_first_line = _make_label("Instruction", 24, Vector2(20, 14), Vector2(420, 34))
	_first_line.text = "按住左键，将记忆碎片"
	_second_line = _make_label("Destination", 24, Vector2(20, 48), Vector2(420, 34))
	_footer = _make_label("DismissHint", 19, Vector2(20, 184), Vector2(420, 26))
	_footer.text = "按任意键收起提示"
	_footer.add_theme_color_override("font_color", Color(0.70, 0.81, 0.89, 0.86))


func _make_label(node_name: String, font_size: int, at: Vector2, box: Vector2) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = at
	label.size = box
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_color_override("font_shadow_color", Color(0.015, 0.035, 0.055, 0.94))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
	return label


func present(target_name: String) -> void:
	if is_open or _dismiss_pending:
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_labels()
	_target_name = target_name
	_second_line.text = "拖到%s上松开" % target_name
	var text_width := FONT.get_string_size(_second_line.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var font_size := mini(24, maxi(12, int(24.0 * 420.0 / maxf(text_width, 1.0))))
	_second_line.add_theme_font_size_override("font_size", font_size)
	_stop_fade()
	is_open = true
	modulate.a = 0.0
	show()
	queue_redraw()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func dismiss() -> void:
	if not is_open:
		return
	is_open = false
	_dismiss_pending = true
	_stop_fade()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, 0.18)
	_fade_tween.tween_callback(_finish_dismiss)


func _finish_dismiss() -> void:
	if not _dismiss_pending:
		return
	_dismiss_pending = false
	hide()
	_fade_tween = null
	dismissed.emit()


func stop() -> void:
	is_open = false
	_dismiss_pending = false
	_stop_fade()
	modulate.a = 0.0
	hide()


func _stop_fade() -> void:
	if is_instance_valid(_fade_tween):
		_fade_tween.kill()
	_fade_tween = null


func _draw() -> void:
	draw_style_box(_panel, Rect2(Vector2.ZERO, HINT_SIZE))
	draw_line(Vector2(28, 176), Vector2(432, 176), Color(0.54, 0.70, 0.79, 0.20), 1.0)
	_draw_mouse(Vector2(76, 102))
	_draw_moon(Vector2(186, 127), 23.0)
	var arrow_start := Vector2(226, 127)
	var arrow_end := Vector2(292, 127)
	draw_line(arrow_start, arrow_end, GLOW_COLOR, 6.0, true)
	draw_line(arrow_start, arrow_end, TEXT_COLOR, 1.5, true)
	draw_polyline(PackedVector2Array([Vector2(283, 120), arrow_end, Vector2(283, 134)]), TEXT_COLOR, 1.5, true)
	_draw_destination(Vector2(350, 127))


func _draw_mouse(at: Vector2) -> void:
	draw_style_box(_mouse, Rect2(at, Vector2(36, 50)))
	draw_style_box(_left_button, Rect2(at + Vector2(3, 3), Vector2(14, 20)))
	draw_line(at + Vector2(18, 2), at + Vector2(18, 24), TEXT_COLOR, 1.0, true)
	draw_line(at + Vector2(2, 25), at + Vector2(34, 25), TEXT_COLOR, 1.0, true)
	draw_line(at + Vector2(21, 8), at + Vector2(21, 15), BORDER_COLOR, 2.0, true)


func _draw_moon(center: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for index in range(25):
		var angle := -PI * 0.5 + PI * float(index) / 24.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	for index in range(1, 24):
		var angle := PI * 0.5 - PI * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * 0.32, sin(angle)) * radius)
	draw_colored_polygon(points, Color(0.82, 0.93, 0.99, 0.88))
	points.append(points[0])
	draw_polyline(points, GLOW_COLOR, 5.0, true)
	draw_polyline(points, TEXT_COLOR, 1.0, true)


func _draw_destination(center: Vector2) -> void:
	if _target_name == "鱼缸":
		var tank := Rect2(center - Vector2(35, 25), Vector2(70, 50))
		draw_rect(tank, Color(0.08, 0.20, 0.28, 0.32))
		draw_rect(tank, BORDER_COLOR, false, 1.5)
		draw_line(center + Vector2(-31, -8), center + Vector2(31, -8), TEXT_COLOR, 1.0, true)
	else:
		var rim := PackedVector2Array()
		for index in range(49):
			var angle := TAU * float(index) / 48.0
			rim.append(center + Vector2(cos(angle) * 35, sin(angle) * 11 - 9))
		draw_colored_polygon(rim, Color(0.08, 0.20, 0.28, 0.32))
		draw_polyline(rim, TEXT_COLOR, 1.5, true)
		draw_line(center + Vector2(-35, -9), center + Vector2(-35, 18), BORDER_COLOR, 1.0, true)
		draw_line(center + Vector2(35, -9), center + Vector2(35, 18), BORDER_COLOR, 1.0, true)
		var lower_rim := PackedVector2Array()
		for index in range(25):
			var angle := PI * float(index) / 24.0
			lower_rim.append(center + Vector2(cos(angle) * 35, 18 + sin(angle) * 11))
		draw_polyline(lower_rim, BORDER_COLOR, 1.0, true)
	for offset in [-6.0, 4.0]:
		draw_line(center + Vector2(-17, offset), center + Vector2(17, offset), Color(0.67, 0.86, 0.96, 0.55), 1.0, true)
