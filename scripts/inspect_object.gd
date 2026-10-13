extends "res://scripts/interactable.gd"
## Text-only inspection, available through a direct click or nearby F.
@export_multiline var text := ""

func contains_click(world_position: Vector2) -> bool:
	var visual := get_node_or_null(visual_path) as Node2D
	if visual == null:
		return false
	var value: Variant = visual.get("size")
	if not value is Vector2:
		return false
	var visual_size: Vector2 = value
	if visual_size.x <= 0 or visual_size.y <= 0:
		return false
	var local := visual.to_local(world_position)
	if bool(visual.get("oval")):
		return (local / (visual_size * 0.5)).length_squared() <= 1.0
	return Rect2(-visual_size * 0.5, visual_size).has_point(local)

func interact(context: Dictionary) -> void:
	if context["ui"].modal_open:
		return
	interacted.emit(context)
	var pages: Array[String] = [text]
	context["ui"].show_collection(pages)
