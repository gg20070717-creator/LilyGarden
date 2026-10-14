extends "res://scripts/inspect_object.gd"
## The studio bucket shares inventory and the common memory-puzzle flow.
const INTRO_EVENT: StringName = &"brush_wash_memory_intro"
@export var puzzle_definition: Resource = preload("res://resources/brush_wash_memory_puzzle.tres")

func get_highlight_color() -> Color:
	return MEMORY_GLOW_COLOR

func interact(context: Dictionary) -> void:
	if context["ui"].modal_open or not can_interact(context):
		return
	if puzzle_definition != null:
		var owned_ids: Array[StringName] = context["state"].owned_fragment_ids()
		for option: Resource in puzzle_definition.options:
			if option != null and owned_ids.has(option.fragment_id):
				interacted.emit(context)
				var show_intro: bool = not context["state"].has_seen_story_event(INTRO_EVENT)
				var opened: bool = context["ui"].open_puzzle(puzzle_definition, owned_ids, show_intro)
				if opened and show_intro and context["ui"].active_puzzle.introduction_started:
					context["state"].mark_story_event_seen(INTRO_EVENT)
				return
	super.interact(context)
