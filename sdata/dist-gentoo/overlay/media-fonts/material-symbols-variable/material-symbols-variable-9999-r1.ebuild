# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit font git-r3

DESCRIPTION="Material Design icons by Google - variable fonts"
HOMEPAGE="https://github.com/google/material-design-icons"
EGIT_REPO_URI="https://github.com/google/material-design-icons.git"
S="${WORKDIR}/fonts"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS=""

BDEPEND=">=dev-vcs/git-2.19[curl]"

FONT_SUFFIX="ttf"

src_unpack() {
	local repo="${WORKDIR}/material-design-icons"

	git clone \
		--depth=1 \
		--filter=blob:none \
		--no-checkout \
		--single-branch \
		"${EGIT_REPO_URI}" \
		"${repo}" || die

	EGIT_VERSION=$(git -C "${repo}" rev-parse --verify HEAD) \
		|| die "failed to determine Git revision"
	export EGIT_VERSION

	mkdir -p "${S}" || die

	local style
	for style in Outlined Rounded Sharp; do
		git -C "${repo}" show \
			"HEAD:variablefont/MaterialSymbols${style}[FILL,GRAD,opsz,wght].ttf" \
			> "${S}/MaterialSymbols${style}[FILL,GRAD,opsz,wght].ttf" \
			|| die "failed to fetch Material Symbols ${style}"
	done
}
