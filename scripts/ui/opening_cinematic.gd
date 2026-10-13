extends CanvasLayer
signal finished
const StoryDialogue = preload("res://scripts/ui/story_dialogue.gd")
const PAGES: Array[Dictionary] = [
	{"text": "世界在你眼中缓慢旋转。"},
	{"text": "她的身影晕开，扭曲，逐渐消散。"},
	{"text": "你心中涌现一种强烈的冲动，想触碰她飘动的裙角，想擦去她脸庞滚落的泪水。"},
	{"text": "可是潮水骤然涌入，你被卷进水流，推向与她相反的方向。"},
	{"text": "你坠入水中，眼前的光亮离你越来越远。"},
	{"text": "你拼命地想去抓住什么，她的体温，她身上洗衣粉的香气——然而你的手心只有虚无。"},
	{"text": "一个声音在你耳边响起，明亮而坚定。"},
	{"speaker": "Luna", "text": "醒过来。", "shake": true},
	{"speaker": "你", "text": "这是哪里？", "expression": &"speaking"},
	{"speaker": "你", "text": "发生什么了？", "expression": &"speaking"},
	{"text": "你仔细检索自己的大脑，尝试回忆过去发生的任何事。一片空白。", "show_protagonist": true, "expression": &"neutral"},
]
var dialogue: StoryDialogue
var black: ColorRect
var _shake_remaining := 0.0
var _shake_elapsed := 0.0
var _reveal_tween: Tween

func _ready() -> void:
	layer = 50
	black = ColorRect.new()
	black.name = "BlackScreen"
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	dialogue = StoryDialogue.new()
	dialogue.name = "Dialogue"
	add_child(dialogue)
	dialogue.finished.connect(_on_finished)
	dialogue.page_changed.connect(_on_page_changed)
	hide()

func prepare() -> void:
	dialogue.stop()
	_shake_remaining = 0.0
	show()

func start() -> void:
	dialogue.modulate.a = 0.0
	dialogue.start(PAGES)
	_reveal_tween = create_tween()
	_reveal_tween.tween_property(dialogue, "modulate:a", 1.0, 0.45)

func handle_input(event: InputEvent) -> bool:
	return dialogue.handle_input(event)

func _on_page_changed(index: int) -> void:
	if bool(PAGES[index].get("shake", false)):
		_shake_remaining = 0.55
		_shake_elapsed = 0.0

func _process(delta: float) -> void:
	if _shake_remaining <= 0.0:
		return
	_shake_elapsed += delta
	_shake_remaining = maxf(0.0, _shake_remaining - delta)
	var strength := 16.0 * _shake_remaining / 0.55
	dialogue.set_shake_offset(Vector2(sin(_shake_elapsed * 91.0), cos(_shake_elapsed * 113.0)) * strength)
	if _shake_remaining == 0.0:
		dialogue.set_shake_offset(Vector2.ZERO)

func _on_finished() -> void:
	finished.emit()

func stop() -> void:
	_shake_remaining = 0.0
	if is_instance_valid(_reveal_tween):
		_reveal_tween.kill()
	dialogue.stop()
	hide()
