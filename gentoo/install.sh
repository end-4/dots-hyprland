#!/bin/bash
set -e

# Add necessary USE flags
echo "Adding necessary USE flags..."
sudo emerge --verbose app-portage/gentoolkit
sudo euse pipewire pulseaudio sound-server

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
sudo emerge --verbose dev-lang/python:3.12
sudo emerge --verbose net-libs/libsoup gui-apps/hypridle

# Install Hyprland and related packages
echo "Installing Hyprland and related packages..."
sudo emerge --verbose gui-wm/hyprland gui-libs/hyprland-qtutil
sudo emerge --verbose gui-apps/hyprpaper gui-apps/hyprpicker gui-apps/hyprshot dev-util/hyprwayland-scanner gui-apps/hyprlock gui-apps/wlogout dev-libs/pugixml
sudo emerge --verbose app-misc/cliphist
# Install GUI and toolkit dependencies
echo "Installing GUI and toolkit dependencies..."
sudo emerge --verbose gui-libs/gtk gui-libs/libadwaita
suso emerge --verbose gui-labs/gtk-layer-shell