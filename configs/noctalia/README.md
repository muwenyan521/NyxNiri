# Noctalia 主题适配 (Theme Adaptation)

> 本目录是 NyxNiri 主题系统的物理归属，包含调度脚本、配置模板、
> hook 脚本和 GTK Material You 模板。本文档记录架构设计、遇到过的
> 所有问题及其解决方案，供未来维护参考。

---

## 1. 架构总览 (Architecture Overview)

应用要知道"现在是深还是浅"，有三条信息源，互不替代：

| 信号路径 | 机制 | 谁在用 | 时机 |
|---|---|---|---|
| Portal `color-scheme` | gsettings → xdg-desktop-portal → `AdwStyleManager` | Nautilus 等 GTK4/libadwaita | 实时（portal 信号） |
| `settings.ini` `prefer-dark-theme` | `theme-sync.sh` 写入 → `GtkSettings` 读取 | Brave 等 Chromium | 启动时读一次 |
| `gtk-theme-name` 切换 | gsettings `gtk-theme` → `adw-gtk3(-dark)` | GTK3 老应用 | 启动时 + gsettings 信号 |

此外还有 **gtk.css（M3 配色）**：由 Noctalia 渲染到 `~/.config/gtk-{3,4}.0/gtk.css`，
GTK3 热重载，GTK4 靠 `@media (prefers-color-scheme)` 实时切换。

---

## 2. 组件清单 (Components)

```
configs/noctalia/
├── README.md              ← 本文档
├── theme-sync.sh          ← 调度中枢（深浅切换时运行）
├── noctalia-config.toml   ← hook + user template 注册
├── wallpaper-hook.sh      ← 壁纸切换 hook（视频缩略图）
├── mpvpaper-sync.sh       ← mpvpaper 视频壁纸同步
└── templates/
    ├── gtk-3.0.css        ← GTK3 M3 模板（无条件 @define-color）
    └── gtk-4.0.css        ← GTK4 M3 模板（双 @media 块）
```

### theme-sync.sh — 调度中枢

`theme-sync.sh` 在深浅切换时运行，按 step 1-9 执行：

| Step | 职责 | 说明 |
|---|---|---|
| 1 | 可覆盖变量 | `NYXNIRI_GTK_THEME_DARK` 等环境变量 |
| 2 | 并发锁 | `flock` 防止快速 toggle 竞争 |
| 3 | `atomic_update_ini` | 原子写 INI，含 regex 特殊字符转义 |
| 4 | `set_system_theme` | gsettings / dconf 双路径降级 |
| 5 | 模式解析 | `toggle` / `dark` / `light` / hook 环境变量 |
| 6 | gsettings 广播 | `color-scheme` + `gtk-theme` 立即广播 |
| 7 | settings.ini 同步 | 写入 `gtk-{3,4}.0/settings.ini` |
| 8 | 热重载 | Kitty `SIGUSR1` + Kvantum |
| 9 | 交互反馈 | 终端运行时打印结果 |

### noctalia-config.toml — 注册中心

- **hook 注册**：`theme_mode_changed` → `theme-sync.sh`
- **hook 注册**：`wallpaper_changed` → `wallpaper-hook.sh`
- **user template 注册**：`nyxniri_gtk3` / `nyxniri_gtk4`
- `/home/user` 占位符由 `nyxniri.deploy` 在部署时替换为实际 `$HOME`

### templates/gtk-3.0.css — GTK3 M3 模板

无条件 `@define-color`。GTK3 不用 `@media`，靠 `gtk-theme-name` 在
`adw-gtk3` / `adw-gtk3-dark` 之间切换。换壁纸时 Noctalia 重新渲染，
GTK3 应用热重载 CSS。

### templates/gtk-4.0.css — GTK4 M3 模板

**双 `@media (prefers-color-scheme: dark/light)` 块**（核心设计，见 §4）。
同一个文件同时输出 dark 和 light 两套 M3 配色，由 GTK4 运行时根据
portal `color-scheme` 选择。

### wallpaper-hook.sh — 视频壁纸缩略图

`wallpaper_changed` hook。视频壁纸无法直接取色，用 `ffmpeg` 提取首帧
作为缩略图喂给 Noctalia 的 Material You 算法。

### mpvpaper-sync.sh — mpvpaper 同步

视频壁纸分配与主题联动，依赖 `jq` / `ffmpeg` / `inotifywait`。

### niri config.kdl 中的主题相关配置

`configs/niri/config.kdl` 的 `spawn-at-startup` 中有一项与主题相关：

- **`spawn-at-startup "bash" "-c" "sleep 8; ..."`**
  冷启动后 Noctalia 需要时间算壁纸调色板。8 秒后强制重新渲染 gtk.css，
  确保 Nautilus 等 GTK4 应用尽快加载到 M3 配色（而非 libadwaita 默认外观）。

---

## 3. 信号流图 (Signal Flow)

```
nyxniri theme toggle / dark / light
        │
        ▼
theme-sync.sh
        │
        ├─ step 6: gsettings color-scheme + gtk-theme  ← 立即广播
        │     │
        │     ├─ Brave (Chromium 114+): 读 portal color-scheme
        │     │    → 冷启动后需按钮唤醒（见 Problem 11），唤醒后实时跟随 ✅
        │     ├─ Firefox: 读 portal color-scheme → 秒跟 ✅
        │     ├─ Kitty: 不读 gsettings，靠 step 8 SIGUSR1 → 秒跟 ✅
        │     └─ Nautilus (GTK4/libadwaita): 读 portal → AdwStyleManager
        │          → @media CSS 重求值 → 即时切换 ✅
        │
        ├─ step 7: settings.ini 写入 (prefer-dark-theme + gtk-theme-name)
        │     └─ Brave (Chromium): 启动时读一次（冷启动兜底）
        │
        ├─ step 8: pkill SIGUSR1 kitty + Kvantum
        │
        └─ Noctalia 自动 (~6s)
              │
              └─ gtk.css 重渲染 (M3 配色)
                    ├─ GTK3: 热重载 CSS
                    └─ GTK4: @media 已在内存中，深浅即时切；
                             M3 配色值更新需重启
```

**关键**：
- gsettings/portal 信号是**立即**的，深浅模式（明暗）秒跟。
- gtk.css（M3 自定义颜色）由 Noctalia **~6s** 自动渲染。
- Nautilus 靠 `@media` CSS 即时切换深浅，M3 配色值更新需重启。

---

## 4. GTK4 @media 双块设计 (Dual-Block Design)

### 遇到的问题

`gtk-4.0.css` 原本用无条件 `@define-color` 写死颜色：

```css
@define-color window_bg_color  #131318;  /* dark 值，永远生效 */
```

libadwaita 的 `AdwStyleManager` 读 portal `color-scheme` 切深浅，但它自身
的 `libadwaita.css` 用 `@media (prefers-color-scheme)` 包裹颜色定义（159 个
`@media` 块）。我们的无条件 `@define-color` 覆盖了 libadwaita 的 `@media` 块：

- portal 说"现在是 light"
- `AdwStyleManager` 切了它自己的运行时状态
- 但 `window_bg_color` 仍是 `#131318`（dark）—— 因为无条件定义优先级高于 `@media`
- Nautilus 读 `window_bg_color` 画窗口背景 → 永远 dark

### 为什么不是 `prefer-dark-theme` 的锅

最初怀疑 `gtk-4.0/settings.ini` 的 `gtk-application-prefer-dark-theme` 干扰了
libadwaita。实机验证推翻了这个假设：

1. 删掉该 key 后 Nautilus **仍不跟**（视觉卡 dark）
2. 真正起作用的是把 `gtk.css` 改成 `@media` 双块
3. 该 key 只产生一条 `Adwaita-WARNING`（cosmetic，不影响功能）
4. 但 Brave 依赖该 key 检测暗色 → **不能删**

### 解决方案

把所有 M3 `@define-color` 和 widget 规则包进两个 `@media` 块：

```css
@media (prefers-color-scheme: dark) {
    @define-color window_bg_color  {{ colors.background.dark.hex }};
    /* widget rules with .dark. colors */
}

@media (prefers-color-scheme: light) {
    @define-color window_bg_color  {{ colors.background.light.hex }};
    /* widget rules with .light. colors */
}
```

Noctalia 模板引擎支持 `.dark.` / `.light.` 两种模式取色
（见 Noctalia 文档 `05_THEMING_PALETTES_AND_TEMPLATES.md` §3.2）。
一个文件同时输出两套配色，由 GTK4 运行时 `@media` 选择。

模式无关的部分留在 `@media` 外：
- 语义色（`warning_color`、`success_color` 等）
- GTK3 legacy 命名色（`theme_bg_color` 等，GTK4 不读）
- M3 调色板参照色（`STRAWBERRY`、`BLUEBERRY` 等）
- shade/shadow（`rgba(0,0,0,...)` 固定值）

---

## 5. settings.ini Key 保留决策

### 为什么留着 deprecated key

`gtk-application-prefer-dark-theme` 在 GTK4 标记为 deprecated，libadwaita
会打印 warning。但：

1. **Brave (Chromium 114+) 启动时通过 `GtkSettings` 读该 key 做冷启动兜底**
2. 删掉后 Brave 冷启动时可能无法正确检测暗色
3. warning 是 cosmetic，不影响 libadwaita 功能
4. libadwaita 靠 portal `color-scheme` + `@media` CSS，不依赖该 key

### 鲁棒性分析

- **key 被 GTK 移除** → 写入变 no-op，Brave 那条路失效，
  Nautilus 不受影响（单点失效不崩）
- **Brave 未来改读 portal** → key 变 no-op，留着重启无影响
- **两套机制独立**：Nautilus 走 `@media`，Brave 走 `settings.ini`，
  任一失效另一个不受影响

---

## 6. 问题与解决全记录 (Problem Log)

### Problem 1: `nyxniri theme toggle` 不广播 gsettings

- **症状**：toggle 后 Chrome/Edge/Brave/Kitty 深浅色不跟随
- **根因**：`toggle` 分支调用 `noctalia msg theme-mode-toggle` 后直接
  `exit 0`，跳过 `set_system_theme`、INI 同步、kitty reload
- **修复**：toggle 后 `sleep 0.3` → 读回新 mode → 继续跑完整 sync 流程
- **状态**：已解决

### Problem 2: `theme-sync.sh` step 8 有害（config-reload + templates-apply）

- **症状**：gtk.css 渲染错色（切 light 时仍为 dark 配色）+ 调色板更新延迟翻倍
- **根因**：hook 在 Noctalia 调色板重算**之前**触发，`templates-apply` 用旧
  调色板渲染。且 `config-reload` 会拖慢 Noctalia 调色板更新（从 ~6s 拖到
  12-20s）
- **修复**：移除 step 8。Noctalia 调色板更新后会自动渲染 user templates
  （实测 ~6s），无需手动触发
- **状态**：已解决

### Problem 3: GTK Material You 模板未部署

- **症状**：`templates-apply` 不碰 gtk.css
- **根因**：工作树的 `noctalia-config.toml` GTK 注册块 + `templates/` 目录
  从未通过 `nyxniri install config` 部署到实机。`templates-apply` 不碰
  gtk.css 是因为 toml 里没注册，不是缓存 bug
- **修复**：部署 toml + 模板目录，注册后 `templates-apply` 完全正常
  （0.023s 重渲染，无占位符残留）
- **状态**：已解决

### Problem 4: `atomic_update_ini` 未转义 regex 特殊字符

- **症状**：key 含 `.`、`[` 等 regex 特殊字符时 `[[ =~ ]]` 匹配失败
- **修复**：key 经 `sed 's/[][\.^$*+?(){}|/]/\\&/g'` 转义后再用于匹配
- **状态**：已解决

### Problem 5: Nautilus (GTK4/libadwaita) 深浅模式不跟随

- **症状**：切换 dark↔light 后，Nautilus 窗口一直保持 dark，重启才跟
- **误判过程**：
  1. 怀疑 `gtk-4.0/settings.ini` 的 `prefer-dark-theme` 干扰 libadwaita
  2. 删除该 key → Nautilus 仍不跟（视觉卡 dark）
  3. 但 Brave 不跟了（回归）
- **真根因**：`gtk-4.0.css` 用无条件 `@define-color` 写死 dark 颜色，
  覆盖了 libadwaita 自身的 `@media (prefers-color-scheme)` 块
- **修复**：`gtk-4.0.css` 重构为双 `@media (dark/light)` 块，
  用 Noctalia `.dark.` / `.light.` 取色
- **教训**：删 `prefer-dark-theme` 前未验证 Brave 依赖 → 回归。
  最终方案：保留 key（喂 Brave）+ `@media` CSS（喂 Nautilus），双保险
- **状态**：已解决

### Problem 6: Brave (Chromium) 深浅模式不跟随

- **症状**：删除 `prefer-dark-theme` 后 Brave 不跟随深浅切换；恢复 key 后
  Brave 只在启动时跟随，toggle 时不实时变色
- **根因**：Brave 通过 `GtkSettings` 读 `prefer-dark-theme` 检测暗色。
  `GtkSettings` 只在启动时读 `settings.ini`，运行中不监视文件变化。
  `settings.ini` 中的 `gtk-modules=colorreload-gtk-module` 不可靠
  （GTK3 不会自动读该 key 加载模块）
- **修复**：
  1. 恢复向 `gtk-4.0/settings.ini` 写入 `prefer-dark-theme`（启动时跟随）
  2. （未采用）曾考虑在 niri config `environment` 加
     `GTK_MODULES "colorreload-gtk-module"`，但反编译验证该模块只监视
     `~/.config/gtk-3.0/colors.css`，不读 `settings.ini`，对 Brave 无用，
     从未加入 config.kdl
- **状态**：部分解决。`prefer-dark-theme` 解决冷启动跟随（启动读对深浅）；
  toggle 实时跟随未解决，见 Problem 11

### Problem 7: Noctalia 调色板更新延迟 ~6 秒

- **症状**：模式切换后，gtk.css（M3 配色）约 6 秒后才更新
- **根因**：Noctalia 调色板重算本身需要时间（壁纸 Material You 算法），
  这是 Noctalia 固有速度，NyxNiri 侧无法再快
- **状态**：可接受。深浅模式立即跟，M3 颜色 6 秒跟

### Problem 8: `gtk uninstall` 不持久

- **根因**：GTK 模板注册写在源 `noctalia-config.toml`，每次 `nyxniri install`
  会重新部署并自动重渲染。`nyxniri gtk uninstall` 从已部署的 toml 删除注册
  并删 gtk.css，但下次 install 会完全恢复
- **对比**：fcitx/greeter 在安装时动态写入 toml，卸载是持久的
- **状态**：可接受。核心特性定位下不影响功能

### Problem 9: `gtk-3.0.css` 含 GTK4 专有属性 `transform`

- **症状**：Brave 报 `Theme parsing error: 'transform' is not a valid property`
- **根因**：从 HyprYou `gtk3.scss` 展平时没删干净，`transform` 是 GTK4 专有
- **修复**：删除 `gtk-3.0.css` 中 `scale.marks-after slider` 的
  `transform: none`。`gtk-4.0.css` 保留该属性（GTK4 需要）
- **状态**：已解决

### Problem 10: 重启后 Nautilus 延迟显示 M3 主题

- **症状**：重启电脑后 Nautilus 显示 libadwaita 默认外观（adw），过一会儿
  或手动 toggle 后才变成 M3 主题
- **根因**：冷启动时 Noctalia 需要时间算壁纸调色板，gtk.css 在渲染完成前
  不存在或为旧内容。Nautilus 启动时加载到空/旧 CSS → 显示默认外观。
  Noctalia 渲染完成后不会主动通知 Nautilus 重新加载 CSS
- **修复**：niri config 加 `spawn-at-startup "bash" "-c" "sleep 8;
  noctalia msg config-reload && noctalia msg templates-apply"`，
  冷启动 8 秒后强制重新渲染 gtk.css。但 Nautilus 仍需一次 toggle 或重启
  才能加载新 CSS（GTK4 不热重载 CSS 文件）
- **状态**：部分解决（gtk.css 更快就绪，但 Nautilus 仍需 toggle 触发 CSS 重载）

### Problem 11: Brave (Chromium) toggle 时不实时变色

- **症状**：`nyxniri theme toggle` 后 Nautilus 秒跟，但 Brave 不变色，需重启
- **调查**：
  - Chromium 114+ 官方用 XDG Desktop Portal `color-scheme` 检测暗色
    （[ArchWiki](https://wiki.archlinux.org/title/Chromium#Dark_mode) 确认），
    dissociated from GTK theme
  - `theme-sync.sh` step 6 已 `gsettings set color-scheme` → portal 广播
    `SettingChanged`，portal 值正确（`uint32 1` = dark）
  - NyxNiri 侧信号链路正确，问题在 Brave 自身
  - `colorreload-gtk-module`（`kde-gtk-config` 包）经反编译验证只监视
    `~/.config/gtk-3.0/colors.css`，不读 `settings.ini`，对 Brave 无用，
    从未加入 config.kdl
- **根因**：Brave 在非 GNOME 的 Wayland 复合器（如 Niri）上冷启动时，
  portal `SettingChanged` 信号订阅未正确初始化。这是 Brave/Chromium
  自身的冷启动 bug，不是 NyxNiri 的信号链路问题。
  实测直接 `gsettings set org.gnome.desktop.interface color-scheme`（绕开
  theme-sync.sh）Brave 亦不变色——gsettings 值正确变化、portal 信号确实
  发出，但 Brave 不处理；偶尔跟一次是 portal 订阅 race 命中，不可靠。
  v2.3.3 时代 Brave 版本能稳定处理 gsettings 信号（CHANGELOG 声称"实时
  跟随"属实），后续 Brave 更新引入 portal 订阅 race
- **按钮唤醒现象**：在 `brave://settings/appearance` 手动切换一次主题模式
  （如"经典"→"GTK"→"经典"），Brave 内部重新初始化 `NativeTheme` 观察者，
  portal 订阅被激活，此后 toggle 即可实时跟随
- **排障指引**：如果 Brave 不跟随 toggle，去 `brave://settings/appearance`
  切一次模式即可唤醒，无需重启 Brave
- **状态**：已确认 Brave upstream bug，NyxNiri 侧无法修复。方案 A
  （延迟广播）实机证伪；方案 B（CDP）因 `brave://` 禁 CDP 导航不可行；
  两全方案（toggle 跳过 gsettings 广播让 Noctalia hook 异步独占）实测
  gsettings 值正确变化但 Brave 仍不响应

---

## 7. 旧文档的错误假设纠正

原 `notes/主题问题.md` 和 `主题问题总结.md` 的多个结论经实机验证是错误的：

| 旧结论 | 实机真相 |
|---|---|
| 模板已注册部署 | **从未部署**——工作树 toml 改动 + templates 目录从未 sync 到 `~/.config/` |
| `templates-apply` 有缓存/不可靠 | 注册后**完全正常**，0.023s 重渲染，无缓存问题 |
| Noctalia 不自动渲染 user templates | **会自动渲染**（调色板更新后 ~6s）|
| `config-reload` 卡 30s 网络超时 | 实测 0.045s，无超时 |
| `gtk-dark.css` 软链接是根因 | 无关（GTK4 下 gtk-theme-name 无效）|
| `.rgb_csv` 渲染风险 | 实机验证成功，0 个占位符残留 |
| `palette-export --format gtk-css` 子命令 | **不存在**（`unknown command`）。PR #20 的 GTK 方案依赖此子命令，不可行；其 GTK Material You 目标已被当前用户模板架构（nyxniri_gtk3/gtk4）取代，PR #20 已关闭 |
| `prefer-dark-theme` 是 Nautilus 不跟的根因 | 真根因是 `gtk-4.0.css` 无条件 `@define-color` 覆盖 libadwaita `@media` |

---

## 8. 排障速查 (Troubleshooting)

| 症状 | 检查点 |
|---|---|
| Nautilus 不跟深浅 | `gtk-4.0/gtk.css` 是否含 `@media` 块？`grep @media ~/.config/gtk-4.0/gtk.css` |
| Brave 启动时不跟深浅 | `gtk-4.0/settings.ini` 是否有 `gtk-application-prefer-dark-theme`？ |
| Brave toggle 时不实时变色 | 去 `brave://settings/appearance` 切一次模式唤醒（Brave 冷启动 bug，见 Problem 11） |
| 重启后 Nautilus 显示 adw（非 M3） | Noctalia 是否已渲染 gtk.css？等 ~8s 或手动 toggle 一次 |
| 所有应用都不跟 | `gsettings get org.gnome.desktop.interface color-scheme` 是否正确？`theme-sync.sh` 是否运行？ |
| gtk.css 不更新 | `noctalia-config.toml` 是否注册了 `theme.templates.user.nyxniri_gtk4`？ |
| gtk.css 渲染错色 | Noctalia 调色板是否已更新？（等 ~6s）`noctalia msg config-reload && noctalia msg templates-apply` |
| Brave 报 Theme parsing error | `gtk-3.0.css` 是否含 GTK4 专有属性？ |
| M3 颜色覆盖不了 | `gtk-dark.css` 软链接是否已删？`ls -la ~/.config/gtk-4.0/gtk-dark.css` |

---

## 9. 调试命令 (Debug Commands)

```bash
# 手动触发 Noctalia 渲染
noctalia msg config-reload && noctalia msg templates-apply

# 查看渲染结果（应有 @media 块 + 两套 window_bg_color）
grep "@media\|window_bg_color" ~/.config/gtk-4.0/gtk.css

# 查看当前 gsettings 信号源
gsettings get org.gnome.desktop.interface color-scheme
gsettings get org.gnome.desktop.interface gtk-theme

# 查看 portal color-scheme（uint32: 0=no pref, 1=dark, 2=light）
gdbus call --session --dest org.freedesktop.portal.Desktop \
  --object-path /org/freedesktop/portal/desktop \
  --method org.freedesktop.portal.Settings.ReadOne \
  "org.freedesktop.appearance" "color-scheme"

# 查看 Noctalia 模式
noctalia msg theme-mode-get

# 查看 AdwStyleManager 状态（需 Python + gi）
python3 -c "
import gi; gi.require_version('Adw', '1')
from gi.repository import Adw
sm = Adw.StyleManager.get_default()
print('dark:', sm.get_dark())
"

# 手动切换
nyxniri theme toggle
nyxniri theme dark
nyxniri theme light
```

---

## 10. 相关文件索引

| 文件 | 职责 |
|---|---|
| `configs/noctalia/theme-sync.sh` | 深浅切换调度中枢 |
| `configs/noctalia/noctalia-config.toml` | hook + user template 注册 |
| `configs/noctalia/templates/gtk-3.0.css` | GTK3 M3 模板 |
| `configs/noctalia/templates/gtk-4.0.css` | GTK4 M3 模板（双 @media） |
| `configs/noctalia/wallpaper-hook.sh` | 壁纸切换 hook |
| `configs/noctalia/mpvpaper-sync.sh` | mpvpaper 同步 |
| `nyxniri/gtktheme.py` | `nyxniri gtk install\|status\|uninstall` |
| `nyxniri/cli.py` | `nyxniri theme` 子命令 |
| `nyxniri/deploy.py` | 部署 + 模板渲染触发 |
| `notes/gtk-material-you-port.md` | SCSS→CSS 移植笔记 |
