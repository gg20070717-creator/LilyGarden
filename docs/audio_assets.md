# 音频资源规范

本规范仅适用于 `D:/godot/demo/demo2`（Lunar）。开发约束见 [AGENTS.md](../AGENTS.md)，运行结构见 [架构说明](architecture.md)，完成状态见 [项目状态](project_status.md)，项目入口见 [README](../README.md)。图片和字体继续维护在美术规范，音频使用独立的目录及清单。

## 目录与来源

| 路径 | 职责 |
| --- | --- |
| `assets/audio/bgm/` | 项目实际引用的背景音乐原文件及 `.import` 设置 |
| `assets/audio/manifest.json` | 音频稳定 ID、原文件名、项目路径、格式、帧数、循环范围和 SHA-256 |
| `resources/audio/gameplay_bgm.tres` | Hide/SEEK 双 clip 与转换规则 |
| `scripts/audio/bgm_controller.gd` | 常驻 BGM 播放、场景状态切换、暂停和恢复 |

用户提供的微信来源文件原样复制到项目内，运行时全部使用 `res://` 路径。微信下载目录只作来源记录，不作为运行依赖。替换文件时保留稳定 ID 与引用路径，并更新 [音频清单](../assets/audio/manifest.json)；音频不写入 `assets/art/manifest.json`。

| 原文件 | 项目文件 | 稳定 ID | 用途 |
| --- | --- | --- | --- |
| `Hide.wav` | `assets/audio/bgm/hide.wav` | `bgm_hide` | 自由探索、普通查看和普通对白 |
| `SEEK.wav` | `assets/audio/bgm/seek.wav` | `bgm_seek` | 水井、鱼缸和洗笔桶的谜题、前置剧情、微剧情及 CG |

两份原文件各为 42,287,278 字节，格式为双声道 PCM32 WAV（`pcm_s32le`），采样率 48,000 Hz，均有 5,285,648 个采样帧，时长约 110.1176667 秒。原文件字节与 SHA-256 保留，具体校验值记录在音频清单。

## 导入与循环

两份 WAV 使用相同导入参数，保留 `.import` 文件随项目交付。项目 `.gitattributes` 将 `*.wav` 标记为 `binary`，WAV 按二进制资产随项目保留。

| 导入字段 | 当前值与含义 |
| --- | --- |
| `compress/mode` | `0`，无压缩运行 PCM16；源文件仍保留 PCM32 字节 |
| `edit/trim`、`edit/normalize` | 均为 `false`，不裁剪或归一化 |
| `force/8_bit`、`force/mono`、`force/max_rate` | 均为 `false`，不强制 8-bit、单声道或重采样 |
| `edit/loop_mode` | `2`，导入器的 Forward 循环选项 |
| `edit/loop_begin` | `0`，从首帧开始循环 |
| `edit/loop_end` | `-1`，全曲末尾；导入器映射至末帧 `5285647` |

导入器 `edit/loop_mode = 2` 与运行时 `AudioStreamWAV.loop_mode = 1` 都表示 Forward，各自枚举值不同，配置时按所在接口使用。当前两轨均使用 `begin 0 / end -1` 全曲循环；末帧索引为 `5285647`，原始总帧数为 `5285648`。替换时同步两条音轨的采样率、帧长、循环起止和音乐起点，避免裁剪、重采样或单独偏移某一轨。

相同采样帧数和循环参数支持同位置切换的配置，乐句与循环边界的听感仍需用户确认。静态格式及校验结果不作为无缝试听通过的结论。

## 播放与切换

`main.tscn` 的常驻 `BGM` 节点挂 `bgm_controller.gd`，使用单个 AudioStreamPlayer 播放 `AudioStreamInteractive`。同一资源的 clip 0 名为 `Hide`，clip 1 名为 `Seek`（原曲名 SEEK）；两个方向均配置 `IMMEDIATE + SAME_POSITION + FADE_CROSS`，保持当前位置切换。

`fade_beats = 0.03`。当前 WAV 无 BPM，该配置对应约 30 ms 的逐采样交叉平滑，用于切换瞬间衔接。默认音量为 `-6 dB`，由控制器导出属性调整，输出至 `Master` bus；当前没有独立音效系统或音量设置页。

| 时机 | 音乐行为 |
| --- | --- |
| 主菜单、整段开场、卧室淡入完成之前 | 不开始播放音乐；返回主菜单时已有会话的音频暂停 |
| 进入可自由操作的游戏界面 | 首次从 0 开始 Hide；继续会话时从暂停位置恢复 |
| 打开水井、鱼缸或洗笔桶谜题 | 同位置切换 SEEK，覆盖前置剧情、选碎片、填词、微剧情和 CG；微剧情读完回谜题时保持 SEEK |
| `return_started` 或 Esc 关闭谜题 | 同位置切回 Hide，后续普通对白保持 Hide |
| 普通收集、图片、对白、地点切换 | 保留当前 BGM 播放时间，不重新开始 |
| 暂停或返回主菜单 | 冻结音频时间；继续时恢复同一位置 |
| 新游戏 | 重建会话及 BGM，在开场和卧室淡入结束后从 0 开始 Hide |

控制器公开 `start_or_resume()`、`suspend()`、`set_puzzle_active(active)`、`stop()`，由菜单和常驻游戏协调调用。`main.gd` 的谜题白名单为 `well_memory`、`fish_tank_memory`、`brush_wash_memory`；洗笔桶前三句对白包含在谜题模态中，开始对白即切 SEEK。组合剧情沿用同一谜题模态：微剧情读完回选碎片时保持 SEEK，CG 返回探索时切回 Hide。新增地点和普通弹窗不另建 BGM 播放器；调整音乐语义时同步控制器、菜单生命周期、谜题状态与架构文档。

## 替换与验收

1. 使用用户确认的音频，按原字节归档，核对来源与项目副本的 SHA-256，并更新独立音频清单。
2. 成对核对采样率、声道、帧长、起点和循环范围，保留两条同位置切换的时间关系；同时维护双向转换规则。
3. 交付完整项目内 WAV、`.import`、资源和脚本，微信来源文件夹无需随游戏交付。
4. 原文件归档及参数已静态核对，三处组合剧情沿用已有音轨、音量和切换参数；未由 Codex 启动试玩、自动化测试或音频试听。当前音乐接入待用户试听，记录保持“听感待确认”；用户明确要求测试或修复 bug 时，再按受影响的状态与音频行为验证。
