extends Node
## Run this scene for integration checks and rendered proof screenshots.
var game
var checks: Array[Dictionary] = []
var failures := 0
var acquired_keys: Array[StringName] = []
var acquired_fragments: Array[StringName] = []

func _ready() -> void:
	call_deferred("_run")

func _check(condition: bool, check_name: String) -> void:
	checks.append({"name": check_name, "passed": condition})
	if condition:
		print("PASS: " + check_name)
	else:
		failures += 1
		push_error("FAIL: " + check_name)

func _frames(count: int = 3) -> void:
	for index in range(count):
		await get_tree().physics_frame
	await get_tree().process_frame

func _press_key(code: Key, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	event.echo = echo
	Input.parse_input_event(event)
	await _frames(2)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(2)

func _click(position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = position
	Input.parse_input_event(event)
	await _frames(2)
	event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = position
	Input.parse_input_event(event)
	await _frames(2)

func _walk(actions: Array, count: int) -> void:
	for action: String in actions:
		Input.action_press(action)
	await _frames(count)
	for action: String in actions:
		Input.action_release(action)
	await _frames(2)

func _place(position: Vector2) -> void:
	game.player.global_position = position
	game.player.velocity = Vector2.ZERO
	await _frames()

func _capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var error := image.save_png("res://verification/" + filename + ".png")
	_check(error == OK, "Screenshot saved: " + filename)

func _portal(portal_name: String, expected: StringName) -> void:
	var portal: Node2D = game.level.get_node("Interactables/" + portal_name)
	await _place(portal.global_position)
	_check(game.current_target == portal, "F selects portal: " + portal_name)
	await _press_key(KEY_F)
	_check(game.level.level_id == expected, "Portal reaches: " + String(expected))
	_check(game.level_host.get_child_count() == 1, "Exactly one level loaded")
	_check(game.player.velocity == Vector2.ZERO, "Arrival resets player velocity")
	_check(not game.ui.note_label.visible, "No old floating text after transition")

func _check_boundaries() -> void:
	# Include the original leaking bedroom/corridor door gaps, all sides and diagonals.
	var probes := {
		"bedroom": [
			[Vector2(210, 412), ["move_left"]], [Vector2(650, 415.5), ["move_right"]],
			[Vector2(350, 270), ["move_up"]], [Vector2(300, 548), ["move_down"]],
			[Vector2(130, 275), ["move_left", "move_up"]], [Vector2(650, 275), ["move_right", "move_up"]],
			[Vector2(260, 548), ["move_left", "move_down"]], [Vector2(460, 435), ["move_right", "move_down"]]
		],
		"corridor": [
			[Vector2(60, 141), ["move_left"]], [Vector2(730, 110), ["move_right"]],
			[Vector2(444, 100), ["move_up"]], [Vector2(444, 200), ["move_down"]],
			[Vector2(60, 105), ["move_left", "move_up"]], [Vector2(730, 105), ["move_right", "move_up"]],
			[Vector2(60, 198), ["move_left", "move_down"]], [Vector2(730, 198), ["move_right", "move_down"]]
		],
		"first_floor": [
			[Vector2(40, 620), ["move_left"]], [Vector2(1380, 540), ["move_right"]],
			[Vector2(540, 245), ["move_up"]], [Vector2(780, 1080), ["move_down"]],
			[Vector2(460, 235), ["move_left", "move_up"]], [Vector2(1240, 370), ["move_right", "move_up"]],
			[Vector2(300, 1080), ["move_left", "move_down"]], [Vector2(1280, 930), ["move_right", "move_down"]]
		],
		"studio": [
			[Vector2(45, 270), ["move_left"]], [Vector2(438, 270), ["move_right"]],
			[Vector2(240, 190), ["move_up"]], [Vector2(240, 550), ["move_down"]],
			[Vector2(45, 190), ["move_left", "move_up"]], [Vector2(438, 190), ["move_right", "move_up"]],
			[Vector2(45, 550), ["move_left", "move_down"]], [Vector2(438, 550), ["move_right", "move_down"]]
		],
		"courtyard": [
			[Vector2(44, 270), ["move_left"]], [Vector2(615, 270), ["move_right"]],
			[Vector2(330, 46), ["move_up"]], [Vector2(105, 480), ["move_down"]],
			[Vector2(50, 50), ["move_left", "move_up"]], [Vector2(612, 50), ["move_right", "move_up"]],
			[Vector2(50, 480), ["move_left", "move_down"]], [Vector2(612, 480), ["move_right", "move_down"]]
		]
	}
	var entry_points := {"bedroom": &"start", "corridor": &"from_bedroom", "first_floor": &"from_corridor", "courtyard": &"from_first_floor", "studio": &"from_corridor"}
	for level_id: String in probes:
		game.change_level("res://scenes/" + level_id + ".tscn", entry_points[level_id])
		await _frames()
		var perimeter = game.level.get_node("MovementBounds")
		var radius: float = game.player.get_node("Collision").shape.radius
		_check(perimeter.contains_body(game.player.position, radius), level_id + ": arrival is inside playable area")
		var index := 0
		for probe: Array in probes[level_id]:
			await _place(probe[0])
			await _walk(probe[1], 36)
			_check(perimeter.contains_body(game.player.position, radius), "%s: perimeter probe %d stays inside (including player radius)" % [level_id, index])
			_check(String(game.level.level_id) == level_id, level_id + ": movement alone never changes scene")
			index += 1
	# Collision sweeps must also hold at speeds far above the normal WASD speed.
	var normal_speed: float = game.player.speed
	game.player.speed = 2500.0
	var fast_probes := [
		["bedroom", Vector2(645, 415.5), ["move_right"]],
		["corridor", Vector2(60, 141), ["move_left"]],
		["first_floor", Vector2(540, 245), ["move_up"]],
		["first_floor", Vector2(460, 235), ["move_left"]],
		["studio", Vector2(240, 550), ["move_down"]]
	]
	for probe: Array in fast_probes:
		var level_id: String = probe[0]
		game.change_level("res://scenes/" + level_id + ".tscn", entry_points[level_id])
		await _frames()
		await _place(probe[1])
		await _walk(probe[2], 18)
		_check(game.level.get_node("MovementBounds").contains_body(game.player.position, game.player.get_node("Collision").shape.radius), level_id + ": high speed remains within complete floor boundary")
	game.player.speed = normal_speed
	game.change_level("res://scenes/bedroom.tscn", &"start")
	await _frames()

func _visible_ui_texts() -> Array[String]:
	var texts: Array[String] = []
	for node: Node in game.ui.root_control.find_children("*", "Label", true, false):
		var label := node as Label
		if label.is_visible_in_tree() and not label.text.is_empty():
			texts.append(label.text)
	return texts

func _check_black_texts(context_name: String) -> void:
	for root: Node in [game.level, game.ui.root_control]:
		for label: Label in root.find_children("*", "Label", true, false):
			if label.is_visible_in_tree() and not label.text.is_empty():
				_check(label.get_theme_color("font_color") == Color.BLACK, context_name + ": black text: " + label.text)

func _check_collection_layout() -> void:
	var viewport := get_viewport().get_visible_rect().size
	var panel: Rect2 = game.ui.collection_panel.get_global_rect()
	_check(panel.size.is_equal_approx(viewport * Vector2(0.94, 0.25)) and is_equal_approx(viewport.y - panel.end.y, viewport.y * 0.03), "Collection panel follows 94% width, 25% height and 3% bottom margin")
	_check(panel.encloses(game.ui.collection_text.get_global_rect()), "Collection text fits inside white panel")
	_check(game.ui.collection_text.horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT, "Collection text is left aligned")
	_check(game.ui.collection_text.get_line_count() * game.ui.collection_text.get_line_height() <= game.ui.collection_text.size.y, "Collection text wraps without vertical clipping")
	_check(game.get_node("World").visible and game.ui.overlay.color.a > 0 and game.ui.overlay.color.a < 1, "Collection dims current scene without hiding it")
	_check(game.ui.collection_panel.color == Color.WHITE, "Collection panel is white")
	if game.ui.collection_footer.visible:
		_check(panel.encloses(game.ui.collection_footer.get_global_rect()) and not game.ui.collection_text.get_global_rect().intersects(game.ui.collection_footer.get_global_rect()), "Reward footer fits below text without overlap")
	_check_black_texts("Collection")

func _check_first_act_content() -> void:
	await _portal("ToCorridor", &"corridor")
	var door = game.level.get_node("Interactables/ToStudio")
	await _place(door.position)
	await _press_key(KEY_F)
	_check(game.level.level_id == &"corridor" and game.ui.note_label.text == "已上锁" and game.ui.note_label.visible, "Studio door rejects entry without key and shows locked line")
	_check(not game.player.input_blocked and not game.state.has_key(&"studio_key_01"), "Locked door leaves movement active and does not grant a key")
	await _capture("14_studio_locked")
	await _place(game.level.get_node("Interactables/CorridorPhoto").position)
	await _press_key(KEY_F)
	_check(game.ui.modal_open and game.state.has_fragment(&"corridor_photo_02") and game.state.fragment_count() == 2, "Corridor photograph grants the second independent fragment")
	_check(_visible_ui_texts() == ["你搂着某人站在实验室里。照片上，那人的脸庞不知为何被烧了一个洞。"], "Corridor body page only displays exact narrative")
	_check(game.ui.collection_text.get_theme_font_size("font_size") == 36, "Body text uses 36 pixels")
	_check_collection_layout()
	await _capture("15_corridor_photo")
	await _press_key(KEY_ESCAPE)
	_check(not game.ui.modal_open and game.state.has_fragment(&"corridor_photo_02"), "Esc on first corridor body page retains immediately granted fragment")
	await _press_key(KEY_F)
	_check(game.state.fragment_count() == 2 and game.ui.collection_page == 0, "Repeated corridor photo starts from body without duplicate reward")
	await _click(Vector2(1915, 1075))
	_check(game.ui.modal_open and _visible_ui_texts() == ["获得记忆碎片‘镜面’", "左键点击屏幕任意位置退出"], "Click at any screen point advances corridor photo to named reward")
	_check(game.ui.collection_text.get_theme_font_size("font_size") == 40, "Reward text uses 40 pixels")
	_check_collection_layout()
	await _capture("21_corridor_reward")
	await _click(Vector2(5, 5))
	_check(not game.ui.modal_open and not game.player.input_blocked, "Second click closes corridor collection and resumes movement")
	await _press_key(KEY_F)
	await _press_key(KEY_F)
	await _press_key(KEY_ESCAPE)
	_check(not game.ui.modal_open and acquired_fragments.count(&"corridor_photo_02") == 1, "Esc also closes reward page and repeated photo grants only once")
	await _portal("ToFirstFloor", &"first_floor")
	await _portal("ToCourtyard", &"courtyard")
	var bush = game.level.get_node("Geometry/Bush")
	var well = game.level.get_node("Geometry/Pool")
	_check(bush.position.x + bush.size.x * 0.5 < well.position.x - well.size.x * 0.5, "Whitebox bush is to the left of well")
	await _place(Vector2(410, 220))
	await _walk(["move_up"], 35)
	_check(game.player.position.y < 65, "Player can walk through gap between bush and well")
	await _place(game.level.get_node("Interactables/BushKey").position)
	var pickup_position: Vector2 = game.player.position
	_check(game.current_target.name == "BushKey", "Bush is reachable as a distinct F target")
	await _press_key(KEY_F)
	_check(game.state.has_key(&"studio_key_01") and _visible_ui_texts() == ["画室钥匙"], "Bush grants studio key immediately and displays only item name")
	_check(game.ui.collection_preview.visible and game.ui.collection_preview.placeholder_type == &"key" and game.ui.collection_preview.artwork == null, "Key modal displays code-native key placeholder")
	_check_collection_layout()
	await _capture("22_bush_key")
	await _walk(["move_right"], 10)
	_check(game.player.position == pickup_position and game.player.input_blocked, "Key collection pauses movement at pickup position")
	await _click(Vector2(1915, 1075))
	_check(not game.ui.modal_open and not game.player.input_blocked and game.player.position == pickup_position, "Any left click closes key popup and restores movement at same position")
	await _press_key(KEY_F)
	await _press_key(KEY_F)
	_check(not game.ui.modal_open and acquired_keys == [&"studio_key_01"], "Repeated key pickup closes with F and grants only once")
	await _press_key(KEY_F)
	await _press_key(KEY_ESCAPE)
	_check(not game.ui.modal_open and game.state.keys.size() == 1, "Esc closes key popup without losing or duplicating key")
	await _place(Vector2(340, 230))
	await _walk(["move_up"], 25)
	_check(game.player.position.y >= bush.position.y + bush.size.y * 0.5 + game.player.get_node("Collision").shape.radius - 0.5, "Bush whitebox blocks movement")
	await _portal("ToFirstFloor", &"first_floor")
	await _portal("ToCorridor", &"corridor")
	await _place(game.level.get_node("Interactables/ToStudio").position)
	await _press_key(KEY_F)
	_check(game.level.level_id == &"studio" and game.ui.note_label.text == "已解锁" and game.ui.note_label.visible, "Actual bush key unlocks door and enters separate studio")
	_check(game.state.has_key(&"studio_key_01") and game.level.get_interactables().size() == 1, "Key is retained and empty studio only offers return door")
	await _capture("16_empty_studio")
	await _portal("ToCorridor", &"corridor")
	await _portal("ToFirstFloor", &"first_floor")
	await _place(Vector2(227.5, 630))
	await _walk(["move_up"], 32)
	_check(game.player.position.y < 550 and game.level.level_id == &"first_floor", "Upper empty room can be walked into without F")
	await _walk(["move_down"], 32)
	await _walk(["move_right"], 50)
	_check(game.player.position.x > 450, "Upper room passage joins the hall")
	await _place(Vector2(125, 630))
	await _walk(["move_down"], 60)
	_check(game.player.position.y > 890, "Lower empty room can be walked into through its door opening")
	await _walk(["move_up"], 60)
	_check(game.player.position.y < 680, "Lower room passage permits return")
	await _place(Vector2(1005, 460))
	await _walk(["move_up"], 20)
	_check(game.player.position.y < 370, "Rug is walkable")
	await _place(Vector2(590, 300))
	await _walk(["move_up"], 12)
	_check(game.player.position.y < 250, "Shoe mat is walkable")
	await _place(Vector2(1005, 380))
	await _walk(["move_up"], 20)
	_check(game.player.position.y >= 334, "Sofa blocks the foot collider")
	await _place(Vector2(1080, 660))
	await _walk(["move_down"], 25)
	_check(game.player.position.y <= 691, "Dining table blocks movement between chairs")
	await _place(Vector2(880, 760))
	await _walk(["move_right"], 20)
	_check(game.player.position.x <= 887, "Dining chair blocks movement")
	await _place(Vector2(580, 820))
	await _walk(["move_down"], 30)
	_check(game.player.position.y <= 852, "Tent blocks movement")
	await _place(game.level.get_spawn(&"from_corridor").position)
	await _capture("17_furnished_first_floor")
	_check_black_texts("Furnished hall")
	await _portal("ToCourtyard", &"courtyard")
	await _portal("ToFirstFloor", &"first_floor")
	await _portal("ToCorridor", &"corridor")
	await _portal("ToBedroom", &"bedroom")
	_check(game.state.fragment_count() == 2 and game.state.has_key(&"studio_key_01"), "Both fragments and key persist across all scene travel")

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	add_child(game)
	await _frames(5)
	game.state.key_acquired.connect(func(id: StringName): acquired_keys.append(id))
	game.state.fragment_acquired.connect(func(id: StringName): acquired_fragments.append(id))
	_check(get_viewport().get_visible_rect().size == Vector2(1920, 1080), "Default viewport is 1920x1080")
	_check(_visible_ui_texts().is_empty(), "No fixed top or bottom HUD text at startup")
	_check(game.level.level_id == &"bedroom", "Starts in bedroom")
	_check(game.player.position.distance_to(game.level.get_spawn(&"start").position) < 1, "Player starts at reference person position")
	await _capture("01_bedroom")

	await _place(Vector2(300, 340))
	var before: Vector2 = game.player.position
	await _walk(["move_right"], 24)
	var cardinal: float = game.player.position.distance_to(before)
	_check(absf(cardinal - game.player.speed * 24.0 / Engine.physics_ticks_per_second) < 12.0, "WASD movement changes position")
	await _place(Vector2(300, 340))
	before = game.player.position
	await _walk(["move_right", "move_down"], 24)
	var diagonal: float = game.player.position.distance_to(before)
	_check(absf(cardinal - diagonal) < 6, "Diagonal movement is normalized")

	await _place(Vector2(650, 340))
	await _walk(["move_right"], 30)
	_check(game.player.position.x <= game.level.get_playable_bounds().end.x - game.player.get_node("Collision").shape.radius + 0.5, "Wall blocks movement")
	await _place(Vector2(155, 460))
	await _walk(["move_left"], 20)
	_check(game.player.position.x >= game.level.get_node("Geometry/Desk").position.x + game.level.get_node("Geometry/Desk").size.x * 0.5 + game.player.get_node("Collision").shape.radius - 0.5, "Desk blocks movement")
	await _place(Vector2(581, 430))
	await _walk(["move_down"], 30)
	_check(game.player.position.y <= game.level.get_node("Geometry/Bed").position.y - game.level.get_node("Geometry/Bed").size.y * 0.5 - game.player.get_node("Collision").shape.radius + 0.5, "Bed blocks movement")
	await _place(Vector2(240, 519))
	await _walk(["move_left"], 20)
	_check(game.player.position.x >= game.level.get_node("Geometry/Chair").position.x + game.level.get_node("Geometry/Chair").size.x * 0.5 + game.player.get_node("Collision").shape.radius - 0.5, "Chair blocks movement")

	await _place(game.level.get_node("Interactables/WindowCG").position + Vector2(0, 10))
	_check(game.current_target.name == "WindowCG", "Window is reachable")
	_check(_visible_ui_texts() == ["按F交互"], "Only exact F prompt appears near an interactable")
	await _press_key(KEY_F)
	_check(game.ui.modal_open and game.ui.current_view_title == "窗外场景 CG", "Window F opens fullscreen CG")
	_check(_visible_ui_texts().is_empty(), "CG has no debug title or placeholder description")
	_check(game.state.fragment_count() == 0, "Window does not collect fragment")
	await _capture("02_window_cg")
	await _press_key(KEY_ESCAPE)
	_check(not game.ui.modal_open, "Esc closes CG")

	await _place(game.level.get_node("Interactables/DeskNote").position)
	_check(game.current_target.name == "DeskNote", "Desk note is reachable")
	await _press_key(KEY_F)
	_check(game.ui.note_label.text == "来水井边见我", "Exact note text")
	_check(game.ui.note_label.visible and not game.ui.modal_open, "Note is floating text without fullscreen UI")
	_check(not game.player.input_blocked, "Note permits movement")
	_check(game.ui.note_anchor.y < game.level.get_node("Geometry/Desk").position.y - game.level.get_node("Geometry/Desk").size.y * 0.5, "Note is anchored above desk")
	await _capture("03_desk_note")
	var remaining: float = game.ui.note_remaining
	await _press_key(KEY_F)
	_check(game.ui.note_remaining > remaining - 0.1, "Repeated note interaction refreshes one label")

	await _place(game.level.get_node("Interactables/ShelfPhoto").position)
	_check(game.current_target.name == "ShelfPhoto", "Photo is reachable")
	await _press_key(KEY_F)
	_check(game.ui.modal_open and game.ui.collection_page == 0, "Photo F opens body page without skipping")
	_check(_visible_ui_texts() == ["照片上的女人背对月光，面目模糊不清"], "Bedroom body page displays exact narrative without extra labels")
	_check(game.state.fragment_count() == 1, "First photo acquisition adds exactly one fragment")
	_check_collection_layout()
	await _capture("20_bedroom_photo_body")
	before = game.player.position
	await _walk(["move_right"], 12)
	_check(game.player.position.distance_to(before) < 0.1, "Collection body blocks movement")
	await _press_key(KEY_ESCAPE)
	_check(not game.ui.modal_open and game.state.fragment_count() == 1 and game.player.position == before, "Early Esc retains fragment and restores exact player position")
	await _press_key(KEY_F)
	await _click(Vector2(5, 5))
	_check(game.ui.modal_open and _visible_ui_texts() == ["获得记忆碎片‘港湾’", "左键点击屏幕任意位置退出"], "Left click advances to reward with exact exit hint")
	_check_collection_layout()
	await _capture("04_photo_reward")
	await _click(Vector2(640, 360))
	_check(not game.ui.modal_open and not game.player.input_blocked, "Next left click closes reward and resumes movement")
	await _press_key(KEY_F)
	await _press_key(KEY_F)
	_check(game.ui.modal_open and game.ui.collection_page == 1, "F advances body to reward")
	await _press_key(KEY_F, true)
	_check(game.ui.modal_open and game.ui.collection_page == 1, "Held F echo never skips reward page")
	await _press_key(KEY_F)
	_check(not game.ui.modal_open and acquired_fragments == [&"bedroom_photo_01"], "Next F closes reward without duplicate fragment")
	await _press_key(KEY_F, true)
	_check(not game.ui.modal_open, "Keyboard echo cannot reopen photo")

	await _portal("ToCorridor", &"corridor")
	_check(game.level.get_interactables().size() == 4, "Corridor offers two travel portals, studio door and lab photograph")
	await _capture("05_corridor")
	await _portal("ToFirstFloor", &"first_floor")
	_check(game.level.get_interactables().size() == 2, "First floor only has two travel interactions")
	await _capture("06_first_floor")
	await _portal("ToCourtyard", &"courtyard")
	_check(game.level.get_interactables().size() == 3, "Courtyard has house door, well and bush key interactions")
	await _capture("07_courtyard")
	await _place(game.level.get_node("Interactables/Well").position)
	_check(game.current_target.name == "Well", "Well is an F interaction target")
	await _press_key(KEY_F)
	_check(game.ui.is_puzzle_open() and game.state.fragment_count() == 1, "F at well opens puzzle without consuming fragment")
	await _press_key(KEY_ESCAPE)
	_check(not game.ui.modal_open, "Esc returns from well puzzle")
	await _walk(["move_up"], 18)
	_check(game.player.position.y >= game.level.get_node("Geometry/Pool").position.y + game.level.get_node("Geometry/Pool").size.y * 0.5 + game.player.get_node("Collision").shape.radius - 0.5, "Pool blocks movement")

	await _portal("ToFirstFloor", &"first_floor")
	await _portal("ToCorridor", &"corridor")
	await _portal("ToBedroom", &"bedroom")
	_check(game.state.has_fragment(&"bedroom_photo_01"), "Fragment persists over complete round trip")
	await _place(game.level.get_node("Interactables/ShelfPhoto").position)
	await _press_key(KEY_F)
	_check(game.state.fragment_count() == 1, "Photo cannot be collected again after revisiting")
	await _click(Vector2(1270, 710))
	await _click(Vector2(1915, 1075))
	_check(not game.ui.modal_open, "Revisited photo still requires body, reward and close")
	await _place(game.level.get_node("Interactables/DeskNote").position)
	await _press_key(KEY_F)
	await get_tree().create_timer(4.1).timeout
	_check(not game.ui.note_label.visible, "Floating note expires after four seconds")
	await _place(game.level.get_spawn(&"start").position)
	await _check_first_act_content()
	await _check_boundaries()

	var report := {"failures": failures, "checks": checks, "rendered": DisplayServer.get_name() != "headless"}
	var file := FileAccess.open("res://verification/test_results.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "  "))
	print("DEMO2_RESULT: %d checks, %d failures" % [checks.size(), failures])
	get_tree().quit(0 if failures == 0 else 1)
