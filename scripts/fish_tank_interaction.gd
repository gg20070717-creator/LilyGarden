extends "res://scripts/inspect_object.gd"
## The fish tank shares inspection input and opens only with a matching memory.
const INTRO_EVENT: StringName = &"fish_tank_memory_intro"
@export var definition: Resource = preload("res://resources/fish_tank_memory_puzzle.tres")
@export var required_story_id: StringName = &"cg_02"

func get_highlight_color() -> Color:
	return MEMORY_GLOW_COLOR

func interact(context: Dictionary) -> void:
	if context["ui"].modal_open:
		return
	if not context["state"].has_seen_memory_story(required_story_id):
		super.interact(context)
		return
	var owned_ids: Array[StringName] = context["state"].owned_fragment_ids()
	for option: Resource in definition.options:
		if owned_ids.has(option.fragment_id):
			interacted.emit(context)
			var show_intro: bool = not context["state"].has_seen_story_event(INTRO_EVENT)
			var opened: bool = context["ui"].open_puzzle(definition, owned_ids, show_intro)
			if opened and show_intro and context["ui"].active_puzzle.introduction_started:
				context["state"].mark_story_event_seen(INTRO_EVENT)
			return
	super.interact(context)
