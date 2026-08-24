# NyxNiri 第四轮调查：工具、系统命令与可见体验

更新时间：2026-08-23

本轮只调查 NyxNiri 项目本身的可见体验和可维护依赖边界，不修改当前系统配置，也不把当前系统的 DMS 方案直接搬进 NyxNiri。`niri`、`noctalia`、`Orbit` 是本项目的固定核心，本轮不评估替换它们。

## 结论摘要

1. **核心桌面栈不换。** Niri + Noctalia + Orbit 已经覆盖窗口管理、桌面 shell 和应用入口；换成 Waybar、Rofi、QuickShell、Vicinae 或其他启动器会制造第二套常驻 UI，收益小于冲突成本。
2. **优先增强现有工具链。** `eza`、`zoxide`、`fd`、`rg`、`fzf`、`yazi`、`btop`、`fastfetch`、`mpv`、`nvim` 已经形成合理基础。下一轮应该做主题同步、快捷入口和可靠降级，而不是继续堆工具。
3. **最值得默认引入的用户可见改进：** `yazi` 入口和 Fish `y` 回写目录、完整的 `eza` 别名、可选 `bat` 预览、`btop`/`duf` 入口、统一的 Fastfetch cyan/coral/amber 视觉、Noctalia OSD 的音量/亮度/媒体反馈，以及 Orbit 中可搜索的文件管理入口。
4. **只做可选集成的工具：** Atuin、Television、`git-delta`、`vivid`、`superfile`。它们有明显体验价值，但会增加状态、配置或重复功能；默认安装不符合 NyxNiri “低熵、可卸载”的原则。
5. **mpv 和 Nvim 采用 token bridge，不复制 DMS。** 读取 NyxNiri 的 `nyx-tokens.toml` 或 Noctalia 生成的 Kitty 主题，生成播放器和编辑器自己的 palette；缺少脚本、插件或 token 时仍回退到原生可用界面。

## 调查范围与证据

### 当前目录下的项目

已检查 `tools_and_themes/` 与 `thirdparty_os/` 中与桌面、终端和主题有关的项目，包括 LanRhyme-dotfiles、hyprvibe、huzch-nix-dotfiles、omarchy-glassmorphism、glasmorphism-arch-theme、Papirus、omarchy 等。

可迁移的具体模式：

| 来源 | 可见模式 | NyxNiri 适配结论 |
| --- | --- | --- |
| `LanRhyme-dotfiles` | `superfile` 主题、Chafa Fastfetch 图像 logo、按用途拆分的 Nvim/终端配置 | 可借鉴主题字段和图像展示；不复制 Morandi 配色、ChezMoi 部署或替代 Orbit 的入口 |
| `hyprvibe` | brightnessctl/DDC/CI 双路径、亮度菜单、媒体快捷键、模块化 OSD 脚本 | 亮度控制的硬件回退逻辑有价值；脚本需接入 Noctalia OSD，不能引入 Waybar/Hyprland 规则 |
| `huzch-nix-dotfiles` | QuickShell 音量 OSD、透明表面、媒体可视化 | 只借鉴 OSD 的尺寸、居中和淡入淡出层次；Noctalia 已负责常驻 shell，不增加 QuickShell |
| `omarchy-glassmorphism` | 集中式 colors、透明表面和状态栏层级 | NyxNiri 已有 `design/tokens.toml`，只吸收 surface/outline/shadow 的角色分工，不复制紫色主题 |
| `glasmorphism-arch-theme` | 模块 chip 固定宽度、网络/电池/媒体/天气/GPU 状态分层 | 可用于 Noctalia widget 的最小宽度和数值防跳动设计 |
| `Papirus` | GTK/Qt/文件管理器图标一致性 | 后续可加入图标/光标一致性检查；不把完整图标主题强制作为项目依赖 |
| `omarchy` | `btop`/Neovim 主题模板共享语义色，编辑器状态栏和诊断颜色有明确角色 | 适合 Nyx token 到 Nvim 的映射；不使用其发行版脚本或主题路径 |

### GitHub 与官方资料

Tavily 本轮额度/TLS 不可用，资料改用 GitHub API、官方仓库 README、官方文档和本机 Arch `pacman` 数据库交叉核对。

| 项目 | 调查到的能力 | 证据 |
| --- | --- | --- |
| eza | 颜色、图标、Git 状态、超链接、扩展属性；维护中的 `ls` 替代 | <https://github.com/eza-community/eza> |
| zoxide | Fish 集成，`z`/`zi`/`z -`，基于目录频率跳转 | <https://github.com/ajeetdsouza/zoxide> |
| Yazi | Kitty/Chafa/Sixel 预览、多标签、VFS、Trash、Git、插件和主题 | <https://github.com/sxyazi/yazi>；<https://yazi-rs.github.io/docs/quick-start/> |
| bat | 语法高亮、Git 修改标记；非交互管道自动退化为普通内容，可安全作为 fzf previewer | <https://github.com/sharkdp/bat> |
| Atuin | SQLite 历史、按目录/会话筛选、Fish Ctrl-R、可选加密同步 | <https://github.com/atuinsh/atuin> |
| Television | channel 化的文件/文本/Git 搜索、预览、Fish Ctrl-T/Ctrl-R、Nvim 插件 | <https://github.com/alexpasmantier/television> |
| btop | CPU、内存、磁盘、网络和 GPU 监控，支持主题 | <https://github.com/aristocratos/btop> |
| dust | 以树形百分比快速找大目录/文件 | <https://github.com/bootandy/dust> |
| duf | 磁盘使用表格、按终端宽度适配、主题和挂载点视图 | <https://github.com/muesli/duf> |
| git-delta | Git/diff/blame/grep 高亮、可导航 diff、主题和超链接 | <https://github.com/dandavison/delta> |
| vivid | `LS_COLORS` 主题生成，支持 ANSI/无真彩终端回退 | <https://github.com/sharkdp/vivid> |
| Kando | 圆盘菜单和桌面操作入口 | <https://github.com/kando-menu/kando>；仅作为 Orbit 设计对照，不引入 |
| mpv/uosc | proximity UI、可搜索菜单、timeline、音轨/字幕/播放列表/清晰度面板 | <https://github.com/tomasklaen/uosc> |
| thumbfast | 实时缩略图、混合宽高比和可选硬件解码 | <https://github.com/po5/thumbfast> |
| Snacks.nvim | Dashboard、Picker、Image、Notifier、Terminal、Scope 等可组合 UI | <https://github.com/folke/snacks.nvim> |
| mpv | `vo=gpu-next`、硬件解码、profile、字幕/音频语言和截图等原生配置能力 | <https://mpv.io/manual/master/> |
| Neovim | 颜色、浮窗、状态栏、诊断和终端 UI 都可由 Lua 独立控制 | <https://neovim.io/doc/user/> |

## 1. 当前工具的替代评估

### 固定不动

| 工具 | 结论 | 原因 |
| --- | --- | --- |
| Niri | 保留 | 项目配置、动画、动态工作区和 layer-shell 脚本都以 Niri 为前提 |
| Noctalia | 保留 | 负责 bar、OSD、锁屏、壁纸、主题和插件，是 Nyx token 的运行时出口 |
| Orbit | 保留 | 是项目的核心视觉入口，替换会破坏已有星环交互和快捷键 |
| Kitty | 保留 | 已有 Kitty 主题 include、Fish/Wayland/图片协议和 Scratchpad 集成 |
| Fish + Starship | 保留 | 已有交互补全、代理、包管理和 prompt 体系；替换 shell 没有足够用户收益 |
| fzf | 保留 | 已用于 `nyxhelp`、包搜索、历史、文件和 Git 操作；切换工具会造成键位与脚本迁移成本 |

### 默认增强候选

| 当前入口 | 候选/增强 | 用户能看到的收益 | 依赖与风险 | 决策 |
| --- | --- | --- | --- | --- |
| `ls` | eza 的 `ll`/`la`/`lt`/`l` 别名，保留纯 TTY 原生降级 | 文件类型、Git 状态、目录层级更容易扫读 | eza 已安装；不要覆盖脚本语义 | **默认引入** |
| `cd` | zoxide 的 `z`/`zi`，保留原生 `cd` | 常用项目目录少打字；`zi` 有可视候选列表 | 只在交互 Fish 初始化；不改脚本环境 | **默认引入** |
| 文件管理 | Yazi + 安全 `y` wrapper | Kitty 内预览图片/视频/代码、Trash、多标签和退出回写目录 | 配置默认部署；Yazi 包保持可选，无 Kitty/Chafa 时仍可文本浏览 | **默认入口，可选依赖** |
| `cat` | bat 的 `bathelp` 与 fzf preview，`cat` alias 只在 bat 存在时启用 | 读配置/代码有语法色和行号 | 本机包可用但当前未安装；管道必须保留原生行为 | **可选** |
| `top` | btop 快捷入口 | 资源、GPU、网络和进程状态更直观 | 配置默认部署；btop 包保持可选，只提供 `sys` 入口，不覆盖脚本 | **默认入口，可选依赖** |
| `df` | duf 入口 | 挂载点、容量和可用空间的可视表格 | 配置默认部署；duf 包保持可选，保留 `df` 回退 | **默认入口，可选依赖** |
| `du` | dust 入口 | 快速定位大目录/文件 | 未安装；适合 `disk`/`largest` 显式命令 | **可选** |
| Git diff | git-delta | diff 阅读、冲突和 blame 更容易扫读 | 未安装；全局 pager 是用户级行为，应在 opt-in 模块 | **可选** |
| `LS_COLORS` | vivid | eza/fd 等共享更细致的文件颜色 | 未安装；需避免与 Kitty/Noctalia palette 冲突 | **可选主题模块** |
| 历史搜索 | Atuin | Ctrl-R 可按目录、会话、成功状态搜索 | 约 33 MiB、SQLite、可选同步和隐私状态 | **可选，不进核心** |
| fzf | Television | channel、预览和 Fish Ctrl-T/Ctrl-R 一体化 | 与现有 fzf 重复；约 8 MiB，迁移脚本和键位有成本 | **调查保留，不替换** |
| fzf/Orbit | Vicinae/Kando | 桌面级 dmenu/圆盘入口 | 非核心依赖/包源状态不稳定，且与 Orbit 重复 | **不引入** |
| 文件管理 | superfile | 强主题化的全屏文件面板 | 约 19.5 MiB，与 Yazi 功能重叠 | **不作为默认** |

本机 Arch 包数据（2026-08-23）显示：`eza 0.23.5`、`zoxide 0.10.0`、`yazi 26.8.15`、`btop 1.4.7`、`fastfetch 2.67.1`、`mpv 0.41.0`、`neovim 0.12.4` 已安装；`bat 0.26.1`、`atuin 18.19.0`、`television 0.15.9`、`procs 0.14.12`、`dust 1.2.5`、`duf 0.9.1`、`git-delta 0.19.2`、`vivid 0.11.1`、`superfile 1.6.0` 在 `extra` 可用。`vicinae`、`kando` 和 `carapace` 未在本机同步包数据库中确认，不能作为核心依赖。

## 2. 操作系统默认命令替代清单

### 建议加入 NyxNiri Fish 的用户入口

```text
ls  -> eza --icons=auto
ll  -> eza -lah --group-directories-first --git
la  -> eza -a --icons=auto
lt  -> eza --tree --level=2 --icons=auto
z/zi -> zoxide（仅交互 Fish）
fm  -> yazi（可选，退出后回写目录）
sys -> btop
disk -> duf
largest -> dust（存在时）
```

推荐继续使用显式命令而不是全局 alias：

```text
grep -> rg
find -> fd
ps/top -> btop 或 procs
history -> fzf，Atuin 仅 opt-in
cat -> bat，仅交互终端和存在 bat 时
```

原因是 `grep`、`find`、`cat` 等经常出现在安装脚本、管道和第三方程序中；覆盖它们会带来脚本输出变化和纯 TTY 兼容问题。NyxNiri 目前已经正确区分交互 Fish 和 `TERM=linux`，新增入口必须保持这个边界。

## 3. 用户可见的进一步美化与加强

### 3.1 终端与 shell

当前 `configs/fish/config.fish` 只有基础 `ls -> eza`，而 `nyxhelp`、包搜索和 fzf 已经是较完整的交互基础。可见改进按优先级为：

1. 增加 `ll`、`la`、`lt`，并根据 Nerd Font/TTY 自动去除图标。
2. 仅在交互 Fish 中初始化 zoxide；提供 `z` 和 `zi`，不重写原生 `cd`。
3. 增加安全 `y` wrapper：执行 `yazi`，退出后读取其输出目录并 `cd`；没有 yazi 时不注册函数。
4. 为 `nyxhelp`、包搜索、文件预览统一使用 Nyx cyan/coral/amber，而不是当前混合的 magenta/emoji；纯 TTY 保留 ANSI 结构，不发送 Nerd Font 图标。
5. 增加 `sys`、`disk`、`fm` 等显式入口，避免用户记忆工具名。
6. 如果用户安装 bat，只注册 `bathelp` 和 fzf preview；不要强制把所有 `cat` 替换为 bat。

### 3.2 Fastfetch

当前 `configs/fastfetch/config.jsonc` 的 logo、标题和全部 key/title 都是 magenta，和 NyxNiri 已确定的 cyan/coral/amber/ink token 不一致。用户能直接看到的改进是：

- 将 logo/title/key 分为 `primary`、`secondary`、`tertiary` 三个角色色。
- 增加 `colors` 或一条轻量分隔线，避免大块单色。
- 使用存在时的 Kitty/Chafa 图片 logo；图片缺失时回退到小型文本 logo。
- 对窄终端设置更短的 key 和 `disableLinewrap`，避免启动信息换行。
- 保持信息量克制，不加入纯装饰模块。

### 3.3 Noctalia、Niri 和 Orbit

现有 Noctalia 已有透明 capsule、壁纸取色、`fancy_audio_visualizer`、媒体/音量/通知模块、锁屏和 OSD。可见增强建议：

- 把 OSD 的音量、亮度、护眼和媒体状态统一为 token 驱动的 compact surface，显示图标、数值和短时进度条。
- 参考 `huzch-nix-dotfiles` 的 200x60 左右居中 OSD 和淡入淡出，但颜色、圆角、间距读 Nyx token。
- 参考 `glasmorphism-arch-theme` 的固定最小模块宽度，避免电量、时钟、音量数值变化造成 bar 跳动。
- Orbit 增加 `Yazi`/`btop`/`fastfetch` 作为本地工具入口；保留现有搜索引擎和 Orbit 几何，不引入第二个 launcher。
- Noctalia 的动态 palette 继续覆盖运行时颜色；仓库 token 只作为缺省值，不把 GUI 写回源码。
- 屏幕阅读、无 Nerd Font、`NYXNIRI_REDUCED_MOTION=1` 和无 GtkLayerShell 时必须有静态/文本降级。

### 3.4 壁纸与媒体

当前 Wallpaper Picker 已有响应式网格、空状态、搜索和动态目录兼容；Noctalia `mpvpaper` 负责动态壁纸。下一步的可见增强应集中在：

- 卡片上显示静态/动态类型、分辨率和当前选中状态。
- 动态壁纸缩略图优先使用已有缓存，缺少 ffmpeg 时显示离线 SVG/文件类型占位，不阻塞选择器。
- 媒体播放器 mpv 与壁纸 mpvpaper 明确分开：前者允许完整 uosc，后者继续 `--config=no --load-scripts=no` 的轻量脚本模式。

## 4. mpv 适配方案（只针对 NyxNiri）

### 当前系统方案可以借鉴的部分

当前系统的 `uosc 5.12.0`、thumbfast、autoload、SponsorBlock、yt-dlp、Wayland、`gpu-next`、字幕/音轨快捷菜单已经验证过，适合提炼为“功能层”：

- proximity UI 和 searchable menu；
- timeline 缩略图；
- 播放列表、字幕、音频轨和清晰度可搜索面板；
- quality/performance profile；
- 保存位置、截图目录和字幕/音频语言优先级。

### 不能直接复制的部分

- `dank-theme.conf`、DMS dark rose 颜色和任何当前系统绝对路径；
- 绑定当前 GPU 的固定 `gpu-api=vulkan`/`hwdec=vaapi-copy` 作为所有机器默认；
- 把桌面 mpv 的脚本参数用于 Noctalia `mpvpaper`。

### NyxNiri 正确适配方式

1. 新增可选 `configs/mpv/` 模块，读取 `~/.config/kitty/current-theme.conf` 或 Nyx token 文件，生成 uosc 自己的 `uosc.conf` 颜色变量。
2. 颜色映射：`primary=cyan`、`secondary=coral`、`tertiary=amber`、`surface=ink`、`on_surface=text`，对亮色模式反转 surface/text。
3. 将 GPU/硬件解码做成能力探测 profile：检测 `mpv --gpu-context=help`、VA-API/Vulkan 可用性；检测失败时回退 `vo=gpu` 和软件解码，不让播放器启动失败。
4. uosc/thumbfast/yt-dlp 缺少时只关闭对应 UI/网络功能，保留 mpv 原生 OSC、播放列表和字幕。
5. `mpvpaper` 保持独立、无全局配置污染；现有 `mpv-hook.lua` 只负责 Noctalia 壁纸同步。

## 5. Nvim 适配方案（可选模块）

NyxNiri 当前没有独立 Nvim 配置目录，因此不应为了“工具更多”强行把 LazyVim、Snacks、Blink、Mason 等全部纳入核心。用户可见价值足够高时，建议作为独立可选模块：

1. 读取 Nyx token 或 Kitty `current-theme.conf`，生成 base16-ish palette；不依赖 DMS 的颜色名和路径。
2. 仅在已有插件存在时启用 Snacks Dashboard/Picker、rounded float、通知、诊断和 Lualine 主题；插件缺失时回退原生 Nvim。
3. Dashboard 显示项目、最近文件、Git 状态和启动时间，但窄终端切换 vertical picker，避免布局挤压。
4. 统一 `NormalFloat`、`FloatBorder`、`Pmenu`、`CursorLine`、诊断虚拟文本、Lualine/Bufferline 的角色色。
5. 加入 CJK 字体 fallback 和无真彩终端检查；不要把当前系统的 `dank-material`、`~/.config/kitty/dank-theme.conf` 或 DMS 热更新监听复制过来。
6. 如果采用 Snacks，优先复用已有 Snacks 能力，不再同时引入 Telescope、nvim-notify、独立 dashboard 等重复 UI。

## 6. 实施优先级

### P0：下一轮可以直接实现

- Fish `ll/la/lt`、交互式 zoxide、可选 Yazi `y` wrapper。
- Orbit 本地工具入口：Yazi、btop、Fastfetch。
- Fastfetch 从单一 magenta 改成 Nyx token 角色色，并加入窄终端/缺图回退。
- Noctalia OSD 的固定尺寸、数值防跳动和音量/亮度/媒体状态统一。
- `nyxhelp` 的颜色和纯 TTY 降级统一。

### P1：验证依赖后实现

- `configs/mpv/` 可选模块：uosc + thumbfast + Nyx token bridge、GPU 能力 profile、原生 OSC fallback。
- `configs/nvim/` 可选模块：token bridge、Snacks/Lualine/浮窗角色色、无插件 fallback。
- Yazi 主题文件与 Nyx token 的生成/同步。
- btop/duf 主题或启动入口。

### P2：保持 optional，不默认安装

- bat、dust、git-delta、vivid、Atuin、Television、superfile。
- procs 只作为 btop 之外的进程查看器，不覆盖 `ps`。
- Vicinae、Kando 等桌面 launcher 不引入，以免和 Orbit/Noctalia 形成重复常驻组件。

## 7. 验证与风险边界

- 每个新增命令都必须有 `command -v` 判断和纯 TTY/无 Nerd Font 降级。
- Fish wrapper 不得改变非交互 shell、脚本或管道输出。
- 新的主题同步只能写入用户运行时目录，不能把 GUI 生成状态回写 Git 工作树。
- mpv 的桌面播放和 mpvpaper 动态壁纸必须分离测试。
- Nvim 只能在实际存在的插件上启用增强，不得让主题缺失阻塞编辑器启动。
- 现有静态验证仍需执行：`compileall`、`bash -n`、`shellcheck`、`git diff --check`、沙箱部署和 Niri validate。
- GTK layer-shell 真实 UI QA 当前环境仍缺 `GtkLayerShell` typelib；在安装该运行时之前，视觉结论只能标记为 `NOT RUN`，不能用静态检查代替。

本轮调查没有修改当前系统，也没有替换 NyxNiri 的 Niri、Noctalia 或 Orbit。下一轮进入实现时，应按 P0 -> P1 顺序逐项提交并为每个用户可见行为保留回滚路径。

## 本轮执行记录

用户随后要求直接实现所有与现有功能不重复的 P0/P1/P2 项，本轮已完成以下可见功能：

- Fish：`l/ll/la/lt`、交互式 zoxide、Yazi `y/fm` 目录回写、`sys/disk/largest/gdiff/bathelp` 显式入口和缺失工具回退。
- Fastfetch/Starship：从单色 magenta 改为 Nyx cyan/coral/amber/ink 角色色。
- Orbit：新增 `Workspace Tools` 子菜单，提供 Yazi、btop、Fastfetch、duf/disk、Nyx MPV 和 Nyx Nvim 入口。
- Yazi：新增 Nyx 配置和主题；btop：新增 Nyx 配置和主题；vivid：新增 `LS_COLORS` 主题。
- mpv：新增隔离的 `mpv-nyx` profile、uosc 颜色、质量/性能 profile、键位和可选脚本发现器；与 mpvpaper 保持独立。
- Nvim：新增隔离的 `nvim-nyx` profile，包含 Nyx token 读取、主题、dashboard、浮窗、诊断和基础快捷键。
- 主题同步：Noctalia theme hook 会在存在 mpv-nyx 时刷新 uosc palette；缺失目录时静默跳过。
- 部署：新增模块均进入选择性部署发现、原子复制、可执行权限处理和契约校验；可单独部署，不会要求未选中的 Niri/Noctalia 配置。
- 验证：8/8 项目契约测试通过，Python/Fish/Bash/ShellCheck/TOML/YAML 检查通过，沙箱部署通过，隔离部署后的 Niri validate 通过；Yazi 和 btop 在 120×40 伪终端中均产生真实渲染流后退出。

GTK layer-shell 真实 Wayland 截图仍因环境缺少 `GtkLayerShell` typelib 标记为 `NOT RUN`，没有用静态检查冒充视觉 PASS。
