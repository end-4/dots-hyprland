#!/usr/bin/env bash
# Theme slots: snapshot the current theme so you can come back to it later.
# A snapshot = a COPY of the wallpaper (random downloads overwrite random_wallpaper.*)
# + light/dark mode + scheme type + 4 dominant colors of the image (for the preview
# swatches in Settings). Everything else regenerates deterministically via switchwall.sh.
#
#   theme-slots.sh save [N]    save current theme (slot N, or first free slot)
#   theme-slots.sh restore N   restore slot N
#   theme-slots.sh delete N    free slot N
#   theme-slots.sh list        print the JSON index
#
# N = 1..10. Index: ~/.local/state/quickshell/user/theme-slots/slots.json,
# an array of 10 entries (null = free) — consumed by QuickConfig.qml (FileView).
set -euo pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
DIR="$XDG_STATE_HOME/quickshell/user/theme-slots"
INDEX="$DIR/slots.json"
CFG="$XDG_CONFIG_HOME/illogical-impulse/config.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAX=10

mkdir -p "$DIR"
[ -s "$INDEX" ] || printf '[%s]' "$(printf 'null,%.0s' $(seq $((MAX - 1))))null" > "$INDEX"

die() { notify-send -a "Theme slots" "$1" "${2:-}" 2>/dev/null || true; echo "$1 ${2:-}" >&2; exit 1; }

idx_of() {  # N (1..10) -> index 0..9, validated
    [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le $MAX ] || die "Invalid slot" "$1 (expected 1..$MAX)"
    echo $(($1 - 1))
}

case "${1:-list}" in
save)
    if [ -n "${2:-}" ]; then
        i=$(idx_of "$2")
    else
        i=$(jq 'index(null) // -1' "$INDEX")
        [ "$i" -ge 0 ] || die "All slots are full" "Delete a slot in Settings to free up space."
    fi
    wall=$(jq -r '.background.wallpaperPath' "$CFG")
    [ -f "$wall" ] || die "Wallpaper not found" "$wall"
    mode=light
    gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | grep -q dark && mode=dark
    type=$(jq -r '.appearance.palette.type // "auto"' "$CFG")
    ext="${wall##*.}"
    rm -f "$DIR/slot$((i + 1))".*
    cp "$wall" "$DIR/slot$((i + 1)).$ext"
    # Dominant colors of the image (4 genuinely distinct hues), for the preview swatches.
    swatches=$(magick "$wall" -resize 64x64^ +dither -colors 4 -unique-colors txt:- 2>/dev/null \
        | grep -oE '#[0-9A-Fa-f]{6}' | head -4 | jq -R . | jq -cs .)
    [ -n "$swatches" ] && [ "$swatches" != "[]" ] || swatches='[]'
    jq --argjson i "$i" \
       --arg file "$DIR/slot$((i + 1)).$ext" --arg mode "$mode" --arg type "$type" \
       --arg date "$(date +%d/%m)" --argjson colors "$swatches" \
       '.[$i] = {file: $file, mode: $mode, type: $type, date: $date, colors: $colors}' \
       "$INDEX" > "$INDEX.tmp" && mv "$INDEX.tmp" "$INDEX"
    notify-send -a "Theme slots" "Theme saved" "Slot $((i + 1)) - $mode - $type" 2>/dev/null || true
    ;;
restore)
    i=$(idx_of "${2:?slot required}")
    entry=$(jq -c ".[$i]" "$INDEX")
    [ "$entry" != "null" ] || die "Empty slot" "Slot $((i + 1))"
    file=$(jq -r '.file' <<<"$entry"); mode=$(jq -r '.mode' <<<"$entry"); type=$(jq -r '.type' <<<"$entry")
    [ -f "$file" ] || die "Slot image is gone" "$file"
    jq --arg t "$type" '.appearance.palette.type = $t' "$CFG" > "$CFG.tmp" && mv "$CFG.tmp" "$CFG"
    exec "$SCRIPT_DIR/switchwall.sh" --image "$file" --mode "$mode"
    ;;
delete)
    i=$(idx_of "${2:?slot required}")
    file=$(jq -r ".[$i].file // empty" "$INDEX")
    # Refuse to delete the slot whose image is the CURRENT wallpaper (config points at
    # it after a restore): the background would vanish on the next reload.
    if [ -n "$file" ] && [ "$file" = "$(jq -r '.background.wallpaperPath' "$CFG")" ]; then
        die "Slot is active" "This slot is the current wallpaper - change wallpaper before deleting it."
    fi
    [ -n "$file" ] && rm -f "$file"
    jq --argjson i "$i" '.[$i] = null' "$INDEX" > "$INDEX.tmp" && mv "$INDEX.tmp" "$INDEX"
    ;;
list)
    cat "$INDEX"
    ;;
*)
    die "Unknown command" "$1"
    ;;
esac
