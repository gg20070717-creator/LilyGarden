extends Control
## Short, local accents only. Coordinates are local to the parent puzzle root.
var _word_trails: Array[Dictionary] = []
var _sentence_sweeps: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(not _word_trails.is_empty() or not _sentence_sweeps.is_empty())

func emit_word_trail(from: Vector2, to: Vector2, duration: float) -> void:
	_word_trails.append({
		"from": get_transform().affine_inverse() * from,
		"to": get_transform().affine_inverse() * to,
		"duration": clampf(duration, 0.12, 1.1),
		"elapsed": 0.0,
	})
	set_process(true)
	queue_redraw()

func pulse_sentence(rect: Rect2, duration: float = 0.5) -> void:
	if not rect.has_area():
		return
	_sentence_sweeps.append({
		"rect": get_transform().affine_inverse() * rect,
		"duration": clampf(duration, 0.12, 1.1),
		"elapsed": 0.0,
	})
	set_process(true)
	queue_redraw()

func clear_effects() -> void:
	_word_trails.clear()
	_sentence_sweeps.clear()
	set_process(false)
	queue_redraw()

func _process(delta: float) -> void:
	_advance_effects(_word_trails, delta)
	_advance_effects(_sentence_sweeps, delta)
	set_process(not _word_trails.is_empty() or not _sentence_sweeps.is_empty())
	queue_redraw()

func _advance_effects(effects: Array[Dictionary], delta: float) -> void:
	for index in range(effects.size() - 1, -1, -1):
		var effect: Dictionary = effects[index]
		effect["elapsed"] = float(effect["elapsed"]) + delta
		if float(effect["elapsed"]) >= float(effect["duration"]):
			effects.remove_at(index)

func _draw() -> void:
	for trail: Dictionary in _word_trails:
		_draw_word_trail(trail)
	for sweep: Dictionary in _sentence_sweeps:
		_draw_sentence_sweep(sweep)

func _draw_word_trail(trail: Dictionary) -> void:
	var from: Vector2 = trail["from"]
	var to: Vector2 = trail["to"]
	var progress := float(trail["elapsed"]) / float(trail["duration"])
	var direction := (to - from).normalized()
	var normal := Vector2(-direction.y, direction.x)
	for index in range(6):
		var delay := float(index) * 0.024
		var t := clampf((progress - delay) / (1.0 - delay), 0.0, 1.0)
		var alpha := sin(t * PI) * (0.48 - float(index) * 0.035)
		if alpha <= 0.0:
			continue
		var travel := smoothstep(0.0, 1.0, t)
		var drift := sin(float(index) * 2.4) * (3.0 + float(index)) * sin(t * PI)
		var point := from.lerp(to, travel) + normal * drift
		var tail := from.lerp(to, maxf(0.0, travel - 0.018)) + normal * drift
		draw_line(tail, point, Color(0.47, 0.79, 0.95, alpha * 0.20), 1.0, true)
		draw_circle(point, 6.0, Color(0.41, 0.76, 0.94, alpha * 0.08))
		draw_circle(point, 3.1, Color(0.53, 0.84, 1.0, alpha * 0.22))
		draw_circle(point, 1.3, Color(0.78, 0.94, 1.0, alpha))

func _draw_sentence_sweep(sweep: Dictionary) -> void:
	var rect: Rect2 = sweep["rect"]
	var progress := float(sweep["elapsed"]) / float(sweep["duration"])
	var alpha := sin(progress * PI)
	var center_x := lerpf(rect.position.x - 16.0, rect.end.x + 16.0, progress)
	for index in range(3):
		var half_width := 14.0 - float(index) * 5.0
		var strip := Rect2(Vector2(center_x - half_width, rect.position.y), Vector2(half_width * 2.0, rect.size.y)).intersection(rect)
		if strip.has_area():
			draw_rect(strip, Color(0.65, 0.88, 1.0, alpha * (0.035 + float(index) * 0.018)))
