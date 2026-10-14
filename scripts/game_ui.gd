extends CanvasLayer
signal view_state_changed(is_open: bool)
signal restoration_succeeded(puzzle_id: StringName)
const FONT = preload("res://ui_font.tres")
const TextStyle = preload("res://scripts/ui_text_style.gd")
const PuzzleScene = preload("res://scenes/puzzles/memory_puzzle.tscn")
const StoryDialogue = preload("res://scripts/ui/story_dialogue.gd")
const ControlsHint = preload("res://scripts/ui/controls_hint.gd")
const CollectionPreview = preload("res://scripts/collection_preview.gd")
enum ModalMode { NONE, IMAGE, PUZZLE, COLLECTION, DIALOGUE }
var modal_mode := ModalMode.NONE
var active_puzzle
var modal_open := false
var puzzle_returning := false
var pending_puzzle_dialogue: Array[Dictionary] = []
var puzzle_drag_hint_seen := false
var note_remaining := 0.0
var note_anchor := Vector2.ZERO
var prompt_anchor := Vector2.ZERO
var scene_name := ""
var current_view_title := ""
var dialogue: StoryDialogue
var controls_hint: ControlsHint
var root_control: Control
var prompt_label: Label
var note_label: Label
var overlay: ColorRect
var view_notice: Label
var view_caption: Label
var view_footer: Label
var view_panel: ColorRect
var view_texture: TextureRect
var collection_panel: ColorRect
var collection_text: Label
var collection_footer: Label
var collection_preview: CollectionPreview
var collection_pages: Array[String] = []
var collection_page := 0
var collection_reward_page := -1
var collection_exit_hint := false
var collection_large_artwork := false
var image_slides: Array[Texture2D] = []
var image_slide_index := 0
var image_slide_duration := 2.0
var image_slide_elapsed := 0.0

func _ready() -> void:
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 36
	root_control.theme = theme
	prompt_label = _label(root_control, "", 36, Color.BLACK)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.hide()
	note_label = _label(root_control, "", 36, Color.BLACK)
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.hide()
	overlay = ColorRect.new()
	overlay.color = Color(0.1, 0.1, 0.1)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(overlay)
	view_panel = ColorRect.new()
	view_panel.color = Color(0.88, 0.88, 0.88)
	view_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(view_panel)
	view_texture = TextureRect.new()
	view_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(view_texture)
	view_caption = _label(overlay, "", 36, Color.BLACK)
	view_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	view_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	view_notice = _label(overlay, "", 40, Color.BLACK)
	view_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	view_footer = _label(overlay, "左键点击屏幕任意位置退出", 36, Color.BLACK)
	view_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	collection_panel = ColorRect.new()
	collection_panel.color = Color.WHITE
	collection_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(collection_panel)
	collection_text = _label(collection_panel, "", 36, Color.BLACK)
	collection_text.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	collection_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	collection_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	collection_footer = _label(collection_panel, "左键点击屏幕任意位置退出", 36, Color.BLACK)
	collection_footer.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	collection_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	collection_preview = CollectionPreview.new()
	collection_panel.add_child(collection_preview)
	collection_panel.hide()
	overlay.hide()
	dialogue = StoryDialogue.new()
	dialogue.name = "StoryDialogue"
	root_control.add_child(dialogue)
	dialogue.finished.connect(close_view)
	controls_hint = ControlsHint.new()
	root_control.add_child(controls_hint)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	TextStyle.apply(result, font_size)
	parent.add_child(result)
	return result

func _layout() -> void:
	var viewport := get_viewport().get_visible_rect().size
	var has_caption := not view_caption.text.is_empty()
	var panel_rect := Rect2(viewport * Vector2(0.1, 0.28 if has_caption else 0.1), viewport * Vector2(0.8, 0.60 if has_caption else 0.7))
	view_panel.position = panel_rect.position
	view_panel.size = panel_rect.size
	view_texture.position = panel_rect.position
	view_texture.size = panel_rect.size
	if modal_mode == ModalMode.IMAGE and not image_slides.is_empty():
		view_texture.position = Vector2.ZERO
		view_texture.size = viewport
	if modal_mode == ModalMode.COLLECTION and collection_large_artwork:
		view_texture.position = viewport * Vector2(0.03, 0.03)
		view_texture.size = viewport * Vector2(0.94, 0.66)
	view_caption.position = viewport * Vector2(0.1, 0.035)
	view_caption.size = viewport * Vector2(0.8, 0.13)
	view_notice.position = Vector2(viewport.x * 0.1, viewport.y * (0.18 if has_caption else 0.82))
	view_notice.size = Vector2(viewport.x * 0.8, 70)
	view_footer.size = Vector2(_line_width(view_footer), 66)
	view_footer.position = Vector2((viewport.x - view_footer.size.x) * 0.5, viewport.y * 0.92)
	collection_panel.position = viewport * Vector2(0.03, 0.72)
	collection_panel.size = viewport * Vector2(0.94, 0.25)
	var inset := 32.0
	var content_height := collection_panel.size.y - 48.0
	collection_preview.position = Vector2(inset, 24)
	collection_preview.size = Vector2(minf(200, collection_panel.size.x * 0.2), content_height)
	var text_left := inset + (collection_preview.size.x + 32 if collection_preview.visible else 0.0)
	collection_text.position = Vector2(text_left, 24)
	collection_text.size = Vector2(collection_panel.size.x - text_left - inset, content_height - (66 if collection_footer.visible else 0))
	collection_footer.position = Vector2(inset, collection_panel.size.y - 76)
	collection_footer.size = Vector2(collection_panel.size.x - inset * 2, 60)
	_position_world_labels()

func _line_width(label: Label) -> float:
	return FONT.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x + 40.0

func _place_world_label(label: Label, anchor: Vector2) -> void:
	var viewport := get_viewport().get_visible_rect().size
	label.size = Vector2(minf(_line_width(label), viewport.x - 40), 66)
	label.position = get_viewport().get_canvas_transform() * anchor - Vector2(label.size.x * 0.5, 40)
	label.position.x = clampf(label.position.x, 20, maxf(20, viewport.x - label.size.x - 20))
	label.position.y = clampf(label.position.y, 20, maxf(20, viewport.y - label.size.y - 20))

func _position_world_labels() -> void:
	_place_world_label(prompt_label, prompt_anchor)
	_place_world_label(note_label, note_anchor)
	if note_label.visible and prompt_label.visible and note_label.get_rect().intersects(prompt_label.get_rect()):
		prompt_label.position.y = note_label.position.y + note_label.size.y + 10

func _process(delta: float) -> void:
	_position_world_labels()
	if modal_mode == ModalMode.IMAGE and not image_slides.is_empty():
		image_slide_elapsed += delta
		while image_slide_elapsed >= image_slide_duration and modal_open:
			image_slide_elapsed -= image_slide_duration
			image_slide_index += 1
			if image_slide_index >= image_slides.size():
				close_view()
			else:
				view_texture.texture = image_slides[image_slide_index]
	if note_remaining > 0:
		note_remaining = maxf(0, note_remaining - delta)
		note_label.visible = note_remaining > 0 and not modal_open

func set_status(location: String, _count: int) -> void:
	# Scene state remains available to other systems without displaying a HUD.
	scene_name = location

func set_prompt(_text: String, _world_anchor: Vector2 = Vector2.ZERO) -> void:
	# Interaction controls are explained once at gameplay entry.
	prompt_label.text = ""
	prompt_label.hide()

func show_controls_hint() -> void:
	controls_hint.present_once()

func is_controls_hint_open() -> bool:
	return is_instance_valid(controls_hint) and controls_hint.is_open

func handle_controls_hint_input(event: InputEvent) -> bool:
	return controls_hint.handle_input(event)

func show_note(text: String, world_anchor: Vector2, seconds: float) -> void:
	note_anchor = world_anchor
	note_remaining = seconds
	note_label.text = text
	note_label.show()
	_process(0)

func clear_note() -> void:
	note_remaining = 0
	note_label.hide()

func show_view(title: String, _caption: String, artwork: Texture2D = null, notice: String = "", show_exit_hint: bool = false, narrative_text: String = "") -> void:
	clear_note()
	image_slides.clear()
	modal_open = true
	modal_mode = ModalMode.IMAGE
	current_view_title = title
	prompt_label.hide()
	collection_panel.hide()
	overlay.color = Color(0.1, 0.1, 0.1)
	view_panel.show()
	view_texture.texture = artwork
	view_texture.visible = artwork != null
	view_notice.text = notice
	view_notice.visible = not notice.is_empty()
	view_caption.text = narrative_text
	view_caption.visible = not narrative_text.is_empty()
	view_footer.visible = show_exit_hint
	_layout()
	overlay.show()
	view_state_changed.emit(true)

func show_slideshow(title: String, artworks: Array[Texture2D], seconds_per_slide: float = 2.0) -> void:
	if modal_open or artworks.is_empty():
		return
	var slides: Array[Texture2D] = []
	for image in artworks:
		if image != null:
			slides.append(image)
	if slides.is_empty():
		return
	show_view(title, "", slides[0])
	image_slides.assign(slides)
	image_slide_index = 0
	image_slide_elapsed = 0.0
	image_slide_duration = maxf(0.1, seconds_per_slide)
	view_panel.hide()
	_layout()

func show_collection(pages: Array[String], artwork: Texture2D = null, placeholder_type: StringName = &"", reward_page: int = -1, show_exit_hint: bool = false, large_artwork: bool = false) -> void:
	if modal_open or pages.is_empty():
		return
	clear_note()
	modal_open = true
	modal_mode = ModalMode.COLLECTION
	collection_pages = pages.duplicate()
	collection_page = 0
	collection_reward_page = reward_page
	collection_exit_hint = show_exit_hint
	collection_large_artwork = large_artwork and artwork != null
	prompt_label.hide()
	for control: Control in [view_panel, view_texture, view_caption, view_notice, view_footer]:
		control.hide()
	overlay.color = Color(0, 0, 0, 0.6)
	view_texture.texture = artwork if collection_large_artwork else null
	view_texture.visible = collection_large_artwork
	collection_preview.artwork = null if collection_large_artwork else artwork
	collection_preview.placeholder_type = placeholder_type
	collection_preview.visible = not collection_large_artwork and (artwork != null or not placeholder_type.is_empty())
	collection_preview.queue_redraw()
	collection_panel.show()
	_show_collection_page()
	overlay.show()
	view_state_changed.emit(true)

func _show_collection_page() -> void:
	collection_text.text = collection_pages[collection_page]
	collection_text.add_theme_font_size_override("font_size", 40 if collection_page == collection_reward_page else 36)
	collection_footer.visible = collection_exit_hint and collection_page == collection_pages.size() - 1
	_layout()

func _advance_collection() -> void:
	if collection_page + 1 >= collection_pages.size():
		close_view()
	else:
		collection_page += 1
		_show_collection_page()

func open_puzzle(definition: Resource, owned_fragments: Array[StringName] = [], show_introduction: bool = false) -> bool:
	if modal_open:
		return false
	clear_note()
	prompt_label.hide()
	overlay.hide()
	modal_open = true
	modal_mode = ModalMode.PUZZLE
	puzzle_returning = false
	pending_puzzle_dialogue.clear()
	active_puzzle = PuzzleScene.instantiate()
	active_puzzle.definition = definition
	active_puzzle.available_fragment_ids = owned_fragments.duplicate()
	active_puzzle.show_introduction = show_introduction
	active_puzzle.show_drag_hint = not puzzle_drag_hint_seen
	active_puzzle.drag_hint_presented.connect(_on_puzzle_drag_hint_presented)
	active_puzzle.exit_requested.connect(close_view)
	active_puzzle.return_started.connect(_on_puzzle_return_started)
	active_puzzle.followup_requested.connect(_on_puzzle_followup_requested)
	active_puzzle.restoration_succeeded.connect(_on_restoration_succeeded)
	root_control.add_child(active_puzzle)
	active_puzzle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view_state_changed.emit(true)
	return true

func _on_puzzle_drag_hint_presented() -> void:
	puzzle_drag_hint_seen = true

func _on_puzzle_followup_requested(pages: Array[Dictionary]) -> void:
	pending_puzzle_dialogue.assign(pages.duplicate(true))

func _on_restoration_succeeded(puzzle_id: StringName) -> void:
	restoration_succeeded.emit(puzzle_id)

func show_dialogue(pages: Array[Dictionary]) -> void:
	if modal_open or pages.is_empty():
		return
	clear_note()
	prompt_label.hide()
	modal_open = true
	modal_mode = ModalMode.DIALOGUE
	for control: Control in [view_panel, view_texture, view_caption, view_notice, view_footer, collection_panel]:
		control.hide()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.show()
	dialogue.start(pages)
	view_state_changed.emit(true)


func _on_puzzle_return_started() -> void:
	puzzle_returning = true
	view_state_changed.emit(true)

func is_puzzle_covering_world() -> bool:
	return is_puzzle_open() and not puzzle_returning

func is_puzzle_open() -> bool:
	return modal_mode == ModalMode.PUZZLE

func handle_modal_input(event: InputEvent) -> bool:
	if modal_mode == ModalMode.DIALOGUE:
		if not event.is_echo() and event.is_action_pressed("close_view"):
			close_view()
			return true
		return dialogue.handle_input(event)
	if is_puzzle_open():
		return active_puzzle.handle_input(event)
	if not event.is_echo() and event.is_action_pressed("close_view"):
		close_view()
		return true
	var mouse_close: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var key_close: bool = not event.is_echo() and (event.is_action_pressed("interact") or event.is_action_pressed("close_view"))
	if mouse_close or key_close:
		if modal_mode == ModalMode.COLLECTION:
			_advance_collection()
		else:
			close_view()
		return true
	return false

func close_view() -> void:
	if not modal_open:
		return
	var followup_pages: Array[Dictionary] = []
	followup_pages.assign(pending_puzzle_dialogue)
	pending_puzzle_dialogue.clear()
	var viewport := get_viewport()
	if viewport.gui_is_dragging() and viewport.has_method("gui_cancel_drag"):
		viewport.call("gui_cancel_drag")
	modal_open = false
	modal_mode = ModalMode.NONE
	puzzle_returning = false
	dialogue.stop()
	image_slides.clear()
	image_slide_index = 0
	image_slide_elapsed = 0.0
	collection_pages.clear()
	collection_page = 0
	collection_large_artwork = false
	view_texture.texture = null
	collection_preview.artwork = null
	collection_panel.hide()
	if is_instance_valid(active_puzzle):
		root_control.remove_child(active_puzzle)
		active_puzzle.queue_free()
		active_puzzle = null
	overlay.hide()
	if followup_pages.is_empty():
		view_state_changed.emit(false)
	else:
		# The CG has faded out; keep movement locked through the new dialogue.
		show_dialogue(followup_pages)
