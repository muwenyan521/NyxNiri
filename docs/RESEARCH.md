# NyxNiri 第二、三轮调查记录

更新时间：2026-08-23

这份记录只描述 NyxNiri 项目本身的改动依据，不用于修改当前系统配置。

## 第二轮：互联网资料

### 采集结果

Tavily CLI 已按项目要求执行查询；本轮 API 返回了 TLS/额度错误，因此没有把不可复核的摘要当作证据。随后直接读取了公开的一手仓库与文档页面，保留 URL 供复查。

| 来源 | 可借鉴内容 | 处理结果 |
| --- | --- | --- |
| https://github.com/noctalia-dev/noctalia-shell | Noctalia 将 shell 配置拆成可包含的 TOML 文件，配置层有明确覆盖顺序，GUI 状态最后覆盖手写配置 | 保留 NyxNiri 的 `configs/noctalia/` 与 `configs/niri/nyx-tokens.toml` 分层；不把 GUI 状态写回仓库 |
| https://docs.noctalia.dev/noctalia/configuration/ | `include.files`、`autoload = false`、配置覆盖优先级和热加载边界 | 在设计文档中明确 fallback token 与运行时 palette 的优先级；部署仍保持原子替换 |
| https://github.com/YaLTeR/niri | layer-shell、动态工作区、可配置布局、动画和无障碍是 compositor 的原生能力 | 继续把 Orbit/Wallpaper Picker 做成 layer-shell surface；没有引入额外常驻 daemon |
| https://github.com/basecamp/omarchy | 主题和桌面方案强调少量可识别的角色色、集中式主题切换和可回滚安装 | 采用 cyan/coral/amber/ink 角色 token 与 `DESIGN.md`，不复制其发行版级安装流程 |

### 实际引入

- 用 `design/tokens.toml` 和 `configs/niri/nyx-tokens.toml` 统一 surface、outline、text、motion、shape、spacing 和 typography。
- 新增共享 token loader；layout、Spring 和 Wallpaper Picker 字体从 token 文件读取关键语义值，Noctalia 只覆盖运行时颜色。
- Noctalia palette 作为运行时覆盖，缺失时退回仓库内 token；`NYXNIRI_REDUCED_MOTION=1` 让动画立即收敛。
- Wallpaper Picker 根据可用窗口空间计算 2 到 4 列和卡片尺寸，不再依赖单一分辨率。
- 增加搜索无结果、空壁纸目录和空分类的可见状态；卡片悬停只改变光晕和边框，不改变命中几何。

### 未采用

- 没有复制外部 dotfiles 的具体快捷键、壁纸、字体或当前系统路径。
- 没有引入 Qt/GTK 以外的新常驻桌面组件，也没有把外部主题仓库作为运行时依赖。

## 第三轮：原项目 forks 与 PR

仓库元数据：`ech678/NyxNiri` 不是 fork，默认分支为 `main`，调查基线为 `910f13a532f473436cc342d451644ccf78719619`。

### PR 状态

| PR | 状态 | 结论 |
| --- | --- | --- |
| #19 | open | 内容包含部署/诊断恢复和 GTK 主题同步；与当前 Python 部署契约部分重叠，未直接搬运 |
| #18 | open | 采纳搜索键位、Orbit 智能回车、Noctalia 动态目录兼容、palette overlay 修正、缩略图文件守卫和线程池关闭 |
| #17 | open | 与 #18 有重复；其问题清单用于交叉验证，重新按当前共享 runtime 实现 |
| #16 | open | 采纳卡片悬停抖动修复和命中区域容差 |
| #15 | closed/merged | 方向键导航、重复触发和动态壁纸清理已在当前树中存在，作为回归基线复核 |
| #12/#11/#9/#4/#3 | closed/merged | 文档、XML、历史 WM 配置或已存在内容，不再重复引入 |

### Fork 状态

GitHub forks API 返回 29 个 fork（包括 `ylh440104/NyxNiri`、`TackaIzHe/NyxNiri`、`Krits03/NyxNiri`、`Deslo1n/NyxNiri` 等）。它们都没有显示可直接合并的领先分支元数据；其中近期提交主要对应当前 PR 作者的工作树。唯一有价值的实现差异来自 PR #16、#17、#18、#19 的提交，而不是直接 cherry-pick 某个 fork。

### 已重新实现的内容

- `nyxui.runtime.acquire_instance_lock()` 在终止旧实例后等待最多 500ms，缩小重复触发竞态窗口。
- `WallpaperScanner` 在缩略图任务开始前检查文件存在，并在窗口淡出完成时关闭线程池。
- Noctalia `plugin_settings` 中任意插件表都可提供 `video_directory`。
- Wallpaper Picker 的视觉卡片不再随 hover 向上移动，命中测试增加 8px 容差。
- 搜索框新增 Ctrl+A/E/L、Ctrl+Backspace；网格新增 Page Up/Down；Orbit 回车优先匹配已注册菜单项。
- 选择性部署的契约校验按本次选中配置范围执行，不会因未选择的 Niri/Noctalia 单元缺失而误报失败。

### 有意不引入

- PR #19 的大范围恢复项没有直接覆盖当前实现，因为 `nyxniri/deploy.py` 已有 `validate_deployed_configs()`、preflight 和生成物清理契约；重复移植会增加冲突面。
- 外部 PR 的 broad exception、固定 1080p 网格常量和旧脚本路径没有保留。
