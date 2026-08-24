#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
evidence="$root/docs/evidence/round6"
originals="$evidence/originals"

cd "$root"
sha256sum -c "$evidence/modified.sha256" >/dev/null

while read -r _ path; do
    mkdir -p "$(dirname "$path")"
    cp -a "$originals/$path" "$path"
done < "$evidence/baseline.sha256"

while read -r expected path; do
    if [ -e "$path" ]; then
        actual=$(sha256sum "$path" | awk '{print $1}')
        [ "$actual" = "$expected" ] || { printf 'Refusing to remove changed new file: %s\n' "$path" >&2; exit 1; }
        rm -f "$path"
    fi
done < "$evidence/new-files.sha256"

printf '%s\n' 'NyxNiri round6 rollback complete.'
