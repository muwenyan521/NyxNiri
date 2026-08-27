# TUI Preset Switcher — 双栏、焦点分发、窄 deploy

> CLI（`nyxniri preset <app> apply <name>`）之外，交互菜单里也能切预设。**双栏布局**，
> 复用 Menu 的渲染骨架但双栏+双光标是新交互，自写焦点+按键分发。源码：`nyxniri/tui.py`（`PresetSwitcher`）。

## 布局

```
  预设切换            ←/→ 跳栏  ↑/↓ 栏内移动  Enter 应用  q 退
  ──────────────────────────────────────────────────────────────
  应用                预设 (niri)
  ─────────────       ──────────────
  kitty          →    default
> niri           ←  > glass          ◄ 栏内光标
  fish                compact
  noctalia
```

- **左栏 = 应用**，右栏 = 当前聚焦应用的预设。活动预设前标 `>`。
- **←/→**（+ `h`/`l`）跳栏（应用 ↔ 预设）。
- **↑/↓**（+ `k`/`j`）栏内移动，循环。
- **Enter / Space** = apply 当前 (应用, 预设) 组合。
- **q / ESC / 0** = 退回（返回 None）。
- 跳到新应用时右栏换显该应用的预设列表，栏内光标 `land_on_active` 停在该应用当前活动项。

两轴两键集，永远知道在动哪个维度——ranger/mc 那套肌肉记忆。

## 解耦设计

`PresetSwitcher(apps, presets_for)` 不碰 deploy：调用方（`cli.preset_switcher_loop`）传 app
列表 + 一个 callback `presets_for(app) → [(name, is_active)]`。`run()` 返回选中的 `(app, preset)`
或 None。caller 拿到后调 `apply_preset(app, name)`。组件是纯数据+渲染，副作用在 caller。

## apply 后的窄 deploy 路径

切预设只跑该 app 的 `atomic_replace_item` + 模板渲染（`/home/user` 替换），**不走**
`deploy_selected_configs` 全流水线——不触发 `_phase_hardware_patches`（NVIDIA 解注释）和
`_phase_post_install_services`（fisher update / theme-sync / gtk 重渲染）。切个 kitty 预设
不该顺带跑 fisher，无关副作用违反"无熵"。详见 [preset-mechanism](preset-mechanism.md)。

## 反馈

apply 完 `_render_preset_result` 打印"已切到 transparent，X 个文件更新，Y 个 `__custom__`
保留"——和 install/update 一致的反馈风格，不静默。

## 光标保障

`sys.stdout.write(Colors.CURSOR_HIDE)` 进入循环，`finally: CURSOR_SHOW`——光标恢复由 trap
钩子绝对保障（崩溃也恢复），符合 TUI 宪章"光标恢复由 trap 钩子绝对保障"。
