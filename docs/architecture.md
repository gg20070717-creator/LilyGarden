# demo2 架构与扩展指南

## 文档职责

本文说明 Lunar 在 `D:/godot/demo/demo2` 内的运行结构、模块职责、接口及扩展方式。静态核对日期：2026-10-15，依据当前 `.gd`、`.tscn`、`.tres` 与项目配置整理。当前同步三处谜题的碎片中文名、有序组合剧情与浮现组件；未由 Codex 启动试玩、验证场景或自动化测试，文中描述不构成运行验收结论。

- 开发操作、项目边界及验证要求见 [AGENTS.md](../AGENTS.md)。
- 当前接入内容、占位与后续事项见 [项目状态](project_status.md)。
- 素材命名、导入、裁图与原图保护见 [美术资产规范](art_assets.md)。
- 音轨归档、WAV 导入、循环和试听约定见 [音频资源规范](audio_assets.md)。
- 项目入口说明见 [README](../README.md)。

实现变动时更新对应章节，避免在本文累计记录每轮工作或复制完整资产清单。

## 入口与目录

`project.godot` 配置 Godot 4.7、GL Compatibility 渲染及 1920 x 1080 参考视口，项目名为 Lunar。项目逻辑使用 GDScript；`.NET` 程序集名配置不代表已有 C# 玩法模块。

| 路径 | 职责 |
| --- | --- |
| `project.godot` | 引擎设置、主场景、插件与运行时辅助节点配置 |
| `scenes/ui/main_menu.tscn`、`scripts/ui/main_menu.gd` | F5 主入口，会话创建、保留、暂停与菜单切换 |
| `main.tscn`、`scripts/main.gd` | 单次游戏会话，协调玩家、地点、状态与 UI |
| `scenes/` | 五个地点及玩家、白模、移动边界复用场景 |
| `scripts/` | 探索、交互、会话状态及共享显示组件 |
| `scripts/ui/`、`scenes/ui/` | 主菜单、暂停、开场、对白与一次性操作说明 |
| `scripts/puzzles/`、`scenes/puzzles/` | 共用记忆解谜状态机、拖拽、反馈与演出 |
| `scripts/audio/`、`resources/audio/` | 会话常驻 BGM 控制器、Hide/SEEK clip 与转换规则 |
| `resources/` | 解谜定义与 AtlasTexture、SpriteFrames 等配置资源 |
| `LunarTitleFX/`、`shaders/` | 菜单标题效果与交互光晕、暂停模糊着色器 |
| `assets/` | 游戏实际引用的原图、字体、音轨及各自资产清单 |
| `addons/godot_ai/` | 按项目启用的编辑器桥接插件及运行时辅助节点 |
| `tests/` | 已有专用验证场景和脚本，执行条件遵循项目规范 |

Godot AI 的 `_mcp_game_helper` 是工具辅助 autoload。玩法状态由 `main.tscn` 的 `GameState` 节点持有。

## 会话与场景生命周期

### 菜单、开场与暂停

`main_menu.gd` 保持在场景树中，通过 `GameHost` 持有 `_game`。主要流程为：

```text
主菜单 -> 新游戏 -> 黑幕加载资源 -> 开场与主角对白
       -> 黑幕创建 main.tscn -> 淡入卧室 -> 探索

探索 -> Esc -> 暂停 -> 继续 -> 同一会话
暂停 -> 主菜单 -> 继续游戏 -> 同一会话
新游戏 -> 完整开场 -> 重建会话
```

`start_new_game()` 先设置 `transitioning`，锁定重复输入并淡出，在完全黑屏后线程加载 `main.tscn`。加载失败时恢复菜单，并保留旧会话供继续。加载成功后播放 `opening_cinematic.gd` 的完整页序列；开场结束后释放旧实例、创建新实例，保持游戏冻结直到卧室淡入结束。

`opening_cinematic.gd` 使用独立 `StoryDialogue`、黑底、淡入与特定页震动；页数据包含前段旁白、Luna 台词、主角对白及回忆旁白。每次新游戏完整播放。开场期间由菜单转发输入，Esc 被消化，当前没有跳过开场接口。

`continue_game()` 恢复 `_game` 的显示、UI、相机和 `PROCESS_MODE_INHERIT`，并调用 BGM 的 `start_or_resume()`。`return_to_menu()` 调用 `_suspend_game()`，隐藏游戏、UI 和相机，设置 `PROCESS_MODE_DISABLED` 并清零速度。`pause_game()` 同样禁用游戏处理，但保留画面供暂停界面的两遍高斯模糊取样。暂停与 `_suspend_game()` 都显式调用 BGM 的 `suspend()` 冻结音频时间；节点处理模式负责会话逻辑，未使用 `SceneTree.paused`。

BGM 不自动播放。整段开场和卧室淡入结束前保持无音乐，菜单在恢复自由操作界面时才开始 Hide。新游戏销毁旧会话并重建 BGM，起始播放位置为 0；继续游戏恢复当前时间，主菜单没有另建音乐播放器。

“继续游戏”要求当前 `_game` 有效。退出进程后会话消失；存档槽、设置和制作人员页面目前为预留空白页。后续页面接口为：

| 接口 | 作用 |
| --- | --- |
| `page_requested(page_id)` | 打开 `load_game`、`settings`、`credits` 时发出 |
| `request_load_slot(slot_id)` | 供未来槽位界面调用 |
| `load_slot_requested(slot_id)` | 转发载入请求，当前没有读写存档实现 |
| `return_to_menu()`、`pause_game()`、`continue_game()` | 控制现有会话的显示与处理模式 |

### 常驻游戏结构

```text
Demo2 (main.gd)
  GameState (game_state.gd)
  BGM (bgm_controller.gd，运行时创建 AudioStreamPlayer)
  World
    LevelHost
      当前地点 (level.gd)
    Player (player.tscn / player.gd)
    Camera (Camera2D)
  UI (game_ui.gd, CanvasLayer 10)
  RoomTransition (运行时建立, CanvasLayer 90)
```

地点切换只替换 `LevelHost` 的子实例。玩家、相机、GameState、GameUI 与 BGM 在单次会话内复用。主菜单的开场层为 50、全局转场层为 100，暂停场景层为 20。

`main.gd` 默认从 `bedroom.tscn` 的 `start` 出生。地点根节点挂 `level.gd`，包含以下固定结构：

| 节点或字段 | 契约 |
| --- | --- |
| `level_id`、`display_name` | 地点身份与显示名称 |
| `camera_bounds: Rect2` | 相机可见范围约束 |
| `MovementBounds` | 物理活动边界，提供 `area` 与可选 `outline` |
| `Geometry` | 可见物件与碰撞，不承担统一交互调度 |
| `Interactables` | 当前实现只枚举其直接子节点 |
| `SpawnPoints/<spawn_id>` | 命名 `Marker2D`，由 `get_spawn()` 获取 |

`get_playable_bounds()` 返回 `MovementBounds.area`；物理活动范围还可能由多边形 `outline` 决定，相机约束则独立读取 `camera_bounds`。

### 五地点连接与出生点

| 来源 | 目标场景 | 目标出生点 | 条件 |
| --- | --- | --- | --- |
| 新游戏 | `bedroom.tscn` | `start` | 默认初始地点 |
| 卧室 | `corridor.tscn` | `from_bedroom` | F 交互 |
| 走廊 | `bedroom.tscn` | `from_corridor` | F 交互 |
| 走廊 | `first_floor.tscn` | `from_corridor` | 楼梯 F 交互 |
| 一楼 | `corridor.tscn` | `from_first_floor` | 楼梯 F 交互 |
| 一楼 | `courtyard.tscn` | `from_first_floor` | F 交互 |
| 小院 | `first_floor.tscn` | `from_courtyard` | F 交互 |
| 走廊 | `studio.tscn` | `from_corridor` | 持有 `studio_key_01` |
| 画室 | `corridor.tscn` | `from_studio` | F 交互 |

门户保存 `target_scene_path` 字符串，避免双向地点产生 PackedScene 循环引用。`portal.gd` 检查钥匙后调用常驻对象的 `change_level()`；无钥匙显示 4 秒“已上锁”，钥匙不消耗，成功进入后不自动显示“已解锁”。门和楼梯保留物理边界，转场由 F 触发。

### 地点加载与错误处理

`change_level(scene_path, spawn_id, arrival_note, note_offset)` 是异步地点切换入口：锁定输入、清零速度、取消目标高亮与旧提示，淡出后等待黑幕已绘制，线程加载目标，调用 `_replace_level()`，最后淡入并恢复输入。加载结果为 `bool`；有成功到达提示时在新地点显示。

`_replace_level()` 在移除旧地点前检查资源、根脚本类型及指定出生点。资源加载失败、地点根类型无效或缺少出生点时输出错误并返回 `false`；切换已有地点时旧实例保留，外层继续完成淡入和输入恢复。初次进入在 `_ready()` 中同步加载默认地点，也经过该替换入口；当前未实现自动重试或替代地点。

门户发起调用后会随旧地点释放，加载及转场完成由常驻 `main.gd` 负责。新增切换行为继续使用该入口，避免在交互节点中直接替换整个游戏场景。

## 输入与交互

### 输入路由

`main.gd:_setup_input()` 在运行时补齐物理按键动作：W/A/S/D 对应移动，F 对应 `interact`，Esc 对应 `close_view`。主菜单通过 Godot 的 `ui_cancel` 处理暂停和返回。

探索输入按以下顺序处理：

1. 地点转场中消化输入，禁止继续交互。
2. 一次性 `controls_hint` 优先处理按键；关闭说明的按键被消化。说明打开时移动与物件交互均被阻塞。
3. `modal_open` 时交给 GameUI；主场景停止向探索交互分发该事件。
4. 鼠标左键尝试点击检查物件。
5. F 重新选择最近有效目标并调用其 `interact(context)`。

`_physics_process()` 将 `transitioning`、`ui.modal_open`、操作说明状态汇总为 `player.input_blocked`。GameUI 发出 `view_state_changed` 时立即更新锁定、清零速度并重选目标。解谜覆盖世界时隐藏 `World`；解谜返回动画开始时恢复世界显示，模态锁定保留至退出完成。

`_select_target()` 遍历当前地点 `Interactables` 的直接子节点，依次检查继承类型、`can_interact()` 和交互范围，以世界距离选择最近目标，并切换其高亮。当前不显示浮动“按 F 交互”文字，`GameUI.set_prompt()` 保留接口并主动隐藏标签。

点击路径通过视口 canvas 变换还原世界坐标，按节点顺序选择第一个满足 `can_interact()` 且 `contains_click()` 命中的节点。点击不要求靠近，也不采用最近目标排序。`inspect_object.gd` 以 `visual_path` 指向物件的 `size` 和 `oval` 判断命中；该范围与美术透明轮廓及 `artwork_size/artwork_offset` 独立。

图片、收集、对白及解谜各自处理 Esc，处理成功后消化事件。菜单在 `_unhandled_input()` 处理剩余 Esc，并检查游戏模态与转场状态，保持当前弹层关闭优先于打开暂停。

### 交互上下文与基类

`main.gd` 创建并复用以下上下文：

```gdscript
context = {"game": self, "player": player, "state": state, "ui": ui}
```

| 键 | 依赖与典型用途 |
| --- | --- |
| `game` | `main.gd`，地点切换及 `transitioning` |
| `player` | 玩家实例与世界位置 |
| `state` | GameState，碎片、钥匙与剧情标记 |
| `ui` | GameUI，正文、图片、对白、解谜与临时提示 |

新增交互继承 `interactable.gd`，遵循 `can_interact(context)`、`is_in_interaction_range(world_position, default_range)`、`interact(context)` 及 `set_highlight(value)`。基类 `can_interact()` 返回 `enabled`，`interact()` 发出 `interacted(context)`；子类覆盖时按需要保留信号。继承的 `interaction_id` 和收集用 `fragment_id/key_id` 各有职责。

`interaction_rect` 为节点局部的玩家脚底位置矩形；非空时使用矩形，空时使用默认半径。`visual_path` 绑定可见对象，独立于 Area2D 的位置和交互范围。`get_highlight_color()` 默认返回白色，记忆类返回 `MEMORY_GLOW_COLOR`。

| 脚本 | 实现职责 |
| --- | --- |
| `portal.gd` | 可选钥匙门槛、锁定提示、目标场景路径及出生点 |
| `read_note.gd` | 世界坐标锚定、限时显示字条 |
| `inspect_cg.gd` | 单图查看或配置图片序列播放 |
| `inspect_object.gd` | 点击和靠近 F 检查，使用 collection 正文弹窗 |
| `collect_photo.gd` | F 照片收集，正文和获得提示两页，立即发放去重碎片 |
| `collect_memory_item.gd` | 继承点击检查的记忆来源，支持正文、美术和获得提示 |
| `collect_key.gd` | 立即发放去重钥匙，展示道具图片或代码钥匙占位 |
| `well_interaction.gd` | 水井碎片门槛、首次前置对白判断与解谜调用 |
| `fish_tank_interaction.gd` | 继承点击检查，有匹配碎片时打开独立鱼缸配置，否则显示正文 |
| `brush_wash_interaction.gd` | 继承点击检查，持有任意匹配碎片时打开独立洗笔桶资源；本局首次先播前置对白并记标记，否则显示静水正文 |
| `studio_genesis_interaction.gd` | 默认五页《创世纪》阅读与头痛剧情，靠近 F 或点击书本启动普通对白 |

## 会话状态

`game_state.gd` 持有 `fragments`、`keys`、`seen_story_events` 三个字典，跨地点保留，新游戏重建。

| 接口 | 语义 |
| --- | --- |
| `collect_fragment(fragment_id) -> bool` | 新 ID 写入并发出 `fragment_acquired`；重复返回 `false` |
| `has_fragment(fragment_id)`、`fragment_count()` | 查询持有状态与数量 |
| `owned_fragment_ids() -> Array[StringName]` | 构造新的 ID 列表，供解谜接收快照 |
| `collect_key(key_id) -> bool`、`has_key(key_id)` | 去重收集与持有查询，新钥匙发出 `key_acquired` |
| `has_seen_story_event(event_id)`、`mark_story_event_seen(event_id)` | 会话级剧情标记 |

照片和草稿纸在打开正文时即写入碎片，提前关闭保留奖励。重复查看仍可呈现获得页，状态不重复发放。门户仅查询钥匙。当前没有序列化存档、独立背包 UI 或已完成谜题集合。

水井在同时持有 `bedroom_photo_01`、`corridor_photo_02` 且未标记 `well_memory_intro` 时请求前置对白。解谜成功打开且 `introduction_started` 为真后，入口立即写入标记；提前 Esc 退出对白也保留该标记。谜题的 `restoration_succeeded` 目前由 GameUI 转发，未自动写入 GameState。

洗笔桶在持有任意匹配碎片且未标记 `brush_wash_memory_intro` 时请求 `brush_wash_memory_story.gd:INTRO_PAGES` 的三句前置对白。对白实际开始后立即写入标记，提前 Esc 也保留；重复交互直接进入选碎片，新游戏重建状态后重新播放。没有匹配碎片时显示静水正文，不标记前置对白。

碎片拖拽引导的已显示标记位于常驻 GameUI 的 `puzzle_drag_hint_seen`，供水井、鱼缸和洗笔桶在同一局中共享。它随新游戏重建 UI 后重置，退出谜题、换地点、失败重试及再次进入均保留；当前不写入 GameState 或磁盘。

## UI 与对白接口

`game_ui.gd` 是常驻 `CanvasLayer`，主要控件在 `_ready()` 里构建。`ModalMode` 包含 `NONE`、`IMAGE`、`PUZZLE`、`COLLECTION`、`DIALOGUE`；`modal_open` 与 `view_state_changed(is_open)` 对外表达输入锁定。

| API | 用途与边界 |
| --- | --- |
| `show_note(text, world_anchor, seconds)`、`clear_note()` | 限时世界提示，随相机投影并限制在视口内 |
| `show_view(title, caption, artwork, notice, show_exit_hint, narrative_text)` | 图片模态；`title` 留作当前标题状态，`caption` 参数当前未渲染，顶部正文来自 `narrative_text` |
| `show_slideshow(title, artworks, seconds_per_slide)` | 过滤空图片，自动按顺序播放；完整结束或手动退出后关闭 |
| `show_collection(pages, artwork, placeholder_type, reward_page, show_exit_hint, large_artwork)` | 底部正文分页，奖励页字号独立，可显示缩略图、钥匙占位或大图 |
| `show_dialogue(pages)` | 普通逐字对白，实例由 GameUI 复用 |
| `open_puzzle(definition, owned_fragments, show_introduction) -> bool` | 无模态时创建共用解谜实例，复制库存并连接信号；依据本局 `puzzle_drag_hint_seen` 设置实例 `show_drag_hint`，收到 `drag_hint_presented` 后记录已显示 |
| `handle_modal_input(event)`、`close_view()` | 输入转发、关闭、拖拽取消、资源引用和临时状态清理 |
| `show_controls_hint()` | 每个新游戏实例只呈现一次操作说明 |
| `set_status(location, count)` | 当前仅保存地点名，未显示计数 HUD |

`show_collection()`、`show_dialogue()`、`show_slideshow()` 和 `open_puzzle()` 会拒绝已有模态下的重复打开；交互调用者仍应统一遵守当前模态状态。图片/收集由左键、F 或 Esc 关闭或推进；普通对白由左键、Enter、空格、F 补全文字或推进，Esc 关闭。谜题输入由其自身接管。

普通对白页为 `Array[Dictionary]`：

```gdscript
var pages: Array[Dictionary] = [
    {"speaker": "主角", "text": "已确认的台词", "expression": &"speaking"},
    {"speaker": "Luna", "text": "已确认的台词"},
    {"text": "已确认的旁白", "show_protagonist": true, "expression": &"neutral"},
]
context["ui"].show_dialogue(pages)
```

`speaker` 可省略；`expression` 支持 `neutral`、`speaking`、`smile`、`teary`，未知值回退到 `neutral`。主角名为“主角”“你”或 `protagonist` 时默认显示立绘，也可由 `show_protagonist` 指定首次出现。一旦在本段出现，主角立绘持续保留到该对白序列结束；后续未指定表情的页采用中性图。`speaking` 在逐字播放时切换说话/中性口型，文字完成后回到中性。每次 `start()` 深拷贝页数据并重置本段立绘状态。

页可配置 `shake: true`，由 StoryDialogue 统一播放 0.55 秒、参考幅度 16 像素的衰减震动；`set_shake_offset()` 更新对白位置并发出 `shake_offset_changed(offset)`，偏移采用参考画布坐标。`main.gd` 监听常驻 GameUI 的对白实例，将偏移按对白缩放和镜头 zoom 转为反向 `Camera2D.offset`，使探索画面与对白同步移动。翻页、完整结束和 `stop()` 均归零，Esc 经 GameUI 关闭时同样清理。开场沿用此页字段及相同参数，共用实现管理震动计时。

对白、开场和菜单按 1920 x 1080 参考画布等比居中适配。字体统一引用 `ui_font.tres`；`ui_text_style.gd` 管理一般提示的基础文字与底衬，谜题可按配置覆盖。主菜单与暂停按钮沿用图片文字。

## 会话背景音乐

`main.tscn` 根下的 `BGM` Node 挂 `scripts/audio/bgm_controller.gd`，运行时创建一个 `AudioStreamPlayer`。控制器深复制 `resources/audio/gameplay_bgm.tres` 的 AudioStreamInteractive，为当前会话保留独立状态；clip 0 为 Hide，clip 1 为 Seek（原曲名 SEEK）。默认音量 `-6 dB` 可由导出属性调整，输出至 `Master` bus。

| 接口 | 作用 |
| --- | --- |
| `start_or_resume()` | 首次启动当前 clip；已有播放时解除 `stream_paused`，恢复同一时间 |
| `suspend()` | 设置 `stream_paused`，冻结音频播放时间 |
| `set_puzzle_active(active)` | 水井/鱼缸/洗笔桶谜题为真时选择 SEEK，否则选择 Hide；相同目标不重复请求 |
| `stop()` | 停止并重置控制器至未启动的 Hide 状态 |

`main.gd` 根据 GameUI 的 `view_state_changed` 与 `is_puzzle_covering_world()` 更新音乐状态，并检查谜题 ID 为 `well_memory/fish_tank_memory/brush_wash_memory`。谜题打开后的前置对白、选碎片、填词、微剧情与 CG 都使用 SEEK；微剧情读完回到谜题时保持 SEEK。收到 `return_started` 后即切回 Hide，Esc 关闭也切回 Hide，随后普通对白保持 Hide。普通图片、收集、普通对白和地点切换保留当前播放时间。

双向转换均使用 `IMMEDIATE + SAME_POSITION + FADE_CROSS`，通过 `AudioStreamPlaybackInteractive.switch_to_clip()` 在同位置切换。`fade_beats = 0.03` 在当前无 BPM 的 WAV 上对应约 30 ms 逐采样交叉平滑；切换不重新播放或 seek。暂停与返回菜单由菜单壳显式挂起播放器，新游戏通过重建整个会话从 0 开始；整个开场及卧室淡入期间无 BGM，主菜单无新增 BGM。

两份原 WAV 与导入参数独立维护在 `assets/audio/`，全曲循环为 `begin 0 / end -1`，格式、循环枚举及替换约束见音频规范。当前未实现音效系统或音量设置页。原文件归档及参数已静态核对，三处组合剧情沿用既有谜题音乐生命周期；未由 Codex 启动试玩或音频试听，同位置切换、循环和乐句衔接的实际听感待用户确认。

## 共用记忆解谜

### 数据、实例与状态机

`scenes/puzzles/memory_puzzle.tscn` 配合 `scripts/puzzles/memory_puzzle.gd` 供水井、鱼缸、洗笔桶和后续入口复用。静态配置与单轮状态分开：

| 层 | 内容 |
| --- | --- |
| `memory_option.gd` Resource | 稳定 `choice_id`、绑定库存 `fragment_id`、展示名、词、月相比例或图片 |
| `memory_puzzle_definition.gd` Resource | 选项、动词、失败反馈、演出脚本、背景布局、投放区域及可选视觉行为；保留旧左右答案与成功开关作兼容 |
| `memory_combination_stories.gd:BY_PUZZLE` | 按谜题 ID 配置左右有序 `choice_id`、剧情 ID、`kind` 与文字/占位标题 |
| 解谜实例 | `available_fragment_ids` 快照、`selected_ids`、两个 `slot_ids`、深拷贝组合路由与待播内容、临时 token、动画与当前 phase |
| GameState | 实际持有碎片和剧情标记，解谜实例不发放或消耗碎片 |
| GameUI | 本局共享的 `puzzle_drag_hint_seen`，在引导实际显示时更新 |

推荐调用：

```gdscript
context["ui"].open_puzzle(definition, context["state"].owned_fragment_ids())
```

阶段为 `MOON`、`RISING`、`WORD`、`FEEDBACK`、`INTRO`、`RESOLVING`、`STORY`、`ECHO`、`RETURNING`。常规流程是选月相 -> 浮词 -> 两槽填词 -> 组合判定；前置对白、成功扫光、CG 与微剧情在相应阶段衔接。

未持有的月相隐藏并拒绝拖动；至少投入一块才可 Enter 进入填词，至少填入一槽才可再次确认。可替换、交换槽中词牌或拖回水面取消。三处谜题先用稳定 `choice_id` 匹配 `BY_PUZZLE` 中的有序路由，显示文字独立维护为 A=港湾、B=涌泉、C=潮汐。路由表外组合或少填沿用失败反馈，按 `failure_duration` 清空本轮投入和槽位，库存保留；只有未定义组合路由的入口才使用 `answer_left/answer_right` 与 `play_success_story` 的旧行为。

拖拽数据带 `{kind, choice_id, puzzle_instance}`，`accepts_drag()` 同时检查实例身份、阶段和资格。实例深拷贝路由及待播 payload，单轮操作不修改共享 Resource 或常量数据。退出或重置时清理动画、浮现 Tween、计时器、临时词牌与待播内容；GameUI 关闭时取消仍在进行的 GUI 拖拽并释放解谜实例。

### 首次拖拽引导与接收区域

`memory_drag_hint.gd` 绘制鼠标左键、月相和箭头指向目标的图示，文字为“按住左键，将记忆碎片”“拖到水井/鱼缸/洗笔桶上松开”；目标名来自定义的 `drag_hint_target_name`。浅灰蓝文字与透明深色薄边框沿用月光 UI，图片与引导均不拦截拖拽。`drag_hint_rect` 使用参考画布坐标：水井为 `(32, 32, 460, 224)`，鱼缸为 `(1290, 112, 460, 224)`，洗笔桶为 `(48, 710, 460, 224)`；随窗口等比适配并限制在视口内，避开月相与目标物体。

实例通过 `show_drag_hint` 接收显示资格，仅在有可拖碎片且实际进入 `MOON` 阶段时显示并发出 `drag_hint_presented`。水井或洗笔桶前置剧情未读完时不显示也不记录；无可拖碎片时不记录。引导保持可直接拖拽，首块成功投入后淡出。任意非 Esc 按键可收起并消耗该事件，避免同次 Enter 提前确认；Esc 按原规则退出谜题。显示一次后，重试或重新进入均不重复。

`fragment_drop_rect` 是 `moon_reference_size` 中的绝对参考坐标，`fragment_drop_margin` 为同一参考尺度的边缘容错，默认分别为空矩形与 0。空矩形回退至水面形状；当前水井配置 `(600, 842, 750, 230)`，鱼缸配置 `(701, 339, 1060, 490)`，洗笔桶配置 `(760, 310, 700, 770)`，三处 margin 均为 24，覆盖整个目标物体外接矩形及边缘。

`moon_water_rect` 和其局部 `water_drop_polygon` 继续定义可见水面、涟漪及词语拖回取消范围。布局函数将碎片矩形及容错转换为 Water 的局部坐标；Water 的 `_has_point()` 在合法月相拖拽时扩展 GUI 接收范围，`_can_drop_data()` 继续检查实例、阶段和资格。词语拖回仍检查原椭圆或多边形。扩展碎片接收范围只影响月相投放，图片、涟漪、浮词位置、词牌与词槽尺寸保持各自配置。

### 子组件职责

| 文件 | 职责 |
| --- | --- |
| `memory_token.gd` | 月相/词牌绘制、拖拽预览、数据封装、已占用词槽接收替换拖放 |
| `water_drop_zone.gd` | 月相使用独立矩形与容错接收；词牌取消使用原水面椭圆或局部多边形；同步 GUI 命中与拖放资格校验 |
| `memory_drag_hint.gd` | 每局共享的首次碎片拖拽图示、两行文案、淡出与视口内适配 |
| `word_slot.gd` | 两个词槽的接收、弧光绘制、合法拖拽高亮与落槽反馈 |
| `water_ripple.gd`、同名 shader | 配置 SpriteFrames 单次播放、透明裁区与水面显示 |
| `moonlight_hint.gd` | Enter/Esc 透明键帽与阶段提示 |
| `moonlight_effects.gd` | 浮词光尘和成功句子扫光，效果结束后停止刷新 |
| `moonlight_sentence_mist.gd` | 句子背后可选的局部对比柔雾 |
| `memory_combination_stories.gd` | 三处谜题共 12 条有序组合路由及微剧情文字、CG 占位数据 |
| `memory_echo.gd` | 原谜题背景上的淡雾、月光文字浮现与 CG 占位；补齐、继续、淡出及 Tween 清理 |
| `well_memory_story.gd` | 水井 `INTRO_PAGES`、`NARRATIVE_PAGES`、`FOLLOWUP_PAGES` 数据 |
| `brush_wash_memory_story.gd` | 洗笔桶 `INTRO_PAGES` 三句前置对白 |

### 三处谜题配置差异

| 行为 | 水井 | 鱼缸 | 洗笔桶 |
| --- | --- | --- | --- |
| 定义 | `resources/well_memory_puzzle.tres` | `resources/fish_tank_memory_puzzle.tres` | `resources/brush_wash_memory_puzzle.tres` |
| 入口 | 靠近 F，任意匹配碎片可尝试 | 点击或靠近 F，任意匹配碎片可尝试 | 点击或靠近 F，任意匹配碎片可尝试 |
| 阶段编号 / 动词 | 1 / 看见 | 3 / 选择了 | 2 / 之中有 |
| 组合路由 | A→B 为情节块 1；B→A 为微剧情 | A→B 为情节块 3 占位；其余五种 A/B/C 异词组合为微剧情 | A→C 为情节块 2 占位；C→A、B→C、C→B 为微剧情 |
| 前置对白 | A+B 首次齐备时请求水井对白 | 不请求前置对白 | 本局首次有匹配碎片进入时播放三句对白 |
| 碎片接收 | 水井外接矩形 `(600, 842, 750, 230)`，margin 24 | 鱼缸外接矩形 `(701, 339, 1060, 490)`，margin 24 | 洗笔桶外接矩形 `(760, 310, 700, 770)`，margin 24 |
| 水面效果 / 词语取消 | `moon_water_rect` 内椭圆 | `water_drop_polygon` 四边形 | `water_drop_polygon` 贴合桶内水面 |
| 拖拽引导 | 左上 `(32, 32)`，目标名“水井” | 右上 `(1290, 112)`，目标名“鱼缸” | 左下 `(48, 710)`，目标名“洗笔桶”；三处共享已显示状态 |
| 浮词时机 | Enter 后统一浮词，`rise_on_drop=false` | 每次投入后立即浮词，动画结束可继续投入 | 每次投入后立即浮词，`rise_on_drop=true`，0.9 秒后可继续投入 |
| CG 后 / 微剧情后 | 情节块 1 完整读完后返回探索并衔接后续对白；微剧情回选碎片 | 情节块 3 占位读完后返回探索；微剧情回选碎片 | 情节块 2 占位读完后返回探索；微剧情回选碎片 |
| 水波纹 | 配置 SpriteFrames | 未配置 | 未配置 |
| 可选 UI | 无白底、月光文字/槽位 | 无白底、月光文字/槽位，独立字号与句子柔雾 | 无白底、月光文字/槽位，句子柔雾透明度 0.21 |

布局位置由 `moon_reference_size`、`moon_well_rect`、`moon_water_rect`、可选月相/水中词坐标、句子矩形和提示中心配置；碎片接收和首次引导另由 `fragment_drop_rect/fragment_drop_margin`、`drag_hint_target_name/drag_hint_rect` 配置。`moon_environment` 单独存在时即可启用整图背景，`moon_well` 作为可选叠加层；洗笔桶使用用户原始整图，布局示意另行归档。背景按覆盖视口的等比缩放映射，部分控件采用自身尺寸规则；新增布局沿用现有换算函数，分别维护图像、水面效果和月相接收范围。洗笔桶的月相坐标、水面多边形及字号见美术规范。

三处共 12 条组合的剧情 ID 与对应词见 [项目状态的组合剧情映射](project_status.md#组合剧情映射)。`micro` 在 `ECHO` 阶段调用 `memory_echo.gd`，淡化原背景并让文字轻微上浮显现，配细光线与稀疏光点；沿用项目字体，不显示常规对白框或角色立绘。左键/Enter/空格/F 先补齐浮现，再继续淡出，读完清空本轮尝试并返回 `MOON`，库存与共享拖拽引导标记保留，不发出 `restoration_succeeded`，不请求水井后续对白。

`cg_existing` 复用水井 `NARRATIVE_PAGES` 与现有 CG，`cg_placeholder` 通过浮现组件展示“情节块 2/3 · CG 占位”和“画面待补充”。CG 路由开始显示时发出 `restoration_succeeded(puzzle_id)`，由 GameUI 转发，读完后返回探索。水井完整读完 `NARRATIVE_PAGES` 后才发出 `followup_requested(pages)`；Esc 提前退出演出不会排入后续对白，微剧情与占位 CG 均沿用 Esc 退出谜题规则。

GameUI 暂存后续页，收到 `return_started` 时恢复探索世界显示但继续锁定输入，等待解谜淡出和 `exit_requested`。`close_view()` 释放解谜后直接打开待续对白，避免恢复移动后再重新锁定。

`story_script` 通过脚本常量加载三类页数据。普通页格式由 StoryDialogue 解析；解谜演出额外读取 `cg_image`。当前水井将 AtlasTexture 区域作为 3508 x 2480 合成画布中的位置与尺寸，首次遇到各分镜时淡入并保留先前分镜。普通图片路径使用单图显示。新增剧情结构若超出这些规则，需要同时扩展演出逻辑。

洗笔桶 `puzzle_definition` 绑定独立资源，使用稳定的 A—E 库存映射；未持有选项隐藏，D/E 来源继续预留。首次前置对白沿用实例的 `INTRO` 阶段、`introduction_started` 与 GameState 剧情标记机制。创世纪已在 `studio_genesis_interaction.gd` 默认 `story_pages` 中接入五页对白，复用普通查看物件的交互范围、白色光晕与输入分发；每次交互从第一页开始，具体故事时序见项目状态文档。

## 移动、相机与显示效果

| 模块 | 实现及维护边界 |
| --- | --- |
| `player.gd`、`player.tscn` | `CharacterBody2D` 浮动模式，`Input.get_vector()` + `move_and_slide()`；脚底碰撞半径 19.5，默认速度 300、交互半径 65、白模身高 150；移动步态与朝向仅控制绘制 |
| `main.gd` 相机 | `camera_view_size` 默认 1024 x 576 世界单位，按视口较小缩放因子等比适配；跟随脚底上方半身高，按 `camera_bounds` 限制，小于视野的轴居中 |
| `movement_bounds.gd` | `@tool` 生成物理外围；`outline` 有至少三点时建立闭合分段碰撞，否则使用 `area` 四边墙；`contains_body()` 为几何查询工具 |
| `whitebox.gd` | `@tool` 根据 `size/solid/oval` 重建碰撞，按 `artwork/artwork_size/artwork_offset` 绘图；有美术时隐藏占位文字，视觉尺寸与物理占地独立 |
| `interaction_glow.gd` + `shaders/interaction_glow.gdshader` | 懒创建独立光晕子层，按 PNG alpha/Atlas 裁区或矩形椭圆采样；依据 canvas 缩放保持屏幕亮边宽度；白色普通目标、幽蓝记忆目标，暂停随游戏冻结 |
| `pause_menu.tscn` + `shaders/pause_gaussian_blur.gdshader`、`pause_title.gdshader` | 冻结画面上水平/垂直两遍模糊，中间 BackBufferCopy，再叠加半透明 ColorRect、独立 Atlas 标题和图片按钮 |
| `scripts/ui/menu_hover_button.gd` | 保持 TextureButton 命中矩形，子图层承担悬停展开、淡入及按压回弹 |
| `LunarTitleFX/lunar_title.gd`、同名 shader、`lunar_title.tscn` | 主菜单标题单平面透视、鼠标平滑倾斜及程序扫光；每个实例独立 ShaderMaterial；可配置自动摆动与高光遮罩 |

100 世界单位约 1 米。玩家位置、出生点与 F 矩形使用脚底基准；绘制角色向上延伸。相机强制刷新后，UI 将世界提示投影到屏幕并限制越界。修改视野、物理尺寸和图像尺寸前分别核对其职责。

光晕视觉绑定当前依赖白模物件的 `size`、`artwork`、`artwork_size`、`artwork_offset`、`draw_placeholder`、`oval` 属性。改用新物件类型时应提供相同属性或补充适配。标题效果包含 `res://LunarTitleFX/` 的绝对资源引用，迁移目录时同步修改引用。素材文件及裁图维护细节见美术资产规范。

## 常用扩展步骤

### 新增地点与门户

1. 创建挂 `level.gd` 的地点场景，保留四个约定容器并设置 `level_id`、`display_name`、`camera_bounds`。
2. 配置 `MovementBounds.area/outline` 和 Geometry 占地，建立明确的 `SpawnPoints/<spawn_id>`。
3. 在来源地点 `Interactables` 的直接子节点中创建门户，配置目标 `res://` 路径、出生点、可选钥匙、局部 F 矩形和 `visual_path`。
4. 双向通路分别配置目标出生点；继续经 `change_level()` 加载。更新连接表与项目状态，按项目验证要求交付。

### 新增检查或收集物

1. 复用检查、照片、记忆物或钥匙脚本；行为确有差异时继承基类增加专用脚本。
2. 配置正文、展示图、稳定 ID、F 范围和视觉绑定；需要点击时提供 `contains_click()`。
3. 通过 GameState 方法收集，确认奖励发放时机、重复查看行为及弹层输入规则；美术替换继续分离显示和碰撞。

### 新增解谜入口

1. 创建独立定义资源，复用 `memory_puzzle_definition.gd` 与 `memory_option.gd`，配置独立 `puzzle_id`、选项、句型和反馈；按需在 `BY_PUZZLE` 添加有序组合路由，未定义路由的入口沿用旧答案字段。
2. 将选项 `fragment_id` 绑定实际来源，同步展示名与词牌；分别配置该入口的图像、水面、碎片矩形与容错、首次拖拽引导、浮词时机及剧情行为，维护单轮状态与共享配置分离。
3. 入口以持有 ID 列表快照调用 `GameUI.open_puzzle()`。需要前置对白时明确入口条件和已播放标记，复用水井或洗笔桶的时序。
4. 需要成功后解锁或存档时，在会话层显式接入 `restoration_succeeded` 并定义去重规则；当前转发信号尚未提供完成状态存储。

### 新增对白与存档

普通对白通过 `show_dialogue(pages)` 接入。创世纪的默认 `story_pages` 提供现有示例，演出震动使用页字段 `shake`。解谜前置、成功和后续页放入独立剧情脚本的对应常量；谨慎约定“启动”“读完”“还原成功”三种事件的标记时机。

存档接口目前预留。实现时需要显式选择序列化范围，例如 GameState 字典、当前地点身份与玩家位置，并通过现有加载和状态接口恢复；继续游戏现有行为只恢复内存实例。新增能力应同步更新本架构、项目状态及项目规范中的相关接口描述。
