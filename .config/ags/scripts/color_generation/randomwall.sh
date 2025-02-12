#!/usr/bin/env bash

WallSwitch="$HOME/.config/ags/scripts/color_generation/switchwall.sh"
RecentWallpapersFile="$HOME/.config/ags/switched_wallpapers.txt"
MaxRecentWallpapers=1  # Number of recent wallpapers to remember

mkdir -p "$(dirname "$RecentWallpapersFile")"
touch "$RecentWallpapersFile"
cleanup_recent_wallpapers() {
  if [ "$(wc -l < "$RecentWallpapersFile")" -gt "$MaxRecentWallpapers" ]; then
    head -n -"$MaxRecentWallpapers" "$RecentWallpapersFile" > "$RecentWallpapersFile.tmp" && mv "$RecentWallpapersFile.tmp" "$RecentWallpapersFile"
  fi
}
imgpath=$(find "$HOME/Pictures/Wallpapers/" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) ! -path "*/thumbnails/*" ! -path "$(grep -v '^#' "$RecentWallpapersFile" | tr '\n' '|' | sed 's/|$//')" -print0 | shuf -zn 1 | xargs -0 -I {} echo {})
if [ -z "$imgpath" ]; then
  echo "No new wallpapers available."
  exit 1
fi

"$WallSwitch" "$imgpath"
echo "$imgpath" >> "$RecentWallpapersFile"
cleanup_recent_wallpapers
