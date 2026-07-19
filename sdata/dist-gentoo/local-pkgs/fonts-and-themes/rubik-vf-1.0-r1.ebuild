# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

COMMIT="e337a5f69a9bea30e58d05bd40184d79cc099628"

inherit font

DESCRIPTION="A sans serif font family with slightly rounded corners: variable font version"
HOMEPAGE="https://github.com/googlefonts/rubik"
SRC_URI="https://github.com/googlefonts/rubik/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="OFL-1.1"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

S="${WORKDIR}/rubik-${COMMIT}"

FONT_S="${S}/fonts/variable"
FONT_SUFFIX="ttf"

src_install() {
	font_src_install
	dodoc OFL.txt AUTHORS.txt CONTRIBUTORS.txt
}

