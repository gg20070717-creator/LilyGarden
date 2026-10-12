extends Node2D
const LevelScript = preload("res://scripts/level.gd")
const InteractionScript = preload("res://scripts/interactable.gd")
## Owns the reusable player/UI/state; only the level instance is replaced.
@export_file("*.tscn") var initial_scene_path := "res://scenes/bedroom.tscn"
@export var initial_spawn: StringName = &"start"
## Visible world area at the reference aspect ratio; map geometry stays unchanged.
@export var camera_view_size := Vector2(1024, 576)
@onready var player = $World/Player
@onready var camera: Camera2D = $World/Camera
@onready var level_host: Node2D = $World/LevelHost
@onready var state = $GameState
@onready var ui = $UI
var level: LevelScript
var current_target: InteractionScript
var transitioning := false
var context: Dictionary

func _ready() -> void:
	_setup_input()
	context = {"game": self, "player": player, "state": state, "ui": ui}
	ui.view_state_changed.connect(_on_view_state_changed)
	state.fragment_acquired.connect(_on_fragment_acquired)
	get_viewport().size_changed.connect(_fit_camera)
	change_level(initial_scene_path, initial_spawn)

func _setup_input() -> void:
	var bindings := {
		"move_up": KEY_W, "move_down": KEY_S,
		"move_left": KEY_A, "move_right": KEY_D,
		"interact": KEY_F, "close_view": KEY_ESCAPE
	}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func _process(_delta: float) -> void:
	_update_camera()

func _physics_process(_delta: float) -> void:
	player.input_blocked = transitioning or ui.modal_open
	_select_target()

func _input(event: InputEvent) -> void:
	if transitioning:
		return
	if ui.modal_open:
		if ui.handle_modal_input(event):
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		_select_target()
		if is_instance_valid(current_target):
			current_target.interact(context)
		get_viewport().set_input_as_handled()

func _select_target() -> void:
	var nearest: InteractionScript
	var nearest_distance: float = INF
	if is_instance_valid(level) and not transitioning and not ui.modal_open:
		for node: Node in level.get_interactables():
			var candidate := node as InteractionScript
			if candidate == null or not candidate.can_interact(context):
				continue
			if not candidate.is_in_interaction_range(player.global_position, player.interaction_range):
				continue
			var distance: float = player.global_position.distance_to(candidate.global_position)
			if distance < nearest_distance:
				nearest = candidate
				nearest_distance = distance
	if current_target != nearest:
		if is_instance_valid(current_target):
			current_target.set_highlight(false)
		current_target = nearest
		if is_instance_valid(current_target):
			current_target.set_highlight(true)
	if is_instance_valid(current_target):
		ui.set_prompt("按F交互", current_target.global_position + current_target.prompt_offset)
	else:
		ui.set_prompt("")

func change_level(scene_path: String, spawn_id: StringName) -> bool:
	if transitioning:
		return false
	transitioning = true
	player.input_blocked = true
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Cannot load level: " + scene_path)
		transitioning = false
		player.input_blocked = ui.modal_open
		return false
	var next_level := packed.instantiate() as LevelScript
	var marker: Marker2D = next_level.get_spawn(spawn_id)
	if marker == null:
		push_error("Missing spawn '%s' in %s" % [spawn_id, scene_path])
		next_level.free()
		transitioning = false
		player.input_blocked = ui.modal_open
		return false
	if is_instance_valid(current_target):
		current_target.set_highlight(false)
	current_target = null
	ui.clear_note()
	if is_instance_valid(level):
		level_host.remove_child(level)
		level.queue_free()
	level = next_level
	level_host.add_child(level)
	player.global_position = marker.global_position
	player.velocity = Vector2.ZERO
	_fit_camera()
	ui.set_status(level.display_name, state.fragment_count())
	transitioning = false
	player.input_blocked = ui.modal_open
	_select_target()
	return true

func _fit_camera() -> void:
	if not is_instance_valid(level):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var view_size := camera_view_size.max(Vector2.ONE)
	var zoom_factor := minf(viewport_size.x / view_size.x, viewport_size.y / view_size.y)
	camera.zoom = Vector2.ONE * maxf(zoom_factor, 0.001)
	_update_camera()

func _update_camera() -> void:
	if not is_instance_valid(level):
		return
	var bounds: Rect2 = level.camera_bounds
	var half_view := get_viewport().get_visible_rect().size / camera.zoom * 0.5
	# Player position is at the feet; follow the middle of the visible body.
	var target: Vector2 = player.global_position - Vector2(0, player.body_height * 0.5)
	for axis: int in range(2):
		if bounds.size[axis] <= half_view[axis] * 2.0:
			target[axis] = bounds.get_center()[axis]
		else:
			target[axis] = clampf(target[axis], bounds.position[axis] + half_view[axis], bounds.end[axis] - half_view[axis])
	camera.global_position = target
	# Refresh before UI projects its world-anchored interaction labels.
	camera.force_update_scroll()

func _on_view_state_changed(is_open: bool) -> void:
	$World.visible = not ui.is_puzzle_open()
	player.input_blocked = is_open or transitioning
	player.velocity = Vector2.ZERO
	_select_target()

func _on_fragment_acquired(_fragment_id: StringName) -> void:
	ui.set_status(level.display_name, state.fragment_count())
