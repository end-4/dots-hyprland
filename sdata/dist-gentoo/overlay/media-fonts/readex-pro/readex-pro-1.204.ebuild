# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit font

COMMIT="1a5aaa4c15edb043c37113a8cddf020235917050"

DESCRIPTION="Illogical Impulse Fonts and Theming Dependencies"
HOMEPAGE="https://github.com/ThomasJockin/readexpro"
SRC_URI="https://github.com/ThomasJockin/readexpro/archive/${COMMIT}.tar.gz -> ${P}-readexpro.tar.gz"
S="${WORKDIR}/readexpro-${COMMIT}"

LICENSE="OFL-1.1"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

src_install() {
	insinto /usr/share/fonts/ttf-readex-pro
	doins "${S}"/fonts/ttf/*.ttf
}
