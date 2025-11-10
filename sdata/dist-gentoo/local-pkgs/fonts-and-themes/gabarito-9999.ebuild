# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit font git-r3

DESCRIPTION="Illogical Impulse Fonts and Theming Dependencies"
HOMEPAGE=""
EGIT_REPO_URI="https://github.com/naipefoundry/gabarito"

LICENSE="OFL-1.1"
SLOT="0"
KEYWORDS=""

FONT_S="${S}/fonts/ttf"
FONT_SUFFIX="ttf"

src_install() {
	font_src_install
	dodoc OFL.txt
}
