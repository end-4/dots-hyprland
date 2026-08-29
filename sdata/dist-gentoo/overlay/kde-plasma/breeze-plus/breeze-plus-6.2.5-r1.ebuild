# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Breeze styled extra icon theme for KDE"
HOMEPAGE="https://github.com/mjkim0727/breeze-plus"
SRC_URI="https://github.com/mjkim0727/breeze-plus/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RDEPEND="kde-plasma/breeze"
BDEPEND=""

S="${WORKDIR}/${PN}-${PV}"

src_install() {
	insinto /usr/share/icons
	doins -r src/breeze-plus*
}

