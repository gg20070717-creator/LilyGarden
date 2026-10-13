extends Control
## A quiet keyboard hint. The puzzle owns its visibility and fade animation.
const FONT = preload("res://ui_font.tres")
const KEY_FONT_SIZE := 25
const CAPTION_FONT_SIZE := 28
const TEXT_COLOR := Color(0.82, 0.90, 0.96, 0.94)
var _key_label: Label
var _caption_label: Label
var _keycap := StyleBoxFlat.new()
var _keycap_rect := Rect2()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_keycap.bg_color = Color(0.025, 0.065, 0.10, 0.18)
	_keycap.border_color = Color(0.54, 0.70, 0.79, 0.64)
	_keycap.set_border_width_all(1)
	_keycap.set_corner_radius_all(5)
	_ensure_labels()
	resized.connect(_layout)
	_layout()

func set_hint(key: String, caption: String) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_labels()
	_key_label.text = key
	_caption_label.text = caption
	_layout()

func _ensure_labels() -> void:
	if is_instance_valid(_key_label):
		return
	_key_label = Label.new()
	_key_label.name = "Key"
	_caption_label = Label.new()
	_caption_label.name = "Caption"
	for label: Label in [_key_label, _caption_label]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_override("font", FONT)
		label.add_theme_color_override("font_color", TEXT_COLOR)
		label.add_theme_color_override("font_shadow_color", Color(0.015, 0.035, 0.055, 0.94))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(label)
	_key_label.add_theme_font_size_override("font_size", KEY_FONT_SIZE)
	_caption_label.add_theme_font_size_override("font_size", CAPTION_FONT_SIZE)

func _layout() -> void:
	if not is_instance_valid(_key_label):
		return
	var key_width := maxf(48.0, FONT.get_string_size(_key_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, KEY_FONT_SIZE).x + 22.0)
	var caption_width := FONT.get_string_size(_caption_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_FONT_SIZE).x + 4.0
	var gap := 14.0 if not _caption_label.text.is_empty() else 0.0
	var height := minf(44.0, maxf(1.0, size.y))
	var origin := Vector2((size.x - key_width - gap - caption_width) * 0.5, (size.y - height) * 0.5)
	_keycap_rect = Rect2(origin, Vector2(key_width, height))
	_key_label.position = origin
	_key_label.size = _keycap_rect.size
	_caption_label.position = origin + Vector2(key_width + gap, 0)
	_caption_label.size = Vector2(caption_width, height)
	queue_redraw()

func _draw() -> void:
	if _keycap_rect.has_area():
		draw_style_box(_keycap, _keycap_rect)
