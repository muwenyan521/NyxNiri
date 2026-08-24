"""Behavior contracts for backup/uninstall: non-interactive no-op, interactive flag, mode aliases.

Safety: all tests run inside TempEnv which isolates HOME to a temp directory.
No test may call real fcitx_uninstall, greeter_uninstall, or touch real ~/.config.
"""

import sys
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock

from tests.utils import TempEnv


class TestUninstallNonInteractiveNoop(unittest.TestCase):
    """Non-interactive uninstall with no mode must be a no-op (return False)."""

    def setUp(self):
        self._ctx = TempEnv()
        self._ctx.__enter__()
        self.env = self._ctx.env
        (self.env.config_dir / "niri").mkdir(parents=True, exist_ok=True)
        (self.env.config_dir / "niri" / "config.kdl").write_text("test")

    def tearDown(self):
        self._ctx.__exit__()

    def test_non_interactive_uninstall_is_noop(self):
        """Running uninstall non-interactively with no mode must not touch configs."""
        from nyxniri.backup import uninstall_nyxniri

        with patch("sys.stdin.isatty", return_value=False):
            result = uninstall_nyxniri("")

        self.assertFalse(result, "Non-interactive uninstall should return False (no-op)")
        self.assertTrue(
            (self.env.config_dir / "niri" / "config.kdl").exists(),
            "Config must survive non-interactive uninstall no-op",
        )

    def test_non_interactive_uninstall_purge_still_works(self):
        """Explicit purge mode should still execute even non-interactively."""
        from nyxniri.backup import uninstall_nyxniri

        with patch("sys.stdin.isatty", return_value=False):
            with patch("builtins.print"):
                with patch("nyxniri.backup.prompt_confirm", return_value=True):
                    with patch("nyxniri.backup.get_all_backups", return_value=[]):
                        with patch("nyxniri.fcitx.fcitx_uninstall"):
                            with patch("nyxniri.greeter.greeter_uninstall"):
                                with patch("nyxniri.backup._remove_path"):
                                    with patch("nyxniri.backup.get_pics_dir", return_value=self.env.home / "Pictures"):
                                        result = uninstall_nyxniri("purge")

        self.assertTrue(result)


class TestModeAliases(unittest.TestCase):
    """Legacy mode aliases (1/safe/--safe/2/--restore/3/--purge) must map correctly."""

    def setUp(self):
        self._ctx = TempEnv()
        self._ctx.__enter__()
        self.env = self._ctx.env

    def tearDown(self):
        self._ctx.__exit__()

    def test_alias_safe_maps_to_standard(self):
        """Alias 'safe' should map to 'standard' and run the standard uninstall path."""
        from nyxniri.backup import uninstall_nyxniri

        with patch("sys.stdin.isatty", return_value=True):
            with patch("builtins.print"):
                with patch("nyxniri.backup._copy_path"):
                    with patch("nyxniri.backup._remove_path"):
                        with patch("nyxniri.fcitx.fcitx_uninstall"):
                            result = uninstall_nyxniri("safe")

        self.assertTrue(result)

    def test_alias_purge_maps_correctly(self):
        """Alias '3' should map to 'purge'."""
        from nyxniri.backup import uninstall_nyxniri

        with patch("sys.stdin.isatty", return_value=False):
            with patch("builtins.print"):
                with patch("nyxniri.backup.prompt_confirm", return_value=True):
                    with patch("nyxniri.backup.get_all_backups", return_value=[]):
                        with patch("nyxniri.fcitx.fcitx_uninstall"):
                            with patch("nyxniri.greeter.greeter_uninstall"):
                                with patch("nyxniri.backup._remove_path"):
                                    with patch("nyxniri.backup.get_pics_dir", return_value=self.env.home / "Pictures"):
                                        result = uninstall_nyxniri("3")
                                        self.assertTrue(result)


class TestBackupInteractiveFlag(unittest.TestCase):
    """interactive=False should suppress printing."""

    def setUp(self):
        self._ctx = TempEnv()
        self._ctx.__enter__()

    def tearDown(self):
        self._ctx.__exit__()

    def test_interactive_false_suppresses_output(self):
        """backup_configs with interactive=False should not print backing_up/done messages."""
        from nyxniri.backup import backup_configs

        with patch("builtins.print") as mock_print:
            with patch("nyxniri.deploy.discover_config_items", return_value=[]):
                backup_configs(note="test", interactive=False)

        printed = " ".join(str(c) for c in mock_print.call_args_list)
        self.assertNotIn("backing_up", printed.lower(),
                         "interactive=False should not print backing_up message")

    def test_interactive_true_prints_output(self):
        """backup_configs with interactive=True should print."""
        from nyxniri.backup import backup_configs

        with patch("builtins.print") as mock_print:
            with patch("nyxniri.deploy.discover_config_items", return_value=[]):
                backup_configs(note="test", interactive=True)

        mock_print.assert_called()


if __name__ == "__main__":
    unittest.main()
