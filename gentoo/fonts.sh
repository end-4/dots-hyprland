#!/bin/bash
set -e

FONT_DIR="$HOME/.local/share/fonts"
CACHE_DIR="$HOME/.cache/depends"

# Function to check if font files exist in FONT_DIR
fonts_installed() {
    [[ -d "$FONT_DIR/adobe-source-code-pro" ]]
}

# Ask user whether to continue or skip if fonts exist
if fonts_installed; then
    echo -ne "Custom fonts detected. Reinstall/Update them? (y/N): "
    read -r answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo "Skipping font installation."
        exit 0
    fi
fi

rm -rf "$CACHE_DIR"
mkdir -p "$CACHE_DIR"
cd "$CACHE_DIR"

# Clone the fonts repository
git clone https://github.com/EisregenHaha/end4fonts
cd end4fonts/fonts

# Ensure the fonts directory exists
mkdir -p "$FONT_DIR"

# Copy fonts
cp -R * "$FONT_DIR"

# Refresh font cache
fc-cache -f

# Cleanup
rm -rf "$CACHE_DIR"

# Success
echo -e "\e[1m✅ Installation complete. Proceed with the manual-install-helper script.\e[0m"