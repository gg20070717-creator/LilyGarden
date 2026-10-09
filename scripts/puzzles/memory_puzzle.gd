extends Control
## Reusable core scene: all attempt state lives here; exploration stays in the caller.
signal exit_requested
signal restoration_succeeded(puzzle_id: StringName)
const TokenScript = preload("res://scripts/puzzles/memory_token.gd")
const FONT = preload("res://ui_font.tres")
const TextStyle = preload("res://scripts/ui_text_style.gd")
enum Phase { MOON, RISING, WORD, FEEDBACK, STORY }
@export var definition: Resource = preload("res://resources/well_memory_puzzle.tres")
## Caller-owned inventory snapshot. The scene never grants or consumes fragments.
@export var available_fragment_ids: Array[StringName] = []
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
	resized.connect(_layout)
	feedback_timer.timeout.connect(reset_attempt)
	reset_attempt()

func _make_token(option: Resource, kind: StringName) -> Control:
	var token = Control.new()
	token.set_script(TokenScript)
	token.choice = option
	token.token_kind = kind
	token.puzzle = self
	token.light_backing = _has_moon_art() and phase in [Phase.MOON, Phase.RISING]
	cards.add_child(token)
	return token

func _layout() -> void:
	if not is_node_ready():
		return
	var w := size.x
	var h := size.y
	var art_visible := _has_moon_art() and phase in [Phase.MOON, Phase.RISING]
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
	water_ripple.position = Vector2.ZERO
	water_ripple.size = water.size
	if phase not in [Phase.MOON, Phase.RISING]:
		water_ripple.stop()
	var total: int = definition.options.size()
	for index in range(total):
		var option: Resource = definition.options[index]
		var t := float(index) / maxf(1.0, total - 1.0)
		var token: Control = moon_tokens[option.choice_id]
		token.size = Vector2(144, 144) * minf(w / 1920.0, h / 1080.0)
		token.position = Vector2(w * (0.12 + 0.76 * t), h * (0.14 + 0.26 * pow(absf(t - 0.5) * 2.0, 1.4))) - token.size * 0.5
		var label: Label = underwater_labels[option.choice_id]
		label.size = Vector2(64, 62) if art_visible else Vector2(140, 48)
		label.position = water.position + Vector2(water.size.x * (0.12 + 0.76 * t), water.size.y * 0.5) - label.size * 0.5 if art_visible else water.position + Vector2(water.size.x * (0.12 + 0.76 * t), water.size.y * 0.13) - Vector2(70, 0)
	if phase != Phase.RISING:
		sentence.position = _sentence_position()
	sentence.size = size * (Vector2(0.48, 0.09) if phase == Phase.MOON else Vector2(0.56, 0.10))
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
	story_panel.position = size * Vector2(0.1, 0.1)
	story_panel.size = size * Vector2(0.8, 0.8)

func _sentence_position() -> Vector2:
	return size * Vector2(0.26, 0.66 if _has_moon_art() else 0.78) if phase == Phase.MOON else size * Vector2(0.22, 0.22)

func _has_moon_art() -> bool:
	return definition.moon_environment != null and definition.moon_well != null

func _word_home(choice_id: StringName) -> Vector2:
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
	water_ripple.play()
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

func _rise_words() -> void:
	# Order follows the configuration, independently of drop order.
	var ordered: Array[StringName] = []
	for option: Resource in definition.options:
		if selected_ids.has(option.choice_id):
			ordered.append(option.choice_id)
	selected_ids = ordered
	phase = Phase.RISING
	for token: Control in moon_tokens.values():
		token.hide()
	underwater_words.hide()
	_refresh_hint()
	_layout()
	rise_tween = create_tween().set_parallel(true)
	rise_tween.tween_property(sentence, "position", size * Vector2(0.22, 0.22), definition.rise_duration).set_trans(Tween.TRANS_SINE)
	for choice_id: StringName in selected_ids:
		var token := _make_token(choices[choice_id], &"word")
		token.size = Vector2(120, 72)
		token.position = underwater_labels[choice_id].position
		word_tokens[choice_id] = token
		rise_tween.tween_property(token, "position", _word_home(choice_id), definition.rise_duration).set_trans(Tween.TRANS_SINE)
	rise_tween.finished.connect(_finish_rise)

func _finish_rise() -> void:
	phase = Phase.WORD
	for token: Control in word_tokens.values():
		token.light_backing = false
		token.queue_redraw()
	_layout()
	_refresh_hint()

func _show_story() -> void:
	phase = Phase.STORY
	_refresh_hint()
	water.hide()
	sentence.hide()
	cards.hide()
	underwater_words.hide()
	feedback.hide()
	story_image.texture = definition.success_image
	story_image.visible = definition.success_image != null
	story_panel.show()
	esc_hint.move_to_front()
	restoration_succeeded.emit(definition.puzzle_id)

func reset_attempt() -> void:
	water_ripple.stop()
	if is_instance_valid(rise_tween):
		rise_tween.kill()
	feedback_timer.stop()
	phase = Phase.MOON
	selected_ids.clear()
	slot_ids.assign([&"", &""])
	for token: Control in word_tokens.values():
		cards.remove_child(token)
		token.queue_free()
	word_tokens.clear()
	for choice_id: StringName in moon_tokens:
		moon_tokens[choice_id].visible = available_fragment_ids.has(choices[choice_id].fragment_id)
	for label: Label in underwater_labels.values():
		label.add_theme_color_override("font_color", Color.BLACK)
	water.show()
	sentence.show()
	cards.show()
	underwater_words.show()
	feedback.hide()
	story_panel.hide()
	_layout()
	_refresh_hint()

func request_exit() -> void:
	if exit_requested.has_connections():
		exit_requested.emit()
	elif get_tree().current_scene == self:
		get_tree().quit()

func handle_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE:
			request_exit()
			return true
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
