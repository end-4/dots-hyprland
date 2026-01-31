# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A fork of mjkim0727/OneUI4-Icons for illogical-impulse dotfiles"
HOMEPAGE=""
SRC_URI="https://github.com/end-4/OneUI4-Icons/archive/main.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="strip"

DEPEND=""
RDEPEND=""

S="${WORKDIR}/OneUI4-Icons-main"

src_install() {
	insinto /usr/share/icons

	for theme in "OneUI" "OneUI-dark" "OneUI-light"; do
        doins -r ${S}/${theme}
    done
}
