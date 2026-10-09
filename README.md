# demo2 第一幕白模

Godot 4.7.2 / GDScript / 2D。打开本目录的 project.godot，按 F5 运行项目。默认 1920×1080，WASD 移动，靠近交互目标后按 F。

## 本轮内容

- 卧室：窗户展示空白 CG；字条在桌子上方单行显示“来水井边见我”，4 秒后消失；书架照片打开底部正文“照片上的女人背对月光，面目模糊不清”，立即获得碎片1“港湾”。
- 二楼走廊：保留卧室门和下楼楼梯，增加三幅照片框、画室门、无交互花盆。标有“照片”的框按 F 在当前场景上弹出实验室剧情正文，立即获得碎片2“镜面”。
- 空画室：独立 studio.tscn，目前门上锁。按 F 显示“已上锁”。持有钥匙 studio_key_01 后显示“已解锁”并进入；室内有返回走廊的门。钥匙来自院子水井左侧的灌木丛，使用后保留。
- 一楼：按参考图设置玄关、客厅、餐桌、小帐篷、厨房柜台和两个空房。空房直接走入，无需 F。家具仅为有碰撞的白模，地毯、鞋垫可踩踏；大门和楼梯继续按 F 切换场景。
- 院子：没有对应碎片时，水井上方显示“水面很平静，毫无波澜”；拥有任意一块对应碎片可进入独立解谜界面。
- 两张照片采用正文→获得提示→关闭的分步弹窗，左键任意位置或 F 前进，Esc 随时关闭。打开正文时立即获得碎片；提前退出保留奖励，重复查看仍有两页，奖励去重。当前场景变暗，底部白色框宽94%、高25%、距底部3%；正文页仅显示正文，获得页另有“左键点击屏幕任意位置退出”。弹窗和解谜暂停移动，关闭恢复原位置。
- 灌木丛按 F 立即获得钥匙1（studio_key_01），显示代码绘制的钥匙占位图形和“画室钥匙”。左键、F 或 Esc 关闭，重复查看不重复发放钥匙。
- 所有操作提示和弹出正文为 36 像素，照片碎片提示为 40 像素，字体为纯黑色，采用白色或浅色底衬。未接入美术的物件保留占位名称，已接入素材的物件自动隐藏占位文字；不显示常驻说明、占位描述或计数 HUD。

人物高度 150，脚下碰撞直径 39，移动速度 300。沿用 100 世界单位约 1 米的尺度。卧室已接入用户提供的 10 张美术素材，其他场景、人物和 CG 继续使用占位；月相由圆弧和椭圆弧绘制。状态在本次运行内跨场景保留，重新运行重置；没有存档、背包或音效系统。

卧室原图位于 assets/art/environments/bedroom/，AtlasTexture 区域资源位于 resources/art/bedroom/。图片显示与原有碰撞/F 交互分开；绑定美术后自动隐藏白模占位文字，未提供素材的字条等对象保留文字。新增桌面台灯仅为装饰。完整目录、命名、导入和替换约定见 [美术资产规范](docs/art_assets.md)，资产原名及校验清单见 assets/art/manifest.json。

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

main.tscn 保留 Player、UI、GameState 和 LevelHost；场景切换只替换地点实例。五个地点均在 scenes 中，Geometry 为白模，Interactables 为 F 交互节点，SpawnPoints 为命名入口；camera_bounds 控制场景完整显示。

继承 scripts/interactable.gd，覆写 interact(context)，放在地点的 Interactables 下即可新增 F 交互。context 中有 game、player、state、ui。交互锚点放在可接近的地面，prompt_offset 调整提示位置。

- portal.gd：target_scene_path、target_spawn 配置往返；required_key 为空时直接通行，非空时检查钥匙。message_offset 调整锁门提示位置。
- collect_photo.gd：fragment_id 为稳定身份；fragment_display_name 控制获得提示；narrative_text 为可见剧情正文；artwork 可添加收集弹窗中的物品预览。placeholder_caption 仅为内部元数据。
- game_state.gd：collect_fragment / has_fragment / owned_fragment_ids / fragment_count，以及 collect_key / has_key。奖励接口去重，fragment_acquired 和 key_acquired 可接任务系统。
- collect_key.gd：key_id、item_name、artwork 配置钥匙收集；默认绘制钥匙占位图形。
- game_ui.gd：show_collection(pages, artwork, placeholder_type, reward_page, show_exit_hint) 为可复用收集弹窗。pages 是文本页列表，reward_page 指定40像素的奖励页，其他页36像素，show_exit_hint 仅在最后一页显示退出提示。可选 artwork 替换左侧图形，placeholder_type 为 key 时绘制钥匙。该界面沿用 view_state_changed 管理移动暂停；show_view 继续用于 CG。scripts/ui_text_style.gd 统一纯黑文字和浅色底衬。
- MovementBounds：原矩形场景通过 area、thickness 调整外围；一楼通过 outline 的闭合多边形限制脚下碰撞体，轮廓无需重复首点。内墙和家具另有碰撞。contains_body 可验证完整脚下碰撞体的位置。

后续钥匙物件可复用 collect_key.gd 或调用 context["state"].collect_key(&"studio_key_01")。收集状态在 GameState 中去重，画室门只检查持有条件，不消耗钥匙。

## 验证

- tests/runtime_verification.tscn：移动、原有卧室交互、五个地点往返、画室锁门、实际灌木取钥匙及解锁往返、两个空房通道、家具碰撞、矩形/多边形外围、照片正文/奖励分步推进、提前 Esc、黑色字体、文字框布局及奖励去重。
- tests/puzzle_verification.tscn：零碎片、仅 A、仅 B、A+B，真实左键拖拽、椭圆边缘、填词替换交换、少填/错填/顺序、成功 CG、各阶段退出和配置复用。碎片3–5通过测试接口注入，只用于验证后续扩展。

结果写入 verification/test_results.json、puzzle_test_results.json，图形验证自动保存实际运行截图。verification 图片用于检查显示效果，不作为游戏资产。

本项目已安装并启用 addons/godot_ai；MCP 配置属于本机，复制项目不需要复制 Codex 配置。交给组员时复制整个 demo2 文件夹，他们在 Godot 中导入 project.godot 后按 F5。中文字体采用系统 Microsoft YaHei，可通过 ui_font.tres 替换。
