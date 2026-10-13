extends Area2D
const InteractionGlow = preload("res://scripts/interaction_glow.gd")
const MEMORY_GLOW_COLOR := Color(0.3843137, 0.772549, 1.0, 1.0)
## The only contract the player needs. New interactions subclass this script.
signal interacted(context: Dictionary)
@export var interaction_id: StringName
@export var prompt := "交互"
@export var enabled := true
@export var prompt_offset := Vector2(0, -48)
## Optional local foot-position area. Empty keeps the player default radius.
@export var interaction_rect := Rect2()
## Bind the visible object independently of its foot-position interaction area.
@export_node_path("Node2D") var visual_path: NodePath
var highlighted := false
var _glow: InteractionGlow

func can_interact(_context: Dictionary) -> bool:
	return enabled

func is_in_interaction_range(world_position: Vector2, default_range: float) -> bool:
	if interaction_rect.has_area():
		return interaction_rect.has_point(to_local(world_position))
	return global_position.distance_to(world_position) < default_range

func interact(context: Dictionary) -> void:
	interacted.emit(context)

func get_highlight_color() -> Color:
	return Color.WHITE

func set_highlight(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	if value and not is_instance_valid(_glow):
		if visual_path.is_empty():
			return
		var visual := get_node_or_null(visual_path) as Node2D
		if visual == null:
			return
		_glow = InteractionGlow.new()
		_glow.name = "InteractionGlow"
		visual.add_child(_glow)
		_glow.bind_visual(visual)
	if is_instance_valid(_glow):
		_glow.set_active(value, get_highlight_color())
