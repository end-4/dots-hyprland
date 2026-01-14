# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogicall Impulse Widget Dependencies"
HOMEPAGE=""

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

DEPEND=""
RDEPEND="
	gui-apps/fuzzel
	dev-libs/glib
	media-gfx/imagemagick
	gui-apps/hypridle
	gui-apps/hyprlock
	gui-apps/hyprpicker
	app-misc/songrec
	app-i18n/translate-shell
	gui-apps/wlogout
	sci-libs/libqalculate
"
##### CUSTOM EBUILDS
# app-misc/songrec
