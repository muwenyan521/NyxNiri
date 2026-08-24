<a id="readme-top"></a>

<div align="right">
  <a href="README.md">English</a> | <strong>简体中文</strong>
</div>

<div align="center">

<h1>NyxNiri</h1>

<p><strong>基于 Niri 与 Noctalia V5 的 Material You 桌面体验</strong><br />
<sub>适用于 Arch Linux / CachyOS</sub></p>

<p>
  <a href="https://github.com/ech678/NyxNiri/stargazers"><img height="22" src="https://m3-markdown-badges.vercel.app/stars/3/3/ech678/NyxNiri" alt="Stars" /></a>
  &nbsp;
  <a href="https://archlinux.org"><img height="22" src="https://ziadoua.github.io/m3-Markdown-Badges/badges/Arch/arch2.svg" alt="Arch Linux" /></a>
  &nbsp;
  <a href="LICENSE"><img height="22" src="https://ziadoua.github.io/m3-Markdown-Badges/badges/LicenceGPLv3/licencegplv33.svg" alt="GPL-3.0" /></a>
</p>

<a href="https://github.com/user-attachments/assets/9ef4da30-54c0-491b-916f-2f2a3beac6be">
  <img src="https://github.com/user-attachments/assets/9ef4da30-54c0-491b-916f-2f2a3beac6be" alt="NyxNiri 预览" width="92%" />
</a>

<p>
  <sub><em><a href="https://nyxniri.com">官网</a> · 观看 <a href="https://www.bilibili.com/video/BV1c63n6dEEG">Bilibili 演示</a> · 参与 <a href="https://www.reddit.com/r/niri/comments/1vf53le/nyxniri_a_material_you_desktop_config_for_niri/">Reddit 讨论</a></em></sub>
</p>

</div>

## 个人偏好改版说明

这个仓库是我基于 NyxNiri 按个人使用习惯整理的一套配置。当前改动集中在
Nyx token 配色、Shorin Niri 快捷键、终端反馈降噪，以及 Kitty、Yazi、btop、
mpv、Neovim 和 Zed 的独立配置。Niri、Noctalia、Orbit 仍然是核心组件；这
是一套偏好配置，不代表上游默认方案。部署到其他机器前，请先检查对应配置。

## 特性

- 壁纸选择器（`Super+Alt+W`）— 聚合静态与动态壁纸，支持实时搜索与分类。
- 壁纸选择器会按屏幕空间自适应 2–4 列；空目录、空分类和无结果搜索都有明确提示。
- 壁纸色彩联动 — Noctalia V5 直接从壁纸取色；`mpvpaper` 配合 `ffmpeg` 抽取视频帧，动态壁纸亦实时生成调色板。
- 明暗模式同步 — GSettings、GTK 3/4、XDG Desktop Portal、Kitty 终端以及浏览器（Brave、Chromium、Firefox）即时跟随主题变化。
- 护眼模式（`Super+Shift+N`）— 调暖色温、关闭模糊、纯色不透明背景。
- Scratchpad 终端（`Super+~` 或 `Super+/`）— 随时快捷呼出 Kitty 持久浮动终端。
- Orbit 启动器（`Super+Alt+Z` / `Super+鼠标前侧键`）— 矢量星环启动器，聚合应用、工具、网页与 AI/搜索引擎轮盘（全 TOML 自定义）。
- 终端与 Shell — Fish 代理/缓存别名，Kitty 光标轨迹，Windows 风格快捷键。
- 个人偏好层 — 代理状态显式探测、精简 Git prompt、scrollback 工具、GPU 可选 btop 布局、Yazi 快捷键，以及 Nyx 风格编辑器/媒体配置。
- NyxMellow 动态 fcitx5 皮肤 — mellow 圆角形状，随 Noctalia 自动取色。
- 视觉系统 — `DESIGN.md` 和 token 文件集中定义颜色、间距、圆角与动效；设置 `NYXNIRI_REDUCED_MOTION=1` 可关闭动态过渡。

## 环境要求

- Arch Linux / CachyOS
- [Niri](https://github.com/YaLTeR/niri)（Wayland 合成器）
- [Noctalia V5](https://github.com/noctalia-dev/noctalia)（桌面 Shell，官方仓库）
- `mpvpaper`（AUR）、`kitty`、`fish`、`starship`、`tmux`

## 安装

> [!IMPORTANT]
> **从旧版 Bash 目录（`lib/` + `v2/`）升级：**旧版 `nyxniri update` 无法直接切换到新版 Python 目录。更新前请先运行一次新版引导：
> ```bash
> curl -fsSL --connect-timeout 10 https://raw.githubusercontent.com/ech678/NyxNiri/main/install.sh | bash
> ```
> 如果想先检查脚本，可先下载再运行：
> ```bash
> curl -fsSL --connect-timeout 10 -o /tmp/nyxniri-install.sh https://raw.githubusercontent.com/ech678/NyxNiri/main/install.sh
> bash /tmp/nyxniri-install.sh
> ```
> 迁移不会删除现有配置、`~/.config/NyxNiri/backups/`，也不会删除旧版 `~/.config/dotfiles_backup_*` 快照。

### 独立在线安装

```bash
curl -fsSL --connect-timeout 10 https://raw.githubusercontent.com/ech678/NyxNiri/main/install.sh | bash
```

### 从 Git 仓库安装（推荐）

```bash
# 浅克隆：仅拉取最新快照（约 9MB）；如需完整历史去掉 --depth 1
git clone --depth 1 https://github.com/ech678/NyxNiri.git ~/NyxNiri
cd ~/NyxNiri && ./install.sh
```

<details>
<summary>国内镜像加速 (gh-proxy / CDN)</summary>

```bash
# 通过 gh-proxy.org 独立安装
curl -fsSL --connect-timeout 10 https://gh-proxy.org/https://raw.githubusercontent.com/ech678/NyxNiri/main/install.sh | bash

# 通过 gh-proxy.org 克隆仓库
git clone --depth 1 https://gh-proxy.org/https://github.com/ech678/NyxNiri.git ~/NyxNiri
cd ~/NyxNiri && ./install.sh
```

拉取仓库时，`install.sh` 会先尝试 GitHub，再尝试 gh-proxy。
</details>

> [!NOTE]
> 缺少 AUR helper 时，`nyxniri install full` 可以安装 `paru`；交互部署默认先在 `~/.config/NyxNiri/backups/` 创建快照。旧版 DMS 保留在 `archive/v1-dms` 分支。

## 包含配置

```text
NyxNiri
├── install.sh                  # 极简引导入口脚本
├── nyxniri/                    # 纯 Python 核心运维引擎 (零 pip 依赖)
├── assets/                     # 静态资产 (壁纸库、NyxMellow 输入法皮肤模板)
└── configs/
    ├── niri/                   # 窗口管理器 (.kdl, .toml)
    │   └── scripts/            # Orbit 启动器、壁纸选择器与 Scratchpad 脚本
    ├── noctalia/               # 桌面 Shell 与主题同步
    ├── xdg-desktop-portal/     # Portal 路由 (Settings 主题与录屏分流)
    ├── kitty/                  # 终端
    ├── fish/                   # 别名与函数
    ├── fastfetch/              # 系统信息
    ├── yazi/                   # 文件管理器主题与预览默认值
    ├── btop/                   # 系统监视器主题
    ├── vivid/                  # 共享文件颜色主题
    ├── mpv-nyx/                # 隔离的 Nyx mpv 配置
    ├── nvim-nyx/               # 隔离的 Nyx Neovim 配置
    ├── bin/                    # Shorin-contrib 命令组件（部署到 ~/.local/bin）
    ├── zed/                    # 编辑器
    └── starship.toml           # 提示符
```

> [!NOTE]
> 更新时采用原子替换。个人改动通过 Dunder 协议保留：
> - 含 `*__custom__*` 的文件自动保留（如 `01__custom__.kdl`，数字前缀控制加载顺序）
> - 含 `*__custom__*` 的目录整体保留（如 `~/.config/niri/__custom__/`）
> - `~/.config/niri/monitor.kdl` 在部署时保留

## 工具

`nyxniri` 用于管理安装、快照和系统诊断：

> 旧版 Bash 用户需先运行上面的新版引导，再使用以下命令；旧版 `nyxniri update` 无法完成目录迁移。

| 指令 | 作用 |
| :--- | :--- |
| `nyxniri` | 交互式菜单 |
| `nyxniri install [full\|config]` | 全量部署，或仅同步配置 |
| `nyxniri update [--force|--no-deploy]` | 更新源码，并强制部署或跳过配置部署 |
| `nyxniri snapshot [备注]` | 保存当前配置快照 |
| `nyxniri snapshot delete [序号]` | 删除快照（未指定序号则可批量勾选） |
| `nyxniri rollback [序号]` | 恢复历史快照 |
| `nyxniri list` | 查看快照列表 |
| `nyxniri uninstall` | 归档当前配置并卸载；交互模式也可选择复原 |
| `nyxniri purge` | 清除配置、快照、缓存与壁纸 |
| `nyxniri doctor` | 依赖与系统健康检查 |
| `nyxniri deps` | 打开依赖检查与安装菜单 |
| `nyxniri apps` | 常用软件安装菜单（Nautilus、Mission Center、Fcitx5 雾凇拼音） |
| `nyxniri wallpapers` | 从外部仓库下载全套壁纸与动态视频包 |
| `nyxniri theme [toggle\|dark\|light\|sync\|status]` | 切换或同步系统深浅主题 |
| `nyxniri bug` / `nyxniri report` | 生成诊断报告 |
| `nyxniri test` | 开发者实机测试部署（不备份、保留 monitor.kdl） |
| `nyxniri fcitx [install\|status\|uninstall]` | NyxMellow fcitx5 皮肤 |
| `nyxniri greeter [install\|status\|uninstall]` | Noctalia Greeter（登录界面） |

`nyxhelp` 是基于 `fzf` 的简明速查，覆盖 CLI、Shell 助手和核心快捷键：

| 指令 | 作用 |
| :--- | :--- |
| `nyxhelp` | 双栏交互式速查菜单 |
| `nyxhelp keys` | Niri 快捷键 |
| `nyxhelp proxy` | 代理控制（`proxy_on [port]`、`proxy_off`、`proxy_status`） |
| `nyxhelp pkg` | 包管理快捷指令（`up`、`in`、`se`、`un`、`clean`） |
| `nyxhelp all` | 完整速查手册 |

Shorin-contrib 命令组件会作为显式命令部署到 `~/.local/bin`，例如
`preview`、`lsi`、`timer`、`procusage`、`pac`、`pacr`、`pak`、
`quicksave`、`quickload`、`sysup`、`shorin-clean` 以及媒体处理工具。
它们不会覆盖 `ls`、`cat`、`ps` 等 Shell 基础命令。

## 快捷键

<details>
<summary>窗口控制</summary>

| 快捷键 | 动作 |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Enter</kbd> | 打开终端 |
| <kbd>Super</kbd> + <kbd>Q</kbd> | 关闭窗口 |
| <kbd>Super</kbd> + <kbd>T</kbd> | 打开 Kitty 终端 |
| <kbd>Super</kbd> + <kbd>V</kbd> | 切换浮动/平铺 |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>T</kbd> | 平铺/浮动层焦点穿透切换 |
| <kbd>Super</kbd> + <kbd>X</kbd> | 切换标签页列模式 (Tabbed Group) |
| <kbd>Super</kbd> + <kbd>F</kbd> | 最大化当前列 |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>F</kbd> | 全屏 |
| <kbd>Super</kbd> + <kbd>Tab</kbd> | 工作区总览 |
| <kbd>Super</kbd> + <kbd>H</kbd> / <kbd>L</kbd> | 聚焦左/右侧列 |
| <kbd>Super</kbd> + <kbd>方向键</kbd> | 焦点移动（跨列 / 跨屏 / 跨工作区） |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>方向键</kbd> | 移动窗口（跨列 / 跨屏 / 跨工作区） |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>方向键</kbd> | 本地微调移动（含列内窗口上下调位） |
| <kbd>Super</kbd> + <kbd>D</kbd> / <kbd>U</kbd> | 向右移动窗口 / 聚焦上方工作区 |
| <kbd>Super</kbd> + <kbd>Space</kbd> | 切换预设列宽比例 |
| <kbd>Super</kbd> + <kbd>-</kbd> / <kbd>=</kbd> | 收缩/拉伸列宽 |

</details>

<details>
<summary>系统与组件</summary>

| 快捷键 | 动作 |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Z</kbd> | 启动器 |
| <kbd>Super</kbd> + <kbd>E</kbd> | Yazi 文件管理器 |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>X</kbd> | 电源菜单 |
| <kbd>Super</kbd> + <kbd>F2</kbd> | 控制中心 |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>V</kbd> | 剪贴板 |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>W</kbd> | 壁纸选择器（静态与动态） |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>W</kbd> | 免打扰随机切换壁纸 |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>N</kbd> | 护眼模式 |
| <kbd>Super</kbd> + <kbd>~</kbd> / <kbd>Super</kbd> + <kbd>/</kbd> | 切换 Kitty Scratchpad 浮动终端 |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>Z</kbd> / <kbd>Super</kbd> + <kbd>鼠标前侧键</kbd> | Orbit 矢量星环启动器 |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>L</kbd> | 锁屏 |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> | 截图 |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>R</kbd> | 重载 Niri |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>E</kbd> | 退出 Niri |

</details>

> [!TIP]
> 快速查看：`nyxhelp keys`。Niri 的完整按键覆盖层请按 <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>/</kbd>。

## 可选模块

**NyxMellow fcitx5 皮肤：** 圆角 mellow 风格，随 Noctalia 自动提取配色并同步明暗。`nyxniri fcitx install` 注册为模板并随主题自动重绘；按需启用，不覆盖现有配置。

<p align="center">
  <img src="https://github.com/user-attachments/assets/3f861e8e-55da-408e-a9d5-7f337a039b74" alt="NyxMellow 皮肤（亮色）" width="48%" />
  <img src="https://github.com/user-attachments/assets/291918e9-4532-480f-b777-7ebe0691eaf9" alt="NyxMellow 皮肤（暗色）" width="48%" />
  <br />
  <sub><em>NyxMellow 皮肤亮色 / 暗色效果</em></sub>
</p>

**壁纸与动态视频包：** 高清壁纸与动态视频（约 100MB）独立存放于 [wallpaper-collection](https://github.com/ech678/wallpaper-collection) 仓库。`install` 时可选拉取，或随时通过 `nyxniri wallpapers` 按需下载。

**Noctalia Greeter：** 与 Noctalia 主题一致的 greetd 登录界面。`nyxniri greeter install` 安装 `greetd` + `noctalia-greeter`（AUR）、备份现有配置并配置 Polkit 规则；不禁用已有显示管理器。

## 故障排除

<details>
<summary><b>Noctalia 启动卡死</b> — 多为 <code>ddcutil</code> 扫描 I2C 总线超时（NVIDIA 常见）。</summary>

在 `~/.config/noctalia/noctalia-config.toml` 中禁用 `ddcutil`：

```toml
[brightness]
enable_ddcutil = false
```

</details>

<details>
<summary><b>插件仓库损坏</b> — Noctalia 拉取插件卡住。</summary>

运行以下命令重置插件仓库：

```bash
git -C ~/.local/state/noctalia/plugins/sources/community/repo reset --hard HEAD
git -C ~/.local/state/noctalia/plugins/sources/official/repo reset --hard HEAD
```

</details>

<details>
<summary><b>Greeter 同步需要输密码</b> — 添加 Polkit 免密规则（<code>nyxniri greeter install</code> 会自动写入）。</summary>

如需手动添加 Polkit 规则：

```bash
sudo bash -c 'cat > /etc/polkit-1/rules.d/50-noctalia-greeter.rules << EOF
polkit.addRule(function(action, subject) {
    if (action.id == "org.noctalia.greeter.apply-appearance" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF'
```

</details>

<details>
<summary><b>Nautilus 或 Libadwaita 应用白屏 / 深色模式失效</b> — 旧 CSS 覆盖了系统主题。</summary>

如果此前开启过 Noctalia 自带的 GTK 模板或其他美化工具，会在 `~/.config/gtk-4.0/` 生成 `noctalia.css` 或 `gtk.css`，GTK4 会无条件优先加载该文件并写死白色背景。

运行主题同步或手动删除残留的覆盖文件：

```bash
nyxniri theme sync
# 或手动删除：
rm -f ~/.config/gtk-4.0/gtk.css ~/.config/gtk-4.0/noctalia.css ~/.config/gtk-3.0/gtk.css ~/.config/gtk-3.0/noctalia.css
```

</details>

## 致谢与社区

**联系与社区：**

- TG 频道：[@linux_ricing](https://t.me/linux_ricing)
- QQ：`2040244628`
- Linux Ricing 交流群：`631425889`
- 赞助支持：[爱发电](https://afdian.com/a/Echoes678)
- 问题反馈：[GitHub Issues](https://github.com/ech678/NyxNiri/issues)

**协助与鸣谢：**

- [@zhuhuaian](https://github.com/zhuhuaian) · [@Krits03](https://github.com/Krits03) · [@Yulljie](https://github.com/Yulljie) — 社区管理与情感支持
- [@TyhLxxxhLrqTq](https://github.com/TyhLxxxhLrqTq) — 配套壁纸站支持（开发中）

**致谢：**

- [RanXom/glassy-niri](https://github.com/RanXom/glassy-niri) — 参考了 blur 效果
- [SHORiN-KiWATA/shorin-niri](https://github.com/SHORiN-KiWATA/shorin-niri) — 抄了很多！
- [sanweiya/fcitx5-mellow-themes](https://github.com/sanweiya/fcitx5-mellow-themes) — NyxMellow 皮肤圆角形状的来源
- [StarWhiteIsBusy/Round-Simple-Fcitx5-Skin](https://github.com/StarWhiteIsBusy/Round-Simple-Fcitx5-Skin) — Noctalia 取色联动方案参考
- [doctorlogix](https://github.com/doctorlogix) — 官网网页设计借鉴与参考

**推荐项目：**

- [h465855hgg/noctalia-lyrics](https://github.com/h465855hgg/noctalia-lyrics) — 状态栏歌词组件
- [Ocfeather/chrome-niri-opacity](https://github.com/Ocfeather/chrome-niri-opacity) — 浏览器透明度脚本

---

<div align="right">
  <a href="#readme-top">↑ 返回顶部</a>
</div>
