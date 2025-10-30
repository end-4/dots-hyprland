# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogical Impulse Basic Dependencies"
HOMEPAGE=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="strip"

DEPEND=""
RDEPEND="
	net-misc/axel
	sys-devel/bc
	sys-apps/coreutils
	app-misc/cliphist
	dev-build/cmake
	net-misc/curl
	net-misc/rsync
	net-misc/wget
	sys-apps/ripgrep
	dev-python/jq
	dev-build/meson
	x11-misc/xdg-user-dirs
	app-misc/yq-go
"
