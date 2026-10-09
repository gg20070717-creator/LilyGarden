extends "res://scripts/interactable.gd"
@export var title := "窗外"
@export_multiline var placeholder_caption := "月亮与水井场景 CG 占位符"
@export var artwork: Texture2D
@export var artworks: Array[Texture2D] = []
@export_range(0.1, 30.0) var slide_duration := 2.0

func interact(context: Dictionary) -> void:
	interacted.emit(context)
	if not artworks.is_empty():
		context["ui"].show_slideshow(title, artworks, slide_duration)
	else:
		context["ui"].show_view(title, placeholder_caption, artwork)
