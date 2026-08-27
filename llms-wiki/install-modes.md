# Install Modes — standalone / repo / system 三模式

> "哪里跑就是哪里的模式"——不搞优先级规则、不搞自动判定胜出者。源码：`nyxniri/core.py`、
> `nyxniri/network.py`、`nyxniri/packaging/PKGBUILD`。

## 三模式

| 方式 | repo_dir | run_mode | mode_label | update 行为 |
|---|---|---|---|---|
| `curl \| bash` | `~/.cache/NyxNiri` | `standalone` | Remote Cache | `git pull` |
| `git clone` + `./install.sh` | 任意路径 | `repo` | Local Path | `git pull`（脏树跳过） |
| AUR `nyxniri-git` | `/usr/share/nyxniri` | `system` | System Package | `pacman -Syu`（禁 git pull） |

## 检测（`_detect_run_mode`，marker 最先）

```python
if (root_dir / ".system-install").is_file():   → system
elif root_dir.resolve() == cache_dir.resolve(): → standalone
elif (root_dir / "configs") and (root_dir / "assets"): → repo
else: → standalone（fallback）
```

`.system-install` marker **最先**检查——system 包在 `/usr/share/nyxniri/` 也 ship 了
configs/+assets/，不加 marker 会被误判成 repo。AUR 包 `package()` 里 `touch .system-install`。

`nyxniri` 命令模式由软链指向的 `install.sh` 决定，跟 cwd 无关——`cd /tmp && nyxniri update`
不改模式。要切模式重新跑对应目录的 `./install.sh`。

## CLI 软链（`ensure_nyxniri_symlink`）

`~/.local/bin/nyxniri` 软链指向你**主动跑** install.sh 的那个目录：

- 从 `~/NyxNiri` 跑 → 软链指 `~/NyxNiri` → `nyxniri` 命令用开发仓库代码
- 从 `bash <(curl)` 跑 → 软链指 `~/.cache/NyxNiri`
- **system 模式 no-op**：包 owns `/usr/bin/nyxniri`，不动用户 `~/.local/bin/nyxniri`
  （包不主动跑 install.sh，不抢软链）

## PATH 遮蔽（`check_path_occlusion`）

`~/.local/bin` 一般在 `/usr/bin` 前面，所以用户软链会盖住系统包。AUR 用户若之前用过
curl/git 装法，`~/.local/bin/nyxniri` 还在，会盖住包——`nyxniri update` 看似成功其实更新的是
缓存副本，pacman 更新的 `/usr/share/nyxniri` 用户感知不到。

system 模式下 `update` / `doctor` **开头都检测**：实际解析到的 install.sh 不在
`/usr/share/nyxniri` 就**持续**警告"你正用一个遮蔽系统包的旧软链"——不只装包时提醒一次。
控制感：用户随时知道自己到底在跑什么。

## update 分支（`safe_git_pull`，network.py）

```python
if run_mode == "system":
    print(msg("update_use_pacman"))   # "系统包由 pacman 管，跑 sudo pacman -Syu nyxniri-git"
    return None                        # 拒绝 git pull
```

堵死"对系统包跑 git pull"的故障路径。system 模式 **不做版本预检测**——禁了 git pull 就无法
知道上游有没有新版，要查就得调 AUR RPC / GitHub Releases API，违背纯标准库原则。诚实比
花哨重要：直接提示 pacman 管更新，pacman 自己会告诉用户有没有更新。

## AUR 包（`nyxniri/packaging/PKGBUILD`）

- 单一 rolling 包 `nyxniri-git`，`source=("git+https://github.com/ech678/NyxNiri.git#branch=main")`
- `pkgver()` = `git describe --long --tags`
- `package()`：cp nyxniri/configs/assets/install.sh 到 `/usr/share/nyxniri/`、`touch .system-install`、
  `/usr/bin/nyxniri` 软链到 install.sh、strip `__pycache__`
- **不做交互安装**（makepkg 不能 sudo）；用户装完包跑 `nyxniri install`
- 不发 stable 包——现状更新模型就是 rolling，双包 = 双倍熵
- `depends` / `optdepends` 由 `nyxniri/packaging/gen-deps.py` 扫所有 manifest 聚合生成——
  单一数据源，加 app 只动 configs/，不动 PKGBUILD

## 用户数据正交

无论哪种方式，用户数据都在两处、与方法无关：
- `~/.config/<app>/` — 部署的配置 + `__custom__` 覆盖
- `~/.config/NyxNiri/` — backups / presets / active 状态

curl → AUR 迁移 = 装包 + 删 `~/.cache/NyxNiri`，用户数据零迁移。**切换安装方式 = 换代码来源，
不换用户数据**。
