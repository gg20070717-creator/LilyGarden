extends Control
@export_range(0, 1) var slot_index := 0
var puzzle
var line_color := Color(0.2, 0.2, 0.2)
var moonlight_style := false
var line_width: float = 1.4
var empty_opacity: float = 0.66
var _drag_light := 0.0
var _pulse_light := 0.0
var _fade_tween: Tween
var _pulse_tween: Tween

func _ready() -> void:
	resized.connect(queue_redraw)
	set_process(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN and moonlight_style and is_visible_in_tree():
		if _fade_tween != null:
			_fade_tween.kill()
		set_process(true)
	elif what == NOTIFICATION_DRAG_END and moonlight_style:
		set_process(false)
		_fade_drag_light()
		queue_redraw()

func _process(delta: float) -> void:
	if not moonlight_style or not is_visible_in_tree() or not get_viewport().gui_is_dragging():
		set_process(false)
		_fade_drag_light()
		return
	var data: Variant = get_viewport().gui_get_drag_data()
	# Reading the slot's rectangle also works while its filled word covers this Control.
	var valid: bool = puzzle != null and puzzle.accepts_drag(data, &"word")
	var hovered: bool = valid and get_global_rect().has_point(get_global_mouse_position())
	var next_light := move_toward(_drag_light, 1.0 if hovered else 0.0, delta * 9.0)
	if not is_equal_approx(next_light, _drag_light):
		_set_drag_light(next_light)

func _set_drag_light(value: float) -> void:
	_drag_light = value
	queue_redraw()

func _fade_drag_light() -> void:
	if _fade_tween != null:
		_fade_tween.kill()
	if not is_inside_tree() or is_zero_approx(_drag_light):
		return
	_fade_tween = create_tween()
	_fade_tween.tween_method(_set_drag_light, _drag_light, 0.0, 0.16)

func pulse() -> void:
	if not moonlight_style:
		return
	if _pulse_tween != null:
		_pulse_tween.kill()
	_set_pulse_light(1.0)
	_pulse_tween = create_tween()
	_pulse_tween.tween_method(_set_pulse_light, 1.0, 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _set_pulse_light(value: float) -> void:
	_pulse_light = value
	queue_redraw()

func _exit_tree() -> void:
	if _fade_tween != null:
		_fade_tween.kill()
	if _pulse_tween != null:
		_pulse_tween.kill()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return puzzle != null and puzzle.accepts_drag(data, &"word")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	puzzle.assign_word(data["choice_id"], slot_index)

func _draw() -> void:
	if not moonlight_style:
		draw_line(Vector2(4, size.y * 0.82), Vector2(size.x - 4, size.y * 0.82), line_color, 3.0, true)
		return
	var occupied: bool = puzzle != null and slot_index < puzzle.slot_ids.size() and puzzle.slot_ids[slot_index] != &""
	var strength: float = (0.34 if occupied else empty_opacity) + 0.26 * _drag_light + 0.36 * _pulse_light
	var arc := PackedVector2Array()
	for index in range(25):
		var t := float(index) / 24.0
		arc.append(Vector2(lerpf(4.0, size.x - 4.0, t), size.y * 0.79 + 6.0 * (1.0 - pow(t * 2.0 - 1.0, 2.0))))
	if line_width > 1.4:
		draw_polyline(arc, Color(0.02, 0.08, 0.16, 0.24 * strength), line_width + 3.0, true)
	var glow_growth: float = maxf(0.0, line_width - 1.4)
	draw_polyline(arc, Color(0.34, 0.74, 0.96, 0.055 * strength), 9.0 + glow_growth * 2.0, true)
	draw_polyline(arc, Color(0.49, 0.82, 1.0, 0.13 * strength), 4.0 + glow_growth, true)
	draw_polyline(arc, Color(0.79, 0.94, 1.0, 0.95 * strength), line_width + 0.3 * _pulse_light, true)
