# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit font

DESCRIPTION="Upgrades Roboto to become a more powerful typeface system"
HOMEPAGE="https://github.com/googlefonts/roboto-flex"
SRC_URI="
	https://github.com/googlefonts/roboto-flex/releases/download/${PV}/roboto-flex-fonts.zip -> ${P}.zip
	https://github.com/googlefonts/roboto-flex/raw/main/OFL.txt -> ${P}-OFL.txt
"

LICENSE="OFL-1.1"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

BDEPEND="app-arch/unzip"

S="${WORKDIR}/roboto-flex-fonts"

FONT_SUFFIX="ttf"
FONT_S="${S}/fonts/variable"

src_install() {
	font_src_install
	dodoc "${DISTDIR}/${P}-OFL.txt"
}
