# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Fork of Lightly - A modern style for Qt applications"
HOMEPAGE="https://github.com/Bali10050/Darkly"
SRC_URI="https://github.com/Bali10050/darkly/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/Darkly-${PV}"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

DEPEND="
	dev-qt/qtbase:6=[dbus,gui,widgets]
	kde-frameworks/kcoreaddons:6
	kde-frameworks/kconfig:6
	kde-frameworks/kguiaddons:6
	kde-frameworks/ki18n:6
	kde-frameworks/kiconthemes:6
	kde-frameworks/kwindowsystem:6
	kde-frameworks/kcmutils:6
	kde-frameworks/frameworkintegration:6
	kde-frameworks/kcolorscheme:6
	kde-frameworks/kconfigwidgets:6
	kde-plasma/kdecoration:6
	dev-qt/qtdeclarative:6
	kde-frameworks/kirigami:6
"
RDEPEND="${DEPEND}"
BDEPEND="
	dev-build/cmake
	kde-frameworks/extra-cmake-modules
	dev-vcs/git
"

src_configure() {
	local mycmakeargs=(
		-DBUILD_TESTING=OFF
		-DBUILD_QT5=OFF
		-DBUILD_QT6=ON
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install
	rm -rf "${ED}/usr/$(get_libdir)/cmake" || die
}
