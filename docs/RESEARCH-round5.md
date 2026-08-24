# NyxNiri 第五轮调查：Dotfiles 深度审计与 GitHub 对照

更新时间：2026-08-24

本轮只调查 NyxNiri 仓库内的 dotfiles，以及 GitHub 上当前仍在维护的官方仓库和成熟 Niri 配置。没有写入当前系统的 `~/.config`，没有替换 `niri`、`noctalia` 或 `Orbit`，也没有把其他项目的完整主题方案直接搬进 NyxNiri。

## 结论先行

NyxNiri 现在的基础已经完整：Niri 负责滚动平铺和窗口规则，Noctalia 负责 bar、OSD、壁纸、锁屏和主题运行时，Orbit 负责桌面级入口，Fish、Kitty、Yazi、btop、mpv-nyx、nvim-nyx 和 Zed 各自有清晰边界。GitHub 对照没有发现需要更换核心栈的理由。

本轮真正值得继续做的是以下六组用户可见改进：

1. **Niri 窗口规则补齐应用族和多显示器体验。** 官方默认配置与成熟 dotfiles 都把 Picture-in-Picture、Steam 对话框、屏幕录制/密码管理器遮挡、截图路径和多显示器移动作为显式规则；NyxNiri 已有不少窗口规则，但仍可把这些规则整理成独立、可审计的“通用规则”和“机器私有规则”。
2. **Noctalia OSD 与 bar 的信息反馈更完整。** 当前只显式关闭了 media/nightlight 两类 OSD；上游当前 schema 仍提供 volume、volume-input/output、brightness、wifi、bluetooth、power-profile、caffeine、DND、privacy、keyboard-layout 等可见状态。建议只打开实际需要的几类，避免通知噪声。
3. **Yazi 采用官方可覆盖交互。** 上游默认已经提供 `spot`、`fzf`、`zoxide`、linemode 切换和完整 MIME 预览入口。NyxNiri 当前的三栏、size linemode 和 Chafa 预览是合理的，但应补一个小型 `keymap.toml`，只覆盖 Nyx 需要的跳转、回收站和 spot，不引入 superfile。
4. **Kitty 补齐 shell integration 与 scrollback 体验。** 当前关闭了 Kitty shell integration，只保留 `no-cursor`；这会牺牲 cwd、滚动回看和跳转能力。建议启用 `enabled` 或 `no-cursor` 的最小模式，并配置有限的 scrollback/search，保持当前 Windows 风格复制键位。
5. **mpv-nyx 与 uosc 使用上游的新配置面。** 现有 token、进度条、菜单搜索和 quality/performance profile 已经可用；建议继续补 `progress`/`autoload`/`thumbnail` 的条件显示、Wayland 能力探测和字幕/音轨菜单，不复制当前系统的 DMS 路径或固定 GPU 参数。
6. **nvim-nyx 的文件查找和 Zed 的主题是下一批高收益点。** `<Space>ff` 当前调用 `:find **/*`，依赖 Vim 的 `path`/shell 语义，中文路径和大型目录下不如 `vim.fs.find` 或可选 `mini.pick` 稳定；Zed 仍使用 One Light/VSCode Dark Modern，没有接入 Nyx token，视觉上是仓库内最明显的断层。

这些建议都可以在现有部署引擎内以独立配置单元落地，回滚边界清楚。Atuin、Television、superfile、Vicinae、Kando、Waybar、Rofi、QuickShell 等不应进入核心：它们与 fzf、Yazi、Noctalia 或 Orbit 重复，或者会新增常驻状态。

## 1. 调查范围与方法

### 本地仓库

逐项读取了以下范围：

- Niri：`configs/niri/config.kdl`、`layout.kdl`、`rules.kdl`、`animations.kdl`、`effects_*.kdl`、`monitor.kdl`、`binds.kdl`、`nyx-tokens.toml`、`scripts/`。
- Noctalia：`configs/noctalia/noctalia-config.toml`、三个 shell hook、`mpv-hook.lua`。
- 终端和 shell：Fish 配置/插件/补全、Starship、Kitty 和动态 Kitty 主题、Fastfetch。
- 终端应用：Yazi、btop、vivid、mpv-nyx、nvim-nyx、Zed。
- 主题与部署：`design/tokens.toml`、部署/备份/诊断代码、已有 `docs/RESEARCH.md`、Shorin 命令和快捷键迁移结果。
- 当前工作树：保留已有 dirty worktree；本轮没有触碰当前系统配置。

### GitHub 官方仓库快照

以下仓库在 2026-08-24 通过 GitHub API 和浅克隆读取默认分支源码。短 SHA 用于复查，链接指向仓库和对应项目文档/示例：

| 仓库 | 调查快照 | 关注内容 |
| --- | --- | --- |
| [YaLTeR/niri](https://github.com/YaLTeR/niri) | `dd75865f547f` | 当前默认 `config.kdl`、window/layer rule、overview、hotkey overlay、截图和多显示器动作 |
| [noctalia-dev/noctalia-shell](https://github.com/noctalia-dev/noctalia-shell) | `a4324409f4f0` | TOML schema、bar capsule、OSD kind、panel placement、theme hook |
| [sxyazi/yazi](https://github.com/sxyazi/yazi) | `519939b5ab9c` | `yazi-default.toml`、`keymap-default.toml`、`theme-dark.toml`、spot/fzf/zoxide/linemode |
| [kovidgoyal/kitty](https://github.com/kovidgoyal/kitty) | `c3d36a3dfeb6` | shell integration、scrollback、tab、Wayland 和 remote-control 配置 |
| [tomasklaen/uosc](https://github.com/tomasklaen/uosc) | `d124c2c930d6` | `uosc.conf` 的 timeline/progress/menu/proximity/scale/color 能力 |
| [aristocratos/btop](https://github.com/aristocratos/btop) | `76e323ddc1ca` | GPU box、preset、theme 目录和 truecolor 行为 |
| [fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch) | `e7ecba4460e1` | `display.disableLinewrap`、separator/color、模块格式 |
| [starship/starship](https://github.com/starship/starship) | `0b48f454da65` | `scan_timeout`、`right_format`、palette、条件模块 |

工具层还复核了 [mpv](https://github.com/mpv-player/mpv)、[Neovim](https://github.com/neovim/neovim)、[folke/snacks.nvim](https://github.com/folke/snacks.nvim)、[po5/thumbfast](https://github.com/po5/thumbfast)、[zed-industries/zed](https://github.com/zed-industries/zed)、Fish、eza、zoxide、bat、vivid、git-delta 的当前文档/仓库入口。

### 成熟 dotfiles 对照

- [saatvik333/niri-dotfiles](https://github.com/saatvik333/niri-dotfiles) `2b00970f04e7`：规则覆盖、Picture-in-Picture、Steam toast、截图键位和低噪声的多类窗口匹配。
- [Vantesh/dotfiles](https://github.com/Vantesh/dotfiles) `2b59d52ec9d3`：Matugen 模板化和集中 token 的思路，但其 chezmoi/DankMaterial 运行时不适合直接复制。
- [tonybanters/niri-btw](https://github.com/tonybanters/niri-btw) `33d8c723b982`：接近官方默认的 Noctalia + Niri 最小配置，适合作为字段兼容性对照。
- [okyashgajjar/Low-Spec-Niri-Dotfiles](https://github.com/okyashgajjar/Low-Spec-Niri-Dotfiles) `dd7ff0b02333`：低规格机器的动画、亮度、idle 和主题切换降级。
- [SirineZanina/niri-dotfiles](https://github.com/SirineZanina/niri-dotfiles) `75f71e9a33a6`：Noctalia v5、Yazi keymap、btop、截图和可见状态的完整用户路径。

当前目录下还对照了 `LanRhyme-dotfiles`、`hyprvibe`、`huzch-nix-dotfiles`、`omarchy-glassmorphism`、`glasmorphism-arch-theme`、`Papirus` 和 `Shorin-ArchLinux-Guide`。这些项目提供了主题角色、OSD 尺寸、图标一致性和低规格降级的参考，但没有一个应该整体替换 NyxNiri 的部署或桌面栈。

## 2. 本地 Dotfiles 审计

### 2.1 Niri

当前配置的优点：

- `config.kdl` 已拆分 monitor/effects/input/layout/animations/rules/binds，部署时保留 `__custom__`，便于从 Shorin 迁移快捷键。
- `overview`、`recent-windows`、`prefer-no-csd`、cursor、截图路径和 `honor-xdg-activation-with-invalid-serial` 已显式设置。
- `rules.kdl` 已覆盖 Noctalia bar/wallpaper、mpvpaper、Steam toast、Wine、浏览器 PiP、播放器、游戏和 scratchpad。
- `effects_normal.kdl`/`effects_eyecare.kdl` 与 `toggle-eyecare.sh` 有持久状态和恢复逻辑，不需要额外常驻守护进程。

可见缺口和风险：

- `rules.kdl` 同时包含通用窗口行为、特定应用美化和机器/地区相关应用（QQ、Ente、Mission Center、Wine）。用户在另一台机器上看到的结果可能不一致。建议将规则按“通用可见规则 / 可选应用规则 / 本机私有规则”拆成 include 单元，默认只启用前两类。
- 官方默认配置明确展示了 `block-out-from "screen-capture"`、Firefox PiP、Wayland portal、截图和 monitor movement；NyxNiri 尚未提供一套可选的录屏隐私规则和显式多显示器快捷键说明。建议加为 `__custom__` 示例或可选规则，不默认遮挡用户窗口。
- `overview.workspace-shadow off` 与 `layout.kdl` 的窗口圆角/透明规则是有意的 Nyx 风格，但 `background-effect { blur true }` 的应用范围较宽。低功耗档位应能一次关闭 blur，而不是逐个应用改规则。
- `cursor` 固定 `Adwaita` 24。成熟配置通常把 cursor theme/size 作为环境可覆盖项；建议加入 `NYXNIRI_CURSOR_THEME`/`NYXNIRI_CURSOR_SIZE` 的部署占位或文档入口，不绑定当前机器的图标主题。
- `monitor.kdl` 保持用户配置是正确的，但应增加部署前 `niri msg outputs` 对照提示，避免把旧输出名带入新机器。

### 2.2 Noctalia

当前 `noctalia-config.toml` 的可见结构是合理的：透明 bar capsule、clock 居中、media/tray/wallpaper/mpvpaper/volume/notifications/session 组合，壁纸取色为 `m3-content`，theme hooks 连接 Kitty/GTK/mpv-nyx，panel 位置和 session action 都明确。

上游 schema 对照结果：

- `control_center_placement`、`control_center_position`、`settings_show_advanced`、`capsule_padding`、`capsule_radius`、`wallpaper_scheme` 和 `theme_mode_changed`/`wallpaper_changed` 仍是当前支持字段，不需要因为旧文章而重写。
- 当前上游 OSD kind 比本地显式配置更多：volume、volume input/output、brightness、wifi、bluetooth、power profile、caffeine、DND、lock keys、keyboard layout、media、privacy、keyboard backlight。`media=false` 和 `nightlight=false` 不是字段过时，而是当前主题的主动降噪选择。
- `fancy_audio_visualizer` 仍是上游桌面 widget，并且要求 PipeWire spectrum；当前无背景、wave rings 的配置可以保留。缺失 PipeWire 时应有静态空状态，不应阻塞 shell 启动。

建议：

1. 默认打开 `brightness`、`volume-output`、`power-profile` 和 `privacy` OSD；`media`、`keyboard-layout`、`wifi` 按实际硬件和通知频率再决定。
2. 为 bar 的动态数值设置固定最小宽度或短格式，避免音量、电量、时钟变化造成 capsule 跳动。参考 `glasmorphism-arch-theme` 的固定 chip 宽度思路，但不复制其 CSS。
3. 保留 `background_opacity=0.0` 的透明 bar；通过 capsule opacity、outline 和 Nyx token 提升层次，不要再叠一套常驻 Waybar。
4. `brightness.enable_ddcutil=false` 只适合当前默认。已有 Niri media key 是 `ddcutil -> brightnessctl` 回退，Noctalia 设置应说明 DDC-capable 外接显示器的可选打开方式。
5. `lockscreen_widgets.enabled=false` 是低噪声选择；若启用，只放时钟、电量和网络三个信息，避免把控制项堆到锁屏。

### 2.3 Fish、Starship、Fastfetch、Kitty

Fish 当前已经有 eza 的 `l/ll/la/lt`、zoxide、Yazi `y/fm`、btop/duf/dust/procs/bat/delta 显式入口和纯 TTY 降级，命令不覆盖脚本中的 `ls/cat/ps` 语义。这是正确边界。

仍可改进的用户可见点：

- `proxy_status` 每次执行会做多个外部连通性检查；建议把网络探测改为显式 `proxy_status --check`，默认只显示当前变量/端点，减少 prompt 或帮助菜单等待。
- Starship 的 `git_status` 被关闭，而当前 prompt 已显示 branch。建议在 dirty 仓库时显示最小 `+/-/?` 状态，干净仓库不增加噪声；同时设置较短的 `scan_timeout`，避免大型仓库卡住 prompt。
- Fastfetch 已有 cyan/yellow 角色色和 system/hardware 分组；上游新增的 `display.disableLinewrap`、separator color 和窄终端示例值得采用。当前 GPU 模块虽显示，但 btop 的主布局仍是 `cpu mem net proc`，GPU 监控需要明确作为可切换 preset，而不是只在配置里写 `show_gpu_info=Auto`。
- Kitty 当前 `shell_integration no-cursor`、`cursor_trail 1`、透明背景和动态 theme include 已形成视觉风格，但没有滚动回看、搜索或 tab bar 约束。建议启用最小 shell integration，增加 `scrollback_lines`、`kitten show_scrollback`/search 入口，并保留现有 Ctrl+C/Ctrl+V/字体缩放键位。
- Fish 插件只有 Fisher、autopair.fish、fzf.fish，依赖边界很干净。Atuin 或 Television 不应同时加入；若将来试用，只能作为独立 opt-in profile。

### 2.4 Yazi、btop、vivid

Yazi 当前 `ratio=[1,3,4]`、natural sort、size linemode、hidden/symlink 可见、MIME opener 和 Chafa 预览已经比默认更适合 Nyx。上游默认 keymap 提供：

- `<Tab>` spot 文件；
- `z`/`Z` 通过 fzf/zoxide 跳转；
- `m,s`/`m,p`/`m,b`/`m,m`/`m,o`/`m,n` 切换 size/permissions/btime/mtime/owner/none；
- `,s` 等排序快捷键和内置 trash/bulk rename 流程。

建议只增加 `configs/yazi/keymap.toml` 的小覆盖：`Tab=spot`、`Z=zoxide`、一个 Nyx 约定的 `g` 跳转组，以及与 Fish `y` wrapper 一致的退出回写说明。不要复制外部 dotfiles 的整套 keymap，也不要引入 superfile。

btop 的 truecolor、透明背景、rounded corners、block graph 和 Nyx theme 已完成。上游 README 明确说明 GPU box 通过 `5`-`0` 切换，主题可以放在 `$XDG_CONFIG_HOME/btop/themes`；建议增加一个带 `gpu0` 的可选 preset，并确认二进制编译时启用了 GPU support。不要把 GPU 设为所有机器的强制依赖。

vivid 主题已存在，建议补全压缩包、媒体、设备、socket、权限和链接状态的映射，并让 `TERM=linux`/无真彩终端自动退回 ANSI 基础色。eza、Yazi、Kitty 三者的目录/链接颜色应继续共用 Nyx role，而不是各写一套近似色。

### 2.5 mpv-nyx

当前 profile 隔离是正确设计：`run.sh` 使用独立 `--config-dir`，uosc/thumbfast/autoload/sponsorblock 只有文件存在时才加载，mpvpaper 仍保持自己的轻量配置。现有 uosc 已使用 Nyx token、progress bar、菜单搜索、右侧音量、quality/performance profile 和原生 OSC fallback。

GitHub 上游 `uosc.conf` 还提供：

- `progress=always` 的细进度条与 `timeline_style=line`；
- 通过 `<video,audio>`、`<has_playlist>`、`<stream>` 条件显示控件；
- `menu_type_to_search=yes`、`menu_min_width`、`scale_fullscreen`、`proximity_in/out`；
- `autoload`、目录播放、playlist/chapters/stream-quality/open-file 菜单；
- thumbfast 的缩略图和混合宽高比支持。

NyxNiri 下一步应优先做：字幕/音轨语言顺序的可覆盖变量、无 GPU/无 thumbfast 时的启动诊断、窗口/全屏两套 scale，以及 `autoload` 的显式开关。继续保持 `mpvpaper` 与桌面 mpv 分离，不把 uosc 或 yt-dlp 参数写进 Noctalia 壁纸插件。

### 2.6 nvim-nyx 与 Zed

nvim-nyx 的 token bridge、浮窗、诊断角色色、dashboard 和无插件启动路径是好的低依赖基线。当前唯一明显的功能缺口是：

```text
<Space>ff -> :find **/*
```

它依赖 `path` 和 shell 风格 glob，不如 `vim.fs.find()` 对中文路径、隐藏目录和大型仓库稳定。建议实现一个原生 Lua picker：优先 `vim.ui.select`/`vim.fs.find`，检测到 `mini.pick` 或 Snacks 时才启用增强 UI，否则保持当前无插件路径。

可见主题层还可以补 `Pmenu`、`FloatTitle`、`WinBar`、diagnostic virtual text、diff/add/change/delete 和 inactive pane 的角色色。不要为一个独立 profile 强制引入 LazyVim、Telescope、Mason、Lualine 和 Snacks 全家桶。

Zed 当前的字体回退、右侧 terminal、VSCode keymap 和 AI 关闭设置都很实用，但 theme 仍是 One Light/VSCode Dark Modern，和 Nyx token 脱节。建议把 Zed 作为独立 P1：

1. 生成一个最小 Nyx theme extension 或本地主题文件，只覆盖 editor background、panel、border、accent、diagnostics、terminal ANSI；
2. `theme.mode=system` 继续保留，light/dark 分别绑定 Nyx light/dark；
3. 不把 Zed AI/agent 面板重新打开，不把当前系统的 DMS 绝对路径复制过来。

## 3. GitHub 成熟配置的可迁移内容

| 来源 | 实际可见做法 | NyxNiri 结论 |
| --- | --- | --- |
| `saatvik333/niri-dotfiles` | PiP 浮动、Steam toast 不抢焦点、截图三键、隐私 screen-capture rule、GPU/低规格开关 | **可迁移**为 Nyx 的可选 Niri 规则和文档示例 |
| `Vantesh/dotfiles` | Matugen 生成 Kitty/GTK/编辑器多个目标的同一 palette | **可借鉴**“一个 palette、多出口”；使用 Nyx token/Noctalia hook，不引入 Matugen/chezmoi |
| `tonybanters/niri-btw` | 接近官方默认的 Noctalia v5 schema 和 Niri 配置 | **作为兼容性基线**，不复制其快捷键 |
| `Low-Spec-Niri-Dotfiles` | 动画、壁纸、亮度和 idle 的低规格 fallback | **可迁移** `NYXNIRI_REDUCED_MOTION`、无 ffmpeg/无 GPU 降级 |
| `SirineZanina/niri-dotfiles` | Noctalia、Yazi keymap、btop、截图和应用列表协同 | **可迁移** Yazi 小覆盖和状态栏信息分组，不复制 stow/主题 |
| `LanRhyme-dotfiles` | Yazi/superfile 主题、Chafa logo、按用途拆开的 Nvim | **只取预览和模块化边界**，不引入 superfile |
| `hyprvibe` | brightnessctl/DDC 两级回退、媒体/亮度 OSD | **可取回退逻辑**，显示仍交给 Noctalia |
| `huzch-nix-dotfiles` | 居中 OSD、透明 surface、媒体可视化 | **可取尺寸/层次**，不引入 QuickShell |
| `omarchy-glassmorphism` / `glasmorphism-arch-theme` | surface/outline/shadow 角色、固定 chip 宽度 | **与 Nyx tokens 同方向**，只吸收几何与信息密度 |
| `Papirus` | GTK/Qt/文件管理器图标一致性 | **作为可选图标一致性检查**，不成为核心依赖 |

没有发现这些项目中存在比 NyxNiri 更适合当前约束的整体方案。尤其是 Waybar、Rofi、Vicinae、Kando 和 QuickShell 都会与现有 Noctalia/Orbit 形成第二套入口或常驻 UI。

## 4. 优先级建议

### P0：可直接带来明显用户收益

- 为 `rules.kdl` 增加可选的 PiP/Steam toast/屏幕录制隐私规则，并把 QQ/Wine/Ente 等机器相关项隔离。
- Noctalia 开启并验证 `volume-output`、`brightness`、`power-profile`、`privacy` OSD kind；保留 media/nightlight 的低噪声决策。
- 添加最小 `yazi/keymap.toml`：spot、zoxide、linemode 和 Nyx 跳转组。
- Kitty 开启最小 shell integration，增加 scrollback/search；确认不影响当前 Ctrl+C/Ctrl+V 和 Shorin 快捷键。
- Fastfetch 增加 `disableLinewrap` 和 separator role；btop 增加 GPU 可选 preset。

### P1：需要真实运行环境验证

- mpv-nyx：Wayland/GPU 能力探测、全屏 scale、autoload 和字幕/音轨菜单；同时测试无 uosc、无 thumbfast、无 yt-dlp 三种降级。
- nvim-nyx：用 `vim.fs.find`/`vim.ui.select` 替换 `:find **/*`，补 diff/float/diagnostic 角色色。
- Zed：独立 Nyx theme extension 或仓库内主题文件，light/dark 与 Noctalia mode 对齐。
- Noctalia：固定 widget 最小宽度、锁屏只读信息 widget、外接显示器 DDC 可选路径。
- vivid：补全文件类型和权限状态映射，并做 16 色/无 Nerd Font 终端检查。

### P2：保持可选，不进入核心依赖

- Atuin：历史数据库和同步状态与现有 fzf.fish 重复。
- Television：channel 化搜索很强，但会替换现有 fzf 习惯并增加另一套预览/键位。
- git-delta、bat、dust、procs：继续作为 Fish 显式入口或 opt-in，不覆盖 `cat`、`ps`、`du` 的脚本语义。
- superfile：与 Yazi 功能重叠。
- Vicinae/Kando/Rofi/Wofi/Fuzzel/Waybar/QuickShell：与 Orbit 或 Noctalia 形成常驻入口冲突。
- Matugen/Wallust：Nyx 已有 token loader 和 Noctalia palette hook；引入第二个生成器会增加主题竞态。

## 5. 明确不建议的方向

- 不替换 Niri、Noctalia、Orbit。
- 不把当前系统 DMS/dank-material 的绝对路径、监听脚本、主题文件名和固定 GPU 参数复制进 NyxNiri。
- 不把当前机器的 `monitor.kdl`、私有应用 app-id、壁纸目录或字体路径写成不可覆盖默认值。
- 不为了“看起来更完整”添加常驻 daemon、第二个 launcher、第二个文件管理器或第二套 notification/OSD。
- 不用静态 PTY 输出冒充 GTK layer-shell/真实 Wayland 视觉通过；当前环境缺少 `GtkLayerShell` typelib，视觉 QA 仍应标记 `NOT RUN`。

## 6. 建议实施时的验证矩阵

| 层级 | 必须观察的结果 |
| --- | --- |
| 语法 | `compileall`、`bash -n`、Fish parse、TOML/JSON/YAML/KDL 检查通过 |
| 部署 | 只通过 NyxNiri deployment engine，目标为隔离 `HOME`；检查原子复制、可执行位、backup/rollback |
| Niri | `niri validate` 通过；检查 include、window/layer rule 和绑定无重复 |
| Fish | 交互 Fish 中 `l/ll/la/lt`、`z/zi`、`y/fm`、`sys/disk` 可用；非交互 shell 不被 alias 污染 |
| Yazi/btop | 120x40 PTY 真实启动、预览/主题加载、退出回写目录和 GPU 缺失降级 |
| mpv | 原生 OSC、uosc、无脚本 profile、quality/performance、截图和 Wayland/GPU fallback |
| Nvim/Zed | 无插件启动、中文路径、浮窗/诊断/主题、Zed light/dark 和终端字体回退 |
| 视觉 | Noctalia bar/OSD、Orbit、Wallpaper Picker 的真实 Wayland/GTK 路径；GtkLayerShell 缺失时记录 `NOT RUN` |
| 回滚 | 修改前 hash、modified artifact、patch/diff、baseline/modified 命令及 literal output、可执行 rollback 均可重放 |

## 7. 本轮产物与状态

- 本报告：`docs/RESEARCH-round5.md`。
- 本轮只新增调查报告，没有修改当前系统配置，也没有改写 NyxNiri 既有 dotfiles。
- GitHub 官方快照、成熟 dotfiles 快照和本地文件范围已在报告中记录，后续实施可按优先级逐项引用。
- 当前项目已有的静态检查、沙箱部署、Niri validate、Fish/Bash/Python/ShellCheck、命令 `--help` 和 PTY 证据沿用上一轮记录；GTK layer-shell 真实截图仍为 `NOT RUN`，不能升级为 PASS。

