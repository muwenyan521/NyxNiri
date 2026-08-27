"""TUI component and terminal presentation engine (Native ANSI + Standard Library)."""

import atexit
import os
import re
import select
import shutil
import signal
import sys
import termios
import time
import tty
import unicodedata
from contextlib import ExitStack, contextmanager
from dataclasses import dataclass
from typing import Any, Callable, List, Optional, Tuple

from nyxniri.constants import Colors
from nyxniri.core import Environment, get_env
from nyxniri.i18n import msg

ANSI_ESCAPE_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")


class TerminalGuard:
    """Fail-safe guard that guarantees terminal attributes and cursor visibility are restored."""
    _orig_attr: Optional[List[Any]] = None
    _initialized: bool = False

    @classmethod
    def init(cls) -> None:
        if cls._initialized:
            return
        if sys.stdin.isatty():
            try:
                cls._orig_attr = termios.tcgetattr(sys.stdin.fileno())
            except Exception:
                cls._orig_attr = None
            atexit.register(cls.restore)
            signal.signal(signal.SIGINT, cls._sig_handler)
            signal.signal(signal.SIGTERM, cls._sig_handler)
        cls._initialized = True

    @classmethod
    def restore(cls) -> None:
        if cls._orig_attr and sys.stdin.isatty():
            try:
                termios.tcsetattr(sys.stdin.fileno(), termios.TCSADRAIN, cls._orig_attr)
            except Exception:
                pass
        sys.stdout.write(Colors.CURSOR_SHOW)
        sys.stdout.flush()

    @classmethod
    def _sig_handler(cls, signum: int, frame: Any) -> None:
        cls.restore()
        sys.stdout.write("\n")
        sys.exit(130)


TerminalGuard.init()


# --- Geometric Column Alignment ---
def display_width(text: str) -> int:
    """Calculate the real physical terminal column width of a string (CJK = 2 cols)."""
    clean_text = ANSI_ESCAPE_RE.sub("", text)
    return sum(
        0 if unicodedata.combining(ch) else 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
        for ch in clean_text
    )


def pad_display(text: str, width: int) -> str:
    """Pad string with trailing spaces to achieve exact visual column alignment."""
    curr = display_width(text)
    if curr < width:
        return text + (" " * (width - curr))
    return text


def truncate_display(text: str, width: int, suffix: str = "…") -> str:
    """Clip ANSI-styled text to a physical terminal width without splitting CJK glyphs."""
    if width <= 0:
        return ""
    if display_width(text) <= width:
        return text

    suffix_width = display_width(suffix)
    content_width = max(0, width - suffix_width)
    output: List[str] = []
    used = 0
    pos = 0
    while pos < len(text):
        match = ANSI_ESCAPE_RE.match(text, pos)
        if match:
            output.append(match.group(0))
            pos = match.end()
            continue
        char = text[pos]
        char_width = 0 if unicodedata.combining(char) else 2 if unicodedata.east_asian_width(char) in ("W", "F") else 1
        if used + char_width > content_width:
            break
        output.append(char)
        used += char_width
        pos += 1
    reset = Colors.RESET if ANSI_ESCAPE_RE.search(text) else ""
    return "".join(output) + suffix + reset


def responsive_hint(key: str) -> str:
    """Use compact control hints when the terminal cannot hold the full legend."""
    if shutil.get_terminal_size((80, 24)).columns >= 72:
        return msg(key)
    short_keys = {
        "menu_hint": "menu_hint_short",
        "submenu_hint": "submenu_hint_short",
        "selective_hint": "checklist_hint_short",
        "delete_snapshot_hint": "checklist_hint_short",
        "dep_menu_hint": "checklist_hint_short",
        "opt_apps_menu_hint": "checklist_hint_short",
        "summary_action_hint": "summary_action_hint_short",
        "preset_switcher_hint": "preset_switcher_hint_short",
    }
    return msg(short_keys.get(key, key))


# --- Single Key Event Listener ---
def read_key() -> str:
    """Listen for a single keyboard event using raw unbuffered OS file descriptor reads."""
    if not sys.stdin.isatty():
        return "ENTER"

    fd = sys.stdin.fileno()
    old_attr = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        raw_bytes = os.read(fd, 1)
        if not raw_bytes:
            return "EOF"
        if raw_bytes == b"\x1b":
            ready, _, _ = select.select([fd], [], [], 0.05)
            if ready:
                raw_bytes += os.read(fd, 31)

        # 1. Standalone ESC
        if raw_bytes == b"\x1b":
            return "ESC"

        # 2. Arrow keys (CSI: \x1b[ and SS3: \x1bO)
        if raw_bytes in (b"\x1b[A", b"\x1bOA"):
            return "UP"
        if raw_bytes in (b"\x1b[B", b"\x1bOB"):
            return "DOWN"
        if raw_bytes in (b"\x1b[C", b"\x1bOC"):
            return "RIGHT"
        if raw_bytes in (b"\x1b[D", b"\x1bOD"):
            return "LEFT"

        # 3. CSI Extended keys (Home, End, PageUp, PageDown)
        if raw_bytes.startswith(b"\x1b["):
            code = raw_bytes[2:]
            if code in (b"H", b"1~"):
                return "HOME"
            if code in (b"F", b"4~"):
                return "END"
            if code == b"5~":
                return "PAGEUP"
            if code == b"6~":
                return "PAGEDOWN"
            return "ESC"

        # 4. Standard control keys
        if raw_bytes in (b"\r", b"\n"):
            return "ENTER"
        if raw_bytes == b" ":
            return "SPACE"
        if raw_bytes in (b"\x03", b"\x04"):  # Ctrl+C / Ctrl+D — both exit
            return "EXIT"

        # 5. Normal UTF-8 single character
        try:
            return raw_bytes.decode("utf-8")
        except UnicodeDecodeError:
            return ""
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_attr)

# --- Loop-scoped raw input (kills the cooked-echo window between keys) ---
def _swallow_repeat(fd: int, quiet: float = 0.05, cap: float = 2.0) -> None:
    """Keep draining bytes until `quiet` seconds pass with no new input.

    Absorbs an OS auto-repeat burst (held key) until the user releases, so the
    repeated bytes don't feed the next read_key() and cascade. The quiet window
    (~50ms) reliably exceeds a standard ~33ms auto-repeat interval, so silence
    means release. Hard-capped so a runaway stream can't pin the loop.
    """
    end = time.time() + cap
    while time.time() < end:
        ready, _, _ = select.select([fd], [], [], quiet)
        if not ready:
            return  # quiet window elapsed → key released
        try:
            if os.read(fd, 64) == b"":
                return
        except OSError:
            return


def _drain_pending(fd: int, debounce: bool = False) -> None:
    """Discard pending input; optionally debounce-swallow the auto-repeat tail.

    Two modes:
    - ``debounce=False`` (component *entry*): one non-blocking sweep of bytes
      already queued from the previous component. No wait if empty → zero
      latency on a clean transition.
    - ``debounce=True`` (after an *action* key, e.g. the Enter that confirms):
      sweep, then keep swallowing until a quiet window — the OS auto-repeat
      stream arrives ~30ms *after* the legitimate key, so a snapshot sweep
      runs in the gap and misses it; only a timed quiet-wait catches the tail.
      Called in each loop's ``finally`` so every exit (the action that caused it)
      drains its own repeat burst before the next component reads.

    A held Enter otherwise cascades: repeat bytes feed the next read_key().
    """
    found = False
    while True:
        ready, _, _ = select.select([fd], [], [], 0)
        if not ready:
            break
        try:
            if os.read(fd, 64) == b"":
                return
        except OSError:
            return
        found = True
    if debounce or found:
        _swallow_repeat(fd)


@contextmanager
def raw_input_mode(fd: int):
    """Hold stdin in echo-off raw mode for an interactive loop's duration.

    read_key() toggles raw↔cooked per call; the cooked echo window between calls
    echoed held/auto-repeated Enter as newlines and let the buffered bytes
    cascade into the next prompt. Holding raw for the whole loop removes that
    window. OPOST is re-enabled so the loop's ``\\n`` renders still become
    ``\\r\\n`` (no staircase); ISIG stays off so Ctrl+C arrives as ``\\x03``
    (handled as EXIT, same as the per-call read_key path).

    No-op when stdin is not a real tty: tests patch isatty + read_key, the real
    fd isn't a tty, tcgetattr raises and we skip — the loop then reads the patch.
    """
    old = None
    try:
        if sys.stdin.isatty():
            old = termios.tcgetattr(fd)
            tty.setraw(fd)
            new = termios.tcgetattr(fd)
            new[1] |= termios.OPOST  # keep \n -> \r\n translation on output
            termios.tcsetattr(fd, termios.TCSANOW, new)
    except Exception:
        old = None
    try:
        yield
    finally:
        if old is not None:
            try:
                termios.tcsetattr(fd, termios.TCSADRAIN, old)
            except Exception:
                pass


def drain_stdin() -> None:
    """Drain pending input for cooked-line callers (snapshot note / rollback index).

    A brief raw pass that reliably discards leftover bytes (canonical mode's
    select+read is unreliable for partial lines), then restores cooked for readline.
    """
    if not sys.stdin.isatty():
        return
    with raw_input_mode(sys.stdin.fileno()):
        _drain_pending(sys.stdin.fileno())

# --- Rendering Primitives & Screen Cleaners ---
def clear_screen() -> None:
    """Clear the visible terminal without destroying scrollback history."""
    if sys.stdin.isatty():
        sys.stdout.write("\033[2J\033[H")
        sys.stdout.flush()

def write_cleared(text: str) -> None:
    """Write text, ensuring each line has \\033[K before \\n to wipe right-side ghost chars."""
    if not text:
        return
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if i == len(lines) - 1:
            sys.stdout.write(line)
        else:
            sys.stdout.write(f"{line}\033[K\n")

def show_logo(env: Optional[Environment] = None) -> None:
    """Render the official NyxNiri ASCII brand header."""
    if env is None:
        env = get_env()

    terminal = shutil.get_terminal_size((80, 24))
    if terminal.columns < 66 or terminal.lines < 20:
        mode_line = truncate_display(f"Mode: {env.mode_label} ({env.repo_dir})", max(12, terminal.columns - 4))
        logo = (
            f"{Colors.BOLD_PURPLE}\n  NYX NIRI{Colors.RESET}  "
            f"{Colors.BOLD_WHITE}{env.version}{Colors.RESET}\n"
            f"  {Colors.DARK_GRAY}{mode_line}{Colors.RESET}\n\n"
        )
        write_cleared(logo)
        return

    mode_line = truncate_display(
        f"Mode: {env.mode_label} ({env.repo_dir})",
        max(12, terminal.columns - 4),
    )
    logo = (
        f"{Colors.BOLD_PURPLE}\n"
        " ███╗   ██╗██╗   ██╗██╗  ██╗    ███╗   ██╗██╗██████╗ ██╗\n"
        " ████╗  ██║╚██╗ ██╔╝╚██╗██╔╝    ████╗  ██║██║██╔══██╗██║\n"
        " ██╔██╗ ██║ ╚████╔╝  ╚███╔╝     ██╔██╗ ██║██║██████╔╝██║\n"
        " ██║╚██╗██║  ╚██╔╝   ██╔██╗     ██║╚██╗██║██║██╔══██╗██║\n"
        " ██║ ╚████║   ██║   ██╔╝ ██╗    ██║ ╚████║██║██║  ██║██║\n"
        " ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝    ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝\n"
        f"{Colors.RESET}\n"
        f"  {Colors.BOLD_CYAN}Noctalia V5 & Niri Desktop Environment Setup{Colors.RESET} {Colors.DARK_GRAY}|{Colors.RESET} {Colors.BOLD_WHITE}{env.version}{Colors.RESET}\n"
        f"  {Colors.DARK_GRAY}{mode_line}{Colors.RESET}\n\n"
    )
    write_cleared(logo)

def render_menu_item(idx: int, label: str, focus: int, style: str = "normal") -> None:
    """Render a single interactive menu row with line-level erase."""
    if idx == focus:
        prefix = f"  {Colors.BOLD_CYAN}❯ {Colors.RESET}"
        if style == "warn":
            color = Colors.BOLD_RED
        elif style == "subtle":
            color = Colors.DARK_GRAY
        else:
            color = Colors.BOLD_WHITE
    else:
        prefix = "    "
        if style == "warn":
            color = Colors.RED
        elif style == "subtle":
            color = Colors.DARK_GRAY
        else:
            color = ""
    available = max(1, shutil.get_terminal_size((80, 24)).columns - display_width(prefix) - 1)
    clipped_label = truncate_display(label, available)
    sys.stdout.write(f"{prefix}{color}{clipped_label}{Colors.RESET}\033[K\n")

def render_check_row(is_focus: bool, check_str: str, label: str) -> None:
    """Render a single checkbox item row with line-level erase."""
    prefix = f"  {Colors.BOLD_CYAN}❯ {Colors.RESET}" if is_focus else "    "
    available = max(
        1,
        shutil.get_terminal_size((80, 24)).columns
        - display_width(prefix)
        - display_width(check_str)
        - 2,
    )
    clipped_label = truncate_display(label, available)
    if is_focus:
        sys.stdout.write(
            f"  {Colors.BOLD_CYAN}❯ {Colors.RESET}{check_str} "
            f"{Colors.BOLD_WHITE}{clipped_label}{Colors.RESET}\033[K\n"
        )
    else:
        sys.stdout.write(f"    {check_str} {clipped_label}\033[K\n")

def press_any_key() -> None:
    """Prompt to press any key to continue."""
    if sys.stdin.isatty():
        fd = sys.stdin.fileno()
        sys.stdout.write(msg("press_any_key"))
        sys.stdout.flush()
        with raw_input_mode(fd):
            _drain_pending(fd)
            read_key()
            _drain_pending(fd, debounce=True)
        sys.stdout.write("\n")

def prompt_confirm(prompt_key: str, default: str = "y") -> bool:
    """Bilingual prompt confirmation (True for Yes, False for No).

    Single-key raw read (y/n/Enter=default/Esc/Ctrl+C=No). Only the first char
    ever mattered under the old readline path (``line.lower().startswith('y')``),
    so raw single-key is equivalent — and it can't echo a stale buffered Enter.
    """
    if os.environ.get("NYXNIRI_AUTO_YES", "0") == "1":
        return True

    sys.stdout.write(msg(prompt_key))
    sys.stdout.flush()
    if not sys.stdin.isatty():
        return default.lower().startswith("y")

    fd = sys.stdin.fileno()
    with raw_input_mode(fd):
        _drain_pending(fd)
        key = read_key()
        _drain_pending(fd, debounce=True)
    sys.stdout.write("\n")
    if key in ("y", "Y"):
        return True
    if key == "ENTER":
        return default.lower().startswith("y")
    return False  # n/N/Esc/Ctrl+C/any other → No (safe cancel)

# --- Component: Interactive Menu ---
@dataclass
class MenuItem:
    label: str
    action: Any = None
    style: str = "normal"
    group_header: Optional[str] = None


class Menu:
    def __init__(self, title_key: str, items: List[MenuItem], hint_key: str = "menu_hint"):
        self.title_key = title_key
        self.items = items
        self.hint_key = hint_key

    def run(self, initial_focus: int = 0) -> int:
        """Run interactive menu loop and return the selected item index."""
        if not sys.stdin.isatty():
            return len(self.items) - 1

        clear_screen()
        focus = initial_focus
        max_idx = len(self.items) - 1
        env = get_env()

        sys.stdout.write(Colors.CURSOR_HIDE)
        fd = sys.stdin.fileno()
        stack = ExitStack()
        stack.enter_context(raw_input_mode(fd))
        try:
            _drain_pending(fd)
            while True:
                sys.stdout.write("\033[?25l\033[H")
                show_logo(env)
                title = msg(self.title_key).strip("\n")
                write_cleared(f"{title}\n\n")

                terminal_lines = shutil.get_terminal_size((80, 24)).lines
                visible_count = max(3, terminal_lines - 18)
                start = max(0, min(focus - visible_count // 2, len(self.items) - visible_count))
                end = min(len(self.items), start + visible_count)
                if start > 0:
                    write_cleared(f"    {Colors.DARK_GRAY}...{Colors.RESET}\n")
                for curr_idx in range(start, end):
                    item = self.items[curr_idx]
                    if item.group_header:
                        header = truncate_display(
                            item.group_header,
                            max(1, shutil.get_terminal_size((80, 24)).columns - 1),
                        )
                        write_cleared(f"{header}\n")
                    render_menu_item(curr_idx, item.label, focus, item.style)
                if end < len(self.items):
                    write_cleared(f"    {Colors.DARK_GRAY}...{Colors.RESET}\n")

                hint = responsive_hint(self.hint_key).strip("\n")
                write_cleared(f"\n{hint}\n")
                sys.stdout.write("\033[J")
                sys.stdout.flush()

                key = read_key()
                if key in ("UP", "k", "K", "LEFT", "h", "H"):
                    focus = max_idx if focus <= 0 else focus - 1
                elif key in ("DOWN", "j", "J", "RIGHT", "l", "L"):
                    focus = 0 if focus >= max_idx else focus + 1
                elif key in ("ENTER", "SPACE"):
                    return focus
                elif key.isdigit() and 1 <= int(key) <= len(self.items):
                    return int(key) - 1
                elif key in ("0", "q", "Q"):
                    return max_idx
                elif key in ("ESC", "EXIT"):
                    return max_idx
        finally:
            _drain_pending(fd, debounce=True)
            stack.close()
            sys.stdout.write(Colors.CURSOR_SHOW)
            sys.stdout.flush()

# --- Component: Checkbox Checklist ---
@dataclass
class CheckboxEntry:
    key: str
    label: str
    checked: bool = False
    is_separator: bool = False


class CheckboxList:
    def __init__(self, title_key: str, entries: List[CheckboxEntry], hint_key: str = "selective_hint"):
        self.title_key = title_key
        self.entries = entries
        self.hint_key = hint_key

    def run(self, accept_defaults: bool = False) -> Optional[List[str]]:
        """Run checkbox selection loop. Returns list of selected keys, or None if cancelled."""
        if not any(not entry.is_separator for entry in self.entries):
            return []
        if not sys.stdin.isatty():
            if accept_defaults:
                return [e.key for e in self.entries if not e.is_separator and e.checked]
            return None

        clear_screen()
        selectable = [idx for idx, entry in enumerate(self.entries) if not entry.is_separator]
        focus_pos = 0

        env = get_env()
        sys.stdout.write(Colors.CURSOR_HIDE)
        fd = sys.stdin.fileno()
        stack = ExitStack()
        stack.enter_context(raw_input_mode(fd))
        try:
            _drain_pending(fd)
            while True:
                sys.stdout.write("\033[?25l\033[H")
                show_logo(env)
                title = msg(self.title_key).strip("\n")
                write_cleared(f"{title}\n\n")

                focus = selectable[focus_pos]
                terminal_lines = shutil.get_terminal_size((80, 24)).lines
                visible_count = max(4, terminal_lines - 18)
                start = max(
                    0,
                    min(focus - visible_count // 2, len(self.entries) - visible_count),
                )
                end = min(len(self.entries), start + visible_count)
                if start > 0:
                    write_cleared(f"    {Colors.DARK_GRAY}...{Colors.RESET}\n")
                for idx in range(start, end):
                    entry = self.entries[idx]
                    if entry.is_separator:
                        write_cleared(f"{entry.label}\n")
                        continue

                    check_str = (
                        f"{Colors.BOLD_GREEN}[✓]{Colors.RESET}"
                        if entry.checked
                        else f"{Colors.DARK_GRAY}[ ]{Colors.RESET}"
                    )
                    render_check_row(idx == focus, check_str, entry.label)
                if end < len(self.entries):
                    write_cleared(f"    {Colors.DARK_GRAY}...{Colors.RESET}\n")

                hint = responsive_hint(self.hint_key).strip("\n")
                write_cleared(f"\n{hint}\n")
                sys.stdout.write("\033[J")
                sys.stdout.flush()

                key = read_key()
                if key in ("UP", "k", "K", "LEFT", "h", "H"):
                    focus_pos = (focus_pos - 1) % len(selectable)
                elif key in ("DOWN", "j", "J", "RIGHT", "l", "L"):
                    focus_pos = (focus_pos + 1) % len(selectable)
                elif key == "SPACE":
                    self.entries[focus].checked = not self.entries[focus].checked
                elif key in ("a", "A"):
                    for e in self.entries:
                        if not e.is_separator:
                            e.checked = True
                elif key in ("n", "N"):
                    for e in self.entries:
                        if not e.is_separator:
                            e.checked = False
                elif key in ("0", "q", "Q", "ESC", "EXIT"):
                    return None
                elif key.isdigit():
                    num = int(key) - 1
                    if 0 <= num < len(selectable):
                        focus_pos = num
                        entry_idx = selectable[focus_pos]
                        self.entries[entry_idx].checked = not self.entries[entry_idx].checked
                elif key == "ENTER":
                    return [e.key for e in self.entries if not e.is_separator and e.checked]
        finally:
            _drain_pending(fd, debounce=True)
            stack.close()
            sys.stdout.write(Colors.CURSOR_SHOW)
            sys.stdout.flush()

# --- Component: Dual-Pane Preset Switcher (§9) ---
class PresetSwitcher:
    """Two-column preset switcher: left = apps, right = presets of the focused app.

    The ranger/mc model: one cursor that lives in one pane at a time. ←/→ move
    the cursor between panes; ↑/↓ move within the active pane. Enter applies the
    (focused app, focused preset) pair; q/ESC cancels. The active preset is
    always marked ``>``; the focused app's preset list re-renders on switch,
    landing its cursor on the active preset.

    Decoupled from deploy/preset: the caller supplies the app list and a
    callback returning ``[(preset_name, is_active)]`` for an app. ``run()``
    returns the chosen ``(app, preset)`` pair, or None on cancel.
    """

    def __init__(
        self,
        apps: List[str],
        presets_for: Callable[[str], List[Tuple[str, bool]]],
        title_key: str = "preset_switcher_title",
        hint_key: str = "preset_switcher_hint",
    ):
        self.apps = apps
        self.presets_for = presets_for
        self.title_key = title_key
        self.hint_key = hint_key

    def run(self) -> Optional[Tuple[str, str]]:
        if not self.apps or not sys.stdin.isatty():
            return None
        env = get_env()
        left = 0
        pane = "left"
        right_cache: dict = {}
        right_idx = 0

        def right_items(app: str) -> List[Tuple[str, bool]]:
            if app not in right_cache:
                right_cache[app] = list(self.presets_for(app))
            return right_cache[app]

        def land_on_active(app: str) -> int:
            for i, (_, is_active) in enumerate(right_items(app)):
                if is_active:
                    return i
            return 0

        right_idx = land_on_active(self.apps[left])
        sys.stdout.write(Colors.CURSOR_HIDE)
        fd = sys.stdin.fileno()
        stack = ExitStack()
        stack.enter_context(raw_input_mode(fd))
        try:
            _drain_pending(fd)
            while True:
                sys.stdout.write("\033[?25l\033[H")
                show_logo(env)
                title = msg(self.title_key).strip("\n")
                write_cleared(f"{title}\n\n")

                app = self.apps[left]
                presets = right_items(app)
                size = shutil.get_terminal_size((80, 24))
                cols, terminal_lines = size.columns, size.lines
                left_w = min(24, max(8, cols // 3))
                gap = 3
                right_w = max(8, cols - left_w - gap - 4)

                hdr_l = msg("preset_switcher_col_app")
                hdr_r = msg("preset_switcher_col_preset", app)
                write_cleared(
                    f"  {Colors.BOLD_WHITE}{pad_display(hdr_l, left_w)}{Colors.RESET}"
                    f"{' ' * gap}{Colors.BOLD_WHITE}{truncate_display(hdr_r, right_w)}{Colors.RESET}\n"
                )
                write_cleared(
                    f"  {Colors.DARK_GRAY}{'─' * left_w}{Colors.RESET}"
                    f"{' ' * gap}{Colors.DARK_GRAY}{'─' * min(right_w, 16)}{Colors.RESET}\n"
                )

                rows = max(len(self.apps), len(presets))
                visible = max(4, terminal_lines - 16)
                active_cursor = left if pane == "left" else right_idx
                start = max(0, min(active_cursor - visible // 2, rows - visible))
                end = min(rows, start + visible)
                if start > 0:
                    write_cleared(f"  {Colors.DARK_GRAY}...{Colors.RESET}\n")
                for i in range(start, end):
                    # left cell
                    if i < len(self.apps):
                        a = self.apps[i]
                        is_left_focus = i == left
                        if pane == "left" and is_left_focus:
                            lpre = f"{Colors.BOLD_CYAN}❯ {Colors.RESET}"
                            lcol = Colors.BOLD_WHITE
                        elif is_left_focus:
                            lpre = f"{Colors.DARK_GRAY}❯ {Colors.RESET}"
                            lcol = Colors.DARK_GRAY
                        else:
                            lpre = "  "
                            lcol = ""
                        lcell = f"{lpre}{lcol}{truncate_display(a, left_w - 2)}{Colors.RESET}"
                    else:
                        lcell = ""
                    # right cell
                    if i < len(presets):
                        pname, is_active = presets[i]
                        marker = f"{Colors.BOLD_GREEN}>{Colors.RESET}" if is_active else " "
                        if pane == "right" and i == right_idx:
                            rpre = f"{Colors.BOLD_CYAN}❯ {Colors.RESET}"
                            rcol = Colors.BOLD_WHITE
                        else:
                            rpre = "  "
                            rcol = ""
                        rcell = f"{rpre}{marker} {rcol}{truncate_display(pname, right_w - 4)}{Colors.RESET}"
                    else:
                        rcell = ""
                    write_cleared(f"  {pad_display(lcell, left_w + 2)}{' ' * gap}{rcell}\033[K\n")
                if end < rows:
                    write_cleared(f"  {Colors.DARK_GRAY}...{Colors.RESET}\n")

                hint = responsive_hint(self.hint_key).strip("\n")
                write_cleared(f"\n{hint}\n")
                sys.stdout.write("\033[J")
                sys.stdout.flush()

                key = read_key()
                if key in ("LEFT", "h", "H"):
                    pane = "left"
                elif key in ("RIGHT", "l", "L"):
                    if presets:
                        pane = "right"
                elif key in ("UP", "k", "K"):
                    if pane == "left":
                        left = (left - 1) % len(self.apps)
                        right_idx = land_on_active(self.apps[left])
                    elif presets:
                        right_idx = (right_idx - 1) % len(presets)
                elif key in ("DOWN", "j", "J"):
                    if pane == "left":
                        left = (left + 1) % len(self.apps)
                        right_idx = land_on_active(self.apps[left])
                    elif presets:
                        right_idx = (right_idx + 1) % len(presets)
                elif key in ("ENTER", "SPACE"):
                    if presets:
                        return (self.apps[left], presets[right_idx][0])
                elif key in ("0", "q", "Q", "ESC", "EXIT"):
                    return None
        finally:
            _drain_pending(fd, debounce=True)
            stack.close()
            sys.stdout.write(Colors.CURSOR_SHOW)
            sys.stdout.flush()

# --- Component: Language Selection ---
def select_language() -> str:
    """Prompt user to select language mode with smooth arrow keys."""
    if not sys.stdin.isatty():
        from nyxniri.i18n import get_lang
        return get_lang()

    clear_screen()
    from nyxniri.i18n import set_lang
    env = get_env()
    focus = 1  # Default to Simplified Chinese

    sys.stdout.write(Colors.CURSOR_HIDE)
    fd = sys.stdin.fileno()
    stack = ExitStack()
    stack.enter_context(raw_input_mode(fd))
    try:
        _drain_pending(fd)
        while True:
            sys.stdout.write("\033[?25l\033[H")
            show_logo(env)
            write_cleared(f"  {Colors.BOLD_CYAN}── 请选择语言 / Select Language ──{Colors.RESET}\n\n")

            if focus == 0:
                sys.stdout.write(f"  {Colors.BOLD_CYAN}❯ {Colors.BOLD_WHITE}English{Colors.RESET}\033[K\n")
                sys.stdout.write(f"    {Colors.DARK_GRAY}简体中文 (Simplified Chinese){Colors.RESET}\033[K\n")
            else:
                sys.stdout.write(f"    {Colors.DARK_GRAY}English{Colors.RESET}\033[K\n")
                sys.stdout.write(f"  {Colors.BOLD_CYAN}❯ {Colors.BOLD_WHITE}简体中文 (Simplified Chinese){Colors.RESET}\033[K\n")

            hint = "[↑/↓] Move  [Enter] Select"
            write_cleared(f"\n  {Colors.DARK_GRAY}{hint}{Colors.RESET}\n")
            sys.stdout.write("\033[J")
            sys.stdout.flush()

            key = read_key()
            if key in ("UP", "k", "K", "LEFT", "h", "H", "1"):
                focus = 0
            elif key in ("DOWN", "j", "J", "RIGHT", "l", "L", "2"):
                focus = 1
            elif key in ("ENTER", "SPACE"):
                chosen = "en" if focus == 0 else "zh"
                set_lang(chosen)
                clear_screen()
                return chosen
            elif key in ("ESC", "EXIT"):
                sys.exit(130)
    finally:
        _drain_pending(fd, debounce=True)
        stack.close()
        sys.stdout.write(Colors.CURSOR_SHOW)
        sys.stdout.flush()
