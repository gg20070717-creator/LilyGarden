extends Node
## Session state survives level replacement. Persistent saves can later wrap this node.
signal fragment_acquired(fragment_id: StringName)
signal key_acquired(key_id: StringName)
var fragments: Dictionary = {}
var keys: Dictionary = {}

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
