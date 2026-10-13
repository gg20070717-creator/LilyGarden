extends "res://scripts/inspect_object.gd"
## A clickable memory source with the shared image/text/reward presentation.
@export var fragment_id: StringName
@export var fragment_display_name := ""
@export var artwork: Texture2D

func can_interact(context: Dictionary) -> bool:
	return super.can_interact(context) and fragment_id != &""

func get_highlight_color() -> Color:
	return MEMORY_GLOW_COLOR

func interact(context: Dictionary) -> void:
	if context["ui"].modal_open:
		return
	interacted.emit(context)
	context["state"].collect_fragment(fragment_id)
	var notice := "获得一个记忆碎片" if fragment_display_name.is_empty() else "获得记忆碎片‘%s’" % fragment_display_name
	var pages: Array[String] = [text, notice]
	context["ui"].show_collection(pages, artwork, &"", 1, true, true)
