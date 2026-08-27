# NVIDIA Patch — 硬件自适应层（为何不塞进 preset）

> NVIDIA env 解注释是**硬件自适应**（自动检测、用户不可见），不是**预设**（显式切换、用户可见）。
> 强塞进同一机制是 category error。源码：`nyxniri/deploy/hardware.py`。

## 现状

`configs/niri/config.kdl:33-35` 三行注释掉的 env（非 NVIDIA 机器必须保持注释，强开会报错或
行为异常）：

```kdl
// GBM_BACKEND "nvidia-drm"
// __GLX_VENDOR_LIBRARY_NAME "nvidia"
// LIBVA_DRIVER_NAME "nvidia"
```

`_phase_hardware_patches`（`hardware.py`）：
- `_detect_nvidia()`：跑 `lspci`，缓存结果到 `_IS_NVIDIA`（进程内），stdout 含 "nvidia" 即真。
- 若 NVIDIA：`re.sub` 把这三行的 `//` 注释去掉（解注释），写回 config.kdl。
- 若非 NVIDIA：保持注释，打印"未检测到 NVIDIA"。

由全部署流水线 `deploy_selected_configs` / `test_deploy` 调用；apply_preset 的窄路径**不调**
（切预设不该顺带改硬件 patch）。

## 三个选项，选 A（保持现状硬编码）

| 选项 | 机制 | 代价 |
|---|---|---|
| **A. 保持现状** | `_phase_hardware_patches` 硬编码 | 一处特殊 case 代码 |
| B. overlay 预设 | preset 只含差异文件，deploy 先默认再覆盖 | 引入 overlay 概念，deploy 逻辑复杂 |
| C. full 预设 | `configs/niri/presets/nvidia/` 完整 copy | 配置重复，更新要双写，易漂移 |

选 A。NVIDIA 是硬件自适应（自动检测、用户不可见），预设是用户选择（显式切换、用户可见）——
两者是不同概念，强塞进同一机制是 category error。这正是用户感到"麻烦"的直觉来源。

## 延迟决策

硬件适配累积到 **>3 处**（AMD、多显示器、低性能模式…）时，overlay 预设才有规模回报：
overlay 是新的 manifest 字段 `overlay = true`，deploy 先默认再 overlay 差异文件。当前 ≤1 处，
保持 `_phase_hardware_patches` 硬编码作为**独立的硬件自适应层**，不塞进 preset 系统。

> 预设接受全树复制（风味受人工策展约束、个位数、drift 管得住）；硬件 patch 否决全树（选项 C）
> 因适配可能膨胀到十几处、drift 是另一个数量级。同涉"复制"但规模量级不同，处理方式不同不是矛盾。
