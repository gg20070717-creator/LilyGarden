extends "res://scripts/interactable.gd"
@export var key_id: StringName = &"studio_key_01"
@export var item_name := "画室钥匙"
@export var artwork: Texture2D

func interact(context: Dictionary) -> void:
	interacted.emit(context)
	context["state"].collect_key(key_id)
	var pages: Array[String] = [item_name]
	context["ui"].show_collection(pages, artwork, &"key")
