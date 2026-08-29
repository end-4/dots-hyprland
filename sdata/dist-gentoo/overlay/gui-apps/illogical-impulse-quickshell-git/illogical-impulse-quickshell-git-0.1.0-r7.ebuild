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

# Upstream recommends leaving all build options enabled by default
IUSE="
	+jemalloc +sockets
	+wayland +layer-shell +session-lock +toplevel-management
	+hyprland +screencopy
	+X +i3
	+tray +pipewire +mpris +pam +policykit +greetd +upower +notifications
	+bluetooth +networkmanager +crash-handler
"

REQUIRED_USE="
	layer-shell?         ( wayland )
	session-lock?        ( wayland )
	toplevel-management? ( wayland )
	hyprland?            ( wayland )
	screencopy?          ( wayland )
	i3? ( X )
"

II_RDEPEND="
	dev-qt/qt5compat:6=
	kde-frameworks/kimageformats:6=[avif]
	dev-qt/qtimageformats:6=
	dev-qt/qtmultimedia:6=
	dev-qt/qtpositioning:6=
	dev-qt/qtquicktimeline:6=
	dev-qt/qtsensors:6=
	dev-qt/qtsvg:6=
	dev-qt/qttools:6=
	dev-qt/qttranslations:6=
	dev-qt/qtvirtualkeyboard:6=
	wayland? (
		dev-libs/wayland
		dev-qt/qtwayland:6=
	)
	kde-frameworks/kirigami:6=
	kde-apps/kdialog
	kde-frameworks/syntax-highlighting:6=
"
RDEPEND="
	${II_RDEPEND}

	dev-qt/qtbase:6=[dbus,vulkan,X?]
	dev-qt/qtdeclarative:6=
	x11-libs/libdrm
	jemalloc? ( dev-libs/jemalloc )
	screencopy? ( media-libs/mesa )
	X? ( x11-libs/libxcb )
	pipewire? ( media-video/pipewire )
	pam? ( sys-libs/pam )
	policykit? (
		sys-auth/polkit
		dev-libs/glib
	)
	bluetooth? ( net-wireless/bluez )
	networkmanager? ( net-misc/networkmanager )
"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
	dev-cpp/cli11
	dev-util/spirv-tools
	dev-qt/qtshadertools:6
	screencopy? ( dev-util/vulkan-headers )
	wayland? (
		dev-util/wayland-scanner
		dev-libs/wayland-protocols
	)
	crash-handler? ( dev-cpp/cpptrace[unwind] )
"

DOCS=( README.md changelog/ )

PATCHES=( "${FILESDIR}/quickshell-0.3.0-strict-aliasing.patch" )

src_configure() {
	if tc-ld-is-mold; then
		ewarn "Using mold as a linker for quickshell will cause runtime issues"
		tc-ld-force-bfd
	fi
	# hyprland controls all Hyprland sub-features as a group.
	# i3 controls I3/Sway IPC.
	# screencopy controls all screencopy backends (icc, wlr, hyprland-toplevel).
	local _hyprland=$(usex hyprland)
	local _screencopy=$(usex screencopy)
	local _i3=$(usex i3)

	local mycmakeargs=(
		-DDISTRIBUTOR="Gentoo Illogical-Impulses"
		-DINSTALL_QML_PREFIX="$(get_libdir)/qt6/qml"
		-DCRASH_HANDLER=$(usex crash-handler)
		-DUSE_JEMALLOC=$(usex jemalloc)
		-DSOCKETS=$(usex sockets)
		-DWAYLAND=$(usex wayland)
		-DWAYLAND_WLR_LAYERSHELL=$(usex layer-shell)
		-DWAYLAND_SESSION_LOCK=$(usex session-lock)
		-DWAYLAND_TOPLEVEL_MANAGEMENT=$(usex toplevel-management)
		-DHYPRLAND=${_hyprland}
		-DHYPRLAND_IPC=${_hyprland}
		-DHYPRLAND_GLOBAL_SHORTCUTS=${_hyprland}
		-DHYPRLAND_FOCUS_GRAB=${_hyprland}
		-DHYPRLAND_SURFACE_EXTENSIONS=${_hyprland}
		-DSCREENCOPY=${_screencopy}
		-DSCREENCOPY_ICC=${_screencopy}
		-DSCREENCOPY_WLR=${_screencopy}
		-DSCREENCOPY_HYPRLAND_TOPLEVEL=${_screencopy}
		-DX11=$(usex X)
		-DI3=${_i3}
		-DI3_IPC=${_i3}
		-DSERVICE_STATUS_NOTIFIER=$(usex tray)
		-DSERVICE_PIPEWIRE=$(usex pipewire)
		-DSERVICE_MPRIS=$(usex mpris)
		-DSERVICE_PAM=$(usex pam)
		-DSERVICE_POLKIT=$(usex policykit)
		-DSERVICE_GREETD=$(usex greetd)
		-DSERVICE_UPOWER=$(usex upower)
		-DSERVICE_NOTIFICATIONS=$(usex notifications)
		-DBLUETOOTH=$(usex bluetooth)
		-DNETWORK=$(usex networkmanager)

	)
	cmake_src_configure
}
