from dataclasses import dataclass

from .tokens import token


@dataclass(frozen=True)
class GridMetrics:
    dialog_width: float
    dialog_height: float
    columns: int
    card_width: float
    card_height: float
    thumb_height: float
    gap_x: float
    gap_y: float
    grid_x: float
    grid_y: float
    grid_width: float
    grid_height: float
    radius: float


def calculate_grid_metrics(window_width: float, window_height: float) -> GridMetrics:
    panel_padding = float(token("spacing", "panel_padding", 28.0))
    grid_gap = float(token("spacing", "grid_gap", 16.0))
    dialog_radius = float(token("shape", "dialog_radius", 24.0))
    dialog_width = min(1120.0, max(560.0, window_width - 40.0))
    dialog_height = min(760.0, max(420.0, window_height - 40.0))
    inner_width = dialog_width - panel_padding * 2.0
    columns = 4 if inner_width >= 1030 else 3 if inner_width >= 760 else 2
    gap_x = grid_gap
    card_width = min(360.0, max(248.0, (inner_width - gap_x * (columns - 1)) / columns))
    thumb_height = card_width * 9.0 / 16.0
    card_height = thumb_height + 44.0
    grid_y = 68.0 + 48.0
    grid_height = max(220.0, dialog_height - grid_y - 24.0)
    return GridMetrics(
        dialog_width, dialog_height, columns, card_width, card_height, thumb_height,
        gap_x, grid_gap, panel_padding, grid_y, inner_width, grid_height, dialog_radius,
    )
