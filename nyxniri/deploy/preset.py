"""Preset mechanism — switch an app's active variant (default / official / user).

Three layers stack, lowest to highest (§2.4)::

    默认 config  ←  官方预设  ←  __custom__ 文件

The active choice lives in a state file ``~/.config/NyxNiri/presets/<app>.active``
(one line: the preset name, or ``default``). This module owns the read/write and
the src-resolution that picks which directory gets deployed for an app.

Write timing (iron law, §3.2): apply flows deploy first, then write the active
file. The dest-missing reset is the only sanctioned write-before-deploy (dest is
empty, so a half-written state self-heals next run).
"""

import os
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional, Tuple

from nyxniri.constants import Colors
from nyxniri.core import get_env
from nyxniri.i18n import msg


def _active_path(app: str) -> Path:
    return get_env().presets_dir / f"{app}.active"


def read_active_preset(app: str) -> str:
    """Return the app's active preset name, or 'default' if unset/unreadable."""
    try:
        content = _active_path(app).read_text(encoding="utf-8").strip()
        return content or "default"
    except Exception:
        return "default"


def write_active_preset(app: str, name: str) -> None:
    """Atomically write the active preset file (temp + rename).

    A half-written (empty) file would be read as 'default' and silently switch
    the user back to defaults — atomic write blocks that failure path (§3.2).
    """
    env = get_env()
    env.presets_dir.mkdir(parents=True, exist_ok=True)
    final = _active_path(app)
    tmp = final.with_suffix(f".{final.suffix}.tmp.{os.getpid()}")
    try:
        tmp.write_text(name, encoding="utf-8")
        os.replace(tmp, final)
    except Exception:
        try:
            tmp.unlink(missing_ok=True)
        except OSError:
            pass
        raise


@dataclass
class PresetSrcResult:
    """Outcome of resolving an app's active preset to a deploy source."""

    src: Optional[Path]          # None → freeze dest, skip deploy (preset not found)
    reset_active: Optional[str]  # write this before deploy (dest-missing reset to default)
    warnings: List[str] = field(default_factory=list)


def resolve_preset_src(app: str, active: str, dest: Path) -> PresetSrcResult:
    """Resolve which source dir to deploy for ``app`` given its ``active`` preset.

    Four branches (§3.2): dest-missing reset; default; official preset;
    user preset. If none matches, src is None (freeze + warn) — we never
    silently fall back to default, which would wipe the user's frozen state.
    """
    env = get_env()
    app_root = env.configs_src / app
    repo_presets = app_root / "presets"
    user_presets = env.presets_dir / app

    # Boundary: user rm -rf'd ~/.config/<app> but the active file still points
    # at a (possibly upstream-removed) preset. Nothing to freeze — reset to
    # default so the next deploy reinstalls defaults. If the original preset is
    # also gone from repo+user, surface an extra warning (upstream rename/remove
    # info must not be swallowed by the dest-missing rule).
    if not dest.exists() and active != "default":
        upstream_removed = not (repo_presets / active).is_dir() and not (user_presets / active).is_dir()
        warnings: List[str] = []
        if upstream_removed:
            warnings.append(msg("preset_warn_upstream_removed", app, active))
        return PresetSrcResult(src=app_root, reset_active="default", warnings=warnings)

    if active == "default":
        return PresetSrcResult(src=app_root, reset_active=None)

    official = repo_presets / active
    if official.is_dir():
        return PresetSrcResult(src=official, reset_active=None)

    user = user_presets / active
    if user.is_dir():
        return PresetSrcResult(src=user, reset_active=None)

    # Active points at a preset that no longer exists anywhere — freeze dest,
    # do NOT fall back to default (would silently wipe the user's config).
    return PresetSrcResult(
        src=None,
        reset_active=None,
        warnings=[msg("preset_warn_frozen", app, active)],
    )


# --- CLI-facing operations ----------------------------------------------------

def _find_preset_src(app: str, name: str) -> Optional[Path]:
    """Direct lookup of a named preset (apply flow). No dest-missing reset.

    Distinct from resolve_preset_src (update flow): apply is an explicit user
    choice, so a missing dest does not silently reset to default — the named
    preset is deployed as-is. 'default' resolves to the app root.
    """
    env = get_env()
    if name == "default":
        src = env.configs_src / app
        return src if src.exists() else None
    official = env.configs_src / app / "presets" / name
    if official.is_dir():
        return official
    user = env.presets_dir / app / name
    if user.is_dir():
        return user
    return None


def collect_presets(app: str) -> List[Tuple[str, str, bool]]:
    """Return (name, source, is_active) for every preset of an app.

    source is 'official' (shipped in repo) or 'user' (saved under nyx_dir).
    'default' is always first. Used by list_presets (printing) and the TUI
    switcher (data only) — no side effects.
    """
    active = read_active_preset(app)
    entries: List[Tuple[str, str, bool]] = [("default", "official", active == "default")]

    env = get_env()
    official_dir = env.configs_src / app / "presets"
    if official_dir.is_dir():
        for p in sorted(official_dir.iterdir(), key=lambda x: x.name):
            if p.is_dir():
                entries.append((p.name, "official", active == p.name))
    user_dir = env.presets_dir / app
    if user_dir.is_dir():
        for p in sorted(user_dir.iterdir(), key=lambda x: x.name):
            if p.is_dir():
                entries.append((p.name, "user", active == p.name))
    return entries


def list_presets(app: str) -> List[Tuple[str, str, bool]]:
    """List presets for an app; the active one is marked. ``list`` is status.

    Prints a numbered list with the active entry prefixed by ``*``.
    """
    entries = collect_presets(app)
    print(msg("preset_list_title", app))
    for i, (name, source, is_active) in enumerate(entries, 1):
        marker = "*" if is_active else " "
        tag = msg(f"preset_src_{source}")
        print(f"  {marker} [{i}] {name}  {Colors.DIM}{tag}{Colors.RESET}")
    return entries


def _render_preset_result(app: str, name: str, preserved_lines: List[str], failed: bool = False) -> None:
    """Lightweight feedback reusing the completion screen's preserved section."""
    if failed:
        print(msg("preset_apply_failed", app, name))
        return
    print(msg("preset_applied", app, name))
    if preserved_lines:
        print(f"\n  {Colors.BOLD_WHITE}{msg('summary_section_preserved')}{Colors.RESET}")
        for pline in sorted(set(preserved_lines)):
            print(f"    {pline}")


def apply_preset(app: str, name: str) -> bool:
    """Switch an app to a named preset (narrow deploy path).

    Runs only atomic_replace + template render for this app — no hardware
    patches, no post-install services (§9: switching kitty must not rerun
    fisher). Writes the active file AFTER deploy succeeds (iron law, §3.2).
    """
    from nyxniri.deploy.templates import _phase_render_templates
    from nyxniri.deploy.atomic import atomic_replace_item

    env = get_env()
    dest = env.config_dir / app
    src = _find_preset_src(app, name)
    if src is None:
        print(msg("preset_not_found", app, name))
        return False

    preserved_log: List[str] = []
    if not atomic_replace_item(src, dest, preserved_log=preserved_log):
        _render_preset_result(app, name, preserved_log, failed=True)
        return False

    _phase_render_templates(only_app=app)
    # deploy-then-write: a crash mid-flow must not leave active pointing at a
    # preset whose deploy didn't complete (would skip re-deploy next run). §3.2
    write_active_preset(app, name)
    _render_preset_result(app, name, preserved_log)
    return True


def _ignore_custom_and_manifest(_src_dir, names):
    """copytree ignore: drop __custom__ entries (any depth) and .module.toml."""
    return {n for n in names if "__custom__" in n or n == ".module.toml"}


def save_preset(app: str, name: str) -> bool:
    """Snapshot current ~/.config/<app>/ into a user preset, minus __custom__.

    'default' is reserved (apply default = reset). Official-name collisions
    are rejected (official presets win on name). §2.2
    """
    if name == "default":
        print(msg("preset_name_reserved", name))
        return False
    env = get_env()
    dest = env.config_dir / app
    if not dest.is_dir():
        print(msg("preset_nothing_to_save", app))
        return False
    if (env.configs_src / app / "presets" / name).is_dir():
        print(msg("preset_official_name_collision", name))
        return False

    target = env.presets_dir / app / name
    if target.exists():
        shutil.rmtree(target, ignore_errors=True)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(dest, target, symlinks=True, ignore=_ignore_custom_and_manifest)
    print(msg("preset_saved", app, name))
    return True


def delete_preset(app: str, name: str) -> bool:
    """Delete a user preset. Official presets cannot be deleted. §2.5"""
    if name == "default":
        print(msg("preset_name_reserved", name))
        return False
    env = get_env()
    target = env.presets_dir / app / name
    if not target.is_dir():
        print(msg("preset_not_found", app, name))
        return False
    if (env.configs_src / app / "presets" / name).is_dir():
        print(msg("preset_delete_official_denied", name))
        return False
    shutil.rmtree(target, ignore_errors=True)
    print(msg("preset_deleted", app, name))
    return True

def edit_preset(app: str, name: str) -> bool:
    """Open a user preset's directory in $EDITOR (rejects default + official).

    Default is reserved; official presets are repo-owned read-only. Only user
    presets under ~/.config/NyxNiri/presets/<app>/<name>/ are editable in place;
    re-running ``apply <name>`` deploys the edits. Non-interactive → hint path.
    """
    if name == "default":
        print(msg("preset_name_reserved", name))
        return False
    env = get_env()
    if (env.configs_src / app / "presets" / name).is_dir():
        print(msg("preset_edit_official_denied", name))
        return False
    target = env.presets_dir / app / name
    if not target.is_dir():
        print(msg("preset_not_found", app, name))
        return False
    if not sys.stdin.isatty():
        print(msg("preset_edit_notty", target))
        return False
    editor = os.environ.get("EDITOR") or os.environ.get("VISUAL") or "nano"
    subprocess.run([editor, str(target)], check=False)
    print(msg("preset_edit_opened", app, name))
    return True
