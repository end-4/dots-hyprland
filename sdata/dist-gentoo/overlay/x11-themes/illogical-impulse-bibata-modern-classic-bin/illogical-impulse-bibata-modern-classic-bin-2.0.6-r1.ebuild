# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Material Based Cursor Theme, installed for illogical-impulse dotfiles"
HOMEPAGE="https://github.com/ful1e5/Bibata_Cursor"
SRC_URI="https://github.com/ful1e5/Bibata_Cursor/releases/download/v${PV}/Bibata-Modern-Classic.tar.xz -> ${P}.tar.xz"
S="${WORKDIR}/Bibata-Modern-Classic"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

src_install() {
	insinto /usr/share/icons
	doins -r "${S}"
}
