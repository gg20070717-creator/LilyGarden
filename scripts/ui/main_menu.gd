extends Node
## Main-menu shell. The original gameplay scene owns its existing session state.
signal page_requested(page_id: StringName)
signal load_slot_requested(slot_id: StringName)

const GAME_SCENE_PATH := "res://main.tscn"
const OpeningCinematic = preload("res://scripts/ui/opening_cinematic.gd")
const PauseMenuScene = preload("res://scenes/ui/pause_menu.tscn")
const REFERENCE_SIZE := Vector2(1920, 1080)
const EMPTY_PAGES: Array[StringName] = [&"load_game", &"settings", &"credits"]

@export var transition_duration := 0.5
@export var opening_black_delay := 0.65

@onready var game_host: Node = $GameHost
@onready var menu_root: Control = $MenuLayer/MenuRoot
@onready var artwork: Control = $MenuLayer/MenuRoot/Artwork
@onready var continue_button: TextureButton = $MenuLayer/MenuRoot/Artwork/ContinueGame
@onready var empty_page: Control = $MenuLayer/EmptyPage

var current_page: StringName = &"main"
var _game: Node2D
var pause_menu: CanvasLayer
var opening: OpeningCinematic
var transitioning := false
var transition_mask: ColorRect


func _ready() -> void:
	opening = OpeningCinematic.new()
	opening.name = "OpeningCinematic"
	add_child(opening)
	var transition_layer := CanvasLayer.new()
	transition_layer.name = "SceneTransition"
	transition_layer.layer = 100
	add_child(transition_layer)
	transition_mask = ColorRect.new()
	transition_mask.name = "BlackFade"
	transition_mask.color = Color(0, 0, 0, 0)
	transition_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_mask.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_layer.add_child(transition_mask)
	transition_mask.hide()
	pause_menu = PauseMenuScene.instantiate() as CanvasLayer
	add_child(pause_menu)
	pause_menu.connect("resume_requested", continue_game)
	pause_menu.connect("main_menu_requested", return_to_menu)
	pause_menu.connect("quit_requested", _on_quit_pressed)
	get_viewport().size_changed.connect(_fit_artwork)
	_fit_artwork()
	return_to_menu()


func _fit_artwork() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / REFERENCE_SIZE.x, viewport_size.y / REFERENCE_SIZE.y)
	artwork.scale = Vector2.ONE * fit
	artwork.position = (viewport_size - REFERENCE_SIZE * fit) * 0.5


func start_new_game() -> void:
	if transitioning:
		return
	# Lock input before any loading work so the menu responds immediately.
	transitioning = true
	current_page = &"transition"
	pause_menu.hide()
	await _fade_to(1.0)
	await _wait_for_black_frame()
	_suspend_game()
	menu_root.hide()
	empty_page.hide()
	var packed := await _load_game_scene()
	if packed == null:
		push_error("Cannot load gameplay scene: " + GAME_SCENE_PATH)
		await _restore_menu_after_load_failure()
		return
	# Every New Game starts with the entire story; Continue resumes its session.
	opening.prepare()
	await _fade_to(0.0)
	await get_tree().create_timer(opening_black_delay).timeout
	current_page = &"opening"
	opening.start()
	await opening.finished
	current_page = &"transition"
	await _fade_to(1.0)
	# Scene instantiation stays on the main thread behind an already drawn mask.
	await _wait_for_black_frame()
	opening.stop()
	if is_instance_valid(_game):
		game_host.remove_child(_game)
		_game.queue_free()
	_game = packed.instantiate() as Node2D
	game_host.add_child(_game)
	# Render the bedroom during the fade while keeping all gameplay frozen.
	_game.process_mode = Node.PROCESS_MODE_DISABLED
	await _fade_to(0.0)
	transitioning = false
	continue_game()


func _wait_for_black_frame() -> void:
	await get_tree().process_frame
	# Headless servers do not emit rendering signals.
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw


func _load_game_scene() -> PackedScene:
	var request_error := ResourceLoader.load_threaded_request(GAME_SCENE_PATH, "PackedScene", true)
	if request_error != OK:
		push_error("Cannot request gameplay scene load: " + error_string(request_error))
		return null
	while true:
		var status := ResourceLoader.load_threaded_get_status(GAME_SCENE_PATH)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			return ResourceLoader.load_threaded_get(GAME_SCENE_PATH) as PackedScene
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			return null
		await get_tree().process_frame
	return null


func _restore_menu_after_load_failure() -> void:
	empty_page.hide()
	menu_root.show()
	continue_button.disabled = not is_instance_valid(_game)
	await _fade_to(0.0)
	current_page = &"main"
	transitioning = false


func _fade_to(alpha: float) -> void:
	transition_mask.show()
	var tween := create_tween()
	tween.tween_property(transition_mask, "color:a", alpha, maxf(0.01, transition_duration)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if alpha == 0.0:
		transition_mask.hide()


func _input(event: InputEvent) -> void:
	if not transitioning:
		return
	if current_page == &"opening":
		opening.handle_input(event)
	get_viewport().set_input_as_handled()

func continue_game() -> void:
	if transitioning:
		return
	if not is_instance_valid(_game):
		return
	pause_menu.hide()
	current_page = &"game"
	menu_root.hide()
	empty_page.hide()
	_game.show()
	_game.process_mode = Node.PROCESS_MODE_INHERIT
	_game.get_node("UI").show()
	_game.get_node("World/Camera").enabled = true
	get_viewport().set_input_as_handled()


func return_to_menu() -> void:
	if transitioning:
		return
	pause_menu.hide()
	_suspend_game()
	current_page = &"main"
	empty_page.hide()
	menu_root.show()
	# Keep the supplied appearance even when no session exists to continue.
	continue_button.disabled = not is_instance_valid(_game)


func open_page(page_id: StringName) -> void:
	if transitioning:
		return
	if page_id not in EMPTY_PAGES:
		return
	pause_menu.hide()
	_suspend_game()
	current_page = page_id
	menu_root.hide()
	empty_page.set_meta("page_id", page_id)
	empty_page.show()
	page_requested.emit(page_id)


func request_load_slot(slot_id: StringName) -> void:
	# Future save-slot UI connects here; this release creates no save data.
	load_slot_requested.emit(slot_id)


func _suspend_game() -> void:
	if not is_instance_valid(_game):
		return
	_game.process_mode = Node.PROCESS_MODE_DISABLED
	_game.hide()
	_game.get_node("UI").hide()
	_game.get_node("World/Camera").enabled = false
	_game.get_node("World/Player").velocity = Vector2.ZERO


func pause_game() -> void:
	if transitioning:
		return
	if current_page != &"game" or not is_instance_valid(_game):
		return
	if bool(_game.get_node("UI").get("modal_open")) or bool(_game.get("transitioning")):
		return
	# Keep the world, camera and UI rendered for the two Gaussian blur passes.
	_game.process_mode = Node.PROCESS_MODE_DISABLED
	_game.get_node("World/Player").velocity = Vector2.ZERO
	current_page = &"pause"
	pause_menu.show()
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	if current_page == &"main":
		return
	if current_page == &"game":
		# Existing modal/puzzle Esc handling has priority over the menu.
		pause_game()
	elif current_page == &"pause":
		continue_game()
	else:
		return_to_menu()
	get_viewport().set_input_as_handled()


func _on_settings_pressed() -> void:
	open_page(&"settings")


func _on_load_game_pressed() -> void:
	open_page(&"load_game")


func _on_credits_pressed() -> void:
	open_page(&"credits")


func _on_quit_pressed() -> void:
	get_tree().quit()
