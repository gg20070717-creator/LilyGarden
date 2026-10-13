extends Control
## One keyboard guide for each newly loaded gameplay instance.
const FONT = preload("res://ui_font.tres")
var was_shown := false
var is_open := false
var fade_tween: Tween

func _ready() -> void:
	name = "ControlsHint"
	size = Vector2(400, 350)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := Panel.new()
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color(0.98, 0.98, 0.98, 0.97)
	backing.border_color = Color(0.55, 0.55, 0.55)
	backing.set_border_width_all(2)
	backing.set_corner_radius_all(10)
	backing.shadow_color = Color(0, 0, 0, 0.20)
	backing.shadow_size = 6
	backing.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", backing)
	add_child(panel)
	_label(panel, "按", Vector2(24, 62), Vector2(40, 48))
	_keycap(panel, "W", Vector2(130, 24))
	_keycap(panel, "A", Vector2(70, 84))
	_keycap(panel, "S", Vector2(130, 84))
	_keycap(panel, "D", Vector2(190, 84))
	_label(panel, "移动", Vector2(270, 62), Vector2(100, 48))
	_label(panel, "按", Vector2(24, 160), Vector2(40, 52))
	_keycap(panel, "F", Vector2(70, 160))
	_label(panel, "交互", Vector2(190, 160), Vector2(170, 52))
	_label(panel, "按", Vector2(24, 224), Vector2(40, 52))
	_keycap(panel, "Esc", Vector2(70, 224), 88)
	_label(panel, "暂停", Vector2(190, 224), Vector2(170, 52))
	var footer := _label(panel, "按任意键关闭提示", Vector2(24, 300), Vector2(352, 30), 22)
	footer.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	get_viewport().size_changed.connect(_fit)
	_fit()
	hide()

func _label(parent: Node, text: String, at: Vector2, box: Vector2, font_size: int = 32) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = box
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _keycap(parent: Node, key: String, at: Vector2, width: float = 52) -> void:
	var cap := Panel.new()
	cap.position = at
	cap.size = Vector2(width, 52)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = Color(0.40, 0.40, 0.40)
	style.set_border_width_all(2)
	style.border_width_bottom = 5
	style.set_corner_radius_all(6)
	cap.add_theme_stylebox_override("panel", style)
	parent.add_child(cap)
	var label := _label(cap, key, Vector2(0, -2), cap.size, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _fit() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
	scale = Vector2.ONE * fit
	position = Vector2(32, 32) * fit

func present_once() -> void:
	if was_shown:
		return
	was_shown = true
	is_open = true
	modulate.a = 0.0
	show()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func handle_input(event: InputEvent) -> bool:
	if not is_open:
		return false
	if event is InputEventKey and event.pressed and not event.echo:
		is_open = false
		if is_instance_valid(fade_tween):
			fade_tween.kill()
		fade_tween = create_tween()
		fade_tween.tween_property(self, "modulate:a", 0.0, 0.18)
		fade_tween.tween_callback(hide)
		return true
	return false
