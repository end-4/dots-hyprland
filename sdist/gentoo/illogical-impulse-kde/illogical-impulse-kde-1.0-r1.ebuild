# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogical Impulse KDE Dependencies"
HOMEPAGE=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="strip"

DEPEND=""
RDEPEND="
	kde-plasma/bluedevil
	gnome-base/gnome-keyring
	net-misc/networkmanager
	kde-plasma/plasma-nm
	kde-plasma/polkit-kde-agent
	kde-apps/dolphin
	kde-plasma/systemsettings
"
