#!/usr/bin/env bash
set -euo pipefail

DIR="${1:-$(cd "$(dirname "$0")" && pwd)}"
ERRORS=0

compile() {
    local out="${1%.fnl}.lua"
    if ! fennel --use-bit-lib --compile "$1" > "$out" 2>&1; then
        echo "fail: ${1#"$DIR"/}" >&2
        ERRORS=$(( ERRORS + 1 ))
    else
        echo "pass: ${1#"$DIR"/}"
    fi
}

for dir in init.fnl plugin ftplugin after/plugin after/ftplugin; do
    target="$DIR/$dir"
    if [[ -f "$target" ]]; then
        compile "$target"
    elif [[ -d "$target" ]]; then
        while IFS= read -r f; do compile "$f"; done < <(find "$target" -name "*.fnl" | sort)
    fi
done

[[ $ERRORS -eq 0 ]] || exit 1
