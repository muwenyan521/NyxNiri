"""Contract test for packaging/gen-deps.py — depends aggregation shape (§5.7)."""

import importlib.util
import unittest
from pathlib import Path

from tests.utils import TempEnv

_GENDEPS = Path(__file__).resolve().parent.parent / "nyxniri" / "packaging" / "gen-deps.py"


def _load_gendeps():
    spec = importlib.util.spec_from_file_location("gendeps", _GENDEPS)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


class TestGenDeps(unittest.TestCase):
    """depends = deployable apps' packages ∪ CORE_DEPS ∪ AUR_DEPS; optdepends = manifest-only."""

    def setUp(self):
        self._ctx = TempEnv()
        self._ctx.__enter__()
        self.repo_root = self._ctx.env.repo_dir
        self.gendeps = _load_gendeps()

    def tearDown(self):
        self._ctx.__exit__()

    def test_depends_includes_deployable_app_packages_and_base(self):
        depends, _opt = self.gendeps.compute_depends(self.repo_root)
        # Deployable app packages (from manifests / defaults).
        for app_pkg in ("kitty", "niri", "fish", "fastfetch", "starship", "noctalia", "zed", "xdg-desktop-portal"):
            self.assertIn(app_pkg, depends)
        # Base system deps not tied to an app (from CORE_DEPS).
        for base in ("wlsunset", "eza", "jq", "tmux", "inotify-tools", "fzf", "python-gobject",
                     "gtk-layer-shell", "ttf-jetbrains-mono", "noto-fonts-cjk"):
            self.assertIn(base, depends)
        # AUR-only deps.
        self.assertIn("mpvpaper", depends)

    def test_optional_apps_go_to_optdepends_not_depends(self):
        depends, optdepends = self.gendeps.compute_depends(self.repo_root)
        # nautilus/missioncenter/fcitx5-rime are manifest-only → optdepends, not depends.
        for opt_pkg in ("nautilus", "mission-center", "rime-ice-git"):
            self.assertNotIn(opt_pkg, depends)
        opt_pkg_names = [p for p, _ in optdepends]
        self.assertIn("nautilus", opt_pkg_names)
        self.assertIn("mission-center", opt_pkg_names)
        self.assertIn("rime-ice-git", opt_pkg_names)

    def test_depends_is_sorted_deduplicated_list(self):
        depends, _ = self.gendeps.compute_depends(self.repo_root)
        self.assertEqual(depends, sorted(set(depends)))

    def test_render_and_update_roundtrip(self):
        depends, optdepends = self.gendeps.compute_depends(self.repo_root)
        rendered = self.gendeps._render(depends, optdepends)
        self.assertIn("depends=(", rendered)
        self.assertIn("optdepends=(", rendered)
        self.assertIn("'kitty'", rendered)
        self.assertIn("'nautilus: nautilus'", rendered)
        # Note: update_pkgbuild() rewrites the real PKGBUILD on disk — it's a
        # manual maintainer script (gen-deps --update), not test-covered. Tests
        # only assert _render() output (pure function, no filesystem side effects).


if __name__ == "__main__":
    unittest.main()
