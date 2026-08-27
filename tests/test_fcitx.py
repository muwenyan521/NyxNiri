"""Behavior contracts for fcitx: partial template registration detection (OR logic)."""

import unittest
from pathlib import Path
from unittest.mock import patch, mock_open

from tests.utils import TempEnv


class TestFcitxTemplateDetection(unittest.TestCase):
    """fcitx_templates_registered must use OR logic (any one template = registered)."""

    def setUp(self):
        self._ctx = TempEnv()
        self._ctx.__enter__()

    def tearDown(self):
        self._ctx.__exit__()

    def test_all_three_registered_returns_true(self):
        """All 3 templates present → True."""
        from nyxniri.modules.fcitx import fcitx_templates_registered, FCITX_THEME

        content = (
            f"[theme.templates.user.{FCITX_THEME}_theme]\n"
            f"[theme.templates.user.{FCITX_THEME}_panel]\n"
            f"[theme.templates.user.{FCITX_THEME}_highlight]\n"
        )
        with patch("nyxniri.modules.fcitx._fcitx_paths") as mock_paths:
            mock_paths.return_value = (None, None, None, None, Path("/fake/config.toml"), None, None, None)
            with patch("pathlib.Path.is_file", return_value=True):
                with patch("pathlib.Path.read_text", return_value=content):
                    self.assertTrue(fcitx_templates_registered())

    def test_only_one_registered_returns_true(self):
        """Only 1 of 3 templates present → True (OR logic)."""
        from nyxniri.modules.fcitx import fcitx_templates_registered, FCITX_THEME

        content = f"[theme.templates.user.{FCITX_THEME}_theme]\n"
        with patch("nyxniri.modules.fcitx._fcitx_paths") as mock_paths:
            mock_paths.return_value = (None, None, None, None, Path("/fake/config.toml"), None, None, None)
            with patch("pathlib.Path.is_file", return_value=True):
                with patch("pathlib.Path.read_text", return_value=content):
                    self.assertTrue(fcitx_templates_registered(),
                                    "Partial registration (1/3) should return True with OR logic")

    def test_none_registered_returns_false(self):
        """No templates present → False."""
        from nyxniri.modules.fcitx import fcitx_templates_registered, FCITX_THEME

        content = "[some.other.template]\n"
        with patch("nyxniri.modules.fcitx._fcitx_paths") as mock_paths:
            mock_paths.return_value = (None, None, None, None, Path("/fake/config.toml"), None, None, None)
            with patch("pathlib.Path.is_file", return_value=True):
                with patch("pathlib.Path.read_text", return_value=content):
                    self.assertFalse(fcitx_templates_registered())

    def test_no_config_file_returns_false(self):
        """No config file → False."""
        from nyxniri.modules.fcitx import fcitx_templates_registered

        with patch("nyxniri.modules.fcitx._fcitx_paths") as mock_paths:
            mock_paths.return_value = (None, None, None, None, Path("/fake/config.toml"), None, None, None)
            with patch("pathlib.Path.is_file", return_value=False):
                self.assertFalse(fcitx_templates_registered())


if __name__ == "__main__":
    unittest.main()
