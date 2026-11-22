#!/usr/bin/env bash
# Convert chosen image/svg/pdf into Plymouth XANA watermark.png + bootsplash watermark.png and rebuild initramfs.
set -euo pipefail

SRC="${1:-}"
[ -f "$SRC" ] || { echo "Dosya bulunamadi: $SRC" >&2; exit 1; }

OUT_TMP="$(mktemp /tmp/xana-logo-XXXXXX.png)"
EXT="${SRC##*.}"
EXT="${EXT,,}"

case "$EXT" in
    pdf)
        SVG_TMP="$(mktemp /tmp/xana-logo-XXXXXX.svg)"
        pdftocairo -svg "$SRC" "$SVG_TMP"
        rsvg-convert -h 360 "$SVG_TMP" -o "$OUT_TMP"
        rm -f "$SVG_TMP"
        ;;
    svg)
        rsvg-convert -h 360 "$SRC" -o "$OUT_TMP"
        ;;
    *)
        magick "$SRC" -resize x360 "$OUT_TMP"
        ;;
esac

mkdir -p "$HOME/.config/hypr/custom/bootsplash"
cp "$OUT_TMP" "$HOME/.config/hypr/custom/bootsplash/watermark.png"

sudo cp "$OUT_TMP" /usr/share/plymouth/themes/xana/watermark.png
rm -f "$OUT_TMP"
sudo plymouth-set-default-theme -R xana
echo "✓ Boot splash logosu guncellendi."
