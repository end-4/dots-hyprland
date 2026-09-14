# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogical Impulse Fonts and Theming Dependencies"
HOMEPAGE="https://github.com/end-4/dots-hyprland"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	x11-themes/adw-gtk3
	kde-plasma/breeze
	kde-plasma/breeze-plus
	kde-misc/darkly
	sys-apps/eza
	app-shells/fish
	media-libs/fontconfig
	x11-terms/kitty
	x11-misc/matugen
	media-fonts/space-grotesk
	app-shells/starship
	media-fonts/nerdfonts[jetbrainsmono]
	media-fonts/material-symbols-variable
	media-fonts/readex-pro
	media-fonts/rubik-vf
	media-fonts/twemoji
"
