"""Deploy subpackage — atomic swap, manifest, templates, assets, hardware,
preset, and the deploy orchestrator.

Re-exports keep external imports shallow (§13). For test patching, address the
defining submodule directly (e.g. nyxniri.deploy.atomic.atomic_replace_item).
"""

from nyxniri.deploy.atomic import atomic_replace_item
from nyxniri.deploy.manifest import (
    ModuleManifest,
    load_manifest,
    load_manifest_for,
    discover_manifest_apps,
    discover_deployable_apps,
    discover_optional_apps,
)
from nyxniri.deploy.templates import _phase_render_templates
from nyxniri.deploy.assets import (
    WallpaperDeployResult,
    deploy_wallpapers,
    wallpapers_pack_present,
)
from nyxniri.deploy.hardware import _phase_hardware_patches
from nyxniri.deploy.preset import (
    read_active_preset,
    write_active_preset,
    resolve_preset_src,
    apply_preset,
    collect_presets,
    list_presets,
    save_preset,
    delete_preset,
    edit_preset,
)
from nyxniri.deploy.deploy import (
    config_destination,
    discover_config_items,
    managed_bin_sources,
    _phase_atomic_deployment,
    _phase_post_install_services,
    render_completion_screen,
    deploy_selected_configs,
    test_deploy,
)

__all__ = [
    "atomic_replace_item", "config_destination", "discover_config_items",
    "managed_bin_sources", "deploy_selected_configs",
    "deploy_wallpapers", "wallpapers_pack_present", "render_completion_screen",
    "test_deploy",
    "read_active_preset", "write_active_preset", "resolve_preset_src",
    "apply_preset", "collect_presets", "list_presets", "save_preset",
    "delete_preset", "edit_preset",
    "load_manifest", "load_manifest_for", "discover_manifest_apps",
    "discover_deployable_apps", "discover_optional_apps", "ModuleManifest",
]
