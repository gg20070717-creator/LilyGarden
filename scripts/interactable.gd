extends Area2D
## The only contract the player needs. New interactions subclass this script.
signal interacted(context: Dictionary)
@export var interaction_id: StringName
@export var prompt := "交互"
@export var enabled := true
@export var prompt_offset := Vector2(0, -48)
## Optional local foot-position area. Empty keeps the player default radius.
@export var interaction_rect := Rect2()
var highlighted := false

func can_interact(_context: Dictionary) -> bool:
	return enabled

func is_in_interaction_range(world_position: Vector2, default_range: float) -> bool:
	if interaction_rect.has_area():
		return interaction_rect.has_point(to_local(world_position))
	return global_position.distance_to(world_position) < default_range

func interact(context: Dictionary) -> void:
	interacted.emit(context)

func set_highlight(value: bool) -> void:
	highlighted = value
