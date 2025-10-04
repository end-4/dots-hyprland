# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
MICROTEX_VER="0e3707f"

DESCRIPTION="MicroTeX for illogical-impulse dotfiles"
HOMEPAGE="https://github.com/NanoMichael/MicroTeX"
SRC_URI="https://github.com/NanoMichael/MicroTeX/archive/${MICROTEX_VER}.tar.gz -> MicroTeX-${MICROTEX_VER}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="strip"

DEPEND=""
RDEPEND="
	dev-libs/tinyxml2
	dev-cpp/gtkmm
	dev-cpp/gtksourceviewmm
	dev-cpp/cairomm
"

# Use WORKDIR directly after stripping top-level folder
S="${WORKDIR}"

src_unpack() {
	# If I don't strip it it has an insane hash
	tar xvf "${DISTDIR}/MicroTeX-${MICROTEX_VER}.tar.gz" --strip-components=1 -C "${WORKDIR}"
}

src_prepare() {
	default
	cd "${S}" || die
	# Gentoo doesn't have gtksourceviewmm4 even on testing so I just left it on 3
	# sed -i 's/gtksourceviewmm-3.0/gtksourceviewmm-4.0/' CMakeLists.txt
	sed -i 's/tinyxml2.so.10/tinyxml2.so.11/' CMakeLists.txt
}

src_compile() {
	cd "${S}" || die
	mkdir -p build
	cmake -B build -S . -DCMAKE_BUILD_TYPE=None
	cmake --build build
}

src_install() {
	cd "${S}" || die
	insinto /opt/illogical-impulse-microtex-git
	doins -r build/LaTeX
	doins -r build/res

	insinto /usr/share/licenses/illogical-impulse-microtex-git
	doins LICENSE
}

