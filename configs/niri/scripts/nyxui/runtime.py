import fcntl
import os
import signal
import sys
import time


def acquire_instance_lock(lock_path: str, pid_path: str) -> int:
    try:
        lock_fd = os.open(lock_path, os.O_CREAT | os.O_RDWR, 0o600)
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except (BlockingIOError, OSError):
        old_pid = None
        try:
            with open(pid_path, encoding="utf-8") as pid_file:
                old_pid = int(pid_file.read().strip())
            os.kill(old_pid, signal.SIGTERM)
        except (OSError, ValueError):
            pass
        if old_pid is not None:
            for _ in range(20):
                time.sleep(0.025)
                try:
                    os.kill(old_pid, 0)
                except OSError:
                    break
        sys.exit(0)
    try:
        with open(pid_path, "w", encoding="utf-8") as pid_file:
            pid_file.write(str(os.getpid()))
    except OSError:
        pass
    return lock_fd


def release_instance_lock(lock_fd: int | None, pid_path: str) -> None:
    try:
        if os.path.isfile(pid_path):
            os.remove(pid_path)
    except OSError:
        pass
    if lock_fd is not None:
        try:
            fcntl.flock(lock_fd, fcntl.LOCK_UN)
            os.close(lock_fd)
        except OSError:
            pass
