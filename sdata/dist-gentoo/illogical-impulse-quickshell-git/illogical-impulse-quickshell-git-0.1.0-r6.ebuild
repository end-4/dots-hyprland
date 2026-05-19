# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3

DESCRIPTION="Toolkit for building desktop widgets using QtQuick"
HOMEPAGE="https://quickshell.org/"

EGIT_REPO_URI="https://github.com/quickshell-mirror/quickshell.git"
EGIT_COMMIT="7511545ee20664e3b8b8d3322c0ffe7567c56f7a"

KEYWORDS="~amd64 ~arm64 ~x86"
LICENSE="LGPL-3"
SLOT="0"

IUSE="-breakpad +jemalloc +sockets +wayland +layer-shell +session-lock +toplevel-management +screencopy +X +pipewire +tray +mpris +pam +hyprland +hyprland-global-shortcuts +hyprland-focus-grab -i3 -i3-ipc +bluetooth"

RDEPEND="
	dev-qt/qtbase:6=
	dev-qt/qtdeclarative:6=
	dev-qt/qt5compat:6=
	kde-frameworks/kimageformats:6=[avif]
	dev-cpp/cpptrace[unwind]
	dev-qt/qtimageformats:6=
	dev-qt/qtmultimedia:6=
	dev-qt/qtpositioning:6=
	dev-qt/qtquicktimeline:6=
	dev-qt/qtsensors:6=
	dev-qt/qtsvg:6=
	dev-qt/qttools:6=
	dev-qt/qttranslations:6=
	dev-qt/qtvirtualkeyboard:6=
	dev-qt/qtwayland:6=
	kde-apps/kdialog
	kde-frameworks/syntax-highlighting:6=
	kde-frameworks/kirigami:6=

	jemalloc? ( dev-libs/jemalloc:= )
	wayland? (
		dev-libs/wayland
		dev-qt/qtwayland:6=
	)
	screencopy? (
		x11-libs/libdrm
		media-libs/mesa
	)
	X? ( x11-libs/libxcb:= )
	pipewire? ( media-video/pipewire:= )
	mpris? ( dev-qt/qtdbus:= )
	pam? ( sys-libs/pam )
	bluetooth? ( net-wireless/bluez )
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-cpp/cli11
	dev-build/cmake
	dev-vcs/git
	dev-build/ninja
	dev-qt/qtshadertools

	dev-util/spirv-tools
	wayland? (
		dev-util/wayland-scanner
		dev-libs/wayland-protocols
	)
	virtual/pkgconfig
	breakpad? ( dev-util/breakpad )
	dev-util/vulkan-headers
"

src_configure(){
	mycmakeargs=(
			-DCMAKE_BUILD_TYPE=RelWithDebInfo
			-DDISTRIBUTOR="Gentoo Illogical-Impulses"
			-DINSTALL_QML_PREFIX="$(get_libdir)/qt6/qml"
			-DCRASH_REPORTER=$(usex breakpad ON OFF)
			-DUSE_JEMALLOC=$(usex jemalloc ON OFF)
			-DSOCKETS=$(usex sockets ON OFF)
			-DWAYLAND=$(usex wayland ON OFF)
			-DWAYLAND_WLR_LAYERSHELL=$(usex layer-shell ON OFF)
			-DWAYLAND_SESSION_LOCK=$(usex session-lock ON OFF)
			-DWAYLAND_TOPLEVEL_MANAGEMENT=$(usex toplevel-management ON OFF)
			-DSCREENCOPY=$(usex screencopy ON OFF)
			-DX11=$(usex X ON OFF)
			-DSERVICE_PIPEWIRE=$(usex pipewire ON OFF)
			-DSERVICE_STATUS_NOTIFIER=$(usex tray ON OFF)
			-DSERVICE_MPRIS=$(usex mpris ON OFF)
			-DSERVICE_PAM=$(usex pam ON OFF)
			-DHYPRLAND=$(usex hyprland ON OFF)
			-DHYPRLAND_GLOBAL_SHORTCUTS=$(usex hyprland-global-shortcuts)
			-DHYPRLAND_FOCUS_GRAB=$(usex hyprland-focus-grab)
			-DI3=$(usex i3 ON OFF)
			-DI3_IPC=$(usex i3-ipc ON OFF)
			-DBLUETOOTH=$(usex bluetooth ON OFF)
		)
		cmake_src_configure
}
