#!/usr/bin/env bash
# Installation script for Productivity Features

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Installing Productivity Features..."

# Make scripts executable
echo "📝 Making scripts executable..."
chmod +x "$SCRIPT_DIR/focus-mode.sh"
chmod +x "$SCRIPT_DIR/digital-wellbeing.py"
chmod +x "$SCRIPT_DIR/productivity-dashboard.py"

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p "$HOME/.local/share/digital-wellbeing"
mkdir -p "$HOME/.cache/hypr"
mkdir -p "$HOME/.config/systemd/user"

# Check dependencies
echo "🔍 Checking dependencies..."
MISSING_DEPS=()

command -v python3 >/dev/null 2>&1 || MISSING_DEPS+=("python3")
command -v jq >/dev/null 2>&1 || MISSING_DEPS+=("jq")
command -v hyprctl >/dev/null 2>&1 || MISSING_DEPS+=("hyprland")
command -v notify-send >/dev/null 2>&1 || MISSING_DEPS+=("libnotify")
command -v sqlite3 >/dev/null 2>&1 || MISSING_DEPS+=("sqlite")

python3 -c "import gi; gi.require_version('Gtk', '3.0')" 2>/dev/null || MISSING_DEPS+=("python-gobject + gtk3")

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "⚠️  Missing dependencies:"
    printf '%s\n' "${MISSING_DEPS[@]}"
    echo ""
    echo "On Arch Linux, install with:"
    echo "  sudo pacman -S python python-gobject gtk3 jq libnotify sqlite"
    exit 1
fi

# Copy systemd service
if [ -f "$SCRIPT_DIR/../systemd/user/digital-wellbeing.service" ]; then
    echo "📋 Installing systemd service..."
    cp "$SCRIPT_DIR/../systemd/user/digital-wellbeing.service" "$HOME/.config/systemd/user/"
    systemctl --user daemon-reload
    systemctl --user enable digital-wellbeing.service
fi

# Initialize database
echo "🗄️  Initializing database..."
python3 "$SCRIPT_DIR/digital-wellbeing.py" stop 2>/dev/null || true

echo ""
echo "✅ Installation complete!"
echo ""
echo "📚 Quick Start:"
echo "  • Toggle Focus Mode:         Super + Shift + F"
echo "  • Open Dashboard:            Super + Shift + P"
echo "  • View stats:                Super + Shift + Ctrl + P"
echo ""
echo "  • Start tracking:            python3 ~/.config/hypr/productivity/digital-wellbeing.py start"
echo "  • View configuration:        cat ~/.config/hypr/productivity/README.md"
echo ""
echo "🎯 Focus Mode is ready to use!"
echo "👁️  Digital Wellbeing will start on next login (or start manually with the command above)"
echo ""
echo "📖 See README.md for detailed documentation and configuration options."
