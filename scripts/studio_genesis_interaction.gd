extends "res://scripts/inspect_object.gd"
## Fill these pages when the Act Two Genesis performance is supplied.
@export var story_pages: Array[Dictionary] = []

func can_interact(context: Dictionary) -> bool:
	return super.can_interact(context) and not story_pages.is_empty()

func interact(context: Dictionary) -> void:
	if context["ui"].modal_open or not can_interact(context):
		return
	interacted.emit(context)
	context["ui"].show_dialogue(story_pages)
