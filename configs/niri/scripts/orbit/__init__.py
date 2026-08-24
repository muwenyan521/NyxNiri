from importlib import import_module

__all__ = ["OrbitLauncher", "acquire_instance_lock", "release_instance_lock"]


def __getattr__(name: str):
    if name == "OrbitLauncher":
        return import_module(".window", __name__).OrbitLauncher
    if name in {"acquire_instance_lock", "release_instance_lock"}:
        return getattr(import_module(".lock", __name__), name)
    raise AttributeError(name)
