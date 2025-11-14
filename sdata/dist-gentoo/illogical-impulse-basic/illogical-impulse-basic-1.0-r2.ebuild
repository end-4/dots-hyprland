# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogical Impulse Basic Dependencies"
HOMEPAGE=""

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="strip"

DEPEND=""
RDEPEND="
	sys-devel/bc
	sys-apps/coreutils
	app-misc/cliphist
	dev-build/cmake
	net-misc/curl
	net-misc/wget
	sys-apps/ripgrep
	dev-python/jq
	x11-misc/xdg-user-dirs
	net-misc/rsync
	app-misc/yq-go
"
