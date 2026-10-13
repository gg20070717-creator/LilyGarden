extends "res://scripts/interactable.gd"
@export var fragment_id: StringName = &"bedroom_photo_01"
@export var fragment_display_name := ""
@export_multiline var narrative_text := ""
@export var title := "照片"
@export_multiline var placeholder_caption := "照片占位符\n（前妻在月光前的照片）"
@export var artwork: Texture2D

func get_highlight_color() -> Color:
	return MEMORY_GLOW_COLOR

func interact(context: Dictionary) -> void:
	interacted.emit(context)
	context["state"].collect_fragment(fragment_id)
	var notice := "获得一个记忆碎片" if fragment_display_name.is_empty() else "获得记忆碎片‘%s’" % fragment_display_name
	var pages: Array[String] = [narrative_text, notice]
	context["ui"].show_collection(pages, artwork, &"", 1, true, true)
