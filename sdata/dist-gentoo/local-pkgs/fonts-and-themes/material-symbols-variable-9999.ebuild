# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit font

DESCRIPTION="Material Design icons by Google - variable fonts"
HOMEPAGE="https://github.com/google/material-design-icons"

BASE_URL="https://github.com/google/material-design-icons/raw/refs/heads/master"

SRC_URI="
	${BASE_URL}/variablefont/MaterialSymbolsOutlined%5BFILL,GRAD,opsz,wght%5D.ttf -> MaterialSymbolsOutlined-FILL-GRAD-opsz-wght.ttf
	${BASE_URL}/variablefont/MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf -> MaterialSymbolsRounded-FILL-GRAD-opsz-wght.ttf
	${BASE_URL}/variablefont/MaterialSymbolsSharp%5BFILL,GRAD,opsz,wght%5D.ttf -> MaterialSymbolsSharp-FILL-GRAD-opsz-wght.ttf
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS=""

S="${WORKDIR}"

FONT_SUFFIX="ttf"

src_unpack() {
	mkdir -p "${S}"
	cp "${DISTDIR}/MaterialSymbolsOutlined-FILL-GRAD-opsz-wght.ttf" \
		"${S}/MaterialSymbolsOutlined[FILL,GRAD,opsz,wght].ttf"
	cp "${DISTDIR}/MaterialSymbolsRounded-FILL-GRAD-opsz-wght.ttf" \
		"${S}/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf"
	cp "${DISTDIR}/MaterialSymbolsSharp-FILL-GRAD-opsz-wght.ttf" \
		"${S}/MaterialSymbolsSharp[FILL,GRAD,opsz,wght].ttf"
}

src_install() {
	font_src_install
}

