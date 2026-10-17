extends Node
## Session state survives level replacement. Persistent saves can later wrap this node.
signal fragment_acquired(fragment_id: StringName)
signal key_acquired(key_id: StringName)
var fragments: Dictionary = {}
var keys: Dictionary = {}
var seen_story_events: Dictionary = {}
## Stable combination-story IDs, recorded only after their complete narrative ends.
var seen_memory_stories: Dictionary = {}
## The most recently completed branch and its future story target for each story.
var memory_story_branches: Dictionary = {}
## Ending unlocks belong to this game session, like fragments and CG progress.
var unlocked_endings: Dictionary = {}
var current_ending: StringName = &""

func unlock_ending(ending_id: StringName) -> void:
	if ending_id in [&"end1", &"end2"]:
		unlocked_endings[ending_id] = true
		current_ending = ending_id

func collect_fragment(fragment_id: StringName) -> bool:
	if fragments.has(fragment_id):
		return false
	fragments[fragment_id] = true
	fragment_acquired.emit(fragment_id)
	return true

func has_fragment(fragment_id: StringName) -> bool:
	return fragments.has(fragment_id)

func fragment_count() -> int:
	return fragments.size()

func owned_fragment_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for fragment_id: StringName in fragments:
		result.append(fragment_id)
	return result

func collect_key(key_id: StringName) -> bool:
	if keys.has(key_id):
		return false
	keys[key_id] = true
	key_acquired.emit(key_id)
	return true

func has_key(key_id: StringName) -> bool:
	return keys.has(key_id)

func has_seen_story_event(event_id: StringName) -> bool:
	return seen_story_events.has(event_id)

func mark_story_event_seen(event_id: StringName) -> void:
	seen_story_events[event_id] = true

func has_seen_memory_story(story_id: StringName) -> bool:
	return seen_memory_stories.has(story_id)

func mark_memory_story_seen(story_id: StringName) -> void:
	if story_id != &"":
		seen_memory_stories[story_id] = true

func record_memory_story_branch(story_id: StringName, branch_id: StringName, next_story_id: StringName) -> void:
	if story_id == &"" or branch_id == &"" or next_story_id == &"":
		return
	memory_story_branches[story_id] = {"branch_id": branch_id, "next_story_id": next_story_id}

func get_memory_story_branch(story_id: StringName) -> StringName:
	var record: Dictionary = memory_story_branches.get(story_id, {})
	return StringName(record.get("branch_id", &""))

func get_next_memory_story(story_id: StringName) -> StringName:
	var record: Dictionary = memory_story_branches.get(story_id, {})
	return StringName(record.get("next_story_id", &""))
