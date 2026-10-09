extends Control
@export_range(0, 1) var slot_index := 0
var puzzle

func _ready() -> void:
	resized.connect(queue_redraw)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return puzzle != null and puzzle.accepts_drag(data, &"word")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	puzzle.assign_word(data["choice_id"], slot_index)

func _draw() -> void:
	draw_line(Vector2(4, size.y * 0.82), Vector2(size.x - 4, size.y * 0.82), Color(0.2, 0.2, 0.2), 3.0, true)
