#!/usr/bin/env bash
set -euo pipefail

profile_dir="${XDG_CONFIG_HOME:-$HOME/.config}/mpv-nyx"
default_scripts="${XDG_CONFIG_HOME:-$HOME/.config}/mpv/scripts"
args=("--config-dir=$profile_dir")

for script in uosc/main.lua thumbfast.lua autoload.lua sponsorblock.lua; do
    if [ -f "$default_scripts/$script" ]; then
        args+=("--script=$default_scripts/$script")
    fi
done

exec mpv "${args[@]}" "$@"
