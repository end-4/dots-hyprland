# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogicall Impulse Widget Dependencies"
HOMEPAGE=""
SRC_URI="https://github.com/marin-m/SongRec/archive/${PV}.tar.gz -> ${P}-SongRec.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
# need for cargo fetch, idk how to get around it if possible
RESTRICT="strip network-sandbox"

DEPEND=""
RDEPEND=""

S="${WORKDIR}/SongRec-${PV}"

src_prepare() {
	default
	export CARGO_HOME="${WORKDIR}/cargo"
	cargo fetch --locked --target "$(rustc -vV | sed -n 's/host: //p')"
}

src_compile() {
	export CARGO_HOME="${WORKDIR}/cargo"
	cargo build --release --frozen --offline
}

src_install() {
	dobin target/release/songrec
	insinto /usr/share/applications

	doins packaging/rootfs/usr/share/applications/com.github.marinm.songrec.desktop

	insinto /usr/share/icons/hicolor/scalable/apps
	doins packaging/rootfs/usr/share/icons/hicolor/scalable/apps/com.github.marinm.songrec.svg

	insinto /usr/share/metainfo
	doins packaging/rootfs/usr/share/metainfo/com.github.marinm.songrec.metainfo.xml

	insinto /usr/share/songrec/translations
	doins -r translations/*

	dodoc README.md
}
