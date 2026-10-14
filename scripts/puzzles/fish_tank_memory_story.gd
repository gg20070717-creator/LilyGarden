extends RefCounted
## Act Three memory: black-screen dialogue while CG imagery is pending.
const NARRATIVE_PAGES: Array[Dictionary] = [
	{
		"speaker": "你",
		"text": "我回来了！",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你刚进门就被手里沉甸甸的袋子绊了一下——袋子里装着冰好的啤酒可乐还有炸鸡薯片。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你的脚步一下踉跄，控制不住重心，整个人向着前方倾倒过去。",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "呀！",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你被沾着颜料的柔软双手接住，鼻尖嗅到熟悉的洗衣粉香气。抬头，小泠笑着看你。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你一整年埋在书山题海里的日夜苦读没有白费，最终拿到了首都大学物理系的录取通知书，",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "而小泠也放弃了老家本地的艺术院校机会，随着你一起来到了繁华的首都。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "2089年，你硕士毕业之后，你听从父母的安排，进入弦音科技公司的总部研究所，负责引力波引擎的研发工作。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "弦音科技的核心业务围绕引力波引擎展开，但老员工都清楚，公司董事长早年是做脑机接口出身，",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "后来被媒体曝出开展非人道生物实验，这才推动公司整体转型，投入更加政治正确的环保引擎开发。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "公司内部一直流传着地下室藏着恐怖实验之类的小道传闻，但你对此毫不在意，反正你的工牌刷不开那层。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "显然，你并不相信弦音科技“改变能源结构，解决全球变暖”的那一套，",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "但他们支付给研究员的薪水足够让你闭嘴干活——你在首都不错的街区买了套小独栋后，",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "余下的存款也足够支撑你和小泠两人的生活。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "至于小泠，她接稿就是有一单没一单的。搞艺术的嘛。",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "（捡起散落的东西）今天怎么回来这么早？",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "实验进行得很顺利，采集到的所有实验数据都很漂亮，完全符合我们之前的预期。",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "老板很满意，提前放我们走，不用留在所做收尾整理了。（看向厨房）哇塞，你还点了披萨？！",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你笑嘻嘻地跑到擦桌边，准备用脏手抓起披萨往嘴里塞。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "忽然，眼前的景象变了。天花板滴下水，一地，两滴，餐桌上是泛着酸臭的罐头和发霉的压缩饼干。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "积水漫过你脚踝，几张被水浸湿的稿纸向你飘来。你知道，如果按照纸上的算式推导，必然得出那个结果——",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "小泠在你手上轻拍一下，把你拉回现实。",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "喂，先去洗手。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "她察觉到你神情异样。",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "小汐，你怎么了？",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "没什么。我做实验做出幻觉了。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你乖乖去洗手后在餐桌旁坐定。这是你一天中最幸福的时刻——逃离你算不上热爱的工作，和她在餐桌前享用食物。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "杯中的淡色艾尔啤酒冒着细密的气泡，微醺的酒意逐渐朦胧了你的视野，桌上暖黄色的灯光漫溢开来，",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "在她清亮的眼底慢慢晕开。这样的瞬间会让你觉得，选择物理研究这条路是正确的。",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "......所以你能给我带月壤吗？",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "小泠对你们公司那个月球计划比你热衷得多。她对自己脱产画画这件事有些敏感，",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "于是主动和你聊起工作上的话题，好让自己看起来没那么脱离社会。",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你心里清楚，首都从没给过她安全感，是故乡小城的明月始终让她魂牵梦萦。",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "说什么傻话呢，我又不是阿姆斯特朗。这次实验风险很高，监管部门怎么都不同意我们在地球上开展实机测试。",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "所以引力波引擎会先由运载火箭送上月球，再由地面站的工程师远程操作——如果所有环节顺利，",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "只要在控制中心按下启动按钮，整艘试验飞船就会“咻”的一下，通过引力折叠通道直接闪回地球的发射基地——",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "你喋喋不休，夸张地比着手势，没有注意到小泠脸上一闪而过的尴尬。",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "好了好了。对了，《铃兰女校弓道部》出新剧场版了，下周末一起去看吧？",
		"show_protagonist": false
	},
	{
		"speaker": "你",
		"text": "下周末？唉火箭马上就要发射了，哪里有时间......",
		"show_protagonist": false
	},
	{
		"speaker": "",
		"text": "小泠叹一口气。",
		"show_protagonist": false
	},
	{
		"speaker": "小泠",
		"text": "随便吧。就当我没说过。",
		"show_protagonist": false
	}
]
