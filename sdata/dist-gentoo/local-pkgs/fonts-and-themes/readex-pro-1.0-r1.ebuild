# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit font

DESCRIPTION="Illogical Impulse Fonts and Theming Dependencies"
HOMEPAGE=""
SRC_URI="https://github.com/ThomasJockin/readexpro/archive/refs/heads/master.tar.gz -> ${P}-readexpro.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="strip"

S="${WORKDIR}/readexpro-master"

src_install() {
	insinto /usr/share/fonts/ttf-readex-pro
	doins "${S}"/fonts/ttf/*.ttf
}
