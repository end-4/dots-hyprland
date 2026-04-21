# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogical Impulse Fonts and Theming Dependencies"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="strip"

DEPEND=""
RDEPEND="
	x11-themes/adw-gtk3
	kde-plasma/breeze
	kde-plasma/breeze-plus
	x11-themes/darkly
	sys-apps/eza
	app-shells/fish
	media-libs/fontconfig
	x11-terms/kitty
	x11-misc/matugen
	media-fonts/space-grotesk
	app-shells/starship
	media-fonts/jetbrains-mono
	media-fonts/material-symbols-variable
	media-fonts/readex-pro
	media-fonts/rubik-vf
	media-fonts/twemoji
"
##### CUSTOM EBUILDS
# x11-themes/adw-gtk3
# x11-themes/darkly
# media-fonts/space-grotesk
# media-fonts/material-symbols-variable
# media-fonts/readex-pro
# media-fonts/rubik-vf
