extends "res://scripts/inspect_object.gd"
## Assign the dedicated brush-wash puzzle when its fragments and answer are supplied.
@export var puzzle_definition: Resource

func interact(context: Dictionary) -> void:
	if context["ui"].modal_open or not can_interact(context):
		return
	if puzzle_definition != null:
		var owned_ids: Array[StringName] = context["state"].owned_fragment_ids()
		for option: Resource in puzzle_definition.options:
			if option != null and owned_ids.has(option.fragment_id):
				interacted.emit(context)
				context["ui"].open_puzzle(puzzle_definition, owned_ids)
				return
	super.interact(context)
