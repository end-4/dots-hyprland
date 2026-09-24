# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogical Impulse Widget Dependencies"
HOMEPAGE="https://github.com/end-4/dots-hyprland"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	gui-apps/fuzzel
	dev-libs/glib
	media-gfx/imagemagick
	gui-apps/hypridle
	gui-apps/hyprlock
	gui-apps/hyprpicker
	media-sound/songrec
	app-i18n/translate-shell
	gui-apps/wlogout
	sci-libs/libqalculate
"
