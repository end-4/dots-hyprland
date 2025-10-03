# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogical Impulse Hyprland related packages"
HOMEPAGE=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm64 x86"
RESTRICT="strip"

DEPEND=""
RDEPEND="
	gui-apps/hypridle
	gui-libs/hyprcursor
	gui-libs/hyprland-qtutils
	gui-libs/hyprland-qt-support
	dev-libs/hyprlang
	gui-apps/hyprlock
	gui-apps/hyprpicker
	gui-apps/hyprsunset
	gui-libs/hyprutils
	dev-libs/hyprland-protocols
	dev-libs/hyprgraphics
	gui-libs/aquamarine
	gui-wm/hyprland
	dev-util/hyprwayland-scanner
	gui-libs/xdg-desktop-portal-hyprland
	gui-apps/wl-clipboard
"
