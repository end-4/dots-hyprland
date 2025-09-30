#!/usr/bin/env bash

# ==============================
# Use Catppuccin folder colors directly
# ==============================

# Read Matugen hex (or another input)
hex=$(<~/.config/matugen/papirus-folders/colors-papirus.txt)
hex=${hex#\#}
hex=$(echo "$hex" | tr '[:lower:]' '[:upper:]')

RR=${hex:0:2}
GG=${hex:2:2}
BB=${hex:4:2}

R1=$((16#$RR))
G1=$((16#$GG))
B1=$((16#$BB))

# Catppuccin Mocha palette (already valid Papirus folder names!)
declare -A colors=(
  [cat-mocha-blue]="#89B4FA"
  [cat-mocha-flamingo]="#F2CDCD"
  [cat-mocha-green]="#A6E3A1"
  [cat-mocha-lavender]="#B4BEFE"
  [cat-mocha-maroon]="#EBA0AC"
  [cat-mocha-mauve]="#CBA6F7"
  [cat-mocha-peach]="#FAB387"
  [cat-mocha-pink]="#F5C2E7"
  [cat-mocha-red]="#F38BA8"
  [cat-mocha-rosewater]="#F5E0DC"
  [cat-mocha-sapphire]="#74C7EC"
  [cat-mocha-sky]="#89DCEB"
  [cat-mocha-teal]="#94E2D5"
  [cat-mocha-yellow]="#F9E2AF"
)

# Find nearest Catppuccin color
min_dist=999999
closest_color=""

for color_name in "${!colors[@]}"; do
    palette_hex=${colors[$color_name]}
    palette_hex=${palette_hex#\#}
    palette_hex=$(echo "$palette_hex" | tr '[:lower:]' '[:upper:]')

    RR=${palette_hex:0:2}
    GG=${palette_hex:2:2}
    BB=${palette_hex:4:2}

    R2=$((16#$RR))
    G2=$((16#$GG))
    B2=$((16#$BB))

    ((diff_R = R1 - R2))
    ((diff_G = G1 - G2))
    ((diff_B = B1 - B2))
    ((dist = diff_R * diff_R + diff_G * diff_G + diff_B * diff_B))

    if (( dist < min_dist )); then
        min_dist=$dist
        closest_color=$color_name
    fi
done

echo "Closest Catppuccin color: $closest_color"
papirus-folders -C "$closest_color"
gtk-update-icon-cache
