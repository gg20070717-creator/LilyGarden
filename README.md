# Lunar

Godot 4.7.2 / GDScript / 2D。项目显示名与程序集名为 Lunar，本地工作目录为 `D:/godot/demo/demo2`。打开本目录的 project.godot，按 F5 运行项目。默认 1920×1080，WASD 移动，靠近交互目标后按 F。

## 主界面菜单

每次新载入游玩场景时，左上角淡入一次键帽式操作说明：W 在上、A/S/D 在下，F 交互，Esc 暂停。按任意键关闭，此次按键仅关闭说明；之后切换地点、暂停或继续游戏均不重弹。场景中的“按F交互”浮动文字已移除，交互范围、高亮与 F 功能保留；解谜 Enter 确认提示继续显示。

F5 的项目入口为 `scenes/ui/main_menu.tscn`，菜单逻辑位于 `scripts/ui/main_menu.gd`。每次点击“新游戏”依次播放开场演出、两句主角对白和回忆旁白，剧情全部结束后淡入卧室并开始探索，同时重建角色、地点与收集状态。

游戏一级界面按 Esc 打开暂停界面，当前游戏画面保留并采用高斯模糊，人物移动与交互暂停。暂停界面按 Esc 或点击“继续游戏”恢复；点击“主菜单”保留当前位置与进度并返回主菜单，之后可点击主菜单的“继续游戏”恢复。图片、收集弹窗、水井解谜等二级界面沿用 Esc 返回功能，同一次 Esc 仅关闭当前二级界面。

主菜单和暂停菜单的按钮使用用户提供的半透明背景：鼠标悬停时平滑展开、淡入，移开时淡出；按下时轻微缩小并下沉，松开后回弹。原图片文字、配色、布局和点击范围保持不变，视觉效果统一由 `scripts/ui/menu_hover_button.gd` 管理。

主菜单的“继续游戏”恢复本次运行中的位置与进度，没有游戏实例时不可点击。游戏进度在本次运行内保存，关闭或重新运行项目后重置。每次新游戏都从开场演出开始，“继续游戏”直接恢复当前进度。

“载入游戏”“设置”“制作人员名单”目前进入预留空白页，按 Esc 返回主菜单；“退出”关闭游戏。

后续页面与存档系统可连接以下接口：

- `page_requested(page_id: StringName)`：打开空白页时发出，页面 ID 为 `load_game`、`settings` 或 `credits`。
- `load_slot_requested(slot_id: StringName)`：后续载入槽位的请求信号；本轮不读写存档。
- `request_load_slot(slot_id: StringName)`：供后续槽位界面调用，发出 `load_slot_requested`。
- `return_to_menu()`：暂停保留的游戏实例并显示主菜单。
- `pause_game()`：在一级游戏界面冻结游戏实例，保留画面并打开 `scenes/ui/pause_menu.tscn`。

## 开场演出与人物对白

开场由 `scripts/ui/opening_cinematic.gd` 管理，演出完整原文分为八页：静默黑屏→旁白→Luna“醒过来。”，接着播放三页主角对白与回忆旁白。左键、Enter、空格或 F 推进；文字出现过程中点击补全，再次点击进入下一页。最后一页保持黑底、短暂震动；Luna 使用画外音，画面不显示立绘。按用户要求，开场无环境音。

“新游戏→开场演出→主角对白与回忆旁白→游玩”使用黑色遮罩淡入淡出。整段剧情结束前阻止角色操作和重复开局，结束后才创建游玩场景并淡入卧室。旧的开场完成记录不再用于跳过新游戏剧情。

`scripts/ui/story_dialogue.gd` 为复用组件。通过 `game_ui.gd:show_dialogue(pages)` 打开普通对白，冻结移动，左键/Enter/空格/F 推进，Esc 关闭。speaker 为“主角”“你”或“protagonist”时显示右侧主角；主角立绘在本段首次出现后持续保留，后续旁白和 Luna 台词也不会隐藏；其他角色或旁白时使用中性表情，整段对白结束后随对白框一起退出。尚未出现主角的段落和纯 CG 不额外显示立绘。表情：`neutral` 中性、`speaking` 说话口型、`smile` 微笑、`teary` 落泪。每次新游戏在开场演出之后、淡入卧室之前，依次显示“你：这是哪里？”、“你：发生什么了？”及回忆旁白。两句主角台词显示右侧说话立绘，旁白保留中性立绘；最后一页结束后隐藏对话框与立绘，淡入卧室并开始探索。界面不显示幕标题，继续游戏保留当前进度。

```gdscript
var pages: Array[Dictionary] = [
    {"speaker": "主角", "text": "主角的台词", "expression": &"speaking"},
    {"speaker": "Luna", "text": "Luna 的台词"},
]
context["ui"].show_dialogue(pages)
```

四张原图原样保存到 `assets/art/characters/protagonist/`：立绘→`protagonist_neutral.png`，拆分1→`protagonist_speaking.png`，拆分2→`protagonist_smile.png`，拆分3→`protagonist_teary.png`。通过 AtlasTexture 统一显示区域，未修改源图片。对白框和立绘按 1920×1080 参考画布等比适配窗口。

## 本轮内容

- 卧室：窗户展示空白 CG；字条在桌子上方单行显示“来水井边见我”，4 秒后消失；书架照片打开底部正文“照片上的女人背对月光，面目模糊不清”，立即获得碎片1“港湾”。
- 二楼走廊：已接入墙面地板、边框、卧室侧门、画室门、三幅照片框和花盆，按素材原始画布关系排列；对应调整走廊宽度、碰撞和交互位置。下楼楼梯从走廊下边缘凸出，在楼梯上端可按 F 交互，左侧不触发；上楼返回时落在该上端平台。右侧记忆照片框按 F 在当前场景上弹出实验室剧情正文，立即获得碎片2“镜面”。
- 画室：按参考图补齐画架、凳子、调色板桌、洗笔桶、置物架、窗、散落画框及后墙挂画、报纸与照片白模。独立 studio.tscn，门上锁。按 F 显示“已上锁”。持有钥匙 studio_key_01 后显示“已解锁”并进入；室内有返回走廊的门。钥匙来自院子水井左侧的灌木丛，使用后保留。
- 一楼：按参考图设置玄关、客厅、餐桌、小帐篷、厨房柜台和两个空房。空房直接走入，无需 F。已接入地板墙面、边框、玄关大门、鞋垫与小凳子，统一按原始画布布局；其他家具继续使用有碰撞的白模，地毯、鞋垫可踩踏；大门和楼梯继续按 F 切换场景。上楼在楼梯下端可按 F 交互，左侧不触发；下楼返回时落在该下端。
- 一楼玄关与客厅：鞋柜、挂画、绿色地毯、鱼缸及四处水渍可直接左键点击查看正文，也兼容靠近按 F。文字按交互表原文显示，左键/F/Esc 关闭，查看期间暂停移动，不发放或消耗道具。鱼缸当前统一显示“水里没有鱼。水面毫无波澜。”，暂不开放第二幕解谜。四处水渍位于左上空房、左侧通道、客厅右侧、帐篷右侧，均可踩踏。仅修改这些物件；原楼梯、门、其他家具及房间通行保留。
- 本次地图补齐：二楼走廊新增墙面水渍及落地水洼；一楼下方房间新增书柜与窗，餐桌新增杯盘、打开的杂志，料理台右端新增废纸篓；小院新增左侧弯路、后方栏杆、右侧树木与落叶、底部灌木和稀疏杂草。卧室及所有已有物件、场景边界、门、出生点与交互保留。新增小院装饰不阻挡通行。
- 院子：没有对应碎片时，水井上方显示“水面很平静，毫无波澜”；拥有任意一块对应碎片可进入独立解谜界面。
- 两张照片采用正文→获得提示→关闭的分步弹窗，左键任意位置或 F 前进，Esc 随时关闭。打开正文时立即获得碎片；提前退出保留奖励，重复查看仍有两页，奖励去重。当前场景变暗，底部白色框宽94%、高25%、距底部3%；正文页仅显示正文，获得页另有“左键点击屏幕任意位置退出”。弹窗和解谜暂停移动，关闭恢复原位置。
- 灌木丛按 F 立即获得钥匙1（studio_key_01），显示代码绘制的钥匙占位图形和“画室钥匙”。左键、F 或 Esc 关闭，重复查看不重复发放钥匙。
- 所有操作提示和弹出正文为 36 像素，照片碎片提示为 40 像素，字体为纯黑色，采用白色或浅色底衬。未接入美术的物件保留占位名称，已接入素材的物件自动隐藏占位文字；不显示常驻说明、占位描述或计数 HUD。

人物高度 150，脚下碰撞直径 39，移动速度 300。沿用 100 世界单位约 1 米的尺度。镜头默认显示约 1024×576 世界单位，完整容纳卧室，卧室内镜头保持固定；较大地图中跟随人物身体中心。出生和切换地点时立即定位，到地图边缘时限制镜头，小于视野的轴居中显示。镜头显示范围独立于地图和家具，窗口大小变化时等比调整显示。可在 main.tscn 根节点的 camera_view_size 调整视野。卧室已接入用户提供的 10 张美术素材，走廊和一楼另接入 13 张素材；缺少对应美术的物件与人物继续使用占位；月相由圆弧和椭圆弧绘制。状态在本次运行内跨场景保留，重新运行重置；没有存档、背包或音效系统。

按现有尺度换算实际地面（不计背墙立面）：卧室约 6.45×3.55 米，走廊约 13.61×1.68 米（另含向下凸出的楼梯），一楼地面外轮廓最大约 14×8.47 米。各地点共用同一镜头缩放；卧室完整显示，走廊和一楼随人物分区显示。

场景原图位于 assets/art/environments/ 下的 bedroom、corridor、first_floor 目录，AtlasTexture 区域资源位于 resources/art/ 下的对应目录。图片显示与原有碰撞/F 交互分开；绑定美术后自动隐藏白模占位文字，未提供素材的字条等对象保留文字。新增桌面台灯仅为装饰。完整目录、命名、导入和替换约定见 [美术资产规范](docs/art_assets.md)，资产原名及校验清单见 assets/art/manifest.json。

## 解谜与碎片配置

同一局中首次同时持有卧室碎片 `bedroom_photo_01` 和走廊碎片 `corridor_photo_02` 后进入水井，会先显示 Luna 与主角对话，再进入原解谜。未集齐时沿用原玩法；再次进入不重播。首次标志存于本局 GameState，切换地点与退出水井保留，新游戏重置。剧情数据位于 `scripts/puzzles/well_memory_story.gd`，CG 原图为 `assets/art/cg/act_01/cg_01_rooftop.png`。

核心界面为 scenes/puzzles/memory_puzzle.tscn，配置位于 resources/well_memory_puzzle.tres。月相固定五个位置，未获得月相隐藏并拒绝拖动。上半界面水中保留五个占位词，下半界面只出现本轮投入的月相对应词。

选碎片界面已接入环境/水井分层背景，三张原图统一归档在 assets/art/puzzles/well_memory/backgrounds/，总图作为合成参考。井口椭圆与可拖入区域对齐，月相及黑色文字采用浅色底衬；进入填词后继续显示同一水井背景；本轮投入碎片对应的词先浮出水面，再飞向各自原月相位置，其他词不会变成可用词牌。句子和填词槽留在水井上方，原有投入、确认、拖拽填词、错误重试及退出规则保留。背景、参考画布、水井显示区域和井口区域通过解谜资源的 moon_environment / moon_well / moon_reference_size / moon_well_rect / moon_water_rect 配置。

| 碎片 | 来源 | ID | 对应词 |
| --- | --- | --- | --- |
| 1 港湾 | 卧室照片 | bedroom_photo_01 | A |
| 2 镜面 | 走廊照片 | corridor_photo_02 | B |
| 3 | 后续添加 | memory_fragment_03 | C |
| 4 | 后续添加 | memory_fragment_04 | D |
| 5 | 后续添加 | memory_fragment_05 | E |

左键拖月相入椭圆水面，至少投入一个后出现“按enter开始还原”。Enter 后所选词和句子浮出水面。将词拖入两个空格，至少填入一个后可再次按 Enter。可替换、交换或将词拖回水面取消。

正确答案为左 A、右 B，成功从 CG 文案1 开始播放完整分段剧情，并依次显示 CG1 左上、左下、右侧三块画面。三块均裁去外围白边与分隔线，按原照片位置逐步叠加：第1—6页显示左上，第7—10页加入左下并保留左上，第11—16页再加入右侧，最后三张同时显示。源图保留，显示区域由 resources/art/cg/act_01/ 下的独立 AtlasTexture 配置；最后一页结束后，CG 与对白直接淡出至进入水井前的游戏画面，自动恢复原地点与操作，无黑屏停留或额外点击。CG 阅读期间左键、Enter、空格或 F 补全/推进，Esc 沿用退出功能。少填、颠倒或填错显示“水面很平静，毫无波澜”，1.5 秒后清空本轮投入和填词；已收集碎片保留。只有 A 或只有 B 也能进入尝试，完成当前答案需要先收集两张照片。

界面持续显示“按esc退出”；各阶段 Esc 返回原位置，成功 CG 也可左键退出。退出会清理拖拽与动画。本轮选择属于解谜实例，不修改共享配置或消耗碎片。

每个 memory_option.gd 资源设置 choice_id、fragment_id、fragment_display_name、word、moon_fraction、moon_texture。替换词语和月相资产或添加新的收集来源，可直接修改资源。memory_puzzle_definition.gd 设置 answer_left / answer_right、sentence_verb、success_image、rise_duration、failure_duration 和 puzzle_id。

调用入口：
```gdscript
context["ui"].open_puzzle(definition, context["state"].owned_fragment_ids())
```
场景只接收碎片列表快照，使用 exit_requested 和 restoration_succeeded(puzzle_id) 信号。单独 F6 运行时默认没有持有碎片；可在 Inspector 的 available_fragment_ids 配置测试库存，或按 F5 通过实际收集流程试玩。

## 继续扩展

main.tscn 保留 Player、UI、GameState 和 LevelHost；场景切换只替换地点实例。五个地点均在 scenes 中，Geometry 为白模，Interactables 为 F 交互节点，SpawnPoints 为命名入口；camera_bounds 控制镜头移动边界。

继承 scripts/interactable.gd，覆写 interact(context)，放在地点的 Interactables 下即可新增 F 交互。context 中有 game、player、state、ui。交互锚点放在可接近的地面，prompt_offset 调整提示位置。interaction_rect 可配置以该锚点为原点的局部矩形脚点区域；空矩形沿用人物默认65单位半径。卧室门两侧采用较宽矩形覆盖斜角接近，楼梯采用上端/下端定向矩形，普通物件仍保留原距离判定。

- portal.gd：target_scene_path、target_spawn 配置往返；required_key 为空时直接通行，非空时检查钥匙。message_offset 调整锁门提示位置。
- collect_photo.gd：fragment_id 为稳定身份；fragment_display_name 控制获得提示；narrative_text 为可见剧情正文；artwork 可添加收集弹窗中的物品预览。placeholder_caption 仅为内部元数据。
- game_state.gd：collect_fragment / has_fragment / owned_fragment_ids / fragment_count，以及 collect_key / has_key。奖励接口去重，fragment_acquired 和 key_acquired 可接任务系统。
- collect_key.gd：key_id、item_name、artwork 配置钥匙收集；默认绘制钥匙占位图形。
- game_ui.gd：show_collection(pages, artwork, placeholder_type, reward_page, show_exit_hint) 为可复用收集弹窗。pages 是文本页列表，reward_page 指定40像素的奖励页，其他页36像素，show_exit_hint 仅在最后一页显示退出提示。可选 artwork 替换左侧图形，placeholder_type 为 key 时绘制钥匙。该界面沿用 view_state_changed 管理移动暂停；show_view 继续用于 CG。scripts/ui_text_style.gd 统一纯黑文字和浅色底衬。
- MovementBounds：原矩形场景通过 area、thickness 调整外围；一楼和凸出楼梯的走廊通过 outline 的闭合多边形限制脚下碰撞体，轮廓无需重复首点。内墙和家具另有碰撞。contains_body 可验证完整脚下碰撞体的位置。

后续钥匙物件可复用 collect_key.gd 或调用 context["state"].collect_key(&"studio_key_01")。收集状态在 GameState 中去重，画室门只检查持有条件，不消耗钥匙。

## 验证

- tests/opening_verification.tscn：首次八页开场、无环境音、立绘与震动、输入拦截、完成记录跳过、对白冻结移动、新游戏重置及暂停继续。使用独立临时配置，结果为 verification/opening_results.json，并保存 opening_*.png 画面。
- tests/runtime_verification.tscn：移动、原有卧室交互、五个地点往返、画室锁门、实际灌木取钥匙及解锁往返、两个空房通道、家具碰撞、矩形/多边形外围、照片正文/奖励分步推进、提前 Esc、黑色字体、文字框布局及奖励去重。
- tests/puzzle_verification.tscn：零碎片、仅 A、仅 B、A+B，真实左键拖拽、椭圆边缘、填词替换交换、少填/错填/顺序、成功 CG、各阶段退出和配置复用。碎片3–5通过测试接口注入，只用于验证后续扩展。

结果写入 verification/test_results.json、puzzle_test_results.json，图形验证自动保存实际运行截图。verification 图片用于检查显示效果，不作为游戏资产。

本项目已安装并启用 addons/godot_ai；MCP 配置属于本机，复制项目不需要复制 Codex 配置。交给组员时复制整个 demo2 文件夹，他们在 Godot 中导入 project.godot 后按 F5。游戏文字统一使用项目内的寒蝉点阵体 16px（assets/fonts/chill_bitmap_16px.ttf），由 ui_font.tres 引用；主菜单与暂停界面继续使用图片文字。替换字体时保持 ui_font.tres 的路径，沿用现有字号与黑色文字样式。
