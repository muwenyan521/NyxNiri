"""Shared test utilities: environment isolation, temp HOME, subprocess mocks.

Design principle: tests must NEVER touch the real ~/.config, ~/.local, or ~/.cache.
All Environment access is patched to point at a temp directory for the entire test.
"""

import os
import sys
import tempfile
from pathlib import Path
from unittest.mock import patch

import nyxniri.core as core


class TempEnv:
    """Context manager that fully isolates the NyxNiri Environment to a temp HOME.

    Patches core._ENV, os.environ["HOME"], and get_env() so that every module
    that calls get_env() gets the temp environment — not the real one.
    """

    def __init__(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.home = Path(self._tmp.name)
        self._old_env = {}
        self._patcher = None

    def __enter__(self):
        home = self.home
        # Create directory skeleton
        (home / ".config").mkdir(parents=True, exist_ok=True)
        (home / ".local" / "bin").mkdir(parents=True, exist_ok=True)
        (home / ".local" / "state" / "NyxNiri").mkdir(parents=True, exist_ok=True)
        (home / ".cache").mkdir(parents=True, exist_ok=True)
        (home / "Pictures").mkdir(parents=True, exist_ok=True)

        # Save and override environment variables
        for key in ("HOME", "XDG_STATE_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
            self._old_env[key] = os.environ.get(key)
        os.environ["HOME"] = str(home)
        os.environ["XDG_STATE_HOME"] = str(home / ".local" / "state")

        # Reset cached Environment so next get_env() picks up new HOME
        core._ENV = None

        # Build the Environment with temp HOME, then force repo mode
        env = core.get_env()
        env.run_mode = "repo"
        env.mode_label = "Local Path"
        env.repo_dir = Path(__file__).resolve().parent.parent
        env.configs_src = env.repo_dir / "configs"
        env.assets_src = env.repo_dir / "assets"
        self.env = env

        return self

    def __exit__(self, *exc):
        # Restore environment variables
        for key, val in self._old_env.items():
            if val is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = val
        # Reset cached Environment so subsequent code uses real HOME
        core._ENV = None
        self._tmp.cleanup()
        return False
