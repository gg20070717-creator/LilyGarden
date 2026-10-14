extends "res://scripts/inspect_object.gd"
## Read the shelf book through the same interaction flow as other studio objects.
@export var story_pages: Array[Dictionary] = [
	{
		"text": "置物架上扣着一本《创世纪》。你将它翻开，正是第七章——洪水泛滥。",
	},
	{
		"speaker": "主角",
		"text": "——二月十七日那一天，大渊的泉源都裂开了，天上的窗户也敞开了。四十昼夜降大雨在地上……",
		"expression": &"speaking",
	},
	{
		"speaker": "主角",
		"text": "啊？！",
		"expression": &"teary",
		"shake": true,
	},
	{
		"text": "钻心的疼痛穿过头骨。你双手抱头，跪倒在地。",
		"expression": &"teary",
	},
	{
		"speaker": "Luna",
		"text": "别看你不该看的。",
		"expression": &"teary",
	},
]

func can_interact(context: Dictionary) -> bool:
	return super.can_interact(context) and not story_pages.is_empty()

func interact(context: Dictionary) -> void:
	if context["ui"].modal_open or not can_interact(context):
		return
	interacted.emit(context)
	context["ui"].show_dialogue(story_pages)
