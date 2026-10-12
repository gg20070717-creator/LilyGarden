# 美术资产规范

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
| `assets/art/puzzles/<puzzle>/backgrounds/` | 独立解谜界面的背景、环境和水井等分层图片 |
| `assets/art/puzzles/<puzzle>/effects/<effect>/` | 对应解谜的透明特效序列，帧号使用四位数字 |
| `resources/art/<scene>/` | AtlasTexture 区域、SpriteFrames 等引擎资源配置 |
| `scenes/props/` | 后续需要复用的物件场景，组合图片、碰撞和交互节点 |
| `assets/art/manifest.json` | 资产清单：稳定 ID、中文原名、项目路径、尺寸、区域及 SHA-256 |

以上是按需建立的目录约定。当前 bedroom、corridor、first_floor 已建立背景、物件及 AtlasTexture 资源目录；其他分类在收到对应素材时建立。

命名示例：`bedroom_bookshelf.png`、`player_walk_down.png`、`act_01_memory_01.png`。方向/动画/帧号按需要追加，如 `player_walk_down_01.png`。不使用空格、临时名称、中文运行时路径或 `最终版2` 之类的后缀。美术原文件可继续用中文名，交付清单保留中文对照。

PSD、Aseprite、设计稿及历史版本放在项目外的团队美术源文件目录，运行项目仅放需要的导出资源。Godot 自动生成的 `.godot/` 缓存不提交；PNG 对应的 `.import` 设置文件随项目保留。

## 游戏字体

用户提供的 `ChillBitmap_16px.ttf` 原样保存为 `assets/fonts/chill_bitmap_16px.ttf`，中文字体名为“寒蝉点阵体 16px”。`ui_font.tres` 作为统一 FontVariation 引用该 FontFile，覆盖交互提示、字条、剧情正文、获得提示、水井解谜的提示与词卡，以及场景占位文字；主菜单和暂停界面沿用图片文字。

字体不依赖系统安装，导入时关闭抗锯齿、子像素定位和系统字体回退，保留原字体数据。字号、纯黑文字和现有底衬继续沿用；更新字体后只核对文字覆盖、换行和容器显示。原文件名、项目路径及 SHA-256 记录在资产清单。

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

表中项目文件均位于 `assets/art/environments/bedroom/`。照片.png 是场景中的照片框图，当前照片交互继续使用已确认的正文→获得提示流程。字条、人物和未提供对应素材的物件继续使用现有占位。

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
| 走廊 | 照片记忆碎片.png | `props/corridor_memory_photo_frame.png`，右侧记忆照片，保留“镜面”碎片交互 |
| 走廊 | 花盆.png | `props/corridor_flower_pot.png`，右端楼梯上方，仅盆底有碰撞 |

表中 PNG 位于 `assets/art/environments/<scene>/`，AtlasTexture 位于 `resources/art/<scene>/`。图片无损导入、关闭 mipmaps，场景采用最近邻过滤。原图像素和透明通道保留；走廊照片和画室门存在低透明度散点，Atlas 只截取主体，避免无关透明区挤占显示尺寸。

一楼五层共用 4000×3000 画布，按 0.35 等比缩放并偏移 (35, 64)。大门中心约 (539.7, 140.125)，鞋垫约 (526.225, 248.625)，凳子在其左侧。原图左上、左下透明区域继续作为原有可进入空房，复用地板、墙面裁片，并在门口保留通道。外轮廓、厨房柜台和家具位置随地板底边调整；右上楼梯位于凹口，楼梯下端 y407，到达脚点 (1387.5, 467)。

走廊横坐标按 `x = 0.6 × 原图 x + 2.4` 排列，墙面保留 200 高，步行地面为 1360.8×168。家具图片等比显示，画室门按人物高度单独定为 180 高。记忆照片交互脚点 (574.5, 115)，画室门脚点 (379.5, 120)，楼梯上端 (1316, 240)，从一楼返回落在 (1316, 190)。凸出楼梯与上一轮上下端交互方向保留，缺少美术的楼梯、沙发、餐桌椅、厨房柜等继续白膜。

## 导入与摆放

- 像素素材使用最近邻过滤、无损压缩、关闭 mipmaps；卧室、走廊与一楼根节点已设置最近邻，其他场景维持原有配置。今后非像素 CG 可单独采用线性过滤。
- 家具等物件等比缩放。背景与墙体按场景区域铺设；不要把整张透明大画布作为物件尺寸。
- 现有约定为 100 世界单位约 1 米。人物、床、桌椅的大小基于同一尺度校准。尽量统一导出像素密度；同一方向物件采用一致的落地锚点。
- `whitebox.gd` 的 `artwork` 绑定纹理，`artwork_size` 与 `artwork_offset` 调整显示尺寸和偏移。零显示尺寸会自动等比适配 `size`；地板、边框可显式指定铺设尺寸。
- `size`、`solid`、碰撞体、活动边界和 F 交互锚点属于玩法配置，独立于图片。美术替换后核查可通行区域及交互可达性。台灯、地毯等装饰不增加碰撞。
- 已带在图片中的枕头、桌脚等旧占位绘制已关闭，避免叠加。绑定 artwork 后自动隐藏原白模占位文字；物件名作为内部配置保留。尚无素材的字条等对象继续显示占位文字，F 提示及黑色剧情文字保留。

## 后续交付与替换

1. 导出透明 PNG，说明场景、物件身份、方向及是否为像素风；若使用大画布分层导出，保持所有层的画布尺寸和原点一致。
2. 按上表归类并命名，更新 manifest 的路径、尺寸与校验值。复用资源引用已有路径。
3. 若原图画布或有效区域改变，更新对应 AtlasTexture 的 region；保持场景中资源路径稳定。图片文件重命名或移动使用 Godot FileSystem 面板，随后核查引用。
4. 调整显示尺寸、偏移及必要的物件层级；碰撞只覆盖实体占地。后续角色素材用独立动画资源管理。
5. 按本次改动范围验证：替换图片时核对显示、比例和对齐；涉及碰撞或交互时再检查对应物件的通行与 F 功能，不重复运行无关场景和解谜检查。交付时复制整个 demo2 项目，临时目录中的原图无需一同复制。

## 水井选碎片界面

三张原图归档在 `assets/art/puzzles/well_memory/backgrounds/`：`well_memory_environment.png` 与 `well_memory_well.png` 在选碎片及文字浮现阶段分层显示；`well_memory_composite.png` 保留作总图对照，不重复叠加。填词和 CG 阶段继续使用原有界面。

`resources/well_memory_puzzle.tres` 绑定 `moon_environment`、`moon_well`；`moon_reference_size` 表示原始画布大小，`moon_well_rect` 表示水井图片位置，`moon_water_rect` 单独定义井口椭圆拖放区域。更换背景后按图调整井口范围，井身与井沿不作为投入区域。无图片配置时保留白模界面。

图片层忽略鼠标输入，交互仍由井口拖放节点接收。月相及黑色文本配浅色底衬，Esc、Enter 与句子区分开放置，不增加额外文字说明。

## 水井涟漪动画

`水波纹(1).zip` 的 229 张透明 PNG 原样归档为 `assets/art/puzzles/well_memory/effects/ripple/ripple_0001.png` 至 `ripple_0229.png`，按数字顺序播放。原始 2500×2500 图片和透明通道保留；Godot 的 `.import` 设置将运行纹理尺寸限制为 512，采用线性过滤并关闭 mipmaps，避免加载原始大画布消耗过多显存。

`resources/art/well_memory/water_ripple_frames.tres` 统一管理帧序、60 FPS 和单次播放配置。当前播放时长约 3.82 秒，可在 SpriteFrames 中调整速度。`well_memory_puzzle.tres` 的 `water_ripple` 绑定动画；`ripple_source_uv` 根据整套序列的透明有效范围裁出显示区域，源文件像素不改动。

碎片有效投入井口后播放，连续投入会重新开始；无效拖放不触发。动画位于词语下方，通过 shader 限制在井口椭圆内并降低亮度与不透明度，忽略鼠标输入。Enter 可以直接进入还原，进入填词阶段、重置或关闭界面后清除动画。没有投入时水面保持静止，原有失败提示与解谜判定继续保留。

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

## 主界面菜单资产

用户提供的主界面素材共 8 张 PNG，原始像素和透明通道原样保留，统一归档在 `assets/art/ui/main_menu/`。中文原名、尺寸和 SHA-256 记录在 `assets/art/manifest.json`。菜单标题与按钮的白色文字直接沿用提供的图片。

`scenes/ui/main_menu.tscn` 按 1920×1080 参考画布布置。下表坐标为整张 PNG 的左上角，尺寸包含透明留白；所有图层共同等比缩放并居中，保持相对位置。背景与标题忽略鼠标输入，按钮的 300×60 区域接收点击。

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

菜单图片采用线性过滤、无损导入并关闭 mipmaps。替换素材时保持上述文件路径、画布和坐标关系；参考合成图与原始 ZIP 保留在项目外。

## 暂停界面资产

用户提供的暂停素材共 4 张 PNG，原始像素和透明通道原样保留，归档在 `assets/art/ui/pause_menu/`。中文原名、尺寸及 SHA-256 记录在 `assets/art/manifest.json`。按钮文字直接使用原图。

`scenes/ui/pause_menu.tscn` 按 1920×1080 参考画布布置。下表坐标为整张 PNG 的左上角，按钮点击区域为 390×80；素材共同等比缩放并居中。

| 原文件 | 项目文件 | 参考坐标（x, y） | 显示尺寸 |
| --- | --- | --- | --- |
| 暂停+透明背景.png | `pause_menu_overlay.png` | 0, 0 | 1920×1080 |
| 继续游戏.png | `pause_menu_resume.png` | 765, 437 | 390×80 |
| 主菜单.png | `pause_menu_main_menu.png` | 765, 527 | 390×80 |
| 退出游戏.png | `pause_menu_quit.png` | 765, 612 | 390×80 |

背景底板为 RGBA（26, 46, 101, 142）的半透明图片。运行时先保留并冻结当前游戏画面，通过 `shaders/pause_gaussian_blur.gdshader` 分别执行水平、垂直两遍高斯模糊，两遍之间使用全视口 `BackBufferCopy`；随后将原底板和按钮叠加在模糊画面上。底板透明度原样保留，按钮保持清晰。

暂停图片采用线性过滤、无损导入并关闭 mipmaps。更换素材时保留文件路径、画布、透明通道及坐标关系；原始 ZIP 留在项目外。图片、收集弹窗和水井解谜的 Esc 退出由原界面优先处理，暂停界面仅在一级游戏界面打开。

## 菜单悬停与按压

主菜单和暂停菜单共用用户提供的悬停 PNG，原图保存为 `assets/art/ui/panels/menu_hover_background.png`，原始像素与透明通道保持不变。`resources/art/ui/menu_hover_background.tres` 选取主体与柔光区域（176, 96, 1823, 514），隐藏透明画布留白。图片采用无损导入、线性过滤并关闭 mipmaps。

9 个现有 TextureButton 共用 `scripts/ui/menu_hover_button.gd`。背景在原文字下方绘制，主菜单显示 450×80、暂停菜单显示 585×106.67，居中于原按钮；文字、背景、标题、按钮坐标与点击区域沿用现有配置。悬停背景在 0.18 秒内淡入并轻微展开，移开在 0.14 秒内淡出。素材自身的半透明颜色原样保留。

按下时仅视觉层在 0.08 秒内缩至 97% 并下移 4 个参考像素，松开后 0.16 秒回弹。特效与文字子层均忽略鼠标输入。禁用的“继续游戏”沿用原外观与不可点击规则；切页、隐藏菜单、窗口移出时清理动画，返回与调整窗口尺寸后同步悬停位置。
