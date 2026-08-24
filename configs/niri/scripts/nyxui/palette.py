import os
from pathlib import Path

from .tokens import load_tokens

try:
    import tomllib
except ModuleNotFoundError:
    tomllib = None


def hex_to_rgb(hex_str: str, default=(0.5, 0.5, 0.5)):
    try:
        value = hex_str.strip().lstrip("#")
        if len(value) == 6:
            return tuple(int(value[index : index + 2], 16) / 255.0 for index in (0, 2, 4))
    except (TypeError, ValueError):
        pass
    return default


def _token_path() -> Path:
    configured = os.environ.get("NYXNIRI_TOKENS_FILE")
    if configured:
        return Path(os.path.expanduser(configured))
    return Path(os.path.expanduser("~/.config/niri/nyx-tokens.toml"))


def _load_fallback_tokens() -> dict:
    return load_tokens().get("color", {}).get("dark", {})


def _load_dynamic_palette() -> dict:
    path = Path(os.path.expanduser("~/.cache/noctalia/starship-palette.toml"))
    if tomllib is None or not path.is_file():
        return {}
    try:
        data = tomllib.loads(path.read_text(encoding="utf-8"))
        return data.get("palettes", {}).get("noctalia", {})
    except (OSError, tomllib.TOMLDecodeError):
        return {}


def load_material_palette() -> dict:
    fallback = _load_fallback_tokens()
    palette = {
        role: hex_to_rgb(fallback.get(role, value))
        for role, value in {
            "primary": "#62d8e7", "secondary": "#ff9f8e", "tertiary": "#f2c66d",
            "surface": "#111820", "surface_dim": "#0a0f14", "surface_bright": "#24313b",
            "on_surface": "#e6f1f4", "on_surface_var": "#a9bdc4", "outline": "#78929b", "error": "#ffb4ab",
        }.items()
    }
    dynamic = _load_dynamic_palette()
    mappings = {
        "blue": "primary", "sapphire": "primary", "primary": "primary",
        "teal": "secondary", "green": "secondary", "secondary": "secondary",
        "peach": "tertiary", "pink": "tertiary", "mauve": "tertiary", "yellow": "tertiary", "tertiary": "tertiary",
        "surface0": "surface", "surface1": "surface", "base": "surface", "crust": "surface_dim", "mantle": "surface_dim",
        "surface2": "surface_bright", "overlay0": "outline", "text": "on_surface", "white": "on_surface",
        "subtext0": "on_surface_var", "subtext1": "on_surface_var", "overlay2": "on_surface_var", "overlay1": "outline",
    }
    for key, role in mappings.items():
        if key in dynamic:
            palette[role] = hex_to_rgb(dynamic[key], palette[role])
    sr, sg, sb = palette["surface"]
    palette["is_dark"] = 0.299 * sr + 0.587 * sg + 0.114 * sb < 0.5
    return palette
