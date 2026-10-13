extends Node
## Isolated integration checks for opening CG and shared protagonist dialogue.
## Uses isolated preference files and never writes the real opening_progress.cfg.
const MenuScene = preload("res://scenes/ui/main_menu.tscn")
const OpeningProgress = preload("res://scripts/ui/opening_progress.gd")
const OUTPUT_DIR := "res://verification"
const MAX_RUNTIME_MS := 29000

var _checks: Array[Dictionary] = []
var _screenshots: Array[Dictionary] = []
var _failures := 0
var _started_ms := 0
var _finished := false
var _test_path := ""
var _malformed_path := ""
var _opening_page_count := 0


func _ready() -> void:
	_started_ms = Time.get_ticks_msec()
	var unique := "%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	_test_path = "user://opening_verification_%s.cfg" % unique
	_malformed_path = "user://opening_verification_%s_malformed.cfg" % unique
	call_deferred("_run")


func _process(_delta: float) -> void:
	if not _finished and Time.get_ticks_msec() - _started_ms >= MAX_RUNTIME_MS:
		_check(false, "Complete integration suite within 29 seconds")
		_finish()


func _check(condition: bool, label: String) -> void:
	_checks.append({"check": label, "passed": condition})
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + label)


func _new_menu() -> Node:
	var menu: Node = MenuScene.instantiate()
	menu.set("opening_progress_path", _test_path)
	menu.set("transition_duration", 0.03)
	menu.set("opening_black_delay", 0.02)
	add_child(menu)
	menu.get("opening").get("dialogue").connect("page_changed", _on_opening_page_changed)
	return menu


func _on_opening_page_changed(_index: int) -> void:
	_opening_page_count += 1


func _wait_until(predicate: Callable, timeout_ms: int = 2500) -> bool:
	var until := Time.get_ticks_msec() + timeout_ms
	while not _finished and Time.get_ticks_msec() < until:
		if bool(predicate.call()):
			return true
		await get_tree().process_frame
	return false


func _wait_seconds(seconds: float) -> void:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not _finished and Time.get_ticks_msec() < until:
		await get_tree().process_frame


func _wait_page(menu: Node, page: StringName, timeout_ms: int = 2500) -> bool:
	return await _wait_until(func() -> bool: return menu.get("current_page") == page, timeout_ms)


func _escape() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	return event


func _send_escape() -> void:
	Input.parse_input_event(_escape())
	await _wait_seconds(0.04)
	var release := _escape()
	release.pressed = false
	Input.parse_input_event(release)
	await _wait_seconds(0.04)


func _audio_node_count(parent: Node) -> int:
	var count := 0
	if parent is AudioStreamPlayer or parent is AudioStreamPlayer2D or parent is AudioStreamPlayer3D:
		count += 1
	for child in parent.get_children():
		count += _audio_node_count(child)
	return count


func _capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		_screenshots.append({"path": OUTPUT_DIR.path_join(filename), "status": "skipped_headless"})
		return
	# Normal rendering runs during these bounded waits; headless is handled above.
	await _wait_seconds(0.05)
	if _finished:
		return
	var image := get_viewport().get_texture().get_image()
	var path := OUTPUT_DIR.path_join(filename)
	var error := image.save_png(path)
	_screenshots.append({"path": path, "status": "saved" if error == OK else error_string(error)})
	_check(error == OK, "Save visual evidence: " + filename)


func _advance(dialogue: Control) -> void:
	dialogue.call("reveal_text")
	await _wait_seconds(0.18)
	if not _finished:
		dialogue.call("advance")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_check(_test_path != "user://opening_progress.cfg" and not FileAccess.file_exists(_test_path), "Use a unique, initially empty test profile")
	var menu := _new_menu()
	_check(menu.get("current_page") == &"main", "Fresh menu starts on the main page")
	# Do not await the coroutine: its completion depends on driving the dialogue.
	menu.call("start_new_game")
	menu.call("start_new_game")
	_check(bool(menu.get("transitioning")), "New Game immediately locks transition input")
	var reached_opening := await _wait_page(menu, &"opening")
	_check(reached_opening, "First New Game reaches the opening")
	if not reached_opening or _finished:
		_finish()
		return
	var opening: CanvasLayer = menu.get("opening")
	var dialogue: Control = opening.get("dialogue")
	_check(not is_instance_valid(menu.get("_game")), "Gameplay is not instantiated before completing the opening")
	_check(menu.get_node("GameHost").get_child_count() == 0, "Repeated New Game does not create duplicate sessions")
	_check(not FileAccess.file_exists(_test_path) and not bool(menu.get("opening_progress").get("completed")), "Unfinished opening is not persisted as complete")
	_check(_audio_node_count(opening) == 0, "Opening contains no ambient or other audio players")
	_check(opening.get("black").color == Color.BLACK, "Opening uses an opaque black background")
	_check(dialogue.get("pages").size() == 8, "Opening contains all 8 narrative pages")
	await _send_escape()
	_check(menu.get("current_page") == &"opening" and bool(dialogue.get("active")) and int(dialogue.get("page_index")) == 0, "Escape neither leaves nor advances the opening")
	menu.call("start_new_game")
	_check(menu.get("opening") == opening and int(dialogue.get("page_index")) == 0 and not is_instance_valid(menu.get("_game")), "New Game during the opening is ignored")
	await _wait_seconds(0.46)
	dialogue.call("reveal_text")
	await _capture("opening_narration.png")
	for index in range(7):
		_check(int(dialogue.get("page_index")) == index, "Narration page %s appears in order" % (index + 1))
		_check(not dialogue.get("portrait").visible and not dialogue.get("speaker_label").visible, "Narration page %s shows no portrait or speaker label" % (index + 1))
		await _advance(dialogue)
		if _finished:
			return
	_check(dialogue.get("speaker_label").text == "Luna：" and dialogue.get("body_label").text == "醒过来。", "Final page preserves Luna's exact line")
	_check(dialogue.get("portrait").visible, "Final Luna page shows the protagonist on the right")
	_check(dialogue.get("portrait").position.x > 960.0, "Portrait is placed in the right half of the reference canvas")
	var textures: Dictionary = dialogue.get("_textures")
	_check(textures.size() == 4, "Dialogue loads exactly four protagonist expressions")
	for expression in [&"neutral", &"speaking", &"smile", &"teary"]:
		var texture: AtlasTexture = textures.get(expression)
		var expected_path := "res://assets/art/characters/protagonist/protagonist_%s.png" % expression
		_check(texture != null and texture.atlas != null and texture.atlas.resource_path == expected_path, "Expression %s uses supplied protagonist artwork" % expression)
	_check(float(opening.get("_shake_remaining")) > 0.0, "Luna's wake-up line triggers the shake")
	await _wait_seconds(0.65)
	_check(float(opening.get("_shake_remaining")) == 0.0 and dialogue.get("_shake_offset") == Vector2.ZERO, "Shake completes and restores the exact base position")
	dialogue.call("reveal_text")
	await _capture("opening_luna.png")
	await _advance(dialogue)
	var reached_game := await _wait_page(menu, &"game")
	_check(reached_game, "Completed opening fades into gameplay")
	if not reached_game or _finished:
		_finish()
		return
	var game: Node2D = menu.get("_game")
	_check(game.get("level").scene_file_path == "res://scenes/bedroom.tscn", "Gameplay begins in the bedroom")
	_check(not opening.visible and not bool(dialogue.get("active")), "Opening is hidden and inactive after entry")
	_check(_opening_page_count == 8, "First run displays exactly 8 opening pages")
	_check(bool(menu.get("opening_progress").get("completed")), "Completion flag is set only after gameplay entry")
	var persisted := OpeningProgress.new(_test_path)
	_check(persisted.completed and FileAccess.file_exists(_test_path), "A fresh profile object reads persisted completion")
	await _capture("opening_game.png")

	var ui: CanvasLayer = game.get_node("UI")
	var player: CharacterBody2D = game.get_node("World/Player")
	var test_pages: Array[Dictionary] = [
		{"speaker": "主角", "text": "测试对白", "expression": &"speaking"},
		{"speaker": "Luna", "text": "测试对白"},
		{"text": "测试对白"},
	]
	ui.call("show_dialogue", test_pages)
	var game_dialogue: Control = ui.get("dialogue")
	_check(bool(ui.get("modal_open")) and player.get("input_blocked"), "Dialogue opens a modal and immediately blocks movement")
	_check(game_dialogue.get("portrait").visible and game_dialogue.get("_expression") == &"speaking", "Protagonist speech selects the speaking portrait")
	var before := player.position
	Input.action_press("move_right")
	await _wait_seconds(0.18)
	Input.action_release("move_right")
	_check(player.position.is_equal_approx(before) and player.velocity.is_zero_approx(), "Held movement input cannot move the player during dialogue")
	menu.call("pause_game")
	_check(menu.get("current_page") == &"game", "Pause cannot open over a dialogue modal")
	await _wait_seconds(0.25)
	game_dialogue.call("reveal_text")
	await _capture("opening_protagonist.png")
	await _advance(game_dialogue)
	_check(game_dialogue.get("speaker_label").text == "Luna：" and not game_dialogue.get("portrait").visible, "Normal Luna speech shows no portrait")
	await _advance(game_dialogue)
	_check(not game_dialogue.get("speaker_label").visible and not game_dialogue.get("portrait").visible, "Normal narration shows no portrait or name")
	await _send_escape()
	_check(not bool(ui.get("modal_open")) and not player.get("input_blocked") and menu.get("current_page") == &"game", "Escape closes dialogue and resumes control without pausing")
	var state: Node = game.get_node("GameState")
	state.call("collect_fragment", &"verification_fragment")
	state.call("collect_key", &"verification_key")
	var original_game_id := game.get_instance_id()
	menu.call("pause_game")
	_check(menu.get("current_page") == &"pause" and game.process_mode == Node.PROCESS_MODE_DISABLED, "Pause keeps the existing game session frozen")
	menu.call("continue_game")
	_check(menu.get("current_page") == &"game" and game.get_instance_id() == original_game_id and not opening.visible, "Continue after pause resumes the existing game without opening CG")
	menu.call("return_to_menu")
	_check(menu.get("current_page") == &"main" and state.call("has_fragment", &"verification_fragment"), "Return to menu preserves session collection")
	menu.call("continue_game")
	_check(menu.get("current_page") == &"game" and game.get_instance_id() == original_game_id and not opening.visible, "Continue from main menu resumes without replaying CG")
	menu.call("return_to_menu")
	menu.call("start_new_game")
	var skipped := await _wait_page(menu, &"game")
	_check(skipped and not opening.visible and _opening_page_count == 8, "Second New Game in the same process skips opening CG")
	if not skipped or _finished:
		_finish()
		return
	game = menu.get("_game")
	state = game.get_node("GameState")
	_check(game.get_instance_id() != original_game_id and int(state.call("fragment_count")) == 0 and not state.call("has_key", &"verification_key"), "New Game replaces the session and resets fragments and keys")
	_check(game.get("level").scene_file_path == "res://scenes/bedroom.tscn", "Second New Game returns to bedroom")
	remove_child(menu)
	menu.queue_free()
	await _wait_seconds(0.05)
	menu = _new_menu()
	_check(bool(menu.get("opening_progress").get("completed")), "A newly created menu reloads the persisted completion preference")
	menu.call("start_new_game")
	var reloaded_skip := await _wait_page(menu, &"game")
	_check(reloaded_skip and not menu.get("opening").visible and _opening_page_count == 8, "New menu with completed profile enters gameplay without replay")
	# Malformed configuration should behave like a first visit rather than truthy data.
	for invalid: Variant in ["true", 1, [true], null]:
		var bad_config := ConfigFile.new()
		bad_config.set_value("opening", "completed", invalid)
		var saved := bad_config.save(_malformed_path)
		var malformed := OpeningProgress.new(_malformed_path)
		_check(saved == OK and not malformed.completed, "Non-boolean completed value is treated as unseen: " + var_to_str(invalid))
	var missing_config := ConfigFile.new()
	missing_config.set_value("unrelated", "setting", true)
	var missing_saved := missing_config.save(_malformed_path)
	var missing := OpeningProgress.new(_malformed_path)
	_check(missing_saved == OK and not missing.completed, "Missing completion field is treated as unseen")
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	Input.action_release("move_right")
	var cleanup: Array[Dictionary] = []
	for path: String in [_test_path, _malformed_path]:
		if not path.is_empty() and FileAccess.file_exists(path):
			var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			cleanup.append({"test_profile": path, "removed": error == OK})
			_check(error == OK, "Remove isolated test preference file")
	var result := {
		"passed": _failures == 0,
		"failures": _failures,
		"checks": _checks,
		"runtime_ms": Time.get_ticks_msec() - _started_ms,
		"screenshots": _screenshots,
		"cleanup": cleanup,
	}
	var output := FileAccess.open(OUTPUT_DIR.path_join("opening_results.json"), FileAccess.WRITE)
	if output == null:
		_failures += 1
		print("FAIL: Write opening_results.json: " + error_string(FileAccess.get_open_error()))
	else:
		output.store_string(JSON.stringify(result, "\t"))
		output.close()
	print("OPENING_VERIFICATION: %s (%s failures)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	get_tree().quit(_failures)

