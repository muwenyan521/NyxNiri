#!/usr/bin/env bash
set -euo pipefail

token_file="${1:-${HOME}/.config/niri/nyx-tokens.toml}"
target="${2:-${HOME}/.config/mpv-nyx/script-opts/uosc.conf}"

color() {
    local key="$1"
    sed -nE "s/^${key}[[:space:]]*=[[:space:]]*\"(#[0-9A-Fa-f]{6})\"/\1/p" "$token_file" | head -n 1
}

[ -r "$token_file" ] || exit 0
mkdir -p "$(dirname "$target")"
primary="$(color primary)"
secondary="$(color secondary)"
tertiary="$(color tertiary)"
surface="$(color surface_dim)"
text="$(color on_surface)"
outline="$(color outline)"
error="$(color error)"

for value in primary secondary tertiary surface text outline error; do
    [ -n "${!value}" ] || exit 0
done

tmp="$(mktemp "$(dirname "$target")/.uosc.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
printf 'color=foreground=%s,foreground_text=%s,background=%s,background_text=%s,window_border=%s,curtain=%s,success=%s,error=%s,match=%s,heatmap=%s\n' \
    "${primary#\#}" "${surface#\#}" "${surface#\#}" "${text#\#}" "${outline#\#}" "${surface#\#}" "${tertiary#\#}" "${error#\#}" "${tertiary#\#}" "${secondary#\#}" > "$tmp"
if [ -f "$target" ]; then
    tail -n +2 "$target" >> "$tmp"
fi
chmod 644 "$tmp"
mv -f "$tmp" "$target"
trap - EXIT
