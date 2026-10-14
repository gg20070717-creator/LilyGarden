# 美术资产规范

本规范仅适用于 `D:/godot/demo/demo2`（Lunar）。开发规则见 [AGENTS.md](../AGENTS.md)，模块职责见 [项目架构](architecture.md)，完成情况与待办见 [项目状态](project_status.md)，项目入口见 [README](../README.md)。本文维护美术来源、导入、显示和替换约定；当前配置以对应场景、脚本及资源文件为准。

## 目录与职责

所有游戏用资源必须位于 demo2 项目内，场景通过 `res://` 引用。资源文件使用英文小写及下划线，名称表达用途与身份；替换图片时保持路径和 ID 稳定。

| 路径 | 内容 |
| --- | --- |
| `assets/art/environments/<scene>/backgrounds/` | 场景地板、墙面、边框及背景层 |
| `assets/art/environments/<scene>/props/` | 对应场景的家具、门窗、照片框等物件图片 |
| `assets/art/environments/<scene>/decals/` | 后续增加的无碰撞地面贴花、污渍等 |
| `assets/art/shared/props/` | 多个场景实际共用的同一张物件图片，保持一份 |
| `assets/art/characters/<character>/` | 人物、朝向及动画图集 |
| `assets/art/ui/icons/`、`assets/art/ui/panels/` | 背包图标、按钮、界面边框 |
| `assets/art/ui/main_menu/`、`assets/art/ui/pause_menu/` | 主界面与暂停界面的配套素材 |
| `assets/fonts/` | 游戏文字字体文件与 Godot 导入设置 |
| `assets/art/cg/<act>/` | 剧情插画、全屏照片及分镜 |
| `assets/art/puzzles/<puzzle>/backgrounds/` | 独立解谜界面的整图背景或环境、物件分层图片；参考图单独归档 |
| `assets/art/puzzles/<puzzle>/effects/<effect>/` | 对应解谜的透明特效序列，帧号使用四位数字 |
| `resources/art/<scene>/` | AtlasTexture 区域、SpriteFrames 等引擎资源配置 |
| `scenes/props/` | 后续需要复用的物件场景，组合图片、碰撞和交互节点 |
| `assets/art/manifest.json` | 资产清单：稳定 ID、中文原名、项目路径、尺寸、区域及 SHA-256 |
| `LunarTitleFX/` | 已接入主菜单的标题组件、`assets/title.png` 与专用 shader，保留整套相对路径 |

以上是按需建立的目录约定。当前 bedroom、corridor、first_floor 已建立背景、物件及 AtlasTexture 资源目录；主角对白立绘、第一幕 CG、水井、鱼缸与洗笔桶解谜背景、菜单及字体也已接入。新增分类在收到对应素材时建立。

命名示例：`bedroom_bookshelf.png`、`player_walk_down.png`、`act_01_memory_01.png`。方向/动画/帧号按需要追加，如 `player_walk_down_01.png`。不使用空格、临时名称、中文运行时路径或 `最终版2` 之类的后缀。美术原文件可继续用中文名，交付清单保留中文对照。

PSD、Aseprite、设计稿及历史版本放在项目外的团队美术源文件目录，运行项目仅放需要的导出资源。Godot 自动生成的 `.godot/` 缓存不提交；PNG 对应的 `.import` 设置文件随项目保留。

未获得用户明确授权时，继续使用已有素材或已确认的占位，不生成、下载或重新设计美术，也不补写缺失剧情。资产接入时同步 manifest；美术说明更新在本文，功能状态更新在 `project_status.md`。

## 游戏字体

用户提供的 `ChillBitmap_16px.ttf` 原样保存为 `assets/fonts/chill_bitmap_16px.ttf`，中文字体名为“寒蝉点阵体 16px”。`ui_font.tres` 作为统一 FontVariation 引用项目内的 FontFile，覆盖键帽操作说明、字条、剧情对白与正文、获得提示、水井、鱼缸及洗笔桶解谜的提示与词卡，以及场景占位文字；菜单按钮及暂停标题使用图片字形，主菜单标题使用 `LunarTitleFX` 的图片与 shader。

字体不依赖系统安装，导入时关闭抗锯齿、子像素定位和系统字体回退，保留原字体数据。普通文字沿用纯黑文字与白色或浅色底衬，由 `scripts/ui_text_style.gd` 等现有 UI 配置管理。水井、鱼缸与洗笔桶启用 `moonlight_ui_enabled`，使用浅灰蓝文字、轻微深影与低强度青蓝柔光；其 `ui_backing_enabled = false`，保留透明键帽和薄弧光词槽。各类 UI 都继续引用 `ui_font.tres`，替换字体时保持路径并保留各自字号及样式。原文件名、项目路径及 SHA-256 记录在资产清单。

## 本次卧室资产

已原样复制用户提供的 10 张 PNG，透明通道与原始像素均保留。它们使用同一套 1360×870 画布，每张图包含不同位置的物件；通过 AtlasTexture 选择有效区域，避免透明留白影响缩放和摆放。

| 原文件 | 项目文件 | 接入位置 |
| --- | --- | --- |
| 地板墙面.png | `backgrounds/bedroom_floor_wall.png` | 分为地板和后墙两个区域 |
| 墙体.png | `backgrounds/bedroom_wall_border.png` | 分为上下左右边框，右侧保留门洞 |
| 书架.png | `props/bedroom_bookshelf.png` | 左侧书架 |
| 台灯.png | `props/bedroom_desk_lamp.png` | 桌面，无独立交互或碰撞 |
| 床.png | `props/bedroom_bed.png` | 右下床，图片自带枕头和地毯 |
| 桌子.png | `props/bedroom_desk.png` | 左下桌子 |
| 椅子.png | `props/bedroom_chair.png` | 桌子右侧椅子 |
| 照片.png | `props/bedroom_photo_frame.png` | 书架上的照片物件 |
| 窗户.png | `props/bedroom_window.png` | 上方窗户 |
| 门.png | `props/bedroom_door.png` | 右侧卧室门 |

表中项目文件均位于 `assets/art/environments/bedroom/`。照片.png 是场景中的照片框图，当前照片交互继续使用已确认的正文→获得提示流程。字条、探索中的行走人物和未提供对应素材的物件继续使用现有占位；对白主角使用下述四张立绘。

## 一楼与走廊资产

用户提供的 `客厅厨房(1).zip` 与 `走廊(1).zip` 共 13 张 PNG 原样保存，中文原名、画布、区域和 SHA-256 记录在 manifest。所有运行资源引用项目内路径，原 ZIP 与中文源文件留在项目外。

| 场景 | 原文件 | 项目文件 / 位置 |
| --- | --- | --- |
| 一楼 | 地板墙面.png | `backgrounds/first_floor_floor_wall.png`，大厅与厨房地板墙面；裁片复用到现有两间空房 |
| 一楼 | 墙体.png | `backgrounds/first_floor_wall_border.png`，外轮廓、墙返及房间边框 |
| 一楼 | 大门.png | `props/first_floor_courtyard_door.png`，玄关上方，保留院子入口 |
| 一楼 | 毯子.png | `decals/first_floor_shoe_mat.png`，大门下方鞋垫，无碰撞 |
| 一楼 | 凳子.png | `props/first_floor_stool.png`，鞋垫左侧，仅凳脚处有碰撞 |
| 走廊 | 墙壁地面.png | `backgrounds/corridor_floor_wall.png`，墙面和地板分别裁片铺设 |
| 走廊 | 墙体.png | `backgrounds/corridor_wall_border.png`，边框按楼梯口拆开 |
| 走廊 | 门1.png | `props/corridor_bedroom_door.png`，左侧卧室门 |
| 走廊 | 门2.png | `props/corridor_studio_door.png`，上墙画室门，保留钥匙判定 |
| 走廊 | 照片1.png | `props/corridor_photo_frame_left.png`，画室门右侧第一张 |
| 走廊 | 照片2.png | `props/corridor_photo_frame_middle.png`，中间竖框 |
| 走廊 | 照片记忆碎片.png | `props/corridor_memory_photo_frame.png`，右侧记忆照片，提供“涌泉”碎片，稳定 ID 为 `corridor_photo_02` |
| 走廊 | 花盆.png | `props/corridor_flower_pot.png`，右端楼梯上方，仅盆底有碰撞 |

表中 PNG 位于 `assets/art/environments/<scene>/`，AtlasTexture 位于 `resources/art/<scene>/`。图片无损导入、关闭 mipmaps，场景采用最近邻过滤。原图像素和透明通道保留；走廊照片和画室门存在低透明度散点，Atlas 只截取主体，避免无关透明区挤占显示尺寸。

一楼五层共用 4000×3000 画布，按 0.35 等比缩放并偏移 (35, 64)。大门中心约 (539.7, 140.125)，鞋垫约 (526.225, 248.625)，凳子在其左侧。原图左上、左下透明区域继续作为原有可进入空房，复用地板、墙面裁片，并在门口保留通道。外轮廓、厨房柜台和家具位置随地板底边调整；右上楼梯位于凹口，楼梯下端 y407，到达脚点 (1387.5, 467)。

走廊横坐标按 `x = 0.6 × 原图 x + 2.4` 排列，墙面保留 200 高，步行地面为 1360.8×168。家具图片等比显示，画室门按人物高度单独定为 180 高。记忆照片交互脚点 (574.5, 115)，画室门脚点 (379.5, 120)，楼梯上端 (1316, 240)，从一楼返回落在 (1316, 190)。凸出楼梯与上一轮上下端交互方向保留，缺少美术的楼梯、沙发、餐桌椅、厨房柜等继续白膜。

## 导入与摆放

- 像素场景素材使用最近邻过滤、无损压缩、关闭 mipmaps；卧室、走廊与一楼根节点已设置最近邻，其他场景维持各自配置。非像素菜单、主角立绘、解谜背景、CG 和水井涟漪使用各自显示节点的线性过滤，避免把像素场景的过滤方式全局套用到 UI。
- 家具等物件等比缩放。背景与墙体按场景区域铺设；不要把整张透明大画布作为物件尺寸。
- 现有约定为 100 世界单位约 1 米。人物、床、桌椅的大小基于同一尺度校准。尽量统一导出像素密度；同一方向物件采用一致的落地锚点。
- `whitebox.gd` 的 `artwork` 绑定纹理，`artwork_size` 与 `artwork_offset` 调整显示尺寸和偏移。零显示尺寸会自动等比适配 `size`；地板、边框可显式指定铺设尺寸。
- `size`、`solid`、碰撞体、活动边界和 F 交互锚点属于玩法配置，独立于图片。美术替换时保持玩法配置；需要验证时按下面的范围规则核查通行与交互可达性。台灯、地毯等装饰不增加碰撞。
- 已带在图片中的枕头、桌脚等旧占位绘制已关闭，避免叠加。绑定 artwork 后自动隐藏原白模占位文字；物件名作为内部配置保留。尚无素材的字条等对象继续显示占位文字，普通剧情文字保留黑字浅底样式。
- 场景中“按 F 交互”的浮动文字已移除，F 功能与物件光晕保留。`scripts/ui/controls_hint.gd` 在每次新载入游玩实例时，于左上角显示一次 WASD、F、Esc 键帽说明；任意键关闭并消耗该次按键，切换地点、暂停和继续游戏不重弹。解谜界面保留阶段性的 Enter/Esc 提示。

## 后续交付与替换

1. 导出透明 PNG，说明场景、物件身份、方向及是否为像素风；若使用大画布分层导出，保持所有层的画布尺寸和原点一致。
2. 按上表归类并命名，更新 manifest 的路径、尺寸与校验值。复用资源引用已有路径。
3. 若原图画布或有效区域改变，更新对应 AtlasTexture 的 region；保持场景中资源路径稳定。图片文件重命名或移动使用 Godot FileSystem 面板，随后核查引用。
4. 调整显示尺寸、偏移及必要的物件层级；碰撞只覆盖实体占地。后续角色素材用独立动画资源管理。
5. 常规开发不主动运行自动化测试、验证场景或试玩，手工测试由用户进行。仅在用户明确要求测试或正在修复 bug 时主动验证，并按改动范围检查显示、比例和对齐；涉及碰撞或交互时再检查对应物件的通行与 F 功能。交付说明需写明实际验证范围及未运行项目，不把历史截图或报告作为本次验证结果。
6. 交付时复制整个 demo2 项目，保留 `LunarTitleFX/`、项目内字体、资源和 `.import` 设置；临时目录中的原图无需一同复制。

## 水井选碎片界面

三张原图归档在 `assets/art/puzzles/well_memory/backgrounds/`：`well_memory_environment.png` 与 `well_memory_well.png` 在选碎片、文字浮现及填词阶段持续分层显示；`well_memory_composite.png` 保留作总图对照，不重复叠加。港湾→涌泉进入现有独立 CG 与对白流程，涌泉→港湾在原谜题背景上浮现微剧情。

`resources/well_memory_puzzle.tres` 绑定 `moon_environment`、`moon_well`；`moon_reference_size` 表示原始画布大小，`moon_well_rect` 表示水井图片位置。月相碎片的接收范围独立使用 `fragment_drop_rect = Rect2(600, 842, 750, 230)`，覆盖整件水井外接矩形，`fragment_drop_margin = 24` 为参考画布尺度的边缘容错，井身与井沿均可接收碎片。`moon_water_rect` 继续定义井口椭圆的水面效果及词语拖回取消区域。更换背景后分别维护图像、水面和碎片接收范围，无图片配置时保留白模界面。

图片层忽略鼠标输入，由 Water 节点接收拖放；其合法月相 GUI 范围扩展至独立碎片矩形，词语拖回仍使用原水面。当前 `ui_backing_enabled = false`，碎片外围白盘、词卡白底、句子白底与提示白底均已关闭，月相本体保留。`moonlight_ui_enabled = true` 提供浅灰蓝字迹、柔光、薄弧光槽及透明细线键帽；水中词字号 32、可用词字号 46，句子雾透明度为 0。词先浮出水面再飞回各自月相原位，句子与填词槽保留在水井上方，Esc、Enter 与句子分开放置。碎片接收范围扩展不会放大背景、涟漪、浮词或词槽。

## 鱼缸记忆界面

`客厅鱼缸.zip` 的三张原图归档在 `assets/art/puzzles/fish_tank/backgrounds/`：`客厅.png` 对应 `fish_tank_environment.png`，`鱼缸.png` 对应 `fish_tank_layer.png`，`总图.png` 对应 `fish_tank_composite_reference.png`。前两张分层显示，总图仅作合成参考；原始画布、像素和透明通道保留，来源与校验值记录在 manifest。

鱼缸共用 `scenes/puzzles/memory_puzzle.tscn`，独立配置位于 `resources/fish_tank_memory_puzzle.tres`。参考画布为 1920×1080；鱼缸显示矩形为 `(701, 339, 1060, 490)`，月相碎片以同一外接矩形作为 `fragment_drop_rect`，并配置 `fragment_drop_margin = 24` 的参考边缘容错。水面矩形为 `(737, 383, 863, 128)`，局部多边形为 `(1, 0)、(863, 2)、(863, 128)、(0, 124)`，继续管理水面效果与词语拖回取消。更换素材时分别核对整件鱼缸的碎片接收区域和可见水面区域。

| 配置 | 当前值 |
| --- | --- |
| A—E 月相中心 | `(200, 860)、(250, 570)、(410, 225)、(735, 185)、(1005, 200)` |
| 月相尺寸 | `160×160` |
| A—E 水中词中心 | `(855, 615)、(1005, 670)、(1160, 630)、(1320, 680)、(1480, 610)` |
| 句子矩形 | `(835, 405, 680, 84)` |
| 水中词 / 可用词字号 | `46 / 64` |
| 词牌尺寸 | `144×96` |
| 词槽线宽 / 空槽透明度 | `3.2 / 0.95` |
| 句子柔雾透明度 | `moonlight_sentence_mist_opacity = 0.21` |
| Enter / 反馈中心 | `(1210, 950) / (1180, 970)` |

鱼缸同样关闭白底并启用 moonlight UI，句子后方绘制低透明深蓝柔雾，保持亮水面上的可读性。`rise_on_drop = true` 使每次有效投入的对应词立即浮至水面并飞回其月相原位；进入填词阶段后沿用同一分层背景。A/B/C 词牌显示港湾/涌泉/潮汐，句型保持“选择了”；港湾→涌泉触发情节块 3 的代码 CG 占位，其余已配置组合浮现微剧情。原资源保留的 `play_success_story = false` 供兼容入口使用，当前鱼缸优先按组合路由处理。鱼缸未配置涟漪，布局、字号、柔雾与水面多边形继续在独立资源中调整。

## 洗笔桶记忆界面

用户提供的 `画室洗笔桶.png` 原样保存为 `assets/art/puzzles/brush_wash/backgrounds/brush_wash_environment.png`，1920×1080 整图已包含桶身、画笔和环境；`画室洗笔桶 记忆碎片示意.png` 单独保存为同目录的 `brush_wash_layout_reference.png`，用于月相布局对照，不在运行画面叠加。原像素、画布和透明通道保留，来源、路径与 SHA-256 记录在 manifest。

独立配置位于 `resources/brush_wash_memory_puzzle.tres`，复用共用记忆谜题。只配置 `moon_environment` 即可显示整图背景，`moon_well` 为可选叠加层；当前洗笔桶不重复叠加桶身图片。图片采用无损导入、线性过滤并关闭 mipmaps，控件沿 1920×1080 参考坐标适配。

| 配置 | 当前值 |
| --- | --- |
| A—E 月相中心 | `(442, 345)、(815, 172)、(1314, 148)、(1682, 364)、(1762, 710)` |
| 月相 token 尺寸 / 可见直径 | `350×350 / 约 266` |
| A—E 水中词中心 | `(960, 545)、(1050, 500)、(1160, 545)、(1080, 595)、(1260, 585)` |
| 碎片接收矩形 / 容错 | `(760, 310, 700, 770) / 24` |
| 水面矩形 | `(820, 415, 570, 385)` |
| 句子矩形 | `(800, 640, 680, 88)` |
| 水中词 / 可用词字号 | `46 / 64` |
| 词牌尺寸 | `144×96` |
| 句子柔雾透明度 | `moonlight_sentence_mist_opacity = 0.21` |
| Enter / 反馈中心 | `(1110, 980) / (1110, 970)` |
| 拖拽引导矩形 / 目标名 | `(48, 710, 460, 224) / 洗笔桶` |

水面局部 `water_drop_polygon` 为 `(23, 106)、(96, 61)、(291, 13)、(359, 0)、(416, 42)、(481, 120)、(552, 241)、(564, 272)、(544, 286)、(222, 375)、(168, 377)、(133, 348)、(61, 215)`，贴合桶内水面并用于词语拖回取消。月相投放使用覆盖整件洗笔桶的独立接收矩形与 24 像素边缘容错，水面显示、浮词和词槽各自保留配置。

洗笔桶关闭白底并使用月光 UI，`rise_on_drop = true`，每次有效投入立即浮词，0.9 秒后可继续投入。三句前置对白后进入选碎片，句型保持“之中有”，A/B/C 词牌显示港湾/涌泉/潮汐。未持有月相隐藏，D/E 名称及来源继续沿用预留。港湾→潮汐触发情节块 2 的完整黑底对白，现阶段复用通用对白框与字体，不显示角色立绘，CG 图片待提供；其余已配置组合浮现微剧情。对白读完返回画室原位置，微剧情读完回选碎片，不新增后续普通对白或涟漪。布局示意中的圆形作为摆放参考，运行时沿用共用月相绘制。实际排版、适配和投放体验待手工确认。

## 组合微剧情与 CG 占位

水井、洗笔桶、鱼缸分别对应阶段 1、2、3，完整有序组合见 [项目状态](project_status.md#组合剧情映射)。`scripts/puzzles/memory_echo.gd` 在既有谜题背景上绘制深蓝半透明淡雾，使用 `ui_font.tres` 的浅月光色正文、细光线和稀疏光点；正文轻微上浮并淡入，读完再淡出。微剧情不显示常规对白框或角色立绘，长段落及观测日志按正文换行。

情节块 1 继续使用已有天台 CG 原图与 AtlasTexture。情节块 2 已接入用户提供的完整对白，画面使用全屏黑底和既有对白框；`success_image` 保持未配置，各页不配置 `cg_image` 或主角立绘，无新增图片资产。情节块 3 继续由代码绘制月弧、细角框、“情节块 3 · CG 占位”与“画面待补充”。当前没有新增位图资产及 manifest 项；收到正式 CG 时再归档素材、记录来源与校验，并接入对应剧情。组合剧情数据位于 `memory_combination_stories.gd:BY_PUZZLE`，文字与稳定选项 ID 独立维护，不通过更换图片更改库存映射。

当前仅静态核对脚本、资源配置及引用，未运行试玩或测试；浮现对比度、长文本排版与窗口适配待用户手工确认。

## 首次碎片拖拽引导

水井、鱼缸与洗笔桶共享 `scripts/puzzles/memory_drag_hint.gd` 的代码绘制引导，无新增位图素材。浅灰蓝文字搭配透明深色薄边框，显示鼠标左键、月相与指向目标的箭头；两行文案为“按住左键，将记忆碎片”“拖到水井/鱼缸/洗笔桶上松开”，按当前目标显示名称。目标名由 `drag_hint_target_name` 配置，`drag_hint_rect` 使用绝对参考坐标：水井 `(32, 32, 460, 224)`，鱼缸 `(1290, 112, 460, 224)`，洗笔桶 `(48, 710, 460, 224)`。引导随窗口等比适配并限制在视口内，布局避开月相和目标主体。

引导不阻塞直接拖拽，首块成功投入后淡出；任意非 Esc 按键收起并消耗该次事件，Esc 沿用退出谜题功能。GameUI 的会话标记仅在有可拖碎片并实际进入选碎片阶段、引导呈现时更新；水井或洗笔桶前置剧情结束后才呈现。三处每局合计显示一次，重试与重新进入不重复，新游戏重置。调整图示和布局时保留这套显示时序，相关状态与信号职责见架构说明。本次未运行测试或试玩，图示与适配效果待手工确认。

## 水井涟漪动画

`水波纹(1).zip` 的 229 张透明 PNG 原样归档为 `assets/art/puzzles/well_memory/effects/ripple/ripple_0001.png` 至 `ripple_0229.png`，按数字顺序播放。原始 2500×2500 图片和透明通道保留；Godot 的 `.import` 设置将运行纹理尺寸限制为 512，采用线性过滤并关闭 mipmaps，避免加载原始大画布消耗过多显存。

`resources/art/well_memory/water_ripple_frames.tres` 统一管理帧序、60 FPS 和单次播放配置。当前播放时长约 3.82 秒，可在 SpriteFrames 中调整速度。`well_memory_puzzle.tres` 的 `water_ripple` 绑定动画；`ripple_source_uv` 根据整套序列的透明有效范围裁出显示区域，源文件像素不改动。

碎片有效投入水井接收矩形及其容错边缘后播放，连续投入会重新开始；无效拖放不触发。动画位于词语下方，仍通过 shader 限制在原井口椭圆内并降低亮度与不透明度，忽略鼠标输入。碎片接收范围扩大时涟漪显示范围保持原水面。Enter 可以直接进入还原，进入填词阶段、重置或关闭界面后清除动画。没有投入时水面保持静止，原有失败提示与解谜判定继续保留。

## 卧室照片与窗户 CG

用户提供的 `照片 2.png` 原样保存为 `assets/art/cg/act_01/bedroom_photo.png`，绑定卧室 `ShelfPhoto.artwork`。查看时在底部文字框上方等比显示大图，正文→获得“港湾”→关闭的两页流程及奖励去重保留。`show_collection` 的可选 `large_artwork` 参数开启大图布局，钥匙等物品继续沿用原有小图或占位显示。

五张窗户 CG 原样归档在 `assets/art/cg/act_01/window_moon/`，按月亮亮部从少到多排列；两组左右朝向素材均保留：

| 播放顺序 | 原文件 | 项目文件 |
| --- | --- | --- |
| 1 | 未命名作品 5.png | `window_moon_01_crescent_left.png` |
| 2 | 未命名作品 8.png | `window_moon_02_crescent_right.png` |
| 3 | 未命名作品 1 2.png | `window_moon_03_wide_left.png` |
| 4 | 未命名作品 7.png | `window_moon_04_wide_right.png` |
| 5 | 未命名作品 6.png | `window_moon_05_full.png` |

`WindowCG.artworks` 配置播放顺序，`slide_duration` 配置每张停留时间，目前为 2 秒。靠近窗户按 F 全屏等比播放，完整播放后返回卧室；左键、F 或 Esc 可提前退出，重新查看从第一张开始。CG 不增加占位文字，播放期间暂停人物移动，退出后保留原位置。图片顺序和时长均通过场景配置调整，`show_slideshow` 可供后续其他 CG 使用。

## 主角立绘与水井 CG

四张主角原图原样保存到 `assets/art/characters/protagonist/`，原画布均为 1100×1900。中文原名及 SHA-256 记录在 manifest。

| 原文件 | 项目文件 | 表情 ID |
| --- | --- | --- |
| 立绘 (1).png | `protagonist_neutral.png` | `neutral` |
| 拆分1 (1).png | `protagonist_speaking.png` | `speaking` |
| 拆分2 (1).png | `protagonist_smile.png` | `smile` |
| 拆分3 (1).png | `protagonist_teary.png` | `teary` |

`scripts/ui/story_dialogue.gd` 为四张图分别创建 AtlasTexture，统一 `region = Rect2(180, 70, 715, 1800)`，源图片不裁切或改写。1920×1080 参考画布中，显示位置为 `(1285, 105)`，容器为 `555×1397`，使用等比居中和线性过滤，随对白整体等比适配窗口。表情由对白页配置，主角在本段首次出现后持续保留，结束时与对白框一起隐藏；开场 Luna 画外音及纯 CG 不额外显示立绘。

水井成功 CG 的原图 `CG1.png` 保存为 `assets/art/cg/act_01/cg_01_rooftop.png`。三个裁片由 `resources/art/cg/act_01/cg_01_rooftop_01.tres` 至 `cg_01_rooftop_03.tres` 管理，区域依次为 `(72, 89, 1260, 811)`、`(72, 954, 1260, 1422)`、`(1382, 91, 2051, 2290)`。剧情按原照片布局逐步叠加左上、左下及右侧画面，已出现的画面保留；源图、分隔线与白边通过 Atlas 显示区域处理，替换时同步资源及 manifest。剧情时序由 `scripts/puzzles/well_memory_story.gd` 和解谜组件管理。

## 主界面菜单资产

用户提供的原主界面素材共 8 张 PNG，原始像素和透明通道原样保留，统一归档在 `assets/art/ui/main_menu/`。中文原名、尺寸和 SHA-256 记录在 `assets/art/manifest.json`。背景与六个按钮继续使用该目录图片，按钮的白色文字沿用原图。旧 `main_menu_title.png` 作为已接收素材归档保留。

`scenes/ui/main_menu.tscn` 已接入 `LunarTitleFX/lunar_title.tscn`，当前标题纹理为 `LunarTitleFX/assets/title.png`，`lunar_title.gd` 与 `lunar_title.gdshader` 控制鼠标透视倾斜及周期扫光。标题位置仍为 `(490, 187)`、容器 `920×440`，shader 参数由标题脚本导出项管理。替换当前标题时更新这套组件内的纹理与参数，保持 `res://LunarTitleFX/` 路径完整。

主菜单按 1920×1080 参考画布布置。下表保留原始 8 张素材的来源与摆放数据，其中旧标题一行用于归档对照。坐标为整张 PNG 的左上角，尺寸包含透明留白；运行图层共同等比缩放并居中，保持相对位置。背景与标题忽略鼠标输入，按钮的 300×60 区域接收点击。

| 原文件 | 项目文件 | 参考坐标（x, y） | 显示尺寸 |
| --- | --- | --- | --- |
| 背景.png | `main_menu_background.png` | 0, 0 | 1920×1080 |
| 标题.png | `main_menu_title.png` | 490, 187 | 920×440 |
| 新游戏.png | `main_menu_new_game.png` | 810, 564 | 300×60 |
| 继续游戏.png | `main_menu_continue.png` | 810, 639 | 300×60 |
| 设置.png | `main_menu_settings.png` | 810, 715 | 300×60 |
| 载入游戏.png | `main_menu_load_game.png` | 810, 788 | 300×60 |
| 退出.png | `main_menu_quit.png` | 810, 863 | 300×60 |
| 制作人员名单.png | `main_menu_credits.png` | 809, 938 | 300×60 |

菜单图片采用线性过滤、无损导入并关闭 mipmaps。替换背景和按钮时保持上述文件路径、画布和坐标关系；当前标题按 `LunarTitleFX` 的配置替换，参考合成图与原始 ZIP 保留在项目外。

## 暂停界面资产

用户提供的暂停素材共 4 张 PNG，原始像素和透明通道原样保留，归档在 `assets/art/ui/pause_menu/`。中文原名、尺寸及 SHA-256 记录在 `assets/art/manifest.json`。按钮文字直接使用原图。

`scenes/ui/pause_menu.tscn` 按 1920×1080 参考画布布置。下表坐标为整张 PNG 的左上角，按钮点击区域为 390×80；素材共同等比缩放并居中。

| 原文件 | 项目文件 | 参考坐标（x, y） | 显示尺寸 |
| --- | --- | --- | --- |
| 暂停+透明背景.png | `pause_menu_overlay.png` | 0, 0 | 1920×1080 |
| 继续游戏.png | `pause_menu_resume.png` | 765, 437 | 390×80 |
| 主菜单.png | `pause_menu_main_menu.png` | 765, 527 | 390×80 |
| 退出游戏.png | `pause_menu_quit.png` | 765, 612 | 390×80 |

运行时保留并冻结当前游戏画面，通过 `shaders/pause_gaussian_blur.gdshader` 分别执行水平、垂直两遍高斯模糊，两遍之间使用全视口 `BackBufferCopy`。随后用 `Overlay` ColorRect 绘制与原底板一致的 RGBA（26, 46, 101, 142）半透明遮罩，再叠加标题和按钮；按钮保持清晰。

暂停标题通过 AtlasTexture 从 `pause_menu_overlay.png` 的 `(896, 352, 128, 64)` 区域取字形，独立放在参考位置 `(880, 284)`、尺寸 `160×80`，保留相对原始字形上移和放大后的布局。`shaders/pause_title.gdshader` 提取字形为白字透明底，消除原蓝底的叠加；更新标题时同时保留 Atlas 区域与该材质的关系。

暂停图片采用线性过滤、无损导入并关闭 mipmaps。更换素材时保留文件路径、画布、透明通道及坐标关系；原始 ZIP 留在项目外。图片、收集弹窗和水井解谜的 Esc 退出由原界面优先处理，暂停界面仅在一级游戏界面打开。

## 菜单悬停与按压

主菜单和暂停菜单共用用户提供的悬停 PNG，原图保存为 `assets/art/ui/panels/menu_hover_background.png`，原始像素与透明通道保持不变。`resources/art/ui/menu_hover_background.tres` 选取主体与柔光区域（176, 96, 1823, 514），隐藏透明画布留白。图片采用无损导入、线性过滤并关闭 mipmaps。

9 个现有 TextureButton 共用 `scripts/ui/menu_hover_button.gd`。背景在原文字下方绘制，主菜单显示 450×80、暂停菜单显示 585×106.67，居中于原按钮；文字、背景、标题、按钮坐标与点击区域沿用现有配置。悬停背景在 0.18 秒内淡入并轻微展开，移开在 0.14 秒内淡出。素材自身的半透明颜色原样保留。

按下时仅视觉层在 0.08 秒内缩至 97% 并下移 4 个参考像素，松开后 0.16 秒回弹。特效与文字子层均忽略鼠标输入。禁用的“继续游戏”沿用原外观与不可点击规则；切页、隐藏菜单、窗口移出时清理动画，返回与调整窗口尺寸后同步悬停位置。
