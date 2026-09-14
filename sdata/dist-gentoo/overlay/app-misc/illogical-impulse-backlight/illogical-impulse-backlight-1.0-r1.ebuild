# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogical Impulse Backlight Dependencies"
HOMEPAGE="https://github.com/end-4/dots-hyprland"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND="
	app-misc/geoclue
	app-misc/brightnessctl
	app-misc/ddcutil
"
