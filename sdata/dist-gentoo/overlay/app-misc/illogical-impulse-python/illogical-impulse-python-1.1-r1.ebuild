# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogical Impulse Python Dependencies"
HOMEPAGE="https://github.com/end-4/dots-hyprland"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

RDEPEND="
	dev-python/clang
	dev-python/uv
	gui-libs/gtk
	gui-libs/libadwaita
	net-libs/libsoup
	dev-libs/libportal[gtk]
	dev-libs/gobject-introspection
"
