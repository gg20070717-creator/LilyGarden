extends "res://scripts/inspect_object.gd"
## The fish tank shares inspection input and opens only with a matching memory.
@export var definition: Resource = preload("res://resources/fish_tank_memory_puzzle.tres")

func get_highlight_color() -> Color:
	return MEMORY_GLOW_COLOR

func interact(context: Dictionary) -> void:
	if context["ui"].modal_open:
		return
	var owned_ids: Array[StringName] = context["state"].owned_fragment_ids()
	for option: Resource in definition.options:
		if owned_ids.has(option.fragment_id):
			interacted.emit(context)
			context["ui"].open_puzzle(definition, owned_ids, false)
			return
	super.interact(context)
