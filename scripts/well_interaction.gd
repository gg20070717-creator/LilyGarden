extends "res://scripts/interactable.gd"
@export var definition: Resource = preload("res://resources/well_memory_puzzle.tres")
@export var message_duration := 4.0
@export var message_offset := Vector2(0, -195)

func interact(context: Dictionary) -> void:
	interacted.emit(context)
	var owned_ids: Array[StringName] = context["state"].owned_fragment_ids()
	var has_available_fragment := false
	for option: Resource in definition.options:
		if owned_ids.has(option.fragment_id):
			has_available_fragment = true
			break
	if not has_available_fragment:
		context["ui"].show_note("水面很平静，毫无波澜", global_position + message_offset, message_duration)
		return
	context["ui"].open_puzzle(definition, owned_ids)
