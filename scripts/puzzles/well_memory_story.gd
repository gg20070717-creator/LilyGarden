extends RefCounted

# 首次集齐两块记忆碎片后进入水井时播放。
const INTRO_PAGES: Array[Dictionary] = [
	{
		"speaker": "",
		"text": "又是那个声音，从你脑海中的某个角落传来。",
		"show_protagonist": false,
	},
	{
		"speaker": "Luna",
		"text": "嗨，小汐。你还记得你叫小汐吧？",
		"show_protagonist": false,
	},
	{
		"speaker": "你",
		"text": "嗨。你不打算解释一下，为什么你能就这样在我脑子里说话吗？",
		"expression": "speaking",
		"show_protagonist": true,
	},
	{
		"speaker": "",
		"text": "她干笑了两声。",
		"show_protagonist": false,
	},
	{
		"speaker": "Luna",
		"text": "小汐，我要解释的有很多很多。你什么也不记得了。在你想起发生在我们身上的事情之前，有些事......我无从说起。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "她听上在强颜欢笑。你听出了她语气中掩藏的悲伤，不知为何，这让你的心绞作一团。",
		"show_protagonist": false,
	},
	{
		"speaker": "Luna",
		"text": "书架和走廊上的照片，让你记起了什么对吗？试试把它们组合起来吧。",
		"show_protagonist": false,
	},
]

# 水井解密成功后播放 CG1；读完后直接淡出回原游戏界面。
const NARRATIVE_PAGES: Array[Dictionary] = [
	{
		"speaker": "",
		"text": "2080年的夏天，天气预报每天显示红色高温，人人都谈论厄尔尼诺，温室气体，海平面上升，好像这样就能免除自己对气候变暖应负的责任。",
		"cg_image": "res://resources/art/cg/act_01/cg_01_rooftop_01.tres",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "正值午休时间，气温是可怕的三十八度。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "你们刚去礼堂听完弦音科技代表的宣讲——你对他嘴里的口中的什么引力波没有半点兴趣，但即便如此，听讲座也比上自习好玩得多。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "教室里的凝滞的空气让你喘不过气，窗外传来的阵阵蝉鸣吵得你心烦意乱。当然，手中那张60分的英语试卷才是你心烦意乱的主要原因。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "你假装去问问题，偷偷从教室后门溜走。你轻车熟路地上楼，绕开班主任办公室，停在通往天台的防盗门之前。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "你从校服兜里掏出发卡，捅进锁孔摆弄一番。咔，轻轻松松。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "然而你的秘密基地被人捷足先登了。炫目的阳光下，那个女孩的瞳孔被照映成琥珀色。她靠在栏杆上，拿着炭笔写写画画。",
		"cg_image": "res://resources/art/cg/act_01/cg_01_rooftop_02.tres",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "你偷偷绕到她身后，然后大叫一声。",
		"show_protagonist": false,
	},
	{
		"speaker": "小泠",
		"text": "呀？！",
		"show_protagonist": false,
	},
	{
		"speaker": "你",
		"text": "你也看《铃兰女校弓道部》？！",
		"expression": "speaking",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "她眼中的错愕立马变成了激动。她的画本上画满了《铃兰女校弓道部》的角色。",
		"cg_image": "res://resources/art/cg/act_01/cg_01_rooftop_03.tres",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "拜少女运动番所赐，你们顺理成章地成为了朋友，又顺理成章地形影不离，直到某个一同走回家的晚上，你们指尖相触，你牵起了她的手。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "往后你会无数次会想起那个夏天，你和她从主机游戏聊到尼采黑格尔，在草稿本甚至教科书上画你们喜欢的漫画角色，为只有你们才懂的笑话大笑到流泪。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "每个周五你送她回家，又在周末偷偷溜到她家后院，把你的画折成纸飞机扔进她的窗户。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "你不明白你是否真的喜欢画画，或只是因为她而喜欢画画。",
		"show_protagonist": false,
	},
	{
		"speaker": "",
		"text": "你只是知道，每当你拿起画笔，60分的英语成绩不再重要，老师和家长的期待不再重要，虚无缥缈的成功未来不再重要。",
		"show_protagonist": false,
	},
]
