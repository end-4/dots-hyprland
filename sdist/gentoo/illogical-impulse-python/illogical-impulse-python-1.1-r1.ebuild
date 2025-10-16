# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogical Impulse Python Dependencies"
HOMEPAGE=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="strip"

# SASSC is not needed here, pkgbuild is capping
DEPEND=""
RDEPEND="
	dev-python/clang
	dev-python/uv
	gui-libs/gtk
	gui-libs/libadwaita
	net-libs/libsoup
	dev-libs/libportal
	dev-libs/gobject-introspection
"
