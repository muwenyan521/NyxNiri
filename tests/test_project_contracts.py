import os
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "configs" / "niri" / "scripts"
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(SCRIPTS))

from nyxniri.deploy import atomic_replace_item, validate_deployed_configs
from nyxniri.constants import CORE_DEPS, OPTIONAL_APPS
from nyxui.layout import calculate_grid_metrics
from nyxui.motion import Spring
from nyxui.palette import load_material_palette
from wallpaper_picker.config import ALL_SUPPORTED_EXTENSIONS
from orbit.config import DEFAULT_MENU_TREE, load_menu_tree


class ProjectContractsTest(unittest.TestCase):
    def test_atomic_replace_preserves_dunder_file_and_ignores_bytecode(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            previous_home = os.environ.get("HOME")
            os.environ["HOME"] = str(root)
            source = root / "source"
            target = root / ".config" / "niri"
            source.mkdir()
            target.mkdir(parents=True)
            (source / "config.kdl").write_text("new", encoding="utf-8")
            (source / "__pycache__").mkdir()
            (source / "__pycache__" / "stale.pyc").write_bytes(b"stale")
            (target / "input__custom__.kdl").write_text("keep", encoding="utf-8")
            try:
                self.assertTrue(atomic_replace_item(source, target))
                self.assertEqual((target / "config.kdl").read_text(encoding="utf-8"), "new")
                self.assertEqual((target / "input__custom__.kdl").read_text(encoding="utf-8"), "keep")
                self.assertFalse((target / "__pycache__").exists())
            finally:
                if previous_home is None:
                    os.environ.pop("HOME", None)
                else:
                    os.environ["HOME"] = previous_home

    def test_responsive_grid_has_stable_two_to_four_columns(self):
        narrow = calculate_grid_metrics(720, 900)
        wide = calculate_grid_metrics(2560, 1440)
        self.assertEqual(narrow.columns, 2)
        self.assertEqual(wide.columns, 4)
        self.assertGreaterEqual(narrow.card_width, 248)
        self.assertLessEqual(wide.card_width, 360)

    def test_reduced_motion_settles_spring_immediately(self):
        old = os.environ.get("NYXNIRI_REDUCED_MOTION")
        os.environ["NYXNIRI_REDUCED_MOTION"] = "1"
        try:
            spring = Spring(0.0)
            spring.target = 1.0
            self.assertFalse(spring.update(0.016))
            self.assertEqual(spring.current, 1.0)
        finally:
            if old is None:
                os.environ.pop("NYXNIRI_REDUCED_MOTION", None)
            else:
                os.environ["NYXNIRI_REDUCED_MOTION"] = old

    def test_wallpaper_formats_and_default_menu_are_available(self):
        self.assertTrue({".webp", ".mp4", ".avif"}.issubset(ALL_SUPPORTED_EXTENSIONS))
        import orbit.config as orbit_config
        previous = orbit_config.CONFIG_PATHS
        orbit_config.CONFIG_PATHS = []
        try:
            self.assertEqual(load_menu_tree(), DEFAULT_MENU_TREE)
        finally:
            orbit_config.CONFIG_PATHS = previous

    def test_palette_keeps_outline_separate_from_bright_surface(self):
        palette = load_material_palette()
        self.assertNotEqual(palette["outline"], palette["surface_bright"])

    def test_selective_deploy_validation_does_not_require_unselected_surfaces(self):
        old = os.environ.get("HOME")
        with tempfile.TemporaryDirectory() as tmp:
            os.environ["HOME"] = tmp
            try:
                self.assertEqual(validate_deployed_configs(["fish"]), [])
            finally:
                if old is None:
                    os.environ.pop("HOME", None)
                else:
                    os.environ["HOME"] = old

    def test_selective_validation_ignores_unselected_dirty_config_tree(self):
        old = os.environ.get("HOME")
        with tempfile.TemporaryDirectory() as tmp:
            os.environ["HOME"] = tmp
            config_dir = Path(tmp) / ".config"
            niri_dir = config_dir / "niri"
            niri_dir.mkdir(parents=True)
            (niri_dir / "__pycache__").mkdir()
            (niri_dir / "__pycache__" / "stale.pyc").write_bytes(b"stale")
            (niri_dir / "effects.kdl").symlink_to(niri_dir / "missing-effects.kdl")
            try:
                self.assertEqual(validate_deployed_configs(["fish"]), [])
            finally:
                if old is None:
                    os.environ.pop("HOME", None)
                else:
                    os.environ["HOME"] = old

    def test_desktop_tool_profiles_remain_optional_dependencies(self):
        for tool in ("yazi", "btop", "duf"):
            self.assertNotIn(tool, CORE_DEPS)
            self.assertIn(tool, OPTIONAL_APPS)

    def test_optional_profiles_have_complete_user_visible_entrypoints(self):
        required = {
            "yazi": (ROOT / "configs/yazi/yazi.toml", ROOT / "configs/yazi/theme.toml", ROOT / "configs/yazi/keymap.toml"),
            "btop": (ROOT / "configs/btop/btop.conf", ROOT / "configs/btop/themes/nyx.theme"),
            "vivid": (ROOT / "configs/vivid/themes/nyx.yml",),
            "mpv-nyx": (ROOT / "configs/mpv-nyx/mpv.conf", ROOT / "configs/mpv-nyx/input.conf"),
            "nvim-nyx": (ROOT / "configs/nvim-nyx/init.lua", ROOT / "configs/nvim-nyx/lua/nyx-theme.lua"),
        }
        for paths in required.values():
            self.assertTrue(all(path.is_file() for path in paths))

        orbit_text = (ROOT / "configs/niri/orbit-items__custom__.toml").read_text(encoding="utf-8")
        self.assertIn('id = "workspace-tools"', orbit_text)
        self.assertIn('id = "nvim-nyx"', orbit_text)
        self.assertIn('id = "mpv-nyx"', orbit_text)

    def test_shorin_components_deploy_as_managed_local_commands(self):
        bin_dir = ROOT / "configs/bin"
        commands = {path.name for path in bin_dir.iterdir() if path.is_file()}
        self.assertIn("preview", commands)
        self.assertIn("timer", commands)
        self.assertIn("getown", commands)
        self.assertTrue(all(path.stat().st_mode & 0o111 for path in bin_dir.iterdir() if path.is_file()))

    def test_niri_keymap_has_no_duplicate_bindings(self):
        import re
        keys = []
        for line in (ROOT / "configs/niri/binds.kdl").read_text(encoding="utf-8").splitlines():
            match = re.match(r"\s*([A-Za-z0-9+_-]+(?:\+[A-Za-z0-9_-]+)*)\b.*\{", line)
            if match:
                keys.append(match.group(1))
        self.assertEqual(len(keys), len(set(keys)))

    def test_user_visible_profiles_expose_nyx_integrations(self):
        self.assertIn('include optional=true "rules_optional.kdl"', (ROOT / "configs/niri/config.kdl").read_text(encoding="utf-8"))
        self.assertIn("gpu0:0:default", (ROOT / "configs/btop/btop.conf").read_text(encoding="utf-8"))
        self.assertIn("gpu-api=auto", (ROOT / "configs/mpv-nyx/mpv.conf").read_text(encoding="utf-8"))
        self.assertIn("theme_overrides", (ROOT / "configs/zed/settings.json").read_text(encoding="utf-8"))

    def test_geometry_tokens_are_shared_by_orbit_and_picker(self):
        token_text = (ROOT / "design/tokens.toml").read_text(encoding="utf-8")
        orbit_text = (ROOT / "configs/niri/scripts/orbit/config.py").read_text(encoding="utf-8")
        picker_text = (ROOT / "configs/niri/scripts/wallpaper_picker/config.py").read_text(encoding="utf-8")
        self.assertIn("[orbit]", token_text)
        self.assertIn('token("orbit", "base_radius"', orbit_text)
        self.assertIn('token("wallpaper", "card_radius"', picker_text)
