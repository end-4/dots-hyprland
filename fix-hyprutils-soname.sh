#!/usr/bin/env bash
set -euo pipefail

echo "=== Fixing libhyprutils.so.10 -> .so.11 breakage ==="
echo ""

# 1. Replace stale hyprgraphics-git (built against .so.10) with official repo version
#    The repo version is already compiled against .so.11.
#    If you prefer to keep the -git version, replace this block with:
yay -S --rebuildtree hyprgraphics-git
echo "[1/3] Replacing hyprgraphics-git with official hyprgraphics..."
# sudo pacman -S --noconfirm hyprgraphics

# 2. Reinstall hyprtoolkit from repo (should be rebuilt against .so.11)
echo "[2/3] Reinstalling hyprtoolkit..."
sudo pacman -S --noconfirm hyprtoolkit

# 3. Verify no more missing libs
echo ""
echo "[3/3] Verifying linked libraries..."
failed=0
for bin in /usr/bin/Hyprland /usr/bin/hyprlock; do
  missing=$(ldd "$bin" 2>/dev/null | grep "not found" || true)
  if [ -n "$missing" ]; then
    echo "STILL BROKEN: $bin"
    echo "  $missing"
    failed=1
  else
    echo "OK: $bin"
  fi
done

if [ "$failed" -eq 1 ]; then
  echo ""
  echo "Some libraries are still missing. The repo binaries may not have been"
  echo "rebuilt yet. Try installing -git versions from AUR to compile from source:"
  echo "  yay -S hyprgraphics-git hyprtoolkit-git"
  exit 1
else
  echo ""
  echo "All clear. Hyprland should start now."
fi
