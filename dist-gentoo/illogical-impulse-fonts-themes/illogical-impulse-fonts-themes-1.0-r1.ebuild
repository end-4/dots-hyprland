# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
DART_SASS_VER=1.78.0
SPACE_GROTESK_VER=1.1.4

DESCRIPTION="Illogical Impulse Fonts and Theming Dependencies"
HOMEPAGE=""
SRC_URI="
https://github.com/Bali10050/Darkly/archive/refs/heads/main.tar.gz -> ${P}-darkly.tar.gz
https://github.com/naipefoundry/gabarito/archive/refs/heads/main.tar.gz -> ${P}-gabarito.tar.gz
https://github.com/googlefonts/rubik/archive/refs/heads/main.tar.gz -> ${P}-rubik.tar.gz
https://github.com/ThomasJockin/readexpro/archive/refs/heads/master.tar.gz -> ${P}-readexpro.tar.gz
https://github.com/mjkim0727/breeze-plus/archive/refs/heads/main.tar.gz -> ${P}-breeze-plus.tar.gz
https://github.com/lassekongo83/adw-gtk3/archive/refs/heads/main.tar.gz -> ${P}-adw-gtk3.tar.gz
https://github.com/google/material-design-icons/raw/refs/heads/master/variablefont/MaterialSymbolsOutlined%5BFILL,GRAD,opsz,wght%5D.ttf -> MaterialSymbolsOutlined.ttf
    https://github.com/google/material-design-icons/raw/refs/heads/master/variablefont/MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf -> MaterialSymbolsRounded.ttf
    https://github.com/google/material-design-icons/raw/refs/heads/master/variablefont/MaterialSymbolsSharp%5BFILL,GRAD,opsz,wght%5D.ttf -> MaterialSymbolsSharp.ttf
https://github.com/floriankarsten/space-grotesk/archive/refs/tags/${SPACE_GROTESK_VER}.tar.gz -> ${P}-space-grotesk-${SPACE_GROTESK_VER}.tar.gz
"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="strip"

DEPEND=""
RDEPEND="
	kde-plasma/breeze
	sys-apps/eza
	app-shells/fish
	media-libs/fontconfig
	x11-terms/kitty
	x11-misc/matugen
	app-shells/starship
	media-fonts/jetbrains-mono
	media-fonts/twemoji
"

# Source directories
S="${WORKDIR}"
S_DARKLY="${S}/Darkly-main"
S_GABARITO="${S}/gabarito-main"
S_RUBIK="${S}/rubik-main"
S_READEXPRO="${S}/readexpro-master"
S_ADW_GTK3="${S}/adw-gtk3-main"
S_BREEZE_PLUS="${S}/breeze-plus-main"
S_SPACE_GROTESK="${S}/space-grotesk-${SPACE_GROTESK_VER}"

src_unpack() {
	default

	mv "${WORKDIR}/dart-sass-${DART_SASS_VER}-linux-x64" "${S_DART_SASS}"
}

src_compile() {
	cd "${S_DARKLY}"
	mkdir -p build
	cd build
	cmake .. -DBUILD_QT5=OFF -DBUILD_QT6=ON
	cmake --build . --parallel=$(nproc)

	cd "${S_ADW_GTK3}"
	meson setup build
	meson compile -C build
}

src_install() {
	cd "${S_DARKLY}/build"
	cmake --install . --destdir="${D}"

	insinto /usr/share/fonts/ttf-gabarito
	doins "${S_GABARITO}"/fonts/ttf/*.ttf

	insinto /usr/share/fonts/ttf-readex-pro
	doins "${S_READEXPRO}"/fonts/ttf/*.ttf

	insinto /usr/share/fonts/material-symbols
	doins "${DISTDIR}"/MaterialSymbols*.ttf

	insinto /usr/share/fonts/OTF
	doins "${S_SPACE_GROTESK}"/fonts/otf/*.otf

	insinto /usr/share/themes
	doins -r "${S_BREEZE_PLUS}"/src/breeze-plus*

	cd "${S_ADW_GTK3}"
	meson install -C build --destdir="${D}"

	fc-cache -f
}
