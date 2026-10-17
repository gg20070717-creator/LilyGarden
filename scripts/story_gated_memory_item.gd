extends "res://scripts/collect_memory_item.gd"
## A memory source becomes available after its required story is fully read.
@export var required_story_id: StringName

func can_interact(context: Dictionary) -> bool:
	return super.can_interact(context) and (required_story_id == &"" or context["state"].has_seen_memory_story(required_story_id))

func interact(context: Dictionary) -> void:
	if context["ui"].modal_open or not can_interact(context):
		return
	super.interact(context)
