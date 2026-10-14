extends RefCounted

# Visible fragment words use stable choice IDs: A = 港湾, B = 涌泉, C = 潮汐.
# Existing water-well CG data and its follow-up remain in well_memory_story.gd.
const BY_PUZZLE: Dictionary = {
	&"well_memory": [
		{
			"left": &"A",
			"right": &"B",
			"id": "cg_01",
			"kind": &"cg_existing",
		},
		{
			"left": &"B",
			"right": &"A",
			"id": "1_3_1",
			"kind": &"micro",
			"text": "你回想起两颊的湿润，以为那是眼泪的触感。后来才知道，有些温柔的地方，也藏着不安分的水源",
		},
	],
	&"brush_wash_memory": [
		{
			"left": &"A",
			"right": &"C",
			"id": "cg_02",
			"kind": &"cg_placeholder",
			"title": "情节块 2 · CG 占位",
			"text": "画面待补充",
		},
		{
			"left": &"C",
			"right": &"A",
			"id": "1_4_1",
			"kind": &"micro",
			"text": "浪涛中也许也有能停脚的地方。你抓着那块起伏的安稳，很久以后才想起来问——这是港湾，还是只是浪比较慢的地方？",
		},
		{
			"left": &"B",
			"right": &"C",
			"id": "1_3_4",
			"kind": &"micro",
			"text": "你回想起一潭开始按时涨落的井水，它以为自己在涌动，其实只是跟着潮起。什么时候开始，连心跳都要听从外面的时表？",
		},
		{
			"left": &"C",
			"right": &"B",
			"id": "1_4_3",
			"kind": &"micro",
			"text": "你有一种奇妙的感觉——浩大的水势里，钻出一小股温热。是浪，不是回涌，却从底下涌上来。它能否冲开潮汐，抑或被巨力卷走？",
		},
	],
	&"fish_tank_memory": [
		{
			"left": &"A",
			"right": &"B",
			"id": "cg_03",
			"kind": &"cg_placeholder",
			"title": "情节块 3 · CG 占位",
			"text": "画面待补充",
		},
		{
			"left": &"A",
			"right": &"C",
			"id": "2_1_4",
			"kind": &"micro",
			"text": "（观测日志编号 1011）\n【第 47 号锚点】潮差：0.00m　连续无波动：72h+\n结论：内生泉与“潮汐”无共振。\n页边铅笔备注：“再向下 300 dp。”",
		},
		{
			"left": &"B",
			"right": &"A",
			"id": "2_3_1",
			"kind": &"micro",
			"text": "你看见一道狭窄的螺旋阶梯\n没有岸，没有底，没有回头的余地，连前进的方向也未知。\n只能往上。再往上。",
		},
		{
			"left": &"B",
			"right": &"C",
			"id": "2_3_4",
			"kind": &"micro",
			"text": "（手册划线句）\n内生泉，不受月相牵引。——手册上如是写道。",
		},
		{
			"left": &"C",
			"right": &"A",
			"id": "2_4_1",
			"kind": &"micro",
			"text": "她沿着防波堤走了一整夜，说要找一个浪听不见的地方。天亮的时候她回来了，鞋子是干的。",
		},
		{
			"left": &"C",
			"right": &"B",
			"id": "2_4_3",
			"kind": &"micro",
			"text": "水面很平静，没有一丝波澜",
		},
	],
}
