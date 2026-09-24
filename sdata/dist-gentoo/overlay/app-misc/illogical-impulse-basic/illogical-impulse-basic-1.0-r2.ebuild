# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogical Impulse Basic Dependencies"
HOMEPAGE="https://github.com/end-4/dots-hyprland"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	sys-devel/bc
	sys-apps/coreutils
	app-misc/cliphist
	dev-build/cmake
	net-misc/curl
	net-misc/wget
	sys-apps/ripgrep
	app-misc/jq
	x11-misc/xdg-user-dirs
	net-misc/rsync
	app-misc/yq-go
"
