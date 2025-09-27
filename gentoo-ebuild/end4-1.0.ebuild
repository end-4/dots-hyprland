# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
Bibata_VER=2.0.6
DART_SASS_VER=1.78.0

DESCRIPTION="For End-4 dot-files with icons, themes, fonts, adw-gtk3, and Dart Sass"
HOMEPAGE=""
SRC_URI="
https://github.com/end-4/OneUI4-Icons/archive/main.tar.gz -> ${P}.tar.gz
https://github.com/ful1e5/Bibata_Cursor/releases/download/v${Bibata_VER}/Bibata-Modern-Classic.tar.xz -> bibata-modern-classic.tar.xz
https://github.com/Bali10050/Darkly/archive/refs/heads/main.tar.gz -> ${P}-darkly.tar.gz
https://github.com/naipefoundry/gabarito/archive/refs/heads/main.tar.gz -> ${P}-gabarito.tar.gz
https://github.com/luisbocanegra/kde-material-you-colors/archive/refs/heads/main.tar.gz -> ${P}-kde-material-you-colors.tar.gz
https://github.com/googlefonts/rubik/archive/refs/heads/main.tar.gz -> ${P}-rubik.tar.gz
https://github.com/ThomasJockin/readexpro/archive/refs/heads/master.tar.gz -> ${P}-readexpro.tar.gz
https://github.com/google/material-design-icons/archive/refs/heads/main.tar.gz -> ${P}-material-design-icons.tar.gz
https://github.com/mjkim0727/breeze-plus/archive/refs/heads/main.tar.gz -> ${P}-breeze-plus.tar.gz
https://github.com/lassekongo83/adw-gtk3/archive/refs/heads/main.tar.gz -> ${P}-adw-gtk3.tar.gz
https://github.com/sass/dart-sass/releases/download/${DART_SASS_VER}/dart-sass-${DART_SASS_VER}-linux-x64.tar.gz -> dart-sass.tar.gz
"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="strip"


DEPEND=""
RDEPEND="
	media-sound/cava
	media-sound/pavucontrol-qt
	media-video/wireplumber
	dev-libs/libdbusmenu[gtk3]
	media-sound/playerctl

	app-misc/brightnessctl
	app-misc/geoclue
	app-misc/ddcutil

	sys-apps/coreutils
	net-misc/axel
	sys-devel/bc
	app-misc/cliphist
	net-misc/curl
	dev-build/cmake
	net-misc/rsync
	net-misc/wget
	sys-apps/ripgrep
	dev-python/jq
	dev-build/meson
	x11-misc/xdg-user-dirs

	kde-plasma/bluedevil
	gnome-base/gnome-keyring
	net-misc/networkmanager
	kde-plasma/plasma-nm
	kde-plasma/polkit-kde-agent
	kde-apps/dolphin
	kde-plasma/systemsettings

	sys-apps/xdg-desktop-portal
	kde-plasma/xdg-desktop-portal-kde
	sys-apps/xdg-desktop-portal-gtk
	gui-libs/xdg-desktop-portal-hyprland

	dev-python/clang
	dev-python/uv
	gui-libs/gtk
	gui-libs/libadwaita
	net-libs/libsoup
	dev-libs/gobject-introspection
	dev-lang/sassc
	media-libs/opencv

	gui-apps/hyprshot
	gui-apps/slurp
	gui-apps/swappy
	app-text/tesseract
	gui-apps/wf-recorder

	kde-apps/kdialog
	dev-qt/qt5compat
	dev-qt/qtbase
	dev-qt/qtdeclarative
	dev-qt/qtimageformats
	dev-qt/qtmultimedia
	dev-qt/qtpositioning
	dev-qt/qtquicktimeline
	dev-qt/qtsensors
	dev-qt/qtsvg
	dev-qt/qttools
	dev-qt/qttranslations
	dev-qt/qtvirtualkeyboard
	dev-qt/qtwayland
	kde-frameworks/syntax-highlighting
	sys-power/upower
	gui-apps/wtype
	x11-misc/ydotool

	gui-apps/fuzzel
	dev-libs/glib
	gui-apps/quickshell
	app-i18n/translate-shell
	gui-apps/wlogout

	kde-plasma/breeze
	app-shells/fish
	sys-apps/eza
	media-libs/fontconfig
	x11-terms/kitty
	x11-misc/matugen
	app-shells/starship
	media-fonts/twemoji
	media-fonts/jetbrains-mono
"

# Source directories
S="${WORKDIR}"
S_BIBATA="${S}/Bibata-Modern-Classic"
S_ONEUI="${S}/OneUI4-Icons-main"
S_DARKLY="${S}/Darkly-main"
S_GABARITO="${S}/gabarito-main"
S_KDE_MATERIAL_YOU_COLORS="${S}/kde-material-you-colors-main"
S_RUBIK="${S}/rubik-main"
S_READEXPRO="${S}/readexpro-master"
S_MATERIAL_DESIGN_ICONS="${S}/material-design-icons-main"
S_ADW_GTK3="${S}/adw-gtk3-main"
S_BREEZE_PLUS="${S}/breeze-plus-main"
S_DART_SASS="${S}/dart-sass"

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
	insinto /usr/libexec/dart-sass
	doins -r "${S_DART_SASS}"/*
	fperms +x /usr/libexec/dart-sass/sass
	fperms +x /usr/libexec/dart-sass/src/dart

	dodir /usr/bin
	cat > "${D}/usr/bin/sass" <<-EOF || die
#!/bin/bash
exec /usr/libexec/dart-sass/sass "\$@"
EOF
	fperms +x /usr/bin/sass

	insinto /usr/share/icons
	doins -r "${S_BIBATA}"
	for theme in "OneUI" "OneUI-dark" "OneUI-light"; do
        doins -r ${S_ONEUI}/${theme}
    done

	cd "${S_DARKLY}/build"
	cmake --install . --destdir="${D}"

	insinto /usr/share/fonts/ttf-gabarito
	doins "${S_GABARITO}"/fonts/ttf/*.ttf

	cd "${S_KDE_MATERIAL_YOU_COLORS}"
	mkdir -p build
	cd build
	cmake ..
	cmake --build . --parallel=$(nproc)
	cmake --install . --destdir="${D}"

	insinto /usr/share/fonts/ttf-readex-pro
	doins "${S_READEXPRO}"/fonts/ttf/*.ttf

	insinto /usr/share/fonts/ttf-material-design-icons
	doins "${S_MATERIAL_DESIGN_ICONS}"/font/*.ttf

	insinto /usr/share/themes
	doins -r "${S_BREEZE_PLUS}"/src/breeze-plus*

	cd "${S_ADW_GTK3}"
	meson install -C build --destdir="${D}"

	fc-cache -f
}
