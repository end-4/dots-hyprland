# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3

DESCRIPTION="QML style provider for hypr* Qt apps"
HOMEPAGE="https://github.com/hyprwm/hyprland-qt-support"
EGIT_REPO_URI="https://github.com/hyprwm/hyprland-qt-support.git"

LICENSE="BSD"

SLOT="0"
KEYWORDS="amd64"

RDEPEND="
	dev-qt/qtbase:6
	dev-qt/qtdeclarative:6
	>=dev-libs/hyprlang-0.6.0
"

DEPEND="${RDEPEND}"

BDEPEND="
	virtual/pkgconfig
"

src_configure() {
	local mycmakeargs=(
		-DINSTALL_QML_PREFIX="${EPFREIX}/$(get_libdir)/qt6/qml"
	)

	cmake_src_configure
}
