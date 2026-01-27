# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogical Impulse Hyprland related packages"
HOMEPAGE=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm64 x86"
RESTRICT="strip"

DEPEND=""
RDEPEND="
	gui-apps/hyprsunset
	>=gui-wm/hyprland-0.53.3:=
	gui-apps/wl-clipboard
"
