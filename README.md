# Lunar

Godot 4.7.2 / GDScript / 2D。项目显示名与程序集名为 Lunar，本地工作目录为 `D:/godot/demo/demo2`。打开本目录的 project.godot，按 F5 运行项目。默认 1920×1080，WASD 移动，靠近交互目标后按 F。

## 主界面菜单

F5 的项目入口为 `scenes/ui/main_menu.tscn`，菜单逻辑位于 `scripts/ui/main_menu.gd`。点击“新游戏”创建原有 `main.tscn`，从卧室开始；再次选择新游戏会重建角色、地点与收集状态。

游戏一级界面按 Esc 打开暂停界面，当前游戏画面保留并采用高斯模糊，人物移动与交互暂停。暂停界面按 Esc 或点击“继续游戏”恢复；点击“主菜单”保留当前位置与进度并返回主菜单，之后可点击主菜单的“继续游戏”恢复。图片、收集弹窗、水井解谜等二级界面沿用 Esc 返回功能，同一次 Esc 仅关闭当前二级界面。

主菜单和暂停菜单的按钮使用用户提供的半透明背景：鼠标悬停时平滑展开、淡入，移开时淡出；按下时轻微缩小并下沉，松开后回弹。原图片文字、配色、布局和点击范围保持不变，视觉效果统一由 `scripts/ui/menu_hover_button.gd` 管理。

主菜单的“继续游戏”恢复本次运行中的位置与进度，没有游戏实例时不可点击。当前没有持久存档，关闭或重新运行项目后进度重置。

“载入游戏”“设置”“制作人员名单”目前进入预留空白页，按 Esc 返回主菜单；“退出”关闭游戏。

后续页面与存档系统可连接以下接口：

- `page_requested(page_id: StringName)`：打开空白页时发出，页面 ID 为 `load_game`、`settings` 或 `credits`。
- `load_slot_requested(slot_id: StringName)`：后续载入槽位的请求信号；本轮不读写存档。
- `request_load_slot(slot_id: StringName)`：供后续槽位界面调用，发出 `load_slot_requested`。
- `return_to_menu()`：暂停保留的游戏实例并显示主菜单。
- `pause_game()`：在一级游戏界面冻结游戏实例，保留画面并打开 `scenes/ui/pause_menu.tscn`。

## 本轮内容

- 卧室：窗户展示空白 CG；字条在桌子上方单行显示“来水井边见我”，4 秒后消失；书架照片打开底部正文“照片上的女人背对月光，面目模糊不清”，立即获得碎片1“港湾”。
- 二楼走廊：已接入墙面地板、边框、卧室侧门、画室门、三幅照片框和花盆，按素材原始画布关系排列；对应调整走廊宽度、碰撞和交互位置。下楼楼梯从走廊下边缘凸出，在楼梯上端显示 F 交互提示，左侧不触发；上楼返回时落在该上端平台。右侧记忆照片框按 F 在当前场景上弹出实验室剧情正文，立即获得碎片2“镜面”。
- 空画室：独立 studio.tscn，目前门上锁。按 F 显示“已上锁”。持有钥匙 studio_key_01 后显示“已解锁”并进入；室内有返回走廊的门。钥匙来自院子水井左侧的灌木丛，使用后保留。
- 一楼：按参考图设置玄关、客厅、餐桌、小帐篷、厨房柜台和两个空房。空房直接走入，无需 F。已接入地板墙面、边框、玄关大门、鞋垫与小凳子，统一按原始画布布局；其他家具继续使用有碰撞的白模，地毯、鞋垫可踩踏；大门和楼梯继续按 F 切换场景。上楼在楼梯下端显示交互提示，左侧不触发；下楼返回时落在该下端。
- 院子：没有对应碎片时，水井上方显示“水面很平静，毫无波澜”；拥有任意一块对应碎片可进入独立解谜界面。
- 两张照片采用正文→获得提示→关闭的分步弹窗，左键任意位置或 F 前进，Esc 随时关闭。打开正文时立即获得碎片；提前退出保留奖励，重复查看仍有两页，奖励去重。当前场景变暗，底部白色框宽94%、高25%、距底部3%；正文页仅显示正文，获得页另有“左键点击屏幕任意位置退出”。弹窗和解谜暂停移动，关闭恢复原位置。
- 灌木丛按 F 立即获得钥匙1（studio_key_01），显示代码绘制的钥匙占位图形和“画室钥匙”。左键、F 或 Esc 关闭，重复查看不重复发放钥匙。
- 所有操作提示和弹出正文为 36 像素，照片碎片提示为 40 像素，字体为纯黑色，采用白色或浅色底衬。未接入美术的物件保留占位名称，已接入素材的物件自动隐藏占位文字；不显示常驻说明、占位描述或计数 HUD。

人物高度 150，脚下碰撞直径 39，移动速度 300。沿用 100 世界单位约 1 米的尺度。镜头默认显示约 1024×576 世界单位，完整容纳卧室，卧室内镜头保持固定；较大地图中跟随人物身体中心。出生和切换地点时立即定位，到地图边缘时限制镜头，小于视野的轴居中显示。镜头显示范围独立于地图和家具，窗口大小变化时等比调整显示。可在 main.tscn 根节点的 camera_view_size 调整视野。卧室已接入用户提供的 10 张美术素材，走廊和一楼另接入 13 张素材；缺少对应美术的物件与人物继续使用占位；月相由圆弧和椭圆弧绘制。状态在本次运行内跨场景保留，重新运行重置；没有存档、背包或音效系统。

按现有尺度换算实际地面（不计背墙立面）：卧室约 6.45×3.55 米，走廊约 13.61×1.68 米（另含向下凸出的楼梯），一楼地面外轮廓最大约 14×8.47 米。各地点共用同一镜头缩放；卧室完整显示，走廊和一楼随人物分区显示。

场景原图位于 assets/art/environments/ 下的 bedroom、corridor、first_floor 目录，AtlasTexture 区域资源位于 resources/art/ 下的对应目录。图片显示与原有碰撞/F 交互分开；绑定美术后自动隐藏白模占位文字，未提供素材的字条等对象保留文字。新增桌面台灯仅为装饰。完整目录、命名、导入和替换约定见 [美术资产规范](docs/art_assets.md)，资产原名及校验清单见 assets/art/manifest.json。

## 解谜与碎片配置

核心界面为 scenes/puzzles/memory_puzzle.tscn，配置位于 resources/well_memory_puzzle.tres。月相固定五个位置，未获得月相隐藏并拒绝拖动。上半界面水中保留五个占位词，下半界面只出现本轮投入的月相对应词。

选碎片界面已接入环境/水井分层背景，三张原图统一归档在 assets/art/puzzles/well_memory/backgrounds/，总图作为合成参考。井口椭圆与可拖入区域对齐，月相及黑色文字采用浅色底衬；进入填词后沿用原有界面。背景、参考画布、水井显示区域和井口区域通过解谜资源的 moon_environment / moon_well / moon_reference_size / moon_well_rect / moon_water_rect 配置。

| 碎片 | 来源 | ID | 对应词 |
| --- | --- | --- | --- |
| 1 港湾 | 卧室照片 | bedroom_photo_01 | A |
| 2 镜面 | 走廊照片 | corridor_photo_02 | B |
| 3 | 后续添加 | memory_fragment_03 | C |
| 4 | 后续添加 | memory_fragment_04 | D |
| 5 | 后续添加 | memory_fragment_05 | E |

左键拖月相入椭圆水面，至少投入一个后出现“按enter开始还原”。Enter 后所选词和句子浮出水面。将词拖入两个空格，至少填入一个后可再次按 Enter。可替换、交换或将词拖回水面取消。

正确答案为左 A、右 B，成功展示 CG 占位。少填、颠倒或填错显示“水面很平静，毫无波澜”，1.5 秒后清空本轮投入和填词；已收集碎片保留。只有 A 或只有 B 也能进入尝试，完成当前答案需要先收集两张照片。

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

- tests/runtime_verification.tscn：移动、原有卧室交互、五个地点往返、画室锁门、实际灌木取钥匙及解锁往返、两个空房通道、家具碰撞、矩形/多边形外围、照片正文/奖励分步推进、提前 Esc、黑色字体、文字框布局及奖励去重。
- tests/puzzle_verification.tscn：零碎片、仅 A、仅 B、A+B，真实左键拖拽、椭圆边缘、填词替换交换、少填/错填/顺序、成功 CG、各阶段退出和配置复用。碎片3–5通过测试接口注入，只用于验证后续扩展。

结果写入 verification/test_results.json、puzzle_test_results.json，图形验证自动保存实际运行截图。verification 图片用于检查显示效果，不作为游戏资产。

本项目已安装并启用 addons/godot_ai；MCP 配置属于本机，复制项目不需要复制 Codex 配置。交给组员时复制整个 demo2 文件夹，他们在 Godot 中导入 project.godot 后按 F5。游戏文字统一使用项目内的寒蝉点阵体 16px（assets/fonts/chill_bitmap_16px.ttf），由 ui_font.tres 引用；主菜单与暂停界面继续使用图片文字。替换字体时保持 ui_font.tres 的路径，沿用现有字号与黑色文字样式。
