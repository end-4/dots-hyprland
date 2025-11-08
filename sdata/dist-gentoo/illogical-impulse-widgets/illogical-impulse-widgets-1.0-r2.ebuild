# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogicall Impulse Widget Dependencies"
HOMEPAGE=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="strip"

DEPEND=""
RDEPEND="
	gui-apps/fuzzel
	dev-libs/glib
	media-gfx/imagemagick
	gui-apps/hypridle
	gui-libs/hyprutils
	gui-apps/hyprlock
	gui-apps/hyprpicker
	app-i18n/translate-shell
	gui-apps/wlogout
"
