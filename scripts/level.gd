extends Node2D
## A level owns geometry, interactables and named arrival markers.
@export var level_id: StringName
@export var display_name := ""
@export var camera_bounds := Rect2(0, 0, 1280, 720)

func get_spawn(spawn_id: StringName) -> Marker2D:
	return get_node_or_null(NodePath("SpawnPoints/" + String(spawn_id))) as Marker2D

func get_interactables() -> Array[Node]:
	return $Interactables.get_children()

func get_playable_bounds() -> Rect2:
	return $MovementBounds.area
