#!/usr/bin/env bash
# Test script for productivity features

set -e

# Determine if we're in the repo or installed location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/focus-mode.sh" ]; then
    PRODUCTIVITY_DIR="$SCRIPT_DIR"
else
    PRODUCTIVITY_DIR="$HOME/.config/hypr/productivity"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🧪 Testing Productivity Features..."
echo "📍 Testing from: $PRODUCTIVITY_DIR"
echo ""

# Test 1: Check if scripts exist
echo "📂 Checking if scripts exist..."
for script in focus-mode.sh digital-wellbeing.py productivity-dashboard.py; do
    if [ -f "$PRODUCTIVITY_DIR/$script" ]; then
        echo -e "  ${GREEN}✓${NC} $script found"
    else
        echo -e "  ${RED}✗${NC} $script NOT found"
        exit 1
    fi
done
echo ""

# Test 2: Check if scripts are executable
echo "🔓 Checking if scripts are executable..."
for script in focus-mode.sh digital-wellbeing.py productivity-dashboard.py; do
    if [ -x "$PRODUCTIVITY_DIR/$script" ]; then
        echo -e "  ${GREEN}✓${NC} $script is executable"
    else
        echo -e "  ${YELLOW}⚠${NC} $script is NOT executable (fixing...)"
        chmod +x "$PRODUCTIVITY_DIR/$script"
    fi
done
echo ""

# Test 3: Check dependencies
echo "📦 Checking dependencies..."
MISSING=()

command -v python3 >/dev/null 2>&1 && echo -e "  ${GREEN}✓${NC} python3" || { echo -e "  ${RED}✗${NC} python3"; MISSING+=("python3"); }
command -v jq >/dev/null 2>&1 && echo -e "  ${GREEN}✓${NC} jq" || { echo -e "  ${RED}✗${NC} jq"; MISSING+=("jq"); }
command -v hyprctl >/dev/null 2>&1 && echo -e "  ${GREEN}✓${NC} hyprctl (hyprland)" || { echo -e "  ${RED}✗${NC} hyprctl"; MISSING+=("hyprland"); }
command -v notify-send >/dev/null 2>&1 && echo -e "  ${GREEN}✓${NC} notify-send (libnotify)" || { echo -e "  ${RED}✗${NC} notify-send"; MISSING+=("libnotify"); }
command -v sqlite3 >/dev/null 2>&1 && echo -e "  ${GREEN}✓${NC} sqlite3" || { echo -e "  ${RED}✗${NC} sqlite3"; MISSING+=("sqlite"); }

python3 -c "import gi; gi.require_version('Gtk', '3.0')" 2>/dev/null && echo -e "  ${GREEN}✓${NC} python-gobject + gtk3" || { echo -e "  ${RED}✗${NC} python-gobject + gtk3"; MISSING+=("python-gobject gtk3"); }

echo ""

if [ ${#MISSING[@]} -ne 0 ]; then
    echo -e "${RED}Missing dependencies:${NC}"
    printf '  • %s\n' "${MISSING[@]}"
    echo ""
    echo "Install with:"
    echo "  sudo pacman -S python python-gobject gtk3 jq libnotify sqlite"
    echo ""
fi

# Test 4: Check configuration files
echo "⚙️  Checking configuration files..."
if [ -f "$PRODUCTIVITY_DIR/focus-mode.conf" ]; then
    echo -e "  ${GREEN}✓${NC} focus-mode.conf exists"
else
    echo -e "  ${YELLOW}⚠${NC} focus-mode.conf will be created on first run"
fi

if [ -f "$HOME/.config/hypr/productivity/wellbeing.json" ]; then
    echo -e "  ${GREEN}✓${NC} wellbeing.json exists"
else
    echo -e "  ${YELLOW}⚠${NC} wellbeing.json will be created on first run"
fi
echo ""

# Test 5: Check keybindings
echo "⌨️  Checking keybindings..."
if grep -q "focus-mode.sh" "$HOME/.config/hypr/custom/keybinds.conf" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Focus Mode keybinding configured"
else
    echo -e "  ${YELLOW}⚠${NC} Focus Mode keybinding NOT found in custom/keybinds.conf"
fi

if grep -q "productivity-dashboard.py" "$HOME/.config/hypr/custom/keybinds.conf" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Productivity Dashboard keybinding configured"
else
    echo -e "  ${YELLOW}⚠${NC} Dashboard keybinding NOT found in custom/keybinds.conf"
fi
echo ""

# Test 6: Check autostart
echo "🚀 Checking autostart configuration..."
if grep -q "digital-wellbeing.py" "$HOME/.config/hypr/custom/execs.conf" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Digital Wellbeing autostart configured"
else
    echo -e "  ${YELLOW}⚠${NC} Digital Wellbeing autostart NOT found in custom/execs.conf"
fi
echo ""

# Test 7: Test focus mode script
echo "🎯 Testing Focus Mode script..."
if "$PRODUCTIVITY_DIR/focus-mode.sh" status &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Focus Mode script runs successfully"
    "$PRODUCTIVITY_DIR/focus-mode.sh" status
else
    echo -e "  ${RED}✗${NC} Focus Mode script failed"
fi
echo ""

# Test 8: Test digital wellbeing help
echo "👁️  Testing Digital Wellbeing script..."
if python3 "$PRODUCTIVITY_DIR/digital-wellbeing.py" 2>&1 | grep -q "Usage"; then
    echo -e "  ${GREEN}✓${NC} Digital Wellbeing script runs successfully"
else
    echo -e "  ${RED}✗${NC} Digital Wellbeing script failed"
fi
echo ""

# Summary
echo "📊 Test Summary"
echo "════════════════════════════════════════════════"
if [ ${#MISSING[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ All dependencies installed${NC}"
    echo -e "${GREEN}✓ Scripts are ready to use${NC}"
    echo ""
    echo "Quick Start:"
    echo "  • Toggle Focus Mode:    Super + Shift + F"
    echo "  • Open Dashboard:       Super + Shift + P"
    echo "  • View stats:           Super + Shift + Ctrl + P"
    echo ""
    echo "Manual commands:"
    echo "  • Start tracking:       python3 ~/.config/hypr/productivity/digital-wellbeing.py start"
    echo "  • Enable focus:         ~/.config/hypr/productivity/focus-mode.sh enable"
    echo ""
    echo -e "${GREEN}✅ Productivity features are ready!${NC}"
else
    echo -e "${YELLOW}⚠️  Some dependencies are missing${NC}"
    echo "Please install missing packages before using the features."
fi
