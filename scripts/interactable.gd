extends Area2D
## The only contract the player needs. New interactions subclass this script.
signal interacted(context: Dictionary)
@export var interaction_id: StringName
@export var prompt := "交互"
@export var enabled := true
@export var prompt_offset := Vector2(0, -48)
var highlighted := false

func can_interact(_context: Dictionary) -> bool:
	return enabled

func interact(context: Dictionary) -> void:
	interacted.emit(context)

func set_highlight(value: bool) -> void:
	highlighted = value
