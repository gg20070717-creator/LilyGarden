extends Control
## Reusable core scene: all attempt state lives here; exploration stays in the caller.
signal exit_requested
signal return_started
signal restoration_succeeded(puzzle_id: StringName)
const TokenScript = preload("res://scripts/puzzles/memory_token.gd")
const FONT = preload("res://ui_font.tres")
const TextStyle = preload("res://scripts/ui_text_style.gd")
const StoryDialogue = preload("res://scripts/ui/story_dialogue.gd")
enum Phase { MOON, RISING, WORD, FEEDBACK, STORY, INTRO, RETURNING }
@export var definition: Resource = preload("res://resources/well_memory_puzzle.tres")
## Caller-owned inventory snapshot. The scene never grants or consumes fragments.
@export var available_fragment_ids: Array[StringName] = []
@export var show_introduction := false
@onready var water = $Water
@onready var water_ripple = $Water/Ripple
@onready var moon_environment: TextureRect = $MoonEnvironment
@onready var moon_well: TextureRect = $MoonWell
@onready var sentence_backing: ColorRect = $Sentence/Backing
@onready var underwater_words: Control = $UnderwaterWords
@onready var sentence: Control = $Sentence
@onready var slots: Array[Control] = [$Sentence/LeftSlot, $Sentence/RightSlot]
@onready var verb: Label = $Sentence/Verb
@onready var cards: Control = $Cards
@onready var esc_hint: Label = $EscHint
@onready var enter_hint: Label = $EnterHint
@onready var feedback: Label = $Feedback
@onready var feedback_timer: Timer = $FeedbackTimer
@onready var story_panel: ColorRect = $StoryPanel
@onready var story_image: TextureRect = $StoryPanel/StoryImage
var phase := Phase.MOON
var selected_ids: Array[StringName] = []
var slot_ids: Array[StringName] = [&"", &""]
var moon_tokens: Dictionary = {}
var word_tokens: Dictionary = {}
var underwater_labels: Dictionary = {}
var choices: Dictionary = {}
var rise_tween: Tween
var introduction_started := false
var story_dialogue: StoryDialogue
var story_shade: ColorRect
var story_tween: Tween
var story_canvas: Control
var story_panels: Dictionary = {}
const STORY_CANVAS_SIZE := Vector2(3508, 2480)
var introduction_pages: Array[Dictionary] = []
var narrative_pages: Array[Dictionary] = []
var closing := false

func _ready() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font = FONT
	ui_theme.default_font_size = 36
	ui_theme.set_color("font_color", "Label", Color.BLACK)
	theme = ui_theme
	for hint: Label in [esc_hint, enter_hint, feedback]:
		TextStyle.apply(hint)
	water.puzzle = self
	water_ripple.configure(definition.water_ripple, definition.ripple_source_uv)
	moon_environment.texture = definition.moon_environment
	moon_well.texture = definition.moon_well
	for slot in slots:
		slot.puzzle = self
	for option: Resource in definition.options:
		choices[option.choice_id] = option
		moon_tokens[option.choice_id] = _make_token(option, &"moon")
		var label := Label.new()
		label.text = option.word
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 32)
		if _has_moon_art():
			TextStyle.apply(label, 32)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		underwater_words.add_child(label)
		underwater_labels[option.choice_id] = label
	verb.text = definition.sentence_verb
	feedback.text = definition.failure_text
	resized.connect(_layout)
	feedback_timer.timeout.connect(reset_attempt)
	_setup_story()
	reset_attempt()
	if show_introduction and not introduction_pages.is_empty():
		_show_introduction()

func _make_token(option: Resource, kind: StringName) -> Control:
	var token = Control.new()
	token.set_script(TokenScript)
	token.choice = option
	token.token_kind = kind
	token.puzzle = self
	token.light_backing = _has_moon_art()
	cards.add_child(token)
	return token

func _layout() -> void:
	if not is_node_ready():
		return
	var w := size.x
	var h := size.y
	var art_visible := _has_moon_art() and phase not in [Phase.STORY, Phase.RETURNING]
	moon_environment.visible = art_visible
	moon_well.visible = art_visible
	sentence_backing.visible = art_visible
	water.draw_surface = not art_visible
	if art_visible:
		var fit := maxf(w / definition.moon_reference_size.x, h / definition.moon_reference_size.y)
		var origin: Vector2 = (size - definition.moon_reference_size * fit) * 0.5
		moon_environment.position = origin
		moon_environment.size = definition.moon_reference_size * fit
		moon_well.position = origin + definition.moon_well_rect.position * fit
		moon_well.size = definition.moon_well_rect.size * fit
		water.position = origin + definition.moon_water_rect.position * fit
		water.size = definition.moon_water_rect.size * fit
	else:
		water.position = Vector2(w * 0.16, h * 0.72)
		water.size = Vector2(w * 0.68, h * 0.20)
	water.drop_polygon = PackedVector2Array()
	if art_visible and definition.water_drop_polygon.size() >= 3:
		var water_fit := _art_fit()
		for point: Vector2 in definition.water_drop_polygon:
			water.drop_polygon.append(point * water_fit)
	water_ripple.position = Vector2.ZERO
	water_ripple.size = water.size
	if phase not in [Phase.MOON, Phase.RISING]:
		water_ripple.stop()
	var total: int = definition.options.size()
	for index in range(total):
		var option: Resource = definition.options[index]
		var t := float(index) / maxf(1.0, total - 1.0)
		var token: Control = moon_tokens[option.choice_id]
		token.size = definition.moon_token_size * minf(w / definition.moon_reference_size.x, h / definition.moon_reference_size.y)
		if art_visible and index < definition.moon_centers.size():
			token.position = _reference_point(definition.moon_centers[index]) - token.size * 0.5
		else:
			token.position = Vector2(w * (0.12 + 0.76 * t), h * (0.14 + 0.26 * pow(absf(t - 0.5) * 2.0, 1.4))) - token.size * 0.5
		var label: Label = underwater_labels[option.choice_id]
		label.size = Vector2(64, 62) if art_visible else Vector2(140, 48)
		if art_visible and index < definition.underwater_word_centers.size():
			label.position = _reference_point(definition.underwater_word_centers[index]) - label.size * 0.5
		else:
			label.position = water.position + Vector2(water.size.x * (0.12 + 0.76 * t), water.size.y * 0.5) - label.size * 0.5 if art_visible else water.position + Vector2(water.size.x * (0.12 + 0.76 * t), water.size.y * 0.13) - Vector2(70, 0)
	if phase != Phase.RISING:
		sentence.position = _sentence_position()
	sentence.size = definition.sentence_rect.size * _art_fit() if art_visible and definition.sentence_rect.has_area() else size * (Vector2(0.48, 0.09) if phase == Phase.MOON else Vector2(0.56, 0.10))
	sentence_backing.position = Vector2(-12, -12)
	sentence_backing.size = sentence.size + Vector2(24, 24)
	slots[0].position = Vector2.ZERO
	slots[0].size = sentence.size * Vector2(0.34, 1)
	slots[1].position = sentence.size * Vector2(0.66, 0)
	slots[1].size = slots[0].size
	verb.position = sentence.size * Vector2(0.35, 0)
	verb.size = sentence.size * Vector2(0.30, 1)
	if phase != Phase.RISING:
		_position_words()
	esc_hint.position = Vector2(w - 310, 26)
	esc_hint.size = Vector2(280, 66)
	enter_hint.size = Vector2(440, 66)
	enter_hint.position = Vector2((w - enter_hint.size.x) * 0.5, h * 0.58 if art_visible else h - 76)
	feedback.size = Vector2(540, 66)
	feedback.position = Vector2((w - feedback.size.x) * 0.5, water.position.y - 85)
	if art_visible and definition.enter_hint_center.x >= 0.0:
		enter_hint.position = _reference_point(definition.enter_hint_center) - enter_hint.size * 0.5
	if art_visible and definition.feedback_center.x >= 0.0:
		feedback.position = _reference_point(definition.feedback_center) - feedback.size * 0.5
	story_panel.position = Vector2.ZERO if not narrative_pages.is_empty() else size * Vector2(0.1, 0.1)
	story_panel.size = size if not narrative_pages.is_empty() else size * Vector2(0.8, 0.8)
	if not narrative_pages.is_empty():
		var story_fit := minf(w / 1920.0, h / 1080.0)
		var dialogue_top := (h - 1080.0 * story_fit) * 0.5 + 800.0 * story_fit
		if not story_panels.is_empty():
			var composition_fit := minf(w / STORY_CANVAS_SIZE.x, dialogue_top / STORY_CANVAS_SIZE.y)
			story_canvas.scale = Vector2.ONE * composition_fit
			story_canvas.position = (Vector2(w, dialogue_top) - STORY_CANVAS_SIZE * composition_fit) * 0.5
		else:
			story_image.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
			story_image.position = Vector2.ZERO
			story_image.size = Vector2(w, dialogue_top)
			story_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _art_fit() -> float:
	return maxf(size.x / definition.moon_reference_size.x, size.y / definition.moon_reference_size.y)

func _reference_point(point: Vector2) -> Vector2:
	var fit := _art_fit()
	return (size - definition.moon_reference_size * fit) * 0.5 + point * fit

func _sentence_position() -> Vector2:
	if _has_moon_art() and definition.sentence_rect.has_area():
		return _reference_point(definition.sentence_rect.position)
	if _has_moon_art():
		return size * Vector2(0.26, 0.66) if phase == Phase.MOON else size * Vector2(0.22, 0.66)
	return size * Vector2(0.26, 0.78) if phase == Phase.MOON else size * Vector2(0.22, 0.22)

func _has_moon_art() -> bool:
	return definition.moon_environment != null and definition.moon_well != null

func _word_home(choice_id: StringName) -> Vector2:
	if _has_moon_art():
		var moon: Control = moon_tokens[choice_id]
		return moon.position + moon.size * 0.5 - Vector2(60, 36)
	var index := selected_ids.find(choice_id)
	var t := float(index) / maxf(1.0, selected_ids.size() - 1.0) if selected_ids.size() > 1 else 0.5
	return size * Vector2(0.20 + 0.60 * t, 0.50) - Vector2(60, 36)

func _position_words() -> void:
	for choice_id: StringName in word_tokens:
		var token: Control = word_tokens[choice_id]
		token.size = Vector2(120, 72)
		var slot_index := slot_ids.find(choice_id)
		if slot_index >= 0:
			token.position = sentence.position + slots[slot_index].position + slots[slot_index].size * Vector2(0.5, 0.43) - token.size * 0.5
		else:
			token.position = _word_home(choice_id)

func can_drag(kind: StringName, choice_id: StringName) -> bool:
	if kind == &"moon":
		return phase == Phase.MOON and choices.has(choice_id) and available_fragment_ids.has(choices[choice_id].fragment_id) and not selected_ids.has(choice_id)
	return kind == &"word" and phase == Phase.WORD and selected_ids.has(choice_id)

func accepts_drag(data: Variant, kind: StringName) -> bool:
	return data is Dictionary and data.get("puzzle_instance") == get_instance_id() and data.get("kind") == kind and can_drag(kind, data.get("choice_id", &""))

func add_moon(choice_id: StringName) -> void:
	if not can_drag(&"moon", choice_id):
		return
	selected_ids.append(choice_id)
	moon_tokens[choice_id].hide()
	underwater_labels[choice_id].add_theme_color_override("font_color", Color.BLACK)
	if definition.water_ripple != null:
		water_ripple.play()
	if definition.rise_on_drop:
		_rise_dropped_word(choice_id)
	_refresh_hint()

func assign_word(choice_id: StringName, slot_index: int) -> void:
	if not can_drag(&"word", choice_id) or slot_index < 0 or slot_index > 1:
		return
	var source := slot_ids.find(choice_id)
	if source == slot_index:
		return
	var displaced := slot_ids[slot_index]
	if source >= 0:
		slot_ids[source] = displaced
	slot_ids[slot_index] = choice_id
	_position_words()
	_refresh_hint()

func remove_word(choice_id: StringName) -> void:
	if not can_drag(&"word", choice_id):
		return
	var source := slot_ids.find(choice_id)
	if source >= 0:
		slot_ids[source] = &""
		_position_words()
		_refresh_hint()

func _refresh_hint() -> void:
	enter_hint.visible = (phase == Phase.MOON and not selected_ids.is_empty()) or (phase == Phase.WORD and (slot_ids[0] != &"" or slot_ids[1] != &""))
	for slot in slots:
		slot.mouse_filter = Control.MOUSE_FILTER_STOP if phase == Phase.WORD else Control.MOUSE_FILTER_IGNORE

func confirm_restoration() -> void:
	if phase == Phase.MOON and not selected_ids.is_empty():
		_rise_words()
	elif phase == Phase.WORD and (slot_ids[0] != &"" or slot_ids[1] != &""):
		if slot_ids[0] == definition.answer_left and slot_ids[1] == definition.answer_right:
			_show_story()
		else:
			phase = Phase.FEEDBACK
			feedback.show()
			_refresh_hint()
			feedback_timer.start(definition.failure_duration)

func _surface_word_position(choice_id: StringName, token: Control) -> Vector2:
	if not definition.underwater_word_centers.is_empty():
		var underwater: Label = underwater_labels[choice_id]
		var center := underwater.position + underwater.size * 0.5
		center.x = clampf(center.x, water.position.x + water.size.x * 0.08, water.position.x + water.size.x * 0.92)
		center.y = water.position.y + water.size.y * 0.5
		return center - token.size * 0.5
	return token.position - Vector2(0, maxf(32.0, water.size.y * 0.7))

func _rise_dropped_word(choice_id: StringName) -> void:
	phase = Phase.RISING
	var underwater: Label = underwater_labels[choice_id]
	var token := _make_token(choices[choice_id], &"word")
	token.size = Vector2(120, 72)
	token.position = underwater.position + underwater.size * 0.5 - token.size * 0.5
	token.modulate.a = 0.0
	word_tokens[choice_id] = token
	underwater.hide()
	var surface := _surface_word_position(choice_id, token)
	var rise_time: float = definition.rise_duration * 0.35
	var flight_time: float = definition.rise_duration * 0.65
	rise_tween = create_tween().set_parallel(true)
	rise_tween.tween_property(token, "position", surface, rise_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	rise_tween.tween_property(token, "modulate:a", 1.0, rise_time)
	rise_tween.tween_property(token, "position", _word_home(choice_id), flight_time).from(surface).set_delay(rise_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	rise_tween.finished.connect(_finish_dropped_word)

func _finish_dropped_word() -> void:
	phase = Phase.MOON
	_layout()
	_refresh_hint()

func _rise_words() -> void:
	# Order follows the configuration, independently of drop order.
	var ordered: Array[StringName] = []
	for option: Resource in definition.options:
		if selected_ids.has(option.choice_id):
			ordered.append(option.choice_id)
	selected_ids = ordered
	if definition.rise_on_drop:
		for moon: Control in moon_tokens.values():
			moon.hide()
		underwater_words.hide()
		phase = Phase.WORD
		_layout()
		_refresh_hint()
		return
	phase = Phase.RISING
	for token: Control in moon_tokens.values():
		token.hide()
	underwater_words.hide()
	_refresh_hint()
	_layout()
	rise_tween = create_tween().set_parallel(true)
	rise_tween.tween_property(sentence, "position", _sentence_position(), definition.rise_duration).set_trans(Tween.TRANS_SINE)
	for choice_id: StringName in selected_ids:
		var token := _make_token(choices[choice_id], &"word")
		token.size = Vector2(120, 72)
		var underwater: Label = underwater_labels[choice_id]
		token.position = underwater.position + underwater.size * 0.5 - token.size * 0.5
		token.modulate.a = 0.0
		word_tokens[choice_id] = token
		var surface := _surface_word_position(choice_id, token)
		var rise_time: float = definition.rise_duration * 0.35
		var flight_time: float = definition.rise_duration * 0.65
		rise_tween.tween_property(token, "position", surface, rise_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		rise_tween.tween_property(token, "modulate:a", 1.0, rise_time)
		rise_tween.tween_property(token, "position", _word_home(choice_id), flight_time).from(surface).set_delay(rise_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	rise_tween.finished.connect(_finish_rise)

func _finish_rise() -> void:
	phase = Phase.WORD
	for token: Control in word_tokens.values():
		token.light_backing = _has_moon_art()
		token.queue_redraw()
	_layout()
	_refresh_hint()

func _show_story() -> void:
	if not definition.play_success_story:
		restoration_succeeded.emit(definition.puzzle_id)
		_return_to_world()
		return
	phase = Phase.STORY
	_refresh_hint()
	water.hide()
	sentence.hide()
	cards.hide()
	underwater_words.hide()
	feedback.hide()
	story_image.texture = definition.success_image
	story_image.visible = definition.success_image != null and story_panels.is_empty()
	story_canvas.visible = not story_panels.is_empty()
	for panel: TextureRect in story_panels.values():
		panel.hide()
	story_panel.color = Color.BLACK if not narrative_pages.is_empty() else Color(0.85, 0.85, 0.85)
	story_panel.show()
	_layout()
	if not narrative_pages.is_empty():
		esc_hint.hide()
		story_panel.modulate.a = 0.0
		story_dialogue.modulate.a = 0.0
		story_dialogue.start(narrative_pages)
		story_dialogue.move_to_front()
		story_tween = create_tween().set_parallel(true)
		story_tween.tween_property(story_panel, "modulate:a", 1.0, 0.4)
		story_tween.tween_property(story_dialogue, "modulate:a", 1.0, 0.4)
	else:
		esc_hint.move_to_front()
	restoration_succeeded.emit(definition.puzzle_id)

func reset_attempt() -> void:
	if is_instance_valid(story_tween):
		story_tween.kill()
	if is_instance_valid(story_dialogue):
		story_dialogue.stop()
		story_shade.hide()
	water_ripple.stop()
	if is_instance_valid(rise_tween):
		rise_tween.kill()
	feedback_timer.stop()
	phase = Phase.MOON
	modulate.a = 1.0
	selected_ids.clear()
	slot_ids.assign([&"", &""])
	for token: Control in word_tokens.values():
		cards.remove_child(token)
		token.queue_free()
	word_tokens.clear()
	for choice_id: StringName in moon_tokens:
		moon_tokens[choice_id].visible = available_fragment_ids.has(choices[choice_id].fragment_id)
	for label: Label in underwater_labels.values():
		label.show()
		label.add_theme_color_override("font_color", Color.BLACK)
	water.show()
	sentence.show()
	cards.show()
	underwater_words.show()
	feedback.hide()
	story_panel.hide()
	for panel: TextureRect in story_panels.values():
		panel.hide()
	esc_hint.show()
	_layout()
	_refresh_hint()

func request_exit() -> void:
	if closing:
		return
	closing = true
	if is_instance_valid(rise_tween):
		rise_tween.kill()
	if is_instance_valid(story_tween):
		story_tween.kill()
	story_dialogue.stop()
	if exit_requested.has_connections():
		exit_requested.emit()
	elif get_tree().current_scene == self:
		get_tree().quit()

func handle_input(event: InputEvent) -> bool:
	if phase == Phase.RETURNING:
		return event is InputEventKey or event is InputEventMouseButton
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE:
			request_exit()
			return true
	if phase in [Phase.INTRO, Phase.STORY] and story_dialogue.active:
		return story_dialogue.handle_input(event)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER] or event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			confirm_restoration()
			return true
	if phase == Phase.STORY and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		request_exit()
		return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	var viewport := get_viewport()
	if handle_input(event):
		viewport.set_input_as_handled()

func _setup_story() -> void:
	if definition.story_script != null:
		var constants: Dictionary = definition.story_script.get_script_constant_map()
		introduction_pages.assign(constants.get("INTRO_PAGES", []))
		narrative_pages.assign(constants.get("NARRATIVE_PAGES", []))
	story_shade = ColorRect.new()
	story_shade.name = "DialogueShade"
	story_shade.color = Color(0, 0, 0, 0.45)
	story_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(story_shade)
	story_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	story_shade.hide()
	story_dialogue = StoryDialogue.new()
	story_dialogue.name = "WellDialogue"
	add_child(story_dialogue)
	story_dialogue.finished.connect(_on_story_dialogue_finished)
	story_dialogue.page_changed.connect(_on_story_page_changed)
	_build_story_panels()

func _show_introduction() -> void:
	phase = Phase.INTRO
	introduction_started = true
	for control: Control in [water, sentence, cards, underwater_words, esc_hint, enter_hint, feedback]:
		control.hide()
	story_shade.show()
	story_dialogue.start(introduction_pages)
	_refresh_hint()

func _on_story_dialogue_finished() -> void:
	if phase == Phase.INTRO:
		reset_attempt()
	elif phase == Phase.STORY:
		_return_to_world()

func _return_to_world() -> void:
	phase = Phase.RETURNING
	_refresh_hint()
	water_ripple.stop()
	if is_instance_valid(story_tween):
		story_tween.kill()
	# Keep modal input locked until the puzzle/CG has faded off the original world.
	return_started.emit()
	story_tween = create_tween()
	story_tween.tween_property(self, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	story_tween.tween_callback(request_exit)

func _on_story_page_changed(index: int) -> void:
	if phase != Phase.STORY:
		return
	var image_path := String(narrative_pages[index].get("cg_image", ""))
	if image_path.is_empty():
		return
	if story_panels.has(image_path):
		var panel: TextureRect = story_panels[image_path]
		if not panel.visible:
			panel.modulate.a = 0.0
			panel.show()
			create_tween().tween_property(panel, "modulate:a", 1.0, 0.35)
		return
	var artwork := load(image_path) as Texture2D
	if artwork != null:
		story_image.texture = artwork
		story_image.show()

func _build_story_panels() -> void:
	story_canvas = Control.new()
	story_canvas.name = "StoryComposition"
	story_canvas.size = STORY_CANVAS_SIZE
	story_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story_panel.add_child(story_canvas)
	story_canvas.hide()
	for page: Dictionary in narrative_pages:
		var image_path := String(page.get("cg_image", ""))
		if image_path.is_empty() or story_panels.has(image_path):
			continue
		var artwork := load(image_path) as AtlasTexture
		if artwork == null:
			continue
		var panel := TextureRect.new()
		panel.name = "StoryPanel%d" % (story_panels.size() + 1)
		panel.texture = artwork
		# Crop out the white borders while retaining the source composition.
		panel.position = artwork.region.position
		panel.size = artwork.region.size
		panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		panel.stretch_mode = TextureRect.STRETCH_SCALE
		panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		story_canvas.add_child(panel)
		panel.hide()
		story_panels[image_path] = panel
