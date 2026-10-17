extends "res://scripts/inspect_object.gd"
## Stage four opens after the complete fish-tank story; inventory stays caller-owned.
const INTRO_EVENT: StringName = &"tent_storage_memory_intro"
@export var definition: Resource = preload("res://resources/tent_storage_memory_puzzle.tres")
@export var puzzle_scene: PackedScene = preload("res://scenes/puzzles/tent_storage_memory_puzzle.tscn")
@export var required_story_id: StringName = &"cg_03"

func get_highlight_color() -> Color:
	return MEMORY_GLOW_COLOR

func interact(context: Dictionary) -> void:
	if context["ui"].modal_open or not can_interact(context):
		return
	if not context["state"].has_seen_memory_story(required_story_id):
		super.interact(context)
		return
	var owned_ids: Array[StringName] = context["state"].owned_fragment_ids()
	for option: Resource in definition.options:
		if option != null and owned_ids.has(option.fragment_id):
			interacted.emit(context)
			var show_intro: bool = not context["state"].has_seen_story_event(INTRO_EVENT)
			var opened: bool = context["ui"].open_puzzle(definition, owned_ids, show_intro, puzzle_scene)
			if opened and show_intro and context["ui"].active_puzzle.introduction_started:
				context["state"].mark_story_event_seen(INTRO_EVENT)
			return
	super.interact(context)
