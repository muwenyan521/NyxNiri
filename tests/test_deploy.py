"""Behavior contracts for deploy: atomic replace rollback, broken symlink, no-clobber.

Safety: all tests use tempfile.TemporaryDirectory for filesystem operations.
No test touches the real ~/.config or the real repo configs/ directory.
"""

import shutil
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tests.utils import TempEnv


class TestAtomicReplaceFileRollback(unittest.TestCase):
    """If the 2nd rename fails, dest must be restored from old_dest."""

    def setUp(self):
        self._ctx = TempEnv()
        self._ctx.__enter__()

    def tearDown(self):
        self._ctx.__exit__()

    def test_file_replace_rollback_on_second_rename_failure(self):
        """If tmp_file.rename(dest) fails, dest must be restored from old_dest."""
        from nyxniri.deploy.atomic import atomic_replace_item

        with tempfile.TemporaryDirectory() as workdir:
            workdir = Path(workdir)
            src = workdir / "src.txt"
            src.write_text("new")
            dest = workdir / "dest.txt"
            dest.write_text("original")

            original_rename = Path.rename

            def fail_second_rename(self_path, target):
                if ".new." in self_path.name and target == dest:
                    raise OSError("simulated rename failure")
                return original_rename(self_path, target)

            with patch.object(Path, "rename", fail_second_rename):
                result = atomic_replace_item(src, dest)

            self.assertFalse(result, "Should return False on failure")
            self.assertTrue(dest.exists(), "dest must still exist (restored)")
            self.assertEqual(dest.read_text(), "original",
                             "dest content must be the original, not 'new'")

    def test_file_replace_normal_success(self):
        """Normal file replace should succeed."""
        from nyxniri.deploy.atomic import atomic_replace_item

        with tempfile.TemporaryDirectory() as workdir:
            workdir = Path(workdir)
            src = workdir / "src.txt"
            src.write_text("new content")
            dest = workdir / "dest.txt"
            dest.write_text("old content")

            result = atomic_replace_item(src, dest)
            self.assertTrue(result)
            self.assertEqual(dest.read_text(), "new content")


class TestAtomicReplaceDirRollback(unittest.TestCase):
    """Directory atomic replace must also rollback on failure."""

    def setUp(self):
        self._ctx = TempEnv()
        self._ctx.__enter__()

    def tearDown(self):
        self._ctx.__exit__()

    def test_dir_replace_rollback_on_rename_failure(self):
        """If tmp_new.rename(dest) fails, dest must be restored from old_dest."""
        from nyxniri.deploy.atomic import atomic_replace_item

        with tempfile.TemporaryDirectory() as workdir:
            workdir = Path(workdir)
            src = workdir / "srcdir"
            src.mkdir()
            (src / "file.txt").write_text("new")
            dest = workdir / "dest_dir"
            dest.mkdir()
            (dest / "old.txt").write_text("original")

            original_rename = Path.rename

            def fail_final_rename(self_path, target):
                if ".new." in self_path.name and target == dest:
                    raise OSError("simulated dir rename failure")
                return original_rename(self_path, target)

            with patch.object(Path, "rename", fail_final_rename):
                result = atomic_replace_item(src, dest)

            self.assertFalse(result)
            self.assertTrue(dest.exists(), "dest must be restored")
            self.assertTrue((dest / "old.txt").exists(),
                            "Original content must survive rollback")


class TestEffectsSymlinkBroken(unittest.TestCase):
    """A broken effects.kdl symlink should be detected and recreated."""

    def setUp(self):
        self._ctx = TempEnv()
        self._ctx.__enter__()

    def tearDown(self):
        self._ctx.__exit__()

    def test_broken_symlink_condition(self):
        """The deploy condition for broken symlinks must fire correctly.

        Tests in a temp directory — never touches the real repo.
        """
        with tempfile.TemporaryDirectory() as workdir:
            workdir = Path(workdir)
            effects_normal = workdir / "effects_normal.kdl"
            effects_normal.write_text("// normal")
            effects_sym = workdir / "effects.kdl"

            effects_sym.symlink_to(workdir / "effects_eyecare.kdl")

            self.assertTrue(effects_normal.is_file())
            self.assertFalse(effects_sym.exists(),
                             "Broken symlink should not exist() — triggers recreation")
            self.assertTrue(effects_sym.is_symlink())

            if effects_normal.is_file() and not effects_sym.exists():
                effects_sym.unlink(missing_ok=True)
                effects_sym.symlink_to(effects_normal)

            self.assertTrue(effects_sym.exists())
            self.assertEqual(effects_sym.resolve(), effects_normal.resolve())


class TestWallpaperNoClobber(unittest.TestCase):
    """Wallpaper pack download should not overwrite existing user files."""

    def setUp(self):
        self._ctx = TempEnv()
        self._ctx.__enter__()
        self.env = self._ctx.env

    def tearDown(self):
        self._ctx.__exit__()

    def test_existing_wallpaper_not_overwritten(self):
        """When downloading wallpaper pack, existing files must be preserved."""
        from nyxniri.deploy.assets import deploy_wallpapers

        wp_dest = self.env.home / "Pictures" / "Wallpapers"
        wp_dest.mkdir(parents=True, exist_ok=True)
        user_wp = wp_dest / "my_custom.webp"
        user_wp.write_text("user custom content")

        fake_clone = Path(tempfile.mkdtemp())
        (fake_clone / "my_custom.webp").write_text("repo version")
        (fake_clone / "new_wallpaper.webp").write_text("new from repo")
        (fake_clone / "video").mkdir()
        (fake_clone / "video" / "test.mp4").write_text("video")

        try:
            with patch("nyxniri.deploy.assets.git_clone_timeout", return_value=True):
                with patch("nyxniri.deploy.assets.tempfile.mkdtemp", return_value=str(fake_clone)):
                    with patch("nyxniri.deploy.assets._wallpaper_pack_present_at", return_value=True):
                        with patch("nyxniri.deploy.assets.wallpapers_pack_present", return_value=False):
                            with patch("builtins.print"):
                                deploy_wallpapers(do_download=True)

            self.assertEqual(user_wp.read_text(), "user custom content",
                             "Existing user wallpaper must not be overwritten")
            self.assertTrue((wp_dest / "new_wallpaper.webp").exists(),
                            "New wallpaper from repo should be added")
        finally:
            shutil.rmtree(fake_clone, ignore_errors=True)


class TestWallpaperStatus(unittest.TestCase):
    """WallpaperDeployResult.status_line: each outcome → (key, color, icon) shape."""

    def _r(self, **kw):
        from nyxniri.deploy.assets import WallpaperDeployResult
        base = dict(download_attempted=False, downloaded=False,
                    pack_present=False, fallback_synced=False)
        base.update(kw)
        return WallpaperDeployResult(**base)

    def test_downloaded(self):
        k, c, i = self._r(downloaded=True).status_line(False)
        self.assertEqual(k, "summary_item_wallpapers_downloaded")
        self.assertEqual(i, "[✓]")

    def test_refresh_failed(self):
        k, _, _ = self._r(download_attempted=True, downloaded=False, pack_present=True).status_line(False)
        self.assertEqual(k, "summary_item_wallpapers_refresh_failed")

    def test_failed_with_fallback(self):
        k, _, _ = self._r(download_attempted=True, downloaded=False, fallback_synced=True).status_line(False)
        self.assertEqual(k, "summary_item_wallpapers_failed_fallback")

    def test_failed_no_pack(self):
        k, _, i = self._r(download_attempted=True, downloaded=False).status_line(False)
        self.assertEqual(k, "summary_item_wallpapers_failed")
        self.assertEqual(i, "[✗]")

    def test_existing_from_result(self):
        k, _, _ = self._r(pack_present=True).status_line(False)
        self.assertEqual(k, "summary_item_wallpapers_existing")

    def test_existing_from_disk_probe(self):
        # result silent about pack, but live disk says present → existing
        k, _, _ = self._r().status_line(True)
        self.assertEqual(k, "summary_item_wallpapers_existing")

    def test_fallback_only(self):
        k, _, _ = self._r(fallback_synced=True).status_line(False)
        self.assertEqual(k, "summary_item_wallpapers_fallback")

    def test_skip(self):
        k, _, _ = self._r().status_line(False)
        self.assertEqual(k, "summary_item_wallpapers_skip")


if __name__ == "__main__":
    unittest.main()
