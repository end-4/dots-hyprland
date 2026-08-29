# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit font

DESCRIPTION="Space Grotesk OTF font from 38C3 styleguide"
HOMEPAGE="https://events.ccc.de/congress/2024/infos/styleguide.html"
SRC_URI="https://events.ccc.de/congress/2024/infos/styleguide/38c3-styleguide-full-v2.zip"

LICENSE="OFL-1.1"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

BDEPEND="app-arch/unzip"

S="${WORKDIR}/fonts/space-grotesk-${PV}"

FONT_S="${S}/otf"
FONT_SUFFIX="otf"

src_install() {
	font_src_install

	dodoc OFL.txt
}

