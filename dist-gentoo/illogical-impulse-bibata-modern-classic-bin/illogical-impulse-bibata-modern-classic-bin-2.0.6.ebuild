# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
Bibata_VER=2.0.6

DESCRIPTION="Material Based Cursor Theme, installed for illogical-impulse dotfiles"
HOMEPAGE=""
SRC_URI="https://github.com/ful1e5/Bibata_Cursor/releases/download/v${Bibata_VER}/Bibata-Modern-Classic.tar.xz -> bibata-modern-classic.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="strip"

DEPEND=""
RDEPEND=""

S="${WORKDIR}/Bibata-Modern-Classic"

src_install() {
	insinto /usr/share/icons
	doins -r "${S}"
}
