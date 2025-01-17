#!/bin/bash

# Function to convert hex color to RGB
hex_to_rgb() {
  hex=${1#"#"}
  r=$((16#${hex:0:2}))
  g=$((16#${hex:2:2}))
  b=$((16#${hex:4:2}))
  echo "$r $g $b"
}

# Function to calculate the distance between two colors
color_distance() {
  rgb1=($1)
  rgb2=($2)
  r_diff=$((rgb1[0] - rgb2[0]))
  g_diff=$((rgb1[1] - rgb2[1]))
  b_diff=$((rgb1[2] - rgb2[2]))
  echo $((r_diff * r_diff + g_diff * g_diff + b_diff * b_diff))
}

# Predefined Papirus colors with their approximate RGB values
declare -A papirus_colors
papirus_colors=(
  ["adwaita"]="239 241 244"
  ["black"]="0 0 0"
  ["blue"]="33 150 243"
  ["bluegrey"]="96 125 139"
  ["breeze"]="216 228 231"
  ["brown"]="121 85 72"
  ["carmine"]="196 30 58"
  ["cyan"]="0 188 212"
  ["darkcyan"]="0 139 139"
  ["deeporange"]="255 87 34"
  ["green"]="76 175 80"
  ["grey"]="158 158 158"
  ["indigo"]="63 81 181"
  ["magenta"]="255 0 255"
  ["nordic"]="0 97 153"
  ["orange"]="255 152 0"
  ["palebrown"]="188 170 164"
  ["paleorange"]="255 224 178"
  ["pink"]="233 30 99"
  ["red"]="244 67 54"
  ["teal"]="0 150 136"
  ["violet"]="138 43 226"
  ["white"]="255 255 255"
  ["yaru"]="226 83 1"
  ["yellow"]="255 235 59"
)

# Hardcoded color file path
color_file="$HOME/.local/state/ags/scss/_material.scss"

# Step 1: Read the primary color from the file
echo "Reading the primary color from the file..."
primary_color=$(grep '^$primary:' $color_file | cut -d ':' -f2 | tr -d ' ;')
echo "Primary color found: $primary_color"

# Step 2: Convert the primary color to RGB
if [[ $primary_color =~ ^#[0-9A-Fa-f]{6}$ ]]; then
  echo "Converting the color to RGB..."
  color_rgb=$(hex_to_rgb $primary_color)
  echo "RGB value: $color_rgb"
else
  echo "Invalid primary color format: $primary_color"
  exit 1
fi

# Step 3: Find the closest Papirus color
echo "Finding the closest Papirus color..."
closest_color=""
min_distance=-1

for papirus_color in "${!papirus_colors[@]}"; do
  papirus_rgb=${papirus_colors[$papirus_color]}
  distance=$(color_distance "$color_rgb" "$papirus_rgb")
  if [[ $min_distance -lt 0 || $distance -lt $min_distance ]]; then
    min_distance=$distance
    closest_color=$papirus_color
  fi
done
echo "Closest Papirus color: $closest_color"

# Step 4: Apply the closest color to all folders
echo "Applying the color to all folders..."
papirus-folders -C $closest_color
echo "Folder color change applied successfully!"
