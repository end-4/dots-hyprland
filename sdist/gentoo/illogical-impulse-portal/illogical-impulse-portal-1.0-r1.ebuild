# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogical Impulse XDG Desktop Portals"
HOMEPAGE=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="strip"

DEPEND=""
RDEPEND="
	sys-apps/xdg-desktop-portal
	kde-plasma/xdg-desktop-portal-kde
	sys-apps/xdg-desktop-portal-gtk
	gui-libs/xdg-desktop-portal-hyprland
"
