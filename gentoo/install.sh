#!/bin/bash
set -e

# Add necessary USE flags
echo "Adding necessary USE flags..."
sudo emerge --verbose --noreplace app-portage/gentoolkit
sudo euse -E pipewire pulseaudio sound-server git cups
sudo euse -p dev-libs/libdbusmenu -E gtk3

# Update the system
echo "Updating the system..."
sudo emerge --sync
sudo emerge --update --verbose --deep --newuse @world
echo "System update complete."

# Add necessary overlays
echo "Adding necessary overlays..."
sudo emerge --verbose app-eselect/eselect-repository
sudo eselect repository enable guru
sudo eselect repository enable nest
sudo eselect repository enable xoores
sudo emerge --sync guru
sudo emerge --sync nest
sudo emerge --sync xoores
echo "Overlays added successfully."

# Install Python packages
echo "Installing Python packages..."
sudo emerge --verbose --noreplace dev-lang/python:3.12
sudo emerge --verbose --noreplace net-libs/libsoup gui-apps/hypridle

# Install Hyprland and related packages
echo "Installing Hyprland and related packages..."
sudo emerge --verbose --noreplace gui-wm/hyprland gui-libs/hyprland-qtutil
sudo emerge --verbose --noreplace gui-apps/hyprpaper gui-apps/hyprpicker gui-apps/hyprshot dev-util/hyprwayland-scanner gui-apps/hyprlock gui-apps/wlogout dev-libs/pugixml
sudo emerge --verbose --noreplace app-misc/cliphist

# Install GUI and toolkit dependencies
echo "Installing GUI and toolkit dependencies..."
sudo emerge --verbose --noreplace gui-libs/gtk gui-libs/libadwaita
sudo emerge --verbose --noreplace gui-labs/gtk-layer-shell dev-libs/gobject-introspection sys-power/upower
sudo emerge --verbose --noreplace gui-libs/gdk-pixbuf-loader-webp
sudo emerge --verbose --noreplace dev-libs/gjs media-libs/libpulse

# Install Desktop integrations and utilities
echo "Installing Desktop integrations and utilities..."
sudo emerge --verbose --noreplace sys-apps/xdg-desktop-portal kde-plasma/xdg-desktop-portal-kde sys-apps/xdg-desktop-portal-gtk gui-libs/xdg-desktop-portal-hyprland x11-apps/xrandr
sudo emerge --verbose --noreplace net-wireless/gnome-bluetooth net-wireless/bluez
sudo emerge --verbose --noreplace x11-misc/gammastep app-i18n/translate-shell
# Install core utilities
echo "Installing core utilities..."
sudo emerge --verbose --noreplace sys-apps/coreutils gui-apps/wl-clipboard x11-misc/xdg-utils net-misc/curl gui-apps/fuzzel net-misc/rsync net-misc/wget sys-apps/ripgrep app-misc/jq dev-build/meson dev-lang/typescript net-misc/axel sys-apps/eza
sudo emerge --verbose --noreplace app-misc/brightnessctl app-misc/ddcutil

# Install Audio & media
echo "Installing Audio & media packages..."
sudo emerge --verbose --noreplace media-sound/pavucontrol media-video/pipewire media-video/wireplumber dev-libs/libdbusmenu media-sound/playerctl media-sound/cava

# Install other individual tools
echo "Installing other individual tools..."
