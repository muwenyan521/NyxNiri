#!/usr/bin/env bash
set -euo pipefail

profile_dir="${XDG_CONFIG_HOME:-$HOME/.config}/mpv-nyx"
default_scripts="${XDG_CONFIG_HOME:-$HOME/.config}/mpv/scripts"
args=("--config-dir=$profile_dir")

if ! command -v mpv >/dev/null 2>&1; then
    printf '%s\n' "NyxMPV: mpv is not installed." >&2
    exit 127
fi

if [ "${NYXNIRI_MPV_DIAGNOSTICS:-0}" = "1" ]; then
    printf 'NyxMPV profile: %s\n' "$profile_dir" >&2
    printf 'NyxMPV optional scripts:' >&2
    for script in uosc/main.lua thumbfast.lua autoload.lua sponsorblock.lua; do
        if [ -f "$default_scripts/$script" ]; then
            printf ' %s' "$script" >&2
        else
            printf ' %s(missing)' "$script" >&2
        fi
    done
    printf '\n' >&2
fi

if [ -n "${WAYLAND_DISPLAY:-}" ] && mpv --gpu-context=help 2>&1 | grep -Eq '(^|[[:space:]])wayland([[:space:]]|$)'; then
    args+=("--gpu-context=wayland")
fi

for script in uosc/main.lua thumbfast.lua autoload.lua sponsorblock.lua; do
    if [ -f "$default_scripts/$script" ]; then
        args+=("--script=$default_scripts/$script")
    fi
done

exec mpv "${args[@]}" "$@"
