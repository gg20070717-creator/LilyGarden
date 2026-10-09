extends "res://tests/runtime_verification.gd"
const PuzzleScript = preload("res://scripts/puzzles/memory_puzzle.gd")
var solved_events: Array[StringName] = []

func _drag(token: Control, destination: Vector2, escape_midway: bool = false) -> void:
	# A headless DisplayServer has no OS pointer. Exercise the same drop handlers;
	# the rendered run below exercises native left-button drag and hit testing.
	if DisplayServer.get_name() == "headless":
		if escape_midway:
			await _press_key(KEY_ESCAPE)
			return
		var puzzle = token.puzzle
		var data := {"kind": token.token_kind, "choice_id": token.choice.choice_id, "puzzle_instance": puzzle.get_instance_id()}
		if not puzzle.can_drag(token.token_kind, token.choice.choice_id):
			return
		for target in [puzzle.water, puzzle.slots[0], puzzle.slots[1]]:
			var point: Vector2 = destination - target.global_position
			if target.get_global_rect().has_point(destination) and target._can_drop_data(point, data):
				target._drop_data(point, data)
				break
		await _frames(3)
		return
	var start := token.get_global_rect().get_center()
	get_viewport().warp_mouse(start)
	var motion := InputEventMouseMotion.new()
	motion.position = start
	get_viewport().push_input(motion, true)
	await _frames(2)
	var button := InputEventMouseButton.new()
	button.position = start
	button.global_position = start
	button.button_index = MOUSE_BUTTON_LEFT
	button.pressed = true
	get_viewport().push_input(button, true)
	await _frames(2)
	motion = InputEventMouseMotion.new()
	motion.position = start + Vector2(28, 0)
	get_viewport().warp_mouse(motion.position)
	motion.relative = Vector2(28, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(motion, true)
	await _frames(2)
	if escape_midway:
		await _press_key(KEY_ESCAPE)
		button = InputEventMouseButton.new()
		button.position = start
		button.button_index = MOUSE_BUTTON_LEFT
		button.pressed = false
		get_viewport().push_input(button, true)
		await _frames()
		return
	motion = InputEventMouseMotion.new()
	motion.position = destination
	get_viewport().warp_mouse(destination)
	motion.relative = destination - start - Vector2(28, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(motion, true)
	await _frames(2)
	button = InputEventMouseButton.new()
	button.position = destination
	button.global_position = destination
	button.button_index = MOUSE_BUTTON_LEFT
	button.pressed = false
	get_viewport().push_input(button, true)
	await _frames(3)

func _choose(puzzle, ids: Array) -> void:
	for choice_id: StringName in ids:
		await _drag(puzzle.moon_tokens[choice_id], puzzle.water.get_global_rect().get_center())
	await _press_key(KEY_ENTER)
	await get_tree().create_timer(0.55).timeout
	await _frames()

func _fill(puzzle, choice_id: StringName, index: int) -> void:
	await _drag(puzzle.word_tokens[choice_id], puzzle.slots[index].get_global_rect().get_center())

func _retry(puzzle, label: String) -> void:
	var retained_count: int = game.state.fragment_count()
	await _press_key(KEY_ENTER)
	_check(puzzle.phase == PuzzleScript.Phase.FEEDBACK, label + ": enters failure feedback")
	_check(puzzle.feedback.visible and puzzle.feedback.text == "水面很平静，毫无波澜", label + ": exact calm text")
	_check(not puzzle.enter_hint.visible, label + ": cannot submit during feedback")
	await get_tree().create_timer(1.6).timeout
	await _frames()
	_check(puzzle.phase == PuzzleScript.Phase.MOON and puzzle.selected_ids.is_empty() and puzzle.slot_ids == [&"", &""], label + ": resets both choices and slots")
	_check(puzzle.word_tokens.is_empty() and not puzzle.feedback.visible and not puzzle.enter_hint.visible, label + ": removes stale words and feedback")
	_check(game.state.fragment_count() == retained_count, label + ": acquired fragments retained")

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	add_child(game)
	await _frames(5)
	game.ui.restoration_succeeded.connect(func(id: StringName): solved_events.append(id))
	game.change_level("res://scenes/courtyard.tscn", &"from_first_floor")
	await _place(game.level.get_node("Interactables/Well").position)
	await _press_key(KEY_F)
	_check(not game.ui.modal_open and not game.player.input_blocked, "Unowned fragment leaves player in courtyard")
	_check(game.ui.note_label.text == "水面很平静，毫无波澜" and game.ui.note_label.visible, "Unowned fragment shows exact local line")
	_check(game.ui.note_anchor.y < game.level.get_node("Geometry/Pool").position.y - game.level.get_node("Geometry/Pool").size.y * 0.5, "Calm line floats above the well")
	_check(game.state.fragment_count() == 0, "Well cannot grant missing fragment")
	await _capture("08_well_locked")
	game.change_level("res://scenes/corridor.tscn", &"from_bedroom")
	await _place(game.level.get_node("Interactables/CorridorPhoto").position)
	await _press_key(KEY_F)
	await _click(Vector2(5, 5))
	await _click(Vector2(1915, 1075))
	_check(not game.ui.modal_open, "Photo collection fully closes before well entry")
	game.change_level("res://scenes/courtyard.tscn", &"from_first_floor")
	await _place(game.level.get_node("Interactables/Well").position)
	await _press_key(KEY_F)
	var b_only = game.ui.active_puzzle
	_check(b_only != null and b_only.moon_tokens[&"B"].visible and not b_only.moon_tokens[&"A"].visible, "Only corridor fragment opens well with only moon B")
	b_only.add_moon(&"A")
	_check(b_only.selected_ids.is_empty() and not b_only.can_drag(&"moon", &"C"), "Unowned moons are rejected even by direct deposit calls")
	await _capture("18_moon_B_only")
	await _choose(b_only, [&"B"])
	await _fill(b_only, &"B", 1)
	await _retry(b_only, "B only cannot solve AB")
	await _press_key(KEY_ESCAPE)
	game.state.fragments.clear()

	game.change_level("res://scenes/bedroom.tscn", &"start")
	await _place(game.level.get_node("Interactables/ShelfPhoto").position)
	await _press_key(KEY_F)
	await _click(Vector2(5, 5))
	await _click(Vector2(1915, 1075))
	_check(not game.ui.modal_open, "Photo collection fully closes before well entry")
	game.change_level("res://scenes/courtyard.tscn", &"from_first_floor")
	await _place(game.level.get_node("Interactables/Well").position)
	var return_position: Vector2 = game.player.position
	await _press_key(KEY_F)
	var puzzle = game.ui.active_puzzle
	_check(puzzle != null and game.ui.is_puzzle_open(), "Owned fragment opens independent scene")
	_check(not game.get_node("World").visible and game.player.input_blocked, "Exploration hidden and blocked")
	_check(puzzle.esc_hint.visible and puzzle.esc_hint.text == "按esc退出", "Persistent exact Esc hint")
	_check(puzzle.moon_tokens.size() == 5 and puzzle.underwater_labels.size() == 5, "Five moon candidates and five water words")
	_check(puzzle.moon_tokens[&"A"].visible and not puzzle.moon_tokens[&"B"].visible and not puzzle.moon_tokens[&"E"].visible, "Only bedroom fragment makes moon A visible")
	_check(not puzzle.enter_hint.visible and puzzle.phase == PuzzleScript.Phase.MOON, "No Enter hint before first selection")
	_check(_visible_ui_texts().size() == 7, "Initial page only contains five words, verb and Esc hint")
	_check_black_texts("Moon page")
	await _capture("09_moons")
	await _walk(["move_right"], 10)
	_check(game.player.position == return_position, "WASD cannot move exploration while solving")
	await _click(Vector2(15, 15))
	await _press_key(KEY_F)
	await _press_key(KEY_ENTER)
	_check(game.ui.active_puzzle == puzzle and puzzle.phase == PuzzleScript.Phase.MOON, "Blank clicks, F and empty Enter do not close or advance")

	await _drag(puzzle.moon_tokens[&"A"], Vector2(50, 50))
	_check(puzzle.selected_ids.is_empty() and puzzle.moon_tokens[&"A"].visible, "Drop outside well returns original moon")
	await _drag(puzzle.moon_tokens[&"A"], puzzle.water.global_position + Vector2(3, 3))
	_check(puzzle.selected_ids.is_empty(), "Ellipse rectangle corner is not water")
	await _drag(puzzle.moon_tokens[&"A"], puzzle.water.get_global_rect().get_center())
	_check(puzzle.selected_ids == [&"A"] and not puzzle.moon_tokens[&"A"].visible, "Native left drag deposits moon A once")
	_check(puzzle.enter_hint.visible and puzzle.enter_hint.text == "按enter开始还原", "Exact Enter hint after first moon")
	puzzle.add_moon(&"A")
	_check(puzzle.selected_ids.size() == 1, "Duplicate moon cannot be deposited")
	await _press_key(KEY_ENTER)
	_check(puzzle.phase == PuzzleScript.Phase.RISING, "Enter starts rising animation")
	await get_tree().create_timer(0.55).timeout
	await _frames()
	_check(puzzle.phase == PuzzleScript.Phase.WORD and puzzle.word_tokens.keys() == [&"A"], "Only selected word rises from water")
	_check(not puzzle.underwater_words.visible and not puzzle.moon_tokens[&"B"].visible, "Unselected words and moon cards are hidden")
	_check(puzzle.sentence.position.y < puzzle.water.position.y, "Sentence rises with words above water")
	_check(_visible_ui_texts() == ["看见", "按esc退出"], "Word stage has no extra labels")
	_check_black_texts("Word page")
	await _capture("10_words")
	await _fill(puzzle, &"A", 0)
	_check(puzzle.slot_ids == [&"A", &""] and puzzle.enter_hint.visible, "Native word drag fills left slot and enables Enter")
	await _drag(puzzle.word_tokens[&"A"], puzzle.water.get_global_rect().get_center())
	_check(puzzle.slot_ids == [&"", &""] and not puzzle.enter_hint.visible, "Dragging filled word into water returns it to floating row")
	await _fill(puzzle, &"A", 0)
	await _press_key(KEY_ENTER)
	_check_black_texts("Failure page")
	await _capture("11_failure")
	_check(puzzle.phase == PuzzleScript.Phase.FEEDBACK, "One filled slot fails")
	await get_tree().create_timer(1.6).timeout
	await _frames()
	_check(puzzle.phase == PuzzleScript.Phase.MOON and puzzle.selected_ids.is_empty(), "Missing word resets attempt")
	_check(not puzzle.moon_tokens[&"B"].visible, "Failed attempt never reveals unowned moons")
	await _press_key(KEY_ESCAPE)
	game.change_level("res://scenes/corridor.tscn", &"from_bedroom")
	await _place(game.level.get_node("Interactables/CorridorPhoto").position)
	await _press_key(KEY_F)
	await _click(Vector2(5, 5))
	await _click(Vector2(1915, 1075))
	_check(not game.ui.modal_open, "Photo collection fully closes before well entry")
	game.change_level("res://scenes/courtyard.tscn", &"from_first_floor")
	await _place(game.level.get_node("Interactables/Well").position)
	await _press_key(KEY_F)
	puzzle = game.ui.active_puzzle
	_check(puzzle.moon_tokens[&"A"].visible and puzzle.moon_tokens[&"B"].visible and not puzzle.moon_tokens[&"C"].visible, "Two collected photographs provide exactly A and B")
	await _capture("19_moons_A_B")
	await _choose(puzzle, [&"A", &"B"])
	await _fill(puzzle, &"A", 0)
	await _fill(puzzle, &"B", 1)
	await _press_key(KEY_ENTER)
	_check(puzzle.phase == PuzzleScript.Phase.STORY and game.state.fragment_count() == 2, "Actual bedroom and corridor rewards suffice to solve AB without consuming either")
	await _click(Vector2(10, 10))
	solved_events.clear()
	await _press_key(KEY_F)
	puzzle = game.ui.active_puzzle

	await _choose(puzzle, [&"A", &"B"])
	await _fill(puzzle, &"B", 0)
	await _fill(puzzle, &"A", 1)
	_check(puzzle.slot_ids == [&"B", &"A"], "Reversed answer is represented")
	await _retry(puzzle, "BA order")
	# Future fragments are granted through the same state API solely as test fixtures.
	await _press_key(KEY_ESCAPE)
	for fragment_id: StringName in [&"memory_fragment_03", &"memory_fragment_04", &"memory_fragment_05"]:
		game.state.collect_fragment(fragment_id)
	await _press_key(KEY_F)
	puzzle = game.ui.active_puzzle
	await _choose(puzzle, [&"A", &"C"])
	await _fill(puzzle, &"A", 0)
	await _fill(puzzle, &"C", 1)
	await _retry(puzzle, "AC wrong answer")

	await _choose(puzzle, [&"C", &"B", &"A"])
	_check(puzzle.selected_ids == [&"A", &"B", &"C"] and puzzle.word_tokens.size() == 3, "Multiple moons yield ordered selected words only")
	await _fill(puzzle, &"A", 0)
	await _fill(puzzle, &"B", 1)
	await _fill(puzzle, &"C", 0)
	_check(puzzle.slot_ids == [&"C", &"B"] and puzzle.word_tokens[&"A"].position == puzzle._word_home(&"A"), "Occupied slot replacement returns displaced word")
	await _fill(puzzle, &"B", 0)
	_check(puzzle.slot_ids == [&"B", &"C"], "Moving an assigned word to occupied slot swaps without duplicates")
	await _fill(puzzle, &"A", 0)
	await _fill(puzzle, &"B", 1)
	_check(puzzle.slot_ids == [&"A", &"B"], "Final slots contain ordered A then B")
	await _capture("12_words_AB")
	await _press_key(KEY_ENTER)
	_check(puzzle.phase == PuzzleScript.Phase.STORY and puzzle.story_panel.visible, "AB enters story CG")
	_check(solved_events == [&"well_memory"], "Success emits one reusable puzzle signal")
	_check(_visible_ui_texts() == ["按esc退出"], "CG only retains Esc hint and has no placeholder caption")
	await _capture("13_story_cg")
	await _click(Vector2(10, 10))
	_check(not game.ui.modal_open and game.get_node("World").visible and not game.player.input_blocked, "Left click exits story CG")
	_check(game.player.position == return_position and game.state.fragment_count() == 5, "Caller position and all acquired fragments retained")

	await _press_key(KEY_F)
	puzzle = game.ui.active_puzzle
	_check(puzzle.selected_ids.is_empty() and puzzle.slot_ids == [&"", &""], "Reentry creates fresh attempt")
	await _drag(puzzle.moon_tokens[&"E"], puzzle.water.get_global_rect().get_center())
	await _press_key(KEY_ENTER)
	await _press_key(KEY_ESCAPE)
	await get_tree().create_timer(0.55).timeout
	_check(not game.ui.modal_open and game.player.position == return_position, "Esc during animation safely returns to caller")

	var alternate: Resource = load("res://resources/well_memory_puzzle.tres").duplicate(true)
	alternate.answer_left = &"C"
	alternate.answer_right = &"D"
	alternate.puzzle_id = &"another_location"
	alternate.failure_duration = 0.2
	game.ui.open_puzzle(alternate, game.state.owned_fragment_ids())
	puzzle = game.ui.active_puzzle
	# Let Godot complete Control layout/hit testing before synthetic pointer events.
	await _frames()
	_check(puzzle.moon_tokens[&"C"].visible and puzzle.moon_tokens[&"D"].visible, "Alternate scene exposes owned C and D before native drag")
	await _choose(puzzle, [&"C", &"D"])
	_check(puzzle.phase == PuzzleScript.Phase.WORD and puzzle.selected_ids == [&"C", &"D"], "Alternate scene rises exactly C and D")
	await _fill(puzzle, &"C", 0)
	await _fill(puzzle, &"D", 1)
	_check(puzzle.slot_ids == [&"C", &"D"], "Native dragging fills alternate C and D answer")
	await _press_key(KEY_ENTER)
	_check(puzzle.phase == PuzzleScript.Phase.STORY and solved_events.back() == &"another_location", "Same scene accepts alternate answer configuration")
	_check(load("res://resources/well_memory_puzzle.tres").answer_left == &"A", "Attempt never mutates shared definition")
	await _press_key(KEY_ESCAPE)
	_check(not game.ui.modal_open and game.player.position == return_position, "Esc exits CG to same caller")
	await _press_key(KEY_F)
	puzzle = game.ui.active_puzzle
	await _choose(puzzle, [&"E"])
	await _fill(puzzle, &"E", 0)
	await _press_key(KEY_ENTER)
	await _press_key(KEY_ESCAPE)
	await get_tree().create_timer(1.6).timeout
	_check(not game.ui.modal_open and game.state.fragment_count() == 5, "Esc during feedback stops callbacks and retains all fragments")
	await _press_key(KEY_F)
	puzzle = game.ui.active_puzzle
	await _drag(puzzle.moon_tokens[&"A"], Vector2(10, 10), true)
	_check(not game.ui.modal_open and not get_viewport().gui_is_dragging(), "Esc during active drag clears the preview and returns to exploration")
	_check(game.player.position == return_position, "Active drag exit preserves caller position")

	var file := FileAccess.open("res://verification/puzzle_test_results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures": failures, "checks": checks, "rendered": DisplayServer.get_name() != "headless"}, "  "))
	print("PUZZLE_RESULT: %d checks, %d failures" % [checks.size(), failures])
	get_tree().quit(0 if failures == 0 else 1)


