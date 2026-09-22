#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/.local/share/wallpapers}"
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper-current"

next() {
    mapfile -t wallpapers < <(find -L "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.webp' \) -print | sort)

    if (( ${#wallpapers[@]} == 0 )); then
        echo "wallpaper-cycle: no wallpapers found in $WALLPAPER_DIR" >&2
        exit 1
    fi

    local i=0
    if [ -f "$STATE_FILE" ]; then
        local last
        last=$(cat "$STATE_FILE")
        for idx in "${!wallpapers[@]}"; do
            if [ "${wallpapers[$idx]}" = "$last" ]; then
                i=$(((idx + 1) % ${#wallpapers[@]}))
                break
            fi
        done
    fi

    set_wallpaper "${wallpapers[$i]}"
}

restore() {
    if [ -f "$STATE_FILE" ]; then
        set_wallpaper "$(cat "$STATE_FILE")"
    else
        next
    fi
}

set_wallpaper() {
    local wallpaper=$1
    awww img "$wallpaper"
    mkdir -p "$(dirname "$STATE_FILE")"
    printf '%s\n' "$wallpaper" > "$STATE_FILE"
}

case "${1:-next}" in
    restore) restore ;;
    *)       next ;;
esac