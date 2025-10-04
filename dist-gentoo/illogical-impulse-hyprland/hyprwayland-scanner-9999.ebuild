# Copyright 2024-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake toolchain-funcs

DESCRIPTION="A Hyprland implementation of wayland-scanner, in and for C++"
HOMEPAGE="https://github.com/hyprwm/hyprwayland-scanner/"

if [[ ${PV} == 9999 ]] ; then
	EGIT_REPO_URI="https://github.com/hyprwm/hyprwayland-scanner.git"
	inherit git-r3
else
	SRC_URI="https://github.com/hyprwm/hyprwayland-scanner/archive/v${PV}.tar.gz -> ${P}.gh.tar.gz"
fi

LICENSE="BSD"
KEYWORDS="amd64 arm64 x86"
SLOT="0"

RDEPEND=">=dev-libs/pugixml-1.14"
DEPEND="${RDEPEND}"

pkg_setup() {
	[[ ${MERGE_TYPE} == binary ]] && return

	if tc-is-gcc && ver_test $(gcc-version) -lt 13 ; then
		eerror "Hyprland requires >=sys-devel/gcc-13 to build"
		eerror "Please upgrade GCC: emerge -v1 sys-devel/gcc"
		die "GCC version is too old to compile Hyprland!"
	elif tc-is-clang && ver_test $(clang-version) -lt 16 ; then
		eerror "Hyprland requires >=llvm-core/clang-16 to build"
		eerror "Please upgrade Clang: emerge -v1 llvm-core/clang"
		die "Clang version is too old to compile Hyprland!"
	fi
}
