import os
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:
    tomllib = None


def _path() -> Path:
    configured = os.environ.get("NYXNIRI_TOKENS_FILE")
    if configured:
        return Path(os.path.expanduser(configured))
    return Path(os.path.expanduser("~/.config/niri/nyx-tokens.toml"))


def load_tokens() -> dict:
    if tomllib is None:
        return {}
    path = _path()
    if not path.is_file():
        source = Path(__file__).resolve().parents[4] / "design" / "tokens.toml"
        path = source if source.is_file() else path
    try:
        return tomllib.loads(path.read_text(encoding="utf-8"))
    except (OSError, tomllib.TOMLDecodeError):
        return {}


def token(section: str, name: str, default):
    return load_tokens().get(section, {}).get(name, default)
