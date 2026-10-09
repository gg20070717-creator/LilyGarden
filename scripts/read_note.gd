extends "res://scripts/interactable.gd"
@export var text := "来水井边见我"
@export var duration := 4.0
@export var text_offset := Vector2(-105, -145)

func interact(context: Dictionary) -> void:
	interacted.emit(context)
	context["ui"].show_note(text, global_position + text_offset, duration)
