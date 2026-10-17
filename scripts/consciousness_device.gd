extends "res://scripts/inspect_object.gd"
## The final decision requires the recalled truth and access to the storage room.
@export var required_story_id: StringName = &"cg_05_true"
@export var branch_story_id: StringName = &"cg_04"
@export var required_branch_id: StringName = &"truth"
@export var opened_event: StringName = &"storage_room_opened"
## Coordinates relative to the containing Interactables node.
@export var player_access_rect := Rect2(35, 255, 385, 289)

func can_interact(context: Dictionary) -> bool:
	var player_position: Vector2 = get_parent().to_local(context["player"].global_position)
	return (
		super.can_interact(context)
		and context["state"].has_seen_memory_story(required_story_id)
		and context["state"].get_memory_story_branch(branch_story_id) == required_branch_id
		and context["state"].has_seen_story_event(opened_event)
		and player_access_rect.has_point(player_position)
	)

func interact(context: Dictionary) -> void:
	if context["ui"].modal_open or not can_interact(context):
		return
	interacted.emit(context)
	context["ui"].open_consciousness_device()
