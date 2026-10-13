extends Control
## Once introduced, the protagonist stays visible for this dialogue sequence.
signal finished
signal page_changed(index: int)

const FONT = preload("res://ui_font.tres")
const REFERENCE_SIZE := Vector2(1920, 1080)
const PORTRAIT_REGION := Rect2(180, 70, 715, 1800)
const PORTRAIT_POSITION := Vector2(1285, 105)
const PORTRAIT_FILES := {
	&"neutral": "res://assets/art/characters/protagonist/protagonist_neutral.png",
	&"speaking": "res://assets/art/characters/protagonist/protagonist_speaking.png",
	&"smile": "res://assets/art/characters/protagonist/protagonist_smile.png",
	&"teary": "res://assets/art/characters/protagonist/protagonist_teary.png",
}
@export var characters_per_second := 42.0

var pages: Array[Dictionary] = []
var page_index := 0
var active := false
var artwork: Control
var portrait: TextureRect
var panel: ColorRect
var speaker_label: Label
var body_label: Label
var hint_label: Label
var _textures: Dictionary = {}
var _revealed := 0.0
var _input_cooldown := 0.0
var _mouth_time := 0.0
var _expression: StringName = &"neutral"
var _base_position := Vector2.ZERO
var _shake_offset := Vector2.ZERO
var _portrait_tween: Tween
var _portrait_present := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artwork = Control.new()
	artwork.name = "Artwork"
	artwork.size = REFERENCE_SIZE
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(artwork)
	for expression: StringName in PORTRAIT_FILES:
		var texture := AtlasTexture.new()
		texture.atlas = load(PORTRAIT_FILES[expression]) as Texture2D
		texture.region = PORTRAIT_REGION
		_textures[expression] = texture
	portrait = TextureRect.new()
	portrait.name = "ProtagonistPortrait"
	portrait.position = PORTRAIT_POSITION
	portrait.size = Vector2(555, 1397)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork.add_child(portrait)
	portrait.hide()
	panel = ColorRect.new()
	panel.name = "DialoguePanel"
	panel.color = Color.WHITE
	panel.position = Vector2(58, 800)
	panel.size = Vector2(1804, 248)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork.add_child(panel)
	speaker_label = _make_label("Speaker", 32)
	speaker_label.position = Vector2(32, 18)
	speaker_label.size = Vector2(1740, 42)
	body_label = _make_label("Body", 36)
	body_label.size = Vector2(1740, 168)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_constant_override("line_spacing", 10)
	hint_label = _make_label("ContinueHint", 22)
	hint_label.position = Vector2(1200, 207)
	hint_label.size = Vector2(568, 30)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	get_viewport().size_changed.connect(_fit)
	_fit()
	hide()

func _make_label(node_name: String, font_size: int) -> Label:
	var result := Label.new()
	result.name = node_name
	result.add_theme_font_override("font", FONT)
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", Color.BLACK)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(result)
	return result

func _fit() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / REFERENCE_SIZE.x, viewport_size.y / REFERENCE_SIZE.y)
	artwork.scale = Vector2.ONE * fit
	_base_position = (viewport_size - REFERENCE_SIZE * fit) * 0.5
	set_shake_offset(_shake_offset)

func set_shake_offset(offset: Vector2) -> void:
	_shake_offset = offset
	if is_instance_valid(artwork):
		artwork.position = _base_position + offset * artwork.scale

func start(story_pages: Array[Dictionary]) -> void:
	if story_pages.is_empty():
		return
	pages.assign(story_pages.duplicate(true))
	page_index = 0
	_portrait_present = false
	portrait.hide()
	active = true
	show()
	_show_page()

func _show_page() -> void:
	var page: Dictionary = pages[page_index]
	var speaker := String(page.get("speaker", ""))
	speaker_label.text = speaker + "：" if not speaker.is_empty() else ""
	speaker_label.visible = not speaker.is_empty()
	body_label.position = Vector2(32, 68 if speaker_label.visible else 30)
	body_label.size = Vector2(1740, 130 if speaker_label.visible else 168)
	body_label.text = String(page.get("text", ""))
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body_label.visible_characters = 0
	_revealed = 0.0
	_input_cooldown = 0.15
	_mouth_time = 0.0
	_expression = StringName(page.get("expression", &"neutral"))
	if not _textures.has(_expression):
		_expression = &"neutral"
	portrait.texture = _textures[_expression]
	_portrait_present = _portrait_present or bool(page.get("show_protagonist", speaker in ["主角", "你", "protagonist"]))
	var show_protagonist := _portrait_present
	var was_visible := portrait.visible
	if is_instance_valid(_portrait_tween):
		_portrait_tween.kill()
	portrait.visible = show_protagonist
	portrait.position = PORTRAIT_POSITION
	portrait.modulate.a = 1.0
	if show_protagonist and not was_visible:
		portrait.modulate.a = 0.0
		portrait.position.x += 28
		_portrait_tween = create_tween().set_parallel(true)
		_portrait_tween.tween_property(portrait, "modulate:a", 1.0, 0.35)
		_portrait_tween.tween_property(portrait, "position", PORTRAIT_POSITION, 0.35).set_trans(Tween.TRANS_SINE)
	_update_hint()
	page_changed.emit(page_index)

func _process(delta: float) -> void:
	if not active:
		return
	_input_cooldown = maxf(0.0, _input_cooldown - delta)
	var text_length := body_label.text.length()
	_revealed = minf(text_length, _revealed + delta * characters_per_second)
	body_label.visible_characters = int(_revealed)
	if portrait.visible and _expression == &"speaking":
		_mouth_time += delta
		var speaking := int(_mouth_time / 0.16) % 2 == 0 and not is_text_complete()
		portrait.texture = _textures[&"speaking" if speaking else &"neutral"]
	_update_hint()

func _update_hint() -> void:
	hint_label.text = "点击继续  ▸" if is_text_complete() else "点击显示全文"

func is_text_complete() -> bool:
	return body_label.visible_characters >= body_label.text.length()

func reveal_text() -> void:
	_revealed = body_label.text.length()
	body_label.visible_characters = body_label.text.length()
	_update_hint()

func advance() -> void:
	if not active or _input_cooldown > 0.0:
		return
	if not is_text_complete():
		reveal_text()
		_input_cooldown = 0.15
		return
	if page_index + 1 >= pages.size():
		active = false
		finished.emit()
	else:
		page_index += 1
		_show_page()

func handle_input(event: InputEvent) -> bool:
	if not active:
		return false
	var click: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var key: bool = event is InputEventKey and event.pressed and not event.echo and (event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_F] or event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_F])
	if click or key:
		advance()
	return click or key or event.is_action_pressed("ui_cancel")

func stop() -> void:
	active = false
	_portrait_present = false
	portrait.hide()
	pages.clear()
	set_shake_offset(Vector2.ZERO)
	if is_instance_valid(_portrait_tween):
		_portrait_tween.kill()
	hide()
