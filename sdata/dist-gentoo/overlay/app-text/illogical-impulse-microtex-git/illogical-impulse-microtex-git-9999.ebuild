# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3

DESCRIPTION="MicroTeX for illogical-impulse dotfiles"
HOMEPAGE="https://github.com/end-4/MicroTeX"
EGIT_REPO_URI="https://github.com/end-4/MicroTeX.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""

DEPEND="
	dev-libs/tinyxml2
	dev-cpp/gtkmm
	dev-cpp/gtksourceviewmm
	dev-cpp/cairomm
	media-libs/fontconfig
"
RDEPEND="${DEPEND}"
BDEPEND="virtual/pkgconfig"

src_install() {
	exeinto /opt/illogical-impulse-microtex-git
	doexe "${BUILD_DIR}/LaTeX"
	insinto /opt/illogical-impulse-microtex-git
	doins -r "${BUILD_DIR}/res"
	dodoc LICENSE
}
