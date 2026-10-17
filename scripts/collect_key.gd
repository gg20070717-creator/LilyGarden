extends "res://scripts/interactable.gd"
@export var key_id: StringName = &"studio_key_01"
@export var item_name := "画室钥匙"
@export_multiline var acquisition_text := ""
@export var artwork: Texture2D = preload("res://resources/art/ui/key_icon.tres")

func interact(context: Dictionary) -> void:
	interacted.emit(context)
	context["state"].collect_key(key_id)
	var pages: Array[String] = [acquisition_text if not acquisition_text.is_empty() else item_name]
	context["ui"].show_collection(pages, artwork, &"key")
